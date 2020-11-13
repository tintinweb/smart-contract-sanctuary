pragma solidity ^0.5.17;


// solhint-disable-next-line compiler-version
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
contract Initializable {
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
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}

library Hasher {
    function poseidon(uint256[] memory inputs)
        public
        pure
        returns (uint256 result);
}

contract MerkleTreeWithHistory is Initializable {
    // The compiler does not reserve a storage slot for constant variables, the optimiser will replace every occurrence
    // of the constant variables in the compiling process. Hence it is okay to initialize these variables here, even
    // this is an upgradable contract
    uint256
        public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256
        public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292;
    uint32 public constant ROOT_HISTORY_SIZE = 100;

    uint32 public levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code
    bytes32[] public filledSubtrees;
    bytes32[] public zeros;
    uint32 public currentRootIndex;
    uint32 public nextIndex;

    bytes32[ROOT_HISTORY_SIZE] public roots;

    // this tree stores two roots
    bytes32 public rewardCurrentRoot;
    uint32 public rewardCurrentBlocknum;
    bytes32 public rewardNextRoot;
    uint32 public rewardNextBlocknum;

    // rewardRoot|--------blockcount-------|nextRewardRoot|----|
    uint32 public blockCount;

    event RewardUpdate(uint32 updateAtBlock, bytes32 newRewardRoot);
    event BlockCountUpdate(uint32 blockCount);

    // DO NOT implement a constructor because this is an upgradable logic.
    // Use the initialize function as a constructor.
    constructor() public {}

    /**
     * @dev The initializer
     */
    function _initialize(uint32 _treeLevels, uint32 _blockCount)
        internal
        initializer
    {
        require(_treeLevels > 0, "_treeLevels should be greater than zero");
        require(_treeLevels < 32, "_treeLevels should be less than 32");
        levels = _treeLevels;

        // new
        blockCount = _blockCount;

        bytes32 currentZero = bytes32(ZERO_VALUE);

        zeros.push(currentZero);

        filledSubtrees.push(currentZero);

        for (uint32 i = 1; i < levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);

        //
        rewardCurrentRoot = roots[0];
        rewardCurrentBlocknum = uint32(block.number);
        rewardNextRoot = roots[0];
        rewardNextBlocknum = uint32(block.number);
    }

    function _setBlockCount(uint32 _blockCount) internal {
        blockCount = _blockCount;
        emit BlockCountUpdate(blockCount);
    }

    // poseidon
    function hashLeftRight(bytes32 _left, bytes32 _right)
        public
        pure
        returns (bytes32)
    {
        uint256[] memory inputs = new uint256[](2);
        inputs[0] = uint256(_left);
        inputs[1] = uint256(_right);
        uint256 output = Hasher.poseidon(inputs);
        return bytes32(output);
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 currentIndex = nextIndex;
        require(
            currentIndex != uint32(2)**levels,
            "Merkle tree is full. No more leafs can be added"
        );
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

        // update roots
        if ((uint32(block.number) - rewardNextBlocknum) >= blockCount) {
            rewardCurrentRoot = rewardNextRoot;
            rewardNextRoot = currentLevelHash;
            // current tree root
            rewardCurrentBlocknum = rewardNextBlocknum;
            rewardNextBlocknum = uint32(block.number);
            emit RewardUpdate(rewardCurrentBlocknum, rewardCurrentRoot);
        }

        return nextIndex - 1;
    }

    /**
      @dev Whether the root is present in the root history
    */
    function isKnownRoot(bytes32 _root) public view returns (bool) {
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

    //
    function isRewardRoot(bytes32 _rroot) public view returns (bool) {
        if (_rroot == 0) {
            return false;
        }
        if (_rroot == rewardCurrentRoot) {
            return true;
        }
        return false;
    }

    /**
      @dev Returns the last root
    */
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }
}

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
contract UpgradableReentrancyGuard {
    // modified from _notEntered to _entered, to make lifer easier for upgrading contracts.
    bool private _entered;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(!_entered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _entered = true;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _entered = false;
    }
}

interface WVerifier {
    function verifyProof(bytes calldata _proof, uint256[7] calldata _input)
        external
        returns (bool);
}

interface RVerifier {
    function verifyProof(bytes calldata _proof, uint256[6] calldata _input)
        external
        returns (bool);
}

