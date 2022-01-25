/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: wavesminter.sol



pragma solidity ^0.8.4;


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


interface IERC721 {
    function safeMint(address to, string memory uri) external;
}


contract WavesMinter is Ownable, ReentrancyGuard {

    using Counters for Counters.Counter; 

    AggregatorV3Interface internal priceFeed;

    Counters.Counter private _mintedPigsCount; 
    Counters.Counter private _mintedThievesCount; 
    
    mapping(address => bool) private _whitelist; // for presale 
    mapping(address => bool) private _whitelistGiveaway; // for giveaway 
    mapping(address => uint) private _mintedAddresses; 
    mapping(address => uint) private _mintedAddressesGiveaway; 
    
    mapping(uint => bool) private _mintedPigId; 
    mapping(uint => bool) private _mintedThiefId; 

    address private _pigs;   // 0 
    address private _thieves; // 1 

    enum SaleStatus {
        Disable,  // 0
        Presale,  // 1
        Wave1,    // 2
        Wave2,    // 3
        Wave3,    // 4
        Giveaway  // 5
    }

    SaleStatus private _sale; // must be Disable, if sale not active
    bool private _saleOn; // true if sale enabled
    
    uint private constant MAX_PER_WALLET = 3;
    uint private constant MAX_PER_WALLET_GIVEAWAY = 1;

    // max counts for sale
    uint private constant MAX_PIG_PER_PRESALE = 1125;
    uint private constant MAX_THIEF_PER_PRESALE = 1125;
    uint private constant MAX_PER_PRESALE = 2250;

    uint private constant MAX_PIG_PER_WAVE1 = 2250;
    uint private constant MAX_THIEF_PER_WAVE1 = 2250;
    uint private constant MAX_PER_WAVE1 = 4500;

    uint private constant MAX_PIG_PER_WAVE2 = 3750;
    uint private constant MAX_THIEF_PER_WAVE2 = 3750;
    uint private constant MAX_PER_WAVE2 = 7500;

    uint private constant MAX_PIG_PER_WAVE3 = 12500;
    uint private constant MAX_THIEF_PER_WAVE3 = 12500;
    uint private constant MAX_PER_WAVE3 = 25000;

    uint private constant MAX_PIG_PER_GIVEAWAY = 13000;
    uint private constant MAX_THIEF_PER_GIVEAWAY = 13000;
    uint private constant MAX_PER_GIVEAWAY = 26000;

    // ids
    uint private constant MIN_PIG_ID = 0;
    uint private constant MAX_PIG_ID = 12499;

    uint private constant MIN_THIEF_ID = 12500;
    uint private constant MAX_THIEF_ID = 24999;

    uint private constant MIN_PIG_ID_GIVEAWAY = 25000;
    uint private constant MAX_PIG_ID_GIVEAWAY = 25499;

    uint private constant MIN_THIEF_ID_GIVEAWAY = 25499;
    uint private constant MAX_THIEF_ID_GIVEAWAY = 25999;

    // price
    uint private PRESALE_PRICE = 75000;       // 750.00 
    uint private FIRST_WAVE_PRICE = 93750;    // 937.50
    uint private SECOND_WAVE_PRICE = 112500;  // 1125.00
    uint private THIRD_WAVE_PRICE = 131250;   // 1312.50

    constructor(address pigs, address thieves) {
        _pigs = pigs;
        _thieves = thieves;

        _sale = SaleStatus.Disable;
        _saleOn = false;

        /**
        * Network: Rinkeby
        * Aggregator: ETH/USD
        * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        */
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        /**
        * Network: Ethereum
        * Aggregator: ETH/USD
        * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        */
        // priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    modifier mintInfo(address to, uint price, uint contractNum) {
        require(_mintedAddresses[to] + 1 <= MAX_PER_WALLET, "WavesMinter: Mints token limit exhausted");     
        require(msg.value >= price, "WavesMinter: Insufficient funds");
        require(to != address(0), "WavesMinter: Token receiver is zero address");
        require(contractNum == 0 || contractNum == 1, "WavesMinter: Incorrect contract number");
        _;
    }


    // ------------------- WRITE FUNCTIONS -------------------


    function enableSale() public onlyOwner {
        require(!saleOn(), "WavesMinter: Sale already enabled");
        
        _sale = SaleStatus.Presale;
        _saleOn = true;
    }

    // price (example: 100000 == 1000.00 usd, 75050 == 750.50 usd)
    function updatePresalePrice(uint newPrice) public onlyOwner {
        PRESALE_PRICE = newPrice;
    }

    function updateWave1Price(uint newPrice) public onlyOwner {
        FIRST_WAVE_PRICE = newPrice;
    }

    function updateWave2Price(uint newPrice) public onlyOwner {
        SECOND_WAVE_PRICE = newPrice;
    }

    function updateWave3Price(uint newPrice) public onlyOwner {
        THIRD_WAVE_PRICE = newPrice;
    }

    // whitelist
    function addToWhiteListBatch(address[] memory whitelist) public onlyOwner {
        for(uint i=0; i<whitelist.length; i++) {
            _whitelist[whitelist[i]] = true;
        }
    }

    function addToWhiteList(address account) public onlyOwner {
        _whitelist[account] = true;
    }

    function addToWhiteListGiveawayBatch(address[] memory whitelist) public onlyOwner {
        for(uint i=0; i<whitelist.length; i++) {
            _whitelistGiveaway[whitelist[i]] = true;
        }
    }

    function addToWhiteListGiveaway(address account) public onlyOwner {
        _whitelistGiveaway[account] = true;
    }

    // mint
    function mintPresale(
        uint contractNumber,
        uint id // for uri 
    ) 
        public payable 
        nonReentrant  
        mintInfo(_msgSender(), getSalePrice(PRESALE_PRICE), contractNumber) 
    {                          // 1$ for test
        address to = _msgSender(); // token receiver
        require(_sale == SaleStatus.Presale, "WavesMinter: Presale is not active");
        require(_whitelist[to], "WavesMinter: Token receiver is not in the whitelist");   
        
        if(contractNumber == 0) {
            require(_mintedPigsCount.current() + 1 <= MAX_PIG_PER_PRESALE, "WavesMinter: All pigs already minted on presale");
            _mintPig(to, id);
        } else if (contractNumber == 1) {
            require(_mintedThievesCount.current() + 1 <= MAX_THIEF_PER_PRESALE, "WavesMinter: All thiefs already minted on presale ");
            _mintThief(to, id);
        }

        (bool success, ) = payable(owner()).call{ value: msg.value }("");
        require(success, "Error sending funds to owner");

        if (_mintedPigsCount.current() + _mintedThievesCount.current() == MAX_PER_PRESALE) {
            _sale = SaleStatus.Wave1;
        }
    }


    function mintWave1(
        uint contractNumber,
        uint id // for uri
    ) 
        public payable 
        nonReentrant 
        mintInfo(_msgSender(), getSalePrice(FIRST_WAVE_PRICE), contractNumber)
    {                          // 1.25$ for test
        address to = _msgSender(); // token receiver
        require(_sale == SaleStatus.Wave1, "WavesMinter: Wave1 sale is not active");

        if(contractNumber == 0) {
            require(_mintedPigsCount.current() + 1 <= MAX_PIG_PER_WAVE1, "WavesMinter: All pigs already minted in first wave");
            _mintPig(to, id);
        } else if (contractNumber == 1) {
            require(_mintedThievesCount.current() + 1 <= MAX_THIEF_PER_WAVE1, "WavesMinter: All thiefs already minted in first wave");
            _mintThief(to, id);
        }

        (bool success, ) = payable(owner()).call{ value: msg.value }("");
        require(success, "Error sending funds to owner");
        
        if (_mintedPigsCount.current() + _mintedThievesCount.current() == MAX_PER_WAVE1) {
            _sale = SaleStatus.Wave2;
        }
    }


    function mintWave2(
        uint contractNumber,
        uint id // for uri
    ) 
        public payable 
        nonReentrant 
        mintInfo(_msgSender(), getSalePrice(SECOND_WAVE_PRICE), contractNumber)
    {                          // 1.5$ for test
        address to = _msgSender(); // token receiver
        require(_sale == SaleStatus.Wave2, "WavesMinter: Wave2 sale is not active");
        
        if(contractNumber == 0) {
            require(_mintedPigsCount.current() + 1 <= MAX_PIG_PER_WAVE2, "WavesMinter: All pigs already minted in second wave");
            _mintPig(to, id);
        } else if (contractNumber == 1) {
            require(_mintedThievesCount.current() + 1 <= MAX_THIEF_PER_WAVE2, "WavesMinter: All thiefs already minted in second wave");
            _mintThief(to, id);
        }

        (bool success, ) = payable(owner()).call{ value: msg.value }("");
        require(success, "Error sending funds to owner");
        
        if (_mintedPigsCount.current() + _mintedThievesCount.current() == MAX_PER_WAVE2) {
            _sale = SaleStatus.Wave3;
        }
    }


    function mintWave3(
        uint contractNumber,
        uint id // for uri
    ) 
        public payable 
        nonReentrant 
        mintInfo(_msgSender(), getSalePrice(THIRD_WAVE_PRICE), contractNumber) 
    {                          // 1.75$ for test
        address to = _msgSender(); // token receiver
        require(_sale == SaleStatus.Wave3, "WavesMinter: Wave3 sale is not active");

        if(contractNumber == 0) {
            require(_mintedPigsCount.current() + 1 <= MAX_PIG_PER_WAVE3, "WavesMinter: All pigs already minted in third wave");
            _mintPig(to, id);
        } else if (contractNumber == 1) {
            require(_mintedThievesCount.current() + 1 <= MAX_THIEF_PER_WAVE3, "WavesMinter: All thiefs already minted in third wave");
            _mintThief(to, id);
        }

        (bool success, ) = payable(owner()).call{ value: msg.value }("");
        require(success, "Error sending funds to owner");
        
        if (_mintedPigsCount.current() + _mintedThievesCount.current() == MAX_PER_WAVE3) {
            _sale = SaleStatus.Giveaway;
        }
    }


    function mintGiveaway(
        uint contractNumber,
        uint id // for uri
    ) 
        public 
        nonReentrant 
    {
        address to = _msgSender(); // token receiver
        require(_sale == SaleStatus.Giveaway, "WavesMinter: Wave3 sale is not active");
        require(_mintedAddressesGiveaway[to] + 1 <= MAX_PER_WALLET_GIVEAWAY, "WavesMinter: Mints token limit exhausted");     
        require(to != address(0), "WavesMinter: Token receiver is zero address");
        require(contractNumber == 0 || contractNumber == 1, "WavesMinter: Incorrect contract number");

        if(contractNumber == 0) {
            require(_mintedPigsCount.current() + 1 <= MAX_PIG_PER_GIVEAWAY, "WavesMinter: All pigs already minted on giveaway");
            _mintPigGiveaway(to, id);
        } else if (contractNumber == 1) {
            require(_mintedThievesCount.current() + 1 <= MAX_THIEF_PER_GIVEAWAY, "WavesMinter: All thiefs already minted on giveaway");
            _mintThiefGiveaway(to, id);
        }
        
        if (_mintedPigsCount.current() + _mintedThievesCount.current() == MAX_PER_GIVEAWAY) {
            _sale = SaleStatus.Disable;
        }
    }


    // private
    function _mintPig(address to, uint id) private {
        require(!_mintedPigId[id], "WavesMinter: This pig id is already minted");
        require(id >= MIN_PIG_ID && id <= MAX_PIG_ID, "WavesMinter: Incorrect pig id");

        string memory uri = string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/QmNh3i8B6y2oQmoHCuipBMrPrx6LDdFZfsjY7KyCokU5gS/", // set pigs ipfs folder
                Strings.toString(id),
                ".json"
            )
        );

        IERC721(_pigs).safeMint(to, uri);

        _mintedPigId[id] = true;
        _mintedPigsCount.increment();
        _mintedAddresses[to] += 1;
    }
 
    function _mintThief(address to, uint id) private {
        require(!_mintedThiefId[id], "WavesMinter: This thief id is already minted");
        require(id >= MIN_THIEF_ID && id <= MAX_THIEF_ID, "WavesMinter: Incorrect thief id");

        string memory uri = string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/QmVhxoWwYNcYNhtvSwwRmCSvYovtcuYf5WA2XNtBicM9u7/", // set thieves ipfs folder
                Strings.toString(id),
                ".json"
            )
        );

        IERC721(_thieves).safeMint(to, uri);

        _mintedThiefId[id] = true;
        _mintedThievesCount.increment();
        _mintedAddresses[to] += 1;
    }

    function _mintPigGiveaway(address to, uint id) private {
        require(!_mintedPigId[id], "WavesMinter: This pig id is already minted");
        require(id >= MIN_PIG_ID_GIVEAWAY && id <= MAX_PIG_ID_GIVEAWAY, "WavesMinter: Incorrect pig id for giveaway");

        string memory uri = string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/QmSz1Fmh6rwAWfWmLx9MDtGbmgvzAAQteNY6B5E3jc8xN1/", // set pigs Giveaway ipfs folder
                Strings.toString(id),
                ".json"
            )
        );

        IERC721(_pigs).safeMint(to, uri);

        _mintedPigId[id] = true;
        _mintedPigsCount.increment();
        _mintedAddressesGiveaway[to] += 1;
    }

    function _mintThiefGiveaway(address to, uint id) private {
        require(!_mintedThiefId[id], "WavesMinter: This thief id is already minted");
        require(id >= MIN_THIEF_ID_GIVEAWAY && id <= MAX_THIEF_ID_GIVEAWAY, "WavesMinter: Incorrect thief id for giveaway");

        string memory uri = string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/QmSz1Fmh6rwAWfWmLx9MDtGbmgvzAAQteNY6B5E3jc8xN1/", // set thieves Giveaway ipfs folder
                Strings.toString(id),
                ".json"
            )
        );

        IERC721(_thieves).safeMint(to, uri);

        _mintedThiefId[id] = true;
        _mintedThievesCount.increment();
        _mintedAddressesGiveaway[to] += 1;
    }

    receive() external payable {}

    // ------------------- VIEW FUNCTIONS -------------------


    function getLatestPrice() public view returns (int) {
        ( , int price, , ,) = priceFeed.latestRoundData();
        return price;
    }

    // for example 100000 = 1000.00 usd
    function getSalePrice(uint usd) public view returns (uint) {
        uint latestPrice = uint(getLatestPrice()) / 1000000; // eth price in usd        
        return usd * (1 ether) / latestPrice ;
    }

    function getPresaleExpectedPrice() public view returns (uint) {
        return PRESALE_PRICE;
    }  

    function getWave1ExpectedPrice() public view returns (uint) {
        return FIRST_WAVE_PRICE;
    }

    function getWave2ExpectedPrice() public view returns (uint) {
        return SECOND_WAVE_PRICE;
    }  

    function getWave3ExpectedPrice() public view returns (uint) {
        return THIRD_WAVE_PRICE;
    }

    function whitelistMember(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function whitelistGiveawayMember(address account) public view returns (bool) {
        return _whitelistGiveaway[account];
    }

    function mintedOf(address account) public view returns (uint) {
        return _mintedAddresses[account]; // max: 3
    }

    function mintedGiveawayOf(address account) public view returns (uint) {
        return _mintedAddressesGiveaway[account]; // max: 1
    }

    function saleStatus() public view returns (SaleStatus) {
        return _sale;
    }

    function saleOn() public view returns (bool) {
        return _saleOn;
    }

    function mintedPigsCount() public view returns (uint) {
        return _mintedPigsCount.current();
    }

    function mintedThievesCount() public view returns (uint) {
        return _mintedThievesCount.current();
    }

    function pigsContract() public view returns (address) {
        return _pigs;
    }

    function thievesContract() public view returns (address) {
        return _thieves;
    }

}