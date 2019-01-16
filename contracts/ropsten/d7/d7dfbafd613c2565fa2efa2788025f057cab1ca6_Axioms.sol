pragma solidity ^0.4.25;

contract Token {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address receiver)public returns(uint);
}

///@title Axioms-Airdrops
///@author  Lucasxhy & Kafcioo
contract Axioms {
    Airdrop [] public airdrops;
    address owner;
    uint idCounter;

    ///@notice  Set the creator of the smart contract to be its sole owner
    constructor () public {
        owner = msg.sender;
    }

    ///@notice  Modifier to require a minimum amount fo ether for the function to launch
    modifier minEth {
        require(msg.value >= 1000000000); //Change this to amount of eth we want in GWEI!
        _;
    }
    
    ///@notice  Modifier that only allows the owner to execute a function
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    ///@notice  Creates a structure for airdrops, which stores all the necessary information for users to look up the history effectively and directly from the smart contract.
    struct Airdrop {
        uint id;
        uint tokenAmount;
        string name;
        uint countDown;
        address distributor;
        Token tokenSC;
    }

    ///@notice  Adds a new airdrop to the smart contract and starts the count down until it is distributed
    function addNewAirdrop(
      uint _tokenAmount,
      string _name,
      address  _smartContract
    )
      public
      payable
      minEth
    { 
      uint lastIndex = airdrops.length++;
      Airdrop storage airdrop = airdrops[lastIndex];
      airdrop.id = idCounter;
      airdrop.tokenAmount = _tokenAmount;
      airdrop.name = _name;
      airdrop.distributor = msg.sender;
      airdrop.tokenSC = Token(_smartContract);
      idCounter = airdrop.id+1;
   }

    ///@notice  Distirbutes a differen quantity of tokens to all the specified addresses.
    ///@dev Distribution will only occur when a distribute function is called, and passed the correct parameters, it is not the smart contracts job to produce the addresses or determine the ammounts
    ///@param index  The airdrop to distribute based in the the array in which is saved
    ///@param _addrs The set of addresses in array form, to which the airdrop will be distributed
    ///@param _vals  The set of values to be distributed to each address in array form.
    function distributeVariable(
        uint index,
        address[] _addrs,
        uint[] _vals
    )
        public
        onlyOwner
    {
      if(timeGone(index)==true && getTokensBalance(index)>= airdrop.tokenAmount) {
        Airdrop memory airdrop = airdrops[index];
        for(uint i = 0; i < _addrs.length; ++i) {
            airdrop.tokenSC.transfer(_addrs[i], _vals[i]);
        }
      } else revert("Airdrop was NOT distributed");
    }

    ///@notice  Distirbutes a constant quantity of tokens to all the specified addresses.
    ///@dev Distribution will only occur when a distribute function is called, and passed the correct parameters, it is not the smart contracts job to produce the addresses or determine the ammount
    ///@param index  The airdrop to distribute based in the the array in which is saved
    ///@param _addrs The set of addresses in array form, to which the airdrop will be distributed
    ///@param _amoutToEach  The value to be distributed to each address in array form.
    function distributeFixed(
        uint index,
        address[] _addrs,
        uint _amoutToEach
    )
        public
        onlyOwner
    {
        if(timeGone(index)==true && getTokensBalance(index)>= airdrop.tokenAmount) {
          Airdrop memory airdrop = airdrops[index];
          for(uint i = 0; i < _addrs.length; ++i) {
           airdrop.tokenSC.transfer(_addrs[i], _amoutToEach);
           }
        } else revert("AirDrop was NOT added");
    }

    ///@notice  Distributes a constant quantity of tokens to all the specified addresses.
    ///@dev Distribution will only occur when a distribute function is called, and passed the correct parameters, it is not the smart contracts job to produce the addresses or determine the ammount
    ///@param index The airdrop token to withdraw based in the the array in which is saved
    ///@param _amount  The amount to be withdrawn from the smart contract
    function withdrawTokens(
        uint index,
        uint _amount
    )
        public
        onlyOwner
    {
      Airdrop memory airdrop = airdrops[index];
      airdrop.tokenSC.transfer(owner,_amount);
    }

    ///@notice  Get the balance of a specific token within the smart contracts
    function getTokensBalance(uint index) private view returns(uint) {
      Airdrop memory airdrop = airdrops[index];
      Token t = Token(airdrop.tokenSC);
      return (t.balanceOf(this));
    }
        

    ///@notice  Determines whether an aidrop is due to be distributed or not.
    ///@dev Distribution will only occur when a distribute function is called, and passed the correct parameters, it is not the smart contracts job to produce the addresses or determine the ammount
    function timeGone(uint index) public view returns(bool) {
        Airdrop memory airdrop = airdrops[index];
        uint timenow=now;
        if ( airdrop.countDown <timenow){
          return (true);
        }else return (false);
    }
}