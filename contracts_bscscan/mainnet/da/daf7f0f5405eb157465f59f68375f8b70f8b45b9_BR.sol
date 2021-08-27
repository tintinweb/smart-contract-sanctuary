/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/*

Bloody Revenge is a chaotic first-person melee combat game set in different locations and periods and featuring a massive Rogue-Like adventure. 
The voxel-based enemies can be punched, bashed, kicked, stabbed, and sliced completely dynamically with anything that isn't nailed down.

Total Supply: 160 Billion 
Starting Market Cap: $200,000 
Listing Price: $0.00005
Website Whitelist Pre-sale & Unicrypt Public Pre-sale 

Bloody Revenge Official links 🌏

🌐 | Website (https://bloodyrevenge.io/)
🗒 | Certik Audit Processing  (https://blockaudit.report/projects/BloodyRevenge)
📣 | Announcements (hhttps://t.me/BloodyRevenge_Channel)
🕊️ | Twitter https://twitter.com/BloodyROfficial)
💬 | Telegram (hhttps://t.me/BloodyRevenge_Global)m

*/
pragma solidity ^0.5.16;

interface IStakeModifier {
    function getVotingPower(address user, uint256 votes) external view returns(uint256);
}

contract BR {
    /// @notice EIP-20 token name for this token
    string public constant name = "BloodyRevenge";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "BR";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Initial number of tokens in circulation
    uint256 public totalSupply = 0;

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
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

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Admin can update admin, minter and stake modifier
    address public admin;

    /// @notice Minter can call mint() function
    address public minter;

    /// @notice Interface for receiving voting power data
    IStakeModifier public stakeModifier;

    /**
     * @dev Modifier to make a function callable only by the admin.
     */
    modifier adminOnly() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    /**
     * @dev Modifier to make a function callable only by the minter.
     */
    modifier minterOnly() {
        require(msg.sender == minter, "Only minter");
        _;
    }

    /// @notice Emitted when changing admin
    event SetAdmin(address indexed newAdmin, address indexed oldAdmin);

    /// @notice Emitted when changing minter
    event SetMinter(address indexed newMinter, address indexed oldAdmin);

    /// @notice Event used for cross-chain transfers
    event BridgeTransfer(address indexed sender, address indexed receiver, uint256 amount, string externalAddress);

    /// @notice Emitted when stake modifier address is updated
    event SetStakeModifier(address indexed newStakeModifier, address indexed oldStakeModifier);

    /**
     * @notice Construct a new Comp token
     * @param adminAddress The address with admin rights
     * @param minterAddress The address with minter rights
     * @param stakeModifierAddress The address of stakeModifier contract
     */
     constructor(address adminAddress, address minterAddress, address stakeModifierAddress) public {
         admin = adminAddress;
         minter = minterAddress;

         stakeModifier = IStakeModifier(stakeModifierAddress);
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
    function approve(address spender, uint256 rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "BR::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
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
    function transfer(address dst, uint256 rawAmount) public returns (bool) {
        uint96 amount = safe96(rawAmount, "BR::transfer: amount exceeds 96 bits");
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
    function transferFrom(address src, address dst, uint256 rawAmount) public returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "BR::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "BR::transferFrom: transfer amount exceeds spender allowance");
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
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "BR::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "BR::delegateBySig: invalid nonce");
        require(now <= expiry, "BR::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        uint96 votes = nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
        return getModifiedVotes(account, votes);
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "BR::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            uint96 votes = checkpoints[account][nCheckpoints - 1].votes;
            return getModifiedVotes(account, votes);
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
        uint96 votes = checkpoints[account][lower].votes;
        return getModifiedVotes(account, votes);
    }

    /**
     * @notice Determines the number of votes an account has after modifications by the StakeModifier
     * @param account The address of the account to check
     * @param votes The initial, unmodified number of votes, read from storage
     */
    function getModifiedVotes(address account, uint96 votes) internal view returns (uint96) {
        if (address(stakeModifier) == address(0)){
            return votes;
        }
        return safe96(stakeModifier.getVotingPower(account, votes), "BR::getModifiedVotes: amount exceeds 96 bits");
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "BR::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "BR::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "BR::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "BR::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "BR::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "BR::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "BR::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * @notice Set new admin address
     * @param newAdmin New admin address
     */
    function setAdmin(address newAdmin) external adminOnly {
        emit SetAdmin(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @notice Set new minter address
     * @param newMinter New minter address
     */
    function setMinter(address newMinter) external adminOnly {
        emit SetMinter(newMinter, minter);
        minter = newMinter;
    }

    /**
     * @notice Set new stake modifier address
     * @param newStakeModifier New stake modifer contract address
     */
    function setStakeModifier(address newStakeModifier) external adminOnly {
        emit SetStakeModifier(newStakeModifier, address(stakeModifier));
        stakeModifier = IStakeModifier(newStakeModifier);
    }

    /**
     * @notice Mint additional tokens
     * @param toAccount Account receiving new tokens
     * @param amount Amount of minted tokens
     */
    function mint(address toAccount, uint256 amount) external minterOnly {
        _mint(toAccount, amount);
    }

    /**
     * @notice Mint additional tokens
     * @param account The address of the account to check
     * @param amount The amount of tokens minted
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += uint96(amount);
        balances[account] = safe96(uint256(balances[account]) + amount, "BR::_mint: amount exceeds 96 bits");
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Transfer tokens to cross-chain bridge
     * @param bridgeAddress The address of the bridge account
     * @param rawAmount The amount of tokens transfered
     * @param externalAddress The address on another chain
     */
     function bridgeTransfer(address bridgeAddress, uint256 rawAmount, string calldata externalAddress) external returns(bool) {
         emit BridgeTransfer(msg.sender, bridgeAddress, rawAmount, externalAddress);
         transfer(bridgeAddress, rawAmount);
     }

     /**
      * @notice Transfer tokens from address to cross-chain bridge
      * @param sourceAddress The address of the source account
      * @param bridgeAddress The address of the bridge account
      * @param rawAmount The amount of tokens transfered
      * @param externalAddress The address on another chain
      */
     function bridgeTransferFrom(address sourceAddress, address bridgeAddress, uint256 rawAmount, string calldata externalAddress) external returns(bool) {
         emit BridgeTransfer(sourceAddress, bridgeAddress, rawAmount, externalAddress);
         transferFrom(sourceAddress, bridgeAddress, rawAmount);
     }
}