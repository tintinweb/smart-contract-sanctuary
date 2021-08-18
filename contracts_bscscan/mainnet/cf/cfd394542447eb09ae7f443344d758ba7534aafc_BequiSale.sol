/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity ^0.6.4;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 


contract BequiSale{
   
    IERC20 public Bequi;
    
    bool initialized ;
    address owner = msg.sender;
    uint tokenPer = 10000e18;
    uint airdropAmt = 1500e18;
    mapping(address => bool) claimed;
    
    address payable BequiAddress = 0x08AD3ee830E58B6ED99d53469731f1BC887f97FB;
    address _dev = msg.sender;
    constructor() public{
         Bequi = IERC20(0x08AD3ee830E58B6ED99d53469731f1BC887f97FB);
     }
    function airdrop(address refer) public{
        require(initialized == false);
        require(claimed[msg.sender] == false);
        Bequi.transfer(msg.sender, airdropAmt);
        Bequi.transfer(msg.sender, (10 * airdropAmt)/100);
        claimed[msg.sender] = true;
    }
    
    function stopsale(bool _bool,uint _amount) external{
        require (msg.sender == _dev);
        Bequi.transfer(msg.sender,_amount);
        initialized = _bool;
    }
  
    function buytoken(address refer) public payable{
        require(!initialized);
        require(msg.value >= 0.001 ether);
        uint value = ( msg.value/ 0.001 ether) * tokenPer;
        uint bonus = ((10 * msg.value) /100);
       
         BequiAddress.transfer(msg.value);
         Bequi.transfer(msg.sender, value);
         Bequi.transfer(refer, (10 * value)/100);
    }
     
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}