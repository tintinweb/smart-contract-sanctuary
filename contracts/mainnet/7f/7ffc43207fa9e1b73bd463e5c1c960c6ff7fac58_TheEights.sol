// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import 'ERC721.sol';
import 'ERC721Enumerable.sol';
import 'Ownable.sol';

contract TheEights is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant EIGHTS_GIFT = 90;
  uint256 public constant EIGHTS_PRIVATE = 150;
  uint256 public constant EIGHTS_PUBLIC = 648;
  uint256 private EIGHTS_MAGIC = 0;

  uint256 public constant EIGHTS_PRICE = 0.08 ether;
  uint256 public constant EIGHTS_PER_MINT = 5;

  mapping(string => bool) private _usedNonces;

  mapping(address => uint256) public presalerListPurchases;

  string private _contractURI;
  string private _tokenBaseURI = '';

  address private _mainAddress = 0xa4B7100a1316c442d4337B0f6c3b9a5D37076B98;

  string public proof;
  uint256 public giftedAmount;
  uint256 public privateAmountMinted;
  uint256 public presalePurchaseLimit = 2;
  bool public privateSaleLive = true;
  bool public publicSaleLive = false;
  bool public locked;

  constructor() ERC721('TheEights', 'EIGHTS') {}

  modifier notLocked() {
    require(!locked, 'Contract metadata methods are locked');
    _;
  }

  function privateSaleBuy(uint256 tokenQuantity) external payable {
    require(privateSaleLive, 'SALE_CLOSED');
    require(totalSupply() < EIGHTS_GIFT + EIGHTS_PRIVATE + EIGHTS_PUBLIC + EIGHTS_MAGIC, 'OUT_OF_STOCK');
    require(tokenQuantity <= EIGHTS_PER_MINT, 'EXCEED_EIGHTS_PER_MINT');
    require(EIGHTS_PRICE * tokenQuantity <= msg.value, 'INSUFFICIENT_ETH');
    require(presalerListPurchases[msg.sender] + tokenQuantity <= presalePurchaseLimit, "EXCEED_ALLOC");

    for (uint256 i = 0; i < tokenQuantity; i++) {
            presalerListPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
  }

  function publicSaleBuy(uint256 tokenQuantity) external payable {
    require(publicSaleLive, 'SALE_CLOSED');
    require(totalSupply() < EIGHTS_GIFT + EIGHTS_PRIVATE + EIGHTS_PUBLIC + EIGHTS_MAGIC, 'OUT_OF_STOCK');
    require(tokenQuantity <= EIGHTS_PER_MINT, 'EXCEED_EIGHTS_PER_MINT');
    require(EIGHTS_PRICE * tokenQuantity <= msg.value, 'INSUFFICIENT_ETH');

    for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
  }

  function gift(address[] calldata receivers) external {
    require(msg.sender == _mainAddress, 'PERMISSION_DENIED');
    require(totalSupply() + receivers.length <= EIGHTS_GIFT + EIGHTS_PRIVATE + EIGHTS_PUBLIC + EIGHTS_MAGIC, 'MAX_MINT');
    require(giftedAmount + receivers.length <= EIGHTS_GIFT, 'GIFTS_EMPTY');

    for (uint256 i = 0; i < receivers.length; i++) {
      giftedAmount++;
      _safeMint(receivers[i], totalSupply() + 1);
    }
  }

  function withdraw() external {
    require(msg.sender == _mainAddress, 'PERMISSION_DENIED');
    payable(_mainAddress).transfer(address(this).balance);
  }

  function lockMetadata() external onlyOwner {
    locked = true;
  }

  function togglePrivateSale() external {
    require(msg.sender == _mainAddress, 'PERMISSION_DENIED');

    privateSaleLive = !privateSaleLive;
  }

  function togglePublicSale() external {
    require(msg.sender == _mainAddress, 'PERMISSION_DENIED');

    publicSaleLive = !publicSaleLive;
  }

  function setSignerAddress(address addr) external onlyOwner {
    _mainAddress = addr;
  }


  function setContractURI(string calldata URI) external notLocked {
     require(msg.sender == _mainAddress, 'PERMISSION_DENIED');
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external notLocked {
     require(msg.sender == _mainAddress, 'PERMISSION_DENIED');
    _tokenBaseURI = URI;
  }

  function setMagic(uint256 magicNumber) external notLocked {
     require(msg.sender == _mainAddress, 'PERMISSION_DENIED');
    EIGHTS_MAGIC = magicNumber;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory base = _tokenBaseURI;
    string memory _tokenURI = Strings.toString(_tokenId);

    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    return string(abi.encodePacked(base, _tokenURI));
  }

  function checkTotalMintable()
    public
    view
    returns (uint256)
  {
   return EIGHTS_GIFT + EIGHTS_PRIVATE + EIGHTS_PUBLIC + EIGHTS_MAGIC;
  }

  function checkMinted()
    public
    view
    returns (uint256)
  {
   return totalSupply();
  }
}