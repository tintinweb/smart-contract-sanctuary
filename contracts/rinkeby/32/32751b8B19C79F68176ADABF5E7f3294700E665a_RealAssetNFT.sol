// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol"; 
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

contract RealAssetNFT is
    VRFConsumerBase,
    ERC1155,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    bool public ended = false;
    bool public revealed = false;
    bool private isrequestfulfilled;

    uint256 public immutable MaxSupply; 
    uint256 public immutable saleStartTime;
    uint256 public immutable preSaleStartTime;
    uint256 public immutable preSaleEndTime;
    uint256 public immutable preSaleDuration;
    uint256 public constant publicSaleBufferDuration=30;
    uint256 public constant maxTokenPerMint = 5; 
    uint256 public immutable mintCost;
    uint256 private currentTokenId = 0;    
    uint256 public totalMint = 0;
    uint256 public constant BigPrimeNumber = 9973;

    uint256 private constant fee  = 2 * 10 ** 18;
    uint256 private randomNumber;
    bytes32 internal keyHash;
    bytes32 public vrfRequestId;
    
    string public baseTokenURI;
    mapping(address => uint256) public presalerListPurchases;
    address private immutable signerAddress;

    modifier preSaleEnded {
        require(block.timestamp > preSaleEndTime, "Sorry, the pre-sale is not yet ended");
        _;
    }

    modifier saleNotEnded {
        require(!ended, "Sorry, the sale is ended");
        _;
    }

    modifier saleEnded {
        require(ended, "Sorry, the sale not yet ended");
        _;
    }

    modifier saleStarted {
        require(block.timestamp >= saleStartTime, "Sorry, the sale is not yet started");
        _;
    }

    event URI(string uri);
    event RandomNumberRequested( address indexed sender,bytes32 indexed vrfRequestId);
    event RandomNumberCompleted(bytes32 indexed requestId, uint256 randomNumber);
    event SaleEnded(address account);
    event TokensRevealed(uint256 time);

    constructor(address _vrfCoordinator, address _link , bytes32 _keyHash , string memory _metadataBaseUri , uint256 _mintCost , uint256 _maxSuppply,uint256 _preSaleStartTime ,uint256 _preSaleDuration,address _signerAddress)
        VRFConsumerBase(_vrfCoordinator, _link)ERC1155(_metadataBaseUri)
    { 
        require(block.timestamp <= _preSaleStartTime,"Presale start time must be greater then current time");
        require(_maxSuppply > 0,"Maximum token supply must be greator then zero");
        require(_preSaleDuration > 0,"Presale duration must be greater then zero");
        require(_mintCost > 0,"Token cost must be greater then zero wei");

        mintCost = _mintCost;
        keyHash = _keyHash;
        baseTokenURI = _metadataBaseUri;
        MaxSupply = _maxSuppply;
        signerAddress = _signerAddress;
        preSaleStartTime = _preSaleStartTime;
        preSaleDuration = _preSaleDuration;
        preSaleEndTime = _preSaleDuration + _preSaleStartTime;
        saleStartTime = _preSaleDuration + _preSaleStartTime + publicSaleBufferDuration;
    }

    function hashMessage(address sender,uint256 chainId,uint256 tokenQuantity) private pure returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender,chainId,tokenQuantity)))
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return signerAddress == hash.recover(signature);
    }
    
    function preSalebuy(uint256 tokenSignQuantity,uint256 tokenQuantity,bytes memory signature)   external nonReentrant() payable   {
        bytes32 hash = hashMessage(msg.sender,block.chainid,tokenSignQuantity);
        require(tokenQuantity > 0 && tokenSignQuantity > 0,"Token quantity to mint must be greter then zero");
        require(block.timestamp >= preSaleStartTime, "Sorry, the pre-sale is not yet started");
        require(block.timestamp <= preSaleEndTime, "Sorry, the pre-sale is ended");
        require(matchAddressSigner(hash, signature), "Sorry, you are not a whitelisted user");
        require((totalMint + tokenQuantity) <= MaxSupply,"Sorry, can't be purchased as exceed max supply.");
        require((mintCost * tokenQuantity) <= msg.value,"you need to pay the minimum token price.");
        require(msg.sender != address(0),"ERC1155: mint to the zero address");
        require(presalerListPurchases[msg.sender] + tokenQuantity  <= tokenSignQuantity, "Sorry,can't be purchased as exceed maxm allowed limit");

        for(uint256 i = 0; i < tokenQuantity; i++) {
            _incrementTokenId();
            _mint(msg.sender, currentTokenId, 1, "");
            presalerListPurchases[msg.sender]++;
            totalMint += uint256(1);
        }
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }

    function isPreSaleLive() external view  returns(bool) {
        return (block.timestamp >= preSaleStartTime && block.timestamp <= preSaleEndTime);
    }

    function isPublicSaleLive() external view  returns(bool) {
        return (block.timestamp >= saleStartTime && !ended);
    }

    function mint(uint256 tokenQuantity) external nonReentrant() payable saleNotEnded saleStarted preSaleEnded {
        require(tokenQuantity > 0,"Token quantity to mint must be greter then zero");
        require(tokenQuantity <= maxTokenPerMint, "Limit exceed to purchase in single mint");
        require((totalMint + tokenQuantity) <= MaxSupply,"Sorry, can't be purchased as exceed max supply.");
        require((mintCost * tokenQuantity) <= msg.value, "you need to pay the minimum token price.");
        require(msg.sender != address(0),"ERC1155: mint to the zero address");

        for(uint256 i = 0; i < tokenQuantity; i++) {
            _incrementTokenId();
            _mint(msg.sender, currentTokenId, 1, "");
            totalMint += uint256(1);
        }        
    }

    function endSale() external onlyOwner saleStarted saleNotEnded {
        ended = true;
        emit SaleEnded(msg.sender);
    }
    
    function requestRandomNumber() external onlyOwner saleStarted saleEnded returns (bytes32, uint32) {
        require( !isrequestfulfilled , "Already obtained the random no");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK tokens available");

        uint32 lockBlock = uint32(block.number);
        vrfRequestId = requestRandomness(keyHash, fee);
        emit RandomNumberRequested( msg.sender ,vrfRequestId);
        return (vrfRequestId, lockBlock);
    }

    function revealTokens(string memory _uri) external onlyOwner saleStarted saleEnded {
        require(isrequestfulfilled, "Random entropy has not been assigned");
        require(!revealed, "Already revealed");

        revealed = true;
        baseTokenURI = _uri;
        _setURI(_uri);
        emit TokensRevealed(block.timestamp);
        emit URI(_uri);
    }
    
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        randomNumber = _randomness;
        isrequestfulfilled = true; 
        emit RandomNumberCompleted(_requestId, _randomness);
    }

    function getAssetId(uint256 _tokenID) external view saleStarted returns(uint256){
        require(_tokenID > 0 && _tokenID <= MaxSupply, "Invalid token Id");
        require( isrequestfulfilled , "Please wait for random number to be assigned");

        uint256 assetID = BigPrimeNumber * _tokenID + ( randomNumber % BigPrimeNumber);
        assetID = assetID%MaxSupply;
        if(assetID == 0) assetID = MaxSupply;
        return assetID;
    }

    function getRandomNumber() external view  saleStarted returns(uint256) {
        require(isrequestfulfilled , "Please wait for random number to be assigned");

        return randomNumber;
    }

    function _incrementTokenId() private {
        require(currentTokenId < MaxSupply, "token Id limit reached");

        currentTokenId++;
    }

    function setURI(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
        _setURI(_uri);
        emit URI(_uri);
    }

    function getBalanceEther() external view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function getBalanceLink() external view onlyOwner returns(uint256) {
        return LINK.balanceOf(address(this));
    }

    function withdrawEth(uint256 _amount) external onlyOwner nonReentrant(){
        require(_amount > 0, "Amount should be greater then zero");
        require(address(this).balance >= _amount , "Not enough eth balance to withdraw");

        payable(msg.sender).transfer(_amount);
    }
    
    function getLinkAddress() external view returns (address) {
        return address(LINK);
    }

    function withdrawLink(uint256 _amount) external onlyOwner nonReentrant() {
        require(_amount > 0, "Amount should be greater then zero");
        require(LINK.balanceOf(address(this)) >= _amount, "Not enough LINK tokens available");
        
        LINK.transfer(msg.sender , _amount);
    }
    
    function uri(uint256 _tokenID) public view override returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(_tokenID), (_tokenID.toString())));
    }
}