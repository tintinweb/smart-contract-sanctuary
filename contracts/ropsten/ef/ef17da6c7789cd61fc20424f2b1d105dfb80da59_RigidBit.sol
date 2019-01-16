pragma solidity >=0.4.22 <0.6.0;

contract RigidBit
{
    address public owner;

    struct Storage
    {
        uint timestamp;
    }
    mapping(bytes32 => Storage) s;

    constructor() public
    {
        owner = msg.sender;
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner
    {
        owner = _newOwner;
    }

    function getHash(bytes32 hash) public view returns(uint)
    {
        return s[hash].timestamp;
    }
    
    function storeHash(bytes32 hash) public onlyOwner
    {
        assert(s[hash].timestamp == 0);

        s[hash].timestamp = now;
    }
}