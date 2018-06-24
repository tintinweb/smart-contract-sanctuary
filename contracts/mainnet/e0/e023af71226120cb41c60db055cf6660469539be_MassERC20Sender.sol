pragma solidity ^0.4.21;

contract ERC20Interface {
    // function totalSupply() public constant returns (uint);
    // function balanceOf(address tokenOwner) public constant returns (uint balance);
    // function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    // function transfer(address to, uint tokens) public returns (bool success);
    // function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    // event Transfer(address indexed from, address indexed to, uint tokens);
    // event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MassERC20Sender   {
    address public owner;

    function MassERC20Sender() public{
        owner = msg.sender;
    }

    function multisend(ERC20Interface _tokenAddr, address[] dests, uint256[] values) public returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            _tokenAddr.transferFrom(msg.sender, dests[i], values[i]);
            i += 1;
        }
        return(i);
    }

    function withdraw() public{
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
}