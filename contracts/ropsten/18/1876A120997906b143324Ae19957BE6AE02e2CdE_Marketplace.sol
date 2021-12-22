// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./SafeMath.sol";

abstract contract ERC2981Base is ERC165 {

    struct RoyaltyInfo {
        address recipient;
        uint24 ratio;
    }

    mapping(address => uint256) internal _mintingFees;
    mapping(address => uint24) internal _sellingFees;
    mapping(uint256 => RoyaltyInfo) internal _royaltyRatio;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _setMintingFee(address creater, uint256 fee) internal {
        _mintingFees[creater] = fee;
    }

    function _setSellingFee(address seller, uint24 ratio) internal {
        _sellingFees[seller] = ratio;
    }

    function _setRoyalty(uint256 _tokenId, address creater, uint24 ratio) internal {
        _royaltyRatio[_tokenId] = RoyaltyInfo(creater, ratio);
    }

    function getMintingFee(address creater) public view returns (uint256) {
        return _mintingFees[creater];
    }

    function getSellingRatio(address seller) public view returns (uint24) {
        return _sellingFees[seller];
    }

    function getRoyaltyRecipient(uint256 _tokenId) public view returns (address) {
        return _royaltyRatio[_tokenId].recipient;
    }

    function getRoyaltyRatio(uint256 _tokenId) public view returns (uint24) {
        return _royaltyRatio[_tokenId].ratio;
    }
}

