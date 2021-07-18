/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IBankConfig {
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);

    function getReserveBps() external view returns (uint256);

    function getLiquidateBps() external view returns (uint256);
    
    function isStable(address goblin) external view returns (bool);
}

interface InterestModel {
    function getInterestRate(uint256 debt, uint256 floating) external view returns (uint256);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: Uniswap/[email protected]/IUniswapV2Pair

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

interface IGoblin {
  function lpToken() external view returns (IUniswapV2Pair);
}

// Part: PriceOracle

interface PriceOracle {
  /// @dev Return the wad price of token0/token1, multiplied by 1e18
  /// NOTE: (if you have 1 token0 how much you can sell it for token1)
  function getPrice(address goblin)
    external
    view
    returns (uint price, uint lastUpdate);
}

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Part: ERC20Interface

interface ERC20Interface {
  function balanceOf(address user) external view returns (uint);
}

// Part: SafeToken

library SafeToken {
  function myBalance(address token) internal view returns (uint) {
    return ERC20Interface(token).balanceOf(address(this));
  }

  function balanceOf(address token, address user) internal view returns (uint) {
    return ERC20Interface(token).balanceOf(user);
  }

  function safeApprove(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeApprove');
  }

  function safeTransfer(
    address token,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransfer');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) =
      token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), '!safeTransferFrom');
  }

  function safeTransferBNB(address to, uint value) internal {
    (bool success, ) = to.call{value:value}(new bytes(0));
    require(success, '!safeTransferBNB');
  }
}

contract BankConfig is IBankConfig, Ownable {
    using SafeToken for address;
    using SafeMath for uint;
  
    uint256 override public getReserveBps;
    uint256 override public getLiquidateBps;
    InterestModel public interestModel;
    PriceOracle public oracle;
    mapping(address => uint64) public goblinsMaxPriceDiff;
    
    constructor() public {}

    function setParams(uint256 _getReserveBps, uint256 _getLiquidateBps, InterestModel _interestModel,PriceOracle _oracle) public onlyOwner {
        getReserveBps = _getReserveBps;
        getLiquidateBps = _getLiquidateBps;
        interestModel = _interestModel;
        oracle = _oracle;
    }

    function getInterestRate(uint256 debt, uint256 floating) override external view returns (uint256) {
        return interestModel.getInterestRate(debt, floating);
    }
    
    /// @dev Set oracle address. Must be called by owner.
    function setOracle(PriceOracle _oracle) external onlyOwner {
        oracle = _oracle;
    }
    
    /// @dev Set goblin configurations. Must be called by owner.
    function setConfigs(address[] calldata addrs, uint64[] calldata maxPriceDiff) external onlyOwner {
        uint len = addrs.length;
        require(maxPriceDiff.length == len, 'bad len');
        for (uint idx = 0; idx < len; idx++) {
            goblinsMaxPriceDiff[addrs[idx]] = maxPriceDiff[idx];
        }
    }
    
    /// @dev Return whether the given goblin is stable, presumably not under manipulation.
    function isStable(address goblin) public override view returns (bool) {
        IUniswapV2Pair lp = IGoblin(goblin).lpToken();
        address token0 = lp.token0();
        address token1 = lp.token1();
        // 1. Check that reserves and balances are consistent (within 1%)
        (uint r0, uint r1, ) = lp.getReserves();
        uint t0bal = token0.balanceOf(address(lp));
        uint t1bal = token1.balanceOf(address(lp));
        require(t0bal.mul(100) <= r0.mul(101), 'bad t0 balance');
        require(t1bal.mul(100) <= r1.mul(101), 'bad t1 balance');
        // 2. Check that price is in the acceptable range
        (uint price, uint lastUpdate) = oracle.getPrice(goblin);
        require(lastUpdate >= now - 1 days, 'price too stale');
        uint lpPrice = r1.mul(1e18).div(r0);
        uint maxPriceDiff = goblinsMaxPriceDiff[goblin];
        require(lpPrice <= price.mul(maxPriceDiff).div(10000), 'price too high');
        require(lpPrice >= price.mul(10000).div(maxPriceDiff), 'price too low');
        // 3. Done
        return true;
    }
}