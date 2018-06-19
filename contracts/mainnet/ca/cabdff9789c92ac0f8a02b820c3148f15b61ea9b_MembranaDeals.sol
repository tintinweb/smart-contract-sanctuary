pragma solidity ^0.4.15;

contract MembranaDeals {
  address public be = 0x873A2832898b17b5C12355769A7E2DAe6c2f92f7;
  enum state { paid, verified, halted, finished}
  enum currencyType { USDT, BTC, ETH}
  struct Deal {
    state  currentState;
    uint  start;
    uint  deadline;
    uint  maxLoss;
    uint  startBalance;
    uint  targetBalance;
    uint  amount;
    currencyType  currency;
    string  investor;
    address  investorAddress;
    string  trader;
    address  traderAddress;
  }
  Deal[] public deals;
  function MercatusDeals() public payable{
    revert();
  }
  modifier onlyBe() {
   require(msg.sender == be);
   _;
 }
  modifier inState(uint dealId, state s) {
   require(deals[dealId].currentState == s);
   _;
 }
 function getState(uint dealId) public constant returns (uint)  {
   return uint(deals[dealId].currentState);
 }
 function getStart(uint dealId) public constant returns (uint)  {
   return deals[dealId].start;
 }
 function setVerified(uint dealId) public  onlyBe inState(dealId, state.paid) {
     deals[dealId].currentState = state.verified;
}

 function setHalted(uint dealId) public  onlyBe {
     require(deals[dealId].currentState == state.paid || deals[dealId].currentState == state.verified);
     require(deals[dealId].amount != 0);
     deals[dealId].traderAddress.transfer(deals[dealId].amount);
     deals[dealId].amount = 0;
     deals[dealId].currentState = state.halted;
}
function getSplit(uint finishAmount, uint startBalance, uint targetBalance, uint amount) public pure returns (uint) {
    return ((finishAmount - startBalance) * amount) / ((targetBalance - startBalance) );
}
 function setFinished(uint dealId, uint finishAmount) public  onlyBe inState(dealId, state.verified) {
     require(deals[dealId].amount != 0);
     if(finishAmount <= deals[dealId].startBalance){
       deals[dealId].investorAddress.transfer(deals[dealId].amount);
     }else if(finishAmount>deals[dealId].targetBalance){
       deals[dealId].traderAddress.transfer(deals[dealId].amount);
     }
     else{
        uint split = getSplit(finishAmount, deals[dealId].startBalance, deals[dealId].targetBalance, deals[dealId].amount);
        deals[dealId].traderAddress.transfer(split);
        deals[dealId].investorAddress.transfer(deals[dealId].amount - split);
     }
     deals[dealId].amount = 0;
     deals[dealId].currentState = state.finished;
}
    function getDealsCount() public constant returns (uint){
        return deals.length;
    }
function () external payable  {
  revert();
}
    function makeDeal(uint _duration, uint _maxLoss, uint _startBalance, uint _targetBalance, uint _amount,  string _investor, address _investorAddress, string _trader, address _traderAddress, uint offer, uint _currency)
    payable public {
      require( _currency >= 0 &&  _currency < 3  );
      require(msg.value == _amount);
        deals.push(Deal({
            currentState: state.paid,
            start: now,
            deadline: 0,
            maxLoss: _maxLoss,
            startBalance: _startBalance,
            targetBalance: _targetBalance,
            amount: _amount,
            currency: currencyType(_currency),
            investor: _investor,
            investorAddress: _investorAddress,
            trader: _trader,
            traderAddress: _traderAddress
          }));
          deals[deals.length-1].deadline = now +  _duration * 86400;
        spawnInstance(msg.sender,deals.length-1, now, offer);
    }
    event spawnInstance(address indexed from, uint indexed dealId, uint start, uint offer);
}