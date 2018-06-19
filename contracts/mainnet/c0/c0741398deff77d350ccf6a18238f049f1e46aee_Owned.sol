pragma solidity ^0.4.16;

contract IOwned {

    function owner() public pure returns (address) {
        
    }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    }

contract Owned is IOwned {
    address public owner;
    address public newOwner;
    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }


    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}