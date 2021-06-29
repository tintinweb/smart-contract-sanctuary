// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ Convex_AMO ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian
// github.com/denett


import "../Curve/IStableSwap3Pool.sol";
import "../Curve/IMetaImplementationUSD.sol";
import "../Misc_AMOs/convex/IConvexBooster.sol";
import "../Misc_AMOs/convex/IConvexBaseRewardPool.sol";
import "../Misc_AMOs/convex/IVirtualBalanceRewardPool.sol";
import "../Misc_AMOs/convex/IConvexClaimZap.sol";
import "../Misc_AMOs/convex/IcvxRewardPool.sol";
import '../Uniswap/TransferHelper.sol';
import "../ERC20/ERC20.sol";
import "../Frax/Frax.sol";
import "../FXS/FXS.sol";
import "../Math/SafeMath.sol";
import "../Proxy/Initializable.sol";
import "../Staking/Owned_Proxy.sol";

contract Convex_AMO is AccessControl, Initializable, Owned_Proxy {
    using SafeMath for uint256;
    // Solidity ^8.0.0 automatically reverts on int256 underflows/overflows

    /* ========== STATE VARIABLES ========== */

    // Core
    FRAXStablecoin private FRAX;
    FraxPool private pool;
    ERC20 private collateral_token;

    // Curve-related
    IMetaImplementationUSD private frax3crv_metapool;
    IStableSwap3Pool private three_pool;
    ERC20 private three_pool_erc20;

    // Convex-related
    IConvexBooster private convex_booster;
    IConvexBaseRewardPool private convex_base_reward_pool;
    IConvexClaimZap private convex_claim_zap;
    IVirtualBalanceRewardPool private convex_fxs_rewards_pool;
    IcvxRewardPool private cvx_reward_pool;
    ERC20 private cvx;
    address cvx_crv_address;
    uint256 lp_deposit_pid;

    address private crv_address;
    address private fxs_address;
    address private frax3crv_metapool_address;

    address public timelock_address;
    address public custodian_address;

    // Number of decimals under 18, for collateral token
    uint256 private missing_decimals;

    // Precision related
    uint256 private PRICE_PRECISION;

    // Tracks FRAX
    int256 public minted_frax_historical;
    int256 public burned_frax_historical;

    // Max amount of FRAX outstanding the contract can mint from the FraxPool
    int256 public max_frax_outstanding;
    
    // Tracks collateral
    int256 public borrowed_collat_historical;
    int256 public returned_collat_historical;

    // Max amount of collateral the contract can borrow from the FraxPool
    int256 public collat_borrow_cap;

    // Minimum collateral ratio needed for new FRAX minting
    uint256 public min_cr;

    // Min ratio of collat <-> 3crv conversions via add_liquidity / remove_liquidity; 1e6
    uint256 public liq_slippage_3crv;

    // Min ratio of (FRAX + 3CRV) <-> FRAX3CRV-f-2 metapool conversions via add_liquidity / remove_liquidity; 1e6
    uint256 public slippage_metapool;

    // Convergence window
    uint256 public convergence_window; // 1 cent

    // Default will use global_collateral_ratio()
    bool public custom_floor;    
    uint256 public frax_floor;

    // Discount
    bool public set_discount;
    uint256 public discount_rate;

    // Collateral balance related
    bool public override_collat_balance;
    uint256 public override_collat_balance_amount;

    /* ========== INITIALIZER ========== */

    function initialize(
        address _frax_contract_address,
        address _fxs_address,
        address _collateral_address,
        address _creator_address,
        address _custodian_address,
        address _timelock_address,
        address _frax3crv_metapool_address,
        address _pool_address
    ) public initializer {
        owner = _creator_address;
        FRAX = FRAXStablecoin(_frax_contract_address);
        fxs_address = _fxs_address;
        collateral_token = ERC20(_collateral_address);
        missing_decimals = uint(18).sub(collateral_token.decimals());
        timelock_address = _timelock_address;
        custodian_address = _custodian_address;

        frax3crv_metapool_address = _frax3crv_metapool_address;
        frax3crv_metapool = IMetaImplementationUSD(_frax3crv_metapool_address);
        three_pool = IStableSwap3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
        three_pool_erc20 = ERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
        pool = FraxPool(_pool_address);

        // Convex-related 
        convex_booster = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
        convex_base_reward_pool = IConvexBaseRewardPool(0xB900EF131301B307dB5eFcbed9DBb50A3e209B2e);
        convex_claim_zap = IConvexClaimZap(0x4890970BB23FCdF624A0557845A29366033e6Fa2);
        cvx_reward_pool = IcvxRewardPool(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
        cvx = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
        cvx_crv_address = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
        crv_address = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        convex_fxs_rewards_pool = IVirtualBalanceRewardPool(0xcDEC6714eB482f28f4889A0c122868450CDBF0b0);
        lp_deposit_pid = 32;

        // Other variable initializations
        minted_frax_historical = 0;
        burned_frax_historical = 0;
        max_frax_outstanding = int256(2000000e18);
        borrowed_collat_historical = 0;
        returned_collat_historical = 0;
        collat_borrow_cap = int256(1000000e6);
        min_cr = 820000;
        PRICE_PRECISION = 1e6;
        liq_slippage_3crv = 800000;
        slippage_metapool = 950000;
        convergence_window = 1e16;
        custom_floor = false;  
        set_discount = false;
        override_collat_balance = false;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner, "Must be owner or timelock");
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodian_address, "Must be rewards custodian");
        _;
    }

    /* ========== VIEWS ========== */

    function showAllocations() public view returns (uint256[11] memory return_arr) {
        // ------------LP Balance------------

        // Free LP
        uint256 lp_owned = (frax3crv_metapool.balanceOf(address(this)));

        // Staked in the vault
        uint256 lp_value_in_vault = FRAX3CRVInVault();
        lp_owned = lp_owned.add(lp_value_in_vault);

        // ------------3pool Withdrawable------------
        // Uses iterate() to get metapool withdrawable amounts at FRAX floor price (global_collateral_ratio)
        uint256 frax3crv_supply = frax3crv_metapool.totalSupply();

        uint256 frax_withdrawable;
        uint256 _3pool_withdrawable;
        (frax_withdrawable, _3pool_withdrawable, ,) = iterate();
        if (frax3crv_supply > 0) {
            _3pool_withdrawable = _3pool_withdrawable.mul(lp_owned).div(frax3crv_supply);
            frax_withdrawable = frax_withdrawable.mul(lp_owned).div(frax3crv_supply);
        }
        else _3pool_withdrawable = 0;
         
        // ------------Frax Balance------------
        // Frax sums
        uint256 frax_in_contract = FRAX.balanceOf(address(this));

        // ------------Collateral Balance------------
        // Free Collateral
        uint256 usdc_in_contract = collateral_token.balanceOf(address(this));

        // Returns the dollar value withdrawable of USDC if the contract redeemed its 3CRV from the metapool; assume 1 USDC = $1
        uint256 usdc_withdrawable = _3pool_withdrawable.mul(three_pool.get_virtual_price()).div(1e18).div(10 ** missing_decimals);

        // USDC subtotal assuming FRAX drops to the CR and all reserves are arbed
        uint256 usdc_subtotal = usdc_in_contract.add(usdc_withdrawable);

        return [
            frax_in_contract, // [0] Free FRAX in the contract
            frax_withdrawable, // [1] FRAX withdrawable from the FRAX3CRV tokens
            frax_withdrawable.add(frax_in_contract), // [2] FRAX withdrawable + free FRAX in the the contract
            usdc_in_contract, // [3] Free USDC
            usdc_withdrawable, // [4] USDC withdrawable from the FRAX3CRV tokens
            usdc_subtotal, // [5] USDC subtotal assuming FRAX drops to the CR and all reserves are arbed
            usdc_subtotal.add((frax_in_contract.add(frax_withdrawable)).mul(fraxDiscountRate()).div(1e6 * (10 ** missing_decimals))), // [6] USDC Total
            lp_owned, // [7] FRAX3CRV free or in the vault
            frax3crv_supply, // [8] Total supply of FRAX3CRV tokens
            _3pool_withdrawable, // [9] 3pool withdrawable from the FRAX3CRV tokens
            lp_value_in_vault // [10] FRAX3CRV in the vault
        ];
    }

    function collatDollarBalance() external view returns (uint256) {
        if(override_collat_balance){
            return override_collat_balance_amount;
        }
        return (showAllocations()[6] * (10 ** missing_decimals));
    }

    function showRewards() public view returns (uint256[8] memory return_arr) {
        // return_arr[0] = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52).balanceOf(address(this)); // CRV in contract
        return_arr[0] = convex_base_reward_pool.earned(address(this)); // CRV claimable
        // return_arr[2] = cvx.balanceOf(address(this)); // CVX in contract
        return_arr[1] = 0; // CVX claimable. See https://docs.convexfinance.com/convexfinanceintegration/cvx-minting
        // return_arr[4] = ERC20(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7).balanceOf(address(this)); // cvxCRV in contract
        return_arr[2] = cvx_reward_pool.earned(address(this)); // cvxCRV claimable
        // return_arr[6] = ERC20(fxs_address).balanceOf(address(this)); // FXS in contract
        return_arr[3] = convex_fxs_rewards_pool.earned(address(this)); // FXS claimable
    }

    // Returns hypothetical reserves of metapool if the FRAX price went to the CR,
    // assuming no removal of liquidity from the metapool.
    function iterate() public view returns (uint256, uint256, uint256, uint256) {
        uint256 frax_balance = FRAX.balanceOf(frax3crv_metapool_address);
        uint256 crv3_balance = three_pool_erc20.balanceOf(frax3crv_metapool_address);
        uint256 total_balance = frax_balance.add(crv3_balance);

        uint256 floor_price_frax = uint(1e18).mul(fraxFloor()).div(1e6);
        
        uint256 crv3_received;
        uint256 dollar_value; // 3crv is usually slightly above $1 due to collecting 3pool swap fees
        for(uint i = 0; i < 256; i++){
            crv3_received = frax3crv_metapool.get_dy(0, 1, 1e18, [frax_balance, crv3_balance]);
            dollar_value = crv3_received.mul(1e18).div(three_pool.get_virtual_price());
            if(dollar_value <= floor_price_frax.add(convergence_window) && dollar_value >= floor_price_frax.sub(convergence_window)){
                uint256 factor = uint256(1e6).mul(total_balance).div(frax_balance.add(crv3_balance)); //1e6 precision

                // Normalize back to initial balances, since this estimation method adds in extra tokens
                frax_balance = frax_balance.mul(factor).div(1e6);
                crv3_balance = crv3_balance.mul(factor).div(1e6);
                return (frax_balance, crv3_balance, i, factor);
            } else if (dollar_value <= floor_price_frax.add(convergence_window)){
                uint256 crv3_to_swap = total_balance.div(2 ** i);
                frax_balance = frax_balance.sub(frax3crv_metapool.get_dy(1, 0, crv3_to_swap, [frax_balance, crv3_balance]));
                crv3_balance = crv3_balance.add(crv3_to_swap);
            } else if (dollar_value >= floor_price_frax.sub(convergence_window)){
                uint256 frax_to_swap = total_balance.div(2 ** i);
                crv3_balance = crv3_balance.sub(frax3crv_metapool.get_dy(0, 1, frax_to_swap, [frax_balance, crv3_balance]));
                frax_balance = frax_balance.add(frax_to_swap);
            }
        }
        revert("No hypothetical point"); // in 256 rounds
    }

    function fraxFloor() public view returns (uint256) {
        if(custom_floor){
            return frax_floor;
        } else {
            return FRAX.global_collateral_ratio();
        }
    }

    function fraxDiscountRate() public view returns (uint256) {
        if(set_discount){
            return discount_rate;
        } else {
            return FRAX.global_collateral_ratio();
        }
    }

    // In FRAX, can be negative
    function mintedBalance() public view returns (int256) {
        return minted_frax_historical - burned_frax_historical;
    }

    // In collateral, can be negative
    function borrowedCollatBalance() public view returns (int256) {
        return borrowed_collat_historical - returned_collat_historical;
    }

    // In FRAX, can be negative
    function totalInvested() public view returns (int256) {
        return mintedBalance() + (borrowedCollatBalance() * int256((10 ** missing_decimals)));
    }

    function FRAX3CRVInVault() public view returns (uint256){
        return convex_base_reward_pool.balanceOf(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // This is basically a workaround to transfer USDC from the FraxPool to this investor contract
    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main FRAX contract
    // It mints FRAX from nothing, and redeems it on the target pool for collateral and FXS
    // The burn can be called separately later on
    function mintRedeemPart1(uint256 frax_amount) external onlyByOwnerOrGovernance {
        //require(allow_yearn || allow_aave || allow_compound, 'All strategies are currently off');
        uint256 redeem_amount_E6 = (frax_amount.mul(uint256(1e6).sub(pool.redemption_fee()))).div(1e6).div(10 ** missing_decimals);
        uint256 expected_collat_amount = redeem_amount_E6.mul(FRAX.global_collateral_ratio()).div(1e6);
        expected_collat_amount = expected_collat_amount.mul(1e6).div(pool.getCollateralPrice());

        require((borrowedCollatBalance() + int256(expected_collat_amount)) <= collat_borrow_cap, "Borrow cap");
        borrowed_collat_historical = borrowed_collat_historical + int256(expected_collat_amount);

        // Mint the frax 
        FRAX.pool_mint(address(this), frax_amount);

        // Redeem the frax
        FRAX.approve(address(pool), frax_amount);
        pool.redeemFractionalFRAX(frax_amount, 0, 0);
    }

    function mintRedeemPart2() external onlyByOwnerOrGovernance {
        pool.collectRedemption();
    }

    // Give USDC profits back
    function giveCollatBack(uint256 amount) external onlyByOwnerOrGovernance {
        returned_collat_historical = returned_collat_historical + int256(amount);
        TransferHelper.safeTransfer(address(collateral_token), address(pool), uint256(amount));
    }
   
    // Burn unneeded or excess FRAX
    function burnFRAX(uint256 frax_amount) public onlyByOwnerOrGovernance {
        burned_frax_historical = burned_frax_historical + int256(frax_amount);
        FRAX.burn(uint256(frax_amount));
    }
   
    function burnFXS(uint256 amount) external onlyByOwnerOrGovernance {
        FRAXShares(fxs_address).approve(address(this), amount);
        FRAXShares(fxs_address).pool_burn_from(address(this), amount);
    }

    function metapoolDeposit(uint256 _frax_amount, uint256 _collateral_amount) external onlyByOwnerOrGovernance returns (uint256 metapool_LP_received) {
        // Mint the FRAX component
        minted_frax_historical = minted_frax_historical + int256(_frax_amount);
        FRAX.pool_mint(address(this), _frax_amount);
        require(mintedBalance() <= max_frax_outstanding, "max_frax_outstanding reached");

        uint256 threeCRV_received = 0;
        if (_collateral_amount > 0) {
            // Approve the collateral to be added to 3pool
            collateral_token.approve(address(three_pool), _collateral_amount);

            // Convert collateral into 3pool
            uint256[3] memory three_pool_collaterals;
            three_pool_collaterals[1] = _collateral_amount;
            {
                uint256 min_3pool_out = (_collateral_amount * (10 ** missing_decimals)).mul(liq_slippage_3crv).div(PRICE_PRECISION);
                three_pool.add_liquidity(three_pool_collaterals, min_3pool_out);
            }

            // Approve the 3pool for the metapool
            threeCRV_received = three_pool_erc20.balanceOf(address(this));

            // WEIRD ISSUE: NEED TO DO three_pool_erc20.approve(address(three_pool), 0); first before every time
            // May be related to https://github.com/vyperlang/vyper/blob/3e1ff1eb327e9017c5758e24db4bdf66bbfae371/examples/tokens/ERC20.vy#L85
            three_pool_erc20.approve(frax3crv_metapool_address, 0);
            three_pool_erc20.approve(frax3crv_metapool_address, threeCRV_received);
        }
        
        // Approve the FRAX for the metapool
        FRAX.approve(frax3crv_metapool_address, _frax_amount);

        {
            // Add the FRAX and the collateral to the metapool
            uint256 min_lp_out = (_frax_amount.add(threeCRV_received)).mul(slippage_metapool).div(PRICE_PRECISION);
            metapool_LP_received = frax3crv_metapool.add_liquidity([_frax_amount, threeCRV_received], min_lp_out);
        }

        // Make sure the collateral ratio did not fall too much
        uint256 current_collateral_E18 = (FRAX.globalCollateralValue()).mul(10 ** missing_decimals);
        uint256 cur_frax_supply = FRAX.totalSupply();
        uint256 new_cr = (current_collateral_E18.mul(PRICE_PRECISION)).div(cur_frax_supply);
        require (new_cr >= min_cr, "CR would be too low");
        
        return metapool_LP_received;
    }

    // Removed to save space 
    // function metapoolWithdrawAtCurRatio(uint256 _metapool_lp_in, bool burn_the_frax, uint256 min_frax, uint256 min_3pool) external onlyByOwnerOrGovernance returns (uint256 frax_received) {
    //     // Approve the metapool LP tokens for the metapool contract
    //     frax3crv_metapool.approve(address(this), _metapool_lp_in);

    //     // Withdraw FRAX and 3pool from the metapool at the current balance
    //     uint256 three_pool_received;
    //     {
    //         uint256[2] memory result_arr = frax3crv_metapool.remove_liquidity(_metapool_lp_in, [min_frax, min_3pool]);
    //         frax_received = result_arr[0];
    //         three_pool_received = result_arr[1];
    //     }

    //     // Convert the 3pool into the collateral
    //     three_pool_erc20.approve(address(three_pool), 0);
    //     three_pool_erc20.approve(address(three_pool), three_pool_received);
    //     {
    //         // Add the FRAX and the collateral to the metapool
    //         uint256 min_collat_out = three_pool_received.mul(liq_slippage_3crv).div(PRICE_PRECISION * (10 ** missing_decimals));
    //         three_pool.remove_liquidity_one_coin(three_pool_received, 1, min_collat_out);
    //     }

    //     // Optionally burn the FRAX
    //     if (burn_the_frax){
    //         burnFRAX(frax_received);
    //     }
        
    // }

    function metapoolWithdrawFrax(uint256 _metapool_lp_in, bool burn_the_frax) external onlyByOwnerOrGovernance returns (uint256 frax_received) {
        // Withdraw FRAX from the metapool
        uint256 min_frax_out = _metapool_lp_in.mul(slippage_metapool).div(PRICE_PRECISION);
        frax_received = frax3crv_metapool.remove_liquidity_one_coin(_metapool_lp_in, 0, min_frax_out);

        // Optionally burn the FRAX
        if (burn_the_frax){
            burnFRAX(frax_received);
        }
    }

    function metapoolWithdraw3pool(uint256 _metapool_lp_in) internal onlyByOwnerOrGovernance {
        // Withdraw 3pool from the metapool
        uint256 min_3pool_out = _metapool_lp_in.mul(slippage_metapool).div(PRICE_PRECISION);
        frax3crv_metapool.remove_liquidity_one_coin(_metapool_lp_in, 1, min_3pool_out);
    }

    function three_pool_to_collateral(uint256 _3pool_in) internal onlyByOwnerOrGovernance {
        // Convert the 3pool into the collateral
        // WEIRD ISSUE: NEED TO DO three_pool_erc20.approve(address(three_pool), 0); first before every time
        // May be related to https://github.com/vyperlang/vyper/blob/3e1ff1eb327e9017c5758e24db4bdf66bbfae371/examples/tokens/ERC20.vy#L85
        three_pool_erc20.approve(address(three_pool), 0);
        three_pool_erc20.approve(address(three_pool), _3pool_in);
        uint256 min_collat_out = _3pool_in.mul(liq_slippage_3crv).div(PRICE_PRECISION * (10 ** missing_decimals));
        three_pool.remove_liquidity_one_coin(_3pool_in, 1, min_collat_out);
    }

    function metapoolWithdrawAndConvert3pool(uint256 _metapool_lp_in) external onlyByOwnerOrGovernance {
        metapoolWithdraw3pool(_metapool_lp_in);
        three_pool_to_collateral(three_pool_erc20.balanceOf(address(this)));
    }

    /* ========== Convex: Deposit / Claim / Withdraw FRAX3CRV Metapool LP ========== */

    // Deposit Metapool LP tokens, convert them to Convex LP, and deposit into their vault
    function depositFRAX3CRV(uint256 _metapool_lp_in) external onlyByOwnerOrGovernance {
        // Approve the metapool LP tokens for the vault contract
        frax3crv_metapool.approve(address(convex_booster), _metapool_lp_in);
        
        // Deposit the metapool LP into the vault contract
        convex_booster.deposit(lp_deposit_pid, _metapool_lp_in, true);
    }

    // Claim CVX, CRV, and FXS rewards
    function claimRewardsFRAX3CRV() external onlyByOwnerOrGovernance {
        address[] memory rewardContracts = new address[](1);
        rewardContracts[0] = address(convex_base_reward_pool);

        uint256[] memory chefIds = new uint256[](0);

        convex_claim_zap.claimRewards(
            rewardContracts, 
            chefIds, 
            false, 
            false, 
            false, 
            0, 
            0
        );
    }

    // Withdraw Convex LP, convert it back to Metapool LP tokens, and give them back to the sender
    function withdrawAndUnwrapFRAX3CRV(uint256 amount, bool claim) external onlyByOwnerOrGovernance {
        convex_base_reward_pool.withdrawAndUnwrap(amount, claim);
    }

    /* ========== Convex: Stake / Claim / Withdraw CVX ========== */

    // Stake CVX tokens
    // E18
    function stakeCVX(uint256 _cvx_in) external onlyByOwnerOrGovernance {
        // Approve the CVX tokens for the staking contract
        cvx.approve(address(cvx_reward_pool), _cvx_in);
        
        // Stake the CVX tokens into the staking contract
        cvx_reward_pool.stakeFor(address(this), _cvx_in);
    }

    // Claim cvxCRV rewards
    function claimRewards_cvxCRV(bool stake) external onlyByOwnerOrGovernance {
        cvx_reward_pool.getReward(address(this), true, stake);
    }

    // Unstake CVX tokens
    // E18
    function withdrawCVX(uint256 cvx_amt, bool claim) external onlyByOwnerOrGovernance {
        cvx_reward_pool.withdraw(cvx_amt, claim);
    }

    /* ========== Custodian / Voter========== */

    // NOTE: The custodian_address or voter_contract_address can be set to the governance contract to be used as
    // a mega-voter or sorts.
    function withdrawRewards(
        uint256 crv_amt,
        uint256 cvx_amt,
        uint256 cvxCRV_amt,
        uint256 fxs_amt
    ) external onlyCustodian {
        if (crv_amt > 0) TransferHelper.safeTransfer(crv_address, msg.sender, crv_amt);
        if (cvx_amt > 0) TransferHelper.safeTransfer(address(cvx), msg.sender, cvx_amt);
        if (cvxCRV_amt > 0) TransferHelper.safeTransfer(cvx_crv_address, msg.sender, cvxCRV_amt);
        if (fxs_amt > 0) TransferHelper.safeTransfer(fxs_address, msg.sender, fxs_amt);
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        timelock_address = new_timelock;
    }

    function setCustodian(address _custodian_address) external onlyByOwnerOrGovernance {
        require(_custodian_address != address(0), "Custodian address cannot be 0");        
        custodian_address = _custodian_address;
    }

    function setCollatBorrowCap(int256 _collat_borrow_cap) external onlyByOwnerOrGovernance {
        collat_borrow_cap = _collat_borrow_cap;
    }

    function setMaxFraxOutstanding(int256 _max_frax_outstanding) external onlyByOwnerOrGovernance {
        max_frax_outstanding = _max_frax_outstanding;
    }

    function setMinimumCollateralRatio(uint256 _min_cr) external onlyByOwnerOrGovernance {
        min_cr = _min_cr;
    }

    function setConvergenceWindow(uint256 _window) external onlyByOwnerOrGovernance {
        convergence_window = _window;
    }

    function setOverrideCollatBalance(bool _state, uint256 _balance) external onlyByOwnerOrGovernance {
        override_collat_balance = _state;
        override_collat_balance_amount = _balance;
    }

    // in terms of 1e6 (overriding global_collateral_ratio)
    function setCustomFloor(bool _state, uint256 _floor_price) external onlyByOwnerOrGovernance {
        custom_floor = _state;
        frax_floor = _floor_price;
    }

    // in terms of 1e6 (overriding global_collateral_ratio)
    function setDiscountRate(bool _state, uint256 _discount_rate) external onlyByOwnerOrGovernance {
        set_discount = _state;
        discount_rate = _discount_rate;
    }

    function setSlippages(uint256 _liq_slippage_3crv, uint256 _slippage_metapool) external onlyByOwnerOrGovernance {
        liq_slippage_3crv = _liq_slippage_3crv;
        slippage_metapool = _slippage_metapool;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerOrGovernance {
        // Can only be triggered by owner or governance, not custodian
        // Tokens are sent to the custodian, as a sort of safeguard
        TransferHelper.safeTransfer(address(tokenAddress), custodian_address, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IStableSwap3Pool {
	// Deployment
	function __init__(address _owner, address[3] memory _coins, address _pool_token, uint256 _A, uint256 _fee, uint256 _admin_fee) external;

	// ERC20 Standard
	function decimals() external view returns (uint);
	function transfer(address _to, uint _value) external returns (uint256);
	function transferFrom(address _from, address _to, uint _value) external returns (bool);
	function approve(address _spender, uint _value) external returns (bool);
	function totalSupply() external view returns (uint);
	function mint(address _to, uint256 _value) external returns (bool);
	function burnFrom(address _to, uint256 _value) external returns (bool);
	function balanceOf(address _owner) external view returns (uint256);

	// 3Pool
	function A() external view returns (uint);
	function get_virtual_price() external view returns (uint);
	function calc_token_amount(uint[3] memory amounts, bool deposit) external view returns (uint);
	function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
	function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
	function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;
	function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
	function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
	
	// Admin functions
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;
	function commit_new_fee(uint256 new_fee, uint256 new_admin_fee) external;
	function apply_new_fee() external;
	function commit_transfer_ownership(address _owner) external;
	function apply_transfer_ownership() external;
	function revert_transfer_ownership() external;
	function admin_balances(uint256 i) external returns (uint256);
	function withdraw_admin_fees() external;
	function donate_admin_fees() external;
	function kill_me() external;
	function unkill_me() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IMetaImplementationUSD {

	// Deployment
	function __init__() external;
	function initialize(string memory _name, string memory _symbol, address _coin, uint _decimals, uint _A, uint _fee, address _admin) external;

	// ERC20 Standard
	function decimals() external view returns (uint);
	function transfer(address _to, uint _value) external returns (uint256);
	function transferFrom(address _from, address _to, uint _value) external returns (bool);
	function approve(address _spender, uint _value) external returns (bool);
	function balanceOf(address _owner) external view returns (uint256);
	function totalSupply() external view returns (uint256);


	// StableSwap Functionality
	function get_previous_balances() external view returns (uint[2] memory);
	function get_twap_balances(uint[2] memory _first_balances, uint[2] memory _last_balances, uint _time_elapsed) external view returns (uint[2] memory);
	function get_price_cumulative_last() external view returns (uint[2] memory);
	function admin_fee() external view returns (uint);
	function A() external view returns (uint);
	function A_precise() external view returns (uint);
	function get_virtual_price() external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit) external view returns (uint);
	function calc_token_amount(uint[2] memory _amounts, bool _is_deposit, bool _previous) external view returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount) external returns (uint);
	function add_liquidity(uint[2] memory _amounts, uint _min_mint_amount, address _receiver) external returns (uint);
	function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
	function get_dy_underlying(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
	function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);
	function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts, address _receiver) external returns (uint256[2] memory);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount) external returns (uint256);
	function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount, address _receiver) external returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);
	function calc_withdraw_one_coin(uint256 _burn_amount, int128 i, bool _previous) external view returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);
	function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver) external returns (uint256);
	function ramp_A(uint256 _future_A, uint256 _future_time) external;
	function stop_ramp_A() external;
	function admin_balances(uint256 i) external view returns (uint256);
	function withdraw_admin_fees() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexBooster {
  function FEE_DENOMINATOR() external view returns (uint256);
  function MaxFees() external view returns (uint256);
  function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns (bool);
  function claimRewards(uint256 _pid, address _gauge) external returns (bool);
  function crv() external view returns (address);
  function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
  function distributionAddressId() external view returns (uint256);
  function earmarkFees() external returns (bool);
  function earmarkIncentive() external view returns (uint256);
  function earmarkRewards(uint256 _pid) external returns (bool);
  function feeDistro() external view returns (address);
  function feeManager() external view returns (address);
  function feeToken() external view returns (address);
  function gaugeMap(address) external view returns (bool);
  function isShutdown() external view returns (bool);
  function lockFees() external view returns (address);
  function lockIncentive() external view returns (uint256);
  function lockRewards() external view returns (address);
  function minter() external view returns (address);
  function owner() external view returns (address);
  function platformFee() external view returns (uint256);
  function poolInfo(uint256) external view returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
  function poolLength() external view returns (uint256);
  function poolManager() external view returns (address);
  function registry() external view returns (address);
  function rewardArbitrator() external view returns (address);
  function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns (bool);
  function rewardFactory() external view returns (address);
  function setArbitrator(address _arb) external;
  function setFactories(address _rfactory, address _sfactory, address _tfactory) external;
  function setFeeInfo() external;
  function setFeeManager(address _feeM) external;
  function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external;
  function setGaugeRedirect(uint256 _pid) external returns (bool);
  function setOwner(address _owner) external;
  function setPoolManager(address _poolM) external;
  function setRewardContracts(address _rewards, address _stakerRewards) external;
  function setTreasury(address _treasury) external;
  function setVoteDelegate(address _voteDelegate) external;
  function shutdownPool(uint256 _pid) external returns (bool);
  function shutdownSystem() external;
  function staker() external view returns (address);
  function stakerIncentive() external view returns (uint256);
  function stakerRewards() external view returns (address);
  function stashFactory() external view returns (address);
  function tokenFactory() external view returns (address);
  function treasury() external view returns (address);
  function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool);
  function voteDelegate() external view returns (address);
  function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);
  function voteOwnership() external view returns (address);
  function voteParameter() external view returns (address);
  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
  function withdrawAll(uint256 _pid) external returns (bool);
  function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns (bool);
}


