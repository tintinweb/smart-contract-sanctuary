pragma solidity ^0.8.3;

import "./interfaces/IGlue.sol";
import "./interfaces/IOGLoanRouter.sol";
import "./interfaces/IOGBondController.sol";
import "./interfaces/ILoanRouter.sol";
import "./interfaces/IBondController.sol";
import "./interfaces/ITranche.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Glue is IGlue {
    uint256 public constant MAX_UINT256 = 2**256 - 1;

    /**
     * @inheritdoc IGlue
     */
    function deposit(
        uint256 ogAmount,
        IOGBondController ogBond,
        uint256[] memory amounts,
        IBondController bond
    ) external override {
        // Deposit to ogBond
        IERC20 ogCollateral = IERC20(ogBond.collateralToken());
        ogCollateral.transferFrom(msg.sender, address(this), ogAmount);
        ogCollateral.approve(address(ogBond), ogAmount);
        ogBond.deposit(ogAmount);

        // Sanitize amounts
        amounts = _sanitizeAmounts(bond, amounts);

        // Deposit to bond
        uint256 trancheCount = bond.trancheCount();
        for (uint256 i = 0; i < trancheCount; i++) {
            (ITranche collateralTranche, ) = bond.tranches(i);
            IERC20 collateral = IERC20(address(collateralTranche));
            collateral.approve(address(bond), amounts[i]);
        }
        bond.deposit(amounts);

        // Give all tokens to `msg.sender`
        uint256 ogTrancheCount = ogBond.trancheCount();
        IERC20[] memory tokens = new IERC20[](ogTrancheCount + trancheCount);
        for (uint256 i = 0; i < ogTrancheCount; i++) {
            (ITranche collateralTranche, ) = ogBond.tranches(i);
            IERC20 collateral = IERC20(address(collateralTranche));
            tokens[i] = collateral;
        }
        for (uint256 i = 0; i < trancheCount; i++) {
            tokens[ogTrancheCount + i] = IERC20(bond.ious(i));
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            tokens[i].transfer(msg.sender, balance);
        }
    }

    /**
     * @inheritdoc IGlue
     */
    function borrow(
        IERC20 currency,
        IOGLoanRouter ogLoanRouter,
        uint256 ogAmount,
        IOGBondController ogBond,
        uint256[] memory ogSales,
        uint256 ogMinOutput,
        ILoanRouter loanRouter,
        uint256[] memory amounts,
        IBondController bond,
        uint256[] memory sales,
        uint256 minOutput
    ) external override {
        // Borrow from ogLoanRouter
        {
            IERC20 ogCollateral = IERC20(ogBond.collateralToken());
            ogCollateral.transferFrom(msg.sender, address(this), ogAmount);
            ogCollateral.approve(address(ogLoanRouter), ogAmount);
            ogLoanRouter.borrow(ogAmount, ogBond, currency, ogSales, ogMinOutput);
        }

        // Sanitize amounts
        amounts = _sanitizeAmounts(bond, amounts);

        // Borrow from loanRouter
        uint256 trancheCount = bond.trancheCount();
        {
            for (uint256 i = 0; i < trancheCount; i++) {
                (ITranche collateralTranche, ) = bond.tranches(i);
                IERC20 collateral = IERC20(address(collateralTranche));
                collateral.approve(address(loanRouter), amounts[i]);
            }
            loanRouter.borrow(amounts, bond, currency, sales, minOutput);
        }

        // Give all tokens to `msg.sender`
        uint256 ogTrancheCount = ogBond.trancheCount();
        IERC20[] memory tokens = new IERC20[](ogTrancheCount + trancheCount + 1);
        for (uint256 i = 0; i < ogTrancheCount; i++) {
            (ITranche collateralTranche, ) = ogBond.tranches(i);
            IERC20 collateral = IERC20(address(collateralTranche));
            tokens[i] = collateral;
        }
        for (uint256 i = 0; i < trancheCount; i++) {
            tokens[ogTrancheCount + i] = IERC20(bond.ious(i));
        }
        tokens[tokens.length - 1] = currency;

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            tokens[i].transfer(msg.sender, balance);
        }
    }

    /**
     * @dev Sanitize amounts
     * Make sure amounts is correct, avoid reverting with "BondController: Invalid deposit amounts"
     * Also handle MAX_UINT256 amounts
     */
    function _sanitizeAmounts(IBondController bond, uint256[] memory amounts) internal view returns (uint256[] memory) {
        // Store tranche ratios for later
        uint256 trancheCount = bond.trancheCount();
        uint256[] memory ratios = new uint256[](trancheCount);

        // If amounts[i] is MAX_UINT256, set amounts[i] to all owned collateral
        for (uint256 i = 0; i < trancheCount; i++) {
            if (amounts[i] == MAX_UINT256) {
                (ITranche collateralTranche, uint256 ratio) = bond.tranches(i);
                IERC20 collateral = IERC20(address(collateralTranche));
                ratios[i] = ratio;
                amounts[i] = collateral.balanceOf(address(this));
            }
        }

        // Make deposit amounts precise
        // If bond tranche ratio is 200 / 500, then
        // - amounts[0] must be a multiple of 200
        // - amounts[1] must be a multiple of 500
        for (uint256 i = 0; i < ratios.length; i++) {
            amounts[i] -= amounts[i] % ratios[i];
        }

        // Make deposit amounts precise
        // If bond tranche ratio is 200 / 500, then
        // - amounts[0] / amounts[1] must be in a 200 / 500 ratio
        // Find out which amount is the limiting factor
        // Set non-limiting amount to the amount dictated by the limiting amount
        if (amounts[0] * ratios[1] < amounts[1] * ratios[0]) {
            // amounts[0] is the limiting factor
            amounts[1] = amounts[0] * ratios[1] / ratios[0];
        }
        if (amounts[0] * ratios[1] > amounts[1] * ratios[0]) {
            // amounts[1] is the limiting factor
            amounts[0] = amounts[1] * ratios[0] / ratios[1];
        }

        return amounts;
    }
}

