/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity >=0.5.0 <0.6.0;

contract NFTRegistryLike {
    function ownerOf(uint256 tokenId) public view returns (address);
    function data(uint tokenID) public view returns (address, uint, bytes32, uint64);
}

contract NFTUpdateLike {
    function update(bytes32 nftID, uint value, uint risk) public;
    function file(bytes32 name, bytes32 nftID, uint maturityDate) public;
}

contract NFTOracle {
    bytes32 public fingerprint;

    // mapping (owners => uint);
    mapping (address => uint) public wards;

    // mapping (token holders)
    mapping (address => uint) public tokenHolders;

    // mapping (nftID => loanData);
    mapping (uint => NFTData) public nftData;

    // nft registry that holds the metadata for each nft
    NFTRegistryLike public registry;

    // nft update that holds the value of NFT's risk and value
    NFTUpdateLike public nftUpdate;

    struct NFTData {
        uint80 riskScore;
        uint128 value;
        uint64 maturityDate;
        uint48 timestamp;
    }

    event NFTValueUpdated(uint indexed tokenID);

    constructor (
        address _nftUpdate,
        address _registry,
        bytes32 _fingerprint,
        address _ward,
        address[] memory _tokenHolders) public {

        fingerprint = _fingerprint;
        registry = NFTRegistryLike(_registry);
        nftUpdate = NFTUpdateLike(_nftUpdate);

        // update nft token holders
        uint i;
        for (i=0; i<_tokenHolders.length; i++) {
            tokenHolders[_tokenHolders[i]] = 1;
        }

        // add the creator to auth
        wards[_ward] = 1;
        wards[msg.sender] = 1;
    }

    function rely(address usr) public auth { wards[usr] = 1; }
    function deny(address usr) public auth { wards[usr] = 0; }
    function relyTokenHolder(address usr) public auth { tokenHolders[usr] = 1; }
    function denyTokenHolder(address usr) public auth { tokenHolders[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
    modifier authToken(uint token) {
        require(tokenHolders[registry.ownerOf(token)] == 1, "oracle/token owner not allowed");
        _;
    }

    function depend(address _nftUpdate) public auth {
        nftUpdate = NFTUpdateLike(_nftUpdate);
    }

    function update(uint tokenID, bytes32 _fingerprint, bytes32 _result) public authToken(tokenID) {
        require(fingerprint == _fingerprint, "oracle/fingerprint mismatch");
        (uint80 risk, uint128 value) = getRiskAndValue(_result);
        (, , , uint64 maturityDate) = registry.data(tokenID);
        nftData[tokenID] = NFTData(risk, value, maturityDate, uint48(block.timestamp));

        // pass value to NFT update
        bytes32 nftID = keccak256(abi.encodePacked(address(registry), tokenID));
        nftUpdate.update(nftID, uint(value), uint(risk));
        nftUpdate.file("maturityDate",nftID,uint(maturityDate));
        emit NFTValueUpdated(tokenID);
    }

    function getRiskAndValue(bytes32 _result) public pure returns (uint80, uint128) {
        bytes memory riskb = sliceFromBytes32(_result, 0, 16);
        bytes memory valueb = sliceFromBytes32(_result, 16, 32);
        return (uint80(toUint128(riskb)), toUint128(valueb));
    }

    function sliceFromBytes32(bytes32 data, uint start, uint end) internal pure returns (bytes memory) {
        bytes memory res = new bytes(end -start);
        for (uint i=0; i< end -start; i++){
            res[i] = data[i+start];
        }
        return res;
    }

    function toUint128(bytes memory _bytes) internal pure returns (uint128) {
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), 0))
        }

        return tempUint;
    }
}