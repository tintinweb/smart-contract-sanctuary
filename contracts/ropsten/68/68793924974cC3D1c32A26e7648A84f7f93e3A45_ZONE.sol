// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/Ownable.sol";
import "./lib/Global.sol";

contract CompBase is Ownable {
    using SafeMath for uint256;

    /// @notice EIP-20 token name for this token
    string public constant name = "GridZone.io";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "ZONE";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    // Total number of tokens in circulation
    uint256 internal constant _teamSupply = 3360000 * (10 ** uint256(decimals)); // 12%
    uint256 internal constant _advisorsSupply = 980000 * (10 ** uint256(decimals)); // 3.5%
    uint256 internal constant _genesisSupply = 2800000 * (10 ** uint256(decimals)); // 10%
    uint256 internal constant _publicSupply = 420000 * (10 ** uint256(decimals)); // 1.5%
    uint256 internal constant _treasurySupply = 3640000 * (10 ** uint256(decimals)); // 13%
    uint256 internal constant _airdropSupply = 420000 * (10 ** uint256(decimals)); // 1.5%
    uint256 internal constant _ecosystemSupply = 16380000 * (10 ** uint256(decimals)); // 58.5%

    uint256 internal constant _genesisEthCapacity = 100e18; // 100 ETH
    uint256 internal _publicEthCapacity = 2000e18; // 2000 ETH

    uint256 private _totalSupply = 0;
    uint256 private _totalLockedTokens = 0;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    uint256 private constant _cap = _teamSupply + _advisorsSupply + _genesisSupply
        + _publicSupply + _treasurySupply + _airdropSupply + _ecosystemSupply;

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) internal allowances;

    // Official record of token balances for each account
    mapping (address => uint256) internal _balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    // A record of the locked token
    uint8 internal constant LOCK_TYPE_GENESIS = 0;
    uint8 internal constant LOCK_TYPE_BLACKLIST = 1;
    struct LockedToken {
        uint256 id;
        uint8 lockType;
        uint256 amount;
        uint256 start;
        uint256 end;
    }
    mapping(address => LockedToken[]) internal _lockedTokens;
    uint256 private lastLockId = 0;

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

    /// @notice token locked event
    event TokenLocked(address indexed account, uint256 amount, uint8 lockType, uint256 end);
    event TokenUnlocked(address indexed account, uint256 amount, uint8 lockType);

    /**
     * @notice Construct a new GridZone token
     * @param ownerAddress Owner address of the GridZone token
     */
    constructor(address ownerAddress) Ownable(ownerAddress) public {
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply.add(_totalLockedTokens);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public pure returns (uint256) {
        return _cap;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        uint256 amount = _balances[account];
        return amount.add(getLockedAmount(account));
    }

    function getLockedAmount(address account) public view returns (uint256) {
        LockedToken[] memory lockedTokensRef = _lockedTokens[account];
        uint256 length = lockedTokensRef.length;

        uint256 amount = 0;
        for (uint256 i = 0; i < length; i ++) {
            amount = amount.add(lockedTokensRef[i].amount);
        }
        return amount;
    }

    /**
     * @notice Gets the available votes balance for `account` regarding locked token
     * @param account The address to get votes balance
     * @return The number of available votes balance for `account`
     */
    function voteBalanceOf(address account) public view returns (uint256) {
        uint256 amount = _balances[account];

        LockedToken[] memory lockedTokensRef = _lockedTokens[account];
        uint256 length = lockedTokensRef.length;
        for (uint256 i = 0; i < length; i ++) {
            if (lockedTokensRef[i].lockType != LOCK_TYPE_BLACKLIST) {
                amount = amount.add(lockedTokensRef[i].amount);
            }
        }

        return amount;
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint256) {
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
        _approve(_msgSender(), spender, rawAmount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ZONE: approve from the zero address");
        require(spender != address(0), "ZONE: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        _transferTokens(msg.sender, dst, rawAmount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = spenderAllowance.sub(rawAmount);
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, rawAmount);
        return true;
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
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ZONE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ZONE::delegateBySig: invalid nonce");
        require(now <= expiry, "ZONE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
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
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ZONE::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = voteBalanceOf(delegator);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "ZONE::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "ZONE::_transferTokens: cannot transfer to the zero address");

        _beforeTokenTransfer(src, dst, amount);

        _balances[src] = _balances[src].sub(amount);
        _balances[dst] = _balances[dst].add(amount);
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "ZONE::_writeCheckpoint: block number exceeds 32 bits");

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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
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
        require(account != address(0), "ZONE: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);

        _moveDelegates(address(0), delegates[account], amount);
    }

    function _mintLockedToken(address account, uint256 amount, uint8 lockType, uint256 end) internal {
        require(account != address(0), "ZONE: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalLockedTokens = _totalLockedTokens.add(amount);

        LockedToken memory lockedToken = LockedToken({
            id: lastLockId++,
            lockType: lockType,
            amount: amount,
            start: now,
            end: end
        });
        _lockedTokens[account].push(lockedToken);

        emit Transfer(address(0), account, amount);

        if (lockType != LOCK_TYPE_BLACKLIST) {
            _moveDelegates(address(0), delegates[account], amount);
        }
        emit TokenLocked(account, amount, lockType, end);
    }

    function _unlockToken(address account, uint256 lockId) internal {
        LockedToken[] storage lockedTokensRef = _lockedTokens[account];
        uint256 length = lockedTokensRef.length;
        require(0 < length, "ZONE: No locked token");

        bool found = false;
        uint256 index = 0;
        for (uint256 i = 0; i < length; i++) {
            if (lockedTokensRef[i].id == lockId) {
                index = i;
                found = true;
                break;
            }
        }
        require(found == true, "ZONE: lockId invalid");

        uint256 amount = lockedTokensRef[index].amount;
        uint8 lockType = lockedTokensRef[index].lockType;

        _totalLockedTokens = _totalLockedTokens.sub(amount);
        _totalSupply = _totalSupply.add(amount);

        // remove item from list
        uint256 lastIndex = length - 1;
        if (index < lastIndex) {
            lockedTokensRef[index] = lockedTokensRef[lastIndex];
        }
        lockedTokensRef.pop();
        _balances[account] = _balances[account].add(amount);

        if (lockType == LOCK_TYPE_BLACKLIST) {
            _moveDelegates(address(0), delegates[account], amount);
        }
        emit TokenUnlocked(account, amount, lockType);
    }

    function getLockedTokens(address account) external view returns (LockedToken[] memory) {
        LockedToken[] memory lockedTokensRef = _lockedTokens[account];
        return lockedTokensRef;
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
        require(account != address(0), "ZONE: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ZONE: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);

        _moveDelegates(delegates[account], address(0), amount);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) view internal {
        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= _cap, "Capped: cap exceeded");
        }
    }
}


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is CompBase {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public {
        address spender = _msgSender();
        uint256 spenderAllowance = allowances[account][spender];
        uint256 decreasedAllowance = spenderAllowance.sub(amount, "ZONE::burnFrom: burn amount exceeds allowance");

        _approve(account, spender, decreasedAllowance);
        _burn(account, amount);
    }
}

contract ZONE is CompBase, ERC20Burnable {
    using SafeMath for uint256;

    uint256 public immutable launchTime;

    address public immutable vault;

    uint256 private _genesisRate;
    uint256 private _publicRate;
    uint256 public immutable genesisSaleEndTime;
    uint256 public immutable genesisSaleUnlockTime;

    // total purchased eth amount during ICO. The unit is wei
    uint256 public genesisSaleBoughtEth = 0;
    uint256 public publicSaleBoughtEth = 0;

    uint256 public genesisSaleSoldToken = 0;
    uint256 public publicSaleSoldToken = 0;

    bool private _genesisSaleFinished = false;
    bool private _publicSaleFinished = false;

    struct Vest {
        address beneficiary;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 amount;
        uint256 claimedAmount;
        bool revoked;
    }
    mapping (address => Vest) public vests;

    uint16[] private quarterlyRate; // sum is same with quarterlyRateDenominator
    uint16 private constant quarterlyRateDenominator = 10000;
    uint256 public claimedEcosystemVest = 0;

    address private governorTimelock;

    event VestAdded(address indexed beneficiary, uint256 start, uint256 cliff, uint256 duration, uint256 amount);
    event VestClaimed(address indexed beneficiary, uint256 amount);
    event EcosystemVestClaimed(address indexed account, uint256 amount);
    event SoldOnGenesisSale(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event SoldOnPublicSale(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event GenesisSaleFinished(uint256 boughtEth, uint256 soldToken);
    event PublicSaleFinished(uint256 boughtEth, uint256 soldToken);
    event GenesisSaleRateChanged(uint256 newRate);
    event PublicSaleRateChanged(uint256 newRate);
    event PublicSaleEthCapacityChanged(uint256 newRate, uint256 newEthCapacity);

    constructor(address owner_, address vault_, address advisors_, address treasury_) CompBase(owner_) public {
        require(owner_ != vault_, "ZONE: You specified owner address as an vault address");
        launchTime = now;
        quarterlyRate = [3182, 2676, 2250, 1892];

        vault = vault_;

        _genesisRate = _genesisSupply.mul(10).div(_genesisEthCapacity).div(12); // 2/12 is for bonuses
        _publicRate = _publicSupply.div(_publicEthCapacity);
        genesisSaleEndTime = now + GLOBAL.SECONDS_IN_MONTH * 3;
        genesisSaleUnlockTime = now + GLOBAL.SECONDS_IN_MONTH * 4;

        AddVest(owner_, now, 0, GLOBAL.SECONDS_IN_YEAR * 2, _teamSupply);
        AddVest(advisors_, now, 0, GLOBAL.SECONDS_IN_YEAR, _advisorsSupply);

        _mintLockedToken(treasury_, _treasurySupply, LOCK_TYPE_BLACKLIST, now + GLOBAL.SECONDS_IN_YEAR);
        _mint(vault_, _airdropSupply);
    }

    modifier onlyCommunity() {
        require(msg.sender == governorTimelock, "ZONE: The caller is not the governance timelock contract.");
        _;
    }

    modifier onlyEndUser {
        require(msg.sender == tx.origin, "ZONE: Only end-user");
        _;
    }

    function setGovernorTimelock(address governorTimelock_) external onlyOwner  {
        governorTimelock = governorTimelock_;
    }

    /**
    * @param beneficiary address of the beneficiary to whom vested tokens are transferred
    * @param cliff duration in seconds of the cliff in which tokens will begin to vest
    * @param duration duration in seconds of the period in which the tokens will vest
    */
    function AddVest(address beneficiary, uint256 start, uint256 cliff, uint256 duration, uint256 amount) internal {
        require(beneficiary != address(0), "ZONE::AddVest Invalid beneficiary");
        require(cliff <= duration, "ZONE::AddVest cliff > duration");

        Vest memory vest = Vest({
            beneficiary: beneficiary,
            start: start,
            cliff: start.add(cliff),
            duration: duration,
            amount: amount,
            claimedAmount: 0,
            revoked: false
        });

        vests[beneficiary] = vest;
        emit VestAdded(beneficiary, start, cliff, duration, amount);
    }

    function calculateVestClaim(address beneficiary) public view returns (uint256 vestedAmount, uint256 claimedAmount) {
        Vest storage vest = vests[beneficiary];
        if (vest.beneficiary != beneficiary) {
            // Invalid beneficiary
            return (0, 0);
        }

        if (now < vest.cliff) {
            // For vest created with a future start date, that hasn't been reached, return 0, 0
            return (0, vest.claimedAmount);
        } else if (vest.revoked == true) {
            return (vest.claimedAmount, vest.claimedAmount);
        } else if (vest.start.add(vest.duration) <= now) {
            return (vest.amount, vest.claimedAmount);
        } else {
            vestedAmount = vest.amount.mul(now.sub(vest.start)).div(vest.duration);
            return (vestedAmount, vest.claimedAmount);
        }
    }

    function claimVestedToken(address beneficiary) external {
        (uint256 vested, uint256 claimed) = calculateVestClaim(beneficiary);
        require(claimed < vested, "ZONE: No claimable token");

        uint256 fund = vested.sub(claimed);
        vests[beneficiary].claimedAmount = vested;
        _mint(beneficiary, fund);
        emit VestClaimed(beneficiary, fund);
    }

    function revokeVest(address beneficiary) external onlyCommunity {
        Vest storage vest = vests[beneficiary];
        require(vest.beneficiary == beneficiary, "ZONE: Invalid beneficiary");
        require(vest.revoked == false, "ZONE: Already revoked");

        uint256 fund = vest.amount.sub(vest.claimedAmount);
        if (0 < fund) {
            vest.claimedAmount = vest.amount;
            _mint(beneficiary, fund);
            emit VestClaimed(beneficiary, fund);
        }
        vest.revoked = true;
    }

    //
    // Unlock token
    //
    function getUnlockableAmount(address account) public view returns (uint256) {
        LockedToken[] memory lockedTokensRef = _lockedTokens[account];
        uint256 length = lockedTokensRef.length;

        uint256 amount = 0;
        for (uint256 i = 0; i < length; i ++) {
            if (_isUnlockable(lockedTokensRef[i].lockType, lockedTokensRef[i].end) == true) {
                amount = amount.add(lockedTokensRef[i].amount);
            }
        }
        return amount;
    }

    function Unlock(address account) public returns (uint256) {
        LockedToken[] memory lockedTokensRef = _lockedTokens[account];
        uint256 length = lockedTokensRef.length;
        bool unlocked = false;

        for (uint256 i = 0; i < length; i ++) {
            if (_isUnlockable(lockedTokensRef[i].lockType, lockedTokensRef[i].end) == true) {
                _unlockToken(account, lockedTokensRef[i].id);
                unlocked = true;
            }
        }
        require(unlocked, "ZONE: No unlockable token.");
    }

    function _isUnlockable(uint8 lockType, uint256 end) internal view returns (bool) {
        if (end <= now) {
            return true;
        }
        if ((lockType == LOCK_TYPE_GENESIS) && _publicSaleFinished) {
            return true;
        }
        return false;
    }

    function revokeBlacklistLock(address account) external onlyCommunity {
        LockedToken[] memory lockedTokensRef = _lockedTokens[account];
        uint256 length = lockedTokensRef.length;

        for (uint256 i = 0; i < length; i ++) {
            if (lockedTokensRef[i].lockType == LOCK_TYPE_BLACKLIST) {
                _unlockToken(account, lockedTokensRef[i].id);
            }
        }
    }

    //
    // Quarterly vesting for ecosystem
    //
    function calculateEcosystemVested() public view returns (uint256 vestedAmount) {
        uint256 quartersCount = now.sub(launchTime).div(GLOBAL.SECONDS_IN_QUARTER);
        uint256 yearsCount = quartersCount.div(GLOBAL.QUARTERS_IN_YEAR);
        uint256 currentQurter = quartersCount.mod(GLOBAL.QUARTERS_IN_YEAR);
        uint256 yearSupply = _ecosystemSupply >> (yearsCount + 1);

        if (0 < yearsCount) {
            // _ecosystemSupply * (1 - 1 / (2*yearsCount))
            vestedAmount =  _ecosystemSupply.sub(_ecosystemSupply.div(2).div(yearsCount));
        } else {
            vestedAmount = 0;
        }

        for (uint8 quarter = 0; quarter <= currentQurter; quarter ++) {
            uint256 vestedInQuarter = yearSupply.mul(quarterlyRate[quarter]).div(quarterlyRateDenominator);
            vestedAmount = vestedAmount.add(vestedInQuarter);
        }
        return vestedAmount;
    }

    function claimEcosystemVest() external {
        uint256 vested = calculateEcosystemVested();
        require (claimedEcosystemVest < vested, "ZONE: No claimable token for the ecosystem.");

        uint256 fund = vested.sub(claimedEcosystemVest);
        claimedEcosystemVest = vested;
        _mint(vault, fund);
        emit EcosystemVestClaimed(vault, fund);
    }

    function revokeEcosystemVest() external onlyCommunity {
        require (claimedEcosystemVest < _ecosystemSupply, "ZONE: All tokens already have been claimed for the ecosystem.");

        uint256 fund = _ecosystemSupply.sub(claimedEcosystemVest);
        claimedEcosystemVest = _ecosystemSupply;
        _mint(vault, fund);
        emit EcosystemVestClaimed(vault, fund);
    }

    //
    // Genesis and Public sale
    //
    function isGenesisSaleFinished() external view returns (bool) {
        if (_genesisSaleFinished == true || genesisSaleEndTime <= now) {
            return true;
        }
        return false;
    }

    function isPublicSaleFinished() external view returns (bool) {
        return _publicSaleFinished;
    }

    // Crowds Sale contains both the Genesis sale and the Public sale
    function isCrowdsaleFinished() external view returns (bool) {
        if (_publicSaleFinished) return true;
        if (genesisSaleEndTime <= now) return false;
        if (_genesisSaleFinished) return true;
        return false;
    }

    function rate() public view returns (uint256) {
        return (now < genesisSaleEndTime) ? _genesisRate : _publicRate;
    }

    function getGenesisSaleRate() external view returns(uint256) {
        return _genesisRate;
    }

    function setGenesisSaleRate(uint256 newRate) external onlyOwner {
        require(0 < newRate, "ZONE: The rate can't be 0.");
        _genesisRate = newRate;
        emit GenesisSaleRateChanged(_genesisRate);
    }

    function getPublicSaleRate() external view returns(uint256) {
        return _publicRate;
    }

    function setPublicSaleRate(uint256 newRate) public onlyOwner {
        require(0 < newRate, "ZONE: The rate can't be 0.");
        _publicRate = newRate;
        emit PublicSaleRateChanged(_publicRate);
    }

    function getPublicSaleEthCapacity() external view returns(uint256) {
        return _publicEthCapacity;
    }

    function setPublicSaleEthCapacity(uint256 newEthCapacity) public onlyOwner {
        require(publicSaleBoughtEth < newEthCapacity, "ZONE: The capacity must be greater than the already bought amount in the public sale.");

        _publicRate = _publicSupply.sub(publicSaleSoldToken).div(newEthCapacity.sub(publicSaleBoughtEth));
        _publicEthCapacity = newEthCapacity;
        emit PublicSaleEthCapacityChanged(_publicRate, _publicEthCapacity);
    }

    function finishCrowdsale() external onlyOwner  {
        _finishGenesisSale();
       if (genesisSaleEndTime <= now) {
           _finishPublicSale();
       }
    }
    
    function _finishGenesisSale() private {
        if (_genesisSaleFinished) return;
        _genesisSaleFinished = true;

        uint256 leftOver = _genesisSupply.sub(genesisSaleSoldToken);
        if (leftOver > 0) {
            _mint(owner(), leftOver);
        }
        emit GenesisSaleFinished(genesisSaleBoughtEth, genesisSaleSoldToken);
    }

    function _finishPublicSale() private {
        if (_publicSaleFinished) return;
        _publicSaleFinished = true;

        uint256 leftOver = _publicSupply.sub(publicSaleSoldToken);
        if (leftOver > 0) {
            _mint(owner(), leftOver);
        }
        emit PublicSaleFinished(publicSaleBoughtEth, publicSaleSoldToken);
    }

    function _sellOnGenesisSale(address payable buyer, uint256 ethAmount) private {
        uint256 capacity = _genesisEthCapacity.sub(genesisSaleBoughtEth);
        uint256 _ethAmount = (ethAmount < capacity) ? ethAmount : capacity;
        uint256 refund = ethAmount - _ethAmount;
        require(0 < _ethAmount, "ZONE: The amount can't be 0.");

        uint256 amount = _ethAmount.mul(_genesisRate);
        uint256 genesisBonus = amount.div(10);   // when buying during Genesis sale, 10% bonus
        uint256 purchaseBonus = 0;

        if (_ethAmount >= 10e18) {
            // when buying for over 10eth, 10% bonus
            purchaseBonus = amount.div(10);
        }

        // total token amount
        amount = amount.add(genesisBonus).add(purchaseBonus);

        genesisSaleBoughtEth = genesisSaleBoughtEth.add(_ethAmount);
        genesisSaleSoldToken = genesisSaleSoldToken.add(amount);
        require(genesisSaleSoldToken <= _genesisSupply, "ZONE: Genesis supply is insufficient.");

        // mint token amount and bonuses to buyer
        _mintLockedToken(buyer, amount, LOCK_TYPE_GENESIS, genesisSaleUnlockTime);

        address payable ownerAddress = address(uint160(owner()));
        ownerAddress.transfer(_ethAmount);
        emit SoldOnGenesisSale(buyer, _ethAmount, amount);

        if (0 < refund) {
            buyer.transfer(refund);
        }
        if (_genesisEthCapacity <= genesisSaleBoughtEth) {
            _finishGenesisSale();
        }
    }

    function _sellOnPublicSale(address payable buyer, uint256 ethAmount) private {
        uint256 capacity = _publicEthCapacity.sub(publicSaleBoughtEth);
        uint256 _ethAmount = (ethAmount < capacity) ? ethAmount : capacity;
        uint256 refund = ethAmount - _ethAmount;
        require(0 < _ethAmount, "ZONE: The amount can't be 0.");

        uint256 amount = _ethAmount.mul(_publicRate);

        publicSaleBoughtEth = publicSaleBoughtEth.add(_ethAmount);
        publicSaleSoldToken = publicSaleSoldToken.add(amount);
        require(publicSaleSoldToken <= _publicSupply, "ZONE: Public supply is insufficient.");

        // mint token amount to buyer
        _mint(buyer, amount);

        address payable ownerAddress = address(uint160(owner()));
        ownerAddress.transfer(_ethAmount);
        emit SoldOnPublicSale(buyer, _ethAmount, amount);

        if (0 < refund) {
            buyer.transfer(refund);
        }
        if (_publicEthCapacity <= publicSaleBoughtEth) {
            _finishPublicSale();
        }
    }

    // low level token purchase function
    function purchase() external payable onlyEndUser {
        address payable buyer = _msgSender();
        require(buyer != address(0));
        require(msg.value >= 1e16, "ZONE: The purchase minimum amount is 0.01 ETH");

        if (now < genesisSaleEndTime) {
            require(_genesisSaleFinished == false, "ZONE: Genesis sale already finished");
            _sellOnGenesisSale(buyer, msg.value);
        } else {
            _finishGenesisSale();

            require(_publicSaleFinished == false, "ZONE: Public sale already finished");
            _sellOnPublicSale(buyer, msg.value);
        }
    }

    receive() external payable {
        require(false, "ZONE: Use the purchase function to buy the ZONE token.");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;
    address private _pendingOwner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address owner) internal {
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
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
        _pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "acceptOwnership: Call must come from pendingOwner.");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library GLOBAL {
    uint256 constant SECONDS_IN_YEAR = 365 * 24 * 3600; // 365 days * 24 hours * 60 minutes * 60 seconds
    uint256 constant SECONDS_IN_QUARTER = SECONDS_IN_YEAR / 4;
    uint256 constant SECONDS_IN_MONTH = 30 * 24 * 3600; // 30 days * 24 hours * 60 minutes * 60 seconds

    uint8 constant QUARTERS_IN_YEAR = 4;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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