// /**
//  * @dev Standard math utilities missing in the Solidity language.
//  */
// library MathUtil {
//     /**
//      * @dev Returns the smallest of two numbers.
//      */
//     function min(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a < b ? a : b;
//     }
// }

// contract ReentrancyGuard {
//     uint256 private _guardCounter;

//     constructor () internal {
//         _guardCounter = 1;
//     }

//     modifier nonReentrant() {
//         _guardCounter += 1;
//         uint256 localCounter = _guardCounter;
//         _;
//         require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
//     }
// }

// interface ICurveGauge {
//     function deposit(uint256) external;
//     function balanceOf(address) external view returns (uint256);
//     function withdraw(uint256) external;
//     function claim_rewards() external;
//     function reward_tokens(uint256) external view returns(address);//v2
//     function rewarded_token() external view returns(address);//v1
// }

// interface ICurveVoteEscrow {
//     function create_lock(uint256, uint256) external;
//     function increase_amount(uint256) external;
//     function increase_unlock_time(uint256) external;
//     function withdraw() external;
//     function smart_wallet_checker() external view returns (address);
// }

// interface IWalletChecker {
//     function check(address) external view returns (bool);
// }

// interface IVoting{
//     function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
//     function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory); 
//     function vote_for_gauge_weights(address,uint256) external;
// }

