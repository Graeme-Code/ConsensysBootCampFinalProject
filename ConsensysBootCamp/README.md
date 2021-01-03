# ConsensysBootCamp
A repo with final project for Consensys Bootcamp 

**Name: All or Nothing**

**Concept:** 

On twitter and in particular crypto twitter there are a lot of bets said, but are never followed through with. In real life, when making a bet, we will say something like, “I bet $10 that my team will win”. The intention for “All or Nothing” Dapp is to facilitate this interaction but securely and trustlessly amongst multiple people. 

**How it works:**

Someone should be able to create a bet. Creating a bet will mean working with a smart contract that, when receiving a collateral token, will produce tokens in equal proportion to collateral,  which represent an outcome of the bet. The contract that produces these outcome tokens should receive an input which will determine which outcome token may be redeemed for collateral and which ones are worthless. 

There are several audited and battle tested contracts that do this, most notable examples come for Augur or Gnosis. 

The magic of the experience and where I would like my project to really focus on is the order matching. 

The user who creates the bet will be required to put down collateral on an outcome. Another user may come along and put collateral on the other side of the bet. At this point the smart contract should mint outcome tokens which equal the amount of collateral on both sides and send the outcome tokens to correct parties.  

To keep the scope of the project limited, creation of bets and redeeming of outcome tokens will be left to existing interfaces. The core project will primarily focus on facilitation of bet making. 

In practice I could not relaible get the project to mint conditional tokens on behalf of the user. So this project doesnt use conditional tokens but rather faciliates ether betting with bet creation, tracking bets made, resolving bets and faciliating redemption of winnings. 

**How to get it running on your machine:**

This project is based on the react truffle box found here: https://www.trufflesuite.com/boxes/react and uses the react version as specified in the box.
Using Truffle: Truffle v5.1.51
NPM Version: 6.14.8

Step one, git this project running on your local machine. Start a new folder and clone the project using https://github.com/Graeme-Code/ConsensysBootCamp.git

Step two: Open the your folder with a VS code (my preference), start a new terminal and run truffle develop

Step three: Run test, to make sure the project is runnning correct. 

Step four: configure your wallet. In the truffle config file replace: const mnemonic = "secret" with mnemonic of your wallet. 

Step five: Should be good to deploy on rinkeby, run: truffle migrate --network rinkeby

Step six: Cd into client, then run npm run start to boot up a local front end. 

Step seven: navigate to local host and make sure your metamask is on rinkeby network. Enjoy. 

**Demo Video**

https://www.youtube.com/watch?v=DP_KS-tY3NQ

