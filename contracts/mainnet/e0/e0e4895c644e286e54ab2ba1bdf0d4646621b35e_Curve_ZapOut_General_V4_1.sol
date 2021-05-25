pragma solidity ^0.5.7;

import "../oz/ownership/Ownable.sol";
import "../oz/token/ERC20/SafeERC20.sol";

contract ZapBaseV1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;

    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(uint256 _goodwill, uint256 _affiliateSplit) public {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, uint256(-1));
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 _token = IERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function set_feeWhitelist(address zapAddress, bool status)
        external
        onlyOwner
    {
        feeWhitelist[zapAddress] = status;
    }

    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit)
        external
        onlyOwner
    {
        require(
            _new_affiliateSplit <= 100,
            "Affiliate Split Value not allowed"
        );
        affiliateSplit = _new_affiliateSplit;
    }

    function set_affiliate(address _affiliate, bool _status)
        external
        onlyOwner
    {
        affiliates[_affiliate] = _status;
    }

    ///@notice Withdraw goodwill share, retaining affilliate share
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance.sub(
                    totalAffiliateBalance[tokens[i]]
                );
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this)).sub(
                    totalAffiliateBalance[tokens[i]]
                );
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    ///@notice Withdraw affilliate share, retaining goodwill share
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]]
                .sub(tokenBal);

            if (tokens[i] == ETHAddress) {
                Address.sendValue(msg.sender, tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract swaps and bridges ETH/Tokens to Matic/Polygon
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "../_base/ZapBaseV1.sol";

// PoS Bridge
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function tokenToType(address) external returns (bytes32);

    function typeToPredicate(bytes32) external returns (address);
}

// Plasma Bridge
interface IDepositManager {
    function depositERC20ForUser(
        address _token,
        address _user,
        uint256 _amount
    ) external;
}

contract Zapper_Matic_Bridge_V1_2 is ZapBaseV1 {
    IRootChainManager public rootChainManager;
    IDepositManager public depositManager;

    address private constant maticAddress =
        0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {
        rootChainManager = IRootChainManager(
            0xA0c68C638235ee32657e8f720a23ceC1bFc77C77
        );
        depositManager = IDepositManager(
            0x401F6c983eA34274ec46f84D70b31C151321188b
        );
        IERC20(maticAddress).approve(address(depositManager), uint256(-1));
    }

    /**
    @notice Bridge from Ethereum to Matic
    @notice Use index 0 for primary swap and index 1 for matic swap
    @param fromToken Address of the token to swap from
    @param toToken Address of the token to bridge
    @param swapAmounts Quantites of fromToken to swap to toToken and matic
    @param minTokensRec Minimum acceptable quantity of swapped tokens and/or matic
    @param swapTargets Execution targets for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    */
    function ZapBridge(
        address fromToken,
        address toToken,
        uint256[2] calldata swapAmounts,
        uint256[2] calldata minTokensRec,
        address[2] calldata swapTargets,
        bytes[2] calldata swapData,
        address affiliate
    ) external payable {
        uint256[2] memory toInvest =
            _pullTokens(fromToken, swapAmounts, affiliate);

        if (swapAmounts[0] > 0) {
            // Token swap
            uint256 toTokenAmt =
                _fillQuote(
                    fromToken,
                    toInvest[0],
                    toToken,
                    swapTargets[0],
                    swapData[0]
                );
            require(toTokenAmt >= minTokensRec[0], "ERR: High Slippage 1");

            _bridgeToken(toToken, toTokenAmt);
        }

        // Matic swap
        if (swapAmounts[1] > 0) {
            uint256 maticAmount =
                _fillQuote(
                    fromToken,
                    toInvest[1],
                    maticAddress,
                    swapTargets[1],
                    swapData[1]
                );
            require(maticAmount >= minTokensRec[1], "ERR: High Slippage 2");

            _bridgeMatic(maticAmount);
        }
    }

    function _bridgeToken(address toToken, uint256 toTokenAmt) internal {
        if (toToken == address(0)) {
            rootChainManager.depositEtherFor.value(toTokenAmt)(msg.sender);
        } else {
            bytes32 tokenType = rootChainManager.tokenToType(toToken);
            address predicate = rootChainManager.typeToPredicate(tokenType);
            _approveToken(toToken, predicate);
            rootChainManager.depositFor(
                msg.sender,
                toToken,
                abi.encode(toTokenAmt)
            );
        }
    }

    function _bridgeMatic(uint256 maticAmount) internal {
        depositManager.depositERC20ForUser(
            maticAddress,
            msg.sender,
            maticAmount
        );
    }

    // 0x Swap
    function _fillQuote(
        address fromToken,
        uint256 amount,
        address toToken,
        address swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (fromToken == toToken) {
            return amount;
        }

        if (fromToken == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function _pullTokens(
        address fromToken,
        uint256[2] memory swapAmounts,
        address affiliate
    ) internal returns (uint256[2] memory toInvest) {
        if (fromToken == address(0)) {
            require(msg.value > 0, "No eth sent");
            require(
                swapAmounts[0].add(swapAmounts[1]) == msg.value,
                "msg.value != fromTokenAmounts"
            );
        } else {
            require(msg.value == 0, "Eth sent with token");

            // transfer token
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                swapAmounts[0].add(swapAmounts[1])
            );
        }

        if (swapAmounts[0] > 0) {
            toInvest[0] = swapAmounts[0].sub(
                _subtractGoodwill(fromToken, swapAmounts[0], affiliate)
            );
        }

        if (swapAmounts[1] > 0) {
            toInvest[1] = swapAmounts[1].sub(
                _subtractGoodwill(fromToken, swapAmounts[1], affiliate)
            );
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to 1inch mooniswap pools using any token
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "../_base/ZapBaseV1.sol";

interface IMooniswap {
    function getTokens() external view returns (address[] memory tokens);

    function tokens(uint256 i) external view returns (IERC20);

    function deposit(
        uint256[2] calldata maxAmounts,
        uint256[2] calldata minAmounts
    )
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);

    function depositFor(
        uint256[2] calldata maxAmounts,
        uint256[2] calldata minAmounts,
        address target
    )
        external
        payable
        returns (uint256 fairSupply, uint256[2] memory receivedAmounts);
}

contract Mooniswap_ZapIn_V1 is ZapBaseV1 {
    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice Adds liquidity to 1inch pools with an any token
    @param fromToken The ERC20 token used for investment (address(0x00) if ether)
    @param toPool The 1inch pool to add liquidity to
    @param minPoolTokens Minimum acceptable quantity of LP tokens to receive
    @param fromTokenAmounts Quantities of fromToken to invest into each poolToken
    @param swapTargets Excecution targets for both swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @return Quantitiy of LP received
     */

    function ZapIn(
        address fromToken,
        address toPool,
        uint256 minPoolTokens,
        uint256[] calldata fromTokenAmounts,
        address[] calldata swapTargets,
        bytes[] calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 lpReceived) {
        // get incoming tokens
        uint256[2] memory toInvest =
            _pullTokens(fromToken, fromTokenAmounts, affiliate);

        uint256[] memory amounts = new uint256[](2);

        // get underlying tokens
        address[] memory tokens = IMooniswap(toPool).getTokens();

        // No swap if fromToken is underlying
        if (fromToken == tokens[0]) {
            amounts[0] = toInvest[0];
        } else {
            // swap 50% fromToken to token 0
            amounts[0] = _fillQuote(
                fromToken,
                tokens[0],
                toInvest[0],
                swapTargets[0],
                swapData[0]
            );
        }
        // No swap if fromToken is underlying
        if (fromToken == tokens[1]) {
            amounts[1] = toInvest[1];
        } else {
            // swap 50% fromToken to token 1
            amounts[1] = _fillQuote(
                fromToken,
                tokens[1],
                toInvest[1],
                swapTargets[1],
                swapData[1]
            );
        }

        lpReceived = _inchDeposit(tokens, amounts, toPool);

        require(lpReceived >= minPoolTokens, "ERR: High Slippage");
    }

    function _inchDeposit(
        address[] memory tokens,
        uint256[] memory amounts,
        address toPool
    ) internal returns (uint256 lpReceived) {
        // minToken amounts = 90% of token amounts
        uint256[2] memory minAmounts =
            [amounts[0].mul(90).div(100), amounts[1].mul(90).div(100)];
        uint256[2] memory receivedAmounts;

        // tokens[1] is never ETH, approving for both cases
        IERC20(tokens[1]).safeApprove(toPool, 0);
        IERC20(tokens[1]).safeApprove(toPool, amounts[1]);

        if (tokens[0] == address(0)) {
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor.value(
                amounts[0]
            )([amounts[0], amounts[1]], minAmounts, msg.sender);
        } else {
            IERC20(tokens[0]).safeApprove(toPool, 0);
            IERC20(tokens[0]).safeApprove(toPool, amounts[0]);
            (lpReceived, receivedAmounts) = IMooniswap(toPool).depositFor(
                [amounts[0], amounts[1]],
                minAmounts,
                msg.sender
            );
        }

        emit zapIn(msg.sender, toPool, lpReceived);

        // transfer any residue
        for (uint8 i = 0; i < 2; i++) {
            if (amounts[i] > receivedAmounts[i] + 1) {
                _transferTokens(tokens[i], amounts[i].sub(receivedAmounts[i]));
            }
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            IERC20 fromToken = IERC20(fromTokenAddress);
            fromToken.safeApprove(address(swapTarget), 0);
            fromToken.safeApprove(address(swapTarget), amount);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function _transferTokens(address token, uint256 amt) internal {
        if (token == address(0)) {
            Address.sendValue(msg.sender, amt);
        } else {
            IERC20(token).safeTransfer(msg.sender, amt);
        }
    }

    function _pullTokens(
        address fromToken,
        uint256[] memory fromTokenAmounts,
        address affiliate
    ) internal returns (uint256[2] memory toInvest) {
        if (fromToken == address(0)) {
            require(msg.value > 0, "No eth sent");
            require(
                fromTokenAmounts[0].add(fromTokenAmounts[1]) == msg.value,
                "msg.value != fromTokenAmounts"
            );
        } else {
            require(msg.value == 0, "Eth sent with token");

            // transfer token
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                fromTokenAmounts[0].add(fromTokenAmounts[1])
            );
        }

        toInvest[0] = fromTokenAmounts[0].sub(
            _subtractGoodwill(fromToken, fromTokenAmounts[0], affiliate)
        );
        toInvest[1] = fromTokenAmounts[1].sub(
            _subtractGoodwill(fromToken, fromTokenAmounts[1], affiliate)
        );
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

pragma solidity ^0.5.7;

import "./ZapBaseV1.sol";

contract ZapOutBaseV2_1 is ZapBaseV1 {
    /**
    @dev Transfer tokens from msg.sender to this contract
    @param token The ERC20 token to transfer to this contract
    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
    @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );

            IERC20 _token = IERC20(token);
            uint256 allowance = _token.allowance(msg.sender, address(this));
            _token.safeTransferFrom(msg.sender, address(this), allowance);

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract implements one click removal of liquidity from Sushiswap pools, receiving ETH, ERC tokens or both.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;
import "../../_base/ZapOutBaseV2.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Sushiswap_ZapOut_Polygon_V1 is ZapOutBaseV2_1 {
    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    // sushiSwap
    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice Zap out in both tokens with permit
    @param fromSushiPool Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @return  amountA, amountB - Quantity of tokens received 
    */
    function ZapOut2PairToken(
        address fromSushiPool,
        uint256 incomingLP,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);

        require(
            address(pair) != address(0),
            "Error: Invalid Sushipool Address"
        );

        //get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        incomingLP = _pullTokens(
            fromSushiPool,
            incomingLP,
            shouldSellEntireBalance
        );

        _approveToken(fromSushiPool, address(sushiSwapRouter), incomingLP);

        if (token0 == wmaticTokenAddress || token1 == wmaticTokenAddress) {
            address _token = token0 == wmaticTokenAddress ? token1 : token0;
            (amountA, amountB) = sushiSwapRouter.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA.sub(tokenGoodwill));
            Address.sendValue(msg.sender, amountB.sub(ethGoodwill));
        } else {
            (amountA, amountB) = sushiSwapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(
                msg.sender,
                amountA.sub(tokenAGoodwill)
            );
            IERC20(token1).safeTransfer(
                msg.sender,
                amountB.sub(tokenBGoodwill)
            );
        }
        emit zapOut(msg.sender, fromSushiPool, token0, amountA);
        emit zapOut(msg.sender, fromSushiPool, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param toToken Address of desired token
    @param fromSushiPool Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param allowanceTargets Targets to approve for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
    */
    function ZapOut(
        address toToken,
        address fromSushiPool,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        address[] memory allowanceTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokenBought) {
        incomingLP = _pullTokens(
            fromSushiPool,
            incomingLP,
            shouldSellEntireBalance
        );

        (uint256 amountA, uint256 amountB) =
            _removeLiquidity(fromSushiPool, incomingLP);

        tokenBought = _swapTokens(
            fromSushiPool,
            amountA,
            amountB,
            toToken,
            swapTargets,
            allowanceTargets,
            swapData
        );

        require(tokenBought >= minTokensRec, "High slippage");

        uint256 tokensRec = _transfer(toToken, tokenBought, affiliate);

        emit zapOut(msg.sender, fromSushiPool, toToken, tokensRec);

        return tokensRec;
    }

    function _transfer(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 tokensTransferred) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                amount,
                affiliate,
                true
            );

            msg.sender.transfer(amount.sub(totalGoodwillPortion));
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                token,
                amount,
                affiliate,
                true
            );

            IERC20(token).safeTransfer(
                msg.sender,
                amount.sub(totalGoodwillPortion)
            );
        }
        tokensTransferred = amount.sub(totalGoodwillPortion);
    }

    function _removeLiquidity(address fromSushiPool, uint256 incomingLP)
        internal
        returns (uint256 amountA, uint256 amountB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);

        require(
            address(pair) != address(0),
            "Error: Invalid Sushipool Address"
        );

        address token0 = pair.token0();
        address token1 = pair.token1();

        _approveToken(fromSushiPool, address(sushiSwapRouter), incomingLP);

        (amountA, amountB) = sushiSwapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amountA > 0 && amountB > 0, "Removed insufficient liquidity");
    }

    function _swapTokens(
        address fromSushiPool,
        uint256 amountA,
        uint256 amountB,
        address toToken,
        address[] memory swapTargets,
        address[] memory allowanceTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);
        address token0 = pair.token0();
        address token1 = pair.token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought.add(amountA);
        } else {
            tokensBought = tokensBought.add(
                _fillQuote(
                    token0,
                    toToken,
                    amountA,
                    swapTargets[0],
                    allowanceTargets[0],
                    swapData[0]
                )
            );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought.add(amountB);
        } else {
            //swap token using 0x swap
            tokensBought = tokensBought.add(
                _fillQuote(
                    token1,
                    toToken,
                    amountB,
                    swapTargets[1],
                    allowanceTargets[1],
                    swapData[1]
                )
            );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        address allowanceTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        uint256 valueToSend;

        if (fromTokenAddress == wmaticTokenAddress && toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(amount);
            return amount;
        }

        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, allowanceTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        (bool success, ) = swapTarget.call.value(valueToSend)(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken).sub(initialBalance);

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
    @notice Utility function to determine quantity and addresses of tokens being removed
    @param fromSushiPool Pool from which to remove liquidity
    @param liquidity Quantity of LP tokens to remove.
    @return  amountA- amountB- Quantity of token0 and token1 removed
    @return  token0- token1- Addresses of the underlying tokens to be removed
    */
    function removeLiquidityReturn(address fromSushiPool, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromSushiPool);
        uint256 balance1 = IERC20(token1).balanceOf(fromSushiPool);

        uint256 _totalSupply = pair.totalSupply();

        amountA = liquidity.mul(balance0) / _totalSupply;
        amountB = liquidity.mul(balance1) / _totalSupply;
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract removes liquidity from Curve pools

pragma solidity ^0.5.7;
import "../_base/ZapOutBaseV2.sol";
import "./Curve_Registry_V2.sol";

interface ICurveSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool removeUnderlying
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 index)
        external
        view
        returns (uint256);
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Curve_ZapOut_General_V4_1 is ZapOutBaseV2_1 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    Curve_Registry_V2 public curveReg;

    mapping(address => bool) public approvedTargets;

    constructor(
        Curve_Registry_V2 _curveRegistry,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) public ZapBaseV1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        curveReg = _curveRegistry;
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice This method removes the liquidity from curve pools to ETH/ERC tokens
    @param swapAddress indicates Curve swap address for the pool
    @param incomingCrv indicates the amount of lp tokens to remove
    @param intermediateToken specifies in which token to exit the curve pool
    @param toToken indicates the ETH/ERC token to which tokens to convert
    @param minToTokens indicates the minimum amount of toTokens to receive
    @param _swapTarget Excecution target for the first swap
    @param _swapCallData DEX quote data
    @param affiliate Affiliate address to share fees
    @param shouldSellEntireBalance True if incomingCrv is determined at execution time (i.e. contract is caller)
    @return ToTokensBought- indicates the amount of toTokens received
     */
    function ZapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        uint256 minToTokens,
        address _swapTarget,
        bytes calldata _swapCallData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external stopInEmergency returns (uint256 ToTokensBought) {
        address poolTokenAddress = curveReg.getTokenAddress(swapAddress);

        // get lp tokens
        incomingCrv = _pullTokens(
            poolTokenAddress,
            incomingCrv,
            shouldSellEntireBalance
        );

        if (intermediateToken == address(0)) {
            intermediateToken = ETHAddress;
        }

        // perform zapOut
        ToTokensBought = _zapOut(
            swapAddress,
            incomingCrv,
            intermediateToken,
            toToken,
            _swapTarget,
            _swapCallData
        );
        require(ToTokensBought >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        // Transfer tokens
        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                ToTokensBought,
                affiliate,
                true
            );
            Address.sendValue(
                msg.sender,
                ToTokensBought.sub(totalGoodwillPortion)
            );
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                ToTokensBought,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                ToTokensBought.sub(totalGoodwillPortion)
            );
        }

        emit zapOut(msg.sender, swapAddress, toToken, ToTokensBought);

        return ToTokensBought.sub(totalGoodwillPortion);
    }

    function _zapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 ToTokensBought) {
        (bool isUnderlying, uint256 underlyingIndex) =
            curveReg.isUnderlyingToken(swapAddress, intermediateToken);

        // not metapool
        if (isUnderlying) {
            uint256 intermediateBought =
                _exitCurve(
                    swapAddress,
                    incomingCrv,
                    underlyingIndex,
                    intermediateToken
                );

            if (intermediateToken == ETHAddress) intermediateToken = address(0);

            ToTokensBought = _fillQuote(
                intermediateToken,
                toToken,
                intermediateBought,
                _swapTarget,
                _swapCallData
            );
        } else {
            // from metapool
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            uint8 i;
            for (; i < 4; i++) {
                if (curveReg.getSwapAddress(poolTokens[i]) != address(0)) {
                    intermediateSwapAddress = curveReg.getSwapAddress(
                        poolTokens[i]
                    );
                    break;
                }
            }
            // _exitCurve to intermediateSwapAddress Token
            uint256 intermediateCrvBought =
                _exitMetaCurve(swapAddress, incomingCrv, i, poolTokens[i]);
            // _performZapOut: fromPool = intermediateSwapAddress
            ToTokensBought = _zapOut(
                intermediateSwapAddress,
                intermediateCrvBought,
                intermediateToken,
                toToken,
                _swapTarget,
                _swapCallData
            );
        }
    }

    /**
    @notice This method removes the liquidity from meta curve pools
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitMetaCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256 tokensReceived) {
        require(incomingCrv > 0, "Insufficient lp tokens");

        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, swapAddress);

        uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
        ICurveSwap(swapAddress).remove_liquidity_one_coin(
            incomingCrv,
            int128(index),
            0
        );
        tokensReceived = (IERC20(exitTokenAddress).balanceOf(address(this)))
            .sub(iniTokenBal);

        require(tokensReceived > 0, "Could not receive reserve tokens");
    }

    /**
    @notice This method removes the liquidity from given curve pool
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256 tokensReceived) {
        require(incomingCrv > 0, "Insufficient lp tokens");

        address depositAddress = curveReg.getDepositAddress(swapAddress);

        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, depositAddress);

        address balanceToken =
            exitTokenAddress == ETHAddress ? address(0) : exitTokenAddress;

        uint256 iniTokenBal = _getBalance(balanceToken);

        if (curveReg.shouldAddUnderlying(swapAddress)) {
            // aave
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(index),
                0,
                true
            );
        } else {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(index),
                0
            );
        }

        tokensReceived = _getBalance(balanceToken).sub(iniTokenBal);

        require(tokensReceived > 0, "Could not receive reserve tokens");
    }

    /**
    @notice This method swaps the fromToken to toToken using the 0x swap
    @param _fromTokenAddress indicates the ETH/ERC20 token
    @param _toTokenAddress indicates the ETH/ERC20 token
    @param _amount indicates the amount of from tokens to swap
    @param _swapTarget Excecution target for the first swap
    @param _swapCallData DEX quote data
    */
    function _fillQuote(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 amountBought) {
        if (_fromTokenAddress == _toTokenAddress) return _amount;
        if (_swapTarget == wethTokenAddress) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }
        uint256 valueToSend;
        if (_fromTokenAddress == ETHAddress || _fromTokenAddress == address(0))
            valueToSend = _amount;
        else _approveToken(_fromTokenAddress, _swapTarget);

        uint256 iniBal = _getBalance(_toTokenAddress);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call.value(valueToSend)(_swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toTokenAddress);

        amountBought = finalBal.sub(iniBal);

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param swapAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove.
    @return  amount Quantity of token removed
    */
    function removeLiquidityReturn(
        address swapAddress,
        address tokenAddress,
        uint256 liquidity
    ) external view returns (uint256 amount) {
        if (tokenAddress == address(0)) tokenAddress = ETHAddress;
        (bool underlying, uint256 index) =
            curveReg.isUnderlyingToken(swapAddress, tokenAddress);
        if (underlying) {
            return
                ICurveSwap(curveReg.getDepositAddress(swapAddress))
                    .calc_withdraw_one_coin(liquidity, int128(index));
        } else {
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            for (uint256 i = 0; i < 4; i++) {
                intermediateSwapAddress = curveReg.getSwapAddress(
                    poolTokens[i]
                );
                if (intermediateSwapAddress != address(0)) break;
            }
            uint256 metaTokensRec =
                ICurveSwap(swapAddress).calc_withdraw_one_coin(liquidity, 1);

            (, index) = curveReg.isUnderlyingToken(
                intermediateSwapAddress,
                tokenAddress
            );

            return
                ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
                    metaTokensRec,
                    int128(index)
                );
        }
    }

    function updateCurveRegistry(Curve_Registry_V2 newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        curveReg = newCurveRegistry;
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Registry for Curve Pools with Utility functions.

pragma solidity ^0.5.7;

import "../oz/ownership/Ownable.sol";
import "../oz/token/ERC20/SafeERC20.sol";

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address lpToken)
        external
        view
        returns (address);

    function get_lp_token(address swapAddress) external view returns (address);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

