//SourceUnit: GDEXLOCK.sol

pragma solidity ^0.6.8;
// SPDX-License-Identifier: UNLICENSED
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface TRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
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
    
    

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
    
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 380 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}   

contract GDEXLOCK is Context,Ownable {
     using SafeMath for uint256;
     TRC20 private gdxToken;
     uint256 public _previousWithdrawtime=0;
     uint256 public withdraw_interval=86400;
     uint256 public withdraw_limit =1000; 
     event Transfer(address sender,address receipient ,uint256 amount);
     
    constructor(TRC20 _gdxToken) public {
        gdxToken = _gdxToken;
    }
    
    function withdrawToken(address receipient) public onlyOwner() payable{
        require(block.timestamp>getUnlockTime()," contract locked now !");
        require(_previousWithdrawtime+withdraw_interval<block.timestamp,"not completed 24 hours");
         uint256 tokenQnt=0;
        if(_previousWithdrawtime==0){
               tokenQnt = withdraw_limit.mul(10**8);
        }else{
          uint256 time=  block.timestamp-_previousWithdrawtime;
          tokenQnt =withdraw_limit.mul(time.div(withdraw_interval)).mul(10**8);
        }
        uint256 contractBalance =gdxToken.balanceOf(address(this));
        require(contractBalance>=tokenQnt,"low contract balance");
        gdxToken.transfer(receipient,tokenQnt);
        _previousWithdrawtime=block.timestamp;
        emit Transfer(address(this),receipient,tokenQnt);
    }
    
    function setWithdrawInterval(uint256 _time) public onlyOwner(){
        withdraw_interval=_time;
    }
    
    // function setWithdrawLimit(uint256 _tokenQnt) public onlyOwner(){
    //     withdraw_limit=_tokenQnt;
    // }
    
}