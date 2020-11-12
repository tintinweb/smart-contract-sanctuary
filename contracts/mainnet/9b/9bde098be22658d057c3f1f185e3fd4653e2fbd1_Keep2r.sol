// SPDX-License-Identifier: MIT


/**
 * KP2R.NETWORK
 * A standard implementation of kp3rv1 protocol
 * Optimized Dapp
 * Scalability
 * Clean & tested code
 */


pragma solidity ^0.6.12;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add: +");

        return c;
    }
   function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
   function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "sub: -");
    }
   function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
  function mul(uint a, uint b) internal pure returns (uint) {
       if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "mul: *");

        return c;
    }
  function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
       if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }
  function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "div: /");
    }
  function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
   function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "mod: %");
    }
  function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract ReentrancyGuard {
   uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
       require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
       _status = _ENTERED;
       _;
       _status = _NOT_ENTERED;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
   function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value:amount}("");
        require(success, "Address: reverted");
    }
}
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: < 0");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
           // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: !contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
     if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: !succeed");
        }
    }
}

library Keep2rLibrary {
    function getReserve(address pair, address reserve) external view returns (uint) {
        (uint _r0, uint _r1,) = IUniswapV2Pair(pair).getReserves();
        if (IUniswapV2Pair(pair).token0() == reserve) {
            return _r0;
        } else if (IUniswapV2Pair(pair).token1() == reserve) {
            return _r1;
        } else {
            return 0;
        }
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IGovernance {
    function proposeJob(address job) external;
}

interface IKeep2rHelper {
    function getQuoteLimit(uint gasUsed) external view returns (uint);
}

contract Keep2r is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /// @notice Keep3r Helper to set max prices for the ecosystem
    IKeep2rHelper public KPRH;

    /// @notice EIP-20 token name for this token
    string public constant name = "KP2R.Network";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "KP2R";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0; // Initial 0

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint nonce,uint expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");


    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint votes;
    }

    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "delegateBySig: sig");
        require(nonce == nonces[signatory]++, "delegateBySig: nonce");
        require(now <= expiry, "delegateBySig: expired");
        _delegate(signatory, delegatee);
    }

  
    function getCurrentVotes(address account) external view returns (uint) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "getPriorVotes:");

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
        uint delegatorBalance = votes[delegator].add(bonds[delegator][address(this)]);
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld.sub(amount, "_moveVotes: underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
      uint32 blockNumber = safe32(block.number, "_writeCheckpoint: 32 bits");

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

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);

    /// @notice Submit a job
    event SubmitJob(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Apply credit to a job
    event ApplyCredit(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Remove credit for a job
    event RemoveJob(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Unbond credit for a job
    event UnbondJob(address indexed job, address indexed liquidity, address indexed provider, uint block, uint credit);

    /// @notice Added a Job
    event JobAdded(address indexed job, uint block, address governance);

    /// @notice Removed a job
    event JobRemoved(address indexed job, uint block, address governance);

    /// @notice Worked a job
    event KeeperWorked(address indexed credit, address indexed job, address indexed keeper, uint block, uint amount);

    /// @notice Keeper bonding
    event KeeperBonding(address indexed keeper, uint block, uint active, uint bond);

    /// @notice Keeper bonded
    event KeeperBonded(address indexed keeper, uint block, uint activated, uint bond);

    /// @notice Keeper unbonding
    event KeeperUnbonding(address indexed keeper, uint block, uint deactive, uint bond);

    /// @notice Keeper unbound
    event KeeperUnbound(address indexed keeper, uint block, uint deactivated, uint bond);

    /// @notice Keeper slashed
    event KeeperSlashed(address indexed keeper, address indexed slasher, uint block, uint slash);

    /// @notice Keeper disputed
    event KeeperDispute(address indexed keeper, uint block);

    /// @notice Keeper resolved
    event KeeperResolved(address indexed keeper, uint block);

    event AddCredit(address indexed credit, address indexed job, address indexed creditor, uint block, uint amount);

    /// @notice 1 day to bond to become a keeper
    uint constant public BOND = 3 days;
    /// @notice 14 days to unbond to remove funds from being a keeper
    uint constant public UNBOND = 14 days;
    /// @notice 3 days till liquidity can be bound
    uint constant public LIQUIDITYBOND = 3 days;

    /// @notice direct liquidity fee 0.3%
    uint constant public FEE = 30;
    uint constant public BASE = 10000;

    /// @notice address used for ETH transfers
    address constant public ETH = address(0xE);

    /// @notice tracks all current bondings (time)
    mapping(address => mapping(address => uint)) public bondings;
    /// @notice tracks all current unbondings (time)
    mapping(address => mapping(address => uint)) public unbondings;
    /// @notice allows for partial unbonding
    mapping(address => mapping(address => uint)) public partialUnbonding;
    /// @notice tracks all current pending bonds (amount)
    mapping(address => mapping(address => uint)) public pendingbonds;
    /// @notice tracks how much a keeper has bonded
    mapping(address => mapping(address => uint)) public bonds;
    /// @notice tracks underlying votes (that don't have bond)
    mapping(address => uint) public votes;

    /// @notice total bonded (totalSupply for bonds)
    uint public totalBonded = 0;
    /// @notice tracks when a keeper was first registered
    mapping(address => uint) public firstSeen;

    /// @notice tracks if a keeper has a pending dispute
    mapping(address => bool) public disputes;

    /// @notice tracks last job performed for a keeper
    mapping(address => uint) public lastJob;
    /// @notice tracks the total job executions for a keeper
    mapping(address => uint) public workCompleted;
    /// @notice list of all jobs registered for the keeper system
    mapping(address => bool) public jobs;
    /// @notice the current credit available for a job
    mapping(address => mapping(address => uint)) public credits;
    /// @notice the balances for the liquidity providers
    mapping(address => mapping(address => mapping(address => uint))) public liquidityProvided;
    /// @notice liquidity unbonding days
    mapping(address => mapping(address => mapping(address => uint))) public liquidityUnbonding;
    /// @notice liquidity unbonding amounts
    mapping(address => mapping(address => mapping(address => uint))) public liquidityAmountsUnbonding;
    /// @notice job proposal delay
    mapping(address => uint) public jobProposalDelay;
    /// @notice liquidity apply date
    mapping(address => mapping(address => mapping(address => uint))) public liquidityApplied;
    /// @notice liquidity amount to apply
    mapping(address => mapping(address => mapping(address => uint))) public liquidityAmount;

    /// @notice list of all current keepers
    mapping(address => bool) public keepers;
    /// @notice blacklist of keepers not allowed to participate
    mapping(address => bool) public blacklist;

    /// @notice traversable array of keepers to make external management easier
    address[] public keeperList;
    /// @notice traversable array of jobs to make external management easier
    address[] public jobList;

    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;

    /// @notice the liquidity token supplied by users paying for jobs
    mapping(address => bool) public liquidityAccepted;

    address[] public liquidityPairs;

    uint internal _gasUsed;

    constructor(address _kph) public {
        // Set governance for this token
        governance = msg.sender;
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        KPRH = IKeep2rHelper(_kph);
    }

    /**
     * @notice Add ETH credit to a job to be paid out for work
     * @param job the job being credited
     */
    function addCreditETH(address job) external payable {
        require(jobs[job], "addCreditETH: !job");
        uint _fee = msg.value.mul(FEE).div(BASE);
        credits[job][ETH] = credits[job][ETH].add(msg.value.sub(_fee));
        payable(governance).transfer(_fee);

        emit AddCredit(ETH, job, msg.sender, block.number, msg.value);
    }

    function addCredit(address credit, address job, uint amount) external nonReentrant {
        require(jobs[job], "addCreditETH: !job");
        uint _before = IERC20(credit).balanceOf(address(this));
        IERC20(credit).safeTransferFrom(msg.sender, address(this), amount);
        uint _received = IERC20(credit).balanceOf(address(this)).sub(_before);
        uint _fee = _received.mul(FEE).div(BASE);
        credits[job][credit] = credits[job][credit].add(_received.sub(_fee));
        IERC20(credit).safeTransfer(governance, _fee);

        emit AddCredit(credit, job, msg.sender, block.number, _received);
    }

    function addVotes(address voter, uint amount) external {
        require(msg.sender == governance, "addVotes: !gov");
        _activate(voter, address(this));
        votes[voter] = votes[voter].add(amount);
        totalBonded = totalBonded.add(amount);
        _moveDelegates(address(0), delegates[voter], amount);
    }

 
    function removeVotes(address voter, uint amount) external {
        require(msg.sender == governance, "addVotes: !gov");
        votes[voter] = votes[voter].sub(amount);
        totalBonded = totalBonded.sub(amount);
        _moveDelegates(delegates[voter], address(0), amount);
    }

    function addKPRCredit(address job, uint amount) external {
        require(msg.sender == governance, "addKPRCredit: !gov");
        require(jobs[job], "addKPRCredit: !job");
        credits[job][address(this)] = credits[job][address(this)].add(amount);
        _mint(address(this), amount);
        emit AddCredit(address(this), job, msg.sender, block.number, amount);
    }

 
    function approveLiquidity(address liquidity) external {
        require(msg.sender == governance, "approveLiquidity: !gov");
        require(!liquidityAccepted[liquidity], "approveLiquidity: !pair");
        liquidityAccepted[liquidity] = true;
        liquidityPairs.push(liquidity);
    }

    function revokeLiquidity(address liquidity) external {
        require(msg.sender == governance, "revokeLiquidity: !gov");
        liquidityAccepted[liquidity] = false;
    }

    function pairs() external view returns (address[] memory) {
        return liquidityPairs;
    }

  
    function addLiquidityToJob(address liquidity, address job, uint amount) external nonReentrant {
        require(liquidityAccepted[liquidity], "addLiquidityToJob: !pair");
        IERC20(liquidity).safeTransferFrom(msg.sender, address(this), amount);
        liquidityProvided[msg.sender][liquidity][job] = liquidityProvided[msg.sender][liquidity][job].add(amount);

        liquidityApplied[msg.sender][liquidity][job] = now.add(LIQUIDITYBOND);
        liquidityAmount[msg.sender][liquidity][job] = liquidityAmount[msg.sender][liquidity][job].add(amount);

        if (!jobs[job] && jobProposalDelay[job] < now) {
            IGovernance(governance).proposeJob(job);
            jobProposalDelay[job] = now.add(UNBOND);
        }
        emit SubmitJob(job, liquidity, msg.sender, block.number, amount);
    }

    function applyCreditToJob(address provider, address liquidity, address job) external {
        require(liquidityAccepted[liquidity], "addLiquidityToJob: !pair");
        require(liquidityApplied[provider][liquidity][job] != 0, "credit: no bond");
        require(liquidityApplied[provider][liquidity][job] < now, "credit: bonding");
        uint _liquidity = Keep2rLibrary.getReserve(liquidity, address(this));
        uint _credit = _liquidity.mul(liquidityAmount[provider][liquidity][job]).div(IERC20(liquidity).totalSupply());
        _mint(address(this), _credit);
        credits[job][address(this)] = credits[job][address(this)].add(_credit);
        liquidityAmount[provider][liquidity][job] = 0;

        emit ApplyCredit(job, liquidity, provider, block.number, _credit);
    }

    function unbondLiquidityFromJob(address liquidity, address job, uint amount) external {
        require(liquidityAmount[msg.sender][liquidity][job] == 0, "credit: pending credit");
        liquidityUnbonding[msg.sender][liquidity][job] = now.add(UNBOND);
        liquidityAmountsUnbonding[msg.sender][liquidity][job] = liquidityAmountsUnbonding[msg.sender][liquidity][job].add(amount);
        require(liquidityAmountsUnbonding[msg.sender][liquidity][job] <= liquidityProvided[msg.sender][liquidity][job], "unbondLiquidityFromJob: insufficient funds");

        uint _liquidity = Keep2rLibrary.getReserve(liquidity, address(this));
        uint _credit = _liquidity.mul(amount).div(IERC20(liquidity).totalSupply());
        if (_credit > credits[job][address(this)]) {
            _burn(address(this), credits[job][address(this)]);
            credits[job][address(this)] = 0;
        } else {
            _burn(address(this), _credit);
            credits[job][address(this)] = credits[job][address(this)].sub(_credit);
        }

        emit UnbondJob(job, liquidity, msg.sender, block.number, amount);
    }

    function removeLiquidityFromJob(address liquidity, address job) external {
        require(liquidityUnbonding[msg.sender][liquidity][job] != 0, "removeJob: unbond");
        require(liquidityUnbonding[msg.sender][liquidity][job] < now, "removeJob: unbonding");
        uint _amount = liquidityAmountsUnbonding[msg.sender][liquidity][job];
        liquidityProvided[msg.sender][liquidity][job] = liquidityProvided[msg.sender][liquidity][job].sub(_amount);
        liquidityAmountsUnbonding[msg.sender][liquidity][job] = 0;
        IERC20(liquidity).safeTransfer(msg.sender, _amount);

        emit RemoveJob(job, liquidity, msg.sender, block.number, _amount);
    }

    function mint(uint amount) external {
        require(msg.sender == governance, "mint: !gov");
        _mint(governance, amount);
    }

  
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }

    function _mint(address dst, uint amount) internal {
        totalSupply = totalSupply.add(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {
        require(dst != address(0), "_burn: zero address");
        balances[dst] = balances[dst].sub(amount, "_burn: exceeds balance");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(dst, address(0), amount);
    }

    function worked(address keeper) external {
        workReceipt(keeper, KPRH.getQuoteLimit(_gasUsed.sub(gasleft())));
    }

    function workReceipt(address keeper, uint amount) public {
        require(jobs[msg.sender], "workReceipt: !job");
        require(amount <= KPRH.getQuoteLimit(_gasUsed.sub(gasleft())), "workReceipt: max limit");
        credits[msg.sender][address(this)] = credits[msg.sender][address(this)].sub(amount, "workReceipt: insuffient funds");
        lastJob[keeper] = now;
        _reward(keeper, amount);
        workCompleted[keeper] = workCompleted[keeper].add(amount);
        emit KeeperWorked(address(this), msg.sender, keeper, block.number, amount);
    }

  
    function receipt(address credit, address keeper, uint amount) external {
        require(jobs[msg.sender], "receipt: !job");
        credits[msg.sender][credit] = credits[msg.sender][credit].sub(amount, "workReceipt: insuffient funds");
        lastJob[keeper] = now;
        IERC20(credit).safeTransfer(keeper, amount);
        emit KeeperWorked(credit, msg.sender, keeper, block.number, amount);
    }

  
    function receiptETH(address keeper, uint amount) external {
        require(jobs[msg.sender], "receipt: !job");
        credits[msg.sender][ETH] = credits[msg.sender][ETH].sub(amount, "workReceipt: insuffient funds");
        lastJob[keeper] = now;
        payable(keeper).transfer(amount);
        emit KeeperWorked(ETH, msg.sender, keeper, block.number, amount);
    }

    function _reward(address _from, uint _amount) internal {
        bonds[_from][address(this)] = bonds[_from][address(this)].add(_amount);
        totalBonded = totalBonded.add(_amount);
        _moveDelegates(address(0), delegates[_from], _amount);
        emit Transfer(msg.sender, _from, _amount);
    }

    function _bond(address bonding, address _from, uint _amount) internal {
        bonds[_from][bonding] = bonds[_from][bonding].add(_amount);
        if (bonding == address(this)) {
            totalBonded = totalBonded.add(_amount);
            _moveDelegates(address(0), delegates[_from], _amount);
        }
    }

    function _unbond(address bonding, address _from, uint _amount) internal {
        bonds[_from][bonding] = bonds[_from][bonding].sub(_amount);
        if (bonding == address(this)) {
            totalBonded = totalBonded.sub(_amount);
            _moveDelegates(delegates[_from], address(0), _amount);
        }

    }

    function addJob(address job) external {
        require(msg.sender == governance, "addJob: !gov");
        require(!jobs[job], "addJob: job known");
        jobs[job] = true;
        jobList.push(job);
        emit JobAdded(job, block.number, msg.sender);
    }

  
    function getJobs() external view returns (address[] memory) {
        return jobList;
    }

 
    function removeJob(address job) external {
        require(msg.sender == governance, "removeJob: !gov");
        jobs[job] = false;
        emit JobRemoved(job, block.number, msg.sender);
    }

    function setKeep3rHelper(IKeep2rHelper _kprh) external {
        require(msg.sender == governance, "setKeep3rHelper: !gov");
        KPRH = _kprh;
    }

  
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "acceptGovernance: !pendingGov");
        governance = pendingGovernance;
    }

    function isKeeper(address keeper) external returns (bool) {
        _gasUsed = gasleft();
        return keepers[keeper];
    }

    function isMinKeeper(address keeper, uint minBond, uint earned, uint age) external returns (bool) {
        _gasUsed = gasleft();
        return keepers[keeper]
                && bonds[keeper][address(this)].add(votes[keeper]) >= minBond
                && workCompleted[keeper] >= earned
                && now.sub(firstSeen[keeper]) >= age;
    }

  
    function isBondedKeeper(address keeper, address bond, uint minBond, uint earned, uint age) external returns (bool) {
        _gasUsed = gasleft();
        return keepers[keeper]
                && bonds[keeper][bond] >= minBond
                && workCompleted[keeper] >= earned
                && now.sub(firstSeen[keeper]) >= age;
    }

 
    function bond(address bonding, uint amount) external nonReentrant {
        require(!blacklist[msg.sender], "bond: blacklisted");
        bondings[msg.sender][bonding] = now.add(BOND);
        if (bonding == address(this)) {
            _transferTokens(msg.sender, address(this), amount);
        } else {
            uint _before = IERC20(bonding).balanceOf(address(this));
            IERC20(bonding).safeTransferFrom(msg.sender, address(this), amount);
            amount = IERC20(bonding).balanceOf(address(this)).sub(_before);
        }
        pendingbonds[msg.sender][bonding] = pendingbonds[msg.sender][bonding].add(amount);
        emit KeeperBonding(msg.sender, block.number, bondings[msg.sender][bonding], amount);
    }

   
    function getKeepers() external view returns (address[] memory) {
        return keeperList;
    }

  
    function activate(address bonding) external {
        require(!blacklist[msg.sender], "activate: blacklisted");
        require(bondings[msg.sender][bonding] != 0 && bondings[msg.sender][bonding] < now, "activate: bonding");
        _activate(msg.sender, bonding);
    }
    
    function _activate(address keeper, address bonding) internal {
        if (firstSeen[keeper] == 0) {
          firstSeen[keeper] = now;
          keeperList.push(keeper);
          lastJob[keeper] = now;
        }
        keepers[keeper] = true;
        _bond(bonding, keeper, pendingbonds[keeper][bonding]);
        pendingbonds[keeper][bonding] = 0;
        emit KeeperBonded(keeper, block.number, block.timestamp, bonds[keeper][bonding]);
    }

  
    function unbond(address bonding, uint amount) external {
        unbondings[msg.sender][bonding] = now.add(UNBOND);
        _unbond(bonding, msg.sender, amount);
        partialUnbonding[msg.sender][bonding] = partialUnbonding[msg.sender][bonding].add(amount);
        emit KeeperUnbonding(msg.sender, block.number, unbondings[msg.sender][bonding], amount);
    }

  
    function withdraw(address bonding) external nonReentrant {
        require(unbondings[msg.sender][bonding] != 0 && unbondings[msg.sender][bonding] < now, "withdraw: unbonding");
        require(!disputes[msg.sender], "withdraw: disputes");

        if (bonding == address(this)) {
            _transferTokens(address(this), msg.sender, partialUnbonding[msg.sender][bonding]);
        } else {
            IERC20(bonding).safeTransfer(msg.sender, partialUnbonding[msg.sender][bonding]);
        }
        emit KeeperUnbound(msg.sender, block.number, block.timestamp, partialUnbonding[msg.sender][bonding]);
        partialUnbonding[msg.sender][bonding] = 0;
    }

   
    function dispute(address keeper) external {
        require(msg.sender == governance, "dispute: !gov");
        disputes[keeper] = true;
        emit KeeperDispute(keeper, block.number);
    }

  
    function slash(address bonded, address keeper, uint amount) public nonReentrant {
        require(msg.sender == governance, "slash: !gov");
        if (bonded == address(this)) {
            _transferTokens(address(this), governance, amount);
        } else {
            IERC20(bonded).safeTransfer(governance, amount);
        }
        _unbond(bonded, keeper, amount);
        disputes[keeper] = false;
        emit KeeperSlashed(keeper, msg.sender, block.number, amount);
    }

    function revoke(address keeper) external {
        require(msg.sender == governance, "slash: !gov");
        keepers[keeper] = false;
        blacklist[keeper] = true;
        slash(address(this), keeper, bonds[keeper][address(this)]);
    }

  
    function resolve(address keeper) external {
        require(msg.sender == governance, "resolve: !gov");
        disputes[keeper] = false;
        emit KeeperResolved(keeper, block.number);
    }

   
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

  
    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

   
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: signature");
        require(signatory == owner, "permit: unauthorized");
        require(now <= deadline, "permit: expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    
    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

  
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "transferFrom: exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "_transferTokens: zero address");
        require(dst != address(0), "_transferTokens: zero address");

        balances[src] = balances[src].sub(amount, "_transferTokens: exceeds balance");
        balances[dst] = balances[dst].add(amount, "_transferTokens: overflows");
        emit Transfer(src, dst, amount);
    }

    function _getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}