contract BlenderCore is MerkleTreeWithHistory, UpgradableReentrancyGuard {
    // Amount of deposit
    uint256 public d_denomination;
    // Amount of reward
    uint256 public r_denomination;
    // Withdraw nullifier list
    mapping(bytes32 => bool) public nullifierHashes;
    // Reward nullifier list
    mapping(bytes32 => bool) public rewardNullifierHashes;
    // Commitments
    mapping(bytes32 => bool) public commitments;
    // withdraw Verifier
    WVerifier public withdrawVerifier;
    // reward verifier
    RVerifier public rewardVerifier;
    // reward counter
    uint32 public rewardCounter;
    // operator can update snark verification key
    // after the final trusted setup ceremony operator rights are supposed to be transferred to zero address
    address public operator;
    modifier onlyOperator {
        require(
            msg.sender == operator,
            "Only operator can call this function."
        );
        _;
    }
    // relayer whitelisting
    bool public relayerWhitelistingEnabled;
    mapping(address => bool) public relayerWhitelist;
    modifier onlyWhitelistedRelayer(address _relayer) {
        if (relayerWhitelistingEnabled) {
            require(relayerWhitelist[_relayer], "Not a whitelisted relayer");
        }
        _;
    }

    address public blnd;

    uint256 public firstStageReward;
    uint256 public secondStageReward;
    uint256 public thirdStageReward;
    uint256 public firstStageDepositors;
    uint256 public secondStageDepositors;

    event Deposit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );
    event Reward(
        address to,
        bytes32 rewardNullifierHash,
        address indexed relayer,
        uint256 fee
    );
    event Withdrawal(
        address to,
        bytes32 withdrawNullifierHash,
        bytes32 rewardNullifierHash,
        address indexed relayer,
        uint256 fee
    );
    event rewardUpdate(uint256 r_denomination, uint32 leafIndex);
    event RelayerUpdate(address relayer, bool permitted);

    // DO NOT implement a constructor because this is an upgradable logic.
    // Use the initialize function as a constructor.
    constructor() public {}

    /**
     * @dev The initializer
     * @param _withdrawVerifier the address of SNARK verifier for this contract
     * @param _rewardVerifier the address of SNARK verifier for this contract
     * @param _d_denomination transfer amount for each deposit
     * @param _merkleTreeHeight the height of deposits Merkle Tree
     * @param _operator operator address (see operator comment above)
     */
    function _initialize(
        WVerifier _withdrawVerifier, // withdraw verifier
        RVerifier _rewardVerifier, // reward verifier
        uint256 _d_denomination,
        uint32 _merkleTreeHeight,
        uint32 _blockCount,
        address _operator,
        address _blnd,
        uint256 _firstStageReward,
        uint256 _secondStageReward,
        uint256 _thirdStageReward,
        uint256 _firstStageDepositors,
        uint256 _secondStageDepositors
    ) internal initializer {
        // call the initialize function of the parent contract (the constructor of the parent contract)
        MerkleTreeWithHistory._initialize(_merkleTreeHeight, _blockCount);
        // constructor logic
        require(
            _d_denomination > 0,
            "Deposit denomination should be greater than 0"
        );
        firstStageReward = _firstStageReward;
        secondStageReward = _secondStageReward;
        thirdStageReward = _thirdStageReward;
        firstStageDepositors = _firstStageDepositors;
        secondStageDepositors = _secondStageDepositors;

        withdrawVerifier = _withdrawVerifier;
        rewardVerifier = _rewardVerifier;
        operator = _operator;
        d_denomination = _d_denomination;
        r_denomination = firstStageReward;
        blnd = _blnd;
    }

    // Should be unchanged
    /**
      @dev Deposit funds into the contract. The caller must send (for ETH) or approve (for ERC20) value equal to or `denomination` of this instance.
      @param _commitment the note commitment, which is PedersenHash(nullifier + secret)
    */
    function deposit(bytes32 _commitment) external payable nonReentrant {
        require(!commitments[_commitment], "The commitment has been submitted");
        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit();
        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /** @dev this function is defined in a child contract */
    function _processDeposit() internal;

    /**
      @dev Withdraw a deposit from the contract. `proof` is a zkSNARK proof data, and input is an array of circuit public inputs
      `input` array consists of:
        - merkle root of all deposits in the contract
        - hash of unique deposit nullifier to prevent double spends
        - the recipient of funds
        - optional fee that goes to the transaction sender (usually a relay)
    */
    function withdraw(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _wdrHash,
        bytes32 _rwdHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant onlyWhitelistedRelayer(_relayer) {
        require(_fee <= d_denomination, "Fee exceeds transfer value");
        require(
            !nullifierHashes[_wdrHash],
            "The withdraw note has been already spent for withdrawing"
        );
        require(
            !nullifierHashes[_rwdHash],
            "The reward note has been already spent for withdrawing"
        );
        require(isKnownRoot(_root), "Cannot find your merkle root");
        // Make sure to use a recent one
        require(
            withdrawVerifier.verifyProof(
                _proof,
                [
                    uint256(_root),
                    uint256(_wdrHash),
                    uint256(_rwdHash),
                    uint256(_recipient),
                    uint256(_relayer),
                    _fee,
                    _refund
                ]
            ),
            "Invalid withdraw proof"
        );
        nullifierHashes[_wdrHash] = true;
        //
        nullifierHashes[_rwdHash] = true;
        //
        rewardNullifierHashes[_rwdHash] = true;
        // cannot obtain reward using this hash anymore
        _processWithdraw(_recipient, _relayer, _fee, _refund);
        emit Withdrawal(_recipient, _wdrHash, _rwdHash, _relayer, _fee);
    }

    function reward(
        bytes calldata _rproof,
        bytes32 _rroot,
        bytes32 _rwdHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant onlyWhitelistedRelayer(_relayer) {
        require(_fee <= r_denomination, "Fee exceeds transfer value");
        require(
            !rewardNullifierHashes[_rwdHash],
            "The reward note has been already redeemed"
        );
        require(isRewardRoot(_rroot), "Cannot find your merkle root");
        // Make sure to use a recent one
        require(
            rewardVerifier.verifyProof(
                _rproof,
                [
                    uint256(_rroot),
                    uint256(_rwdHash),
                    uint256(_recipient),
                    uint256(_relayer),
                    _fee,
                    _refund
                ]
            ),
            "Invalid reward proof"
        );
        // update reward at certain checkpoints
        if (rewardCounter == firstStageDepositors) {
            r_denomination = secondStageReward;
            emit rewardUpdate(r_denomination, rewardCounter);
        }

        if (rewardCounter == secondStageDepositors) {
            r_denomination = thirdStageReward;
            emit rewardUpdate(r_denomination, rewardCounter);
        }
        // cannot obtain reward using this hash anymore
        rewardNullifierHashes[_rwdHash] = true;
        _processReward(_recipient, _relayer, _fee, _refund);
        rewardCounter = rewardCounter + 1;
        emit Reward(_recipient, _rwdHash, _relayer, _fee);
    }

    /** @dev this function is defined in a child contract */
    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal;

    function _processReward(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal {
        require(
            msg.value == _refund,
            "Incorrect refund amount received by the contract"
        );
        SafeERC20.safeTransfer(IERC20(blnd), _recipient, r_denomination - _fee);
        if (_fee > 0) {
            SafeERC20.safeTransfer(IERC20(blnd), _relayer, _fee);
        }
        // to prevent attacker from burning relayer eth in fee
        if (_refund > 0) {
            (bool success, ) = _recipient.call.value(_refund)("");
            if (!success) {
                _relayer.transfer(_refund);
            }
        }
    }

    /** @dev whether a note is already spent */
    // TODO blnd may need to verify two nullifier hashes is needed
    function isSpent(bytes32 _wdrHash) public view returns (bool) {
        return nullifierHashes[_wdrHash];
    }

    function isRedeem(bytes32 _rwdHash) public view returns (bool) {
        return rewardNullifierHashes[_rwdHash];
    }

    /** @dev whether an array of notes is already spent */
    function isSpentArray(bytes32[] calldata _nullifierHashes)
        external
        view
        returns (bool[] memory spent)
    {
        spent = new bool[](_nullifierHashes.length);
        for (uint256 i = 0; i < _nullifierHashes.length; i++) {
            if (isSpent(_nullifierHashes[i])) {
                spent[i] = true;
            }
        }
    }

    /** @dev whether an array of notes is already spent */
    function isRedeemArray(bytes32[] calldata _nullifierHashes)
        external
        view
        returns (bool[] memory redeem)
    {
        redeem = new bool[](_nullifierHashes.length);
        for (uint256 i = 0; i < _nullifierHashes.length; i++) {
            if (isRedeem(_nullifierHashes[i])) {
                redeem[i] = true;
            }
        }
    }

    /**
      @dev allow operator to update SNARK verification keys. This is needed to update keys after the final trusted setup ceremony is held.
      After that operator rights are supposed to be transferred to zero address
    */
    // update withdraw verifier
    function updateWithdrawVerifier(address _newVerifier)
        external
        onlyOperator
    {
        withdrawVerifier = WVerifier(_newVerifier);
    }

    // update reward verifier
    function updateRewardVerifier(address _newVerifier) external onlyOperator {
        rewardVerifier = RVerifier(_newVerifier);
    }

    /** @dev operator can change his address */
    function changeOperator(address _newOperator) external onlyOperator {
        operator = _newOperator;
    }

    /**
     * @dev operator can enable relayer whitelisting
     */
    function enableRelayerWhitelisting() external onlyOperator nonReentrant {
        relayerWhitelistingEnabled = true;
    }

    /**
     * @dev operator can disable relayer whitelisting
     */
    function disableRelayerWhitelisting() external onlyOperator nonReentrant {
        relayerWhitelistingEnabled = false;
    }

    /**
     * @dev operator can add a relayer to the whitelist.
     */
    function addRelayer(address _relayer) external onlyOperator nonReentrant {
        relayerWhitelist[_relayer] = true;
        emit RelayerUpdate(_relayer, relayerWhitelist[_relayer]);
    }

    /**
     * @dev operator can remove a relayer from the whitelist.
     */
    function removeRelayer(address _relayer)
        external
        onlyOperator
        nonReentrant
    {
        relayerWhitelist[_relayer] = false;
        emit RelayerUpdate(_relayer, relayerWhitelist[_relayer]);
    }

    /**
     * @dev operator can change the number of blocks between the current and next reward roots
     */
    function setBlockCount(uint32 _blockCount)
        external
        onlyOperator
        nonReentrant
    {
        _setBlockCount(_blockCount);
    }
}

interface AToken {
    function balanceOf(address _user) external view returns (uint256);

    function redeem(uint256 _amount) external;
}

interface ALendingPool {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;
}

interface ALendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

contract AETHBlender is Initializable, BlenderCore {
    ALendingPoolAddressesProvider public lendingPoolAddressesProvider;
    AToken public aToken;
    address public reserve;
    uint256 public depositors;

    // DO NOT implement a constructor because this is an upgradable logic.
    // Use the initialize function as a constructor.
    constructor() public {}

    function initialize(
        WVerifier _withdrawVerifier,
        RVerifier _rewardVerifier,
        uint256 _d_denomination,
        uint32 _merkleTreeHeight,
        uint32 _blockCount,
        address _operator,
        address _blnd,
        address _aToken,
        address _reserve,
        uint256 _firstStageReward,
        uint256 _secondStageReward,
        uint256 _thirdStageReward,
        uint256 _firstStageDepositors,
        uint256 _secondStageDepositors
    ) public {
        // call the initialize function of the parent contract (the constructor of the parent contract)
        BlenderCore._initialize(
            _withdrawVerifier,
            _rewardVerifier,
            _d_denomination,
            _merkleTreeHeight,
            _blockCount,
            _operator,
            _blnd,
            _firstStageReward,
            _secondStageReward,
            _thirdStageReward,
            _firstStageDepositors,
            _secondStageDepositors
        );
        // constructor logic
        lendingPoolAddressesProvider = ALendingPoolAddressesProvider(
            0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
        );
        aToken = AToken(_aToken);
        reserve = _reserve;
    }

    function _processDeposit() internal {
        require(
            msg.value == d_denomination,
            "Please send `mixDenomination` ETH along with transaction"
        );
        // Deposit all the balance
        uint256 balance = address(this).balance;
        ALendingPool(lendingPoolAddressesProvider.getLendingPool())
            .deposit
            .value(balance)(reserve, balance, 0);
        depositors++;
    }

    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal {
        require(
            msg.value == 0,
            "Message value is supposed to be zero for ETH instance"
        );
        require(
            _refund == 0,
            "Refund value is supposed to be zero for ETH instance"
        );
        require(depositors > 0, "Number of depositors must be positive");

        uint256 beforeBalance = address(this).balance;
        uint256 aBalance = aToken.balanceOf(address(this));
        uint256 redeemAmount = SafeMath.div(aBalance, depositors);
        aToken.redeem(redeemAmount);
        uint256 afterBalance = address(this).balance;
        uint256 redeemedAmount = SafeMath.sub(afterBalance, beforeBalance);

        (bool success, ) = _recipient.call.value(redeemedAmount - _fee)("");
        require(success, "payment to _recipient did not go thru");
        if (_fee > 0) {
            (success, ) = _relayer.call.value(_fee)("");
            require(success, "payment to _relayer did not go thru");
        }
        depositors--;
    }

    function() external payable {}
}