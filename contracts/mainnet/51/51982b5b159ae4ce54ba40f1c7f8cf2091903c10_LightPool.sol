// hevm: flattened sources of contracts/LightPool.sol
pragma solidity ^0.4.21;

////// contracts/interfaces/ERC20.sol
/* pragma solidity ^0.4.21; */

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function decimals() public view returns (uint);
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);
}

////// contracts/interfaces/PriceSanityInterface.sol
/* pragma solidity ^0.4.21; */

contract PriceSanityInterface {
    function checkPrice(address base, address quote, bool buy, uint256 baseAmount, uint256 quoteAmount) external view returns (bool result);
}

////// contracts/interfaces/WETHInterface.sol
/* pragma solidity ^0.4.21; */

/* import "./ERC20.sol"; */

contract WETHInterface is ERC20 {
  function() external payable;
  function deposit() external payable;
  function withdraw(uint wad) external;
}

////// contracts/LightPool.sol
/* pragma solidity ^0.4.21; */

/* import "./interfaces/WETHInterface.sol"; */
/* import "./interfaces/PriceSanityInterface.sol"; */
/* import "./interfaces/ERC20.sol"; */

contract LightPool {
    uint16 constant public EXTERNAL_QUERY_GAS_LIMIT = 4999;    // Changes to state require at least 5000 gas

    struct TokenData {
        address walletAddress;
        PriceSanityInterface priceSanityContract;
    }

    // key = keccak256(token, base, walletAddress)
    mapping(bytes32 => TokenData)       public markets;
    mapping(address => bool)            public traders;
    address                             public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWalletAddress(address base, address quote) {
        bytes32 key = keccak256(base, quote, msg.sender);
        require(markets[key].walletAddress == msg.sender);
        _;
    }

    modifier onlyTrader() {
        require(traders[msg.sender]);
        _;
    }

    function LightPool() public {
        owner = msg.sender;
    }

    function setTrader(address trader, bool enabled) onlyOwner external {
        traders[trader] = enabled;
    }

    function setOwner(address _owner) onlyOwner external {
        require(_owner != address(0));
        owner = _owner;
    }

    event AddMarket(address indexed base, address indexed quote, address indexed walletAddress, address priceSanityContract);
    function addMarket(ERC20 base, ERC20 quote, PriceSanityInterface priceSanityContract) external {
        require(base != address(0));
        require(quote != address(0));

        // Make sure there&#39;s no such configured token
        bytes32 tokenHash = keccak256(base, quote, msg.sender);
        require(markets[tokenHash].walletAddress == address(0));

        // Initialize token pool data
        markets[tokenHash] = TokenData(msg.sender, priceSanityContract);
        emit AddMarket(base, quote, msg.sender, priceSanityContract);
    }

    event RemoveMarket(address indexed base, address indexed quote, address indexed walletAddress);
    function removeMarket(ERC20 base, ERC20 quote) onlyWalletAddress(base, quote) external {
        bytes32 tokenHash = keccak256(base, quote, msg.sender);
        TokenData storage tokenData = markets[tokenHash];

        emit RemoveMarket(base, quote, tokenData.walletAddress);
        delete markets[tokenHash];
    }

    event ChangePriceSanityContract(address indexed base, address indexed quote, address indexed walletAddress, address priceSanityContract);
    function changePriceSanityContract(ERC20 base, ERC20 quote, PriceSanityInterface _priceSanityContract) onlyWalletAddress(base, quote) external {
        bytes32 tokenHash = keccak256(base, quote, msg.sender);
        TokenData storage tokenData = markets[tokenHash];
        tokenData.priceSanityContract = _priceSanityContract;
        emit ChangePriceSanityContract(base, quote, msg.sender, _priceSanityContract);
    }

    event Trade(address indexed trader, address indexed baseToken, address indexed quoteToken, address walletAddress, bool buy, uint256 baseAmount, uint256 quoteAmount);
    function trade(ERC20 base, ERC20 quote, address walletAddress, bool buy, uint256 baseAmount, uint256 quoteAmount) onlyTrader external {
        bytes32 tokenHash = keccak256(base, quote, walletAddress);
        TokenData storage tokenData = markets[tokenHash];
        require(tokenData.walletAddress != address(0));
        if (tokenData.priceSanityContract != address(0)) {
            require(tokenData.priceSanityContract.checkPrice.gas(EXTERNAL_QUERY_GAS_LIMIT)(base, quote, buy, baseAmount, quoteAmount)); // Limit gas to prevent reentrancy
        }
        ERC20 takenToken;
        ERC20 givenToken;
        uint256 takenTokenAmount;
        uint256 givenTokenAmount;
        if (buy) {
            takenToken = quote;
            givenToken = base;
            takenTokenAmount = quoteAmount;
            givenTokenAmount = baseAmount;
        } else {
            takenToken = base;
            givenToken = quote;
            takenTokenAmount = baseAmount;
            givenTokenAmount = quoteAmount;
        }
        require(takenTokenAmount != 0 && givenTokenAmount != 0);

        // Swap!
        require(takenToken.transferFrom(msg.sender, tokenData.walletAddress, takenTokenAmount));
        require(givenToken.transferFrom(tokenData.walletAddress, msg.sender, givenTokenAmount));
        emit Trade(msg.sender, base, quote, walletAddress, buy, baseAmount, quoteAmount);
    }
}