// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// Use upgradeable library.  These interfaces will work for tokens that
// are non-upgradeable

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
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
    using SafeERC20Upgradeable for IERC20Upgradeable;

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
    // This are in fact interest rate per apy
    // but keeping old names for legacy front end
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
    mapping(uint => uint) nutStakedMap; // the number of nut tokens staked in a position

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
    function initialize(address _governor, address _nutAddr, address _nutDistAddr) external initializer {
        __Governable__init(_governor);
        nut = _nutAddr;
        nutDistributor = _nutDistAddr;
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

        // 1. check pre-conditions
        Stake storage stk = stakeMap[token][msg.sender][tranche];

        // 2. transfer the principal to the pool.
        IERC20Upgradeable(pool.baseToken).safeTransferFrom(msg.sender, address(this), principal);

        // 3. add or update a stake
        uint sumIpp = pool.sumIpp[tranche];
        uint scaledPrincipal = 0;

        if (stk.status != StakeStatus.Open) { // new stk
            stk.id = stk.status == StakeStatus.Closed ? stk.id : STAKE_COUNTER++;
            stk.status = StakeStatus.Open;
            stk.owner = msg.sender;
            stk.pool = token;
            stk.tranche = tranche;
            stk.sumIppStart = 0;
            stk.earnedInterest = 0;
            stk.lossMultiplierBase = 0;
            stk.lossZeroCounterBase = 0;
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
        require(stk.status == StakeStatus.Open, 'unstk invalid status');
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
        IERC20Upgradeable(pool.baseToken).safeTransfer(msg.sender, actualWithdrawAmt);

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
	      Pool storage pool = poolMap[stk.pool];
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

        uint totalLoan = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);
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

            uint totalWeightedLoan;
            for (uint idx = 0; idx < pool.loans.length; idx++) {
                totalWeightedLoan = totalWeightedLoan.add(pool.loans[idx].mul(2**idx));
            }

            // update tranche sumIpp.
            for (uint idx = 0; idx < pool.loans.length; idx++) {
                if (pool.principals[idx] > 0) {
                    uint interest = (totalLoan.mul(pool.loans[idx]).mul(2**idx).mul(rtb)).div(NUM_BLOCK_PER_YEAR.mul(10000).mul(totalWeightedLoan));
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
        Pool storage pool = poolMap[token];
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

        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint totalLoan = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);

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

        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint totalLoan = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);

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
        Position storage pos = positionMap[CURR_POSITION_ID];
        require(pos.baseToken == address(0), 'brw no rebrw');

        // check borrowAmt
        uint maxBorrowAmt = getMaxBorrowAmount(baseToken, baseAmt);
        require(borrowAmt <= maxBorrowAmt, "brw too bad");
        require(borrowAmt >= baseAmt, "brw brw < coll");

        // check available principal per tranche.
        uint[3] memory availPrincipals;
        for (uint i = 0; i < 3; i++) {
            availPrincipals[i] = pool.principals[i].sub(pool.loans[i]);
        }
        uint totalAvailPrincipal = Math.sumOf3UintArray(availPrincipals);
        require(borrowAmt <= totalAvailPrincipal, 'brw asset low');

        // calculate loan amount from each tranche.
        uint[3] memory loans;
        loans[0] = borrowAmt.mul(availPrincipals[0]).div(totalAvailPrincipal);
        loans[1] = borrowAmt.mul(availPrincipals[1]).div(totalAvailPrincipal);
        loans[2] = borrowAmt.sub(loans[0].add(loans[1])); // handling rounding numbers

        if (loans[2] > availPrincipals[2]) {
            loans[2] = availPrincipals[2];
            loans[1] = loans[1].add(loans[2]).sub(availPrincipals[2]);
        }
        if (loans[1] > availPrincipals[1]) {
            loans[1] = availPrincipals[1];
            loans[0] = loans[0].add(loans[1]).sub(availPrincipals[1]);
        }

        // transfer base tokens from borrower to contract as the collateral.
        IERC20Upgradeable(pool.baseToken).safeApprove(address(this), 0);
        IERC20Upgradeable(pool.baseToken).safeApprove(address(this), baseAmt);
        IERC20Upgradeable(pool.baseToken).safeTransferFrom(pos.owner, address(this), baseAmt);

        // transfer borrowed assets to the adapter
        IERC20Upgradeable(pool.baseToken).safeTransfer(msg.sender, borrowAmt);

        // move over nut tokens
        uint nutStaked = minNut4Borrowers[baseToken][pos.adapter];
        if (nutStaked > 0) {
           nutStakedMap[pos.id] = nutStaked;
           IERC20Upgradeable(nut).safeApprove(address(this), 0);
           IERC20Upgradeable(nut).safeApprove(address(this), nutStaked);
           IERC20Upgradeable(nut).safeTransferFrom(pos.owner, address(this), nutStaked);
        }

        // update position information
        pos.status = PositionStatus.Open;
        pos.baseToken = pool.baseToken;
        pos.collToken = collToken;
        pos.baseAmt = baseAmt;
        pos.borrowAmt = borrowAmt;
        pos.loans = loans;
        pos.sumRtbStart = pool.sumRtb;

        borrowerPositionMap[pos.owner].push(pos.id);

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

        uint totalLoan = pos.loans[0].add(pos.loans[1]).add(pos.loans[2]); // owe to lenders
        uint interest = getPositionInterest(pool.baseToken, pos.id); // already paid to lenders
        uint totalRepayAmt = repayAmt.add(pos.baseAmt).sub(interest); // total amount used for repayment
        uint change = totalRepayAmt > totalLoan ? totalRepayAmt.sub(totalLoan) : 0; // profit of the borrower


        // transfer total redeemed amount from adapter to the pool
        IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), repayAmt);
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
            IERC20Upgradeable(baseToken).safeTransfer(pos.owner, change);
        }
        // return nut if any
        if (nutStakedMap[pos.id] > 0) {
            IERC20Upgradeable(nut).safeTransfer(pos.owner, nutStakedMap[pos.id]);
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
        IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), liquidateAmt);

        uint totalLoan = pos.loans[0].add(pos.loans[1]).add(pos.loans[2]);
        uint interest = getPositionInterest(pool.baseToken, pos.id);
        uint totalRepayAmt = liquidateAmt.add(pos.baseAmt).sub(interest); // total base tokens from liquidated
        uint bonusAmt = LIQUIDATION_COMMISSION.mul(totalRepayAmt).div(100); // bonus for liquidator.

        uint repayAmt = totalRepayAmt.sub(bonusAmt); // amount to pay lenders and the borrower
        uint change = totalLoan < repayAmt ? repayAmt.sub(totalLoan) : 0;

        uint[3] memory repays = _getRepayAmount(pos.loans, liquidateAmt);

        // transfer bonus to the liquidator.
        IERC20Upgradeable(baseToken).safeTransfer(CURR_SENDER, bonusAmt);

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
            IERC20Upgradeable(baseToken).safeTransfer(pos.owner, change);
        }
        if (totalRepayAmt < totalLoan) {
            pos.repayDeficit = totalLoan.sub(totalRepayAmt);
        }
        if (nutStakedMap[pos.id] > 0) {
            IERC20Upgradeable(nut).safeTransfer(pos.owner, nutStakedMap[pos.id]);
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

        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);

        uint runningLoss = poolLoss;
        for (uint i = 0; i < 3; i++) {
            uint j = 3 - i - 1;
            // The running totals are based on the principal,
            // however, when I calculate the multipliers, I
            // take into account accured interest
            uint tranchePrincipal = pool.principals[j];
            uint trancheValue = pool.principals[j].add(pool.interests[j]);
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
            require(positionMap[posId].adapter == adapterAddr, 'bad adpr');
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

    function openPosition( IAdapter adapter, address baseToken, address collToken, uint baseAmt, uint borrowAmt ) external {
        beforeExecution(0, adapter);
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

    function version() public virtual pure returns (string memory) {
        return "1.0.0";
    }
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
    enum StakeStatus {Uninitialized, Open, Closed}
    enum PositionStatus {Uninitialized, Open, Closed, Liquidated}

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

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
library SafeMathUpgradeable {
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

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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