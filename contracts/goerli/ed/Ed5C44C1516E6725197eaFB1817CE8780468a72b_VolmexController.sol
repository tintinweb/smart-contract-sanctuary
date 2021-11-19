// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';

import './interfaces/IVolmexAMM.sol';
import './interfaces/IVolmexProtocol.sol';
import './interfaces/IERC20Modified.sol';

/**
 * @title Volmex Controller contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexController is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    event AdminFeeUpdated(uint256 adminFee);

    event AssetSwaped(uint256 assetInAmount, uint256 assetOutAmount);

    // Address of the collateral used in protocol
    IERC20Modified public stablecoin;
    // Ratio of volatility to be minted per 250 collateral
    uint256 private _volatilityCapRatio;
    // Minimum amount of collateral amount needed to collateralize
    uint256 private _minimumCollateralQty;
    // Used to set the index of pool and protocol
    uint256 public poolIndex;

    // Store the addresses of pools
    mapping(uint256 => address) public pools;
    // Store the addresses of protocols
    mapping(uint256 => address) public protocols;

    /**
     * @notice Initializes the contract
     *
     * @dev Sets the volatilityCapRatio and _minimumCollateralQty
     *
     * @param _stablecoin Address of the collateral token used in protocol
     * @param _pool Address of the pool contract
     * @param _protocol Address of the protocol contract
     */
    function initialize(
        IERC20Modified _stablecoin,
        address _pool,
        IVolmexProtocol _protocol
    ) external initializer {
        stablecoin = _stablecoin;

        pools[poolIndex] = _pool;
        protocols[poolIndex] = address(_protocol);

        _volatilityCapRatio = _protocol.volatilityCapRatio();
        _minimumCollateralQty = _protocol.minimumCollateralQty();
    }

    /**
     * @notice Used to set the pool and protocol on new index
     */
    function setPoolAndProtocol(address _pool, address _protocol) external onlyOwner {
        poolIndex++;
        pools[poolIndex] = _pool;
        protocols[poolIndex] = address(_protocol);
    }

    /**
     * @notice Used to update the minimum collateral qty value
     */
    function updateMinCollateralQty(uint256 _minCollateralQty) external onlyOwner {
        _minimumCollateralQty = _minCollateralQty;
    }

    /**
     * @notice Used to swap collateral token to a type of volatility token
     *
     * @dev Amount if transferred to the controller and approved for pool
     * @dev collateralize the amount to get volatility
     * @dev Swaps half the quantity of volatility asset using pool contract
     * @dev Transfers the asset to caller
     *
     * @param _amount Amount of collateral token
     * @param _isInverseRequired Bool value token type required { true: iETHV, false: ETHV }
     */
    function swapCollateralToVolatility(
        uint256 _amount,
        bool _isInverseRequired,
        uint256 _tokenPoolIndex
    ) external {
        IVolmexProtocol _protocol = IVolmexProtocol(protocols[_tokenPoolIndex]);
        stablecoin.transferFrom(msg.sender, address(this), _amount);
        _approveAssets(stablecoin, _amount, address(this), address(_protocol));

        _protocol.collateralize(_amount);

        uint256 volatilityAmount = calculateAssetQuantity(_amount, _protocol.issuanceFees(), true);

        IERC20Modified volatilityToken = _protocol.volatilityToken();
        IERC20Modified inverseVolatilityToken = _protocol.inverseVolatilityToken();

        IVolmexAMM _pool = IVolmexAMM(pools[_tokenPoolIndex]);

        uint256 tokenAmountOut;
        if (_isInverseRequired) {
            _approveAssets(volatilityToken, volatilityAmount, address(this), address(_pool));
            tokenAmountOut = _swap(
                _pool,
                address(_protocol.volatilityToken()),
                volatilityAmount,
                address(_protocol.inverseVolatilityToken()),
                volatilityAmount >> 1
            );
        } else {
            _approveAssets(inverseVolatilityToken, volatilityAmount, address(this), address(_pool));
            tokenAmountOut = _swap(
                _pool,
                address(_protocol.inverseVolatilityToken()),
                volatilityAmount,
                address(_protocol.volatilityToken()),
                volatilityAmount >> 1
            );
        }

        uint256 totalVolatilityAmount = volatilityAmount.add(tokenAmountOut);
        transferAsset(
            _isInverseRequired ? inverseVolatilityToken : volatilityToken,
            totalVolatilityAmount
        );

        emit AssetSwaped(_amount, totalVolatilityAmount);
    }

    /**
     * @notice Used to swap a type of volatility token to collateral token
     *
     * @dev Amount if transferred to the controller and approved for pool
     * @dev Swaps half the quantity of volatility asset using pool contract
     * @dev redeems the amount to get collateral
     * @dev Transfers the asset to caller
     *
     * @param _amount Amount of volatility token
     * @param _isInverse Bool value of token type passed { true: iETHV, false: ETHV }
     */
    function swapVolatilityToCollateral(
        uint256 _amount,
        bool _isInverse,
        uint256 _tokenPoolIndex
    ) external {
        IVolmexProtocol _protocol = IVolmexProtocol(protocols[_tokenPoolIndex]);
        IERC20Modified volatilityToken = _protocol.volatilityToken();
        IERC20Modified inverseVolatilityToken = _protocol.inverseVolatilityToken();

        IVolmexAMM _pool = IVolmexAMM(pools[_tokenPoolIndex]);

        uint256 tokenAmountOut;
        if (_isInverse) {
            volatilityToken.transferFrom(msg.sender, address(this), _amount);
            _approveAssets(volatilityToken, _amount >> 1, address(this), address(_pool));

            tokenAmountOut = _swap(
                _pool,
                address(_protocol.volatilityToken()),
                _amount >> 1,
                address(_protocol.inverseVolatilityToken()),
                _amount.div(10)
            );
        } else {
            inverseVolatilityToken.transferFrom(msg.sender, address(this), _amount);
            _approveAssets(inverseVolatilityToken, _amount >> 1, address(this), address(_pool));

            tokenAmountOut = _swap(
                _pool,
                address(_protocol.inverseVolatilityToken()),
                _amount >> 1,
                address(_protocol.volatilityToken()),
                _amount.div(10)
            );
        }

        uint256 collateralAmount = calculateAssetQuantity(
            tokenAmountOut.mul(_volatilityCapRatio),
            _protocol.redeemFees(),
            false
        );

        _protocol.redeem(tokenAmountOut);

        transferAsset(stablecoin, collateralAmount);
        transferAsset(
            _isInverse ? volatilityToken : inverseVolatilityToken,
            (_amount >> 1).sub(tokenAmountOut)
        );

        emit AssetSwaped(_amount, collateralAmount);
    }

    function swapAssets(
        IERC20Modified _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _tokenInPoolIndex,
        uint256 _tokenOutPoolIndex
    ) external {
        IVolmexAMM _pool = IVolmexAMM(pools[_tokenInPoolIndex]);
        _tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        _approveAssets(_tokenIn, _amountIn, address(this), address(_pool));

        uint256 tokenAmount = _swap(
            _pool,
            address(_tokenIn),
            _amountIn >> 1,
            _pool.getPrimaryDerivativeAddress() == address(_tokenIn)
                ? _pool.getComplementDerivativeAddress()
                : _pool.getPrimaryDerivativeAddress(),
            _amountIn.div(10)
        );

        IVolmexProtocol _protocol = IVolmexProtocol(protocols[_tokenInPoolIndex]);
        _protocol.redeem(tokenAmount);

        uint256 _collateralAmount = calculateAssetQuantity(
            tokenAmount.mul(_volatilityCapRatio),
            _protocol.redeemFees(),
            false
        );

        _protocol = IVolmexProtocol(protocols[_tokenOutPoolIndex]);
        _protocol.collateralize(_collateralAmount);
        uint256 _volatilityAmount = calculateAssetQuantity(
            _collateralAmount,
            _protocol.issuanceFees(),
            true
        );

        _pool = IVolmexAMM(pools[_tokenOutPoolIndex]);
        uint256 tokenAmountOut = _swap(
            _pool,
            _pool.getPrimaryDerivativeAddress() == address(_tokenOut)
                ? _pool.getComplementDerivativeAddress()
                : _pool.getPrimaryDerivativeAddress(),
            _volatilityAmount >> 1,
            _tokenOut,
            _volatilityAmount.div(10)
        );

        transferAsset(_tokenIn, (_amountIn >> 1).sub(tokenAmount));
        transferAsset(IERC20Modified(_tokenOut), tokenAmountOut);
    }

    /**
     * @notice Used to add liquidity in the pool
     *
     * @param _poolAmountOut Amount of pool token mint and transfer to LP
     * @param _maxAmountsIn Max amount of pool assets an LP can supply
     * @param _poolIndex Index of the pool in which user wants to add liquidity
     */
    function addLiquidity(
        uint256 _poolAmountOut,
        uint256[2] calldata _maxAmountsIn,
        uint256 _poolIndex
    ) external {
        IVolmexAMM _pool = IVolmexAMM(pools[_poolIndex]);
        IVolmexProtocol _protocol = IVolmexProtocol(protocols[_poolIndex]);

        _approveAssets(_protocol.volatilityToken(), _maxAmountsIn[0], msg.sender, address(_pool));
        _approveAssets(_protocol.inverseVolatilityToken(), _maxAmountsIn[1], msg.sender, address(_pool));

        _pool.joinPool(_poolAmountOut, _maxAmountsIn, msg.sender);
    }

    /**
     * @notice Used to remove liquidity from the pool
     *
     * @param _poolAmountIn Amount of pool token transfer to the pool
     * @param _minAmountsOut Min amount of pool assets an LP wish to redeem
     * @param _poolIndex Index of the pool in which user wants to add liquidity
     */
    function removeLiquidity(
        uint256 _poolAmountIn,
        uint256[2] calldata _minAmountsOut,
        uint256 _poolIndex
    ) external {
        IVolmexAMM _pool = IVolmexAMM(pools[_poolIndex]);

        _pool.exitPool(_poolAmountIn, _minAmountsOut, msg.sender);
    }

    /**
     * @notice Used to call falsh loan on AMM
     *
     * @dev This method is for developers.
     * Make sure you call this metehod from a contract with the implementation
     * of IFlashLoanReceiver interface
     *
     * @param _assetToken Address of the token in need
     * @param _amount Amount of token in need
     * @param _params msg.data for verifying the loan
     * @param _poolIndex Index of the AMM
     */
    function makeFlashLoan(
        address _assetToken,
        uint256 _amount,
        bytes calldata _params,
        uint256 _poolIndex
    ) external {
        IVolmexAMM _pool = IVolmexAMM(pools[_poolIndex]);
        _pool.flashLoan(
            msg.sender,
            _assetToken,
            _amount,
            _params
        );
    }

    function swap(
        uint256 _poolIndex,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) external {
        IVolmexAMM _amm = IVolmexAMM(pools[_poolIndex]);

        IERC20Modified(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        _approveAssets(IERC20Modified(_tokenIn), _amountIn, address(this), address(_amm));

        uint256 tokenAmountOut = _swap(
            _amm,
            _tokenIn,
            _amountIn,
            _tokenOut,
            _amountOut
        );
        transferAsset(IERC20Modified(_tokenOut), tokenAmountOut);
    }

    //solium-disable-next-line security/no-assign-params
    function calculateAssetQuantity(
        uint256 _amount,
        uint256 _feePercent,
        bool isVolatility
    ) internal view returns (uint256) {
        uint256 fee = (_amount.mul(_feePercent)).div(10000);
        _amount = _amount.sub(fee);

        return isVolatility ? _amount.div(_volatilityCapRatio) : _amount;
    }

    function transferAsset(IERC20Modified _token, uint256 _amount) internal {
        _token.transfer(msg.sender, _amount);
    }

    function _swap(
        IVolmexAMM _pool,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _amountOut
    ) internal returns (uint256 exactTokenAmountOut) {
        (exactTokenAmountOut, ) = _pool.swapExactAmountIn(
            _tokenIn,
            _amountIn,
            _tokenOut,
            _amountOut
        );
    }

    function _approveAssets(
        IERC20Modified _token,
        uint256 _amount,
        address _owner,
        address _spender
    ) internal {
        uint256 _allowance = _token.allowance(_owner, _spender);

        if (_amount <= _allowance) return;

        _token.approve(_spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol';

import '../libs/tokens/Token.sol';
import './IVolmexProtocol.sol';
import './IVolmexRepricer.sol';

interface IVolmexAMM is IERC20, IERC165Upgradeable {
    function repricingBlock() external view returns (uint256);

    function baseFee() external view returns (uint256);

    function feeAmpPrimary() external view returns (uint256);

    function feeAmpComplement() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function pMin() external view returns (uint256);

    function qMin() external view returns (uint256);

    function exposureLimitPrimary() external view returns (uint256);

    function exposureLimitComplement() external view returns (uint256);

    function protocol() external view returns (IVolmexProtocol);

    function repricer() external view returns (IVolmexRepricer);

    function isFinalized() external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getTokens() external view returns (address[] memory tokens);

    function getLeverage(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getPrimaryDerivativeAddress() external view returns (address);

    function getComplementDerivativeAddress() external view returns (address);

    function joinPool(uint256 poolAmountOut, uint256[2] calldata maxAmountsIn, address receiver) external;

    function exitPool(uint256 poolAmountIn, uint256[2] calldata minAmountsOut, address receiver) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function paused() external view returns (bool);

    function transferOwnership(address newOwner) external;

    function setController(address controller) external;

    function flashLoan(
        address receiverAddress,
        address assetToken,
        uint256 amount,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

import "./IERC20Modified.sol";

interface IVolmexProtocol {
    // State variables
    function minimumCollateralQty() external view returns (uint256);

    function active() external view returns (bool);

    function isSettled() external view returns (bool);

    function volatilityToken() external view returns (IERC20Modified);

    function inverseVolatilityToken()
        external
        view
        returns (IERC20Modified);

    function collateral() external view returns (IERC20Modified);

    function issuanceFees() external view returns (uint256);

    function redeemFees() external view returns (uint256);

    function accumulatedFees() external view returns (uint256);

    function volatilityCapRatio() external view returns (uint256);

    function settlementPrice() external view returns (uint256);

    // External functions
    function initialize(
        IERC20Modified _collateralTokenAddress,
        IERC20Modified _volatilityToken,
        IERC20Modified _inverseVolatilityToken,
        uint256 _minimumCollateralQty,
        uint256 _volatilityCapRatio
    ) external;

    function toggleActive() external;

    function updateMinimumCollQty(uint256 _newMinimumCollQty)
        external;

    function updatePositionToken(
        address _positionToken,
        bool _isVolatilityIndex
    ) external;

    function collateralize(uint256 _collateralQty) external;

    function redeem(uint256 _positionTokenQty) external;

    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external;

    function settle(uint256 _settlementPrice) external;

    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;

    function updateFees(uint256 _issuanceFees, uint256 _redeemFees)
        external;

    function claimAccumulatedFees() external;

    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

/**
 * @dev Modified Interface of the OpenZeppelin's IERC20 extra functions to add features in position token.
 */
interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function mint(address _toWhom, uint256 amount) external;

    function burn(address _whose, uint256 amount) external;

    function grantRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '../../maths/Num.sol';

// Highly opinionated token implementation

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address whom) external view returns (uint256);

    function allowance(address src, address dst) external view returns (uint256);

    function approve(address dst, uint256 amt) external returns (bool);

    function transfer(address dst, uint256 amt) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external returns (bool);
}

contract TokenBase is Num {
    mapping(address => uint256) internal _balance;
    mapping(address => mapping(address => uint256)) internal _allowance;
    uint256 internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);

    function _mint(uint256 amt) internal {
        _balance[address(this)] = add(_balance[address(this)], amt);
        _totalSupply = add(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint256 amt) internal {
        require(_balance[address(this)] >= amt, 'INSUFFICIENT_BAL');
        _balance[address(this)] = sub(_balance[address(this)], amt);
        _totalSupply = sub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint256 amt
    ) internal {
        require(_balance[src] >= amt, 'INSUFFICIENT_BAL');
        _balance[src] = sub(_balance[src], amt);
        _balance[dst] = add(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint256 amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint256 amt) internal {
        _move(from, address(this), amt);
    }
}

contract Token is TokenBase, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    function setName(string memory name) internal {
        _name = name;
    }

    function setSymbol(string memory symbol) internal {
        _symbol = symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view override returns (uint256) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint256) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address dst, uint256 amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint256 amt) external returns (bool) {
        _allowance[msg.sender][dst] = add(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint256 amt) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = sub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint256 amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amt
    ) external override returns (bool) {
        uint256 oldValue = _allowance[src][msg.sender];
        require(msg.sender == src || amt <= oldValue, 'TOKEN_BAD_CALLER');
        _move(src, dst, amt);
        if (msg.sender != src && oldValue != uint256(-1)) {
            _allowance[src][msg.sender] = sub(oldValue, amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;

import '@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol';

interface IVolmexRepricer is IERC165Upgradeable {
    function protocolVolatilityCapRatio() external view returns (uint256);

    function reprice(uint256 _volatilityIndex)
        external
        view
        returns (
            uint256 estPrimaryPrice,
            uint256 estComplementPrice,
            uint256 estPrice
        );

    function sqrtWrapped(int256 value) external pure returns (int256);
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import './Const.sol';

contract Num is Const {
    function toi(uint256 a) internal pure returns (uint256) {
        return a / BONE;
    }

    function floor(uint256 a) internal pure returns (uint256) {
        return toi(a) * BONE;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, 'ADD_OVERFLOW');
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        bool flag;
        (c, flag) = subSign(a, b);
        require(!flag, 'SUB_UNDERFLOW');
    }

    function subSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, 'MUL_OVERFLOW');
        uint256 c1 = c0 + (BONE / 2);
        require(c1 >= c0, 'MUL_OVERFLOW');
        c = c1 / BONE;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b != 0, 'DIV_ZERO');
        uint256 c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, 'DIV_INTERNAL'); // mul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, 'DIV_INTERNAL'); //  add require
        c = c1 / b;
    }

    // DSMath.wpow
    function powi(uint256 a, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = mul(a, a);

            if (n % 2 != 0) {
                z = mul(z, a);
            }
        }
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `powi` for `b^e` and `powK` for k iterations
    // of approximation of b^0.w
    function pow(uint256 base, uint256 exp) internal pure returns (uint256) {
        require(base >= MIN_POW_BASE, 'POW_BASE_TOO_LOW');
        require(base <= MAX_POW_BASE, 'POW_BASE_TOO_HIGH');

        uint256 whole = floor(exp);
        uint256 remain = sub(exp, whole);

        uint256 wholePow = powi(base, toi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint256 partialResult = powApprox(base, remain, POW_PRECISION);
        return mul(wholePow, partialResult);
    }

    function powApprox(
        uint256 base,
        uint256 exp,
        uint256 precision
    ) internal pure returns (uint256 sum) {
        // term 0:
        uint256 a = exp;
        (uint256 x, bool xneg) = subSign(base, BONE);
        uint256 term = BONE;
        sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint256 i = 1; term >= precision; i++) {
            uint256 bigK = i * BONE;
            (uint256 c, bool cneg) = subSign(a, sub(bigK, BONE));
            term = mul(term, mul(c, x));
            term = div(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sub(sum, term);
            } else {
                sum = add(sum, term);
            }
        }
    }

    function min(uint256 first, uint256 second) internal pure returns (uint256) {
        if (first < second) {
            return first;
        }
        return second;
    }
}

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

contract Const {
    uint256 public constant BONE = 10**18;
    int256 public constant iBONE = int256(BONE);

    uint256 public constant MIN_POW_BASE = 1 wei;
    uint256 public constant MAX_POW_BASE = (2 * BONE) - 1 wei;
    uint256 public constant POW_PRECISION = BONE / 10**10;

    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;

    uint256 public constant VOLATILITY_PRICE_PRECISION = 10**4;
}