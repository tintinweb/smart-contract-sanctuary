// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== FraxLendingAMO ==========================
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
import "../Oracle/UniswapPairOracle.sol";
import "../Governance/AccessControl.sol";
import "../Frax/Pools/FraxPool.sol";
import "./cream/ICREAM_crFRAX.sol";
import "./finnexus/IFNX_CFNX.sol";
import "./finnexus/IFNX_FPT_FRAX.sol";
import "./finnexus/IFNX_FPT_B.sol";
import "./finnexus/IFNX_IntegratedStake.sol";
import "./finnexus/IFNX_MinePool.sol";
import "./finnexus/IFNX_TokenConverter.sol";
import "./finnexus/IFNX_ManagerProxy.sol";
import "./finnexus/IFNX_Oracle.sol";


contract FraxLendingAMO is AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    FRAXShares private FXS;
    FRAXStablecoin private FRAX;
    FraxPool private pool;

    // Cream
    ICREAM_crFRAX private crFRAX = ICREAM_crFRAX(0xb092b4601850E23903A42EaCBc9D8A0EeC26A4d5);

    // FinNexus
    // More addresses: https://github.com/FinNexus/FinNexus-Documentation/blob/master/content/developers/smart-contracts.md
    IFNX_FPT_FRAX private fnxFPT_FRAX = IFNX_FPT_FRAX(0x39ad661bA8a7C9D3A7E4808fb9f9D5223E22F763);
    IFNX_FPT_B private fnxFPT_B = IFNX_FPT_B(0x7E605Fb638983A448096D82fFD2958ba012F30Cd);
    IFNX_IntegratedStake private fnxIntegratedStake = IFNX_IntegratedStake(0x23e54F9bBe26eD55F93F19541bC30AAc2D5569b2);
    IFNX_MinePool private fnxMinePool = IFNX_MinePool(0x4e6005396F80a737cE80d50B2162C0a7296c9620);
    IFNX_TokenConverter private fnxTokenConverter = IFNX_TokenConverter(0x955282b82440F8F69E901380BeF2b603Fba96F3b);
    IFNX_ManagerProxy private fnxManagerProxy = IFNX_ManagerProxy(0xa2904Fd151C9d9D634dFA8ECd856E6B9517F9785);
    IFNX_Oracle private fnxOracle = IFNX_Oracle(0x43BD92bF3Bb25EBB3BdC2524CBd6156E3Fdd41F3);

    // Reward Tokens
    IFNX_CFNX private CFNX = IFNX_CFNX(0x9d7beb4265817a4923FAD9Ca9EF8af138499615d);
    ERC20 private FNX = ERC20(0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B);

    address public collateral_address;
    address public pool_address;
    address public owner_address;
    address public timelock_address;
    address public custodian_address;

    uint256 public immutable missing_decimals;
    uint256 private constant PRICE_PRECISION = 1e6;

    // Max amount of FRAX this contract mint
    uint256 public mint_cap = uint256(100000e18);

    // Minimum collateral ratio needed for new FRAX minting
    uint256 public min_cr = 850000;

    // Amount the contract borrowed
    uint256 public minted_sum_historical = 0;
    uint256 public burned_sum_historical = 0;

    // Allowed strategies (can eventually be made into an array)
    bool public allow_cream = true;
    bool public allow_finnexus = true;

    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address _frax_contract_address,
        address _fxs_contract_address,
        address _pool_address,
        address _collateral_address,
        address _owner_address,
        address _custodian_address,
        address _timelock_address
    ) public {
        FRAX = FRAXStablecoin(_frax_contract_address);
        FXS = FRAXShares(_fxs_contract_address);
        pool_address = _pool_address;
        pool = FraxPool(_pool_address);
        collateral_address = _collateral_address;
        collateral_token = ERC20(_collateral_address);
        timelock_address = _timelock_address;
        owner_address = _owner_address;
        custodian_address = _custodian_address;
        missing_decimals = uint(18).sub(collateral_token.decimals());
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodian_address, "You are not the rewards custodian");
        _;
    }

    /* ========== VIEWS ========== */

    function showAllocations() external view returns (uint256[10] memory allocations) {
        // IMPORTANT
        // Should ONLY be used externally, because it may fail if any one of the functions below fail

        // All numbers given are in FRAX unless otherwise stated
        allocations[0] = FRAX.balanceOf(address(this)); // Unallocated FRAX
        allocations[1] = (crFRAX.balanceOf(address(this)).mul(crFRAX.exchangeRateStored()).div(1e18)); // Cream
        allocations[2] = (fnxMinePool.getUserFPTABalance(address(this))).mul(1e8).div(fnxManagerProxy.getTokenNetworth()); // Staked FPT-FRAX
        allocations[3] = (fnxFPT_FRAX.balanceOf(address(this))).mul(1e8).div(fnxManagerProxy.getTokenNetworth()); // Free FPT-FRAX
        allocations[4] = fnxTokenConverter.lockedBalanceOf(address(this)); // Unwinding CFNX
        allocations[5] = fnxTokenConverter.getClaimAbleBalance(address(this)); // Claimable Unwound FNX
        allocations[6] = FNX.balanceOf(address(this)); // Free FNX

        uint256 sum_fnx = allocations[4];
        sum_fnx = sum_fnx.add(allocations[5]);
        sum_fnx = sum_fnx.add(allocations[6]);
        allocations[7] = sum_fnx; // Total FNX possessed in various forms

        uint256 sum_frax = allocations[0];
        sum_frax = sum_frax.add(allocations[1]);
        sum_frax = sum_frax.add(allocations[2]);
        sum_frax = sum_frax.add(allocations[3]);
        allocations[8] = sum_frax; // Total FRAX possessed in various forms
        allocations[9] = collatDollarBalance();
    }

    function showRewards() external view returns (uint256[1] memory rewards) {
        // IMPORTANT
        // Should ONLY be used externally, because it may fail if FNX.balanceOf() fails
        rewards[0] = FNX.balanceOf(address(this)); // FNX
    }

    // In FRAX
    function mintedBalance() public view returns (uint256){
        if (minted_sum_historical > burned_sum_historical) return minted_sum_historical.sub(burned_sum_historical);
        else return 0;
    }

    // In FRAX
    function historicalProfit() public view returns (uint256){
        if (burned_sum_historical > minted_sum_historical) return burned_sum_historical.sub(minted_sum_historical);
        else return 0;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Needed for the Frax contract to not brick
    bool public override_collat_balance = false;
    uint256 public override_collat_balance_amount;
    function collatDollarBalance() public view returns (uint256) {
        if(override_collat_balance){
            return override_collat_balance_amount;
        }

        // E18 for dollars, not E6
        // Assumes $1 FRAX and $1 USDC
        return (mintedBalance()).mul(FRAX.global_collateral_ratio()).div(PRICE_PRECISION);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main FRAX contract
    function mintFRAXForInvestments(uint256 frax_amount) public onlyByOwnerOrGovernance {
        uint256 borrowed_balance = mintedBalance();

        // Make sure you aren't minting more than the mint cap
        require(borrowed_balance.add(frax_amount) <= mint_cap, "Borrow cap reached");
        minted_sum_historical = minted_sum_historical.add(frax_amount);

        // Make sure the current CR isn't already too low
        require (FRAX.global_collateral_ratio() > min_cr, "Collateral ratio is already too low");

        // Make sure the FRAX minting wouldn't push the CR down too much
        uint256 current_collateral_E18 = (FRAX.globalCollateralValue()).mul(10 ** missing_decimals);
        uint256 cur_frax_supply = FRAX.totalSupply();
        uint256 new_frax_supply = cur_frax_supply.add(frax_amount);
        uint256 new_cr = (current_collateral_E18.mul(PRICE_PRECISION)).div(new_frax_supply);
        require (new_cr > min_cr, "Minting would cause collateral ratio to be too low");

        // Mint the frax 
        FRAX.pool_mint(address(this), frax_amount);
    }

    // Give USDC profits back
    function giveCollatBack(uint256 amount) public onlyByOwnerOrGovernance {
        collateral_token.transfer(address(pool), amount);
    }
   
    // Burn unneeded or excess FRAX
    function burnFRAX(uint256 frax_amount) public onlyByOwnerOrGovernance {
        FRAX.burn(frax_amount);
        burned_sum_historical = burned_sum_historical.add(frax_amount);
    }

    // Burn unneeded FXS
    function burnFXS(uint256 amount) public onlyByOwnerOrGovernance {
        FXS.approve(address(this), amount);
        FXS.pool_burn_from(address(this), amount);
    }

    /* ==================== CREAM ==================== */

    // E18
    function creamDeposit_FRAX(uint256 FRAX_amount) public onlyByOwnerOrGovernance {
        require(allow_cream, 'Cream strategy is disabled');
        FRAX.approve(address(crFRAX), FRAX_amount);
        require(crFRAX.mint(FRAX_amount) == 0, 'Mint failed');
    }

    // E18
    function creamWithdraw_FRAX(uint256 FRAX_amount) public onlyByOwnerOrGovernance {
        require(crFRAX.redeemUnderlying(FRAX_amount) == 0, 'RedeemUnderlying failed');
    }

    // E8
    function creamWithdraw_crFRAX(uint256 crFRAX_amount) public onlyByOwnerOrGovernance {
        require(crFRAX.redeem(crFRAX_amount) == 0, 'Redeem failed');
    }

    /* ==================== FinNexus ==================== */
    
    /* --== Staking ==-- */

    function fnxIntegratedStakeFPTs_FRAX_FNX(uint256 FRAX_amount, uint256 FNX_amount, uint256 lock_period) public onlyByOwnerOrGovernance {
        require(allow_finnexus, 'FinNexus strategy is disabled');
        FRAX.approve(address(fnxIntegratedStake), FRAX_amount);
        FNX.approve(address(fnxIntegratedStake), FNX_amount);
        
        address[] memory fpta_tokens = new address[](1);
        uint256[] memory fpta_amounts = new uint256[](1);
        address[] memory fptb_tokens = new address[](1);
        uint256[] memory fptb_amounts = new uint256[](1);

        fpta_tokens[0] = address(FRAX);
        fpta_amounts[0] = FRAX_amount;
        fptb_tokens[0] = address(FNX);
        fptb_amounts[0] = FNX_amount;

        fnxIntegratedStake.stake(fpta_tokens, fpta_amounts, fptb_tokens, fptb_amounts, lock_period);
    }

    // FPT-FRAX : FPT-B = 10:1 is the best ratio for staking. You can get it using the prices.
    function fnxStakeFRAXForFPT_FRAX(uint256 FRAX_amount, uint256 lock_period) public onlyByOwnerOrGovernance {
        require(allow_finnexus, 'FinNexus strategy is disabled');
        FRAX.approve(address(fnxIntegratedStake), FRAX_amount);

        address[] memory fpta_tokens = new address[](1);
        uint256[] memory fpta_amounts = new uint256[](1);
        address[] memory fptb_tokens = new address[](0);
        uint256[] memory fptb_amounts = new uint256[](0);

        fpta_tokens[0] = address(FRAX);
        fpta_amounts[0] = FRAX_amount;

        fnxIntegratedStake.stake(fpta_tokens, fpta_amounts, fptb_tokens, fptb_amounts, lock_period);
    }

    /* --== Collect CFNX ==-- */

    function fnxCollectCFNX() public onlyByOwnerOrGovernance {
        uint256 claimable_cfnx = fnxMinePool.getMinerBalance(address(this), address(CFNX));
        fnxMinePool.redeemMinerCoin(address(CFNX), claimable_cfnx);
    }

    /* --== UnStaking ==-- */

    // FPT-FRAX = Staked FRAX
    function fnxUnStakeFPT_FRAX(uint256 FPT_FRAX_amount) public onlyByOwnerOrGovernance {
        fnxMinePool.unstakeFPTA(FPT_FRAX_amount);
    }

    // FPT-B = Staked FNX
    function fnxUnStakeFPT_B(uint256 FPT_B_amount) public onlyByOwnerOrGovernance {
        fnxMinePool.unstakeFPTB(FPT_B_amount);
    }

    /* --== Unwrapping LP Tokens ==-- */

    // FPT-FRAX = Staked FRAX
    function fnxUnRedeemFPT_FRAXForFRAX(uint256 FPT_FRAX_amount) public onlyByOwnerOrGovernance {
        fnxFPT_FRAX.approve(address(fnxManagerProxy), FPT_FRAX_amount);
        fnxManagerProxy.redeemCollateral(FPT_FRAX_amount, address(FRAX));
    }

    // FPT-B = Staked FNX
    function fnxUnStakeFPT_BForFNX(uint256 FPT_B_amount) public onlyByOwnerOrGovernance {
        fnxFPT_B.approve(address(fnxManagerProxy), FPT_B_amount);
        fnxManagerProxy.redeemCollateral(FPT_B_amount, address(FNX));
    }

    /* --== Convert CFNX to FNX ==-- */
    
    // Has to be done in batches, since it unlocks over several months
    function fnxInputCFNXForUnwinding() public onlyByOwnerOrGovernance {
        uint256 cfnx_amount = CFNX.balanceOf(address(this));
        CFNX.approve(address(fnxTokenConverter), cfnx_amount);
        fnxTokenConverter.inputCfnxForInstallmentPay(cfnx_amount);
    }

    function fnxClaimFNX_From_CFNX() public onlyByOwnerOrGovernance {
        fnxTokenConverter.claimFnxExpiredReward();
    }

    /* --== Combination Functions ==-- */
    
    function fnxCFNXCollectConvertUnwind() public onlyByOwnerOrGovernance {
        fnxCollectCFNX();
        fnxInputCFNXForUnwinding();
        fnxClaimFNX_From_CFNX();
    }

    /* ========== Custodian ========== */

    function withdrawRewards() public onlyCustodian {
        FNX.transfer(custodian_address, FNX.balanceOf(address(this)));
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setMiscRewardsCustodian(address _custodian_address) external onlyByOwnerOrGovernance {
        custodian_address = _custodian_address;
    }

    function setPool(address _pool_address) external onlyByOwnerOrGovernance {
        pool_address = _pool_address;
        pool = FraxPool(_pool_address);
    }

    function setMintCap(uint256 _mint_cap) external onlyByOwnerOrGovernance {
        mint_cap = _mint_cap;
    }

    function setMinimumCollateralRatio(uint256 _min_cr) external onlyByOwnerOrGovernance {
        min_cr = _min_cr;
    }

    function setAllowedStrategies(bool _cream, bool _finnexus) external onlyByOwnerOrGovernance {
        allow_cream = _cream;
        allow_finnexus = _finnexus;
    }

    function setOverrideCollatBalance(bool _state, uint256 _balance) external onlyByOwnerOrGovernance {
        override_collat_balance = _state;
        override_collat_balance_amount = _balance;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerOrGovernance {
        // Can only be triggered by owner or governance, not custodian
        // Tokens are sent to the custodian, as a sort of safeguard

        ERC20(tokenAddress).transfer(custodian_address, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }


    /* ========== EVENTS ========== */

    event Recovered(address token, uint256 amount);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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
import "../Math/SafeMath.sol";
import "../Governance/AccessControl.sol";

contract FRAXShares is ERC20Custom, AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public FRAXStablecoinAdd;
    
    uint256 public constant genesis_supply = 100000000e18; // 100M is printed upon genesis
    uint256 public FXS_DAO_min; // Minimum FXS required to join DAO groups 

    address public owner_address;
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
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol, 
        address _oracle_address,
        address _owner_address,
        address _timelock_address
    ) public {
        name = _name;
        symbol = _symbol;
        owner_address = _owner_address;
        oracle_address = _oracle_address;
        timelock_address = _timelock_address;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(owner_address, genesis_supply);

        // Do a checkpoint for the owner
        _writeCheckpoint(owner_address, 0, 0, uint96(genesis_supply));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOracle(address new_oracle) external onlyByOwnerOrGovernance {
        oracle_address = new_oracle;
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }
    
    function setFRAXAddress(address frax_contract_address) external onlyByOwnerOrGovernance {
        FRAX = FRAXStablecoin(frax_contract_address);
    }
    
    function setFXSMinDAO(uint256 min_FXS) external onlyByOwnerOrGovernance {
        FXS_DAO_min = min_FXS;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /* ========== EVENTS ========== */
    
    /// @notice An event thats emitted when a voters account's vote balance changes
    event VoterVotesChanged(address indexed voter, uint previousBalance, uint newBalance);

    // Track FXS burned
    event FXSBurned(address indexed from, address indexed to, uint256 amount);

    // Track FXS minted
    event FXSMinted(address indexed from, address indexed to, uint256 amount);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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
import "../FXS/FXS.sol";
import "./Pools/FraxPool.sol";
import "../Oracle/UniswapPairOracle.sol";
import "../Oracle/ChainlinkETHUSDPriceConsumer.sol";
import "../Governance/AccessControl.sol";

contract FRAXStablecoin is ERC20Custom, AccessControl {
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
    address public owner_address;
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
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address || msg.sender == controller_address, "You are not the owner, controller, or the governance timelock");
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == owner_address 
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
    ) public {
        name = _name;
        symbol = _symbol;
        creator_address = _creator_address;
        timelock_address = _timelock_address;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DEFAULT_ADMIN_ADDRESS = _msgSender();
        owner_address = _creator_address;
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
        uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth;

        if (choice == PriceChoice.FRAX) {
            price_vs_eth = uint256(fraxEthOracle.consult(weth_address, PRICE_PRECISION)); // How much FRAX if you put in PRICE_PRECISION WETH
        }
        else if (choice == PriceChoice.FXS) {
            price_vs_eth = uint256(fxsEthOracle.consult(weth_address, PRICE_PRECISION)); // How much FXS if you put in PRICE_PRECISION WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (FRAX) or 1 (FXS)");

        // Will be in 1e6 format
        return eth_usd_price.mul(PRICE_PRECISION).div(price_vs_eth);
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
    function addPool(address pool_address) public onlyByOwnerOrGovernance {
        require(frax_pools[pool_address] == false, "address already exists");
        frax_pools[pool_address] = true; 
        frax_pools_array.push(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerOrGovernance {
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
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setRedemptionFee(uint256 red_fee) public onlyByOwnerOrGovernance {
        redemption_fee = red_fee;
    }

    function setMintingFee(uint256 min_fee) public onlyByOwnerOrGovernance {
        minting_fee = min_fee;
    }  

    function setFraxStep(uint256 _new_step) public onlyByOwnerOrGovernance {
        frax_step = _new_step;
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerOrGovernance {
        price_target = _new_price_target;
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerOrGovernance {
    	refresh_cooldown = _new_cooldown;
    }

    function setFXSAddress(address _fxs_address) public onlyByOwnerOrGovernance {
        fxs_address = _fxs_address;
    }

    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyByOwnerOrGovernance {
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_usd_pricer = ChainlinkETHUSDPriceConsumer(eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setController(address _controller_address) external onlyByOwnerOrGovernance {
        controller_address = _controller_address;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerOrGovernance {
        price_band = _price_band;
    }

    // Sets the FRAX_ETH Uniswap oracle address 
    function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        frax_eth_oracle_address = _frax_oracle_addr;
        fraxEthOracle = UniswapPairOracle(_frax_oracle_addr); 
        weth_address = _weth_address;
    }

    // Sets the FXS_ETH Uniswap oracle address 
    function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        fxs_eth_oracle_address = _fxs_oracle_addr;
        fxsEthOracle = UniswapPairOracle(_fxs_oracle_addr);
        weth_address = _weth_address;
    }

    function toggleCollateralRatio() public onlyCollateralRatioPauser {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    /* ========== EVENTS ========== */

    // Track FRAX burned
    event FRAXBurned(address indexed from, address indexed to, uint256 amount);

    // Track FRAX minted
    event FRAXMinted(address indexed from, address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
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
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

contract Comp {
    /// @notice EIP-20 token name for this token
    string public constant name = "Compound";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "COMP";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public constant totalSupply = 10000000e18; // 10 million Comp

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
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
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
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
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

        if (spender != src && spenderAllowance != uint96(-1)) {
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
        require(now <= expiry, "Comp::delegateBySig: signature expired");
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

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import '../Uniswap/Interfaces/IUniswapV2Factory.sol';
import '../Uniswap/Interfaces/IUniswapV2Pair.sol';
import '../Math/FixedPoint.sol';

import '../Uniswap/UniswapV2OracleLibrary.sol';
import '../Uniswap/UniswapV2Library.sol';

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle {
    using FixedPoint for *;
    
    address owner_address;
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
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    constructor(address factory, address tokenA, address tokenB, address _owner_address, address _timelock_address) public {
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

        owner_address = _owner_address;
        timelock_address = _timelock_address;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
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

pragma solidity ^0.6.0;

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
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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
import "../../FXS/FXS.sol";
import "../../Frax/Frax.sol";
import "../../ERC20/ERC20.sol";
import "../../Oracle/UniswapPairOracle.sol";
import "../../Governance/AccessControl.sol";
import "./FraxPoolLibrary.sol";

contract FraxPool is AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    address private collateral_address;
    address private owner_address;

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
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
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
    ) public {
        FRAX = FRAXStablecoin(_frax_contract_address);
        FXS = FRAXShares(_fxs_contract_address);
        frax_contract_address = _frax_contract_address;
        fxs_contract_address = _fxs_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
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

        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
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
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
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
        uint FXSAmount;
        uint CollateralAmount;

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

        if(sendFXS == true){
            FXS.transfer(msg.sender, FXSAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
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
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
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
        collateral_token.transfer(msg.sender, collateral_precision);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external {
        require(hasRole(MINT_PAUSER, msg.sender));
        mintPaused = !mintPaused;
    }

    function toggleRedeeming() external {
        require(hasRole(REDEEM_PAUSER, msg.sender));
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external {
        require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
        recollateralizePaused = !recollateralizePaused;
    }
    
    function toggleBuyBack() external {
        require(hasRole(BUYBACK_PAUSER, msg.sender));
        buyBackPaused = !buyBackPaused;
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
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    /* ========== EVENTS ========== */

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// Original at https://etherscan.io/address/0xb092b4601850E23903A42EaCBc9D8A0EeC26A4d5
// Some functions were omitted for brevity. See the contract for details

interface ICREAM_crFRAX is IERC20  {
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external view returns (uint);
    function borrowBalanceCurrent(address account) external view returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external view returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

// pragma solidity ^0.5.16;

// import "./ComptrollerInterface.sol";
// import "./CTokenInterfaces.sol";
// import "./ErrorReporter.sol";
// import "./Exponential.sol";
// import "./EIP20Interface.sol";
// import "./EIP20NonStandardInterface.sol";
// import "./InterestRateModel.sol";

// /**
//  * @title Compound's CToken Contract
//  * @notice Abstract base for CTokens
//  * @author Compound
//  */
// contract CToken is CTokenInterface, Exponential, TokenErrorReporter {
//     /**
//      * @notice Initialize the money market
//      * @param comptroller_ The address of the Comptroller
//      * @param interestRateModel_ The address of the interest rate model
//      * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
//      * @param name_ EIP-20 name of this token
//      * @param symbol_ EIP-20 symbol of this token
//      * @param decimals_ EIP-20 decimal precision of this token
//      */
//     function initialize(ComptrollerInterface comptroller_,
//                         InterestRateModel interestRateModel_,
//                         uint initialExchangeRateMantissa_,
//                         string memory name_,
//                         string memory symbol_,
//                         uint8 decimals_) public {
//         require(msg.sender == admin, "only admin may initialize the market");
//         require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

//         // Set initial exchange rate
//         initialExchangeRateMantissa = initialExchangeRateMantissa_;
//         require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

//         // Set the comptroller
//         uint err = _setComptroller(comptroller_);
//         require(err == uint(Error.NO_ERROR), "setting comptroller failed");

//         // Initialize block number and borrow index (block number mocks depend on comptroller being set)
//         accrualBlockNumber = getBlockNumber();
//         borrowIndex = mantissaOne;

//         // Set the interest rate model (depends on block number / borrow index)
//         err = _setInterestRateModelFresh(interestRateModel_);
//         require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

//         name = name_;
//         symbol = symbol_;
//         decimals = decimals_;

//         // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
//         _notEntered = true;
//     }

//     /**
//      * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
//      * @dev Called by both `transfer` and `transferFrom` internally
//      * @param spender The address of the account performing the transfer
//      * @param src The address of the source account
//      * @param dst The address of the destination account
//      * @param tokens The number of tokens to transfer
//      * @return Whether or not the transfer succeeded
//      */
//     function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
//         /* Fail if transfer not allowed */
//         uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
//         if (allowed != 0) {
//             return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
//         }

//         /* Do not allow self-transfers */
//         if (src == dst) {
//             return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
//         }

//         /* Get the allowance, infinite for the account owner */
//         uint startingAllowance = 0;
//         if (spender == src) {
//             startingAllowance = uint(-1);
//         } else {
//             startingAllowance = transferAllowances[src][spender];
//         }

//         /* Do the calculations, checking for {under,over}flow */
//         MathError mathErr;
//         uint allowanceNew;
//         uint srcTokensNew;
//         uint dstTokensNew;

//         (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
//         if (mathErr != MathError.NO_ERROR) {
//             return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
//         }

//         (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
//         if (mathErr != MathError.NO_ERROR) {
//             return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
//         }

//         (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
//         if (mathErr != MathError.NO_ERROR) {
//             return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         accountTokens[src] = srcTokensNew;
//         accountTokens[dst] = dstTokensNew;

//         /* Eat some of the allowance (if necessary) */
//         if (startingAllowance != uint(-1)) {
//             transferAllowances[src][spender] = allowanceNew;
//         }

//         /* We emit a Transfer event */
//         emit Transfer(src, dst, tokens);

//         comptroller.transferVerify(address(this), src, dst, tokens);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
//      * @param dst The address of the destination account
//      * @param amount The number of tokens to transfer
//      * @return Whether or not the transfer succeeded
//      */
//     function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
//         return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice Transfer `amount` tokens from `src` to `dst`
//      * @param src The address of the source account
//      * @param dst The address of the destination account
//      * @param amount The number of tokens to transfer
//      * @return Whether or not the transfer succeeded
//      */
//     function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
//         return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice Approve `spender` to transfer up to `amount` from `src`
//      * @dev This will overwrite the approval amount for `spender`
//      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
//      * @param spender The address of the account which may transfer tokens
//      * @param amount The number of tokens that are approved (-1 means infinite)
//      * @return Whether or not the approval succeeded
//      */
//     function approve(address spender, uint256 amount) external returns (bool) {
//         address src = msg.sender;
//         transferAllowances[src][spender] = amount;
//         emit Approval(src, spender, amount);
//         return true;
//     }

//     /**
//      * @notice Get the current allowance from `owner` for `spender`
//      * @param owner The address of the account which owns the tokens to be spent
//      * @param spender The address of the account which may transfer tokens
//      * @return The number of tokens allowed to be spent (-1 means infinite)
//      */
//     function allowance(address owner, address spender) external view returns (uint256) {
//         return transferAllowances[owner][spender];
//     }

//     /**
//      * @notice Get the token balance of the `owner`
//      * @param owner The address of the account to query
//      * @return The number of tokens owned by `owner`
//      */
//     function balanceOf(address owner) external view returns (uint256) {
//         return accountTokens[owner];
//     }

//     /**
//      * @notice Get the underlying balance of the `owner`
//      * @dev This also accrues interest in a transaction
//      * @param owner The address of the account to query
//      * @return The amount of underlying owned by `owner`
//      */
//     function balanceOfUnderlying(address owner) external returns (uint) {
//         Exp memory exchangeRate = Exp({mantissa: exchangeRateCurrent()});
//         (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
//         require(mErr == MathError.NO_ERROR, "balance could not be calculated");
//         return balance;
//     }

//     /**
//      * @notice Get a snapshot of the account's balances, and the cached exchange rate
//      * @dev This is used by comptroller to more efficiently perform liquidity checks.
//      * @param account Address of the account to snapshot
//      * @return (possible error, token balance, borrow balance, exchange rate mantissa)
//      */
//     function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint) {
//         uint cTokenBalance = accountTokens[account];
//         uint borrowBalance;
//         uint exchangeRateMantissa;

//         MathError mErr;

//         (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
//         if (mErr != MathError.NO_ERROR) {
//             return (uint(Error.MATH_ERROR), 0, 0, 0);
//         }

//         (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
//         if (mErr != MathError.NO_ERROR) {
//             return (uint(Error.MATH_ERROR), 0, 0, 0);
//         }

//         return (uint(Error.NO_ERROR), cTokenBalance, borrowBalance, exchangeRateMantissa);
//     }

//     /**
//      * @dev Function to simply retrieve block number
//      *  This exists mainly for inheriting test contracts to stub this result.
//      */
//     function getBlockNumber() internal view returns (uint) {
//         return block.number;
//     }

//     /**
//      * @notice Returns the current per-block borrow interest rate for this cToken
//      * @return The borrow interest rate per block, scaled by 1e18
//      */
//     function borrowRatePerBlock() external view returns (uint) {
//         return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
//     }

//     /**
//      * @notice Returns the current per-block supply interest rate for this cToken
//      * @return The supply interest rate per block, scaled by 1e18
//      */
//     function supplyRatePerBlock() external view returns (uint) {
//         return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
//     }

//     /**
//      * @notice Returns the current total borrows plus accrued interest
//      * @return The total borrows with interest
//      */
//     function totalBorrowsCurrent() external nonReentrant returns (uint) {
//         require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
//         return totalBorrows;
//     }

//     /**
//      * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
//      * @param account The address whose balance should be calculated after updating borrowIndex
//      * @return The calculated balance
//      */
//     function borrowBalanceCurrent(address account) external nonReentrant returns (uint) {
//         require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
//         return borrowBalanceStored(account);
//     }

//     /**
//      * @notice Return the borrow balance of account based on stored data
//      * @param account The address whose balance should be calculated
//      * @return The calculated balance
//      */
//     function borrowBalanceStored(address account) public view returns (uint) {
//         (MathError err, uint result) = borrowBalanceStoredInternal(account);
//         require(err == MathError.NO_ERROR, "borrowBalanceStored: borrowBalanceStoredInternal failed");
//         return result;
//     }

//     /**
//      * @notice Return the borrow balance of account based on stored data
//      * @param account The address whose balance should be calculated
//      * @return (error code, the calculated balance or 0 if error code is non-zero)
//      */
//     function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
//         /* Note: we do not assert that the market is up to date */
//         MathError mathErr;
//         uint principalTimesIndex;
//         uint result;

//         /* Get borrowBalance and borrowIndex */
//         BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

//         /* If borrowBalance = 0 then borrowIndex is likely also 0.
//          * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
//          */
//         if (borrowSnapshot.principal == 0) {
//             return (MathError.NO_ERROR, 0);
//         }

//         /* Calculate new borrow balance using the interest index:
//          *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
//          */
//         (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
//         if (mathErr != MathError.NO_ERROR) {
//             return (mathErr, 0);
//         }

//         (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
//         if (mathErr != MathError.NO_ERROR) {
//             return (mathErr, 0);
//         }

//         return (MathError.NO_ERROR, result);
//     }

//     /**
//      * @notice Accrue interest then return the up-to-date exchange rate
//      * @return Calculated exchange rate scaled by 1e18
//      */
//     function exchangeRateCurrent() public nonReentrant returns (uint) {
//         require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
//         return exchangeRateStored();
//     }

//     /**
//      * @notice Calculates the exchange rate from the underlying to the CToken
//      * @dev This function does not accrue interest before calculating the exchange rate
//      * @return Calculated exchange rate scaled by 1e18
//      */
//     function exchangeRateStored() public view returns (uint) {
//         (MathError err, uint result) = exchangeRateStoredInternal();
//         require(err == MathError.NO_ERROR, "exchangeRateStored: exchangeRateStoredInternal failed");
//         return result;
//     }

//     /**
//      * @notice Calculates the exchange rate from the underlying to the CToken
//      * @dev This function does not accrue interest before calculating the exchange rate
//      * @return (error code, calculated exchange rate scaled by 1e18)
//      */
//     function exchangeRateStoredInternal() internal view returns (MathError, uint) {
//         uint _totalSupply = totalSupply;
//         if (_totalSupply == 0) {
//             /*
//              * If there are no tokens minted:
//              *  exchangeRate = initialExchangeRate
//              */
//             return (MathError.NO_ERROR, initialExchangeRateMantissa);
//         } else {
//             /*
//              * Otherwise:
//              *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
//              */
//             uint totalCash = getCashPrior();
//             uint cashPlusBorrowsMinusReserves;
//             Exp memory exchangeRate;
//             MathError mathErr;

//             (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
//             if (mathErr != MathError.NO_ERROR) {
//                 return (mathErr, 0);
//             }

//             (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
//             if (mathErr != MathError.NO_ERROR) {
//                 return (mathErr, 0);
//             }

//             return (MathError.NO_ERROR, exchangeRate.mantissa);
//         }
//     }

//     /**
//      * @notice Get cash balance of this cToken in the underlying asset
//      * @return The quantity of underlying asset owned by this contract
//      */
//     function getCash() external view returns (uint) {
//         return getCashPrior();
//     }

//     /**
//      * @notice Applies accrued interest to total borrows and reserves
//      * @dev This calculates interest accrued from the last checkpointed block
//      *   up to the current block and writes new checkpoint to storage.
//      */
//     function accrueInterest() public returns (uint) {
//         /* Remember the initial block number */
//         uint currentBlockNumber = getBlockNumber();
//         uint accrualBlockNumberPrior = accrualBlockNumber;

//         /* Short-circuit accumulating 0 interest */
//         if (accrualBlockNumberPrior == currentBlockNumber) {
//             return uint(Error.NO_ERROR);
//         }

//         /* Read the previous values out of storage */
//         uint cashPrior = getCashPrior();
//         uint borrowsPrior = totalBorrows;
//         uint reservesPrior = totalReserves;
//         uint borrowIndexPrior = borrowIndex;

//         /* Calculate the current borrow interest rate */
//         uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
//         require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

//         /* Calculate the number of blocks elapsed since the last accrual */
//         (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
//         require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

//         /*
//          * Calculate the interest accumulated into borrows and reserves and the new index:
//          *  simpleInterestFactor = borrowRate * blockDelta
//          *  interestAccumulated = simpleInterestFactor * totalBorrows
//          *  totalBorrowsNew = interestAccumulated + totalBorrows
//          *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
//          *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
//          */

//         Exp memory simpleInterestFactor;
//         uint interestAccumulated;
//         uint totalBorrowsNew;
//         uint totalReservesNew;
//         uint borrowIndexNew;

//         (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: borrowRateMantissa}), blockDelta);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
//         }

//         (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
//         }

//         (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
//         }

//         (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa: reserveFactorMantissa}), interestAccumulated, reservesPrior);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
//         }

//         (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /* We write the previously calculated values into storage */
//         accrualBlockNumber = currentBlockNumber;
//         borrowIndex = borrowIndexNew;
//         totalBorrows = totalBorrowsNew;
//         totalReserves = totalReservesNew;

//         /* We emit an AccrueInterest event */
//         emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice Sender supplies assets into the market and receives cTokens in exchange
//      * @dev Accrues interest whether or not the operation succeeds, unless reverted
//      * @param mintAmount The amount of the underlying asset to supply
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
//      */
//     function mintInternal(uint mintAmount) internal nonReentrant returns (uint, uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
//             return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
//         }
//         // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
//         return mintFresh(msg.sender, mintAmount);
//     }

//     struct MintLocalVars {
//         Error err;
//         MathError mathErr;
//         uint exchangeRateMantissa;
//         uint mintTokens;
//         uint totalSupplyNew;
//         uint accountTokensNew;
//         uint actualMintAmount;
//     }

//     /**
//      * @notice User supplies assets into the market and receives cTokens in exchange
//      * @dev Assumes interest has already been accrued up to the current block
//      * @param minter The address of the account which is supplying the assets
//      * @param mintAmount The amount of the underlying asset to supply
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
//      */
//     function mintFresh(address minter, uint mintAmount) internal returns (uint, uint) {
//         /* Fail if mint not allowed */
//         uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
//         if (allowed != 0) {
//             return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed), 0);
//         }

//         /* Verify market's block number equals current block number */
//         if (accrualBlockNumber != getBlockNumber()) {
//             return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
//         }

//         MintLocalVars memory vars;

//         (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr)), 0);
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /*
//          *  We call `doTransferIn` for the minter and the mintAmount.
//          *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
//          *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
//          *  side-effects occurred. The function returns the amount actually transferred,
//          *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
//          *  of cash.
//          */
//         vars.actualMintAmount = doTransferIn(minter, mintAmount);

//         /*
//          * We get the current exchange rate and calculate the number of cTokens to be minted:
//          *  mintTokens = actualMintAmount / exchangeRate
//          */

//         (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa: vars.exchangeRateMantissa}));
//         require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");

//         /*
//          * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
//          *  totalSupplyNew = totalSupply + mintTokens
//          *  accountTokensNew = accountTokens[minter] + mintTokens
//          */
//         (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
//         require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

//         (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
//         require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

//         /* We write previously calculated values into storage */
//         totalSupply = vars.totalSupplyNew;
//         accountTokens[minter] = vars.accountTokensNew;

//         /* We emit a Mint event, and a Transfer event */
//         emit Mint(minter, vars.actualMintAmount, vars.mintTokens);
//         emit Transfer(address(this), minter, vars.mintTokens);

//         /* We call the defense hook */
//         comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

//         return (uint(Error.NO_ERROR), vars.actualMintAmount);
//     }

//     /**
//      * @notice Sender redeems cTokens in exchange for the underlying asset
//      * @dev Accrues interest whether or not the operation succeeds, unless reverted
//      * @param redeemTokens The number of cTokens to redeem into underlying
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function redeemInternal(uint redeemTokens) internal nonReentrant returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
//             return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
//         }
//         // redeemFresh emits redeem-specific logs on errors, so we don't need to
//         return redeemFresh(msg.sender, redeemTokens, 0);
//     }

//     /**
//      * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
//      * @dev Accrues interest whether or not the operation succeeds, unless reverted
//      * @param redeemAmount The amount of underlying to receive from redeeming cTokens
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
//             return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
//         }
//         // redeemFresh emits redeem-specific logs on errors, so we don't need to
//         return redeemFresh(msg.sender, 0, redeemAmount);
//     }

//     struct RedeemLocalVars {
//         Error err;
//         MathError mathErr;
//         uint exchangeRateMantissa;
//         uint redeemTokens;
//         uint redeemAmount;
//         uint totalSupplyNew;
//         uint accountTokensNew;
//     }

//     /**
//      * @notice User redeems cTokens in exchange for the underlying asset
//      * @dev Assumes interest has already been accrued up to the current block
//      * @param redeemer The address of the account which is redeeming the tokens
//      * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
//      * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {
//         require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

//         RedeemLocalVars memory vars;

//         /* exchangeRate = invoke Exchange Rate Stored() */
//         (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
//         }

//         /* If redeemTokensIn > 0: */
//         if (redeemTokensIn > 0) {
//             /*
//              * We calculate the exchange rate and the amount of underlying to be redeemed:
//              *  redeemTokens = redeemTokensIn
//              *  redeemAmount = redeemTokensIn x exchangeRateCurrent
//              */
//             vars.redeemTokens = redeemTokensIn;

//             (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), redeemTokensIn);
//             if (vars.mathErr != MathError.NO_ERROR) {
//                 return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
//             }
//         } else {
//             /*
//              * We get the current exchange rate and calculate the amount to be redeemed:
//              *  redeemTokens = redeemAmountIn / exchangeRate
//              *  redeemAmount = redeemAmountIn
//              */

//             (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa: vars.exchangeRateMantissa}));
//             if (vars.mathErr != MathError.NO_ERROR) {
//                 return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
//             }

//             vars.redeemAmount = redeemAmountIn;
//         }

//         /* Fail if redeem not allowed */
//         uint allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
//         if (allowed != 0) {
//             return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
//         }

//         /* Verify market's block number equals current block number */
//         if (accrualBlockNumber != getBlockNumber()) {
//             return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
//         }

//         /*
//          * We calculate the new total supply and redeemer balance, checking for underflow:
//          *  totalSupplyNew = totalSupply - redeemTokens
//          *  accountTokensNew = accountTokens[redeemer] - redeemTokens
//          */
//         (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
//         }

//         (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
//         }

//         /* Fail gracefully if protocol has insufficient cash */
//         if (getCashPrior() < vars.redeemAmount) {
//             return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /*
//          * We invoke doTransferOut for the redeemer and the redeemAmount.
//          *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
//          *  On success, the cToken has redeemAmount less of cash.
//          *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
//          */
//         doTransferOut(redeemer, vars.redeemAmount);

//         /* We write previously calculated values into storage */
//         totalSupply = vars.totalSupplyNew;
//         accountTokens[redeemer] = vars.accountTokensNew;

//         /* We emit a Transfer event, and a Redeem event */
//         emit Transfer(redeemer, address(this), vars.redeemTokens);
//         emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);

//         /* We call the defense hook */
//         comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//       * @notice Sender borrows assets from the protocol to their own address
//       * @param borrowAmount The amount of the underlying asset to borrow
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function borrowInternal(uint borrowAmount) internal nonReentrant returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
//             return fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED);
//         }
//         // borrowFresh emits borrow-specific logs on errors, so we don't need to
//         return borrowFresh(msg.sender, borrowAmount);
//     }

//     struct BorrowLocalVars {
//         MathError mathErr;
//         uint accountBorrows;
//         uint accountBorrowsNew;
//         uint totalBorrowsNew;
//     }

//     /**
//       * @notice Users borrow assets from the protocol to their own address
//       * @param borrowAmount The amount of the underlying asset to borrow
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function borrowFresh(address payable borrower, uint borrowAmount) internal returns (uint) {
//         /* Fail if borrow not allowed */
//         uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
//         if (allowed != 0) {
//             return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.BORROW_COMPTROLLER_REJECTION, allowed);
//         }

//         /* Verify market's block number equals current block number */
//         if (accrualBlockNumber != getBlockNumber()) {
//             return fail(Error.MARKET_NOT_FRESH, FailureInfo.BORROW_FRESHNESS_CHECK);
//         }

//         /* Fail gracefully if protocol has insufficient underlying cash */
//         if (getCashPrior() < borrowAmount) {
//             return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE);
//         }

//         BorrowLocalVars memory vars;

//         /*
//          * We calculate the new borrower and total borrow balances, failing on overflow:
//          *  accountBorrowsNew = accountBorrows + borrowAmount
//          *  totalBorrowsNew = totalBorrows + borrowAmount
//          */
//         (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
//         }

//         (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
//         }

//         (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /*
//          * We invoke doTransferOut for the borrower and the borrowAmount.
//          *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
//          *  On success, the cToken borrowAmount less of cash.
//          *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
//          */
//         doTransferOut(borrower, borrowAmount);

//         /* We write the previously calculated values into storage */
//         accountBorrows[borrower].principal = vars.accountBorrowsNew;
//         accountBorrows[borrower].interestIndex = borrowIndex;
//         totalBorrows = vars.totalBorrowsNew;

//         /* We emit a Borrow event */
//         emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

//         /* We call the defense hook */
//         comptroller.borrowVerify(address(this), borrower, borrowAmount);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice Sender repays their own borrow
//      * @param repayAmount The amount to repay
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
//      */
//     function repayBorrowInternal(uint repayAmount) internal nonReentrant returns (uint, uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
//             return (fail(Error(error), FailureInfo.REPAY_BORROW_ACCRUE_INTEREST_FAILED), 0);
//         }
//         // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
//         return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
//     }

//     /**
//      * @notice Sender repays a borrow belonging to borrower
//      * @param borrower the account with the debt being payed off
//      * @param repayAmount The amount to repay
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
//      */
//     function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint, uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
//             return (fail(Error(error), FailureInfo.REPAY_BEHALF_ACCRUE_INTEREST_FAILED), 0);
//         }
//         // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
//         return repayBorrowFresh(msg.sender, borrower, repayAmount);
//     }

//     struct RepayBorrowLocalVars {
//         Error err;
//         MathError mathErr;
//         uint repayAmount;
//         uint borrowerIndex;
//         uint accountBorrows;
//         uint accountBorrowsNew;
//         uint totalBorrowsNew;
//         uint actualRepayAmount;
//     }

//     /**
//      * @notice Borrows are repaid by another user (possibly the borrower).
//      * @param payer the account paying off the borrow
//      * @param borrower the account with the debt being payed off
//      * @param repayAmount the amount of undelrying tokens being returned
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
//      */
//     function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
//         /* Fail if repayBorrow not allowed */
//         uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
//         if (allowed != 0) {
//             return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REPAY_BORROW_COMPTROLLER_REJECTION, allowed), 0);
//         }

//         /* Verify market's block number equals current block number */
//         if (accrualBlockNumber != getBlockNumber()) {
//             return (fail(Error.MARKET_NOT_FRESH, FailureInfo.REPAY_BORROW_FRESHNESS_CHECK), 0);
//         }

//         RepayBorrowLocalVars memory vars;

//         /* We remember the original borrowerIndex for verification purposes */
//         vars.borrowerIndex = accountBorrows[borrower].interestIndex;

//         /* We fetch the amount the borrower owes, with accumulated interest */
//         (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
//         if (vars.mathErr != MathError.NO_ERROR) {
//             return (failOpaque(Error.MATH_ERROR, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
//         }

//         /* If repayAmount == -1, repayAmount = accountBorrows */
//         if (repayAmount == uint(-1)) {
//             vars.repayAmount = vars.accountBorrows;
//         } else {
//             vars.repayAmount = repayAmount;
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /*
//          * We call doTransferIn for the payer and the repayAmount
//          *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
//          *  On success, the cToken holds an additional repayAmount of cash.
//          *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
//          *   it returns the amount actually transferred, in case of a fee.
//          */
//         vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

//         /*
//          * We calculate the new borrower and total borrow balances, failing on underflow:
//          *  accountBorrowsNew = accountBorrows - actualRepayAmount
//          *  totalBorrowsNew = totalBorrows - actualRepayAmount
//          */
//         (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
//         require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

//         (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
//         require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

//         /* We write the previously calculated values into storage */
//         accountBorrows[borrower].principal = vars.accountBorrowsNew;
//         accountBorrows[borrower].interestIndex = borrowIndex;
//         totalBorrows = vars.totalBorrowsNew;

//         /* We emit a RepayBorrow event */
//         emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew);

//         /* We call the defense hook */
//         comptroller.repayBorrowVerify(address(this), payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

//         return (uint(Error.NO_ERROR), vars.actualRepayAmount);
//     }

//     /**
//      * @notice The sender liquidates the borrowers collateral.
//      *  The collateral seized is transferred to the liquidator.
//      * @param borrower The borrower of this cToken to be liquidated
//      * @param cTokenCollateral The market in which to seize collateral from the borrower
//      * @param repayAmount The amount of the underlying borrowed asset to repay
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
//      */
//     function liquidateBorrowInternal(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal nonReentrant returns (uint, uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
//             return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED), 0);
//         }

//         error = cTokenCollateral.accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
//             return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
//         }

//         // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
//         return liquidateBorrowFresh(msg.sender, borrower, repayAmount, cTokenCollateral);
//     }

//     /**
//      * @notice The liquidator liquidates the borrowers collateral.
//      *  The collateral seized is transferred to the liquidator.
//      * @param borrower The borrower of this cToken to be liquidated
//      * @param liquidator The address repaying the borrow and seizing collateral
//      * @param cTokenCollateral The market in which to seize collateral from the borrower
//      * @param repayAmount The amount of the underlying borrowed asset to repay
//      * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
//      */
//     function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, CTokenInterface cTokenCollateral) internal returns (uint, uint) {
//         /* Fail if liquidate not allowed */
//         uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(cTokenCollateral), liquidator, borrower, repayAmount);
//         if (allowed != 0) {
//             return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
//         }

//         /* Verify market's block number equals current block number */
//         if (accrualBlockNumber != getBlockNumber()) {
//             return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_FRESHNESS_CHECK), 0);
//         }

//         /* Verify cTokenCollateral market's block number equals current block number */
//         if (cTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
//             return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
//         }

//         /* Fail if borrower = liquidator */
//         if (borrower == liquidator) {
//             return (fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
//         }

//         /* Fail if repayAmount = 0 */
//         if (repayAmount == 0) {
//             return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
//         }

//         /* Fail if repayAmount = -1 */
//         if (repayAmount == uint(-1)) {
//             return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
//         }


//         /* Fail if repayBorrow fails */
//         (uint repayBorrowError, uint actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);
//         if (repayBorrowError != uint(Error.NO_ERROR)) {
//             return (fail(Error(repayBorrowError), FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /* We calculate the number of collateral tokens that will be seized */
//         (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(cTokenCollateral), actualRepayAmount);
//         require(amountSeizeError == uint(Error.NO_ERROR), "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

//         /* Revert if borrower collateral token balance < seizeTokens */
//         require(cTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

//         // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
//         uint seizeError;
//         if (address(cTokenCollateral) == address(this)) {
//             seizeError = seizeInternal(address(this), liquidator, borrower, seizeTokens);
//         } else {
//             seizeError = cTokenCollateral.seize(liquidator, borrower, seizeTokens);
//         }

//         /* Revert if seize tokens fails (since we cannot be sure of side effects) */
//         require(seizeError == uint(Error.NO_ERROR), "token seizure failed");

//         /* We emit a LiquidateBorrow event */
//         emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(cTokenCollateral), seizeTokens);

//         /* We call the defense hook */
//         comptroller.liquidateBorrowVerify(address(this), address(cTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

//         return (uint(Error.NO_ERROR), actualRepayAmount);
//     }

//     /**
//      * @notice Transfers collateral tokens (this market) to the liquidator.
//      * @dev Will fail unless called by another cToken during the process of liquidation.
//      *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
//      * @param liquidator The account receiving seized collateral
//      * @param borrower The account having collateral seized
//      * @param seizeTokens The number of cTokens to seize
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function seize(address liquidator, address borrower, uint seizeTokens) external nonReentrant returns (uint) {
//         return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
//     }

//     /**
//      * @notice Transfers collateral tokens (this market) to the liquidator.
//      * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
//      *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
//      * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
//      * @param liquidator The account receiving seized collateral
//      * @param borrower The account having collateral seized
//      * @param seizeTokens The number of cTokens to seize
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal returns (uint) {
//         /* Fail if seize not allowed */
//         uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
//         if (allowed != 0) {
//             return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_SEIZE_COMPTROLLER_REJECTION, allowed);
//         }

//         /* Fail if borrower = liquidator */
//         if (borrower == liquidator) {
//             return fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
//         }

//         MathError mathErr;
//         uint borrowerTokensNew;
//         uint liquidatorTokensNew;

//         /*
//          * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
//          *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
//          *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
//          */
//         (mathErr, borrowerTokensNew) = subUInt(accountTokens[borrower], seizeTokens);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint(mathErr));
//         }

//         (mathErr, liquidatorTokensNew) = addUInt(accountTokens[liquidator], seizeTokens);
//         if (mathErr != MathError.NO_ERROR) {
//             return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint(mathErr));
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /* We write the previously calculated values into storage */
//         accountTokens[borrower] = borrowerTokensNew;
//         accountTokens[liquidator] = liquidatorTokensNew;

//         /* Emit a Transfer event */
//         emit Transfer(borrower, liquidator, seizeTokens);

//         /* We call the defense hook */
//         comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);

//         return uint(Error.NO_ERROR);
//     }


//     /*** Admin Functions ***/

//     /**
//       * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
//       * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
//       * @param newPendingAdmin New pending admin.
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function _setPendingAdmin(address payable newPendingAdmin) external returns (uint) {
//         // Check caller = admin
//         if (msg.sender != admin) {
//             return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_ADMIN_OWNER_CHECK);
//         }

//         // Save current value, if any, for inclusion in log
//         address oldPendingAdmin = pendingAdmin;

//         // Store pendingAdmin with value newPendingAdmin
//         pendingAdmin = newPendingAdmin;

//         // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
//         emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//       * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
//       * @dev Admin function for pending admin to accept role and update admin
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function _acceptAdmin() external returns (uint) {
//         // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
//         if (msg.sender != pendingAdmin || msg.sender == address(0)) {
//             return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_ADMIN_PENDING_ADMIN_CHECK);
//         }

//         // Save current values for inclusion in log
//         address oldAdmin = admin;
//         address oldPendingAdmin = pendingAdmin;

//         // Store admin with value pendingAdmin
//         admin = pendingAdmin;

//         // Clear the pending value
//         pendingAdmin = address(0);

//         emit NewAdmin(oldAdmin, admin);
//         emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//       * @notice Sets a new comptroller for the market
//       * @dev Admin function to set a new comptroller
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function _setComptroller(ComptrollerInterface newComptroller) public returns (uint) {
//         // Check caller is admin
//         if (msg.sender != admin) {
//             return fail(Error.UNAUTHORIZED, FailureInfo.SET_COMPTROLLER_OWNER_CHECK);
//         }

//         ComptrollerInterface oldComptroller = comptroller;
//         // Ensure invoke comptroller.isComptroller() returns true
//         require(newComptroller.isComptroller(), "marker method returned false");

//         // Set market's comptroller to newComptroller
//         comptroller = newComptroller;

//         // Emit NewComptroller(oldComptroller, newComptroller)
//         emit NewComptroller(oldComptroller, newComptroller);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//       * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
//       * @dev Admin function to accrue interest and set a new reserve factor
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function _setReserveFactor(uint newReserveFactorMantissa) external nonReentrant returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
//             return fail(Error(error), FailureInfo.SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED);
//         }
//         // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
//         return _setReserveFactorFresh(newReserveFactorMantissa);
//     }

//     /**
//       * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
//       * @dev Admin function to set a new reserve factor
//       * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//       */
//     function _setReserveFactorFresh(uint newReserveFactorMantissa) internal returns (uint) {
//         // Check caller is admin
//         if (msg.sender != admin) {
//             return fail(Error.UNAUTHORIZED, FailureInfo.SET_RESERVE_FACTOR_ADMIN_CHECK);
//         }

//         // Verify market's block number equals current block number
//         if (accrualBlockNumber != getBlockNumber()) {
//             return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
//         }

//         // Check newReserveFactor ≤ maxReserveFactor
//         if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
//             return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
//         }

//         uint oldReserveFactorMantissa = reserveFactorMantissa;
//         reserveFactorMantissa = newReserveFactorMantissa;

//         emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice Accrues interest and reduces reserves by transferring from msg.sender
//      * @param addAmount Amount of addition to reserves
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
//             return fail(Error(error), FailureInfo.ADD_RESERVES_ACCRUE_INTEREST_FAILED);
//         }

//         // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
//         (error, ) = _addReservesFresh(addAmount);
//         return error;
//     }

//     /**
//      * @notice Add reserves by transferring from caller
//      * @dev Requires fresh interest accrual
//      * @param addAmount Amount of addition to reserves
//      * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
//      */
//     function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
//         // totalReserves + actualAddAmount
//         uint totalReservesNew;
//         uint actualAddAmount;

//         // We fail gracefully unless market's block number equals current block number
//         if (accrualBlockNumber != getBlockNumber()) {
//             return (fail(Error.MARKET_NOT_FRESH, FailureInfo.ADD_RESERVES_FRESH_CHECK), actualAddAmount);
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         /*
//          * We call doTransferIn for the caller and the addAmount
//          *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
//          *  On success, the cToken holds an additional addAmount of cash.
//          *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
//          *  it returns the amount actually transferred, in case of a fee.
//          */

//         actualAddAmount = doTransferIn(msg.sender, addAmount);

//         totalReservesNew = totalReserves + actualAddAmount;

//         /* Revert on overflow */
//         require(totalReservesNew >= totalReserves, "add reserves unexpected overflow");

//         // Store reserves[n+1] = reserves[n] + actualAddAmount
//         totalReserves = totalReservesNew;

//         /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
//         emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

//         /* Return (NO_ERROR, actualAddAmount) */
//         return (uint(Error.NO_ERROR), actualAddAmount);
//     }


//     /**
//      * @notice Accrues interest and reduces reserves by transferring to admin
//      * @param reduceAmount Amount of reduction to reserves
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function _reduceReserves(uint reduceAmount) external nonReentrant returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
//             return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
//         }
//         // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
//         return _reduceReservesFresh(reduceAmount);
//     }

//     /**
//      * @notice Reduces reserves by transferring to admin
//      * @dev Requires fresh interest accrual
//      * @param reduceAmount Amount of reduction to reserves
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function _reduceReservesFresh(uint reduceAmount) internal returns (uint) {
//         // totalReserves - reduceAmount
//         uint totalReservesNew;

//         // Check caller is admin
//         if (msg.sender != admin) {
//             return fail(Error.UNAUTHORIZED, FailureInfo.REDUCE_RESERVES_ADMIN_CHECK);
//         }

//         // We fail gracefully unless market's block number equals current block number
//         if (accrualBlockNumber != getBlockNumber()) {
//             return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
//         }

//         // Fail gracefully if protocol has insufficient underlying cash
//         if (getCashPrior() < reduceAmount) {
//             return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
//         }

//         // Check reduceAmount ≤ reserves[n] (totalReserves)
//         if (reduceAmount > totalReserves) {
//             return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
//         }

//         /////////////////////////
//         // EFFECTS & INTERACTIONS
//         // (No safe failures beyond this point)

//         totalReservesNew = totalReserves - reduceAmount;
//         // We checked reduceAmount <= totalReserves above, so this should never revert.
//         require(totalReservesNew <= totalReserves, "reduce reserves unexpected underflow");

//         // Store reserves[n+1] = reserves[n] - reduceAmount
//         totalReserves = totalReservesNew;

//         // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
//         doTransferOut(admin, reduceAmount);

//         emit ReservesReduced(admin, reduceAmount, totalReservesNew);

//         return uint(Error.NO_ERROR);
//     }

//     /**
//      * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
//      * @dev Admin function to accrue interest and update the interest rate model
//      * @param newInterestRateModel the new interest rate model to use
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint) {
//         uint error = accrueInterest();
//         if (error != uint(Error.NO_ERROR)) {
//             // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted change of interest rate model failed
//             return fail(Error(error), FailureInfo.SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED);
//         }
//         // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
//         return _setInterestRateModelFresh(newInterestRateModel);
//     }

//     /**
//      * @notice updates the interest rate model (*requires fresh interest accrual)
//      * @dev Admin function to update the interest rate model
//      * @param newInterestRateModel the new interest rate model to use
//      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
//      */
//     function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal returns (uint) {

//         // Used to store old model for use in the event that is emitted on success
//         InterestRateModel oldInterestRateModel;

//         // Check caller is admin
//         if (msg.sender != admin) {
//             return fail(Error.UNAUTHORIZED, FailureInfo.SET_INTEREST_RATE_MODEL_OWNER_CHECK);
//         }

//         // We fail gracefully unless market's block number equals current block number
//         if (accrualBlockNumber != getBlockNumber()) {
//             return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
//         }

//         // Track the market's current interest rate model
//         oldInterestRateModel = interestRateModel;

//         // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
//         require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

//         // Set the interest rate model to newInterestRateModel
//         interestRateModel = newInterestRateModel;

//         // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
//         emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

//         return uint(Error.NO_ERROR);
//     }

//     /*** Safe Token ***/

//     /**
//      * @notice Gets balance of this contract in terms of the underlying
//      * @dev This excludes the value of the current message, if any
//      * @return The quantity of underlying owned by this contract
//      */
//     function getCashPrior() internal view returns (uint);

//     /**
//      * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
//      *  This may revert due to insufficient balance or insufficient allowance.
//      */
//     function doTransferIn(address from, uint amount) internal returns (uint);

//     /**
//      * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
//      *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
//      *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
//      */
//     function doTransferOut(address payable to, uint amount) internal;


//     /*** Reentrancy Guard ***/

//     /**
//      * @dev Prevents a contract from calling itself, directly or indirectly.
//      */
//     modifier nonReentrant() {
//         require(_notEntered, "re-entered");
//         _notEntered = false;
//         _;
//         _notEntered = true; // get a gas-refund post-Istanbul
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// FPT-FRAX: Original at https://etherscan.io/address/0x9d7beb4265817a4923fad9ca9ef8af138499615d
// Some functions were omitted for brevity. See the contract for details

interface IFNX_CFNX is IERC20 {
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// FPT-FRAX: Original at https://etherscan.io/address/0x39ad661bA8a7C9D3A7E4808fb9f9D5223E22F763
// FPT-B (FNX): Original at https://etherscan.io/address/0x7E605Fb638983A448096D82fFD2958ba012F30Cd
// Some functions were omitted for brevity. See the contract for details

interface IFNX_FPT_FRAX is IERC20 {
    /**
     * @dev Retrieve user's start time for burning. 
     *  user user's account.
     */ 
    function getUserBurnTimeLimite(address /*user*/) external view returns (uint256);

    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() external view returns (uint256);

    /**
     * @dev Retrieve user's locked balance. 
     *  account user's account.
     */ 
    function lockedBalanceOf(address /*account*/) external view returns (uint256);

    /**
     * @dev Retrieve user's locked net worth. 
     *  account user's account.
     */ 
    function lockedWorthOf(address /*account*/) external view returns (uint256);

    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     *  account user's account.
     */ 
    function getLockedBalance(address /*account*/) external view returns (uint256,uint256);

    /**
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     *  account user's account.
     *  amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address /*account*/,uint256 /*amount*/) external;

    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     *  account user's account.
     *  amount amount of locked FPT.
     *  lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address /*account*/, uint256 /*amount*/,uint256 /*lockedWorth*/) external;

    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function burn(address /*account*/, uint256 /*amount*/) external;

    /**
     * @dev mint user's FPT when user add collateral. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function mint(address /*account*/, uint256 /*amount*/) external;

    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     *  account user's account.
     *  tokenAmount amount of FPT.
     *  leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address /*account*/,uint256 /*tokenAmount*/,uint256 /*leftCollateral*/) external returns (uint256,uint256);

    // Get the mining pool address
    function getFNXMinePoolAddress() external view returns(address);

    /**
     * @dev FPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn FPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    function getTimeLimitation() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// FPT-FRAX: Original at https://etherscan.io/address/0x39ad661bA8a7C9D3A7E4808fb9f9D5223E22F763
// FPT-B (FNX): Original at https://etherscan.io/address/0x7E605Fb638983A448096D82fFD2958ba012F30Cd
// Some functions were omitted for brevity. See the contract for details

interface IFNX_FPT_B is IERC20 {
    /**
     * @dev Retrieve user's start time for burning. 
     *  user user's account.
     */ 
    function getUserBurnTimeLimite(address /*user*/) external view returns (uint256);

    /**
     * @dev Retrieve total locked worth. 
     */ 
    function getTotalLockedWorth() external view returns (uint256);

    /**
     * @dev Retrieve user's locked balance. 
     *  account user's account.
     */ 
    function lockedBalanceOf(address /*account*/) external view returns (uint256);

    /**
     * @dev Retrieve user's locked net worth. 
     *  account user's account.
     */ 
    function lockedWorthOf(address /*account*/) external view returns (uint256);

    /**
     * @dev Retrieve user's locked balance and locked net worth. 
     *  account user's account.
     */ 
    function getLockedBalance(address /*account*/) external view returns (uint256,uint256);

    /**
     * @dev Interface to manager FNX mine pool contract, add miner balance when user has bought some options. 
     *  account user's account.
     *  amount user's pay for buying options, priced in USD.
     */ 
    function addMinerBalance(address /*account*/,uint256 /*amount*/) external;

    /**
     * @dev Move user's FPT to locked balance, when user redeem collateral. 
     *  account user's account.
     *  amount amount of locked FPT.
     *  lockedWorth net worth of locked FPT.
     */ 
    function addlockBalance(address /*account*/, uint256 /*amount*/,uint256 /*lockedWorth*/) external;

    /**
     * @dev burn user's FPT when user redeem FPTCoin. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function burn(address /*account*/, uint256 /*amount*/) external;

    /**
     * @dev mint user's FPT when user add collateral. 
     *  account user's account.
     *  amount amount of FPT.
     */ 
    function mint(address /*account*/, uint256 /*amount*/) external;

    /**
     * @dev An interface of redeem locked FPT, when user redeem collateral, only manager contract can invoke. 
     *  account user's account.
     *  tokenAmount amount of FPT.
     *  leftCollateral left available collateral in collateral pool, priced in USD.
     */ 
    function redeemLockedCollateral(address /*account*/,uint256 /*tokenAmount*/,uint256 /*leftCollateral*/) external returns (uint256,uint256);

    // Get the mining pool address
    function getFNXMinePoolAddress() external view returns(address);

    /**
     * @dev FPT has burn time limit. When user's balance is moved in som coins, he will wait `timeLimited` to burn FPT. 
     * latestTransferIn is user's latest time when his balance is moved in.
     */
    function getTimeLimitation() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// Original at https://etherscan.io/address/0x23e54F9bBe26eD55F93F19541bC30AAc2D5569b2
// Some functions were omitted for brevity. See the contract for details

interface IFNX_IntegratedStake {
    function stake(address[] memory fpta_tokens,uint256[] memory fpta_amounts,
            address[] memory fptb_tokens, uint256[] memory fptb_amounts,uint256 lockedPeriod) external;

}


// contract integratedStake is Ownable{
//     using SafeERC20 for IERC20;
//     address public _FPTA;
//     address public _FPTB;
//     address public _FPTAColPool;//the option manager address
//     address public _FPTBColPool;//the option manager address
//     address public _minePool;    //the fixed minePool address
//     mapping (address=>bool) approveMapA;
//     mapping (address=>bool) approveMapB;
//     uint256  constant internal MAX_UINT = (2**256 - 1); 
//     /**
//      * @dev constructor.
//      */
//     constructor(address FPTA,address FPTB,address FPTAColPool,address FPTBColPool,address minePool)public{
//         setAddress(FPTA,FPTB,FPTAColPool,FPTBColPool,minePool);
//     }
//     function setAddress(address FPTA,address FPTB,address FPTAColPool,address FPTBColPool,address minePool) onlyOwner public{
//         _FPTA = FPTA;
//         _FPTB = FPTB;
//         _FPTAColPool = FPTAColPool;
//         _FPTBColPool = FPTBColPool;
//         _minePool = minePool;
//         if (IERC20(_FPTA).allowance(msg.sender, _minePool) == 0){
//             IERC20(_FPTA).safeApprove(_minePool,MAX_UINT);
//         }
//         if (IERC20(_FPTB).allowance(msg.sender, _minePool) == 0){
//             IERC20(_FPTB).safeApprove(_minePool,MAX_UINT);
//         }
//     }
//     function stake(address[] memory fpta_tokens,uint256[] memory fpta_amounts,
//             address[] memory fptb_tokens,uint256[] memory fptb_amounts,uint256 lockedPeriod) public{
//         require(fpta_tokens.length==fpta_amounts.length && fptb_tokens.length==fptb_amounts.length,"the input array length is not equal");
//         uint256 i = 0;
//         for(i = 0;i<fpta_tokens.length;i++) {
//             if (!approveMapA[fpta_tokens[i]]){
//                 IERC20(fpta_tokens[i]).safeApprove(_FPTAColPool,MAX_UINT);
//                 approveMapA[fpta_tokens[i]] = true;
//             }
//             uint256 amount = getPayableAmount(fpta_tokens[i],fpta_amounts[i]);
//             IOptionMgrPoxy(_FPTAColPool).addCollateral(fpta_tokens[i],amount);
//             IERC20(_FPTA).safeTransfer(msg.sender,0);
//         }
//         for(i = 0;i<fptb_tokens.length;i++) {
//             if (!approveMapB[fptb_tokens[i]]){
//                 IERC20(fptb_tokens[i]).safeApprove(_FPTBColPool,MAX_UINT);
//                 approveMapB[fptb_tokens[i]] = true;
//             }
//             uint256 amount = getPayableAmount(fptb_tokens[i],fptb_amounts[i]);
//             IOptionMgrPoxy(_FPTBColPool).addCollateral(fptb_tokens[i],amount);
//             IERC20(_FPTB).safeTransfer(msg.sender,0);
//         }
//         IMinePool(_minePool).lockAirDrop(msg.sender,lockedPeriod);
//     }
//     /**
//      * @dev Auxiliary function. getting user's payment
//      * @param settlement user's payment coin.
//      * @param settlementAmount user's payment amount.
//      */
//     function getPayableAmount(address settlement,uint256 settlementAmount) internal returns (uint256) {
//         if (settlement == address(0)){
//             settlementAmount = msg.value;
//         }else if (settlementAmount > 0){
//             IERC20 oToken = IERC20(settlement);
//             uint256 preBalance = oToken.balanceOf(address(this));
//             oToken.safeTransferFrom(msg.sender, address(this), settlementAmount);
//             //oToken.transferFrom(msg.sender, address(this), settlementAmount);
//             uint256 afterBalance = oToken.balanceOf(address(this));
//             require(afterBalance-preBalance==settlementAmount,"settlement token transfer error!");
//         }
//         return settlementAmount;
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// Original at https://etherscan.io/address/0x4e6005396F80a737cE80d50B2162C0a7296c9620
// Some functions were omitted for brevity. See the contract for details

interface IFNX_MinePool {
    /**
     * @dev getting function. Retrieve FPT-A coin's address
     */
    function getFPTAAddress() external view returns (address);
    /**
     * @dev getting function. Retrieve FPT-B coin's address
     */
    function getFPTBAddress() external view returns (address);
    /**
     * @dev getting function. Retrieve mine pool's start time.
     */
    function getStartTime() external view returns (uint256);
    /**
     * @dev getting current mine period ID.
     */
    function getCurrentPeriodID() external view returns (uint256);
    /**
     * @dev getting user's staking FPT-A balance.
     * account user's account
     */
    function getUserFPTABalance(address /*account*/) external view returns (uint256);
    /**
     * @dev getting user's staking FPT-B balance.
     * account user's account
     */
    function getUserFPTBBalance(address /*account*/) external view returns (uint256);
    /**
     * @dev getting user's maximium locked period ID.
     * account user's account
     */
    function getUserMaxPeriodId(address /*account*/) external view returns (uint256);
    /**
     * @dev getting user's locked expired time. After this time user can unstake FPTB coins.
     * account user's account
     */
    function getUserExpired(address /*account*/) external view returns (uint256);
    function getCurrentTotalAPY(address /*mineCoin*/) external view returns (uint256);
    /**
     * @dev Calculate user's current APY.
     * account user's account.
     * mineCoin mine coin address
     */
    function getUserCurrentAPY(address /*account*/,address /*mineCoin*/) external view returns (uint256);
    function getAverageLockedTime() external view returns (uint256);
    /**
     * @dev foundation redeem out mine coins.
     *  mineCoin mineCoin address
     *  amount redeem amount.
     */
    function redeemOut(address /*mineCoin*/,uint256 /*amount*/) external;
    /**
     * @dev retrieve total distributed mine coins.
     *  mineCoin mineCoin address
     */
    function getTotalMined(address /*mineCoin*/) external view returns(uint256);
    /**
     * @dev retrieve minecoin distributed informations.
     *  mineCoin mineCoin address
     * @return distributed amount and distributed time interval.
     */
    function getMineInfo(address /*mineCoin*/) external view returns(uint256,uint256);
    /**
     * @dev retrieve user's mine balance.
     *  account user's account
     *  mineCoin mineCoin address
     */
    function getMinerBalance(address /*account*/,address /*mineCoin*/) external view returns(uint256);
    /**
     * @dev Set mineCoin mine info, only foundation owner can invoked.
     *  mineCoin mineCoin address
     *  _mineAmount mineCoin distributed amount
     *  _mineInterval mineCoin distributied time interval
     */
    function setMineCoinInfo(address /*mineCoin*/,uint256 /*_mineAmount*/,uint256 /*_mineInterval*/) external ;

    /**
     * @dev user redeem mine rewards.
     *  mineCoin mine coin address
     *  amount redeem amount.
     */
    function redeemMinerCoin(address /*mineCoin*/,uint256 /*amount*/) external;
    /**
     * @dev getting whole pool's mine production weight ratio.
     *      Real mine production equals base mine production multiply weight ratio.
     */
    function getMineWeightRatio() external view returns (uint256);
    /**
     * @dev getting whole pool's mine shared distribution. All these distributions will share base mine production.
     */
    function getTotalDistribution() external view returns (uint256);
    /**
     * @dev convert timestamp to period ID.
     * _time timestamp. 
     */ 
    function getPeriodIndex(uint256 /*_time*/) external view returns (uint256);
    /**
     * @dev convert period ID to period's finish timestamp.
     * periodID period ID. 
     */
    function getPeriodFinishTime(uint256 /*periodID*/) external view returns (uint256);
    /**
     * @dev Stake FPT-A coin and get distribution for mining.
     * amount FPT-A amount that transfer into mine pool.
     */
    function stakeFPTA(uint256 /*amount*/) external ;
    /**
     * @dev Air drop to user some FPT-B coin and lock one period and get distribution for mining.
     * user air drop's recieptor.
     * ftp_b_amount FPT-B amount that transfer into mine pool.
     */
    function lockAirDrop(address /*user*/,uint256 /*ftp_b_amount*/) external;
    /**
     * @dev Stake FPT-B coin and lock locedPreiod and get distribution for mining.
     * amount FPT-B amount that transfer into mine pool.
     * lockedPeriod locked preiod number.
     */
    function stakeFPTB(uint256 /*amount*/,uint256 /*lockedPeriod*/) external;
    /**
     * @dev withdraw FPT-A coin.
     * amount FPT-A amount that withdraw from mine pool.
     */
    function unstakeFPTA(uint256 /*amount*/) external ;
    /**
     * @dev withdraw FPT-B coin.
     * amount FPT-B amount that withdraw from mine pool.
     */
    function unstakeFPTB(uint256 /*amount*/) external;
    /**
     * @dev Add FPT-B locked period.
     * lockedPeriod FPT-B locked preiod number.
     */
    function changeFPTBLockedPeriod(uint256 /*lockedPeriod*/) external;

       /**
     * @dev retrieve total distributed premium coins.
     */
    function getTotalPremium() external view returns(uint256);
    /**
     * @dev user redeem his options premium rewards.
     */
    function redeemPremium() external;
    /**
     * @dev user redeem his options premium rewards.
     * amount redeem amount.
     */
    function redeemPremiumCoin(address /*premiumCoin*/,uint256 /*amount*/) external;
    /**
     * @dev get user's premium balance.
     * account user's account
     */ 
    function getUserLatestPremium(address /*account*/,address /*premiumCoin*/) external view returns(uint256);
 
    /**
     * @dev Distribute premium from foundation.
     * periodID period ID
     * amount premium amount.
     */ 
    function distributePremium(address /*premiumCoin*/,uint256 /*periodID*/,uint256 /*amount*/) external ;
}

// /**
//  *Submitted for verification at Etherscan.io on 2021-01-26
// */

// // File: contracts\Proxy\newBaseProxy.sol

// pragma solidity =0.5.16;
// /**
//  * @title  newBaseProxy Contract

//  */
// contract newBaseProxy {
//     bytes32 private constant implementPositon = keccak256("org.Finnexus.implementation.storage");
//     bytes32 private constant proxyOwnerPosition  = keccak256("org.Finnexus.Owner.storage");
//     constructor(address implementation_) public {
//         // Creator of the contract is admin during initialization
//         _setProxyOwner(msg.sender);
//         _setImplementation(implementation_);
//         (bool success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
//         require(success);
//     }
//     /**
//      * @dev Allows the current owner to transfer ownership
//      * @param _newOwner The address to transfer ownership to
//      */
//     function transferProxyOwnership(address _newOwner) public onlyProxyOwner 
//     {
//         require(_newOwner != address(0));
//         _setProxyOwner(_newOwner);
//     }
//     function _setProxyOwner(address _newOwner) internal 
//     {
//         bytes32 position = proxyOwnerPosition;
//         assembly {
//             sstore(position, _newOwner)
//         }
//     }
//     function proxyOwner() public view returns (address owner) {
//         bytes32 position = proxyOwnerPosition;
//         assembly {
//             owner := sload(position)
//         }
//     }
//     /**
//      * @dev Tells the address of the current implementation
//      * @return address of the current implementation
//      */
//     function getImplementation() public view returns (address impl) {
//         bytes32 position = implementPositon;
//         assembly {
//             impl := sload(position)
//         }
//     }
//     function _setImplementation(address _newImplementation) internal 
//     {
//         bytes32 position = implementPositon;
//         assembly {
//             sstore(position, _newImplementation)
//         }
//     }
//     function setImplementation(address _newImplementation)public onlyProxyOwner{
//         address currentImplementation = getImplementation();
//         require(currentImplementation != _newImplementation);
//         _setImplementation(_newImplementation);
//         (bool success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
//         require(success);
//     }

//     /**
//      * @notice Delegates execution to the implementation contract
//      * @dev It returns to the external caller whatever the implementation returns or forwards reverts
//      * @param data The raw data to delegatecall
//      * @return The returned bytes from the delegatecall
//      */
//     function delegateToImplementation(bytes memory data) public returns (bytes memory) {
//         (bool success, bytes memory returnData) = getImplementation().delegatecall(data);
//         assembly {
//             if eq(success, 0) {
//                 revert(add(returnData, 0x20), returndatasize)
//             }
//         }
//         return returnData;
//     }

//     /**
//      * @notice Delegates execution to an implementation contract
//      * @dev It returns to the external caller whatever the implementation returns or forwards reverts
//      *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
//      * @param data The raw data to delegatecall
//      * @return The returned bytes from the delegatecall
//      */
//     function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
//         (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
//         assembly {
//             if eq(success, 0) {
//                 revert(add(returnData, 0x20), returndatasize)
//             }
//         }
//         return abi.decode(returnData, (bytes));
//     }

//     function delegateToViewAndReturn() internal view returns (bytes memory) {
//         (bool success, ) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", msg.data));

//         assembly {
//             let free_mem_ptr := mload(0x40)
//             returndatacopy(free_mem_ptr, 0, returndatasize)

//             switch success
//             case 0 { revert(free_mem_ptr, returndatasize) }
//             default { return(add(free_mem_ptr, 0x40), sub(returndatasize, 0x40)) }
//         }
//     }

//     function delegateAndReturn() internal returns (bytes memory) {
//         (bool success, ) = getImplementation().delegatecall(msg.data);

//         assembly {
//             let free_mem_ptr := mload(0x40)
//             returndatacopy(free_mem_ptr, 0, returndatasize)

//             switch success
//             case 0 { revert(free_mem_ptr, returndatasize) }
//             default { return(free_mem_ptr, returndatasize) }
//         }
//     }
//         /**
//     * @dev Throws if called by any account other than the owner.
//     */
//     modifier onlyProxyOwner() {
//         require (msg.sender == proxyOwner());
//         _;
//     }
// }

// // File: contracts\fixedMinePool\fixedMinePoolProxy.sol

// pragma solidity =0.5.16;


// /**
//  * @title FNX period mine pool.
//  * @dev A smart-contract which distribute some mine coins when user stake FPT-A and FPT-B coins.
//  *
//  */
// contract fixedMinePoolProxy is newBaseProxy {
//     /**
//     * @dev constructor.
//     * FPTA FPT-A coin's address,staking coin
//     * FPTB FPT-B coin's address,staking coin
//     * startTime the start time when this mine pool begin.
//     */
//     constructor (address implementation_,address FPTA,address FPTB,uint256 startTime) newBaseProxy(implementation_) public{
//         (bool success,) = implementation_.delegatecall(abi.encodeWithSignature(
//                 "setAddresses(address,address,uint256)",
//                 FPTA,
//                 FPTB,
//                 startTime));
//         require(success);
//     }
//         /**
//      * @dev default function for foundation input miner coins.
//      */
//     function()external payable{

//     }
//         /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view returns (address) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev Returns true if the caller is the current owner.
//      */
//     function isOwner() public view returns (bool) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public {
//         delegateAndReturn();
//     }
//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address /*newOwner*/) public {
//         delegateAndReturn();
//     }
//     function setHalt(bool /*halt*/) public  {
//         delegateAndReturn();
//     }
//      function addWhiteList(address /*addAddress*/)public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev Implementation of revoke an invalid address from the whitelist.
//      *  removeAddress revoked address.
//      */
//     function removeWhiteList(address /*removeAddress*/)public returns (bool){
//         delegateAndReturn();
//     }
//     /**
//      * @dev Implementation of getting the eligible whitelist.
//      */
//     function getWhiteList()public view returns (address[] memory){
//         delegateToViewAndReturn();
//     }
//     /**
//      * @dev Implementation of testing whether the input address is eligible.
//      *  tmpAddress input address for testing.
//      */    
//     function isEligibleAddress(address /*tmpAddress*/) public view returns (bool){
//         delegateToViewAndReturn();
//     }
//     function setOperator(uint256 /*index*/,address /*addAddress*/)public{
//         delegateAndReturn();
//     }
//     function getOperator(uint256 /*index*/)public view returns (address) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting function. Retrieve FPT-A coin's address
//      */
//     function getFPTAAddress()public view returns (address) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting function. Retrieve FPT-B coin's address
//      */
//     function getFPTBAddress()public view returns (address) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting function. Retrieve mine pool's start time.
//      */
//     function getStartTime()public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting current mine period ID.
//      */
//     function getCurrentPeriodID()public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting user's staking FPT-A balance.
//      * account user's account
//      */
//     function getUserFPTABalance(address /*account*/)public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting user's staking FPT-B balance.
//      * account user's account
//      */
//     function getUserFPTBBalance(address /*account*/)public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting user's maximium locked period ID.
//      * account user's account
//      */
//     function getUserMaxPeriodId(address /*account*/)public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting user's locked expired time. After this time user can unstake FPTB coins.
//      * account user's account
//      */
//     function getUserExpired(address /*account*/)public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     function getCurrentTotalAPY(address /*mineCoin*/)public view returns (uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev Calculate user's current APY.
//      * account user's account.
//      * mineCoin mine coin address
//      */
//     function getUserCurrentAPY(address /*account*/,address /*mineCoin*/)public view returns (uint256){
//         delegateToViewAndReturn(); 
//     }
//     function getAverageLockedTime()public view returns (uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev foundation redeem out mine coins.
//      *  mineCoin mineCoin address
//      *  amount redeem amount.
//      */
//     function redeemOut(address /*mineCoin*/,uint256 /*amount*/)public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev retrieve total distributed mine coins.
//      *  mineCoin mineCoin address
//      */
//     function getTotalMined(address /*mineCoin*/)public view returns(uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev retrieve minecoin distributed informations.
//      *  mineCoin mineCoin address
//      * @return distributed amount and distributed time interval.
//      */
//     function getMineInfo(address /*mineCoin*/)public view returns(uint256,uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev retrieve user's mine balance.
//      *  account user's account
//      *  mineCoin mineCoin address
//      */
//     function getMinerBalance(address /*account*/,address /*mineCoin*/)public view returns(uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev Set mineCoin mine info, only foundation owner can invoked.
//      *  mineCoin mineCoin address
//      *  _mineAmount mineCoin distributed amount
//      *  _mineInterval mineCoin distributied time interval
//      */
//     function setMineCoinInfo(address /*mineCoin*/,uint256 /*_mineAmount*/,uint256 /*_mineInterval*/)public {
//         delegateAndReturn();
//     }

//     /**
//      * @dev user redeem mine rewards.
//      *  mineCoin mine coin address
//      *  amount redeem amount.
//      */
//     function redeemMinerCoin(address /*mineCoin*/,uint256 /*amount*/)public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev getting whole pool's mine production weight ratio.
//      *      Real mine production equals base mine production multiply weight ratio.
//      */
//     function getMineWeightRatio()public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev getting whole pool's mine shared distribution. All these distributions will share base mine production.
//      */
//     function getTotalDistribution() public view returns (uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev convert timestamp to period ID.
//      * _time timestamp. 
//      */ 
//     function getPeriodIndex(uint256 /*_time*/) public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev convert period ID to period's finish timestamp.
//      * periodID period ID. 
//      */
//     function getPeriodFinishTime(uint256 /*periodID*/)public view returns (uint256) {
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev Stake FPT-A coin and get distribution for mining.
//      * amount FPT-A amount that transfer into mine pool.
//      */
//     function stakeFPTA(uint256 /*amount*/)public {
//         delegateAndReturn();
//     }
//     /**
//      * @dev Air drop to user some FPT-B coin and lock one period and get distribution for mining.
//      * user air drop's recieptor.
//      * ftp_b_amount FPT-B amount that transfer into mine pool.
//      */
//     function lockAirDrop(address /*user*/,uint256 /*ftp_b_amount*/) external{
//         delegateAndReturn();
//     }
//     /**
//      * @dev Stake FPT-B coin and lock locedPreiod and get distribution for mining.
//      * amount FPT-B amount that transfer into mine pool.
//      * lockedPeriod locked preiod number.
//      */
//     function stakeFPTB(uint256 /*amount*/,uint256 /*lockedPeriod*/)public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev withdraw FPT-A coin.
//      * amount FPT-A amount that withdraw from mine pool.
//      */
//     function unstakeFPTA(uint256 /*amount*/)public {
//         delegateAndReturn();
//     }
//     /**
//      * @dev withdraw FPT-B coin.
//      * amount FPT-B amount that withdraw from mine pool.
//      */
//     function unstakeFPTB(uint256 /*amount*/)public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev Add FPT-B locked period.
//      * lockedPeriod FPT-B locked preiod number.
//      */
//     function changeFPTBLockedPeriod(uint256 /*lockedPeriod*/)public{
//         delegateAndReturn();
//     }

//        /**
//      * @dev retrieve total distributed premium coins.
//      */
//     function getTotalPremium()public view returns(uint256){
//         delegateToViewAndReturn(); 
//     }
//     /**
//      * @dev user redeem his options premium rewards.
//      */
//     function redeemPremium()public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev user redeem his options premium rewards.
//      * amount redeem amount.
//      */
//     function redeemPremiumCoin(address /*premiumCoin*/,uint256 /*amount*/)public{
//         delegateAndReturn();
//     }
//     /**
//      * @dev get user's premium balance.
//      * account user's account
//      */ 
//     function getUserLatestPremium(address /*account*/,address /*premiumCoin*/)public view returns(uint256){
//         delegateToViewAndReturn(); 
//     }
 
//     /**
//      * @dev Distribute premium from foundation.
//      * periodID period ID
//      * amount premium amount.
//      */ 
//     function distributePremium(address /*premiumCoin*/,uint256 /*periodID*/,uint256 /*amount*/)public {
//         delegateAndReturn();
//     }
//         /**
//      * @dev Emitted when `account` stake `amount` FPT-A coin.
//      */
//     event StakeFPTA(address indexed account,uint256 amount);
//     /**
//      * @dev Emitted when `from` airdrop `recieptor` `amount` FPT-B coin.
//      */
//     event LockAirDrop(address indexed from,address indexed recieptor,uint256 amount);
//     /**
//      * @dev Emitted when `account` stake `amount` FPT-B coin and locked `lockedPeriod` periods.
//      */
//     event StakeFPTB(address indexed account,uint256 amount,uint256 lockedPeriod);
//     /**
//      * @dev Emitted when `account` unstake `amount` FPT-A coin.
//      */
//     event UnstakeFPTA(address indexed account,uint256 amount);
//     /**
//      * @dev Emitted when `account` unstake `amount` FPT-B coin.
//      */
//     event UnstakeFPTB(address indexed account,uint256 amount);
//     /**
//      * @dev Emitted when `account` change `lockedPeriod` locked periods for FPT-B coin.
//      */
//     event ChangeLockedPeriod(address indexed account,uint256 lockedPeriod);
//     /**
//      * @dev Emitted when owner `account` distribute `amount` premium in `periodID` period.
//      */
//     event DistributePremium(address indexed account,address indexed premiumCoin,uint256 indexed periodID,uint256 amount);
//     /**
//      * @dev Emitted when `account` redeem `amount` premium.
//      */
//     event RedeemPremium(address indexed account,address indexed premiumCoin,uint256 amount);

//     /**
//      * @dev Emitted when `account` redeem `value` mineCoins.
//      */
//     event RedeemMineCoin(address indexed account, address indexed mineCoin, uint256 value);

// }

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// Original at https://etherscan.io/address/0x955282b82440F8F69E901380BeF2b603Fba96F3b
// Some functions were omitted for brevity. See the contract for details

interface IFNX_TokenConverter {
    struct lockedReward {
        uint256 startTime; //this tx startTime for locking
        uint256 total;     //record input amount in each lock tx    
        // Have to comment this out to get compiling working here
        // mapping (uint256 => uint256) alloc;//the allocation table
    }
    
    struct lockedIdx {
        uint256 beginIdx;//the first index for user converting input claimable tx index 
        uint256 totalIdx;//the total number for converting tx
    }

    function cfnxAddress() external returns (address); //cfnx token address
    function fnxAddress() external returns (address);  //fnx token address
    function timeSpan() external returns (uint256); //time interval span time ,default one month
    function dispatchTimes() external returns (uint256);    //allocation times,default 6 times
    function txNum() external returns (uint256); //100 times transfer tx 
    function lockPeriod() external returns (uint256);
    function lockedBalances(address) external returns (uint256); //locked balance for each user
    function lockedAllRewards(address, uint256) external returns (lockedReward memory); //converting tx record for each user
    function lockedIndexs(address) external returns (lockedIdx memory); //the converting tx index info
    function getbackLeftFnx(address /*reciever*/) external;
    function setParameter(address /*_cfnxAddress*/,address /*_fnxAddress*/,uint256 /*_timeSpan*/,uint256 /*_dispatchTimes*/,uint256 /*_txNum*/) external;
    function lockedBalanceOf(address /*account*/) external view returns (uint256);
    function inputCfnxForInstallmentPay(uint256 /*amount*/) external;
    function claimFnxExpiredReward() external;
    function getClaimAbleBalance(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// Original at https://etherscan.io/address/0xa2904Fd151C9d9D634dFA8ECd856E6B9517F9785
// Some functions were omitted for brevity. See the contract for details
// More info: https://github.com/FinNexus/OptionsContract/blob/master/contracts/ManagerContract.sol
// For Collateral Calculations: https://github.com/FinNexus/FinnexusOptionsV1.0/blob/master/contracts/OptionsManager/CollateralCal.sol
// Addresses: https://github.com/FinNexus/FinNexus-Documentation/blob/master/content/developers/smart-contracts.md

interface IFNX_ManagerProxy {
    /**
     * @dev Get the minimum collateral occupation rate.
     */
    function getCollateralRate(address /*collateral*/)external view returns (uint256) ;

    /**
     * @dev Retrieve user's cost of collateral, priced in USD.
     *  user input retrieved account 
     */
    function getUserPayingUsd(address /*user*/)external view returns (uint256);

    /**
     * @dev Retrieve user's amount of the specified collateral.
     *  user input retrieved account 
     *  collateral input retrieved collateral coin address 
     */
    function userInputCollateral(address /*user*/,address /*collateral*/)external view returns (uint256);

    /**
     * @dev Retrieve user's current total worth, priced in USD.
     *  account input retrieve account
     */
    function getUserTotalWorth(address /*account*/)external view returns (uint256);

    /**
     * @dev Retrieve FPTCoin's net worth, priced in USD.
     */
    function getTokenNetworth() external view returns (uint256);

    /**
     * @dev Deposit collateral in this pool from user.
     *  collateral The collateral coin address which is in whitelist.
     *  amount the amount of collateral to deposit.
     */
    function addCollateral(address /*collateral*/,uint256 /*amount*/) external payable;

    /**
     * @dev redeem collateral from this pool, user can input the prioritized collateral,he will get this coin,
     * if this coin is unsufficient, he will get others collateral which in whitelist.
     *  tokenAmount the amount of FPTCoin want to redeem.
     *  collateral The prioritized collateral coin address.
     */
    function redeemCollateral(uint256 /*tokenAmount*/,address /*collateral*/) external;
    
    /**
     * @dev Retrieve user's collateral worth in all collateral coin. 
     * If user want to redeem all his collateral,and the vacant collateral is sufficient,
     * He can redeem each collateral amount in return list.
     *  account the retrieve user's account;
     */
    function calCollateralWorth(address /*account*/)external view returns(uint256[] memory);

    /**
     * @dev Retrieve the occupied collateral worth, multiplied by minimum collateral rate, priced in USD. 
     */
    function getOccupiedCollateral() external view returns(uint256);

    /**
     * @dev Retrieve the available collateral worth, the worth of collateral which can used for buy options, priced in USD. 
     */
    function getAvailableCollateral() external view returns(uint256);

    /**
     * @dev Retrieve the left collateral worth, the worth of collateral which can used for redeem collateral, priced in USD. 
     */
    function getLeftCollateral() external view returns(uint256);

    /**
     * @dev Retrieve the unlocked collateral worth, the worth of collateral which currently used for options, priced in USD. 
     */
    function getUnlockedCollateral() external view returns(uint256);


    /**
     * @dev Retrieve the total collateral worth, priced in USD. 
     */
    function getTotalCollateral() external view returns(uint256);

    /**
     * @dev Retrieve the balance of collateral, the auxiliary function for the total collateral calculation. 
     */
    function getRealBalance(address /*settlement*/)external view returns(int256);
    function getNetWorthBalance(address /*settlement*/)external view returns(uint256);

    /**
     * @dev collateral occupation rate calculation
     *      collateral occupation rate = sum(collateral Rate * collateral balance) / sum(collateral balance)
     */
    function calculateCollateralRate() external view returns (uint256);

    /**
    * @dev retrieve input price valid range rate, thousandths.
    */ 
    function getPriceRateRange() external view returns(uint256,uint256) ;
    
    function getALLCollateralinfo(address /*user*/)external view 
        returns(uint256[] memory,int256[] memory,uint32[] memory,uint32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;
import '../../ERC20/IERC20.sol';

// Original at https://etherscan.io/address/0x43BD92bF3Bb25EBB3BdC2524CBd6156E3Fdd41F3
// Some functions were omitted for brevity. See the contract for details

interface IFNX_Oracle {
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) external view returns (uint256,uint256);
    function getPrices(uint256[]memory assets) external view returns (uint256[]memory);

    /**
    * @notice retrieves price of an asset
    * @dev function to get price for an asset
    * @param asset Asset for which to get the price
    * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
    */
    function getPrice(address asset) external view returns (uint256);
    function getUnderlyingPrice(uint256 underlying) external view returns (uint256);
}

// /**
//  *Submitted for verification at Etherscan.io on 2020-11-04
// */

// // File: contracts\modules\Ownable.sol

// pragma solidity >=0.6.0;

// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * there is an account (an owner) that can be granted exclusive access to
//  * specific functions.
//  *
//  * This module is used through inheritance. It will make available the modifier
//  * `onlyOwner`, which can be applied to your functions to restrict their use to
//  * the owner.
//  */
// contract Ownable {
//     address internal _owner;

//     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

//     /**
//      * @dev Initializes the contract setting the deployer as the initial owner.
//      */
//     constructor() internal {
//         _owner = msg.sender;
//         emit OwnershipTransferred(address(0), _owner);
//     }

//     /**
//      * @dev Returns the address of the current owner.
//      */
//     function owner() public view returns (address) {
//         return _owner;
//     }

//     /**
//      * @dev Throws if called by any account other than the owner.
//      */
//     modifier onlyOwner() {
//         require(isOwner(), "Ownable: caller is not the owner");
//         _;
//     }

//     /**
//      * @dev Returns true if the caller is the current owner.
//      */
//     function isOwner() public view returns (bool) {
//         return msg.sender == _owner;
//     }

//     /**
//      * @dev Leaves the contract without owner. It will not be possible to call
//      * `onlyOwner` functions anymore. Can only be called by the current owner.
//      *
//      * NOTE: Renouncing ownership will leave the contract without an owner,
//      * thereby removing any functionality that is only available to the owner.
//      */
//     function renounceOwnership() public onlyOwner {
//         emit OwnershipTransferred(_owner, address(0));
//         _owner = address(0);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      * Can only be called by the current owner.
//      */
//     function transferOwnership(address newOwner) public onlyOwner {
//         _transferOwnership(newOwner);
//     }

//     /**
//      * @dev Transfers ownership of the contract to a new account (`newOwner`).
//      */
//     function _transferOwnership(address newOwner) internal {
//         require(newOwner != address(0), "Ownable: new owner is the zero address");
//         emit OwnershipTransferred(_owner, newOwner);
//         _owner = newOwner;
//     }
// }

// // File: contracts\modules\whiteList.sol

// pragma solidity >=0.6.0;
//     /**
//      * @dev Implementation of a whitelist which filters a eligible uint32.
//      */
// library whiteListUint32 {
//     /**
//      * @dev add uint32 into white list.
//      * @param whiteList the storage whiteList.
//      * @param temp input value
//      */

//     function addWhiteListUint32(uint32[] storage whiteList,uint32 temp) internal{
//         if (!isEligibleUint32(whiteList,temp)){
//             whiteList.push(temp);
//         }
//     }
//     /**
//      * @dev remove uint32 from whitelist.
//      */
//     function removeWhiteListUint32(uint32[] storage whiteList,uint32 temp)internal returns (bool) {
//         uint256 len = whiteList.length;
//         uint256 i=0;
//         for (;i<len;i++){
//             if (whiteList[i] == temp)
//                 break;
//         }
//         if (i<len){
//             if (i!=len-1) {
//                 whiteList[i] = whiteList[len-1];
//             }
//             whiteList.pop();
//             return true;
//         }
//         return false;
//     }
//     function isEligibleUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (bool){
//         uint256 len = whiteList.length;
//         for (uint256 i=0;i<len;i++){
//             if (whiteList[i] == temp)
//                 return true;
//         }
//         return false;
//     }
//     function _getEligibleIndexUint32(uint32[] memory whiteList,uint32 temp) internal pure returns (uint256){
//         uint256 len = whiteList.length;
//         uint256 i=0;
//         for (;i<len;i++){
//             if (whiteList[i] == temp)
//                 break;
//         }
//         return i;
//     }
// }
//     /**
//      * @dev Implementation of a whitelist which filters a eligible uint256.
//      */
// library whiteListUint256 {
//     // add whiteList
//     function addWhiteListUint256(uint256[] storage whiteList,uint256 temp) internal{
//         if (!isEligibleUint256(whiteList,temp)){
//             whiteList.push(temp);
//         }
//     }
//     function removeWhiteListUint256(uint256[] storage whiteList,uint256 temp)internal returns (bool) {
//         uint256 len = whiteList.length;
//         uint256 i=0;
//         for (;i<len;i++){
//             if (whiteList[i] == temp)
//                 break;
//         }
//         if (i<len){
//             if (i!=len-1) {
//                 whiteList[i] = whiteList[len-1];
//             }
//             whiteList.pop();
//             return true;
//         }
//         return false;
//     }
//     function isEligibleUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (bool){
//         uint256 len = whiteList.length;
//         for (uint256 i=0;i<len;i++){
//             if (whiteList[i] == temp)
//                 return true;
//         }
//         return false;
//     }
//     function _getEligibleIndexUint256(uint256[] memory whiteList,uint256 temp) internal pure returns (uint256){
//         uint256 len = whiteList.length;
//         uint256 i=0;
//         for (;i<len;i++){
//             if (whiteList[i] == temp)
//                 break;
//         }
//         return i;
//     }
// }
//     /**
//      * @dev Implementation of a whitelist which filters a eligible address.
//      */
// library whiteListAddress {
//     // add whiteList
//     function addWhiteListAddress(address[] storage whiteList,address temp) internal{
//         if (!isEligibleAddress(whiteList,temp)){
//             whiteList.push(temp);
//         }
//     }
//     function removeWhiteListAddress(address[] storage whiteList,address temp)internal returns (bool) {
//         uint256 len = whiteList.length;
//         uint256 i=0;
//         for (;i<len;i++){
//             if (whiteList[i] == temp)
//                 break;
//         }
//         if (i<len){
//             if (i!=len-1) {
//                 whiteList[i] = whiteList[len-1];
//             }
//             whiteList.pop();
//             return true;
//         }
//         return false;
//     }
//     function isEligibleAddress(address[] memory whiteList,address temp) internal pure returns (bool){
//         uint256 len = whiteList.length;
//         for (uint256 i=0;i<len;i++){
//             if (whiteList[i] == temp)
//                 return true;
//         }
//         return false;
//     }
//     function _getEligibleIndexAddress(address[] memory whiteList,address temp) internal pure returns (uint256){
//         uint256 len = whiteList.length;
//         uint256 i=0;
//         for (;i<len;i++){
//             if (whiteList[i] == temp)
//                 break;
//         }
//         return i;
//     }
// }

// // File: contracts\modules\Operator.sol

// pragma solidity >=0.6.0;


// /**
//  * @dev Contract module which provides a basic access control mechanism, where
//  * each operator can be granted exclusive access to specific functions.
//  *
//  */
// contract Operator is Ownable {
//     using whiteListAddress for address[];
//     address[] private _operatorList;
//     /**
//      * @dev modifier, every operator can be granted exclusive access to specific functions. 
//      *
//      */
//     modifier onlyOperator() {
//         require(_operatorList.isEligibleAddress(msg.sender),"Managerable: caller is not the Operator");
//         _;
//     }
//     /**
//      * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
//      *
//      */
//     modifier onlyOperatorIndex(uint256 index) {
//         require(_operatorList.length>index && _operatorList[index] == msg.sender,"Managerable: caller is not the eligible Operator");
//         _;
//     }
//     /**
//      * @dev add a new operator by owner. 
//      *
//      */
//     function addOperator(address addAddress)public onlyOwner{
//         _operatorList.addWhiteListAddress(addAddress);
//     }
//     /**
//      * @dev modify indexed operator by owner. 
//      *
//      */
//     function setOperator(uint256 index,address addAddress)public onlyOwner{
//         _operatorList[index] = addAddress;
//     }
//     /**
//      * @dev remove operator by owner. 
//      *
//      */
//     function removeOperator(address removeAddress)public onlyOwner returns (bool){
//         return _operatorList.removeWhiteListAddress(removeAddress);
//     }
//     /**
//      * @dev get all operators. 
//      *
//      */
//     function getOperator()public view returns (address[] memory) {
//         return _operatorList;
//     }
//     /**
//      * @dev set all operators by owner. 
//      *
//      */
//     function setOperators(address[] memory operators)public onlyOwner {
//         _operatorList = operators;
//     }
// }

// // File: contracts\interfaces\AggregatorV3Interface.sol

// pragma solidity >=0.6.0;

// interface AggregatorV3Interface {

//   function decimals() external view returns (uint8);
//   function description() external view returns (string memory);
//   function version() external view returns (uint256);

//   // getRoundData and latestRoundData should both raise "No data present"
//   // if they do not have data to report, instead of returning unset values
//   // which could be misinterpreted as actual reported values.
//   function getRoundData(uint80 _roundId)
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );
//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

// }

// // File: contracts\interfaces\IERC20.sol

// pragma solidity ^0.6.11;
// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
//  * the optional functions; to access them see {ERC20Detailed}.
//  */
// interface IERC20 {
//     function decimals() external view returns (uint8);
//     /**
//      * @dev Returns the amount of tokens in existence.
//      */
//     function totalSupply() external view returns (uint256);

//     /**
//      * @dev Returns the amount of tokens owned by `account`.
//      */
//     function balanceOf(address account) external view returns (uint256);

//     /**
//      * @dev Moves `amount` tokens from the caller's account to `recipient`.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transfer(address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Returns the remaining number of tokens that `spender` will be
//      * allowed to spend on behalf of `owner` through {transferFrom}. This is
//      * zero by default.
//      *
//      * This value changes when {approve} or {transferFrom} are called.
//      */
//     function allowance(address owner, address spender) external view returns (uint256);

//     /**
//      * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * IMPORTANT: Beware that changing an allowance with this method brings the risk
//      * that someone may use both the old and the new allowance by unfortunate
//      * transaction ordering. One possible solution to mitigate this race
//      * condition is to first reduce the spender's allowance to 0 and set the
//      * desired value afterwards:
//      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//      *
//      * Emits an {Approval} event.
//      */
//     function approve(address spender, uint256 amount) external returns (bool);

//     /**
//      * @dev Moves `amount` tokens from `sender` to `recipient` using the
//      * allowance mechanism. `amount` is then deducted from the caller's
//      * allowance.
//      *
//      * Returns a boolean value indicating whether the operation succeeded.
//      *
//      * Emits a {Transfer} event.
//      */
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     /**
//      * @dev Emitted when `value` tokens are moved from one account (`from`) to
//      * another (`to`).
//      *
//      * Note that `value` may be zero.
//      */
//     event Transfer(address indexed from, address indexed to, uint256 value);

//     /**
//      * @dev Emitted when the allowance of a `spender` for an `owner` is set by
//      * a call to {approve}. `value` is the new allowance.
//      */
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

// // File: contracts\FNXOracle.sol

// pragma solidity ^0.6.7;




// contract FNXOracle is Operator {
//     mapping(uint256 => AggregatorV3Interface) private assetsMap;
//     mapping(uint256 => uint256) private decimalsMap;
//     mapping(uint256 => uint256) private priceMap;
//     uint256 internal decimals = 1;

//     /**
//      * Network: Ropsten
//      * Aggregator: LTC/USD
//      * Address: 0x727B59d0989d6D1961138122BC9F94f534E82B32
//      */
//     constructor() public {
//         //mainnet
//         assetsMap[1] = AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
//         assetsMap[2] = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
//         assetsMap[3] = AggregatorV3Interface(0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2);
//         assetsMap[4] = AggregatorV3Interface(0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699);
//         assetsMap[5] = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
//         assetsMap[0] = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
//         assetsMap[uint256(0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B)] = AggregatorV3Interface(0x80070f7151BdDbbB1361937ad4839317af99AE6c);
//         priceMap[uint256(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = 1e20;
//         decimalsMap[0] = 18;
//         decimalsMap[1] = 18;
//         decimalsMap[2] = 18;
//         decimalsMap[3] = 18;
//         decimalsMap[4] = 18;
//         decimalsMap[5] = 18;
//         decimalsMap[uint256(0xeF9Cd7882c067686691B6fF49e650b43AFBBCC6B)] = 18;
//         decimalsMap[uint256(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = 6;
//         /*
//         //rinkeby
//         assetsMap[1] = AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
//         assetsMap[2] = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//         assetsMap[3] = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
//         assetsMap[4] = AggregatorV3Interface(0xE96C4407597CD507002dF88ff6E0008AB41266Ee);
//         assetsMap[5] = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);
//         assetsMap[0] = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
//         assetsMap[uint256(0xaf30F6A6B09728a4e793ED6d9D0A7CcBa192c229)] = AggregatorV3Interface(0xcf74110A02b1D391B27cE37364ABc3b279B1d9D1);
//         priceMap[uint256(0xD12BC93Ac5eA2b4Ba99e0ffEd053a53B6d18C7a3)] = 1e20;
//         decimalsMap[0] = 18;
//         decimalsMap[1] = 18;
//         decimalsMap[2] = 18;
//         decimalsMap[3] = 18;
//         decimalsMap[4] = 18;
//         decimalsMap[5] = 18;
//         decimalsMap[uint256(0xaf30F6A6B09728a4e793ED6d9D0A7CcBa192c229)] = 18;
//         decimalsMap[uint256(0xD12BC93Ac5eA2b4Ba99e0ffEd053a53B6d18C7a3)] = 6;
//         */


//     }
//     function setDecimals(uint256 newDecimals) public onlyOwner{
//         decimals = newDecimals;
//     }
//     function getAssetAndUnderlyingPrice(address asset,uint256 underlying) public view returns (uint256,uint256) {
//         return (getUnderlyingPrice(uint256(asset)),getUnderlyingPrice(underlying));
//     }
//     function setPrices(uint256[]memory assets,uint256[]memory prices) public onlyOwner {
//         require(assets.length == prices.length, "input arrays' length are not equal");
//         uint256 len = assets.length;
//         for (uint i=0;i<len;i++){
//             priceMap[i] = prices[i];
//         }
//     }
//     function getPrices(uint256[]memory assets) public view returns (uint256[]memory) {
//         uint256 len = assets.length;
//         uint256[] memory prices = new uint256[](len);
//         for (uint i=0;i<len;i++){
//             prices[i] = getUnderlyingPrice(assets[i]);
//         }
//         return prices;
//     }
//         /**
//   * @notice retrieves price of an asset
//   * @dev function to get price for an asset
//   * @param asset Asset for which to get the price
//   * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
//   */
//     function getPrice(address asset) public view returns (uint256) {
//         return getUnderlyingPrice(uint256(asset));
//     }
//     function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
//         if (underlying == 3){
//             return getMKRPrice();
//         }
//         AggregatorV3Interface assetsPrice = assetsMap[underlying];
//         if (address(assetsPrice) != address(0)){
//             (, int price,,,) = assetsPrice.latestRoundData();
//             uint256 tokenDecimals = decimalsMap[underlying];
//             if (tokenDecimals < 18){
//                 return uint256(price)/decimals*(10**(18-tokenDecimals));  
//             }else if (tokenDecimals > 18){
//                 return uint256(price)/decimals/(10**(18-tokenDecimals)); 
//             }else{
//                 return uint256(price)/decimals;
//             }
//         }else {
//             return priceMap[underlying];
//         }
//     }
//     function getMKRPrice() internal view returns (uint256) {
//         AggregatorV3Interface assetsPrice = assetsMap[3];
//         AggregatorV3Interface ethPrice = assetsMap[0];
//         if (address(assetsPrice) != address(0) && address(ethPrice) != address(0)){
//             (, int price,,,) = assetsPrice.latestRoundData();
//             (, int ethPrice,,,) = ethPrice.latestRoundData();
//             uint256 tokenDecimals = decimalsMap[3];
//             uint256 mkrPrice = uint256(price*ethPrice)/decimals/1e18;
//             if (tokenDecimals < 18){
//                 return mkrPrice/decimals*(10**(18-tokenDecimals));  
//             }else if (tokenDecimals > 18){
//                 return mkrPrice/decimals/(10**(18-tokenDecimals)); 
//             }else{
//                 return mkrPrice/decimals;
//             }
//         }else {
//             return priceMap[3];
//         }
//     }
//     /**
//       * @notice set price of an asset
//       * @dev function to set price for an asset
//       * @param asset Asset for which to set the price
//       * @param price the Asset's price
//       */    
//     function setPrice(address asset,uint256 price) public onlyOperatorIndex(0) {
//         priceMap[uint256(asset)] = price;

//     }
//     /**
//       * @notice set price of an underlying
//       * @dev function to set price for an underlying
//       * @param underlying underlying for which to set the price
//       * @param price the underlying's price
//       */  
//     function setUnderlyingPrice(uint256 underlying,uint256 price) public onlyOperatorIndex(0) {
//         require(underlying>0 , "underlying cannot be zero");
//         priceMap[underlying] = price;
//     }
//         /**
//       * @notice set price of an asset
//       * @dev function to set price for an asset
//       * @param asset Asset for which to set the price
//       * @param aggergator the Asset's aggergator
//       */    
//     function setAssetsAggregator(address asset,address aggergator,uint256 _decimals) public onlyOwner {
//         assetsMap[uint256(asset)] = AggregatorV3Interface(aggergator);
//         decimalsMap[uint256(asset)] = _decimals;
//     }
//     /**
//       * @notice set price of an underlying
//       * @dev function to set price for an underlying
//       * @param underlying underlying for which to set the price
//       * @param aggergator the underlying's aggergator
//       */  
//     function setUnderlyingAggregator(uint256 underlying,address aggergator,uint256 _decimals) public onlyOwner {
//         require(underlying>0 , "underlying cannot be zero");
//         assetsMap[underlying] = AggregatorV3Interface(aggergator);
//         decimalsMap[underlying] = _decimals;
//     }
//     function getAssetsAggregator(address asset) public view returns (address,uint256) {
//         return (address(assetsMap[uint256(asset)]),decimalsMap[uint256(asset)]);
//     }
//     function getUnderlyingAggregator(uint256 underlying) public view returns (address,uint256) {
//         return (address(assetsMap[underlying]),decimalsMap[underlying]);
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

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
pragma solidity 0.6.11;

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
pragma solidity 0.6.11;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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

pragma solidity ^0.6.0;

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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

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
pragma solidity 0.6.11;

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
pragma solidity 0.6.11;

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
pragma solidity 0.6.11;

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
pragma solidity 0.6.11;

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
pragma solidity 0.6.11;

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
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))); // this matches the CREATE2 in UniswapV2Factory.createPair
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
        for (uint i; i < path.length - 1; i++) {
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
pragma solidity 0.6.11;

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

