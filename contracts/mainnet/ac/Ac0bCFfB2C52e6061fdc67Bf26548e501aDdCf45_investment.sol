pragma solidity ^0.4.18;

contract BCSToken {
    
    function BCSToken() internal {}
    function transfer(address _to, uint256 _value) public {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract investment{
    using SafeMath for uint;
    
    address public owner;
    mapping (address => uint) private amount;
    mapping (address => uint) private day;
    mapping (address => uint) private dateDeposit;
    mapping (address => uint) private rewardPerYear;
    mapping (address => uint) private outcome;
    
    struct a{
        uint aday;
        uint adateDeposit;
        uint aamount;
    }
    BCSToken dc;
    function investment(address _t) public {
        dc = BCSToken(_t);
        owner = msg.sender;
    }
    function Datenow () public view returns (uint timeNow){
        return block.timestamp;
    }
    
    
    function calculate(address _user) private returns (bool status) {
        uint _amount =amount[_user];
        uint _day =day[_user];
        uint _rewardPerYear = 1000;


        if(_day == 90 && _amount >= SafeMath.mul(1000000,10**8)){
            _rewardPerYear = 180;
        }else if(_day == 60 && _amount >= SafeMath.mul(1000000,10**8)){
            _rewardPerYear = 160;
        }else if(_day == 90 && _amount >= SafeMath.mul(800000,10**8)){
            _rewardPerYear = 140;
        }else if(_day == 60 && _amount >= SafeMath.mul(800000,10**8)){
            _rewardPerYear = 120;
        }else if(_day == 90 && _amount >= SafeMath.mul(500000,10**8)){
            _rewardPerYear = 100;
        }else if(_day == 60 && _amount >= SafeMath.mul(500000,10**8)){
            _rewardPerYear = 80;
        }else if(_day == 90 && _amount >= SafeMath.mul(300000,10**8)){
            _rewardPerYear = 60;
        }else if(_day == 60 && _amount >= SafeMath.mul(300000,10**8)){
            _rewardPerYear = 40;
        }else if(_day == 30 && _amount >= SafeMath.mul(50001,10**8)){
            _rewardPerYear = 15;
        }else if(_day == 60 && _amount >= SafeMath.mul(50001,10**8)){ 
            _rewardPerYear = 25;
        }else if(_day == 90 && _amount >= SafeMath.mul(50001,10**8)){
            _rewardPerYear = 45;
        }else if(_day == 30 && _amount >= SafeMath.mul(10001,10**8)){
            _rewardPerYear = 5;
        }else if(_day == 60 && _amount >= SafeMath.mul(10001,10**8)){
            _rewardPerYear = 15;
        }else if(_day == 90 && _amount >= SafeMath.mul(10001,10**8)){
            _rewardPerYear = 25;
        }else{
            return false;
        }
        
        rewardPerYear[_user]=_rewardPerYear;
        outcome[_user] = SafeMath.add((SafeMath.div(SafeMath.mul(SafeMath.mul((_amount), rewardPerYear[_user]), _day), 365000)), _amount);
        return true;
    }
    
    function _withdraw(address _user) private returns (bool result){
        
        require(timeLeft(_user) == 0);
        dc.transfer(_user, outcome[_user]);
        amount[_user] = 0;
        day[_user] = 0;
        dateDeposit[_user] = 0;
        rewardPerYear[_user] = 0;
        outcome[_user] = 0;
        return true;
    }
    
    function timeLeft(address _user) view private returns (uint result){
        
        uint temp = SafeMath.add(SafeMath.mul(SafeMath.mul(SafeMath.mul(60,60),24),day[_user]),dateDeposit[_user]); // for mainnet (day-month)
        if(now >= temp){
            return 0;
        }else{
            return SafeMath.sub(temp,now);
        }
    }
    
    function deposit(uint _amount, uint _day) public returns (bool result){
        require(amount[msg.sender]==0);
        require(( _day == 90 || _day == 60 || _day == 30));
        require(_amount >= SafeMath.mul(10001,10**8));
        dc.transferFrom(msg.sender, this, _amount);
        amount[msg.sender] = _amount;
        day[msg.sender] = _day;
        dateDeposit[msg.sender] = now;
        calculate(msg.sender);
        return true;
    }
    function withdraw(address _user) public returns (bool result) {
        require(owner == msg.sender);
        return _withdraw(_user);
        
    }
    
    function withdraw() public returns (bool result){
        return _withdraw(msg.sender);
    }
    
    function info(address _user) public view returns (uint principle, uint secondLeft, uint annualized, uint returnInvestment, uint packetDay, uint timestampDeposit){
        return (amount[_user],timeLeft(_user),rewardPerYear[_user],outcome[_user],day[_user],dateDeposit[_user] );
    }

}