// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;


import './Ownable.sol';


contract Xolo is Ownable {
    /// @notice EIP-20 token name for this token
    string public constant name = "Xolo Inu";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "XL";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 9;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 10000000000 * 10**9; // 10 bil Xolo Inu

    // @notice Total number of tokens that users in black list own
    // We need this for correct calculation of fees (to distribute black listed users share)
    uint public blackListedTokens;

    /// @notice Total number of tokens distributed
    uint public distributed;

    /// @notice feesPercentage% of each transfer is distributed between all holders of Xolo Inu
    uint8 public feesPercentage = 2; // 2%

    mapping (address => mapping (address => uint)) internal allowances;

    mapping (address => uint) internal balances;

    /// @notice Number of tokens from which user has earned fees
    mapping (address => uint) public taxed;

    /// @notice Addresses in this mapping dont receive fees
    mapping (address => bool) public feeBlackList;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emits every time user receive distributed fees
    event feesAccrued(address indexed account, uint256 amount);

    /// @notice Emits every time user pay fees
    event feesPaid(address indexed account, uint256 amount);

    /**
     * @notice Construct a new Xolo Inu token
     */
    constructor(address[] memory initialFeeBlackList) {
        balances[msg.sender] = totalSupply;
        for (uint i = 0; i < initialFeeBlackList.length; i++) {
            addToFeeBlackList(initialFeeBlackList[i]);
        }

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((amount != 0) && (allowances[msg.sender][spender] != 0)), "Xolo Inu::approve: should set allowance to zero first");

        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account] + calculateCollectedFees(account);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        _collectFees(msg.sender);

        require(allowances[src][msg.sender] >= amount, "Xolo Inu::transferFrom: transfer amount exceeds spender allowance");

        uint newAllowance = allowances[src][msg.sender] - amount;
        allowances[src][msg.sender] = newAllowance;

        emit Approval(src, msg.sender, newAllowance);
        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @dev Automically increases the allowance granted to `spender` by the caller.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Automically decreases the allowance granted to `spender` by the caller.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Xolo Inu::decreaseAllowance: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function addToFeeBlackList(address account) public onlyOwner {
        require (!feeBlackList[account], "Xolo Inu::addToFeeBlackList: account is already in fee black list");
        _collectFees(account);
        feeBlackList[account] = true;
        blackListedTokens = blackListedTokens + balances[account];
    }

    function removeFromBlackList(address account) external onlyOwner {
        require (feeBlackList[account], "Xolo Inu::removeFromBlackList: account is not in fee black list");
        feeBlackList[account] = false;
        blackListedTokens = blackListedTokens - balances[account];
    }

    function setFeesPercentage(uint8 number) external onlyOwner {
        require (number < 100, "Xolo Inu::setFeesPercentage: number should be less than 100");
        feesPercentage = number;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        _collectFees(msg.sender);
        return _delegate(msg.sender, delegatee);
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
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Xolo Inu::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Xolo Inu::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "Xolo Inu::delegateBySig: signature expired");
        _collectFees(signatory);
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) external view returns (uint) {
        require(blockNumber < block.number, "Xolo Inu::getPriorVotes: not yet determined");

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

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function calculateCollectedFees(address account) public view returns (uint256) {
        if (feeBlackList[account]) {
            return 0;
        }

        uint to_tax = distributed - taxed[account];
        // multiply by 1e12 to avoid zero rounding
        // we do not count blackListedTokens when calculating share, because black listed users dont receive fees
        uint user_share = balances[account] * 1e12 / (totalSupply - blackListedTokens);
        uint accrued_fees = to_tax * user_share / 1e12;

        return accrued_fees;
    }

    function _collectFees(address account) internal returns (uint256) {
        uint accrued_fees = calculateCollectedFees(account);
        balances[account] = balances[account] + accrued_fees;
        taxed[account] = distributed;

        emit feesAccrued(account, accrued_fees);
        return accrued_fees;
    }

    function _calculateFee(uint256 amount) internal view returns (uint256, uint256) {
        uint fees = amount * feesPercentage / 100;
        return (amount - fees, fees);
    }

    function _distribute(uint256 amount) internal {
        distributed = distributed + amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Xolo Inu::_approve: cannot approve from the zero address");
        require(spender != address(0), "Xolo Inu::_approve: cannot approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "Xolo Inu::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Xolo Inu::_transferTokens: cannot transfer to the zero address");

        // sender collect all fees up to this moment
        _collectFees(src);

        require(balances[src] >= amount, "Xolo Inu::_transferTokens: transfer amount exceeds balance");

        (uint clean_amount, uint fees) = _calculateFee(amount);

        balances[src] = balances[src] - amount;
        if (feeBlackList[src]) {
            blackListedTokens = blackListedTokens - amount;
        }

        // receiver get his fee based on his balance before this transfer
        // sender get his fee based on his balance after this transfer
        _distribute(fees);
        _collectFees(dst);

        balances[dst] = balances[dst] + clean_amount;
        if (feeBlackList[dst]) {
            blackListedTokens = blackListedTokens + clean_amount;
        }

        emit feesPaid(src, fees);
        emit Transfer(src, dst, clean_amount);
        _moveDelegates(delegates[src], delegates[dst], clean_amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld - amount;
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld + amount;
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(uint32(block.number), newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }


    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}