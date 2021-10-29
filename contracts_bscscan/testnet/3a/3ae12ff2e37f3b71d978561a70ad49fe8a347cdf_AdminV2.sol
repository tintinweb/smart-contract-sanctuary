// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./lib/IXBEP20.sol";
import "./tokens/WJXN.sol";
import "./lib/IPancakeswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AdminV2 is Initializable {
    
    /**
    Governance
     */
    address public admin;
    address public governor;
    address public ajax_prime;

    uint public current_system_state;

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
    
    WJXN public wjxn;
    IXBEP20 public wjax;
    IXBEP20 public vrp;
    IXBEP20 public jusd;
    IXBEP20 public jinr;

    uint public fee_decimal;
    uint public ratio_decimal;

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

    function register_colony(uint tx_tax, string memory colony_policy_link, string memory colony_policy_hash, address mother_colony_public_key) public {
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

    function set_jaxcorp_dao(address _jax_corp_dao, uint tx_tax, string memory policy_link, string memory policy_hash) public onlyAjaxPrime {
        jusd.setJaxCorpDAO(_jax_corp_dao, tx_tax, policy_link, policy_hash);
        jinr.setJaxCorpDAO(_jax_corp_dao, tx_tax, policy_link, policy_hash);
    }

    function set_wjax_usd_pair_address(address _pair) public onlyAdmin {
        wjax_usd_pair = _pair;
    }


    function setTokenAddresses(address _wjxn, address _wjax, address _vrp, address _jusd, address _jinr) public onlyAdmin {
        wjxn = WJXN(_wjxn);
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

        //Comment the below part in TestNet
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
        uint wjax_lsc_ratio = wjax_usd_value * (10 ** ratio_decimal) / lsc_usd_value;
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

   function exchange_wjxn_vrp(uint wjxn_amount) public isActive returns (uint) {
        require(wjxn_amount > 0, "WJXN amount must not be zero.");
        require(wjxn.balanceOf(msg.sender) >= wjxn_amount, "Insufficient funds.");
        (uint wjxn_vrp_ratio,) = get_wjxn_vrp_ratio();
        wjxn.transferFrom(msg.sender, address(this), wjxn_amount);
        uint vrp_to_be_minted = wjxn_amount * wjxn_vrp_ratio;
        vrp.mint(msg.sender, vrp_to_be_minted);
		emit Exchange_WJXN_VRP(msg.sender, wjxn_amount, vrp_to_be_minted);
        return vrp_to_be_minted;
    }

    function get_wjxn_vrp_ratio() public view returns (uint, uint) {
        uint wjxn_vrp_ratio = 0;
        if( vrp.totalSupply() == 0 || wjxn.balanceOf(address(this)) == 0){
            wjxn_vrp_ratio = 1 * (10 ** vrp.decimals());
        }
        else {
            wjxn_vrp_ratio = vrp.totalSupply() / wjxn.balanceOf(address(this));

        }
        return (wjxn_vrp_ratio, vrp.decimals());
    }


    function exchange_vrp_wjxn(uint vrp_amount) public isActive returns (uint) {
        require(vrp_amount > 0, "VRP amount must not be zero");
        require(wjxn.balanceOf(address(this))> 0, "No reserves.");
        (uint vrp_wjxn_ratio,) = get_vrp_wjxn_ratio();
        uint wjxn_to_be_withdrawn = vrp_amount * vrp_wjxn_ratio / (10 ** (vrp.decimals() * 2));
        require(wjxn_to_be_withdrawn >= 1, "Min. Amount for withdrawal is 1 WJXN.");
        require(wjxn.balanceOf(address(this))>= wjxn_to_be_withdrawn, "Insufficient WJXN in pool.");
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
            vrp_wjxn_ratio = wjxn.balanceOf(address(this)) * (10 ** (vrp.decimals() * 2)) / vrp.totalSupply();
        }
        return (vrp_wjxn_ratio, vrp.decimals());
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
        //Comment the Below part in TestNet
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

    // Initialization functions

    function initialize() public initializer {
        address sender = msg.sender;
        admin = sender;
        governor = sender;
        ajax_prime = sender;
        fee_decimal = 8;
        ratio_decimal = 8;
        // WJAX_JUSD exchange
        wjax_jusd_markup_fee = 100000;
        wjax_jusd_markup_fee_wallet = sender;
        wjax_usd_pair = 0x30C0039E721FBA14a21dFb3C6F7138d854c349EE;
        // JUSD_JINR exchange
        usd_inr_ratio = 7500000000;
        jusd_jinr_markup_fee = 2500000;
        jusd_jinr_markup_fee_wallet = sender;
        // System state
        current_system_state = 0;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function abc() public view returns (uint) {
        return 123;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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
    function registerColony(address colony_public_key, uint tx_tax, string memory colony_policy_link, string memory colony_policy_hash, address mother_colony_public_key) external;

     /**
     * @dev Set colony address for the addr
     */
    function setColonyAddress(address addr,address colony) external;

    function setJaxCorpDAO(address jaxCorpDao_wallet, uint tx_tax, string memory policy_link, string memory policy_hash) external;

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


/* This contract created to support token distribution in JaxNet project
*  By default, all transfers are paused. Except function, transferFromOwner, which allows
*  to distribute tokens.
*  Supply is limited to  40002164
*  Owner of contract may burn coins from his account
*/

contract WJXN is Ownable, ERC20, Pausable {

    constructor() ERC20("Wrapped JAXNET", "WJXN") {
        address owner = msg.sender;
        _mint(owner, 40002164);
        _pause();
        transferOwnership(owner);
    }

    function decimals() public pure override  returns (uint8) {
        return 0;
    }




    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be contract owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
      * @dev Check if system is not paused.
    */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}