// interface IMinter{
//     function mint(address) external;
// }

// interface IRegistry{
//     function get_registry() external view returns(address);
//     function get_address(uint256 _id) external view returns(address);
//     function gauge_controller() external view returns(address);
//     function get_lp_token(address) external view returns(address);
//     function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
// }

// interface IStaker{
//     function deposit(address, address) external;
//     function withdraw(address) external;
//     function withdraw(address, address, uint256) external;
//     function withdrawAll(address, address) external;
//     function createLock(uint256, uint256) external;
//     function increaseAmount(uint256) external;
//     function increaseTime(uint256) external;
//     function release() external;
//     function claimCrv(address) external returns (uint256);
//     function claimRewards(address) external;
//     function claimFees(address,address) external;
//     function setStashAccess(address, bool) external;
//     function vote(uint256,address,bool) external;
//     function voteGaugeWeight(address,uint256) external;
//     function balanceOfPool(address) external view returns (uint256);
//     function operator() external view returns (address);
//     function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
// }

// interface IRewards{
//     function stake(address, uint256) external;
//     function stakeFor(address, uint256) external;
//     function withdraw(address, uint256) external;
//     function exit(address) external;
//     function getReward(address) external;
//     function queueNewRewards(uint256) external;
//     function notifyRewardAmount(uint256) external;
//     function addExtraReward(address) external;
//     function stakingToken() external returns (address);
// }

