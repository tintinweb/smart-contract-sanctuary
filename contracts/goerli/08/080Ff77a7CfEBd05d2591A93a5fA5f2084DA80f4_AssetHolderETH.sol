// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../vendor/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./AssetHolder.sol";

/**
 * @title The Perun AssetHolderETH
 * @notice AssetHolderETH is a concrete implementation of the abstract
 * AssetHolder which holds ETH.
 */
contract AssetHolderETH is AssetHolder {
    using SafeMath for uint256;

    /**
     * @notice Sets the adjudicator contract by calling the constructor of the
     * base asset holder contract.
     * @param _adjudicator Address of the adjudicator contract.
     */
    constructor(address _adjudicator) AssetHolder(_adjudicator) 
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice Should not be called directly but only by the parent AssetHolder.
     * @dev Checks that `msg.value` is equal to `amount`.
     */
    function depositCheck(bytes32, uint256 amount) internal override view {
        require(msg.value == amount, "wrong amount of ETH for deposit");
    }

    /**
     * @notice Should not be called directly but only by the parent AssetHolder.
     * @dev Withdraws ethereum for channel participant authorization.participant
     * to authorization.receiver.
     * @param authorization Withdrawal Authorization to authorize token transer
     * from a channel participant to an on-chain receiver.
     */
    function withdrawEnact(WithdrawalAuth calldata authorization, bytes calldata) internal override {
        authorization.receiver.transfer(authorization.amount);
    }
}

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

// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../vendor/openzeppelin-contracts/contracts/math/SafeMath.sol";
import "./Sig.sol";

/**
 * @title The Perun AssetHolder
 * @notice AssetHolder is an abstract contract that holds the funds for a
 * Perun state channel.
 */
