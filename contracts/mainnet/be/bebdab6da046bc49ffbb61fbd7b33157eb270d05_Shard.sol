/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.6.7;

contract Shard {
    /// @notice EIP-20 token name for this token
    string public constant name = "Shard";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "SHARD";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 80_000_000e18; // 80 million Shard

    /// @notice Limit on the totalSupply that can be minted
    uint96 public constant maxSupply = 210_000_000e18; // 210 million Shard

    /// @notice Address which may mint new tokens
    address public minter;

    /// @notice The timestamp after which minting may occur
    uint public mintingAllowedAfter;

    /// @notice Minimum time between mints
    uint32 public constant minimumTimeBetweenMints = 183 days;

    /// @dev Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @dev Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice The EIP-712 typehash for the transfer struct used by the contract
    bytes32 public constant TRANSFER_TYPEHASH = keccak256("Transfer(address to,uint256 value,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the transferWithFee struct used by the contract
    bytes32 public constant TRANSFER_WITH_FEE_TYPEHASH = keccak256("TransferWithFee(address to,uint256 value,uint256 fee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when the minter address is changed
    event MinterChanged(address minter, address newMinter);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Shard token
     * @param account The initial account to grant all the tokens
     * @param minter_ The account with minting ability
     * @param mintingAllowedAfter_ The timestamp after which minting may occur
     */
    constructor(address account, address minter_, uint mintingAllowedAfter_) public {
        require(mintingAllowedAfter_ >= block.timestamp, "Shard::constructor: minting can only begin after deployment");

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        minter = minter_;
        emit MinterChanged(address(0), minter_);
        mintingAllowedAfter = mintingAllowedAfter_;
    }

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external {
        require(msg.sender == minter, "Shard::setMinter: only the minter can change the minter address");
        require(minter_ != address(0), "Shard::setMinter: cannot set minter to the zero address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }

    /**
     * @notice Mint new tokens
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to be minted
     */
    function mint(address dst, uint rawAmount) external {
        require(msg.sender == minter, "Shard::mint: only the minter can mint");
        require(block.timestamp >= mintingAllowedAfter, "Shard::mint: minting not allowed yet");
        require(dst != address(0), "Shard::mint: cannot transfer to the zero address");

        // record the mint
        mintingAllowedAfter = add256(block.timestamp, minimumTimeBetweenMints, "Shard::mint: mintingAllowedAfter overflows");

        // mint the amount
        uint96 amount = safe96(rawAmount, "Shard::mint: amount exceeds 96 bits");
        uint _totalSupply = totalSupply;
        require(amount <= _totalSupply / 100, "Shard::mint: amount exceeds mint allowance");
        _totalSupply = add256(_totalSupply, amount, "Shard::mint: totalSupply overflows");
        require(_totalSupply <= maxSupply, "Shard::mint: totalSupply exceeds maxSupply");
        totalSupply = _totalSupply;

        // transfer the amount to the recipient
        balances[dst] = add96(balances[dst], amount, "Shard::mint: transfer amount overflows");
        emit Transfer(address(0), dst, amount);

        // move delegates
        _moveDelegates(address(0), delegates[dst], amount);
    }

    /**
     * @notice Burn `amount` tokens from `msg.sender`
     * @param rawAmount The number of tokens to burn
     * @return Whether or not the burn succeeded
     */
    function burn(uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Shard::burn: amount exceeds 96 bits");
        _burnTokens(msg.sender, amount);
        return true;
    }

    /**
     * @notice Burn `amount` tokens from `src`
     * @param src The address of the source account
     * @param rawAmount The number of tokens to burn
     * @return Whether or not the burn succeeded
     */
    function burnFrom(address src, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Shard::burnFrom: amount exceeds 96 bits");
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Shard::burnFrom: amount exceeds spender allowance");
            _approve(src, spender, newAllowance);
        }

        _burnTokens(src, amount);
        return true;
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
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Shard::approve: amount exceeds 96 bits");
        }

        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer `amount` extra from `src`
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens to increase the approval by
     * @return Whether or not the approval succeeded
     */
    function increaseAllowance(address spender, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Shard::increaseAllowance: amount exceeds 96 bits");
        uint96 newAllowance = add96(allowances[msg.sender][spender], amount, "Shard::increaseAllowance: allowance overflows");
        _approve(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer `amount` less from `src`
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens to decrease the approval by
     * @return Whether or not the approval succeeded
     */
    function decreaseAllowance(address spender, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Shard::decreaseAllowance: amount exceeds 96 bits");
        uint96 newAllowance = sub96(allowances[msg.sender][spender], amount, "Shard::decreaseAllowance: allowance underflows");
        _approve(msg.sender, spender, newAllowance);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint rawAmount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Shard::permit: amount exceeds 96 bits");
        }

        require(block.timestamp <= deadline, "Shard::permit: signature expired");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline));
        address signatory = ecrecover(getDigest(structHash), v, r, s);
        require(signatory != address(0), "Shard::permit: invalid signature");
        require(signatory == owner, "Shard::permit: unauthorized");

        return _approve(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Shard::transfer: amount exceeds 96 bits");
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
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Shard::transferFrom: amount exceeds 96 bits");
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Shard::transferFrom: amount exceeds spender allowance");
            _approve(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Transfer various `amount` tokens from `msg.sender` to `dsts`
     * @param dsts The addresses of the destination accounts
     * @param rawAmounts The numbers of tokens to transfer
     * @return Whether or not the transfers succeeded
     */
    function transferBatch(address[] calldata dsts, uint[] calldata rawAmounts) external returns (bool) {
        uint length = dsts.length;
        require(length == rawAmounts.length, "Shard::transferBatch: calldata arrays must have the same length");
        for (uint i = 0; i < length; i++) {
            uint96 amount = safe96(rawAmounts[i], "Shard::transferBatch: amount exceeds 96 bits");
            _transferTokens(msg.sender, dsts[i], amount);
        }
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from signatory to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function transferBySig(address dst, uint rawAmount, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount = safe96(rawAmount, "Shard::transferBySig: amount exceeds 96 bits");

        require(block.timestamp <= expiry, "Shard::transferBySig: signature expired");
        bytes32 structHash = keccak256(abi.encode(TRANSFER_TYPEHASH, dst, rawAmount, nonce, expiry));
        address signatory = ecrecover(getDigest(structHash), v, r, s);
        require(signatory != address(0), "Shard::transferBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Shard::transferBySig: invalid nonce");

        return _transferTokens(signatory, dst, amount);
    }

    /**
     * @notice Transfer `amount` tokens from signatory to `dst` with 'fee' tokens to 'feeTo'
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @param rawFee The number of tokens to transfer as fee
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param feeTo The address of the fee recipient account chosen by the msg.sender
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function transferWithFeeBySig(address dst, uint rawAmount, uint rawFee, uint nonce, uint expiry, address feeTo, uint8 v, bytes32 r, bytes32 s) external {
        uint96 amount = safe96(rawAmount, "Shard::transferWithFeeBySig: amount exceeds 96 bits");
        uint96 fee = safe96(rawFee, "Shard::transferWithFeeBySig: fee exceeds 96 bits");

        require(block.timestamp <= expiry, "Shard::transferWithFeeBySig: signature expired");
        bytes32 structHash = keccak256(abi.encode(TRANSFER_WITH_FEE_TYPEHASH, dst, rawAmount, rawFee, nonce, expiry));
        address signatory = ecrecover(getDigest(structHash), v, r, s);
        require(signatory != address(0), "Shard::transferWithFeeBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Shard::transferWithFeeBySig: invalid nonce");

        _transferTokens(signatory, feeTo, fee);
        return _transferTokens(signatory, dst, amount);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
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
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        require(block.timestamp <= expiry, "Shard::delegateBySig: signature expired");
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        address signatory = ecrecover(getDigest(structHash), v, r, s);
        require(signatory != address(0), "Shard::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Shard::delegateBySig: invalid nonce");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
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
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "Shard::getPriorVotes: not yet determined");

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

    function _approve(address owner, address spender, uint96 amount) internal {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnTokens(address src, uint96 amount) internal {
        require(src != address(0), "Shard::_burnTokens: cannot transfer from the zero address");

        balances[src] = sub96(balances[src], amount, "Shard::_burnTokens: transfer amount exceeds balance");
        totalSupply -= amount; // no case where balance exceeds totalSupply
        emit Transfer(src, address(0), amount);

        _moveDelegates(delegates[src], address(0), amount);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Shard::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Shard::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Shard::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Shard::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Shard::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Shard::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Shard::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96 c) {
        require((c = a + b) >= a, errorMessage);
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function add256(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256 c) {
        require((c = a + b) >= a, errorMessage);
    }

    function getDigest(bytes32 structHash) internal view returns (bytes32) {
        uint256 chainId;
        assembly { chainId := chainid() }
        bytes32 domainSeparator =  keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), chainId, address(this)));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}