pragma solidity 0.8.7;

import "./IOGLoanRouter.sol";
import "./IOGBondController.sol";
import "./ILoanRouter.sol";
import "./IBondController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Glue between the OG ButtonTranche bond system and the HourGlass bond system
 */
interface IGlue {

    /**
     * @dev Deposit a given collateral
     * Deposits twice
     *  - gives collateral to ogLoanRouter, takes A/B/Z tranches from ogLoanRouter
     *  - gives A/Z tranches to loanRouter, takes A/Z ious from loanRouter
     * Gives all tokens to `msg.sender`
     *
     * @param ogAmount The ogAmount of the collateral to deposit
     * @param ogBond The ogBond to deposit with
     * @param amounts The amounts of the collateral to deposit
     * @param bond The bond to deposit with
     */
    function deposit(
        uint256 ogAmount,
        IOGBondController ogBond,
        uint256[] memory amounts,
        IBondController bond
    ) external;

    /**
     * @dev Borrow a given currency from a given collateral
     * Borrows twice
     *  - gives collateral to ogLoanRouter, takes A/B/Z tranches and currency from ogLoanRouter
     *  - gives A/Z tranches to loanRouter, takes A/Z ious and currency from loanRouter
     * Gives all tokens to `msg.sender`
     *
     * @param currency The currency to borrow
     * @param ogLoanRouter The ogLoanRouter to borrow from
     * @param ogAmount The ogAmount of the collateral to deposit
     * @param ogBond The ogBond to deposit with
     * @param ogSales The amount of each tranche to sell for the currency.
     *  If MAX_UNT256, then sell full balance of the token
     * @param ogMinOutput The minimum amount of currency that should be recived, else reverts
     * @param loanRouter The loanRouter to borrow from
     * @param amounts The amounts of the collateral to deposit
     * @param bond The bond to deposit with
     * @param sales The amount of each iou to sell for the currency.
     *  If MAX_UNT256, then sell full balance of the token
     * @param minOutput The minimum amount of currency that should be recived, else reverts
     */
    function borrow(
        IERC20 currency,
        IOGLoanRouter ogLoanRouter,
        uint256 ogAmount,
        IOGBondController ogBond,
        uint256[] memory ogSales,
        uint256 ogMinOutput,
        ILoanRouter loanRouter,
        uint256[] memory amounts,
        IBondController bond,
        uint256[] memory sales,
        uint256 minOutput
    ) external;
}

pragma solidity 0.8.7;

import "./IOGBondController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Router for creating loans with tranche
 */
interface IOGLoanRouter {
    function borrow(
        uint256 amount,
        IOGBondController bond,
        IERC20 currency,
        uint256[] memory sales,
        uint256 minOutput
    ) external returns (uint256 amountOut);

    function borrowMax(
        uint256 amount,
        IOGBondController bond,
        IERC20 currency,
        uint256 minOutput
    ) external returns (uint256 amountOut);
}

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

/**
 * @dev Controller for a ButtonTranche bond system
 */
interface IOGBondController {
    event Deposit(address from, uint256 amount);
    event Mature(address caller);
    event RedeemMature(address user, address tranche, uint256 amount);
    event Redeem(address user, uint256[] amounts);

    function collateralToken() external view returns (address);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    /**
     * @dev Deposit `amount` tokens from `msg.sender`, get tranche tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amount` collateral tokens to this contract
     */
    function deposit(uint256 amount) external;

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
}

pragma solidity 0.8.7;

import "./IBondController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Router for creating loans with tranche
 */
interface ILoanRouter {
    function borrow(
        uint256[] memory amounts,
        IBondController bond,
        IERC20 currency,
        uint256[] memory sales,
        uint256 minOutput
    ) external returns (uint256 amountOut);

    function borrowMax(
        uint256[] memory amounts,
        IBondController bond,
        IERC20 currency,
        uint256 minOutput
    ) external returns (uint256 amountOut);
}

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
    event Deposit(address from, uint256[] amounts);
    event Mature(address caller);
    event RedeemMature(address user, address iou, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event RedeemEmergency(address user, uint256 amount);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function ious(uint256 i) external view returns (address iou);

    function trancheCount() external view returns (uint256 count);

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
     * @dev Gets the Z tranche interest that would be redeemed as if `amount` A iou tokens are redeemed at maturity
     */
    function getInterestOnRedeemMature(uint256 amount) external view returns (uint256);

    /**
     * @dev Gets the Z tranche interest sacrificed that would be redeemed as if `amount` A iou tokens are redeemed at maturity
     */
    function getInterestSacrificedOnRedeemMature(uint256 amount) external view returns (uint256);

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
     * @dev Gets the Z tranche interest that would be redeemed as if `amount` A iou tokens are redeemed before maturity at the current `block`'s timestamp
     */
    function getInterestOnRedeemEmergency(uint256 amount) external view returns (uint256);

    /**
     * @dev Redeems `amount` A iou tokens for `amount` A tranche tokens and the Z tranche interest earned till now
     * Requirements:
     *  - The bond is not mature
     *  - `msg.sender` owns at least `amount` A iou tokens
     */
    function redeemEmergency(uint256 amount) external;
}

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