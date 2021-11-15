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
// ============================ CurveAMO_V3 ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Travis Moore: https://github.com/FortisFortuna
// Jason Huan: https://github.com/jasonhuan

// Reviewer(s) / Contributor(s)
// Sam Kazemian: https://github.com/samkazemian
// github.com/denett


import "./IStableSwap3Pool.sol";
import "./IMetaImplementationUSD.sol";
import "../Misc_AMOs/yearn/IYearnVault.sol";
import "../ERC20/ERC20.sol";
import "../Frax/Frax.sol";
import "../FXS/FXS.sol";
import "../Math/SafeMath.sol";
import "../Proxy/Initializable.sol";

contract CurveAMO_V3 is AccessControl, Initializable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IMetaImplementationUSD private frax3crv_metapool;
    IStableSwap3Pool private three_pool;
    IYearnVault private crvFRAX_vault;
    ERC20 private three_pool_erc20;
    FRAXStablecoin private FRAX;
    FraxPool private pool;
    ERC20 private collateral_token;

    address private three_pool_address;
    address private three_pool_token_address;
    address private fxs_contract_address;
    address private collateral_token_address;
    address private crv_address;

    address public frax3crv_metapool_address;
    address public crvFRAX_vault_address;
    address public timelock_address;
    address public owner_address;
    address public custodian_address;
    address public pool_address;
    address public voter_contract_address; // FRAX3CRV and CRV will be sent here for veCRV voting, locked LP boosts, etc

    // Tracks FRAX
    uint256 public minted_frax_historical;
    uint256 public burned_frax_historical;

    // Max amount of FRAX outstanding the contract can mint from the FraxPool
    uint256 public max_frax_outstanding;
    
    // Tracks collateral
    uint256 public borrowed_collat_historical;
    uint256 public returned_collat_historical;

    // Max amount of collateral the contract can borrow from the FraxPool
    uint256 public collat_borrow_cap;

    // Minimum collateral ratio needed for new FRAX minting
    uint256 public min_cr;

    // Number of decimals under 18, for collateral token
    uint256 private missing_decimals;

    // Precision related
    uint256 private PRICE_PRECISION;

    // Min ratio of collat <-> 3crv conversions via add_liquidity / remove_liquidity; 1e6
    uint256 public liq_slippage_3crv;

    // Min ratio of (FRAX + 3CRV) <-> FRAX3CRV-f-2 metapool conversions via add_liquidity / remove_liquidity; 1e6
    uint256 public add_liq_slippage_metapool;
    uint256 public rem_liq_slippage_metapool;

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
        address _fxs_contract_address,
        address _collateral_address,
        address _creator_address,
        address _custodian_address,
        address _timelock_address,
        address _frax3crv_metapool_address,
        address _three_pool_address,
        address _three_pool_token_address,
        address _pool_address
    ) public payable initializer {
        FRAX = FRAXStablecoin(_frax_contract_address);
        fxs_contract_address = _fxs_contract_address;
        collateral_token_address = _collateral_address;
        collateral_token = ERC20(_collateral_address);
        crv_address = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        missing_decimals = uint(18).sub(collateral_token.decimals());
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        custodian_address = _custodian_address;
        voter_contract_address = _custodian_address; // Default to the custodian

        frax3crv_metapool_address = _frax3crv_metapool_address;
        frax3crv_metapool = IMetaImplementationUSD(_frax3crv_metapool_address);
        three_pool_address = _three_pool_address;
        three_pool = IStableSwap3Pool(_three_pool_address);
        three_pool_token_address = _three_pool_token_address;
        three_pool_erc20 = ERC20(_three_pool_token_address);
        pool_address = _pool_address;
        pool = FraxPool(_pool_address);

        crvFRAX_vault_address = 0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139;
        crvFRAX_vault = IYearnVault(0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139);

        // Other variable initializations
        minted_frax_historical = 0;
        burned_frax_historical = 0;
        max_frax_outstanding = uint256(2000000e18);
        borrowed_collat_historical = 0;
        returned_collat_historical = 0;
        collat_borrow_cap = uint256(1000000e6);
        min_cr = 850000;
        PRICE_PRECISION = 1e6;
        liq_slippage_3crv = 800000;
        add_liq_slippage_metapool = 950000;
        rem_liq_slippage_metapool = 950000;
        convergence_window = 1e16;
        custom_floor = false;  
        set_discount = false;
        override_collat_balance = false;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "Must be owner or timelock");
        _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodian_address, "Must be rewards custodian");
        _;
    }

    modifier onlyCustodianOrVoter() {
        require(msg.sender == custodian_address || msg.sender == voter_contract_address, "Must be rewards custodian or the voter contract");
        _;
    }

    // modifier onlyVoter() {
    //     require(msg.sender == voter_contract_address, "Must be voter contract");
    //     _;
    // }

    /* ========== VIEWS ========== */

    function showAllocations() public view returns (uint256[11] memory return_arr) {
        // ------------LP Balance------------

        // Free LP
        uint256 lp_owned = (frax3crv_metapool.balanceOf(address(this)));

        // Staked in the vault
        uint256 lp_value_in_vault = usdValueInVault();
        lp_owned = lp_owned.add(lp_value_in_vault);

        // ------------3pool Withdrawable------------
        // Uses iterate() to get metapool withdrawable amounts at FRAX floor price (global_collateral_ratio)
        uint256 frax3crv_supply = frax3crv_metapool.totalSupply();

        uint256 frax_withdrawable;
        uint256 _3pool_withdrawable;
        (frax_withdrawable, _3pool_withdrawable, ) = iterate();
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
            frax_in_contract, // [0]
            frax_withdrawable, // [1]
            frax_withdrawable.add(frax_in_contract), // [2]
            usdc_in_contract, // [3]
            usdc_withdrawable, // [4]
            usdc_subtotal, // [5]
            usdc_subtotal + (frax_in_contract.add(frax_withdrawable)).mul(fraxDiscountRate()).div(1e6 * (10 ** missing_decimals)), // [6] USDC Total
            lp_owned, // [7]
            frax3crv_supply, // [8]
            _3pool_withdrawable, // [9]
            lp_value_in_vault // [10]
        ];
    }

    function collatDollarBalance() public view returns (uint256) {
        if(override_collat_balance){
            return override_collat_balance_amount;
        }
        return (showAllocations()[6] * (10 ** missing_decimals));
    }

    // Returns hypothetical reserves of metapool if the FRAX price went to the CR,
    // assuming no removal of liquidity from the metapool.
    function iterate() public view returns (uint256, uint256, uint256) {
        uint256 frax_balance = FRAX.balanceOf(frax3crv_metapool_address);
        uint256 crv3_balance = three_pool_erc20.balanceOf(frax3crv_metapool_address);

        uint256 floor_price_frax = uint(1e18).mul(fraxFloor()).div(1e6);
        
        uint256 crv3_received;
        uint256 dollar_value; // 3crv is usually slightly above $1 due to collecting 3pool swap fees
        uint256 virtual_price = three_pool.get_virtual_price();
        for(uint i = 0; i < 256; i++){
            crv3_received = frax3crv_metapool.get_dy(0, 1, 1e18, [frax_balance, crv3_balance]);
            dollar_value = crv3_received.mul(1e18).div(virtual_price);
            if(dollar_value <= floor_price_frax.add(convergence_window)){
                return (frax_balance, crv3_balance, i);
            }
            uint256 frax_to_swap = frax_balance.div(10);
            crv3_balance = crv3_balance.sub(frax3crv_metapool.get_dy(0, 1, frax_to_swap, [frax_balance, crv3_balance]));
            frax_balance = frax_balance.add(frax_to_swap);
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

    // In FRAX
    function fraxBalance() public view returns (uint256) {
        if (minted_frax_historical >= burned_frax_historical) return minted_frax_historical.sub(burned_frax_historical);
        else return 0;
    }

    // In collateral
    function collateralBalance() public view returns (uint256) {
        if (borrowed_collat_historical >= returned_collat_historical) return borrowed_collat_historical.sub(returned_collat_historical);
        else return 0;
    }


    // Amount of FRAX3CRV deposited in the vault contract
    function yvCurveFRAXBalance() public view returns (uint256){
        return crvFRAX_vault.balanceOf(address(this));
    }

    function usdValueInVault() public view returns (uint256){
        uint256 yvCurveFrax_balance = yvCurveFRAXBalance();
        return yvCurveFrax_balance.mul(crvFRAX_vault.pricePerShare()).div(1e18);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // This is basically a workaround to transfer USDC from the FraxPool to this investor contract
    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main FRAX contract
    // It mints FRAX from nothing, and redeems it on the target pool for collateral and FXS
    // The burn can be called separately later on
    function mintRedeemPart1(uint256 frax_amount) external onlyByOwnerOrGovernance {
        //require(allow_yearn || allow_aave || allow_compound, 'All strategies are currently off');
        uint256 redemption_fee = pool.redemption_fee();
        uint256 col_price_usd = pool.getCollateralPrice();
        uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
        uint256 redeem_amount_E6 = (frax_amount.mul(uint256(1e6).sub(redemption_fee))).div(1e6).div(10 ** missing_decimals);
        uint256 expected_collat_amount = redeem_amount_E6.mul(global_collateral_ratio).div(1e6);
        expected_collat_amount = expected_collat_amount.mul(1e6).div(col_price_usd);

        require(collateralBalance().add(expected_collat_amount) <= collat_borrow_cap, "Borrow cap");
        borrowed_collat_historical = borrowed_collat_historical.add(expected_collat_amount);

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
        collateral_token.transfer(address(pool), amount);
        returned_collat_historical = returned_collat_historical.add(amount);
    }
   
    // Burn unneeded or excess FRAX
    function burnFRAX(uint256 frax_amount) public onlyByOwnerOrGovernance {
        FRAX.burn(frax_amount);
        burned_frax_historical = burned_frax_historical.add(frax_amount);
    }
   
    function burnFXS(uint256 amount) public onlyByOwnerOrGovernance {
        FRAXShares(fxs_contract_address).approve(address(this), amount);
        FRAXShares(fxs_contract_address).pool_burn_from(address(this), amount);
    }

    function metapoolDeposit(uint256 _frax_amount, uint256 _collateral_amount) external onlyByOwnerOrGovernance returns (uint256 metapool_LP_received) {
        // Mint the FRAX component
        FRAX.pool_mint(address(this), _frax_amount);
        minted_frax_historical = minted_frax_historical.add(_frax_amount);
        require(fraxBalance() <= max_frax_outstanding, "max_frax_outstanding reached");

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
            uint256 min_lp_out = (_frax_amount.add(threeCRV_received)).mul(add_liq_slippage_metapool).div(PRICE_PRECISION);
            metapool_LP_received = frax3crv_metapool.add_liquidity([_frax_amount, threeCRV_received], min_lp_out);
        }

        // Make sure the collateral ratio did not fall too much
        uint256 current_collateral_E18 = (FRAX.globalCollateralValue()).mul(10 ** missing_decimals);
        uint256 cur_frax_supply = FRAX.totalSupply();
        uint256 new_cr = (current_collateral_E18.mul(PRICE_PRECISION)).div(cur_frax_supply);
        require (new_cr >= min_cr, "CR would be too low");
        
        return metapool_LP_received;
    }

    function metapoolWithdrawAtCurRatio(uint256 _metapool_lp_in, bool burn_the_frax, uint256 min_frax, uint256 min_3pool) external onlyByOwnerOrGovernance returns (uint256 frax_received) {
        // Approve the metapool LP tokens for the metapool contract
        frax3crv_metapool.approve(address(this), _metapool_lp_in);

        // Withdraw FRAX and 3pool from the metapool at the current balance
        uint256 three_pool_received;
        {
            uint256[2] memory result_arr = frax3crv_metapool.remove_liquidity(_metapool_lp_in, [min_frax, min_3pool]);
            frax_received = result_arr[0];
            three_pool_received = result_arr[1];
        }

        // Convert the 3pool into the collateral
        three_pool_erc20.approve(address(three_pool), 0);
        three_pool_erc20.approve(address(three_pool), three_pool_received);
        {
            // Add the FRAX and the collateral to the metapool
            uint256 min_collat_out = three_pool_received.mul(liq_slippage_3crv).div(PRICE_PRECISION * (10 ** missing_decimals));
            three_pool.remove_liquidity_one_coin(three_pool_received, 1, min_collat_out);
        }

        // Optionally burn the FRAX
        if (burn_the_frax){
            burnFRAX(frax_received);
        }
        
    }

    function metapoolWithdrawFrax(uint256 _metapool_lp_in, bool burn_the_frax) external onlyByOwnerOrGovernance returns (uint256 frax_received) {
        // Withdraw FRAX from the metapool
        uint256 min_frax_out = _metapool_lp_in.mul(rem_liq_slippage_metapool).div(PRICE_PRECISION);
        frax_received = frax3crv_metapool.remove_liquidity_one_coin(_metapool_lp_in, 0, min_frax_out);

        // Optionally burn the FRAX
        if (burn_the_frax){
            burnFRAX(frax_received);
        }
    }

    function metapoolWithdraw3pool(uint256 _metapool_lp_in) public onlyByOwnerOrGovernance {
        // Withdraw 3pool from the metapool
        uint256 min_3pool_out = _metapool_lp_in.mul(rem_liq_slippage_metapool).div(PRICE_PRECISION);
        frax3crv_metapool.remove_liquidity_one_coin(_metapool_lp_in, 1, min_3pool_out);
    }

    function three_pool_to_collateral(uint256 _3pool_in) public onlyByOwnerOrGovernance {
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

    // Deposit Metapool LP tokens into the Curve DAO for vault rewards, if any
    function depositToVault(uint256 _metapool_lp_in) external onlyByOwnerOrGovernance {
        // Approve the metapool LP tokens for the vault contract
        frax3crv_metapool.approve(address(crvFRAX_vault), _metapool_lp_in);
        
        // Deposit the metapool LP into the vault contract
        crvFRAX_vault.deposit(_metapool_lp_in, address(this));
    }

    // Withdraw Metapool LP from Curve DAO back to this contract
    function withdrawFromVault(uint256 _metapool_lp_out) external onlyByOwnerOrGovernance {
        crvFRAX_vault.withdraw(_metapool_lp_out, address(this), 1);
    }

    // Same as withdrawFromVault, but with manual loss override
    // 1 = 0.01% [BPS]
    function withdrawFromVaultMaxLoss(uint256 _metapool_lp_out, uint256 maxloss) external onlyByOwnerOrGovernance {
        crvFRAX_vault.withdraw(_metapool_lp_out, address(this), maxloss);
    }

    /* ========== Custodian / Voter========== */

    // NOTE: The custodian_address or voter_contract_addresse can be set to the governance contract to be used as
    // a mega-voter or sorts. The CRV here can then be converted to veCRV and then used to vote
    function withdrawCRVRewards() external onlyCustodianOrVoter {
        ERC20(crv_address).transfer(msg.sender, ERC20(crv_address).balanceOf(address(this)));
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

    function setVoterContract(address _voter_contract_address) external onlyByOwnerOrGovernance {
        voter_contract_address = _voter_contract_address;
    }

    function setPool(address _pool_address) external onlyByOwnerOrGovernance {
        pool_address = _pool_address;
        pool = FraxPool(_pool_address);
    }

    function setThreePool(address _three_pool_address, address _three_pool_token_address) external onlyByOwnerOrGovernance {
        three_pool_address = _three_pool_address;
        three_pool = IStableSwap3Pool(_three_pool_address);
        three_pool_token_address = _three_pool_token_address;
        three_pool_erc20 = ERC20(_three_pool_token_address);
    }

    function setMetapool(address _metapool_address) external onlyByOwnerOrGovernance {
        frax3crv_metapool_address = _metapool_address;
        frax3crv_metapool = IMetaImplementationUSD(_metapool_address);
    }

    function setVault(address _crvFRAX_vault_address) external onlyByOwnerOrGovernance {
        crvFRAX_vault_address = _crvFRAX_vault_address;
        crvFRAX_vault = IYearnVault(_crvFRAX_vault_address);
    }

    function setCollatBorrowCap(uint256 _collat_borrow_cap) external onlyByOwnerOrGovernance {
        collat_borrow_cap = _collat_borrow_cap;
    }

    function setMaxFraxOutstanding(uint256 _max_frax_outstanding) external onlyByOwnerOrGovernance {
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

    function setSlippages(uint256 _liq_slippage_3crv, uint256 _add_liq_slippage_metapool, uint256 _rem_liq_slippage_metapool) external onlyByOwnerOrGovernance {
        liq_slippage_3crv = _liq_slippage_3crv;
        add_liq_slippage_metapool = _add_liq_slippage_metapool;
        rem_liq_slippage_metapool = _rem_liq_slippage_metapool;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerOrGovernance {
        // Can only be triggered by owner or governance, not custodian
        // Tokens are sent to the custodian, as a sort of safeguard
        ERC20(tokenAddress).transfer(custodian_address, tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import '../../ERC20/IERC20.sol';

// Address [0xB4AdA607B9d6b2c9Ee07A275e9616B84AC560139] used is a proxy
// Some functions were omitted for brevity. See the contract for details

interface IYearnVault is IERC20 {
    function deposit(uint256 _amount, address recipient) external returns (uint256);
    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss) external returns (uint256);
    function pricePerShare() external view returns (uint256);
}

// """
// @title Yearn Token Vault
// @license GNU AGPLv3
// @author yearn.finance
// @notice
//     Yearn Token Vault. Holds an underlying token, and allows users to interact
//     with the Yearn ecosystem through Strategies connected to the Vault.
//     Vaults are not limited to a single Strategy, they can have as many Strategies
//     as can be designed (however the withdrawal queue is capped at 20.)

//     Deposited funds are moved into the most impactful strategy that has not
//     already reached its limit for assets under management, regardless of which
//     Strategy a user's funds end up in, they receive their portion of yields
//     generated across all Strategies.

//     When a user withdraws, if there are no funds sitting undeployed in the
//     Vault, the Vault withdraws funds from Strategies in the order of least
//     impact. (Funds are taken from the Strategy that will disturb everyone's
//     gains the least, then the next least, etc.) In order to achieve this, the
//     withdrawal queue's order must be properly set and managed by the community
//     (through governance).

//     Vault Strategies are parameterized to pursue the highest risk-adjusted yield.

//     There is an "Emergency Shutdown" mode. When the Vault is put into emergency
//     shutdown, assets will be recalled from the Strategies as quickly as is
//     practical (given on-chain conditions), minimizing loss. Deposits are
//     halted, new Strategies may not be added, and each Strategy exits with the
//     minimum possible damage to position, while opening up deposits to be
//     withdrawn by users. There are no restrictions on withdrawals above what is
//     expected under Normal Operation.

//     For further details, please refer to the specification:
//     https://github.com/iearn-finance/yearn-vaults/blob/master/SPECIFICATION.md
// """

// API_VERSION: constant(String[28]) = "0.3.5"

// from vyper.interfaces import ERC20

// implements: ERC20


// interface DetailedERC20:
//     def name() -> String[42]: view
//     def symbol() -> String[20]: view
//     def decimals() -> uint256: view


// interface Strategy:
//     def want() -> address: view
//     def vault() -> address: view
//     def isActive() -> bool: view
//     def delegatedAssets() -> uint256: view
//     def estimatedTotalAssets() -> uint256: view
//     def withdraw(_amount: uint256) -> uint256: nonpayable
//     def migrate(_newStrategy: address): nonpayable


// interface GuestList:
//     def authorized(guest: address, amount: uint256) -> bool: view


// event Transfer:
//     sender: indexed(address)
//     receiver: indexed(address)
//     value: uint256


// event Approval:
//     owner: indexed(address)
//     spender: indexed(address)
//     value: uint256


// name: public(String[64])
// symbol: public(String[32])
// decimals: public(uint256)
// precisionFactor: public(uint256)

// balanceOf: public(HashMap[address, uint256])
// allowance: public(HashMap[address, HashMap[address, uint256]])
// totalSupply: public(uint256)

// token: public(ERC20)
// governance: public(address)
// management: public(address)
// guardian: public(address)
// pendingGovernance: address
// guestList: public(GuestList)

// struct StrategyParams:
//     performanceFee: uint256  # Strategist's fee (basis points)
//     activation: uint256  # Activation block.timestamp
//     debtRatio: uint256  # Maximum borrow amount (in BPS of total assets)
//     minDebtPerHarvest: uint256  # Lower limit on the increase of debt since last harvest
//     maxDebtPerHarvest: uint256  # Upper limit on the increase of debt since last harvest
//     lastReport: uint256  # block.timestamp of the last time a report occured
//     totalDebt: uint256  # Total outstanding debt that Strategy has
//     totalGain: uint256  # Total returns that Strategy has realized for Vault
//     totalLoss: uint256  # Total losses that Strategy has realized for Vault


// event StrategyAdded:
//     strategy: indexed(address)
//     debtRatio: uint256  # Maximum borrow amount (in BPS of total assets)
//     minDebtPerHarvest: uint256  # Lower limit on the increase of debt since last harvest
//     maxDebtPerHarvest: uint256  # Upper limit on the increase of debt since last harvest
//     performanceFee: uint256  # Strategist's fee (basis points)


// event StrategyReported:
//     strategy: indexed(address)
//     gain: uint256
//     loss: uint256
//     debtPaid: uint256
//     totalGain: uint256
//     totalLoss: uint256
//     totalDebt: uint256
//     debtAdded: uint256
//     debtRatio: uint256


// event UpdateGovernance:
//     governance: address # New active governance


// event UpdateManagement:
//     management: address # New active manager


// event UpdateGuestList:
//     guestList: address # Vault guest list address


// event UpdateRewards:
//     rewards: address # New active rewards recipient


// event UpdateDepositLimit:
//     depositLimit: uint256 # New active deposit limit


// event UpdatePerformanceFee:
//     performanceFee: uint256 # New active performance fee


// event UpdateManagementFee:
//     managementFee: uint256 # New active management fee


// event UpdateGuardian:
//     guardian: address # Address of the active guardian


// event EmergencyShutdown:
//     active: bool # New emergency shutdown state (if false, normal operation enabled)


// event UpdateWithdrawalQueue:
//     queue: address[MAXIMUM_STRATEGIES] # New active withdrawal queue


// event StrategyUpdateDebtRatio:
//     strategy: indexed(address) # Address of the strategy for the debt ratio adjustment
//     debtRatio: uint256 # The new debt limit for the strategy (in BPS of total assets)


// event StrategyUpdateMinDebtPerHarvest:
//     strategy: indexed(address) # Address of the strategy for the rate limit adjustment
//     minDebtPerHarvest: uint256  # Lower limit on the increase of debt since last harvest


// event StrategyUpdateMaxDebtPerHarvest:
//     strategy: indexed(address) # Address of the strategy for the rate limit adjustment
//     maxDebtPerHarvest: uint256  # Upper limit on the increase of debt since last harvest


// event StrategyUpdatePerformanceFee:
//     strategy: indexed(address) # Address of the strategy for the performance fee adjustment
//     performanceFee: uint256 # The new performance fee for the strategy


// event StrategyMigrated:
//     oldVersion: indexed(address) # Old version of the strategy to be migrated
//     newVersion: indexed(address) # New version of the strategy


// event StrategyRevoked:
//     strategy: indexed(address) # Address of the strategy that is revoked


// event StrategyRemovedFromQueue:
//     strategy: indexed(address) # Address of the strategy that is removed from the withdrawal queue


// event StrategyAddedToQueue:
//     strategy: indexed(address) # Address of the strategy that is added to the withdrawal queue


// # NOTE: Track the total for overhead targeting purposes
// strategies: public(HashMap[address, StrategyParams])
// MAXIMUM_STRATEGIES: constant(uint256) = 20
// DEGREDATION_COEFFICIENT: constant(uint256) = 10 ** 18

// # Ordering that `withdraw` uses to determine which strategies to pull funds from
// # NOTE: Does *NOT* have to match the ordering of all the current strategies that
// #       exist, but it is recommended that it does or else withdrawal depth is
// #       limited to only those inside the queue.
// # NOTE: Ordering is determined by governance, and should be balanced according
// #       to risk, slippage, and/or volatility. Can also be ordered to increase the
// #       withdrawal speed of a particular Strategy.
// # NOTE: The first time a ZERO_ADDRESS is encountered, it stops withdrawing
// withdrawalQueue: public(address[MAXIMUM_STRATEGIES])

// emergencyShutdown: public(bool)

// depositLimit: public(uint256)  # Limit for totalAssets the Vault can hold
// debtRatio: public(uint256)  # Debt ratio for the Vault across all strategies (in BPS, <= 10k)
// totalDebt: public(uint256)  # Amount of tokens that all strategies have borrowed
// lastReport: public(uint256)  # block.timestamp of last report
// activation: public(uint256)  # block.timestamp of contract deployment
// lockedProfit: public(uint256) # how much profit is locked and cant be withdrawn
// lockedProfitDegration: public(uint256) # rate per block of degration. DEGREDATION_COEFFICIENT is 100% per block
// rewards: public(address)  # Rewards contract where Governance fees are sent to
// # Governance Fee for management of Vault (given to `rewards`)
// managementFee: public(uint256)
// # Governance Fee for performance of Vault (given to `rewards`)
// performanceFee: public(uint256)
// MAX_BPS: constant(uint256) = 10_000  # 100%, or 10k basis points
// # NOTE: A four-century period will be missing 3 of its 100 Julian leap years, leaving 97.
// #       So the average year has 365 + 97/400 = 365.2425 days
// #       ERROR(Julian): -0.0078
// #       ERROR(Gregorian): -0.0003
// SECS_PER_YEAR: constant(uint256) = 31_556_952  # 365.2425 days
// # `nonces` track `permit` approvals with signature.
// nonces: public(HashMap[address, uint256])
// DOMAIN_SEPARATOR: public(bytes32)
// DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
// PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")


// @external
// def initialize(
//     token: address,
//     governance: address,
//     rewards: address,
//     nameOverride: String[64],
//     symbolOverride: String[32],
//     guardian: address = msg.sender,
// ):
//     """
//     @notice
//         Initializes the Vault, this is called only once, when the contract is
//         deployed.
//         The performance fee is set to 10% of yield, per Strategy.
//         The management fee is set to 2%, per year.
//         The initial deposit limit is set to 0 (deposits disabled); it must be
//         updated after initialization.
//     @dev
//         If `nameOverride` is not specified, the name will be 'yearn'
//         combined with the name of `token`.

//         If `symbolOverride` is not specified, the symbol will be 'y'
//         combined with the symbol of `token`.
//     @param token The token that may be deposited into this Vault.
//     @param governance The address authorized for governance interactions.
//     @param rewards The address to distribute rewards to.
//     @param nameOverride Specify a custom Vault name. Leave empty for default choice.
//     @param symbolOverride Specify a custom Vault symbol name. Leave empty for default choice.
//     @param guardian The address authorized for guardian interactions. Defaults to caller.
//     """
//     assert self.activation == 0  # dev: no devops199
//     self.token = ERC20(token)
//     if nameOverride == "":
//         self.name = concat(DetailedERC20(token).symbol(), " yVault")
//     else:
//         self.name = nameOverride
//     if symbolOverride == "":
//         self.symbol = concat("yv", DetailedERC20(token).symbol())
//     else:
//         self.symbol = symbolOverride
//     self.decimals = DetailedERC20(token).decimals()
//     if self.decimals < 18:
//       self.precisionFactor = 10 ** (18 - self.decimals)
//     else:
//       self.precisionFactor = 1

//     self.governance = governance
//     log UpdateGovernance(governance)
//     self.management = governance
//     log UpdateManagement(governance)
//     self.rewards = rewards
//     log UpdateRewards(rewards)
//     self.guardian = guardian
//     log UpdateGuardian(guardian)
//     self.performanceFee = 1000  # 10% of yield (per Strategy)
//     log UpdatePerformanceFee(convert(1000, uint256))
//     self.managementFee = 200  # 2% per year
//     log UpdateManagementFee(convert(200, uint256))
//     self.lastReport = block.timestamp
//     self.activation = block.timestamp
//     self.lockedProfitDegration = convert(DEGREDATION_COEFFICIENT * 46 /10 ** 6 , uint256) # 6 hours in blocks
//     # EIP-712
//     self.DOMAIN_SEPARATOR = keccak256(
//         concat(
//             DOMAIN_TYPE_HASH,
//             keccak256(convert("Yearn Vault", Bytes[11])),
//             keccak256(convert(API_VERSION, Bytes[28])),
//             convert(chain.id, bytes32),
//             convert(self, bytes32)
//         )
//     )


// @pure
// @external
// def apiVersion() -> String[28]:
//     """
//     @notice
//         Used to track the deployed version of this contract. In practice you
//         can use this version number to compare with Yearn's GitHub and
//         determine which version of the source matches this deployed contract.
//     @dev
//         All strategies must have an `apiVersion()` that matches the Vault's
//         `API_VERSION`.
//     @return API_VERSION which holds the current version of this contract.
//     """
//     return API_VERSION


// @external
// def setName(name: String[42]):
//     """
//     @notice
//         Used to change the value of `name`.

//         This may only be called by governance.
//     @param name The new name to use.
//     """
//     assert msg.sender == self.governance
//     self.name = name


// @external
// def setSymbol(symbol: String[20]):
//     """
//     @notice
//         Used to change the value of `symbol`.

//         This may only be called by governance.
//     @param symbol The new symbol to use.
//     """
//     assert msg.sender == self.governance
//     self.symbol = symbol


// # 2-phase commit for a change in governance
// @external
// def setGovernance(governance: address):
//     """
//     @notice
//         Nominate a new address to use as governance.

//         The change does not go into effect immediately. This function sets a
//         pending change, and the governance address is not updated until
//         the proposed governance address has accepted the responsibility.

//         This may only be called by the current governance address.
//     @param governance The address requested to take over Vault governance.
//     """
//     assert msg.sender == self.governance
//     self.pendingGovernance = governance


// @external
// def acceptGovernance():
//     """
//     @notice
//         Once a new governance address has been proposed using setGovernance(),
//         this function may be called by the proposed address to accept the
//         responsibility of taking over governance for this contract.

//         This may only be called by the proposed governance address.
//     @dev
//         setGovernance() should be called by the existing governance address,
//         prior to calling this function.
//     """
//     assert msg.sender == self.pendingGovernance
//     self.governance = msg.sender
//     log UpdateGovernance(msg.sender)


// @external
// def setManagement(management: address):
//     """
//     @notice
//         Changes the management address.
//         Management is able to make some investment decisions adjusting parameters.

//         This may only be called by governance.
//     @param management The address to use for managing.
//     """
//     assert msg.sender == self.governance
//     self.management = management
//     log UpdateManagement(management)


// @external
// def setGuestList(guestList: address):
//     """
//     @notice
//         Used to set or change `guestList`. A guest list is another contract
//         that dictates who is allowed to participate in a Vault (and transfer
//         shares).

//         This may only be called by governance.
//     @param guestList The address of the `GuestList` contract to use.
//     """
//     assert msg.sender == self.governance
//     self.guestList = GuestList(guestList)
//     log UpdateGuestList(guestList)


// @external
// def setRewards(rewards: address):
//     """
//     @notice
//         Changes the rewards address. Any distributed rewards
//         will cease flowing to the old address and begin flowing
//         to this address once the change is in effect.

//         This will not change any Strategy reports in progress, only
//         new reports made after this change goes into effect.

//         This may only be called by governance.
//     @param rewards The address to use for collecting rewards.
//     """
//     assert msg.sender == self.governance
//     self.rewards = rewards
//     log UpdateRewards(rewards)


// @external
// def setLockedProfitDegration(degration: uint256):
//     """
//     @notice
//         Changes the locked profit degration.
//     @param degration The rate of degration in percent per second scaled to 1e18.
//     """
//     assert msg.sender == self.governance
//     # Since "degration" is of type uint256 it can never be less than zero
//     assert degration <= DEGREDATION_COEFFICIENT
//     self.lockedProfitDegration = degration


// @external
// def setDepositLimit(limit: uint256):
//     """
//     @notice
//         Changes the maximum amount of tokens that can be deposited in this Vault.

//         Note, this is not how much may be deposited by a single depositor,
//         but the maximum amount that may be deposited across all depositors.

//         This may only be called by governance.
//     @param limit The new deposit limit to use.
//     """
//     assert msg.sender == self.governance
//     self.depositLimit = limit
//     log UpdateDepositLimit(limit)


// @external
// def setPerformanceFee(fee: uint256):
//     """
//     @notice
//         Used to change the value of `performanceFee`.

//         Should set this value below the maximum strategist performance fee.

//         This may only be called by governance.
//     @param fee The new performance fee to use.
//     """
//     assert msg.sender == self.governance
//     assert fee <= MAX_BPS
//     self.performanceFee = fee
//     log UpdatePerformanceFee(fee)


// @external
// def setManagementFee(fee: uint256):
//     """
//     @notice
//         Used to change the value of `managementFee`.

//         This may only be called by governance.
//     @param fee The new management fee to use.
//     """
//     assert msg.sender == self.governance
//     assert fee <= MAX_BPS
//     self.managementFee = fee
//     log UpdateManagementFee(fee)


// @external
// def setGuardian(guardian: address):
//     """
//     @notice
//         Used to change the address of `guardian`.

//         This may only be called by governance or the existing guardian.
//     @param guardian The new guardian address to use.
//     """
//     assert msg.sender in [self.guardian, self.governance]
//     self.guardian = guardian
//     log UpdateGuardian(guardian)


// @external
// def setEmergencyShutdown(active: bool):
//     """
//     @notice
//         Activates or deactivates Vault mode where all Strategies go into full
//         withdrawal.

//         During Emergency Shutdown:
//         1. No Users may deposit into the Vault (but may withdraw as usual.)
//         2. Governance may not add new Strategies.
//         3. Each Strategy must pay back their debt as quickly as reasonable to
//             minimally affect their position.
//         4. Only Governance may undo Emergency Shutdown.

//         See contract level note for further details.

//         This may only be called by governance or the guardian.
//     @param active
//         If true, the Vault goes into Emergency Shutdown. If false, the Vault
//         goes back into Normal Operation.
//     """
//     if active:
//         assert msg.sender in [self.guardian, self.governance]
//     else:
//         assert msg.sender == self.governance
//     self.emergencyShutdown = active
//     log EmergencyShutdown(active)


// @external
// def setWithdrawalQueue(queue: address[MAXIMUM_STRATEGIES]):
//     """
//     @notice
//         Updates the withdrawalQueue to match the addresses and order specified
//         by `queue`.

//         There can be fewer strategies than the maximum, as well as fewer than
//         the total number of strategies active in the vault. `withdrawalQueue`
//         will be updated in a gas-efficient manner, assuming the input is well-
//         ordered with 0x0 only at the end.

//         This may only be called by governance or management.
//     @dev
//         This is order sensitive, specify the addresses in the order in which
//         funds should be withdrawn (so `queue`[0] is the first Strategy withdrawn
//         from, `queue`[1] is the second, etc.)

//         This means that the least impactful Strategy (the Strategy that will have
//         its core positions impacted the least by having funds removed) should be
//         at `queue`[0], then the next least impactful at `queue`[1], and so on.
//     @param queue
//         The array of addresses to use as the new withdrawal queue. This is
//         order sensitive.
//     """
//     assert msg.sender in [self.management, self.governance]
//     # HACK: Temporary until Vyper adds support for Dynamic arrays
//     for i in range(MAXIMUM_STRATEGIES):
//         if queue[i] == ZERO_ADDRESS and self.withdrawalQueue[i] == ZERO_ADDRESS:
//             break
//         assert self.strategies[queue[i]].activation > 0
//         self.withdrawalQueue[i] = queue[i]
//     log UpdateWithdrawalQueue(queue)


// @internal
// def erc20_safe_transfer(token: address, receiver: address, amount: uint256):
//     # Used only to send tokens that are not the type managed by this Vault.
//     # HACK: Used to handle non-compliant tokens like USDT
//     response: Bytes[32] = raw_call(
//         token,
//         concat(
//             method_id("transfer(address,uint256)"),
//             convert(receiver, bytes32),
//             convert(amount, bytes32),
//         ),
//         max_outsize=32,
//     )
//     if len(response) > 0:
//         assert convert(response, bool), "Transfer failed!"


// @internal
// def erc20_safe_transferFrom(token: address, sender: address, receiver: address, amount: uint256):
//     # Used only to send tokens that are not the type managed by this Vault.
//     # HACK: Used to handle non-compliant tokens like USDT
//     response: Bytes[32] = raw_call(
//         token,
//         concat(
//             method_id("transferFrom(address,address,uint256)"),
//             convert(sender, bytes32),
//             convert(receiver, bytes32),
//             convert(amount, bytes32),
//         ),
//         max_outsize=32,
//     )
//     if len(response) > 0:
//         assert convert(response, bool), "Transfer failed!"


// @internal
// def _transfer(sender: address, receiver: address, amount: uint256):
//     # See note on `transfer()`.

//     # Protect people from accidentally sending their shares to bad places
//     assert not (receiver in [self, ZERO_ADDRESS])
//     self.balanceOf[sender] -= amount
//     self.balanceOf[receiver] += amount
//     log Transfer(sender, receiver, amount)


// @external
// def transfer(receiver: address, amount: uint256) -> bool:
//     """
//     @notice
//         Transfers shares from the caller's address to `receiver`. This function
//         will always return true, unless the user is attempting to transfer
//         shares to this contract's address, or to 0x0.
//     @param receiver
//         The address shares are being transferred to. Must not be this contract's
//         address, must not be 0x0.
//     @param amount The quantity of shares to transfer.
//     @return
//         True if transfer is sent to an address other than this contract's or
//         0x0, otherwise the transaction will fail.
//     """
//     self._transfer(msg.sender, receiver, amount)
//     return True


// @external
// def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
//     """
//     @notice
//         Transfers `amount` shares from `sender` to `receiver`. This operation will
//         always return true, unless the user is attempting to transfer shares
//         to this contract's address, or to 0x0.

//         Unless the caller has given this contract unlimited approval,
//         transfering shares will decrement the caller's `allowance` by `amount`.
//     @param sender The address shares are being transferred from.
//     @param receiver
//         The address shares are being transferred to. Must not be this contract's
//         address, must not be 0x0.
//     @param amount The quantity of shares to transfer.
//     @return
//         True if transfer is sent to an address other than this contract's or
//         0x0, otherwise the transaction will fail.
//     """
//     # Unlimited approval (saves an SSTORE)
//     if (self.allowance[sender][msg.sender] < MAX_UINT256):
//         allowance: uint256 = self.allowance[sender][msg.sender] - amount
//         self.allowance[sender][msg.sender] = allowance
//         # NOTE: Allows log filters to have a full accounting of allowance changes
//         log Approval(sender, msg.sender, allowance)
//     self._transfer(sender, receiver, amount)
//     return True


// @external
// def approve(spender: address, amount: uint256) -> bool:
//     """
//     @dev Approve the passed address to spend the specified amount of tokens on behalf of
//          `msg.sender`. Beware that changing an allowance with this method brings the risk
//          that someone may use both the old and the new allowance by unfortunate transaction
//          ordering. See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//     @param spender The address which will spend the funds.
//     @param amount The amount of tokens to be spent.
//     """
//     self.allowance[msg.sender][spender] = amount
//     log Approval(msg.sender, spender, amount)
//     return True


// @external
// def increaseAllowance(spender: address, amount: uint256) -> bool:
//     """
//     @dev Increase the allowance of the passed address to spend the total amount of tokens
//          on behalf of msg.sender. This method mitigates the risk that someone may use both
//          the old and the new allowance by unfortunate transaction ordering.
//          See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//     @param spender The address which will spend the funds.
//     @param amount The amount of tokens to increase the allowance by.
//     """
//     self.allowance[msg.sender][spender] += amount
//     log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
//     return True


// @external
// def decreaseAllowance(spender: address, amount: uint256) -> bool:
//     """
//     @dev Decrease the allowance of the passed address to spend the total amount of tokens
//          on behalf of msg.sender. This method mitigates the risk that someone may use both
//          the old and the new allowance by unfortunate transaction ordering.
//          See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
//     @param spender The address which will spend the funds.
//     @param amount The amount of tokens to decrease the allowance by.
//     """
//     self.allowance[msg.sender][spender] -= amount
//     log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
//     return True


// @external
// def permit(owner: address, spender: address, amount: uint256, expiry: uint256, signature: Bytes[65]) -> bool:
//     """
//     @notice
//         Approves spender by owner's signature to expend owner's tokens.
//         See https://eips.ethereum.org/EIPS/eip-2612.

//     @param owner The address which is a source of funds and has signed the Permit.
//     @param spender The address which is allowed to spend the funds.
//     @param amount The amount of tokens to be spent.
//     @param expiry The timestamp after which the Permit is no longer valid.
//     @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v.
//     @return True, if transaction completes successfully
//     """
//     assert owner != ZERO_ADDRESS  # dev: invalid owner
//     assert expiry == 0 or expiry >= block.timestamp  # dev: permit expired
//     nonce: uint256 = self.nonces[owner]
//     digest: bytes32 = keccak256(
//         concat(
//             b'\x19\x01',
//             self.DOMAIN_SEPARATOR,
//             keccak256(
//                 concat(
//                     PERMIT_TYPE_HASH,
//                     convert(owner, bytes32),
//                     convert(spender, bytes32),
//                     convert(amount, bytes32),
//                     convert(nonce, bytes32),
//                     convert(expiry, bytes32),
//                 )
//             )
//         )
//     )
//     # NOTE: signature is packed as r, s, v
//     r: uint256 = convert(slice(signature, 0, 32), uint256)
//     s: uint256 = convert(slice(signature, 32, 32), uint256)
//     v: uint256 = convert(slice(signature, 64, 1), uint256)
//     assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
//     self.allowance[owner][spender] = amount
//     self.nonces[owner] = nonce + 1
//     log Approval(owner, spender, amount)
//     return True


// @view
// @internal
// def _totalAssets() -> uint256:
//     # See note on `totalAssets()`.
//     return self.token.balanceOf(self) + self.totalDebt


// @view
// @external
// def totalAssets() -> uint256:
//     """
//     @notice
//         Returns the total quantity of all assets under control of this
//         Vault, whether they're loaned out to a Strategy, or currently held in
//         the Vault.
//     @return The total assets under control of this Vault.
//     """
//     return self._totalAssets()


// @internal
// def _issueSharesForAmount(to: address, amount: uint256) -> uint256:
//     # Issues `amount` Vault shares to `to`.
//     # Shares must be issued prior to taking on new collateral, or
//     # calculation will be wrong. This means that only *trusted* tokens
//     # (with no capability for exploitative behavior) can be used.
//     shares: uint256 = 0
//     # HACK: Saves 2 SLOADs (~4000 gas)
//     totalSupply: uint256 = self.totalSupply
//     if totalSupply > 0:
//         # Mint amount of shares based on what the Vault is managing overall
//         # NOTE: if sqrt(token.totalSupply()) > 1e39, this could potentially revert
//         precisionFactor: uint256 = self.precisionFactor
//         shares = precisionFactor * amount * totalSupply / self._totalAssets() / precisionFactor
//     else:
//         # No existing shares, so mint 1:1
//         shares = amount

//     # Mint new shares
//     self.totalSupply = totalSupply + shares
//     self.balanceOf[to] += shares
//     log Transfer(ZERO_ADDRESS, to, shares)

//     return shares


// @external
// @nonreentrant("withdraw")
// def deposit(_amount: uint256 = MAX_UINT256, recipient: address = msg.sender) -> uint256:
//     """
//     @notice
//         Deposits `_amount` `token`, issuing shares to `recipient`. If the
//         Vault is in Emergency Shutdown, deposits will not be accepted and this
//         call will fail.
//     @dev
//         Measuring quantity of shares to issues is based on the total
//         outstanding debt that this contract has ("expected value") instead
//         of the total balance sheet it has ("estimated value") has important
//         security considerations, and is done intentionally. If this value were
//         measured against external systems, it could be purposely manipulated by
//         an attacker to withdraw more assets than they otherwise should be able
//         to claim by redeeming their shares.

//         On deposit, this means that shares are issued against the total amount
//         that the deposited capital can be given in service of the debt that
//         Strategies assume. If that number were to be lower than the "expected
//         value" at some future point, depositing shares via this method could
//         entitle the depositor to *less* than the deposited value once the
//         "realized value" is updated from further reports by the Strategies
//         to the Vaults.

//         Care should be taken by integrators to account for this discrepancy,
//         by using the view-only methods of this contract (both off-chain and
//         on-chain) to determine if depositing into the Vault is a "good idea".
//     @param _amount The quantity of tokens to deposit, defaults to all.
//     @param recipient
//         The address to issue the shares in this Vault to. Defaults to the
//         caller's address.
//     @return The issued Vault shares.
//     """
//     assert not self.emergencyShutdown  # Deposits are locked out

//     amount: uint256 = _amount

//     # If _amount not specified, transfer the full token balance,
//     # up to deposit limit
//     if amount == MAX_UINT256:
//         amount = min(
//             self.depositLimit - self._totalAssets(),
//             self.token.balanceOf(msg.sender),
//         )
//     else:
//         # Ensure deposit limit is respected
//         assert self._totalAssets() + amount <= self.depositLimit

//     # Ensure we are depositing something
//     assert amount > 0

//     # Ensure deposit is permitted by guest list
//     if self.guestList.address != ZERO_ADDRESS:
//         assert self.guestList.authorized(msg.sender, amount)

//     # Issue new shares (needs to be done before taking deposit to be accurate)
//     # Shares are issued to recipient (may be different from msg.sender)
//     # See @dev note, above.
//     shares: uint256 = self._issueSharesForAmount(recipient, amount)

//     # Tokens are transferred from msg.sender (may be different from _recipient)
//     self.erc20_safe_transferFrom(self.token.address, msg.sender, self, amount)

//     return shares  # Just in case someone wants them


// @view
// @internal
// def _shareValue(shares: uint256) -> uint256:
//     # Returns price = 1:1 if vault is empty
//     if self.totalSupply == 0:
//         return shares

//     # Determines the current value of `shares`.
//         # NOTE: if sqrt(Vault.totalAssets()) >>> 1e39, this could potentially revert
//     lockedFundsRatio: uint256 = (block.timestamp - self.lastReport) * self.lockedProfitDegration
//     freeFunds: uint256 = self._totalAssets()
//     precisionFactor: uint256 = self.precisionFactor
//     if(lockedFundsRatio < DEGREDATION_COEFFICIENT):
//         freeFunds -= (
//             self.lockedProfit
//              - (
//                  precisionFactor
//                  * lockedFundsRatio
//                  * self.lockedProfit
//                  / DEGREDATION_COEFFICIENT
//                  / precisionFactor
//              )
//          )
//     # NOTE: using 1e3 for extra precision here, when decimals is low
//     return (
//         precisionFactor
//        * shares
//         * freeFunds
//         / self.totalSupply
//         / precisionFactor
//     )


// @view
// @internal
// def _sharesForAmount(amount: uint256) -> uint256:
//     # Determines how many shares `amount` of token would receive.
//     # See dev note on `deposit`.
//     if self._totalAssets() > 0:
//         # NOTE: if sqrt(token.totalSupply()) > 1e37, this could potentially revert
//         precisionFactor: uint256 = self.precisionFactor
//         return  (
//             precisionFactor
//             * amount
//             * self.totalSupply
//             / self._totalAssets()
//             / precisionFactor
//         )
//     else:
//         return 0


// @view
// @external
// def maxAvailableShares() -> uint256:
//     """
//     @notice
//         Determines the maximum quantity of shares this Vault can facilitate a
//         withdrawal for, factoring in assets currently residing in the Vault,
//         as well as those deployed to strategies on the Vault's balance sheet.
//     @dev
//         Regarding how shares are calculated, see dev note on `deposit`.

//         If you want to calculated the maximum a user could withdraw up to,
//         you want to use this function.

//         Note that the amount provided by this function is the theoretical
//         maximum possible from withdrawing, the real amount depends on the
//         realized losses incurred during withdrawal.
//     @return The total quantity of shares this Vault can provide.
//     """
//     shares: uint256 = self._sharesForAmount(self.token.balanceOf(self))

//     for strategy in self.withdrawalQueue:
//         if strategy == ZERO_ADDRESS:
//             break
//         shares += self._sharesForAmount(self.strategies[strategy].totalDebt)

//     return shares


// @internal
// def _reportLoss(strategy: address, loss: uint256):
//     # Loss can only be up the amount of debt issued to strategy
//     totalDebt: uint256 = self.strategies[strategy].totalDebt
//     assert totalDebt >= loss
//     self.strategies[strategy].totalLoss += loss
//     self.strategies[strategy].totalDebt = totalDebt - loss
//     self.totalDebt -= loss

//     # Also, make sure we reduce our trust with the strategy by the same amount
//     debtRatio: uint256 = self.strategies[strategy].debtRatio
//     precisionFactor: uint256 = self.precisionFactor
//     ratio_change: uint256 = min(precisionFactor * loss * MAX_BPS / self._totalAssets() / precisionFactor, debtRatio)
//     self.strategies[strategy].debtRatio -= ratio_change
//     self.debtRatio -= ratio_change


// @external
// @nonreentrant("withdraw")
// def withdraw(
//     maxShares: uint256 = MAX_UINT256,
//     recipient: address = msg.sender,
//     maxLoss: uint256 = 1,  # 0.01% [BPS]
// ) -> uint256:
//     """
//     @notice
//         Withdraws the calling account's tokens from this Vault, redeeming
//         amount `_shares` for an appropriate amount of tokens.

//         See note on `setWithdrawalQueue` for further details of withdrawal
//         ordering and behavior.
//     @dev
//         Measuring the value of shares is based on the total outstanding debt
//         that this contract has ("expected value") instead of the total balance
//         sheet it has ("estimated value") has important security considerations,
//         and is done intentionally. If this value were measured against external
//         systems, it could be purposely manipulated by an attacker to withdraw
//         more assets than they otherwise should be able to claim by redeeming
//         their shares.

//         On withdrawal, this means that shares are redeemed against the total
//         amount that the deposited capital had "realized" since the point it
//         was deposited, up until the point it was withdrawn. If that number
//         were to be higher than the "expected value" at some future point,
//         withdrawing shares via this method could entitle the depositor to
//         *more* than the expected value once the "realized value" is updated
//         from further reports by the Strategies to the Vaults.

//         Under exceptional scenarios, this could cause earlier withdrawals to
//         earn "more" of the underlying assets than Users might otherwise be
//         entitled to, if the Vault's estimated value were otherwise measured
//         through external means, accounting for whatever exceptional scenarios
//         exist for the Vault (that aren't covered by the Vault's own design.)
//     @param maxShares
//         How many shares to try and redeem for tokens, defaults to all.
//     @param recipient
//         The address to issue the shares in this Vault to. Defaults to the
//         caller's address.
//     @param maxLoss
//         The maximum acceptable loss to sustain on withdrawal. Defaults to 0.01%.
//     @return The quantity of tokens redeemed for `_shares`.
//     """
//     shares: uint256 = maxShares  # May reduce this number below

//     # Max Loss is <=100%, revert otherwise
//     assert maxLoss <= MAX_BPS

//     # If _shares not specified, transfer full share balance
//     if shares == MAX_UINT256:
//         shares = self.balanceOf[msg.sender]

//     # Limit to only the shares they own
//     assert shares <= self.balanceOf[msg.sender]

//     # Ensure we are withdrawing something
//     assert shares > 0

//     # See @dev note, above.
//     value: uint256 = self._shareValue(shares)

//     totalLoss: uint256 = 0
//     if value > self.token.balanceOf(self):
//         # We need to go get some from our strategies in the withdrawal queue
//         # NOTE: This performs forced withdrawals from each Strategy. During
//         #       forced withdrawal, a Strategy may realize a loss. That loss
//         #       is reported back to the Vault, and the will affect the amount
//         #       of tokens that the withdrawer receives for their shares. They
//         #       can optionally specify the maximum acceptable loss (in BPS)
//         #       to prevent excessive losses on their withdrawals (which may
//         #       happen in certain edge cases where Strategies realize a loss)
//         for strategy in self.withdrawalQueue:
//             if strategy == ZERO_ADDRESS:
//                 break  # We've exhausted the queue

//             vault_balance: uint256 = self.token.balanceOf(self)
//             if value <= vault_balance:
//                 break  # We're done withdrawing

//             amountNeeded: uint256 = value - vault_balance

//             # NOTE: Don't withdraw more than the debt so that Strategy can still
//             #       continue to work based on the profits it has
//             # NOTE: This means that user will lose out on any profits that each
//             #       Strategy in the queue would return on next harvest, benefiting others
//             amountNeeded = min(amountNeeded, self.strategies[strategy].totalDebt)
//             if amountNeeded == 0:
//                 continue  # Nothing to withdraw from this Strategy, try the next one

//             # Force withdraw amount from each Strategy in the order set by governance
//             loss: uint256 = Strategy(strategy).withdraw(amountNeeded)
//             withdrawn: uint256 = self.token.balanceOf(self) - vault_balance

//             # NOTE: Withdrawer incurs any losses from liquidation
//             if loss > 0:
//                 value -= loss
//                 totalLoss += loss
//                 self._reportLoss(strategy, loss)

//             # Reduce the Strategy's debt by the amount withdrawn ("realized returns")
//             # NOTE: This doesn't add to returns as it's not earned by "normal means"
//             self.strategies[strategy].totalDebt -= withdrawn
//             self.totalDebt -= withdrawn

//     # NOTE: We have withdrawn everything possible out of the withdrawal queue
//     #       but we still don't have enough to fully pay them back, so adjust
//     #       to the total amount we've freed up through forced withdrawals
//     vault_balance: uint256 = self.token.balanceOf(self)
//     if value > vault_balance:
//         value = vault_balance
//         # NOTE: Burn # of shares that corresponds to what Vault has on-hand,
//         #       including the losses that were incurred above during withdrawals
//         shares = self._sharesForAmount(value + totalLoss)

//     # NOTE: This loss protection is put in place to revert if losses from
//     #       withdrawing are more than what is considered acceptable.
//     precisionFactor: uint256 = self.precisionFactor
//     assert totalLoss <= precisionFactor * maxLoss * (value + totalLoss) / MAX_BPS / precisionFactor

//     # Burn shares (full value of what is being withdrawn)
//     self.totalSupply -= shares
//     self.balanceOf[msg.sender] -= shares
//     log Transfer(msg.sender, ZERO_ADDRESS, shares)

//     # Withdraw remaining balance to _recipient (may be different to msg.sender) (minus fee)
//     self.erc20_safe_transfer(self.token.address, recipient, value)

//     return value


// @view
// @external
// def pricePerShare() -> uint256:
//     """
//     @notice Gives the price for a single Vault share.
//     @dev See dev note on `withdraw`.
//     @return The value of a single share.
//     """
//     return self._shareValue(10 ** self.decimals)


// @internal
// def _organizeWithdrawalQueue():
//     # Reorganize `withdrawalQueue` based on premise that if there is an
//     # empty value between two actual values, then the empty value should be
//     # replaced by the later value.
//     # NOTE: Relative ordering of non-zero values is maintained.
//     offset: uint256 = 0
//     for idx in range(MAXIMUM_STRATEGIES):
//         strategy: address = self.withdrawalQueue[idx]
//         if strategy == ZERO_ADDRESS:
//             offset += 1  # how many values we need to shift, always `<= idx`
//         elif offset > 0:
//             self.withdrawalQueue[idx - offset] = strategy
//             self.withdrawalQueue[idx] = ZERO_ADDRESS


// @external
// def addStrategy(
//     strategy: address,
//     debtRatio: uint256,
//     minDebtPerHarvest: uint256,
//     maxDebtPerHarvest: uint256,
//     performanceFee: uint256,
// ):
//     """
//     @notice
//         Add a Strategy to the Vault.

//         This may only be called by governance.
//     @dev
//         The Strategy will be appended to `withdrawalQueue`, call
//         `setWithdrawalQueue` to change the order.
//     @param strategy The address of the Strategy to add.
//     @param debtRatio
//         The share of the total assets in the `vault that the `strategy` has access to.
//     @param minDebtPerHarvest
//         Lower limit on the increase of debt since last harvest
//     @param maxDebtPerHarvest
//         Upper limit on the increase of debt since last harvest
//     @param performanceFee
//         The fee the strategist will receive based on this Vault's performance.
//     """
//     # Check if queue is full
//     assert self.withdrawalQueue[MAXIMUM_STRATEGIES - 1] == ZERO_ADDRESS

//     # Check calling conditions
//     assert not self.emergencyShutdown
//     assert msg.sender == self.governance

//     # Check strategy configuration
//     assert strategy != ZERO_ADDRESS
//     assert self.strategies[strategy].activation == 0
//     assert self == Strategy(strategy).vault()
//     assert self.token.address == Strategy(strategy).want()

//     # Check strategy parameters
//     assert self.debtRatio + debtRatio <= MAX_BPS
//     assert minDebtPerHarvest <= maxDebtPerHarvest
//     assert performanceFee <= MAX_BPS - self.performanceFee

//     # Add strategy to approved strategies
//     self.strategies[strategy] = StrategyParams({
//         performanceFee: performanceFee,
//         activation: block.timestamp,
//         debtRatio: debtRatio,
//         minDebtPerHarvest: minDebtPerHarvest,
//         maxDebtPerHarvest: maxDebtPerHarvest,
//         lastReport: block.timestamp,
//         totalDebt: 0,
//         totalGain: 0,
//         totalLoss: 0,
//     })
//     log StrategyAdded(strategy, debtRatio, minDebtPerHarvest, maxDebtPerHarvest, performanceFee)

//     # Update Vault parameters
//     self.debtRatio += debtRatio

//     # Add strategy to the end of the withdrawal queue
//     self.withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy
//     self._organizeWithdrawalQueue()


// @external
// def updateStrategyDebtRatio(
//     strategy: address,
//     debtRatio: uint256,
// ):
//     """
//     @notice
//         Change the quantity of assets `strategy` may manage.

//         This may be called by governance or management.
//     @param strategy The Strategy to update.
//     @param debtRatio The quantity of assets `strategy` may now manage.
//     """
//     assert msg.sender in [self.management, self.governance]
//     assert self.strategies[strategy].activation > 0
//     self.debtRatio -= self.strategies[strategy].debtRatio
//     self.strategies[strategy].debtRatio = debtRatio
//     self.debtRatio += debtRatio
//     assert self.debtRatio <= MAX_BPS
//     log StrategyUpdateDebtRatio(strategy, debtRatio)


// @external
// def updateStrategyMinDebtPerHarvest(
//     strategy: address,
//     minDebtPerHarvest: uint256,
// ):
//     """
//     @notice
//         Change the quantity assets per block this Vault may deposit to or
//         withdraw from `strategy`.

//         This may only be called by governance or management.
//     @param strategy The Strategy to update.
//     @param minDebtPerHarvest
//         Lower limit on the increase of debt since last harvest
//     """
//     assert msg.sender in [self.management, self.governance]
//     assert self.strategies[strategy].activation > 0
//     assert self.strategies[strategy].maxDebtPerHarvest >= minDebtPerHarvest
//     self.strategies[strategy].minDebtPerHarvest = minDebtPerHarvest
//     log StrategyUpdateMinDebtPerHarvest(strategy, minDebtPerHarvest)


// @external
// def updateStrategyMaxDebtPerHarvest(
//     strategy: address,
//     maxDebtPerHarvest: uint256,
// ):
//     """
//     @notice
//         Change the quantity assets per block this Vault may deposit to or
//         withdraw from `strategy`.

//         This may only be called by governance or management.
//     @param strategy The Strategy to update.
//     @param maxDebtPerHarvest
//         Upper limit on the increase of debt since last harvest
//     """
//     assert msg.sender in [self.management, self.governance]
//     assert self.strategies[strategy].activation > 0
//     assert self.strategies[strategy].minDebtPerHarvest <= maxDebtPerHarvest
//     self.strategies[strategy].maxDebtPerHarvest = maxDebtPerHarvest
//     log StrategyUpdateMaxDebtPerHarvest(strategy, maxDebtPerHarvest)


// @external
// def updateStrategyPerformanceFee(
//     strategy: address,
//     performanceFee: uint256,
// ):
//     """
//     @notice
//         Change the fee the strategist will receive based on this Vault's
//         performance.

//         This may only be called by governance.
//     @param strategy The Strategy to update.
//     @param performanceFee The new fee the strategist will receive.
//     """
//     assert msg.sender == self.governance
//     assert performanceFee <= MAX_BPS - self.performanceFee
//     assert self.strategies[strategy].activation > 0
//     self.strategies[strategy].performanceFee = performanceFee
//     log StrategyUpdatePerformanceFee(strategy, performanceFee)


// @internal
// def _revokeStrategy(strategy: address):
//     self.debtRatio -= self.strategies[strategy].debtRatio
//     self.strategies[strategy].debtRatio = 0
//     log StrategyRevoked(strategy)


// @external
// def migrateStrategy(oldVersion: address, newVersion: address):
//     """
//     @notice
//         Migrates a Strategy, including all assets from `oldVersion` to
//         `newVersion`.

//         This may only be called by governance.
//     @dev
//         Strategy must successfully migrate all capital and positions to new
//         Strategy, or else this will upset the balance of the Vault.

//         The new Strategy should be "empty" e.g. have no prior commitments to
//         this Vault, otherwise it could have issues.
//     @param oldVersion The existing Strategy to migrate from.
//     @param newVersion The new Strategy to migrate to.
//     """
//     assert msg.sender == self.governance
//     assert newVersion != ZERO_ADDRESS
//     assert self.strategies[oldVersion].activation > 0
//     assert self.strategies[newVersion].activation == 0

//     strategy: StrategyParams = self.strategies[oldVersion]

//     self._revokeStrategy(oldVersion)
//     # _revokeStrategy will lower the debtRatio
//     self.debtRatio += strategy.debtRatio
//     # Debt is migrated to new strategy
//     self.strategies[oldVersion].totalDebt = 0

//     self.strategies[newVersion] = StrategyParams({
//         performanceFee: strategy.performanceFee,
//         # NOTE: use last report for activation time, so E[R] calc works
//         activation: strategy.lastReport,
//         debtRatio: strategy.debtRatio,
//         minDebtPerHarvest: strategy.minDebtPerHarvest,
//         maxDebtPerHarvest: strategy.maxDebtPerHarvest,
//         lastReport: strategy.lastReport,
//         totalDebt: strategy.totalDebt,
//         totalGain: 0,
//         totalLoss: 0,
//     })

//     Strategy(oldVersion).migrate(newVersion)
//     log StrategyMigrated(oldVersion, newVersion)

//     for idx in range(MAXIMUM_STRATEGIES):
//         if self.withdrawalQueue[idx] == oldVersion:
//             self.withdrawalQueue[idx] = newVersion
//             return  # Don't need to reorder anything because we swapped


// @external
// def revokeStrategy(strategy: address = msg.sender):
//     """
//     @notice
//         Revoke a Strategy, setting its debt limit to 0 and preventing any
//         future deposits.

//         This function should only be used in the scenario where the Strategy is
//         being retired but no migration of the positions are possible, or in the
//         extreme scenario that the Strategy needs to be put into "Emergency Exit"
//         mode in order for it to exit as quickly as possible. The latter scenario
//         could be for any reason that is considered "critical" that the Strategy
//         exits its position as fast as possible, such as a sudden change in market
//         conditions leading to losses, or an imminent failure in an external
//         dependency.

//         This may only be called by governance, the guardian, or the Strategy
//         itself. Note that a Strategy will only revoke itself during emergency
//         shutdown.
//     @param strategy The Strategy to revoke.
//     """
//     assert msg.sender in [strategy, self.governance, self.guardian]
//     self._revokeStrategy(strategy)


// @external
// def addStrategyToQueue(strategy: address):
//     """
//     @notice
//         Adds `strategy` to `withdrawalQueue`.

//         This may only be called by governance or management.
//     @dev
//         The Strategy will be appended to `withdrawalQueue`, call
//         `setWithdrawalQueue` to change the order.
//     @param strategy The Strategy to add.
//     """
//     assert msg.sender in [self.management, self.governance]
//     # Must be a current Strategy
//     assert self.strategies[strategy].activation > 0
//     # Can't already be in the queue
//     last_idx: uint256 = 0
//     for s in self.withdrawalQueue:
//         if s == ZERO_ADDRESS:
//             break
//         assert s != strategy
//         last_idx += 1
//     # Check if queue is full
//     assert last_idx < MAXIMUM_STRATEGIES

//     self.withdrawalQueue[MAXIMUM_STRATEGIES - 1] = strategy
//     self._organizeWithdrawalQueue()
//     log StrategyAddedToQueue(strategy)


// @external
// def removeStrategyFromQueue(strategy: address):
//     """
//     @notice
//         Remove `strategy` from `withdrawalQueue`.

//         This may only be called by governance or management.
//     @dev
//         We don't do this with revokeStrategy because it should still
//         be possible to withdraw from the Strategy if it's unwinding.
//     @param strategy The Strategy to remove.
//     """
//     assert msg.sender in [self.management, self.governance]
//     for idx in range(MAXIMUM_STRATEGIES):
//         if self.withdrawalQueue[idx] == strategy:
//             self.withdrawalQueue[idx] = ZERO_ADDRESS
//             self._organizeWithdrawalQueue()
//             log StrategyRemovedFromQueue(strategy)
//             return  # We found the right location and cleared it
//     raise  # We didn't find the Strategy in the queue


// @view
// @internal
// def _debtOutstanding(strategy: address) -> uint256:
//     # See note on `debtOutstanding()`.
//     precisionFactor: uint256 = self.precisionFactor
//     strategy_debtLimit: uint256 = (
//         precisionFactor
//         * self.strategies[strategy].debtRatio
//         * self._totalAssets()
//         / MAX_BPS
//         / precisionFactor
//     )
//     strategy_totalDebt: uint256 = self.strategies[strategy].totalDebt

//     if self.emergencyShutdown:
//         return strategy_totalDebt
//     elif strategy_totalDebt <= strategy_debtLimit:
//         return 0
//     else:
//         return strategy_totalDebt - strategy_debtLimit


// @view
// @external
// def debtOutstanding(strategy: address = msg.sender) -> uint256:
//     """
//     @notice
//         Determines if `strategy` is past its debt limit and if any tokens
//         should be withdrawn to the Vault.
//     @param strategy The Strategy to check. Defaults to the caller.
//     @return The quantity of tokens to withdraw.
//     """
//     return self._debtOutstanding(strategy)


// @view
// @internal
// def _creditAvailable(strategy: address) -> uint256:
//     # See note on `creditAvailable()`.
//     if self.emergencyShutdown:
//         return 0
//     precisionFactor: uint256 = self.precisionFactor
//     vault_totalAssets: uint256 = self._totalAssets()
//     vault_debtLimit: uint256 = precisionFactor * self.debtRatio * vault_totalAssets / MAX_BPS / precisionFactor
//     vault_totalDebt: uint256 = self.totalDebt
//     strategy_debtLimit: uint256 = precisionFactor * self.strategies[strategy].debtRatio * vault_totalAssets / MAX_BPS / precisionFactor
//     strategy_totalDebt: uint256 = self.strategies[strategy].totalDebt
//     strategy_minDebtPerHarvest: uint256 = self.strategies[strategy].minDebtPerHarvest
//     strategy_maxDebtPerHarvest: uint256 = self.strategies[strategy].maxDebtPerHarvest

//     # Exhausted credit line
//     if strategy_debtLimit <= strategy_totalDebt or vault_debtLimit <= vault_totalDebt:
//         return 0

//     # Start with debt limit left for the Strategy
//     available: uint256 = strategy_debtLimit - strategy_totalDebt

//     # Adjust by the global debt limit left
//     available = min(available, vault_debtLimit - vault_totalDebt)

//     # Can only borrow up to what the contract has in reserve
//     # NOTE: Running near 100% is discouraged
//     available = min(available, self.token.balanceOf(self))

//     # Adjust by min and max borrow limits (per harvest)
//     # NOTE: min increase can be used to ensure that if a strategy has a minimum
//     #       amount of capital needed to purchase a position, it's not given capital
//     #       it can't make use of yet.
//     # NOTE: max increase is used to make sure each harvest isn't bigger than what
//     #       is authorized. This combined with adjusting min and max periods in
//     #       `BaseStrategy` can be used to effect a "rate limit" on capital increase.
//     if available < strategy_minDebtPerHarvest:
//         return 0
//     else:
//         return min(available, strategy_maxDebtPerHarvest)

// @view
// @external
// def creditAvailable(strategy: address = msg.sender) -> uint256:
//     """
//     @notice
//         Amount of tokens in Vault a Strategy has access to as a credit line.

//         This will check the Strategy's debt limit, as well as the tokens
//         available in the Vault, and determine the maximum amount of tokens
//         (if any) the Strategy may draw on.

//         In the rare case the Vault is in emergency shutdown this will return 0.
//     @param strategy The Strategy to check. Defaults to caller.
//     @return The quantity of tokens available for the Strategy to draw on.
//     """
//     return self._creditAvailable(strategy)


// @view
// @internal
// def _expectedReturn(strategy: address) -> uint256:
//     # See note on `expectedReturn()`.
//     strategy_lastReport: uint256 = self.strategies[strategy].lastReport
//     timeSinceLastHarvest: uint256 = block.timestamp - strategy_lastReport
//     totalHarvestTime: uint256 = strategy_lastReport - self.strategies[strategy].activation

//     # NOTE: If either `timeSinceLastHarvest` or `totalHarvestTime` is 0, we can short-circuit to `0`
//     if timeSinceLastHarvest > 0 and totalHarvestTime > 0 and Strategy(strategy).isActive():
//         # NOTE: Unlikely to throw unless strategy accumalates >1e68 returns
//         # NOTE: Calculate average over period of time where harvests have occured in the past
//         precisionFactor: uint256 = self.precisionFactor
//         return (
//             precisionFactor
//             * self.strategies[strategy].totalGain
//             * timeSinceLastHarvest
//             / totalHarvestTime
//             / precisionFactor
//         )
//     else:
//         return 0  # Covers the scenario when block.timestamp == activation


// @view
// @external
// def availableDepositLimit() -> uint256:
//     if self.depositLimit > self._totalAssets():
//         return self.depositLimit - self._totalAssets()
//     else:
//         return 0


// @view
// @external
// def expectedReturn(strategy: address = msg.sender) -> uint256:
//     """
//     @notice
//         Provide an accurate expected value for the return this `strategy`
//         would provide to the Vault the next time `report()` is called
//         (since the last time it was called).
//     @param strategy The Strategy to determine the expected return for. Defaults to caller.
//     @return
//         The anticipated amount `strategy` should make on its investment
//         since its last report.
//     """
//     return self._expectedReturn(strategy)


// @internal
// def _assessFees(strategy: address, gain: uint256) -> uint256:
//     # Issue new shares to cover fees
//     # NOTE: In effect, this reduces overall share price by the combined fee
//     # NOTE: may throw if Vault.totalAssets() > 1e64, or not called for more than a year
//     precisionFactor: uint256 = self.precisionFactor
//     management_fee: uint256 = (
//         precisionFactor *
//         (
//             (self.strategies[strategy].totalDebt - Strategy(strategy).delegatedAssets())
//             * (block.timestamp - self.strategies[strategy].lastReport)
//             * self.managementFee
//         )
//         / MAX_BPS
//         / SECS_PER_YEAR
//         / precisionFactor
//     )

//     # Only applies in certain conditions
//     strategist_fee: uint256 = 0
//     performance_fee: uint256 = 0

//     # NOTE: Applies if Strategy is not shutting down, or it is but all debt paid off
//     # NOTE: No fee is taken when a Strategy is unwinding it's position, until all debt is paid
//     if gain > 0:
//         # NOTE: Unlikely to throw unless strategy reports >1e72 harvest profit
//         strategist_fee = (
//             precisionFactor
//             * gain
//             * self.strategies[strategy].performanceFee
//             / MAX_BPS
//             / precisionFactor
//         )
//         # NOTE: Unlikely to throw unless strategy reports >1e72 harvest profit
//         performance_fee = precisionFactor * gain * self.performanceFee / MAX_BPS / precisionFactor

//     # NOTE: This must be called prior to taking new collateral,
//     #       or the calculation will be wrong!
//     # NOTE: This must be done at the same time, to ensure the relative
//     #       ratio of governance_fee : strategist_fee is kept intact
//     total_fee: uint256 = performance_fee + strategist_fee + management_fee
//     # ensure total_fee is not more than gain
//     if total_fee > gain:
//         total_fee = gain
//         # if total performance fee is greater than 100% then this will cause an underflow
//         management_fee = gain - performance_fee - strategist_fee
//     if total_fee > 0:  # NOTE: If mgmt fee is 0% and no gains were realized, skip
//         reward: uint256 = self._issueSharesForAmount(self, total_fee)

//         # Send the rewards out as new shares in this Vault
//         if strategist_fee > 0:  # NOTE: Guard against DIV/0 fault
//             # NOTE: Unlikely to throw unless sqrt(reward) >>> 1e39
//             strategist_reward: uint256 = (
//                 precisionFactor
//                 * strategist_fee
//                 * reward
//                 / total_fee
//                 / precisionFactor
//             )
//             self._transfer(self, strategy, strategist_reward)
//             # NOTE: Strategy distributes rewards at the end of harvest()
//         # NOTE: Governance earns any dust leftover from flooring math above
//         if self.balanceOf[self] > 0:
//             self._transfer(self, self.rewards, self.balanceOf[self])
//     return total_fee


// @external
// def report(gain: uint256, loss: uint256, _debtPayment: uint256) -> uint256:
//     """
//     @notice
//         Reports the amount of assets the calling Strategy has free (usually in
//         terms of ROI).

//         The performance fee is determined here, off of the strategy's profits
//         (if any), and sent to governance.

//         The strategist's fee is also determined here (off of profits), to be
//         handled according to the strategist on the next harvest.

//         This may only be called by a Strategy managed by this Vault.
//     @dev
//         For approved strategies, this is the most efficient behavior.
//         The Strategy reports back what it has free, then Vault "decides"
//         whether to take some back or give it more. Note that the most it can
//         take is `gain + _debtPayment`, and the most it can give is all of the
//         remaining reserves. Anything outside of those bounds is abnormal behavior.

//         All approved strategies must have increased diligence around
//         calling this function, as abnormal behavior could become catastrophic.
//     @param gain
//         Amount Strategy has realized as a gain on it's investment since its
//         last report, and is free to be given back to Vault as earnings
//     @param loss
//         Amount Strategy has realized as a loss on it's investment since its
//         last report, and should be accounted for on the Vault's balance sheet
//     @param _debtPayment
//         Amount Strategy has made available to cover outstanding debt
//     @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
//     """

//     # Only approved strategies can call this function
//     assert self.strategies[msg.sender].activation > 0
//     # No lying about total available to withdraw!
//     assert self.token.balanceOf(msg.sender) >= gain + _debtPayment

//     # We have a loss to report, do it before the rest of the calculations
//     if loss > 0:
//         self._reportLoss(msg.sender, loss)

//     # Assess both management fee and performance fee, and issue both as shares of the vault
//     totalFees: uint256 = self._assessFees(msg.sender, gain)

//     # Returns are always "realized gains"
//     self.strategies[msg.sender].totalGain += gain

//     # Outstanding debt the Strategy wants to take back from the Vault (if any)
//     # NOTE: debtOutstanding <= StrategyParams.totalDebt
//     debt: uint256 = self._debtOutstanding(msg.sender)
//     debtPayment: uint256 = min(_debtPayment, debt)

//     if debtPayment > 0:
//         self.strategies[msg.sender].totalDebt -= debtPayment
//         self.totalDebt -= debtPayment
//         debt -= debtPayment
//         # NOTE: `debt` is being tracked for later

//     # Compute the line of credit the Vault is able to offer the Strategy (if any)
//     credit: uint256 = self._creditAvailable(msg.sender)

//     # Update the actual debt based on the full credit we are extending to the Strategy
//     # or the returns if we are taking funds back
//     # NOTE: credit + self.strategies[msg.sender].totalDebt is always < self.debtLimit
//     # NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
//     if credit > 0:
//         self.strategies[msg.sender].totalDebt += credit
//         self.totalDebt += credit

//     # Give/take balance to Strategy, based on the difference between the reported gains
//     # (if any), the debt payment (if any), the credit increase we are offering (if any),
//     # and the debt needed to be paid off (if any)
//     # NOTE: This is just used to adjust the balance of tokens between the Strategy and
//     #       the Vault based on the Strategy's debt limit (as well as the Vault's).
//     totalAvail: uint256 = gain + debtPayment
//     if totalAvail < credit:  # credit surplus, give to Strategy
//         self.erc20_safe_transfer(self.token.address, msg.sender, credit - totalAvail)
//     elif totalAvail > credit:  # credit deficit, take from Strategy
//         self.erc20_safe_transferFrom(self.token.address, msg.sender, self, totalAvail - credit)
//     # else, don't do anything because it is balanced

//     # Update reporting time
//     self.strategies[msg.sender].lastReport = block.timestamp
//     self.lastReport = block.timestamp
//     self.lockedProfit = gain  - totalFees  # profit is locked and gradually released per block

//     log StrategyReported(
//         msg.sender,
//         gain,
//         loss,
//         debtPayment,
//         self.strategies[msg.sender].totalGain,
//         self.strategies[msg.sender].totalLoss,
//         self.strategies[msg.sender].totalDebt,
//         credit,
//         self.strategies[msg.sender].debtRatio,
//     )

//     if self.strategies[msg.sender].debtRatio == 0 or self.emergencyShutdown:
//         # Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
//         # NOTE: This is different than `debt` in order to extract *all* of the returns
//         return Strategy(msg.sender).estimatedTotalAssets()
//     else:
//         # Otherwise, just return what we have as debt outstanding
//         return debt


// @external
// def sweep(token: address, amount: uint256 = MAX_UINT256):
//     """
//     @notice
//         Removes tokens from this Vault that are not the type of token managed
//         by this Vault. This may be used in case of accidentally sending the
//         wrong kind of token to this Vault.

//         Tokens will be sent to `governance`.

//         This will fail if an attempt is made to sweep the tokens that this
//         Vault manages.

//         This may only be called by governance.
//     @param token The token to transfer out of this vault.
//     @param amount The quantity or tokenId to transfer out.
//     """
//     assert msg.sender == self.governance
//     # Can't be used to steal what this Vault is protecting
//     assert token != self.token.address
//     value: uint256 = amount
//     if value == MAX_UINT256:
//         value = ERC20(token).balanceOf(self)
//     self.erc20_safe_transfer(token, self.governance, value)

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