// interface IStash{
//     function stashRewards() external returns (bool);
//     function processStash() external returns (bool);
//     function claimRewards() external returns (bool);
// }

// interface IFeeDistro{
//     function claim() external;
//     function token() external view returns(address);
// }

// interface ITokenMinter{
//     function mint(address,uint256) external;
//     function burn(address,uint256) external;
// }

// interface IDeposit{
//     function isShutdown() external view returns(bool);
//     function balanceOf(address _account) external view returns(uint256);
//     function totalSupply() external view returns(uint256);
//     function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
//     function rewardClaimed(uint256,address,uint256) external;
//     function withdrawTo(uint256,uint256,address) external;
//     function claimRewards(uint256,address) external returns(bool);
//     function rewardArbitrator() external returns(address);
// }

// interface ICrvDeposit{
//     function deposit(uint256, bool) external;
//     function lockIncentive() external view returns(uint256);
// }

// interface IRewardFactory{
//     function setAccess(address,bool) external;
//     function CreateCrvRewards(uint256,address) external returns(address);
//     function CreateTokenRewards(address,address,address) external returns(address);
//     function activeRewardCount(address) external view returns(uint256);
//     function addActiveReward(address,uint256) external returns(bool);
//     function removeActiveReward(address,uint256) external returns(bool);
// }

// interface IStashFactory{
//     function CreateStash(uint256,address,address,uint256) external returns(address);
// }

// interface ITokenFactory{
//     function CreateDepositToken(address) external returns(address);
// }

// interface IPools{
//     function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
//     function shutdownPool(uint256 _pid) external returns(bool);
//     function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
//     function poolLength() external view returns (uint256);
//     function gaugeMap(address) external view returns(bool);
//     function setPoolManager(address _poolM) external;
// }

// interface IVestedEscrow{
//     function fund(address[] calldata _recipient, uint256[] calldata _amount) external returns(bool);
// }

// // File: @openzeppelin\contracts\math\SafeMath.sol

// pragma solidity >=0.6.0 <0.8.0;

// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         uint256 c = a + b;
//         if (c < a) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the substraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b > a) return (false, 0);
//         return (true, a - b);
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) return (true, 0);
//         uint256 c = a * b;
//         if (c / a != b) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a / b);
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a % b);
//     }

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
//         require(b <= a, "SafeMath: subtraction overflow");
//         return a - b;
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
//         if (a == 0) return 0;
//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
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
//         require(b > 0, "SafeMath: division by zero");
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: modulo by zero");
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         return a - b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryDiv}.
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
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a % b;
//     }
// }

// // File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// pragma solidity >=0.6.0 <0.8.0;

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
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

// // File: @openzeppelin\contracts\utils\Address.sol
// pragma solidity >=0.6.2 <0.8.0;

// /**
//  * @dev Collection of functions related to the address type
//  */
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
//         // This method relies on extcodesize, which returns 0 for contracts in
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
//         return functionCallWithValue(target, data, 0, errorMessage);
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

//     /**
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
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
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
// }

// // File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol


// pragma solidity >=0.6.0 <0.8.0;


// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
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

// // File: contracts\Booster.sol

// pragma solidity 0.6.12;



// contract Booster{
//     using SafeERC20 for IERC20;
//     using Address for address;
//     using SafeMath for uint256;

//     address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
//     address public constant registry = address(0x0000000022D53366457F9d5E68Ec105046FC4383);
//     uint256 public constant distributionAddressId = 4;
//     address public constant voteOwnership = address(0xE478de485ad2fe566d49342Cbd03E49ed7DB3356);
//     address public constant voteParameter = address(0xBCfF8B0b9419b9A88c44546519b1e909cF330399);

//     uint256 public lockIncentive = 1000; //incentive to crv stakers
//     uint256 public stakerIncentive = 450; //incentive to native token stakers
//     uint256 public earmarkIncentive = 50; //incentive to users who spend gas to make calls
//     uint256 public platformFee = 0; //possible fee to build treasury
//     uint256 public constant MaxFees = 2000;
//     uint256 public constant FEE_DENOMINATOR = 10000;

//     address public owner;
//     address public feeManager;
//     address public poolManager;
//     address public immutable staker;
//     address public immutable minter;
//     address public rewardFactory;
//     address public stashFactory;
//     address public tokenFactory;
//     address public rewardArbitrator;
//     address public voteDelegate;
//     address public treasury;
//     address public stakerRewards; //cvx rewards
//     address public lockRewards; //cvxCrv rewards(crv)
//     address public lockFees; //cvxCrv vecrv fees
//     address public feeDistro;
//     address public feeToken;

//     bool public isShutdown;

//     struct PoolInfo {
//         address lptoken;
//         address token;
//         address gauge;
//         address crvRewards;
//         address stash;
//         bool shutdown;
//     }

//     //index(pid) -> pool
//     PoolInfo[] public poolInfo;
//     mapping(address => bool) public gaugeMap;

//     event Deposited(address indexed user, uint256 indexed poolid, uint256 amount);
//     event Withdrawn(address indexed user, uint256 indexed poolid, uint256 amount);

//     constructor(address _staker, address _minter) public {
//         isShutdown = false;
//         staker = _staker;
//         owner = msg.sender;
//         voteDelegate = msg.sender;
//         feeManager = msg.sender;
//         poolManager = msg.sender;
//         feeDistro = address(0); //address(0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc);
//         feeToken = address(0); //address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
//         treasury = address(0);
//         minter = _minter;
//     }


//     /// SETTER SECTION ///

//     function setOwner(address _owner) external {
//         require(msg.sender == owner, "!auth");
//         owner = _owner;
//     }

