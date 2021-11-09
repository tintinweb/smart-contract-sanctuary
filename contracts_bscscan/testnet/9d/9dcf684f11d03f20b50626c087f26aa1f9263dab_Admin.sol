// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./lib/IXBEP20.sol";
import "./lib/IBEP20.sol";
import "./lib/IPancakeswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Admin is Initializable {
    
    /**
    Governance
     */
    uint public current_system_state;

    address public admin;
    address public governor;
    address public ajax_prime;

    string public readme_hash;
    string public readme_link;
    string public system_policy_hash;
    string public system_policy_link;
    string public governor_policy_hash;
    string public governor_policy_link;

    address wjax_usd_pair; // = 0xb00eef3E8112410316A5ea2194c9DdCAAA38927d;
  
    modifier onlyAdmin() {
        require(admin == msg.sender, "Only Admin can perorm this operation.");
        _;
    }

    modifier isActive() {
        require(current_system_state == 2, "Exchange has been paused by Admin.");
        _;
    }
    
    IBEP20 public wjxn;
    IXBEP20 public wjax;
    IXBEP20 public vrp;
    IXBEP20 public jusd;
    IXBEP20 public jinr;

    uint public constant fee_decimal = 8;
    uint public constant ratio_decimal = 8;

    modifier onlyGovernor() {
        require(governor == msg.sender, "Only Governor can perform this operation.");
        _;
    }

    
    modifier onlyAjaxPrime() {
        require(ajax_prime == msg.sender, "Only Ajax prime can perform this operation.");
        _;
    }


    /**
    Admin Functions - To be disowned after finalization to reach decentralization.
     */


    function set_governor_public_key_address(address _governor) public onlyAdmin() {
        governor = _governor;
    }

    function get_governor_public_key_address() public view returns (address) {
        return governor;
    }


    function set_system_policy(string memory _policy_hash, string memory _policy_link) public onlyAdmin {
        system_policy_hash = _policy_hash;
        system_policy_link = _policy_link;
    }

    function set_system_status(uint flag) public onlyAdmin {

        current_system_state = flag;

        vrp.set_active_status(flag);
        jinr.set_active_status(flag);
        jusd.set_active_status(flag);
    
    }

    function system_status() public view returns(uint) {
        return current_system_state;
    }
    
    function register_colony(uint128 tx_tax, string memory colony_policy_link, bytes32 colony_policy_hash, address mother_colony_public_key) public {
        jusd.registerColony(msg.sender, tx_tax, colony_policy_link, colony_policy_hash, mother_colony_public_key);
        jinr.registerColony(msg.sender, tx_tax, colony_policy_link, colony_policy_hash, mother_colony_public_key);
    }

    function set_colony_address(address colony_address) public {
        jusd.setColonyAddress(msg.sender, colony_address);
        jinr.setColonyAddress(msg.sender, colony_address);
    }

    function transferAjaxPrimeOwnership(address _new_ajax_prime) public onlyAjaxPrime {
        ajax_prime = _new_ajax_prime;
    }

    function set_jaxcorp_dao(address _jax_corp_dao, uint128 tx_tax, string memory policy_link, bytes32 policy_hash) public onlyAjaxPrime {
        jusd.setJaxCorpDAO(_jax_corp_dao, tx_tax, policy_link, policy_hash);
        jinr.setJaxCorpDAO(_jax_corp_dao, tx_tax, policy_link, policy_hash);
    }

    function set_wjax_usd_pair_address(address _pair) public onlyAdmin {
        wjax_usd_pair = _pair;
    }

    function set_wjxn_usd_pair_address(address _pair) public onlyAdmin {
        wjxn_usd_pair = _pair;
    }
    
    function setTokenAddresses(address _wjxn, address _wjax, address _vrp, address _jusd, address _jinr) public onlyAdmin {
        wjxn = IBEP20(_wjxn);
        wjax = IXBEP20(_wjax);
        vrp = IXBEP20(_vrp);
        jusd = IXBEP20(_jusd);
        jinr = IXBEP20(_jinr);
    }

    function transferOwnershipOfTokens(address newOwner) public onlyAdmin {
        vrp.transferOwnership(newOwner);
        jusd.transferOwnership(newOwner);
        jinr.transferOwnership(newOwner);
    }

    function transferOwnership(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    /**
    Governor's Functions
     */


    function validate_wjxn_withdrawal(uint _amount) public view onlyGovernor returns (bool) {
            return true;
    }

    function validate_wjax_withdrawal(uint _amount) public view onlyGovernor returns (bool) {
        return true;
    }

    function validate_conversion_ratio(string memory _pair, uint _ratio) public view onlyGovernor returns (bool) {
        return true;
    }

    function set_readme(string memory _readme_hash, string memory _readme_link) public onlyGovernor {
        readme_hash = _readme_hash;
        readme_link = _readme_link;
    }

    function set_governor_policy(string memory _hash, string memory _link) public onlyGovernor {
        governor_policy_hash = _hash;
        governor_policy_link = _link;
    }

    function add_to_blacklist(address _addr) public onlyGovernor {
        vrp.add_to_blacklist(_addr);
        jusd.add_to_blacklist(_addr);
        jinr.add_to_blacklist(_addr);
    }

    function remove_from_blacklist(address _addr) public onlyGovernor {
        vrp.remove_from_blacklist(_addr);
        jusd.remove_from_blacklist(_addr);
        jinr.remove_from_blacklist(_addr);
    }

    function show_reserves() public view returns(uint, uint, uint, uint){
        uint wjax_reserves = wjax.balanceOf(address(this));
        uint wjax_pancake_reserves;

        // IPancakeswapV2Pair pair = IPancakeswapV2Pair(wjax_usd_pair);
        // (uint Res0, uint Res1,) = pair.getReserves();
        // if( pair.token1() == address(wjax) ){
        //     wjax_pancake_reserves = Res0;
        // } else {
        //     wjax_pancake_reserves = Res1;
        // }

        (uint wjax_price, ) = get_wjax_jusd_ratio();
        uint wjax_usd_value = wjax_reserves * wjax_price / (10 ** wjax.decimals());
        (uint jinr_jusd_ratio, ) = get_jinr_jusd_ratio();
        uint lsc_usd_value = jusd.totalSupply() + (jinr.totalSupply() * jinr_jusd_ratio / (10 ** ratio_decimal)) ;
        uint wjax_lsc_ratio = 0;
        if( lsc_usd_value == 0 ){
            wjax_lsc_ratio = wjax_usd_value * (10 ** ratio_decimal) / lsc_usd_value;
        }
        return (wjax_pancake_reserves, wjax_usd_value, lsc_usd_value, wjax_lsc_ratio);
    }

    function set_jinr_transaction_fee(uint _tx_fee,  uint _tx_fee_cap, address _wallet) public onlyGovernor {
        require(_tx_fee <= 10 ** fee_decimal * 3 / 100 , "Tx Fee percent can't be more than 3.");
        jinr.setTransactionFee(_tx_fee, _tx_fee_cap, _wallet);
    }

    function set_jinr_ubi_tax(uint _ubi_tax, address _wallet) public onlyAjaxPrime {
        require(_ubi_tax <= 10 ** fee_decimal * 100 / 100 , "UBI tax can't be more than 100.");
        jinr.setUbiTax(_ubi_tax, _wallet);
    }

    function set_jusd_transaction_fee(uint _tx_fee, uint _tx_fee_cap, address _wallet) public onlyGovernor {
        require(_tx_fee <= 10 ** fee_decimal * 3 / 100 , "Tx Fee percent can't be more than 3.");
        jusd.setTransactionFee(_tx_fee, _tx_fee_cap, _wallet);
    }

    function set_jusd_ubi_tax(uint _ubi_tax, address _wallet) public onlyAjaxPrime {
        require(_ubi_tax <= 10 ** fee_decimal * 100 / 100 , "UBI tax can't be more than 100.");
        jusd.setUbiTax(_ubi_tax, _wallet);
    }

    function set_cashback_percent(uint _cashback_percent) public onlyGovernor {
        require(_cashback_percent <= 10 ** fee_decimal * 30 / 100 , "Cashback percent can't be more than 30.");
        jusd.setCashback(_cashback_percent);
        jinr.setCashback(_cashback_percent);
    }

    function set_jinr_referral_fee(uint _referral_fee, uint _threshold) public onlyGovernor {
        require(_referral_fee <= 10 ** fee_decimal * 50 / 100 , "Referral Fee percent can't be more than 50.");
        jinr.setReferralFee(_referral_fee, _threshold);
    }

    function set_jusd_referral_fee(uint _referral_fee, uint _threshold) public onlyGovernor {
        require(_referral_fee <= 10 ** fee_decimal * 50 / 100 , "Referral Fee percent can't be more than 50.");
        jusd.setReferralFee(_referral_fee, _threshold);        
    }



    ///////////////////////////////////////////////////////////////////////////

    /**
     * WJXN_VRP Exchange
     */
    
    event Exchange_WJXN_VRP(
		address sender,
        uint wjxn_amount,
		uint vrp_amount
	);

    event Exchange_VRP_WJXN(
		address sender,
        uint vrp_amount,
		uint wjxn_amount
	);

    function withdraw_wjxn(uint _amount) public onlyGovernor {
        require(validate_wjxn_withdrawal(_amount) == true, "validate_wjxn_withdrawal failed");
        wjxn.transfer(governor, _amount);
    }

    function deposit_wjxn(uint _amount) public onlyGovernor {
        wjxn.transferFrom(governor, address(this), _amount);
    }

    function get_wjxn_jusd_ratio() public view returns (uint, uint)
    {
        // IPancakeswapV2Pair pair = IPancakeswapV2Pair(wjxn_usd_pair);
        // (uint Res0, uint Res1,) = pair.getReserves();
        // uint usd_decimal = 18;
        // // decimals
        // if( pair.token1() == address(wjxn) ){
        //     return (Res0 * (10 ** wjxn.decimals()) / Res1 , usd_decimal);
        // }
        // return (Res1 * (10 ** wjxn.decimals()) / Res0, usd_decimal); // return amount of token0 needed to buy token1
        return (10 ** 18, 18);
    }

    function get_wjxn_vrp_ratio() public view returns (uint, uint) {
        uint wjxn_vrp_ratio = 0;
        if( vrp.totalSupply() == 0 || wjxn.balanceOf(address(this)) == 0){
            wjxn_vrp_ratio = 1 * (10 ** 18);
        }
        else {
            wjxn_vrp_ratio = vrp.totalSupply() / wjxn.balanceOf(address(this));

        }
        return (wjxn_vrp_ratio, 18);
    }

    function freeze_vrp_wjxn_exchange(uint flag) public onlyGovernor {
        _freeze_vrp_wjxn_exchange = flag;
    }


    function set_wjxn_wjax_collateralization_ratio(uint wjxn_wjax_collateralization_ratio) public onlyGovernor {
        _wjxn_wjax_collateralization_ratio = wjxn_wjax_collateralization_ratio;
    }
    
    function get_wjxn_wjax_ratio(uint withdrawal_amount) public view returns (uint) {
        (uint wjxn_jusd_price, ) = get_wjxn_jusd_ratio();
        (uint wjax_jusd_price, ) = get_wjax_jusd_ratio();
        if( wjax.balanceOf(address(this)) == 0 ) return 10 ** ratio_decimal;
        if( wjxn.balanceOf(address(this)) == 0 ) return 0;
        return ((10 ** wjax.decimals()) * (wjxn.balanceOf(address(this)) - withdrawal_amount) 
            * wjxn_jusd_price * (10 ** ratio_decimal)) / (wjax.balanceOf(address(this)) * wjax_jusd_price);
    }
    
   function exchange_wjxn_vrp(uint wjxn_amount) public isActive returns (uint) {
        require(wjxn_amount > 0, "WJXN amount must not be zero.");
        require(wjxn.balanceOf(msg.sender) >= wjxn_amount, "Insufficient funds.");

        // Set wjxn_wjax_ratio of sender 
        uint wjxn_wjax_ratio_now = get_wjxn_wjax_ratio(0);
        uint wjxn_wjax_ratio_old = _wjxn_wjax_ratios[msg.sender];
        if(wjxn_wjax_ratio_old < wjxn_wjax_ratio_now)
            _wjxn_wjax_ratios[msg.sender] = wjxn_wjax_ratio_now;

        (uint wjxn_vrp_ratio,) = get_wjxn_vrp_ratio();
        wjxn.transferFrom(msg.sender, address(this), wjxn_amount);
        uint vrp_to_be_minted = wjxn_amount * wjxn_vrp_ratio;
        vrp.mint(msg.sender, vrp_to_be_minted);
		emit Exchange_WJXN_VRP(msg.sender, wjxn_amount, vrp_to_be_minted);
        return vrp_to_be_minted;
    }


    function exchange_vrp_wjxn(uint vrp_amount) public isActive returns (uint) {
        require(_freeze_vrp_wjxn_exchange == 0, "VRP-WJXN exchange is not allowed now.");
        require(vrp_amount > 0, "VRP amount must not be zero");
        require(wjxn.balanceOf(address(this))> 0, "No reserves.");
        (uint vrp_wjxn_ratio,) = get_vrp_wjxn_ratio();
        uint wjxn_to_be_withdrawn = vrp_amount * vrp_wjxn_ratio / (10 ** (18 * 2));
        require(wjxn_to_be_withdrawn >= 1, "Min. Amount for withdrawal is 1 WJXN.");
        require(wjxn.balanceOf(address(this))>= wjxn_to_be_withdrawn, "Insufficient WJXN in pool.");

        // check wjxn_wjax_ratio of sender 
        uint wjxn_wjax_ratio_now = get_wjxn_wjax_ratio(wjxn_to_be_withdrawn);

        require(wjxn_wjax_ratio_now >= _wjxn_wjax_collateralization_ratio, "Unable to withdraw as reserves are low.");

        vrp.burnFrom(msg.sender, vrp_amount);
        wjxn.transfer(msg.sender, wjxn_to_be_withdrawn);
		emit Exchange_VRP_WJXN(msg.sender, vrp_amount, wjxn_to_be_withdrawn);
        return wjxn_to_be_withdrawn;
    }

    function get_vrp_wjxn_ratio() public view returns (uint, uint) {
        uint vrp_wjxn_ratio = 0;
        if(wjxn.balanceOf(address(this)) == 0 || vrp.totalSupply() == 0) {
            vrp_wjxn_ratio = 0;
        }
        else {
            vrp_wjxn_ratio = wjxn.balanceOf(address(this)) * (10 ** (18 * 2)) / vrp.totalSupply();
        }
        return (vrp_wjxn_ratio, 18);
    }
    

    
    ///////////////////////////////////////////////////////////////////////////

    // WJAX-JUSD Exchange

    uint public wjax_jusd_markup_fee;    
    address public wjax_jusd_markup_fee_wallet;


    
    event Exchange_WJAX_JUSD(
		address sender,
		uint wjax_amount,
        uint jusd_amount
	);
    
    event Exchange_JUSD_WJAX(
		address sender,
		uint jusd_amount,
        uint wjax_amount
	);

    
    function withdraw_wjax(uint _amount) public onlyGovernor {
        require(validate_wjax_withdrawal(_amount) == true, "validate_wjax_withdrawal failed");
        wjax.transfer(governor, _amount);
    }

    function deposit_wjax(uint _amount) public onlyGovernor {
        wjax.transferFrom(governor, address(this), _amount);
    }

    function set_wjax_jusd_markup_fee(uint _wjax_jusd_markup_fee, address _wallet) public onlyGovernor {
        wjax_jusd_markup_fee = _wjax_jusd_markup_fee;
        wjax_jusd_markup_fee_wallet = _wallet;
    }

    function calculate_wjax_jusd_markup_fee(uint _amount) internal view returns (uint) {
        return _amount * wjax_jusd_markup_fee / (10 ** fee_decimal);
    }

    function get_wjax_jusd_ratio() public view returns (uint, uint)
    {
        // Comment the Below part in TestNet
        // IPancakeswapV2Pair pair = IPancakeswapV2Pair(wjax_usd_pair);
        // (uint Res0, uint Res1,) = pair.getReserves();
        // uint usd_decimal = 18;
        // // decimals
        // if( pair.token1() == address(wjax) ){
        //     return (Res0 * (10 ** wjax.decimals()) / Res1 , usd_decimal);
        // }
        // return (Res1 * (10 ** wjax.decimals()) / Res0, usd_decimal); // return amount of token0 needed to buy token1
        return (10 ** 18, 18);
    }
   
    function get_jusd_wjax_ratio() public view returns (uint, uint)
    {
        (uint wjax_jusd_ratio, uint usd_decimal) = get_wjax_jusd_ratio();
        uint jusd_wjax_ratio = (10 ** (usd_decimal*2)) / wjax_jusd_ratio;
        return (jusd_wjax_ratio, usd_decimal);
    }

	/*
        buy J-USD from WJAX
	*/
	function exchange_wjax_jusd(uint wjax_amount) public isActive returns (uint) {
        (uint wjax_price, ) = get_wjax_jusd_ratio();
        // Calculate fee
        uint fee_amount = calculate_wjax_jusd_markup_fee(wjax_amount);
        // markup fee wallet will receive fee
		require(wjax.balanceOf(msg.sender) >= wjax_amount, "Insufficient fund");
        // pay fee
        wjax.transferFrom(msg.sender, wjax_jusd_markup_fee_wallet, fee_amount);
        wjax.transferFrom(msg.sender, address(this), wjax_amount - fee_amount);

        uint jusd_amount = (wjax_amount - fee_amount) * wjax_price / (10 ** wjax.decimals());

        jusd.mint(msg.sender, jusd_amount);
		emit Exchange_WJAX_JUSD(msg.sender, wjax_amount, jusd_amount);
        return 0;
	}

    /*
        sell J-USD and receive WJAX
	*/


	function exchange_jusd_wjax(uint jusd_amount) public isActive returns (uint) {
        (uint wjax_price, ) = get_wjax_jusd_ratio();
       
		require(jusd.balanceOf(msg.sender) >= jusd_amount, "Insufficient fund");
        uint fee_amount = calculate_wjax_jusd_markup_fee(jusd_amount);
        uint wjax_amount = (jusd_amount - fee_amount) * (10 ** wjax.decimals()) / wjax_price;
		require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient reserves");
        jusd.burnFrom(msg.sender, jusd_amount);
        jusd.mint(wjax_jusd_markup_fee_wallet, fee_amount);
        // The recipient has to pay fee.
        wjax.transfer(msg.sender, wjax_amount);


		emit Exchange_JUSD_WJAX(msg.sender, jusd_amount, wjax_amount);
        return wjax_amount;
	}


    ///////////////////////////////////////////////////////////////////////////


    /**
     * JUSD-JINR Exchange
     */

    uint public usd_inr_ratio;

    uint public jusd_jinr_markup_fee;    
    address public jusd_jinr_markup_fee_wallet;

    event Convert_JUSD_JINR(
		address sender,
		uint jusd_amount,
        uint jinr_amount,
        uint fee_jinr_amount
    );

    event Convert_JINR_JUSD(
		address sender,
        uint jinr_amount,
		uint jusd_amount,
        uint fee_jusd_amount
    );


    function set_jusd_jinr_ratio(uint _ratio) public onlyGovernor {
        require(validate_conversion_ratio("jusd_jinr",_ratio) == true, "JUSD-JINR Conversion ratio is not valid.");
        usd_inr_ratio = _ratio;
    }

    function set_jusd_jinr_markup_fee(uint _markup_fee, address _wallet) public onlyGovernor {
        jusd_jinr_markup_fee = _markup_fee;
        jusd_jinr_markup_fee_wallet = _wallet;
    }

    function get_jusd_jinr_ratio() public view returns (uint, uint) {
        return (usd_inr_ratio, ratio_decimal);
    }

    function get_jinr_jusd_ratio() public view returns (uint, uint) {
        return (10 ** (ratio_decimal * 2) / usd_inr_ratio, ratio_decimal);
    }
    
    function calculate_jusd_jinr_markup_fee(uint _amount) internal view returns (uint) {
        return _amount * jusd_jinr_markup_fee / (10 ** fee_decimal);
    }

    function convert_jusd_jinr(uint _amount) public isActive returns (uint) {
        uint256 jinr_amount = _amount * usd_inr_ratio / (10 ** ratio_decimal);
        // Calculate Fee on receiver side
        uint256 fee_jinr_amount = calculate_jusd_jinr_markup_fee(jinr_amount);
		require(jusd.balanceOf(msg.sender) >= _amount, "Insufficient fund");
        jusd.burnFrom(msg.sender, _amount);
        // The recipient has to pay fee. 
        jinr.mint(jusd_jinr_markup_fee_wallet, fee_jinr_amount);
        jinr.mint(msg.sender, jinr_amount-fee_jinr_amount);
        emit Convert_JUSD_JINR(msg.sender, _amount, jinr_amount, fee_jinr_amount);
        return jinr_amount;
    }

    function convert_jinr_jusd(uint _amount) public isActive returns (uint) {
        uint256 jusd_amount = _amount * (10 ** ratio_decimal) / usd_inr_ratio;
        // Calculate Fee on receiver side
        uint256 fee_jusd_amount = calculate_jusd_jinr_markup_fee(jusd_amount);
		require(jinr.balanceOf(msg.sender) >= _amount, "Insufficient fund");
        jinr.burnFrom(msg.sender, _amount);
        // The recipient has to pay fee. 
        jusd.mint(jusd_jinr_markup_fee_wallet, fee_jusd_amount);
        jusd.mint(msg.sender, jusd_amount-fee_jusd_amount);
        emit Convert_JINR_JUSD(msg.sender, _amount, jusd_amount, fee_jusd_amount);
        return jusd_amount;
    }

    ///////////////////////////////////////////////////////////////////////////

    // New variables here
    address public wjxn_usd_pair;
    mapping (address => uint) public _wjxn_wjax_ratios;
    uint public _wjxn_wjax_collateralization_ratio;
    uint public _freeze_vrp_wjxn_exchange;


    ///////////////////////////////////////////////////////////////////////////

    // Initialization functions

    function initialize() public initializer {
        address sender = msg.sender;
        admin = sender;
        governor = sender;
        ajax_prime = sender;
        // fee_decimal = 8;
        // ratio_decimal = 8;
        // WJAX_JUSD exchange
        wjax_jusd_markup_fee = 100000;
        wjax_jusd_markup_fee_wallet = sender;
        wjax_usd_pair = 0x30C0039E721FBA14a21dFb3C6F7138d854c349EE;
        // JUSD_JINR exchange
        usd_inr_ratio = 7500000000;
        jusd_jinr_markup_fee = 2500000;
        jusd_jinr_markup_fee_wallet = sender;
        // System state
        current_system_state = 2;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Interface of the XBEP.
 */
interface IXBEP20 {

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev transfer ownership of token.
     */
    function transferOwnership(address _newOwner) external;

    /**
     * @dev Mint `amount` tokens to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function mint(address recipient, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `account`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     */
    function burnFrom(address account, uint256 amount) external;

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /** **** BEP20-Fee **** **/

    /**
     * @dev Function to set transaction fee.
     * @param tx_fee transaction fee
     */
    function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) external;

    /**
     * @dev Set ubi tax and ubi tax wallet
     */
    function setUbiTax(uint ubi_tax, address wallet) external;


    /**
     * @dev Register Colony
     * @param colony_public_key colony wallet address
     * @param tx_tax transaction fee for colony
     * @param colony_policy_link policy link
     * @param colony_policy_hash policy hash
     * @param mother_colony_public_key wallet address of mother colony of this colony.
     */
    function registerColony(address colony_public_key, uint128 tx_tax, string memory colony_policy_link, bytes32 colony_policy_hash, address mother_colony_public_key) external;

     /**
     * @dev Set colony address for the addr
     */
    function setColonyAddress(address addr,address colony) external;

    function setJaxCorpDAO(address jaxCorpDao_wallet, uint128 tx_tax, string memory policy_link, bytes32 policy_hash) external;

    /**
     * @dev Set referral fee and minimum amount that can set sender as referrer
     */

     
    function setReferralFee(uint referral_fee, uint referral_amount_threshold) external;

    /**
     * @dev Set cashback
     */
    function setCashback(uint _cashback_percent) external;

    /**
     * @dev Returns the referrer of address
     */
    function referrersOf(address sender) external view returns (address);

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

   
    /**      * blacklist     */

    function add_to_blacklist(address _addr) external;

    function check_blacklist(address _addr) external view returns (uint256);

    function remove_from_blacklist(address _addr) external;

    /**
     * Token active status
     */
    function active_status() external view returns (uint256);

    function set_active_status(uint flag) external;

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

pragma solidity ^0.8.9;

/**
 * @dev Interface of the BEP standard.
 */
interface IBEP20 {

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity >=0.7.0 <0.9.0;

interface IPancakeswapV2Pair {
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

pragma solidity ^0.8.0;

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