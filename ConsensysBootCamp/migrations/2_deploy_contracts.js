const AllOrNothing = artifacts.require("AllOrNothing.sol");

module.exports = function (deployer, network, accounts) {
    deployer.deploy(AllOrNothing, "team X", "team Y", "Who will win?", accounts[0], {from: accounts[0]});
};