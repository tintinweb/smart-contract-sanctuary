// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import './Address.sol';
import './Strings.sol';
import './ERC165.sol';
import './IERC1155.sol';
import './IERC1155MetadataURI.sol';
import './IERC1155Receiver.sol';
import './IERC721Metadata.sol';
import './Ownable.sol';
import './IERC2981.sol';
import './base64.sol';

contract UnauthorizedAuthentic is ERC165, IERC2981, IERC1155MetadataURI, Ownable {
  using Address for address;
  using Strings for uint256;

  string public constant name = "Unauthorized Authentic";
  string public constant symbol = "UA-NFT";
  address private constant outerpockets = 0xcB4B6bd8271B4f5F81d46CbC563ae9e4F97B5a37;

  uint256 public immutable startingPrice; // 20 ether
  uint256 public immutable endingPrice; // 0.1 ether
  uint256 public immutable auctionEnd; // block height at end
  uint256 public immutable auctionStart; // block height at start
  uint256 private immutable reductionRate;
  address private royaltyAddress;
  uint256 private royaltyPercentage; // in basis points

  mapping(address => mapping(address => bool)) private operatorApprovals;
  mapping(uint256 => TokenData) public tokens;
  address[] public factories;

  struct TokenData {
    address owner;
    uint32 factoryA;
    uint32 factoryB;
    uint32 factoryC;
  }

  event FactoryListing(address indexed factory, uint256 factoryIndex);
  event Sale(uint256 indexed tokenId, uint256 price);

  constructor(
    uint256 _startingPrice,
    uint256 _endingPrice,
    uint256 _auctionDuration
  ) {
    startingPrice = _startingPrice;
    endingPrice = _endingPrice;
    auctionEnd = _auctionDuration + block.number;
    auctionStart = block.number;
    reductionRate = (_startingPrice - _endingPrice) / _auctionDuration;
    updateRoyaltyAddress(outerpockets);
    updateRoyaltyPercentage(750);
    transferOwnership(outerpockets);
  }

  // CONTRACT METADATA
  
  function supportsInterface(bytes4 _interfaceId) public view override(ERC165, IERC165) returns (bool) {
    return
      _interfaceId == type(IERC1155).interfaceId ||
      _interfaceId == type(IERC1155MetadataURI).interfaceId ||
      _interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  function contractURI() external view returns (string memory) {
    return string(
      abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(
        abi.encodePacked(
          '{'
            '"name": "', name, '",'
            '"description": "**UNAUTHORIZED AUTHENTIC**\\n\\n'
            '\\"Unauthorized Authentics\\" are not simply \\"fakes\\" or \\"copies\\".'
            ' Their metadata is manufactured in the same contracts, by the same code,'
            ' producing the exact same bytes as the originals they replicate.'
            '\\n\\n`.a work by outerpockets.`",'
            '"image": "https://www.unauthedauth.com/default.png",'
            '"seller_fee_basis_points": ', royaltyPercentage.toString(), ','
            '"fee_recipient": "', uint256(uint160(royaltyAddress)).toHexString(20),'",'
            '"external_link": "https://www.unauthedauth.com/"'
          '}'
        ))
    ));
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
    return (
      royaltyAddress,
      _salePrice * royaltyPercentage / 10000
    );
  }

  function updateRoyaltyAddress(address _royaltyAddress) public onlyOwner {
    royaltyAddress = _royaltyAddress;
  }
  
  function updateRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner {
    royaltyPercentage = _royaltyPercentage;
  }

  // UA LOGIC

  function addFactory(address _factory) public returns (uint256) {
    factories.push(_factory);
    uint256 index = factories.length - 1;
    emit FactoryListing(_factory, index);
    return index;
  }

  function getFactories(uint256 _tokenId) external view returns (address, address, address) {
    return (
      factories[tokens[_tokenId].factoryA],
      factories[tokens[_tokenId].factoryB],
      factories[tokens[_tokenId].factoryC]
    );
  }

  function switchFactories(
    uint256 _tokenId,
    address[3] calldata _factoryAddresses,
    uint256[3] memory _factoryIndexes
  ) external {
    require(msg.sender == ownerOf(_tokenId));
    if (_factoryAddresses[0] != address(0)) {
      _factoryIndexes[0] = addFactory(_factoryAddresses[0]);
    }
    if (_factoryAddresses[1] != address(0)) {
      if (_factoryAddresses[1] == _factoryAddresses[0]) {
        _factoryIndexes[1] = _factoryIndexes[0];
      } else {
        _factoryIndexes[1] = addFactory(_factoryAddresses[1]);
      }
    }
    if (_factoryAddresses[2] != address(0)) {
      if (_factoryAddresses[2] == _factoryAddresses[0]) {
        _factoryIndexes[2] = _factoryIndexes[0];
      } else if (_factoryAddresses[2] == _factoryAddresses[1]) {
        _factoryIndexes[2] = _factoryIndexes[1];
      } else {
        _factoryIndexes[2] = addFactory(_factoryAddresses[2]);
      }
    }
    switchFactories(
      _tokenId,
      _factoryIndexes[0],
      _factoryIndexes[1],
      _factoryIndexes[2]
    );
  }

  function switchFactories(
    uint256 _tokenId,
    uint256 _factoryIndexA,
    uint256 _factoryIndexB,
    uint256 _factoryIndexC
  ) public {
    tokens[_tokenId].factoryA = uint32(_factoryIndexA);
    tokens[_tokenId].factoryB = uint32(_factoryIndexB);
    tokens[_tokenId].factoryC = uint32(_factoryIndexC);
  }

  function mint(uint256 _tokenId) external payable {
    require(msg.value >= price(block.number), "INSUFFICIENT ETH SENT");
    require(!exists(_tokenId), "TOKEN ID ALREADY EXISTS");
    tokens[_tokenId].owner = msg.sender;
    emit Sale(_tokenId, msg.value);
    emit TransferSingle(msg.sender, address(0), msg.sender, _tokenId, 1);
  }

  function price(uint256 _blockNumber) public view returns (uint256) {
    if (_blockNumber <= auctionEnd) {
      return startingPrice - (_blockNumber - auctionStart) * reductionRate;
    } else {
      return endingPrice;
    }
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(royaltyAddress), address(this).balance);
  }

  // 1155

  function balanceOf(address _account, uint256 _tokenId) public view override returns (uint256) {
    address owner = ownerOf(_tokenId);
    require(exists(_tokenId), "TOKEN DOESN'T EXIST");
    return  owner == _account ? 1 : 0;
  }

  function balanceOfBatch(
    address[] calldata _accounts,
    uint256[] calldata _tokenIds
  ) public view override returns (uint256[] memory) {
    require(
      _accounts.length == _tokenIds.length,
      "ARRAYS NOT SAME LENGTH"
    );
    uint256[] memory batchBalances = new uint256[](_accounts.length);
    for (uint256 i = 0; i < _accounts.length; ++i) {
      batchBalances[i] = balanceOf(_accounts[i], _tokenIds[i]);
    }
    return batchBalances;
  }
  
  function exists(uint256 _tokenId) public view returns (bool) {
    return tokens[_tokenId].owner != address(0);
  }

  function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokens[_tokenId].owner;
    require(owner != address(0), "TOKEN DOESN'T EXIST");
    return owner;
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  ) external {
    safeTransferFrom(_from, _to, _tokenId, 1, _data);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes calldata _data
  ) public override {
    require(_to != address(0), "INVALID RECEIVER");
    require(
      _from == msg.sender || isApprovedForAll(_from, msg.sender),
      "NOT AUTHED"
    );
    require(
        _amount == 1 && ownerOf(_tokenId) == _from,
        "INVALID SENDER"
    );
    tokens[_tokenId].owner = _to;
    emit TransferSingle(msg.sender, _from, _to, _tokenId, 1);
    _safeTransferCheck(msg.sender, _from, _to, _tokenId, 1, _data);
  }

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) public override {
    uint256 length = _tokenIds.length;
    require(
      length == _amounts.length,
      "ARRAYS NOT SAME LENGTH"
    );
    require(_to != address(0), "INVALID RECEIVER");
    require(
      _from == msg.sender || isApprovedForAll(_from, msg.sender),
      "NOT AUTHED"
    );

    for (uint256 i = 0; i < length; ++i) {
      uint256 id = _tokenIds[i];
      require(
        _amounts[i] == 1 && ownerOf(id) == _from,
        "INVALID SENDER"
      );
      tokens[id].owner = _to;
    }
    
    emit TransferBatch(msg.sender, _from, _to, _tokenIds, _amounts);

    _safeBatchTransferCheck(
      msg.sender,
      _from,
      _to,
      _tokenIds,
      _amounts,
      _data
    );
  }

  function setApprovalForAll(address _operator, bool _approved) public override {
    require(msg.sender != _operator, "CAN'T APPROVE SELF");
    operatorApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }
  
  function uri(uint256 _tokenId) external view override returns (string memory) {
    require(exists(_tokenId), "TOKEN DOESN'T EXIST");
    uint256 timeswitch = (block.timestamp % 10800) / 3600;
    uint256 index;
    if (timeswitch == 0) {
      index = tokens[_tokenId].factoryA;
    } if (timeswitch == 1) {
      index = tokens[_tokenId].factoryB;
    } if (timeswitch == 2) {
      index = tokens[_tokenId].factoryC;
    }
    index = index >= factories.length ? 0 : index;
    address factory = factories[index];
    if(factory.isContract()) {
      try
        IERC721Metadata(factory).tokenURI(_tokenId)
      returns (string memory tokenURI) {
        return tokenURI;
      } catch {}
      try
        IERC1155MetadataURI(factory).uri(_tokenId)
      returns (string memory URI) {
        return URI;
      } catch {}
    }
    return IERC721Metadata(factories[0]).tokenURI(_tokenId);
  }

  function _safeTransferCheck(
    address _operator,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes calldata _data
  ) private {
    if (_to.isContract()) {
      try
        IERC1155Receiver(_to).onERC1155Received(
          _operator,
          _from,
          _tokenId,
          _amount,
          _data
        )
      returns (bytes4 response) {
        if (
          response != IERC1155Receiver(_to).onERC1155Received.selector
        ) {
          revert("INVALID RECEIVER");
        }
      } catch Error(string memory reason) {
          revert(reason);
      } catch {
          revert("INVALID RECEIVER");
      }
    }
  }

  function _safeBatchTransferCheck(
    address _operator,
    address _from,
    address _to,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts,
    bytes calldata _data
  ) private {
    if (_to.isContract()) {
      try
        IERC1155Receiver(_to).onERC1155BatchReceived(
          _operator,
          _from,
          _tokenIds,
          _amounts,
          _data
        )
      returns (bytes4 response) {
        if (
          response != IERC1155Receiver(_to).onERC1155BatchReceived.selector
        ) {
          revert("INVALID RECEIVER");
        }
      } catch Error(string memory reason) {
          revert(reason);
      } catch {
          revert("INVALID RECEIVER");
      }
    }
  }
}