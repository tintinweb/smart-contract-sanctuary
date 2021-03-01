/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity ^0.6.12;
    
contract Ownable {
        
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

contract Storage is Ownable {
    
    
    mapping (string => string) public kitUser;
    mapping (string => bytes32[]) public kitHashes;
    
    event RegisterUserKitEvent(string indexed kitID, string indexed userID);
    event AddHashToKitEvent(string indexed kitID, bytes32 indexed hash);
    event DeleteHashEvent(string indexed kitID, bytes32 indexed hash);
    
    function registerUserKit(string calldata kitID, string calldata userID) external onlyOwner {
        kitUser[kitID] = userID;
        RegisterUserKitEvent(kitID, userID);
    }
    
    function addDocumentHashes(string calldata kitID, bytes32[] calldata hashes) external onlyOwner {
        for (uint i = 0; i < hashes.length; i++) {
            kitHashes[kitID].push(hashes[i]);
            AddHashToKitEvent(kitID, hashes[i]);
        }
    }
    
    function addDocumentHash(string calldata kitID, bytes32 hash) external onlyOwner {
        kitHashes[kitID].push(hash);
        AddHashToKitEvent(kitID, hash);
    }
    
    function deleteDocumentHash(string calldata kitID, bytes32  hash, uint index) external onlyOwner {
        uint length = kitHashes[kitID].length;

        if(hash == kitHashes[kitID][index]){
            delete kitHashes[kitID][index];
            kitHashes[kitID][index] = kitHashes[kitID][length - 1];
            delete kitHashes[kitID][length - 1];
            kitHashes[kitID].pop();
            DeleteHashEvent(kitID, hash);
        }
    }
}