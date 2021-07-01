/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.4.19;

contract IERC20Token {
function totalSupply() public constant returns (uint);

function balanceOf(address tokenOwner) public constant returns (uint balance);

function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

function transfer(address to, uint tokens) public returns (bool success);

function approve(address spender, uint tokens) public returns (bool success);

function transferFrom(address from, address to, uint tokens) public returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Escrow {


    IERC20Token public tokencontract;

    constructor(IERC20Token tokenaddress) public {
        tokencontract=tokenaddress;
    }

    mapping(address => mapping(address => uint256)) public escrowBalance;


    function deposit(uint256 amount) public {
        require(tokencontract.transferFrom(msg.sender, this, amount));
        escrowBalance[msg.sender][tokencontract] += amount;

    }




    function withdraw() public {
       

        uint256 amount = escrowBalance[msg.sender][tokencontract];
        escrowBalance[msg.sender][tokencontract] = 0;
        require(tokencontract.transfer(msg.sender, amount));
    }

    function transfer(
        address from,
        address to,
        IERC20Token token,
        uint256 tokens
    )
        internal
    {
        require(escrowBalance[from][token] >= tokens, "Insufficient balance.");

        escrowBalance[from][token] -= tokens;
        escrowBalance[to][token] += tokens;
    }
}