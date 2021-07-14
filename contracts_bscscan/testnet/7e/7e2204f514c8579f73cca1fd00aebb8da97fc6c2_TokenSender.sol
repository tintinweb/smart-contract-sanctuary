/**
 *Submitted for verification at BscScan.com on 2021-07-14
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

contract TokenSender{
   using SafeMath for uint256;
   ERC20 token; 
   address payable owner;
   
   event MultiSend(uint256 value , address indexed sender);
   event Deposit(uint256 value , address indexed sender);
  
   modifier onlyOwner(){
        require(msg.sender == owner,"You are not authorized owner.");
        _;
   }
   
   constructor() public {
       owner = msg.sender;
       token  = ERC20(0x3AD53Eb310bC6061baa62D900E6953601Dc90E5c);
   }

   function deposit() public payable{
        
        token.transferFrom(msg.sender, address(this), msg.value);
        emit Deposit(msg.value, msg.sender);
   }
  
   function multisendEther(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            token.transferFrom(address(msg.sender),_contributors[i],_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
    }

    function withdraw(address payable _address, uint _amount) external onlyOwner{
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