//     function setFeeManager(address _feeM) external {
//         require(msg.sender == feeManager, "!auth");
//         feeManager = _feeM;
//     }

//     function setPoolManager(address _poolM) external {
//         require(msg.sender == poolManager, "!auth");
//         poolManager = _poolM;
//     }

//     function setFactories(address _rfactory, address _sfactory, address _tfactory) external {
//         require(msg.sender == owner, "!auth");
        
//         //reward factory only allow this to be called once even if owner
//         //removes ability to inject malicious staking contracts
//         //token factory can also be immutable
//         if(rewardFactory == address(0)){
//             rewardFactory = _rfactory;
//             tokenFactory = _tfactory;
//         }

//         //stash factory should be considered more safe to change
//         //updating may be required to handle new types of gauges
//         stashFactory = _sfactory;
//     }

//     function setArbitrator(address _arb) external {
//         require(msg.sender==owner, "!auth");
//         rewardArbitrator = _arb;
//     }

//     function setVoteDelegate(address _voteDelegate) external {
//         require(msg.sender==voteDelegate, "!auth");
//         voteDelegate = _voteDelegate;
//     }

//     function setRewardContracts(address _rewards, address _stakerRewards) external {
//         require(msg.sender == owner, "!auth");
        
//         //reward contracts are immutable or else the owner
//         //has a means to redeploy and mint cvx via rewardClaimed()
//         if(lockRewards == address(0)){
//             lockRewards = _rewards;
//             stakerRewards = _stakerRewards;
//         }
//     }

//     // Set reward token and claim contract, get from Curve's registry
//     function setFeeInfo() external {
//         require(msg.sender==feeManager, "!auth");
        
//         feeDistro = IRegistry(registry).get_address(distributionAddressId);
//         address _feeToken = IFeeDistro(feeDistro).token();
//         if(feeToken != _feeToken){
//             //create a new reward contract for the new token
//             lockFees = IRewardFactory(rewardFactory).CreateTokenRewards(_feeToken,lockRewards,address(this));
//             feeToken = _feeToken;
//         }
//     }

//     function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external{
//         require(msg.sender==feeManager, "!auth");

//         uint256 total = _lockFees.add(_stakerFees).add(_callerFees).add(_platform);
//         require(total <= MaxFees, ">MaxFees");

//         //values must be within certain ranges     
//         if(_lockFees >= 1000 && _lockFees <= 1500
//             && _stakerFees >= 300 && _stakerFees <= 600
//             && _callerFees >= 10 && _callerFees <= 100
//             && _platform <= 200){
//             lockIncentive = _lockFees;
//             stakerIncentive = _stakerFees;
//             earmarkIncentive = _callerFees;
//             platformFee = _platform;
//         }
//     }

//     function setTreasury(address _treasury) external {
//         require(msg.sender==feeManager, "!auth");
//         treasury = _treasury;
//     }

//     /// END SETTER SECTION ///


//     function poolLength() external view returns (uint256) {
//         return poolInfo.length;
//     }

//     //create a new pool
//     function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool){
//         require(msg.sender==poolManager && !isShutdown, "!add");
//         require(_gauge != address(0) && _lptoken != address(0),"!param");

//         //the next pool's pid
//         uint256 pid = poolInfo.length;

//         //create a tokenized deposit
//         address token = ITokenFactory(tokenFactory).CreateDepositToken(_lptoken);
//         //create a reward contract for crv rewards
//         address newRewardPool = IRewardFactory(rewardFactory).CreateCrvRewards(pid,token);
//         //create a stash to handle extra incentives
//         address stash = IStashFactory(stashFactory).CreateStash(pid,_gauge,staker,_stashVersion);

//         //add the new pool
//         poolInfo.push(
//             PoolInfo({
//                 lptoken: _lptoken,
//                 token: token,
//                 gauge: _gauge,
//                 crvRewards: newRewardPool,
//                 stash: stash,
//                 shutdown: false
//             })
//         );
//         gaugeMap[_gauge] = true;
//         //give stashes access to rewardfactory and voteproxy
//         //   voteproxy so it can grab the incentive tokens off the contract after claiming rewards
//         //   reward factory so that stashes can make new extra reward contracts if a new incentive is added to the gauge
//         if(stash != address(0)){
//             poolInfo[pid].stash = stash;
//             IStaker(staker).setStashAccess(stash,true);
//             IRewardFactory(rewardFactory).setAccess(stash,true);
//         }
//         return true;
//     }

//     //shutdown pool
//     function shutdownPool(uint256 _pid) external returns(bool){
//         require(msg.sender==poolManager, "!auth");
//         PoolInfo storage pool = poolInfo[_pid];

//         //withdraw from gauge
//         try IStaker(staker).withdrawAll(pool.lptoken,pool.gauge){
//         }catch{}

//         pool.shutdown = true;
//         gaugeMap[pool.gauge] = false;
//         return true;
//     }

//     //shutdown this contract.
//     //  unstake and pull all lp tokens to this address
//     //  only allow withdrawals
//     function shutdownSystem() external{
//         require(msg.sender == owner, "!auth");
//         isShutdown = true;

//         for(uint i=0; i < poolInfo.length; i++){
//             PoolInfo storage pool = poolInfo[i];
//             if (pool.shutdown) continue;

//             address token = pool.lptoken;
//             address gauge = pool.gauge;

//             //withdraw from gauge
//             try IStaker(staker).withdrawAll(token,gauge){
//                 pool.shutdown = true;
//             }catch{}
//         }
//     }


//     //deposit lp tokens and stake
//     function deposit(uint256 _pid, uint256 _amount, bool _stake) public returns(bool){
//         require(!isShutdown,"shutdown");
//         PoolInfo storage pool = poolInfo[_pid];
//         require(pool.shutdown == false, "pool is closed");

//         //send to proxy to stake
//         address lptoken = pool.lptoken;
//         IERC20(lptoken).safeTransferFrom(msg.sender, staker, _amount);

//         //stake
//         address gauge = pool.gauge;
//         require(gauge != address(0),"!gauge setting");
//         IStaker(staker).deposit(lptoken,gauge);

//         //some gauges claim rewards when depositing, stash them in a seperate contract until next claim
//         address stash = pool.stash;
//         if(stash != address(0)){
//             IStash(stash).stashRewards();
//         }

//         address token = pool.token;
//         if(_stake){
//             //mint here and send to rewards on user behalf
//             ITokenMinter(token).mint(address(this),_amount);
//             address rewardContract = pool.crvRewards;
//             IERC20(token).safeApprove(rewardContract,0);
//             IERC20(token).safeApprove(rewardContract,_amount);
//             IRewards(rewardContract).stakeFor(msg.sender,_amount);
//         }else{
//             //add user balance directly
//             ITokenMinter(token).mint(msg.sender,_amount);
//         }

        
//         emit Deposited(msg.sender, _pid, _amount);
//         return true;
//     }

//     //deposit all lp tokens and stake
//     function depositAll(uint256 _pid, bool _stake) external returns(bool){
//         address lptoken = poolInfo[_pid].lptoken;
//         uint256 balance = IERC20(lptoken).balanceOf(msg.sender);
//         deposit(_pid,balance,_stake);
//         return true;
//     }

//     //withdraw lp tokens
//     function _withdraw(uint256 _pid, uint256 _amount, address _from, address _to) internal {
//         PoolInfo storage pool = poolInfo[_pid];
//         address lptoken = pool.lptoken;
//         address gauge = pool.gauge;

//         //remove lp balance
//         address token = pool.token;
//         ITokenMinter(token).burn(_from,_amount);

//         //pull from gauge if not shutdown
//         // if shutdown tokens will be in this contract
//         if (!pool.shutdown) {
//             IStaker(staker).withdraw(lptoken,gauge, _amount);
//         }

//         //some gauges claim rewards when withdrawing, stash them in a seperate contract until next claim
//         //do not call if shutdown since stashes wont have access
//         address stash = pool.stash;
//         if(stash != address(0) && !isShutdown && !pool.shutdown){
//             IStash(stash).stashRewards();
//         }
        
//         //return lp tokens
//         IERC20(lptoken).safeTransfer(_to, _amount);

//         emit Withdrawn(_to, _pid, _amount);
//     }

//     //withdraw lp tokens
//     function withdraw(uint256 _pid, uint256 _amount) public returns(bool){
//         _withdraw(_pid,_amount,msg.sender,msg.sender);
//         return true;
//     }

//     //withdraw all lp tokens
//     function withdrawAll(uint256 _pid) public returns(bool){
//         address token = poolInfo[_pid].token;
//         uint256 userBal = IERC20(token).balanceOf(msg.sender);
//         withdraw(_pid, userBal);
//         return true;
//     }

//     //allow reward contracts to send here and withdraw to user
//     function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns(bool){
//         address rewardContract = poolInfo[_pid].crvRewards;
//         require(msg.sender == rewardContract,"!auth");

//         _withdraw(_pid,_amount,msg.sender,_to);
//         return true;
//     }


//     //delegate address votes on dao
//     function vote(uint256 _voteId, address _votingAddress, bool _support) external returns(bool){
//         require(msg.sender == voteDelegate, "!auth");
//         require(_votingAddress == voteOwnership || _votingAddress == voteParameter, "!voteAddr");
        
//         IStaker(staker).vote(_voteId,_votingAddress,_support);
//         return true;
//     }

//     function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight ) external returns(bool){
//         require(msg.sender == voteDelegate, "!auth");

//         for(uint256 i = 0; i < _gauge.length; i++){
//             IStaker(staker).voteGaugeWeight(_gauge[i],_weight[i]);
//         }
//         return true;
//     }

//     function claimRewards(uint256 _pid, address _gauge) external returns(bool){
//         address stash = poolInfo[_pid].stash;
//         require(msg.sender == stash,"!auth");

