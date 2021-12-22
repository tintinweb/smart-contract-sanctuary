// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

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
    mapping(string => RoyaltyInfo) internal _royaltyRatio;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _setMintingFee(address creater, uint256 fee) internal {
        _mintingFees[creater] = fee;
    }

    function _setSellingFee(address seller, uint24 ratio) internal {
        _sellingFees[seller] = ratio;
    }

    function _setRoyalty(string memory tokenId, address creater, uint24 ratio) internal {
        _royaltyRatio[tokenId] = RoyaltyInfo(creater, ratio);
    }

    function getMintingFee(address creater) public view returns (uint256) {
        return _mintingFees[creater];
    }

    function getSellingRatio(address seller) public view returns (uint24) {
        return _sellingFees[seller];
    }

    function getRoyaltyRecipient(string memory tokenId) public view returns (address) {
        return _royaltyRatio[tokenId].recipient;
    }

    function getRoyaltyRatio(string memory tokenId) public view returns (uint24) {
        return _royaltyRatio[tokenId].ratio;
    }
}

contract Marketplace is ERC1155, ERC2981Base, Ownable {

    struct SpectraNFT {
        string tokenHash;
        string tokenMetaData;
        address payable currentOwner;
        uint256 price;
        bool isUnlock;
    }

    address payable mkOwner;

    string public collectionName;
    string public collectionNameSymbol;
    uint256 public spectraNFTCounter;

    mapping(string => SpectraNFT) public allSpectraNFT;
    mapping(string => bool) public tokenHashExists;
    mapping(string => bool) public tokenMetaDataExists;
    mapping(address => bool) private _isCreater;

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
    
    function setRoyalty(string memory tokenId, address creater, uint24 ratio) internal onlyAdmin {
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

    function transferToContract(address payable to, uint256 amount) internal {
        to.transfer(amount);
    }

    function mintSpectraNFT(string memory _tokenId, string memory _tokenMetaData, uint256 quantityOfNFT, uint256 _price, bool _isUnlock, uint24 royaltyValue) external payable onlyAdmin {
        require(msg.sender != address(0), "Invalid address...");
        require(!tokenMetaDataExists[_tokenMetaData], "Existing metadata....");

        _mint(msg.sender, spectraNFTCounter, quantityOfNFT, "");
        // payable(msg.sender).call{value: mintingInfo(spectraNFTCounter)};
        // payable(msg.sender).transfer(mintingInfo(spectraNFTCounter));
        transferToContract(mkOwner, _mintingFees[msg.sender]);
        tokenMetaDataExists[_tokenMetaData] = true;

        SpectraNFT memory newSpectraNFT = SpectraNFT(
            _tokenId,
            _tokenMetaData,
            payable(msg.sender),
            _price,
            _isUnlock
        );

        allSpectraNFT[_tokenId] = newSpectraNFT;
    
        setRoyalty(_tokenId, msg.sender, royaltyValue);
        spectraNFTCounter++;
    }

    function transferNFT(string memory _tokenId, uint256 price) public payable {
        require(msg.sender != address(0), "Invalid address...");
        // require(balanceOf(msg.sender, spectraNFTCounter - 1) > price, "Insufficient purchase balance...");

        address payable ownerOfNFT = allSpectraNFT[_tokenId].currentOwner;
        require(ownerOfNFT != address(0), "Invalid address...");
        require(ownerOfNFT != msg.sender, "Invalid address...");

        uint256 royaltyAmount = getRoyaltyRatio(_tokenId);
        uint256 salePrice = price - price * getSellingRatio(ownerOfNFT) / 100 - price * royaltyAmount;

        safeTransferFrom(ownerOfNFT, msg.sender, spectraNFTCounter - 1, 1, '');
        transferToContract(payable(getRoyaltyRecipient(_tokenId)), salePrice);
        transferToContract(ownerOfNFT, salePrice);

        allSpectraNFT[_tokenId].currentOwner = payable(msg.sender);
        allSpectraNFT[_tokenId].price = price;
        allSpectraNFT[_tokenId].tokenHash = _tokenId;
    }
}