abstract contract AssetHolder {
    using SafeMath for uint256;

    /**
     * @dev WithdrawalAuth authorizes an on-chain public key to withdraw from an ephemeral key.
     */
    struct WithdrawalAuth {
        bytes32 channelID;
        address participant; // The account used to sign the authorization which is debited.
        address payable receiver; // The receiver of the authorization.
        uint256 amount; // The amount that can be withdrawn.
    }

    event OutcomeSet(bytes32 indexed channelID);
    event Deposited(bytes32 indexed fundingID, uint256 amount);
    event Withdrawn(bytes32 indexed fundingID, uint256 amount, address receiver);

    /**
     * @notice This mapping stores the balances of participants to their fundingID.
     * @dev Mapping H(channelID||participant) => money
     */
    mapping(bytes32 => uint256) public holdings;

    /**
     * @notice This mapping stores whether a channel was already settled.
     * @dev Mapping channelID => settled
     */
    mapping(bytes32 => bool) public settled;

    /**
     * @notice Address of the adjudicator contract that can call setOutcome.
     * @dev Set by the constructor.
     */
    address public adjudicator;

    /**
     * @notice The onlyAdjudicator modifier specifies functions that can only be called from the adjudicator contract.
     */
    modifier onlyAdjudicator {
        require(msg.sender == adjudicator, "can only be called by the adjudicator"); // solhint-disable-line reason-string
        _;
    }

    /**
     * @notice Sets the adjudicator contract that is able to call setOutcome on this contract.
     * @param _adjudicator Address of the adjudicator contract.
     */
    constructor(address _adjudicator) {
        adjudicator = _adjudicator;
    }

    /**
     * @notice Sets the final outcome of a channel. Can only be called by the adjudicator.
     * @dev This method should not be overwritten by the implementing contract.
     * @param channelID ID of the channel that should be disbursed.
     * @param parts Array of participants of the channel.
     * @param newBals New Balances after execution of the channel.
     */
    function setOutcome(
        bytes32 channelID,
        address[] calldata parts,
        uint256[] calldata newBals)
    external onlyAdjudicator {
        require(parts.length == newBals.length, "participants length should equal balances"); // solhint-disable-line reason-string
        require(settled[channelID] == false, "trying to set already settled channel"); // solhint-disable-line reason-string

        // The channelID itself might already be funded
        uint256 sumHeld = holdings[channelID];
        holdings[channelID] = 0;
        uint256 sumOutcome = 0;

        bytes32[] memory fundingIDs = new bytes32[](parts.length);
        for (uint256 i = 0; i < parts.length; i++) {
            bytes32 id = calcFundingID(channelID, parts[i]);
            // Save calculated ids to save gas.
            fundingIDs[i] = id;
            // Compute old balances.
            sumHeld = sumHeld.add(holdings[id]);
            // Compute new balances.
            sumOutcome = sumOutcome.add(newBals[i]);
        }

        // We allow overfunding channels, who overfunds looses their funds.
        if (sumHeld >= sumOutcome) {
            for (uint256 i = 0; i < parts.length; i++) {
                holdings[fundingIDs[i]] = newBals[i];
            }
        }
        settled[channelID] = true;
        emit OutcomeSet(channelID);
    }

    /**
     * @notice Function that is used to fund a channel.
     * @dev Generic function which uses the virtual functions `depositCheck` and
     * `depositEnact` to execute the user specific code.
     * Requires that:
     *  - `depositCheck` does not revert
     *  - `depositEnact` does not revert
     * Increases the holdings for the participant.
     * Emits a `Deposited` event upon success.
     * @param fundingID Unique identifier for a participant in a channel.
     * Calculated as the hash of the channel id and the participant address.
     * @param amount Amount of money that should be deposited.
     */
    function deposit(bytes32 fundingID, uint256 amount) external payable {
        depositCheck(fundingID, amount);
        holdings[fundingID] = holdings[fundingID].add(amount);
        depositEnact(fundingID, amount);       
        emit Deposited(fundingID, amount);
    }

    /**
     * @notice Sends money from authorization.participant to authorization.receiver.
     * @dev Generic function which uses the virtual functions `withdrawCheck` and
     * `withdrawEnact` to execute the user specific code.
     * Requires that:
     *  - Channel is settled
     *  - Signature is valid
     *  - Enough holdings are available
     *  - `withdrawCheck` does not revert
     *  - `withdrawEnact` does not revert
     * Decreases the holdings for the participant.
     * Emits a `Withdrawn` event upon success.
     * @param authorization WithdrawalAuth that specifies which account receives
     * what amounf of asset from which channel participant.
     * @param signature Signature on the withdrawal authorization.
     */
    function withdraw(WithdrawalAuth calldata authorization, bytes calldata signature) external {
        require(settled[authorization.channelID], "channel not settled");
        require(Sig.verify(abi.encode(authorization), signature, authorization.participant), "signature verification failed");
        bytes32 id = calcFundingID(authorization.channelID, authorization.participant);
        require(holdings[id] >= authorization.amount, "insufficient ETH for withdrawal");
        withdrawCheck(authorization, signature);
        holdings[id] = holdings[id].sub(authorization.amount);
        withdrawEnact(authorization, signature);
        emit Withdrawn(id, authorization.amount, authorization.receiver);
    }

    /**
     * @notice Checks a deposit for validity and reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `deposit` before `depositEnact`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function depositCheck(bytes32 fundingID, uint256 amount) internal view virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Enacts a deposit or reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `deposit` after `depositCheck`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function depositEnact(bytes32 fundingID, uint256 amount) internal virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Checks a withdrawal for validity and reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `withdraw` before `withdrawEnact`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function withdrawCheck(WithdrawalAuth calldata authorization, bytes calldata signature) internal view virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Enacts a withdrawal or reverts otherwise.
     * @dev Should be overridden by all contracts that inherit it since it is
     * called by `withdraw` after `withdrawCheck`.
     * This function is empty by default and the overrider does not need to
     * call it via `super`.
     */
    function withdrawEnact(WithdrawalAuth calldata authorization, bytes calldata signature) internal virtual
    {} // solhint-disable no-empty-blocks

    /**
     * @notice Internal helper function that calculates the fundingID.
     * @param channelID ID of the channel.
     * @param participant Address of a participant in the channel.
     * @return The funding ID, an identifier used for indexing.
     */
    function calcFundingID(bytes32 channelID, address participant) internal pure returns (bytes32) {
        return keccak256(abi.encode(channelID, participant));
    }
}

// Copyright 2019 - See NOTICE file for copyright holders.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.0;

import "../vendor/openzeppelin-contracts/contracts/cryptography/ECDSA.sol";

// Sig is a library to verify signatures.
library Sig {
    // Verify verifies whether a piece of data was signed correctly.
    function verify(bytes memory data, bytes memory signature, address signer) internal pure returns (bool) {
        bytes32 prefixedHash = ECDSA.toEthSignedMessageHash(keccak256(data));
        address recoveredAddr = ECDSA.recover(prefixedHash, signature);
        return recoveredAddr == signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
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
            revert("ECDSA: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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
  },
  "libraries": {}
}