// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NiftyBuilderMaster {
    
    //MODIFIERS
    
    modifier onlyOwner() {
      require((msg.sender) == contractOwner);
      _;
    }
    
    //CONSTANTS
    
    // how many nifties this contract is selling
    // used for metadat retrieval 
    uint public numNiftiesCurrentlyInContract;
    
    //id of this contract for metadata server
    uint public contractId;
    
    address public contractOwner;
    address public tokenTransferProxy;
    
    //multipliers to construct token Ids
    uint topLevelMultiplier = 100000000;
    uint midLevelMultiplier = 10000;
    
    //MAPPINGS
    
    //ERC20s that can mube used to pay
    mapping (address => bool) public ERC20sApproved;
    mapping (address => uint) public ERC20sDec;
    
    //CONSTRUCTOR FUNCTION
    constructor() {}
    
    function changeTokenTransferProxy(address newTokenTransferProxy) onlyOwner public {
        tokenTransferProxy = newTokenTransferProxy;
    }
    
    function changeOwnerKey(address newOwner) onlyOwner public {
        contractOwner = newOwner;
    }
    
    
    //functions to retrieve info from token Ids
    function getContractId(uint tokenId) public view returns (uint) {
        return (uint(tokenId/topLevelMultiplier));
    }
    
    function getNiftyTypeId(uint tokenId) public view returns (uint) {
        uint top_level = getContractId(tokenId);
        return uint((tokenId-(topLevelMultiplier*top_level))/midLevelMultiplier);
    }
    
    function getSpecificNiftyNum(uint tokenId) public view returns (uint) {
         uint top_level = getContractId(tokenId);
         uint mid_level = getNiftyTypeId(tokenId);
         return uint(tokenId - (topLevelMultiplier*top_level) - (mid_level*midLevelMultiplier));
    }
    
    function encodeTokenId(uint contractIdCalc, uint niftyType, uint specificNiftyNum) public view returns (uint) {
        return ((contractIdCalc * topLevelMultiplier) + (niftyType * midLevelMultiplier) + specificNiftyNum);
    }
    
      // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) public pure returns (string memory) {
      return string(abi.encodePacked(_a, _b, _c, _d, _e));
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) public pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) public pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) public pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}

