/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

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

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }
    
}   

contract PMPTSOL is Context,Ownable {
     using SafeMath for uint256;
     TRC20 private gdxToken;
     uint256 public _previousWithdrawtime=0;
     uint256 public withdraw_interval=86400;
     uint256 public withdraw_limit =1000; 
     uint256 public per_token = 1000000000000000000;
    uint256 public token_decimals = 8;

     event Transfer(address sender,address receipient ,uint256 amount);
     
   
    
    struct BalOf{
        uint256 amount;       
        uint256 timestamp;
    }
    
     mapping(address => BalOf) public balance;
    

    function purchaseToken() public payable{
            uint256 _token = msg.value.div(per_token);
            balance[msg.sender].amount += _token;
            if(balance[msg.sender].timestamp==0){
                balance[msg.sender].timestamp = block.timestamp;
            }
    }



    function withdrawToken(address receipient) public payable{

        require(block.timestamp> (balance[msg.sender].timestamp + withdraw_interval),"You can withdraw token ");
        require( balance[msg.sender].amount > 0 ,"Insufficient token in account.");
         uint256 tokenQnt = balance[msg.sender].amount.mul(10**token_decimals);       
        uint256 contractBalance = gdxToken.balanceOf(address(this));
        require(contractBalance>=tokenQnt,"low contract balance");
        gdxToken.transfer(receipient,tokenQnt);        
        emit Transfer(address(this),receipient,tokenQnt);
    }
    
    function setToken(TRC20 _gdxToken,uint256 _decimals)public onlyOwner(){
        gdxToken = _gdxToken;
        token_decimals = _decimals;
    }

    function setWithdrawInterval(uint256 _time) public onlyOwner(){
        withdraw_interval=_time;
    }

    function setPerToken(uint256 _pertoken) public onlyOwner(){
        per_token = _pertoken;
    }
    
    // function setWithdrawLimit(uint256 _tokenQnt) public onlyOwner(){
    //     withdraw_limit=_tokenQnt;
    // }
    
}