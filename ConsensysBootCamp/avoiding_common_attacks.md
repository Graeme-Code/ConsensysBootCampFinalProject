Avoiding Common Attacks

**Over/Under Flow**
Because the smart contract uses a concept of a number line to work out how many bets can be matched after a new bet is placed, it is vunerable to under/overflow errors. 
To prevetn this the contract incorporates the Safe math libraries for both signed and unsigned intergers. 
Note that safe math is not used to increment iterators when running loops as this leads to excersive GAS costs. 

**Denial of Service**

Because the smart contract uses loops to in many of its functions, there is a potential attack whereby a user can:

1. place a bet on an outcome which has highest bet total, incrementing the length of the bet array. 
2. withdraw unmatched bets, not affecting the length of the bet array, but leaving the bet struct in the bet array with an amount 0. 
3. Keep on doing this until the bet array becomes so long that it breaks the function that use loops.

The way this is prevented is by using a require statement when bets are placed which checks that the differences length of the Bet Array's for each outcome are no greater than 3.

require(outcome[_outcome].outcomeBets.length < outcome[oppositeOutcome].outcomeBets.length.add(3), "too many bets one one side");

This means that the above spamming attack is not possible, but also means a users may not place a bet on one side of the outcome once its more than 3 longer than the oppostive outcomes bet array.




