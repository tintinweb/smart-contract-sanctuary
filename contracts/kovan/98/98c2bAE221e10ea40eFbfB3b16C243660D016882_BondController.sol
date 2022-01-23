// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IBondController.sol";
import "./interfaces/IIouFactory.sol";
import "./interfaces/IIou.sol";
import "./interfaces/ITranche.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

/**
 * @dev Controller for a HourGlass bond
 *
 * This bond has A iou and Z iou
 * A iou has two collateral: A tranche and Z tranche
 * Z iou has one collateral: Z tranche
 *
 * (maturityDate - creationDate) = 30 * 1 day
 * token.totalSupply at day 0 = token.totalSupply at day 30
 *
 * Day 0:
 * - Alice deposits 100 AMPL
 *   - Alice gets 20 A tranche worth 20 AMPL
 *   - Alice gets 50 Z tranche worth 50 AMPL
 * - Alice deposits 20 A tranche and 50 Z tranche
 *   - Alice gets 20 A iou worth 20 A tranche
 *   - Alice gets 50 Z iou worth 50 Z tranche
 *   - A iou totalSupply is 20
 *   - Z iou totalSupply is 50
 *
 * Day 3:
 * - AMPL supply decreased by 25% since Day 0
 * - Alice redeems 16 A iou + 40 Z iou
 *   - Alice gets 16 A tranche worth 16 AMPL
 *   - Alice gets 40 Z tranche worth 2 AMPL
 *   - A iou totalSupply is 4
 *   - Z iou totalSupply is 10
 *
 * Day 15:
 * - AMPL supply stayed the same since Day 3
 * - Bob deposits 75 AMPL
 *   - Bob gets 20 A tranche worth 20 AMPL
 *   - Bob gets 50 Z tranche worth 25 AMPL
 * - Bob deposits 20 A tranche and 50 Z tranche
 *   - Bob gets 20 A iou worth 20 A tranche and 25 Z tranche
 *   - Bob gets 50 Z iou worth 25 Z tranche
 *   - A iou totalSupply is 24
 *   - Z iou totalSupply is 60
 *
 * Day 30:
 * - AMPL supply recovers to its original amount on Day 0
 * - Alice redeemMatures 10 Z iou
 *   - Alice gets 10 Z tranche worth 10 AMPL
 *   - A iou totalSupply is 24
 *   - Z iou totalSupply is 50
 * - Bob redeemMatures 50 Z iou
 *   - Bob gets 10 Z tranche worth 10 AMPL
 *   - A iou totalSupply is 24
 *   - Z iou totalSupply is 0
 * - Alice redeemMatures 4 A iou
 *   - Alice gets 4 A tranche worth 4 AMPL
 *   - A iou totalSupply is 20
 *   - Z iou totalSupply is 0
 * - Bob redeemMatures 20 A iou
 *   - Bob gets 20 A tranche worth 20 AMPL
 *   - A iou totalSupply is 0
 *   - Z iou totalSupply is 0
 * - Alice redeems 20 A tranche worth 20 AMPL
 * - Alice redeems 50 Z tranche worth 50 AMPL
 * - Bob redeems 20 A tranche worth 20 AMPL
 * - Bob redeems 50 Z tranche worth 50 AMPL
 */
