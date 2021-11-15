// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.0;

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAToken is IERC20 {
    // solhint-disable-next-line func-name-mixedcase
    function UNDERLYING_ASSET_ADDRESS() external returns (address);
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInterestImplementation {
    function isInterestSupported(address _token) external view returns (bool);

    function invest(address _token, uint256 _amount) external;

    function withdraw(address _token, uint256 _amount) external;

    function investedAmount(address _token) external view returns (uint256);
}

pragma solidity 0.7.5;

interface IInterestReceiver {
    function onInterestReceived(address _token) external;
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external returns (uint256);

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);
}

pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "./OwnableModule.sol";

/**
 * @title MediatorOwnableModule
 * @dev Common functionality for non-upgradeable Omnibridge extension module.
 */
contract MediatorOwnableModule is OwnableModule {
    address public mediator;

    /**
     * @dev Initializes this contract.
     * @param _mediator address of the deployed Omnibridge extension for which this module is deployed.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _mediator, address _owner) OwnableModule(_owner) {
        require(Address.isContract(_mediator));
        mediator = _mediator;
    }

    /**
     * @dev Throws if sender is not the Omnibridge extension.
     */
    modifier onlyMediator {
        require(msg.sender == mediator);
        _;
    }
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../interfaces/IAToken.sol";
import "../../../interfaces/IOwnable.sol";
import "../../../interfaces/IInterestReceiver.sol";
import "../../../interfaces/IInterestImplementation.sol";
import "../../../interfaces/ILendingPool.sol";
import "../MediatorOwnableModule.sol";

/**
 * @title AAVEInterestERC20
 * @dev This contract contains token-specific logic for investing ERC20 tokens into AAVE protocol.
 */
contract AAVEInterestERC20 is IInterestImplementation, MediatorOwnableModule {
    using SafeMath for uint256;

    event PaidInterest(address indexed token, address to, uint256 value);

    struct InterestParams {
        IAToken aToken;
        uint96 dust;
        uint256 investedAmount;
        address interestReceiver;
        uint256 minInterestPaid;
    }

    mapping(address => InterestParams) public interestParams;

    constructor(address _omnibridge, address _owner) MediatorOwnableModule(_omnibridge, _owner) {}

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Tells the address of the LendingPool contract in the Ethereum Mainnet.
     */
    function lendingPool() public pure virtual returns (ILendingPool) {
        return ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    }

    /**
     * @dev Enables support for interest earning through specific aToken.
     * @param _aToken address of the aToken contract. Underlying token address is derived from this contract.
     * @param _dust small amount of underlying tokens that cannot be paid as an interest. Accounts for possible truncation errors.
     * @param _interestReceiver address of the interest receiver for underlying token and associated COMP tokens.
     * @param _minInterestPaid min amount of underlying tokens to be paid as an interest.
     */
    function enableInterestToken(
        IAToken _aToken,
        uint96 _dust,
        address _interestReceiver,
        uint256 _minInterestPaid
    ) external onlyOwner {
        address token = _aToken.UNDERLYING_ASSET_ADDRESS();
        // disallow reinitialization of tokens that were already initialized and invested
        require(interestParams[token].investedAmount == 0);

        interestParams[token] = InterestParams(_aToken, _dust, 0, _interestReceiver, _minInterestPaid);

        IERC20(token).approve(address(lendingPool()), uint256(-1));
    }

    /**
     * @dev Tells the current amount of underlying tokens that was invested into the Compound protocol.
     * @param _token address of the underlying token.
     * @return currently invested value.
     */
    function investedAmount(address _token) external view override returns (uint256) {
        return interestParams[_token].investedAmount;
    }

    /**
     * @dev Tells if interest earning is supported for the specific underlying token contract.
     * @param _token address of the token contract.
     * @return true, if interest earning is supported for the given token.
     */
    function isInterestSupported(address _token) external view override returns (bool) {
        return address(interestParams[_token].aToken) != address(0);
    }

    /**
     * @dev Invests the given amount of tokens to the AAVE protocol.
     * Only Omnibridge contract is allowed to call this method.
     * Converts _amount of TOKENs into aTOKENs.
     * @param _token address of the invested token contract.
     * @param _amount amount of tokens to invest.
     */
    function invest(address _token, uint256 _amount) external override onlyMediator {
        InterestParams storage params = interestParams[_token];
        params.investedAmount = params.investedAmount.add(_amount);
        lendingPool().deposit(_token, _amount, address(this), 0);
    }

    /**
     * @dev Withdraws at least the given amount of tokens from the AAVE protocol.
     * Only Omnibridge contract is allowed to call this method.
     * Converts aTOKENs into _amount of TOKENs.
     * @param _token address of the invested token contract.
     * @param _amount minimal amount of tokens to withdraw.
     */
    function withdraw(address _token, uint256 _amount) external override onlyMediator {
        InterestParams storage params = interestParams[_token];
        uint256 invested = params.investedAmount;
        uint256 redeemed = _safeWithdraw(_token, _amount > invested ? invested : _amount);
        params.investedAmount = redeemed > invested ? 0 : invested - redeemed;
        IERC20(_token).transfer(mediator, redeemed);
    }

    /**
     * @dev Tells the current accumulated interest on the invested tokens, that can be withdrawn and payed to the interest receiver.
     * @param _token address of the invested token contract.
     * @return amount of accumulated interest.
     */
    function interestAmount(address _token) public view returns (uint256) {
        InterestParams storage params = interestParams[_token];
        (IAToken aToken, uint96 dust) = (params.aToken, params.dust);
        uint256 balance = aToken.balanceOf(address(this));
        // small portion of tokens are reserved for possible truncation/round errors
        uint256 reserved = params.investedAmount.add(dust);
        return balance > reserved ? balance - reserved : 0;
    }

    /**
     * @dev Pays collected interest for the underlying token.
     * Anyone can call this function.
     * Earned interest is withdrawn and transferred to the specified interest receiver account.
     * @param _token address of the invested token contract in which interest should be paid.
     */
    function payInterest(address _token) external {
        InterestParams storage params = interestParams[_token];
        uint256 interest = interestAmount(_token);
        require(interest >= params.minInterestPaid);
        _transferInterest(params.interestReceiver, address(_token), _safeWithdraw(_token, interest));
    }

    /**
     * @dev Last-resort function for returning assets to the Omnibridge contract in case of some failures in the logic.
     * Disables this contract and transfers locked tokens back to the mediator.
     * Only owner is allowed to call this method.
     * @param _token address of the invested token contract that should be disabled.
     */
    function forceDisable(address _token) external onlyOwner {
        InterestParams storage params = interestParams[_token];
        IAToken aToken = params.aToken;

        uint256 aTokenBalance = aToken.balanceOf(address(this));
        // try to redeem all cTokens
        try lendingPool().withdraw(_token, aTokenBalance, mediator) {
            uint256 balance = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(mediator, balance);
        } catch {
            aToken.transfer(mediator, aTokenBalance);
        }

        delete params.aToken;
        delete params.dust;
        delete params.investedAmount;
        delete params.minInterestPaid;
        delete params.interestReceiver;
    }

    /**
     * @dev Updates address of the interest receiver. Can be any address, EOA or contract.
     * Set to 0x00..00 to disable interest transfers.
     * Only owner is allowed to call this method.
     * @param _token address of the invested token contract.
     * @param _receiver address of the interest receiver.
     */
    function setInterestReceiver(address _token, address _receiver) external onlyOwner {
        interestParams[_token].interestReceiver = _receiver;
    }

    /**
     * @dev Updates min interest amount that can be transferred in single call.
     * Only owner is allowed to call this method.
     * @param _token address of the invested token contract.
     * @param _minInterestPaid new amount of TOKENS and can be transferred to the interest receiver in single operation.
     */
    function setMinInterestPaid(address _token, uint256 _minInterestPaid) external onlyOwner {
        interestParams[_token].minInterestPaid = _minInterestPaid;
    }

    /**
     * @dev Internal function for securely withdrawing assets from the underlying protocol.
     * @param _token address of the invested token contract.
     * @param _amount minimal amount of underlying tokens to withdraw from AAVE.
     * @return amount of redeemed tokens, at least as much as was requested.
     */
    function _safeWithdraw(address _token, uint256 _amount) private returns (uint256) {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        lendingPool().withdraw(_token, _amount, address(this));

        uint256 redeemed = IERC20(_token).balanceOf(address(this)) - balance;

        require(redeemed >= _amount);

        return redeemed;
    }

    /**
     * @dev Internal function transferring interest tokens to the interest receiver.
     * Calls a callback on the receiver, interest receiver is a contract.
     * @param _receiver address of the tokens receiver.
     * @param _token address of the token contract to send.
     * @param _amount amount of tokens to transfer.
     */
    function _transferInterest(
        address _receiver,
        address _token,
        uint256 _amount
    ) internal {
        require(_receiver != address(0));

        IERC20(_token).transfer(_receiver, _amount);

        if (Address.isContract(_receiver)) {
            IInterestReceiver(_receiver).onInterestReceived(_token);
        }

        emit PaidInterest(_token, _receiver, _amount);
    }
}

