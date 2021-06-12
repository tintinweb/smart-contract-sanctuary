pragma solidity <0.6 >=0.4.24;

import "./math/SafeMath.sol";
import "./token/IMintableToken.sol";
import "./token/SafeERC20.sol";
import "./utils/Address.sol";
import "./zksnarklib/MerkleTreeWithHistory.sol";
import "./zksnarklib/IVerifier.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CycloneV2dot3 is MerkleTreeWithHistory, ReentrancyGuard {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public tokenDenomination; // (10K or 100k or 1M) * 10^18
  uint256 public coinDenomination;
  uint256 public initCYCDenomination;
  mapping(bytes32 => bool) public nullifierHashes;
  mapping(bytes32 => bool) public commitments; // we store all commitments just to prevent accidental deposits with the same commitment
  IVerifier public verifier;
  IERC20 public token;
  IMintableToken public cycToken;
  address public treasury;
  address public govDAO;
  uint256 public numOfShares;
  uint256 public lastRewardBlock;
  uint256 public rewardPerBlock;
  uint256 public accumulateCYC;
  uint256 public anonymityFee;

  modifier onlyGovDAO {
    // Start with an governance DAO address and will transfer to a governance DAO, e.g., Timelock + GovernorAlpha, after launch
    require(msg.sender == govDAO, "Only Governance DAO can call this function.");
    _;
  }

  event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp, uint256 cycDenomination, uint256 anonymityFee);
  event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 reward, uint256 relayerFee);
  event RewardPerBlockUpdated(uint256 oldValue, uint256 newValue);
  event AnonymityFeeUpdated(uint256 oldValue, uint256 newValue);

  /**
    @dev The constructor
    @param _verifier the address of SNARK verifier for this contract
    @param _merkleTreeHeight the height of deposits' Merkle Tree
    @param _govDAO governance DAO address
  */
  constructor(
    address _govDAO,
    IERC20 _token,
    IMintableToken _cycToken,
    address _treasury,
    uint256 _initCYCDenomination,
    uint256 _coinDenomination,
    uint256 _tokenDenomination,
    uint256 _startBlock,
    IVerifier _verifier,
    uint32 _merkleTreeHeight
  ) MerkleTreeWithHistory(_merkleTreeHeight) public {
    require(address(_token) != address(_cycToken), "token cannot be identical to CYC token");
    verifier = _verifier;
    treasury = _treasury;
    cycToken = _cycToken;
    token = _token;
    govDAO = _govDAO;
    if (_startBlock < block.number) {
      lastRewardBlock = block.number;
    } else {
      lastRewardBlock = _startBlock;
    }
    initCYCDenomination = _initCYCDenomination;
    coinDenomination = _coinDenomination;
    tokenDenomination = _tokenDenomination;
    numOfShares = 0;
  }

  function calcAccumulateCYC() internal view returns (uint256) {
    uint256 reward = block.number.sub(lastRewardBlock).mul(rewardPerBlock);
    uint256 remaining = cycToken.balanceOf(address(this)).sub(accumulateCYC);
    if (remaining < reward) {
      reward = remaining;
    }
    return accumulateCYC.add(reward);
  }

  function updateBlockReward() public {
    uint256 blockNumber = block.number;
    if (blockNumber <= lastRewardBlock) {
      return;
    }
    if (rewardPerBlock != 0) {
      accumulateCYC = calcAccumulateCYC();
    }
    // always update lastRewardBlock no matter there is sufficient reward or not
    lastRewardBlock = blockNumber;
  }

  function cycDenomination() public view returns (uint256) {
    if (numOfShares == 0) {
      return initCYCDenomination;
    }
    uint256 blockNumber = block.number;
    uint256 accCYC = accumulateCYC;
    if (blockNumber > lastRewardBlock && rewardPerBlock > 0) {
      accCYC = calcAccumulateCYC();
    }
    return accCYC.add(numOfShares - 1).div(numOfShares);
  }

  /**
    @dev Deposit funds into the contract. The caller must send (for Coin) or approve (for ERC20) value equal to or `denomination` of this instance.
    @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
  */
  function deposit(bytes32 _commitment) external payable nonReentrant {
    require(!commitments[_commitment], "The commitment has been submitted");
    require(msg.value >= coinDenomination, "insufficient coin amount");
    uint256 refund = msg.value - coinDenomination;
    uint32 insertedIndex = _insert(_commitment);
    commitments[_commitment] = true;
    updateBlockReward();
    uint256 cycDeno = cycDenomination();
    uint256 fee = anonymityFee;
    if (cycDeno.add(fee) > 0) {
      require(cycToken.transferFrom(msg.sender, address(this), cycDeno.add(fee)), "insufficient CYC allowance");
    }
    if (fee > 0) {
      address t = treasury;
      if (t == address(0)) {
        require(cycToken.burn(fee), "failed to burn anonymity fee");
      } else {
        safeTransfer(cycToken, t, fee);
      }
    }
    uint256 td = tokenDenomination;
    if (td > 0) {
      token.safeTransferFrom(msg.sender, address(this), td);
    }
    accumulateCYC += cycDeno;
    numOfShares += 1;
    if (refund > 0) {
      (bool success, ) = msg.sender.call.value(refund)("");
      require(success, "failed to refund");
    }
    emit Deposit(_commitment, insertedIndex, block.timestamp, cycDeno, fee);
  }

  /**
    @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
    `input` array consists of:
      - merkle root of all deposits in the contract
      - hash of unique deposit nullifier to prevent double spends
      - the recipient of funds
      - optional fee that goes to the transaction sender (usually a relay)
  */
  function withdraw(bytes calldata _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient, address payable _relayer, uint256 _relayerFee, uint256 _refund) external payable nonReentrant {
    require(_refund == 0, "refund is not zero");
    require(!Address.isContract(_recipient), "recipient of cannot be contract");
    require(!nullifierHashes[_nullifierHash], "The note has been already spent");
    require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
    require(verifier.verifyProof(_proof, [uint256(_root), uint256(_nullifierHash), uint256(_recipient), uint256(_relayer), _relayerFee, _refund]), "Invalid withdraw proof");

    nullifierHashes[_nullifierHash] = true;
    uint256 td = tokenDenomination;
    if (td > 0) {
      safeTransfer(token, _recipient, td);
    }
    updateBlockReward();
    uint256 relayerFee = 0;
    // numOfShares should be larger than 0
    uint256 cycDeno = accumulateCYC.div(numOfShares);
    if (cycDeno > 0) {
      accumulateCYC -= cycDeno;
      safeTransfer(cycToken, _recipient, cycDeno);
    }
    uint256 cd = coinDenomination;
    if (_relayerFee > cd) {
      _relayerFee = cd;
    }
    if (_relayerFee > 0) {
      (bool success,) = _relayer.call.value(_relayerFee)("");
      require(success, "failed to send relayer fee");
      cd -= _relayerFee;
    }
    if (cd > 0) {
      (bool success,) = _recipient.call.value(cd)("");
      require(success, "failed to withdraw coin");
    }
    numOfShares -= 1;
    emit Withdrawal(_recipient, _nullifierHash, _relayer, cycDeno, relayerFee);
  }

  /** @dev whether a note is already spent */
  function isSpent(bytes32 _nullifierHash) public view returns(bool) {
    return nullifierHashes[_nullifierHash];
  }

  /** @dev whether an array of notes is already spent */
  function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns(bool[] memory spent) {
    spent = new bool[](_nullifierHashes.length);
    for(uint i = 0; i < _nullifierHashes.length; i++) {
      if (isSpent(_nullifierHashes[i])) {
        spent[i] = true;
      }
    }
  }

  /**
    @dev allow governance DAO to update SNARK verification keys. This is needed to
    update keys if tornado.cash update their keys in production.
  */
  function updateVerifier(address _newVerifier) external onlyGovDAO {
    verifier = IVerifier(_newVerifier);
  }

  /** @dev governance DAO can change his address */
  function changeGovDAO(address _newGovDAO) external onlyGovDAO {
    govDAO = _newGovDAO;
  }

  function setRewardPerBlock(uint256 _rewardPerBlock) public onlyGovDAO {
    updateBlockReward();
    emit RewardPerBlockUpdated(rewardPerBlock, _rewardPerBlock);
    rewardPerBlock = _rewardPerBlock;
  }

  function setAnonymityFee(uint256 _fee) public onlyGovDAO {
    emit AnonymityFeeUpdated(anonymityFee, _fee);
    anonymityFee = _fee;
  }

  // Safe transfer function, just in case if rounding error causes pool to not have enough CYCs.
  function safeTransfer(IERC20 _token, address _to, uint256 _amount) internal {
    uint256 balance = _token.balanceOf(address(this));
    if (_amount > balance) {
      _token.safeTransfer(_to, balance);
    } else {
      _token.safeTransfer(_to, _amount);
    }
  }

  function version() public pure returns(string memory) {
    return "2.3";
  }

}

