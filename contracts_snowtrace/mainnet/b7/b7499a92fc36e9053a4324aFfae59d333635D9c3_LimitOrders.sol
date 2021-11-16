// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0

/**
 *Submitted for verification at Etherscan.io on 2020-08-31
 */

/**
 *Submitted for verification at Etherscan.io on 2020-08-30
 */

// File: contracts/interfaces/IERC20.sol

//
// Original work by Pine.Finance
//  - https://github.com/pine-finance
//
// Authors:
//  - Ignacio Mazzara <@nachomazzara>
//  - Agustin Aguilar <@agusx1211>

//
//
//                                                /
//                                                @,
//                                               /&&
//                                              &&%%&/
//                                            &%%%%&%%,..
//                                         */%&,*&&&&&&%%&*
//                                           /&%%%%%%%#.
//                                    ./%&%%%&#/%%%%&#&%%%&#(*.
//                                         .%%%%%%%&&%&/ ..,...
//                                       .*,%%%%%%%%%&&%%%%(
//                                     ,&&%%%&&*%%%%%%%%.*(#%&/
//                                  ./,(*,*,#%%%%%%%%%%%%%%%(,
//                                 ,(%%%%%%%%%%%%&%%%%%%%%%#&&%%%#/(*
//                                     *#%%%%%%%&%%%&%%#%%%%%%(
//                              .(####%%&%&#*&%%##%%%%%%%%%%%#.,,
//                                      ,&%%%%%###%%%%%%%%%%%%#&&.
//                             ..,(&%%%%%%%%%%%%%%%%%%&&%%%%#%&&%&%%%%&&#,
//                           ,##//%((#*/#%%%%%%%%%%%%%%%%%%%%%&(.
//                                  (%%%%%%%%%%%%%%%%%%%#%%%%%%%%%&&&&#(*,
//                                   ./%%%%&%%%%#%&%%%%%%##%%&&&&%%(*,
//                                #%%%%%%&&%%%#%%%%%%%%%%%%%%%&#,*&&#.
//                            /%##%(%&/ #%%%%%%%%%%%%%%%%%%%%%%%%%&%%%.
//                                 *&%%%%&%%%%%%%%#%%%%%%%%%%%%%%%%%&%%%#%#%%,
//                        .*(#&%%%%%%%%&&%%%%%%%%%%#%%%%%%%%%%%%%%%(,
//                    ./#%%%%%%%%%%%%%%%%%%%%%%%#%&%#%%%%%%%%%%%%%%%%%%%%&%%%#####(.
//                          .,,*#%%%%%%%%%%%%%##%%&&%#%%%%%%%%&&%%%%%%(&*#&**/(*
//                        .,(&%%%%%#((%%%%%%#%%%%%%%%%#%%%%%%%&&&&&%%%%&%*
//                         ,,,,,..*&%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%#/*.
//                           ,#&%%%%%%%%%%%%%%%%%%%%%%%%&%%%%%%%%%%%%%%%%%%/,
//           .     .,*(#%%%%%%%%%&&&&%%%%%%&&&%%%%%%%%%&&%##%%%%%#,(%%%%%%%%%%%(((*
//             ,/((%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%%%%%&#  . . ...
//                      .,.,,**(%%%%%%%%&%##%%%%%%%%%%%%%%%%%%###%%%%%%%%%&*
//                       ,%&%%%%%&&%%%%%%%#%%%%%%%%%%%%%%%%%%&%%%%##%%%%%%%%%%%%%%%%&&#.
//              .(&&&%%%%%%&#&&%&%%%%%%%##%%%%&&%%%#%%%%%%&%%%%%%&&%%%%&&&/*(,(#(,,.
//                         ..&%%%%%%#%#%%%%%%%%%%%##%%%%%%%&%%%%%%%%%%%%%%%%&&(.
//                      ,%%%%%%%%%##%%%&%%%%%%%%&%%#%%&&%%%%&%%%%%%&%%%%%&(#%%%#,
//              ./%&%%%%%%%%%%%%%%%%%%%%%%%%%&&&%%%##%%%%%%%%%%%%%&&&%%%%%%%%&#.//*/,..
//      ,#%%%%%%%%%%%%%%%%%%&&%%%%%&&&&%%%%%&&&%%%%%#%%%%#%%%%%%%%%%%%%%%%%%%%%%%%%%&&(,..
//            ,#* ,&&&%,.,*(%%%%%%%%%&%%%%&&&%%%%%&%%%%#%%%%##%%%%%%%&&%%%%%%%%%%%#%%%%%%%%&%(*.
//          .,,/((#%&%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&%#%%%%%%%%%%%%%%%%%#%%%%%%%((*
// *,//**,...,/#%%%%%%%%%%%&&&&%%%%%%%%%%%%%#%%%%%%&&&%%%%&&&&%%%#%%#%%%%%%%%%%%%%%%#*.       .,(#%&@*
//  .*%%(*(%%%%%%%%%%&&&&&&&&%%%%%%%&&%%%%%%%%%%%%%&&&%%%%%%%%%##%%%%%%%%%%%%%%%%%%%%%%%%%%%&%%%/..
//      .,/%&%%%%%%@#(&%&%%%%%%%%%#&&%%##%#%%%#%%%%&&&%%%%%%%%###%%%%%&&&%%%%%%%%%%%%%%%%&(//%%/
//          ,..     .(%%%%##%%%#%%%%%%#%%%%%##%%%%%&&&&%%%%%%%#&%#%%%%%%&&&%%%%%##//  ,,.
//            .,(%#%%##%%%#%%%#%%%#%%*,.*%%%%%%%%%&.,/&%%%%%%% #&%%#%%%%%&%(&%((%&&&(*
//                        ,/#/(%%,    ,&%%#%/.//         %*&(%#    .(,(%%%.

