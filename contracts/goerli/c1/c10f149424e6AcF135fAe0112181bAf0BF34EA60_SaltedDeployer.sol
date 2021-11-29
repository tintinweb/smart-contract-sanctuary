// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "@brinkninja/core/contracts/Deployers/SaltedDeployer.sol";
import "@brinkninja/core/contracts/Interfaces/ISingletonFactory.sol";

contract DeploySaltedDeployer {
  constructor () {
    address deployedAddress = ISingletonFactory(0xce0042B868300000d44A59004Da54A005ffdcf9f).deploy(
      type(SaltedDeployer).creationCode, hex"841eb53dae7d7c32f92a7e2a07956fb3b9b1532166bc47aa8f091f49bcaa9ff5"
    );
    require(deployedAddress != address(0), "NOT_DEPLOYED");
    selfdestruct(payable(msg.sender));
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Interfaces/ISingletonFactory.sol";

/// @title Deploys contracts using the canonical SingletonFactory and a hardcoded bytes32 salt. Includes custom events
/// and errors.
contract SaltedDeployer {
  /// @dev Emit when contract is deployed successfully
  event Deployed(address deployAddress);

  /// @dev Revert when SingletonFactory deploy returns 0 address
  error DeployFailed();

  /// @dev Revert when initCode is already deployed
  error DeploymentExists();

  /// @dev Salt used for salted deployments
  bytes32 constant SALT = 0x841eb53dae7d7c32f92a7e2a07956fb3b9b1532166bc47aa8f091f49bcaa9ff5;

  /// @dev Canonical SingletonFactory address
  /// @notice https://eips.ethereum.org/EIPS/eip-2470
  ISingletonFactory constant SINGLETON_FACTORY = ISingletonFactory(0xce0042B868300000d44A59004Da54A005ffdcf9f);

  /// @dev Computes the salted deploy address of contract with initCode
  /// @return deployAddress Address where the contract with initCode will be deployed
  function getDeployAddress (bytes memory initCode) public pure returns (address deployAddress) {
    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), address(SINGLETON_FACTORY), SALT, keccak256(initCode))
    );
    deployAddress = address(uint160(uint(hash)));
  }

  /// @dev Deploys the contract with initCode
  /// @param initCode The initCode to deploy
  function deploy(bytes memory initCode) external {
    if (_isContract(getDeployAddress(initCode))) {
      revert DeploymentExists();
    }
    address deployAddress = SINGLETON_FACTORY.deploy(initCode, SALT);
    if (deployAddress == address(0)) {
      revert DeployFailed();
    }
    emit Deployed(deployAddress);
  }

  function _isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in construction, since the code is only stored
    // at the end of the constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

