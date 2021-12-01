// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

//Openzeppelin Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Internal Imports
import "../interfaces/protocols/IdleInterface.sol";
import "../interfaces/IProtocolL1.sol";
import {Errors} from "../lib/helpers/Error.sol";

/**
 * @title IdleRA Child
 * @author SmartDeFi
 * @dev is used for minting IdleRA tokens.
 *
 * [TIP]: Inherits the interfaces from {IProtocol}. All children contracts inherits the same.
 */

contract IdleRAL1 is IProtocolL1, Ownable {
    IdleInterface public idle;
    IERC20 public usdc;

    mapping(address => bool) private _router;

    modifier onlyRouter() {
        require(_router[_msgSender()], Errors.AC_INVALID_ROUTER);
        _;
    }

    /**
     * @dev initialize the contract with default variables.
     * @param depositRouter is the SD deposit router contract.
     * @param withdrawalRouter is the SD withdrawal router contract.
     * @param idleContract (Here Risk Adjusted) is the idle token contract address.
     */
    constructor(
        address depositRouter,
        address withdrawalRouter,
        address idleContract,
        address usdcContract
    ) Ownable() {
        _router[depositRouter] = true;
        _router[withdrawalRouter] = true;
        idle = IdleInterface(idleContract);
        usdc = IERC20(usdcContract);
    }

    /**
     * @dev updated the router contracts.
     * @param depositRouter is the SD deposit router contract.
     * @param withdrawalRouter is the SD withdrawal router contract.
     * [Requirements]:
     * `_caller` has to be the owner of the contract.
     */
    function updateRouter(address depositRouter, address withdrawalRouter)
        external
        onlyOwner
    {
        require(
            depositRouter != address(0) && withdrawalRouter != address(0),
            Errors.VL_ZERO_ADDRESS
        );
        _router[depositRouter] = true;
        _router[withdrawalRouter] = true;
    }

    /**
     * @dev refer {IProtocol-mintProtocolToken}
     */
    function mintProtocolToken(uint256 amount)
        public
        virtual
        override
        onlyRouter
        returns (uint256)
    {
        usdc.approve(address(idle), amount);
        uint256 minted = idle.mintIdleToken(amount, true, address(0));
        // IMP: call withdraw to L2 function here
        // IERC20(idle).approve(predicate, minted);
        // manager.depositFor(_msgSender(),tokenContract, abi.encode(minted));
        return minted;
    }

    /**
     * @dev refer {IProtocol-redeemProtocolToken}
     */
    function redeemProtocolToken(uint256 amount)
        public
        virtual
        override
        onlyRouter
        returns (uint256)
    {
        return idle.redeemIdleToken(amount);
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

/**
 * @title: Idle Token interface
 * @author: Idle Labs Inc., idle.finance
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IdleInterface {
    // view
    /**
     * IdleToken price calculation, in underlying
     *
     * @return : price in underlying token
     */
    function tokenPrice() external view returns (uint256);

    /**
     * @return : underlying token address
     */
    function token() external view returns (address);

    /**
     * Get APR of every ILendingProtocol
     *
     * @return addresses: array of token addresses
     * @return aprs: array of aprs (ordered in respect to the `addresses` array)
     */
    function getAPRs()
        external
        view
        returns (address[] memory, uint256[] memory);

    // external
    // We should save the amount one has deposited to calc interests

    /**
     * Used to mint IdleTokens, given an underlying amount (eg. DAI).
     * This method triggers a rebalance of the pools if needed
     * NOTE: User should 'approve' _amount of tokens before calling mintIdleToken
     * NOTE 2: this method can be paused
     *
     * @param _amount : amount of underlying token to be lended
     * @param _skipRebalance : flag for skipping rebalance for lower gas price
     * @param _referral : referral address
     * @return mintedTokens : amount of IdleTokens minted
     */
    function mintIdleToken(
        uint256 _amount,
        bool _skipRebalance,
        address _referral
    ) external returns (uint256);

    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * This method triggers a rebalance of the pools if needed
     * NOTE: If the contract is paused or iToken price has decreased one can still redeem but no rebalance happens.
     * NOTE 2: If iToken price has decresed one should not redeem (but can do it) otherwise he would capitalize the loss.
     *         Ideally one should wait until the black swan event is terminated
     *
     * @param _amount : amount of IdleTokens to be burned
     * @return redeemedTokens : amount of underlying tokens redeemed
     */
    function redeemIdleToken(uint256 _amount) external returns (uint256);

    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * and send interest-bearing tokens (eg. cDAI/iDAI) directly to the user.
     * Underlying (eg. DAI) is not redeemed here.
     *
     * @param _amount : amount of IdleTokens to be burned
     */
    function redeemInterestBearingTokens(uint256 _amount) external;

    /**
     * @return : whether has rebalanced or not
     */
    function rebalance() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @dev Shared Interface of All Protocol-Children Contracts.
 */

interface IProtocolL1 {
    /**
     * @dev allows developers to custom code the Protocol Minting Functions.
     * @param amount represents the amount of USDC.
     * @return the amount of protocol tokens minted.
     */
    function mintProtocolToken(uint256 amount) external returns (uint256);

    /**
     * @dev allows developers to custom code the Protocol Withdrawal Functions.
     * @param amount represents the amount of tokens to be sold/redeemed.
     * @return the amount of USDC received.
     */
    function redeemProtocolToken(uint256 amount) external returns (uint256);
}

pragma solidity ^0.8.8;

library Errors {
    string public constant VL_INVALID_DEPOSIT = "1";
    string public constant VL_INSUFFICIENT_BALANCE = "2";

    string public constant VL_INSUFFICIENT_ALLOWANCE = "3";
    string public constant VL_BATCH_NOT_ELLIGIBLE = "4";
    string public constant VL_INVALID_PROTOCOL = "5";
    string public constant VL_ZERO_ADDRESS = "6";

    string public constant AC_USER_NOT_WHITELISTED = "7";
    string public constant AC_INVALID_GOVERNOR = "8";
    string public constant AC_INVALID_ROUTER = "9";
    string public constant AC_BATCH_ALREADY_PROCESSED = "10";
    string public constant VL_NONEXISTENT_CHANNEL = "11";
    string public constant VL_INVALID_CHANNEL = "12";
    string public constant VL_USDC_NOT_ARRIVED = "13";
    string public constant VL_INVALID_RECURRING_PURCHASE = "14";
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