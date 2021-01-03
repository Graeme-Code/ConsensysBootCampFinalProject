// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

//General notes
// This smart contract will focus on matching via two arrays of bet structs
//constraint, bet will only have 2 outcomes
//minting of outcome tokens should be another contract
//refactored bet function to take bet side as an input. 
//refactored to find oldest avalaible bet avaliabilty via an index instead of looping
//refactor initial bet counter
//added events/logging 
//Natspec Comments 
// Cancel Bet Feature
//Safe Math // Note safe math in the update bet function GAS's out. think its incrementing by add(1). 
// Refactor to remove duplicate code and control while statement. 
//ETH only bets with contract deployer as bet Admin
// do a way with the do/while statement for updating bets, its breaking due to gas
// this function can be reworked using the playerBets mapping 


/// @title A betting market maker which matches bets at a one to one ratio. 
/// @author Graeme Barnes
/// @notice This contract faciliates all or nothing betting
/// @dev This contract has not been audited and has implict assumption that bet has two outcomes, A and B. 


contract AllOrNothing {
    
///@notice use safe math for uint 
using SignedSafeMath for int;
using SafeMath for uint;

/// @notice this struct contains all information relating to a users bet. 
struct Bet {
    address betMaker;
    uint amount; //varible to show how much was bet 
    uint betMatched; //varible to show how much bet has been filled, plus how much is avalible. 
}

/// @notice struct to hold metadata accosiated with an outcome
struct BetMetaData {
    string outcomeDescription;
    int outcomeBetTotal; //ref to int public outcomeABetTotal
    int outcomeBetAvailabilityCounter; // ref uint public outcomeABetAvailabilityCounter;
    Bet [] outcomeBets;
    mapping (address => uint[]) playerBets;
}

/// @notice Bet description
string public betDescription; 

/// @notice Owner of contract may resolve betDescription
address public owner;

/// @notice Bet state
enum States { Open, Resolved }
/// @notice state is set to open
States public state = States.Open;

/// @notice winningOutcome 
uint256 public winningOutcome;

/// @notice map outcomes to thier metadata
mapping (uint => BetMetaData) public outcome;

/// @notice outcomes A and B are represent by 0 and  respectively so that it may be used as an in put in the Bet function. 
uint public outcomeA = 0;
uint public outcomeB = 1; 
int private preBetOutcomeDifference;
int private postBetDifference;

/// @notice emergancy Stop varible
 bool public stopped = false;

 /// Modifiers
 modifier stopInEmergency { require(!stopped); _; }
 modifier onlyOwner { require(msg.sender == owner); _;}

/// Events

/// @notice Log events when user has made a bet
event LogBet(address _betMaker, uint _amount, uint _outcome, int outcomeBetTotal);

/// @notice Log events for BetsToBeMatched function
event LogNoMatches(int _preBetOutcomeDifference,int _postBetDifference, int _Matches);
event LogMatchMade(int _preBetOutcomeDifference, int _postBetDifference, int _Matches);

/// @notice Log events for updating Bets 
/// add varibles for the Bet's Amount and BetMatched after Bet. 
event LogBetMakerMatch(uint outcome, int _BetsMatched);
event LogBetTakerMatch(uint outcome, int _BetsMatched, uint _betAvalabile);

/// @notice Log events for withdrawing unMatched Bets
event logWithdrawalLoop(uint i, uint AvalibileBet);
event logPlayerIndex(uint playerBetIndex);
event LogWithdrawUnMatchedBet(uint _withdrawAmount, uint outcome);
event loopRunning(uint _withdrawOutcome);
event loopFirstLoop(uint );

/// @notice log events for resolving a market
event logResolveBet(uint winningOutcome);

/// @notice log evetns for redeeming matched bets
event logRedeemBet(uint playerBetIndex);
event logWinnings(uint winnings);

constructor (string memory _outcomeDescriptionA, string memory _outcomeDescriptionB, string memory _betDescribtion, address _owner) public {
    outcome[outcomeA].outcomeDescription = _outcomeDescriptionA;
    outcome[outcomeB].outcomeDescription = _outcomeDescriptionB;
    betDescription = _betDescribtion;
    owner = _owner;
    winningOutcome = 2;
}

/// @notice function for user to make a bet by adding a Bet to the corresponding bet array. 
/// @param _outcome, 0 or 1 will place bet in A or B array respectively. 
function placeBet (uint _outcome) stopInEmergency public payable {
    require (_outcome == 0 || _outcome == 1, "input must be 0 outcomeA or 1 outcomeB");
    require (state == States.Open);
    uint oppositeOutcome;
    if (_outcome == 0){
         oppositeOutcome = 1;
    } else {
        oppositeOutcome =0;
    }
    require(outcome[_outcome].outcomeBets.length < outcome[oppositeOutcome].outcomeBets.length.add(3), "too many bets one one side");
    
    preBetOutcomeDifference = outcome[0].outcomeBetTotal - outcome[1].outcomeBetTotal;
    Bet memory b;
    b.betMaker = msg.sender;
    b.amount = msg.value;
    
    //point to storage varibles for readability
    Bet [] storage outcomeBets = outcome[_outcome].outcomeBets;
    uint[] storage playerBets = outcome[_outcome].playerBets[msg.sender];
    
    //update Bet Array, BetTotal and playerBets Array
    outcomeBets.push(b);
    outcome[_outcome].outcomeBetTotal = outcome[_outcome].outcomeBetTotal.add(int(b.amount));
    playerBets.push(outcomeBets.length.sub(1));
    
    emit LogBet(msg.sender, msg.value, _outcome, outcome[_outcome].outcomeBetTotal);
        
    /// @notice Update the difference between bet amounts after a bet has been made. 
    postBetDifference = outcome[0].outcomeBetTotal.sub(outcome[1].outcomeBetTotal);
    
    // use the BetMatch function to work out how much bet should be matched. 
    int BetsMatched = betsToBeMatched(preBetOutcomeDifference, postBetDifference);
    
    /// @notice only run the updateBets function if BetsTobEmathced updates BetsMatched to a value greater than 0. 
    if (BetsMatched > 0){
        updateBets (BetsMatched, _outcome);
    } 
    
}

/// @notice Function updates how many bets may be matched after a user makes a Bet. 
/// @param _preBetOutcomeDifference should be preBetOutcomeDifference varible
/// @param _postBetDifference should be postBetDifference varible
function betsToBeMatched (int _preBetOutcomeDifference, int _postBetDifference) internal returns (int BetsMatched) {
    if ((_postBetDifference < _preBetOutcomeDifference && _preBetOutcomeDifference <= 0) || (_postBetDifference > _preBetOutcomeDifference && _preBetOutcomeDifference >= 0)) {
       //Means moving away from zero in the positive direction, without corssing zero. 
    //No Bets should be matched. 
     BetsMatched = 0;
     emit LogNoMatches(_preBetOutcomeDifference, _postBetDifference, BetsMatched);
     return BetsMatched;
       
       
    } else if (_postBetDifference > _preBetOutcomeDifference && _preBetOutcomeDifference < 0 && _postBetDifference >= 0) {
       // Means moved in a positive direcction, crossing zero.
       // Matched bets should be the difference between postBetDifference and zero 
       int zero = 0;
       BetsMatched = zero.sub(preBetOutcomeDifference);
       emit LogMatchMade(_preBetOutcomeDifference, _postBetDifference, BetsMatched);
       return BetsMatched;
       
       
    } else if (_postBetDifference > _preBetOutcomeDifference && _preBetOutcomeDifference < 0 && _postBetDifference < 0) {
        /// Means moving towards 0, but not crossing zero.
        /// Matched bets should equal to the difference between pre and post Bet. 
        BetsMatched = postBetDifference.sub(preBetOutcomeDifference);
        emit LogMatchMade(_preBetOutcomeDifference, _postBetDifference, BetsMatched);
        return BetsMatched;
       
        
    }  else if (_postBetDifference < _preBetOutcomeDifference && _preBetOutcomeDifference > 0 && _postBetDifference <= 0) {
        /// means moving in the negative direction, crossing or reaching zero
        /// Matched bets should be the difference between preBet Difference and zero. 
        BetsMatched = preBetOutcomeDifference.sub(0);
        emit LogMatchMade(_preBetOutcomeDifference, _postBetDifference, BetsMatched);
        return BetsMatched;
        
    } else if (_postBetDifference < _preBetOutcomeDifference && _preBetOutcomeDifference > 0 && _postBetDifference > 0) {
        /// means moving in the negative direction, not reaching or crossing zero.  
        /// Matched bets should be the difference between pre and post Bet differences. 
        BetsMatched = preBetOutcomeDifference.sub(postBetDifference);
        emit LogMatchMade(_preBetOutcomeDifference, _postBetDifference, BetsMatched);
        return BetsMatched;
        
    }
  
}

/// @notice function which updates Bet matches from the oldest BET that has not been completetly matched. 
/// @param _BetsMatched should be varble BetsMatched. 
/// @param _outcome represent the outcome which the user has bet on. 
function updateBets (int _BetsMatched, uint _outcome) internal {
   // local varibles to update bet struct and 
   uint betAvalabile;
   uint oppositeOutcome;

    if(_outcome == 0){
        oppositeOutcome = 1;
    } else {
        oppositeOutcome = 0;
    }
    // update placed bet
    outcome[_outcome].outcomeBets[outcome[_outcome].outcomeBets.length.sub(1)].betMatched = outcome[_outcome].outcomeBets[outcome[_outcome].outcomeBets.length.sub(1)].betMatched.add(uint(_BetsMatched));
    /// increment outcomeABetAvailabilityCounter
    outcome[_outcome].outcomeBetAvailabilityCounter ++;
    emit LogBetMakerMatch(_outcome, _BetsMatched);
       
    //do while loop to match bets from oldest to youngest 
    do{
        betAvalabile = outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].amount.sub(outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].betMatched);
            if (betAvalabile > uint(_BetsMatched)){
                
                outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].betMatched = outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].betMatched.add(uint(_BetsMatched));
                
                //outcomeBBets[outcomeBBetAvailabilityCounter].betMatched = outcomeBBets[outcomeBBetAvailabilityCounter].betMatched.add(uint(_BetsMatched));
                _BetsMatched = 0;
                emit LogBetTakerMatch(_outcome, _BetsMatched, betAvalabile);
                
            } 
            /// if betAvalaible is equal to betmatch, fill betmatch and increment the avalaibility counter.
            else if (betAvalabile == uint(_BetsMatched)) {
                outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].betMatched = outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].amount;
                _BetsMatched = 0;
                outcome[oppositeOutcome].outcomeBetAvailabilityCounter ++;
                emit LogBetTakerMatch(_outcome, _BetsMatched, betAvalabile);
            } 
            /// if there is more betmatch than bet avalabile, fill the bet, increment the avalaible bet counter and start again. 
            else if (betAvalabile < uint(_BetsMatched)) {
                outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].betMatched = outcome[oppositeOutcome].outcomeBets[uint(outcome[oppositeOutcome].outcomeBetAvailabilityCounter)].amount;
                _BetsMatched = _BetsMatched - int(betAvalabile);
                outcome[oppositeOutcome].outcomeBetAvailabilityCounter ++;
                emit LogBetTakerMatch(_outcome, _BetsMatched, betAvalabile);
            }
          } while (_BetsMatched > 0);
        }
        
    function withdrawUnmatchedBets() stopInEmergency public {
        
        uint withdrawAmount = 0;
        uint withdrawOutcome = 0;
    
        /// @notice assign withdraw outcome based on which bet has more bet on it
        if (outcome[withdrawOutcome].outcomeBetTotal > outcome[1].outcomeBetTotal) {
            withdrawOutcome = 0;
        } else if (outcome[withdrawOutcome].outcomeBetTotal < outcome[1].outcomeBetTotal) {
           withdrawOutcome = 1;
        } else {
            return();
        }
        
            for (uint i = uint(outcome[withdrawOutcome].outcomeBetAvailabilityCounter); i < outcome[withdrawOutcome].outcomeBets.length; i++) {
                if (outcome[withdrawOutcome].outcomeBets[i].betMaker == msg.sender) {
                    //update withdraw amount 
                    withdrawAmount = withdrawAmount.add((outcome[withdrawOutcome].outcomeBets[i].amount.sub(outcome[withdrawOutcome].outcomeBets[i].betMatched)));
                    //update bet struct amount to equal betMatched
                    outcome[withdrawOutcome].outcomeBets[i].amount = outcome[withdrawOutcome].outcomeBets[i].betMatched;
                    //update Betoutcome total 
                    outcome[withdrawOutcome].outcomeBetTotal = outcome[withdrawOutcome].outcomeBetTotal.sub(int(withdrawAmount));               
                }
               emit LogWithdrawUnMatchedBet(withdrawAmount, withdrawOutcome);
            }
        msg.sender.transfer(withdrawAmount);   
    }
    
    /// @notice a getter function to find unmatched bets and amounts
    function getOutcomeBetAmount(uint _outcome, uint _betArrayIndex) external view returns (uint _amount, uint _betMatched ) {
        uint amount = outcome[_outcome].outcomeBets[_betArrayIndex].amount;
        uint betMatched = outcome[_outcome].outcomeBets[_betArrayIndex].betMatched;
        return (amount, betMatched);
    }
    /// @notice a function for getting the player bets
    function getPlayerBetsArrayLength(uint _outcome) view public returns (uint) {
        uint playerBetIndexLength;
        playerBetIndexLength = outcome[_outcome].playerBets[msg.sender].length;
        return playerBetIndexLength;
    }
    
    /// @notice resolve bet
    function resolveBet (uint _winningOutcome) onlyOwner public {
        require(state == States.Open, "Can only resolve a bet if its open");
        require(_winningOutcome == 0 || _winningOutcome == 1, "Valid outcomes can be 0 or 1");
        state = States.Resolved;
        winningOutcome = _winningOutcome;
        emit logResolveBet(winningOutcome);
    }
    /// @notice redeem bet
    function redeem() stopInEmergency public {
        require(state == States.Resolved, "Bet must be resolved before redeeming");
        require (getPlayerBetsArrayLength(winningOutcome) > 0, "User must of made a bet on winning outcome");
        uint playerBetIndex;
        uint winnings;
        // loop through a players winning bets
        for(uint i = 0; i <= getPlayerBetsArrayLength(winningOutcome).sub(1); i ++) {
        playerBetIndex = outcome[winningOutcome].playerBets[msg.sender][i];
        emit logRedeemBet(playerBetIndex);
        // now check index if its less than bet avalaible
        if (int(playerBetIndex) <= outcome[winningOutcome].outcomeBetAvailabilityCounter) {
        // add amount to send user
        winnings = winnings.add(outcome[winningOutcome].outcomeBets[playerBetIndex].betMatched);
        //update BetMatched to equal zero to prevent double claims
        outcome[winningOutcome].outcomeBets[playerBetIndex].betMatched = 0;
        }
     }
    // multiple winnings to reflect matched Bets
    winnings = winnings.mul(2);
    emit logWinnings(winnings);
    msg.sender.transfer(winnings);
    }

    /// @notice function to change emergancy stop
    function emergancyStop() onlyOwner public {
        stopped = !stopped;
    }

    /// @notice function to get outcomeA and B description
    function getOutcomeDescriptions() public view returns (string memory, string memory) {
     string memory descriptionA = outcome[outcomeA].outcomeDescription;
     string  memory descriptionB = outcome[outcomeB].outcomeDescription;
     return (descriptionA, descriptionB);
    }

    /// @notice function to get Bet Totals
    function getOutcomeTotals() public view returns (int, int ) {
        int outcomeABetTotal = outcome[outcomeA].outcomeBetTotal;
        int outcomeBBetTotal = outcome[outcomeB].outcomeBetTotal;
        return (outcomeABetTotal, outcomeBBetTotal);
    }

 
    /// @notice fallback function
    fallback() external { }
    
    
}
