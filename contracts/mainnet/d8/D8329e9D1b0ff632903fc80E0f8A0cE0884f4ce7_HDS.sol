pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

contract HDS {
	using SafeMath for uint256;

	/// @notice EIP-20 token name for this token
	string public constant name = "Hades governance token";

	/// @notice EIP-20 token symbol for this token
	string public constant symbol = "HDS";

	/// @notice EIP-20 token decimals for this token
	uint8 public constant decimals = 8;

	/// @notice Total number of tokens in circulation
	uint256 public totalSupply;

	/// @notice Max supply of tokens
	uint256 public constant maxSupply = 21000000e8; // 21 million

	/// @notice Allowance amounts on behalf of others
	mapping(address => mapping(address => uint256)) internal allowances;

	/// @notice Official record of token balances for each account
	mapping(address => uint256) internal balances;

	/// @notice A record of each accounts delegate
	mapping(address => address) public delegates;

	/// @notice A checkpoint for marking number of votes from a given block
	struct Checkpoint {
		uint32 fromBlock;
		uint256 votes;
	}

	/// @notice A record of votes checkpoints for each account, by index
	mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

	/// @notice The number of checkpoints for each account
	mapping(address => uint32) public numCheckpoints;

	/// @notice The admin address that have the auth to initialize the superior
	address public admin;

	/// @notice The distributor address that have the auth to mint or burn tokens
	address public superior;

	/// @notice The EIP-712 typehash for the contract's domain
	bytes32 public constant DOMAIN_TYPEHASH = keccak256(
		"EIP712Domain(string name,uint256 chainId,address verifyingContract)"
	);

	/// @notice The EIP-712 typehash for the delegation struct used by the contract
	bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

	/// @notice A record of states for signing / validating signatures
	mapping(address => uint256) public nonces;

	/// @notice An event thats emitted when an account changes its delegate
	event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

	/// @notice An event thats emitted when a delegate account's vote balance changes
	event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

	/// @notice The standard EIP-20 transfer event
	event Transfer(address indexed from, address indexed to, uint256 amount);

	/// @notice The standard EIP-20 approval event
	event Approval(address indexed owner, address indexed spender, uint256 amount);

	/// @notice For safety auditor: the superior should be the deployed MarketController contract address
	modifier onlySuperior {
		require(superior == msg.sender, "HDS/permission denied");
		_;
	}

	constructor() public {
		admin = msg.sender;
		uint256 initialSupply = 4200000e8; // 4.2 million
		balances[admin] = initialSupply;
		totalSupply = initialSupply;
	}

	function initialize(address _superior) external {
		require(admin == msg.sender, "HDS/permission denied");
		require(superior == address(0), "HDS/Already initialized");
		superior = _superior;
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
	 * @param amount The number of tokens that are approved (2^256-1 means infinite)
	 * @return Whether or not the approval succeeded
	 */
	function approve(address spender, uint256 amount) external returns (bool) {
		address owner = msg.sender;
		require(spender != address(0), "HDS/approve to zero address");
		allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
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
	 * @param amount The number of tokens to transfer
	 * @return Whether or not the transfer succeeded
	 */
	function transfer(address dst, uint256 amount) external returns (bool) {
		return transferFrom(msg.sender, dst, amount);
	}

	/**
	 * @notice Transfer `amount` tokens from `src` to `dst`
	 * @param src The address of the source account
	 * @param dst The address of the destination account
	 * @param amount The number of tokens to transfer
	 * @return Whether or not the transfer succeeded
	 */
	function transferFrom(
		address src,
		address dst,
		uint256 amount
	) public returns (bool) {
		require(balances[src] >= amount, "HDS/insufficient-balance");
		require(src != address(0), "HDS/transfer from zero address");
		require(dst != address(0), "HDS/transfer to zero address");

		address sender = msg.sender;
		uint256 allowed = allowances[src][sender];
		if (sender != src && allowed != uint256(-1)) {
			require(allowed >= amount, "HDS/insufficient-allowance");
			allowances[src][sender] = allowed.sub(amount);
			emit Approval(src, sender, allowances[src][sender]);
		}
		balances[src] = balances[src].sub(amount);
		balances[dst] = balances[dst].add(amount);
		emit Transfer(src, dst, amount);

		_moveDelegates(delegates[src], delegates[dst], amount);
		return true;
	}

	/**
	 * @notice Mint `amount` tokens for 'src'
	 * @param src The address to receive the mint tokens
	 * @param amount The number of tokens to mint
	 */
	function mint(address src, uint256 amount) external onlySuperior {
		require(totalSupply.add(amount) <= maxSupply, "HDS/Max supply exceeded");
		require(src != address(0), "HDS/mint to zero address");

		balances[src] = balances[src].add(amount);
		totalSupply = totalSupply.add(amount);
		emit Transfer(address(0), src, amount);
	}

	/**
	 * @notice Burn `amount` tokens for 'src'
	 * @param src The address to burn tokens
	 * @param amount The number of tokens to burn
	 */
	function burn(address src, uint256 amount) external {
		require(balances[src] >= amount, "HDS/insufficient-balance");
		require(src != address(0), "HDS/burn from zero address");

		address sender = msg.sender;
		uint256 allowed = allowances[src][sender];
		if (src != sender && allowed != uint256(-1)) {
			require(allowed >= amount, "HDS/insufficient-allowance");
			allowances[src][sender] = allowed.sub(amount);
			emit Approval(src, sender, allowances[src][sender]);
		}
		balances[src] = balances[src].sub(amount);
		totalSupply = totalSupply.sub(amount);
		emit Transfer(src, address(0), amount);
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
	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		bytes32 domainSeparator = keccak256(
			abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
		);
		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
		address signatory = ecrecover(digest, v, r, s);
		require(signatory != address(0), "HDS/ invalid signature");
		require(nonce == nonces[signatory]++, "HDS/ invalid nonce");
		require(now <= expiry, "HDS/signature expired");
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
	function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
		require(blockNumber < block.number, "HDS/not yet determined");

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
		delegates[delegator] = delegatee;
		emit DelegateChanged(delegator, currentDelegate, delegatee);
		_moveDelegates(currentDelegate, delegatee, balances[delegator]);
	}

	function _moveDelegates(
		address srcRep,
		address dstRep,
		uint256 amount
	) internal {
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

	function _writeCheckpoint(
		address delegatee,
		uint32 nCheckpoints,
		uint256 oldVotes,
		uint256 newVotes
	) internal {
		uint32 blockNumber = safe32(block.number, "HDS/Block number overflow");

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

	function getChainId() internal pure returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}
}
