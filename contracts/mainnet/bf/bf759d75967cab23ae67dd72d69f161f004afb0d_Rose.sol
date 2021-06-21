/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.5.17;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);
}
contract Rose {
    using SafeMath for uint;

    /// @notice EIP-20 token name for this token
    string public constant name = "Rose";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "Ros";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 20_000_000e18; // 20 million ros

    /// @notice Allowance amounts on behalf of others
    mapping(address => mapping(address => uint)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping(address => uint) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    function setCheckpoint(uint fromBlock64, uint votes192) internal pure returns (uint){
        fromBlock64 |= votes192 << 64;
        return fromBlock64;
    }

    function getCheckpoint(uint _checkpoint) internal pure returns (uint fromBlock, uint votes){
        fromBlock=uint(uint64(_checkpoint));
        votes=uint(uint192(_checkpoint>>64));
    }

    function getCheckpoint(address _account,uint _index) external view returns (uint fromBlock, uint votes){
        uint data=checkpoints[_account][_index];
        (fromBlock,votes)=getCheckpoint(data);
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint => uint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint) public numCheckpoints;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address delegator, address fromDelegate, address toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(address account) public {
        balances[account] = totalSupply;
        emit Transfer(address(0), account, totalSupply);
    }

    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    function approve(address spender, uint rawAmount) external returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[msg.sender][spender] = rawAmount;
        emit Approval(msg.sender, spender, rawAmount);
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
    function transfer(address dst, uint rawAmount) external returns (bool) {
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
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != uint(- 1)) {
            uint newAllowance = spenderAllowance.sub(rawAmount, "Rose::transferFrom: transfer amount exceeds spender allowance");
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

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        (,uint votes)=getCheckpoint(checkpoints[account][nCheckpoints - 1]);
        return nCheckpoints > 0 ? votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "Rose::getPriorVotes: not yet determined");
        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        (uint dataFromBlock1,uint dataVotes1)=getCheckpoint(checkpoints[account][nCheckpoints - 1]);
        // First check most recent balance
        if (dataFromBlock1 <= blockNumber) {
            return dataVotes1;
        }
        (uint fromBlock0,)=getCheckpoint(checkpoints[account][0]);
        // Next check implicit zero balance
        if (fromBlock0 > blockNumber) {
            return 0;
        }
        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2;
            // ceil, avoiding overflow
            uint cp = checkpoints[account][center];
            (uint cpFromBlock,uint cpVotes)=getCheckpoint(cp);
            if (cpFromBlock == blockNumber) {
                return cpVotes;
            } else if (cpFromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        (,uint reVotes)=getCheckpoint(checkpoints[account][lower]);
        return reVotes;
    }



    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "Rose::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Rose::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount, "Rose::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "Rose::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint srcRepNum = numCheckpoints[srcRep];
                (,uint srcVotes)=getCheckpoint(checkpoints[srcRep][srcRepNum - 1]);
                uint srcRepOld = srcRepNum > 0 ? srcVotes : 0;
                uint srcRepNew = srcRepOld.sub(amount, "Rose::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint dstRepNum = numCheckpoints[dstRep];
                (,uint dstVotes)=getCheckpoint(checkpoints[dstRep][dstRepNum - 1]);
                uint dstRepOld = dstRepNum > 0 ? dstVotes : 0;
                uint dstRepNew = dstRepOld.add(amount, "Rose::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint256 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint blockNumber = block.number;
        (uint fromBlock,)=getCheckpoint(checkpoints[delegatee][nCheckpoints - 1]);
        if (nCheckpoints > 0 && fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1] = setCheckpoint(fromBlock,newVotes);
        } else {
            checkpoints[delegatee][nCheckpoints] = setCheckpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}