interface ICurveFactoryRegistry {
    function get_n_coins(address _pool)
        external
        view
        returns (uint256, uint256);

    function get_coins(address _pool) external view returns (address[2] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);
}

contract Curve_Registry_V2 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ICurveAddressProvider private constant CurveAddressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
    ICurveRegistry public CurveRegistry;

    ICurveFactoryRegistry public FactoryRegistry;

    address private constant wbtcToken =
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant sbtcCrvToken =
        0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public shouldAddUnderlying;
    mapping(address => address) private depositAddresses;

    constructor() public {
        CurveRegistry = ICurveRegistry(CurveAddressProvider.get_registry());
        FactoryRegistry = ICurveFactoryRegistry(
            CurveAddressProvider.get_address(3)
        );
    }

    function isCurvePool(address swapAddress) public view returns (bool) {
        if (CurveRegistry.get_lp_token(swapAddress) != address(0)) {
            return true;
        }
        return false;
    }

    function isFactoryPool(address swapAddress) public view returns (bool) {
        if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
            return true;
        }
        return false;
    }

    /**
    @notice This function is used to get the curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return curve pool deposit address or the swap address not mapped
    */
    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress)
    {
        depositAddress = depositAddresses[swapAddress];
        if (depositAddress == address(0)) return swapAddress;
    }

    /**
    @notice This function is used to get the curve pool swap address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return curve pool swap address or address(0) if pool doesnt exist
    */
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress)
    {
        swapAddress = CurveRegistry.get_pool_from_lp_token(tokenAddress);
        if (swapAddress != address(0)) {
            return swapAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return tokenAddress;
        }
        return address(0);
    }

    /**
    @notice This function is used to check the curve pool token address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return curve pool token address or address(0) if pool doesnt exist
    */
    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress)
    {
        tokenAddress = CurveRegistry.get_lp_token(swapAddress);
        if (tokenAddress != address(0)) {
            return tokenAddress;
        }
        if (isFactoryPool(swapAddress)) {
            return swapAddress;
        }
        return address(0);
    }

    /**
    @notice Checks the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return number of underlying tokens in the pool
    */
    function getNumTokens(address swapAddress) public view returns (uint256) {
        if (isCurvePool(swapAddress)) {
            return CurveRegistry.get_n_coins(swapAddress)[0];
        } else {
            (uint256 numTokens, ) = FactoryRegistry.get_n_coins(swapAddress);
            return numTokens;
        }
    }

    /**
    @notice This function is used to check if the curve pool is a metapool
    @notice all factory pools are metapools
    @param swapAddress Curve swap address for the pool
    @return true if the pool is a metapool, false otherwise
    */
    function isMetaPool(address swapAddress) public view returns (bool) {
        if (isCurvePool(swapAddress)) {
            uint256[2] memory poolTokenCounts =
                CurveRegistry.get_n_coins(swapAddress);
            if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
            else return true;
        }
        if (isFactoryPool(swapAddress)) return true;
    }

    /**
    @notice This function returns an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return returns 4 element array containing the addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
    function getPoolTokens(address swapAddress)
        public
        view
        returns (address[4] memory poolTokens)
    {
        if (isMetaPool(swapAddress)) {
            if (isFactoryPool(swapAddress)) {
                address[2] memory poolUnderlyingCoins =
                    FactoryRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            } else {
                address[8] memory poolUnderlyingCoins =
                    CurveRegistry.get_coins(swapAddress);
                for (uint256 i = 0; i < 2; i++) {
                    poolTokens[i] = poolUnderlyingCoins[i];
                }
            }

            return poolTokens;
        } else {
            address[8] memory poolUnderlyingCoins;
            if (isBtcPool(swapAddress) && !isMetaPool(swapAddress)) {
                poolUnderlyingCoins = CurveRegistry.get_coins(swapAddress);
            } else {
                poolUnderlyingCoins = CurveRegistry.get_underlying_coins(
                    swapAddress
                );
            }
            for (uint256 i = 0; i < 4; i++) {
                poolTokens[i] = poolUnderlyingCoins[i];
            }
        }
    }

    /**
    @notice This function checks if the curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
    function isBtcPool(address swapAddress) public view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == wbtcToken || poolTokens[i] == sbtcCrvToken)
                return true;
        }
        return false;
    }

    /**
    @notice This function checks if the curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
    function isEthPool(address swapAddress) external view returns (bool) {
        address[8] memory poolTokens = CurveRegistry.get_coins(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == ETHAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @notice This function is used to check if the pool contains the token
    @param swapAddress Curve swap address for the pool
    @param tokenContractAddress contract address of the token
    @return true if the pool contains the token, false otherwise
    @return index of the token in the pool, 0 if pool does not contain the token
    */
    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint256) {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint256 i = 0; i < 4; i++) {
            if (poolTokens[i] == address(0)) return (false, 0);
            if (poolTokens[i] == tokenContractAddress) return (true, i);
        }
    }

    /**
    @notice Updates to the latest curve registry from the address provider
    */
    function update_curve_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_registry();

        require(address(CurveRegistry) != new_address, "Already updated");

        CurveRegistry = ICurveRegistry(new_address);
    }

    /**
    @notice Updates to the latest curve registry from the address provider
    */
    function update_factory_registry() external onlyOwner {
        address new_address = CurveAddressProvider.get_address(3);

        require(address(FactoryRegistry) != new_address, "Already updated");

        FactoryRegistry = ICurveFactoryRegistry(new_address);
    }

    /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
    function updateShouldAddUnderlying(
        address[] calldata swapAddresses,
        bool[] calldata addUnderlying
    ) external onlyOwner {
        require(
            swapAddresses.length == addUnderlying.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            shouldAddUnderlying[swapAddresses[i]] = addUnderlying[i];
        }
    }

    /**
    @notice Add new pools which use uamounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
    function updateDepositAddresses(
        address[] calldata swapAddresses,
        address[] calldata _depositAddresses
    ) external onlyOwner {
        require(
            swapAddresses.length == _depositAddresses.length,
            "Mismatched arrays"
        );
        for (uint256 i = 0; i < swapAddresses.length; i++) {
            depositAddresses[swapAddresses[i]] = _depositAddresses[i];
        }
    }

    /**
    //@notice Add new pools which use the _use_underlying bool
    */
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract migrates liquidity from the Sushi yveCRV/ETH Pickle Jar to the Sushi yvBOOST/ETH Pickle Jar
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../oz/ownership/Ownable.sol";
import "../oz/token/ERC20/SafeERC20.sol";

