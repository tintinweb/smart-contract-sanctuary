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

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier canSend(
        address from,
        address to,
        uint256 value
    ) {
        require(
            balances[from] >= value &&
                balances[to] + value >= balances[to],
            "Balance value lower than the requested amount!"
        );
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    modifier has_allowance(address _from, address spender, uint value){
        require(allowed[_from][spender] >= value, "Allowed value is lower than requested amount");
        _;
    }

    event Transfer(address _from, address to, uint256 value);
    event Approval(address _from, address spender, uint256 value);

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
        address _from,
        address to,
        uint256 value
    ) public payable canSend(_from, to, value) has_allowance(_from, address(this), value) returns (bool) {
        balances[to] += value;
        balances[_from] -= value;
        allowed[_from][msg.sender] -= value;
        emit Transfer(_from, to, value);
        emit Approval(_from, msg.sender, value);
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

    function allowance(address _from, address spender)
        public
        view
        returns (uint256)
    {
        return allowed[_from][spender];
    }
    
    function setRate(uint _rate) public payable isOwner returns(bool){
        rate = _rate;
        return true;
    }
    
    function buy() public payable returns(bool) {
        uint value = (msg.value / 1 ether) * rate * 100000000;
        transfer_mtkn(owner, msg.sender, value);
        owner.transfer(msg.value);
        return true;
    }
    
    function transfer_mtkn(address _from, address to, uint value) internal has_allowance(_from, address(this), value) returns(bool) {
        balances[to] += value;
        balances[_from] -= value;
        allowed[_from][address(this)] -= value;
        emit Transfer(_from, to, value);
        emit Approval(_from, address(this), value);
        return true;
    }
}