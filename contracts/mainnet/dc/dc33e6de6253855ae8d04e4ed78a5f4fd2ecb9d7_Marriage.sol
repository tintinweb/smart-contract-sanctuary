pragma solidity ^0.4.24;
/**
 * Marriage
 * Copyright (c) 2018 MING-CHIEN LEE
 */
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract Marriage is owned {
    // Marriage data variables
    bytes32 public partner1;
    bytes32 public partner2;
    uint256 public marriageDate;
    bytes32 public marriageStatus;
    bytes public imageHash;
    bytes public marriageProofDoc;
    
    constructor() public {
        createMarriage();
    }

    // Create initial marriage contract
    function createMarriage() onlyOwner public {
        partner1 = "Edison Lee";
        partner2 = "Chino Kafuu";
        marriageDate = 1527169003;
        setStatus("Married");
        bytes32 name = "Marriage Contract Creation";
        
        majorEventFunc(marriageDate, name, "We got married!");
    }
    
    // Set the marriage status if it changes
    function setStatus(bytes32 status) onlyOwner public {
        marriageStatus = status;
        majorEventFunc(block.timestamp, "Changed Status", status);
    }
    
    // Set the IPFS hash of the image of the couple
    function setImage(bytes IPFSImageHash) onlyOwner public {
        imageHash = IPFSImageHash;
        majorEventFunc(block.timestamp, "Entered Marriage Image", "Image is in IPFS");
    }
    
    // Upload documentation for proof of marrage like a marriage certificate
    function marriageProof(bytes IPFSProofHash) onlyOwner public {
        marriageProofDoc = IPFSProofHash;
        majorEventFunc(block.timestamp, "Entered Marriage Proof", "Marriage proof in IPFS");
    }

    // Log major life events
    function majorEventFunc(uint256 eventTimeStamp, bytes32 name, bytes32 description) public {
        emit MajorEvent(block.timestamp, eventTimeStamp, name, description);
    }

    // Declare event structure
    event MajorEvent(uint256 logTimeStamp, uint256 eventTimeStamp, bytes32 indexed name, bytes32 indexed description);
    
    // This function gets executed if a transaction with invalid data is sent to
    // the contract or just ether without data. We revert the send so that no-one
    // accidentally loses money when using the contract.
    function () public {
        revert();
    }
}