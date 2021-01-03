**Design Pattern Decisions**

Data Structures:

The smart contract assumes bets have only two outcomes. This assumption informs the descion of how data is managed. 

The smart contract uses a Struct to represents Bet's placed by the user. These "Bets" contain the address of the user who create the Bet. The amount that has been Bet and how much of that bet has been matched. 

Each Bet is stored in a Bet Array. The Bet Array itself lives in a struct called Bet Meta Data which includes: 
- a string description of the outcome. 
- How much has been bet on the outcome 
- An array of Bets for the outcome 
- A mapping of address to an array of indexs where the address has placed a Bet

Finally there is a mapping between outcomes as represented by 0 and 1 to its Bet Meta Data. 

**When a bet is placed the following happens:**

1. A Bet is created 
2. That Bet is inserted into an Array inside the Bet Meta Data Struct correspondiing to the outcome the Bet was made on. 
3. We then need to know if the Bet can be matched to an exisiting Bet on the opposite outcome. To work this out the smart contract uses a function "betsToBeMatched" which calculates the 
bets to be matched. It does this using [number line](https://en.wikipedia.org/wiki/Number_line). This requires working with signed integers and means working with Signed and Unsigned Safe math to prevent overflows. 
4. Assuming the return of Bets to be matched is positive, the smart contract updates Bets, importantly updating the "betMatched" inside of the Bet Struct to reflect how mcuh has been matched. 
How it does this is...an issue. It uses a do while loop to update matched Bets in the opposite outcomes (to the bet been made) Bet array. Looping through the "oldest bet", updating the betMatched.
This do/while loop will continue until a varible "betAvalaible", initiallized to equal the return of the "betsToBeMatched", reaches 0.

**What if a bet hasnt been matched?** 

We need a way for users to get unmatched Bets out of the smart contract. For this we use a function "withdrawUnmatchedBets" which does just that. 
What is does is loop through the bet array of the outcome which has the highest amount bet on it. It will only start the loop from the "outcomeBetAvailabilityCounter", a varible representing the index in the Bet array which is the oldest bet which can take a bet. 
When the smart contract finds a bet where the betmaker address is equal to the address making the transaction it adds the difference between bet amount and bets matched to a withdraw total, then updates the bet amount to equal bet matched. 

**what happens when a bets finished**
The last parts of the contract involve resolving and redeeming the Bet. Resolving is a function only accessible by the owner and it basically updates the bet state from "Open" to "Resolved". 
The Redeeming of winnings works similarly to withdraw and update bets in the sense that it uses loops. 
The function loops through the Bet array of the winning outcome using the index in the playerBets array, adding the betMatched to a winnings varible. 
When the loop is complete it sends the value in the "winnings" varible to the address that initaited the transaction. 

**Patterns**

Ownable:

The Contract rewquires an owner, defined in the constructer to resolve the bet. It uses an "onlyOwner" modifer to ensure functions, like resolve, may only be run by the owner. 

Why: Only because the contract needs to delegate key the role of resolving a bet to a specific address. 

Emergency Stop: 

Another function the which uses the onlyOwner modifer is emergancy Stop, a function which will stop key functions via a modifier "stopInEmergency".

Why: If there is a vunerability, the owner can mitigate losses by implementing the emergancy stop pattern. 

**Thoughts on Design and next iterations**

Using loops introduces a concern that the amount of GAS required to complete an updateBets, withdrawUnmatchedBets or redeem is greater than the block limit. 
Measures have been put in place to prevent this which is discussed in the avoiding_common_attacks, however it does have a negative impact on UX.
Ideally two measures should be put in place. 

1. Mappings should be used to faciliate updateBets, withdrawUnmatchedBets and redeem over loops. 
2. The contract itself should just be repsonsible for match making and a different contract should be responsible for the resolving. 






