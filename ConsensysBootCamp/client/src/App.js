import React, { Component } from "react";
import AllOrNothing from "./contracts/AllOrNothing.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  constructor(props) { //becasue OOP
    super(props);
    this.state = {//add state varibles
      accounts: null,
      contract: null,
      web3: null,
      winningOutcome:'',
      betDescription:'',
      outcomeA:'',
      outcomeB:'',
      outcomeATotal: '',
      outcomeBTotal: '',
      outcomeADescription:'',
      outcomeBDescription:'',
      betValue: 1,
      owner:'',
      resolveValue: 0,
      isOwner: '',
    }
    this.placeBet = this.placeBet.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.withdrawUnmatchedBets = this.withdrawUnmatchedBets.bind(this);
    this.resolveBet = this.resolveBet.bind(this);
    this.handleSelectorChange = this.handleSelectorChange.bind(this);
    this.redeemBet = this.redeemBet.bind(this);
  }


  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = AllOrNothing.networks[networkId];
      const instance = new web3.eth.Contract(
        AllOrNothing.abi,
        deployedNetwork && deployedNetwork.address,
      );
      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, contract: instance}, this.populateData);
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  populateData = async () => {
    const { accounts, contract } = this.state;
    const betDescription = await contract.methods.betDescription().call();
    const winningOutcome = await contract.methods.winningOutcome().call();
    const outcomeA = await contract.methods.outcomeA().call();
    const outcomeB = await contract.methods.outcomeB().call();
    let outcomeDescriptions = await contract.methods.getOutcomeDescriptions().call();
    const outcomeADescription = outcomeDescriptions[0];
    const outcomeBDescription = outcomeDescriptions[1];
    let outcomeTotals = await contract.methods.getOutcomeTotals().call();
    var outcomeATotal = outcomeTotals[0];
    var outcomeBTotal = outcomeTotals[1];
    
    const owner = await contract.methods.owner().call();
    var isOwner = false;

    
    if (owner == accounts){
      isOwner = true;
    } else {
      isOwner = false;
    }
    
    document.getElementById("resolve").style.display = "none"

    //shit need to write a getter for this 
    //outcome[outcomeA].outcomeDescription = _outcomeDescriptionA;
    //outcome[outcomeB].outcomeDescription = _outcomeDescriptionB;

    // Update state with the result.
    this.setState({ betDescription: betDescription, winningOutcome: winningOutcome, outcomeA: outcomeA, outcomeB: outcomeB, owner: owner, isOwner: isOwner, outcomeADescription: outcomeADescription, outcomeBDescription: outcomeBDescription, outcomeATotal: outcomeATotal, outcomeBTotal: outcomeBTotal });
  
    //show or hide resolve form is user is owner
    if (this.state.isOwner == false){
      document.getElementById("resolve").style.display = "none";
    } else {
      document.getElementById("resolve").style.display = "block";
    }

    if (this.state.winningOutcome == 0 || this.state.winningOutcome == 1) {
      document.getElementById("redeem").style.display = "block";
    } else {
      document.getElementById("redeem").style.display = "none";
    }
  
  };

  placeBet = async(outcome) => {
    const { accounts, contract } = this.state;
    let bet = await contract.methods.placeBet(outcome).send({from: accounts[0], value: this.state.web3.utils.toWei(this.state.betValue, 'ether')});
    let response = bet.events;
    let betAmount =  JSON.stringify(response.LogBet.returnValues[1]);
    let alertResponse = new String(`Amout of Wei Successfully Bet: ${betAmount}`);
    alert(alertResponse);
    //update bet totals
    let outcomeTotals = await contract.methods.getOutcomeTotals().call();
    let outcomeTotal = outcomeTotals[outcome];
    if (outcome == 0) {
      this.setState({outcomeATotal: outcomeTotal});
    } else {
      this.setState({outcomeBTotal: outcomeTotal});
    }

  };

  handleChange(event) {
    console.log(event.target.value);
    this.setState({betValue: event.target.value});
  };

  withdrawUnmatchedBets = async() => {
    const { accounts, contract } = this.state;
    let withdrawUnmatchedBets = await contract.methods.withdrawUnmatchedBets().send({from: accounts[0]});
    console.log(withdrawUnmatchedBets);
    //update bet totals 
    let outcomeTotals = await contract.methods.getOutcomeTotals().call();
    var outcomeATotal = outcomeTotals[0];
    var outcomeBTotal = outcomeTotals[1];
    this.setState({outcomeATotal: outcomeATotal, outcomeBTotal: outcomeBTotal });
  };

  handleSelectorChange = async(event) => {
    this.setState({resolveValue: event.target.value});
  };

  resolveBet = async(event) => {
    const { accounts, contract } = this.state;
    event.preventDefault();
    let resolveBet = await contract.methods.resolveBet(this.state.resolveValue).send({from: accounts[0]});
    let winningOutcome = await contract.methods.winningOutcome().call();
    this.setState({winningOutcome: winningOutcome });
  };

  redeemBet = async() => {
    const { accounts, contract } = this.state;
    let redeemBet = await contract.methods.redeem().send({from: accounts[0]});
    console.log(redeemBet);
  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <h1>All Or Nothing Ether Bet</h1>
        <p>Your account:{this.state.accounts}</p>
        
        <div>
        
        <h1>{this.state.betDescription}</h1>
        
        {this.state.winningOutcome == 2 ? "UnResolved" :
        
        this.state.winningOutcome == 0 ?`resolved to ${this.state.outcomeADescription}` : `resolved to ${this.state.outcomeADescription}` 
       }
        
        
         <br></br>
        </div>

        <form onSubmit={this.placeBet}>
        <label>
         How much Ether do you wanna Bet?
          <input type="text" value={this.state.betValue} onChange={this.handleChange} />
        </label>
      </form>
      
        
        <h2>On which Outcome?</h2>
    
      <button onClick={() => this.placeBet(this.state.outcomeA)}>{this.state.outcomeADescription}</button>
      <button onClick={() => this.placeBet(this.state.outcomeB)}>{this.state.outcomeBDescription}</button>

        <div>
         <br></br>
        </div>

        <div>
        <p>{this.state.outcomeADescription} : {this.state.outcomeATotal}</p>
        <p>{this.state.outcomeBDescription} : {this.state.outcomeBTotal}</p>
        </div>
        
        <div>
          <button onClick={this.withdrawUnmatchedBets}>Withdraw Unmatched Bets</button>
        </div>

    
        <div id="resolve">
        <form onSubmit={this.resolveBet}>
        <label>
          How should this Bet Resolve?
          <select value={this.state.resolveValue} onChange={this.handleSelectorChange}>
            <option value={0}>{this.state.outcomeADescription}</option>
            <option value={1}>{this.state.outcomeBDescription}</option>
          </select>
        </label>
        <input type="submit" value="Submit" />
      </form>
      </div>

      <div id="redeem">
        <button onClick={this.redeemBet}>Redeem Winnings</button>
      </div>
        
    
      </div>
    );
  } 
}

export default App;
