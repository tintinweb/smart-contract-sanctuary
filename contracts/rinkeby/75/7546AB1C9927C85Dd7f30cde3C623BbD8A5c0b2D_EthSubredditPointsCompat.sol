/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./compat/Initializable.sol";
import "./compat/SafeMath.sol";
import "./compat/Address.sol";
import "./compat/Ownable.sol";
import "./compat/UpdatableGSNRecipientSignatureCompat.sol";
import "./ISubredditPoints.sol";

/*
    Tracks subreddit membership subscriptions.
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract SubscriptionsCompat is InitializableCompat, OwnableCompat, UpdatableGSNRecipientSignatureCompat {
    using SafeMath for uint256;
    using Address for address;

    event Subscribed(address indexed recipient, address indexed payer, uint256 burnedPoints, uint256 expiresAt, bool renewable);
    event Canceled(address indexed recipient, uint256 expiresAt);
    event DurationUpdated(uint256 duration);
    event PriceUpdated(uint256 price);
    event RenewBeforeUpdated(uint256 renewBefore);

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    uint256 internal _renewBefore;
    uint256 internal _duration;
    uint256 internal _price;

    // maps address to expiration time
    mapping(address => uint256) internal _subscriptions;
    // maps address of recipient to address of payer
    mapping(address => address) internal _payers;
    address internal _subredditPoints;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(
        address owner_,
        address gsnApprover,
        address subredditPoints,
        uint256 price_,
        uint256 duration_,
        uint256 renewBefore_
    ) external initializer {
        require(owner_ != address(0), "Subscriptions: owner should not be 0");

        OwnableCompat.initialize(owner_);
        UpdatableGSNRecipientSignatureCompat.initialize(gsnApprover);
        _subredditPoints = subredditPoints;

        updatePrice(price_);
        updateDuration(duration_);
        updateRenewBefore(renewBefore_);
    }

    function cancel(address recipient) external {
        address payer = _payers[recipient];
        require(_msgSender() == payer || _msgSender() == recipient, "Subscriptions: subscription can be cancelled by payer or recipient only");
        delete _payers[recipient];
        emit Canceled(recipient, _subscriptions[recipient]);
    }

    function renew(address recipient) external {
        address payer = _payers[recipient];
        require(payer != address(0), "Subscriptions: subscription is canceled");
        // solium-disable-next-line security/no-block-members
        require(expiration(recipient) < block.timestamp.add(_renewBefore), "Subscriptions: too early to renew");
        _subscribe(payer, recipient, true);
    }

    function subscribe(address recipient, bool renewable) external {
        address payer = _msgSender();
        if (renewable) {
            _payers[recipient] = payer;
        }
        _subscribe(payer, recipient, renewable);
    }

    function _subscribe(address payer, address recipient, bool renewable) internal {
        require(recipient != address(0), "Subscriptions: recipient should not be 0");
        uint256 expirationAt = _subscriptions[recipient];
        // solium-disable-next-line security/no-block-members
        if (expirationAt < block.timestamp) {
            // solium-disable-next-line security/no-block-members
            expirationAt = block.timestamp;
        }
        uint256 newExpiration = expirationAt.add(_duration);
        _subscriptions[recipient] = newExpiration;
        emit Subscribed(recipient, payer, _price, newExpiration, renewable);
        ISubredditPoints(_subredditPoints).operatorBurn(payer, _price, "", "");
    }

    function updateDuration(uint256 duration_) public onlyOwner {
        require(duration_ > 0, "Subscriptions: duration should be > 0");
        _duration = duration_;
        emit DurationUpdated(duration_);
    }

    function updatePrice(uint256 price_) public onlyOwner {
        require(price_ > 0, "Subscriptions: price should be > 0");
        _price = price_;
        emit PriceUpdated(price_);
    }

    function updateRenewBefore(uint256 renewBefore_) public onlyOwner {
        require(renewBefore_ > 0, "Subscriptions: renewBefore should be > 0");
        _renewBefore = renewBefore_;
        emit RenewBeforeUpdated(renewBefore_);
    }

    function duration() external view returns (uint256) {
        return _duration;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function renewBefore() external view returns (uint256) {
        return _renewBefore;
    }

    function expiration(address account) public view returns (uint256) {
        return _subscriptions[account];
    }

    function updateGSNApprover(address gsnApprover) external onlyOwner {
        updateSigner(gsnApprover);
    }
}

// Adopted from openzeppelin: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract InitializableCompat {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// Adopted from: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// Adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// Adooted from @openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

import "./Initializable.sol";
import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract OwnableCompat is InitializableCompat, ContextCompat {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
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
        return _msgSender() == _owner;
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

    uint256[50] private ______gap;
}

/*
    Copyright (c) 2020 Reddit Inc. All rights reserved.
    Redistribution and use in source and binary forms, with or without modification, are permitted provided
    that the following conditions are met:
    1. Redistributions of source code must retain the above copyright notice,
        this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation and/or other
        materials provided with the distribution.
    3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
        or promote products derived from this software without specific prior written permission.
    THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
    BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSEARE DISCLAIMED.
    IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
    STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
    EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./Initializable.sol";

import "./GSNRecipient.sol";
import "./ECDSA.sol";

contract UpdatableGSNRecipientSignatureCompat is InitializableCompat, GSNRecipientCompat {
    using ECDSA for bytes32;

    event SignerUpdated(address signer);

    address private _trustedSigner;

    enum GSNRecipientSignatureErrorCodes {
        INVALID_SIGNER
    }

    /**
     * @dev Sets the trusted signer that is going to be producing signatures to approve relayed calls.
     */
    function initialize(address trustedSigner) public initializer {
        updateSigner(trustedSigner);
        GSNRecipientCompat.initialize();
    }

    /**
     * @dev Ensures that only transactions with a trusted signature can be relayed through the GSN.
     */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256
    )
        external
        view
        returns (uint256, bytes memory)
    {
        bytes memory blob = abi.encode(
            relay,
            from,
            encodedFunction,
            transactionFee,
            gasPrice,
            gasLimit,
            nonce, // Prevents replays on RelayHub
            getHubAddr(), // Prevents replays in multiple RelayHubs
            address(this) // Prevents replays in multiple recipients
        );
        if (keccak256(blob).toEthSignedMessageHash().recover(approvalData) == _trustedSigner) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(uint256(GSNRecipientSignatureErrorCodes.INVALID_SIGNER));
        }
    }

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    function updateSigner(address trustedSigner) internal {
        require(trustedSigner != address(0), "GSNRecipientSignature: trusted signer is the zero address");
        _trustedSigner = trustedSigner;
        emit SignerUpdated(trustedSigner);
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface ISubredditPoints {
    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    event DefaultOperatorAdded(address indexed operator);

    event DefaultOperatorRemoved(address indexed operator);

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external; // solium-disable-line indentation

    function burn(
        uint256 amount,
        bytes calldata data
    ) external; // solium-disable-line indentation

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external; // solium-disable-line indentation

    function subreddit() external view returns (string memory);
}

//

// Adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

import "./Initializable.sol";

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
contract ContextCompat is InitializableCompat {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol

pragma solidity ^0.5.0;

import "./Initializable.sol";

import "./IRelayRecipient.sol";
import "./IRelayHub.sol";
import "./Context.sol";

/**
 * @dev Base GSN recipient contract: includes the {IRelayRecipient} interface
 * and enables GSN support on all contracts in the inheritance tree.
 *
 * TIP: This contract is abstract. The functions {IRelayRecipient-acceptRelayedCall},
 *  {_preRelayedCall}, and {_postRelayedCall} are not implemented and must be
 * provided by derived contracts. See the
 * xref:ROOT:gsn-strategies.adoc#gsn-strategies[GSN strategies] for more
 * information on how to use the pre-built {GSNRecipientSignature} and
 * {GSNRecipientERC20Fee}, or how to write your own.
 */
contract GSNRecipientCompat is InitializableCompat, IRelayRecipient, ContextCompat {
    function initialize() public initializer {
        if (_relayHub == address(0)) {
            setDefaultRelayHub();
        }
    }

    function setDefaultRelayHub() public {
        _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
    }

    // Default RelayHub address, deployed on mainnet and all testnets at the same address
    address private _relayHub;

    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

    // How much gas is forwarded to postRelayedCall
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

    /**
     * @dev Emitted when a contract changes its {IRelayHub} contract to a new one.
     */
    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    /**
     * @dev Returns the address of the {IRelayHub} contract for this recipient.
     */
    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

    /**
     * @dev Switches to a new {IRelayHub} instance. This method is added for future-proofing: there's no reason to not
     * use the default instance.
     *
     * IMPORTANT: After upgrading, the {GSNRecipient} will no longer be able to receive relayed calls from the old
     * {IRelayHub} instance. Additionally, all funds should be previously withdrawn via {_withdrawDeposits}.
     */
    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNRecipient: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNRecipient: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        _relayHub = newRelayHub;
    }

    /**
     * @dev Returns the version string of the {IRelayHub} for which this recipient implementation was built. If
     * {_upgradeRelayHub} is used, the new {IRelayHub} instance should be compatible with this version.
     */
    // This function is view for future-proofing, it may require reading from
    // storage in the future.
    function relayHubVersion() public view returns (string memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return "1.0.0";
    }

    /**
     * @dev Withdraws the recipient's deposits in `RelayHub`.
     *
     * Derived contracts should expose this in an external interface with proper access control.
     */
    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_relayHub).withdraw(amount, payee);
    }

    // Overrides for Context's functions: when called from RelayHub, sender and
    // data require some pre-processing: the actual sender is stored at the end
    // of the call data, which in turns means it needs to be removed from it
    // when handling said data.

    /**
     * @dev Replacement for msg.sender. Returns the actual sender of a transaction: msg.sender for regular transactions,
     * and the end-user for GSN relayed calls (where msg.sender is actually `RelayHub`).
     *
     * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.sender`, and use {_msgSender} instead.
     */
    function _msgSender() internal view returns (address payable) {
        if (msg.sender != _relayHub) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    /**
     * @dev Replacement for msg.data. Returns the actual calldata of a transaction: msg.data for regular transactions,
     * and a reduced version for GSN relayed calls (where msg.data contains additional information).
     *
     * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.data`, and use {_msgData} instead.
     */
    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    // Base implementations for pre and post relayedCall: only RelayHub can invoke them, and data is forwarded to the
    // internal hook.

    /**
     * @dev See `IRelayRecipient.preRelayedCall`.
     *
     * This function should not be overriden directly, use `_preRelayedCall` instead.
     *
     * * Requirements:
     *
     * - the caller must be the `RelayHub` contract.
     */
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        return _preRelayedCall(context);
    }

    /**
     * @dev See `IRelayRecipient.preRelayedCall`.
     *
     * Called by `GSNRecipient.preRelayedCall`, which asserts the caller is the `RelayHub` contract. Derived contracts
     * must implement this function with any relayed-call preprocessing they may wish to do.
     *
     */
    function _preRelayedCall(bytes memory context) internal returns (bytes32);

    /**
     * @dev See `IRelayRecipient.postRelayedCall`.
     *
     * This function should not be overriden directly, use `_postRelayedCall` instead.
     *
     * * Requirements:
     *
     * - the caller must be the `RelayHub` contract.
     */
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

    /**
     * @dev See `IRelayRecipient.postRelayedCall`.
     *
     * Called by `GSNRecipient.postRelayedCall`, which asserts the caller is the `RelayHub` contract. Derived contracts
     * must implement this function with any relayed-call postprocessing they may wish to do.
     *
     */
    function _postRelayedCall(bytes memory context, bool success, uint256 actualCharge, bytes32 preRetVal) internal;

    /**
     * @dev Return this in acceptRelayedCall to proceed with the execution of a relayed call. Note that this contract
     * will be charged a fee by RelayHub
     */
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

    /**
     * @dev See `GSNRecipient._approveRelayedCall`.
     *
     * This overload forwards `context` to _preRelayedCall and _postRelayedCall.
     */
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

    /**
     * @dev Return this in acceptRelayedCall to impede execution of a relayed call. No fees will be charged.
     */
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

    /*
     * @dev Calculates how much RelayHub will charge a recipient for using `gas` at a `gasPrice`, given a relayer's
     * `serviceFee`.
     */
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
        // The fee is expressed as a percentage. E.g. a value of 40 stands for a 40% fee, so the recipient will be
        // charged for 1.4 times the spent amount.
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }

    function _getRelayedCallSender() private pure returns (address payable result) {
        // We need to read 20 bytes (an address) located at array index msg.data.length - 20. In memory, the array
        // is prefixed with a 32-byte length value, so we first add 32 to get the memory read index. However, doing
        // so would leave the address in the upper 20 bytes of the 32-byte word, which is inconvenient and would
        // require bit shifting. We therefore subtract 12 from the read index so the address lands on the lower 20
        // bytes. This can always be done due to the 32-byte prefix.

        // The final memory read index is msg.data.length - 20 + 32 - 12 = msg.data.length. Using inline assembly is the
        // easiest/most-efficient way to perform this operation.

        // These fields are not accessible from assembly
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
        // RelayHub appends the sender address at the end of the calldata, so in order to retrieve the actual msg.data,
        // we must strip the last 20 bytes (length of an address type) from it.

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

// adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/cryptography/ECDSA.sol

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// Adopted from @openzeppelin/contracts-ethereum-package/contracts/GSN/IRelayRecipient.sol

pragma solidity ^0.5.0;

/**
 * @dev Base interface for a contract that will be called via the GSN from {IRelayHub}.
 *
 * TIP: You don't need to write an implementation yourself! Inherit from {GSNRecipient} instead.
 */
interface IRelayRecipient {
    /**
     * @dev Returns the address of the {IRelayHub} instance this recipient interacts with.
     */
    function getHubAddr() external view returns (address);

    /**
     * @dev Called by {IRelayHub} to validate if this recipient accepts being charged for a relayed call. Note that the
     * recipient will be charged regardless of the execution result of the relayed call (i.e. if it reverts or not).
     *
     * The relay request was originated by `from` and will be served by `relay`. `encodedFunction` is the relayed call
     * calldata, so its first four bytes are the function selector. The relayed call will be forwarded `gasLimit` gas,
     * and the transaction executed with a gas price of at least `gasPrice`. `relay`'s fee is `transactionFee`, and the
     * recipient will be charged at most `maxPossibleCharge` (in wei). `nonce` is the sender's (`from`) nonce for
     * replay attack protection in {IRelayHub}, and `approvalData` is a optional parameter that can be used to hold a signature
     * over all or some of the previous values.
     *
     * Returns a tuple, where the first value is used to indicate approval (0) or rejection (custom non-zero error code,
     * values 1 to 10 are reserved) and the second one is data to be passed to the other {IRelayRecipient} functions.
     *
     * {acceptRelayedCall} is called with 50k gas: if it runs out during execution, the request will be considered
     * rejected. A regular revert will also trigger a rejection.
     */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    /**
     * @dev Called by {IRelayHub} on approved relay call requests, before the relayed call is executed. This allows to e.g.
     * pre-charge the sender of the transaction.
     *
     * `context` is the second value returned in the tuple by {acceptRelayedCall}.
     *
     * Returns a value to be passed to {postRelayedCall}.
     *
     * {preRelayedCall} is called with 100k gas: if it runs out during exection or otherwise reverts, the relayed call
     * will not be executed, but the recipient will still be charged for the transaction's cost.
     */
    function preRelayedCall(bytes calldata context) external returns (bytes32);

    /**
     * @dev Called by {IRelayHub} on approved relay call requests, after the relayed call is executed. This allows to e.g.
     * charge the user for the relayed call costs, return any overcharges from {preRelayedCall}, or perform
     * contract-specific bookkeeping.
     *
     * `context` is the second value returned in the tuple by {acceptRelayedCall}. `success` is the execution status of
     * the relayed call. `actualCharge` is an estimate of how much the recipient will be charged for the transaction,
     * not including any gas used by {postRelayedCall} itself. `preRetVal` is {preRelayedCall}'s return value.
     *
     *
     * {postRelayedCall} is called with 100k gas: if it runs out during execution or otherwise reverts, the relayed call
     * and the call to {preRelayedCall} will be reverted retroactively, but the recipient will still be charged for the
     * transaction's cost.
     */
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external;
}

// Adopted from @openzeppelin/contracts-ethereum-package/contracts/GSN/IRelayHub.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface for `RelayHub`, the core contract of the GSN. Users should not need to interact with this contract
 * directly.
 *
 * See the https://github.com/OpenZeppelin/openzeppelin-gsn-helpers[OpenZeppelin GSN helpers] for more information on
 * how to deploy an instance of `RelayHub` on your local test network.
 */
interface IRelayHub {
    // Relay management

    /**
     * @dev Adds stake to a relay and sets its `unstakeDelay`. If the relay does not exist, it is created, and the caller
     * of this function becomes its owner. If the relay already exists, only the owner can call this function. A relay
     * cannot be its own owner.
     *
     * All Ether in this function call will be added to the relay's stake.
     * Its unstake delay will be assigned to `unstakeDelay`, but the new value must be greater or equal to the current one.
     *
     * Emits a {Staked} event.
     */
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

    /**
     * @dev Emitted when a relay's stake or unstakeDelay are increased
     */
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

    /**
     * @dev Registers the caller as a relay.
     * The relay must be staked for, and not be a contract (i.e. this function must be called directly from an EOA).
     *
     * This function can be called multiple times, emitting new {RelayAdded} events. Note that the received
     * `transactionFee` is not enforced by {relayCall}.
     *
     * Emits a {RelayAdded} event.
     */
    function registerRelay(uint256 transactionFee, string calldata url) external;

    /**
     * @dev Emitted when a relay is registered or re-registerd. Looking at these events (and filtering out
     * {RelayRemoved} events) lets a client discover the list of available relays.
     */
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

    /**
     * @dev Removes (deregisters) a relay. Unregistered (but staked for) relays can also be removed.
     *
     * Can only be called by the owner of the relay. After the relay's `unstakeDelay` has elapsed, {unstake} will be
     * callable.
     *
     * Emits a {RelayRemoved} event.
     */
    function removeRelayByOwner(address relay) external;

    /**
     * @dev Emitted when a relay is removed (deregistered). `unstakeTime` is the time when unstake will be callable.
     */
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

    /** Deletes the relay from the system, and gives back its stake to the owner.
     *
     * Can only be called by the relay owner, after `unstakeDelay` has elapsed since {removeRelayByOwner} was called.
     *
     * Emits an {Unstaked} event.
     */
    function unstake(address relay) external;

    /**
     * @dev Emitted when a relay is unstaked for, including the returned stake.
     */
    event Unstaked(address indexed relay, uint256 stake);

    // States a relay can be in
    enum RelayState {
        Unknown, // The relay is unknown to the system: it has never been staked for
        Staked, // The relay has been staked for, but it is not yet active
        Registered, // The relay has registered itself, and is active (can relay calls)
        Removed    // The relay has been removed by its owner and can no longer relay calls. It must wait for its unstakeDelay to elapse before it can unstake
    }

    /**
     * @dev Returns a relay's status. Note that relays can be deleted when unstaked or penalized, causing this function
     * to return an empty entry.
     */
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

    // Balance management

    /**
     * @dev Deposits Ether for a contract, so that it can receive (and pay for) relayed transactions.
     *
     * Unused balance can only be withdrawn by the contract itself, by calling {withdraw}.
     *
     * Emits a {Deposited} event.
     */
    function depositFor(address target) external payable;

    /**
     * @dev Emitted when {depositFor} is called, including the amount and account that was funded.
     */
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

    /**
     * @dev Returns an account's deposits. These can be either a contracts's funds, or a relay owner's revenue.
     */
    function balanceOf(address target) external view returns (uint256);

    /**
     * Withdraws from an account's balance, sending it back to it. Relay owners call this to retrieve their revenue, and
     * contracts can use it to reduce their funding.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(uint256 amount, address payable dest) external;

    /**
     * @dev Emitted when an account withdraws funds from `RelayHub`.
     */
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

    // Relaying

    /**
     * @dev Checks if the `RelayHub` will accept a relayed operation.
     * Multiple things must be true for this to happen:
     *  - all arguments must be signed for by the sender (`from`)
     *  - the sender's nonce must be the current one
     *  - the recipient must accept this transaction (via {acceptRelayedCall})
     *
     * Returns a `PreconditionCheck` value (`OK` when the transaction can be relayed), or a recipient-specific error
     * code if it returns one in {acceptRelayedCall}.
     */
    function canRelay(
        address relay,
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external view returns (uint256 status, bytes memory recipientContext);

    // Preconditions for relaying, checked by canRelay and returned as the corresponding numeric values.
    enum PreconditionCheck {
        OK,                         // All checks passed, the call can be relayed
        WrongSignature,             // The transaction to relay is not signed by requested sender
        WrongNonce,                 // The provided nonce has already been used by the sender
        AcceptRelayedCallReverted,  // The recipient rejected this call via acceptRelayedCall
        InvalidRecipientStatusCode  // The recipient returned an invalid (reserved) status code
    }

    /**
     * @dev Relays a transaction.
     *
     * For this to succeed, multiple conditions must be met:
     *  - {canRelay} must `return PreconditionCheck.OK`
     *  - the sender must be a registered relay
     *  - the transaction's gas price must be larger or equal to the one that was requested by the sender
     *  - the transaction must have enough gas to not run out of gas if all internal transactions (calls to the
     * recipient) use all gas available to them
     *  - the recipient must have enough balance to pay the relay for the worst-case scenario (i.e. when all gas is
     * spent)
     *
     * If all conditions are met, the call will be relayed and the recipient charged. {preRelayedCall}, the encoded
     * function and {postRelayedCall} will be called in that order.
     *
     * Parameters:
     *  - `from`: the client originating the request
     *  - `to`: the target {IRelayRecipient} contract
     *  - `encodedFunction`: the function call to relay, including data
     *  - `transactionFee`: fee (%) the relay takes over actual gas cost
     *  - `gasPrice`: gas price the client is willing to pay
     *  - `gasLimit`: gas to forward when calling the encoded function
     *  - `nonce`: client's nonce
     *  - `signature`: client's signature over all previous params, plus the relay and RelayHub addresses
     *  - `approvalData`: dapp-specific data forwared to {acceptRelayedCall}. This value is *not* verified by the
     * `RelayHub`, but it still can be used for e.g. a signature.
     *
     * Emits a {TransactionRelayed} event.
     */
    function relayCall(
        address from,
        address to,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata signature,
        bytes calldata approvalData
    ) external;

    /**
     * @dev Emitted when an attempt to relay a call failed.
     *
     * This can happen due to incorrect {relayCall} arguments, or the recipient not accepting the relayed call. The
     * actual relayed call was not executed, and the recipient not charged.
     *
     * The `reason` parameter contains an error code: values 1-10 correspond to `PreconditionCheck` entries, and values
     * over 10 are custom recipient error codes returned from {acceptRelayedCall}.
     */
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

    /**
     * @dev Emitted when a transaction is relayed.
     * Useful when monitoring a relay's operation and relayed calls to a contract
     *
     * Note that the actual encoded function might be reverted: this is indicated in the `status` parameter.
     *
     * `charge` is the Ether value deducted from the recipient's balance, paid to the relay's owner.
     */
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

    // Reason error codes for the TransactionRelayed event
    enum RelayCallStatus {
        OK,                      // The transaction was successfully relayed and execution successful - never included in the event
        RelayedCallFailed,       // The transaction was relayed, but the relayed call failed
        PreRelayedFailed,        // The transaction was not relayed due to preRelatedCall reverting
        PostRelayedFailed,       // The transaction was relayed and reverted due to postRelatedCall reverting
        RecipientBalanceChanged  // The transaction was relayed and reverted due to the recipient's balance changing
    }

    /**
     * @dev Returns how much gas should be forwarded to a call to {relayCall}, in order to relay a transaction that will
     * spend up to `relayedCallStipend` gas.
     */
    function requiredGas(uint256 relayedCallStipend) external view returns (uint256);

    /**
     * @dev Returns the maximum recipient charge, given the amount of gas forwarded, gas price and relay fee.
     */
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) external view returns (uint256);

     // Relay penalization.
     // Any account can penalize relays, removing them from the system immediately, and rewarding the
    // reporter with half of the relay's stake. The other half is burned so that, even if the relay penalizes itself, it
    // still loses half of its stake.

    /**
     * @dev Penalize a relay that signed two transactions using the same nonce (making only the first one valid) and
     * different data (gas price, gas limit, etc. may be different).
     *
     * The (unsigned) transaction data and signature for both transactions must be provided.
     */
    function penalizeRepeatedNonce(bytes calldata unsignedTx1, bytes calldata signature1, bytes calldata unsignedTx2, bytes calldata signature2) external;

    /**
     * @dev Penalize a relay that sent a transaction that didn't target `RelayHub`'s {registerRelay} or {relayCall}.
     */
    function penalizeIllegalTransaction(bytes calldata unsignedTx, bytes calldata signature) external;

    /**
     * @dev Emitted when a relay is penalized.
     */
    event Penalized(address indexed relay, address sender, uint256 amount);

    /**
     * @dev Returns an account's nonce in `RelayHub`.
     */
    function getNonce(address from) external view returns (uint256);
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./SubscriptionsCompat.sol";
import "./Frozen.sol";

/*
    Used while exporting subscriptions from L1 -> L2
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract SubscriptionsFrozenCompat is SubscriptionsCompat, Frozen {
    function initialize(
        address owner_,
        address gsnApprover,
        address subredditPoints,
        uint256 price_,
        uint256 duration_,
        uint256 renewBefore_
    ) external frozen {
    }

    function cancel(address recipient) external frozen {
    }

    function renew(address recipient) external frozen {
    }

    function subscribe(address recipient, bool renewable) external frozen {
    }

    function updateDuration(uint256 duration_) public frozen {
    }

    function updatePrice(uint256 price_) public frozen {
    }

    function updateRenewBefore(uint256 renewBefore_) public frozen {
    }

    function duration() external view returns (uint256) {
        return _duration;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function renewBefore() external view returns (uint256) {
        return _renewBefore;
    }

    function expiration(address account) public view returns (uint256) {
        return _subscriptions[account];
    }

    function updateGSNApprover(address gsnApprover) external frozen {
    }

    function payerOf(address account) public view returns (address) {
        return _payers[account];
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface Frozen {
    modifier frozen() {
        revert("Contract is frozen");
        _;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./compat/Initializable.sol";
import "./compat/ERC20.sol";
import "./compat/SafeMath.sol";
import "./compat/Address.sol";
import "./compat/Ownable.sol";
import "./compat/UpdatableGSNRecipientSignatureCompat.sol";

import "./IEthBridgedToken.sol";
import "./Frozen.sol";
import "./EthSubredditPointsCompat.sol";

/*
    SubredditPoints ERC20 token Compatible with Rinkeby implementation/OZ 2.x libraries.
    This one is obsolete and is only preserved if
    it's required to rollback for some reason.
*/

contract EthSubredditPointsObsoleteCompat is InitializableCompat, OwnableCompat, UpdatableGSNRecipientSignatureCompat, ERC20Compat {
    using SafeMath for uint256;
    using Address for address;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event DefaultOperatorAdded(address indexed operator);
    event DefaultOperatorRemoved(address indexed operator);

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    string internal _subreddit;
    string internal _name;
    string internal _symbol;

    // operators notion from ERC777, accounts can revoke default operator
    mapping(address => bool) internal _defaultOperators;

    // Maps operators and revoked default operators to state (enabled/disabled)
    mapping(address => mapping(address => bool)) internal _operators;
    mapping(address => mapping(address => bool)) internal _revokedDefaultOperators;

    // operators notion from ERC777, accounts can revoke default operator
    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] internal _defaultOperatorsArray;

    address _distributionContract;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(
        address owner_,
        address gsnApprover_,
        address distributionContract_,
        string calldata subreddit_,
        string calldata name_,
        string calldata symbol_,

        address[] calldata defaultOperators_
    ) external initializer {
        require(bytes(subreddit_).length != 0, "SubredditPoints: subreddit can't be empty");
        require(bytes(name_).length != 0, "SubredditPoints: name can't be empty");
        require(bytes(symbol_).length != 0, "SubredditPoints: symbol can't be empty");
        require(owner_ != address(0), "SubredditPoints: owner should not be 0");

        OwnableCompat.initialize(owner_);
        UpdatableGSNRecipientSignatureCompat.initialize(gsnApprover_);

        updateDistributionContract(distributionContract_);

        _subreddit = subreddit_;
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
            emit DefaultOperatorAdded(defaultOperators_[i]);
        }
    }

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        require(_msgSender() == _distributionContract, "SubredditPoints: only distribution contract can mint points");

        super._mint(account, amount);
        emit Minted(operator, account, amount, userData, operatorData);
    }

    function burn(
        uint256 amount,
        bytes calldata userData
    ) external {
        address account = _msgSender();
        _burn(account, account, amount, userData, "");
    }

    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    function authorizeOperator(address operator) external {
        require(_msgSender() != operator, "SubredditPoints: authorizing self as operator");
        require(address(0) != operator, "SubredditPoints: operator can't have 0 address");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    function revokeOperator(address operator) external {
        require(operator != _msgSender(), "SubredditPoints: revoking self as operator");
        require(address(0) != operator, "SubredditPoints: operator can't have 0 address");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        address operator = _msgSender();
        require(isOperatorFor(operator, sender), "SubredditPoints: caller is not an operator for holder");
        _transfer(sender, recipient, amount);
        emit Sent(operator, sender, recipient, amount, userData, operatorData);
    }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        address operator = _msgSender();
        require(isOperatorFor(operator, account), "SubredditPoints: caller is not an operator for holder");
        _burn(operator, account, amount, data, operatorData);
    }

    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    function addDefaultOperator(address operator) external onlyOwner {
        require(operator != address(0), "SubredditPoints: operator address shouldn't be 0");
        require(!_defaultOperators[operator], "SubredditPoints: operator already exists");

        _defaultOperatorsArray.push(operator);
        _defaultOperators[operator] = true;

        emit DefaultOperatorAdded(operator);
    }

    function removeDefaultOperator(address operator) external onlyOwner {
        require(operator != address(0), "SubredditPoints: operator address shouldn't be 0");
        require(_defaultOperators[operator], "SubredditPoints: operator doesn't exists");

        for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
            if (_defaultOperatorsArray[i] == operator) {
                if (i != (_defaultOperatorsArray.length - 1)) { // if it's not last element, replace it from the tail
                    _defaultOperatorsArray[i] = _defaultOperatorsArray[_defaultOperatorsArray.length-1];
                }
                _defaultOperatorsArray.length = _defaultOperatorsArray.length - 1;
                break;
            }
        }
        delete _defaultOperators[operator];

        emit DefaultOperatorRemoved(operator);
    }

    function _burn(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        super._burn(account, amount);
        emit Burned(operator, account, amount, userData, operatorData);
    }

    function subreddit() external view returns (string memory) {
        return _subreddit;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function updateGSNApprover(address gsnApprover) external onlyOwner {
        updateSigner(gsnApprover);
    }

    function updateDistributionContract(address distributionContract_) public onlyOwner {
        require(distributionContract_ != address(0), "SubredditPoints: distributionContract should not be 0");
        _distributionContract = distributionContract_;
    }

    function distributionContract() external view returns (address) {
        return _distributionContract;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}

// adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;

import "./Initializable.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Compat is InitializableCompat, ContextCompat, IERC20Compat {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface IEthBridgedToken {
    /**
     * @notice should increase token supply by amount, and should only be callable by the L2 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should only be callable by the L2 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 2 token
     */
    function l2Address() external view returns (address);
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./EthSubredditPointsObsoleteCompat.sol";
import "./IEthBridgedToken.sol";

interface IL1CustomGatewayCompat {
    function router() external returns (address);
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);
}

