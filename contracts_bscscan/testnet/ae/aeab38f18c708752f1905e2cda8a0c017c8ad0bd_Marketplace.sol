// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./ERC165.sol";
import "./ERC1155.sol";
import "./Address.sol";
import "./Ownable.sol";
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

    address public constant SPC_TOKEN_ADDR = address(0x00a2f017966d967ec697c7a20cf9d0b43cb8d4ff1d);

    struct SpectraNFT {
        uint256 tokenId;
        string tokenHash;
        address payable currentOwner;
        uint256 price;
        uint256 mintingDate;
        uint256 auctionInterval;
    }

    IERC20 SPCToken;
    address payable mkOwner;

    string private collectionName;
    string private collectionNameSymbol;
    string private baseUri;
    uint256 private spectraNFTCounter;

    mapping(uint256 => SpectraNFT) allSpectraNFT;
    mapping(string => bool) tokenHashExists;
    mapping(address => bool) _isCreater;
    mapping(string => uint256) getTokenIdFromHash;

    modifier onlyAdmin() {
        require((_isCreater[msg.sender] || (mkOwner == msg.sender)), "Not NFT creater...");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, ERC2981Base) returns (bool) {
        return (interfaceId == type(ERC2981Base).interfaceId) || super.supportsInterface(interfaceId);
    }

    constructor(string memory _name ,string memory _symbol, string memory _uri) ERC1155(_uri) {
        collectionName = _name;
        collectionNameSymbol = _symbol;
        baseUri = _uri;
        mkOwner = msg.sender;
        SPCToken = IERC20(SPC_TOKEN_ADDR);
        spectraNFTCounter = 0;
    }

    function setOwner(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid input address...");
        mkOwner = newOwner;
        transferOwnership(mkOwner);
    }

    function setCreater(address addr, bool _IsCreater) external onlyOwner {
        require(addr != address(0), "Invalid input address...");
        _isCreater[addr] = _IsCreater;
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

    function isCreater(address addr) external view returns (bool) {
        require(addr != address(0), "Invalid input address...");
        return _isCreater[addr];
    }
    
    function isAuctionEnded(string memory tokenHash) external returns (bool) {
        require(msg.sender != address(0), "Invalid address...");
        require(tokenHashExists[tokenHash], "Non-Existing NFT hash value....");
        SpectraNFT memory spectraNFT = getNFTInfo(tokenHash);
        bool isEnded;
        if (spectraNFT.mintingDate + spectraNFT.auctionInterval < block.timestamp) {
            isEnded = true;
        } else {
            isEnded = false;    
        }

        emit IsAuctionEnded(tokenHash, isEnded);

        return isEnded;
    }

    function getOwner() external view returns (address) {
        require(msg.sender != address(0), "Invalid address...");
        return mkOwner;
    }

    function getNFTInfo(string memory tokenHash) public view returns (SpectraNFT memory result) {
        require(msg.sender != address(0), "Invalid address...");
        require(tokenHashExists[tokenHash], "Non-Existing NFT hash value....");
        result = allSpectraNFT[getTokenIdFromHash[tokenHash]];
        return result;
    }

    function getWithdrawBalance(uint8 kind) public view returns (uint256) {
        require(msg.sender != address(0), "Invalid address...");
        require(kind >= 0, "Invalid cryptocurrency...");

        if (kind == 0) {
          return address(this).balance;
        } else {
          return SPCToken.balanceOf(address(this));
        }
    }

    function transferToContract(address payable to, uint256 amount, uint8 kind) internal {
        require(msg.sender != address(0), "Invalid address...");
        require(to != address(0), "Invalid address...");
        require(amount > 0, "Invalid transferring amount...");
        require(kind >= 0, "Invalid cryptocurrency...");
        
        if (kind == 0) {
          to.transfer(amount);
        } else {
          SPCToken.transfer(to, amount);
        }
    }

    function mintSpectraNFT(string memory _tokenHash, uint256 auctionInterval, uint256 _price, uint24 royaltyValue, uint8 kind) external payable onlyAdmin {
        require(msg.sender != address(0), "Invalid address...");
        require(!tokenHashExists[_tokenHash], "Existing NFT hash value....");
        require(auctionInterval >= 0, "Invalid auction interval....");
        require(royaltyValue >= 0, "Invalid royalty value....");
        require(kind >= 0, "Invalid cryptocurrency...");

        _mint(msg.sender, spectraNFTCounter, 1, "");
        transferToContract(mkOwner, _mintingFees[msg.sender], kind);
        tokenHashExists[_tokenHash] = true;
        getTokenIdFromHash[_tokenHash] = spectraNFTCounter;

        SpectraNFT memory newSpectraNFT = SpectraNFT(
            spectraNFTCounter,
            _tokenHash,
            payable(msg.sender),
            _price,
            block.timestamp,
            auctionInterval
        );

        allSpectraNFT[spectraNFTCounter] = newSpectraNFT;
    
        setRoyalty(spectraNFTCounter, msg.sender, royaltyValue);
        spectraNFTCounter++;
    }

    function mintBatchSpectraNFT(string[] calldata _tokenHash, uint256 _price, uint24 royaltyValue, uint8 kind) external payable onlyAdmin {
        require(msg.sender != address(0), "Invalid address...");
        require(royaltyValue >= 0, "Invalid royalty value....");
        require(kind >= 0, "Invalid cryptocurrency...");

        uint256[] memory arrayTokenId = new uint256[](_tokenHash.length);
        uint256[] memory arrayTokenAmount = new uint256[](_tokenHash.length);

        for (uint256 i = 0; i < _tokenHash.length; i++) {
          require(!tokenHashExists[_tokenHash[i]], "Existing NFT hash value....");

          tokenHashExists[_tokenHash[i]] = true;
          getTokenIdFromHash[_tokenHash[i]] = spectraNFTCounter + i;

          arrayTokenId[i] = spectraNFTCounter;
          arrayTokenAmount[i] = 1;

          SpectraNFT memory newSpectraNFT = SpectraNFT(
            spectraNFTCounter,
            _tokenHash[i],
            payable(msg.sender),
            _price,
            block.timestamp,
            0
          );

          allSpectraNFT[spectraNFTCounter] = newSpectraNFT;
          setRoyalty(spectraNFTCounter, msg.sender, royaltyValue);
          spectraNFTCounter++;
        }

        _mintBatch(msg.sender, arrayTokenId, arrayTokenAmount, "");
        transferToContract(mkOwner, _mintingFees[msg.sender] * _tokenHash.length, kind);
    }

    function transferNFT(address _to, string memory _tokenHash, uint8 kind) external payable {
        require(msg.sender != address(0), "Invalid address...");
        require(_to != address(0), "Invalid address...");
        require(tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");
        require(kind >= 0, "Invalid cryptocurrency...");

        uint256 indexOfToken = getTokenIdFromHash[_tokenHash];
        uint256 price = msg.value;
        address payable ownerOfNFT = allSpectraNFT[indexOfToken].currentOwner;
        require(ownerOfNFT != address(0), "Invalid address...");
        require(ownerOfNFT != _to, "Invalid address...");

        uint256 royaltyAmount = getRoyaltyRatio(indexOfToken);
        uint256 salePrice = price - price * getSellingRatio(ownerOfNFT) / 100 - price * royaltyAmount / 100;

        safeTransferFrom(ownerOfNFT, _to, indexOfToken, 1, '');
        transferToContract(payable(getRoyaltyRecipient(indexOfToken)), price * royaltyAmount / 100, kind);
        transferToContract(ownerOfNFT, salePrice, kind);

        allSpectraNFT[indexOfToken].currentOwner = payable(_to);
        allSpectraNFT[indexOfToken].price = price;
    }

    function withDraw(uint256 amount, uint8 kind) external onlyOwner {
        require(amount > 0, "Invalid withdraw amount...");
        require(kind >= 0, "Invalid cryptocurrency...");
        require(getWithdrawBalance(kind) > amount, "None left to withdraw...");

        transferToContract(msg.sender, amount, kind);
    }

    function withDrawAll(uint8 kind) external onlyOwner {
        require(kind >= 0, "Invalid cryptocurrency...");
        uint256 remaining = getWithdrawBalance(kind);
        require(remaining > 0, "None left to withdraw...");

        transferToContract(msg.sender, remaining, kind);
    }

    event IsAuctionEnded(string indexed tokenHash, bool indexed inEnded);
}