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
    uint256 public escrowTime;

    constructor(uint256 _escrowTime) public {
        escrowTime = _escrowTime;
    }

    mapping(address => mapping(address => uint256)) public escrowBalance;
    mapping(address => mapping(address => uint256)) public escrowExpiration;

    function deposit(IERC20Token token, uint256 amount) public {
        require(token.transferFrom(msg.sender, this, amount));
        escrowBalance[msg.sender][token] += amount;
        escrowExpiration[msg.sender][token] = 2**256-1;
    }

    event StartWithdrawal(address indexed account, address token, uint256 time);

    function startWithdrawal(IERC20Token token) public {
        uint256 expiration = now + escrowTime;
        escrowExpiration[msg.sender][token] = expiration;
        emit StartWithdrawal(msg.sender, token, expiration);
    }

    function withdraw(IERC20Token token) public {
        require(now > escrowExpiration[msg.sender][token],
            "Funds still in escrow.");

        uint256 amount = escrowBalance[msg.sender][token];
        escrowBalance[msg.sender][token] = 0;
        require(token.transfer(msg.sender, amount));
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