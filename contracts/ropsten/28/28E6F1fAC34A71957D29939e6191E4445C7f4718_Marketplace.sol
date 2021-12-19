// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

import "./IBEP20.sol";
import "./ERC165.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

abstract contract ERC2981Base is ERC165 {
  uint256 public constant HUNDRED_PERCENT = 100;

  struct RoyaltyInfo {
    address recipient;
    uint24 ratio;
  }

  uint256 mintingFee;
  uint24 sellingFee;

  mapping(uint256 => RoyaltyInfo) internal _royalties;
  mapping(uint256 => uint256) internal _mintingFees;
  mapping(uint256 => uint24) internal _sellingFees;

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override
  returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function _setTokenRoyalty(uint256 tokenId, address recipient, uint24 ratio)
  internal {
    _royalties[tokenId] = RoyaltyInfo(recipient, uint24(ratio));
  }

  function _setMintingFee(uint256 tokenId, address recipient, uint256 ratio)
  internal {
    _mintingFees[tokenId] = mintingFee;
  }

  function _setSellingFee(uint256 tokenId, address recipient, uint24 ratio)
  internal {
    _sellingFees[tokenId] = sellingFee;
  }

  function royaltyInfo(uint256 tokenId)
  internal
  view
  returns (address royaltyRecipient, uint256 royaltyRatio) {
    RoyaltyInfo memory royalties = _royalties[tokenId];
    royaltyRecipient = royalties.recipient;
    royaltyRatio = royalties.ratio / HUNDRED_PERCENT;
  }

  function mintingInfo(uint256 tokenId)
  internal
  returns (uint256 feeAmount) {
    return _mintingFees[tokenId];
  }

  function sellingInfo(uint256 tokenId)
  internal
  returns (uint256 feeRatio) {
    return _sellingFees[tokenId] / HUNDRED_PERCENT;
  }
}