//         IStaker(staker).claimRewards(_gauge);
//         return true;
//     }

//     function setGaugeRedirect(uint256 _pid) external returns(bool){
//         address stash = poolInfo[_pid].stash;
//         require(msg.sender == stash,"!auth");
//         address gauge = poolInfo[_pid].gauge;
//         bytes memory data = abi.encodeWithSelector(bytes4(keccak256("set_rewards_receiver(address)")), stash);
//         IStaker(staker).execute(gauge,uint256(0),data);
//         return true;
//     }

//     //claim crv and extra rewards and disperse to reward contracts
//     function _earmarkRewards(uint256 _pid) internal {
//         PoolInfo storage pool = poolInfo[_pid];
//         require(pool.shutdown == false, "pool is closed");

//         address gauge = pool.gauge;

//         //claim crv
//         IStaker(staker).claimCrv(gauge);

//         //check if there are extra rewards
//         address stash = pool.stash;
//         if(stash != address(0)){
//             //claim extra rewards
//             IStash(stash).claimRewards();
//             //process extra rewards
//             IStash(stash).processStash();
//         }

//         //crv balance
//         uint256 crvBal = IERC20(crv).balanceOf(address(this));

//         if (crvBal > 0) {
//             uint256 _lockIncentive = crvBal.mul(lockIncentive).div(FEE_DENOMINATOR);
//             uint256 _stakerIncentive = crvBal.mul(stakerIncentive).div(FEE_DENOMINATOR);
//             uint256 _callIncentive = crvBal.mul(earmarkIncentive).div(FEE_DENOMINATOR);
            
//             //send treasury
//             if(treasury != address(0) && treasury != address(this) && platformFee > 0){
//                 //only subtract after address condition check
//                 uint256 _platform = crvBal.mul(platformFee).div(FEE_DENOMINATOR);
//                 crvBal = crvBal.sub(_platform);
//                 IERC20(crv).safeTransfer(treasury, _platform);
//             }

//             //remove incentives from balance
//             crvBal = crvBal.sub(_lockIncentive).sub(_callIncentive).sub(_stakerIncentive);

//             //send incentives for calling
//             IERC20(crv).safeTransfer(msg.sender, _callIncentive);          

//             //send crv to lp provider reward contract
//             address rewardContract = pool.crvRewards;
//             IERC20(crv).safeTransfer(rewardContract, crvBal);
//             IRewards(rewardContract).queueNewRewards(crvBal);

//             //send lockers' share of crv to reward contract
//             IERC20(crv).safeTransfer(lockRewards, _lockIncentive);
//             IRewards(lockRewards).queueNewRewards(_lockIncentive);

//             //send stakers's share of crv to reward contract
//             IERC20(crv).safeTransfer(stakerRewards, _stakerIncentive);
//             IRewards(stakerRewards).queueNewRewards(_stakerIncentive);
//         }
//     }

//     function earmarkRewards(uint256 _pid) external returns(bool){
//         require(!isShutdown,"shutdown");
//         _earmarkRewards(_pid);
//         return true;
//     }

//     //claim fees from curve distro contract, put in lockers' reward contract
//     function earmarkFees() external returns(bool){
//         //claim fee rewards
//         IStaker(staker).claimFees(feeDistro, feeToken);
//         //send fee rewards to reward contract
//         uint256 _balance = IERC20(feeToken).balanceOf(address(this));
//         IERC20(feeToken).safeTransfer(lockFees, _balance);
//         IRewards(lockFees).queueNewRewards(_balance);
//         return true;
//     }

//     //callback from reward contract when crv is received.
//     function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns(bool){
//         address rewardContract = poolInfo[_pid].crvRewards;
//         require(msg.sender == rewardContract || msg.sender == lockRewards, "!auth");

//         //mint reward tokens
//         ITokenMinter(minter).mint(_address,_amount);
        
//         return true;
//     }

// }

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexBaseRewardPool {
  function addExtraReward(address _reward) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function currentRewards() external view returns (uint256);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward() external returns (bool);
  function getReward(address _account, bool _claimExtras) external returns (bool);
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function pid() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external returns (bool);
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external returns (bool);
  function stakeAll() external returns (bool);
  function stakeFor(address _for, uint256 _amount) external returns (bool);
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 amount, bool claim) external returns (bool);
  function withdrawAll(bool claim) external;
  function withdrawAllAndUnwrap(bool claim) external;
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IVirtualBalanceRewardPool {
    function balanceOf(address account) external view returns (uint256);
    function currentRewards() external view returns (uint256);
    function deposits() external view returns (address);
    function donate(uint256 _amount) external returns (bool);
    function duration() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getReward(address _account) external;
    function historicalRewards() external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function newRewardRatio() external view returns (uint256);
    function operator() external view returns (address);
    function periodFinish() external view returns (uint256);
    function queueNewRewards(uint256 _rewards) external;
    function queuedRewards() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardToken() external view returns (address);
    function rewards(address) external view returns (uint256);
    function stake(address _account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function userRewardPerTokenPaid(address) external view returns (uint256);
    function withdraw(address _account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexClaimZap {
  function chefRewards() external view returns (address);
  function claimRewards(address[] calldata rewardContracts, uint256[] calldata chefIds, bool claimCvx, bool claimCvxStake, bool claimcvxCrv, uint256 depositCrvMaxAmount, uint256 depositCvxMaxAmount) external;
  function crv() external view returns (address);
  function crvDeposit() external view returns (address);
  function cvx() external view returns (address);
  function cvxCrv() external view returns (address);
  function cvxCrvRewards() external view returns (address);
  function cvxRewards() external view returns (address);
  function owner() external view returns (address);
  function setApprovals() external;
  function setChefRewards(address _rewards) external;
}



// /**
//  * @dev Collection of functions related to the address type
//  */
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
//         // This method relies on extcodesize, which returns 0 for contracts in
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
//         return functionCallWithValue(target, data, 0, errorMessage);
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

//     /**
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
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
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
// }

// // File: @openzeppelin\contracts\token\ERC20\IERC20.sol
// pragma solidity >=0.6.0 <0.8.0;

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
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


// // File: node_modules\@openzeppelin\contracts\math\SafeMath.sol
// pragma solidity >=0.6.0 <0.8.0;

// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         uint256 c = a + b;
//         if (c < a) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the substraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b > a) return (false, 0);
//         return (true, a - b);
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) return (true, 0);
//         uint256 c = a * b;
//         if (c / a != b) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a / b);
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a % b);
//     }

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
//         require(b <= a, "SafeMath: subtraction overflow");
//         return a - b;
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
//         if (a == 0) return 0;
//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
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
//         require(b > 0, "SafeMath: division by zero");
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: modulo by zero");
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         return a - b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryDiv}.
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
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a % b;
//     }
// }


// // File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol
// pragma solidity >=0.6.0 <0.8.0;




// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
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

// // File: contracts\ClaimZap.sol
// pragma solidity 0.6.12;


// library Math {
//     /**
//      * @dev Returns the smallest of two numbers.
//      */
//     function min(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a < b ? a : b;
//     }
// }

// interface IBasicRewards{
//     function getReward(address _account, bool _claimExtras) external;
//     function stakeFor(address, uint256) external;
// }

// interface ICvxRewards{
//     function getReward(address _account, bool _claimExtras, bool _stake) external;
// }

// interface IChefRewards{
//     function claim(uint256 _pid, address _account) external;
// }

// interface ICvxCrvDeposit{
//     function deposit(uint256, bool) external;
// }

// contract ClaimZap{
//     using SafeERC20 for IERC20;
//     using Address for address;
//     using SafeMath for uint256;

//     address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
//     address public constant cvx = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
//     address public constant cvxCrv = address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
//     address public constant crvDeposit = address(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);
//     address public constant cvxCrvRewards = address(0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
//     address public constant cvxRewards = address(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);

//     address public immutable owner;
//     address public chefRewards;

//     constructor() public {
//         owner = msg.sender;
//         chefRewards = address(0x5F465e9fcfFc217c5849906216581a657cd60605);
//     }

//     function setChefRewards(address _rewards) external {
//         require(msg.sender == owner, "!auth");
//         chefRewards = _rewards;
//     }

//     function setApprovals() external {
//         require(msg.sender == owner, "!auth");
//         IERC20(crv).safeApprove(crvDeposit, 0);
//         IERC20(crv).safeApprove(crvDeposit, uint256(-1));
//         IERC20(cvx).safeApprove(cvxRewards, 0);
//         IERC20(cvx).safeApprove(cvxRewards, uint256(-1));
//         IERC20(cvxCrv).safeApprove(cvxCrvRewards, 0);
//         IERC20(cvxCrv).safeApprove(cvxCrvRewards, uint256(-1));
//     }

//     function claimRewards(
//         address[] calldata rewardContracts,
//         uint256[] calldata chefIds,
//         bool claimCvx,
//         bool claimCvxStake,
//         bool claimcvxCrv,
//         uint256 depositCrvMaxAmount,
//         uint256 depositCvxMaxAmount
//         ) external{

//         //claim from main curve LP pools
//         for(uint256 i = 0; i < rewardContracts.length; i++){
//             if(rewardContracts[i] == address(0)) break;
//             IBasicRewards(rewardContracts[i]).getReward(msg.sender,true);
//         }

//         //claim from master chef
//         for(uint256 i = 0; i < chefIds.length; i++){
//             IChefRewards(chefRewards).claim(chefIds[i],msg.sender);
//         }

//         //claim (and stake) from cvx rewards
//         if(claimCvxStake){
//             ICvxRewards(cvxRewards).getReward(msg.sender,true,true);
//         }else if(claimCvx){
//             ICvxRewards(cvxRewards).getReward(msg.sender,true,false);
//         }

//         //claim from cvxCrv rewards
//         if(claimcvxCrv){
//             IBasicRewards(cvxCrvRewards).getReward(msg.sender,true);
//         }