pragma solidity <0.6 >=0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */

  /*@CTK SafeMath_mul
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a * b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  /*@CTK SafeMath_div
    @tag spec
    @pre b != 0
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a / b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  /*@CTK SafeMath_sub
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_overflow == true -> __has_assertion_failure == true
    @post __reverted == false -> __return == a - b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  /*@CTK SafeMath_add
    @tag spec
    @post __reverted == __has_assertion_failure
    @post __has_assertion_failure == __has_overflow
    @post __reverted == false -> c == a + b
    @post msg == msg__post
   */
  /* CertiK Smart Labelling, for more details visit: https://certik.org */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity <0.6 >=0.4.21;

import "./IERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 is IERC20Basic {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity <0.6 >=0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract IERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity <0.6 >=0.4.24;

import "./IERC20.sol";

contract IMintableToken is IERC20 {
    function mint(address, uint) external returns (bool);
    function burn(uint) external returns (bool);

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity <0.6 >=0.4.24;

contract IVerifier {
  function verifyProof(bytes memory _proof, uint256[6] memory _input) public returns(bool);
}

pragma solidity <0.6 >=0.4.24;

library Hasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) public pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;

  constructor(uint32 _treeLevels) public {
    require(_treeLevels > 0, "_treeLevels should be greater than zero");
    require(_treeLevels < 32, "_treeLevels should be less than 32");
    levels = _treeLevels;

    bytes32 currentZero = bytes32(ZERO_VALUE);
    zeros.push(currentZero);
    filledSubtrees.push(currentZero);

    for (uint32 i = 1; i < levels; i++) {
      currentZero = hashLeftRight(currentZero, currentZero);
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);
    }

    roots[0] = hashLeftRight(currentZero, currentZero);
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(bytes32 _left, bytes32 _right) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    (R, C) = Hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = Hasher.MiMCSponge(R, C);
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns(uint32 index) {
    uint32 currentIndex = nextIndex;
    require(currentIndex != uint32(2)**levels, "Merkle tree is full. No more leafs can be added");
    nextIndex += 1;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros[i];

        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }

      currentLevelHash = hashLeftRight(left, right);

      currentIndex /= 2;
    }

    currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    roots[currentRootIndex] = currentLevelHash;
    return nextIndex - 1;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns(bool) {
    if (_root == 0) {
      return false;
    }
    uint32 i = currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns(bytes32) {
    return roots[currentRootIndex];
  }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {
      "Hasher": "0x949452e32db13a5771445cf20b304474b866202b"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}