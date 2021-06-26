/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: AggregatorV3Interface

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

// Part: IUniswapV2Factory

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// Part: IUniswapV2Pair

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: BetPriceProvider.sol

contract BetPriceProvider is Ownable {

    address immutable public WETH;// for MainNet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNI_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    uint256 custom_price;
    
    //Only UniSwap price feed is implemented!!!!
    enum OracleType {Custom, Uniswap, ChainLink, Compound}
    
    struct PriceFeedProvider {
        address provider;
        OracleType providerType;
    }


    mapping(address => PriceFeedProvider) public feed;

    mapping(bytes32 => PriceFeedProvider) public namedFeed;


    
    event NewOracleAdded(address indexed _amulet, address _provider, uint8 _providerType);
    event NewPairOracleAdded(string  pairName, address provider, uint8 providerType);

    constructor(address _weth) {
        WETH = _weth;
    }

    function setCustomPrice(uint256 price) external onlyOwner {
        custom_price = price;
    }

    function getLastPrice(address _amulet) external view returns (uint256) {
        address token0;
        address token1;
        address pair;
        uint112 _reserve0;
        uint112 _reserve1;
        uint32  _timeStamp;
        uint256 rate;
        require(_amulet != address(0), "Please ask me NON zero asset");
        if  (feed[_amulet].providerType == OracleType.Uniswap) {
            if (feed[_amulet].provider == address(0)){
                //Try find pair address on UniSwap
                pair = IUniswapV2Factory(UNI_FACTORY).getPair(_amulet, WETH);
                require(pair != address(0), "Can't find pair on UniSwap");
            }   
            token0 = IUniswapV2Pair(pair).token0();
            token1 = IUniswapV2Pair(pair).token1();
            (_reserve0, _reserve1, _timeStamp) = IUniswapV2Pair(pair).getReserves();
            //Let's check what token is WETH  and calc rate
            if  (token0 == WETH) {
                rate = _reserve0*1e18/_reserve1;
            } else {
                rate = _reserve1*1e18/_reserve0;
            }
        } else if (feed[_amulet].providerType == OracleType.Custom) {
            //Dummy MAGIC Price Feed - BULL TREND Forever ;-)
            //It may be used for tests
            rate = uint256(block.timestamp);
        } else {
            //Other Oracle types are not implemented yet
            rate = 0;
        }
        return rate;
    }


    function setPriceFeedProvider(address _token, address _provider, uint8 _providerType) 
        external
        onlyOwner 
    {
        _setPriceFeedProvider(_token, _provider, _providerType);
    }

    function setBatchPriceFeedProvider(address[] memory _token, address[] memory _provider, uint8[] memory _providerType) 
        external
        onlyOwner 
    {
        require(_token.length == _provider.length , 'Arguments must have same length');
        require(_token.length == _providerType.length , 'Arguments2 must have same length');
        require(_token.length < 255 , 'To long array');
        for (uint8 i = 0; i < _token.length; i++) {
            _setPriceFeedProvider(_token[i], _provider[i], _providerType[i]);
        } 
     
    }
    
    function setPriceFeedProviderByPairName(string memory _pairName, address _provider, uint8 _providerType) 
        external
        onlyOwner 
    {
        _setPriceFeedProviderByPairName( _pairName, _provider, _providerType);
    }

    function getLastPriceByPairNameStr(string memory _pairName) public view returns (int256) {
        return getLastPriceByPairName(
           keccak256(abi.encodePacked(_pairName))
        );   
    }

    function getLastPriceByPairName(bytes32 _nameHash) public view returns (int256) {
        //TODO  SOft Chcek of existence
        int256 rate;
        if  (namedFeed[_nameHash].providerType == OracleType.ChainLink) {
            ( 
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = AggregatorV3Interface(namedFeed[_nameHash].provider).latestRoundData();
            rate = price;
        } else if (namedFeed[_nameHash].providerType == OracleType.Custom) {
            //Dummy MAGIC Price Feed - BULL TREND Forever ;-)
            //It may be used for tests
            //rate = int256(block.timestamp);
            if (custom_price > 0) {
                rate = int256(custom_price);
            }
            else {rate = int256(block.timestamp);
            }
        } else {
            //Other Oracle types are not implemented yet
            rate = 0;
        }
        return rate;
    }

    //function isPairExist(bytes32 _nameHash)

    //////////////////////////////////////////////////////////
    //////   Internals                                    ////
    //////////////////////////////////////////////////////////

    function _setPriceFeedProvider(address _token, address _provider, uint8 _providerType) 
        internal
    {
        require(_token != address(0), "Can't add oracle for None asset");
        //Some checks for available oracle types
        if  (OracleType(_providerType) == OracleType.Uniswap) {
            require(
                keccak256(abi.encodePacked(IUniswapV2Pair(_provider).name())) ==
                keccak256(abi.encodePacked('Uniswap V2')), "It seems NOT like Uniswap pair");
            require(IUniswapV2Pair(_provider).token0() == WETH || IUniswapV2Pair(_provider).token1() == WETH,
                "One token in pair must be WETH"
            );
        }

        feed[_token].provider     = _provider;
        feed[_token].providerType = OracleType(_providerType);
        emit NewOracleAdded(_token, _provider, _providerType);
    }

    function _setPriceFeedProviderByPairName(string memory _pairName, address _provider, uint8 _providerType) 
        internal
    {
        //Some checks for available oracle types
        if  (OracleType(_providerType) == OracleType.Uniswap) {
            require(
                keccak256(abi.encodePacked(IUniswapV2Pair(_provider).name())) ==
                keccak256(abi.encodePacked('Uniswap V2')), "It seems NOT like Uniswap pair");
            require(IUniswapV2Pair(_provider).token0() == WETH || IUniswapV2Pair(_provider).token1() == WETH,
                "One token in pair must be WETH"
            );
        }
        //TODO   Check ChainLInk provider
        namedFeed[keccak256(abi.encodePacked(_pairName))].provider     = _provider;
        namedFeed[keccak256(abi.encodePacked(_pairName))].providerType = OracleType(_providerType);
        emit NewPairOracleAdded(_pairName, _provider, _providerType);
    }

}