//         //lock upto given amount of crv and stake
//         if(depositCrvMaxAmount > 0){
//             uint256 crvBalance = IERC20(crv).balanceOf(msg.sender);
//             crvBalance = Math.min(crvBalance, depositCrvMaxAmount);
//             if(crvBalance > 0){
//                 //pull crv
//                 IERC20(crv).safeTransferFrom(msg.sender, address(this), crvBalance);
//                 //deposit
//                 ICvxCrvDeposit(crvDeposit).deposit(crvBalance,true);
//                 //get cvxamount
//                 uint256 cvxCrvBalance = IERC20(cvxCrv).balanceOf(address(this));
//                 //stake for msg.sender
//                 IBasicRewards(cvxCrvRewards).stakeFor(msg.sender, cvxCrvBalance);
//             }
//         }

//         //stake upto given amount of cvx
//         if(depositCvxMaxAmount > 0){
//             uint256 cvxBalance = IERC20(cvx).balanceOf(msg.sender);
//             cvxBalance = Math.min(cvxBalance, depositCvxMaxAmount);
//             if(cvxBalance > 0){
//                 //pull cvx
//                 IERC20(cvx).safeTransferFrom(msg.sender, address(this), cvxBalance);
//                 //stake for msg.sender
//                 IBasicRewards(cvxRewards).stakeFor(msg.sender, cvxBalance);
//             }
//         }
//     }
// }

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IcvxRewardPool {
  function FEE_DENOMINATOR() external view returns (uint256);
  function addExtraReward(address _reward) external;
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function crvDeposits() external view returns (address);
  function currentRewards() external view returns (uint256);
  function cvxCrvRewards() external view returns (address);
  function cvxCrvToken() external view returns (address);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward(bool _stake) external;
  function getReward(address _account, bool _claimExtras, bool _stake) external;
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external;
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external;
  function stakeAll() external;
  function stakeFor(address _for, uint256 _amount) external;
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 _amount, bool claim) external;
  function withdrawAll(bool claim) external;
}


// /**
//  * @dev Standard math utilities missing in the Solidity language.
//  */
// library MathUtil {
//     /**
//      * @dev Returns the smallest of two numbers.
//      */
//     function min(uint256 a, uint256 b) internal pure returns (uint256) {
//         return a < b ? a : b;
//     }
// }

// contract ReentrancyGuard {
//     uint256 private _guardCounter;

//     constructor () internal {
//         _guardCounter = 1;
//     }

//     modifier nonReentrant() {
//         _guardCounter += 1;
//         uint256 localCounter = _guardCounter;
//         _;
//         require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
//     }
// }

// interface ICurveGauge {
//     function deposit(uint256) external;
//     function balanceOf(address) external view returns (uint256);
//     function withdraw(uint256) external;
//     function claim_rewards() external;
//     function reward_tokens(uint256) external view returns(address);//v2
//     function rewarded_token() external view returns(address);//v1
// }

// interface ICurveVoteEscrow {
//     function create_lock(uint256, uint256) external;
//     function increase_amount(uint256) external;
//     function increase_unlock_time(uint256) external;
//     function withdraw() external;
//     function smart_wallet_checker() external view returns (address);
// }

// interface IWalletChecker {
//     function check(address) external view returns (bool);
// }

// interface IVoting{
//     function vote(uint256, bool, bool) external; //voteId, support, executeIfDecided
//     function getVote(uint256) external view returns(bool,bool,uint64,uint64,uint64,uint64,uint256,uint256,uint256,bytes memory); 
//     function vote_for_gauge_weights(address,uint256) external;
// }

// interface IMinter{
//     function mint(address) external;
// }

// interface IRegistry{
//     function get_registry() external view returns(address);
//     function get_address(uint256 _id) external view returns(address);
//     function gauge_controller() external view returns(address);
//     function get_lp_token(address) external view returns(address);
//     function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
// }

// interface IStaker{
//     function deposit(address, address) external;
//     function withdraw(address) external;
//     function withdraw(address, address, uint256) external;
//     function withdrawAll(address, address) external;
//     function createLock(uint256, uint256) external;
//     function increaseAmount(uint256) external;
//     function increaseTime(uint256) external;
//     function release() external;
//     function claimCrv(address) external returns (uint256);
//     function claimRewards(address) external;
//     function claimFees(address,address) external;
//     function setStashAccess(address, bool) external;
//     function vote(uint256,address,bool) external;
//     function voteGaugeWeight(address,uint256) external;
//     function balanceOfPool(address) external view returns (uint256);
//     function operator() external view returns (address);
//     function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
// }

// interface IRewards{
//     function stake(address, uint256) external;
//     function stakeFor(address, uint256) external;
//     function withdraw(address, uint256) external;
//     function exit(address) external;
//     function getReward(address) external;
//     function queueNewRewards(uint256) external;
//     function notifyRewardAmount(uint256) external;
//     function addExtraReward(address) external;
//     function stakingToken() external returns (address);
// }

// interface IStash{
//     function stashRewards() external returns (bool);
//     function processStash() external returns (bool);
//     function claimRewards() external returns (bool);
// }

// interface IFeeDistro{
//     function claim() external;
//     function token() external view returns(address);
// }

// interface ITokenMinter{
//     function mint(address,uint256) external;
//     function burn(address,uint256) external;
// }

// interface IDeposit{
//     function isShutdown() external view returns(bool);
//     function balanceOf(address _account) external view returns(uint256);
//     function totalSupply() external view returns(uint256);
//     function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
//     function rewardClaimed(uint256,address,uint256) external;
//     function withdrawTo(uint256,uint256,address) external;
//     function claimRewards(uint256,address) external returns(bool);
//     function rewardArbitrator() external returns(address);
// }

// interface ICrvDeposit{
//     function deposit(uint256, bool) external;
//     function lockIncentive() external view returns(uint256);
// }

// interface IRewardFactory{
//     function setAccess(address,bool) external;
//     function CreateCrvRewards(uint256,address) external returns(address);
//     function CreateTokenRewards(address,address,address) external returns(address);
//     function activeRewardCount(address) external view returns(uint256);
//     function addActiveReward(address,uint256) external returns(bool);
//     function removeActiveReward(address,uint256) external returns(bool);
// }

// interface IStashFactory{
//     function CreateStash(uint256,address,address,uint256) external returns(address);
// }

// interface ITokenFactory{
//     function CreateDepositToken(address) external returns(address);
// }

// interface IPools{
//     function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns(bool);
//     function shutdownPool(uint256 _pid) external returns(bool);
//     function poolInfo(uint256) external view returns(address,address,address,address,address,bool);
//     function poolLength() external view returns (uint256);
//     function gaugeMap(address) external view returns(bool);
//     function setPoolManager(address _poolM) external;
// }



// /**
//  * @dev Wrappers over Solidity's arithmetic operations with added overflow
//  * checks.
//  *
//  * Arithmetic operations in Solidity wrap on overflow. This can easily result
//  * in bugs, because programmers usually assume that an overflow raises an
//  * error, which is the standard behavior in high level programming languages.
//  * `SafeMath` restores this intuition by reverting the transaction when an
//  * operation overflows.
//  *
//  * Using this library instead of the unchecked operations eliminates an entire
//  * class of bugs, so it's recommended to use it always.
//  */
// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         uint256 c = a + b;
//         if (c < a) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the substraction of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b > a) return (false, 0);
//         return (true, a - b);
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) return (true, 0);
//         uint256 c = a * b;
//         if (c / a != b) return (false, 0);
//         return (true, c);
//     }

//     /**
//      * @dev Returns the division of two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a / b);
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
//      *
//      * _Available since v3.4._
//      */
//     function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
//         if (b == 0) return (false, 0);
//         return (true, a % b);
//     }

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
//         require(b <= a, "SafeMath: subtraction overflow");
//         return a - b;
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
//         if (a == 0) return 0;
//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");
//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting on
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
//         require(b > 0, "SafeMath: division by zero");
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         require(b > 0, "SafeMath: modulo by zero");
//         return a % b;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {trySub}.
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         return a - b;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers, reverting with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryDiv}.
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
//         return a / b;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * reverting with custom message when dividing by zero.
//      *
//      * CAUTION: This function is deprecated because it requires allocating memory for the error
//      * message unnecessarily. For custom revert reasons use {tryMod}.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         return a % b;
//     }
// }

// // File: @openzeppelin\contracts\token\ERC20\IERC20.sol
// pragma solidity >=0.6.0 <0.8.0;

// /**
//  * @dev Interface of the ERC20 standard as defined in the EIP.
//  */
// interface IERC20 {
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

// // File: @openzeppelin\contracts\utils\Address.sol

// pragma solidity >=0.6.2 <0.8.0;

// /**
//  * @dev Collection of functions related to the address type
//  */
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
//         // This method relies on extcodesize, which returns 0 for contracts in
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
//         return functionCallWithValue(target, data, 0, errorMessage);
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

//     /**
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
//      * _Available since v3.4._
//      */
//     function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
//         return functionDelegateCall(target, data, "Address: low-level delegate call failed");
//     }

//     /**
//      * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
//      * but performing a delegate call.
//      *
//      * _Available since v3.4._
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
// }


// // File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

// pragma solidity >=0.6.0 <0.8.0;


// /**
//  * @title SafeERC20
//  * @dev Wrappers around ERC20 operations that throw on failure (when the token
//  * contract returns false). Tokens that return no value (and instead revert or
//  * throw on failure) are also supported, non-reverting calls are assumed to be
//  * successful.
//  * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
//  * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
//  */
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

// // File: contracts\cvxRewardPool.sol

// pragma solidity 0.6.12;
// /**
//  *Submitted for verification at Etherscan.io on 2020-07-17
//  */