interface IPickleJar {
    function token() external view returns (address);

    function withdraw(uint256 _shares) external;

    function getRatio() external view returns (uint256);

    function deposit(uint256 amount) external;
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

interface IYearnZapIn {
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        address superVault,
        bool isAaveUnderlying,
        uint256 minYVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable returns (uint256 yvBoostRec);
}

contract yvBoost_Migrator_V1_0_1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public stopped = false;

    address constant yveCRV_ETH_Sushi =
        0x10B47177E92Ef9D5C6059055d92DdF6290848991;
    address constant yveCRV_ETH_pJar =
        0x5Eff6d166D66BacBC1BF52E2C54dD391AE6b1f48;

    address constant yvBOOST_ETH_Sushi =
        0x9461173740D27311b176476FA27e94C681b1Ea6b;
    address constant yvBOOST_ETH_pJar =
        0xCeD67a187b923F0E5ebcc77C7f2F7da20099e378;

    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;

    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;

    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    IYearnZapIn yearnZapIn;

    constructor(address _yearnZapIn) public {
        yearnZapIn = IYearnZapIn(_yearnZapIn);
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
    @notice This function migrates pTokens from pSushi yveCRV-ETH to pSushi yveBOOST-ETH 
    @param IncomingLP Quantity of pSushi yveCRV-ETH tokens to migrate
    @param minPTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @return pTokensRec- Quantity of pSushi yveBOOST-ETH tokens acquired
     */
    function Migrate(uint256 IncomingLP, uint256 minPTokens)
        external
        stopInEmergency
        returns (uint256 pTokensRec)
    {
        IERC20(yveCRV_ETH_pJar).safeTransferFrom(
            msg.sender,
            address(this),
            IncomingLP
        );

        uint256 underlyingReceived = _jarWithdraw(yveCRV_ETH_pJar, IncomingLP);

        (uint256 amountA, uint256 amountB, address tokenA, ) =
            _sushiWithdraw(underlyingReceived);

        uint256 wethRec = tokenA == yveCRV ? amountB : amountA;

        uint256 yvBoostRec =
            _yearnDeposit(tokenA == yveCRV ? amountA : amountB);

        IUniswapV2Pair pair = IUniswapV2Pair(yvBOOST_ETH_Sushi);

        uint256 token0Amt = pair.token0() == yvBOOST ? yvBoostRec : wethRec;
        uint256 token1Amt = pair.token1() == yvBOOST ? yvBoostRec : wethRec;

        uint256 sushiLpRec =
            _sushiDeposit(pair.token0(), pair.token1(), token0Amt, token1Amt);

        pTokensRec = _jarDeposit(sushiLpRec);

        require(pTokensRec >= minPTokens, "ERR: High Slippage");

        IERC20(yvBOOST_ETH_pJar).transfer(msg.sender, pTokensRec);
    }

    function _jarWithdraw(address fromJar, uint256 amount)
        internal
        returns (uint256 underlyingReceived)
    {
        uint256 iniUnderlyingBal = _getBalance(yveCRV_ETH_Sushi);
        IPickleJar(fromJar).withdraw(amount);
        underlyingReceived = _getBalance(yveCRV_ETH_Sushi).sub(
            iniUnderlyingBal
        );
    }

    function _jarDeposit(uint256 amount)
        internal
        returns (uint256 pTokensReceived)
    {
        _approveToken(yvBOOST_ETH_Sushi, yvBOOST_ETH_pJar, amount);

        uint256 iniYVaultBal = _getBalance(yvBOOST_ETH_pJar);

        IPickleJar(yvBOOST_ETH_pJar).deposit(amount);

        pTokensReceived = _getBalance(yvBOOST_ETH_pJar).sub(iniYVaultBal);
    }

    function _yearnDeposit(uint256 amountIn)
        internal
        returns (uint256 yvBoostRec)
    {
        _approveToken(yveCRV, address(yearnZapIn), amountIn);

        yvBoostRec = yearnZapIn.ZapIn(
            yveCRV,
            amountIn,
            yvBOOST,
            address(0),
            false,
            0,
            yveCRV,
            address(0),
            "",
            address(0)
        );
    }

    function _sushiWithdraw(uint256 IncomingLP)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            address tokenA,
            address tokenB
        )
    {
        _approveToken(yveCRV_ETH_Sushi, address(sushiSwapRouter), IncomingLP);

        IUniswapV2Pair pair = IUniswapV2Pair(yveCRV_ETH_Sushi);

        address token0 = pair.token0();
        address token1 = pair.token1();
        (amountA, amountB) = sushiSwapRouter.removeLiquidity(
            token0,
            token1,
            IncomingLP,
            1,
            1,
            address(this),
            deadline
        );
        return (amountA, amountB, tokenA, tokenB);
    }

