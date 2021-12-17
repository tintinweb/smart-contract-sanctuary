// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "ERC721URIStorage.sol";
import "ERC721Enumerable.sol";
import "IERC20.sol";
import "SafeMath.sol";

contract ArkarusNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;
    
    Counters.Counter private _tokenIds;

    address public busdTokenAddress;
    address public aksTokenAddress;
    address public beneficiaryAddress;
    address[] public approvedNFTTransferAddress;

    string internal baseUri;
    
    constructor() public ERC721("Arkarus NFT", "AKSNFT") {}

    uint8 constant MYSTERIOUSCONTAINER_BOX = 1;
    uint8 constant MYSTERIOUSCARGO_BOX = 2;
    uint8 constant BATTALIONPACK_BOX = 3;

    bool public isPublicGachaSaleOpen = false;
    uint private timestamp;

    mapping(uint256 => uint8) public gachaBoxType;
    
    mapping(uint => uint) public roundsStartTime;
    mapping(uint => uint) public roundsEndTime;
    mapping(address => uint) public accountRoundId;
    mapping(uint => uint) public roundsAccountCount;

    mapping(uint8 => uint) public priceGachaBox;
    mapping(uint => uint256) public maxGachaBoxPerTime;
    
    mapping(uint256 => mapping(uint8 => uint256)) public maxPrivateGachaBoxPerRound;
    mapping(uint256 => mapping(uint8 => uint256)) public gachaLimit;
    mapping(uint256 => mapping(uint8 => uint256)) public gachaCounter;
    
    mapping(uint => mapping(uint8 => uint256)) public maxGachaBoxPerAccount;
    mapping(uint8 => mapping(address => uint)) public accountLimitGachaBox;
    mapping(uint8 => mapping(address => uint)) public gachaBoxBalance;

    event MintGachaBox(address indexed _from, uint8 _boxType, uint _amount);

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721)
    {
        require(isApprovedNFTTransferAddress(msg.sender) == true, "Permission denied");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721)
    {
        require(isApprovedNFTTransferAddress(msg.sender) == true, "Permission denied");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721)
    {
        require(isApprovedNFTTransferAddress(msg.sender) == true, "Permission denied");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function setApprovedNFTTransferAddress(address[] memory _accounts) external onlyOwner 
    {
        for(uint256 i = 0; i < _accounts.length; i++) 
        {
            approvedNFTTransferAddress.push(_accounts[i]);
        }
    }

    function removeApprovedNFTTransferAddress() external onlyOwner 
    {
        delete approvedNFTTransferAddress;
    }

    function isApprovedNFTTransferAddress(address sender) internal view returns (bool)
    {
        for(uint256 i = 0; i < approvedNFTTransferAddress.length; i++) 
        {
            if(sender == approvedNFTTransferAddress[i]){
                return true;
            }
        }
        return false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) 
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    modifier hasWhitelistRegistered() 
    {
        require(roundId(msg.sender) != 0, "The account is not whitelist listed.");
        _;
    }
    
    modifier isPresaleOpen()
    {
       uint _roundId = accountRoundId[msg.sender];
       require(roundsStartTime[_roundId] !=0 && roundsEndTime[_roundId] !=0 ,"Presale hasn't started.");
       require(roundsStartTime[_roundId] <= timeNow(), "Presale hasn't started.");
       require(roundsEndTime[_roundId] >= timeNow(), "Presale has closed.");
        _;
    }
    
    function setTimeNow(uint _timestamp) public onlyOwner 
    {
        timestamp = _timestamp;
    }

    function timeNow() internal view returns(uint) 
    {
        if(timestamp != 0) {
            return timestamp;
        }
        return (block.timestamp.mul(1000));
    }

    function setPresaleTime(uint _roundId, uint _startTime, uint _endTime) external onlyOwner 
    {
        roundsStartTime[_roundId] = _startTime;
        roundsEndTime[_roundId] = _endTime;
    }
    
    function importWhitelist(address[] memory _accounts, uint _roundId) public onlyOwner 
    {
        for(uint256 i = 0; i < _accounts.length; i++) {
            accountRoundId[_accounts[i]] = _roundId;
            roundsAccountCount[_roundId] = roundsAccountCount[_roundId].add(1);
        }
    }
    
    function roundId(address _account) public view returns(uint) 
    {
        return accountRoundId[_account];
    }
    
    function canAccessPresale(address _account) public view returns(uint) 
    {
        
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

    function _baseURI() internal view override returns (string memory) 
    {
        return baseUri;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner
    {
        baseUri = newBaseURI;
    }
    
    function setIsPublicSaleOpen(bool _publicSale) external onlyOwner
    {
        isPublicGachaSaleOpen = _publicSale;
    }

    function setBUSDTokenAddress(address _address) external onlyOwner
    {
        busdTokenAddress = _address;
    }
    
    function setBeneficiaryAddress(address _address) external onlyOwner
    {
        beneficiaryAddress = _address;
    }

    function availableGachaBoxPerAccount(uint8 _boxType, address _account) private view returns(uint) {
        return maxGachaBoxPerAccount[roundId(_account)][_boxType] - accountLimitGachaBox[_boxType][_account];
    }

    function setGachaBoxPool(uint _roundId, uint256 _maxPerTime, uint256 _maxPrivateMysteriousContainerBox, uint256 _maxPrivateMysteriousCargoBox, uint256 _maxMysteriousContainerBox, uint256 _maxPrivateBattalionPackBox, uint256 _maxMysteriousCargoBox, uint256 _maxBattalionPackBox) external onlyOwner 
    {
        maxGachaBoxPerTime[_roundId] = _maxPerTime;
        maxPrivateGachaBoxPerRound[_roundId][MYSTERIOUSCONTAINER_BOX] = _maxPrivateMysteriousContainerBox;
        maxPrivateGachaBoxPerRound[_roundId][MYSTERIOUSCARGO_BOX] = _maxPrivateMysteriousCargoBox;
        maxPrivateGachaBoxPerRound[_roundId][BATTALIONPACK_BOX] = _maxPrivateBattalionPackBox;
        gachaLimit[_roundId][MYSTERIOUSCONTAINER_BOX] = _maxMysteriousContainerBox;
        gachaLimit[_roundId][MYSTERIOUSCARGO_BOX] = _maxMysteriousCargoBox;
        gachaLimit[_roundId][BATTALIONPACK_BOX] = _maxBattalionPackBox;
    }
    
    function setMaxGachaBoxPerAccount(uint _roundId, uint256 _maxMysteriousContainerBox, uint256 _maxMysteriousCargoBox, uint256 _maxBattalionPackBox) external onlyOwner
    {
        maxGachaBoxPerAccount[_roundId][MYSTERIOUSCONTAINER_BOX] = _maxMysteriousContainerBox;
        maxGachaBoxPerAccount[_roundId][MYSTERIOUSCARGO_BOX] = _maxMysteriousCargoBox;
        maxGachaBoxPerAccount[_roundId][BATTALIONPACK_BOX] = _maxBattalionPackBox;
    }
    
    function setPriceGachaBox(uint256 _priceMysteriousContainerBox, uint256 _priceMysteriousCargoBox, uint256 _priceBattalionPackBox)  external onlyOwner 
    {
        priceGachaBox[MYSTERIOUSCONTAINER_BOX] = _priceMysteriousContainerBox * 10 ** 18;
        priceGachaBox[MYSTERIOUSCARGO_BOX] = _priceMysteriousCargoBox * 10 ** 18;
        priceGachaBox[BATTALIONPACK_BOX] = _priceBattalionPackBox * 10 ** 18;
    }

    function privateGachaBox(uint8 _boxType, uint _amount) external hasWhitelistRegistered() isPresaleOpen()
    {     
        uint _roundId = roundId(msg.sender);
        require(_amount <= maxPrivateGachaBoxPerRound[_roundId][_boxType], "This gacha box reaches limit.");  

        maxPrivateGachaBoxPerRound[_roundId][_boxType] = maxPrivateGachaBoxPerRound[_roundId][_boxType] - _amount;

        mintGachaBox(_boxType, _amount);
    }

    function publicGachaBox(uint8 _boxType, uint _amount) external
    {
        require(isPublicGachaSaleOpen == true, "Public sale is not open.");

        mintGachaBox(_boxType, _amount);
    }

    function mintGachaBox(uint8 _boxType, uint _amount) internal
    {
        uint _roundId = roundId(msg.sender);
        
        require(_boxType==1 || _boxType==2 || _boxType==3, "invalid box type.");
        require(_amount > 0 && _amount <= maxGachaBoxPerTime[_roundId], "Your amount is invalid.");
        require(_amount <= gachaLimit[_roundId][_boxType], "This gacha box reaches limit.");
        require(availableGachaBoxPerAccount(_boxType, msg.sender) >= _amount, "This gacha box reaches limit.");

        gachaBoxPayment(priceGachaBox[_boxType], _amount);
        gachaLimit[_roundId][_boxType] = gachaLimit[_roundId][_boxType] - _amount;

        uint256 newItemId;
        for(uint countGachaBox = 0 ; countGachaBox < _amount ; countGachaBox++)
        {
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            gachaBoxType[newItemId] = _boxType;
            gachaBoxBalance[_boxType][msg.sender] = gachaBoxBalance[_boxType][msg.sender].add(1);
            accountLimitGachaBox[_boxType][msg.sender] = accountLimitGachaBox[_boxType][msg.sender].add(1);
        }

        emit MintGachaBox(msg.sender, _boxType, _amount);
    }

    function gachaBoxPayment(uint256 price, uint amount) internal
    {
        IERC20 _BUSDtokenAddress = IERC20(busdTokenAddress);
        uint256 _balance = _BUSDtokenAddress.balanceOf(msg.sender);
        uint256 _totalPrice = price * amount;
        require(_balance >= _totalPrice, "Your balance is insufficient.");
        _BUSDtokenAddress.transferFrom(msg.sender, beneficiaryAddress, _totalPrice);
    }

    function burnOpenGacha(uint8 boxType) external
    {
        require(boxType==1 || boxType==2 || boxType==3, 'this box type is not correct');
        require(getAccountBoxes(boxType) > 0, 'No box available');
        _burn(findBoxTokenId(boxType));
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
        availableGachaBox[0] = gachaLimit[_roundId][MYSTERIOUSCONTAINER_BOX] - gachaCounter[_roundId][MYSTERIOUSCONTAINER_BOX];
        availableGachaBox[1] = gachaLimit[_roundId][MYSTERIOUSCARGO_BOX] - gachaCounter[_roundId][MYSTERIOUSCARGO_BOX];
        availableGachaBox[2] = gachaLimit[_roundId][BATTALIONPACK_BOX] - gachaCounter[_roundId][BATTALIONPACK_BOX];
        return availableGachaBox;
    }
}