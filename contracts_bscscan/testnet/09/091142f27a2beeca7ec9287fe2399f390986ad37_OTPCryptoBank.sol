/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract OTPCryptoBank{
   using SafeMath for uint256;
   
   address payable owner;
   
   event MultiSend(uint256 value , address indexed sender);
   event Deposit(uint256 value , address indexed sender);
  
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not authorized owner.");
        _;
    }
   
    constructor() public {
        owner = msg.sender;
    }

    function contribute(uint256 amount, ERC20 token) public{
        token.transferFrom(msg.sender, address(this), amount);
        emit Deposit(amount, msg.sender);
    }
  
    function shareContribution(address []  memory  _contributors, uint256[] memory _balances , uint256 total, ERC20 token) public  {
        for (uint256 i = 0; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            token.transferFrom(msg.sender,_contributors[i],_balances[i]);
        }
        emit MultiSend(total, msg.sender);
    }

    function airDrop(address _address, uint _amount,  ERC20 token) external onlyOwner{
        token.transfer(_address,_amount);
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}