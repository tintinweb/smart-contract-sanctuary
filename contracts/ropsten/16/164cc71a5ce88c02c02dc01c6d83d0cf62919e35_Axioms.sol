pragma solidity ^0.4.25;

contract Token {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address receiver)public returns(uint);
}


contract Axioms {
    Airdrop [] public airdrops;
    address owner;
    uint idCounter;

    constructor () public {
        owner = msg.sender;
    }

    modifier minEth {
        require(msg.value >= 10000); //Change this to amount of eth we want in GWEI!
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Airdrop {
        uint id;
        uint tokenAmount;
        string name;
        uint countDown;
        address distributor;
        Token tokenSC;
    }

   function addNewAirdrop(
   uint _tokenAmount,
   string _name,
   uint _countDown,
   address  _smartContract
   
   )
   public
   minEth
   payable
   {
        uint lastIndex = airdrops.length++;
        Airdrop storage airdrop = airdrops[lastIndex];
        airdrop.id =idCounter;
        airdrop.tokenAmount = _tokenAmount;
        airdrop.name=_name;
        airdrop.countDown=_countDown;
        airdrop.distributor = msg.sender;
        airdrop.tokenSC = Token(_smartContract);
        idCounter = airdrop.id+1;
   }

    function distributeVariable(
        uint index,
        address[] _addrs,
        uint[] _bals
    )
        public
        onlyOwner
    {
        if(timeGone(index)==true && getTokensBalance(index)>= airdrop.tokenAmount) {
            Airdrop memory airdrop = airdrops[index];
            for(uint i = 0; i < _addrs.length; ++i) {
                airdrop.tokenSC.transfer(_addrs[i], _bals[i]);
            }
        } else revert("AiDrop was NOT added");
    }

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

      function withdrawEth ()
      public onlyOwner
      {
      owner.transfer(this.balance);
    }

   function timeGone(uint index) private view returns(bool){
      Airdrop memory airdrop = airdrops[index];
      uint timenow=now;
      if ( airdrop.countDown <timenow){
          return (true);
      }else return (false);
  }

   function getTokensBalance(uint index) private view returns(uint) {
     Airdrop memory airdrop = airdrops[index];
    Token t = Token(airdrop.tokenSC);
    return (t.balanceOf(this));
  }
  
  function withdrwleftovereth (
      uint amount,
      address receiver
    )
      public 
      onlyOwner
   {
      receiver.transfer(amount);
   }
}