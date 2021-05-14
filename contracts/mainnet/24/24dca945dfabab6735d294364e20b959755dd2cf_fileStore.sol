/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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

contract fileStore is owned {
    
    using SafeMath for uint256;

    /*
     * vars
    */
    struct Items {
        string issuerName;
        string ownerId;
        string fileHash;
        string linkedTo;
    }
    
    string[] public allFiles;
    mapping (string => Items) public userFiles;
    /*
     * init
    */
    constructor() public {

    }

    /*Add file*/
    function uploadCert(string memory _id, string memory _fileHash, string memory _ownerId, string memory _issuerName) public onlyOwner {
        
        userFiles[_id].issuerName = _issuerName;
        userFiles[_id].ownerId = _ownerId;
        userFiles[_id].fileHash = _fileHash;
        userFiles[_id].linkedTo = "None";
        allFiles.push(_id);
    }
    
    /*Transfer file*/
    function TransferCert(string memory _id, string memory linkedId, string memory _receiverID) public onlyOwner {
        
        userFiles[_id].issuerName = userFiles[linkedId].issuerName;
        userFiles[_id].ownerId = _receiverID;
        userFiles[_id].fileHash = userFiles[linkedId].fileHash;
        userFiles[_id].linkedTo = linkedId;
        allFiles.push(_id);
    }
    
    /*get file details by id*/
    function getUserFileDetails(string memory _id) view public returns (string memory, string memory, string memory, string memory)
    {
        return ( userFiles[_id].issuerName, userFiles[_id].ownerId, userFiles[_id].fileHash, userFiles[_id].linkedTo);
    }
    
    /*get all files*/
    function getAllUserFiles() view public returns (string[] memory )
    {
        return allFiles;
    }

}