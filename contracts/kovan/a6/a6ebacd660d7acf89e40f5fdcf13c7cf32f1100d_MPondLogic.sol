/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// File: @openzeppelin/upgrades/contracts/Initializable.sol

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
contract Initializable {

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

// File: contracts/governance/MPondLogic.sol

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;



contract MPondLogic is Initializable {
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 token decimals for this token
    uint8 public decimals;

    /// @notice Total number of tokens in circulation
    uint256 public totalSupply; // 10k MPond
    uint256 public bridgeSupply; // 3k MPond

    address public dropBridge;
    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => mapping(address => uint96)) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public DOMAIN_TYPEHASH;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public DELEGATION_TYPEHASH;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public UNDELEGATION_TYPEHASH;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// customized params
    address public admin;
    mapping(address => bool) public isWhiteListed;
    bool public enableAllTranfers;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @notice Initializer a new MPond token
     * @param account The initial account to grant all the tokens
     */
    function initialize(
        address account,
        address bridge,
        address dropBridgeAddress
    ) public initializer {
        createConstants();
        require(
            account != bridge,
            "Bridge and account should not be the same address"
        );
        balances[bridge] = uint96(bridgeSupply);
        delegates[bridge][address(0)] = uint96(bridgeSupply);
        isWhiteListed[bridge] = true;
        emit Transfer(address(0), bridge, bridgeSupply);

        uint96 remainingSupply = sub96(
            uint96(totalSupply),
            uint96(bridgeSupply),
            "MPond: Subtraction overflow in the constructor"
        );
        balances[account] = remainingSupply;
        delegates[account][address(0)] = remainingSupply;
        isWhiteListed[account] = true;
        dropBridge = dropBridgeAddress;
        emit Transfer(address(0), account, uint256(remainingSupply));
    }

    function createConstants() internal {
        name = "Marlin";
        symbol = "MPond";
        decimals = 18;
        totalSupply = 10000e18;
        bridgeSupply = 7000e18;
        DOMAIN_TYPEHASH = keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
        DELEGATION_TYPEHASH = keccak256(
            "Delegation(address delegatee,uint256 nonce,uint256 expiry,uint96 amount)"
        );
        UNDELEGATION_TYPEHASH = keccak256(
            "Unelegation(address delegatee,uint256 nonce,uint256 expiry,uint96 amount)"
        );
        admin = msg.sender;
        // enableAllTranfers = true; //This is only for testing, will be false
    }

    function addWhiteListAddress(address _address)
        external
        onlyAdmin("Only admin can whitelist")
        returns (bool)
    {
        isWhiteListed[_address] = true;
        return true;
    }

    function removeWhiteListAddress(address _address)
        external
        onlyAdmin("Only admin can remove from whitelist")
        returns (bool)
    {
        isWhiteListed[_address] = false;
        return true;
    }

    function enableAllTransfers()
        external
        onlyAdmin("Only admin can enable all transfers")
        returns (bool)
    {
        enableAllTranfers = true;
        return true;
    }

    function disableAllTransfers()
        external
        onlyAdmin("Only admin can disable all transfers")
        returns (bool)
    {
        enableAllTranfers = false;
        return true;
    }

    function changeDropBridge(address _updatedBridge)
        public
        onlyAdmin("Only admin can change drop bridge")
    {
        dropBridge = _updatedBridge;
    }

    function isWhiteListedTransfer(address _address1, address _address2)
        public
        view
        returns (bool)
    {
        if (
            enableAllTranfers ||
            isWhiteListed[_address1] ||
            isWhiteListed[_address2]
        ) {
            return true;
        } else if (_address1 == dropBridge) {
            return true;
        }
        return false;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                rawAmount,
                "MPond::approve: amount exceeds 96 bits"
            );
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (addedAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                addedAmount,
                "MPond::approve: addedAmount exceeds 96 bits"
            );
        }

        allowances[msg.sender][spender] = add96(
            allowances[msg.sender][spender],
            amount,
            "MPond: increaseAllowance allowance value overflows"
        );
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 removedAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (removedAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(
                removedAmount,
                "MPond::approve: removedAmount exceeds 96 bits"
            );
        }

        allowances[msg.sender][spender] = sub96(
            allowances[msg.sender][spender],
            amount,
            "MPond: decreaseAllowance allowance value underflows"
        );
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        require(
            isWhiteListedTransfer(msg.sender, dst),
            "Atleast one of the address (src or dst) should be whitelisted or all transfers must be enabled via enableAllTransfers()"
        );
        uint96 amount = safe96(
            rawAmount,
            "MPond::transfer: amount exceeds 96 bits"
        );
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        require(
            isWhiteListedTransfer(src, dst),
            "Atleast one of the address (src or dst) should be whitelisted or all transfers must be enabled via enableAllTransfers()"
        );
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(
            rawAmount,
            "MPond::approve: amount exceeds 96 bits"
        );

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "MPond::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee, uint96 amount) public {
        return _delegate(msg.sender, delegatee, amount);
    }

    function undelegate(address delegatee, uint96 amount) public {
        return _undelegate(msg.sender, delegatee, amount);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint96 amount
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "MPond::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "MPond::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "MPond::delegateBySig: signature expired");
        return _delegate(signatory, delegatee, amount);
    }

    function undelegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint96 amount
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(UNDELEGATION_TYPEHASH, delegatee, nonce, expiry, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "MPond::undelegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "MPond::undelegateBySig: invalid nonce"
        );
        require(now <= expiry, "MPond::undelegateBySig: signature expired");
        return _undelegate(signatory, delegatee, amount);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints != 0
                ? checkpoints[account][nCheckpoints - 1].votes
                : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        require(
            blockNumber < block.number,
            "MPond::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(
        address delegator,
        address delegatee,
        uint96 amount
    ) internal {
        delegates[delegator][address(0)] = sub96(
            delegates[delegator][address(0)],
            amount,
            "MPond: delegates underflow"
        );
        delegates[delegator][delegatee] = add96(
            delegates[delegator][delegatee],
            amount,
            "MPond: delegates overflow"
        );

        emit DelegateChanged(delegator, address(0), delegatee);

        _moveDelegates(address(0), delegatee, amount);
    }

    function _undelegate(
        address delegator,
        address delegatee,
        uint96 amount
    ) internal {
        delegates[delegator][delegatee] = sub96(
            delegates[delegator][delegatee],
            amount,
            "MPond: undelegates underflow"
        );
        delegates[delegator][address(0)] = add96(
            delegates[delegator][address(0)],
            amount,
            "MPond: delegates underflow"
        );
        emit DelegateChanged(delegator, delegatee, address(0));
        _moveDelegates(delegatee, address(0), amount);
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            src != address(0),
            "MPond::_transferTokens: cannot transfer from the zero address"
        );
        require(
            delegates[src][address(0)] >= amount,
            "MPond: _transferTokens: undelegated amount should be greater than transfer amount"
        );
        require(
            dst != address(0),
            "MPond::_transferTokens: cannot transfer to the zero address"
        );

        balances[src] = sub96(
            balances[src],
            amount,
            "MPond::_transferTokens: transfer amount exceeds balance"
        );
        delegates[src][address(0)] = sub96(
            delegates[src][address(0)],
            amount,
            "MPond: _tranferTokens: undelegate subtraction error"
        );

        balances[dst] = add96(
            balances[dst],
            amount,
            "MPond::_transferTokens: transfer amount overflows"
        );
        delegates[dst][address(0)] = add96(
            delegates[dst][address(0)],
            amount,
            "MPond: _transferTokens: undelegate addition error"
        );
        emit Transfer(src, dst, amount);

        // _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount != 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum != 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint96 srcRepNew = sub96(
                    srcRepOld,
                    amount,
                    "MPond::_moveVotes: vote amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum != 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint96 dstRepNew = add96(
                    dstRepOld,
                    amount,
                    "MPond::_moveVotes: vote amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "MPond::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints != 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    modifier onlyAdmin(string memory _error) {
        require(msg.sender == admin, _error);
        _;
    }
}