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
        partner1 = &quot;Edison Lee&quot;;
        partner2 = &quot;Chino Kafuu&quot;;
        marriageDate = 1526983200;
        setStatus(&quot;Married&quot;);
        bytes32 name = &quot;Marriage Contract Creation&quot;;
        
        majorEventFunc(marriageDate, name, &quot;We got married!&quot;);
    }
    
    // Set the marriage status if it changes
    function setStatus(bytes32 status) onlyOwner public {
        marriageStatus = status;
        majorEventFunc(block.timestamp, &quot;Changed Status&quot;, status);
    }
    
    // Set the IPFS hash of the image of the couple
    function setImage(bytes IPFSImageHash) onlyOwner public {
        imageHash = IPFSImageHash;
        majorEventFunc(block.timestamp, &quot;Entered Marriage Image&quot;, &quot;Image is in IPFS&quot;);
    }
    
    // Upload documentation for proof of marrage like a marriage certificate
    function marriageProof(bytes IPFSProofHash) onlyOwner public {
        marriageProofDoc = IPFSProofHash;
        majorEventFunc(block.timestamp, &quot;Entered Marriage Proof&quot;, &quot;Marriage proof in IPFS&quot;);
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