pragma solidity 0.8.7;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/interfaces/IModule.sol

interface IModule {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Executes an order
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bought - amount of output token bought
     */
    function execute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _auxData
    ) external returns (uint256 bought);

    /**
     * @notice Check whether an order can be executed or not
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bool - whether the order can be executed or not
     */
    function canExecute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        bytes calldata _data,
        bytes calldata _auxData
    ) external view returns (bool);
}

// File: contracts/interfaces/IHandler.sol

interface IHandler {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bought - Amount of output token bought
     */
    function handle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external payable returns (uint256 bought);

    /**
     * @notice Check whether can handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     */
    function canHandle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external view returns (bool);
}

// File: contracts/commons/Order.sol

contract Order {
    address public constant ETH_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
}

// File: contracts/libs/SafeMath.sol

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
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

// File: contracts/libs/SafeERC20.sol

library SafeERC20 {
    function transfer(
        IERC20 _token,
        address _to,
        uint256 _val
    ) internal returns (bool) {
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.transfer.selector, _to, _val)
        );
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}

// File: contracts/libs/PineUtils.sol

library PineUtils {
    address internal constant ETH_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    /**
     * @notice Get the account's balance of token or ETH
     * @param _token - Address of the token
     * @param _addr - Address of the account
     * @return uint256 - Account's balance of token or ETH
     */
    function balanceOf(IERC20 _token, address _addr)
        internal
        view
        returns (uint256)
    {
        if (ETH_ADDRESS == address(_token)) {
            return _addr.balance;
        }

        return _token.balanceOf(_addr);
    }

    /**
     * @notice Transfer token or ETH to a destinatary
     * @param _token - Address of the token
     * @param _to - Address of the recipient
     * @param _val - Uint256 of the amount to transfer
     * @return bool - Whether the transfer was success or not
     */
    function transfer(
        IERC20 _token,
        address _to,
        uint256 _val
    ) internal returns (bool) {
        if (ETH_ADDRESS == address(_token)) {
            (bool success, ) = _to.call{value: _val}("");
            return success;
        }

        return SafeERC20.transfer(_token, _to, _val);
    }
}

// File: contracts/modules/LimitOrders.sol

/*
 * Original work by Pine.Finance
 * - https://github.com/pine-finance
 *
 * Authors:
 * - Agustin Aguilar <agusx1211>
 * - Ignacio Mazzara <nachomazzara>
 */
contract LimitOrders is IModule, Order, ReentrancyGuard {
    using SafeMath for uint256;

    /// @notice receive ETH
    receive() external payable override {}

    /**
     * @notice Executes an order
     * @param _inputToken - Address of the input token
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bought - amount of output token bought
     */
    function execute(
        IERC20 _inputToken,
        uint256,
        address payable _owner,
        bytes calldata _data,
        bytes calldata _auxData
    ) external override nonReentrant returns (uint256 bought) {
        (IERC20 outputToken, uint256 minReturn) = abi.decode(
            _data,
            (IERC20, uint256)
        );

        IHandler handler = abi.decode(_auxData, (IHandler));

        // Do not trust on _inputToken, it can mismatch the real balance
        uint256 inputAmount = PineUtils.balanceOf(_inputToken, address(this));
        _transferAmount(_inputToken, payable(address(handler)), inputAmount);

        handler.handle(
            _inputToken,
            outputToken,
            inputAmount,
            minReturn,
            _auxData
        );

        bought = PineUtils.balanceOf(outputToken, address(this));
        require(
            bought >= minReturn,
            "LimitOrders#execute: ISSUFICIENT_BOUGHT_TOKENS"
        );

        _transferAmount(outputToken, _owner, bought);

        return bought;
    }

    /**
     * @notice Check whether an order can be executed or not
     * @param _inputToken - Address of the input token
     * @param _inputAmount - uint256 of the input token amount (order amount)
     * @param _data - Bytes of the order's data
     * @param _auxData - Bytes of the auxiliar data used for the handlers to execute the order
     * @return bool - whether the order can be executed or not
     */
    function canExecute(
        IERC20 _inputToken,
        uint256 _inputAmount,
        bytes calldata _data,
        bytes calldata _auxData
    ) external view override returns (bool) {
        (IERC20 outputToken, uint256 minReturn) = abi.decode(
            _data,
            (IERC20, uint256)
        );
        IHandler handler = abi.decode(_auxData, (IHandler));

        return
            handler.canHandle(
                _inputToken,
                outputToken,
                _inputAmount,
                minReturn,
                _auxData
            );
    }

    /**
     * @notice Transfer token or Ether amount to a recipient
     * @param _token - Address of the token
     * @param _to - Address of the recipient
     * @param _amount - uint256 of the amount to be transferred
     */
    function _transferAmount(
        IERC20 _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            (bool success, ) = _to.call{value: _amount}("");
            require(
                success,
                "LimitOrders#_transferAmount: ETH_TRANSFER_FAILED"
            );
        } else {
            require(
                SafeERC20.transfer(_token, _to, _amount),
                "LimitOrders#_transferAmount: TOKEN_TRANSFER_FAILED"
            );
        }
    }
}