    function _sushiDeposit(
        address toUnipoolToken0,
        address toUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        _approveToken(toUnipoolToken0, address(sushiSwapRouter), token0Bought);
        _approveToken(toUnipoolToken1, address(sushiSwapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            sushiSwapRouter.addLiquidity(
                toUnipoolToken0,
                toUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        //Returning Residue in token0, if any
        if (token0Bought.sub(amountA) > 0) {
            IERC20(toUnipoolToken0).safeTransfer(
                msg.sender,
                token0Bought.sub(amountA)
            );
        }

        //Returning Residue in token1, if any
        if (token1Bought.sub(amountB) > 0) {
            IERC20(toUnipoolToken1).safeTransfer(
                msg.sender,
                token1Bought.sub(amountB)
            );
        }

        return LP;
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20 _token = IERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    function updateYearnZapIn(address _yearnZapIn) external onlyOwner {
        yearnZapIn = IYearnZapIn(_yearnZapIn);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }
}

pragma solidity ^0.5.7;

import "./ZapBaseV1.sol";

contract ZapOutBaseV1 is ZapBaseV1 {
    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract removes liquidity from yEarn Vaults to ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapOutBaseV1.sol";

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);
}

interface IYVaultV1Registry {
    function getVaults() external view returns (address[] memory);

    function getVaultsLength() external view returns (uint256);
}

// -- Aave --
interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

contract yVault_ZapOut_V2 is ZapOutBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider =
        IAaveLendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );

    IYVaultV1Registry V1Registry =
        IYVaultV1Registry(0x3eE41C098f9666ed2eA246f4D2558010e59d63A0);

    event Zapout(
        address _toWhomToIssue,
        address _fromYVaultAddress,
        address _toTokenAddress,
        uint256 _tokensRecieved
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice Zap out in to a single token with permit
    @param fromVault Vault from which to remove liquidity
    @param amountIn Quantity of vault tokens to remove
    @param toToken Address of desired token
    @param isAaveUnderlying True if vault contains aave token
    @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
    @param permitData Encoded permit data, which contains owner, spender, value, deadline, r,s,v values
    @param swapTarget Execution targets for swap or Zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return Quantity of tokens or ETH received
    */
    function ZapOutWithPermit(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        bytes calldata permitData,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external returns (uint256 tokensReceived) {
        // permit
        (bool success, ) = fromVault.call(permitData);
        require(success, "Could Not Permit");

        return
            ZapOut(
                fromVault,
                amountIn,
                toToken,
                isAaveUnderlying,
                minToTokens,
                swapTarget,
                swapData,
                affiliate
            );
    }

    /**
    @notice Zap out in to a single token with permit
    @param fromVault Vault from which to remove liquidity
    @param amountIn Quantity of vault tokens to remove
    @param toToken Address of desired token
    @param isAaveUnderlying True if vault contains aave token
    @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
    @param swapTarget Execution targets for swap or Zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return Quantity of tokens or ETH received
    */
    function ZapOut(
        address fromVault,
        uint256 amountIn,
        address toToken,
        bool isAaveUnderlying,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        IERC20(fromVault).safeTransferFrom(msg.sender, address(this), amountIn);

        // get underlying token from vault
        address underlyingToken = IYVault(fromVault).token();
        uint256 underlyingTokenReceived =
            _vaultWithdraw(fromVault, amountIn, underlyingToken);

        // swap to toToken
        uint256 toTokenAmt;

        if (isAaveUnderlying) {
            address underlyingAsset =
                IAToken(underlyingToken).underlyingAssetAddress();
            // unwrap atoken
            IAToken(underlyingToken).redeem(underlyingTokenReceived);

            // aTokens are 1:1
            if (underlyingAsset == toToken) {
                toTokenAmt = underlyingTokenReceived;
            } else {
                toTokenAmt = _fillQuote(
                    underlyingAsset,
                    toToken,
                    underlyingTokenReceived,
                    swapTarget,
                    swapData
                );
            }
        } else {
            toTokenAmt = _fillQuote(
                underlyingToken,
                toToken,
                underlyingTokenReceived,
                swapTarget,
                swapData
            );
        }
        require(toTokenAmt >= minToTokens, "Err: High Slippage");

        uint256 totalGoodwillPortion =
            _subtractGoodwill(toToken, toTokenAmt, affiliate, true);
        tokensReceived = toTokenAmt.sub(totalGoodwillPortion);

        // send toTokens
        if (toToken == address(0)) {
            Address.sendValue(msg.sender, tokensReceived);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, tokensReceived);
        }
    }

    function _vaultWithdraw(
        address fromVault,
        uint256 amount,
        address underlyingVaultToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingVaultToken);

        IYVault(fromVault).withdraw(amount);

        underlyingReceived = _getBalance(underlyingVaultToken).sub(
            iniUnderlyingBal
        );
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);

        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBal = _getBalance(toToken);

        require(finalBal > 0, "ERR: Swapped to wrong token");

        amtBought = finalBal.sub(iniBal);
    }

