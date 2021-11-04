// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IArkarusNFT.sol";

contract ArkarusNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;
    
    Counters.Counter private _tokenIds;

    address public busdTokenAddress;
    address public aksTokenAddress;
    address public beneficiaryAddress;
    address private marketplaceAddress;

    string internal baseUri;
    
    string private bronzeGachaURI = "gachabox/BronzeBox";
    string private goldGachaURI = "gachabox/GoldBox";
    string private platinumGachaURI = "gachabox/PlatinumBox";
    
    constructor() public ERC721("Arkarus NFT", "AKSNFT") {}

    uint8 constant BRONZE_BOX = 1;
    uint8 constant GOLD_BOX = 2;
    uint8 constant PLATINUM_BOX = 3;

    uint8 constant ROBOT = 1;
    //uint8 constnat MOTHERSHIP = 2;

    mapping(uint256 => uint8) public tokenType;
    
    mapping(uint256 => uint8) public gachaBoxType;
    
    mapping(uint => uint) public roundsStartTime;
    mapping(uint => uint) public roundsEndTime;
    mapping(address => uint) public accountRoundId;
    mapping(uint => uint) public roundsAccountCount;

    mapping(uint8 => uint8) public gachaPerBox;
    mapping(uint8 => uint) public priceGachaBox;
    mapping(uint => uint256) public maxGachaBoxPerTime;
    
    mapping(uint256 => mapping(uint8 => uint256)) public gachaLimit;
    mapping(uint256 => mapping(uint8 => uint256)) public gachaCounter;
    
    mapping(uint => mapping(uint8 => uint256)) public maxGachaBoxPerAccount;
    mapping(uint8 => mapping(address => uint)) public accountLimitGachaBox;
    mapping(uint8 => mapping(address => uint)) public gachaBoxBalance;

    event MintGachaBox(address indexed _from, uint8 _boxType, uint _amount);
    event OpenGachaBox(uint256[] tokenIds);

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
    {
        require(msg.sender == marketplaceAddress, "Permission denied");
        super.transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721)
    {
        require(msg.sender == marketplaceAddress, "Permission denied");
        super.safeTransferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
        override(ERC721)
    {
        require(msg.sender == marketplaceAddress, "Permission denied");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    modifier hasWhitelistRegistered() {
        require(roundId(msg.sender) != 0, "The account is not whitelist listed.");
        _;
    }
    
    modifier isPresaleOpen(){
       uint _roundId = accountRoundId[msg.sender];
       require(roundsStartTime[_roundId] !=0 && roundsEndTime[_roundId] !=0 ,"Presale hasn't started.");
       require(roundsStartTime[_roundId] <= timeNow(), "Presale hasn't started.");
       require(roundsEndTime[_roundId] >= timeNow(), "Presale has closed.");
        _;
    }

    uint private timestamp;
    
    function setTimeNow(uint _timestamp) public onlyOwner {
        timestamp = _timestamp;
    }

    function timeNow() internal view returns(uint) {
        if(timestamp != 0) {
            return timestamp;
        }
        return (block.timestamp.mul(1000));
    }

    function setPresaleTime(uint _roundId, uint _startTime, uint _endTime) external onlyOwner {
        roundsStartTime[_roundId] = _startTime;
        roundsEndTime[_roundId] = _endTime;
    }
    
    function importWhitelist(address[] memory _accounts, uint _roundId) public onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++) {
            accountRoundId[_accounts[i]] = _roundId;
            roundsAccountCount[_roundId] = roundsAccountCount[_roundId].add(1);
        }
    }
    
    function roundId(address _account) public view returns(uint) {
        return accountRoundId[_account];
    }
    
    function canAccessPresale(address _account) public view returns(uint) {
        
        uint _roundId = accountRoundId[_account];

        if(_roundId == 0) {
            return 0;
        }

        require(roundsStartTime[_roundId] !=0 && roundsEndTime[_roundId] !=0 ,"Presale hasn't started.");

        if(timeNow() >= roundsEndTime[_roundId]) {
            return 3;
        }else if (timeNow() >= roundsStartTime[_roundId] && timeNow() <= roundsEndTime[_roundId]) {
            return 2;
        }else{
            return 1;
        }
    }

    function setNewBronzeGachaURI(string memory newBronzeGachaURI) public onlyOwner
    {
        bronzeGachaURI = newBronzeGachaURI;
    }
    
    function setNewGoldGachaURI(string memory newGoldGachaURI) public onlyOwner
    {
        goldGachaURI = newGoldGachaURI;
    }
    
    function setNewPlatinumGachaURI(string memory newPlatinumGachaURI) public onlyOwner
    {
        platinumGachaURI = newPlatinumGachaURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner
    {
        baseUri = newBaseURI;
    }
    
    function setBUSDTokenAddress(address _address) public onlyOwner
    {
        busdTokenAddress = _address;
    }
    
    function setBeneficiaryAddress(address _address) public onlyOwner
    {
        beneficiaryAddress = _address;
    }

    function setMarketplaceAddress(address newMarketplaceAddress) public onlyOwner
    {
        marketplaceAddress = newMarketplaceAddress;
    }

    function availableGachaBoxPerAccount(uint8 _boxType, address _account) private view returns(uint) {
        return maxGachaBoxPerAccount[roundId(_account)][_boxType] - accountLimitGachaBox[_boxType][_account];
    }

    function setGachaBoxPool(uint _roundId, uint256 _maxPerTime, uint256 _maxBronzeBox, uint256 _maxGoldBox, uint256 _maxPlatinumBox) external onlyOwner 
    {
        maxGachaBoxPerTime[_roundId] = _maxPerTime;
        gachaLimit[_roundId][BRONZE_BOX] = _maxBronzeBox;
        gachaLimit[_roundId][GOLD_BOX] = _maxGoldBox;
        gachaLimit[_roundId][PLATINUM_BOX] = _maxPlatinumBox;
    }
    
    function setMaxGachaBoxPerAccount(uint _roundId, uint256 _maxBronzeBox, uint256 _maxGoldBox, uint256 _maxPlatinumBox) external onlyOwner
    {
        maxGachaBoxPerAccount[_roundId][BRONZE_BOX] = _maxBronzeBox;
        maxGachaBoxPerAccount[_roundId][GOLD_BOX] = _maxGoldBox;
        maxGachaBoxPerAccount[_roundId][PLATINUM_BOX] = _maxPlatinumBox;
    }
    
    function setPriceGachaBox(uint256 _priceBronzeBox, uint256 _priceGoldBox, uint256 _pricePlatinumBox)  external onlyOwner 
    {
        priceGachaBox[BRONZE_BOX] = _priceBronzeBox * 10 ** 18;
        priceGachaBox[GOLD_BOX] = _priceGoldBox * 10 ** 18;
        priceGachaBox[PLATINUM_BOX] = _pricePlatinumBox * 10 ** 18;
    }

    function mintGachaBox(uint8 _boxType, uint _amount) external hasWhitelistRegistered() isPresaleOpen() returns (uint256) 
    {
        uint _roundId = roundId(msg.sender);
        
        require(_boxType==1 || _boxType==2 || _boxType==3, 'invalid box type');
        require(_amount > 0 && _amount <= maxGachaBoxPerTime[_roundId], "Your amount is invalid.");
        require(_amount <= gachaLimit[_roundId][_boxType], 'This gacha box reaches limit');
        require(availableGachaBoxPerAccount(_boxType, msg.sender) >= _amount, "This gacha box reaches limit");

        gachaBoxPayment(priceGachaBox[_boxType], _amount);
        gachaLimit[_roundId][_boxType] = gachaLimit[_roundId][_boxType] - _amount;

        uint256 newItemId;
        for(uint countGachaBox = 0 ; countGachaBox < _amount ; countGachaBox++)
        {
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, bronzeGachaURI);
            gachaBoxType[newItemId] = _boxType;
            gachaBoxBalance[_boxType][msg.sender] = gachaBoxBalance[_boxType][msg.sender].add(1);
            accountLimitGachaBox[_boxType][msg.sender] = accountLimitGachaBox[_boxType][msg.sender].add(1);
        }

        emit MintGachaBox(msg.sender, _boxType, _amount);
        return newItemId;
    }

    function setGachaPerBox(uint8 gachaPerBronze, uint8 gachaPerGold, uint8 gachaPerPlatinum) external onlyOwner
    {
        gachaPerBox[BRONZE_BOX] = gachaPerBronze;
        gachaPerBox[GOLD_BOX] = gachaPerGold;
        gachaPerBox[PLATINUM_BOX] = gachaPerPlatinum;
    }

    function gachaBoxPayment(uint256 price, uint amount) internal
    {
        IERC20 _BUSDtokenAddress = IERC20(busdTokenAddress);
        uint256 _balance = _BUSDtokenAddress.balanceOf(msg.sender);
        uint256 _totalPrice = price * amount;
        require(_balance >= _totalPrice, "Your balance is insufficient.");
        _BUSDtokenAddress.transferFrom(msg.sender, beneficiaryAddress, _totalPrice);
    }
    
    function mintOpenGacha(uint8 boxType) external
    {
        require(boxType==1 || boxType==2 || boxType==3, 'this box type is not correct');
        require(gachaPerBox[boxType] > 0, 'Please, set gacha per box type');
        require(getAccountBoxes(boxType) > 0, 'No box available');
        mintRobot(findBoxTokenId(boxType), boxType);
    }

    function findBoxTokenId(uint8 boxType) internal returns (uint256)
    {
        uint256 currentToken = 0;
        for(uint256 tokenCounter = 0; tokenCounter < balanceOf(msg.sender); tokenCounter++)
        {
            currentToken = getToken(tokenCounter);
            if(gachaBoxType[currentToken] == boxType)
            {
                delete gachaBoxType[currentToken];
                break;
            }
        }
        return currentToken;
    }

    function mintRobot(uint256 boxTokenId, uint8 boxType) internal
    {
        _burn(boxTokenId);
        uint256[] memory newTokenIds = new uint256[](gachaPerBox[boxType]);
        for(uint mintGachaCounter = 0; mintGachaCounter < gachaPerBox[boxType]; mintGachaCounter++)
        {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            _setTokenURI(newItemId, string(abi.encodePacked('robots/', newItemId.toString())));
            tokenType[newItemId] = ROBOT;
            newTokenIds[mintGachaCounter] = newItemId;
        }
        emit OpenGachaBox(newTokenIds);
    }
    
    function getToken(uint256 index) public view returns (uint256)
    {
        return ERC721Enumerable.tokenOfOwnerByIndex(msg.sender, index);
    }
    
    function getAccountBoxes(uint8 boxType) public view returns (uint256)
    {
        require(boxType==1 || boxType==2 || boxType==3, 'this box type is not correct');
        uint totalBox = 0;
        for(uint boxCounter = 0; boxCounter < balanceOf(msg.sender); boxCounter++)
        {
            if(gachaBoxType[getToken(boxCounter)] == boxType)
            {
                totalBox = totalBox.add(1);
            }
        }
        return totalBox;
    }
    
    function getAvailableGachaBox(uint _roundId) public view returns (uint256[] memory)
    {
        uint256[] memory availableGachaBox = new uint256[](3);
        availableGachaBox[0] = gachaLimit[_roundId][BRONZE_BOX] - gachaCounter[_roundId][BRONZE_BOX];
        availableGachaBox[1] = gachaLimit[_roundId][GOLD_BOX] - gachaCounter[_roundId][GOLD_BOX];
        availableGachaBox[2] = gachaLimit[_roundId][PLATINUM_BOX] - gachaCounter[_roundId][PLATINUM_BOX];
        return availableGachaBox;
    }
}