pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IBondController.sol";
import "./interfaces/ITrancheFactory.sol";
import "./interfaces/ITranche.sol";

/**
 * @dev Controller for a ButtonTranche bond
 *
 * Invariants:
 *  - `totalDebt` should always equal the sum of all tranche tokens' `totalSupply()`
 */
contract BondController is IBondController, OwnableUpgradeable {
    uint256 private constant TRANCHE_RATIO_GRANULARITY = 1000;
    // Denominator for basis points. Used to calculate fees
    uint256 private constant BPS = 10_000;
    // Maximum fee in terms of basis points
    uint256 private constant MAX_FEE_BPS = 50;

    // to avoid precision loss and other weird math from a small initial deposit
    // we require at least a minimum initial deposit
    uint256 private constant MINIMUM_FIRST_DEPOSIT = 10e9;

    address public override collateralToken;
    TrancheData[] public override tranches;
    uint256 public override trancheCount;
    mapping(address => bool) public trancheTokenAddresses;
    uint256 public maturityDate;
    bool public isMature;
    uint256 public totalDebt;

    // Maximum amount of collateral that can be deposited into this bond
    // Used as a guardrail for initial launch.
    // If set to 0, no deposit limit will be enforced
    uint256 public depositLimit;
    // Fee taken on deposit in basis points. Can be set by the contract owner
    uint256 public override feeBps;

    /**
     * @dev Constructor for Tranche ERC20 token
     * @param _trancheFactory The address of the tranche factory
     * @param _collateralToken The address of the ERC20 collateral token
     * @param _admin The address of the initial admin for this contract
     * @param trancheRatios The tranche ratios for this bond
     * @param _maturityDate The date timestamp in seconds at which this bond matures
     * @param _depositLimit The maximum amount of collateral that can be deposited. 0 if no limit
     */
    function init(
        address _trancheFactory,
        address _collateralToken,
        address _admin,
        uint256[] memory trancheRatios,
        uint256 _maturityDate,
        uint256 _depositLimit
    ) external initializer {
        require(_trancheFactory != address(0), "BondController: invalid trancheFactory address");
        require(_collateralToken != address(0), "BondController: invalid collateralToken address");
        require(_admin != address(0), "BondController: invalid admin address");
        __Ownable_init();
        transferOwnership(_admin);

        trancheCount = trancheRatios.length;
        collateralToken = _collateralToken;
        string memory collateralSymbol = IERC20Metadata(collateralToken).symbol();

        uint256 totalRatio;
        for (uint256 i = 0; i < trancheRatios.length; i++) {
            uint256 ratio = trancheRatios[i];
            require(ratio <= TRANCHE_RATIO_GRANULARITY, "BondController: Invalid tranche ratio");
            totalRatio += ratio;

            address trancheTokenAddress = ITrancheFactory(_trancheFactory).createTranche(
                getTrancheName(collateralSymbol, i, trancheRatios.length),
                getTrancheSymbol(collateralSymbol, i, trancheRatios.length),
                _collateralToken
            );
            tranches.push(TrancheData(ITranche(trancheTokenAddress), ratio));
            trancheTokenAddresses[trancheTokenAddress] = true;
        }

        require(totalRatio == TRANCHE_RATIO_GRANULARITY, "BondController: Invalid tranche ratios");
        require(_maturityDate > block.timestamp, "BondController: Invalid maturity date");
        maturityDate = _maturityDate;
        depositLimit = _depositLimit;
    }

    /**
     * @inheritdoc IBondController
     */
    function deposit(uint256 amount) external override {
        require(amount > 0, "BondController: invalid amount");

        // saving totalDebt in memory to minimize sloads
        uint256 _totalDebt = totalDebt;
        require(_totalDebt > 0 || amount >= MINIMUM_FIRST_DEPOSIT, "BondController: invalid initial amount");
        require(!isMature, "BondController: Already mature");

        uint256 collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        require(depositLimit == 0 || collateralBalance + amount <= depositLimit, "BondController: Deposit limit");

        TrancheData[] memory _tranches = tranches;

        uint256 newDebt;
        uint256[] memory trancheValues = new uint256[](trancheCount);
        for (uint256 i = 0; i < _tranches.length; i++) {
            // NOTE: solidity 0.8 checks for over/underflow natively so no need for SafeMath
            uint256 trancheValue = (amount * _tranches[i].ratio) / TRANCHE_RATIO_GRANULARITY;

            // if there is any collateral, we should scale by the debt:collateral ratio
            if (collateralBalance > 0) {
                trancheValue = (trancheValue * _totalDebt) / collateralBalance;
            }
            newDebt += trancheValue;
            trancheValues[i] = trancheValue;
        }
        totalDebt += newDebt;

        TransferHelper.safeTransferFrom(collateralToken, _msgSender(), address(this), amount);
        // saving feeBps in memory to minimize sloads
        uint256 _feeBps = feeBps;
        for (uint256 i = 0; i < trancheValues.length; i++) {
            uint256 trancheValue = trancheValues[i];
            // fee tranche tokens are minted and held by the contract
            // upon maturity, they are redeemed and underlying collateral are sent to the owner
            uint256 fee = (trancheValue * _feeBps) / BPS;
            if (fee > 0) {
                _tranches[i].token.mint(address(this), fee);
            }

            _tranches[i].token.mint(_msgSender(), trancheValue - fee);
        }

        emit Deposit(_msgSender(), amount, _feeBps);
    }

    /**
     * @inheritdoc IBondController
     */
    function mature() external override {
        require(!isMature, "BondController: Already mature");
        require(owner() == _msgSender() || maturityDate < block.timestamp, "BondController: Invalid call to mature");
        isMature = true;

        TrancheData[] memory _tranches = tranches;
        uint256 collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        // Go through all tranches A-Y (not Z) delivering collateral if possible
        for (uint256 i = 0; i < _tranches.length - 1 && collateralBalance > 0; i++) {
            ITranche _tranche = _tranches[i].token;
            // pay out the entire tranche token's owed collateral (equal to the supply of tranche tokens)
            // if there is not enough collateral to pay it out, pay as much as we have
            uint256 amount = Math.min(_tranche.totalSupply(), collateralBalance);
            collateralBalance -= amount;

            TransferHelper.safeTransfer(collateralToken, address(_tranche), amount);

            // redeem fees, sending output tokens to owner
            _tranche.redeem(address(this), owner(), IERC20(_tranche).balanceOf(address(this)));
        }

        // Transfer any remaining collaeral to the Z tranche
        if (collateralBalance > 0) {
            ITranche _tranche = _tranches[_tranches.length - 1].token;
            TransferHelper.safeTransfer(collateralToken, address(_tranche), collateralBalance);
            _tranche.redeem(address(this), owner(), IERC20(_tranche).balanceOf(address(this)));
        }

        emit Mature(_msgSender());
    }

    /**
     * @inheritdoc IBondController
     */
    function redeemMature(address tranche, uint256 amount) external override {
        require(isMature, "BondController: Bond is not mature");
        require(trancheTokenAddresses[tranche], "BondController: Invalid tranche address");

        ITranche(tranche).redeem(_msgSender(), _msgSender(), amount);
        totalDebt -= amount;
        emit RedeemMature(_msgSender(), tranche, amount);
    }

    /**
     * @inheritdoc IBondController
     */
    function redeem(uint256[] memory amounts) external override {
        require(!isMature, "BondController: Bond is already mature");

        TrancheData[] memory _tranches = tranches;
        require(amounts.length == _tranches.length, "BondController: Invalid redeem amounts");
        uint256 total;

        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                (amounts[i] * TRANCHE_RATIO_GRANULARITY) / total == _tranches[i].ratio,
                "BondController: Invalid redemption ratio"
            );
            _tranches[i].token.burn(_msgSender(), amounts[i]);
        }

        uint256 collateralBalance = IERC20(collateralToken).balanceOf(address(this));
        // return as a proportion of the total debt redeemed
        uint256 returnAmount = (total * collateralBalance) / totalDebt;
        totalDebt -= total;
        TransferHelper.safeTransfer(collateralToken, _msgSender(), returnAmount);

        emit Redeem(_msgSender(), amounts);
    }

    /**
     * @inheritdoc IBondController
     */
    function setFee(uint256 newFeeBps) external override onlyOwner {
        require(!isMature, "BondController: Invalid call to setFee");
        require(newFeeBps <= MAX_FEE_BPS, "BondController: New fee too high");
        feeBps = newFeeBps;

        emit FeeUpdate(newFeeBps);
    }

    /**
     * @dev Get the string name for a tranche
     * @param collateralSymbol the symbol of the collateral token
     * @param index the tranche index
     * @param _trancheCount the total number of tranches
     * @return the string name of the tranche
     */
    function getTrancheName(
        string memory collateralSymbol,
        uint256 index,
        uint256 _trancheCount
    ) internal pure returns (string memory) {
        return
            string(abi.encodePacked("ButtonTranche ", collateralSymbol, " ", getTrancheLetter(index, _trancheCount)));
    }

    /**
     * @dev Get the string symbol for a tranche
     * @param collateralSymbol the symbol of the collateral token
     * @param index the tranche index
     * @param _trancheCount the total number of tranches
     * @return the string symbol of the tranche
     */
    function getTrancheSymbol(
        string memory collateralSymbol,
        uint256 index,
        uint256 _trancheCount
    ) internal pure returns (string memory) {
        return string(abi.encodePacked("TRANCHE-", collateralSymbol, "-", getTrancheLetter(index, _trancheCount)));
    }

    /**
     * @dev Get the string letter for a tranche index
     * @param index the tranche index
     * @param _trancheCount the total number of tranches
     * @return the string letter of the tranche index
     */
    function getTrancheLetter(uint256 index, uint256 _trancheCount) internal pure returns (string memory) {
        bytes memory trancheLetters = bytes("ABCDEFGHIJKLMNOPQRSTUVWXY");
        bytes memory target = new bytes(1);
        if (index == _trancheCount - 1) {
            target[0] = "Z";
        } else {
            target[0] = trancheLetters[index];
        }
        return string(target);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

struct TrancheData {
    ITranche token;
    uint256 ratio;
}

/**
 * @dev Controller for a ButtonTranche bond system
 */
interface IBondController {
    event Deposit(address from, uint256 amount, uint256 feeBps);
    event Mature(address caller);
    event RedeemMature(address user, address tranche, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event FeeUpdate(uint256 newFee);

    function collateralToken() external view returns (address);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function feeBps() external view returns (uint256 fee);

    /**
     * @dev Deposit `amount` tokens from `msg.sender`, get tranche tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amount` collateral tokens to this contract
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Matures the bond. Disables deposits,
     * fixes the redemption ratio, and distributes collateral to redemption pools
     * Redeems any fees collected from deposits, sending redeemed funds to the contract owner
     * Requirements:
     *  - The bond is not already mature
     *  - One of:
     *      - `msg.sender` is owner
     *      - `maturityDate` has passed
     */
    function mature() external;

    /**
     * @dev Redeems some tranche tokens
     * Requirements:
     *  - The bond is mature
     *  - `msg.sender` owns at least `amount` tranche tokens from address `tranche`
     *  - `tranche` must be a valid tranche token on this bond
     */
    function redeemMature(address tranche, uint256 amount) external;

    /**
     * @dev Redeems a slice of tranche tokens from all tranches.
     *  Returns collateral to the user proportionally to the amount of debt they are removing
     * Requirements
     *  - The bond is not mature
     *  - The number of `amounts` is the same as the number of tranches
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function redeem(uint256[] memory amounts) external;

    /**
     * @dev Updates the fee taken on deposit to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */
    function setFee(uint256 newFeeBps) external;
}

pragma solidity 0.8.3;

/**
 * @dev Factory for Tranche minimal proxy contracts
 */
interface ITrancheFactory {
    event TrancheCreated(address newTrancheAddress);

    /**
     * @dev Deploys a minimal proxy instance for a new tranche ERC20 token with the given parameters.
     */
    function createTranche(
        string memory name,
        string memory symbol,
        address _collateralToken
    ) external returns (address);
}

pragma solidity 0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @dev ERC20 token to represent a single tranche for a ButtonTranche bond
 *
 */
interface ITranche is IERC20 {
    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically creating tokens upon deposit
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically burning tokens upon redemption
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from` and return the proportional
     * value of the collateral token to `to`
     * @param from The address to burn tokens from
     * @param to The address to send collateral back to
     * @param amount The amount of tokens to burn
     */
    function redeem(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}