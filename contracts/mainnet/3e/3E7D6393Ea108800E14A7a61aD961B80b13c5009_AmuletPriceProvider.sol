/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;



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

// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/SafeMath

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

// Part: AmuletPriceProviderBase

contract AmuletPriceProviderBase is Ownable {
    using SafeMath for uint256;

    address constant public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant public UNI_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    enum OracleType {None, Uniswap, SushiSwap, ChainLink}
    
    struct PriceFeedProvider {
        address provider;
        OracleType providerType;
    }

    mapping(address => PriceFeedProvider) public feed;
    
    event NewOracleAdded(address indexed _amulet, address _provider, uint8 _providerType);

    constructor() {
    }

    function getLastPrice(address _amulet) public virtual view returns (uint256) {
        OracleType providerType = feed[_amulet].providerType;
        require(providerType != OracleType.None, 'Oracle not configured for this token');

        if (providerType == OracleType.Uniswap || providerType == OracleType.SushiSwap) {
            address pair = feed[_amulet].provider;
            address token0 = IUniswapV2Pair(pair).token0();
            address token1 = IUniswapV2Pair(pair).token1();
            (uint112 _reserve0, uint112 _reserve1, uint32 _timeStamp) = IUniswapV2Pair(pair).getReserves();
            // Let's check what token is WETH and calc rate
            if (token0 == WETH) {
                return (uint256)(_reserve0)*1e18/_reserve1;
            } else {
                return (uint256)(_reserve1)*1e18/_reserve0;
            }
        }
        if (providerType == OracleType.ChainLink) {
            ( 
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = AggregatorV3Interface(feed[_amulet].provider).latestRoundData();
            return uint256(price);
        }
        return 0;
    }

    function setPriceFeedProvider(address _token, address _provider, OracleType _providerType)
        external
        onlyOwner 
    {
        _setPriceFeedProvider(_token, _provider, _providerType);
    }

    function setBatchPriceFeedProvider(address[] memory _token, address[] memory _provider, OracleType[] memory _providerType)
        external
        onlyOwner 
    {
        require(_token.length == _provider.length , 'Arguments must have same length');
        require(_token.length == _providerType.length , 'Arguments2 must have same length');
        require(_token.length < 255, 'To long array');
        for (uint8 i = 0; i < _token.length; i++) {
            _setPriceFeedProvider(_token[i], _provider[i], _providerType[i]);
        } 
     
    }

    function _setPriceFeedProvider(address _token, address _provider, OracleType _providerType)
        internal
    {
        require(_token != address(0), "Can't add oracle for None asset");
        //Some checks for available oracle types
        if (_providerType == OracleType.Uniswap) {

            if (_provider == address(0)){
                // Try find pair address on UniSwap
                _provider = IUniswapV2Factory(UNI_FACTORY).getPair(_token, WETH);
                require(_provider != address(0), "Can't find pair on UniSwap");
            }

            require(
                keccak256(abi.encodePacked(IUniswapV2Pair(_provider).name())) ==
                keccak256(abi.encodePacked('Uniswap V2')), "It seems NOT like Uniswap pair");
            require(IUniswapV2Pair(_provider).token0() == WETH || IUniswapV2Pair(_provider).token1() == WETH,
                "One token in pair must be WETH"
            );
        }
        if (_providerType == OracleType.SushiSwap) {

            if (_provider == address(0)){
                // Try find pair address on UniSwap
                _provider = IUniswapV2Factory(UNI_FACTORY).getPair(_token, WETH);
                require(_provider != address(0), "Can't find pair on UniSwap");
            }

            require(
                keccak256(abi.encodePacked(IUniswapV2Pair(_provider).name())) ==
                keccak256(abi.encodePacked('SushiSwap LP Token')), "It seems NOT like SushiSwap pair");
            require(IUniswapV2Pair(_provider).token0() == WETH || IUniswapV2Pair(_provider).token1() == WETH,
                "One token in pair must be WETH"
            );
        }
        feed[_token].provider     = _provider;
        feed[_token].providerType = OracleType(_providerType);
        emit NewOracleAdded(_token, _provider, (uint8)(_providerType));
    }

}

// File: AmuletPriceProvider.sol

contract AmuletPriceProvider is AmuletPriceProviderBase {

    constructor() AmuletPriceProviderBase() {
        _setPriceFeedProvider(0xD533a949740bb3306d119CC777fa900bA034cd52, 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e, OracleType.ChainLink); // $CRV
        _setPriceFeedProvider(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e, OracleType.ChainLink); // $UNI
        _setPriceFeedProvider(0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a, 0xc16935B445F4BDC172e408433c8f7101bbBbE368, OracleType.ChainLink); // $RGT
        _setPriceFeedProvider(0xDADA00A9C23390112D08a1377cc59f7d03D9df55, 0x83B04AF7a77C727273B7a582D6Fda65472FCB3f2, OracleType.SushiSwap); // $DUNG
        _setPriceFeedProvider(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2, 0xe572CeF69f43c2E488b33924AF04BDacE19079cf, OracleType.ChainLink); // $SUSHI
        _setPriceFeedProvider(0x0D8775F648430679A709E98d2b0Cb6250d2887EF, 0x0d16d4528239e9ee52fa531af613AcdB23D88c94, OracleType.ChainLink); // $BAT
        _setPriceFeedProvider(0x3472A5A71965499acd81997a54BBA8D852C6E53d, 0x58921Ac140522867bf50b9E009599Da0CA4A2379, OracleType.ChainLink); // $BADGER
        _setPriceFeedProvider(0x0d438F3b5175Bebc262bF23753C1E53d03432bDE, 0xe5Dc0A609Ab8bCF15d3f35cFaa1Ff40f521173Ea, OracleType.ChainLink); // $WNXM
        _setPriceFeedProvider(0x3155BA85D5F96b2d030a4966AF206230e46849cb, 0x875D60C44cfbC38BaA4Eb2dDB76A767dEB91b97e, OracleType.ChainLink); // $RUNE
        _setPriceFeedProvider(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9, 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012, OracleType.ChainLink); // $AAVE
        _setPriceFeedProvider(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F, 0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c, OracleType.ChainLink); // $SNX
        _setPriceFeedProvider(0x967da4048cD07aB37855c090aAF366e4ce1b9F48, 0x9b0FC4bb9981e5333689d69BdBF66351B9861E62, OracleType.ChainLink); // $OCEAN
        _setPriceFeedProvider(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942, 0x82A44D92D6c329826dc557c5E1Be6ebeC5D5FeB9, OracleType.ChainLink); // $MANA
        _setPriceFeedProvider(0x514910771AF9Ca656af840dff83E8264EcF986CA, 0xDC530D9457755926550b59e8ECcdaE7624181557, OracleType.ChainLink); // $LINK
        _setPriceFeedProvider(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32, 0x4e844125952D32AcdF339BE976c98E22F6F318dB, OracleType.ChainLink); // $LDO
        _setPriceFeedProvider(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C, 0xCf61d1841B178fe82C8895fe60c2EDDa08314416, OracleType.ChainLink); // $BNT
        _setPriceFeedProvider(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2, 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2, OracleType.ChainLink); // $MKR
        _setPriceFeedProvider(0x111111111117dC0aa78b770fA6A738034120C302, 0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8, OracleType.ChainLink); // $1INCH
        _setPriceFeedProvider(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, 0x7c5d4F8345e66f68099581Db340cd65B078C41f4, OracleType.ChainLink); // $YFI
        _setPriceFeedProvider(0xc00e94Cb662C3520282E6f5717214004A7f26888, 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699, OracleType.ChainLink); // $COMP
    }
}