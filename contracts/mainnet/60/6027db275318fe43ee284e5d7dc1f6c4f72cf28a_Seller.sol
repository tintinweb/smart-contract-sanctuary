pragma solidity ^0.4.19;

contract Token {
    function buyPrice() public view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}

contract Seller {
    address owner;
    Token token;

    function Seller() public {
        owner = address(0xbB428fBA097696556330704734dB9f2Ab00d4E32);
        token = Token(address(0x9bF393aFAc08096F8C7c9b9b932aFc106f65b615));
    }

    function kill() external {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function () public payable {
        require (msg.data.length == 0);
        token.transferFrom(owner, msg.sender, msg.value / token.buyPrice());
        owner.transfer(msg.value);
    }
}