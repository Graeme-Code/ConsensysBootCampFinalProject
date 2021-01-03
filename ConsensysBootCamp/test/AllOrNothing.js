const { isMainThread } = require("worker_threads");

const AllOrNothing = artifacts.require("./AllOrNothing.sol");

contract('AllOrNothing', (accounts) => {
    let [alice, bob, chris, dave] = accounts;
    let contractInstance;
    beforeEach(async () => {
        contractInstance = await AllOrNothing.new('A', 'B', 'A or B', dave);
    });
    it('Should deploy', async () => {
        console.log(contractInstance.address);
        assert.notEqual(contractInstance.address,'');
    });
    it('An account should be able to place first bet',async () => {
        let bet1 = await contractInstance.placeBet(0, {from: alice, value: 1});
        let bet1EventAmount = bet1.logs[0].args[1].words[0];
        let betMatchedEvent = bet1.logs[1].event;
        assert.equal(bet1EventAmount, 1);
        assert.equal(betMatchedEvent, "LogNoMatches", "The event LogNoMatches should be fired after Bet 1")
    });
    it('Two bets of equal size should equal a bet match of equal size',async () => {
        let bet1 = await contractInstance.placeBet(0, {from: alice, value: 2});
        let bet1MatchedEvent = bet1.logs[1].event;
        let bet1EventAmount = bet1.logs[0].args[1].words[0];
        let bet2 = await contractInstance.placeBet(1, {from: bob, value: 2});
        let bet2EventAmount = bet1.logs[0].args[1].words[0];
        let bet2MatchedEvent = bet2.logs[1].event;
        let bet2MatchedEventAmount = bet2.logs[1].args._Matches.words[0];
        //check event amount for bet is correct 
        assert.equal(bet1EventAmount, 2);
        assert.equal(bet2EventAmount, 2);
        //Check that LogNoMAtches event is fired after Bet 1 is placed. 
        assert.equal(bet1MatchedEvent, "LogNoMatches", "The event LogNoMatches should be fired after Bet 1");
        //Check that LogBetMatch event is fired after Bet 2 is placed and that the amount matched is 2
        assert.equal(bet2MatchedEvent, "LogMatchMade", "The event LogBetMatche should be fired after Bet 2");
        assert.equal(bet2MatchedEventAmount, 2);
    });
    it('Mutliple Bets on one side of Bet should be matched by a Bet from the other side from oldest to yougest',async () => {
        let bet1 = await contractInstance.placeBet(0, {from: alice, value: 2});
        let bet1MatchedEvent = bet1.logs[1].event;
        let bet2 = await contractInstance.placeBet(0, {from: bob, value: 2});
        let bet2MatchedEvent = bet2.logs[1].event;
        let bet3 = await contractInstance.placeBet(1, {from: chris, value: 3});
        let bet3MatchedEvent = bet3.logs[1].event;
        //get amount emitted for bet3
        let bet3EventAmount = bet3.logs[0].args._amount.words[0];
        //get match amount emitted for bet3 
        let bet3MatchedEventAmount = bet3.logs[1].args._Matches.words[0];
        //Check that no Match event is emmited for bet 1
        assert.equal(bet1MatchedEvent, "LogNoMatches", "The event LogNoMatches should be fired after Bet 1");
        //Check that no Match event is emmited for bet 2
        assert.equal(bet2MatchedEvent, "LogNoMatches", "The event LogNoMatches should be fired after Bet 2");
        //Check the first B Bet that amount = 3 and betMatched equals 3. 
        assert.equal(bet3EventAmount, 3);
        //Check that Match event is emmited and matched amount equals 3
        assert.equal(bet3MatchedEvent, "LogMatchMade", "The event LogBetMatch should be fired after Bet 3");
        assert.equal(bet3MatchedEventAmount, 3);
    });
    it('Withdrawing unMatched Bets should send unmatched ether back to user account and update Bet Struct',async () => {
        let bet1 = await contractInstance.placeBet(0, {from: alice, value: 5});
        let bet1MatchedEvent = bet1.logs[1].event;
        let bet2 = await contractInstance.placeBet(1, {from: bob, value: 1});
        let bet2MatchedEvent = bet2.logs[1].event;
        let aliceBeforeWithdrawBalance = await web3.eth.getBalance(alice);
        let withdrawBet = await contractInstance.withdrawUnmatchedBets({from: alice});
        let aliceAfterWithdrawBalance = await web3.eth.getBalance(alice);
        assert(aliceAfterWithdrawBalance, (aliceBeforeWithdrawBalance + 4), "Amount should equal Betmatched after withdrawl of unmatched bets" );
    });
    it("it should be able to be resolved",async () => {
        let bet1 = await contractInstance.placeBet(0, {from: alice, value: 5});
        let bet1MatchedEvent = bet1.logs[1].event;
        let bet2 = await contractInstance.placeBet(1, {from: bob, value: 5});
        let bet2MatchedEvent = bet2.logs[1].event;
        let resolveBet = await contractInstance.resolveBet(0, {from: dave});
        let resolvedBet = await contractInstance.winningOutcome.call();
        assert(resolvedBet, 0, "resolveBetEvent Outcome should equal 0" );
    });
    it("it should be able to redeem winnings",async () => {
        let bet1 = await contractInstance.placeBet(0, {from: alice, value: 5});
        let bet1MatchedEvent = bet1.logs[1].event;
        let bet2 = await contractInstance.placeBet(1, {from: bob, value: 5});
        let bet2MatchedEvent = bet2.logs[1].event;
        let resolveBet = await contractInstance.resolveBet(0, {from: dave});
        let aliceBeforeRedeem = await web3.eth.getBalance(alice);
        let redeem = await contractInstance.redeem({from:alice});
        let aliceAfterRedeem = await web3.eth.getBalance(alice);
        assert(aliceAfterRedeem, (aliceBeforeRedeem + 10), "resolveBetEvent Outcome should equal 0" );
    });

});
