// SPDX-License-Identifier: NONE

pragma solidity ^0.8.0;

import "./utils/MerkleProof.sol";
import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IRewardsAirdropWithLock.sol";

/**
 * @title Ruler RewardsAirdropWithLock contract
 * @author crypto-pumpkin
 * This contract handles multiple rounds of airdrops. It also can (does not have to) enforce a lock up window for claiming. Meaning if the user claimed before the lock up ends, it will charge a penalty.
 */
contract RewardsAirdropWithLock is IRewardsAirdropWithLock, Ownable {
  using SafeERC20 for IERC20;

  address public override penaltyReceiver;
  uint256 public constant override claimWindow = 120 days;
  uint256 public constant BASE = 1e18;

  AirdropRound[] private airdropRounds;
  // roundsIndex => merkleIndex => mask
  mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMaps;

  modifier onlyNotDisabled(uint256 _roundInd) {
    require(!airdropRounds[_roundInd].disabled, "RWL: Round disabled");
    _;
  }

  constructor(address _penaltyReceiver) {
    penaltyReceiver = _penaltyReceiver;
  }

  function updatePaneltyReceiver(address _new) external override onlyOwner {
    require(_new != address(0), "RWL: penaltyReceiver is 0");
    emit UpdatedPenaltyReceiver(penaltyReceiver, _new);
    penaltyReceiver = _new;
  }

  /**
   * @notice add an airdrop round
   * @param _token, the token to drop
   * @param _merkleRoot, the merkleRoot of the airdrop round
   * @param _lockWindow, the amount of time in secs that the rewards are locked, if claim before lock ends, a lockRate panelty is charged. 0 means no lock up period and _lockRate is ignored.
   * @param _lockRate, the lockRate to charge if claim before lock ends, 40% lock rate means u only get 60% of the amount if claimed before 1 month (the lock window)
   * @param _total, the total amount to be dropped
   */
  function addAirdrop(
    address _token,
    bytes32 _merkleRoot,
    uint256 _lockWindow,
    uint256 _lockRate,
    uint256 _total
  ) external override onlyOwner returns (uint256) {
    require(_token != address(0), "RWL: token is 0");
    require(_total > 0, "RWL: total is 0");
    require(_merkleRoot.length > 0, "RWL: empty merkle");

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _total);
    airdropRounds.push(AirdropRound(
      _token,
      _merkleRoot,
      false,
      block.timestamp,
      _lockWindow,
      _lockRate,
      _total,
      0
    ));
    uint256 index = airdropRounds.length - 1;
    emit AddedAirdrop(index, _token, _total);
    return index;
  }

  function updateRoundStatus(uint256 _roundInd, bool _disabled) external override onlyOwner {
    emit UpdatedRoundStatus(_roundInd, airdropRounds[_roundInd].disabled, _disabled);
    airdropRounds[_roundInd].disabled = _disabled;
  }

  function claim(
    uint256 _roundInd,
    uint256 _merkleInd,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external override onlyNotDisabled(_roundInd) {
    require(!isClaimed(_roundInd, _merkleInd), "RWL: Already claimed");
    AirdropRound memory airdropRound = airdropRounds[_roundInd];
    require(block.timestamp <= airdropRound.startTime + claimWindow, "RWL: Too late");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(_merkleInd, account, amount));
    require(MerkleProof.verify(merkleProof, airdropRound.merkleRoot, node), "RWL: Invalid proof");

    // Mark it claimed and send the token.
    airdropRounds[_roundInd].totalClaimed = airdropRound.totalClaimed + amount;
    _setClaimed(_roundInd, _merkleInd);

    // calculate penalty if any
    uint256 claimableAmount = amount;
    if (block.timestamp < airdropRound.startTime + airdropRound.lockWindow) {
      uint256 penalty = airdropRound.lockRate * amount / BASE;
      IERC20(airdropRound.token).safeTransfer(penaltyReceiver, penalty);
      claimableAmount -= penalty;
    }

    IERC20(airdropRound.token).safeTransfer(account, claimableAmount);
    emit Claimed(_roundInd, _merkleInd, account, claimableAmount, amount);
  }

  // collect any token send by mistake, collect target after 120 days
  function collectDust(uint256[] calldata _roundInds) external onlyOwner {
    for (uint256 i = 0; i < _roundInds.length; i ++) {
      AirdropRound memory airdropRound = airdropRounds[_roundInds[i]];
      require(block.timestamp > airdropRound.startTime + claimWindow || airdropRound.disabled, "RWL: Not ready");
      airdropRounds[_roundInds[i]].disabled = true;
      uint256 toCollect = airdropRound.total - airdropRound.totalClaimed;
      IERC20(airdropRound.token).safeTransfer(owner(), toCollect);
    }
  }

  function isClaimed(uint256 _roundInd, uint256 _merkleInd) public view override returns (bool) {
    uint256 claimedWordIndex = _merkleInd / 256;
    uint256 claimedBitIndex = _merkleInd % 256;
    uint256 claimedWord = claimedBitMaps[_roundInd][claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function getAllAirdropRounds() external view override returns (AirdropRound[] memory) {
    return airdropRounds;
  }

  function getAirdropRoundsLength() external view override returns (uint256) {
    return airdropRounds.length;
  }

  function getAirdropRounds(uint256 _startInd, uint256 _endInd) external view override returns (AirdropRound[] memory) {
    AirdropRound[] memory roundsResults = new AirdropRound[](_endInd - _startInd);
    AirdropRound[] memory roundsCopy = airdropRounds;
    uint256 resultInd;
    for (uint256 i = _startInd; i < _endInd; i++) {
      roundsResults[resultInd] = roundsCopy[i];
      resultInd++;
    }
    return roundsResults;
  }

  function _setClaimed(uint256 _roundInd, uint256 _merkleInd) private {
    uint256 claimedWordIndex = _merkleInd / 256;
    uint256 claimedBitIndex = _merkleInd % 256;
    claimedBitMaps[_roundInd][claimedWordIndex] = claimedBitMaps[_roundInd][claimedWordIndex] | (1 << claimedBitIndex);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author [email protected]
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev COVER: Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IRewardsAirdropWithLock {
    event Claimed(uint256 roundInd, uint256 merkleInd, address account, uint256 claimedAmount, uint256 amount);
    event UpdatedPenaltyReceiver(address old, address _new);
    event UpdatedRoundStatus(uint256 roundInd, bool oldDisabled, bool _newDisabled);
    event AddedAirdrop(uint256 roundInd, address token, uint256 total);

    struct AirdropRound {
        address token;
        bytes32 merkleRoot;
        bool disabled;
        uint256 startTime;
        uint256 lockWindow;
        uint256 lockRate;
        uint256 total;
        uint256 totalClaimed;
    }

    function penaltyReceiver() external view returns (address);
    function claimWindow() external view returns (uint256);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 _roundsIndex, uint256 index) external view returns (bool);

    // extra view
    function getAllAirdropRounds() external returns (AirdropRound[] memory);
    function getAirdropRounds(uint256 _startInd, uint256 _endInd) external returns (AirdropRound[] memory);
    function getAirdropRoundsLength() external returns (uint256);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 _roundsIndex,
        uint256 _merkleIndex,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // Only owner
    function updatePaneltyReceiver(address _new) external;
    function addAirdrop(
        address _token,
        bytes32 _merkleRoot,
        uint256 _lockWindow,
        uint256 _lockRate,
        uint256 _total
    ) external returns (uint256);
    function updateRoundStatus(uint256 _roundInd, bool _disabled) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

