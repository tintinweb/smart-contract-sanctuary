// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) external restricted {
    last_completed_migration = completed;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/INut.sol";
import "./lib/Governable.sol";

contract Nut is ERC20, Governable, INut {
    using SafeMath for uint;

    address public distributor;

    uint public constant MAX_TOKENS = 1000000 ether; // total amount of NUT tokens
    uint public constant SINK_FUND = 200000 ether; // 20% of tokens goes to sink fund

    constructor (string memory name, string memory symbol, address sinkAddr) ERC20(name, symbol) {
        _mint(sinkAddr, SINK_FUND);
        __Governable__init();
    }

    /// @dev Set the new distributor
    function setNutDistributor(address addr) external onlyGov {
        distributor = addr;
    }

    /// @dev Mint nut tokens to receipt
    function mint(address receipt, uint256 amount) external override {
        require(msg.sender == distributor, "must be called by distributor");
        require(amount.add(this.totalSupply()) < MAX_TOKENS, "cannot mint more than MAX_TOKENS");
        _mint(receipt, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface INut {
    function mint(address receipt, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/Initializable.sol";
contract Governable is Initializable {
  address public governor;
  address public pendingGovernor;

  modifier onlyGov() {
    require(msg.sender == governor, 'bad gov');
    _;
  }

  function __Governable__init() internal initializer {
    governor = msg.sender;
  }

  function __Governable__init(address _governor) internal initializer {
    governor = _governor;
  }

  /// @dev Set the pending governor, which will be the governor once accepted.
  /// @param addr The address of the pending governor.
  function setPendingGovernor(address addr) external onlyGov {
    pendingGovernor = addr;
  }

  /// @dev Accept to become the new governor. Must be called by the pending governor.
  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'no pend');
    pendingGovernor = address(0);
    governor = msg.sender;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/INutDistributor.sol";
import "./interfaces/INut.sol";
import "./interfaces/IPriceOracle.sol";
import "./lib/Governable.sol";

/*
This contract distributes nut tokens based on staking unstaking during
the staking period.  It generates an array of "value times blocks" for
each token/lender pair and "total value times block" for each token.
It then distributes the rewards across the array.

One issue is that each unstake/stake requires a calculation to
determine the fraction of the pool owned by a lender.  To avoid having
to loop across all epochs and use up gas, this algorithm relies on the
fact that all future epochs have the same value.  So the vtb and
totalVtb arrays keep an index of the last epoch in which there was a
partial stake and unstake of tokens and then the epochs beyond that
all of the same value which is stored in futureVtbMap and
futureTotalVtbMap.
*/

contract NutDistributor is Governable, INutDistributor {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct Echo {
        uint id;
        uint endBlock;
        uint amount;
    }

    address public nutmeg;
    address public nut;
    address public oracle;

    uint public constant MAX_NUM_POOLS = 256;
    uint public DIST_START_BLOCK; // starting block of echo 0
    uint public constant NUM_EPOCH = 15; // # of epochs
    uint public BLOCKS_PER_EPOCH; // # of blocks per epoch
    uint public constant DIST_START_AMOUNT = 250000 ether; // # of tokens distributed at epoch 0
    uint public constant DIST_MIN_AMOUNT = 18750 ether; // min # of tokens distributed at any epoch

    uint public CURRENT_EPOCH;
    mapping(address => bool) addedPoolMap;
    address[] public pools;
    mapping(uint => Echo) public echoMap;
    mapping(uint => bool) public distCompletionMap;

    // the term vtb is short for value times blocks
    mapping(address => uint[15]) public totalVtbMap; // pool => total vtb, i.e., valueTimesBlocks.
    mapping(address => uint[15]) public totalNutMap; // pool => total Nut awarded.
    mapping(address => mapping( address => uint[15] ) ) public vtbMap; // pool => lender => vtb.

    mapping(address => uint) futureTotalVtbMap;
    mapping(address => mapping( address => uint) ) futureVtbMap;
    mapping(address => uint) futureTotalVtbEpoch;
    mapping(address => mapping( address => uint) ) futureVtbEpoch;

    modifier onlyNutmeg() {
        require(msg.sender == nutmeg, 'only nutmeg can call');
        _;
    }

    /// @dev Set the Nutmeg
    function setNutmegAddress(address addr) external onlyGov {
        nutmeg = addr;
    }

    /// @dev Set the oracle
    function setPriceOracle(address addr) external onlyGov {
        oracle = addr;
    }

    function initialize(address nutAddr, address _governor) public initializer{
        nut = nutAddr;
        DIST_START_BLOCK = block.number;
        BLOCKS_PER_EPOCH = 80640;
         __Governable__init(_governor);

        // config echoMap which indicates how many tokens will be distributed at each epoch
        for (uint i = 0; i < NUM_EPOCH; i++) {
            Echo storage echo =  echoMap[i];
            echo.id = i;
            echo.endBlock = DIST_START_BLOCK.add(BLOCKS_PER_EPOCH.mul(i.add(1)));
            uint amount = DIST_START_AMOUNT.div(i.add(1));
            if (amount < DIST_MIN_AMOUNT) {
                amount = DIST_MIN_AMOUNT;
            }
            echo.amount = amount;
        }
    }


    function inNutDistribution() external override view returns(bool) {
        return (block.number >= DIST_START_BLOCK && block.number < DIST_START_BLOCK.add(BLOCKS_PER_EPOCH.mul(NUM_EPOCH)));
    }

    /// @notice Update valueTimesBlocks of pools and the lender when they stake or unstake
    /// @param token Base token of the pool.
    /// @param lender Address of the lender.
    /// @param incAmount to stake or unstake
    /// @param decAmount false=subtract/unstake true=add/stake
    function updateVtb(address token, address lender, uint incAmount, uint decAmount) external override onlyNutmeg {
        require(block.number >= DIST_START_BLOCK, 'updateVtb: invalid block number');
        require(incAmount == 0 || decAmount == 0, 'updateVtb: update amount is invalid');

        uint amount = incAmount.add(decAmount);
        require(amount > 0, 'updateVtb: update amount should be positive');

        // get current epoch
        CURRENT_EPOCH = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        if (CURRENT_EPOCH >= NUM_EPOCH) return;

        _fillVtbGap(token, lender);
        _fillTotalVtbGap(token);

        uint dv = echoMap[CURRENT_EPOCH].endBlock.sub( block.number ).mul(amount);
        uint epochDv = BLOCKS_PER_EPOCH.mul(amount);

        if (incAmount > 0) {
            vtbMap[token][lender][CURRENT_EPOCH] = vtbMap[token][lender][CURRENT_EPOCH].add(dv);
            totalVtbMap[token][CURRENT_EPOCH] = totalVtbMap[token][CURRENT_EPOCH].add(dv);
            futureVtbMap[token][lender] = futureVtbMap[token][lender].add(epochDv);
            futureTotalVtbMap[token] = futureTotalVtbMap[token].add(epochDv);
        } else {
            vtbMap[token][lender][CURRENT_EPOCH] = vtbMap[token][lender][CURRENT_EPOCH].sub(dv);
            totalVtbMap[token][CURRENT_EPOCH] = totalVtbMap[token][CURRENT_EPOCH].sub(dv);
            futureVtbMap[token][lender] = futureVtbMap[token][lender].sub(epochDv);
            futureTotalVtbMap[token] = futureTotalVtbMap[token].sub(epochDv);
        }

        if (!addedPoolMap[token]) {
            pools.push(token);
            addedPoolMap[token] = true;
        }
    }
    // @dev This function fills the array between the last epoch at which things were calculated and the current epoch.
    function _fillVtbGap(address token, address lender) internal {
        if (futureVtbEpoch[token][lender] > CURRENT_EPOCH || CURRENT_EPOCH >= NUM_EPOCH ) return;
        uint futureVtb = futureVtbMap[token][lender];
        for (uint i = futureVtbEpoch[token][lender]; i <= CURRENT_EPOCH; i++) {
            vtbMap[token][lender][i] = futureVtb;
        }
        futureVtbEpoch[token][lender] = CURRENT_EPOCH.add(1);
    }

    // @dev This function fills the array between the last epoch at which things were calculated and the current epoch.
    function _fillTotalVtbGap(address token) internal {
        if (futureTotalVtbEpoch[token] > CURRENT_EPOCH || CURRENT_EPOCH >= NUM_EPOCH ) return;
        uint futureTotalVtb = futureTotalVtbMap[token];
        for (uint i = futureTotalVtbEpoch[token]; i <= CURRENT_EPOCH; i++) {
            totalVtbMap[token][i] = futureTotalVtb;
        }
        futureTotalVtbEpoch[token] = CURRENT_EPOCH.add(1);
    }

    /// @dev Distribute NUT tokens for the previous epoch
    function distribute() external onlyGov {
        require(oracle != address(0), 'distribute: no oracle available');

        // get current epoch
        uint currEpochId = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        require(currEpochId > 0, 'distribute: nut token distribution not ready');
        require(currEpochId < NUM_EPOCH.add(1), 'distribute: nut token distribution is over');

        // distribute the nut tokens for the previous epoch.
        uint prevEpochId = currEpochId.sub(1);
        require(!distCompletionMap[prevEpochId], 'distribute: distribution is completed');

        // mint nut tokens
        uint amount = echoMap[prevEpochId].amount;
        INut(nut).mint(address(this), amount);

        uint numOfPools = pools.length < MAX_NUM_POOLS ? pools.length : MAX_NUM_POOLS;
        uint sumOfDv;
        uint actualSumOfNut;
        for (uint i = 0; i < numOfPools; i++) {
            uint price = IPriceOracle(oracle).getPrice(pools[i]);
            uint dv = price.mul(getTotalVtb(pools[i],prevEpochId));
            sumOfDv = sumOfDv.add(dv);
        }

        if (sumOfDv > 0) {
            for (uint i = 0; i < numOfPools; i++) {
                uint price = IPriceOracle(oracle).getPrice(pools[i]);
                uint dv = price.mul(getTotalVtb(pools[i], prevEpochId));
                uint nutAmount = dv.mul(amount).div(sumOfDv);
                actualSumOfNut = actualSumOfNut.add(nutAmount);
                totalNutMap[pools[i]][prevEpochId] = nutAmount;
            }
        }

        require(actualSumOfNut <= amount, "distribute: overflow");

        distCompletionMap[prevEpochId] = true;
    }

    /// @dev Collect Nut tokens
    function collect() external  {
        uint epochId = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        require(epochId > 0, 'collect: distribution is completed');

        address lender = msg.sender;

        uint numOfPools = pools.length < MAX_NUM_POOLS ? pools.length : MAX_NUM_POOLS;
        uint totalAmount;
        for (uint i = 0; i < numOfPools; i++) {
            address pool = pools[i];
            for (uint j = 0; j < epochId && j < NUM_EPOCH; j++) {
                uint vtb = getVtb(pool, lender, j);
                if (vtb > 0 && getTotalVtb(pool, j) > 0) {
                    uint amount = vtb.mul(totalNutMap[pool][j]).div(getTotalVtb(pool, j));
                    totalAmount = totalAmount.add(amount);
                    vtbMap[pool][lender][j] = 0;
                }
            }
        }

        if (totalAmount > 0) {
            require(
                IERC20(nut).approve(address(this), 0),
                'distributor approve failed'
            );
            require(
                IERC20(nut).approve(address(this), totalAmount),
                'NutDist approve amount failed'
            );
            require(
                IERC20(nut).transferFrom(address(this), lender, totalAmount),
                'NutDist transfer failed'
            );
        }
    }

    /// @dev getCollectionAmount get the # of NUT tokens for collection
    function getCollectionAmount() external view returns(uint) {
        uint epochId = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        require(epochId > 0, 'getCollectionAmount: distribution is completed');

        address lender = msg.sender;

        uint numOfPools = pools.length < MAX_NUM_POOLS ? pools.length : MAX_NUM_POOLS;
        uint totalAmount;
        for (uint i = 0; i < numOfPools; i++) {
            address pool = pools[i];
            for (uint j = 0; j < epochId && j < NUM_EPOCH; j++) {
                uint vtb = getVtb(pool, lender, j);
                if (vtb > 0 && getTotalVtb(pool, j) > 0) {
                    uint amount = vtb.mul(totalNutMap[pool][j]).div(getTotalVtb(pool, j));
                    totalAmount = totalAmount.add(amount);
                }
            }
        }

        return totalAmount;
    }

    function getVtb(address pool, address lender, uint i) public view returns(uint) {
        require(i < NUM_EPOCH, 'vtb idx err');
        return i < futureVtbEpoch[pool][lender] ?
            vtbMap[pool][lender][i] : futureVtbMap[pool][lender];
    }
    function getTotalVtb(address pool, uint i) public view returns (uint) {
        require(i < NUM_EPOCH, 'totalVtb idx err');
        return i < futureTotalVtbEpoch[pool] ?
            totalVtbMap[pool][i] : futureTotalVtbMap[pool];
    }

    //@notice output version string
    function getVersionString()
    external virtual pure returns (string memory) {
        return "1";
   }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface INutDistributor {
    function updateVtb(address token, address lender, uint incAmount, uint decAmount) external;
    function inNutDistribution() external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IPriceOracle {
    function getPrice(address token) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import './lib/Governable.sol';
import './lib/Math.sol';
import "./interfaces/IAdapter.sol";
import "./interfaces/INutmeg.sol";
import "./interfaces/INutDistributor.sol";
import "./interfaces/IPriceOracle.sol";

contract Nutmeg is Initializable, Governable, INutmeg {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public nutDistributor;
    address public nut;

    uint private constant INVALID_POSITION_ID = type(uint).max;
    uint private constant NOT_LOCKED = 0;
    uint private constant LOCKED = 1;
    uint private constant TRANCHE_BBB = uint(Tranche.BBB);
    uint private constant TRANCHE_A = uint(Tranche.A);
    uint private constant TRANCHE_AA = uint(Tranche.AA);

    uint private constant MULTIPLIER = 10**18;
    uint private constant NUM_BLOCK_PER_YEAR = 2102400;
    address private constant INVALID_ADAPTER = address(2);

    uint public constant MAX_NUM_POOL = 256;
    uint public constant LIQUIDATION_COMMISSION = 5;
    uint public constant MAX_INTEREST_RATE_PER_BLOCK = 100000; // 1000.00%
    uint public constant MIN_INTEREST_RATE_PER_BLOCK = 500; // 5.00%
    uint public constant VERSION_ID = 1;
    uint public POOL_LOCK;
    uint public EXECUTION_LOCK;
    uint public STAKE_COUNTER;
    uint public POSITION_COUNTER;
    uint public CURR_POSITION_ID;
    address public CURR_SENDER;
    address public CURR_ADAPTER;

    // treasury pool array and map
    address[] public pools; // array of treasury pools
    mapping(address => Pool) public poolMap; // baseToken => pool mapping.

    // stake
    mapping(address => mapping (address => Stake[3])) public stakeMap; // baseToken => sender => tranche.
    mapping(address => uint[]) lenderStakeMap; // all stakes of a lender. address => stakeId

    // adapter
    address[] public adapters;
    mapping(address => bool) public adapterMap;

    // position
    mapping(uint => Position) public positionMap;
    mapping(address => uint[]) borrowerPositionMap; // all positions of a borrower. address => positionId
    mapping(address => mapping(address => uint)) minNut4Borrowers; // pool => adapter => uint

    /// @dev Reentrancy lock guard.
    modifier poolLock() {
        require(POOL_LOCK == NOT_LOCKED, 'pl lck');
        POOL_LOCK = LOCKED;
        _;
        POOL_LOCK = NOT_LOCKED;
    }

    /// @dev Reentrancy lock guard for execution.
    modifier inExecution() {
        require(CURR_POSITION_ID != INVALID_POSITION_ID, 'not exc');
        require(CURR_ADAPTER == msg.sender, 'bad adpr');
        require(EXECUTION_LOCK == NOT_LOCKED, 'exc lock');
        EXECUTION_LOCK = LOCKED;
        _;
        EXECUTION_LOCK = NOT_LOCKED;
    }

    /// @dev Accrue interests in a pool
    modifier accrue(address token) {
        accrueInterest(token);
        _;
    }

    /// @dev Initialize the smart contract, using msg.sender as the first governor.
    function initialize(address _governor) external initializer {
        __Governable__init(_governor);
        POOL_LOCK = NOT_LOCKED;
        EXECUTION_LOCK = NOT_LOCKED;
        STAKE_COUNTER = 1;
        POSITION_COUNTER = 1;
        CURR_POSITION_ID = INVALID_POSITION_ID;
        CURR_ADAPTER = INVALID_ADAPTER;
    }

    function setNutDistributor(address addr) external onlyGov {
        nutDistributor = addr;
    }

    function setNut(address addr) external onlyGov {
        nut = addr;
    }

    function setMinNut4Borrowers(address poolAddr, address adapterAddr, uint val) external onlyGov {
        require(adapterMap[adapterAddr], 'setMin no adpr');
        Pool storage pool = poolMap[poolAddr];
        require(pool.isExists, 'setMin no pool');
        minNut4Borrowers[poolAddr][adapterAddr] = val;
    }

    /// @notice Get all stake IDs of a lender
    function getStakeIds(address lender) external override view returns (uint[] memory){
        return lenderStakeMap[lender];
    }

    /// @notice Get all position IDs of a borrower
    function getPositionIds(address borrower) external override view returns (uint[] memory){
        return borrowerPositionMap[borrower];
    }

    /// @notice Return current position ID
    function getCurrPositionId() external override view returns (uint) {
        return CURR_POSITION_ID;
    }

    /// @notice Return next position ID
    function getNextPositionId() external override view returns (uint) {
        return POSITION_COUNTER;
    }

    /// @notice Get position information
    function getPosition(uint id) external override view returns (Position memory) {
        return positionMap[id];
    }

    /// @dev get current sender
    function getCurrSender() external override view returns (address) {
        return CURR_SENDER;
    }


    /// @dev Get all treasury pools
    function getPools() external view returns (address[] memory) {
        return pools;
    }

    /// @dev Get a specific pool given address
    function getPool(address addr) external view returns (Pool memory) {
        return poolMap[addr];
    }

    /// @dev Add a new treasury pool.
    /// @param token The underlying base token for the pool, e.g., DAI.
    /// @param interestRate The interest rate per block of Tranche A.
    function addPool(address token, uint interestRate)
        external poolLock onlyGov {
        require(pools.length < MAX_NUM_POOL, 'addPl pl > max');
        require(_isInterestRateValid(interestRate), 'addPl bad ir');
        Pool storage pool = poolMap[token];
        require(!pool.isExists, 'addPl pool exts');
        pool.isExists = true;
        pool.baseToken = token;
        pool.interestRates = [interestRate.div(2), interestRate, interestRate.mul(2)];
        pools.push(token);
        emit addPoolEvent(token, interestRate);
        pool.lossMultiplier = [ MULTIPLIER, MULTIPLIER, MULTIPLIER ];
    }

    /// @dev Update interest rate of the pool
    /// @param token The underlying base token for the pool, e.g., DAI.
    /// @param interestRate The interest rate per block of Tranche A. Input 316 for 3.16% APY
    function updateInterestRates(address token, uint interestRate)
        external poolLock onlyGov {
        require(_isInterestRateValid(interestRate), 'upIR bad ir');
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'upIR no pool');
        pool.interestRates = [interestRate.div(2), interestRate, interestRate.mul(2)];
    }

    function _isInterestRateValid(uint interestRate)
        internal pure returns(bool) {
        return (interestRate <= MAX_INTEREST_RATE_PER_BLOCK &&
            interestRate >= MIN_INTEREST_RATE_PER_BLOCK);
    }

    /// @notice Stake to a treasury pool.
    /// @param token The contract address of the base token of the pool.
    /// @param tranche The tranche of the pool, 0 - AA, 1 - A, 2 - BBB.
    /// @param principal The amount of principal
    function stake(address token, uint tranche, uint principal)
        external poolLock accrue(token) {
        require(tranche < 3, 'stk bad trnch');
        require(principal > 0, 'stk bad prpl');
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'stk no pool');
        if (tranche == TRANCHE_BBB) {
            require(principal.add(pool.principals[TRANCHE_BBB]) <= pool.principals[TRANCHE_AA],
                'stk BBB full');
        }

        // 1. transfer the principal to the pool.
        IERC20(pool.baseToken).safeTransferFrom(msg.sender, address(this), principal);

        // 2. add or update a stake
        Stake storage stk = stakeMap[token][msg.sender][tranche];
        uint sumIpp = pool.sumIpp[tranche];
        uint scaledPrincipal = 0;

        if (stk.id == 0) { // new stk
            stk.id = STAKE_COUNTER++;
            stk.status = StakeStatus.Open;
            stk.owner = msg.sender;
            stk.pool = token;
            stk.tranche = tranche;
        } else { // add liquidity to an existing stk
	          scaledPrincipal = _scaleByLossMultiplier( stk, stk.principal );
            uint interest = scaledPrincipal.mul( sumIpp.sub(stk.sumIppStart)).div(MULTIPLIER);
            stk.earnedInterest = _scaleByLossMultiplier(stk, stk.earnedInterest ).add(interest);
        }
        stk.sumIppStart = sumIpp;
        stk.principal = scaledPrincipal.add(principal);
	      stk.lossZeroCounterBase = pool.lossZeroCounter[tranche];
	      stk.lossMultiplierBase = pool.lossMultiplier[tranche];
        lenderStakeMap[stk.owner].push(stk.id);

        // update pool information
        pool.principals[tranche] = pool.principals[tranche].add(principal);
        updateInterestRateAdjustment(token);
        if (INutDistributor(nutDistributor).inNutDistribution()) {
            INutDistributor(nutDistributor).updateVtb(token, stk.owner, principal, 0);
        }

        emit stakeEvent(token, msg.sender, tranche, principal, stk.id);
    }



    /// @notice Unstake from a treasury pool.
    /// @param token The address of the pool.
    /// @param tranche The tranche of the pool, 0 - AA, 1 - A, 2 - BBB.
    /// @param amount The amount of principal that owner want to withdraw
    function unstake(address token, uint tranche, uint amount)
        external poolLock accrue(token) {
        require(tranche < 3, 'unstk bad trnch');
        Pool storage pool = poolMap[token];
        Stake storage stk = stakeMap[token][msg.sender][tranche];
        require(stk.id > 0, 'unstk no dpt');
        uint activePrincipal = _scaleByLossMultiplier( stk, stk.principal );
        require(amount > 0 && amount <= activePrincipal, 'unstk bad amt');
        require(stk.status == StakeStatus.Open, 'unstk bad status');
        // get the available amount to remove
        uint withdrawAmt = _getWithdrawAmount(poolMap[stk.pool], amount);
        uint interest = activePrincipal.mul(pool.sumIpp[tranche].sub(stk.sumIppStart)).div(MULTIPLIER);
        uint totalInterest = _scaleByLossMultiplier(
            stk, stk.earnedInterest
        ).add(interest);
        if (totalInterest > pool.interests[tranche]) { // unlikely, but just in case.
            totalInterest = pool.interests[tranche];
        }

        // transfer liquidity to the lender
        uint actualWithdrawAmt = withdrawAmt.add(totalInterest);
        IERC20(pool.baseToken).safeTransfer(msg.sender, actualWithdrawAmt);

        // update stake information
        stk.principal = activePrincipal.sub(withdrawAmt);
        stk.sumIppStart = pool.sumIpp[tranche];
        stk.lossZeroCounterBase = pool.lossZeroCounter[tranche];
        stk.lossMultiplierBase = pool.lossMultiplier[tranche];
        stk.earnedInterest = 0;
        if (stk.principal == 0) {
            stk.status = StakeStatus.Closed;
        }

        // update pool principal and interest information
        pool.principals[tranche] = pool.principals[tranche].sub(withdrawAmt);
        pool.interests[tranche] = pool.interests[tranche].sub(totalInterest);
        updateInterestRateAdjustment(token);
        if (INutDistributor(nutDistributor).inNutDistribution() && withdrawAmt > 0) {
            INutDistributor(nutDistributor).updateVtb(token, stk.owner, 0, withdrawAmt);
        }

        emit unstakeEvent(token, msg.sender, tranche, withdrawAmt, stk.id);
    }

    function _scaleByLossMultiplier(Stake memory stk, uint quantity) internal view returns (uint) {
	      Pool memory pool = poolMap[stk.pool];
	      return stk.lossZeroCounterBase < pool.lossZeroCounter[stk.tranche] ? 0 :
	          quantity.mul(
	          pool.lossMultiplier[stk.tranche]
	      ).div(
	          stk.lossMultiplierBase
	      );
    }

    /// @notice Accrue interest for a given pool.
    /// @param token Address of the pool.
    function accrueInterest(address token) internal {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'accrIr no pool');

        uint totalLoan = Math.sumOf3UintArray(pool.loans);
        uint currBlock = block.number;
        if (currBlock <= pool.latestAccruedBlock) return;
        if (totalLoan > 0 ) {
            uint interestRate = pool.interestRates[TRANCHE_A];
            if (!pool.isIrAdjustPctNegative) {
                interestRate = interestRate.mul(pool.irAdjustPct.add(100)).div(100);
            } else {
                interestRate = interestRate.mul(uint(100).sub(pool.irAdjustPct)).div(100);
            }
            uint rtb = interestRate.mul(currBlock.sub(pool.latestAccruedBlock));

            // update pool sumRtb.
            pool.sumRtb = pool.sumRtb.add(rtb);

            // update tranche sumIpp.
            for (uint idx = 0; idx < pool.loans.length; idx++) {
                if (pool.principals[idx] > 0) {
                    uint interest = (pool.loans[idx].mul(rtb)).div(NUM_BLOCK_PER_YEAR.mul(10000));
                    pool.interests[idx] = pool.interests[idx].add(interest);
                    pool.sumIpp[idx]= pool.sumIpp[idx].add(interest.mul(MULTIPLIER).div(pool.principals[idx]));
                }
            }
        }
        pool.latestAccruedBlock = block.number;
    }

    /// @notice Get pool information
    /// @param token The base token
    function getPoolInfo(address token) external view override returns(uint, uint, uint) {
        Pool memory pool = poolMap[token];
        require(pool.isExists, 'getPolInf no pol');
        return (Math.sumOf3UintArray(pool.principals),
                Math.sumOf3UintArray(pool.loans),
                pool.totalCollateral);
    }

    /// @notice Get interest a position need to pay
    /// @param token Address of the pool.
    /// @param posId Position ID.
    function getPositionInterest(address token, uint posId) public override view returns(uint) {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'getPosIR no pool');
        Position storage pos = positionMap[posId];
        require(pos.baseToken == pool.baseToken, 'getPosIR bad match');
        return Math.sumOf3UintArray(pos.loans).mul(pool.sumRtb.sub(pos.sumRtbStart)).div(
            NUM_BLOCK_PER_YEAR.mul(10000)
        );
    }

    /// @dev Update the interest rate adjustment of the pool
    /// @param token Address of the pool
    function updateInterestRateAdjustment(address token) public {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'updtIRAdj no pool');

        uint totalPrincipal = Math.sumOf3UintArray(pool.principals);
        uint totalLoan = Math.sumOf3UintArray(pool.loans);

        if (totalPrincipal > 0 ) {
            uint urPct = totalLoan >= totalPrincipal ? 100 : totalLoan.mul(100).div(totalPrincipal);
            if (urPct > 90) { // 0% + 50 * (UR - 90%)
                pool.irAdjustPct = urPct.sub(90).mul(50);
                pool.isIrAdjustPctNegative = false;
            } else if (urPct < 90) { // UR - 90%
                pool.irAdjustPct = (uint(90).sub(urPct));
                pool.isIrAdjustPctNegative = true;
            }
        }
    }

    function _getWithdrawAmount(Pool memory pool, uint amount) internal pure returns (uint) {
        uint availPrincipal = Math.sumOf3UintArray(pool.principals).sub(
            Math.sumOf3UintArray(pool.loans)
        );
        return amount > availPrincipal ? availPrincipal : amount;
    }

    /// @dev Get the collateral ratio of the pool.
    /// @param baseToken Base token of the pool.
    /// @param baseAmt The collateral from the borrower.
    function _getCollateralRatioPct(address baseToken, uint baseAmt) public view returns (uint) {
        Pool storage pool = poolMap[baseToken];
        require(pool.isExists, '_getCollRatPct no pool');

        uint totalPrincipal = Math.sumOf3UintArray(pool.principals);
        uint totalLoan = Math.sumOf3UintArray(pool.loans);
        uint urPct = (totalPrincipal == 0) ? 100 : ((totalLoan.add(baseAmt)).mul(100)).div(totalPrincipal);
        if (urPct > 100) { // not likely, but just in case.
            urPct = 100;
        }

        if (urPct > 90) { // 10% + 9 * (UR - 90%)
            return (urPct.sub(90).mul(9)).add(10);
        }
        // 10% - 0.1 * (90% - UR)
        return (urPct.div(10)).add(1);
    }

    /// @notice Get the maximum available borrow amount
    /// @param baseToken Base token of the pool
    /// @param baseAmt The collateral from the borrower
    function getMaxBorrowAmount(address baseToken, uint baseAmt)
        public override view returns (uint) {
        uint crPct = _getCollateralRatioPct(baseToken, baseAmt);
        return (baseAmt.mul(100).div(crPct)).sub(baseAmt);
    }


    /// @notice Get stakes of a user in a pool
    /// @param token The address of the pool
    /// @param owner The address of the owner
    function getStake(address token, address owner) public view returns (Stake[3] memory) {
        return stakeMap[token][owner];
    }

    /// @dev Add adapter to Nutmeg
    /// @param token The address of the adapter
    function addAdapter(address token) external poolLock onlyGov {
        adapters.push(token);
        adapterMap[token] = true;
    }

    /// @dev Remove adapter from Nutmeg
    /// @param token The address of the adapter
    function removeAdapter(address token) external poolLock onlyGov {
        adapterMap[token] = false;
    }

    /// @notice Borrow tokens from the pool. Must only be called by adapter while under execution.
    /// @param baseToken The token to borrow from the pool.
    /// @param collToken The token borrowers got from the 3rd party pool.
    /// @param baseAmt The amount of collateral from borrower.
    /// @param borrowAmt The amount of tokens to borrow, x time leveraged already.
    function borrow(address baseToken, address collToken, uint baseAmt, uint borrowAmt)
        external override accrue(baseToken) inExecution {
        // check pool and position.
        Pool storage pool = poolMap[baseToken];
        require(pool.isExists, 'brw no pool');
        Position storage position = positionMap[CURR_POSITION_ID];
        require(position.baseToken == address(0), 'brw no rebrw');

        // check borrowAmt
        uint maxBorrowAmt = getMaxBorrowAmount(baseToken, baseAmt);
        require(borrowAmt <= maxBorrowAmt, "brw too bad");
        require(borrowAmt > baseAmt, "brw brw < coll");

        // check available principal per tranche.
        uint[3] memory availPrincipals;
        for (uint i = 0; i < 3; i++) {
            availPrincipals[i] = pool.principals[i].sub(pool.loans[i]);
        }
        uint totalAvailPrincipal = Math.sumOf3UintArray(availPrincipals);
        require(borrowAmt <= totalAvailPrincipal, 'brw asset low');

        // calculate loan amount from each tranche.
        uint[3] memory loans;
        for (uint i = 0; i < 3; i++) {
            loans[i] = borrowAmt.mul(availPrincipals[i]).div(totalAvailPrincipal);
        }
        loans[2] = borrowAmt.sub(loans[0].add(loans[1])); // handling rounding numbers

        // transfer base tokens from borrower to contract as the collateral.
        IERC20(pool.baseToken).safeApprove(address(this), 0);
        IERC20(pool.baseToken).safeApprove(address(this), baseAmt);
        IERC20(pool.baseToken).safeTransferFrom(position.owner, address(this), baseAmt);

        // transfer borrowed assets to the adapter
        IERC20(pool.baseToken).safeTransfer(msg.sender, borrowAmt);

        // update position information
        position.status = PositionStatus.Open;
        position.baseToken = pool.baseToken;
        position.collToken = collToken;
        position.baseAmt = baseAmt;
        position.borrowAmt = borrowAmt;
        position.loans = loans;
        position.sumRtbStart = pool.sumRtb;

        borrowerPositionMap[position.owner].push(position.id);

        // update pool information
        for (uint i = 0; i < 3; i++) {
            pool.loans[i] = pool.loans[i].add(loans[i]);
        }
        pool.totalCollateral = pool.totalCollateral.add(baseAmt);
        updateInterestRateAdjustment(baseToken);
    }

    function _getRepayAmount(uint[3] memory loans, uint totalAmt)
        public pure returns(uint[3] memory) {
        uint totalLoan = Math.sumOf3UintArray(loans);
        uint amount = totalLoan < totalAmt ? totalLoan : totalAmt;
        uint[3] memory repays = [uint(0), uint(0), uint(0)];
        for (uint i; i < 3; i++) {
            repays[i] = (loans[i].mul(amount)).div(totalLoan);
        }
        repays[2] = amount.sub(repays[0].add(repays[1]));

        return repays;
    }

    /// @notice Repay tokens to the pool and close the position. Must only be called while under execution.
    /// @param baseToken The token to borrow from the pool.
    /// @param repayAmt The amount of base token repaid from adapter.
    function repay(address baseToken, uint repayAmt)
        external override accrue(baseToken) inExecution {

        Position storage pos = positionMap[CURR_POSITION_ID];
        Pool storage pool = poolMap[pos.baseToken];
        require(pool.isExists, 'rpy no pool');
        require(adapterMap[pos.adapter] && msg.sender == pos.adapter, 'repay: no such adapter');

        uint totalLoan = Math.sumOf3UintArray(pos.loans); // owe to lenders
        uint interest = getPositionInterest(pool.baseToken, pos.id); // already paid to lenders
        uint totalRepayAmt = repayAmt.add(pos.baseAmt).sub(interest); // total amount used for repayment
        uint change = totalRepayAmt > totalLoan ? totalRepayAmt.sub(totalLoan) : 0; // profit of the borrower


        // transfer total redeemed amount from adapter to the pool
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), repayAmt);
        if (totalRepayAmt < totalLoan) {
            pos.repayDeficit = totalLoan.sub(totalRepayAmt);
        }
        uint[3] memory repays = _getRepayAmount(pos.loans, repayAmt);
        // update position information
        pos.status = PositionStatus.Closed;
        for (uint i; i < 3; i++) {
            pos.loans[i] = pos.loans[i].sub(repays[i]);
        }

        // update pool information
        pool.totalCollateral = pool.totalCollateral.sub(pos.baseAmt);
        for (uint i; i < 3; i++) {
            pool.loans[i] = pool.loans[i].sub(repays[i]);
        }

        // send profit, if any to the borrower.
        if (change > 0) {
            IERC20(baseToken).safeTransfer(pos.owner, change);
        }
    }

    /// @notice Liquidate a position when conditions are satisfied
    /// @param baseToken The base token of the pool.
    /// @param liquidateAmt The repay amount from adapter.
    function liquidate( address baseToken, uint liquidateAmt)
        external override accrue(baseToken) inExecution {
        Position storage pos = positionMap[CURR_POSITION_ID];
        Pool storage pool = poolMap[baseToken];
        require(pool.isExists, 'lqt no pool');
        require(pool.baseToken == baseToken, "lqt base no match");
        require(adapterMap[pos.adapter] && msg.sender == pos.adapter, 'lqt no adpr');
        require(liquidateAmt > 0, 'lqt bad rpy');

        // transfer liquidateAmt of base tokens from adapter to pool.
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), liquidateAmt);

        uint totalLoan = Math.sumOf3UintArray(pos.loans);
        uint interest = getPositionInterest(pool.baseToken, pos.id);
        uint totalRepayAmt = liquidateAmt.add(pos.baseAmt).sub(interest); // total base tokens from liquidated
        uint bonusAmt = LIQUIDATION_COMMISSION.mul(totalRepayAmt).div(100); // bonus for liquidator.

        uint repayAmt = totalRepayAmt.sub(bonusAmt); // amount to pay lenders and the borrower
        uint change = totalLoan < repayAmt ? repayAmt.sub(totalLoan) : 0;

        uint[3] memory repays = _getRepayAmount(pos.loans, liquidateAmt);

        // transfer bonus to the liquidator.
        IERC20(baseToken).safeTransfer(tx.origin, bonusAmt);

        // update position information
        pos.status = PositionStatus.Liquidated;
        for (uint i; i < 3; i++) {
            pos.loans[i] = pos.loans[i].sub(repays[i]);
        }

        // update pool information
        pool.totalCollateral = pool.totalCollateral.sub(pos.baseAmt);
        for (uint i; i < 3; i++) {
            pool.loans[i] = pool.loans[i].sub(repays[i]);
        }

        // send leftover to position owner
        if (change > 0) {
            IERC20(baseToken).safeTransfer(pos.owner, change);
        }
        if (totalRepayAmt < totalLoan) {
            pos.repayDeficit = totalLoan.sub(totalRepayAmt);
        }
    }

    /// @notice Settle credit event callback
    /// @param baseToken Base token of the pool.
    /// @param collateralLoss Loss to be distributed
    /// @param poolLoss Loss to be distributed
    function distributeCreditLosses( address baseToken, uint collateralLoss, uint poolLoss) external override accrue(baseToken) inExecution {
        Pool storage pool = poolMap[baseToken];
        require(pool.isExists, 'dstCrd no pool');
        require(collateralLoss <= pool.totalCollateral, 'dstCrd col high');
        if (collateralLoss >= 0) {
            pool.totalCollateral = pool.totalCollateral.sub(collateralLoss);
        }

        if (poolLoss == 0) {
            return;
        }

        uint totalPrincipal = Math.sumOf3UintArray(pool.principals);

        uint runningLoss = poolLoss;
        for (uint i = 0; i < 3; i++) {
            uint j = 3 - i - 1;
            // The running totals are based on the principal,
            // however, when I calculate the multipliers, I
            // take into account accured interest
            uint tranchePrincipal = pool.principals[j];
            uint trancheValue = pool.principals[j] + pool.interests[j];
            // Do not scale pool.sumIpp.  Since I am scaling the
            // principal, this will cause the interest rate
            // calcuations to take into account the losses when
            // a lender position is unstaked.
            if (runningLoss >= tranchePrincipal) {
                pool.principals[j] = 0;
                pool.interests[j] = 0;
                pool.lossZeroCounter[j] = block.number;
                pool.lossMultiplier[j] = MULTIPLIER;
                runningLoss = runningLoss.sub(tranchePrincipal);
            } else {
                uint valueRemaining = tranchePrincipal.sub(runningLoss);
		            pool.principals[j] = pool.principals[j].mul(valueRemaining).div(trancheValue);
		            pool.interests[j] = pool.interests[j].mul(valueRemaining).div(trancheValue);
		            pool.lossMultiplier[j] = valueRemaining.mul(MULTIPLIER).div(trancheValue);
		            break;
	          }
        }

        // subtract the pool loss from the total loans
        // this keeps principal - loans the same so that
        // we have a correct accounting of the amount of
        // liquidity available for borrows.

        uint totalLoans = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);
        totalPrincipal = (poolLoss <= totalPrincipal) ? totalPrincipal.sub(poolLoss) : 0;
        totalLoans = (poolLoss <= totalLoans) ? totalLoans.sub(poolLoss) : 0;

        for (uint i = 0; i < pool.loans.length; i++) {
            pool.loans[i] = totalPrincipal == 0 ? 0 : totalLoans.mul(pool.principals[i]).div(totalPrincipal);
        }
    }

    /// @notice Add collateral token to position. Must be called during execution.
    /// @param posId Position id
    /// @param collAmt The amount of the collateral token from 3rd party pool.
    function addCollToken(uint posId, uint collAmt)
        external override inExecution {
        Position storage pos = positionMap[CURR_POSITION_ID];
        require(pos.id == posId, "addCollTk bad pos");

        pos.collAmt = collAmt;
    }

    function getEarnedInterest( address token, address owner, Tranche tranche ) external view returns (uint256) {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'gtErndIr no pool');
        Stake memory stk = getStake(token, owner)[uint(tranche)];
        return _scaleByLossMultiplier(
            stk,
            stk.earnedInterest.add(
                stk.principal.mul(
                    pool.sumIpp[uint(tranche)].sub(stk.sumIppStart)
                ).div(MULTIPLIER))
        );
    }

    /// -------------------------------------------------------------------
    /// functions to adapter
    function beforeExecution( uint posId, IAdapter adapter ) internal {
        require(POOL_LOCK == NOT_LOCKED, 'pol lck');
        POOL_LOCK = LOCKED;
        address adapterAddr = address(adapter);
        require(adapterMap[adapterAddr], 'no adpr');

        if (posId == 0) {
            // create a new position
            posId = POSITION_COUNTER++;
            positionMap[posId].id = posId;
            positionMap[posId].owner = msg.sender;
            positionMap[posId].adapter = adapterAddr;
        } else {
            require(posId < POSITION_COUNTER, 'no pos');
            require(positionMap[posId].status == PositionStatus.Open, 'only open pos');
        }

        CURR_POSITION_ID = posId;
        CURR_ADAPTER = adapterAddr;
        CURR_SENDER = msg.sender;
    }

    function afterExecution() internal {
        CURR_POSITION_ID = INVALID_POSITION_ID;
        CURR_ADAPTER = INVALID_ADAPTER;
        POOL_LOCK = NOT_LOCKED;
        CURR_SENDER = address(0);
    }

    function openPosition( uint posId, IAdapter adapter, address baseToken, address collToken, uint baseAmt, uint borrowAmt ) external {
        uint balance = IERC20(nut).balanceOf(msg.sender);
        require(minNut4Borrowers[baseToken][address(adapter)] <= balance, 'NUT low');
        beforeExecution(posId, adapter);
        adapter.openPosition( baseToken, collToken, baseAmt, borrowAmt );
        afterExecution();
    }

    function closePosition( uint posId, IAdapter adapter ) external returns (uint) {
        beforeExecution(posId, adapter);
        uint redeemAmt = adapter.closePosition();
        afterExecution();
        return redeemAmt;
    }

    function liquidatePosition( uint posId, IAdapter adapter ) external {
        beforeExecution(posId, adapter);
        adapter.liquidate();
        afterExecution();
    }

    function settleCreditEvent( IAdapter adapter, address baseToken, uint collateralLoss, uint poolLoss ) onlyGov external {
        beforeExecution(0, adapter);
        adapter.settleCreditEvent( baseToken, collateralLoss, poolLoss );
        afterExecution();
    }

    function getMaxUnstakePrincipal(address token, address owner, uint tranche) external view returns (uint) {
        Stake memory stk = stakeMap[token][owner][tranche];
        return _getWithdrawAmount(poolMap[stk.pool], stk.principal);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library Math {
    using SafeMath for uint;

    function sumOf3UintArray(uint[3] memory data) internal pure returns(uint) {
        return data[0].add(data[1]).add(data[2]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IAdapter {
    function openPosition( address baseToken, address collToken, uint collAmount, uint borrowAmount ) external;
    function closePosition() external returns (uint);
    function liquidate() external;
    function settleCreditEvent(
        address baseToken, uint collateralLoss, uint poolLoss) external;

    event openPositionEvent(uint positionId, address caller, uint baseAmt, uint borrowAmount);
    event closePositionEvent(uint positionId, address caller, uint amount);
    event liquidateEvent(uint positionId, address caller);
    event creditEvent(address token, uint collateralLoss, uint poolLoss);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface INutmeg {
    enum Tranche {AA, A, BBB}
    enum StakeStatus {Uninitialized, Open, Closed, Settled}
    enum PositionStatus {Uninitialized, Open, Closed, Liquidated, Settled}

    struct Pool {
        bool isExists;
        address baseToken; // base token of this pool, e.g., WETH, DAI.
        uint[3] interestRates; // interest rate per block of each tranche. supposed to be updated everyday.
        uint[3] principals; // principals of each tranche, from lenders
        uint[3] loans; // loans of each tranche, from borrowers.
        uint[3] interests; // interests accrued from loans for each tranche.

        uint totalCollateral; // total collaterals in base token from borrowers.
        uint latestAccruedBlock; // the block number of the latest interest accrual action.
        uint sumRtb; // sum of interest rate per block (after adjustment) times # of blocks
        uint irAdjustPct; // interest rate adjustment in percentage, e.g., 1, 99.
        bool isIrAdjustPctNegative; // whether interestRateAdjustPct is negative
        uint[3] sumIpp; // sum of interest per principal.
        uint[3] lossMultiplier;
        uint[3] lossZeroCounter;
    }

    struct Stake {
        uint id;
        StakeStatus status;
        address owner;
        address pool;
        uint tranche; // tranche of the pool, 0 - AA, 1 - A, 2 - BBB.
        uint principal;
        uint sumIppStart;
        uint earnedInterest;
        uint lossMultiplierBase;
        uint lossZeroCounterBase;
    }

    struct Position {
        uint id; // id of the position.
        PositionStatus status; // status of the position, Open, Close, and Liquidated.
        address owner; // borrower's address
        address adapter; // adapter's address
        address baseToken; // base token that the borrower borrows from the pool
        address collToken; // collateral token that the borrower got from 3rd party pool.
        uint[3] loans; // loans of all tranches
        uint baseAmt; // amount of the base token the borrower put into pool as the collateral.
        uint collAmt; // amount of collateral token the borrower got from 3rd party pool.
        uint borrowAmt; // amount of base tokens borrowed from the pool.
        uint sumRtbStart; // rate times block when the position is created.
        uint repayDeficit; // repay pool loss
    }

    struct NutDist {
        uint endBlock;
        uint amount;
    }

    /// @dev Get all stake IDs of a lender
    function getStakeIds(address lender) external view returns (uint[] memory);

    /// @dev Get all position IDs of a borrower
    function getPositionIds(address borrower) external view returns (uint[] memory);

    /// @dev Get the maximum available borrow amount
    function getMaxBorrowAmount(address token, uint collAmount) external view returns(uint);

    /// @dev Get the current position while under execution.
    function getCurrPositionId() external view returns (uint);

    /// @dev Get the next position ID while under execution.
    function getNextPositionId() external view returns (uint);

    /// @dev Get the current sender while under execution
    function getCurrSender() external view returns (address);

    function getPosition(uint id) external view returns (Position memory);

    function getPositionInterest(address token, uint positionId) external view returns(uint);

    function getPoolInfo(address token) external view returns(uint, uint, uint);

    /// @dev Add Collateral token from the 3rd party pool to a position
    function addCollToken(uint posId, uint collAmt) external;

    /// @dev Borrow tokens from the pool.
    function borrow(address token, address collAddr, uint baseAmount, uint borrowAmount) external;

    /// @dev Repays tokens to the pool.
    function repay(address token, uint repayAmount) external;

    /// @dev Liquidate a position when conditions are satisfied
    function liquidate(address token, uint repayAmount) external;

    /// @dev Settle credit event
    function distributeCreditLosses( address baseToken, uint collateralLoss, uint poolLoss) external;
    event addPoolEvent(address bank, uint interestRateA);
    event stakeEvent(address bank, address owner, uint tranche, uint amount, uint depId);
    event unstakeEvent(address bank, address owner, uint tranche, uint amount, uint depId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ICERC20.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/INutmeg.sol";
import "../lib/Governable.sol";
import "../lib/Math.sol";

contract CompoundAdapter is Governable, IAdapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct PosInfo {
        uint posId;
        uint collAmt;
        uint sumIpcStart;
    }

    INutmeg public immutable nutmeg;

    uint private constant MULTIPLIER = 10**18;

    address[] public baseTokens; // array of base tokens
    mapping(address => bool) public baseTokenMap; // e.g., Dai
    mapping(address => address) public tokenPairs; // Dai -> cDai or cDai -> Dai;
    mapping(address => uint) public totalMintAmt;
    mapping(address => uint) public sumIpcMap;
    mapping(uint => PosInfo) public posInfoMap;

    mapping(address => uint) public totalLoan;
    mapping(address => uint) public totalCollateral;
    mapping(address => uint) public totalLoss;

    constructor(INutmeg nutmegAddr) {
        nutmeg = nutmegAddr;
        __Governable__init();
    }

    modifier onlyNutmeg() {
        require(msg.sender == address(nutmeg), 'only nutmeg can call');
        _;
    }

    /// @dev Add baseToken collToken pairs
    function addTokenPair(address baseToken, address collToken) external onlyGov {
        baseTokenMap[baseToken] = true;
        tokenPairs[baseToken] = collToken;
        baseTokens.push(baseToken);
    }

    /// @dev Remove baseToken collToken pairs
    function removeTokenPair(address baseToken) external onlyGov {
        baseTokenMap[baseToken] = false;
        tokenPairs[baseToken] = address(0);
    }

    /// @notice Open a position.
    /// @param baseToken Base token of the position.
    /// @param collToken Collateral token of the position.
    /// @param baseAmt Amount of collateral in base token.
    /// @param borrowAmt Amount of base token to be borrowed from nutmeg.
    function openPosition(address baseToken, address collToken, uint baseAmt, uint borrowAmt)
        external onlyNutmeg override {
        require(baseAmt > 0, 'openPosition: invalid base amount');
        require(baseTokenMap[baseToken], 'openPosition: invalid baseToken address');
        require(tokenPairs[baseToken] == collToken, 'openPosition: invalid cToken address');

        uint posId = nutmeg.getCurrPositionId();
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        require(nutmeg.getCurrSender() == pos.owner, 'openPosition: only owner can initialize this call');
        require(IERC20(baseToken).balanceOf(pos.owner) >= baseAmt, 'openPosition: insufficient balance');

        // check borrowAmt
        uint maxBorrowAmt = nutmeg.getMaxBorrowAmount(baseToken, baseAmt);
        require(borrowAmt <= maxBorrowAmt, "openPosition: borrowAmt exceeds maximum");
        require(borrowAmt > baseAmt, "openPosition: borrowAmt is less than collateral");

        // borrow base tokens from nutmeg
        nutmeg.borrow(baseToken, collToken, baseAmt, borrowAmt);

        _increaseDebtAndCollateral(baseToken, posId);

        // mint collateral tokens from compound
        pos = nutmeg.getPosition(posId);
        (uint result, uint mintAmt) = _doMint(pos, borrowAmt);
        require(result == 0, 'opnPos: _doMint fail');
        if (mintAmt > 0) {
            uint currSumIpc = _calcLatestSumIpc(collToken);
            totalMintAmt[collToken] = totalMintAmt[collToken].add(mintAmt);
            PosInfo storage posInfo = posInfoMap[posId];
            posInfo.sumIpcStart = currSumIpc;
            posInfo.collAmt = mintAmt;

            // add mintAmt to the position in nutmeg.
            nutmeg.addCollToken(posId, mintAmt);
        }
        emit openPositionEvent(posId, nutmeg.getCurrSender(), baseAmt, borrowAmt);
    }

    /// @notice Close a position by the borrower
    function closePosition() external onlyNutmeg override returns (uint) {
        uint posId = nutmeg.getCurrPositionId();
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        require(pos.owner == nutmeg.getCurrSender(), 'closePosition: original caller is not the owner');

        uint collAmt = _getCollTokenAmount(pos);
        (uint result, uint redeemAmt) = _doRedeem(pos, collAmt);
        require(result == 0, 'clsPos: rdm fail');

        // allow nutmeg to receive redeemAmt from the adapter
        IERC20(pos.baseToken).safeApprove(address(nutmeg), 0);
        IERC20(pos.baseToken).safeApprove(address(nutmeg), redeemAmt);

        // repay to nutmeg
        _decreaseDebtAndCollateral(pos.baseToken, pos.id, redeemAmt);
        nutmeg.repay(pos.baseToken, redeemAmt);
        pos = nutmeg.getPosition(posId);
        totalLoss[pos.baseToken] =
            totalLoss[pos.baseToken].add(pos.repayDeficit);
        totalMintAmt[pos.collToken] = totalMintAmt[pos.collToken].sub(pos.collAmt);
        emit closePositionEvent(posId, nutmeg.getCurrSender(), redeemAmt);
        return redeemAmt;
    }

    /// @notice Liquidate a position
    function liquidate() external override onlyNutmeg  {
        uint posId = nutmeg.getCurrPositionId();
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        require(_okToLiquidate(pos), 'liquidate: position is not ready for liquidation yet.');

        uint amount = _getCollTokenAmount(pos);
        (uint result, uint redeemAmt) = _doRedeem(pos, amount);
        require(result == 0, 'lqdte: rdm fail');
        IERC20(pos.baseToken).safeApprove(address(nutmeg), 0);
        IERC20(pos.baseToken).safeApprove(address(nutmeg), redeemAmt);

        // liquidate the position in nutmeg.
        _decreaseDebtAndCollateral(pos.baseToken, posId, redeemAmt);
        nutmeg.liquidate(pos.baseToken, redeemAmt);
        pos = nutmeg.getPosition(posId);
        totalLoss[pos.baseToken] = totalLoss[pos.baseToken].add(pos.repayDeficit);
        totalMintAmt[pos.collToken] = totalMintAmt[pos.collToken].sub(pos.collAmt);
        emit liquidateEvent(posId, nutmeg.getCurrSender());
    }
    /// @notice Get value of credit tokens
    function creditTokenValue(address baseToken) public returns (uint) {
        address collToken = tokenPairs[baseToken];
        require(collToken != address(0), "settleCreditEvent: invalid collateral token" );
        uint collTokenBal = ICERC20(collToken).balanceOf(address(this));
        return collTokenBal.mul(ICERC20(collToken).exchangeRateCurrent());
    }

    /// @notice Settle credit event
    /// @param baseToken The base token address
    function settleCreditEvent( address baseToken, uint collateralLoss, uint poolLoss) external override onlyNutmeg {
        require(baseTokenMap[baseToken] , "settleCreditEvent: invalid base token" );
        require(collateralLoss <= totalCollateral[baseToken], "settleCreditEvent: invalid collateral" );
        require(poolLoss <= totalLoan[baseToken], "settleCreditEvent: invalid poolLoss" );

        nutmeg.distributeCreditLosses(baseToken, collateralLoss, poolLoss);

        emit creditEvent(baseToken, collateralLoss, poolLoss);
        totalLoss[baseToken] = 0;
        totalLoan[baseToken] = totalLoan[baseToken].sub(poolLoss);
        totalCollateral[baseToken] = totalCollateral[baseToken].sub(collateralLoss);
    }

    function _increaseDebtAndCollateral(address token, uint posId) internal {
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        for (uint i = 0; i < 3; i++) {
            totalLoan[token] = totalLoan[token].add(pos.loans[i]);
        }
        totalCollateral[token] = totalCollateral[token].add(pos.baseAmt);
    }

    /// @dev decreaseDebtAndCollateral
    function _decreaseDebtAndCollateral(address token, uint posId, uint redeemAmt) internal {
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        uint totalLoans = pos.loans[0] + pos.loans[1] + pos.loans[2];
        if (redeemAmt >= totalLoans) {
            totalLoan[token] = totalLoan[token].sub(totalLoans);
        } else {
            totalLoan[token] = totalLoan[token].sub(redeemAmt);
        }
        totalCollateral[token] = totalCollateral[token].sub(pos.baseAmt);
    }

    /// @dev Do the mint from the 3rd party pool.this
    function _doMint(INutmeg.Position memory pos, uint amount) internal returns(uint, uint) {
        uint balBefore = ICERC20(pos.collToken).balanceOf(address(this));
        require(IERC20(pos.baseToken).approve(pos.collToken, 0), '_doMint approve error');
        require(IERC20(pos.baseToken).approve(pos.collToken, amount), '_doMint approve amount error');
        uint result = ICERC20(pos.collToken).mint(amount);
        require(result == 0, '_doMint mint error');
        uint balAfter = ICERC20(pos.collToken).balanceOf(address(this));
        uint mintAmount = balAfter.sub(balBefore);
        return (result, mintAmount);
    }

    /// @dev Do the redeem from the 3rd party pool.
    function _doRedeem(INutmeg.Position memory pos, uint amount) internal returns(uint, uint) {
        uint balBefore = IERC20(pos.baseToken).balanceOf(address(this));
        uint result = ICERC20(pos.collToken).redeem(amount);
        uint balAfter = IERC20(pos.baseToken).balanceOf(address(this));
        uint redeemAmt = balAfter.sub(balBefore);
        return (result, redeemAmt);
    }

    /// @dev Get the amount of collToken a position.
    function _getCollTokenAmount(INutmeg.Position memory pos) internal returns(uint) {
        uint currSumIpc = _calcLatestSumIpc(pos.collToken);
        PosInfo storage posInfo = posInfoMap[pos.id];
        uint interest = posInfo.collAmt.mul(currSumIpc.sub(posInfo.sumIpcStart)).div(MULTIPLIER);
        return posInfo.collAmt.add(interest);
    }

    /// @dev Calculate the latest sumIpc.
    /// @param collToken The cToken.
    function _calcLatestSumIpc(address collToken) internal returns(uint) {
        uint balance = ICERC20(collToken).balanceOf(address(this));
        uint mintBalance = totalMintAmt[collToken];
        uint interest = mintBalance > balance ? mintBalance.sub(balance) : 0;
        uint currIpc = (mintBalance == 0) ? 0 : (interest.mul(MULTIPLIER)).div(mintBalance);
        if (currIpc > 0){
            sumIpcMap[collToken] = sumIpcMap[collToken].add(currIpc);
        }
        return sumIpcMap[collToken];
    }

    /// @dev Check if the position is eligible to be liquidated.
    function _okToLiquidate(INutmeg.Position memory pos) internal view returns(bool) {
        bool ok = false;
        uint interest = nutmeg.getPositionInterest(pos.baseToken, pos.id);
        if (interest.mul(2) >= pos.baseAmt) {
            ok = true;
        }
        return ok;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICERC20 {
    function mint(uint) external returns (uint);
    function redeem(uint) external returns (uint);
    function transfer(address dst, uint amount) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function supplyRatePerBlock() external returns (uint);
    function approve(address spender, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IWETH {
    function balanceOf(address user) external returns (uint);
    function approve(address to, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

// Modified from original alphahomora which used 0.6.12
pragma solidity 0.7.6;

interface ICErc20 {
  function decimals() external returns (uint8);

  function underlying() external returns (address);

  function mint(uint mintAmount) external returns (uint);

  function redeem(uint redeemTokens) external returns (uint);

  function balanceOf(address user) external view returns (uint);

  function borrowBalanceCurrent(address account) external returns (uint);

  function borrowBalanceStored(address account) external view returns (uint);

  function borrow(uint borrowAmount) external returns (uint);

  function repayBorrow(uint repayAmount) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "../Nutmeg.sol";

// @notice This contract is a version of Nutmeg that contains additional
// interfaces for testing

contract NutmegAltA is Nutmeg {
    //@notice output version string
    function getVersionString()
    external virtual pure returns (string memory) {
        return "nutmegalta";
   }
}

contract NutmegAltB is Nutmeg {
    //@notice output version string
    function getVersionString()
    external virtual pure returns (string memory) {
        return "nutmegaltb";
   }
}

import "../NutDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// @notice This contract is a version of NutDistributor that allows
// the epoch intervals to be changed for testing

contract NutDistributorAltA is NutDistributor {
    //@notice output version string
    function getVersionString()
    external virtual pure override returns (string memory) {
        return "nutdistributoralta";
   }
}

contract NutDistributorAltB is NutDistributor {
    //@notice output version string
    function getVersionString()
    external virtual pure override returns (string memory) {
        return "nutdistributoraltb";
   }
}

import "./MockERC20.sol";

contract MockERC20AltA is
MockERC20("MockERC20AltA", "MOCKERC20ALTA", 18) {
}

contract MockERC20AltB is
MockERC20("MockERC20AltB", "MOCKERC20ALTB", 18) {
}

contract MockERC20AltC is
MockERC20("MockERC20AltC", "MOCKERC20ALTC", 6) {
}

import "./MockCERC20.sol";

contract MockCERC20AltA is MockCERC20Base {
    constructor(address tokenAddr)
    MockCERC20Base(tokenAddr, "MockCERC20 AltA", "MOCKCERC20ALTA", 18) {
    }
}
contract MockCERC20AltB is MockCERC20Base {
    constructor(address tokenAddr)
    MockCERC20Base(tokenAddr, "MockCERC20 AltB", "MOCKCERC20ALTB", 18) {
    }
}
contract MockCERC20AltC is MockCERC20Base {
    constructor(address tokenAddr)
    MockCERC20Base(tokenAddr, "MockCERC20 AltC", "MOCKCERC20ALTC", 6) {
    }
}

import "../adapters/CompoundAdapter.sol";
import "../interfaces/INutmeg.sol";
contract CompoundAdapterAltA is CompoundAdapter {
    constructor(INutmeg nutmegAddr) CompoundAdapter(nutmegAddr) {
    }
}

contract CompoundAdapterAltB is CompoundAdapter {
    constructor(INutmeg nutmegAddr) CompoundAdapter(nutmegAddr) {
    }
}

// SPDX-License-Identifier: MIT
// Mock ERC20 token for testing

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  function mint(address to, uint amount) external {
    _mint(to, amount);
  }
}

// SPDX-License-Identifier: MIT
// Mock ERC20 token for testing

pragma solidity 0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/ICERC20.sol";

contract MockCERC20Base is ICERC20, ERC20 {
    address public immutable token;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint private constant MULTIPLIER = 10**18;
    uint public exchangeRate;
    bool public returnError;
    constructor(
        address tokenAddr,
        string memory name_, string memory symbol_, uint8 decimals_)
    ERC20(name_, symbol_) {
        token = tokenAddr;
        exchangeRate = MULTIPLIER;
        returnError = false;
        _setupDecimals(decimals_);
    }

    function mint(uint amount) external override returns (uint) {
        if (returnError) return 1;
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount.mul(MULTIPLIER).div(exchangeRate));
        return 0;
    }
    function redeem(uint amount) external override returns (uint) {
        if (returnError) return 1;
        IERC20(token).safeTransfer(
            msg.sender, amount.mul(exchangeRate).div(MULTIPLIER)
        );
        _burn(msg.sender, amount);
        return 0;
    }
    function redeemUnderlying(uint amount) external override returns (uint) {
        if (returnError) return 1;
        IERC20(token).safeTransfer(msg.sender, amount);
        _burn(
            msg.sender, amount.mul(MULTIPLIER).div(exchangeRate)
        );
        return 0;
    }
    function exchangeRateCurrent() external view override returns (uint) {
        return exchangeRate;
    }
    function supplyRatePerBlock() external pure override returns (uint) {
        return 0;
    }
    function balanceOf(address account) public override(ERC20, ICERC20) view returns (uint) {
        return ERC20.balanceOf(account);
    }
    function approve(address account, uint amount) public override(ERC20, ICERC20) returns (bool) {
        return ERC20.approve(account, amount);
    }
    function transfer(address dst, uint amount) public override(ERC20, ICERC20) returns (bool) {
        return ERC20.transfer(dst, amount);
    }

    function setExchangeRate(uint e) external {
        exchangeRate = e;
    }
    function setError(bool b) external {
        returnError = b;
    }
}

contract MockCERC20 is MockCERC20Base {
    constructor(address tokenAddr) MockCERC20Base(
        tokenAddr, "MockCERC20", "MCERC20", 18
    ) {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import './IERC20Mock.sol';

// Export ICEther interface for mainnet-fork testing.
interface ICEtherMock is IERC20Mock {
  function mint() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Export IERC20 interface for mainnet-fork testing.
interface IERC20Mock is IERC20 {
  function name() external view returns (string memory);

  function owner() external view returns (address);

  function issue(uint) external;

  function issue(address, uint) external;

  function mint(address, uint) external;

  function mint(
    address,
    uint,
    uint
  ) external returns (bool);

  function configureMinter(address, uint) external returns (bool);

  function masterMinter() external view returns (address);

  function deposit() external payable;

  function deposit(uint) external;

  function decimals() external view returns (uint);

  function target() external view returns (address);

  function erc20Impl() external view returns (address);

  function custodian() external view returns (address);

  function requestPrint(address, uint) external returns (bytes32);

  function confirmPrint(bytes32) external;

  function invest(uint) external;

  function increaseSupply(uint) external;

  function supplyController() external view returns (address);

  function getModules() external view returns (address[] memory);

  function addMinter(address) external;

  function governance() external view returns (address);

  function core() external view returns (address);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function symbol() external view returns (string memory);

  function getFinalTokens() external view returns (address[] memory);

  function joinPool(uint, uint[] memory) external;

  function getBalance(address) external view returns (uint);

  function createTokens(uint) external returns (bool);

  function resolverAddressesRequired() external view returns (bytes32[] memory addresses);

  function exchangeRateStored() external view returns (uint);

  function accrueInterest() external returns (uint);

  function resolver() external view returns (address);

  function repository(bytes32) external view returns (address);

  function underlying() external view returns (address);

  function mint(uint) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function minter() external view returns (address);

  function borrow(uint) external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IUNISWAP {
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      virtual
      payable
      returns (uint[] memory amounts);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      virtual
      returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../lib/Math.sol';


contract Formula {
    using SafeMath for uint;

    constructor (){}

    function div(uint a, uint b) external pure returns(uint){
      return a.div(b);
    }

    function mul(uint a, uint b) external pure returns(uint){
      return a.mul(b);
    }

    function add(uint a, uint b) external pure returns(uint){
      return a.add(b);
    }

    function sub(uint a, uint b) external pure returns(uint){
      return a.sub(b);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import '../adapters/CompoundAdapter.sol';
import '../interfaces/IAdapter.sol';
import '../interfaces/INutmeg.sol';

contract MockAdapter is CompoundAdapter {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  event Received(address, uint);
  address public immutable weth;

  constructor(INutmeg nutmegAddr, address wethAddr) CompoundAdapter(nutmegAddr) {
    weth = wethAddr;
  }

  function test() external pure {
  }

  function testFail() external pure {
    require(false, "fail");
  }

  function testBorrow(uint amount) external {
    INutmeg(nutmeg).borrow(weth, address(this), amount-10, amount);
  }

  function testCurrPositionId(uint pos) external view {
    uint posret = INutmeg(nutmeg).getCurrPositionId();
    require(pos == posret, 'testCurrentPosition failed');
  }

  function testPosition(uint pos) external view {
    INutmeg.Position memory p = INutmeg(nutmeg).getPosition(pos);
    require(p.id == pos, 'testPosition failed');
  }

  function testRepay(address token, uint repayAmount) external {
    INutmeg(nutmeg).repay(token, repayAmount);
  }

  receive() external payable {
     emit Received(msg.sender, msg.value);
  }
}

/* Local Variables:   */
/* mode: javascript   */
/* js-indent-level: 2 */
/* End:               */

// SPDX-License-Identifier: MIT
// Mock WETH token for testing

pragma solidity 0.7.6;

contract MockWETH {
  string public constant name = 'Wrapped Ether';
  string public constant symbol = 'WETH';
  uint8 public constant decimals = 18;

  event Approval(address indexed src, address indexed guy, uint wad);
  event Transfer(address indexed src, address indexed dst, uint wad);
  event Deposit(address indexed dst, uint wad);
  event Withdrawal(address indexed src, uint wad);

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  receive() external payable {
    deposit();
  }

  function deposit() public payable {
    balanceOf[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint wad) external {
    require(balanceOf[msg.sender] >= wad);
    balanceOf[msg.sender] -= wad;
    payable(msg.sender).transfer(wad);
    emit Withdrawal(msg.sender, wad);
  }

  function totalSupply() external view returns (uint) {
    return address(this).balance;
  }

  function approve(address guy, uint wad) external returns (bool) {
    allowance[msg.sender][guy] = wad;
    emit Approval(msg.sender, guy, wad);
    return true;
  }

  function transfer(address dst, uint wad) external returns (bool) {
    return transferFrom(msg.sender, dst, wad);
  }

  function transferFrom(
    address src,
    address dst,
    uint wad
  ) public returns (bool) {
    require(balanceOf[src] >= wad);

    if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
      require(allowance[src][msg.sender] >= wad);
      allowance[src][msg.sender] -= wad;
    }

    balanceOf[src] -= wad;
    balanceOf[dst] += wad;

    emit Transfer(src, dst, wad);

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "../NutDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// @notice This contract is a version of NutDistributor that allows
// the epoch intervals to be changed for testing

contract TestNutDistributor is NutDistributor {
    using SafeMath for uint;
    function initialize (
        address nutAddr,
        address _governor,
        uint blocks_per_epoch
    ) external initializer {
        initialize(nutAddr, _governor);
	BLOCKS_PER_EPOCH = blocks_per_epoch;

        // config echoMap which indicates how many tokens will be distributed at each epoch
        for (uint i = 0; i < NUM_EPOCH; i++) {
            Echo storage echo =  echoMap[i];
            echo.id = i;
            echo.endBlock = DIST_START_BLOCK.add(BLOCKS_PER_EPOCH.mul(i.add(1)));
            uint amount = DIST_START_AMOUNT.div(i.add(1));
            if (amount < DIST_MIN_AMOUNT) {
                amount = DIST_MIN_AMOUNT;
            }
            echo.amount = amount;
        }
    }

    //@notice output version string
    function getVersionString()
    external virtual pure override returns (string memory) {
        return "test.nutdistrib";
   }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import "../Nutmeg.sol";

// @notice This contract is a version of Nutmeg that contains additional
// interfaces for testing

contract TestNutmeg is Nutmeg {
    function _testSetBaseAmt (
	uint posId, uint baseAmt
    ) external {
	positionMap[posId].baseAmt = baseAmt;
    }

    function _forceAccrueInterest(
        address token
    ) external {
        accrueInterest(token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../lib/Governable.sol';
import "../interfaces/IPriceOracle.sol";

contract PriceOracle is IPriceOracle, Governable {

    mapping(address => uint) public priceMap;

    event setPriceEvent(address token, uint price);

    constructor() {
        __Governable__init();
    }

    /// @notice Return the value of the given token in ETH.
    /// @param token The ERC20 token
    function getPrice(address token) external view override returns (uint) {
        uint price = priceMap[token];
        require(price != 0, 'getPrice: price not found.');
        return price;
    }

    /// @notice Set the prices of the given tokens.
    /// @param tokens The tokens to set the prices.
    /// @param prices The prices of tokens.
    function setPrices(address[] memory tokens, uint[] memory prices) external onlyGov {
        require(tokens.length == prices.length, 'setPrices: lengths do not match');
        for (uint i = 0; i < tokens.length; i++) {
            priceMap[tokens[i]] = prices[i];
            emit setPriceEvent(tokens[i], prices[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}