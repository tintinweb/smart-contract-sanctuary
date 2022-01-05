// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC1155.sol";
import "./Address.sol";

contract Marketplace is ERC1155, Ownable {

    struct NFTInfo {
        uint256 tokenId;
        string tokenHash;
        address creator;
        address currentOwner;
        address lastBidder;
        uint256 lastPrice;
        uint256 mintingDate;
        uint256 auctionInterval;
        uint8 kindOfCoin;
        uint24 royaltyRatio;
        bool onSale;
    }

    address mkOwner;
    IERC20 SPCToken;
    bool private _status;

    string private collectionName;
    string private collectionNameSymbol;
    string private baseUri;
    uint256 private allNFTCounter;

    mapping(uint256 => NFTInfo) _allNFTInfo;
    mapping(string => bool) _tokenHashExists;
    mapping(address => bool) _isCreater;
    mapping(string => uint256) _getTokenIdFromHash;
    mapping(address => uint256) internal _mintingFees;
    mapping(address => uint24) internal _sellingRatio;

    modifier onlyAdmin() {
        require((_isCreater[msg.sender] || (mkOwner == msg.sender)), "Not NFT creater...");
        _;
    }

    modifier onlyNFTOwner(string memory _tokenHash) {
        require(_allNFTInfo[_getTokenIdFromHash[_tokenHash]].currentOwner == msg.sender, "Not NFT Owner...");
        _;
    }

    modifier notOnlyNFTOwner(string memory _tokenHash) {
        require(_allNFTInfo[_getTokenIdFromHash[_tokenHash]].currentOwner != msg.sender, "NFT Owner cannot bid...");
        _;
    }

    modifier nonReentrant() {
        require(_status != true, "ReentrancyGuard: reentrant call");
        _status = true;
        _;
        _status = false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return (interfaceId == type(IERC1155).interfaceId) || super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        if (operator == owner())
            return true;
        return super.isApprovedForAll(account, operator);
    }

    constructor(string memory _name ,string memory _symbol, string memory _uri) ERC1155(_uri) {
        collectionName = _name;
        collectionNameSymbol = _symbol;
        baseUri = _uri;
        SPCToken = IERC20(address(0x00a2f017966d967ec697c7a20cf9d0b43cb8d4ff1d));
        mkOwner = msg.sender;
        allNFTCounter = 0;
        _status = false;
    }

    function isCreater(address addr) external view returns (bool) {
        return _isCreater[addr];
    }
    
    function isAuctionEnded(string memory tokenHash) external nonReentrant returns (bool) {
        require(_tokenHashExists[tokenHash], "Non-Existing NFT hash value....");
        
        if (_allNFTInfo[_getTokenIdFromHash[tokenHash]].mintingDate + _allNFTInfo[_getTokenIdFromHash[tokenHash]].auctionInterval < block.timestamp) {
            _allNFTInfo[_getTokenIdFromHash[tokenHash]].onSale = true;
        } else {
            _allNFTInfo[_getTokenIdFromHash[tokenHash]].onSale = false;    
        }

        emit IsAuctionEnded(tokenHash, _allNFTInfo[_getTokenIdFromHash[tokenHash]].onSale);

        return _allNFTInfo[_getTokenIdFromHash[tokenHash]].onSale;
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
        _mintingFees[creater] = amount;
    }

    function setSellingFee(address seller, uint24 ratio) external onlyOwner {
        require(seller != address(0), "Invalid input address...");
        require(ratio >= 0, "Too small ratio");
        require(ratio < 100, "Too large ratio");
        _sellingRatio[seller] = ratio;
    }
    
    function setRoyalty(string memory _tokenHash, address creator, uint24 ratio) public onlyAdmin {
        require(creator != address(0), "Invalid input address...");
        require(_tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");
        require(ratio >= 0, "Too small ratio");
        require(ratio < 100, "Too large ratio");
        _allNFTInfo[_getTokenIdFromHash[_tokenHash]].creator = creator;
        _allNFTInfo[_getTokenIdFromHash[_tokenHash]].royaltyRatio = ratio;
    }

    function getNFTCount() public view returns (uint256) {
        return allNFTCounter;
    }

    function getNFTInfo(string memory tokenHash) public view returns (NFTInfo memory result) {
        require(_tokenHashExists[tokenHash], "Non-Existing NFT hash value....");
        return _allNFTInfo[_getTokenIdFromHash[tokenHash]];
    }

    function getMintingFee(address creater) public view returns (uint256) {
        return _mintingFees[creater];
    }

    function getSellingRatio(address seller) public view returns (uint24) {
        return _sellingRatio[seller];
    }

    function getRoyaltyRecipient(string memory _tokenHash) public view returns (address) {
        require(_tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");
        return _allNFTInfo[_getTokenIdFromHash[_tokenHash]].creator;
    }

    function getRoyaltyRatio(string memory _tokenHash) public view returns (uint24) {
        require(_tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");
        return _allNFTInfo[_getTokenIdFromHash[_tokenHash]].royaltyRatio;
    }

    function getWithdrawBalance(uint8 kind) public view returns (uint256) {
        require(kind >= 0, "Invalid cryptocurrency...");

        if (kind == 0) {
          return address(this).balance;
        } else {
          return SPCToken.balanceOf(address(this));
        }
    }

    function transferToContract(address payable to, uint256 amount, uint8 kind) internal {
        require(to != address(0), "Invalid address...");
        require(amount >= 0, "Invalid transferring amount...");
        require(kind >= 0, "Invalid cryptocurrency...");
        
        if (kind == 0) {
          to.transfer(amount);
        } else {
          SPCToken.transfer(to, amount);
        }
    }

    function mintSpectraNFT(string memory _tokenHash, uint256 auctionInterval, uint256 _price, uint24 royaltyValue, uint8 kind) external payable nonReentrant onlyAdmin {
        require(!_tokenHashExists[_tokenHash], "Existing NFT hash value....");
        require(auctionInterval >= 0, "Invalid auction interval....");
        require(royaltyValue >= 0, "Invalid royalty value....");
        require(kind >= 0, "Invalid cryptocurrency...");

        _mint(msg.sender, allNFTCounter, 1, "");
        // transferToContract(mkOwner, _mintingFees[msg.sender], kind);
        _tokenHashExists[_tokenHash] = true;
        _getTokenIdFromHash[_tokenHash] = allNFTCounter;

        _allNFTInfo[allNFTCounter] = NFTInfo(allNFTCounter, _tokenHash, msg.sender, msg.sender, msg.sender, _price, block.timestamp, auctionInterval, kind, royaltyValue, true);
        allNFTCounter++;
    }

    function mintBatchSpectraNFT(string[] calldata _tokenHash, uint256 _price, uint24 royaltyValue, uint8 kind) external payable nonReentrant onlyAdmin {
        require(royaltyValue >= 0, "Invalid royalty value....");
        require(kind >= 0, "Invalid cryptocurrency...");

        uint256[] memory arrayTokenId = new uint256[](_tokenHash.length);
        uint256[] memory arrayTokenAmount = new uint256[](_tokenHash.length);

        for (uint256 i = 0; i < _tokenHash.length; i++) {
          require(!_tokenHashExists[_tokenHash[i]], "Existing NFT hash value....");

          arrayTokenId[i] = allNFTCounter;
          arrayTokenAmount[i] = 1;    
          _tokenHashExists[_tokenHash[i]] = true;
          _getTokenIdFromHash[_tokenHash[i]] = allNFTCounter;

          _allNFTInfo[allNFTCounter] = NFTInfo(allNFTCounter, _tokenHash[i], msg.sender, msg.sender, msg.sender, _price, block.timestamp, 0, kind, royaltyValue, true);   
          allNFTCounter++;
        }

        _mintBatch(msg.sender, arrayTokenId, arrayTokenAmount, "");
    }

    function putNFT2Marketplace(string memory _tokenHash, uint256 auctionInterval, uint256 price, uint8 kind) public nonReentrant onlyNFTOwner(_tokenHash) {
        require(_tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");

        if (_allNFTInfo[_getTokenIdFromHash[_tokenHash]].currentOwner != getRoyaltyRecipient(_tokenHash)) {
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastBidder = msg.sender;
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastPrice = price;
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].auctionInterval = auctionInterval;
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].kindOfCoin = kind;
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].onSale = true;
        }
        // _safeTransferFrom(msg.sender, address(this), _getTokenIdFromHash[_tokenHash], 1, "0x0");
    }

    function placeBid(string memory _tokenHash, uint8 kind) public notOnlyNFTOwner(_tokenHash) nonReentrant payable {
        require(_tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");

        if (_allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastPrice < msg.value) {
            if (_allNFTInfo[_getTokenIdFromHash[_tokenHash]].currentOwner != _allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastBidder) {
                transferToContract(payable(_allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastBidder), _allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastPrice, kind);
            }
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastBidder = msg.sender;
            _allNFTInfo[_getTokenIdFromHash[_tokenHash]].lastPrice = msg.value;
        }
    }

    function transferNFT(string memory _tokenHash, uint8 kind) nonReentrant external {
        require(_tokenHashExists[_tokenHash], "Non-Existing NFT hash value....");
        require(kind >= 0, "Invalid cryptocurrency...");

        uint256 indexOfToken = _getTokenIdFromHash[_tokenHash];
        uint256 price = _allNFTInfo[indexOfToken].lastPrice;
        address ownerOfNFT = _allNFTInfo[indexOfToken].currentOwner;
        address lastBidder = _allNFTInfo[indexOfToken].lastBidder;
        
        safeTransferFrom(ownerOfNFT, lastBidder, indexOfToken, 1, "0x0");

        uint256 royaltyAmount = getRoyaltyRatio(_tokenHash);
        uint256 salePrice = price - price * getSellingRatio(ownerOfNFT) / 100 - price * royaltyAmount / 100;

        transferToContract(payable(getRoyaltyRecipient(_tokenHash)), price * royaltyAmount / 100, kind);
        transferToContract(payable(ownerOfNFT), salePrice, kind);

        _allNFTInfo[indexOfToken].currentOwner = payable(lastBidder);
        _allNFTInfo[indexOfToken].onSale = false;
    }

    function withDraw(uint256 amount, uint8 kind) external onlyOwner {
        require(amount > 0, "Invalid withdraw amount...");
        require(kind >= 0, "Invalid cryptocurrency...");
        require(getWithdrawBalance(kind) > amount, "None left to withdraw...");

        transferToContract(payable(msg.sender), amount, kind);
    }

    function withDrawAll(uint8 kind) external onlyOwner {
        require(kind >= 0, "Invalid cryptocurrency...");
        uint256 remaining = getWithdrawBalance(kind);
        require(remaining > 0, "None left to withdraw...");

        transferToContract(payable(msg.sender), remaining, kind);
    }

    event IsAuctionEnded(string indexed tokenHash, bool indexed inEnded);
}