/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

interface IBEP20 {
  
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
 
  constructor ()  { }

  function _msgSender() internal view returns (address ) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

library SafeMath {
  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BitBookStake is Ownable{
    using SafeMath for uint256;
    
    IBEP20 public bitBookToken;
    uint256 stakeID = 0;
    uint256 public APYPcent;
    uint256 private APYdays = 365;
    
    struct User{
        uint256 amount;
        uint256 depositTime;
        uint256 ID;
        bool claim;
    }
    
    struct _StakeingId{
        uint256[] stakingId;
    }
    
    mapping(uint256 => mapping(uint256 => uint256))private getPercentage;
    mapping(address => mapping(uint256 => User))public userDetails;
    mapping(address => _StakeingId) stakings;
    
    event Deposit(address depositor, uint256 amount, uint256 stakeID);
    event SetPBEPentage(address owner,uint256 _from, uint256 _to, uint256 percentage);
    event Withdraw(address depositor,uint256 amount);
    event SetAPYPBEPent(address caller, uint256 Percentage);
    event Failsafe(address to, uint256 amount);
    
    constructor(IBEP20 _bitBookToken, uint256 APYpBEPent) {
        bitBookToken = _bitBookToken;
        APYPcent = APYpBEPent;
        //set fee percentage initially
        getPercentage[1][3] = 5e8;
        getPercentage[3][10] = 25e7;
        getPercentage[10][30] = 15e7;
        getPercentage[30][90] = 5e7;
    }
    
    function deposit(uint256 _amount)public {
        require(_amount > 0,"BitBook Stake: amount must greater than zero ");
        
        safeTransferFrom(msg.sender,address(this),_amount);
        
        userDetails[msg.sender][stakeID].amount = _amount;
        userDetails[msg.sender][stakeID].depositTime = block.timestamp;
        userDetails[msg.sender][stakeID].ID = stakeID;
        stakings[msg.sender].stakingId.push(stakeID);
        
        emit Deposit(msg.sender, _amount, stakeID);
        stakeID++;
    }
    
    function safeTransferFrom(address from, address to, uint256 amount)internal{
        bitBookToken.transferFrom(from,to,amount);
    }
    
    function safeTransfer(address _to,uint _amount)internal{
        bitBookToken.transfer(_to,_amount);
    }
    
    function setAPYpcent(uint256 _APYPercentage)public onlyOwner{
        APYPcent = _APYPercentage;
        emit SetAPYPBEPent(msg.sender, _APYPercentage);
    }
    
    function setFeePercentage(uint256 _from,uint256 _to, uint256 _pcent)public onlyOwner{
        require((_from == 1 && _to == 3) || (_from == 3 && _to == 10) || (_from == 10 && _to == 30) || (_from == 30 && _to == 90) ,"BitBook stake :: give correct days pair" );
        getPercentage[_from][_to] = _pcent;
        
        emit SetPBEPentage(msg.sender,_from, _to, _pcent);
    }
    
    function viewFeePercentage(uint256 _from,uint256 _to)public view returns(uint256){
        require((_from == 1 && _to == 3) || (_from == 3 && _to == 10) || (_from == 10 && _to == 30) || (_from == 30 && _to == 90) ,"BitBook stake :: give correct days pair" );
        return getPercentage[_from][_to];
    }
    
    function calculateReward(address _account , uint256 _stakerID)internal view returns(uint256){
        uint256 stakingDays = block.timestamp.sub(userDetails[_account][_stakerID].depositTime);
        uint256 APYpBEPent = APYPcent.mul(1e12).div(APYdays);  
        if(stakingDays > (APYdays * 86400)) { stakingDays = (APYdays * 86400); }
        return userDetails[_account][_stakerID].amount.mul(APYpBEPent).mul(stakingDays.div(86400)).div(100);
    }
    
    function calculateFee(address _account, uint256 _stakerID)public view returns(uint256 amount) {
        uint256 staketime = block.timestamp.sub(userDetails[_account][_stakerID].depositTime);
        
        if(259200 >= staketime ){
             amount = userDetails[_account][_stakerID].amount.mul(getPercentage[1][3]).div(1e8).div(100);
        }else if(864000 >= staketime ){
             amount = userDetails[_account][_stakerID].amount.mul(getPercentage[3][10]).div(1e8).div(100);
        }else if(2592000 >= staketime ){
             amount = userDetails[_account][_stakerID].amount.mul(getPercentage[10][30]).div(1e8).div(100);
        }else if(7776000 >= staketime ){
             amount = userDetails[_account][_stakerID].amount.mul(getPercentage[30][90]).div(1e8).div(100);
        }else{
             amount = 0;
        }
    }
    
    function withdraw(uint256 _stakerID)public{
        require(!userDetails[msg.sender][_stakerID].claim,"BitBook :: User already claimed");
        require(userDetails[msg.sender][_stakerID].depositTime != 0,"BitBook :: User not found");
        
        uint256 fee = calculateFee(msg.sender, _stakerID);
        uint256 Reward = calculateReward(msg.sender, _stakerID);
        uint256 amount = userDetails[msg.sender][_stakerID].amount.add(Reward.div(1e12)).sub(fee);
        
        safeTransfer(msg.sender,amount);
        userDetails[msg.sender][_stakerID].claim = true;
        
        emit Withdraw(msg.sender, amount);
    }
    
    function stakingId(address _staker) public view returns(uint256[] memory){
        return stakings[_staker].stakingId;
    }
    
    function failsafe(address _to,uint256 _amount) public onlyOwner{
        require(_to != address(0) && _amount != 0,"BitBook :: failsafe params error");
        safeTransfer(_to,_amount);
        
        emit Failsafe(_to,_amount);
    }
}