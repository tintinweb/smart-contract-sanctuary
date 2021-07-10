// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.6;
import './modules/Ownable.sol';
import './interfaces/ITgas.sol';
import './interfaces/ITomiFactory.sol';
import './interfaces/IERC20.sol';
import './interfaces/ITomiPair.sol';
import './libraries/TomiSwapLibrary.sol';
import './libraries/SafeMath.sol';

contract TomiTransferListener is Ownable {
    uint256 public version = 1;
    address public TGAS;
    address public PLATFORM;
    address public WETH;
    address public FACTORY;

    mapping(address => bool) public tokenWhitelist;
    mapping(address => bool) public disablePairlist;

    event Transfer(address indexed from, address indexed to, address indexed token, uint256 amount);

    function initialize(
        address _TGAS,
        address _FACTORY,
        address _WETH,
        address _PLATFORM
    ) external onlyOwner {
        require(
            _TGAS != address(0) && _FACTORY != address(0) && _WETH != address(0) && _PLATFORM != address(0),
            'TOMI TRANSFER LISTENER : INPUT ADDRESS IS ZERO'
        );
        TGAS = _TGAS;
        FACTORY = _FACTORY;
        WETH = _WETH;
        PLATFORM = _PLATFORM;
    }

    function updateTGASImpl(address _newImpl) external onlyOwner {
        ITgas(TGAS).upgradeImpl(_newImpl);
    }

    // added for emergency remove scam tokens.
    function setWhitelist(bool _active, address[] memory _tokens) public onlyOwner {
        for(uint i = 0; i < _tokens.length; i ++) {
            tokenWhitelist[_tokens[i]] = _active;
        }
    }

    function setDisablePairlist(bool _active, address[] memory _pairs) public onlyOwner {
        for(uint i = 0; i < _pairs.length; i ++) {
            disablePairlist[_pairs[i]] = _active;
        }
    }

    function emergencyRemoveProductivity(address _pair, uint _amount) public onlyOwner {
        require(ITomiFactory(FACTORY).isPair(_pair), "TOMI TRANSFER LISTENER: ILLEGAL ADDRESS");
        address token0  = ITomiPair(_pair).token0();
        address token1  = ITomiPair(_pair).token1();
        require(tokenWhitelist[token0] == false || tokenWhitelist[token1] == false, "TOMI TRANSFER LISTENER: ILLEGAL");
        ITgas(TGAS).decreaseProductivity(_pair, _amount);
    }

    // only white listed token will calculate for procutivity.
    function _hasProductivity(address _pair) internal view returns (bool) {
        if(ITomiFactory(FACTORY).isPair(_pair)) {
            address token0  = ITomiPair(_pair).token0();
            address token1  = ITomiPair(_pair).token1();
            if(disablePairlist[_pair] == false && tokenWhitelist[token0] == true && tokenWhitelist[token1] == true)
                return true;
        }
        return false;
    }

    function upgradeProdutivity(address fromPair, address toPair) external {
        require(msg.sender == PLATFORM, 'TOMI TRANSFER LISTENER: PERMISSION');
        (uint256 fromPairPower, ) = ITgas(TGAS).getProductivity(fromPair);
        (uint256 toPairPower, ) = ITgas(TGAS).getProductivity(toPair);
        if(fromPairPower > 0 && toPairPower == 0) {
            ITgas(TGAS).decreaseProductivity(fromPair, fromPairPower);
            ITgas(TGAS).increaseProductivity(toPair, fromPairPower);
        }
    }

    function transferNotify(
        address from,
        address to,
        address token,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == PLATFORM, 'TOMI TRANSFER LISTENER: PERMISSION');

        if (token == WETH) {
            if (_hasProductivity(from)) {
                uint256 decreasePower = ITomiFactory(FACTORY).getPair(TGAS, WETH) == from
                    ? SafeMath.mul(amount, 2)
                    : amount;
                ITgas(TGAS).decreaseProductivity(from, decreasePower);
            }
            if (_hasProductivity(to)) {
                uint256 increasePower = ITomiFactory(FACTORY).getPair(TGAS, WETH) == to
                    ? SafeMath.mul(amount, 2)
                    : amount;
                ITgas(TGAS).increaseProductivity(to, increasePower);
            }

        } else if (token == TGAS) {
            (uint256 reserveTGAS, uint256 reserveWETH) = TomiSwapLibrary.getReserves(FACTORY, TGAS, WETH);
            if (_hasProductivity(to) && ITomiFactory(FACTORY).getPair(TGAS, WETH) != to) {
                ITgas(TGAS).increaseProductivity(to, TomiSwapLibrary.quote(amount, reserveTGAS, reserveWETH));
            }
            if (_hasProductivity(from) && ITomiFactory(FACTORY).getPair(TGAS, WETH) != from) {
                (uint256 pairPower, ) = ITgas(TGAS).getProductivity(from);
                uint256 balance = ITomiPair(from).getTGASReserve();
                uint256 decrasePower = (SafeMath.mul(amount, pairPower)) / (SafeMath.add(balance, amount));
                if (decrasePower > 0) ITgas(TGAS).decreaseProductivity(from, decrasePower);
            }
        }
        emit Transfer(from, to, token, amount);
        return true;
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITgas {
    function amountPerBlock() external view returns (uint);
    function changeInterestRatePerBlock(uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint, uint);
    function increaseProductivity(address user, uint value) external returns (bool);
    function decreaseProductivity(address user, uint value) external returns (bool);
    function take() external view returns (uint);
    function takeWithBlock() external view returns (uint, uint);
    function mint() external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function upgradeImpl(address _newImpl) external;
    function upgradeGovernance(address _newGovernor) external;
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITomiFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function contractCodeHash() external view returns (bytes32);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function playerPairs(address player, uint index) external view returns (address pair);
    function getPlayerPairCount(address player) external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function addPlayerPair(address player, address _pair) external returns (bool);
}

pragma solidity >=0.5.0;

interface ITomiPair {
  
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
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address from, address to, uint amount) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address tokenA, address tokenB, address platform, address tgas) external;
    function swapFee(uint amount, address token, address to) external ;
    function queryReward() external view returns (uint rewardAmount, uint blockNumber);
    function mintReward() external returns (uint rewardAmount);
    function getTGASReserve() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.5.0;

import '../interfaces/ITomiPair.sol';
import '../interfaces/ITomiFactory.sol';
import "./SafeMath.sol";

library TomiSwapLibrary {
    using SafeMath for uint;

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TomiSwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TomiSwapLibrary: ZERO_ADDRESS');
    }

    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes32 rawAddress = keccak256(
        abi.encodePacked(
            bytes1(0xff),
            factory,
            salt,
            ITomiFactory(factory).contractCodeHash()
            )
        );
        return address(bytes20(rawAddress << 96));
    }

    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ITomiPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    
    function quoteEnhance(address factory, address tokenA, address tokenB, uint amountA) internal view returns(uint amountB) {
        (uint reserveA, uint reserveB) = getReserves(factory, tokenA, tokenB);
        return quote(amountA, reserveA, reserveB);
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'TomiSwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'TomiSwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'TomiSwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TomiSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn.mul(reserveOut);
        uint denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'TomiSwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'TomiSwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut);
        uint denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

}

pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}