contract Marketplace is ERC1155, ERC2981Base, Ownable {

    struct SpectraNFT {
        uint256 tokenId;
        string tokenHash;
        string tokenMetaData;
        address payable currentOwner;
        uint256 price;
        bool isUnlock;
    }

    address payable mkOwner;

    // string private collectionName;
    // string private collectionNameSymbol;
    uint256 private spectraNFTCounter;

    mapping(uint256 => SpectraNFT) allSpectraNFT;
    mapping(string => bool) tokenHashExists;
    mapping(string => bool) tokenMetaDataExists;
    mapping(address => bool) _isCreater;

    modifier onlyAdmin() {
        require((_isCreater[msg.sender] || (mkOwner == msg.sender)), "Not NFT creater...");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, ERC2981Base) returns (bool) {
        return (interfaceId == type(ERC2981Base).interfaceId) || super.supportsInterface(interfaceId);
    }

    constructor(string memory _uri) ERC1155(_uri) {
        mkOwner = msg.sender;
        spectraNFTCounter = 0;
    }

    function setOwner(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid input address...");
        mkOwner = newOwner;
    }

    function setCreater(address addr, bool isCreater) external onlyOwner {
        require(addr != address(0), "Invalid input address...");
        _isCreater[addr] = isCreater;
    }

    function setMintingFee(address creater, uint256 amount) external onlyOwner {
        require(creater != address(0), "Invalid input address...");
        require(amount >= 0, "Too small amount");
        _setMintingFee(creater, amount);
    }

    function setSellingFee(address seller, uint24 ratio) external onlyOwner {
        require(seller != address(0), "Invalid input address...");
        require(ratio >= 0, "Too small ratio");
        require(ratio < 100, "Too large ratio");
        _setSellingFee(seller, ratio);
    }
    
    function setRoyalty(uint256 tokenId, address creater, uint24 ratio) public onlyAdmin {
        require(creater != address(0), "Invalid input address...");
        require(ratio >= 0, "Too small ratio");
        require(ratio < 100, "Too large ratio");
        _setRoyalty(tokenId, creater, ratio);
    }

    function getCounterOfNFT() public view returns (uint256) {
        return spectraNFTCounter;
    }

    function getOwnerAddress() public view returns (address) {
        return mkOwner;
    }

    function getWithdrawBalance(uint8 kind) public view returns (uint256) {
        if (kind == 0) {
          return address(this).balance;
        } else {
          return 0;
        }
    }

    function transferToContract(address payable to, uint256 amount, uint8 paymentKind) internal {
        if (paymentKind == 0) {
          to.transfer(amount);
        } else {

        }
    }

    function mintSpectraNFT(string memory _tokenHash, string memory _tokenMetaData, uint256 _price, bool _isUnlock, uint24 royaltyValue) external payable onlyAdmin {
        require(msg.sender != address(0), "Invalid address...");
        require(!tokenHashExists[_tokenHash], "Existing NFT hash value....");
        require(!tokenMetaDataExists[_tokenMetaData], "Existing metadata....");

        _mint(msg.sender, spectraNFTCounter, 1, "");
        tokenHashExists[_tokenHash] = true;
        tokenMetaDataExists[_tokenMetaData] = true;

        SpectraNFT memory newSpectraNFT = SpectraNFT(
            spectraNFTCounter,
            _tokenHash,
            _tokenMetaData,
            payable(msg.sender),
            _price,
            _isUnlock
        );

        allSpectraNFT[spectraNFTCounter] = newSpectraNFT;
    
        setRoyalty(spectraNFTCounter, msg.sender, royaltyValue);
        spectraNFTCounter++;
    }

    function mintBatchSpectraNFT(string[] calldata _tokenHash, string[] calldata _tokenMetaData, uint256 _price, bool _isUnlock, uint24 royaltyValue, uint8 kind) external payable onlyAdmin {
        require(msg.sender != address(0), "Invalid address...");

        uint256[] memory arrayTokenId = new uint256[](_tokenHash.length);
        uint256[] memory arrayTokenAmount = new uint256[](_tokenHash.length);

        for (uint256 i; i < _tokenHash.length; i++) {
          require(!tokenHashExists[_tokenHash[i]], "Existing NFT hash value....");
          require(!tokenMetaDataExists[_tokenMetaData[i]], "Existing metadata....");

          tokenHashExists[_tokenHash[i]] = true;
          tokenMetaDataExists[_tokenMetaData[i]] = true;

          arrayTokenId[i] = spectraNFTCounter;
          arrayTokenAmount[i] = 1;

          SpectraNFT memory newSpectraNFT = SpectraNFT(
            spectraNFTCounter,
            _tokenHash[i],
            _tokenMetaData[i],
            payable(msg.sender),
            _price,
            _isUnlock
          );

          allSpectraNFT[spectraNFTCounter] = newSpectraNFT;
          setRoyalty(spectraNFTCounter, msg.sender, royaltyValue);
          spectraNFTCounter++;
        }

        _mintBatch(msg.sender, arrayTokenId, arrayTokenAmount, "");
        transferToContract(mkOwner, _mintingFees[msg.sender] * _tokenHash.length, kind);
    }

    function transferNFT(uint256 tokenId, uint256 price, uint8 kind) public payable {
        require(msg.sender != address(0), "Invalid address...");

        address payable ownerOfNFT = allSpectraNFT[tokenId].currentOwner;
        require(ownerOfNFT != address(0), "Invalid address...");
        require(ownerOfNFT != msg.sender, "Invalid address...");

        uint256 royaltyAmount = getRoyaltyRatio(tokenId);
        uint256 salePrice = price - price * getSellingRatio(ownerOfNFT) / 100 - price * royaltyAmount / 100;

        safeTransferFrom(ownerOfNFT, msg.sender, tokenId, 1, '');
        transferToContract(payable(getRoyaltyRecipient(tokenId)), price * royaltyAmount / 100, kind);
        transferToContract(ownerOfNFT, salePrice, kind);

        allSpectraNFT[tokenId].currentOwner = payable(msg.sender);
        allSpectraNFT[tokenId].price = price;
    }

    function withDraw(uint256 amount, uint8 kind) public onlyOwner {
        require(getWithdrawBalance(kind) > amount, "None left to withdraw...");

        transferToContract(msg.sender, amount, kind);
    }
}