// /*
//    ____            __   __        __   _
//   / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
//  _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
// /___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
//      /___/

// * Synthetix: cvxRewardPool.sol
// *
// * Docs: https://docs.synthetix.io/
// *
// *
// * MIT License
// * ===========
// *
// * Copyright (c) 2020 Synthetix
// *
// * Permission is hereby granted, free of charge, to any person obtaining a copy
// * of this software and associated documentation files (the "Software"), to deal
// * in the Software without restriction, including without limitation the rights
// * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// * copies of the Software, and to permit persons to whom the Software is
// * furnished to do so, subject to the following conditions:
// *
// * The above copyright notice and this permission notice shall be included in all
// * copies or substantial portions of the Software.
// *
// * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// */



// contract cvxRewardPool{
//     using SafeERC20 for IERC20;
//     using SafeMath for uint256;

//     IERC20 public immutable rewardToken;
//     IERC20 public immutable stakingToken;
//     uint256 public constant duration = 7 days;
//     uint256 public constant FEE_DENOMINATOR = 10000;

//     address public immutable operator;
//     address public immutable crvDeposits;
//     address public immutable cvxCrvRewards;
//     IERC20 public immutable cvxCrvToken;
//     address public immutable rewardManager;

//     uint256 public periodFinish = 0;
//     uint256 public rewardRate = 0;
//     uint256 public lastUpdateTime;
//     uint256 public rewardPerTokenStored;
//     uint256 public queuedRewards = 0;
//     uint256 public currentRewards = 0;
//     uint256 public historicalRewards = 0;
//     uint256 public constant newRewardRatio = 830;
//     uint256 private _totalSupply;
//     mapping(address => uint256) private _balances;
//     mapping(address => uint256) public userRewardPerTokenPaid;
//     mapping(address => uint256) public rewards;

//     address[] public extraRewards;

//     event RewardAdded(uint256 reward);
//     event Staked(address indexed user, uint256 amount);
//     event Withdrawn(address indexed user, uint256 amount);
//     event RewardPaid(address indexed user, uint256 reward);

//     constructor(
//         address stakingToken_,
//         address rewardToken_,
//         address crvDeposits_,
//         address cvxCrvRewards_,
//         address cvxCrvToken_,
//         address operator_,
//         address rewardManager_
//     ) public {
//         stakingToken = IERC20(stakingToken_);
//         rewardToken = IERC20(rewardToken_);
//         operator = operator_;
//         rewardManager = rewardManager_;
//         crvDeposits = crvDeposits_;
//         cvxCrvRewards = cvxCrvRewards_;
//         cvxCrvToken = IERC20(cvxCrvToken_);
//     }

//     function totalSupply() public view returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address account) public view returns (uint256) {
//         return _balances[account];
//     }

//     function extraRewardsLength() external view returns (uint256) {
//         return extraRewards.length;
//     }

//     function addExtraReward(address _reward) external {
//         require(msg.sender == rewardManager, "!authorized");
//         require(_reward != address(0),"!reward setting");

//         extraRewards.push(_reward);
//     }
//     function clearExtraRewards() external{
//         require(msg.sender == rewardManager, "!authorized");
//         delete extraRewards;
//     }

//     modifier updateReward(address account) {
//         rewardPerTokenStored = rewardPerToken();
//         lastUpdateTime = lastTimeRewardApplicable();
//         if (account != address(0)) {
//             rewards[account] = earnedReward(account);
//             userRewardPerTokenPaid[account] = rewardPerTokenStored;
//         }
//         _;
//     }

//     function lastTimeRewardApplicable() public view returns (uint256) {
//         return MathUtil.min(block.timestamp, periodFinish);
//     }

//     function rewardPerToken() public view returns (uint256) {
//         uint256 supply = totalSupply();
//         if (supply == 0) {
//             return rewardPerTokenStored;
//         }
//         return
//             rewardPerTokenStored.add(
//                 lastTimeRewardApplicable()
//                     .sub(lastUpdateTime)
//                     .mul(rewardRate)
//                     .mul(1e18)
//                     .div(supply)
//             );
//     }

//     function earnedReward(address account) internal view returns (uint256) {
//         return
//             balanceOf(account)
//                 .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
//                 .div(1e18)
//                 .add(rewards[account]);
//     }

//     function earned(address account) external view returns (uint256) {
//         uint256 depositFeeRate = ICrvDeposit(crvDeposits).lockIncentive();

//         uint256 r = earnedReward(account);
//         uint256 fees = r.mul(depositFeeRate).div(FEE_DENOMINATOR);
        
//         //fees dont apply until whitelist+vecrv lock begins so will report
//         //slightly less value than what is actually received.
//         return r.sub(fees);
//     }

//     function stake(uint256 _amount)
//         public
//         updateReward(msg.sender)
//     {
//         require(_amount > 0, 'RewardPool : Cannot stake 0');

//         //also stake to linked rewards
//         uint256 length = extraRewards.length;
//         for(uint i=0; i < length; i++){
//             IRewards(extraRewards[i]).stake(msg.sender, _amount);
//         }

//         //add supply
//         _totalSupply = _totalSupply.add(_amount);
//         //add to sender balance sheet
//         _balances[msg.sender] = _balances[msg.sender].add(_amount);
//         //take tokens from sender
//         stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

//         emit Staked(msg.sender, _amount);
//     }

//     function stakeAll() external{
//         uint256 balance = stakingToken.balanceOf(msg.sender);
//         stake(balance);
//     }

//     function stakeFor(address _for, uint256 _amount)
//         public
//         updateReward(_for)
//     {
//         require(_amount > 0, 'RewardPool : Cannot stake 0');

//         //also stake to linked rewards
//         uint256 length = extraRewards.length;
//         for(uint i=0; i < length; i++){
//             IRewards(extraRewards[i]).stake(_for, _amount);
//         }

//          //add supply
//         _totalSupply = _totalSupply.add(_amount);
//         //add to _for's balance sheet
//         _balances[_for] = _balances[_for].add(_amount);
//         //take tokens from sender
//         stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

//         emit Staked(msg.sender, _amount);
//     }

//     function withdraw(uint256 _amount, bool claim)
//         public
//         updateReward(msg.sender)
//     {
//         require(_amount > 0, 'RewardPool : Cannot withdraw 0');

//         //also withdraw from linked rewards
//         uint256 length = extraRewards.length;
//         for(uint i=0; i < length; i++){
//             IRewards(extraRewards[i]).withdraw(msg.sender, _amount);
//         }

//         _totalSupply = _totalSupply.sub(_amount);
//         _balances[msg.sender] = _balances[msg.sender].sub(_amount);
//         stakingToken.safeTransfer(msg.sender, _amount);
//         emit Withdrawn(msg.sender, _amount);

//         if(claim){
//             getReward(msg.sender,true,false);
//         }
//     }

//     function withdrawAll(bool claim) external{
//         withdraw(_balances[msg.sender],claim);
//     }

//     function getReward(address _account, bool _claimExtras, bool _stake) public updateReward(_account){
//         uint256 reward = earnedReward(_account);
//         if (reward > 0) {
//             rewards[_account] = 0;
//             rewardToken.safeApprove(crvDeposits,0);
//             rewardToken.safeApprove(crvDeposits,reward);
//             ICrvDeposit(crvDeposits).deposit(reward,false);

//             uint256 cvxCrvBalance = cvxCrvToken.balanceOf(address(this));
//             if(_stake){
//                 IERC20(cvxCrvToken).safeApprove(cvxCrvRewards,0);
//                 IERC20(cvxCrvToken).safeApprove(cvxCrvRewards,cvxCrvBalance);
//                 IRewards(cvxCrvRewards).stakeFor(_account,cvxCrvBalance);
//             }else{
//                 cvxCrvToken.safeTransfer(_account, cvxCrvBalance);
//             }
//             emit RewardPaid(_account, cvxCrvBalance);
//         }

//         //also get rewards from linked rewards
//         if(_claimExtras){
//             uint256 length = extraRewards.length;
//             for(uint i=0; i < length; i++){
//                 IRewards(extraRewards[i]).getReward(_account);
//             }
//         }
//     }

//     function getReward(bool _stake) external{
//         getReward(msg.sender,true, _stake);
//     }

//     function donate(uint256 _amount) external returns(bool){
//         IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
//         queuedRewards = queuedRewards.add(_amount);
//     }

//     function queueNewRewards(uint256 _rewards) external{
//         require(msg.sender == operator, "!authorized");

//         _rewards = _rewards.add(queuedRewards);

//         if (block.timestamp >= periodFinish) {
//             notifyRewardAmount(_rewards);
//             queuedRewards = 0;
//             return;
//         }

//         //et = now - (finish-duration)
//         uint256 elapsedTime = block.timestamp.sub(periodFinish.sub(duration));
//         //current at now: rewardRate * elapsedTime
//         uint256 currentAtNow = rewardRate * elapsedTime;
//         uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);
//         if(queuedRatio < newRewardRatio){
//             notifyRewardAmount(_rewards);
//             queuedRewards = 0;
//         }else{
//             queuedRewards = _rewards;
//         }
//     }

//     function notifyRewardAmount(uint256 reward)
//         internal
//         updateReward(address(0))
//     {
//         historicalRewards = historicalRewards.add(reward);
//         if (block.timestamp >= periodFinish) {
//             rewardRate = reward.div(duration);
//         } else {
//             uint256 remaining = periodFinish.sub(block.timestamp);
//             uint256 leftover = remaining.mul(rewardRate);
//             reward = reward.add(leftover);
//             rewardRate = reward.div(duration);
//         }
//         currentRewards = reward;
//         lastUpdateTime = block.timestamp;
//         periodFinish = block.timestamp.add(duration);
//         emit RewardAdded(reward);
//     }
// }

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

{
  "optimizer": {
    "enabled": true,
    "runs": 100000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}