contract BondController is IBondController, OwnableUpgradeable, KeeperCompatibleInterface {
    uint256 public TRANCHE_RATIO_GRANULARITY;
    uint256 public constant INTEREST_RATE_GRANULARITY = 100000000000000;
    // Denominator for basis points. Used to calculate fees
    uint256 public constant BPS = 10_000;
    // Maximum fee in terms of basis points
    uint256 public constant MAX_FEE_BPS = 50;

    TrancheData[] public override tranches;
    address[] public override ious;
    uint256 public override trancheCount;
    mapping(address => bool) public iouTokenAddresses;
    uint256 public maturityDate;
    bool public isMature;
    uint256 public creationDate;
    address public token;
    uint256 public tokenSupplyAtCreation;
    uint256 public interestRate;
    // Fee taken on deposit in basis points. Can be set by the contract owner
    uint256 public override feeBps = MAX_FEE_BPS;

    /**
     * @dev Constructor for Tranche ERC20 token
     * @param _iouFactory The address of the iou factory
     * @param _tranches The tranches that may be deposited into this bond
     * @param _admin The address of the initial admin for this contract
     * @param _maturityDate The date timestamp in seconds at which this bond matures
     * @param _token The address of the ERC20 token whose totalSupply determines the interest rate
     */
    function init(
        address _iouFactory,
        TrancheData[] memory _tranches,
        address _admin,
        uint256 _maturityDate,
        address _token
    ) external initializer {
        require(_iouFactory != address(0), "BondController: invalid iouFactory address");
        require(_tranches.length == 2, "BondController: invalid tranche count");
        require(_admin != address(0), "BondController: invalid admin address");
        __Ownable_init();
        transferOwnership(_admin);

        trancheCount = _tranches.length;
        for (uint256 i = 0; i < _tranches.length; i++) {
            tranches.push(_tranches[i]);
        }

        // This bond only accepts `deposit`s and `redeem`s with the ratio defined by `_tranches`
        TRANCHE_RATIO_GRANULARITY = _tranches[0].ratio + _tranches[1].ratio;

        // Create A iou
        address iouTokenAddress = IIouFactory(_iouFactory).createIou("HourGlass token", "A-PRIME", address(_tranches[0].token));
        ious.push(iouTokenAddress);
        iouTokenAddresses[iouTokenAddress] = true;

        // Create Z iou
        iouTokenAddress = IIouFactory(_iouFactory).createIou("HourGlass token", "Z-PRIME", address(_tranches[1].token));
        ious.push(iouTokenAddress);
        iouTokenAddresses[iouTokenAddress] = true;

        require(ious.length == _tranches.length, "BondController: Invalid iou count");

        require(_maturityDate > block.timestamp, "BondController: Invalid maturity date");
        maturityDate = _maturityDate;
        creationDate = block.timestamp;
        token = _token;
        tokenSupplyAtCreation = IERC20(_token).totalSupply();
    }

    /**
     * @inheritdoc IBondController
     */
    function deposit(uint256[] memory amounts) external override {
        require(!isMature, "BondController: Already mature");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;
        require(amounts.length == _tranches.length, "BondController: Invalid deposit amounts");

        // Saving feeBps in memory to minimize sloads
        uint256 _feeBps = feeBps;
        uint256 total = amounts[0] + amounts[1];

        // If always deposit with correct ratio, then can always transfer in 20 A tranche and mint 20 A iou
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 amount = amounts[i];
            require(
                (amount * TRANCHE_RATIO_GRANULARITY) / total == _tranches[i].ratio,
                "BondController: Invalid deposit ratio"
            );
            TransferHelper.safeTransferFrom(address(_tranches[i].token), _msgSender(), address(this), amount);

            // Send fee _tranches[i].token to owner, mint amount less fee _ious[i] to sender
            uint256 fee = (amount * _feeBps) / BPS;
            if (fee > 0) {
                TransferHelper.safeTransfer(address(_tranches[i].token), owner(), fee);
            }
            IIou(_ious[i]).mint(_msgSender(), amount - fee);
        }

        emit Deposit(_msgSender(), amounts, _feeBps);
    }

    /**
     * @inheritdoc IBondController
     */
    function mature() external override {
        require(!isMature, "BondController: Already mature");
        require(owner() == _msgSender() || maturityDate < block.timestamp, "BondController: Invalid call to mature");
        isMature = true;

        // interestRate = INTEREST_RATE_GRANULARITY * tokenSupplyAtCreation / (tokenSupplyAtCreation + abs(tokenSupplyAtMaturity - tokenSupplyAtCreation));
        interestRate = INTEREST_RATE_GRANULARITY;
        uint256 tokenSupplyAtMaturity = IERC20(token).totalSupply();
        if (tokenSupplyAtMaturity < tokenSupplyAtCreation) {
          interestRate *= tokenSupplyAtCreation / (2 * tokenSupplyAtCreation - tokenSupplyAtMaturity);
        } else {
          interestRate *= tokenSupplyAtCreation / tokenSupplyAtMaturity;
        }

        emit Mature(_msgSender());
    }

    /**
     * @inheritdoc IBondController
     */
    function redeemMature(address iou, uint256 amount) external override {
        require(isMature, "BondController: Bond is not mature");
        require(iouTokenAddresses[iou], "BondController: Invalid iou address");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;

        // Burn so that double redeems are not possible
        IIou(iou).burn(_msgSender(), amount);

        uint256 interest;

        if (iou == _ious[0]) {

            interest = amount * _tranches[1].ratio * interestRate / _tranches[0].ratio / INTEREST_RATE_GRANULARITY;

            // Transfer some A tranche
            TransferHelper.safeTransfer(
              address(_tranches[0].token),
              _msgSender(),
              amount
            );

            // Transfer some Z tranche
            TransferHelper.safeTransfer(
              address(_tranches[1].token),
              _msgSender(),
              interest
            );

        } else if (iou == _ious[1]) {

            interest = amount * interestRate / INTEREST_RATE_GRANULARITY;

            // Transfer some Z tranche
            TransferHelper.safeTransfer(
              address(_tranches[1].token),
              _msgSender(),
              amount - interest
            );
        }

        emit RedeemMature(_msgSender(), iou, amount);
    }

    /**
     * @inheritdoc IBondController
     */
    function redeem(uint256[] memory amounts) external override {
        require(!isMature, "BondController: Bond is already mature");
        TrancheData[] memory _tranches = tranches;
        address[] memory _ious = ious;
        require(amounts.length == _ious.length, "BondController: Invalid redeem amounts");
        uint256 total;

        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }

        // If always redeem with correct ratio, then can always burn 20 A iou and transfer out 20 A tranche
        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                (amounts[i] * TRANCHE_RATIO_GRANULARITY) / total == _tranches[i].ratio,
                "BondController: Invalid redemption ratio"
            );

            // Burn so that double redeems are not possible
            IIou(_ious[i]).burn(_msgSender(), amounts[i]);

            TransferHelper.safeTransfer(address(_tranches[i].token), _msgSender(), amounts[i]);
        }

        emit Redeem(_msgSender(), amounts);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = maturityDate < block.timestamp - 60; // - 60 seconds in case reported timestamp is inaccurate
        performData = checkData;
    }

    function performUpkeep(bytes calldata) external override {
        this.mature();
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

/**
 * @dev Controller for a HourGlass bond system
 */
interface IBondController {
    event Deposit(address from, uint256[] amounts, uint256 feeBps);
    event Mature(address caller);
    event RedeemMature(address user, address iou, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event FeeUpdate(uint256 newFee);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function ious(uint256 i) external view returns (address iou);

    function trancheCount() external view returns (uint256 count);

    function feeBps() external view returns (uint256 fee);

    /**
     * @dev Deposit `amounts` tokens from `msg.sender`, get iou tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amounts` tokens to this contract
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function deposit(uint256[] memory amounts) external;

    /**
     * @dev Matures the bond. Disables deposits,
     * fixes the redemption ratio, and distributes collateral to redemption pools
     * Requirements:
     *  - The bond is not already mature
     *  - One of:
     *      - `msg.sender` is `owner`
     *      - `maturityDate` has passed
     */
    function mature() external;

    /**
     * @dev Redeems some iou tokens
     *  If `iou` is A iou token, then also transfer some `interestSacrified` tranches if any 
     * Requirements:
     *  - The bond is mature
     *  - `msg.sender` owns at least `amount` iou tokens from address `iou`
     *  - `iou` must be a valid iou token on this bond
     */
    function redeemMature(address iou, uint256 amount) external;

    /**
     * @dev Redeems a slice of iou tokens from all tranches.
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
     * - `newFeeBps` is in range [0, MAX_FEE_BPS]
     */
    function setFee(uint256 newFeeBps) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

/**
 * @dev Factory for Iou minimal proxy contracts
 */
interface IIouFactory {
    event IouCreated(address newIouAddress);

    /**
     * @dev Deploys a minimal proxy instance for a new iou ERC20 token with the given parameters.
     */
    function createIou(
        string memory name,
        string memory symbol,
        address _collateralToken
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev ERC20 token to represent a single IOU for a HourGlass bond
 *
 */
interface IIou is IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

struct TrancheData {
    ITranche token;
    uint256 ratio;
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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
}