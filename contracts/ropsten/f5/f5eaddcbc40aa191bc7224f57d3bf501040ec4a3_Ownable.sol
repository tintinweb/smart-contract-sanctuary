pragma solidity 0.4.25;

contract EternalStorage 
{

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;
}

contract Ownable is EternalStorage {

    event OwnershipTransferred(address previousOwner, address NewOwner);

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }
    
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}