contract Marketplace is ERC1155, ERC2981Base, Ownable {
  uint256 public BNB_TOKEN_ID = uint256(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
  uint256 public SPC_TOKEN_ID = uint256(0x002013fe8529077c6c6177b80ace8746f8f8a1eb4f);
  uint8 TOKEN_BNB = 1;
  uint8 TOKEN_SPC = 2;

  address payable mkOwner;

  IBEP20 public stakedToken;

  string public collectionName;
  string public collectionNameSymbol;
  uint256 public spectraNFTCounter;

  struct SpectraNFT {
    uint256 tokenId;
    string tokenMetaData;
    address payable currentOwner;
    uint256 price;
    bool isUnlock;
  }

  mapping(uint256 => SpectraNFT) public allSpectraNFT;
  mapping(uint256 => bool) public tokenIDExists;
  mapping(string => bool) public tokenMetaDataExists;
  mapping(uint256 => address) private _nftOwnerFromID;
  mapping(address => bool) private _isCreater;
  mapping(address => uint256) private _balanceFromAddress;

  modifier onlyCreater {
    require((_isCreater[msg.sender]), "Not NFT creater...");
    _;
  }

  function supportsInterface(bytes4 interfaceId)
  public
  view
  virtual
  override(ERC165, ERC2981Base)
  returns (bool) {
    return (interfaceId == type(ERC2981Base).interfaceId) || super.supportsInterface(interfaceId);    
  }

  constructor(string memory _uri) ERC1155(_uri) {
    mkOwner = msg.sender;
    mintingFee = 1;
    sellingFee = 10;
  }

  function setOwner(address payable newOwner)
  external
  onlyOwner {
    require(newOwner != address(0), "Invalid owner address...");
    mkOwner = newOwner;
  }

  function setCreater(address addr, bool isCreater) 
  external
  onlyOwner {
    require(addr != address(0), "Invalid creater address...");
    _isCreater[addr] = isCreater;
  }

  function setStakedToken(IBEP20 _stakedToken)
  external {
    stakedToken = _stakedToken;
  }

  function setRoyalty(uint256 tokenId, address recipient, uint24 ratio)
  external
  onlyOwner {
    require(recipient != address(0), "Invalid recipient address...");
    require(ratio >= 0, "Too small ratio");
    require(ratio < 100, "Too large ratio");
    _setTokenRoyalty(tokenId, recipient, ratio);
  }

  function setMintingFee(uint256 tokenId, address recipient, uint256 amount)
  external
  onlyOwner {
    require(recipient != address(0), "Invalid recipient address...");
    require(amount >= 0, "Too small amount");
    _setMintingFee(tokenId, recipient, amount);
  }

  function setSellingFee(uint256 tokenId, address recipient, uint24 ratio)
  external
  onlyOwner {
    require(recipient != address(0), "Invalid recipient address...");
    require(ratio >= 0, "Too small ratio");
    require(ratio < 100, "Too large ratio");
    _setSellingFee(tokenId, recipient, ratio);
  }

  function getOwnerOfNFT(uint256 tokenId)
  public
  returns (address ownerOfNFT) {
  	return _nftOwnerFromID[tokenId];
  }

  function transferInETH(address payable to, uint256 amountETH)
  internal {
    to.transfer(amountETH);
  }

  function transferInBNB(address payable to, uint256 amountBNB)
  internal {
    to.transfer(amountBNB);
  }

  function transferInSPC(address payable to, uint256 amountSPC)
  internal {
    stakedToken.transfer(to, amountSPC);
  }

  function transferOnBSC(address payable to, uint256 amount, uint8 tokenType)
  internal {
    if (tokenType == TOKEN_BNB) {
      transferInBNB(to, amount);
    } else if (tokenType == TOKEN_SPC) {
      transferInSPC(to, amount);
    } else {
      transferInETH(to, amount);
    }
  }

  function mintSpectraNFT(
  					uint256 _tokenId,
  					string memory _tokenMetaData,
  					uint256 quantityOfNFT,
  					uint256 _price,
  					bool _isUnlock,
    				uint24 royaltyValue,
        		uint8 tokenType)
  external {
    require(msg.sender != address(0), "Invalid address...");
    require((_isCreater[msg.sender]), "Disallowed creater...");
    _nftOwnerFromID[_tokenId] = msg.sender;
    spectraNFTCounter++;

    require(!tokenIDExists[_tokenId], "Existing id...");
    require(!tokenMetaDataExists[_tokenMetaData], "Existing metadata....");

    _mint(msg.sender, spectraNFTCounter, quantityOfNFT, '');
    transferOnBSC(mkOwner, mintingInfo(_tokenId), tokenType);

    tokenIDExists[_tokenId] = true;
    tokenMetaDataExists[_tokenMetaData] = true;

    SpectraNFT memory newSpectraNFT = SpectraNFT(
            spectraNFTCounter,
            _tokenMetaData,
            msg.sender,
            _price,
            _isUnlock);

    allSpectraNFT[spectraNFTCounter] = newSpectraNFT;
    _setTokenRoyalty(_tokenId, msg.sender, royaltyValue);
  }

  function transferNFT(uint256 tokenId, uint256 price, uint8 tokenType)
  public
  payable {
    require(msg.sender != address(0), "Invalid address...");
    require(!tokenIDExists[tokenId], "Existing id...");
    require(balanceOf(msg.sender, tokenId) > price, "Insufficient purchase balance...");

    address ownerOfNFT = getOwnerOfNFT(tokenId);
    require(ownerOfNFT != address(0));
    require(ownerOfNFT != msg.sender);

    (address receiver, uint256 royaltyAmount) = royaltyInfo(tokenId);
    uint256 salePrice = price - price * sellingInfo(tokenId) - price * royaltyAmount;

    SpectraNFT memory spectraNFT = allSpectraNFT[tokenId];

    safeTransferFrom(ownerOfNFT, msg.sender, tokenId, 1, '0');

    address payable sendTo = spectraNFT.currentOwner;
    sendTo.transfer(price);
    transferOnBSC(sendTo, price, tokenType);

    spectraNFT.currentOwner = msg.sender;
    spectraNFT.price = price;
    allSpectraNFT[tokenId] = spectraNFT;
  }

}