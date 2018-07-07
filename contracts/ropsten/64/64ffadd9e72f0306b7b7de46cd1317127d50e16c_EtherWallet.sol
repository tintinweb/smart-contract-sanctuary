pragma solidity ^0.4.24;
contract EtherWallet {
    address public owner;
    uint public releaseId;
    bytes private author;
    event Received(address indexed _from, uint256 _value);
    event Sent(address indexed _to, uint256 _value);
    constructor() public {
        owner = msg.sender;
        releaseId = 1;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public admin returns(bool success) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function addAuthor(bytes hexString) public admin returns(bool success) {
        require(hexString.length >= 4 && author.length == 0);
        author = hexString;
        return true;
    }
    function Author() public view returns(string) {
        return string(author);
    }
    function() public payable {
        require(msg.value >= 1000000000 && msg.data.length == 0);
        emit Received(msg.sender, msg.value);
    }
    function sendTo(address to, uint256 value) public admin returns(bool success) {
        require(to != address(0) && value >= 1000000000 && address(this).balance >= value);
        to.transfer(value);
        emit Sent(to, value);
        return true;
    }
}