/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity ^0.5.16;


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
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: @openzeppelin/contracts/access/Ownable.sol
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
contract Ownable is Context {
    address private _owner;
    address private _authorizedNewOwner;
    event OwnershipTransferAuthorization(address indexed authorizedAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Returns the address of the current authorized new owner.
     */
    function authorizedNewOwner() public view returns (address) {
        return _authorizedNewOwner;
    }
    /**
     * @notice Authorizes the transfer of ownership from _owner to the provided address.
     * NOTE: No transfer will occur unless authorizedAddress calls assumeOwnership( ).
     * This authorization may be removed by another call to this function authorizing
     * the null address.
     *
     * @param authorizedAddress The address authorized to become the new owner.
     */
    function authorizeOwnershipTransfer(address authorizedAddress) external onlyOwner {
        _authorizedNewOwner = authorizedAddress;
        emit OwnershipTransferAuthorization(_authorizedNewOwner);
    }
    /**
     * @notice Transfers ownership of this contract to the _authorizedNewOwner.
     */
    function assumeOwnership() external {
        require(_msgSender() == _authorizedNewOwner, "Ownable: only the authorized new owner can accept ownership");
        emit OwnershipTransferred(_owner, _authorizedNewOwner);
        _owner = _authorizedNewOwner;
        _authorizedNewOwner = address(0);
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * @param confirmAddress The address wants to give up ownership.
     */
    function renounceOwnership(address confirmAddress) public onlyOwner {
        require(confirmAddress == _owner, "Ownable: confirm address is wrong");
        emit OwnershipTransferred(_owner, address(0));
        _authorizedNewOwner = address(0);
        _owner = address(0);
    }
}

contract ANN is Ownable {
    /// @notice BEP-20 token name for this token
    string public constant name = "Annex";

    /// @notice BEP-20 token symbol for this token
    string public constant symbol = "ANN";

    /// @notice BEP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 1000000000e18; // 1 billion ANN

    /// @notice Reward eligible epochs
    uint32 public constant eligibleEpochs = 30; // 30 epochs

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

    /// @notice A transferPoint for marking balance from given epoch
    struct TransferPoint {
        uint32 epoch;
        uint96 balance;
    }

    /// @notice A epoch config for blocks or ROI per epoch
    struct EpochConfig {
        uint32 epoch;
        uint32 blocks;
        uint32 roi;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice A record of transfer checkpoints for each account
    mapping (address => mapping (uint32 => TransferPoint)) public transferPoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The number of transferPoints for each account
    mapping (address => uint32) public numTransferPoints;

    /// @notice The claimed amount for each account
    mapping (address => uint96) public claimedAmounts;

    /// @notice Configs for epoch
    EpochConfig[] public epochConfigs;

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

    /// @notice An event thats emitted when a transfer point balance changes
    // event TransferPointChanged(address indexed src, uint srcBalance, address indexed dst, uint dstBalance);

    /// @notice An event thats emitted when epoch block count changes
    event EpochConfigChanged(uint32 indexed previousEpoch, uint32 previousBlocks, uint32 previousROI, uint32 indexed newEpoch, uint32 newBlocks, uint32 newROI);

    /// @notice The standard BEP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard BEP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new ANN token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {
        EpochConfig memory newEpochConfig = EpochConfig(
            0,
            24 * 60 * 60 / 3, // 1 day blocks in BSC
            20 // 0.2% ROI increase per epoch
        );
        epochConfigs.push(newEpochConfig);
        emit EpochConfigChanged(0, 0, 0, newEpochConfig.epoch, newEpochConfig.blocks, newEpochConfig.roi);
        balances[account] = uint96(totalSupply);
        _writeTransferPoint(address(0), account, 0, 0, uint96(totalSupply));
        emit Transfer(address(0), account, totalSupply);
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
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "ANN::approve: amount exceeds 96 bits");
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
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external  returns (bool) {
        uint96 amount = safe96(rawAmount, "ANN::transfer: amount exceeds 96 bits");
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
    function transferFrom(address src, address dst, uint rawAmount) external  returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "ANN::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "ANN::transferFrom: transfer amount exceeds spender allowance");
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
    function delegate(address delegatee) public  {
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
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public  {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ANN::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "ANN::delegateBySig: invalid nonce");
        require(now <= expiry, "ANN::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "ANN::getPriorVotes: not yet determined");

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

    /**
     * @notice Sets block counter per epoch
     * @param blocks The count of blocks per epoch
     * @param roi The interet of rate increased per epoch
     */
    function setEpochConfig(uint32 blocks, uint32 roi) public onlyOwner {
        require(blocks > 0, "ANN::setEpochConfig: zero blocks");
        require(roi < 10000, "ANN::setEpochConfig: roi exceeds max fraction");
        EpochConfig memory prevEC = epochConfigs[epochConfigs.length - 1];
        EpochConfig memory newEC = EpochConfig(getEpochs(block.number), blocks, roi);
        require(prevEC.blocks != newEC.blocks || prevEC.roi != newEC.roi, "ANN::setEpochConfig: blocks and roi same as before");
        //if (prevEC.epoch == newEC.epoch && epochConfigs.length > 1) {
        if (prevEC.epoch == newEC.epoch) {
            epochConfigs[epochConfigs.length - 1] = newEC;
        } else {
            epochConfigs.push(newEC);
        }
        emit EpochConfigChanged(prevEC.epoch, prevEC.blocks, prevEC.roi, newEC.epoch, newEC.blocks, newEC.roi);
    }

    /**
     * @notice Gets block counter per epoch
     * @return The count of blocks for current epoch
     */
    function getCurrentEpochBlocks() public view returns (uint32 blocks) {
        blocks = epochConfigs[epochConfigs.length - 1].blocks;
    }

    /**
     * @notice Gets rate of interest for current epoch
     * @return The rate of interest for current epoch
     */
    function getCurrentEpochROI() public view returns (uint32 roi) {
        roi = epochConfigs[epochConfigs.length - 1].roi;
    }

    /**
     * @notice Gets current epoch config
     * @return The EpochConfig for current epoch
     */
    function getCurrentEpochConfig() public view returns (uint32 epoch, uint32 blocks, uint32 roi) {
        EpochConfig memory ec = epochConfigs[epochConfigs.length - 1];
        epoch = ec.epoch;
        blocks = ec.blocks;
        roi = ec.roi;
    }

    /**
     * @notice Gets epoch config at given epoch index
     * @param forEpoch epoch
     * @return (index of config,
                config at epoch)
     */
    function getEpochConfig(uint32 forEpoch) public view returns (uint32 index, uint32 epoch, uint32 blocks, uint32 roi) {
        index = uint32(epochConfigs.length - 1);
        // solhint-disable-next-line no-inline-assembly
        for (; index > 0; index--) {
            if (forEpoch >= epochConfigs[index].epoch) {
                break;
            }
        }
        EpochConfig memory ec = epochConfigs[index];
        epoch = ec.epoch;
        blocks = ec.blocks;
        roi = ec.roi;
    }

    /**
     * @notice Gets epoch index at given block number
     * @param blockNumber The number of blocks
     * @return epoch index
     */
    function getEpochs(uint blockNumber) public view returns (uint32) {
        uint96 blocks = 0;
        uint96 epoch = 0;
        uint blockNum = blockNumber;
        for (uint32 i = 0; i < epochConfigs.length; i++) {
            uint96 deltaBlocks = (uint96(epochConfigs[i].epoch) - epoch) * blocks;
            if (blockNum < deltaBlocks) {
                break;
            }
            blockNum = blockNum - deltaBlocks;
            epoch = epochConfigs[i].epoch;
            blocks = epochConfigs[i].blocks;
        }

        if (blocks == 0) {
            blocks = getCurrentEpochBlocks();
        }
        epoch = epoch + uint96(blockNum / blocks);
        if (epoch >= 2**32) {
            epoch = 2**32 - 1;
        }
        return uint32(epoch);
    }

    /**
     * @notice Gets the current holding rewart amount for `account`
     * @param account The address to get holding reward amount
     * @return The number of current holding reward for `account`
     */
    function getHoldingReward(address account) public view returns (uint96) {
        // Check if account is holding more than eligible delay
        uint32 nTransferPoint = numTransferPoints[account];

        if (nTransferPoint == 0) {
            return 0;
        }

        uint32 lastEpoch = getEpochs(block.number);
        if (lastEpoch == 0) {
            return 0;
        }

        lastEpoch = lastEpoch - 1;
        if (lastEpoch < eligibleEpochs) {
            return 0;
        } else {
            uint32 lastEligibleEpoch = lastEpoch - eligibleEpochs;

            // Next check implicit zero balance
            if (transferPoints[account][0].epoch > lastEligibleEpoch) {
                return 0;
            }

            // First check most recent balance
            if (transferPoints[account][nTransferPoint - 1].epoch <= lastEligibleEpoch) {
                nTransferPoint = nTransferPoint - 1;
            } else {
                uint32 upper = nTransferPoint - 1;
                nTransferPoint = 0;
                while (upper > nTransferPoint) {
                    uint32 center = upper - (upper - nTransferPoint) / 2; // ceil, avoiding overflow
                    TransferPoint memory tp = transferPoints[account][center];
                    if (tp.epoch == lastEligibleEpoch) {
                        nTransferPoint = center;
                        break;
                    } if (tp.epoch < lastEligibleEpoch) {
                        nTransferPoint = center;
                    } else {
                        upper = center - 1;
                    }
                }
            }
        }

        // Calculate total rewards amount
        uint256 reward = 0;
        for (uint32 iTP = 0; iTP <= nTransferPoint; iTP++) {
            TransferPoint memory tp = transferPoints[account][iTP];
            (uint32 iEC,,,uint32 roi) = getEpochConfig(tp.epoch);
            uint32 startEpoch = tp.epoch;
            for (; iEC < epochConfigs.length; iEC++) {
                uint32 epoch = lastEpoch;
                bool tookNextTP = false;
                if (iEC < (epochConfigs.length - 1) && epoch > epochConfigs[iEC + 1].epoch) {
                    epoch = epochConfigs[iEC + 1].epoch;
                }
                if (iTP < nTransferPoint && epoch > transferPoints[account][iTP + 1].epoch) {
                    epoch = transferPoints[account][iTP + 1].epoch;
                    tookNextTP = true;
                }
                reward = reward + (uint256(tp.balance) * roi * sub32(epoch, startEpoch, "ANN::getHoldingReward: invalid epochs"));
                if (tookNextTP) {
                    break;
                }
                startEpoch = epoch;
                if (iEC < (epochConfigs.length - 1)) {
                    roi = epochConfigs[iEC + 1].roi;
                }
            }
        }
        uint96 amount = safe96(reward / 10000, "ANN::getHoldingReward: reward exceeds 96 bits");

        // Exclude already claimed amount
        if (claimedAmounts[account] > 0) {
            amount = sub96(amount, claimedAmounts[account], "ANN::getHoldingReward: invalid claimed amount");
        }

        return amount;
    }

    /**
     * @notice Receive the current holding rewart amount to msg.sender
     */
    function claimReward() public  {
        uint96 holdingReward = getHoldingReward(msg.sender);
        if (balances[address(this)] < holdingReward) {
            holdingReward = balances[address(this)];
        }
        claimedAmounts[msg.sender] = add96(claimedAmounts[msg.sender], holdingReward, "ANN::claimReward: invalid claimed amount");
        _transferTokens(address(this), msg.sender, holdingReward);
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "ANN::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "ANN::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "ANN::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "ANN::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
        if (amount > 0) {
            _writeTransferPoint(src, dst, numTransferPoints[dst], balances[src], balances[dst]);
        }
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "ANN::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "ANN::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "ANN::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _writeTransferPoint(address src, address dst, uint32 nDstPoint, uint96 srcBalance, uint96 dstBalance) internal {
        uint32 epoch = getEpochs(block.number);

        if (src != address(this)) {
            // Revoke sender in reward eligible list
            for (uint32 i = 0; i < numTransferPoints[src]; i++) {
                delete transferPoints[src][i];
            }

            // Remove claim amount
            claimedAmounts[src] = 0;

            // delete transferPoints[src];
            if (srcBalance > 0) {
                transferPoints[src][0] = TransferPoint(epoch, srcBalance);
                numTransferPoints[src] = 1;
            } else {
                numTransferPoints[src] = 0;
            }
        }

        if (dst != address(this)) {
            // Add recipient in reward eligible list
            if (nDstPoint > 0 && transferPoints[dst][nDstPoint - 1].epoch >= epoch) {
                transferPoints[dst][nDstPoint - 1].balance = dstBalance;
            } else {
                transferPoints[dst][nDstPoint] = TransferPoint(epoch, dstBalance);
                numTransferPoints[dst] = nDstPoint + 1;
            }
        }

        // emit TransferPointChanged(src, balances[src], dst, balances[dst]);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}