    /**
    @notice Utility function to determine the quantity of underlying tokens removed from vault
    @param fromVault Yearn vault from which to remove liquidity
    @param liquidity Quantity of vault tokens to remove
    @return Quantity of underlying LP or token removed
    */
    function removeLiquidityReturn(address fromVault, uint256 liquidity)
        external
        view
        returns (uint256)
    {
        IYVault vault = IYVault(fromVault);

        address[] memory V1Vaults = V1Registry.getVaults();

        for (uint256 i = 0; i < V1Registry.getVaultsLength(); i++) {
            if (V1Vaults[i] == fromVault)
                return
                    (liquidity.mul(vault.getPricePerFullShare())).div(10**18);
        }
        return (liquidity.mul(vault.pricePerShare())).div(10**vault.decimals());
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract pipes (rebalances) liquidity among arbitrary pools/vaults

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;
import "../_base/ZapOutBaseV1.sol";

contract Zapper_Liquidity_Pipe_V1 is ZapOutBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    modifier OnlyAuthorized(address[] memory swapTargets) {
        require(
            (approvedTargets[swapTargets[0]] || swapTargets[0] == address(0)) &&
                ((approvedTargets[swapTargets[1]]) ||
                    swapTargets[1] == address(0)),
            "Target not Authorized"
        );
        _;
    }

    event zapPipe(
        address sender,
        address fromPool,
        address toPool,
        uint256 tokensRec
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @param fromPool Pool/vault token address from which to remove liquidity
    @param IncomingLP Quantity of LP to remove from fromPool
    @param intermediateToken Token to exit fromPool into
    @param toPool Destination pool/vault token address
    @param minPoolTokens Minimum quantity of tokens to receive
    @param swapTargets Execution targets for Zaps
    @param swapData Zap data
    @param affiliate Affiliate address
    */
    function ZapPipe(
        address fromPool,
        uint256 IncomingLP,
        address intermediateToken,
        address toPool,
        uint256 minPoolTokens,
        address[] calldata swapTargets,
        bytes[] calldata swapData,
        address affiliate
    )
        external
        stopInEmergency
        OnlyAuthorized(swapTargets)
        returns (uint256 tokensRec)
    {
        IERC20(fromPool).safeTransferFrom(
            msg.sender,
            address(this),
            IncomingLP
        );

        uint256 intermediateAmt =
            _fillQuote(
                fromPool,
                intermediateToken,
                IncomingLP,
                swapTargets[0],
                swapData[0]
            );

        uint256 goodwill =
            _subtractGoodwill(
                intermediateToken,
                intermediateAmt,
                affiliate,
                true
            );

        tokensRec = _fillQuote(
            intermediateToken,
            toPool,
            intermediateAmt.sub(goodwill),
            swapTargets[1],
            swapData[1]
        );

        require(tokensRec >= minPoolTokens, "ERR: High Slippage");

        emit zapPipe(msg.sender, fromPool, toPool, tokensRec);

        IERC20(toPool).safeTransfer(msg.sender, tokensRec.sub(goodwill));
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 finalBalance) {
        uint256 valueToSend;
        if (fromToken == address(0)) valueToSend = amount;
        else _approveToken(fromToken, swapTarget);

        uint256 initialBalance = _getBalance(toToken);

        (bool success, ) = swapTarget.call.value(valueToSend)(swapData);
        require(success, "Error Swapping Tokens");

        finalBalance = _getBalance(toToken).sub(initialBalance);

        require(finalBalance > 0, "Swapped to Invalid Token");
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract removes liquidity from Pickle Jars to ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapOutBaseV1.sol";

interface IPickleJar {
    function token() external view returns (address);

    function withdraw(uint256 _shares) external;

    function getRatio() external view returns (uint256);
}

contract Pickle_ZapOut_V1 is ZapOutBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    event Zapout(
        address _toWhomToIssue,
        address _fromPJarAddress,
        address _toTokenAddress,
        uint256 _tokensRecieved
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice Zap out in to a single token or ETH
    @param fromJar Pickle Jar from which to remove liquidity
    @param amountIn Quantity of Jar tokens to remove
    @param toToken Address of desired token
    @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
    @param swapTarget Execution targets for swap or Zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return Quantity of tokens or ETH received
    */
    function ZapOut(
        address fromJar,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        IERC20(fromJar).safeTransferFrom(msg.sender, address(this), amountIn);

        // withdraw underlying token from jar
        address underlyingToken = IPickleJar(fromJar).token();
        uint256 underlyingTokenReceived =
            _jarWithdraw(fromJar, amountIn, underlyingToken);

        // swap to toToken
        uint256 toTokenAmt =
            _fillQuote(
                underlyingToken,
                toToken,
                underlyingTokenReceived,
                swapTarget,
                swapData
            );
        require(toTokenAmt >= minToTokens, "Err: High Slippage");

        uint256 totalGoodwillPortion =
            _subtractGoodwill(toToken, toTokenAmt, affiliate, true);
        tokensReceived = toTokenAmt.sub(totalGoodwillPortion);

        // send toTokens
        if (toToken == address(0)) {
            Address.sendValue(msg.sender, tokensReceived);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, tokensReceived);
        }
    }

    function _jarWithdraw(
        address fromJar,
        uint256 amount,
        address underlyingToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingToken);

        IPickleJar(fromJar).withdraw(amount);

        underlyingReceived = _getBalance(underlyingToken).sub(iniUnderlyingBal);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);

        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBal = _getBalance(toToken);

        require(finalBal > 0, "ERR: Swapped to wrong token");

        amtBought = finalBal.sub(iniBal);
    }

    /**
    @notice Utility function to determine the quantity of underlying tokens removed from jar
    @param fromJar Pickle Jar from which to remove liquidity
    @param liquidity Quantity of Jar tokens to remove
    @return Quantity of underlying LP or token removed
    */
    function removeLiquidityReturn(IPickleJar fromJar, uint256 liquidity)
        external
        view
        returns (uint256)
    {
        return (liquidity.mul(fromJar.getRatio())).div(1e18);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

pragma solidity ^0.5.7;

import "./ZapBaseV1.sol";

contract ZapInBaseV2 is ZapBaseV1 {
    function _pullTokens(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill,
        bool shouldSellEntireBalance
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                msg.value,
                affiliate,
                enableGoodwill
            );

            return msg.value.sub(totalGoodwillPortion);
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );
            amount = IERC20(token).allowance(msg.sender, address(this));
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(
            token,
            amount,
            affiliate,
            enableGoodwill
        );

        return amount.sub(totalGoodwillPortion);
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Vesper Vaults using ETH or ERC20 Tokens.

// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapInBaseV2.sol";

interface IVesper {
    function token() external view returns (address);

    function deposit(uint256 amount) external;
}

contract Vesper_ZapIn_V1 is ZapInBaseV2 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice This function adds liquidity to a Vesper vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toVault Vesper vault address
    @param minVaultTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        uint256 minVaultTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        address underlyingVaultToken = IVesper(toVault).token();

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                underlyingVaultToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(
            intermediateAmt,
            toVault,
            minVaultTokens
        );
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IVesper(toVault).token();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IVesper(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Sushiswap pools on Polygon using ETH or any ERC20 Token.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../../_base/ZapInBaseV2.sol";

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract Sushiswap_ZapIn_Polygon_V2 is ZapInBaseV2 {
    // sushiSwap
    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IUniswapV2Factory private constant sushiSwapFactoryAddress =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
    @notice This function is used to invest in given Sushiswap pair through ETH/ERC20 Tokens
    @param fromToken The ERC20 token used for investment (address(0x00) if ether)
    @param pairAddress The Sushiswap pair address
    @param amount The amount of fromToken to invest
    @param minPoolTokens Reverts if less tokens received than this
    @param swapTarget Excecution target for the first swap
    @param allowanceTarget Target to approve for swap
    @param swapData Dex quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
    @return Amount of LP bought
     */
    function ZapIn(
        address fromToken,
        address pairAddress,
        uint256 amount,
        uint256 minPoolTokens,
        address swapTarget,
        address allowanceTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                fromToken,
                pairAddress,
                toInvest,
                swapTarget,
                allowanceTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= minPoolTokens, "ERR: High Slippage");

        emit zapIn(msg.sender, pairAddress, LPBought);

        IERC20(pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(address pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair sushiPair = IUniswapV2Pair(pairAddress);
        token0 = sushiPair.token0();
        token1 = sushiPair.token1();
    }

    function _performZapIn(
        address fromToken,
        address pairAddress,
        uint256 amount,
        address swapTarget,
        address allowanceTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToSushipoolToken0, address _ToSushipoolToken1) =
            _getPairTokens(pairAddress);

        if (
            fromToken != _ToSushipoolToken0 && fromToken != _ToSushipoolToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                fromToken,
                pairAddress,
                amount,
                swapTarget,
                allowanceTarget,
                swapData
            );
        } else {
            intermediateToken = fromToken;
            intermediateAmt = amount;
        }
        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToSushipoolToken0,
                _ToSushipoolToken1,
                intermediateAmt
            );

        return
            _sushiDeposit(
                _ToSushipoolToken0,
                _ToSushipoolToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _sushiDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(sushiSwapRouter), token0Bought);
        _approveToken(_ToUnipoolToken1, address(sushiSwapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            sushiSwapRouter.addLiquidity(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought.sub(amountA) > 0) {
                IERC20(_ToUnipoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought.sub(amountA)
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought.sub(amountB) > 0) {
                IERC20(_ToUnipoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought.sub(amountB)
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address pairAddress,
        uint256 amount,
        address swapTarget,
        address allowanceTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(_fromTokenAddress, allowanceTarget, amount);
        }

        (address _token0, address _token1) = _getPairTokens(pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        (bool success, ) = swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)).sub(initialBalance0);
        uint256 finalBalance1 =
            token1.balanceOf(address(this)).sub(initialBalance1);

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _toContractAddress,
        address _ToSushipoolToken0,
        address _ToSushipoolToken1,
        uint256 amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                sushiSwapFactoryAddress.getPair(
                    _ToSushipoolToken0,
                    _ToSushipoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_toContractAddress == _ToSushipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = amount.div(2);
            token1Bought = _token2Token(
                _toContractAddress,
                _ToSushipoolToken1,
                amountToSwap
            );
            token0Bought = amount.sub(amountToSwap);
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = amount.div(2);
            token0Bought = _token2Token(
                _toContractAddress,
                _ToSushipoolToken0,
                amountToSwap
            );
            token1Bought = amount.sub(amountToSwap);
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param fromToken The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address fromToken,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromToken == _ToTokenContractAddress) {
            return tokens2Trade;
        }
        _approveToken(fromToken, address(sushiSwapRouter), tokens2Trade);

        address pair =
            sushiSwapFactoryAddress.getPair(fromToken, _ToTokenContractAddress);
        require(pair != address(0), "No Swap Available");

        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = _ToTokenContractAddress;

        tokenBought = sushiSwapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Mushroom Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapInBaseV2.sol";

interface IMVault {
    function deposit(uint256) external;

    function token() external view returns (address);
}

contract Mushroom_ZapIn_V1 is ZapInBaseV2 {
    mapping(address => bool) public approvedTargets;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice This function adds liquidity to Mushroom vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toVault Harvest vault address
    @param minMVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering vault
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        uint256 minMVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(intermediateAmt, toVault, minMVTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IMVault(toVault).token();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniVaultBal = IERC20(toVault).balanceOf(address(this));
        IMVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits ETH or ERC20 tokens into Harvest Vaults
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapInBaseV2.sol";

// -- Harvest --
interface IHVault {
    function underlying() external view returns (address);

    function deposit(uint256 amountWei) external;
}

contract Harvest_ZapIn_V2_0_1 is ZapInBaseV2 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice This function adds liquidity to harvest vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param vault Harvest vault address
    @param minVaultTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering vault
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address vault,
        uint256 minVaultTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest =
            _pullTokens(
                fromToken,
                amountIn,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(intermediateAmt, vault, minVaultTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IHVault(toVault).underlying();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IHVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

pragma solidity ^0.5.7;

import "./ZapBaseV1.sol";

contract ZapInBaseV1 is ZapBaseV1 {
    function _pullTokens(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                msg.value,
                affiliate,
                enableGoodwill
            );

            return msg.value.sub(totalGoodwillPortion);
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(
            token,
            amount,
            affiliate,
            enableGoodwill
        );

        return amount.sub(totalGoodwillPortion);
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = ETHAddress;
                }

                uint256 affiliatePortion =
                    totalGoodwillPortion.mul(affiliateSplit).div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[
                    affiliate
                ][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Yearn Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapInBaseV1.sol";

interface IYVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    // V2
    function pricePerShare() external view returns (uint256);
}

// -- Aave --
interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAaveLendingPoolCore {
    function getReserveATokenAddress(address _reserve)
        external
        view
        returns (address);
}

interface IAaveLendingPool {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;
}

contract yVault_ZapIn_V3 is ZapInBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider =
        IAaveLendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(
        address _curveZapIn,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) public ZapBaseV1(_goodwill, _affiliateSplit) {}

    /**
    @notice This function adds liquidity to a Yearn vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toVault Yearn vault address
    @param superVault Super vault to depoist toVault tokens into (address(0) if none)
    @param isAaveUnderlying True if vault contains aave token
    @param minYVTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering vault
    @param swapTarget Excecution target for the swap or Zap
    @param swapData DEX quote or Zap data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toVault,
        address superVault,
        bool isAaveUnderlying,
        uint256 minYVTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // get 'aIntermediateToken'
        if (isAaveUnderlying) {
            address aaveLendingPoolCore =
                lendingPoolAddressProvider.getLendingPoolCore();
            _approveToken(intermediateToken, aaveLendingPoolCore);

            IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                .deposit(intermediateToken, intermediateAmt, 0);

            intermediateToken = IAaveLendingPoolCore(aaveLendingPoolCore)
                .getReserveATokenAddress(intermediateToken);
        }

        return
            _zapIn(
                toVault,
                superVault,
                minYVTokens,
                intermediateToken,
                intermediateAmt
            );
    }

    function _zapIn(
        address toVault,
        address superVault,
        uint256 minYVTokens,
        address intermediateToken,
        uint256 intermediateAmt
    ) internal returns (uint256 tokensReceived) {
        // Deposit to Vault
        if (superVault == address(0)) {
            tokensReceived = _vaultDeposit(
                intermediateToken,
                intermediateAmt,
                toVault,
                minYVTokens,
                true
            );
        } else {
            uint256 intermediateYVTokens =
                _vaultDeposit(
                    intermediateToken,
                    intermediateAmt,
                    toVault,
                    0,
                    false
                );
            // deposit to super vault
            tokensReceived = _vaultDeposit(
                IYVault(superVault).token(),
                intermediateYVTokens,
                superVault,
                minYVTokens,
                true
            );
        }
    }

    function _vaultDeposit(
        address underlyingVaultToken,
        uint256 amount,
        address toVault,
        uint256 minTokensRec,
        bool shouldTransfer
    ) internal returns (uint256 tokensReceived) {
        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IYVault(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        if (shouldTransfer) {
            IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
            emit zapIn(msg.sender, toVault, tokensReceived);
        }
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 Zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to QuickSwap pools using any arbitrary token
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapInBaseV1.sol";

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

contract QuickSwap_ZapIn_V1 is ZapInBaseV1 {
    IUniswapV2Router02 private constant quickswapRouter =
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    IUniswapV2Factory private constant quickswapFactory =
        IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);

    address private constant wmaticTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice Adds liquidity to QuickSwap Pools with any token
    @param fromTokenAddress ERC20 token address used for investment (address(0x00) if MATIC)
    @param pairAddress QuickSwap pair address
    @param amount Quantity of fromTokenAddress to invest
    @param minPoolTokens Minimum acceptable quantity of LP tokens to receive.
    @param affiliate Affiliate address
    @return Quantity of LP bought
     */
    function ZapIn(
        address fromTokenAddress,
        address pairAddress,
        uint256 amount,
        uint256 minPoolTokens,
        address affiliate
    ) public payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(fromTokenAddress, amount, affiliate, true);

        uint256 LPBought =
            _performZapIn(fromTokenAddress, pairAddress, toInvest);

        require(LPBought >= minPoolTokens, "ERR: High Slippage");

        emit zapIn(msg.sender, pairAddress, LPBought);

        IERC20(pairAddress).safeTransfer(msg.sender, LPBought);

        return LPBought;
    }

    function _getPairTokens(address pairAddress)
        internal
        pure
        returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performZapIn(
        address fromTokenAddress,
        address pairAddress,
        uint256 amount
    ) internal returns (uint256) {
        (address _token0, address _token1) = _getPairTokens(pairAddress);
        address intermediate =
            _getIntermediate(fromTokenAddress, amount, _token0, _token1);

        // swap to intermediate
        uint256 interAmt = _token2Token(fromTokenAddress, intermediate, amount);

        // divide to swap in amounts
        uint256 token0Bought;
        uint256 token1Bought;

        IUniswapV2Pair pair =
            IUniswapV2Pair(quickswapFactory.getPair(_token0, _token1));
        (uint256 res0, uint256 res1, ) = pair.getReserves();

        if (intermediate == _token0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, interAmt);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = interAmt.div(2);
            token1Bought = _token2Token(intermediate, _token1, amountToSwap);
            token0Bought = interAmt.sub(amountToSwap);
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, interAmt);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = interAmt.div(2);
            token0Bought = _token2Token(intermediate, _token0, amountToSwap);
            token1Bought = interAmt.sub(amountToSwap);
        }

        return _quickDeposit(_token0, _token1, token0Bought, token1Bought);
    }

    function _quickDeposit(
        address _token0,
        address _token1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        IERC20(_token0).safeApprove(address(quickswapRouter), token0Bought);
        IERC20(_token1).safeApprove(address(quickswapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            quickswapRouter.addLiquidity(
                _token0,
                _token1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        IERC20(_token0).safeApprove(address(quickswapRouter), 0);
        IERC20(_token1).safeApprove(address(quickswapRouter), 0);

        //Returning Residue in token0, if any.
        if (token0Bought.sub(amountA) > 0) {
            IERC20(_token0).safeTransfer(msg.sender, token0Bought.sub(amountA));
        }

        //Returning Residue in token1, if any
        if (token1Bought.sub(amountB) > 0) {
            IERC20(_token1).safeTransfer(msg.sender, token1Bought.sub(amountB));
        }

        return LP;
    }

    function _getIntermediate(
        address fromTokenAddress,
        uint256 amount,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1
    ) internal view returns (address) {
        // set from to wmatic for matic input
        if (fromTokenAddress == address(0)) {
            fromTokenAddress = wmaticTokenAddress;
        }

        if (fromTokenAddress == _ToUnipoolToken0) {
            return _ToUnipoolToken0;
        } else if (fromTokenAddress == _ToUnipoolToken1) {
            return _ToUnipoolToken1;
        } else if (
            _ToUnipoolToken0 == wmaticTokenAddress ||
            _ToUnipoolToken1 == wmaticTokenAddress
        ) {
            return wmaticTokenAddress;
        } else {
            IUniswapV2Pair pair =
                IUniswapV2Pair(
                    quickswapFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
                );
            (uint256 res0, uint256 res1, ) = pair.getReserves();

            uint256 ratio;
            bool isToken0Numerator;
            if (res0 >= res1) {
                ratio = res0 / res1;
                isToken0Numerator = true;
            } else {
                ratio = res1 / res0;
            }

            //find outputs on swap
            uint256 output0 =
                _calculateSwapOutput(
                    fromTokenAddress,
                    amount,
                    _ToUnipoolToken0
                );
            uint256 output1 =
                _calculateSwapOutput(
                    fromTokenAddress,
                    amount,
                    _ToUnipoolToken1
                );

            if (isToken0Numerator) {
                if (output1 * ratio >= output0) return _ToUnipoolToken1;
                else return _ToUnipoolToken0;
            } else {
                if (output0 * ratio >= output1) return _ToUnipoolToken0;
                else return _ToUnipoolToken1;
            }
        }
    }

    function _calculateSwapOutput(
        address _from,
        uint256 _amt,
        address _to
    ) internal view returns (uint256) {
        // check output via tokenA -> tokenB
        address pairA = quickswapFactory.getPair(_from, _to);

        uint256 amtA;
        if (pairA != address(0)) {
            address[] memory pathA = new address[](2);
            pathA[0] = _from;
            pathA[1] = _to;

            amtA = quickswapRouter.getAmountsOut(_amt, pathA)[1];
        }

        uint256 amtB;
        // check output via tokenA -> wmatic -> tokenB
        if ((_from != wmaticTokenAddress) && _to != wmaticTokenAddress) {
            address[] memory pathB = new address[](3);
            pathB[0] = _from;
            pathB[1] = wmaticTokenAddress;
            pathB[2] = _to;

            amtB = quickswapRouter.getAmountsOut(_amt, pathB)[2];
        }

        if (amtA >= amtB) {
            return amtA;
        } else {
            return amtB;
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    /**
    @notice This function is used to swap ETH/ERC20 <> ETH/ERC20
    @param fromTokenAddress The token address to swap from. (0x00 for ETH)
    @param _ToTokenContractAddress The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address fromTokenAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromTokenAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        if (fromTokenAddress == address(0)) {
            if (_ToTokenContractAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).deposit.value(tokens2Trade)();
                return tokens2Trade;
            }

            address[] memory path = new address[](2);
            path[0] = wmaticTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = quickswapRouter.swapExactETHForTokens.value(
                tokens2Trade
            )(1, path, address(this), deadline)[path.length - 1];
        } else if (_ToTokenContractAddress == address(0)) {
            if (fromTokenAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).withdraw(tokens2Trade);
                return tokens2Trade;
            }

            IERC20(fromTokenAddress).safeApprove(
                address(quickswapRouter),
                tokens2Trade
            );

            address[] memory path = new address[](2);
            path[0] = fromTokenAddress;
            path[1] = wmaticTokenAddress;
            tokenBought = quickswapRouter.swapExactTokensForETH(
                tokens2Trade,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        } else {
            IERC20(fromTokenAddress).safeApprove(
                address(quickswapRouter),
                tokens2Trade
            );

            if (fromTokenAddress != wmaticTokenAddress) {
                if (_ToTokenContractAddress != wmaticTokenAddress) {
                    // check output via tokenA -> tokenB
                    address pairA =
                        quickswapFactory.getPair(
                            fromTokenAddress,
                            _ToTokenContractAddress
                        );
                    address[] memory pathA = new address[](2);
                    pathA[0] = fromTokenAddress;
                    pathA[1] = _ToTokenContractAddress;
                    uint256 amtA;
                    if (pairA != address(0)) {
                        amtA = quickswapRouter.getAmountsOut(
                            tokens2Trade,
                            pathA
                        )[1];
                    }

                    // check output via tokenA -> wmatic -> tokenB
                    address[] memory pathB = new address[](3);
                    pathB[0] = fromTokenAddress;
                    pathB[1] = wmaticTokenAddress;
                    pathB[2] = _ToTokenContractAddress;

                    uint256 amtB =
                        quickswapRouter.getAmountsOut(tokens2Trade, pathB)[2];

                    if (amtA >= amtB) {
                        tokenBought = quickswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathA,
                            address(this),
                            deadline
                        )[pathA.length - 1];
                    } else {
                        tokenBought = quickswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathB,
                            address(this),
                            deadline
                        )[pathB.length - 1];
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = fromTokenAddress;
                    path[1] = wmaticTokenAddress;

                    tokenBought = quickswapRouter.swapExactTokensForTokens(
                        tokens2Trade,
                        1,
                        path,
                        address(this),
                        deadline
                    )[path.length - 1];
                }
            } else {
                address[] memory path = new address[](2);
                path[0] = wmaticTokenAddress;
                path[1] = _ToTokenContractAddress;
                tokenBought = quickswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            }
        }
        require(tokenBought > 0, "Error Swapping Tokens");
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits to Pickle Jars with ETH or ERC tokens
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "../_base/ZapInBaseV1.sol";

interface IPickleJar {
    function token() external view returns (address);

    function deposit(uint256 amount) external;
}

contract Pickle_ZapIn_V1 is ZapInBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    event zapIn(address sender, address pool, uint256 tokensRec);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice This function adds liquidity to a Pickle vaults with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param toPJar Pickle vault address
    @param minPJarTokens The minimum acceptable quantity vault tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering vault
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensReceived- Quantity of Vault tokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address toPJar,
        uint256 minPJarTokens,
        address intermediateToken,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        // get incoming tokens
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        // get intermediate token
        uint256 intermediateAmt =
            _fillQuote(
                fromToken,
                intermediateToken,
                toInvest,
                swapTarget,
                swapData
            );

        // Deposit to Vault
        tokensReceived = _vaultDeposit(intermediateAmt, toPJar, minPJarTokens);
    }

    function _vaultDeposit(
        uint256 amount,
        address toVault,
        uint256 minTokensRec
    ) internal returns (uint256 tokensReceived) {
        address underlyingVaultToken = IPickleJar(toVault).token();

        _approveToken(underlyingVaultToken, toVault);

        uint256 iniYVaultBal = IERC20(toVault).balanceOf(address(this));
        IPickleJar(toVault).deposit(amount);
        tokensReceived = IERC20(toVault).balanceOf(address(this)).sub(
            iniYVaultBal
        );
        require(tokensReceived >= minTokensRec, "Err: High Slippage");

        IERC20(toVault).safeTransfer(msg.sender, tokensReceived);
        emit zapIn(msg.sender, toVault, tokensReceived);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget);
        }

        uint256 iniBal = _getBalance(toToken);
        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = _getBalance(toToken);

        amtBought = finalBal.sub(iniBal);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}

pragma solidity ^0.5.7;

import "../_base/ZapInBaseV1.sol";

contract MockZapIn is ZapInBaseV1 {
    constructor(uint256 goodwill, uint256 affiliateSplit)
        public
        ZapBaseV1(goodwill, affiliateSplit)
    {}

    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address affiliate
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        if (fromToken == address(0)) {
            msg.sender.transfer(toInvest);
        } else {
            IERC20(fromToken).safeTransfer(address(0), toInvest);
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract swaps and bridges Matic Tokens to Ethereum mainnet
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;

import "../_base/ZapInBaseV1.sol";

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IChildToken {
    function withdraw(uint256 amount) external;
}

contract Zapper_ETH_Bridge_V1 is ZapInBaseV1 {
    IUniswapV2Factory private constant quickswapFactory =
        IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    IUniswapV2Router02 private constant quickswapRouter =
        IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    IUniswapV2Factory private constant sushiswapFactory =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
    IUniswapV2Router02 private constant sushiswapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address private constant wmaticTokenAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    function ZapBridge(
        address fromToken,
        uint256 amountIn,
        address toToken,
        bool useSushi,
        address affiliate
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        uint256 toTokenAmt;
        if (useSushi) {
            toTokenAmt = _token2TokenSushi(fromToken, toToken, toInvest);
        } else {
            toTokenAmt = _token2TokenQuick(fromToken, toToken, toInvest);
        }

        IChildToken(toToken).withdraw(toTokenAmt);
    }

    /**
    @notice This function is used to swap MATIC/ERC20 <> MATIC/ERC20 via Quickswap
    @param fromTokenAddress The token address to swap from. (0x00 for ETH)
    @param _ToTokenContractAddress The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2TokenQuick(
        address fromTokenAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromTokenAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        if (fromTokenAddress == address(0)) {
            if (_ToTokenContractAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).deposit.value(tokens2Trade)();
                return tokens2Trade;
            }

            address[] memory path = new address[](2);
            path[0] = wmaticTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = quickswapRouter.swapExactETHForTokens.value(
                tokens2Trade
            )(1, path, address(this), deadline)[path.length - 1];
        } else if (_ToTokenContractAddress == address(0)) {
            if (fromTokenAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).withdraw(tokens2Trade);
                return tokens2Trade;
            }

            IERC20(fromTokenAddress).safeApprove(
                address(quickswapRouter),
                tokens2Trade
            );

            address[] memory path = new address[](2);
            path[0] = fromTokenAddress;
            path[1] = wmaticTokenAddress;
            tokenBought = quickswapRouter.swapExactTokensForETH(
                tokens2Trade,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        } else {
            IERC20(fromTokenAddress).safeApprove(
                address(quickswapRouter),
                tokens2Trade
            );

            if (fromTokenAddress != wmaticTokenAddress) {
                if (_ToTokenContractAddress != wmaticTokenAddress) {
                    // check output via tokenA -> tokenB
                    address pairA =
                        quickswapFactory.getPair(
                            fromTokenAddress,
                            _ToTokenContractAddress
                        );
                    address[] memory pathA = new address[](2);
                    pathA[0] = fromTokenAddress;
                    pathA[1] = _ToTokenContractAddress;
                    uint256 amtA;
                    if (pairA != address(0)) {
                        amtA = quickswapRouter.getAmountsOut(
                            tokens2Trade,
                            pathA
                        )[1];
                    }

                    // check output via tokenA -> wmatic -> tokenB
                    address[] memory pathB = new address[](3);
                    pathB[0] = fromTokenAddress;
                    pathB[1] = wmaticTokenAddress;
                    pathB[2] = _ToTokenContractAddress;

                    uint256 amtB =
                        quickswapRouter.getAmountsOut(tokens2Trade, pathB)[2];

                    if (amtA >= amtB) {
                        tokenBought = quickswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathA,
                            address(this),
                            deadline
                        )[pathA.length - 1];
                    } else {
                        tokenBought = quickswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathB,
                            address(this),
                            deadline
                        )[pathB.length - 1];
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = fromTokenAddress;
                    path[1] = wmaticTokenAddress;

                    tokenBought = quickswapRouter.swapExactTokensForTokens(
                        tokens2Trade,
                        1,
                        path,
                        address(this),
                        deadline
                    )[path.length - 1];
                }
            } else {
                address[] memory path = new address[](2);
                path[0] = wmaticTokenAddress;
                path[1] = _ToTokenContractAddress;
                tokenBought = quickswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            }
        }
        require(tokenBought > 0, "Error Swapping Tokens");
    }

    /**
    @notice This function is used to swap MATIC/ERC20 <> MATIC/ERC20 via Sushiswap
    @param fromTokenAddress The token address to swap from. (0x00 for ETH)
    @param _ToTokenContractAddress The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2TokenSushi(
        address fromTokenAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromTokenAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        if (fromTokenAddress == address(0)) {
            if (_ToTokenContractAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).deposit.value(tokens2Trade)();
                return tokens2Trade;
            }

            address[] memory path = new address[](2);
            path[0] = wmaticTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = sushiswapRouter.swapExactETHForTokens.value(
                tokens2Trade
            )(1, path, address(this), deadline)[path.length - 1];
        } else if (_ToTokenContractAddress == address(0)) {
            if (fromTokenAddress == wmaticTokenAddress) {
                IWETH(wmaticTokenAddress).withdraw(tokens2Trade);
                return tokens2Trade;
            }

            IERC20(fromTokenAddress).safeApprove(
                address(sushiswapRouter),
                tokens2Trade
            );

            address[] memory path = new address[](2);
            path[0] = fromTokenAddress;
            path[1] = wmaticTokenAddress;
            tokenBought = sushiswapRouter.swapExactTokensForETH(
                tokens2Trade,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        } else {
            IERC20(fromTokenAddress).safeApprove(
                address(sushiswapRouter),
                tokens2Trade
            );

            if (fromTokenAddress != wmaticTokenAddress) {
                if (_ToTokenContractAddress != wmaticTokenAddress) {
                    // check output via tokenA -> tokenB
                    address pairA =
                        sushiswapFactory.getPair(
                            fromTokenAddress,
                            _ToTokenContractAddress
                        );
                    address[] memory pathA = new address[](2);
                    pathA[0] = fromTokenAddress;
                    pathA[1] = _ToTokenContractAddress;
                    uint256 amtA;
                    if (pairA != address(0)) {
                        amtA = sushiswapRouter.getAmountsOut(
                            tokens2Trade,
                            pathA
                        )[1];
                    }

                    // check output via tokenA -> wmatic -> tokenB
                    address[] memory pathB = new address[](3);
                    pathB[0] = fromTokenAddress;
                    pathB[1] = wmaticTokenAddress;
                    pathB[2] = _ToTokenContractAddress;

                    uint256 amtB =
                        sushiswapRouter.getAmountsOut(tokens2Trade, pathB)[2];

                    if (amtA >= amtB) {
                        tokenBought = sushiswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathA,
                            address(this),
                            deadline
                        )[pathA.length - 1];
                    } else {
                        tokenBought = sushiswapRouter.swapExactTokensForTokens(
                            tokens2Trade,
                            1,
                            pathB,
                            address(this),
                            deadline
                        )[pathB.length - 1];
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = fromTokenAddress;
                    path[1] = wmaticTokenAddress;

                    tokenBought = sushiswapRouter.swapExactTokensForTokens(
                        tokens2Trade,
                        1,
                        path,
                        address(this),
                        deadline
                    )[path.length - 1];
                }
            } else {
                address[] memory path = new address[](2);
                path[0] = wmaticTokenAddress;
                path[1] = _ToTokenContractAddress;
                tokenBought = sushiswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            }
        }
        require(tokenBought > 0, "Error Swapping Tokens");
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}