interface IL1GatewayRouterCompat {
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256);
}

/*
    L1 SubredditPoints ERC20 token, pairable to L2 and supports L1<->L2 withdrawals/deposits.
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract EthSubredditPointsCompat is EthSubredditPointsObsoleteCompat, IEthBridgedToken {
    using SafeMath for uint256;
    using Address for address;

    event TransferredFromL2(address indexed source, address indexed destination, uint256 amount, bytes userData);
    event TransferredToL2(address indexed source, address indexed destination, uint256 amount, bytes userData, uint256 seqNum);

    modifier onlyGateway {
        require(msg.sender == address(gateway), "Call only from gateway");
        _;
    }

    modifier disabled() {
        revert("Method is disabled");
        _;
    }

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    IL1CustomGatewayCompat public gateway;
    address public l2Address;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(address owner_, string calldata subreddit_, string calldata name_,
        string calldata symbol_, address gateway_, address l2Address_)
        external initializer
    {
        require(gateway_ != address(0), "gateway should not be 0");
        require(l2Address_ != address(0), "l2Address should not be 0");

        gateway = IL1CustomGatewayCompat(gateway_);
        l2Address = l2Address_;

        require(bytes(subreddit_).length != 0, "SubredditPoints: subreddit can't be empty");
        require(bytes(name_).length != 0, "SubredditPoints: name can't be empty");
        require(bytes(symbol_).length != 0, "SubredditPoints: symbol can't be empty");
        require(owner_ != address(0), "SubredditPoints: owner should not be 0");

        OwnableCompat.initialize(owner_);
        //UpdatableGSNRecipientSignatureCompat.initialize(gsnApprover_);
        //updateDistributionContract(distributionContract_);

        _subreddit = subreddit_;
        _name = name_;
        _symbol = symbol_;
    }

    function initializeL2(address gateway_, address l2Address_)
        external onlyOwner
    {
        require(gateway_ != address(0), "gateway should not be 0");
        require(l2Address_ != address(0), "l2Address should not be 0");

        gateway = IL1CustomGatewayCompat(gateway_);
        l2Address = l2Address_;
    }

    // ------------------------------------------------------------------------------------
    // Disabled functions

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external disabled { }

    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return false;
    }

    function authorizeOperator(address operator) external disabled { }

    function revokeOperator(address operator) external disabled { }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external disabled { }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external disabled { }

    function defaultOperators() external view returns (address[] memory) {
        return new address[](0);
    }

    function addDefaultOperator(address operator) external onlyOwner disabled { }

    function removeDefaultOperator(address operator) external onlyOwner disabled { }

    // ------------------------------------------------------------------------------------
    // L2 compatibility functions

    function registerTokenToL2(uint256 maxGas, uint256 gasPriceBid, uint256 maxSubmissionCost) external onlyOwner {
        gateway.registerTokenToL2(
            l2Address,
            maxGas / 2,
            gasPriceBid,
            maxSubmissionCost / 2
        );

        address router = gateway.router();
        IL1GatewayRouterCompat(router).setGateway(address(gateway),
            maxGas / 2,
            gasPriceBid,
            maxSubmissionCost / 2
        );
    }

    function bridgeMint(address account, uint256 amount) external onlyGateway {
        _mint(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external onlyGateway {
        super._burn(account, amount);
    }
}

// adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.5.0 < 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20Compat {
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

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./EthSubredditPointsCompat.sol";

/*
    L1 SubredditPoints ERC20 token that's used while migrating/exporting points to L2
    Compatible with Rinkeby implementation/OZ 2.x libraries.
*/

