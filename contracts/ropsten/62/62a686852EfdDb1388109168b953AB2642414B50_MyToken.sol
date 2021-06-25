/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract MyToken {
    address payable private immutable owner;
    string public constant name = "MyToken";
    string public constant symbol = "MTKN";
    uint8 public immutable decimals = 8;
    uint256 public totalSupply = 0;
    uint public rate = 1;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier canSend(
        address from,
        address to,
        uint256 value
    ) {
        require(
            balances[msg.sender] >= value &&
                balances[to] + value >= balances[to],
            "Balance value lower than the requested amount!"
        );
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    event Transfer(address from, address to, uint256 value);
    event Approval(address from, address spender, uint256 value);

    constructor() {
        owner = payable(msg.sender);
    }

    function mint(address adr, uint256 quantity) public payable isOwner {
        totalSupply += quantity;
        balances[adr] += quantity;
    }

    function balanceOf(address adr) public view returns (uint256) {
        return balances[adr];
    }

    function balanceOf() public view returns (uint256) {
        return balances[msg.sender];
    }

    function transfer(address to, uint256 value)
        public
        payable
        canSend(msg.sender, to, value)
        returns (bool)
    {
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public payable canSend(from, to, value) returns (bool) {
        require(allowed[msg.sender][from] >= value);
        balances[to] += value;
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, value);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        payable
        returns (bool)
    {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address from, address spender)
        public
        view
        returns (uint256)
    {
        return allowed[from][spender];
    }
    
    function setRate(uint _rate) public payable isOwner returns(bool){
        rate = _rate;
        return true;
    }
    
    function buy() public payable returns(bool) {
        uint value = msg.value * rate * 100000000;
        owner.transfer(msg.value);
        return transferFrom(owner, msg.sender, value);
    }
}