// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================== OHM_AMO =============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna

// Reviewer(s) / Contributor(s)
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

import "../Math/SafeMath.sol";
import "../FXS/FXS.sol";
import "../Frax/Frax.sol";
import "../ERC20/ERC20.sol";
import "../ERC20/Variants/Comp.sol";
import "../Frax/Pools/FraxPool.sol";
import "./olympus/IOlympusERC20Token.sol";
import "./olympus/IsOlympus.sol";
import "./olympus/IStakingHelper.sol";
import "./olympus/IOlympusStaking.sol";
import "./olympus/IOlympusBondDepository.sol";
import "../Staking/Owned.sol";
import '../Uniswap/TransferHelper.sol';
import '../Uniswap/UniswapV2Router02_Modified.sol';
import '../Uniswap/UniswapV2Pair.sol';
import "../Proxy/Initializable.sol";
import "../Staking/Owned_Proxy.sol";

// The AMO needs to have 
// 1) Mint FRAX -> Bond (coming next week) -> Collect OHM rewards
// 2) Stake OHM and be able to collect rewards and also withdraw the staked OHM
// 3) Collect OHM rewards and send to custodian
// 4) Sell OHM for FRAX

contract OHM_AMO is Initializable, Owned_Proxy {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // FRAX related
    FRAXStablecoin private FRAX;
    FraxPool private pool;
    address public pool_address;
    address public timelock_address;
    address public custodian_address;

    // Collateral related
    address public collateral_address;

    // Uniswap related
    IUniswapV2Router02 private UniRouterV2;
    UniswapV2Pair private UNI_OHM_FRAX_PAIR;
    address payable public UNISWAP_ROUTER_ADDRESS;

    // OHM related
    IOlympusERC20Token private OHM;
    IsOlympus private sOHM;
    IStakingHelper private stakingHelper;
    IOlympusStaking private olympusStaking;
    IOlympusBondDepository private bondDepository;

    // Precision
    uint256 private missing_decimals_collat;
    uint256 private missing_decimals_ohm;
    uint256 private PRICE_PRECISION;

    // Max amount of FRAX this contract mint
    int256 public mint_cap;

    // Minimum collateral ratio needed for new FRAX minting
    uint256 public min_cr;

    // Amount the contract borrowed
    int256 public minted_sum_historical;
    int256 public burned_sum_historical;

    // Collateral balance related
    bool public override_collat_balance;
    uint256 public override_collat_balance_amount;
    
    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner, "You are not the owner or the governance timelock");
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodian_address, "You are not the rewards custodian");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    
    function initialize(
        address _frax_contract_address,
        address _pool_address,
        address _collateral_address,
        address _creator_address,
        address _custodian_address,
        address _timelock_address
    ) public initializer {
        owner = _creator_address;
        FRAX = FRAXStablecoin(_frax_contract_address);
        pool_address = _pool_address;
        pool = FraxPool(_pool_address);
        timelock_address = _timelock_address;
        custodian_address = _custodian_address;
        collateral_address = _collateral_address;

        // Assignments (must be done in initializer, so assignment gets stored in proxy address's storage instead of implementation address's storage)
        // Olympus
        OHM = IOlympusERC20Token(0x383518188C0C6d7730D91b2c03a03C837814a899);
        sOHM = IsOlympus(0x04F2694C8fcee23e8Fd0dfEA1d4f5Bb8c352111F);
        stakingHelper = IStakingHelper(0xC8C436271f9A6F10a5B80c8b8eD7D0E8f37a612d);
        olympusStaking = IOlympusStaking(0xFd31c7d00Ca47653c6Ce64Af53c1571f9C36566a);
        bondDepository = IOlympusBondDepository(0x8510c8c2B6891E04864fa196693D44E6B6ec2514);

        // Uniswap
        UNISWAP_ROUTER_ADDRESS = payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        UniRouterV2 = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        UNI_OHM_FRAX_PAIR = UniswapV2Pair(0x2dcE0dDa1C2f98e0F171DE8333c3c6Fe1BbF4877);

        PRICE_PRECISION = 1e6;
        missing_decimals_collat = 12;
        missing_decimals_ohm = 9;

        mint_cap = int256(2500000e18);
        min_cr = 820000;
        minted_sum_historical = 0;
        burned_sum_historical = 0;

        override_collat_balance = false;
    }

    /* ========== VIEWS ========== */

    function showAllocations() public view returns (uint256[5] memory allocations) {
        // All numbers given are in FRAX unless otherwise stated
        // Call once to save gas
        (uint256 spot_price_ohm_raw, ) = spotPriceOHM();

        allocations[0] = FRAX.balanceOf(address(this)); // Unallocated FRAX
        allocations[1] = OHM.balanceOf(address(this)).mul(spot_price_ohm_raw); // OHM
        allocations[2] = sOHM.balanceOf(address(this)).mul(spot_price_ohm_raw); // sOHM
        allocations[3] = (bondDepository.pendingPayoutFor(address(this))).mul(spot_price_ohm_raw); // Claimable OHM from bonding
    
        uint256 sum_tally = 0;
        for (uint i = 0; i < 4; i++){ 
            if (allocations[i] > 0){
                sum_tally = sum_tally.add(allocations[i]);
            }
        }

        allocations[4] = sum_tally; // Total Staked
    }

    function showSOHMRewards() external view returns (uint256) {
        return sOHM.balanceOf(address(this));
    }

    function spotPriceOHM() public view returns (uint256 frax_per_ohm_raw, uint256 frax_per_ohm) {
        (uint256 reserve0, uint256 reserve1, ) = (UNI_OHM_FRAX_PAIR.getReserves());

        // OHM = token0, FRAX = token1
        frax_per_ohm_raw = reserve1.div(reserve0);
        frax_per_ohm = reserve1.mul(PRICE_PRECISION).div(reserve0.mul(10 ** missing_decimals_ohm));
    }

    // In FRAX, can be negative
    function mintedBalance() public view returns (int256) {
        return minted_sum_historical - burned_sum_historical;
    }

    // In FRAX, can be negative
    function accumulatedProfit() public view returns (int256) {
        return int256(showAllocations()[4]) - mintedBalance();
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Needed for the Frax contract to function 
    function collatDollarBalance() external view returns (uint256) {
        // Needs to mimic the FraxPool value and return in E18
        // Override is here in case of a brick on the Olympus side
        if(override_collat_balance){
            return override_collat_balance_amount;
        }
        else {
            return (showAllocations()[4]);
        }
        
    }

    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main FRAX contract
    function mintFRAXForInvestments(uint256 frax_amount) public onlyByOwnerOrGovernance {
        int256 frax_amt_i256 = int256(frax_amount);

        // Make sure you aren't minting more than the mint cap
        require((mintedBalance() + frax_amt_i256) <= mint_cap, "Mint cap reached");
        minted_sum_historical = minted_sum_historical + frax_amt_i256;

        // Make sure the current CR isn't already too low
        require (FRAX.global_collateral_ratio() > min_cr, "Collateral ratio is already too low");

        // Make sure the FRAX minting wouldn't push the CR down too much
        // This is also a sanity check for the int256 math
        uint256 current_collateral_E18 = (FRAX.globalCollateralValue()).mul(10 ** missing_decimals_collat);
        uint256 cur_frax_supply = FRAX.totalSupply();
        uint256 new_frax_supply = cur_frax_supply.add(frax_amount);
        uint256 new_cr = (current_collateral_E18.mul(PRICE_PRECISION)).div(new_frax_supply);
        require (new_cr > min_cr, "Minting would cause collateral ratio to be too low");

        // Mint the frax 
        FRAX.pool_mint(address(this), frax_amount);
    }

    // Burn unneeded or excess FRAX
    function burnFRAX(int256 frax_amount) public onlyByOwnerOrGovernance {
        require(frax_amount > 0, "frax_amount must be positive");
        FRAX.burn(uint256(frax_amount));
        burned_sum_historical = burned_sum_historical + frax_amount;
    }

    /* ========== Olympus: Bonding ========== */

    function bondFRAX(uint256 frax_amount) public onlyByOwnerOrGovernance {
        FRAX.approve(address(bondDepository), frax_amount);
        bondDepository.deposit(frax_amount, bondDepository.bondPrice(), address(this));
    }

    function redeemBondedFRAX(bool stake) public onlyByOwnerOrGovernance {
        bondDepository.redeem(address(this), stake);
    }

    function bondInfo() public view returns (uint256 pendingPayout, uint256 percentVested) {
        pendingPayout = bondDepository.pendingPayoutFor(address(this));
        percentVested = bondDepository.percentVestedFor(address(this));
    }

    /* ========== Olympus: Staking ========== */

    // OHM -> sOHM. E9
    // Calls stake and claim together
    function stakeOHM_WithHelper(uint256 ohm_amount) public onlyByOwnerOrGovernance {
        OHM.approve(address(stakingHelper), ohm_amount);
        stakingHelper.stake(ohm_amount);
    }

    // OHM -> sOHM. E9
    // Stake only, no claim
    function stakeOHM_NoHelper(uint256 ohm_amount) public onlyByOwnerOrGovernance {
        OHM.approve(address(olympusStaking), ohm_amount);
        olympusStaking.stake(ohm_amount, address(this));
    }

    // Claim the OHM
    function claimOHM() public onlyByOwnerOrGovernance {
        olympusStaking.claim(address(this));
    }

    // sOHM -> OHM. E9
    // The contract is set up with a warmup period, where user has to stake for some number of epochs before they can 
    // get the sOHM. If they unstake before then they only get the deposit.
    // They earn during warmup period though just can't get rewards before it.
    function unstakeOHM(uint256 sohm_amount, bool rebase) public onlyByOwnerOrGovernance {
        sOHM.approve(address(olympusStaking), sohm_amount);
        olympusStaking.unstake(sohm_amount, rebase);
    }

    // Forfeit takes back the OHM before the warmup is over
    function forfeitOHM() public onlyByOwnerOrGovernance {
        olympusStaking.forfeit();
    }

    // toggleDepositLock() prevents new stakes from being added to the address
    // Anyone can stake for you and it delays the warmup so if someone were to do so maliciously 
    // you'd just toggle that until warmup is done.
    function toggleDepositLock() public onlyByOwnerOrGovernance {
        olympusStaking.toggleDepositLock();
    }

    /* ========== Swaps ========== */

    // FRAX -> OHM. E18 and E9
    function swapFRAXforOHM(uint256 frax_amount, uint256 min_ohm_out) external onlyByOwnerOrGovernance returns (uint256 ohm_spent, uint256 frax_received) {
        // Approve the FRAX for the router
        FRAX.approve(UNISWAP_ROUTER_ADDRESS, frax_amount);

        address[] memory FRAX_OHM_PATH = new address[](2);
        FRAX_OHM_PATH[0] = address(FRAX);
        FRAX_OHM_PATH[1] = address(OHM);

        // Buy some FRAX with OHM
        (uint[] memory amounts) = UniRouterV2.swapExactTokensForTokens(
            frax_amount,
            min_ohm_out,
            FRAX_OHM_PATH,
            address(this),
            2105300114 // Expiration: a long time from now
        );
        return (amounts[0], amounts[1]);
    }

    // OHM -> FRAX. E9 and E18
    function swapOHMforFRAX(uint256 ohm_amount, uint256 min_frax_out) external onlyByOwnerOrGovernance returns (uint256 ohm_spent, uint256 frax_received) {
        // Approve the OHM for the router
        OHM.approve(UNISWAP_ROUTER_ADDRESS, ohm_amount);

        address[] memory OHM_FRAX_PATH = new address[](2);
        OHM_FRAX_PATH[0] = address(OHM);
        OHM_FRAX_PATH[1] = address(FRAX);

        // Buy some FRAX with OHM
        (uint[] memory amounts) = UniRouterV2.swapExactTokensForTokens(
            ohm_amount,
            min_frax_out,
            OHM_FRAX_PATH,
            address(this),
            2105300114 // Expiration: a long time from now
        );
        return (amounts[0], amounts[1]);
    }

    /* ========== Custodian ========== */

    function withdrawRewards() public onlyCustodian {
        OHM.transfer(custodian_address, OHM.balanceOf(address(this)));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        timelock_address = new_timelock;
    }

    function setCustodian(address _custodian_address) external onlyByOwnerOrGovernance {
        require(_custodian_address != address(0), "Custodian address cannot be 0");        
        custodian_address = _custodian_address;
    }

    function setPool(address _pool_address) external onlyByOwnerOrGovernance {
        pool_address = _pool_address;
        pool = FraxPool(_pool_address);
    }

    function setOverrideCollatBalance(bool _state, uint256 _balance) external onlyByOwnerOrGovernance {
        override_collat_balance = _state;
        override_collat_balance_amount = _balance;
    }

    function setMintCap(int256 _mint_cap) external onlyByOwnerOrGovernance {
        mint_cap = _mint_cap;
    }

    function setMinimumCollateralRatio(uint256 _min_cr) external onlyByOwnerOrGovernance {
        min_cr = _min_cr;
    }

    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerOrGovernance {
        // Can only be triggered by owner or governance, not custodian
        // Tokens are sent to the custodian, as a sort of safeguard

        ERC20(tokenAddress).transfer(custodian_address, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /* ========== EVENTS ========== */

    event Recovered(address token, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FRAXShares (FXS) =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../Common/Context.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/IERC20.sol";
import "../Frax/Frax.sol";
import "../Staking/Owned.sol";
import "../Math/SafeMath.sol";
import "../Governance/AccessControl.sol";

contract FRAXShares is ERC20Custom, AccessControl, Owned {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public FRAXStablecoinAdd;
    
    uint256 public constant genesis_supply = 100000000e18; // 100M is printed upon genesis

    address public oracle_address;
    address public timelock_address; // Governance timelock address
    FRAXStablecoin private FRAX;

    bool public trackingVotes = true; // Tracking votes (only change if need to disable votes)

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(FRAX.frax_pools(msg.sender) == true, "Only frax pools can mint new FRAX");
        _;
    } 
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol, 
        address _oracle_address,
        address _creator_address,
        address _timelock_address
    ) public Owned(_creator_address){
        require((_oracle_address != address(0)) && (_timelock_address != address(0)), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        oracle_address = _oracle_address;
        timelock_address = _timelock_address;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_creator_address, genesis_supply);

        // Do a checkpoint for the owner
        _writeCheckpoint(_creator_address, 0, 0, uint96(genesis_supply));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOracle(address new_oracle) external onlyByOwnerOrGovernance {
        require(new_oracle != address(0), "Zero address detected");

        oracle_address = new_oracle;
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        timelock_address = new_timelock;
    }
    
    function setFRAXAddress(address frax_contract_address) external onlyByOwnerOrGovernance {
        require(frax_contract_address != address(0), "Zero address detected");

        FRAX = FRAXStablecoin(frax_contract_address);

        emit FRAXAddressSet(frax_contract_address);
    }
    
    function mint(address to, uint256 amount) public onlyPools {
        _mint(to, amount);
    }
    
    // This function is what other frax pools will call to mint new FXS (similar to the FRAX mint) 
    function pool_mint(address m_address, uint256 m_amount) external onlyPools {        
        if(trackingVotes){
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = add96(srcRepOld, uint96(m_amount), "pool_mint new votes overflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // mint new votes
            trackVotes(address(this), m_address, uint96(m_amount));
        }

        super._mint(m_address, m_amount);
        emit FXSMinted(address(this), m_address, m_amount);
    }

    // This function is what other frax pools will call to burn FXS 
    function pool_burn_from(address b_address, uint256 b_amount) external onlyPools {
        if(trackingVotes){
            trackVotes(b_address, address(this), uint96(b_amount));
            uint32 srcRepNum = numCheckpoints[address(this)];
            uint96 srcRepOld = srcRepNum > 0 ? checkpoints[address(this)][srcRepNum - 1].votes : 0;
            uint96 srcRepNew = sub96(srcRepOld, uint96(b_amount), "pool_burn_from new votes underflows");
            _writeCheckpoint(address(this), srcRepNum, srcRepOld, srcRepNew); // burn votes
        }

        super._burnFrom(b_address, b_amount);
        emit FXSBurned(b_address, address(this), b_amount);
    }

    function toggleVotes() external onlyByOwnerOrGovernance {
        trackingVotes = !trackingVotes;
    }

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(_msgSender(), recipient, uint96(amount));
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        if(trackingVotes){
            // Transfer votes
            trackVotes(sender, recipient, uint96(amount));
        }

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

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
        require(blockNumber < block.number, "FXS::getPriorVotes: not yet determined");

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

    /* ========== INTERNAL FUNCTIONS ========== */

    // From compound's _moveDelegates
    // Keep track of votes. "Delegates" is a misnomer here
    function trackVotes(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "FXS::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "FXS::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address voter, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "FXS::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[voter][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[voter][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[voter][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[voter] = nCheckpoints + 1;
      }

      emit VoterVotesChanged(voter, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
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

    /* ========== EVENTS ========== */
    
    /// @notice An event thats emitted when a voters account's vote balance changes
    event VoterVotesChanged(address indexed voter, uint previousBalance, uint newBalance);

    // Track FXS burned
    event FXSBurned(address indexed from, address indexed to, uint256 amount);

    // Track FXS minted
    event FXSMinted(address indexed from, address indexed to, uint256 amount);

    event FRAXAddressSet(address addr);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= FRAXStablecoin (FRAX) ======================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../Common/Context.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/ERC20.sol";
import "../Math/SafeMath.sol";
import "../Staking/Owned.sol";
import "../FXS/FXS.sol";
import "./Pools/FraxPool.sol";
import "../Oracle/UniswapPairOracle.sol";
import "../Oracle/ChainlinkETHUSDPriceConsumer.sol";
import "../Governance/AccessControl.sol";

contract FRAXStablecoin is ERC20Custom, AccessControl, Owned {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { FRAX, FXS }
    ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    UniswapPairOracle private fraxEthOracle;
    UniswapPairOracle private fxsEthOracle;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public creator_address;
    address public timelock_address; // Governance timelock address
    address public controller_address; // Controller contract to dynamically adjust system parameters automatically
    address public fxs_address;
    address public frax_eth_oracle_address;
    address public fxs_eth_oracle_address;
    address public weth_address;
    address public eth_usd_consumer_address;
    uint256 public constant genesis_supply = 2000000e18; // 2M FRAX (only for testing, genesis supply will be 5k on Mainnet). This is to help with establishing the Uniswap pools, as they need liquidity

    // The addresses in this array are added by the oracle and these contracts are able to mint frax
    address[] public frax_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public frax_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public redemption_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public minting_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public frax_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of FRAX at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    address public DEFAULT_ADMIN_ADDRESS;
    bytes32 public constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
    bool public collateral_ratio_paused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyCollateralRatioPauser() {
        require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender));
        _;
    }

    modifier onlyPools() {
       require(frax_pools[msg.sender] == true, "Only frax pools can call this function");
        _;
    } 
    
    modifier onlyByOwnerGovernanceOrController() {
        require(msg.sender == owner || msg.sender == timelock_address || msg.sender == controller_address, "You are not the owner, controller, or the governance timelock");
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == owner 
            || msg.sender == timelock_address 
            || frax_pools[msg.sender] == true, 
            "You are not the owner, the governance timelock, or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        address _creator_address,
        address _timelock_address
    ) public Owned(_creator_address){
        require(_timelock_address != address(0), "Zero address detected"); 
        name = _name;
        symbol = _symbol;
        creator_address = _creator_address;
        timelock_address = _timelock_address;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DEFAULT_ADMIN_ADDRESS = _msgSender();
        _mint(creator_address, genesis_supply);
        grantRole(COLLATERAL_RATIO_PAUSER, creator_address);
        grantRole(COLLATERAL_RATIO_PAUSER, timelock_address);
        frax_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // Frax system starts off fully collateralized (6 decimals of precision)
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
    }

    /* ========== VIEWS ========== */

    // Choice = 'FRAX' or 'FXS' for now
    function oracle_price(PriceChoice choice) internal view returns (uint256) {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 __eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth = 0;

        if (choice == PriceChoice.FRAX) {
            price_vs_eth = uint256(fraxEthOracle.consult(weth_address, PRICE_PRECISION)); // How much FRAX if you put in PRICE_PRECISION WETH
        }
        else if (choice == PriceChoice.FXS) {
            price_vs_eth = uint256(fxsEthOracle.consult(weth_address, PRICE_PRECISION)); // How much FXS if you put in PRICE_PRECISION WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (FRAX) or 1 (FXS)");

        // Will be in 1e6 format
        return __eth_usd_price.mul(PRICE_PRECISION).div(price_vs_eth);
    }

    // Returns X FRAX = 1 USD
    function frax_price() public view returns (uint256) {
        return oracle_price(PriceChoice.FRAX);
    }

    // Returns X FXS = 1 USD
    function fxs_price()  public view returns (uint256) {
        return oracle_price(PriceChoice.FXS);
    }

    function eth_usd_price() public view returns (uint256) {
        return uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function frax_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            oracle_price(PriceChoice.FRAX), // frax_price()
            oracle_price(PriceChoice.FXS), // fxs_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            minting_fee, // minting_fee()
            redemption_fee, // redemption_fee()
            uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // Iterate through all frax pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < frax_pools_array.length; i++){ 
            // Exclude null addresses
            if (frax_pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(FraxPool(frax_pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        uint256 frax_price_cur = frax_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setFraxStep()) 
        
        if (frax_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= frax_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(frax_step);
            }
        } else if (frax_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(frax_step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(frax_step);
            }
        }

        last_call_time = block.timestamp; // Set the time of the last expansion

        emit CollateralRatioRefreshed(global_collateral_ratio);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit FRAXBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other frax pools will call to mint new FRAX 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit FRAXMinted(msg.sender, m_address, m_amount);
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerGovernanceOrController {
        require(pool_address != address(0), "Zero address detected");

        require(frax_pools[pool_address] == false, "address already exists");
        frax_pools[pool_address] = true; 
        frax_pools_array.push(pool_address);

        emit PoolAdded(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerGovernanceOrController {
        require(pool_address != address(0), "Zero address detected");

        require(frax_pools[pool_address] == true, "address doesn't exist already");
        
        // Delete from the mapping
        delete frax_pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < frax_pools_array.length; i++){ 
            if (frax_pools_array[i] == pool_address) {
                frax_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit PoolRemoved(pool_address);
    }

    function setRedemptionFee(uint256 red_fee) public onlyByOwnerGovernanceOrController {
        redemption_fee = red_fee;

        emit RedemptionFeeSet(red_fee);
    }

    function setMintingFee(uint256 min_fee) public onlyByOwnerGovernanceOrController {
        minting_fee = min_fee;

        emit MintingFeeSet(min_fee);
    }  

    function setFraxStep(uint256 _new_step) public onlyByOwnerGovernanceOrController {
        frax_step = _new_step;

        emit FraxStepSet(_new_step);
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerGovernanceOrController {
        price_target = _new_price_target;

        emit PriceTargetSet(_new_price_target);
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerGovernanceOrController {
    	refresh_cooldown = _new_cooldown;

        emit RefreshCooldownSet(_new_cooldown);
    }

    function setFXSAddress(address _fxs_address) public onlyByOwnerGovernanceOrController {
        require(_fxs_address != address(0), "Zero address detected");

        fxs_address = _fxs_address;

        emit FXSAddressSet(_fxs_address);
    }

    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyByOwnerGovernanceOrController {
        require(_eth_usd_consumer_address != address(0), "Zero address detected");

        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_usd_pricer = ChainlinkETHUSDPriceConsumer(eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();

        emit ETHUSDOracleSet(_eth_usd_consumer_address);
    }

    function setTimelock(address new_timelock) external onlyByOwnerGovernanceOrController {
        require(new_timelock != address(0), "Zero address detected");

        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

    function setController(address _controller_address) external onlyByOwnerGovernanceOrController {
        require(_controller_address != address(0), "Zero address detected");

        controller_address = _controller_address;

        emit ControllerSet(_controller_address);
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerGovernanceOrController {
        price_band = _price_band;

        emit PriceBandSet(_price_band);
    }

    // Sets the FRAX_ETH Uniswap oracle address 
    function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address) public onlyByOwnerGovernanceOrController {
        require((_frax_oracle_addr != address(0)) && (_weth_address != address(0)), "Zero address detected");
        frax_eth_oracle_address = _frax_oracle_addr;
        fraxEthOracle = UniswapPairOracle(_frax_oracle_addr); 
        weth_address = _weth_address;

        emit FRAXETHOracleSet(_frax_oracle_addr, _weth_address);
    }

    // Sets the FXS_ETH Uniswap oracle address 
    function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address) public onlyByOwnerGovernanceOrController {
        require((_fxs_oracle_addr != address(0)) && (_weth_address != address(0)), "Zero address detected");

        fxs_eth_oracle_address = _fxs_oracle_addr;
        fxsEthOracle = UniswapPairOracle(_fxs_oracle_addr);
        weth_address = _weth_address;

        emit FXSEthOracleSet(_fxs_oracle_addr, _weth_address);
    }

    function toggleCollateralRatio() public onlyCollateralRatioPauser {
        collateral_ratio_paused = !collateral_ratio_paused;

        emit CollateralRatioToggled(collateral_ratio_paused);
    }

    /* ========== EVENTS ========== */

    // Track FRAX burned
    event FRAXBurned(address indexed from, address indexed to, uint256 amount);

    // Track FRAX minted
    event FRAXMinted(address indexed from, address indexed to, uint256 amount);

    event CollateralRatioRefreshed(uint256 global_collateral_ratio);
    event PoolAdded(address pool_address);
    event PoolRemoved(address pool_address);
    event RedemptionFeeSet(uint256 red_fee);
    event MintingFeeSet(uint256 min_fee);
    event FraxStepSet(uint256 new_step);
    event PriceTargetSet(uint256 new_price_target);
    event RefreshCooldownSet(uint256 new_cooldown);
    event FXSAddressSet(address _fxs_address);
    event ETHUSDOracleSet(address eth_usd_consumer_address);
    event TimelockSet(address new_timelock);
    event ControllerSet(address controller_address);
    event PriceBandSet(uint256 price_band);
    event FRAXETHOracleSet(address frax_oracle_addr, address weth_address);
    event FXSEthOracleSet(address fxs_oracle_addr, address weth_address);
    event CollateralRatioToggled(bool collateral_ratio_paused);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "./IERC20.sol";
import "../Math/SafeMath.sol";
import "../Utils/Address.sol";


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
    constructor (string memory __name, string memory __symbol) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * Requirements
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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
/**
 *Submitted for verification at Etherscan.io on 2020-03-04
*/
pragma solidity >=0.6.11;

contract Comp {
    // EIP-20 token name for this token
    string public constant name = "Compound";

    // EIP-20 token symbol for this token
    string public constant symbol = "COMP";

    // EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    // Total number of tokens in circulation
    uint public constant totalSupply = 10000000e18; // 10 million Comp

    // Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping (address => uint96) internal balances;

    // A record of each accounts delegate
    mapping (address => address) public delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    // A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    // The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new Comp token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) public {
        balances[account] = uint96(totalSupply);
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
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == type(uint).max) {
            amount = type(uint96).max;
        } else {
            amount = safe96(rawAmount, "Comp::approve: amount exceeds 96 bits");
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
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Comp::transfer: amount exceeds 96 bits");
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
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Comp::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != type(uint96).max) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Comp::transferFrom: transfer amount exceeds spender allowance");
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
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Comp::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Comp::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "Comp::delegateBySig: signature expired");
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
        require(blockNumber < block.number, "Comp::getPriorVotes: not yet determined");

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
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Comp::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Comp::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Comp::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Comp::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "Comp::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "Comp::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "Comp::_writeCheckpoint: block number exceeds 32 bits");

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

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================= FraxPool =============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan
// Sam Kazemian: https://github.com/samkazemian

// Reviewer(s) / Contributor(s)
// Sam Sun: https://github.com/samczsun

import "../../Math/SafeMath.sol";
import '../../Uniswap/TransferHelper.sol';
import "../../Staking/Owned.sol";
import "../../FXS/FXS.sol";
import "../../Frax/Frax.sol";
import "../../ERC20/ERC20.sol";
import "../../Oracle/UniswapPairOracle.sol";
import "../../Governance/AccessControl.sol";
import "./FraxPoolLibrary.sol";

contract FraxPool is AccessControl, Owned {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    address private collateral_address;

    address private frax_contract_address;
    address private fxs_contract_address;
    address private timelock_address;
    FRAXShares private FXS;
    FRAXStablecoin private FRAX;

    UniswapPairOracle private collatEthOracle;
    address public collat_eth_oracle_address;
    address private weth_address;

    uint256 public minting_fee;
    uint256 public redemption_fee;
    uint256 public buyback_fee;
    uint256 public recollat_fee;

    mapping (address => uint256) public redeemFXSBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolFXS;
    mapping (address => uint256) public lastRedeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // Number of decimals needed to get to 18
    uint256 private immutable missing_decimals;
    
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pool_ceiling = 0;

    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;

    // Bonus rate on FXS minted during recollateralizeFRAX(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    // AccessControl Roles
    bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
    bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 private constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    
    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner, "You are not the owner or the governance timelock");
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address _frax_contract_address,
        address _fxs_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) public Owned(_creator_address){
        require(
            (_frax_contract_address != address(0))
            && (_fxs_contract_address != address(0))
            && (_collateral_address != address(0))
            && (_creator_address != address(0))
            && (_timelock_address != address(0))
        , "Zero address detected"); 
        FRAX = FRAXStablecoin(_frax_contract_address);
        FXS = FRAXShares(_fxs_contract_address);
        frax_contract_address = _frax_contract_address;
        fxs_contract_address = _fxs_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        collateral_token = ERC20(_collateral_address);
        pool_ceiling = _pool_ceiling;
        missing_decimals = uint(18).sub(collateral_token.decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MINT_PAUSER, timelock_address);
        grantRole(REDEEM_PAUSER, timelock_address);
        grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
        grantRole(BUYBACK_PAUSER, timelock_address);
        grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this Frax pool
    function collatDollarBalance() public view returns (uint256) {
        if(collateralPricePaused == true){
            return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(pausedPrice).div(PRICE_PRECISION);
        } else {
            uint256 eth_usd_price = FRAX.eth_usd_price();
            uint256 eth_collat_price = collatEthOracle.consult(weth_address, (PRICE_PRECISION * (10 ** missing_decimals)));

            uint256 collat_usd_price = eth_usd_price.mul(PRICE_PRECISION).div(eth_collat_price);
            return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
        }
    }

    // Returns the value of excess collateral held in this Frax pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 total_supply = FRAX.totalSupply();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 global_collat_value = FRAX.globalCollateralValue();

        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 FRAX with $1 of collateral at current collat ratio
        if (global_collat_value > required_collat_dollar_value_d18) return global_collat_value.sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else {
            uint256 eth_usd_price = FRAX.eth_usd_price();
            return eth_usd_price.mul(PRICE_PRECISION).div(collatEthOracle.consult(weth_address, PRICE_PRECISION * (10 ** missing_decimals)));
        }
    }

    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external onlyByOwnerOrGovernance {
        collat_eth_oracle_address = _collateral_weth_oracle_address;
        collatEthOracle = UniswapPairOracle(_collateral_weth_oracle_address);
        weth_address = _weth_address;
    }

    // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1FRAX(uint256 collateral_amount, uint256 FRAX_out_min) external notMintPaused {
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);

        require(FRAX.global_collateral_ratio() >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require((collateral_token.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        
        (uint256 frax_amount_d18) = FraxPoolLibrary.calcMint1t1FRAX(
            getCollateralPrice(),
            collateral_amount_d18
        ); //1 FRAX for each $1 worth of collateral

        frax_amount_d18 = (frax_amount_d18.mul(uint(1e6).sub(minting_fee))).div(1e6); //remove precision at the end
        require(FRAX_out_min <= frax_amount_d18, "Slippage limit reached");

        TransferHelper.safeTransferFrom(address(collateral_token), msg.sender, address(this), collateral_amount);
        FRAX.pool_mint(msg.sender, frax_amount_d18);
    }

    // 0% collateral-backed
    function mintAlgorithmicFRAX(uint256 fxs_amount_d18, uint256 FRAX_out_min) external notMintPaused {
        uint256 fxs_price = FRAX.fxs_price();
        require(FRAX.global_collateral_ratio() == 0, "Collateral ratio must be 0");
        
        (uint256 frax_amount_d18) = FraxPoolLibrary.calcMintAlgorithmicFRAX(
            fxs_price, // X FXS / 1 USD
            fxs_amount_d18
        );

        frax_amount_d18 = (frax_amount_d18.mul(uint(1e6).sub(minting_fee))).div(1e6);
        require(FRAX_out_min <= frax_amount_d18, "Slippage limit reached");

        FXS.pool_burn_from(msg.sender, fxs_amount_d18);
        FRAX.pool_mint(msg.sender, frax_amount_d18);
    }

    // Will fail if fully collateralized or fully algorithmic
    // > 0% and < 100% collateral-backed
    function mintFractionalFRAX(uint256 collateral_amount, uint256 fxs_amount, uint256 FRAX_out_min) external notMintPaused {
        uint256 fxs_price = FRAX.fxs_price();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more FRAX can be minted with this collateral");

        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        FraxPoolLibrary.MintFF_Params memory input_params = FraxPoolLibrary.MintFF_Params(
            fxs_price,
            getCollateralPrice(),
            fxs_amount,
            collateral_amount_d18,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 fxs_needed) = FraxPoolLibrary.calcMintFractionalFRAX(input_params);

        mint_amount = (mint_amount.mul(uint(1e6).sub(minting_fee))).div(1e6);
        require(FRAX_out_min <= mint_amount, "Slippage limit reached");
        require(fxs_needed <= fxs_amount, "Not enough FXS inputted");

        FXS.pool_burn_from(msg.sender, fxs_needed);
        TransferHelper.safeTransferFrom(address(collateral_token), msg.sender, address(this), collateral_amount);
        FRAX.pool_mint(msg.sender, mint_amount);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1FRAX(uint256 FRAX_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
        require(FRAX.global_collateral_ratio() == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");

        // Need to adjust for decimals of collateral
        uint256 FRAX_amount_precision = FRAX_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = FraxPoolLibrary.calcRedeem1t1FRAX(
            getCollateralPrice(),
            FRAX_amount_precision
        );

        collateral_needed = (collateral_needed.mul(uint(1e6).sub(redemption_fee))).div(1e6);
        require(collateral_needed <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
        lastRedeemed[msg.sender] = block.number;
        
        // Move all external functions to the end
        FRAX.pool_burn_from(msg.sender, FRAX_amount);
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem FRAX for collateral and FXS. > 0% and < 100% collateral-backed
    function redeemFractionalFRAX(uint256 FRAX_amount, uint256 FXS_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 fxs_price = FRAX.fxs_price();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        uint256 col_price_usd = getCollateralPrice();

        uint256 FRAX_amount_post_fee = (FRAX_amount.mul(uint(1e6).sub(redemption_fee))).div(PRICE_PRECISION);

        uint256 fxs_dollar_value_d18 = FRAX_amount_post_fee.sub(FRAX_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION));
        uint256 fxs_amount = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(fxs_price);

        // Need to adjust for decimals of collateral
        uint256 FRAX_amount_precision = FRAX_amount_post_fee.div(10 ** missing_decimals);
        uint256 collateral_dollar_value = FRAX_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
        uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(col_price_usd);


        require(collateral_amount <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
        require(FXS_out_min <= fxs_amount, "Slippage limit reached [FXS]");

        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);

        redeemFXSBalances[msg.sender] = redeemFXSBalances[msg.sender].add(fxs_amount);
        unclaimedPoolFXS = unclaimedPoolFXS.add(fxs_amount);

        lastRedeemed[msg.sender] = block.number;
        
        // Move all external functions to the end
        FRAX.pool_burn_from(msg.sender, FRAX_amount);
        FXS.pool_mint(address(this), fxs_amount);
    }

    // Redeem FRAX for FXS. 0% collateral-backed
    function redeemAlgorithmicFRAX(uint256 FRAX_amount, uint256 FXS_out_min) external notRedeemPaused {
        uint256 fxs_price = FRAX.fxs_price();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

        require(global_collateral_ratio == 0, "Collateral ratio must be 0"); 
        uint256 fxs_dollar_value_d18 = FRAX_amount;

        fxs_dollar_value_d18 = (fxs_dollar_value_d18.mul(uint(1e6).sub(redemption_fee))).div(PRICE_PRECISION); //apply fees

        uint256 fxs_amount = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(fxs_price);
        
        redeemFXSBalances[msg.sender] = redeemFXSBalances[msg.sender].add(fxs_amount);
        unclaimedPoolFXS = unclaimedPoolFXS.add(fxs_amount);
        
        lastRedeemed[msg.sender] = block.number;
        
        require(FXS_out_min <= fxs_amount, "Slippage limit reached");
        // Move all external functions to the end
        FRAX.pool_burn_from(msg.sender, FRAX_amount);
        FXS.pool_mint(address(this), fxs_amount);
    }

    // After a redemption happens, transfer the newly minted FXS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out FRAX/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendFXS = false;
        bool sendCollateral = false;
        uint FXSAmount = 0;
        uint CollateralAmount = 0;

        // Use Checks-Effects-Interactions pattern
        if(redeemFXSBalances[msg.sender] > 0){
            FXSAmount = redeemFXSBalances[msg.sender];
            redeemFXSBalances[msg.sender] = 0;
            unclaimedPoolFXS = unclaimedPoolFXS.sub(FXSAmount);

            sendFXS = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

            sendCollateral = true;
        }

        if(sendFXS){
            TransferHelper.safeTransfer(address(FXS), msg.sender, FXSAmount);
        }
        if(sendCollateral){
            TransferHelper.safeTransfer(address(collateral_token), msg.sender, CollateralAmount);
        }
    }


    // When the protocol is recollateralizing, we need to give a discount of FXS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get FXS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of FXS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra FXS value from the bonus rate as an arb opportunity
    function recollateralizeFRAX(uint256 collateral_amount, uint256 FXS_out_min) external {
        require(recollateralizePaused == false, "Recollateralize is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 fxs_price = FRAX.fxs_price();
        uint256 frax_total_supply = FRAX.totalSupply();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 global_collat_value = FRAX.globalCollateralValue();

        (uint256 collateral_units, uint256 amount_to_recollat) = FraxPoolLibrary.calcRecollateralizeFRAXInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            frax_total_supply,
            global_collateral_ratio
        ); 

        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);

        uint256 fxs_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate).sub(recollat_fee)).div(fxs_price);

        require(FXS_out_min <= fxs_paid_back, "Slippage limit reached");
        TransferHelper.safeTransferFrom(address(collateral_token), msg.sender, address(this), collateral_units_precision);
        FXS.pool_mint(msg.sender, fxs_paid_back);
        
    }

    // Function can be called by an FXS holder to have the protocol buy back FXS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackFXS(uint256 FXS_amount, uint256 COLLATERAL_out_min) external {
        require(buyBackPaused == false, "Buyback is paused");
        uint256 fxs_price = FRAX.fxs_price();
    
        FraxPoolLibrary.BuybackFXS_Params memory input_params = FraxPoolLibrary.BuybackFXS_Params(
            availableExcessCollatDV(),
            fxs_price,
            getCollateralPrice(),
            FXS_amount
        );

        (uint256 collateral_equivalent_d18) = (FraxPoolLibrary.calcBuyBackFXS(input_params)).mul(uint(1e6).sub(buyback_fee)).div(1e6);
        uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);

        require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
        // Give the sender their desired collateral and burn the FXS
        FXS.pool_burn_from(msg.sender, FXS_amount);
        TransferHelper.safeTransfer(address(collateral_token), msg.sender, collateral_precision);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external {
        require(hasRole(MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;

        emit MintingToggled(mintPaused);
    }

    function toggleRedeeming() external {
        require(hasRole(REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;

        emit RedeemingToggled(redeemPaused);
    }

    function toggleRecollateralize() external {
        require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;

        emit RecollateralizeToggled(recollateralizePaused);
    }
    
    function toggleBuyBack() external {
        require(hasRole(BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;

        emit BuybackToggled(buyBackPaused);
    }

    function toggleCollateralPrice(uint256 _new_price) external {
        require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = _new_price;
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;

        emit CollateralPriceToggled(collateralPricePaused);
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        minting_fee = new_mint_fee;
        redemption_fee = new_redeem_fee;
        buyback_fee = new_buyback_fee;
        recollat_fee = new_recollat_fee;

        emit PoolParametersSet(new_ceiling, new_bonus_rate, new_redemption_delay, new_mint_fee, new_redeem_fee, new_buyback_fee, new_recollat_fee);
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

    /* ========== EVENTS ========== */

    event PoolParametersSet(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee);
    event TimelockSet(address new_timelock);
    event MintingToggled(bool toggled);
    event RedeemingToggled(bool toggled);
    event RecollateralizeToggled(bool toggled);
    event BuybackToggled(bool toggled);
    event CollateralPriceToggled(bool toggled);

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// OHM
interface IOlympusERC20Token {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external view returns (bytes32);
  function _burnFrom(address account_, uint256 amount_) external;
  function addTWAPSource(address newTWAPSourceDexPool_) external;
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function burn(uint256 amount) external;
  function burnFrom(address account_, uint256 amount_) external;
  function changeTWAPEpochPeriod(uint256 newTWAPEpochPeriod_) external;
  function changeTWAPOracle(address newTWAPOracle_) external;
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function mint(address account_, uint256 amount_) external;
  function name() external view returns (string memory);
  function nonces(address owner) external view returns (uint256);
  function owner() external view returns (address);
  function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
  function removeTWAPSource(address twapSourceToRemove_) external;
  function renounceOwnership() external;
  function setVault(address vault_) external returns (bool);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transferOwnership(address newOwner_) external;
  function twapEpochPeriod() external view returns (uint256);
  function twapOracle() external view returns (address);
  function vault() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// sOHM
interface IsOlympus {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function INDEX() external view returns (uint256);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function allowance(address owner_, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function balanceForGons(uint256 gons) external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function gonsForBalance(uint256 amount) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function index() external view returns (uint256);
    function initialize(address stakingContract_) external returns (bool);
    function initializer() external view returns (address);
    function manager() external view returns (address);
    function name() external view returns (string memory);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function pullManagement() external;
    function pushManagement(address newOwner_) external;
    function rebase(uint256 profit_, uint256 epoch_) external returns (uint256);
    function rebases(uint256) external view returns (uint256 epoch, uint256 rebase, uint256 totalStakedBefore, uint256 totalStakedAfter, uint256 amountRebased, uint256 index, uint256 blockNumberOccured);
    function renounceManagement() external;
    function setIndex(uint256 _INDEX) external returns (bool);
    function stakingContract() external view returns (address);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// sOHM
// OLD VERSION
// interface IsOlympus {
//   function DOMAIN_SEPARATOR() external view returns (bytes32);
//   function PERMIT_TYPEHASH() external view returns (bytes32);
//   function allowance(address owner_, address spender) external view returns (uint256);
//   function approve(address spender, uint256 value) external returns (bool);
//   function balanceOf(address who) external view returns (uint256);
//   function circulatingSupply() external view returns (uint256);
//   function decimals() external view returns (uint8);
//   function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
//   function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
//   function monetaryPolicy() external view returns (address);
//   function name() external view returns (string memory);
//   function nonces(address owner) external view returns (uint256);
//   function owner() external view returns (address);
//   function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
//   function rebase(uint256 olyProfit) external returns (uint256);
//   function renounceOwnership() external;
//   function setMonetaryPolicy(address monetaryPolicy_) external;
//   function setStakingContract(address newStakingContract_) external;
//   function stakingContract() external view returns (address);
//   function symbol() external view returns (string memory);
//   function totalSupply() external view returns (uint256);
//   function transfer(address to, uint256 value) external returns (bool);
//   function transferFrom(address from, address to, uint256 value) external returns (bool);
//   function transferOwnership(address newOwner_) external;
// }

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IStakingHelper {
  function OHM() external view returns (address);
  function stake(uint256 _amount) external;
  function staking() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://etherscan.io/address/0xfd31c7d00ca47653c6ce64af53c1571f9c36566a#code

// OlympusStaking
interface IOlympusStaking {
  function OHM() external view returns (address);
  function claim(address _recipient) external;
  function contractBalance() external view returns (uint256);
  function distributor() external view returns (address);
  function epoch() external view returns (uint256 length, uint256 number, uint256 endBlock, uint256 distribute);
  function forfeit() external;
  function giveLockBonus(uint256 _amount) external;
  function index() external view returns (uint256);
  function locker() external view returns (address);
  function manager() external view returns (address);
  function pullManagement() external;
  function pushManagement(address newOwner_) external;
  function rebase() external;
  function renounceManagement() external;
  function returnLockBonus(uint256 _amount) external;
  function sOHM() external view returns (address);
  function setContract(uint8 _contract, address _address) external;
  function setWarmup(uint256 _warmupPeriod) external;
  function stake(uint256 _amount, address _recipient) external returns (bool);
  function toggleDepositLock() external;
  function totalBonus() external view returns (uint256);
  function unstake(uint256 _amount, bool _trigger) external;
  function warmupContract() external view returns (address);
  function warmupInfo(address) external view returns (uint256 deposit, uint256 gons, uint256 expiry, bool lock);
  function warmupPeriod() external view returns (uint256);
}



// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      *
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");

//         return c;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         return sub(a, b, "SafeMath: subtraction overflow");
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         uint256 c = a - b;

//         return c;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      *
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) {
//             return 0;
//         }

//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");

//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers. Reverts on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         return div(a, b, "SafeMath: division by zero");
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         uint256 c = a / b;
//         assert(a == b * c + a % b); // There is no case in which this doesn't hold

//         return c;
//     }
// }

// interface IERC20 {
//     function decimals() external view returns (uint8);
//   /**
//    * @dev Returns the amount of tokens in existence.
//    */
//   function totalSupply() external view returns (uint256);

//   /**
//    * @dev Returns the amount of tokens owned by `account`.
//    */
//   function balanceOf(address account) external view returns (uint256);

//   /**
//    * @dev Moves `amount` tokens from the caller's account to `recipient`.
//    *
//    * Returns a boolean value indicating whether the operation succeeded.
//    *
//    * Emits a {Transfer} event.
//    */
//   function transfer(address recipient, uint256 amount) external returns (bool);

//   /**
//    * @dev Returns the remaining number of tokens that `spender` will be
//    * allowed to spend on behalf of `owner` through {transferFrom}. This is
//    * zero by default.
//    *
//    * This value changes when {approve} or {transferFrom} are called.
//    */
//   function allowance(address owner, address spender) external view returns (uint256);

//   /**
//    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//    *
//    * Returns a boolean value indicating whether the operation succeeded.
//    *
//    * IMPORTANT: Beware that changing an allowance with this method brings the risk
//    * that someone may use both the old and the new allowance by unfortunate
//    * transaction ordering. One possible solution to mitigate this race
//    * condition is to first reduce the spender's allowance to 0 and set the
//    * desired value afterwards:
//    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//    *
//    * Emits an {Approval} event.
//    */
//   function approve(address spender, uint256 amount) external returns (bool);

//   /**
//    * @dev Moves `amount` tokens from `sender` to `recipient` using the
//    * allowance mechanism. `amount` is then deducted from the caller's
//    * allowance.
//    *
//    * Returns a boolean value indicating whether the operation succeeded.
//    *
//    * Emits a {Transfer} event.
//    */
//   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//   /**
//    * @dev Emitted when `value` tokens are moved from one account (`from`) to
//    * another (`to`).
//    *
//    * Note that `value` may be zero.
//    */
//   event Transfer(address indexed from, address indexed to, uint256 value);

//   /**
//    * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//    * a call to {approve}. `value` is the new allowance.
//    */
//   event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// library Address {
//     /**
//      * @dev Returns true if `account` is a contract.
//      *
//      * [IMPORTANT]
//      * ====
//      * It is unsafe to assume that an address for which this function returns
//      * false is an externally-owned account (EOA) and not a contract.
//      *
//      * Among others, `isContract` will return false for the following
//      * types of addresses:
//      *
//      *  - an externally-owned account
//      *  - a contract in construction
//      *  - an address where a contract will be created
//      *  - an address where a contract lived, but was destroyed
//      * ====
//      */
//     function isContract(address account) internal view returns (bool) {
//         // This method relies in extcodesize, which returns 0 for contracts in
//         // construction, since the code is only stored at the end of the
//         // constructor execution.

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { size := extcodesize(account) }
//         return size > 0;
//     }

//     /**
//      * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
//      * `recipient`, forwarding all available gas and reverting on errors.
//      *
//      * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
//      * of certain opcodes, possibly making contracts go over the 2300 gas limit
//      * imposed by `transfer`, making them unable to receive funds via
//      * `transfer`. {sendValue} removes this limitation.
//      *
//      * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
//      *
//      * IMPORTANT: because control is transferred to `recipient`, care must be
//      * taken to not create reentrancy vulnerabilities. Consider using
//      * {ReentrancyGuard} or the
//      * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
//      */
//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//         (bool success, ) = recipient.call{ value: amount }("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     /**
//      * @dev Performs a Solidity function call using a low level `call`. A
//      * plain`call` is an unsafe replacement for a function call: use this
//      * function instead.
//      *
//      * If `target` reverts with a revert reason, it is bubbled up by this
//      * function (like regular Solidity function calls).
//      *
//      * Returns the raw returned data. To convert to the expected return value,
//      * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
//      *
//      * Requirements:
//      *
//      * - `target` must be a contract.
//      * - calling `target` with `data` must not revert.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//       return functionCall(target, data, "Address: low-level call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
//      * `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         return _functionCallWithValue(target, data, 0, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but also transferring `value` wei to `target`.
//      *
//      * Requirements:
//      *
//      * - the calling contract must have an ETH balance of at least `value`.
//      * - the called Solidity function must be `payable`.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
//      * with `errorMessage` as a fallback revert reason when `target` reverts.
//      *
//      * _Available since v3.1._
//      */
//     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: value }(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }

//   /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
//         return functionStaticCall(target, data, "Address: low-level static call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a static call.
//      *
//      * _Available since v3.3._
//      */
//     function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
//         require(isContract(target), "Address: static call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.staticcall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.3._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.3._
//      */
//     function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         require(isContract(target), "Address: delegate call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.delegatecall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }

//     function addressToString(address _address) internal pure returns(string memory) {
//         bytes32 _bytes = bytes32(uint256(_address));
//         bytes memory HEX = "0123456789abcdef";
//         bytes memory _addr = new bytes(42);

//         _addr[0] = '0';
//         _addr[1] = 'x';

//         for(uint256 i = 0; i < 20; i++) {
//             _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
//             _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
//         }

//         return string(_addr);

//     }
// }

// library SafeERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(IERC20 token, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     /**
//      * @dev Deprecated. This function has issues similar to the ones found in
//      * {IERC20-approve}, and its usage is discouraged.
//      *
//      * Whenever possible, use {safeIncreaseAllowance} and
//      * {safeDecreaseAllowance} instead.
//      */
//     function safeApprove(IERC20 token, address spender, uint256 value) internal {
//         // safeApprove should only be called when setting an initial allowance,
//         // or when resetting it to zero. To increase and decrease it, use
//         // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
//         // solhint-disable-next-line max-line-length
//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }

//     function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(value);
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     /**
//      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
//      * on the return value: the return value is optional (but if data is returned, it must not be false).
//      * @param token The token targeted by the call.
//      * @param data The call data (encoded using abi.encode or one of its variants).
//      */
//     function _callOptionalReturn(IERC20 token, bytes memory data) private {
//         // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
//         // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
//         // the target address contains contract code and also asserts for success in the low-level call.

//         bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
//         if (returndata.length > 0) { // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
//         }
//     }
// }

// interface IOwnable {
//   function manager() external view returns (address);

//   function renounceManagement() external;
  
//   function pushManagement( address newOwner_ ) external;
  
//   function pullManagement() external;
// }

// contract Ownable is IOwnable {

//     address internal _owner;
//     address internal _newOwner;

//     event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
//     event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

//     constructor () {
//         _owner = msg.sender;
//         emit OwnershipPushed( address(0), _owner );
//     }

//     function manager() public view override returns (address) {
//         return _owner;
//     }

//     modifier onlyManager() {
//         require( _owner == msg.sender, "Ownable: caller is not the owner" );
//         _;
//     }

//     function renounceManagement() public virtual override onlyManager() {
//         emit OwnershipPushed( _owner, address(0) );
//         _owner = address(0);
//     }

//     function pushManagement( address newOwner_ ) public virtual override onlyManager() {
//         require( newOwner_ != address(0), "Ownable: new owner is the zero address");
//         emit OwnershipPushed( _owner, newOwner_ );
//         _newOwner = newOwner_;
//     }
    
//     function pullManagement() public virtual override {
//         require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
//         emit OwnershipPulled( _owner, _newOwner );
//         _owner = _newOwner;
//     }
// }

// interface IsOHM {
//     function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);

//     function circulatingSupply() external view returns (uint256);

//     function balanceOf(address who) external view returns (uint256);

//     function gonsForBalance( uint amount ) external view returns ( uint );

//     function balanceForGons( uint gons ) external view returns ( uint );
    
//     function index() external view returns ( uint );
// }

// interface IWarmup {
//     function retrieve( address staker_, uint amount_ ) external;
// }

// interface IDistributor {
//     function distribute() external returns ( bool );
// }

// contract OlympusStaking is Ownable {

//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;

//     address public immutable OHM;
//     address public immutable sOHM;

//     struct Epoch {
//         uint length;
//         uint number;
//         uint endBlock;
//         uint distribute;
//     }
//     Epoch public epoch;

//     address public distributor;
    
//     address public locker;
//     uint public totalBonus;
    
//     address public warmupContract;
//     uint public warmupPeriod;
    
//     constructor ( 
//         address _OHM, 
//         address _sOHM, 
//         uint _epochLength,
//         uint _firstEpochNumber,
//         uint _firstEpochBlock
//     ) {
//         require( _OHM != address(0) );
//         OHM = _OHM;
//         require( _sOHM != address(0) );
//         sOHM = _sOHM;
        
//         epoch = Epoch({
//             length: _epochLength,
//             number: _firstEpochNumber,
//             endBlock: _firstEpochBlock,
//             distribute: 0
//         });
//     }

//     struct Claim {
//         uint deposit;
//         uint gons;
//         uint expiry;
//         bool lock; // prevents malicious delays
//     }
//     mapping( address => Claim ) public warmupInfo;

//     /**
//         @notice stake OHM to enter warmup
//         @param _amount uint
//         @return bool
//      */
//     function stake( uint _amount, address _recipient ) external returns ( bool ) {
//         rebase();
        
//         IERC20( OHM ).safeTransferFrom( msg.sender, address(this), _amount );

//         Claim memory info = warmupInfo[ _recipient ];
//         require( !info.lock, "Deposits for account are locked" );

//         warmupInfo[ _recipient ] = Claim ({
//             deposit: info.deposit.add( _amount ),
//             gons: info.gons.add( IsOHM( sOHM ).gonsForBalance( _amount ) ),
//             expiry: epoch.number.add( warmupPeriod ),
//             lock: false
//         });
        
//         IERC20( sOHM ).safeTransfer( warmupContract, _amount );
//         return true;
//     }

//     /**
//         @notice retrieve sOHM from warmup
//         @param _recipient address
//      */
//     function claim ( address _recipient ) public {
//         Claim memory info = warmupInfo[ _recipient ];
//         if ( epoch.number >= info.expiry && info.expiry != 0 ) {
//             delete warmupInfo[ _recipient ];
//             IWarmup( warmupContract ).retrieve( _recipient, IsOHM( sOHM ).balanceForGons( info.gons ) );
//         }
//     }

//     /**
//         @notice forfeit sOHM in warmup and retrieve OHM
//      */
//     function forfeit() external {
//         Claim memory info = warmupInfo[ msg.sender ];
//         delete warmupInfo[ msg.sender ];

//         IWarmup( warmupContract ).retrieve( address(this), IsOHM( sOHM ).balanceForGons( info.gons ) );
//         IERC20( OHM ).safeTransfer( msg.sender, info.deposit );
//     }

//     /**
//         @notice prevent new deposits to address (protection from malicious activity)
//      */
//     function toggleDepositLock() external {
//         warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
//     }

//     /**
//         @notice redeem sOHM for OHM
//         @param _amount uint
//         @param _trigger bool
//      */
//     function unstake( uint _amount, bool _trigger ) external {
//         if ( _trigger ) {
//             rebase();
//         }
//         IERC20( sOHM ).safeTransferFrom( msg.sender, address(this), _amount );
//         IERC20( OHM ).safeTransfer( msg.sender, _amount );
//     }

//     /**
//         @notice returns the sOHM index, which tracks rebase growth
//         @return uint
//      */
//     function index() public view returns ( uint ) {
//         return IsOHM( sOHM ).index();
//     }

//     /**
//         @notice trigger rebase if epoch over
//      */
//     function rebase() public {
//         if( epoch.endBlock <= block.number ) {

//             IsOHM( sOHM ).rebase( epoch.distribute, epoch.number );

//             epoch.endBlock = epoch.endBlock.add( epoch.length );
//             epoch.number++;
            
//             if ( distributor != address(0) ) {
//                 IDistributor( distributor ).distribute();
//             }

//             uint balance = contractBalance();
//             uint staked = IsOHM( sOHM ).circulatingSupply();

//             if( balance <= staked ) {
//                 epoch.distribute = 0;
//             } else {
//                 epoch.distribute = balance.sub( staked );
//             }
//         }
//     }

//     /**
//         @notice returns contract OHM holdings, including bonuses provided
//         @return uint
//      */
//     function contractBalance() public view returns ( uint ) {
//         return IERC20( OHM ).balanceOf( address(this) ).add( totalBonus );
//     }

//     /**
//         @notice provide bonus to locked staking contract
//         @param _amount uint
//      */
//     function giveLockBonus( uint _amount ) external {
//         require( msg.sender == locker );
//         totalBonus = totalBonus.add( _amount );
//         IERC20( sOHM ).safeTransfer( locker, _amount );
//     }

//     /**
//         @notice reclaim bonus from locked staking contract
//         @param _amount uint
//      */
//     function returnLockBonus( uint _amount ) external {
//         require( msg.sender == locker );
//         totalBonus = totalBonus.sub( _amount );
//         IERC20( sOHM ).safeTransferFrom( locker, address(this), _amount );
//     }

//     enum CONTRACTS { DISTRIBUTOR, WARMUP, LOCKER }

//     /**
//         @notice sets the contract address for LP staking
//         @param _contract address
//      */
//     function setContract( CONTRACTS _contract, address _address ) external onlyManager() {
//         if( _contract == CONTRACTS.DISTRIBUTOR ) { // 0
//             distributor = _address;
//         } else if ( _contract == CONTRACTS.WARMUP ) { // 1
//             require( warmupContract == address( 0 ), "Warmup cannot be set more than once" );
//             warmupContract = _address;
//         } else if ( _contract == CONTRACTS.LOCKER ) { // 2
//             require( locker == address(0), "Locker cannot be set more than once" );
//             locker = _address;
//         }
//     }
    
//     /**
//      * @notice set warmup period for new stakers
//      * @param _warmupPeriod uint
//      */
//     function setWarmup( uint _warmupPeriod ) external onlyManager() {
//         warmupPeriod = _warmupPeriod;
//     }
// }

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IOlympusBondDepository {
  function DAO() external view returns (address);
  function OHM() external view returns (address);
  function adjustment() external view returns (bool add, uint256 rate, uint256 target, uint256 buffer, uint256 lastBlock);
  function bondCalculator() external view returns (address);
  function bondInfo(address) external view returns (uint256 payout, uint256 vesting, uint256 lastBlock, uint256 pricePaid);
  function bondPrice() external view returns (uint256 price_);
  function bondPriceInUSD() external view returns (uint256 price_);
  function currentDebt() external view returns (uint256);
  function debtDecay() external view returns (uint256 decay_);
  function debtRatio() external view returns (uint256 debtRatio_);
  function deposit(uint256 _amount, uint256 _maxPrice, address _depositor) external returns (uint256);
  function initializeBondTerms(uint256 _controlVariable, uint256 _vestingTerm, uint256 _minimumPrice, uint256 _maxPayout, uint256 _fee, uint256 _maxDebt, uint256 _initialDebt) external;
  function isLiquidityBond() external view returns (bool);
  function lastDecay() external view returns (uint256);
  function maxPayout() external view returns (uint256);
  function payoutFor(uint256 _value) external view returns (uint256);
  function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_);
  function percentVestedFor(address _depositor) external view returns (uint256 percentVested_);
  function policy() external view returns (address);
  function principle() external view returns (address);
  function pullManagement() external;
  function pushManagement(address newOwner_) external;
  function recoverLostToken(address _token) external returns (bool);
  function redeem(address _recipient, bool _stake) external returns (uint256);
  function renounceManagement() external;
  function setAdjustment(bool _addition, uint256 _increment, uint256 _target, uint256 _buffer) external;
  function setBondTerms(uint8 _parameter, uint256 _input) external;
  function setStaking(address _staking, bool _helper) external;
  function staking() external view returns (address);
  function stakingHelper() external view returns (address);
  function standardizedDebtRatio() external view returns (uint256);
  function terms() external view returns (uint256 controlVariable, uint256 vestingTerm, uint256 minimumPrice, uint256 maxPayout, uint256 fee, uint256 maxDebt);
  function totalDebt() external view returns (uint256);
  function treasury() external view returns (address);
  function useHelper() external view returns (bool);
}



// interface IOwnable {
//   function policy() external view returns (address);

//   function renounceManagement() external;
  
//   function pushManagement( address newOwner_ ) external;
  
//   function pullManagement() external;
// }

// contract Ownable is IOwnable {

//     address internal _owner;
//     address internal _newOwner;

//     event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
//     event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

//     constructor () {
//         _owner = msg.sender;
//         emit OwnershipPushed( address(0), _owner );
//     }

//     function policy() public view override returns (address) {
//         return _owner;
//     }

//     modifier onlyPolicy() {
//         require( _owner == msg.sender, "Ownable: caller is not the owner" );
//         _;
//     }

//     function renounceManagement() public virtual override onlyPolicy() {
//         emit OwnershipPushed( _owner, address(0) );
//         _owner = address(0);
//     }

//     function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
//         require( newOwner_ != address(0), "Ownable: new owner is the zero address");
//         emit OwnershipPushed( _owner, newOwner_ );
//         _newOwner = newOwner_;
//     }
    
//     function pullManagement() public virtual override {
//         require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
//         emit OwnershipPulled( _owner, _newOwner );
//         _owner = _newOwner;
//     }
// }

// library SafeMath {

//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");

//         return c;
//     }

//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         return sub(a, b, "SafeMath: subtraction overflow");
//     }

//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         uint256 c = a - b;

//         return c;
//     }

//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         if (a == 0) {
//             return 0;
//         }

//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");

//         return c;
//     }

//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         return div(a, b, "SafeMath: division by zero");
//     }

//     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         uint256 c = a / b;
//         return c;
//     }

//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         return mod(a, b, "SafeMath: modulo by zero");
//     }

//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b != 0, errorMessage);
//         return a % b;
//     }

//     function sqrrt(uint256 a) internal pure returns (uint c) {
//         if (a > 3) {
//             c = a;
//             uint b = add( div( a, 2), 1 );
//             while (b < c) {
//                 c = b;
//                 b = div( add( div( a, b ), b), 2 );
//             }
//         } else if (a != 0) {
//             c = 1;
//         }
//     }
// }

// library Address {

//     function isContract(address account) internal view returns (bool) {

//         uint256 size;
//         // solhint-disable-next-line no-inline-assembly
//         assembly { size := extcodesize(account) }
//         return size > 0;
//     }

//     function sendValue(address payable recipient, uint256 amount) internal {
//         require(address(this).balance >= amount, "Address: insufficient balance");

//         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
//         (bool success, ) = recipient.call{ value: amount }("");
//         require(success, "Address: unable to send value, recipient may have reverted");
//     }

//     function functionCall(address target, bytes memory data) internal returns (bytes memory) {
//       return functionCall(target, data, "Address: low-level call failed");
//     }

//     function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         return _functionCallWithValue(target, data, 0, errorMessage);
//     }

//     function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
//         return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
//     }

//     function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
//         require(address(this).balance >= value, "Address: insufficient balance for call");
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: value }(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
//         require(isContract(target), "Address: call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
//         if (success) {
//             return returndata;
//         } else {
//             // Look for revert reason and bubble it up if present
//             if (returndata.length > 0) {
//                 // The easiest way to bubble the revert reason is using memory via assembly

//                 // solhint-disable-next-line no-inline-assembly
//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }

//     function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
//         return functionStaticCall(target, data, "Address: low-level static call failed");
//     }

//     function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
//         require(isContract(target), "Address: static call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.staticcall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
//         require(isContract(target), "Address: delegate call to non-contract");

//         // solhint-disable-next-line avoid-low-level-calls
//         (bool success, bytes memory returndata) = target.delegatecall(data);
//         return _verifyCallResult(success, returndata, errorMessage);
//     }

//     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
//         if (success) {
//             return returndata;
//         } else {
//             if (returndata.length > 0) {

//                 assembly {
//                     let returndata_size := mload(returndata)
//                     revert(add(32, returndata), returndata_size)
//                 }
//             } else {
//                 revert(errorMessage);
//             }
//         }
//     }

//     function addressToString(address _address) internal pure returns(string memory) {
//         bytes32 _bytes = bytes32(uint256(_address));
//         bytes memory HEX = "0123456789abcdef";
//         bytes memory _addr = new bytes(42);

//         _addr[0] = '0';
//         _addr[1] = 'x';

//         for(uint256 i = 0; i < 20; i++) {
//             _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
//             _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
//         }

//         return string(_addr);

//     }
// }

// interface IERC20 {
//     function decimals() external view returns (uint8);

//     function totalSupply() external view returns (uint256);

//     function balanceOf(address account) external view returns (uint256);

//     function transfer(address recipient, uint256 amount) external returns (bool);

//     function allowance(address owner, address spender) external view returns (uint256);

//     function approve(address spender, uint256 amount) external returns (bool);

//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);

//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// abstract contract ERC20 is IERC20 {

//     using SafeMath for uint256;

//     // TODO comment actual hash value.
//     bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256( "ERC20Token" );
    
//     mapping (address => uint256) internal _balances;

//     mapping (address => mapping (address => uint256)) internal _allowances;

//     uint256 internal _totalSupply;

//     string internal _name;
    
//     string internal _symbol;
    
//     uint8 internal _decimals;

//     constructor (string memory name_, string memory symbol_, uint8 decimals_) {
//         _name = name_;
//         _symbol = symbol_;
//         _decimals = decimals_;
//     }

//     function name() public view returns (string memory) {
//         return _name;
//     }

//     function symbol() public view returns (string memory) {
//         return _symbol;
//     }

//     function decimals() public view override returns (uint8) {
//         return _decimals;
//     }

//     function totalSupply() public view override returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address account) public view virtual override returns (uint256) {
//         return _balances[account];
//     }

//     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
//         _transfer(msg.sender, recipient, amount);
//         return true;
//     }

//     function allowance(address owner, address spender) public view virtual override returns (uint256) {
//         return _allowances[owner][spender];
//     }

//     function approve(address spender, uint256 amount) public virtual override returns (bool) {
//         _approve(msg.sender, spender, amount);
//         return true;
//     }

//     function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
//         _transfer(sender, recipient, amount);
//         _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
//         return true;
//     }

//     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
//         _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
//         return true;
//     }

//     function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
//         _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
//         return true;
//     }

//     function _transfer(address sender, address recipient, uint256 amount) internal virtual {
//         require(sender != address(0), "ERC20: transfer from the zero address");
//         require(recipient != address(0), "ERC20: transfer to the zero address");

//         _beforeTokenTransfer(sender, recipient, amount);

//         _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
//         _balances[recipient] = _balances[recipient].add(amount);
//         emit Transfer(sender, recipient, amount);
//     }

//     function _mint(address account_, uint256 ammount_) internal virtual {
//         require(account_ != address(0), "ERC20: mint to the zero address");
//         _beforeTokenTransfer(address( this ), account_, ammount_);
//         _totalSupply = _totalSupply.add(ammount_);
//         _balances[account_] = _balances[account_].add(ammount_);
//         emit Transfer(address( this ), account_, ammount_);
//     }

//     function _burn(address account, uint256 amount) internal virtual {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _beforeTokenTransfer(account, address(0), amount);

//         _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
//         _totalSupply = _totalSupply.sub(amount);
//         emit Transfer(account, address(0), amount);
//     }

//     function _approve(address owner, address spender, uint256 amount) internal virtual {
//         require(owner != address(0), "ERC20: approve from the zero address");
//         require(spender != address(0), "ERC20: approve to the zero address");

//         _allowances[owner][spender] = amount;
//         emit Approval(owner, spender, amount);
//     }

//   function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
// }

// interface IERC2612Permit {

//     function permit(
//         address owner,
//         address spender,
//         uint256 amount,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) external;

//     function nonces(address owner) external view returns (uint256);
// }

// library Counters {
//     using SafeMath for uint256;

//     struct Counter {

//         uint256 _value; // default: 0
//     }

//     function current(Counter storage counter) internal view returns (uint256) {
//         return counter._value;
//     }

//     function increment(Counter storage counter) internal {
//         counter._value += 1;
//     }

//     function decrement(Counter storage counter) internal {
//         counter._value = counter._value.sub(1);
//     }
// }

// abstract contract ERC20Permit is ERC20, IERC2612Permit {
//     using Counters for Counters.Counter;

//     mapping(address => Counters.Counter) private _nonces;

//     // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
//     bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

//     bytes32 public DOMAIN_SEPARATOR;

//     constructor() {
//         uint256 chainID;
//         assembly {
//             chainID := chainid()
//         }

//         DOMAIN_SEPARATOR = keccak256(
//             abi.encode(
//                 keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
//                 keccak256(bytes(name())),
//                 keccak256(bytes("1")), // Version
//                 chainID,
//                 address(this)
//             )
//         );
//     }

//     function permit(
//         address owner,
//         address spender,
//         uint256 amount,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s
//     ) public virtual override {
//         require(block.timestamp <= deadline, "Permit: expired deadline");

//         bytes32 hashStruct =
//             keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

//         bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

//         address signer = ecrecover(_hash, v, r, s);
//         require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

//         _nonces[owner].increment();
//         _approve(owner, spender, amount);
//     }

//     function nonces(address owner) public view override returns (uint256) {
//         return _nonces[owner].current();
//     }
// }

// library SafeERC20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(IERC20 token, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
//     }

//     function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
//         _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
//     }

//     function safeApprove(IERC20 token, address spender, uint256 value) internal {

//         require((value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeERC20: approve from non-zero to non-zero allowance"
//         );
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
//     }

//     function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(value);
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
//         _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
//     }

//     function _callOptionalReturn(IERC20 token, bytes memory data) private {

//         bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
//         if (returndata.length > 0) { // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
//         }
//     }
// }

// library FullMath {
//     function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
//         uint256 mm = mulmod(x, y, uint256(-1));
//         l = x * y;
//         h = mm - l;
//         if (mm < l) h -= 1;
//     }

//     function fullDiv(
//         uint256 l,
//         uint256 h,
//         uint256 d
//     ) private pure returns (uint256) {
//         uint256 pow2 = d & -d;
//         d /= pow2;
//         l /= pow2;
//         l += h * ((-pow2) / pow2 + 1);
//         uint256 r = 1;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         r *= 2 - d * r;
//         return l * r;
//     }

//     function mulDiv(
//         uint256 x,
//         uint256 y,
//         uint256 d
//     ) internal pure returns (uint256) {
//         (uint256 l, uint256 h) = fullMul(x, y);
//         uint256 mm = mulmod(x, y, d);
//         if (mm > l) h -= 1;
//         l -= mm;
//         require(h < d, 'FullMath::mulDiv: overflow');
//         return fullDiv(l, h, d);
//     }
// }

// library FixedPoint {

//     struct uq112x112 {
//         uint224 _x;
//     }

//     struct uq144x112 {
//         uint256 _x;
//     }

//     uint8 private constant RESOLUTION = 112;
//     uint256 private constant Q112 = 0x10000000000000000000000000000;
//     uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
//     uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

//     function decode(uq112x112 memory self) internal pure returns (uint112) {
//         return uint112(self._x >> RESOLUTION);
//     }

//     function decode112with18(uq112x112 memory self) internal pure returns (uint) {

//         return uint(self._x) / 5192296858534827;
//     }

//     function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
//         require(denominator > 0, 'FixedPoint::fraction: division by zero');
//         if (numerator == 0) return FixedPoint.uq112x112(0);

//         if (numerator <= uint144(-1)) {
//             uint256 result = (numerator << RESOLUTION) / denominator;
//             require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
//             return uq112x112(uint224(result));
//         } else {
//             uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
//             require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
//             return uq112x112(uint224(result));
//         }
//     }
// }

// interface ITreasury {
//     function deposit( uint _amount, address _token, uint _profit ) external returns ( bool );
//     function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
// }

// interface IBondCalculator {
//     function valuation( address _LP, uint _amount ) external view returns ( uint );
//     function markdown( address _LP ) external view returns ( uint );
// }

// interface IStaking {
//     function stake( uint _amount, address _recipient ) external returns ( bool );
// }

// interface IStakingHelper {
//     function stake( uint _amount, address _recipient ) external;
// }

// contract OlympusBondDepository is Ownable {

//     using FixedPoint for *;
//     using SafeERC20 for IERC20;
//     using SafeMath for uint;




//     /* ======== EVENTS ======== */

//     event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
//     event BondRedeemed( address indexed recipient, uint payout, uint remaining );
//     event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
//     event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );




//     /* ======== STATE VARIABLES ======== */

//     address public immutable OHM; // token given as payment for bond
//     address public immutable principle; // token used to create bond
//     address public immutable treasury; // mints OHM when receives principle
//     address public immutable DAO; // receives profit share from bond

//     bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
//     address public immutable bondCalculator; // calculates value of LP tokens

//     address public staking; // to auto-stake payout
//     address public stakingHelper; // to stake and claim if no staking warmup
//     bool public useHelper;

//     Terms public terms; // stores terms for new bonds
//     Adjust public adjustment; // stores adjustment to BCV data

//     mapping( address => Bond ) public bondInfo; // stores bond information for depositors

//     uint public totalDebt; // total value of outstanding bonds; used for pricing
//     uint public lastDecay; // reference block for debt decay




//     /* ======== STRUCTS ======== */

//     // Info for creating new bonds
//     struct Terms {
//         uint controlVariable; // scaling variable for price
//         uint vestingTerm; // in blocks
//         uint minimumPrice; // vs principle value
//         uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
//         uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
//         uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
//     }

//     // Info for bond holder
//     struct Bond {
//         uint payout; // OHM remaining to be paid
//         uint vesting; // Blocks left to vest
//         uint lastBlock; // Last interaction
//         uint pricePaid; // In DAI, for front end viewing
//     }

//     // Info for incremental adjustments to control variable 
//     struct Adjust {
//         bool add; // addition or subtraction
//         uint rate; // increment
//         uint target; // BCV when adjustment finished
//         uint buffer; // minimum length (in blocks) between adjustments
//         uint lastBlock; // block when last adjustment made
//     }




//     /* ======== INITIALIZATION ======== */

//     constructor ( 
//         address _OHM,
//         address _principle,
//         address _treasury, 
//         address _DAO, 
//         address _bondCalculator
//     ) {
//         require( _OHM != address(0) );
//         OHM = _OHM;
//         require( _principle != address(0) );
//         principle = _principle;
//         require( _treasury != address(0) );
//         treasury = _treasury;
//         require( _DAO != address(0) );
//         DAO = _DAO;
//         // bondCalculator should be address(0) if not LP bond
//         bondCalculator = _bondCalculator;
//         isLiquidityBond = ( _bondCalculator != address(0) );
//     }

//     /**
//      *  @notice initializes bond parameters
//      *  @param _controlVariable uint
//      *  @param _vestingTerm uint
//      *  @param _minimumPrice uint
//      *  @param _maxPayout uint
//      *  @param _fee uint
//      *  @param _maxDebt uint
//      *  @param _initialDebt uint
//      */
//     function initializeBondTerms( 
//         uint _controlVariable, 
//         uint _vestingTerm,
//         uint _minimumPrice,
//         uint _maxPayout,
//         uint _fee,
//         uint _maxDebt,
//         uint _initialDebt
//     ) external onlyPolicy() {
//         require( terms.controlVariable == 0, "Bonds must be initialized from 0" );
//         terms = Terms ({
//             controlVariable: _controlVariable,
//             vestingTerm: _vestingTerm,
//             minimumPrice: _minimumPrice,
//             maxPayout: _maxPayout,
//             fee: _fee,
//             maxDebt: _maxDebt
//         });
//         totalDebt = _initialDebt;
//         lastDecay = block.number;
//     }



    
//     /* ======== POLICY FUNCTIONS ======== */

//     enum PARAMETER { VESTING, PAYOUT, FEE, DEBT }
//     /**
//      *  @notice set parameters for new bonds
//      *  @param _parameter PARAMETER
//      *  @param _input uint
//      */
//     function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyPolicy() {
//         if ( _parameter == PARAMETER.VESTING ) { // 0
//             require( _input >= 10000, "Vesting must be longer than 36 hours" );
//             terms.vestingTerm = _input;
//         } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
//             require( _input <= 1000, "Payout cannot be above 1 percent" );
//             terms.maxPayout = _input;
//         } else if ( _parameter == PARAMETER.FEE ) { // 2
//             require( _input <= 10000, "DAO fee cannot exceed payout" );
//             terms.fee = _input;
//         } else if ( _parameter == PARAMETER.DEBT ) { // 3
//             terms.maxDebt = _input;
//         }
//     }

//     /**
//      *  @notice set control variable adjustment
//      *  @param _addition bool
//      *  @param _increment uint
//      *  @param _target uint
//      *  @param _buffer uint
//      */
//     function setAdjustment ( 
//         bool _addition,
//         uint _increment, 
//         uint _target,
//         uint _buffer 
//     ) external onlyPolicy() {
//         require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

//         adjustment = Adjust({
//             add: _addition,
//             rate: _increment,
//             target: _target,
//             buffer: _buffer,
//             lastBlock: block.number
//         });
//     }

//     /**
//      *  @notice set contract for auto stake
//      *  @param _staking address
//      *  @param _helper bool
//      */
//     function setStaking( address _staking, bool _helper ) external onlyPolicy() {
//         require( _staking != address(0) );
//         if ( _helper ) {
//             useHelper = true;
//             stakingHelper = _staking;
//         } else {
//             useHelper = false;
//             staking = _staking;
//         }
//     }


    

//     /* ======== USER FUNCTIONS ======== */

//     /**
//      *  @notice deposit bond
//      *  @param _amount uint
//      *  @param _maxPrice uint
//      *  @param _depositor address
//      *  @return uint
//      */
//     function deposit( 
//         uint _amount, 
//         uint _maxPrice,
//         address _depositor
//     ) external returns ( uint ) {
//         require( _depositor != address(0), "Invalid address" );

//         decayDebt();
//         require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        
//         uint priceInUSD = bondPriceInUSD(); // Stored in bond info
//         uint nativePrice = _bondPrice();

//         require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

//         uint value = ITreasury( treasury ).valueOf( principle, _amount );
//         uint payout = payoutFor( value ); // payout to bonder is computed

//         require( payout >= 10000000, "Bond too small" ); // must be > 0.01 OHM ( underflow protection )
//         require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

//         // profits are calculated
//         uint fee = payout.mul( terms.fee ).div( 10000 );
//         uint profit = value.sub( payout ).sub( fee );

//         /**
//             principle is transferred in
//             approved and
//             deposited into the treasury, returning (_amount - profit) OHM
//          */
//         IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
//         IERC20( principle ).approve( address( treasury ), _amount );
//         ITreasury( treasury ).deposit( _amount, principle, profit );
        
//         if ( fee != 0 ) { // fee is transferred to dao 
//             IERC20( OHM ).safeTransfer( DAO, fee ); 
//         }
        
//         // total debt is increased
//         totalDebt = totalDebt.add( value ); 
                
//         // depositor info is stored
//         bondInfo[ _depositor ] = Bond({ 
//             payout: bondInfo[ _depositor ].payout.add( payout ),
//             vesting: terms.vestingTerm,
//             lastBlock: block.number,
//             pricePaid: priceInUSD
//         });

//         // indexed events are emitted
//         emit BondCreated( _amount, payout, block.number.add( terms.vestingTerm ), priceInUSD );
//         emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

//         adjust(); // control variable is adjusted
//         return payout; 
//     }

//     /** 
//      *  @notice redeem bond for user
//      *  @param _recipient address
//      *  @param _stake bool
//      *  @return uint
//      */ 
//     function redeem( address _recipient, bool _stake ) external returns ( uint ) {        
//         Bond memory info = bondInfo[ _recipient ];
//         uint percentVested = percentVestedFor( _recipient ); // (blocks since last interaction / vesting term remaining)

//         if ( percentVested >= 10000 ) { // if fully vested
//             delete bondInfo[ _recipient ]; // delete user info
//             emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
//             return stakeOrSend( _recipient, _stake, info.payout ); // pay user everything due

//         } else { // if unfinished
//             // calculate payout vested
//             uint payout = info.payout.mul( percentVested ).div( 10000 );

//             // store updated deposit info
//             bondInfo[ _recipient ] = Bond({
//                 payout: info.payout.sub( payout ),
//                 vesting: info.vesting.sub( block.number.sub( info.lastBlock ) ),
//                 lastBlock: block.number,
//                 pricePaid: info.pricePaid
//             });

//             emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
//             return stakeOrSend( _recipient, _stake, payout );
//         }
//     }



    
//     /* ======== INTERNAL HELPER FUNCTIONS ======== */

//     /**
//      *  @notice allow user to stake payout automatically
//      *  @param _stake bool
//      *  @param _amount uint
//      *  @return uint
//      */
//     function stakeOrSend( address _recipient, bool _stake, uint _amount ) internal returns ( uint ) {
//         if ( !_stake ) { // if user does not want to stake
//             IERC20( OHM ).transfer( _recipient, _amount ); // send payout
//         } else { // if user wants to stake
//             if ( useHelper ) { // use if staking warmup is 0
//                 IERC20( OHM ).approve( stakingHelper, _amount );
//                 IStakingHelper( stakingHelper ).stake( _amount, _recipient );
//             } else {
//                 IERC20( OHM ).approve( staking, _amount );
//                 IStaking( staking ).stake( _amount, _recipient );
//             }
//         }
//         return _amount;
//     }

//     /**
//      *  @notice makes incremental adjustment to control variable
//      */
//     function adjust() internal {
//         uint blockCanAdjust = adjustment.lastBlock.add( adjustment.buffer );
//         if( adjustment.rate != 0 && block.number >= blockCanAdjust ) {
//             uint initial = terms.controlVariable;
//             if ( adjustment.add ) {
//                 terms.controlVariable = terms.controlVariable.add( adjustment.rate );
//                 if ( terms.controlVariable >= adjustment.target ) {
//                     adjustment.rate = 0;
//                 }
//             } else {
//                 terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
//                 if ( terms.controlVariable <= adjustment.target ) {
//                     adjustment.rate = 0;
//                 }
//             }
//             adjustment.lastBlock = block.number;
//             emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
//         }
//     }

//     /**
//      *  @notice reduce total debt
//      */
//     function decayDebt() internal {
//         totalDebt = totalDebt.sub( debtDecay() );
//         lastDecay = block.number;
//     }




//     /* ======== VIEW FUNCTIONS ======== */

//     /**
//      *  @notice determine maximum bond size
//      *  @return uint
//      */
//     function maxPayout() public view returns ( uint ) {
//         return IERC20( OHM ).totalSupply().mul( terms.maxPayout ).div( 100000 );
//     }

//     /**
//      *  @notice calculate interest due for new bond
//      *  @param _value uint
//      *  @return uint
//      */
//     function payoutFor( uint _value ) public view returns ( uint ) {
//         return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );
//     }


//     /**
//      *  @notice calculate current bond premium
//      *  @return price_ uint
//      */
//     function bondPrice() public view returns ( uint price_ ) {        
//         price_ = terms.controlVariable.mul( debtRatio() ).add( 1000000000 ).div( 1e7 );
//         if ( price_ < terms.minimumPrice ) {
//             price_ = terms.minimumPrice;
//         }
//     }

//     /**
//      *  @notice calculate current bond price and remove floor if above
//      *  @return price_ uint
//      */
//     function _bondPrice() internal returns ( uint price_ ) {
//         price_ = terms.controlVariable.mul( debtRatio() ).add( 1000000000 ).div( 1e7 );
//         if ( price_ < terms.minimumPrice ) {
//             price_ = terms.minimumPrice;        
//         } else if ( terms.minimumPrice != 0 ) {
//             terms.minimumPrice = 0;
//         }
//     }

//     /**
//      *  @notice converts bond price to DAI value
//      *  @return price_ uint
//      */
//     function bondPriceInUSD() public view returns ( uint price_ ) {
//         if( isLiquidityBond ) {
//             price_ = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 100 );
//         } else {
//             price_ = bondPrice().mul( 10 ** IERC20( principle ).decimals() ).div( 100 );
//         }
//     }


//     /**
//      *  @notice calculate current ratio of debt to OHM supply
//      *  @return debtRatio_ uint
//      */
//     function debtRatio() public view returns ( uint debtRatio_ ) {   
//         uint supply = IERC20( OHM ).totalSupply();
//         debtRatio_ = FixedPoint.fraction( 
//             currentDebt().mul( 1e9 ), 
//             supply
//         ).decode112with18().div( 1e18 );
//     }

//     /**
//      *  @notice debt ratio in same terms for reserve or liquidity bonds
//      *  @return uint
//      */
//     function standardizedDebtRatio() external view returns ( uint ) {
//         if ( isLiquidityBond ) {
//             return debtRatio().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 1e9 );
//         } else {
//             return debtRatio();
//         }
//     }

//     /**
//      *  @notice calculate debt factoring in decay
//      *  @return uint
//      */
//     function currentDebt() public view returns ( uint ) {
//         return totalDebt.sub( debtDecay() );
//     }

//     /**
//      *  @notice amount to decay total debt by
//      *  @return decay_ uint
//      */
//     function debtDecay() public view returns ( uint decay_ ) {
//         uint blocksSinceLast = block.number.sub( lastDecay );
//         decay_ = totalDebt.mul( blocksSinceLast ).div( terms.vestingTerm );
//         if ( decay_ > totalDebt ) {
//             decay_ = totalDebt;
//         }
//     }


//     /**
//      *  @notice calculate how far into vesting a depositor is
//      *  @param _depositor address
//      *  @return percentVested_ uint
//      */
//     function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
//         Bond memory bond = bondInfo[ _depositor ];
//         uint blocksSinceLast = block.number.sub( bond.lastBlock );
//         uint vesting = bond.vesting;

//         if ( vesting > 0 ) {
//             percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
//         } else {
//             percentVested_ = 0;
//         }
//     }

//     /**
//      *  @notice calculate amount of OHM available for claim by depositor
//      *  @param _depositor address
//      *  @return pendingPayout_ uint
//      */
//     function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
//         uint percentVested = percentVestedFor( _depositor );
//         uint payout = bondInfo[ _depositor ].payout;

//         if ( percentVested >= 10000 ) {
//             pendingPayout_ = payout;
//         } else {
//             pendingPayout_ = payout.mul( percentVested ).div( 10000 );
//         }
//     }




//     /* ======= AUXILLIARY ======= */

//     /**
//      *  @notice allow anyone to send lost tokens (excluding principle or OHM) to the DAO
//      *  @return bool
//      */
//     function recoverLostToken( address _token ) external returns ( bool ) {
//         require( _token != OHM );
//         require( _token != principle );
//         IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
//         return true;
//     }
// }

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './Interfaces/IUniswapV2Factory.sol';
import './TransferHelper.sol';

import './Interfaces/IUniswapV2Router02.sol';
import './UniswapV2Library.sol';
import '../Math/SafeMath.sol';
import '../ERC20/IERC20.sol';
import '../ERC20/IWETH.sol';

contract UniswapV2Router02_Modified is IUniswapV2Router02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        
        
        TransferHelper.safeTransferFrom(WETH, msg.sender, pair, amountETH);

        // IWETH(WETH).transferFrom(msg.sender, pair, amountETH);
        // IWETH(WETH).deposit{value: amountETH}();
        // assert(IWETH(WETH).transfer(pair, amountETH));

        // require(false, "HELLO: HOW ARE YOU TODAY!");

        liquidity = IUniswapV2Pair(pair).mint(to); // << PROBLEM IS HERE

        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        // for (uint i; i < path.length - 1; i++) {
        //     (address input, address output) = (path[i], path[i + 1]);
        //     (address token0,) = UniswapV2Library.sortTokens(input, output);
        //     IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
        //     uint amountInput;
        //     uint amountOutput;
        //     { // scope to avoid stack too deep errors
        //     (uint reserve0, uint reserve1,) = pair.getReserves();
        //     (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        //     amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
        //     amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
        //     }
        //     (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        //     address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
        //     pair.swap(amount0Out, amount1Out, to, new bytes(0));
        // }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        // TransferHelper.safeTransferFrom(
        //     path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        // );
        // uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // _swapSupportingFeeOnTransferTokens(path, to);
        // require(
        //     IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
        //     'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        // );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        // require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        // uint amountIn = msg.value;
        // IWETH(WETH).deposit{value: amountIn}();
        // assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        // uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        // _swapSupportingFeeOnTransferTokens(path, to);
        // require(
        //     IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
        //     'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        // );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        // require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        // TransferHelper.safeTransferFrom(
        //     path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        // );
        // _swapSupportingFeeOnTransferTokens(path, address(this));
        // uint amountOut = IERC20(WETH).balanceOf(address(this));
        // require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        // IWETH(WETH).withdraw(amountOut);
        // TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;


import './Interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import '../Math/Math.sol';
import '../Math/UQ112x112.sol';
import '../ERC20/IERC20.sol';
import './Interfaces/IUniswapV2Factory.sol';
import './Interfaces/IUniswapV2Callee.sol';

contract UniswapV2Pair is IUniswapV2Pair {
    using SafeMath for uint;
    using UQ112x112 for uint224;

    string public override constant name = 'Uniswap V2';
    string public override constant symbol = 'UNI-V2';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    uint public override constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;


    

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override price0CumulativeLast;
    uint public override price1CumulativeLast;
    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    // event Mint(address indexed sender, uint amount0, uint amount1);
    // event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    // event Swap(
    //     address indexed sender,
    //     uint amount0In,
    //     uint amount1In,
    //     uint amount0Out,
    //     uint amount1Out,
    //     address indexed to
    // );
    // event Sync(uint112 reserve0, uint112 reserve1);

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }

        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }



    // Migrated over from UniswapV2ERC20. Needed for ^0.6.0
    // ===============================================

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }



}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.0 <0.9.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned_Proxy {
    address public owner;
    address public nominatedOwner;

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "./IERC20.sol";
import "../Math/SafeMath.sol";
import "../Utils/Address.sol";

// Due to compiling issues, _name, _symbol, and _decimals were removed


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20Custom is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * - `spender` cannot be the zero address.approve(address spender, uint256 amount)
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
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
     * Requirements
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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
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
     * - the caller must have allowance for `accounts`'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "../Common/Context.sol";
import "../Math/SafeMath.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity >=0.6.11;

import "../Utils/EnumerableSet.sol";
import "../Utils/Address.sol";
import "../Common/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; //bytes32(uint256(0x4B437D01b575618140442A4975db38850e3f8f5f) << 96);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

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
pragma solidity >=0.6.11;

import '../Uniswap/Interfaces/IUniswapV2Factory.sol';
import '../Uniswap/Interfaces/IUniswapV2Pair.sol';
import '../Math/FixedPoint.sol';

import '../Uniswap/UniswapV2OracleLibrary.sol';
import '../Uniswap/UniswapV2Library.sol';
import "../Staking/Owned.sol";

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle is Owned {
    using FixedPoint for *;
    
    address timelock_address;

    uint public PERIOD = 3600; // 1 hour TWAP (time-weighted average price)
    uint public CONSULT_LENIENCY = 120; // Used for being able to consult past the period end
    bool public ALLOW_STALE_CONSULTS = false; // If false, consult() will fail if the TWAP is stale

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    uint    public price0CumulativeLast;
    uint    public price1CumulativeLast;
    uint32  public blockTimestampLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    constructor(address factory, address tokenA, address tokenB, address _owner_address, address _timelock_address) public Owned(_owner_address) {
        IUniswapV2Pair _pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, 'UniswapPairOracle: NO_RESERVES'); // Ensure that there's liquidity in the pair

        timelock_address = _timelock_address;
    }

    function setTimelock(address _timelock_address) external onlyByOwnerOrGovernance {
        timelock_address = _timelock_address;
    }

    function setPeriod(uint _period) external onlyByOwnerOrGovernance {
        PERIOD = _period;
    }

    function setConsultLeniency(uint _consult_leniency) external onlyByOwnerOrGovernance {
        CONSULT_LENIENCY = _consult_leniency;
    }

    function setAllowStaleConsults(bool _allow_stale_consults) external onlyByOwnerOrGovernance {
        ALLOW_STALE_CONSULTS = _allow_stale_consults;
    }

    // Check if update() can be called instead of wasting gas calling it
    function canUpdate() public view returns (bool) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired
        return (timeElapsed >= PERIOD);
    }

    function update() external {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'UniswapPairOracle: PERIOD_NOT_ELAPSED');

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint amountIn) external view returns (uint amountOut) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Ensure that the price is not stale
        require((timeElapsed < (PERIOD + CONSULT_LENIENCY)) || ALLOW_STALE_CONSULTS, 'UniswapPairOracle: PRICE_IS_STALE_NEED_TO_CALL_UPDATE');

        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, 'UniswapPairOracle: INVALID_TOKEN');
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import "./AggregatorV3Interface.sol";

contract ChainlinkETHUSDPriceConsumer {

    AggregatorV3Interface internal priceFeed;


    constructor() public {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(bytes20(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(bytes20(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

import "../../Math/SafeMath.sol";



library FraxPoolLibrary {
    using SafeMath for uint256;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // ================ Structs ================
    // Needed to lower stack size
    struct MintFF_Params {
        uint256 fxs_price_usd; 
        uint256 col_price_usd;
        uint256 fxs_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    struct BuybackFXS_Params {
        uint256 excess_collateral_dollar_value_d18;
        uint256 fxs_price_usd;
        uint256 col_price_usd;
        uint256 FXS_amount;
    }

    // ================ Functions ================

    function calcMint1t1FRAX(uint256 col_price, uint256 collateral_amount_d18) public pure returns (uint256) {
        return (collateral_amount_d18.mul(col_price)).div(1e6);
    }

    function calcMintAlgorithmicFRAX(uint256 fxs_price_usd, uint256 fxs_amount_d18) public pure returns (uint256) {
        return fxs_amount_d18.mul(fxs_price_usd).div(1e6);
    }

    // Must be internal because of the struct
    function calcMintFractionalFRAX(MintFF_Params memory params) internal pure returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint FRAX. We do this by seeing the minimum mintable FRAX based on each amount 
        uint256 fxs_dollar_value_d18;
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the FXS
            fxs_dollar_value_d18 = params.fxs_amount.mul(params.fxs_price_usd).div(1e6);
            c_dollar_value_d18 = params.collateral_amount.mul(params.col_price_usd).div(1e6);

        }
        uint calculated_fxs_dollar_value_d18 = 
                    (c_dollar_value_d18.mul(1e6).div(params.col_ratio))
                    .sub(c_dollar_value_d18);

        uint calculated_fxs_needed = calculated_fxs_dollar_value_d18.mul(1e6).div(params.fxs_price_usd);

        return (
            c_dollar_value_d18.add(calculated_fxs_dollar_value_d18),
            calculated_fxs_needed
        );
    }

    function calcRedeem1t1FRAX(uint256 col_price_usd, uint256 FRAX_amount) public pure returns (uint256) {
        return FRAX_amount.mul(1e6).div(col_price_usd);
    }

    // Must be internal because of the struct
    function calcBuyBackFXS(BuybackFXS_Params memory params) internal pure returns (uint256) {
        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible FXS with the desired collateral
        require(params.excess_collateral_dollar_value_d18 > 0, "No excess collateral to buy back!");

        // Make sure not to take more than is available
        uint256 fxs_dollar_value_d18 = params.FXS_amount.mul(params.fxs_price_usd).div(1e6);
        require(fxs_dollar_value_d18 <= params.excess_collateral_dollar_value_d18, "You are trying to buy back more than the excess!");

        // Get the equivalent amount of collateral based on the market value of FXS provided 
        uint256 collateral_equivalent_d18 = fxs_dollar_value_d18.mul(1e6).div(params.col_price_usd);
        //collateral_equivalent_d18 = collateral_equivalent_d18.sub((collateral_equivalent_d18.mul(params.buyback_fee)).div(1e6));

        return (
            collateral_equivalent_d18
        );

    }


    // Returns value of collateral that must increase to reach recollateralization target (if 0 means no recollateralization)
    function recollateralizeAmount(uint256 total_supply, uint256 global_collateral_ratio, uint256 global_collat_value) public pure returns (uint256) {
        uint256 target_collat_value = total_supply.mul(global_collateral_ratio).div(1e6); // We want 18 decimals of precision so divide by 1e6; total_supply is 1e18 and global_collateral_ratio is 1e6
        // Subtract the current value of collateral from the target value needed, if higher than 0 then system needs to recollateralize
        return target_collat_value.sub(global_collat_value); // If recollateralization is not needed, throws a subtraction underflow
        // return(recollateralization_left);
    }

    function calcRecollateralizeFRAXInner(
        uint256 collateral_amount, 
        uint256 col_price,
        uint256 global_collat_value,
        uint256 frax_total_supply,
        uint256 global_collateral_ratio
    ) public pure returns (uint256, uint256) {
        uint256 collat_value_attempted = collateral_amount.mul(col_price).div(1e6);
        uint256 effective_collateral_ratio = global_collat_value.mul(1e6).div(frax_total_supply); //returns it in 1e6
        uint256 recollat_possible = (global_collateral_ratio.mul(frax_total_supply).sub(frax_total_supply.mul(effective_collateral_ratio))).div(1e6);

        uint256 amount_to_recollat;
        if(collat_value_attempted <= recollat_possible){
            amount_to_recollat = collat_value_attempted;
        } else {
            amount_to_recollat = recollat_possible;
        }

        return (amount_to_recollat.mul(1e6).div(col_price), amount_to_recollat);

    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import '../Uniswap/Interfaces/IUniswapV2Pair.sol';
import '../Math/FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './Interfaces/IUniswapV2Pair.sol';
import './Interfaces/IUniswapV2Factory.sol';

import "../Math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // Less efficient than the CREATE2 method below
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForCreate2(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(bytes20(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))))); // this matches the CREATE2 in UniswapV2Factory.createPair
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i = 0; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IUniswapV2Router01 {
    function factory() external returns (address);
    function WETH() external returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

import './Interfaces/IUniswapV2ERC20.sol';
import '../Math/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public override constant name = 'Uniswap V2';
    string public override constant symbol = 'UNI-V2';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    // event Approval(address indexed owner, address indexed spender, uint value);
    // event Transfer(address indexed from, address indexed to, uint value);

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IUniswapV2ERC20 {
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
}

