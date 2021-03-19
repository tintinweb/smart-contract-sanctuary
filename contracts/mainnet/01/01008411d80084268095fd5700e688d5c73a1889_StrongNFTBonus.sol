//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./ServiceInterface.sol";
import "./IERC1155Preset.sol";
import "./SafeMath.sol";
import "./Context.sol";

contract StrongNFTBonus is Context {

  using SafeMath for uint256;

  event Staked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);
  event Unstaked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);

  ServiceInterface public service;
  IERC1155Preset public nft;

  bool public initDone;

  address public serviceAdmin;
  address public superAdmin;

  string[] public nftBonusNames;
  mapping(string => uint256) public nftBonusLowerBound;
  mapping(string => uint256) public nftBonusUpperBound;
  mapping(string => uint256) public nftBonusValue;

  mapping(uint256 => uint256) public nftIdStakedForNodeId;
  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftId;
  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftBlock;

  function init(address serviceContract, address nftContract, address serviceAdminAddress, address superAdminAddress) public {
    require(initDone == false, "init done");

    serviceAdmin = serviceAdminAddress;
    superAdmin = superAdminAddress;
    service = ServiceInterface(serviceContract);
    nft = IERC1155Preset(nftContract);
    initDone = true;
  }

  function isNftStaked(uint256 _tokenId) public view returns (bool) {
    return nftIdStakedForNodeId[_tokenId] != 0;
  }

  function getNftStakedForNodeId(uint256 _tokenId) public view returns (uint256) {
    return nftIdStakedForNodeId[_tokenId];
  }

  function getStakedNftId(address _entity, uint128 _nodeId) public view returns (uint256) {
    return entityNodeStakedNftId[_entity][_nodeId];
  }

  function getStakedNftBlock(address _entity, uint128 _nodeId) public view returns (uint256) {
    return entityNodeStakedNftBlock[_entity][_nodeId];
  }

  function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
    uint256 nftId = entityNodeStakedNftId[_entity][_nodeId];

    if (nftId == 0) return 0;
    if (nftId < nftBonusLowerBound["BRONZE"]) return 0;
    if (nftId > nftBonusUpperBound["BRONZE"]) return 0;
    if (nft.balanceOf(_entity, nftId) == 0) return 0;
    if (_fromBlock >= _toBlock) return 0;

    uint256 stakedAtBlock = entityNodeStakedNftBlock[_entity][_nodeId];

    if (stakedAtBlock == 0) return 0;

    uint256 startFromBlock = stakedAtBlock > _fromBlock ? stakedAtBlock : _fromBlock;

    if (startFromBlock >= _toBlock) return 0;

    return _toBlock.sub(startFromBlock).mul(nftBonusValue["BRONZE"]);
  }

  function stakeNFT(uint256 _tokenId, uint128 _nodeId) public payable {
    require(nft.balanceOf(_msgSender(), _tokenId) != 0, "not enough");
    require(_tokenId >= nftBonusLowerBound["BRONZE"] && _tokenId <= nftBonusUpperBound["BRONZE"], "not eligible");
    require(nftIdStakedForNodeId[_tokenId] == 0, "already staked");
    require(service.doesNodeExist(_msgSender(), _nodeId), "node doesnt exist");

    nftIdStakedForNodeId[_tokenId] = _nodeId;
    entityNodeStakedNftId[_msgSender()][_nodeId] = _tokenId;
    entityNodeStakedNftBlock[_msgSender()][_nodeId] = block.number;

    emit Staked(msg.sender, _tokenId, _nodeId, block.number);
  }

  function unStakeNFT(uint256 _tokenId, uint128 _nodeId, uint256 _blockNumber) public payable {
    require(nft.balanceOf(_msgSender(), _tokenId) != 0, "not enough");
    require(nftIdStakedForNodeId[_tokenId] == _nodeId, "not this node");

    service.claim{value : msg.value}(_nodeId, _blockNumber, false);

    nftIdStakedForNodeId[_tokenId] = 0;
    entityNodeStakedNftId[_msgSender()][_nodeId] = 0;
    entityNodeStakedNftBlock[_msgSender()][_nodeId] = 0;

    emit Unstaked(msg.sender, _tokenId, _nodeId, _blockNumber);
  }

  function updateBonus(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint256 _value) public {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    bool alreadyExit = false;
    for (uint i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExit = true;
      }
    }

    if (!alreadyExit) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusValue[_name] = _value;
  }

  function updateContracts(address serviceContract, address nftContract) public {
    require(msg.sender == superAdmin, "not admin");
    service = ServiceInterface(serviceContract);
    nft = IERC1155Preset(nftContract);
  }

  function updateServiceAdmin(address newServiceAdmin) public {
    require(msg.sender == superAdmin, "not admin");
    serviceAdmin = newServiceAdmin;
  }
}