interface ISingletonFactory {
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "@brinkninja/core/contracts/Account/Account.sol";
import "@brinkninja/core/contracts/Account/AccountFactory.sol";
import "@brinkninja/core/contracts/Batched/DeployAndCall.sol";
import "@brinkninja/core/contracts/Deployers/SaltedDeployer.sol";

import "@brinkninja/verifiers/contracts/External/CallExecutor.sol";
import "@brinkninja/verifiers/contracts/Verifiers/CancelVerifier.sol";
import "@brinkninja/verifiers/contracts/Verifiers/LimitSwapVerifier.sol";
import "@brinkninja/verifiers/contracts/Verifiers/TransferVerifier.sol";

abstract contract Imports { }

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "./EIP712SignerRecovery.sol";
import "./EIP1271Validator.sol";

/// @title Brink account core
/// @notice Deployed once and used by many proxy contracts as the implementation contract. External functions in this
/// contract are intended to be called by `delegatecall` from proxy contracts deployed by AccountFactory.
contract Account is EIP712SignerRecovery, EIP1271Validator {
  /// @dev Revert if signer of a transaction or EIP712 message signer is not the proxy owner
  /// @param signer The address that is not the owner
  error NotOwner(address signer);

  /// @dev Revert if EIP1271 hash and signature is invalid
  /// @param hash Hash of the data to be validated
  /// @param signature Signature byte array associated with hash
  error InvalidSignature(bytes32 hash, bytes signature);

  /// @dev Revert if the Account.sol implementation contract is called directly
  error NotDelegateCall();

  /// @dev Typehash for signed metaDelegateCall() messages
  bytes32 internal immutable META_DELEGATE_CALL_TYPEHASH;

  /// @dev Typehash for signed metaDelegateCall_EIP1271() messages
  bytes32 internal immutable META_DELEGATE_CALL_EIP1271_TYPEHASH;

  /// @dev Deployment address of the implementation Account.sol contract. Used to enforce onlyDelegateCallable.
  address internal immutable deploymentAddress = address(this);

  /// @dev Used by external functions to revert if they are called directly on the implementation Account.sol contract
  modifier onlyDelegateCallable() {
    if (address(this) == deploymentAddress) {
      revert NotDelegateCall();
    }
    _;
  }

  /// @dev Constructor sets immutable constants
  constructor() { 
    META_DELEGATE_CALL_TYPEHASH = keccak256("MetaDelegateCall(address to,bytes data)");
    META_DELEGATE_CALL_EIP1271_TYPEHASH = keccak256("MetaDelegateCall_EIP1271(address to,bytes data)");
  }

  /// @dev Makes a call to an external contract
  /// @dev Only executable directly by the proxy owner
  /// @param value Amount of wei to send with the call
  /// @param to Address of the external contract to call
  /// @param data Call data to execute
  function externalCall(uint256 value, address to, bytes memory data) external payable onlyDelegateCallable {
    if (proxyOwner() != msg.sender) {
      revert NotOwner(msg.sender);
    }

    assembly {
      let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Makes a delegatecall to an external contract
  /// @param to Address of the external contract to delegatecall
  /// @param data Call data to execute
  function delegateCall(address to, bytes memory data) external payable onlyDelegateCallable {
    if (proxyOwner() != msg.sender) {
      revert NotOwner(msg.sender);
    }

    assembly {
      let result := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Allows execution of a delegatecall with a valid signature from the proxyOwner. Uses EIP-712
  /// (https://github.com/ethereum/EIPs/pull/712) signer recovery.
  /// @param to Address of the external contract to delegatecall, signed by the proxyOwner
  /// @param data Call data to include in the delegatecall, signed by the proxyOwner
  /// @param signature Signature of the proxyOwner
  /// @param unsignedData Unsigned call data appended to the delegatecall
  /// @notice WARNING: The `to` contract is responsible for secure handling of the call provided in the encoded
  /// `callData`. If the proxyOwner signs a delegatecall to a malicious contract, this could result in total loss of
  /// their account.
  function metaDelegateCall(
    address to, bytes calldata data, bytes calldata signature, bytes calldata unsignedData
  ) external payable onlyDelegateCallable {
    address signer = _recoverSigner(
      keccak256(abi.encode(META_DELEGATE_CALL_TYPEHASH, to, keccak256(data))),
      signature
    );
    if (proxyOwner() != signer) {
      revert NotOwner(signer);
    }

    bytes memory callData = abi.encodePacked(data, unsignedData);

    assembly {
      let result := delegatecall(gas(), to, add(callData, 0x20), mload(callData), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Allows execution of a delegatecall if proxyOwner is a smart contract. Uses EIP-1271
  /// (https://eips.ethereum.org/EIPS/eip-1271) signer validation.
  /// @param to Address of the external contract to delegatecall, validated by the proxyOwner contract
  /// @param data Call data to include in the delegatecall, validated by the proxyOwner contract
  /// @param signature Signature that will be validated by the proxyOwner contract
  /// @param unsignedData Unsigned call data appended to the delegatecall
  /// @notice WARNING: The `to` contract is responsible for secure handling of the call provided in the encoded
  /// `callData`. If the proxyOwner contract validates a delegatecall to a malicious contract, this could result in
  /// total loss of the account.
  function metaDelegateCall_EIP1271(
    address to, bytes calldata data, bytes calldata signature, bytes calldata unsignedData
  ) external payable onlyDelegateCallable {
    bytes32 hash = keccak256(abi.encode(META_DELEGATE_CALL_EIP1271_TYPEHASH, to, keccak256(data)));
    if(!_isValidSignature(proxyOwner(), hash, signature)) {
      revert InvalidSignature(hash, signature);
    }

    bytes memory callData = abi.encodePacked(data, unsignedData);

    assembly {
      let result := delegatecall(gas(), to, add(callData, 0x20), mload(callData), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Returns the owner address for the proxy
  /// @return _proxyOwner The owner address for the proxy
  function proxyOwner() internal view returns (address _proxyOwner) {
    assembly {
      extcodecopy(address(), mload(0x40), 0x2d, 0x14)
      _proxyOwner := mload(sub(mload(0x40), 0x0c))
    }
  }

  receive() external payable { }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/// @title Brink account factory
/// @notice This is a factory contract used for deployment of Brink proxy accounts
contract AccountFactory {
  /// @dev Salt used for salted deployment of Proxy accounts
  bytes32 constant SALT = 0x841eb53dae7d7c32f92a7e2a07956fb3b9b1532166bc47aa8f091f49bcaa9ff5;

  /// @dev Deploys a Proxy account for the given owner
  /// @param owner Owner of the Proxy account
  /// @return account Address of the deployed Proxy account
  /// @notice This deploys a "minimal proxy" contract (https://eips.ethereum.org/EIPS/eip-1167) with the proxy owner
  /// address added to the deployed bytecode. The owner address can be read within a delegatecall by using `extcodecopy`
  function deployAccount(address owner) external returns (address account) {
    bytes memory initCode = abi.encodePacked(
      //  [*** constructor **][**** eip-1167 ****][******* implementation_address *******][********* eip-1167 *********]
      hex'3d604180600a3d3981f3363d3d373d3d3d363d7320462190079006816ce1b85664f6202873b4e4165af43d82803e903d91602b57fd5bf3',
      owner
    );
    assembly {
      account := create2(0, add(initCode, 0x20), mload(initCode), SALT)
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Account/AccountFactory.sol";

/// @title DeployAndCall
/// @notice This contract contains a function to batch account deploy and call into one transaction
contract DeployAndCall {
  /// @dev The AccountFactory to use for account deployments
  AccountFactory constant ACCOUNT_FACTORY = AccountFactory(0x0B71C16a71eB1aF834e78678529A6e7003f73C5c);

  /// @dev Deploys an account for the given owner and executes callData on the account
  /// @param owner Address of the account owner
  /// @param callData The call to execute on the account after deployment
  function deployAndCall(address owner, bytes memory callData) external payable {
    address account = ACCOUNT_FACTORY.deployAccount(owner);

    if (callData.length > 0) {
      assembly {
        let result := call(gas(), account, callvalue(), add(callData, 0x20), mload(callData), 0, 0)
        returndatacopy(0, 0, returndatasize())
        switch result
        case 0 {
          revert(0, returndatasize())
        }
        default {
          return(0, returndatasize())
        }
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 * @dev Used as a proxy for call execution to obscure msg.sender of the
 * caller. msg.sender will be the address of the CallExecutor contract.
 *
 * Instances of Proxy (user account contracts) use CallExecutor to execute
 * unsigned data calls without exposing themselves as msg.sender. Users can
 * sign messages that allow public unsigned data execution via CallExecutor
 * without allowing public calls to be executed directly from their Proxy
 * contract.
 *
 * This is implemented specifically for swap calls that allow unsigned data
 * execution. If unsigned data was executed directly from the Proxy contract,
 * an attacker could make a call that satisfies the swap required conditions
 * but also makes other malicious calls that rely on msg.sender. Forcing all
 * unsigned data execution to be done through a CallExecutor ensures that an
 * attacker cannot impersonate the users's account.
 *
 */
contract CallExecutor {

  /**
   * @dev A non-payable function that executes a call with `data` on the
   * contract address `to`
   *
   * Hardcoded 0 for call value
   */
  function proxyCall(address to, bytes memory data) public {
    // execute `data` on execution contract address `to`
    assembly {
      let result := call(gas(), to, 0, add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev A payable function that executes a call with `data` on the
   * contract address `to`
   *
   * Sets value for the call to `callvalue`, the amount of Eth provided with
   * the call
   */
  function proxyPayableCall(address to, bytes memory data) public payable {
    // execute `data` on execution contract address `to`
    assembly {
      let result := call(gas(), to, callvalue(), add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Libraries/Bit.sol";

/// @title Verifier for cancellation of messages signed with a bitmapIndex and bit
/// @notice Uses the Bit library to use the bit, which invalidates messages signed with the same bit
contract CancelVerifier {
  event Cancel (uint256 bitmapIndex, uint256 bit);

  /// @dev Cancels existing messages signed with bitmapIndex and bit
  /// @param bitmapIndex The bitmap index to use
  /// @param bit The bit to use
  function cancel(uint256 bitmapIndex, uint256 bit) external {
    Bit.useBit(bitmapIndex, bit);
    emit Cancel(bitmapIndex, bit);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../External/CallExecutor.sol";
import "../Libraries/Bit.sol";

/// @title Verifier for ERC20 limit swaps
/// @notice These functions should be executed by metaPartialSignedDelegateCall() on Brink account proxy contracts
contract LimitSwapVerifier {
  /// @dev Revert when limit swap is expired
  error Expired();

  /// @dev Revert when swap has not received enough of the output asset to be fulfilled
  error NotEnoughReceived(uint256 amountReceived);

  CallExecutor internal immutable CALL_EXECUTOR;

  constructor(CallExecutor callExecutor) {
    CALL_EXECUTOR = callExecutor;
  }

  /// @dev Executes an ERC20 to ERC20 limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap [signed]
  /// @param tokenInAmount Amount of tokenIn provided [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToToken(
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, IERC20 tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount,
    uint256 expiryBlock, address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }
  
    Bit.useBit(bitmapIndex, bit);

    uint256 tokenOutBalance = tokenOut.balanceOf(address(this));

    tokenIn.transfer(to, tokenInAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(address(this)) - tokenOutBalance;
    if (tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Executes an ETH to ERC20 limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param token The output token required to be received from the swap [signed]
  /// @param ethAmount Amount of ETH provided [signed]
  /// @param tokenAmount Amount of token required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function ethToToken(
    uint256 bitmapIndex, uint256 bit, IERC20 token, uint256 ethAmount, uint256 tokenAmount, uint256 expiryBlock,
    address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }

    Bit.useBit(bitmapIndex, bit);

    uint256 tokenBalance = token.balanceOf(address(this));

    CALL_EXECUTOR.proxyPayableCall{value: ethAmount}(to, data);

    uint256 tokenAmountReceived = token.balanceOf(address(this)) - tokenBalance;
    if (tokenAmountReceived < tokenAmount) {
      revert NotEnoughReceived(tokenAmountReceived);
    }
  }

  /// @dev Executes an ERC20 to ETH limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param token The input token provided for the swap [signed]
  /// @param tokenAmount Amount of tokenIn provided [signed]
  /// @param ethAmount Amount of ETH to receive [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToEth(
    uint256 bitmapIndex, uint256 bit, IERC20 token, uint256 tokenAmount, uint256 ethAmount, uint256 expiryBlock,
    address to, bytes calldata data
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }

    Bit.useBit(bitmapIndex, bit);
    
    uint256 ethBalance = address(this).balance;

    token.transfer(to, tokenAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 ethAmountReceived = address(this).balance - ethBalance;
    if (ethAmountReceived < ethAmount) {
      revert NotEnoughReceived(ethAmountReceived);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Libraries/Bit.sol";
import "../Libraries/TransferHelper.sol";

/// @title Verifier for ETH and ERC20 transfers
/// @notice These functions should be executed by metaDelegateCall() on Brink account proxy contracts
contract TransferVerifier {
  /// @dev Revert when transfer is expired
  error Expired();

  /// @dev Executes an ETH transfer with replay protection and expiry
  /// @notice This should be executed by metaDelegateCall() with the following signed params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot
  /// @param bit The value of the replay bit
  /// @param recipient The recipient of the transfer
  /// @param amount Amount of token to transfer
  /// @param expiryBlock The block when the transfer expires
  function ethTransfer(
    uint256 bitmapIndex, uint256 bit, address recipient, uint256 amount, uint256 expiryBlock
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }
    Bit.useBit(bitmapIndex, bit);
    TransferHelper.safeTransferETH(recipient, amount);
  }

  /// @dev Executes an ERC20 token transfer with replay protection and expiry
  /// @notice This should be executed by metaDelegateCall() with the following signed params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot
  /// @param bit The value of the replay bit
  /// @param token The token to transfer
  /// @param recipient The recipient of the transfer
  /// @param amount Amount of token to transfer
  /// @param expiryBlock The block when the transfer expires
  function tokenTransfer(
    uint256 bitmapIndex, uint256 bit, address token, address recipient, uint256 amount, uint256 expiryBlock
  )
    external
  {
    if (expiryBlock <= block.number) {
      revert Expired();
    }
    Bit.useBit(bitmapIndex, bit);
    TransferHelper.safeTransfer(token, recipient, amount);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "./ECDSA.sol";

/// @title Provides signer address recovery for EIP-712 signed messages
/// @notice https://github.com/ethereum/EIPs/pull/712
abstract contract EIP712SignerRecovery {
  /// @dev Recovers the signer address for an EIP-712 signed message
  /// @param dataHash Hash of the data included in the message
  /// @param signature An EIP-712 signature
  function _recoverSigner(bytes32 dataHash, bytes calldata signature) internal view returns (address) {
    // generate the hash for the signed message
    bytes32 messageHash = keccak256(abi.encodePacked(
      "\x19\x01",
      // hash the EIP712 domain separator
      keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("BrinkAccount"),
        keccak256("1"),
        block.chainid,
        address(this)
      )),
      dataHash
    ));

    // recover the signer address from the signed messageHash and return
    return ECDSA.recover(messageHash, signature);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Interfaces/IERC1271.sol";

/// @title Provides a validation check on a signer contract that implements EIP-1271
/// @notice https://github.com/ethereum/EIPs/issues/1271
abstract contract EIP1271Validator {

  bytes4 constant internal MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

  /**
   * @dev Should return whether the signature provided is valid for the provided hash
   * @param signer Address of a contract that implements EIP-1271
   * @param hash Hash of the data to be validated
   * @param signature Signature byte array associated with hash
   */ 
  function _isValidSignature(address signer, bytes32 hash, bytes calldata signature) internal view returns (bool) {
    return IERC1271(signer).isValidSignature(hash, signature) == MAGICVALUE;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

interface IERC1271 {
  function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/// @title Bit replay protection library
/// @notice Handles storage and loads for replay protection bits
/// @dev Solution adapted from https://github.com/PISAresearch/metamask-comp/blob/77fa8295c168ee0b6bf801cbedab797d6f8cfd5d/src/contracts/BitFlipMetaTransaction/README.md
/// @dev This is a gas optimized technique that stores up to 256 replay protection bits per bytes32 slot
library Bit {
  /// @dev Revert when bit provided is not valid
  error InvalidBit();

  /// @dev Revert when bit provided is used
  error BitUsed();

  /// @dev Initial pointer for bitmap storage ptr computation
  /// @notice This is the uint256 representation of keccak("bmp")
  uint256 constant INITIAL_BMP_PTR = 
  48874093989078844336340380824760280705349075126087700760297816282162649029611;

  /// @dev Adds a bit to the uint256 bitmap at bitmapIndex
  /// @dev Value of bit cannot be zero and must represent a single bit
  /// @param bitmapIndex The index of the uint256 bitmap
  /// @param bit The value of the bit within the uint256 bitmap
  function useBit(uint256 bitmapIndex, uint256 bit) internal {
    if (!validBit(bit)) {
      revert InvalidBit();
    }
    bytes32 ptr = bitmapPtr(bitmapIndex);
    uint256 bitmap = loadUint(ptr);
    if (bitmap & bit != 0) {
      revert BitUsed();
    }
    uint256 updatedBitmap = bitmap | bit;
    assembly { sstore(ptr, updatedBitmap) }
  }

  /// @dev Check that a bit is valid
  /// @param bit The bit to check
  /// @return isValid True if bit is greater than zero and represents a single bit
  function validBit(uint256 bit) internal pure returns (bool isValid) {
    assembly {
      // equivalent to: isValid = (bit > 0 && bit & bit-1) == 0;
      isValid := and(
        iszero(iszero(bit)), 
        iszero(and(bit, sub(bit, 1)))
      )
    } 
  }

  /// @dev Get a bitmap storage pointer
  /// @return The bytes32 pointer to the storage location of the uint256 bitmap at bitmapIndex
  function bitmapPtr (uint256 bitmapIndex) internal pure returns (bytes32) {
    return bytes32(INITIAL_BMP_PTR + bitmapIndex);
  }

  /// @dev Returns the uint256 value at storage location ptr
  /// @param ptr The storage location pointer
  /// @return val The uint256 value at storage location ptr
  function loadUint(bytes32 ptr) internal view returns (uint256 val) {
    assembly { val := sload(ptr) }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'APPROVE_FAILED');
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM_FAILED');
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }
}