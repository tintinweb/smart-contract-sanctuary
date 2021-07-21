/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// File: DToken.sol

contract DToken {
    /// @dev EIP-20 token name for this token
    string public name;

    /// @dev EIP-20 token symbol for this token
    string public symbol;

    /// @dev EIP-20 token decimals for this token
    uint8 public decimals;

    /// @dev Total number of tokens in circulation
    uint256 public totalSupply;

    /// @dev Allowance amounts on behalf of others
    mapping (address => mapping (address => uint256)) internal allowances;

    /// @dev Official record of token balances for each account
    mapping (address => uint256) internal balances;

    address public governance;
    address public pendingGovernance;
    address public convController;
    address public vault;

    /// @dev A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @dev A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @dev The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @dev An event thats emitted when a delegate account's vote balance changes
    event AccountVotesChanged(address indexed account, uint256 previousBalance, uint256 newBalance);

    /// @dev The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Mint(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);

    function initialize(address _governance, uint8  _decimals, bytes calldata _name, bytes calldata _symbol) external {
        require(governance == address(0), 'initialize: can only initialize once');
        require(_governance != address(0), 'initialize: invalid governance address');
        governance = _governance;
        convController = msg.sender;
        name = string(_name);
        symbol = string(_symbol);
        decimals = _decimals;
    }

    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint256(-1)) {
            uint256 newAllowance = sub256(spenderAllowance, amount, "transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @dev Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @dev Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "getPriorVotes: not yet determined");

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

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0), "_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "_transferTokens: cannot transfer to the zero address");

        balances[src] = sub256(balances[src], amount, "_transferTokens: transfer amount exceeds balance");
        balances[dst] = add256(balances[dst], amount, "_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveVotes(src);
        _moveVotes(dst);
    }

    function _moveVotes(address account) internal {
        uint32 repNum = numCheckpoints[account];
        uint256 oldBalance = repNum > 0 ? checkpoints[account][repNum - 1].votes : 0;
        _writeCheckpoint(account, repNum, oldBalance, balances[account]);
    }

    function _writeCheckpoint(address account, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[account][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[account][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[account][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[account] = nCheckpoints + 1;
        }

        emit AccountVotesChanged(account, oldVotes, newVotes);
    }

    function acceptGovernance() public {
        require(msg.sender == pendingGovernance, "!pendingGovernance");
        governance = msg.sender;
        pendingGovernance = address(0);
    }

    function setPendingGovernance(address _pendingGovernance) public {
        require(msg.sender == governance, "!governance");
        pendingGovernance = _pendingGovernance;
    }

    function setConvController(address _convController) public {
        require(msg.sender == governance, "!governance");
        convController = _convController;
    }

    function setVault(address _vault) public {
        require(msg.sender == governance, "!governance");
        vault = _vault;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == convController || msg.sender == vault, "NOT OPERATOR");
        _mint(account,amount);
        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == convController || msg.sender == vault, "NOT OPERATOR");
        _burn(account,amount);
        emit Burn(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply = add256(totalSupply, amount, "ERC20: mint amount overflows");
        balances[account] = add256(balances[account], amount, "ERC20: mint amount overflows");

        emit Transfer(address(0), account, amount);
        _moveVotes(account);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = sub256(balances[account], amount, "ERC20: burn amount exceeds balance");
        totalSupply = sub256(totalSupply, amount, "ERC20: burn amount exceeds balance");

        emit Transfer(account, address(0), amount);
        _moveVotes(account);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add256(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub256(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function sweep(address _token) public {
        require(msg.sender == governance, "!governance");

        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(governance, _balance);
    }
}