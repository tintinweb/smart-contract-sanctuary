// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { VerifyingKey, SnarkProof, Commitment, SNARK_SCALAR_FIELD, CIRCUIT_OUTPUTS } from "./Globals.sol";

import { Verifier } from "./Verifier.sol";
import { Commitments } from "./Commitments.sol";
import { TokenWhitelist } from "./TokenWhitelist.sol";

/**
 * @title Railgun Logic
 * @author Railgun Contributors
 * @notice Functions to interact with the railgun contract
 * @dev Wallets for Railgun will only need to interact with functions specified in this contract.
 * This contract is written to be run behind a ERC1967-like proxy. Upon deployment of proxy the _data parameter should
 * call the initializeRailgunLogic function.
 */

contract RailgunLogic is Initializable, OwnableUpgradeable, Commitments, TokenWhitelist, Verifier {
  using SafeERC20 for IERC20;

  uint256 private constant MAX_DEPOSIT_WITHDRAW = 2**120;

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Treasury variables
  address payable public treasury; // Treasury contract
  uint256 private constant BASIS_POINTS = 10000; // Number of basis points that equal 100%
  // % fee in 100ths of a %. 100 = 1%.
  uint256 public depositFee;
  uint256 public withdrawFee;

  // Flat fee in wei that applies to all transactions
  uint256 public transferFee;

  // Treasury events
  event TreasuryChange(address treasury);
  event FeeChange(uint256 depositFee, uint256 withdrawFee, uint256 transferFee);

  // Transaction events
  event Nullifier(uint256 indexed nullifier);

  /**
   * @notice Initialize Railgun contract
   * @dev OpenZeppelin initializer ensures this can only be called once
   * This function also calls initializers on inherited contracts
   * @param _tokenWhitelist - Initial token whitelist to use
   * @param _treasury - address to send usage fees to
   * @param _depositFee - Deposit fee
   * @param _withdrawFee - Withdraw fee
   * @param _transferFee - Flat fee that applies to all transactions
   * @param _owner - governance contract
   */

  function initializeRailgunLogic(
    VerifyingKey calldata _vKeySmall,
    VerifyingKey calldata _vKeyLarge,
    address[] calldata _tokenWhitelist,
    address payable _treasury,
    uint256 _depositFee,
    uint256 _withdrawFee,
    uint256 _transferFee,
    address _owner
  ) external initializer {
    // Call initializers
    OwnableUpgradeable.__Ownable_init();
    Commitments.initializeCommitments();
    TokenWhitelist.initializeTokenWhitelist(_tokenWhitelist);
    Verifier.initializeVerifier(_vKeySmall, _vKeyLarge);

    // Set treasury and fee
    changeTreasury(_treasury);
    changeFee(_depositFee, _withdrawFee, _transferFee);

    // Change Owner
    OwnableUpgradeable.transferOwnership(_owner);
  }

  /**
   * @notice Change treasury address, only callable by owner (governance contract)
   * @dev This will change the address of the contract we're sending the fees to in the future
   * it won't transfer tokens already in the treasury 
   * @param _treasury - Address of new treasury contract
   */

  function changeTreasury(address payable _treasury) public onlyOwner {
    // Do nothing if the new treasury address is same as the old
    if (treasury != _treasury) {
      // Change treasury
      treasury = _treasury;

      // Emit treasury change event
      emit TreasuryChange(_treasury);
    }
  }

  /**
   * @notice Change fee rate for future transactions
   * @param _depositFee - Deposit fee
   * @param _withdrawFee - Withdraw fee
   * @param _transferFee - Flat fee that applies to all transactions
   */

  function changeFee(
    uint256 _depositFee,
    uint256 _withdrawFee,
    uint256 _transferFee
  ) public onlyOwner {
    if (
      _depositFee != depositFee
      || _withdrawFee != withdrawFee
      || _transferFee != transferFee
    ) {
      // Change fee
      depositFee = _depositFee;
      withdrawFee = _withdrawFee;
      transferFee = _transferFee;

      // Emit fee change event
      emit FeeChange(_depositFee, _withdrawFee, _transferFee);
    }
  }

  /**
   * @notice Perform a transaction in the Railgun system
   * @dev This function will perform any combination of deposit, internal transfer
   * and withdraw actions.
   * @param _proof - snark proof
   * @param _adaptIDcontract - contract address to this proof to (ignored if set to 0)
   * @param _adaptIDparameters - hash of the contract parameters (only used to verify proof, this is verified by the
   * calling contract)
   * @param _depositAmount - deposit amount
   * @param _withdrawAmount - withdraw amount
   * @param _tokenField - token to use if deposit/withdraw is requested
   * @param _outputEthAddress - eth address to use if withdraw is requested
   * @param _treeNumber - merkle tree number
   * @param _merkleRoot - merkle root to verify against
   * @param _nullifiers - nullifiers of commitments
   * @param _commitmentsOut - output commitments
   */

  function transact(
    // Proof
    SnarkProof calldata _proof,
    // Shared
    address _adaptIDcontract,
    uint256 _adaptIDparameters,
    uint256 _depositAmount,
    uint256 _withdrawAmount,
    address _tokenField,
    address _outputEthAddress,
    // Join
    uint256 _treeNumber,
    uint256 _merkleRoot,
    uint256[] calldata _nullifiers,
    // Split
    Commitment[CIRCUIT_OUTPUTS] calldata _commitmentsOut
  ) external payable {
    // Check treasury fee is paid
    require(msg.value >= transferFee, "RailgunLogic: Fee not paid");

    // Transfer to treasury
    // If the treasury contract fails (eg. with revert()) the tx or consumes more than 2300 gas railgun transactions will fail
    // If this is ever the case, changeTreasury() will neeed to be called to change to a good contract
    treasury.transfer(msg.value);

    // If _adaptIDcontract is not zero check that it matches the caller
    require(_adaptIDcontract == address (0) || _adaptIDcontract == msg.sender, "AdaptID doesn't match caller contract");

    // Check merkle root is valid
    require(Commitments.rootHistory[_treeNumber][_merkleRoot], "RailgunLogic: Invalid Merkle Root");

    // Check depositAmount and withdrawAmount are below max allowed value
    require(_depositAmount < MAX_DEPOSIT_WITHDRAW, "RailgunLogic: depositAmount too high");
    require(_withdrawAmount < MAX_DEPOSIT_WITHDRAW, "RailgunLogic: withdrawAmount too high");

    // If deposit amount is not 0, token should be on whitelist
    // address(0) is wildcard (disables whitelist)
    require(
      _depositAmount == 0 ||
      TokenWhitelist.tokenWhitelist[_tokenField] ||
      TokenWhitelist.tokenWhitelist[address(0)],
      "RailgunLogic: Token isn't whitelisted for deposit"
    );

    // Check nullifiers haven't been seen before, this check will also fail if duplicate nullifiers are found in the same transaction
    for (uint i = 0; i < _nullifiers.length; i++) {
      uint256 nullifier = _nullifiers[i];

      require(!Commitments.nullifiers[nullifier], "RailgunLogic: Nullifier already seen");

      // Push to seen nullifiers
      Commitments.nullifiers[nullifier] = true;

      // Emit event
      emit Nullifier(nullifier);
    }

    // Verify proof
    require(
      Verifier.verifyProof(
        // Proof
        _proof,
        // Shared
        _adaptIDcontract,
        _adaptIDparameters,
        _depositAmount,
        _withdrawAmount,
        _tokenField,
        _outputEthAddress,
        // Join
        _treeNumber,
        _merkleRoot,
        _nullifiers,
        // Split
        _commitmentsOut
      ),
      "RailgunLogic: Invalid SNARK proof"
    );

    // Add commitments to accumulator
    Commitments.addCommitments(_commitmentsOut);

    IERC20 token = IERC20(_tokenField);

    // Deposit tokens if required
    // Fee is on top of deposit
    if (_depositAmount > 0) {
      // Calculate fee
      uint256 feeAmount = _depositAmount * depositFee / BASIS_POINTS;

      // Use OpenZeppelin safetransfer to revert on failure - https://github.com/ethereum/solidity/issues/4116
      // Transfer deposit
      token.safeTransferFrom(msg.sender, address(this), _depositAmount);

      // Transfer fee
      token.safeTransferFrom(msg.sender, treasury, feeAmount);
    }

    // Withdraw tokens if required
    // Fee is subtracted from withdraw
    if (_withdrawAmount > 0) {
      // Calculate fee
      uint256 feeAmount = _withdrawAmount * withdrawFee / BASIS_POINTS;

      // Use OpenZeppelin safetransfer to revert on failure - https://github.com/ethereum/solidity/issues/4116
      // Transfer withdraw
      token.safeTransfer(_outputEthAddress, _withdrawAmount - feeAmount);

      // Transfer fee
      token.safeTransfer(treasury, feeAmount);
    }
  }

  /**
   * @notice Deposits requested amount and token, creates a commitment hash from supplied values and adds to tree
   * @dev This is for DeFi integrations where the resulting number of tokens to be added
   * can't be known in advance (eg. AMM trade where transaction ordering could cause toekn amounts to change)
   * @param _pubkey - pubkey of commitment
   * @param _random - randomness field of commitment
   * @param _amount - amount of commitment
   * @param _tokenField - token ID of commitment
   */

  function generateDeposit(
    uint256[2] calldata _pubkey,
    uint256 _random,
    uint256 _amount,
    address _tokenField
  ) external payable {
    // Check treasury fee is paid
    require(msg.value >= transferFee, "RailgunLogic: Fee not paid");

    // Transfer to treasury
    // If the treasury contract fails (eg. with revert()) the tx or consumes more than 2300 gas railgun transactions will fail
    // If this is ever the case, changeTreasury() will neeed to be called to change to a good contract
    treasury.transfer(msg.value);

    // Check deposit amount is not 0
    require(_amount > 0, "RailgunLogic: Cannot deposit 0 tokens");

    // Check token is on the whitelist
    // address(0) is wildcard (disables whitelist)
    require(
      TokenWhitelist.tokenWhitelist[_tokenField] ||
      TokenWhitelist.tokenWhitelist[address(0)],
      "RailgunLogic: Token isn't whitelisted for deposit"
    );

    // Check deposit amount isn't greater than max deposit amount
    require(_amount < MAX_DEPOSIT_WITHDRAW, "RailgunLogic: depositAmount too high");

    // Check _random is in snark scalar field
    require(_random < SNARK_SCALAR_FIELD, "RailgunLogic: random out of range");

    // Check pubkey points are in snark scalar field
    require(_pubkey[0] < SNARK_SCALAR_FIELD, "RailgunLogic: pubkey[0] out of range");
    require(_pubkey[1] < SNARK_SCALAR_FIELD, "RailgunLogic: pubkey[1] out of range");

    // Calculate fee
    // Fee is subtracted from deposit
    uint256 feeAmount = _amount * depositFee / BASIS_POINTS;
    uint256 depositAmount = _amount - feeAmount;

    // Generate and add commmitment
    Commitments.addGeneratedCommitment(_pubkey, _random, depositAmount, _tokenField);

    IERC20 token = IERC20(_tokenField);

    // Use OpenZeppelin safetransfer to revert on failure - https://github.com/ethereum/solidity/issues/4116
    token.safeTransferFrom(msg.sender, address(this), depositAmount);

    // Transfer fee
    token.safeTransferFrom(msg.sender, treasury, feeAmount);
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// Constants
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint256 constant CIRCUIT_OUTPUTS = 3;
uint256 constant CIPHERTEXT_WORDS = 6;

// Commitment hash and ciphertext
struct Commitment {
  uint256 hash;
  uint256[CIPHERTEXT_WORDS] ciphertext; // Ciphertext order: iv, recipient pubkey (2 x uint256), random, amount, token
  uint256[2] senderPubKey; // Ephemeral one time use
}

struct G1Point {
  uint256 x;
  uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
  uint256[2] x;
  uint256[2] y;
}

// Verification key for SNARK
struct VerifyingKey {
  G1Point alpha1;
  G2Point beta2;
  G2Point gamma2;
  G2Point delta2;
  G1Point[2] ic;
}

struct SnarkProof {
  G1Point a;
  G2Point b;
  G1Point c;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { SnarkProof, VerifyingKey, Commitment, SNARK_SCALAR_FIELD, CIRCUIT_OUTPUTS } from "./Globals.sol";

import { Snark } from "./Snark.sol";

/**
 * @title Verifier
 * @author Railgun Contributors
 * @notice Verifies 
 * @dev Functions in this contract statelessly verify proofs, nullifiers, adaptID, and
 * depositAmount/withdrawAmount max sizes should be checked in RailgunLogic.
 * Note, functions have been split up to prevent exceedign solidity stack size limit.
 */

contract Verifier is Initializable, OwnableUpgradeable {
  // Verifying keys
  VerifyingKey public vKeySmall;
  VerifyingKey public vKeyLarge;

  // Verification key changed events
  event SmallVerificationKeyChange(VerifyingKey vkey);
  event LargeVerificationKeyChange(VerifyingKey vkey);


  /**
   * @notice Sets initial values for verification key
   * @dev OpenZeppelin initializer ensures this can only be called once
   * @param _vKeySmall - Initial vkey value for small circuit
   * @param _vKeyLarge - Initial vkey value for large circuit
   */

  function initializeVerifier(VerifyingKey calldata _vKeySmall, VerifyingKey calldata _vKeyLarge) internal initializer {
    // Set verification key
    setVKeySmall(_vKeySmall);
    setVKeyLarge(_vKeyLarge);
  }

  /**
   * @notice Hashes inputs for small proof verification
   * @param _adaptIDcontract - contract address to this proof to (ignored if set to 0)
   * @param _adaptIDparameters - hash of the contract parameters (only used to verify proof, this is verified by the
   * calling contract)
   * @param _depositAmount - deposit amount
   * @param _withdrawAmount - withdraw amount
   * @param _tokenField - token ID to use if deposit/withdraw is requested
   * @param _outputEthAddress - eth address to use if withdraw is requested
   * @param _treeNumber - merkle tree number
   * @param _merkleRoot - merkle root to verify against
   * @param _nullifiers - nullifiers of commitments
   * @param _commitmentsOut - output commitments
   * @return hash
   */
  function hashSmallInputs(
    // Shared
    address _adaptIDcontract,
    uint256 _adaptIDparameters,
    uint256 _depositAmount,
    uint256 _withdrawAmount,
    address _tokenField,
    address _outputEthAddress,
    // Join
    uint256 _treeNumber,
    uint256 _merkleRoot,
    uint256[] calldata _nullifiers,
    // Split
    Commitment[CIRCUIT_OUTPUTS] calldata _commitmentsOut
  ) private pure returns (uint256) {
    // Hash adaptID into single parameter
    uint256[2] memory adaptIDhashPreimage;
    adaptIDhashPreimage[0] = uint256(uint160(_adaptIDcontract));
    adaptIDhashPreimage[1] = _adaptIDparameters;

    uint256 adaptIDhash = uint256(sha256(abi.encodePacked(adaptIDhashPreimage)));

    // Hash ciphertext into single parameter
    uint256[24] memory cipherTextHashPreimage;
    // Commitment 0
    cipherTextHashPreimage[0] = _commitmentsOut[0].senderPubKey[0];
    cipherTextHashPreimage[1] = _commitmentsOut[0].senderPubKey[1];
    cipherTextHashPreimage[2] = _commitmentsOut[0].ciphertext[0];
    cipherTextHashPreimage[3] = _commitmentsOut[0].ciphertext[1];
    cipherTextHashPreimage[4] = _commitmentsOut[0].ciphertext[2];
    cipherTextHashPreimage[5] = _commitmentsOut[0].ciphertext[3];
    cipherTextHashPreimage[6] = _commitmentsOut[0].ciphertext[4];
    cipherTextHashPreimage[7] = _commitmentsOut[0].ciphertext[5];
    // Commitment 1
    cipherTextHashPreimage[8] = _commitmentsOut[1].senderPubKey[0];
    cipherTextHashPreimage[9] = _commitmentsOut[1].senderPubKey[1];
    cipherTextHashPreimage[10] = _commitmentsOut[1].ciphertext[0];
    cipherTextHashPreimage[11] = _commitmentsOut[1].ciphertext[1];
    cipherTextHashPreimage[12] = _commitmentsOut[1].ciphertext[2];
    cipherTextHashPreimage[13] = _commitmentsOut[1].ciphertext[3];
    cipherTextHashPreimage[14] = _commitmentsOut[1].ciphertext[4];
    cipherTextHashPreimage[15] = _commitmentsOut[1].ciphertext[5];
    // Commitment 2
    cipherTextHashPreimage[16] = _commitmentsOut[2].senderPubKey[0];
    cipherTextHashPreimage[17] = _commitmentsOut[2].senderPubKey[1];
    cipherTextHashPreimage[18] = _commitmentsOut[2].ciphertext[0];
    cipherTextHashPreimage[19] = _commitmentsOut[2].ciphertext[1];
    cipherTextHashPreimage[20] = _commitmentsOut[2].ciphertext[2];
    cipherTextHashPreimage[21] = _commitmentsOut[2].ciphertext[3];
    cipherTextHashPreimage[22] = _commitmentsOut[2].ciphertext[4];
    cipherTextHashPreimage[23] = _commitmentsOut[2].ciphertext[5];

    uint256 cipherTextHash = uint256(sha256(abi.encodePacked(cipherTextHashPreimage)));

    uint256[13] memory inputsHashPreimage;
    inputsHashPreimage[0] = adaptIDhash % SNARK_SCALAR_FIELD;
    inputsHashPreimage[1] = _depositAmount;
    inputsHashPreimage[2] = _withdrawAmount;
    inputsHashPreimage[3] = uint256(uint160(_tokenField));
    inputsHashPreimage[4] = uint256(uint160(_outputEthAddress));
    inputsHashPreimage[5] = _treeNumber;
    inputsHashPreimage[6] = _merkleRoot;
    inputsHashPreimage[7] = _nullifiers[0];
    inputsHashPreimage[8] = _nullifiers[1];
    inputsHashPreimage[9] = _commitmentsOut[0].hash;
    inputsHashPreimage[10] = _commitmentsOut[1].hash;
    inputsHashPreimage[11] = _commitmentsOut[2].hash;
    inputsHashPreimage[12] = cipherTextHash % SNARK_SCALAR_FIELD;

    return uint256(sha256(abi.encodePacked(inputsHashPreimage)));
  }

  /**
   * @notice Verify proof from a small transaction
   * @dev This function won't check if the merkle root is stored in the contract,
   * the nullifiers haven't been seed before, or if the deposit or withdraw amounts aren't
   * larger than allowed. It only verifies the snark proof is valid and the ciphertext is bound to the
   * proof.
   * @param _proof - snark proof
   * @param _inputsHash - hash of inputs
   * @return valid
   */
  function verifySmallProof(
    SnarkProof memory _proof,
    uint256 _inputsHash
  ) private view returns (bool) {
    return Snark.verify(
      vKeySmall,
      _proof,
      _inputsHash
    );
  }

  /**
   * @notice Hashes inputs for large proof verification
   * @param _adaptIDcontract - contract address to this proof to (verified in RailgunLogic.sol)
   * @param _adaptIDparameters - hash of the contract parameters (verified by the calling contract)
   * @param _depositAmount - deposit amount
   * @param _withdrawAmount - withdraw amount
   * @param _tokenField - token ID to use if deposit/withdraw is requested
   * @param _outputEthAddress - eth address to use if withdraw is requested
   * @param _treeNumber - merkle tree number
   * @param _merkleRoot - merkle root to verify against
   * @param _nullifiers - nullifiers of commitments
   * @param _commitmentsOut - output commitments
   * @return hash
   */
  function hashLargeInputs(
    // Shared
    address _adaptIDcontract,
    uint256 _adaptIDparameters,
    uint256 _depositAmount,
    uint256 _withdrawAmount,
    address _tokenField,
    address _outputEthAddress,
    // Join
    uint256 _treeNumber,
    uint256 _merkleRoot,
    uint256[] calldata _nullifiers,
    // Split
    Commitment[CIRCUIT_OUTPUTS] calldata _commitmentsOut
  ) private pure returns (uint256) {
    // Hash adaptID into single parameter
    uint256[2] memory adaptIDhashPreimage;
    adaptIDhashPreimage[0] = uint256(uint160(_adaptIDcontract));
    adaptIDhashPreimage[1] = _adaptIDparameters;

    uint256 adaptIDhash = uint256(sha256(abi.encodePacked(adaptIDhashPreimage)));

    // Hash ciphertext into single parameter
    uint256[24] memory cipherTextHashPreimage;
    // Commitment 0
    cipherTextHashPreimage[0] = _commitmentsOut[0].senderPubKey[0];
    cipherTextHashPreimage[1] = _commitmentsOut[0].senderPubKey[1];
    cipherTextHashPreimage[2] = _commitmentsOut[0].ciphertext[0];
    cipherTextHashPreimage[3] = _commitmentsOut[0].ciphertext[1];
    cipherTextHashPreimage[4] = _commitmentsOut[0].ciphertext[2];
    cipherTextHashPreimage[5] = _commitmentsOut[0].ciphertext[3];
    cipherTextHashPreimage[6] = _commitmentsOut[0].ciphertext[4];
    cipherTextHashPreimage[7] = _commitmentsOut[0].ciphertext[5];
    // Commitment 1
    cipherTextHashPreimage[8] = _commitmentsOut[1].senderPubKey[0];
    cipherTextHashPreimage[9] = _commitmentsOut[1].senderPubKey[1];
    cipherTextHashPreimage[10] = _commitmentsOut[1].ciphertext[0];
    cipherTextHashPreimage[11] = _commitmentsOut[1].ciphertext[1];
    cipherTextHashPreimage[12] = _commitmentsOut[1].ciphertext[2];
    cipherTextHashPreimage[13] = _commitmentsOut[1].ciphertext[3];
    cipherTextHashPreimage[14] = _commitmentsOut[1].ciphertext[4];
    cipherTextHashPreimage[15] = _commitmentsOut[1].ciphertext[5];
    // Commitment 2
    cipherTextHashPreimage[16] = _commitmentsOut[2].senderPubKey[0];
    cipherTextHashPreimage[17] = _commitmentsOut[2].senderPubKey[1];
    cipherTextHashPreimage[18] = _commitmentsOut[2].ciphertext[0];
    cipherTextHashPreimage[19] = _commitmentsOut[2].ciphertext[1];
    cipherTextHashPreimage[20] = _commitmentsOut[2].ciphertext[2];
    cipherTextHashPreimage[21] = _commitmentsOut[2].ciphertext[3];
    cipherTextHashPreimage[22] = _commitmentsOut[2].ciphertext[4];
    cipherTextHashPreimage[23] = _commitmentsOut[2].ciphertext[5];

    uint256 cipherTextHash = uint256(sha256(abi.encodePacked(cipherTextHashPreimage)));

    // Hash all inputs into single parameter
    uint256[21] memory inputsHashPreimage;
    inputsHashPreimage[0] = adaptIDhash % SNARK_SCALAR_FIELD;
    inputsHashPreimage[1] = _depositAmount;
    inputsHashPreimage[2] = _withdrawAmount;
    inputsHashPreimage[3] = uint256(uint160(_tokenField));
    inputsHashPreimage[4] = uint256(uint160(_outputEthAddress));
    inputsHashPreimage[5] = _treeNumber;
    inputsHashPreimage[6] = _merkleRoot;
    inputsHashPreimage[7] = _nullifiers[0];
    inputsHashPreimage[8] = _nullifiers[1];
    inputsHashPreimage[9] = _nullifiers[2];
    inputsHashPreimage[10] = _nullifiers[3];
    inputsHashPreimage[11] = _nullifiers[4];
    inputsHashPreimage[12] = _nullifiers[5];
    inputsHashPreimage[13] = _nullifiers[6];
    inputsHashPreimage[14] = _nullifiers[7];
    inputsHashPreimage[15] = _nullifiers[8];
    inputsHashPreimage[16] = _nullifiers[9];
    inputsHashPreimage[17] = _commitmentsOut[0].hash;
    inputsHashPreimage[18] = _commitmentsOut[1].hash;
    inputsHashPreimage[19] = _commitmentsOut[2].hash;
    inputsHashPreimage[20] = cipherTextHash % SNARK_SCALAR_FIELD;

    return uint256(sha256(abi.encodePacked(inputsHashPreimage)));
  }

  /**
   * @notice Verify proof from a Large transaction
   * @dev This function won't check if the merkle root is stored in the contract,
   * the nullifiers haven't been seed before, or if the deposit or withdraw amounts aren't
   * larger than allowed. It only verifies the snark proof is valid and the ciphertext is bound to the
   * proof.
   * @param _proof - snark proof
   * @param _inputsHash - hash of inputs
   * @return valid
   */
  function verifyLargeProof(
    SnarkProof memory _proof,
    uint256 _inputsHash
  ) private view returns (bool) {
    return Snark.verify(
      vKeyLarge,
      _proof,
      _inputsHash
    );
  }

  /**
   * @notice Verify snark proof for either Small or Large
   * @dev This function won't check if the merkle root is stored in the contract,
   * the nullifiers haven't been seed before, or if the deposit or withdraw amounts aren't
   * larger than allowed. It only verifies the snark proof is valid and the ciphertext is bound to the
   * proof.
   * @param _proof - snark proof
   * @param _adaptIDcontract - contract address to this proof to (verified in RailgunLogic.sol)
   * @param _adaptIDparameters - hash of the contract parameters (verified by the calling contract)
   * @param _depositAmount - deposit amount
   * @param _withdrawAmount - withdraw amount
   * @param _tokenField - token ID to use if deposit/withdraw is requested
   * @param _outputEthAddress - eth address to use if withdraw is requested
   * @param _treeNumber - merkle tree number
   * @param _merkleRoot - merkle root to verify against
   * @param _nullifiers - nullifiers of commitments
   * @param _commitmentsOut - output commitments
   * @return valid
   */

  function verifyProof(
    // Proof
    SnarkProof calldata _proof,
    // Shared
    address _adaptIDcontract,
    uint256 _adaptIDparameters,
    uint256 _depositAmount,
    uint256 _withdrawAmount,
    address _tokenField,
    address _outputEthAddress,
    // Join
    uint256 _treeNumber,
    uint256 _merkleRoot,
    uint256[] calldata _nullifiers,
    // Split
    Commitment[CIRCUIT_OUTPUTS] calldata _commitmentsOut
  ) public view returns (bool) {
    // Check all nullifiers are valid snark field elements
    for (uint256 i = 0; i < _nullifiers.length; i++) {
      require(_nullifiers[i] < SNARK_SCALAR_FIELD, "Verifier: Nullifier not a valid field element");
    }

    // Check all commitment hashes are valid snark field elements
    for (uint256 i = 0; i < _commitmentsOut.length; i++) {
      require(_commitmentsOut[i].hash < SNARK_SCALAR_FIELD, "Verifier: Nullifier not a valid field element");
    }

    if (_nullifiers.length == 2) {
      // Hash all inputs into single parameter
      uint256 inputsHash = hashSmallInputs(
        _adaptIDcontract,
        _adaptIDparameters,
        _depositAmount,
        _withdrawAmount,
        _tokenField,
        _outputEthAddress,
        _treeNumber,
        _merkleRoot,
        _nullifiers,
        _commitmentsOut
      );

      // Verify proof
      return verifySmallProof(_proof, inputsHash % SNARK_SCALAR_FIELD);
    } else if (_nullifiers.length == 10) {
      // Hash all inputs into single parameter
      uint256 inputsHash = hashLargeInputs(
        _adaptIDcontract,
        _adaptIDparameters,
        _depositAmount,
        _withdrawAmount,
        _tokenField,
        _outputEthAddress,
        _treeNumber,
        _merkleRoot,
        _nullifiers,
        _commitmentsOut
      );

      // Verify proof
      return verifyLargeProof(_proof, inputsHash % SNARK_SCALAR_FIELD);
    } else {
      // Fail if nullifiers length doesn't match
      return false;
    }
  }

  /**
   * @notice Changes snark verification key for small transaction circuit
   * @param _vKey - verification key to change to
   */

  function setVKeySmall(VerifyingKey calldata _vKey) public onlyOwner {
    // Copy everything manually as solidity can't copy structs to storage
    // Alpha
    vKeySmall.alpha1.x = _vKey.alpha1.x;
    vKeySmall.alpha1.y = _vKey.alpha1.y;
    // Beta
    vKeySmall.beta2.x[0] = _vKey.beta2.x[0];
    vKeySmall.beta2.x[1] = _vKey.beta2.x[1];
    vKeySmall.beta2.y[0] = _vKey.beta2.y[0];
    vKeySmall.beta2.y[1] = _vKey.beta2.y[1];
    // Gamma
    vKeySmall.gamma2.x[0] = _vKey.gamma2.x[0];
    vKeySmall.gamma2.x[1] = _vKey.gamma2.x[1];
    vKeySmall.gamma2.y[0] = _vKey.gamma2.y[0];
    vKeySmall.gamma2.y[1] = _vKey.gamma2.y[1];
    // Delta
    vKeySmall.delta2.x[0] = _vKey.delta2.x[0];
    vKeySmall.delta2.x[1] = _vKey.delta2.x[1];
    vKeySmall.delta2.y[0] = _vKey.delta2.y[0];
    vKeySmall.delta2.y[1] = _vKey.delta2.y[1];
    // IC
    vKeySmall.ic[0].x = _vKey.ic[0].x;
    vKeySmall.ic[0].y = _vKey.ic[0].y;
    vKeySmall.ic[1].x = _vKey.ic[1].x;
    vKeySmall.ic[1].y = _vKey.ic[1].y;

    // Emit change event
    emit SmallVerificationKeyChange(_vKey);
  }

  /**
   * @notice Changes snark verification key for large transaction circuit
   * @param _vKey - verification key to change to
   */

  function setVKeyLarge(VerifyingKey calldata _vKey) public onlyOwner {
    // Copy everything manually as solidity can't copy structs to storage
    // Alpha
    vKeyLarge.alpha1.x = _vKey.alpha1.x;
    vKeyLarge.alpha1.y = _vKey.alpha1.y;
    // Beta
    vKeyLarge.beta2.x[0] = _vKey.beta2.x[0];
    vKeyLarge.beta2.x[1] = _vKey.beta2.x[1];
    vKeyLarge.beta2.y[0] = _vKey.beta2.y[0];
    vKeyLarge.beta2.y[1] = _vKey.beta2.y[1];
    // Gamma
    vKeyLarge.gamma2.x[0] = _vKey.gamma2.x[0];
    vKeyLarge.gamma2.x[1] = _vKey.gamma2.x[1];
    vKeyLarge.gamma2.y[0] = _vKey.gamma2.y[0];
    vKeyLarge.gamma2.y[1] = _vKey.gamma2.y[1];
    // Delta
    vKeyLarge.delta2.x[0] = _vKey.delta2.x[0];
    vKeyLarge.delta2.x[1] = _vKey.delta2.x[1];
    vKeyLarge.delta2.y[0] = _vKey.delta2.y[0];
    vKeyLarge.delta2.y[1] = _vKey.delta2.y[1];
    // IC
    vKeyLarge.ic[0].x = _vKey.ic[0].x;
    vKeyLarge.ic[0].y = _vKey.ic[0].y;
    vKeyLarge.ic[1].x = _vKey.ic[1].x;
    vKeyLarge.ic[1].y = _vKey.ic[1].y;

    // Emit change event
    emit LargeVerificationKeyChange(_vKey);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// Based on code from MACI (https://github.com/appliedzkp/maci/blob/7f36a915244a6e8f98bacfe255f8bd44193e7919/contracts/sol/IncrementalMerkleTree.sol)
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { Commitment, SNARK_SCALAR_FIELD, CIRCUIT_OUTPUTS, CIPHERTEXT_WORDS } from "./Globals.sol";

import { PoseidonT3, PoseidonT6 } from "./Poseidon.sol";

/**
 * @title Commitments
 * @author Railgun Contributors
 * @notice Batch Incremental Merkle Tree for commitments
 * @dev Publically accessible functions to be put in RailgunLogic
 * Relevent external contract calls should be in those functions, not here
 */

contract Commitments is Initializable {
  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Commitment added event
  event NewCommitment(
    uint256 indexed treeNumber,
    uint256 indexed position,
    uint256 hash,
    uint256[CIPHERTEXT_WORDS] ciphertext, // Ciphertext order: iv, recipient pubkey (2 x uint256), random, amount, token
    uint256[2] senderPubKey
  );

  // Generated commitment added event
  event NewGeneratedCommitment(
    uint256 indexed treeNumber,
    uint256 indexed position,
    uint256 hash,
    uint256[2] pubkey,
    uint256 random,
    uint256 amount,
    address token
  );

  // Commitment nullifiers
  mapping(uint256 => bool) public nullifiers;

  // The tree depth
  uint256 private constant TREE_DEPTH = 16;

  // Max number of leaves that can be inserted in a single batch
  uint256 internal constant MAX_BATCH_SIZE = CIRCUIT_OUTPUTS;

  // Tree zero value
  uint256 private constant ZERO_VALUE = uint256(keccak256("Railgun")) % SNARK_SCALAR_FIELD;

  // Next leaf index (number of inserted leaves in the current tree)
  uint256 private nextLeafIndex = 0;

  // The Merkle root
  uint256 public merkleRoot;

  // Store new tree root to quickly migrate to a new tree
  uint256 private newTreeRoot;

  // Tree number
  uint256 private treeNumber;

  // The Merkle path to the leftmost leaf upon initialisation. It *should
  // not* be modified after it has been set by the initialize function.
  // Caching these values is essential to efficient appends.
  uint256[TREE_DEPTH] private zeros;

  // Right-most elements at each level
  // Used for efficient upodates of the merkle tree
  uint256[TREE_DEPTH] private filledSubTrees;

  // Whether the contract has already seen a particular Merkle tree root
  // treeNumber => root => seen
  mapping(uint256 => mapping(uint256 => bool)) public rootHistory;


  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev OpenZeppelin initializer ensures this can only be called once
   */

  function initializeCommitments() internal initializer {
    /*
    To initialise the Merkle tree, we need to calculate the Merkle root
    assuming that each leaf is the zero value.
    H(H(a,b), H(c,d))
      /          \
    H(a,b)     H(c,d)
    /   \       /  \
    a    b     c    d
    `zeros` and `filledSubTrees` will come in handy later when we do
    inserts or updates. e.g when we insert a value in index 1, we will
    need to look up values from those arrays to recalculate the Merkle
    root.
    */

    // Calculate zero values
    zeros[0] = ZERO_VALUE;

    // Store the current zero value for the level we just calculated it for
    uint256 currentZero = ZERO_VALUE;

    // Loop through each level
    for (uint256 i = 0; i < TREE_DEPTH; i++) {
      // Push it to zeros array
      zeros[i] = currentZero;

      // Calculate the zero value for this level
      currentZero = hashLeftRight(currentZero, currentZero);
    }

    // Set merkle root and store root to quickly retrieve later
    newTreeRoot = merkleRoot = currentZero;
    rootHistory[treeNumber][currentZero] = true;
  }

  /**
   * @notice Hash 2 uint256 values
   * @param _left - Left side of hash
   * @param _right - Right side of hash
   * @return hash result
   */
  function hashLeftRight(uint256 _left, uint256 _right) private pure returns (uint256) {
    return PoseidonT3.poseidon([
      _left,
      _right
    ]);
  }

  /**
   * @notice Calculates initial values for Merkle Tree
   * @dev OpenZeppelin initializer ensures this can only be called once.
   * Note: this function INTENTIONALLY causes side effects to save on gas.
   * _leafHashes and _count should never be reused.
   * @param _leafHashes - array of leaf hashes to be added to the merkle tree
   * @param _count - number of leaf hashes to be added to the merkle tree
   */

  function insertLeaves(uint256[MAX_BATCH_SIZE] memory _leafHashes, uint256 _count) private {
    /*
    Loop through leafHashes at each level, if the leaf is on the left (index is even)
    then hash with zeros value and update subtree on this level, if the leaf is on the
    right (index is odd) then hash with subtree value. After calculating each hash
    push to relevent spot on leafHashes array. For gas efficiency we reuse the same
    array and use the count variable to loop to the right index each time.

    Example of updating a tree of depth 4 with elements 13, 14, and 15
    [1,7,15]    {1}                    1
                                       |
    [3,7,15]    {1}          2-------------------3
                             |                   |
    [6,7,15]    {2}     4---------5         6---------7
                       / \       / \       / \       / \
    [13,14,15]  {3}  08   09   10   11   12   13   14   15
    [] = leafHashes array
    {} = count variable
    */

    // Current index is the index at each level to insert the hash
    uint256 levelInsertionIndex = nextLeafIndex;

    // Update nextLeafIndex
    nextLeafIndex += _count;

    // Variables for starting point at next tree level
    uint256 nextLevelHashIndex;
    uint256 nextLevelStartIndex;

    // Loop through each level of the merkle tree and update
    for (uint256 level = 0; level < TREE_DEPTH; level++) {
      // Calculate the index to start at for the next level
      // >> is equivilent to / 2 rounded down
      nextLevelStartIndex = levelInsertionIndex >> 1;

      for (uint256 insertionElement = 0; insertionElement < _count; insertionElement++) {
        uint256 left;
        uint256 right;

        // Calculate left/right values
        if (levelInsertionIndex % 2 == 0) {
          // Leaf hash we're updating with is on the left
          left = _leafHashes[insertionElement];
          right = zeros[level];

          // We've created a new subtree at this level, update
          filledSubTrees[level] = _leafHashes[insertionElement];
        } else {
          // Leaf hash we're updating with is on the right
          left = filledSubTrees[level];
          right = _leafHashes[insertionElement];
        }

        // Calculate index to insert hash into leafHashes[]
        // >> is equivilent to / 2 rounded down
        nextLevelHashIndex = (levelInsertionIndex >> 1) - nextLevelStartIndex;

        // Calculate the hash for the next level
        _leafHashes[nextLevelHashIndex] = hashLeftRight(left, right);

        // Increment level insertion index
        levelInsertionIndex++;
      }

      // Get starting levelInsertionIndex value for next level
      levelInsertionIndex = nextLevelStartIndex;

      // Get count of elements for next level
      _count = nextLevelHashIndex + 1;
    }
 
    // Update the Merkle tree root
    merkleRoot = _leafHashes[0];
    rootHistory[treeNumber][merkleRoot] = true;
  }

  /**
   * @notice Creates new merkle tree
   */

  function newTree() internal {
    // Restore merkleRoot to newTreeRoot
    merkleRoot = newTreeRoot;

    // Existing values in filledSubtrees will never be used so overwriting them is unnecessary

    // Reset next leaf index to 0
    nextLeafIndex = 0;

    // Increment tree number
    treeNumber++;
  }

  /**
   * @notice Adds commitments to tree and emits events
   * @dev MAX_BATCH_SIZE trades off gas cost and batch size
   * @param _commitments - array of commitments to be added to merkle tree
   */

  function addCommitments(Commitment[CIRCUIT_OUTPUTS] calldata _commitments) internal {
    // Create new tree if existing tree can't contain outputs
    // We insert all new commitment into a new tree to ensure they can be spent in the same transaction
    if ((nextLeafIndex + _commitments.length) > (uint256(2) ** TREE_DEPTH)) { newTree(); }

    // Build insertion array
    uint256[MAX_BATCH_SIZE] memory insertionLeaves;

    for (uint256 i = 0; i < _commitments.length; i++) {
      // Throw if leaf is invalid
      require(
        _commitments[i].hash < SNARK_SCALAR_FIELD,
        "Commitments: context.leafHash[] entries must be < SNARK_SCALAR_FIELD"
      );

      // Push hash to insertion array
      insertionLeaves[i] =  _commitments[i].hash;

      // Emit CommitmentAdded events (for wallets) for all the commitments
      emit NewCommitment(treeNumber, nextLeafIndex + i, _commitments[i].hash, _commitments[i].ciphertext, _commitments[i].senderPubKey);
    }

    // Push the leaf hashes into the Merkle tree
    insertLeaves(insertionLeaves, CIRCUIT_OUTPUTS);
  }

  /**
   * @notice Creates a commitment hash from supplied values and adds to tree
   * @dev This is for DeFi integrations where the resulting number of tokens to be added
   * can't be known in advance (eg. AMM trade where transaction ordering could cause toekn amounts to change)
   * @param _pubkey - pubkey of commitment
   * @param _random - randomness component of commitment
   * @param _amount - amount of commitment
   * @param _token - token ID of commitment
   */

  function addGeneratedCommitment(
    uint256[2] memory _pubkey,
    uint256 _random,
    uint256 _amount,
    address _token
  ) internal {
    // Create new tree if current one can't contain existing tree
    // We insert all new commitment into a new tree to ensure they can be spent in the same transaction
    if ((nextLeafIndex + 1) >= (2 ** TREE_DEPTH)) { newTree(); }

    // Calculate commitment hash
    uint256 hash = PoseidonT6.poseidon([
      _pubkey[0],
      _pubkey[1],
      _random,
      _amount,
      uint256(uint160(_token))
    ]);

    // Emit GeneratedCommitmentAdded events (for wallets) for the commitments
    emit NewGeneratedCommitment(treeNumber, nextLeafIndex, hash, _pubkey, _random, _amount, _token);

    // Push the leaf hash into the Merkle tree
    uint256[CIRCUIT_OUTPUTS] memory insertionLeaves;
    insertionLeaves[0] = hash;
    insertLeaves(insertionLeaves, 1);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Token Whitelist
 * @author Railgun Contributors
 * @notice Whitelist of tokens allowed to be deposited in Railgun
 * @dev Tokens on this whitelist can be deposited to railgun.
 * Tokens can be removed from this whitelist but will still be transferrable
 * internally (as internal transactions have a shielded token ID) and
 * withdrawable (to prevent user funds from being locked)
 */

contract TokenWhitelist is Initializable, OwnableUpgradeable {
  // Events for offchain building of whitelist index
  event TokenListing(address indexed token);
  event TokeDelisting(address indexed token);

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list and decrement the __gap
  // variable at the end of this file
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading
  mapping(address => bool) public tokenWhitelist;

  /**
   * @notice Adds initial set of tokens to whitelist.
   * @dev OpenZeppelin initializer ensures this can only be called once
   * @param _tokens - List of tokens to add to whitelist
   */

  function initializeTokenWhitelist(address[] calldata _tokens) internal initializer {
    // Push initial token whitelist to map
    addToWhitelist(_tokens);
  }

  /**
   * @notice Adds tokens to whitelist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that are already in the whitelist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to add to whitelist
   */

  function addToWhitelist(address[] calldata _tokens) public onlyOwner {
    // Loop through token array
    for (uint i = 0; i < _tokens.length; i++) {
      // Don't do anything if the token is already whitelisted
      if (!tokenWhitelist[_tokens[i]]) {
          // Set token address in whitelist map to true
        tokenWhitelist[_tokens[i]] = true;

        // Emit event for building index of whitelisted tokens offchain
        emit TokenListing(_tokens[i]);
      }
    }
  }

  /**
   * @notice Removes token from whitelist, only callable by owner (governance contract)
   * @dev This function will ignore tokens that aren't in the whitelist
   * no events will be emitted in this case
   * @param _tokens - List of tokens to remove from whitelist
   */

  function removeFromWhitelist(address[] calldata _tokens) external onlyOwner {
    // Loop through token array
    for (uint i = 0; i < _tokens.length; i++) {
      // Don't do anything if the token isn't whitelisted
      if (tokenWhitelist[_tokens[i]]) {
        // Set token address in whitelist map to false (default value)
        delete tokenWhitelist[_tokens[i]];

        // Emit event for building index of whitelisted tokens offchain
        emit TokeDelisting(_tokens[i]);
      }
    }
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import { G1Point, G2Point, VerifyingKey, SnarkProof, SNARK_SCALAR_FIELD } from "./Globals.sol";

library Snark {
  uint256 private constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
  uint256 private constant PAIRING_INPUT_SIZE = 24;
  uint256 private constant PAIRING_INPUT_WIDTH = 768; // PAIRING_INPUT_SIZE * 32

  /**
   * @notice Computes the negation of point p
   * @dev The negation of p, i.e. p.plus(p.negate()) should be zero.
   * @return result
   */
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    if (p.x == 0 && p.y == 0) return G1Point(0, 0);

    // check for valid points y^2 = x^3 +3 % PRIME_Q
    uint256 rh = mulmod(p.x, p.x, PRIME_Q); //x^2
    rh = mulmod(rh, p.x, PRIME_Q); //x^3
    rh = addmod(rh, 3, PRIME_Q); //x^3 + 3
    uint256 lh = mulmod(p.y, p.y, PRIME_Q); //y^2
    require(lh == rh, "Snark: ");

    return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }

  /**
   * @notice Adds 2 G1 points
   * @return result
   */
  function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory) {
    // Format inputs
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;

    // Setup output variables
    bool success;
    G1Point memory result;

    // Add points
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0x80, result, 0x40)
    }

    // Check if operation succeeded
    require(success, "Pairing: Add Failed");

    return result;
  }

  /**
   * @notice Scalar multiplies two G1 points p, s
   * @dev The product of a point on G1 and a scalar, i.e.
   * p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
   * points p.
   */
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x60, r, 0x40)
    }

    // Check multiplication succeeded
    require(success, "Pairing: Scalar Multiplication Failed");
  }

  /**
   * @notice Performs pairing check on points
   * @dev The result of computing the pairing check
   * e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
   * For example,
   * pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
   * @return if pairing check passed
   */
  function pairing(
    G1Point memory _a1,
    G2Point memory _a2,
    G1Point memory _b1,
    G2Point memory _b2,
    G1Point memory _c1,
    G2Point memory _c2,
    G1Point memory _d1,
    G2Point memory _d2
  ) internal view returns (bool) {
    uint256[PAIRING_INPUT_SIZE] memory input = [
      _a1.x,
      _a1.y,
      _a2.x[0],
      _a2.x[1],
      _a2.y[0],
      _a2.y[1],
      _b1.x,
      _b1.y,
      _b2.x[0],
      _b2.x[1],
      _b2.y[0],
      _b2.y[1],
      _c1.x,
      _c1.y,
      _c2.x[0],
      _c2.x[1],
      _c2.y[0],
      _c2.y[1],
      _d1.x,
      _d1.y,
      _d2.x[0],
      _d2.x[1],
      _d2.y[0],
      _d2.y[1]
    ];

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        input,
        PAIRING_INPUT_WIDTH,
        out,
        0x20
      )
    }

    // Check if operation succeeded
    require(success, "Pairing: Pairing Verification Failed");

    return out[0] != 0;
  }

  /**
    * @notice Verifies snark proof against proving key
    * @param _vk - Verification Key
    * @param _proof - snark proof
    * @param _input - hash of inputs
    */
  function verify(
    VerifyingKey memory _vk,
    SnarkProof memory _proof,
    uint256 _input
  ) internal view returns (bool) {
    // Compute the linear combination vkX
    G1Point memory vkX = G1Point(0, 0);
    
    // Make sure input is less than SNARK_SCALAR_FIELD
    require(_input < SNARK_SCALAR_FIELD, "Snark: Input gte SNARK_SCALAR_FIELD");

    // Compute vkX
    vkX = add(vkX, scalarMul(_vk.ic[1], _input));
    vkX = add(vkX, _vk.ic[0]);

    // Verify pairing and return
    return pairing(
      negate(_proof.a),
      _proof.b,
      _vk.alpha1,
      _vk.beta2,
      vkX,
      _vk.gamma2,
      _proof.c,
      _vk.delta2
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

/*
Functions here are stubs for the solidity compiler to generate the right interface.
The deployed library is generated bytecode from the circomlib toolchain
*/

library PoseidonT3 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

library PoseidonT6 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1600
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
  "libraries": {
    "contracts/logic/Poseidon.sol": {
      "PoseidonT3": "0x7a865794e85c29a793962754370f8541d36dc12a",
      "PoseidonT6": "0xc20871f4b5281416c2bf72125507c5fcba9079cd"
    }
  }
}