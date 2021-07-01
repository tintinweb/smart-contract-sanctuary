/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.4.19;

contract ERC20Interface {
function totalSupply() public constant returns (uint);

function balanceOf(address tokenOwner) public constant returns (uint balance);

function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

function transfer(address to, uint tokens) public returns (bool success);

function approve(address spender, uint tokens) public returns (bool success);

function transferFrom(address from, address to, uint tokens) public returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract hodlForYouContractV3 {

event Hodl(address indexed hodler, address token, uint  amount);

event PanicSell(address indexed hodler, address token, uint  amount, uint timediff);

event Withdrawal(address indexed hodler, address token, uint  amount);


 mapping ( address => uint256 ) public balances;




function hodl(address token, string tokenSymbol, uint256 amount) {



    ERC20Interface(token).approve(msg.sender, amount);
    balances[msg.sender]+= amount;
    
    ERC20Interface(token).transfer(this, amount);


}







}