contract EthSubredditPointsFrozenCompat is EthSubredditPointsCompat {
    modifier onlyOwnerOrGateway() {
        require(isOwner() || _msgSender() == address(gateway), "Only owner or gateway can call this");
        _;
    }

    function depositToL2(address[] calldata accounts, uint256 maxGas, uint256 gasPriceBid, uint256 maxSubmissionCost)
        external onlyOwner {

        bytes memory emptyBytes = "";
        bytes memory data = abi.encode(maxSubmissionCost, emptyBytes);
        for (uint256 i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            uint256 amount = balanceOf(account);
            if (amount > 0) {
                _transfer(account, address(this), amount);
                gateway.outboundTransfer(address(this), account, amount, maxGas, gasPriceBid, data);
            }
        }
    }

    function _mint(address account, uint256 amount) internal onlyOwnerOrGateway {
        super._mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal onlyOwnerOrGateway {
        super._transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal onlyOwnerOrGateway {
        super._approve(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal onlyOwnerOrGateway {
        super._burn(account, amount);
    }

    function _burnFrom(address account, uint256 amount) internal onlyOwnerOrGateway {
        super._burnFrom(account, amount);
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./compat/Initializable.sol";
import "./compat/SafeMath.sol";
import "./compat/Address.sol";
import "./compat/Ownable.sol";
import "./compat/UpdatableGSNRecipientSignatureCompat.sol";
import "./compat/ECDSA.sol";
import "./compat/IERC20.sol";
import "./ISubredditPoints.sol";

/*
    Same as Distribution but compatible with existing L1 (Rinkeby) implementation and use older OZ libraries (2.x) to
    be upgradable in L1.
    Doesn't have accountID logic.
    Shouldn't be used for any new subreddits or after moving to mainnet.
*/

contract DistributionsCompat is InitializableCompat, OwnableCompat, UpdatableGSNRecipientSignatureCompat {

    struct SharedOwner {
        address account;
        uint256 percent; // e.g. 30% percent = 30 * percentPrecision/100
    }

    struct DistributionRound {
        uint256 availablePoints;
        uint256 sharedOwnersAvailablePoints;
        uint256 totalKarma;
    }

    event SharedOwnerUpdated(
        address indexed _from,
        address indexed _to,
        uint256 _percent
    );

    event AdvanceRound(uint256 round, uint256 totalPoints, uint256 sharedOwnersPoints);
    event ClaimPoints(uint256 round, address indexed user, uint256 karma, uint256 points);
    event KarmaSourceUpdated(address _karmaSource, address _prevKarmaSource);
    event SupplyDecayPercentUpdated(uint256 supplyDecayPercent);
    event RoundsBeforeExpirationUpdated(uint256 roundsBeforeExpiration);

    using SafeMath for uint256;
    using Address for address;

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    address public subredditPoints;
    address public karmaSource;
    string public subreddit;
    string private _subredditLowerCase;
    uint256 public lastRound;
    uint256 public startBlockNumber;
    // maps round number to round data
    mapping(uint256 => DistributionRound) internal _distributionRounds;
    // maps account to next claimable round
    mapping(address => uint256) internal _claimableRounds;

    // when sharing percentage, the least possible share is 1/percentPrecision
    uint256 public constant PERCENT_PRECISION = 1000000;
    uint256 public constant MAX_ROUND_SUPPLY = 10**11 * 10**18; // max is 100 bln, to prevent overflows

    // 1 shared owner ~ 35k gas + 250k gas for other ops in advanceToRound
    // so we limit to (8M - 250k)/35k = 221 maximum shared owners
    uint256 public constant MAX_SHARED_OWNERS = 200;

    uint256 public constant MAX_SKIP_ROUNDS = 10;

    uint256 public initialSupply;
    uint256 public roundsBeforeExpiration;
    uint256 public nextSupply;
    uint256 public supplyDecayPercent;

    // those owners if exists will get proportion of minted points according to value in percentage
    SharedOwner[] public sharedOwners;
    uint256 internal _prevRoundSupply;       // supply in a prev round
    uint256 internal _prevClaimed;           // total claimed in a prev round

    // Previous karmaSource signer. Used when rotating karmaSource key to enable
    // previous signer to still be valid for a while.
    address public prevKarmaSource;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(
        address owner_,
        address subredditPoints_,                    // ISubredditPoints + IERC20 token contract address
        address karmaSource_,                        // Karma source provider address
        address gsnApprover_,                        // GSN approver address

        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 initialKarma_,
        uint256 roundsBeforeExpiration_,              // how many rounds are passed before claiming is possible
        uint256 supplyDecayPercent_,                  // defines percentage of next rounds' supply from the current
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_           // index of percentages must correspond to _sharedOwners array
    ) external initializer {
        require(initialSupply_ > 0 && initialSupply_ <= MAX_ROUND_SUPPLY, "Distributions: initial supply should be > 0 and <= MAX_ROUND_SUPPLY");
        require(initialKarma_ > 0, "Distributions: initial karma should be more than 0");
        require(nextSupply_ > 0 && nextSupply_ <= MAX_ROUND_SUPPLY, "Distributions: nextSupply should be > 0 and <= MAX_ROUND_SUPPLY");
        require(karmaSource_ != address(0), "Distributions: karma source should not be 0");
        require(gsnApprover_ != address(0), "Distributions: GSN approver should not be 0");
        require(owner_ != address(0), "Distributions: owner should not be 0");
        require(sharedOwners_.length == sharedOwnersPercs_.length, "Shared owners: Addresses array must be same length as percentages");

        OwnableCompat.initialize(owner_);
        UpdatableGSNRecipientSignatureCompat.initialize(gsnApprover_);
        updateSupplyDecayPercent(supplyDecayPercent_);
        updateRoundsBeforeExpiration(roundsBeforeExpiration_);

        subredditPoints = subredditPoints_;
        karmaSource = karmaSource_;
        prevKarmaSource = karmaSource_;
        subreddit = ISubredditPoints(subredditPoints_).subreddit();
        _subredditLowerCase = _toLower(subreddit);

        startBlockNumber = block.number;

        initialSupply = initialSupply_;
        nextSupply = nextSupply_;

        for (uint i = 0; i < sharedOwners_.length; i++) {
            _updateSharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]);
        }

        uint256 sharedOwnersPoints = calcSharedOwnersAvailablePoints(initialSupply);
        _distributionRounds[0] = DistributionRound({
            availablePoints: initialSupply,
            sharedOwnersAvailablePoints: sharedOwnersPoints,
            totalKarma: initialKarma_
        });

        emit AdvanceRound(0, initialSupply, sharedOwnersPoints);
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature) external {
        require(karma > 0, "Distributions: karma should be > 0");
        require(_claimableRounds[account] <= round, "Distributions: this rounds points are already claimed");
        require(round <= lastRound, "Distributions: too early to claim this round");
        uint256 mc = minClaimableRound();
        require(round >= mc, "Distributions: too late to claim this round");

        address signedBy = verifySignature(account, round, karma, signature);
        require(signedBy == karmaSource || (prevKarmaSource != address(0) && signedBy == prevKarmaSource), "Distributions: claim is not signed by the karma source");

        DistributionRound memory dr = _distributionRounds[round];
        require(dr.availablePoints > 0, "Distributions: no points to claim in this round");
        require(dr.totalKarma > 0, "Distributions: this round has no karma");
        uint256 userPoints = dr.availablePoints
            .sub(dr.sharedOwnersAvailablePoints)
            .mul(karma)
            .div(dr.totalKarma);
        require(userPoints > 0, "Distributions: user karma is too low to claim points");
        _prevClaimed = _prevClaimed.add(userPoints);
        _claimableRounds[account] = round.add(1);
        emit ClaimPoints(round, account, karma, userPoints);
        ISubredditPoints(subredditPoints).mint(address(this), account, userPoints, "", "");
    }

    // corresponding _distributionRounds mappings are added with
    //  + every next distribution supply is `previous - decay` and stored in nextSupply
    //  + distributed 50% of burned points in a previous round
    // rounds are removed if they are not claimable anymore
    function advanceToRound(uint256 round, uint256 totalKarma) external {
        require((round > lastRound) && (round < lastRound + MAX_SKIP_ROUNDS), "Distributions: round should be > lastRound and < lastRound + MAX_SKIP_ROUNDS");
        require(totalKarma > 0, "Distributions: totalKarma should be > 0");
        require(_msgSender() == karmaSource, "Distributions: only karma source can advance rounds");
        uint256 mc = minClaimableRound();

        if (mc >= (round - lastRound)) {
            for (uint256 i = mc - (round - lastRound); i < mc; i++) {
                delete(_distributionRounds[i]);
            }
        }

        uint256 ts = IERC20Compat(subredditPoints).totalSupply();
        uint256 prevClaimedCopy = _prevClaimed;

        // normally this loop should complete in 1 cycle
        // we move backwards from last to previous rounds
        for (uint256 i = round; i >= (lastRound + 1) && i >= mc; i--) {
            uint256 roundPoints = nextSupply;

            // reintroduce 50 % of previously burned tokens
            uint256 ps = _prevRoundSupply.add(_prevClaimed);
            if (ps > ts) {
                roundPoints = roundPoints.add(ps.sub(ts).div(2));
            }

            // if there is more than 1 cycle, all burned will be reintroduced into the last round
            // the loop is not stopped due to it may switch to halving for a previous rounds
            _prevRoundSupply = ts;
            _prevClaimed = 0;

            if (nextSupply > 0 && supplyDecayPercent > 0) {
                nextSupply = nextSupply.sub(nextSupply.mul(supplyDecayPercent).div(PERCENT_PRECISION));
            }

            uint256 sharedOwnersPoints = 0;
            if (roundPoints > 0) {
                sharedOwnersPoints = calcSharedOwnersAvailablePoints(roundPoints);
                _distributionRounds[i] = DistributionRound({
                    availablePoints: roundPoints,
                    sharedOwnersAvailablePoints: sharedOwnersPoints,
                    totalKarma: 0
                });
            }

            emit AdvanceRound(i, roundPoints, sharedOwnersPoints);
        }

        lastRound = round;
        _prevRoundSupply = ts;
        _prevClaimed = 0;

        DistributionRound storage dc = _distributionRounds[round];
        dc.totalKarma = totalKarma;

        // distribute shared cut, but no more than it was claimed by users
        // this protects from exceeding total amount by increasing percentage between rounds
        if (dc.sharedOwnersAvailablePoints > 0 && prevClaimedCopy > 0) {
            uint256 totalSharedPercent;
            for (uint256 i = 0; i < sharedOwners.length; i++) {
                totalSharedPercent = totalSharedPercent.add(sharedOwners[i].percent);
            }

            uint256 claimedPlusShared = prevClaimedCopy
                .mul(PERCENT_PRECISION)
                .div(PERCENT_PRECISION.sub(totalSharedPercent));

            uint256 sharedLeft = claimedPlusShared.sub(prevClaimedCopy);

            for (uint256 i = 0; i < sharedOwners.length && sharedLeft > 0; i++) {
                uint256 ownerPoints = claimedPlusShared.mul(sharedOwners[i].percent).div(PERCENT_PRECISION);
                if (ownerPoints > 0 && ownerPoints <= sharedLeft) {
                    ISubredditPoints(subredditPoints).mint(address(this), sharedOwners[i].account, ownerPoints, "", "");
                    sharedLeft = sharedLeft.sub(ownerPoints);
                }
            }
        }
    }

    function totalSharedOwners() external view returns (uint256) {
        return sharedOwners.length;
    }

    function updateSupplyDecayPercent(uint256 _supplyDecayPercent) public onlyOwner {
        require(_supplyDecayPercent < PERCENT_PRECISION, "Distributions: supplyDecayPercent should be < PERCENT_PRECISION");
        supplyDecayPercent = _supplyDecayPercent;
        emit SupplyDecayPercentUpdated(_supplyDecayPercent);
    }

    function updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) public onlyOwner {
        roundsBeforeExpiration = _roundsBeforeExpiration;
        emit RoundsBeforeExpirationUpdated(_roundsBeforeExpiration);
    }

    function minClaimableRound() public view returns (uint256) {
        if (lastRound >= roundsBeforeExpiration) {
            return lastRound.sub(roundsBeforeExpiration);
        }
        return 0;
    }

    function verifySignature(address account, uint256 round, uint256 karma, bytes memory signature)
        private view returns (address) {

        bytes32 hash = keccak256(abi.encode(_subredditLowerCase, uint256(round), account, karma));
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(prefixedHash, signature);
    }

    function calcSharedOwnersAvailablePoints(uint256 points) private view returns (uint256) {
        uint256 r;
        for (uint256 i = 0; i < sharedOwners.length; i++) {
            r = r.add(calcSharedPoints(points, sharedOwners[i]));
        }
        return r;
    }

    function calcSharedPoints(uint256 points, SharedOwner memory sharedOwner) private pure returns (uint256) {
        return points
            .mul(sharedOwner.percent)
            .div(PERCENT_PRECISION);
    }

    function updateKarmaSource(address _karmaSource) external onlyOwner {
        require(_karmaSource != address(0), "Distributions: karma source should not be 0");
        prevKarmaSource = karmaSource;
        karmaSource = _karmaSource;
        emit KarmaSourceUpdated(_karmaSource, prevKarmaSource);
    }

    function updateGSNApprover(address gsnApprover) external onlyOwner {
        updateSigner(gsnApprover);
    }

    // shared owners get their points 1 round later within advancement
    // increasing total shared percentage can lead to some of the owners not receiving their cut within a next round
    function updateSharedOwner(address account, uint256 percent) external onlyOwner {
        _updateSharedOwner(account, percent);
    }

    function _updateSharedOwner(address account, uint256 percent) internal {
        require(percent < PERCENT_PRECISION, "Distributions: shared owners percent should be < percentPrecision");
        require(percent > 0 && sharedOwners.length < MAX_SHARED_OWNERS, "Distributions: shared owners limit reached, see MAX_SHARED_OWNERS");

        bool updated = false;

        for (uint256 i = 0; i < sharedOwners.length; i++) {
            SharedOwner memory so = sharedOwners[i];
            if (so.account == account) {
                if (percent == 0) {
                    if (i != (sharedOwners.length - 1)) { // if it's not last element, replace it from the tail
                        sharedOwners[i] = sharedOwners[sharedOwners.length-1];
                    }
                    // remove tail
                    sharedOwners.length = sharedOwners.length - 1;
                } else {
                    sharedOwners[i].percent = percent;
                }
                updated = true;
            }
        }

        if (!updated) {
            if (percent == 0) {
                return;
            }
            sharedOwners.push(SharedOwner(account, percent));
        }

        checkSharedPercentage();
        // allow to update sharedOwnersAvailablePoints for a rounds which aren't claimed yet
        DistributionRound storage dr = _distributionRounds[lastRound];
        if (_prevClaimed == 0 && dr.availablePoints > 0) {
            dr.sharedOwnersAvailablePoints = calcSharedOwnersAvailablePoints(dr.availablePoints);
        }
        emit SharedOwnerUpdated(_msgSender(), account, percent);
    }

    function checkSharedPercentage() private view {
        uint256 total;
        for (uint256 i = 0; i < sharedOwners.length; i++) {
            total = sharedOwners[i].percent.add(total);
        }
        require(total < PERCENT_PRECISION, "Distributions: can't share all 100% of points");
    }

    function percentPrecision() external pure returns (uint256) {
        return PERCENT_PRECISION;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((int8(bStr[i]) >= 65) && (int8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(int8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function claimableRoundOf(address account) public view returns (uint256) {
        uint256 mc = minClaimableRound();
        if (mc > _claimableRounds[account]) {
            return mc;
        }

        return _claimableRounds[account];
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./Frozen.sol";
import "./DistributionsCompat.sol";

/*
    Distribution that is frozen (while exporting/migrating) compatible with L1/Rinkeby and older OZ libraries (2.x)
*/

contract DistributionsFrozenCompat is DistributionsCompat, Frozen {
    function initialize(
        address owner_,
        address subredditPoints_,                    // ISubredditPoints + IERC20 token contract address
        address karmaSource_,                        // Karma source provider address
        address gsnApprover_,                        // GSN approver address

        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 initialKarma_,
        uint256 roundsBeforeExpiration_,              // how many rounds are passed before claiming is possible
        uint256 supplyDecayPercent_,                  // defines percentage of next rounds' supply from the current
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_           // index of percentages must correspond to _sharedOwners array
    ) external frozen {
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature) external frozen {
    }

    function advanceToRound(uint256 round, uint256 totalKarma) external frozen {
    }

    function totalSharedOwners() external view returns (uint256) {
        return sharedOwners.length;
    }

    function updateSupplyDecayPercent(uint256 _supplyDecayPercent) public frozen {
    }

    function updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) public frozen {
    }

    function minClaimableRound() public view returns (uint256) {
        if (lastRound >= roundsBeforeExpiration) {
            return lastRound - roundsBeforeExpiration;
        }
        return 0;
    }

    function updateKarmaSource(address _karmaSource) external frozen {
    }

    function updateGSNApprover(address gsnApprover) external onlyOwner {
        updateSigner(gsnApprover);
    }

    function updateSharedOwner(address account, uint256 percent) external frozen {
    }


    function percentPrecision() external pure returns (uint256) {
        return PERCENT_PRECISION;
    }

    function prevRoundSupply() external view returns (uint256) {
        return _prevRoundSupply;
    }

    function prevClaimed() external view returns (uint256) {
        return _prevClaimed;
    }

    function roundAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].availablePoints;
    }

    function roundSharedOwnersAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].sharedOwnersAvailablePoints;
    }

    function roundTotalKarma(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].totalKarma;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.6.0;

import "./DistributionsCompat.sol";

/*
    Distribution with debug function to mint points
*/

contract DistributionsDebugCompat is DistributionsCompat {
    function generateDebugPoints(address account, uint256 round, uint256 amount) external {
        ISubredditPoints(subredditPoints).mint(address(this), account, amount, "", "");
        _claimableRounds[account] = round;
        if (lastRound < round) {
            lastRound = round;
        }
    }
}

