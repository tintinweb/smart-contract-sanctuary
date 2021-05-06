/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.5.0;

// import "http://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
// import "http://github.com/OpenZeppelin/openzeppelin-solidity/contracts/drafts/Counters.sol";


contract SnowDaqBuilderMaster {
    
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

    constructor() public { 
    }
    
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
    
    function getSnowDaqTypeId(uint tokenId) public view returns (uint) {
        uint top_level = getContractId(tokenId);
        return uint((tokenId-(topLevelMultiplier*top_level))/midLevelMultiplier);
    }
    
    function getSpecificSnowDaqNum(uint tokenId) public view returns (uint) {
         uint top_level = getContractId(tokenId);
         uint mid_level = getSnowDaqTypeId(tokenId);
         return uint(tokenId - (topLevelMultiplier*top_level) - (mid_level*midLevelMultiplier));
    }
    
    function encodeTokenId(uint contractIdCalc, uint snowDaqType, uint specificSnowDaqNum) public view returns (uint) {
        return ((contractIdCalc * topLevelMultiplier) + (snowDaqType * midLevelMultiplier) + specificSnowDaqNum);
    }
    
      // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) public view returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) public view returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) public view returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) public view returns (string memory) {
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
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

}