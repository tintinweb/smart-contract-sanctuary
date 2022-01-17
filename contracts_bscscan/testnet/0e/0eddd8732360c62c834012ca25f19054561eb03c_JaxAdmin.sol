// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IJaxAdmin.sol";
import "./lib/BEP20.sol";

contract HaberStornetta is BEP20 {
    
    IBEP20 WJXN;

    constructor(address _WJXN) BEP20("Haber-Stornetta", "Haber-Stornetta"){
        _setupDecimals(8);
        WJXN = IBEP20(_WJXN);
    }

    function fromWJXN(uint256 amountIn) public {
        WJXN.transferFrom(msg.sender, address(this), amountIn);
        _mint(msg.sender, amountIn * 1e8);
    }

    function toWJXN(uint256 amountOut) public {
        _burn(msg.sender, amountOut * 1e8);
        WJXN.transfer(msg.sender, amountOut);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IJaxAdmin {

  function userIsAdmin (address _user) external view returns (bool);
  function userIsGovernor (address _user) external view returns (bool);
  function userIsAjaxPrime (address _user) external view returns (bool);
  function userIsOperator (address _user) external view returns (bool);
  function jaxSwap() external view returns (address);
  function system_status () external view returns (uint);
  function electGovernor (address _governor) external;  
  function blacklist(address _user) external view returns (bool);
  function fee_blacklist(address _user) external view returns (bool);
  function priceImpactLimit() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IBEP20.sol";

contract BEP20 is Ownable, IBEP20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

   constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

   function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

   function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

   function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

   function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
      uint256 currentAllowance = allowance(account, _msgSender());
      require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
      _approve(account, _msgSender(), currentAllowance - amount);
      _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

   function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./lib/BEP20.sol";
import "./JaxAdmin.sol";
import "./lib/Initializable.sol";

interface IJaxPlanet {

  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  function ubi_tax_wallet() external view returns (address);
  function ubi_tax() external view returns (uint);
  function jaxcorp_dao_wallet() external view returns (address);
  function getMotherColonyAddress(address) external view returns(address);
  function getColony(address addr) external view returns(Colony memory);
  function getUserColonyAddress(address user) external view returns(address);
}

/**
* @title JaxToken
* @dev Implementation of the JaxToken. Extension of {BEP20} that adds a fee transaction behaviour.
*/
contract WJAX is BEP20 {
  
  IJaxAdmin public jaxAdmin;
  address[] public gateKeepers;

  // transaction fee
  uint public transaction_fee = 0;
  uint public transaction_fee_cap = 0;

  // transaction fee wallet
  uint public referral_fee = 0;
  uint public referrer_amount_threshold = 0;
  uint public cashback = 0; //1e8
  // transaction fee decimal 
  // uint public constant _fee_decimal = 8;

  enum Status { InActive, Active }

  Status public active_status = Status.Active;
  
  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  address public tx_fee_wallet;
  
  mapping (address => address) public referrers;

  struct GateKeeper {
    uint mintLimit;
    uint burnLimit;
  }

  mapping (address => GateKeeper) gateKeeerInfo;

  event Set_Jax_Admin(address jax_admin);
  event Set_Gate_Keepers(address[] gate_keepers);
  event Set_Mint_Burn_Limit(address gateKeeper, uint mintLimit, uint burnLimit);
  event Set_Active_Status(Status status);
  event Set_Transaction_Fee(uint transaction_fee, uint trasnaction_fee_cap, address transaction_fee_wallet);
  event Set_Referral_Fee(uint referral_fee, uint referral_amount_threshold);
  event Set_Cashback(uint cashback_percent);

  /**
    * @dev Sets the value of the `cap`. This value is immutable, it can only be
    * set once during construction.
    */
    
  constructor (
      string memory name,
      string memory symbol,
      uint8 decimals
  )
      BEP20(name, symbol)
      payable
  {
      _setupDecimals(decimals);
      tx_fee_wallet = msg.sender;
  }

  modifier onlyJaxAdmin() {
    require(msg.sender == address(jaxAdmin), "Only JaxAdmin Contract");
    _;
  }

  modifier onlyAdmin() {
    require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner(), "Only JaxAdmin Contract");
    _;
  }

  modifier onlyAjaxPrime() {
    require(jaxAdmin.userIsAjaxPrime(msg.sender) || msg.sender == owner(), "Only AjaxPrime can perform this operation.");
    _;
  }

  modifier onlyGateKeeper() {
    uint cnt = gateKeepers.length;
    uint index;
    for(; index < cnt; index += 1) {
      if(gateKeepers[index] == msg.sender)
        break;
    }
    require(index < cnt, "Only GateKeeper can perform this action");
    _;
  }

  
  modifier notFrozen() {
    require(active_status == Status.Active, "Transfers have been frozen.");
    _;
  }

  function setJaxAdmin(address _jaxAdmin) external onlyOwner {
    jaxAdmin = IJaxAdmin(_jaxAdmin);  
    emit Set_Jax_Admin(_jaxAdmin);
  }

  function setGateKeepers(address[] calldata _gateKeepers) external onlyAjaxPrime {
    uint cnt = _gateKeepers.length;
    delete gateKeepers;
    for(uint index; index < cnt; index += 1) {
      gateKeepers.push(_gateKeepers[index]);
    }
    emit Set_Gate_Keepers(_gateKeepers);
  }

  function setMintBurnLimit(address gateKeeper, uint mintLimit, uint burnLimit) external onlyAjaxPrime {
    GateKeeper storage info = gateKeeerInfo[gateKeeper];
    info.mintLimit = mintLimit;
    info.burnLimit = burnLimit;
    emit Set_Mint_Burn_Limit(gateKeeper, mintLimit, burnLimit);
  }

  function set_active_status(Status status) external onlyAdmin { 
    active_status = status;
    emit Set_Active_Status(status);
  }

  function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) external onlyJaxAdmin {
      require(tx_fee <= 1e8 * 3 / 100 , "Tx Fee percent can't be more than 3.");
      transaction_fee = tx_fee;
      transaction_fee_cap = tx_fee_cap;
      tx_fee_wallet = wallet;
      emit Set_Transaction_Fee(tx_fee, tx_fee_cap, wallet);
  }

  /**
    * @dev Set referral fee and minimum amount that can set sender as referrer
    */
  function setReferralFee(uint _referral_fee, uint _referrer_amount_threshold) external onlyJaxAdmin {
      require(referral_fee <= 1e8 * 50 / 100 , "Referral Fee percent can't be more than 50.");
      referral_fee = _referral_fee;
      referrer_amount_threshold = _referrer_amount_threshold;
      emit Set_Referral_Fee(_referral_fee, _referrer_amount_threshold);
  }

  /**
    * @dev Set cashback
    */
  function setCashback(uint cashback_percent) external onlyJaxAdmin {
      require(cashback_percent <= 1e8 * 30 / 100 , "Cashback percent can't be more than 30.");
      cashback = cashback_percent; //1e8
      emit Set_Cashback(cashback_percent);
  }

  function transfer(address recipient, uint amount) public override(BEP20) notFrozen returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  } 

  function transferFrom(address sender, address recipient, uint amount) public override(BEP20) notFrozen returns (bool) {
    _transfer(sender, recipient, amount);
    uint currentAllowance = allowance(sender, msg.sender);
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  } 

  function _transfer(address sender, address recipient, uint amount) internal override(BEP20) {
    require(!jaxAdmin.blacklist(sender), "sender is blacklisted");
    require(!jaxAdmin.blacklist(recipient), "recipient is blacklisted");
    if(amount == 0) return;
    if(jaxAdmin.fee_blacklist(msg.sender) == true || jaxAdmin.fee_blacklist(recipient) == true) {
        return super._transfer(sender, recipient, amount);
    }
    if(referrers[sender] == address(0)) {
        referrers[sender] = address(0xdEaD);
    }

    // Calculate transaction fee
    uint tx_fee_amount = amount * transaction_fee / 1e8;

    if(tx_fee_amount > transaction_fee_cap) {
        tx_fee_amount = transaction_fee_cap;
    }
    
    address referrer = referrers[recipient];
    uint totalreferral_fees = 0;
    uint maxreferral_fee = tx_fee_amount * referral_fee;
    // Transfer referral fees to referrers (70% to first referrer, each 10% to other referrers)
    if( maxreferral_fee > 0 && referrer != address(0xdEaD) && referrer != address(0)){

        super._transfer(sender, referrer, 70 * maxreferral_fee / 1e8 / 100);
        referrer = referrers[referrer];
        totalreferral_fees += 70 * maxreferral_fee / 1e8 / 100;
        if( referrer != address(0xdEaD) && referrer != address(0)){
            super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
            referrer = referrers[referrer];
            totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
            if( referrer != address(0xdEaD) && referrer != address(0)){
                super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                referrer = referrers[referrer];
                totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                if( referrer != address(0xdEaD) && referrer != address(0)){
                    super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                    referrer = referrers[referrer];
                    totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                }
            }
        }
    }

    // Transfer transaction fee to transaction fee wallet
    // Sender will get cashback.
    if( tx_fee_amount > 0){
        super._transfer(sender, tx_fee_wallet, tx_fee_amount - totalreferral_fees - (tx_fee_amount * cashback / 1e8)); //1e8
    }
    
    IJaxPlanet jaxPlanet = IJaxPlanet(jaxAdmin.jaxPlanet());
    //Transfer of UBI Tax        
    uint ubi_tax_amount = amount * jaxPlanet.ubi_tax() / 1e8;
    if(ubi_tax_amount > 0){
        super._transfer(sender, jaxPlanet.ubi_tax_wallet(), ubi_tax_amount);  // ubi tax
    }

    address colony_address = jaxPlanet.getUserColonyAddress(recipient);

    if(colony_address == address(0)) {
        colony_address = jaxPlanet.getMotherColonyAddress(recipient);
    }

    // Transfer transaction tax to colonies.
    // immediate colony will get 50% of transaction tax, mother of that colony will get 25% ... mother of 4th colony will get 3.125%
    // 3.125% of transaction tax will go to JaxCorp Dao public key address.
    uint tx_tax_amount = amount * jaxPlanet.getColony(colony_address).transaction_tax / 1e8;     // Calculate transaction tax amount
    
    // transferTransactionTax(mother_colony_addresses[recipient], tx_tax_amount, 1);          // Transfer tax to colonies and jaxCorp Dao
    // Optimize transferTransactionTax by using loop instead of recursive function

    if( tx_tax_amount > 0 ){
        uint level = 1;
        uint tx_tax_temp = tx_tax_amount;
        
        // Level is limited to 5
        while( colony_address != address(0) && level++ <= 5 ){
            super._transfer(sender, colony_address, tx_tax_temp / 2);
            colony_address = jaxPlanet.getMotherColonyAddress(colony_address);
            tx_tax_temp = tx_tax_temp / 2;            
        }

        // transfer remain tx_tax to jaxcorpDao
        super._transfer(sender, jaxPlanet.jaxcorp_dao_wallet(), tx_tax_temp);
    }

    // Transfer tokens to recipient. recipient will pay the fees.
    require( amount > (tx_fee_amount + ubi_tax_amount + tx_tax_amount), "Total fee is greater than the transfer amount");
    super._transfer(sender, recipient, amount - tx_fee_amount - ubi_tax_amount - tx_tax_amount);

    // set referrers as first sender when transferred amount exceeds the certain limit.
    // recipient mustn't be sender's referrer, recipient couldn't be referrer itself
    if( recipient != sender  && amount >= referrer_amount_threshold  && referrers[recipient] == address(0)) {
        referrers[recipient] = sender;

    }
  }

  function _mint(address account, uint amount) internal override(BEP20) notFrozen onlyGateKeeper {
    require(!jaxAdmin.blacklist(account), "account is blacklisted");
    GateKeeper storage gateKeeper = gateKeeerInfo[msg.sender];
    require(gateKeeper.mintLimit >= amount, "Mint amount exceeds limit");
    super._mint(account, amount);
    gateKeeper.mintLimit -= amount;
  }

  function _burn(address account, uint amount) internal override(BEP20) notFrozen onlyGateKeeper {
    require(!jaxAdmin.blacklist(account), "account is blacklisted");
    GateKeeper storage gateKeeper = gateKeeerInfo[msg.sender];
    require(gateKeeper.burnLimit >= amount, "Burn amount exceeds limit");
    super._burn(account, amount);
    gateKeeper.burnLimit -= amount;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./lib/Initializable.sol";
import "./ref/PancakeRouter.sol";
import "./JaxOwnable.sol";
import "./JaxLibrary.sol";

interface IJaxAdmin {
  
  function userIsAdmin (address _user) external view returns (bool);
  function userIsGovernor (address _user) external view returns (bool);
  function userIsAjaxPrime (address _user) external view returns (bool);
  function userIsOperator (address _user) external view returns (bool);

  function jaxSwap() external view returns (address);
  function jaxPlanet() external view returns (address);

  function system_status () external view returns (uint);
  function electGovernor (address _governor) external;  

  function blacklist(address _user) external view returns (bool);
  function fee_blacklist(address _user) external view returns (bool);
} 

interface IJaxSwap {
  function setTokenAddresses(address _busd, address _wjxn, address _wjax, address _vrp, address _jusd) external;
}

interface IJaxToken {
  function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) external;
  function setReferralFee(uint _referral_fee, uint _referrer_amount_threshold) external;
  function setCashback(uint cashback_percent) external;
}

contract JaxAdmin is IJaxAdmin, Initializable, JaxOwnable {

  using JaxLibrary for JaxAdmin;

  address public admin;
  address public ajaxPrime;

  address public newGovernor;
  address public governor;

  address public jaxSwap;
  address public jaxPlanet;

  uint governorStartDate;

  uint public system_status;

  string public readme_hash;
  string public readme_link;
  string public system_policy_hash;
  string public system_policy_link;
  string public governor_policy_hash;
  string public governor_policy_link;

  event Set_Blacklist(address[] accounts, bool flag);
  event Set_Fee_Blacklist(address[] accounts, bool flag);

  mapping (address => bool) public blacklist;
  mapping (address => bool) public fee_blacklist;

  uint public priceImpactLimit;

  // ------ JaxSwap Control Parameters -------
  IPancakeRouter01 public router;

  IERC20 public wjxn;
  IERC20 public busd;
  IERC20 public wjax;
  IERC20 public vrp; 
  IERC20 public jusd;

  uint public wjax_usd_ratio;
  uint public use_wjax_usd_dex_pair;

  uint public wjxn_usd_ratio;
  uint public use_wjxn_usd_dex_pair;

  uint public wjax_jusd_markup_fee;    
  address public wjax_jusd_markup_fee_wallet;

  mapping (address => uint) public wjxn_wjax_ratios;
  uint public wjxn_wjax_collateralization_ratio;
  uint public wjax_collateralization_ratio;
  uint public freeze_vrp_wjxn_swap;
  
  struct JToken{
    uint jusd_ratio;
    uint markup_fee;
    address markup_fee_wallet;
    string name;
  }

  mapping (address => JToken) public jtokens;
  address[] public jtoken_addresses;

  uint set_wjax_usd_ratio_last_updated;
  address[] public operators;

  mapping (address => uint) public jusd_ratio_last_updated;

  event Set_Admin(address admin);
  event Set_AjaxPrime(address ajaxPrime);
  event Set_Governor(address governor);
  event Set_Operators(address[] operator);
  event Set_Jax_Swap(address jaxSwap);
  event Set_Jax_Planet(address jaxPlanet);
  event Elect_Governor(address governor);
  event Set_VRP(address vrp);
  event Set_System_Status(uint flag);
  event Set_System_Policy(string policy_hash, string policy_link);
  event Set_Readme(string readme_hash, string readme_link);
  event Set_Governor_Policy(string governor_policy_hash, string governor_policy_link);

  event Set_Price_Impact_Limit(uint limit);
  event Set_Token_Addresses(address wjxn, address wjax, address vrp, address jusd);
  event Set_JToken(address token, string name, uint jusd_ratio, uint markup_fee, address markup_fee_wallet);
  event Freeze_Vrp_Wjxn_Swap(uint flag);
  event Set_Wjxn_Wjax_Collateralization_Ratio(uint wjxn_wjax_collateralization_ratio);
  event Set_Wjax_Collateralization_Ratio(uint wjax_collateralization_ratio);
  event Set_Wjxn_Usd_Ratio(uint ratio);
  event Set_Wjax_Usd_Ratio(uint ratio);
  event Set_Wjax_Usd_Ratio_Emergency(uint ratio);
  event Set_Use_Wjxn_Usd_Dex_Pair(uint flag);
  event Set_Use_Wjax_Usd_Dex_Pair(uint flag);
  event Set_Wjax_Jusd_Markup_Fee(uint wjax_jusd_markup_fee, address wallet);
  event Set_Jtoken_Jusd_Ratio(address jtoken, uint old_ratio, uint new_ratio);

  modifier isActive() {
      require(system_status == 2, "Exchange has been paused by Admin.");
      _;
  }

  function userIsAdmin (address _user) public view returns (bool) {
    return admin == _user;
  }

  function userIsGovernor (address _user) public view returns (bool) {
    return governor == _user;
  }

  function userIsAjaxPrime (address _user) public view returns (bool) {
    return ajaxPrime == _user;
  }

  function userIsOperator (address _user) public view returns (bool) {
    uint index;
    uint operatorCnt = operators.length;
    for(; index < operatorCnt; index += 1) {
      if(operators[index] == _user)
        return true;
    }
    return false;
  }

  modifier onlyAdmin() {
    require(userIsAdmin(msg.sender) || msg.sender == owner, "Only Admin can perform this operation");
    _;
  }

  modifier onlyGovernor() {
    require(userIsGovernor(msg.sender), "Only Governor can perform this operation");
    _;
  }

  modifier onlyAjaxPrime() {
    require(userIsAjaxPrime(msg.sender) || msg.sender == owner, "Only AjaxPrime can perform this operation");
    _;
  }

  modifier onlyOperator() {
    require(userIsOperator(msg.sender) || userIsGovernor(msg.sender), "Only operators can perform this operation");
    _;
  }

  function setSystemStatus(uint status) external onlyAdmin {
    system_status = status;
    emit Set_System_Status(status);
  }

  function setAdmin (address _admin ) external onlyAdmin {
    admin = _admin;
    emit Set_Admin(_admin);
  }

  function setGovernor (address _governor) external onlyAdmin {
    governor = _governor;
    emit Set_Governor(_governor);
  }

  function setOperators (address[] calldata _operators) external onlyGovernor {
    uint operatorsCnt = _operators.length;
    delete operators;
    for(uint index; index < operatorsCnt; index += 1 ) {
      operators.push(_operators[index]);
    }
    emit Set_Operators(_operators);
  }

  function electGovernor (address _governor) external {
    require(msg.sender == address(vrp), "Only VRP contract can perform this operation.");
    newGovernor = governor;
    governorStartDate = block.timestamp + 7 * 24 * 3600;
    emit Elect_Governor(_governor);
  }

  function setAjaxPrime (address _ajaxPrime) external onlyAjaxPrime {
    ajaxPrime = _ajaxPrime;
    emit Set_AjaxPrime(_ajaxPrime);
  }

  function updateGovernor () external onlyAjaxPrime {
    require(newGovernor != governor && newGovernor != address(0x0), "New governor hasn't been elected");
    if(governorStartDate >= block.timestamp)
      governor = newGovernor;
  }

  function set_system_policy(string memory _policy_hash, string memory _policy_link) public onlyAdmin {
    system_policy_hash = _policy_hash;
    system_policy_link = _policy_link;
    emit Set_System_Policy(_policy_hash, _policy_link);
  }

  function set_readme(string memory _readme_hash, string memory _readme_link) external onlyGovernor {
    readme_hash = _readme_hash;
    readme_link = _readme_link;
    emit Set_Readme(_readme_hash, _readme_link);
  }
  
  function set_governor_policy(string memory _hash, string memory _link) external onlyGovernor {
    governor_policy_hash = _hash;
    governor_policy_link = _link;
    emit Set_Governor_Policy(_hash, _link);
  }


  function set_fee_blacklist(address[] calldata accounts, bool flag) external onlyAdmin {
      uint length = accounts.length;
      for(uint i = 0; i < length; i++) {
          fee_blacklist[accounts[i]] = flag;
      }
    emit Set_Fee_Blacklist(accounts, flag);
  }

  function set_blacklist(address[] calldata accounts, bool flag) external onlyGovernor {
    uint length = accounts.length;
    for(uint i = 0; i < length; i++) {
      blacklist[accounts[i]] = flag;
    }
    emit Set_Blacklist(accounts, flag);
  }

  function setTransactionFee(address token, uint tx_fee, uint tx_fee_cap, address wallet) external onlyGovernor {
      IJaxToken(token).setTransactionFee(tx_fee, tx_fee_cap, wallet);
  }

  function setReferralFee(address token, uint _referral_fee, uint _referrer_amount_threshold) public onlyAdmin {
      IJaxToken(token).setReferralFee(_referral_fee, _referrer_amount_threshold);
  }

  function setCashback(address token, uint cashback_percent) public onlyAdmin {
      IJaxToken(token).setCashback(cashback_percent);
  }

  // ------ jaxSwap -----
  function setJaxSwap(address _jaxSwap) public onlyAdmin {
    jaxSwap = _jaxSwap;
    emit Set_Jax_Swap(_jaxSwap);
  }

  // ------ jaxPlanet -----
  function setJaxPlanet(address _jaxPlanet) public onlyAdmin {
    jaxPlanet = _jaxPlanet;
    emit Set_Jax_Planet(_jaxPlanet);
  }

  function setTokenAddresses(address _busd, address _wjxn, address _wjax, address _vrp, address _jusd) public onlyAdmin {
    busd = IERC20(_busd);
    wjxn = IERC20(_wjxn);
    wjax = IERC20(_wjax);
    vrp = IERC20(_vrp);
    jusd = IERC20(_jusd);
    IJaxSwap(jaxSwap).setTokenAddresses(_busd, _wjxn, _wjax, _vrp, _jusd);
    emit Set_Token_Addresses(_wjxn, _wjax, _vrp, _jusd);
  }

  function set_jtoken(address token, string calldata name, uint jusd_ratio, uint markup_fee, address markup_fee_wallet) external onlyAdmin {
    require(markup_fee <= 25 * 1e5, "markup fee cannot over 2.5%");
    require(jusd_ratio > 0, "JUSD-JToken ratio should not be zero");
    JToken storage newtoken = jtokens[token];
    if(newtoken.jusd_ratio == 0) {
      jtoken_addresses.push(token);
    }
    newtoken.name = name;
    newtoken.jusd_ratio = jusd_ratio;
    newtoken.markup_fee = markup_fee;
    newtoken.markup_fee_wallet = markup_fee_wallet;
    emit Set_JToken(token, name, jusd_ratio, markup_fee, markup_fee_wallet);
  }

  function set_jtoken_jusd_ratio(address token, uint jusd_ratio) external onlyOperator {
    require(block.timestamp >= jusd_ratio_last_updated[token] + 3600, "Only once an hour");
    JToken storage jtoken = jtokens[token];
    uint old_ratio = jtoken.jusd_ratio;
    require(jusd_ratio <= old_ratio * 103 / 100 && jusd_ratio >= old_ratio * 97 / 100, "Out of 3% ratio change");
    jtoken.jusd_ratio = jusd_ratio;
    jusd_ratio_last_updated[token] = block.timestamp;
    emit Set_Jtoken_Jusd_Ratio(token, old_ratio, jusd_ratio);
  }

  function delete_jtoken(address token) external onlyAdmin {
    JToken storage jtoken = jtokens[token];
    jtoken.jusd_ratio = 0;
    uint jtoken_index;
    uint jtoken_count = jtoken_addresses.length;
    for(; jtoken_index < jtoken_count; jtoken_index += 1){
      if(jtoken_addresses[jtoken_index] == token)
        break;
    }
    if(jtoken_count > 1)
      jtoken_addresses[jtoken_index] = jtoken_addresses[jtoken_count-1];
    jtoken_addresses.pop();
  }

  function set_use_wjxn_usd_dex_pair(uint flag) external onlyGovernor {
    use_wjxn_usd_dex_pair = flag;
    emit Set_Use_Wjxn_Usd_Dex_Pair(flag);
  }

  function set_use_wjax_usd_dex_pair(uint flag) external onlyGovernor {
    use_wjax_usd_dex_pair = flag;
    emit Set_Use_Wjax_Usd_Dex_Pair(flag);
  }

  function set_wjxn_usd_ratio(uint ratio) external onlyOperator {
    wjxn_usd_ratio = ratio;
    emit Set_Wjxn_Usd_Ratio(ratio);
  }

  function set_wjax_usd_ratio(uint ratio) external onlyOperator {
    require(block.timestamp >= set_wjax_usd_ratio_last_updated + 3600, "Only once an hour");
    require(wjax_usd_ratio == 0 || (wjax_usd_ratio * 105 / 100 >= ratio && wjax_usd_ratio * 95 / 100 <= ratio), 
      "Ratio change should not over 5%");
    wjax_usd_ratio = ratio;
    set_wjax_usd_ratio_last_updated = block.timestamp;
    emit Set_Wjax_Usd_Ratio(ratio);
  }

  function set_wjax_usd_ratio_emergency(uint ratio) external onlyGovernor {
    wjax_usd_ratio = ratio;
    emit Set_Wjax_Usd_Ratio_Emergency(ratio);
  }

  function get_wjxn_wjax_ratio(uint withdrawal_amount) public view returns (uint) {
    if( wjax.balanceOf(jaxSwap) == 0 ) return 1e8;
    if( wjxn.balanceOf(jaxSwap) == 0 ) return 0;
    return 1e8 * ((10 ** wjax.decimals()) * (wjxn.balanceOf(jaxSwap) - withdrawal_amount) 
        * get_wjxn_jusd_ratio()) / (wjax.balanceOf(jaxSwap) * get_wjax_jusd_ratio());
  }
  
  function get_wjxn_jusd_ratio() public view returns (uint){
    
    // Using manual ratio.
    if( use_wjxn_usd_dex_pair == 0 ) {
      return wjxn_usd_ratio;
    }

    return getPrice(address(wjxn), address(busd)); // return amount of token0 needed to buy token1
  }

  function get_wjxn_vrp_ratio() public view returns (uint) {
    uint wjxn_vrp_ratio = 0;
    if( vrp.totalSupply() == 0 || wjxn.balanceOf(jaxSwap) == 0){
      wjxn_vrp_ratio = 1e8;
    }
    else {
      wjxn_vrp_ratio = 1e8 * vrp.totalSupply() * (10 ** wjxn.decimals()) / wjxn.balanceOf(jaxSwap) / (10 ** vrp.decimals());
    }
    return wjxn_vrp_ratio;
  }
  
  function get_vrp_wjxn_ratio() public view returns (uint) {
    uint vrp_wjxn_ratio = 0;
    if(wjxn.balanceOf(jaxSwap) == 0 || vrp.totalSupply() == 0) {
        vrp_wjxn_ratio = 0;
    }
    else {
        vrp_wjxn_ratio = 1e8 * wjxn.balanceOf(jaxSwap) * (10 ** vrp.decimals()) / vrp.totalSupply() / (10 ** wjxn.decimals());
    }
    return (vrp_wjxn_ratio);
  }

  function get_wjax_jusd_ratio() public view returns (uint){
    // Using manual ratio.
    if( use_wjax_usd_dex_pair == 0 ) {
        return wjax_usd_ratio;
    }

    return getPrice(address(wjax), address(busd));
  }

  function get_jusd_wjax_ratio() public view returns (uint){
    return 1e8 * 1e8 / get_wjax_jusd_ratio();
  }

  function set_freeze_vrp_wjxn_swap(uint flag) external onlyGovernor {
    freeze_vrp_wjxn_swap = flag;
    emit Freeze_Vrp_Wjxn_Swap(flag);
  }

  function set_wjxn_wjax_collateralization_ratio(uint ratio) external onlyGovernor {
    wjxn_wjax_collateralization_ratio = ratio;
    emit Set_Wjxn_Wjax_Collateralization_Ratio(ratio);
  }

  function set_wjax_collateralization_ratio(uint ratio) external onlyGovernor {
    wjax_collateralization_ratio = ratio;
    emit Set_Wjax_Collateralization_Ratio(ratio);
  }

  function set_wjax_jusd_markup_fee(uint _wjax_jusd_markup_fee, address _wallet) external onlyGovernor {
    require(_wjax_jusd_markup_fee <= 25 * 1e5, "Markup fee must be less than 2.5%");
    wjax_jusd_markup_fee = _wjax_jusd_markup_fee;
    wjax_jusd_markup_fee_wallet = _wallet;
    emit Set_Wjax_Jusd_Markup_Fee(_wjax_jusd_markup_fee, _wallet);
  }

  function setPriceImpactLimit(uint limit) external onlyGovernor {
    require(limit <= 3e6, "price impact cannot be over 3%");
    priceImpactLimit = limit;
    emit Set_Price_Impact_Limit(limit);
  }

  // wjax_usd_value: decimal 8, lsc_usd_value decimal: 18
  function show_reserves() public view returns(uint, uint, uint){
    uint wjax_reserves = wjax.balanceOf(jaxSwap);

    uint wjax_usd_value = wjax_reserves * get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / 1e8 / (10 ** wjax.decimals());
    uint lsc_usd_value = jusd.totalSupply();

    uint jtoken_count = jtoken_addresses.length;
    for(uint i = 0; i < jtoken_count; i++) {
      address addr = jtoken_addresses[i];
      lsc_usd_value += IERC20(addr).totalSupply() * 1e8 / jtokens[addr].jusd_ratio;
    }
    uint wjax_lsc_ratio = 1;
    if( lsc_usd_value > 0 ){
      wjax_lsc_ratio = wjax_usd_value * 1e8 / lsc_usd_value;
    }
    return (wjax_lsc_ratio, wjax_usd_value, lsc_usd_value);
  }
  // ------ end jaxSwap ------

  function getPrice(address token0, address token1) internal view returns(uint) {
    IPancakePair pair = IPancakePair(IPancakeFactory(router.factory()).getPair(token0, token1));
    (uint res0, uint res1,) = pair.getReserves();
    res0 *= 10 ** (18 - IERC20(pair.token0()).decimals());
    res1 *= 10 ** (18 - IERC20(pair.token1()).decimals());
    if(pair.token0() == token1) {
        if(res1 > 0)
            return 1e8 * res0 / res1;
    } 
    else {
        if(res0 > 0)
            return 1e8 * res1 / res0;
    }
    return 0;
  }
  
  function initialize(address pancakeRouter) public initializer {
    address sender = msg.sender;
    admin = sender;
    governor = sender;
    ajaxPrime = sender;
    // System state
    system_status = 2;
    owner = sender;
    router = IPancakeRouter01(pancakeRouter);
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

/**
 *Submitted for verification at BscScan.com on 2021-04-23
*/
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

// File: @uniswap\lib\contracts\libraries\TransferHelper.sol

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

// File: contracts\interfaces\IPancakeRouter01.sol

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

// File: contracts\interfaces\IPancakeRouter02.sol

interface IPancakeRouter02 is IPancakeRouter01 {
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

// File: contracts\interfaces\IPancakeFactory.sol

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// File: contracts\libraries\SafeMath.sol

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, 'ds-math-div-zero');
        z = x / y;
    }
}

// File: contracts\interfaces\IPancakePair.sol

interface IPancakePair {
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

// File: contracts\libraries\PancakeLibrary.sol



library PancakeLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'PancakeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'PancakeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        // (address token0, address token1) = sortTokens(tokenA, tokenB);
        // pair = address(uint160(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         factory,
        //         keccak256(abi.encodePacked(token0, token1)),
        //         hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
        //     )))));
        pair = IPancakeFactory(factory).getPair(tokenA, tokenB);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IPancakePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts\interfaces\IERC20.sol

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\interfaces\IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts\PancakeRouter.sol







contract PancakeRouter is IPancakeRouter02 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) {
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
        if (IPancakeFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPancakeFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = PancakeLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = PancakeLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = PancakeLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
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
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPancakePair(pair).mint(to);
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
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPancakePair(pair).mint(to);
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
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        IPancakePair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IPancakePair(pair).burn(to);
        (address token0,) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'PancakeRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'PancakeRouter: INSUFFICIENT_B_AMOUNT');
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
        address pair = PancakeLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint256).max : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
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
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
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
        address pair = PancakeLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint256).max : liquidity;
        IPancakePair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IPancakePair(PancakeLibrary.pairFor(factory, input, output)).swap(
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
        amounts = PancakeLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
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
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
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
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
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
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
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
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        amounts = PancakeLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'PancakeRouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(PancakeLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = PancakeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? PancakeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
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
        require(path[0] == WETH, 'PancakeRouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
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
        require(path[path.length - 1] == WETH, 'PancakeRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, PancakeLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'PancakeRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return PancakeLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return PancakeLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return PancakeLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return PancakeLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return PancakeLibrary.getAmountsIn(factory, amountOut, path);
    }
}



/**
 *Submitted for verification at BscScan.com on 2020-09-03
*/

contract WETH {
    string public name     = "Wrapped BNB";
    string public symbol   = "WBNB";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return balanceOf[address(this)];
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
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
pragma solidity 0.8.9;

contract JaxOwnable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
      require(owner == msg.sender, "JaxOwnable: caller is not the owner");
      _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Internal function without access restriction.
  */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.9;

import "./ref/PancakeRouter.sol";

library JaxLibrary {

  function swapWithPriceImpactLimit(address router, uint amountIn, uint limit, address[] memory path, address to) internal returns(uint[] memory) {
    IPancakeRouter01 pancakeRouter = IPancakeRouter01(router);
    
    IPancakePair pair = IPancakePair(IPancakeFactory(pancakeRouter.factory()).getPair(path[0], path[1]));
    (uint res0, uint res1, ) = pair.getReserves();
    uint reserveIn;
    uint reserveOut;
    if(pair.token0() == path[0]) {
      reserveIn = res0;
      reserveOut = res1;
    } else {
      reserveIn = res1;
      reserveOut = res0;
    }
    uint amountOut = pancakeRouter.getAmountOut(amountIn, reserveIn, reserveOut);
    require((reserveOut * 1e18 / reserveIn) * (1e8 - limit) / 1e8 <= amountOut * 1e18 / amountIn, "Price Impact too high");
    return pancakeRouter.swapExactTokensForTokens(amountIn, 0, path, to, block.timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../IJaxAdmin.sol";
import "../ref/PancakeRouter.sol";
import "../lib/Initializable.sol";
import "../JaxOwnable.sol";

contract UbiTaxWallet is Initializable, JaxOwnable {

    event Set_Jax_Admin(address old_jax_admin, address new_jax_admin);
    event Set_Yield_Tokens(address[] tokens);
    event Set_Reward_Token(address rewardToken);
    event Swap_Tokens(address[] tokens);

    address[] public yieldTokens;

    address public rewardToken;
    IJaxAdmin public jaxAdmin;

    IPancakeRouter01 public pancakeRouter;

    modifier onlyAdmin() {
        require(jaxAdmin.userIsAjaxPrime(msg.sender) || msg.sender == owner, "Only Admin can perform this operation.");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _admin_address, address _pancakeRouter, address _rewardToken) public initializer {
        jaxAdmin = IJaxAdmin(_admin_address);
        pancakeRouter = IPancakeRouter01(_pancakeRouter); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function set_yield_tokens(address[] calldata newYieldTokens) public onlyAdmin {
        delete yieldTokens;
        uint tokenLength = newYieldTokens.length;
        for (uint i=0; i < tokenLength; i++) {
            yieldTokens.push(newYieldTokens[i]);
            IERC20(newYieldTokens[i]).approve(address(pancakeRouter), type(uint256).max);
        }
        emit Set_Yield_Tokens(newYieldTokens);
    }

    function set_reward_token(address _rewardToken) public onlyAdmin {
        rewardToken = _rewardToken;
        emit Set_Reward_Token(_rewardToken);
    }

    function swap_tokens() public onlyAdmin {
        uint tokenCount = yieldTokens.length;
        address yieldToken;
        address[] memory path = new address[](2);
        uint amountIn;
        for(uint i = 0; i < tokenCount; i++) {
            yieldToken = yieldTokens[i];
            path[0] = yieldToken;
            path[1] = rewardToken;
            amountIn = IERC20(yieldToken).balanceOf(address(this));
            if(amountIn == 0) {
                continue;
            }
            pancakeRouter.swapExactTokensForTokens(
                amountIn, 
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        emit Swap_Tokens(yieldTokens);
    }

    function withdrawByAdmin(address token, uint amount) external onlyAdmin {
        IERC20(token).transfer(msg.sender, amount);
    }

    function setJaxAdmin(address newJaxAdmin) external onlyAdmin {
        address oldJaxAdmin = address(jaxAdmin);
        jaxAdmin = IJaxAdmin(newJaxAdmin);
        jaxAdmin.system_status();
        emit Set_Jax_Admin(oldJaxAdmin, newJaxAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../IJaxAdmin.sol";
import "../ref/PancakeRouter.sol";
import "../lib/Initializable.sol";
import "../JaxOwnable.sol";

interface IYield {
    function deposit_reward(uint amount) external;
}

contract TxFeeWallet is Initializable, JaxOwnable {

    event Set_Jax_Admin(address old_jax_admin, address new_jax_admin);
    event Set_Yield_Tokens(address[] tokens);
    event Set_Reward_Token(address rewardToken);
    event Set_Yield_Info(YieldInfo[] info);
    event Pay_Yield();    
    event Swap_Tokens(address[] tokens);

    struct YieldInfo {
        uint allocPoint; // How many allocation points assigned to this yield
        address yield_address;
        bool isContract;
    }

    // Total allocation poitns. Must be the sum of all allocation points in all yields.
    uint256 public constant totalAllocPoint = 1000;

    address[] public yieldTokens;

    // Info of each yield.
    YieldInfo[] public yieldInfo;

    address public rewardToken;
    IJaxAdmin public jaxAdmin;

    IPancakeRouter01 public pancakeRouter;

    modifier onlyAdmin() {
        require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner, "Only Admin can perform this operation.");
        _;
    }

    modifier onlyGovernor() {
        require(jaxAdmin.userIsGovernor(msg.sender), "Only Governor can perform this operation.");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _admin_address, address _pancakeRouter, address _rewardToken) public initializer {
        jaxAdmin = IJaxAdmin(_admin_address);
        pancakeRouter = IPancakeRouter01(_pancakeRouter); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        rewardToken = _rewardToken;
        owner = msg.sender;
    }

    function set_yield_info(YieldInfo[] calldata newYieldInfo) public onlyGovernor {
        delete yieldInfo;
        uint yieldLength = newYieldInfo.length;
        uint sumAllocPoint;
        for (uint i=0; i < yieldLength; i++) {
            YieldInfo memory yield = newYieldInfo[i];
            sumAllocPoint += yield.allocPoint;
            yieldInfo.push(yield);
            if(yield.isContract) {
                IERC20(rewardToken).approve(yield.yield_address, type(uint).max);
            }
        }
        require(sumAllocPoint == totalAllocPoint, "sum of alloc point should be 1000");
        emit Set_Yield_Info(newYieldInfo);
    }

    function set_yield_tokens(address[] calldata newYieldTokens) public onlyAdmin {
        delete yieldTokens;
        uint tokenLength = newYieldTokens.length;
        for (uint i=0; i < tokenLength; i++) {
            yieldTokens.push(newYieldTokens[i]);
            IERC20(newYieldTokens[i]).approve(address(pancakeRouter), type(uint256).max);
        }
        emit Set_Yield_Tokens(newYieldTokens);
    }

    function set_reward_token(address _rewardToken) public onlyAdmin {
        rewardToken = _rewardToken;
        emit Set_Reward_Token(_rewardToken);
    }

    function pay_yield() public onlyGovernor {
        swap_tokens();
        uint yieldLength = yieldInfo.length;
        uint tokenBalance = IERC20(rewardToken).balanceOf(address(this));
        for (uint i=0; i < yieldLength; i++) {
            YieldInfo memory yield = yieldInfo[i];
            if(yield.isContract) {
                IYield(yield.yield_address).deposit_reward(tokenBalance * yield.allocPoint / totalAllocPoint);
            } else {
                IERC20(rewardToken).transfer(yield.yield_address, tokenBalance * yield.allocPoint / totalAllocPoint);
            }
        }
        emit Pay_Yield();
    }

    function swap_tokens() internal {
        uint tokenCount = yieldTokens.length;
        address yieldToken;
        address[] memory path = new address[](2);
        uint amountIn;
        for(uint i = 0; i < tokenCount; i++) {
            yieldToken = yieldTokens[i];
            path[0] = yieldToken;
            path[1] = rewardToken;
            amountIn = IERC20(yieldToken).balanceOf(address(this));
            if(amountIn == 0) {
                continue;
            }
            pancakeRouter.swapExactTokensForTokens(
                amountIn, 
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        emit Swap_Tokens(yieldTokens);
    }

    function withdrawByAdmin(address token, uint amount) external onlyAdmin {
        IERC20(token).transfer(msg.sender, amount);
    }

    function setJaxAdmin(address newJaxAdmin) external onlyAdmin {
        address oldJaxAdmin = address(jaxAdmin);
        jaxAdmin = IJaxAdmin(newJaxAdmin);
        jaxAdmin.system_status();
        emit Set_Jax_Admin(oldJaxAdmin, newJaxAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/Initializable.sol";
import "../ref/PancakeRouter.sol";
import "../IJaxAdmin.sol";
import "../JaxLibrary.sol";
import "../JaxOwnable.sol";

contract LpYield is Initializable, JaxOwnable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    using JaxLibrary for LpYield;

    using SafeMath for uint;

    IJaxAdmin public jaxAdmin;

    // Info of each user.
    
    struct EpochInfo {
        uint blockCount;
        uint reward;
        uint rewardPerShare; // 1e36
        uint totalRewardPerBalance;
    }

    EpochInfo[] public epochInfo;

    uint public currentEpoch;
    uint lastEpochBlock;
    
    uint epochSharePlus;
    uint epochShareMinus;

    struct UserInfo {
        uint amount;
        uint currentEpoch;
        uint sharePlus;
        uint shareMinus;
        uint rewardPaid;
        uint totalReward;
        uint busdStaked;
    }

    uint public totalAmount;
    uint public totalBusdStaked;
    
    uint public totalReward;

    mapping(address => UserInfo) public userInfo;

    // The REWARD TOKEN (WJXN)
    address public rewardToken;

    address public BUSD;
    address public WJAX;

    // PancakeRouter
    IPancakeRouter01 public router;

    uint public withdraw_fairPriceHigh;
    uint public withdraw_fairPriceLow;
    uint public deposit_fairPriceHigh;
    uint public deposit_fairPriceLow;
    bool public checkFairPriceDeposit;
    bool public checkFairPriceWithdraw;

    uint public liquidity_ratio_limit; //1e8

    event Deposit_BUSD(address user, uint256 busd_amount, uint256 lp_amount);
    event Withdraw(address user, uint256 amount);
    event Harvest(address user, uint256 amount);
    event Set_Token_Addresses(address WJAX, address BUSD);
    event Set_RewardToken(address rewardToken);
    event Set_Fair_Price_Range(uint high, uint low);
    event Set_Liquidity_Ratio_Limit(uint limit);
    event Set_Fair_Price(bool fairPrice);
    event Set_Check_Fair_Price_Deposit(bool flag);
    event Set_Check_Fair_Price_Withdraw(bool flag);
    event Set_Price_Impact_Limit(uint limit);
    event Deposit_Reward(uint amount);
    

    function initialize (address admin_address, address _router, address _BUSD, address _WJAX) external initializer {
        jaxAdmin = IJaxAdmin(admin_address);
        router = IPancakeRouter01(_router);
        BUSD = _BUSD;
        WJAX = _WJAX;
        IERC20(BUSD).approve(address(router), type(uint256).max);
        IERC20(WJAX).approve(address(router), type(uint256).max);

        address lpToken = IPancakeFactory(router.factory()).getPair(WJAX, BUSD);
        IERC20(lpToken).approve(address(router), type(uint256).max);

        EpochInfo memory firstEpoch;
        epochInfo.push(firstEpoch);
        currentEpoch = 1;
        lastEpochBlock = block.number;

        owner = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner, "Only Admin can perform this operation.");
        _;
    }

    modifier onlyGovernor() {
        require(jaxAdmin.userIsGovernor(msg.sender), "Only Governor can perform this operation.");
        _;
    }
    
    modifier onlyOperator() {
        require(jaxAdmin.userIsOperator(msg.sender) || jaxAdmin.userIsGovernor(msg.sender), "Only Operator can perform this operation.");
        _;
    }
    
    function set_token_addresses(address _WJAX, address _BUSD) external onlyAdmin {
        WJAX = _WJAX;
        BUSD = _BUSD;
        address lpToken = IPancakeFactory(router.factory()).getPair(_WJAX, _BUSD);
        IERC20(lpToken).approve(address(router), type(uint256).max);
        emit Set_Token_Addresses(_WJAX, _BUSD);
    }

    function set_reward_token(address _rewardToken) external onlyAdmin {
        rewardToken = _rewardToken;
        emit Set_RewardToken(_rewardToken);
    }

    function set_deposit_fair_price_range(uint high, uint low) external onlyGovernor {
        deposit_fairPriceHigh = high;
        deposit_fairPriceLow = low;
        emit Set_Fair_Price_Range(high, low);
    }

    function set_withdraw_fair_price_range(uint high, uint low) external onlyGovernor {
        withdraw_fairPriceHigh = high;
        withdraw_fairPriceLow = low;
        emit Set_Fair_Price_Range(high, low);
    }
 
    function set_check_fair_price_deposit(bool flag) external onlyGovernor {
        checkFairPriceDeposit = flag;
        emit Set_Check_Fair_Price_Deposit(flag);
    }

    function set_check_fair_price_withdraw(bool flag) external onlyGovernor {
        checkFairPriceWithdraw = flag;
        emit Set_Check_Fair_Price_Withdraw(flag);
    }

    function getPrice(address token0, address token1) public view returns(uint) {
        address pairAddress = IPancakeFactory(router.factory()).getPair(token0, token1);
        (uint res0, uint res1,) = IPancakePair(pairAddress).getReserves();
        res0 *= 10 ** (18 - IERC20(IPancakePair(pairAddress).token0()).decimals());
        res1 *= 10 ** (18 - IERC20(IPancakePair(pairAddress).token1()).decimals());
        if(IPancakePair(pairAddress).token0() == token1) {
            if(res1 > 0)
                return 1e8 * res0 / res1;
        } 
        else {
            if(res0 > 0)
                return 1e8 * res1 / res0;
        }
        return 0;
    }

    function depositBUSD(uint amount) external {
        updateReward(msg.sender);

        IERC20(BUSD).transferFrom(msg.sender, address(this), amount);
        // uint amount_liqudity = amount * 1e8 / liquidity_ratio;
        uint amount_to_buy_wjax = amount / 2;
        uint amountBusdDesired = amount - amount_to_buy_wjax;

        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = WJAX;

        uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), amount_to_buy_wjax, jaxAdmin.priceImpactLimit(), path, address(this));
        if(checkFairPriceDeposit){
            uint price = getPrice(WJAX, BUSD);
            require(price <= deposit_fairPriceHigh && price >= deposit_fairPriceLow, "out of fair price range");
        }

        uint wjax_amount = amounts[1];

        (uint busd_liquidity, uint wjax_liquidity, uint liquidity) = 
            router.addLiquidity( BUSD, WJAX, amountBusdDesired, wjax_amount, 0, 0,
                            address(this), block.timestamp);

        path[0] = WJAX;
        path[1] = BUSD;
        amounts[1] = 0;
        if(wjax_amount - wjax_liquidity > 0)
            amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), wjax_amount - wjax_liquidity, jaxAdmin.priceImpactLimit(), path, msg.sender);
        if(amountBusdDesired - busd_liquidity > 0)
            IERC20(BUSD).transfer(msg.sender, amountBusdDesired - busd_liquidity);

        UserInfo storage user = userInfo[msg.sender];
        uint busd_staked = amount - amounts[1];
        user.shareMinus += liquidity * (block.number - lastEpochBlock);
        epochShareMinus += liquidity * (block.number - lastEpochBlock);
        user.amount += liquidity;
        totalAmount += liquidity;
        user.busdStaked += busd_staked;
        totalBusdStaked += busd_staked;
        // emit Deposit_BUSD(msg.sender, busd_staked, liquidity);
    }

    function withdraw() external {
        _harvest();
        uint amount = userInfo[msg.sender].amount;
        
        if( amount == 0){
            return;
        }
        (uint amountBUSD, uint amountWJAX) = router.removeLiquidity(BUSD, WJAX, amount,
            0, 0, address(this), block.timestamp
        );
        
        require(get_liquidity_ratio() >= liquidity_ratio_limit, "liquidity ratio is too low");
        
        address[] memory path = new address[](2);
        path[0] = WJAX;
        path[1] = BUSD;

        uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), amountWJAX, jaxAdmin.priceImpactLimit(), path, address(this));
        
        if(checkFairPriceWithdraw){
            uint price = getPrice(WJAX, BUSD);
            require(price <= withdraw_fairPriceHigh && price >= withdraw_fairPriceLow, "out of fair price range");
        }
        amountBUSD = amountBUSD.add(amounts[1]);

        IERC20(BUSD).transfer(address(msg.sender), amountBUSD);

        UserInfo storage user = userInfo[msg.sender];
        user.sharePlus += amount * (block.number - lastEpochBlock);
        epochSharePlus += amount * (block.number - lastEpochBlock);

        totalAmount -= user.amount;
        user.amount = 0;

        totalBusdStaked -= user.busdStaked;
        user.busdStaked = 0;

        emit Withdraw(msg.sender, amountBUSD);
    }

    function get_liquidity_ratio() public view returns(uint) { //1e8
        address pairAddress = IPancakeFactory(router.factory()).getPair(BUSD, WJAX);
        (uint res0, uint res1,) = IPancakePair(pairAddress).getReserves();
        uint wjax_supply = IERC20(WJAX).totalSupply();
        uint busd_liquidity;
        uint wjax_supply_in_busd;
        if(IPancakePair(pairAddress).token0() == BUSD) {
            busd_liquidity = res0;
            wjax_supply_in_busd = wjax_supply * res0 / res1;
        } 
        else {
            busd_liquidity = res1;
            wjax_supply_in_busd = wjax_supply * res1 / res0;
        }
        return busd_liquidity * 1e8 / wjax_supply_in_busd;
    }

    function set_liquidity_ratio_limit(uint _liquidity_ratio_limit) external onlyGovernor {
        liquidity_ratio_limit = _liquidity_ratio_limit;
        emit Set_Liquidity_Ratio_Limit(liquidity_ratio_limit);
    }

    function deposit_reward(uint amount) external {
        require(IJaxAdmin(jaxAdmin).userIsGovernor(tx.origin), "tx.origin should be governor");
        uint epochShare = (block.number - lastEpochBlock) * totalAmount + epochSharePlus - epochShareMinus;
        uint rewardPerShare;
        if(epochShare > 0) {
            rewardPerShare = amount * 1e36 / epochShare; // multiplied by 1e36
            IERC20(rewardToken).transferFrom(msg.sender, address(this), rewardPerShare * epochShare / 1e36);
        }
        EpochInfo memory newEpoch;
        newEpoch.reward = amount;
        newEpoch.blockCount = block.number - lastEpochBlock;
        newEpoch.rewardPerShare = rewardPerShare;
        newEpoch.totalRewardPerBalance = epochInfo[currentEpoch-1].totalRewardPerBalance + rewardPerShare * (block.number - lastEpochBlock);
        epochInfo.push(newEpoch);
        lastEpochBlock = block.number;
        epochShare = 0;
        epochSharePlus = 0;
        epochShareMinus = 0;
        currentEpoch += 1;
        totalReward += amount;
        emit Deposit_Reward(amount);
    }

    function updateReward(address account) internal {
        UserInfo storage user = userInfo[account];
        if(user.currentEpoch == currentEpoch) return;
        if(user.currentEpoch == 0) {
            user.currentEpoch = currentEpoch;
            return;
        }
        uint balance = user.amount;
        EpochInfo storage epoch = epochInfo[user.currentEpoch];
        uint newReward = (balance * epoch.blockCount + user.sharePlus - user.shareMinus) * epoch.rewardPerShare;
        newReward += balance * (epochInfo[currentEpoch-1].totalRewardPerBalance - 
                            epochInfo[user.currentEpoch].totalRewardPerBalance);
        user.totalReward += newReward;
        user.sharePlus = 0;
        user.shareMinus = 0;
        user.currentEpoch = currentEpoch;
    }

    function harvest() external {
        uint reward = _harvest();
        require(reward > 0, "Nothing to harvest");
    }

    function _harvest() internal returns (uint reward) {
        updateReward(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        reward = (user.totalReward - user.rewardPaid)/1e36;
        IERC20(rewardToken).transfer(msg.sender, reward);
        user.rewardPaid = user.totalReward;
        emit Harvest(msg.sender, reward);
    }

    function withdrawByAdmin(address token, uint amount) external onlyAdmin {
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ref/PancakeRouter.sol";
import "./lib/Initializable.sol";
import "./JaxLibrary.sol";
import "./JaxOwnable.sol";

interface IJaxSwap {
  event Set_Jax_Admin(address jax_admin);
  event Set_Token_Addresses(address wjxn, address wjax, address vrp, address jusd);
  event Swap_Wjxn_Wjax(uint amount);
  event Swap_Wjax_Wjxn(uint amount);
  event Swap_WJXN_VRP(address account, uint wjxn_amount, uint vrp_amount);
  event Swap_WJAX_JUSD(address account, uint amountIn, uint amountOut);
  event Swap_VRP_WJXN(address account, uint vrp_amount, uint wjxn_amount);
  event Swap_JUSD_WJAX(address account, uint amountIn, uint amountOut);
  event Swap_JToken_JUSD(address jtoken, address account, uint amountIn, uint amountOut);
  event Swap_JUSD_JToken(address jtoken, address account, uint amountIn, uint amountOut);
  event Swap_JToken_BUSD(address jtoken, address account, uint amountIn, uint amountOut);
  event Swap_BUSD_JToken(address jtoken, address account, uint amountIn, uint amountOut);
}

interface IJaxAdmin {

  struct JToken{
    uint jusd_ratio;
    uint markup_fee;
    address markup_fee_wallet;
    string name;
  }

  function userIsAdmin (address _user) external view returns (bool);
  function userIsGovernor (address _user) external view returns (bool);
  function userIsAjaxPrime (address _user) external view returns (bool);
  function system_status () external view returns (uint);

  function priceImpactLimit() external view returns (uint);

  function show_reserves() external view returns(uint, uint, uint);
  function get_wjxn_wjax_ratio(uint withdrawal_amount) external view returns (uint);
  function wjax_usd_ratio() external view returns (uint);
  function get_wjxn_vrp_ratio() external view returns (uint);
  function get_vrp_wjxn_ratio() external view returns (uint);
  function use_wjax_usd_dex_pair() external view returns (uint);
  function wjxn_usd_ratio() external view returns (uint);
  function use_wjxn_usd_dex_pair() external view returns (uint);
  function wjxn_wjax_collateralization_ratio() external view returns (uint);
  function wjax_collateralization_ratio() external view returns (uint);
  function get_wjax_jusd_ratio() external view returns (uint);
  function freeze_vrp_wjxn_swap() external view returns (uint);
  function jtokens(address jtoken_address) external view returns (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, string memory name);
  
  function wjax_jusd_markup_fee() external view returns (uint);
  function wjax_jusd_markup_fee_wallet() external view returns (address);
  function blacklist(address _user) external view returns (bool);
}

contract JaxSwap is IJaxSwap, Initializable, JaxOwnable {
  
  /// @custom:oz-upgrades-unsafe-allow constructor
  using JaxLibrary for JaxSwap;

  IJaxAdmin public jaxAdmin;
  IPancakeRouter01 router;

  IERC20 public wjxn;
  IERC20 public busd;
  IERC20 public wjax;
  IERC20 public vrp; 
  IERC20 public jusd;

  mapping (address => uint) public wjxn_wjax_ratios;

  modifier onlyAdmin() {
    require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner, "Not_Admin"); //Only Admin can perform this operation.
    _;
  }

  modifier onlyGovernor() {
    require(jaxAdmin.userIsGovernor(msg.sender), "Not_Governor"); //Only Governor can perform this operation.
    _;
  }

  modifier isActive() {
      require(jaxAdmin.system_status() == 2, "Swap_Paused"); //Swap has been paused by Admin.
      _;
  }

  modifier notContract() {
    uint256 size;
    address addr = msg.sender;
    assembly {
        size := extcodesize(addr)
    }
    require((size == 0) && (msg.sender == tx.origin),
          "Contract_Call_Not_Allowed"); //Only non-contract/eoa can perform this operation
    _;
  }

  function setJaxAdmin(address newJaxAdmin) external onlyAdmin {
    jaxAdmin = IJaxAdmin(newJaxAdmin);
    jaxAdmin.system_status();
    emit Set_Jax_Admin(newJaxAdmin);
  }

  function setTokenAddresses(address _busd, address _wjxn, address _wjax, address _vrp, address _jusd) external {
    require(msg.sender == address(jaxAdmin), "Only JaxAdmin Contract");
    busd = IERC20(_busd);
    busd.approve(address(router), type(uint).max);
    wjxn = IERC20(_wjxn);
    wjax = IERC20(_wjax);
    vrp = IERC20(_vrp);
    jusd = IERC20(_jusd);
    wjxn.approve(address(router), type(uint).max);
    wjax.approve(address(router), type(uint).max);
    emit Set_Token_Addresses(_wjxn, _wjax, _vrp, _jusd);
  }

  function swap_wjxn_wjax(uint amount) external onlyGovernor {
    address[] memory path = new address[](2);
    path[0] = address(wjxn);
    path[1] = address(wjax);
    JaxLibrary.swapWithPriceImpactLimit(address(router), amount, jaxAdmin.priceImpactLimit(), path, address(this));
    
    (uint wjax_lsc_ratio, ,) = jaxAdmin.show_reserves();

    require(wjax_lsc_ratio <= jaxAdmin.wjax_collateralization_ratio() * 110 / 100, "Unable to swap as collateral is fine"); //Unable to withdraw as collateral is fine.
    emit Swap_Wjxn_Wjax(amount);
  }

  function swap_wjax_wjxn(uint amount) external onlyGovernor {
    // require(validate_wjax_withdrawal(_amount) == true, "validate_wjax_withdrawal failed");

    address[] memory path = new address[](2);
    path[0] = address(wjax);
    path[1] = address(wjxn);
    JaxLibrary.swapWithPriceImpactLimit(address(router), amount, jaxAdmin.priceImpactLimit(), path, address(this));
    
    (uint wjax_lsc_ratio, ,) = jaxAdmin.show_reserves();

    require(wjax_lsc_ratio >= jaxAdmin.wjax_collateralization_ratio(), "Low Reserves");

    emit Swap_Wjax_Wjxn(amount);
  }

  function swap_wjxn_vrp(uint amountIn) external isActive returns (uint) {
    require(amountIn > 0, "Zero AmountIn"); //WJXN amount must not be zero.
    require(!jaxAdmin.blacklist(msg.sender), "blacklisted");
    require(wjxn.balanceOf(msg.sender) >= amountIn, "Insufficient WJXN");

    // Set wjxn_wjax_ratio of sender 
    uint wjxn_wjax_ratio_now = jaxAdmin.get_wjxn_wjax_ratio(0);
    uint wjxn_wjax_ratio_old = wjxn_wjax_ratios[msg.sender];
    if(wjxn_wjax_ratio_old < wjxn_wjax_ratio_now)
        wjxn_wjax_ratios[msg.sender] = wjxn_wjax_ratio_now;

    uint vrp_to_be_minted = amountIn * jaxAdmin.get_wjxn_vrp_ratio() * (10 ** vrp.decimals()) / (10 ** wjxn.decimals()) / 1e8;
    wjxn.transferFrom(msg.sender, address(this), amountIn);
    vrp.mint(msg.sender, vrp_to_be_minted);
    emit Swap_WJXN_VRP(msg.sender, amountIn, vrp_to_be_minted);
    return vrp_to_be_minted;
  }

  function swap_vrp_wjxn(uint amountIn) external isActive returns (uint) {
    require(jaxAdmin.freeze_vrp_wjxn_swap() == 0, "Freeze VRP-WJXN Swap"); //VRP-WJXN exchange is not allowed now.
    require(!jaxAdmin.blacklist(msg.sender), "blacklisted");
    require(amountIn > 0, "Zero AmountIn");
    require(vrp.balanceOf(msg.sender) >= amountIn, "Insufficient VRP");
    require(wjxn.balanceOf(address(this))> 0, "No Reserves.");
    uint wjxn_to_be_withdrawn = amountIn * (10 ** wjxn.decimals()) * jaxAdmin.get_vrp_wjxn_ratio() / (10 ** vrp.decimals()) / 1e8;
    require(wjxn_to_be_withdrawn >= 1, "Min Amount for withdrawal is 1 WJXN."); 
    require(wjxn.balanceOf(address(this))>= wjxn_to_be_withdrawn, "Insufficient WJXN");

    // check wjxn_wjax_ratio of sender 
    uint wjxn_wjax_ratio_now = jaxAdmin.get_wjxn_wjax_ratio(wjxn_to_be_withdrawn);

    require(wjxn_wjax_ratio_now >= jaxAdmin.wjxn_wjax_collateralization_ratio(), "Low Reserves"); //Unable to withdraw as reserves are low.
    // require(wjxn_wjax_ratios[msg.sender] >= wjxn_wjax_ratio_now, "Unable to withdraw as reserves are low.");

    vrp.burnFrom(msg.sender, amountIn);
    wjxn.transfer(msg.sender, wjxn_to_be_withdrawn);
    emit Swap_VRP_WJXN(msg.sender, amountIn, wjxn_to_be_withdrawn);
    return wjxn_to_be_withdrawn;
  }

  function swap_wjax_jusd(uint amountIn) external isActive{
    // Calculate fee
    uint fee_amount = amountIn * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    // markup fee wallet will receive fee
		require(wjax.balanceOf(msg.sender) >= amountIn, "Insufficient WJAX");
    // pay fee
    wjax.transferFrom(msg.sender, jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    wjax.transferFrom(msg.sender, address(this), amountIn - fee_amount);

    uint jusd_amount = (amountIn - fee_amount) * jaxAdmin.get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / (10 ** wjax.decimals()) / 1e8;

    jusd.mint(msg.sender, jusd_amount);
		emit Swap_WJAX_JUSD(msg.sender, amountIn, jusd_amount);
	}

  function swap_jusd_wjax(uint jusd_amount) external isActive returns (uint) {
		require(jusd.balanceOf(msg.sender) >= jusd_amount, "Insufficient jusd");
    uint fee_amount = jusd_amount * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    uint wjax_amount = (jusd_amount - fee_amount) * 1e8 * (10 ** wjax.decimals()) / jaxAdmin.get_wjax_jusd_ratio() / (10 ** jusd.decimals());
		require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient reserves");
    jusd.burnFrom(msg.sender, jusd_amount);
    jusd.mint(jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    // The recipient has to pay fee.
    wjax.transfer(msg.sender, wjax_amount);

		emit Swap_JUSD_WJAX(msg.sender, jusd_amount, wjax_amount);
    return wjax_amount;
	}

  function swap_jusd_jtoken(address jtoken, uint amountIn) external isActive returns (uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    uint ratio = jusd_ratio;
    require(ratio > 0, "Zero Ratio"); //ratio is not set for this token
    uint256 jtoken_amount = amountIn * ratio / 1e8;
    // Calculate Fee on receiver side
    uint256 jtoken_markup_fee = jtoken_amount * markup_fee / 1e8;
    require(jusd.balanceOf(msg.sender) >= amountIn, "Insufficient JUSD");
    jusd.burnFrom(msg.sender, amountIn);
    // The recipient has to pay fee. 
    uint amountOut = jtoken_amount-jtoken_markup_fee;
    IERC20(jtoken).mint(markup_fee_wallet, jtoken_markup_fee);
    IERC20(jtoken).mint(msg.sender, amountOut);
    emit Swap_JUSD_JToken(jtoken, msg.sender, amountIn, amountOut);
    return amountOut;
  }

  function swap_jtoken_jusd(address jtoken, uint amountIn) external isActive returns (uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    uint ratio = jusd_ratio;
    require(ratio > 0, "Zero Ratio"); //ratio is not set for this token
    uint jusd_amountOut = amountIn * 1e8 / ratio;
    uint jusd_markup_fee = jusd_amountOut * markup_fee / 1e8;
    require(IERC20(jtoken).balanceOf(msg.sender) >= amountIn, "Insufficient JTOKEN");
    IERC20(jtoken).burnFrom(msg.sender, amountIn);
    // The recipient has to pay fee. 
    uint amountOut = jusd_amountOut - jusd_markup_fee;
    jusd.mint(markup_fee_wallet, jusd_markup_fee);
    jusd.mint(msg.sender, amountOut);
    emit Swap_JToken_JUSD(jtoken, msg.sender, amountIn, amountOut);
    return amountOut;
  }

  function swap_jtoken_busd(address jtoken, uint amountIn) external isActive returns (uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    require(jusd_ratio > 0, "Zero Ratio"); //ratio is not set for this token
    uint jusd_amountOut = amountIn * 1e8 / jusd_ratio;
    uint jusd_markup_fee = jusd_amountOut * markup_fee / 1e8;
    require(IERC20(jtoken).balanceOf(msg.sender) >= amountIn, "Insufficient Jtoken");
    IERC20(jtoken).burnFrom(msg.sender, amountIn);
    // The recipient has to pay fee. 
    // uint jusd_amount = jusd_amountOut-jusd_markup_fee;
    jusd.mint(markup_fee_wallet, jusd_markup_fee);
    // jusd.mint(msg.sender, amountOut);

       
    uint fee_amount = (jusd_amountOut - jusd_markup_fee) * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    uint wjax_amount = (jusd_amountOut - jusd_markup_fee - fee_amount) * (10 ** wjax.decimals()) * 1e8 / (10 ** jusd.decimals()) / jaxAdmin.get_wjax_jusd_ratio();
		require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient reserves");
    // jusd.burnFrom(msg.sender, jusd_amount);
    jusd.mint(jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    // The recipient has to pay fee.
    // wjax.transfer(msg.sender, wjax_amount);

    address[] memory path = new address[](2);
    path[0] = address(wjax);
    path[1] = address(busd);

    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), wjax_amount, jaxAdmin.priceImpactLimit(), path, msg.sender);
    
		emit Swap_JToken_BUSD(jtoken, msg.sender, amountIn, amounts[1]);
    return amounts[1];
  }

  function swap_busd_jtoken(address jtoken, uint amountIn) external isActive returns(uint) {
    (uint jusd_ratio, uint markup_fee, address markup_fee_wallet, ) = jaxAdmin.jtokens(jtoken);
    require(jusd_ratio > 0, "Invalid JUSD-Ratio");
    require(busd.balanceOf(msg.sender)>=amountIn, "Insufficient BUSD");
    busd.transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(busd);
    path[1] = address(wjax);
    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), amountIn, jaxAdmin.priceImpactLimit(), path, address(this));
    // Calculate fee
    uint wjax_fee = amounts[1] * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    // markup fee wallet will receive fee
    // pay fee
    uint wjax_amountOut = amounts[1] - wjax_fee;
    wjax.transfer(jaxAdmin.wjax_jusd_markup_fee_wallet(), wjax_fee);
    // wjax.transferFrom(msg.sender, address(this), wjax_amountOut);

    uint jusd_amount = wjax_amountOut * jaxAdmin.get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / (10 ** wjax.decimals()) / 1e8;

    // jusd.mint(msg.sender, jusd_amount);

    uint jtoken_amount = jusd_amount * jusd_ratio / 1e8;
    // Calculate Fee on receiver side
    uint jtoken_markup_fee = jtoken_amount * markup_fee / 1e8;
    // jusd.burnFrom(msg.sender, jusd_amount);
    // The recipient has to pay fee. 
    uint amountOut = jtoken_amount-jtoken_markup_fee;
    IERC20(jtoken).mint(markup_fee_wallet, jtoken_markup_fee);
    IERC20(jtoken).mint(msg.sender, amountOut);

		emit Swap_BUSD_JToken(jtoken, msg.sender, amountIn, amountOut);
    return amountOut;
	}

  function swap_jusd_busd(uint amountIn) external isActive returns (uint) {
    uint fee_amount = amountIn * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    uint wjax_amount = (amountIn - fee_amount) * 1e8 * (10 ** wjax.decimals()) / jaxAdmin.get_wjax_jusd_ratio() / (10 ** jusd.decimals());
    
    require(wjax.balanceOf(address(this)) >= wjax_amount, "Insufficient WJAX fund");
    require(jusd.balanceOf(msg.sender) >= amountIn, "Insufficient JUSD");

    jusd.burnFrom(msg.sender, amountIn);
    jusd.mint(jaxAdmin.wjax_jusd_markup_fee_wallet(), fee_amount);
    // The recipient has to pay fee.
    // wjax.transfer(msg.sender, wjax_amount);

    address[] memory path = new address[](2);
    path[0] = address(wjax);
    path[1] = address(busd);

    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), wjax_amount, jaxAdmin.priceImpactLimit(), path, msg.sender);
    return amounts[1];
  } 
  
  function swap_busd_jusd(uint amountIn) external isActive{
		require(busd.balanceOf(msg.sender) >= amountIn, "Insufficient Busd fund");
    busd.transferFrom(msg.sender, address(this), amountIn);
    address[] memory path = new address[](2);
    path[0] = address(busd);
    path[1] = address(wjax);
    uint[] memory amounts = JaxLibrary.swapWithPriceImpactLimit(address(router), amountIn, jaxAdmin.priceImpactLimit(), path, address(this));
    // Calculate fee
    uint wjax_fee = amounts[1] * jaxAdmin.wjax_jusd_markup_fee() / 1e8;
    // markup fee wallet will receive fee
    // pay fee
    wjax.transfer(jaxAdmin.wjax_jusd_markup_fee_wallet(), wjax_fee);
    // wjax.transferFrom(msg.sender, address(this), amounts[1] - wjax_fee);

    uint jusd_amount = (amounts[1] - wjax_fee) * jaxAdmin.get_wjax_jusd_ratio() * (10 ** jusd.decimals()) / (10 ** wjax.decimals()) / 1e8;

    jusd.mint(msg.sender, jusd_amount);
		emit Swap_WJAX_JUSD(msg.sender, amountIn, jusd_amount);
	}

  function initialize(address _jaxAdmin, address pancakeRouter) external initializer {

    // wjax_jusd_markup_fee_wallet = msg.sender;

    router = IPancakeRouter01(pancakeRouter);
    jaxAdmin = IJaxAdmin(_jaxAdmin);

    owner = msg.sender;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./lib/BEP20.sol";
import "./JaxAdmin.sol";
import "./lib/Initializable.sol";

interface IJaxPlanet {

  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  function ubi_tax_wallet() external view returns (address);
  function ubi_tax() external view returns (uint);
  function jaxcorp_dao_wallet() external view returns (address);
  function getMotherColonyAddress(address) external view returns(address);
  function getColony(address addr) external view returns(Colony memory);
  function getUserColonyAddress(address user) external view returns(address);
}

/**
* @title JaxToken
* @dev Implementation of the JaxToken. Extension of {BEP20} that adds a fee transaction behaviour.
*/
contract JaxToken is BEP20 {
  
  IJaxAdmin public jaxAdmin;

  // transaction fee
  uint public transaction_fee = 0;
  uint public transaction_fee_cap = 0;

  // transaction fee wallet
  uint public referral_fee = 0;
  uint public referrer_amount_threshold = 0;
  uint public cashback = 0; //1e8
  // transaction fee decimal 
  // uint public constant _fee_decimal = 8;

  enum Status { InActive, Active }

  Status public active_status = Status.Active;
  
  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  address public tx_fee_wallet;
  
  mapping (address => address) public referrers;

  event Set_Jax_Admin(address jax_admin);
  event Set_Active_Status(Status status);
  event Set_Transaction_Fee(uint transaction_fee, uint trasnaction_fee_cap, address transaction_fee_wallet);
  event Set_Referral_Fee(uint referral_fee, uint referral_amount_threshold);
  event Set_Cashback(uint cashback_percent);

  /**
    * @dev Sets the value of the `cap`. This value is immutable, it can only be
    * set once during construction.
    */
    
  constructor (
      string memory name,
      string memory symbol,
      uint8 decimals
  )
      BEP20(name, symbol)
      payable
  {
      _setupDecimals(decimals);
      tx_fee_wallet = msg.sender;
  }

  modifier onlyJaxAdmin() {
    require(msg.sender == address(jaxAdmin), "Only JaxAdmin Contract");
    _;
  }

  modifier onlyAdmin() {
    require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner(), "Only JaxAdmin Contract");
    _;
  }

  modifier onlyJaxSwap() {
  require(msg.sender == jaxAdmin.jaxSwap(), "Only JaxSwap can perform this operation.");
    _;
  }

  
  modifier notFrozen() {
    require(active_status == Status.Active, "Transfers have been frozen.");
    _;
  }

  function setJaxAdmin(address _jaxAdmin) external onlyOwner {
    jaxAdmin = IJaxAdmin(_jaxAdmin);  
    emit Set_Jax_Admin(_jaxAdmin);
  }

  function set_active_status(Status status) external onlyAdmin { 
    active_status = status;
    emit Set_Active_Status(status);
  }

  function setTransactionFee(uint tx_fee, uint tx_fee_cap, address wallet) external onlyJaxAdmin {
      require(tx_fee <= 1e8 * 3 / 100 , "Tx Fee percent can't be more than 3.");
      transaction_fee = tx_fee;
      transaction_fee_cap = tx_fee_cap;
      tx_fee_wallet = wallet;
      emit Set_Transaction_Fee(tx_fee, tx_fee_cap, wallet);
  }

  /**
    * @dev Set referral fee and minimum amount that can set sender as referrer
    */
  function setReferralFee(uint _referral_fee, uint _referrer_amount_threshold) external onlyJaxAdmin {
      require(referral_fee <= 1e8 * 50 / 100 , "Referral Fee percent can't be more than 50.");
      referral_fee = _referral_fee;
      referrer_amount_threshold = _referrer_amount_threshold;
      emit Set_Referral_Fee(_referral_fee, _referrer_amount_threshold);
  }

  /**
    * @dev Set cashback
    */
  function setCashback(uint cashback_percent) external onlyJaxAdmin {
      require(cashback_percent <= 1e8 * 30 / 100 , "Cashback percent can't be more than 30.");
      cashback = cashback_percent; //1e8
      emit Set_Cashback(cashback_percent);
  }

  function transfer(address recipient, uint amount) public override(BEP20) notFrozen returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  } 

  function transferFrom(address sender, address recipient, uint amount) public override(BEP20) notFrozen returns (bool) {
    _transfer(sender, recipient, amount);
    uint currentAllowance = allowance(sender, msg.sender);
    require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
    _approve(sender, msg.sender, currentAllowance - amount);
    return true;
  } 

  function _transfer(address sender, address recipient, uint amount) internal override(BEP20) {
    require(!jaxAdmin.blacklist(sender), "sender is blacklisted");
    require(!jaxAdmin.blacklist(recipient), "recipient is blacklisted");
    if(amount == 0) return;
    if(jaxAdmin.fee_blacklist(msg.sender) == true || jaxAdmin.fee_blacklist(recipient) == true) {
        return super._transfer(sender, recipient, amount);
    }
    if(referrers[sender] == address(0)) {
        referrers[sender] = address(0xdEaD);
    }

    // Calculate transaction fee
    uint tx_fee_amount = amount * transaction_fee / 1e8;

    if(tx_fee_amount > transaction_fee_cap) {
        tx_fee_amount = transaction_fee_cap;
    }
    
    address referrer = referrers[recipient];
    uint totalreferral_fees = 0;
    uint maxreferral_fee = tx_fee_amount * referral_fee;
    // Transfer referral fees to referrers (70% to first referrer, each 10% to other referrers)
    if( maxreferral_fee > 0 && referrer != address(0xdEaD) && referrer != address(0)){

        super._transfer(sender, referrer, 70 * maxreferral_fee / 1e8 / 100);
        referrer = referrers[referrer];
        totalreferral_fees += 70 * maxreferral_fee / 1e8 / 100;
        if( referrer != address(0xdEaD) && referrer != address(0)){
            super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
            referrer = referrers[referrer];
            totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
            if( referrer != address(0xdEaD) && referrer != address(0)){
                super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                referrer = referrers[referrer];
                totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                if( referrer != address(0xdEaD) && referrer != address(0)){
                    super._transfer(sender, referrer, 10 * maxreferral_fee / 1e8 / 100);
                    referrer = referrers[referrer];
                    totalreferral_fees += 10 * maxreferral_fee / 1e8 / 100;
                }
            }
        }
    }

    // Transfer transaction fee to transaction fee wallet
    // Sender will get cashback.
    if( tx_fee_amount > 0){
        super._transfer(sender, tx_fee_wallet, tx_fee_amount - totalreferral_fees - (tx_fee_amount * cashback / 1e8)); //1e8
    }

    IJaxPlanet jaxPlanet = IJaxPlanet(jaxAdmin.jaxPlanet());
    
    //Transfer of UBI Tax        
    uint ubi_tax_amount = amount * jaxPlanet.ubi_tax() / 1e8;
    if(ubi_tax_amount > 0){
        super._transfer(sender, jaxPlanet.ubi_tax_wallet(), ubi_tax_amount);  // ubi tax
    }

    address colony_address = jaxPlanet.getUserColonyAddress(recipient);

    if(colony_address == address(0)) {
        colony_address = jaxPlanet.getMotherColonyAddress(recipient);
    }

    // Transfer transaction tax to colonies.
    // immediate colony will get 50% of transaction tax, mother of that colony will get 25% ... mother of 4th colony will get 3.125%
    // 3.125% of transaction tax will go to JaxCorp Dao public key address.
    uint tx_tax_amount = amount * jaxPlanet.getColony(colony_address).transaction_tax / 1e8;     // Calculate transaction tax amount
    
    // transferTransactionTax(mother_colony_addresses[recipient], tx_tax_amount, 1);          // Transfer tax to colonies and jaxCorp Dao
    // Optimize transferTransactionTax by using loop instead of recursive function

    if( tx_tax_amount > 0 ){
        uint level = 1;
        uint tx_tax_temp = tx_tax_amount;
        
        // Level is limited to 5
        while( colony_address != address(0) && level++ <= 5 ){
            super._transfer(sender, colony_address, tx_tax_temp / 2);
            colony_address = jaxPlanet.getMotherColonyAddress(colony_address);
            tx_tax_temp = tx_tax_temp / 2;            
        }

        // transfer remain tx_tax to jaxcorpDao
        super._transfer(sender, jaxPlanet.jaxcorp_dao_wallet(), tx_tax_temp);
    }

    // Transfer tokens to recipient. recipient will pay the fees.
    require( amount > (tx_fee_amount + ubi_tax_amount + tx_tax_amount), "Total fee is greater than the transfer amount");
    super._transfer(sender, recipient, amount - tx_fee_amount - ubi_tax_amount - tx_tax_amount);

    // set referrers as first sender when transferred amount exceeds the certain limit.
    // recipient mustn't be sender's referrer, recipient couldn't be referrer itself
    if( recipient != sender  && amount >= referrer_amount_threshold  && referrers[recipient] == address(0)) {
        referrers[recipient] = sender;

    }
  }

  function _mint(address account, uint amount) internal override(BEP20) notFrozen onlyJaxSwap {
      require(!jaxAdmin.blacklist(account), "account is blacklisted");
      super._mint(account, amount);
  }

  function _burn(address account, uint amount) internal override(BEP20) notFrozen onlyJaxSwap {
    require(!jaxAdmin.blacklist(account), "account is blacklisted");
    super._burn(account, amount);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../IJaxAdmin.sol";
import "../lib/Initializable.sol";
import "./IERC20.sol";
import "../JaxOwnable.sol";

interface IVRP {
    enum Action { Mint, Burn }
    enum Status { InActive, Active }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Set_Jax_Admin(address jaxAdmin);
    event Vote_Governor(address voter, address candidate);
    event Init_Average_Balance();
    event Update_Vote_Share(address voter, address candidate, uint voteShare);
    event Set_Reward_Token(address rewardToken);
    event Harvest(address account, uint amount);
    event Deposit_Reward(uint amount);
}

/**
 * @title WJAX
 * @dev Implementation of the WJAX
 */
//, Initializable
contract VRP is IVRP, Initializable, JaxOwnable {
    
    address public jaxAdmin;

    address public rewardToken;

    mapping (address => uint256) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    // blacklisted addressed can not send, receive tokens and tokens cannot be minted to this address.

    struct EpochInfo {
        uint blockCount;
        uint rewardPerShare;
        uint totalRewardPerBalance;
    }

    EpochInfo[] public epochInfo;

    uint currentEpoch;
    uint lastEpochBlock;
    
    uint epochSharePlus;
    uint epochShareMinus;

    struct UserInfo {
        uint currentEpoch;
        uint sharePlus;
        uint shareMinus;
        uint rewardPaid;
        uint totalReward;
    }

    mapping(address => UserInfo) userInfo;

    // Voting States
    mapping (address => uint)  public voteShare;
    mapping (address => address) public vote;
    uint public voterCount;

    function initialize (address _jaxAdmin) public initializer {
        _name = "Volatility Reserves Pool";
        _symbol = "VRP";
        _decimals = 18;
        jaxAdmin = _jaxAdmin;
        EpochInfo memory firstEpoch;
        epochInfo.push(firstEpoch);
        currentEpoch = 1;
        lastEpochBlock = block.number;
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(IJaxAdmin(jaxAdmin).userIsAdmin(msg.sender) || msg.sender == owner, "Only Admin can perform this operation.");
        _;
    }

    modifier onlyGovernor() {
        require(IJaxAdmin(jaxAdmin).userIsGovernor(msg.sender), "Only Governor can perform this operation.");
        _;
    }

    modifier onlyJaxSwap() {
        require(msg.sender == IJaxAdmin(jaxAdmin).jaxSwap(), "Only JaxSwap can perform this operation.");
        _;
    }

    function setJaxAdmin(address _jaxAdmin) public onlyAdmin {
        jaxAdmin = _jaxAdmin;    
        IJaxAdmin(jaxAdmin).system_status();    
        emit Set_Jax_Admin(_jaxAdmin);
    }
    
    function mint(address account, uint256 amount) public onlyJaxSwap {
        updateReward(account);
        UserInfo storage info = userInfo[account];
        info.shareMinus += amount * (block.number - lastEpochBlock);
        epochShareMinus += amount * (block.number - lastEpochBlock);
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyJaxSwap {
        updateReward(account);
        UserInfo storage info = userInfo[account];
        info.sharePlus += amount * (block.number - lastEpochBlock);
        epochSharePlus += amount * (block.number - lastEpochBlock);
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
      uint256 currentAllowance = allowance(account, msg.sender);
      require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
      _approve(account, msg.sender, currentAllowance - amount);
      burn(account, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        revert("transfer is not allowed");
        return false;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        revert("transfer is not allowed");
        return false;
    }

    function deposit_reward(uint amount) public {
        require(IJaxAdmin(jaxAdmin).userIsGovernor(tx.origin), "tx.origin should be governor");
        uint epochShare = (block.number - lastEpochBlock) * totalSupply() + epochSharePlus - epochShareMinus;
        
        uint rewardPerShare;
        if(epochShare > 0) {
            rewardPerShare = amount * 1e36 / epochShare; // multiplied by 1e36
            IERC20(rewardToken).transferFrom(msg.sender, address(this), rewardPerShare * epochShare / 1e36);
        }
        EpochInfo memory newEpoch;
        newEpoch.blockCount = block.number - lastEpochBlock;
        newEpoch.rewardPerShare = rewardPerShare;
        newEpoch.totalRewardPerBalance = epochInfo[currentEpoch-1].totalRewardPerBalance + rewardPerShare * (block.number - lastEpochBlock);
        epochInfo.push(newEpoch);
        lastEpochBlock = block.number;
        epochShare = 0;
        epochSharePlus = 0;
        epochShareMinus = 0;
        currentEpoch += 1;
        emit Deposit_Reward(amount);
    }

    function updateReward(address account) internal {
        UserInfo storage user = userInfo[account];
        if(user.currentEpoch == currentEpoch) return;
        if(user.currentEpoch == 0) {
            user.currentEpoch = currentEpoch;
            return;
        }
        uint balance = balanceOf(account);
        EpochInfo storage epoch = epochInfo[user.currentEpoch];
        uint newReward = (balance * epoch.blockCount + user.sharePlus - user.shareMinus) * epoch.rewardPerShare;
        newReward += balance * (epochInfo[currentEpoch-1].totalRewardPerBalance - 
                            epochInfo[user.currentEpoch].totalRewardPerBalance);
        user.totalReward += newReward;
        user.sharePlus = 0;
        user.shareMinus = 0;
        user.currentEpoch = currentEpoch;
    }

    function harvest() external {
        updateReward(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        uint reward = (user.totalReward - user.rewardPaid)/1e36;
        require(reward > 0, "Nothing to harvest");
        IERC20(rewardToken).transfer(msg.sender, reward);
        user.rewardPaid = user.totalReward;
        emit Harvest(msg.sender, reward);
    }

    function set_reward_token(address _rewardToken) public onlyAdmin {
        rewardToken = _rewardToken;
        emit Set_Reward_Token(_rewardToken);
    }

    // vote functions
    function vote_governor(address candidate) public {
        require(balanceOf(msg.sender) > 0, "Only VRP holders can participate voting.");
        require(vote[msg.sender] != candidate, "Already Voted");
        if(vote[msg.sender] != address(0x0)) {
        voteShare[vote[msg.sender]] -= balanceOf(msg.sender);
        }
        vote[msg.sender] = candidate;
        voteShare[candidate] += balanceOf(msg.sender);
        emit Vote_Governor(msg.sender, candidate);
        check_candidate(candidate);
    }

    function check_candidate(address candidate) internal {
        if(candidate == address(0x0)) return;
        if(voteShare[candidate] >= totalSupply() * 51 / 100) {
            IJaxAdmin(jaxAdmin).electGovernor(candidate);
        }
    }

    function updateVoteShare(address voter, uint amount, Action action) internal {
        address candidate = vote[voter];
        if(action == Action.Mint)
            voteShare[candidate] += amount;
        else
            voteShare[candidate] -= amount;
        emit Update_Vote_Share(voter, candidate, voteShare[candidate]);
        check_candidate(candidate);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function withdrawByAdmin(address token, uint amount) external onlyAdmin {
        IERC20(token).transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the BEP standard.
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getOwner() external view returns (address);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../lib/IERC20.sol";
import "../lib/Initializable.sol";

contract Ubi is Initializable {

    event Set_Ajax_Prime(address oldAjaxPrime, address newAjaxPrime);
    event Set_Reward_Token(address rewardToken);
    event Set_User_Info(address user, string idHash, Status newStatus);
    event Collect_UBI(address indexed user, uint amount);
    event Deposit_Reward(uint amount);
    event Set_Minimum_Reward_Per_Person(uint amount);

    address public ajaxPrime;
    address public rewardToken;

    enum Status { Init, Pending, Approved, Rejected }

    struct UserInfo {
        uint harvestedReward;
        string idHash;
        Status status;
    }

    uint public totalRewardPerPerson;
    uint public userCount;
    uint public minimumRewardPerPerson;

    mapping(address => UserInfo) public userInfo;

    modifier onlyAjaxPrime() {
        require(msg.sender == ajaxPrime, "Only Admin");
        _;
    }

    function set_reward_token(address _rewardToken) external onlyAjaxPrime {
        rewardToken = _rewardToken;
        emit Set_Reward_Token(_rewardToken);
    }

    function set_minimum_reward_per_person(uint amount) external onlyAjaxPrime {
        minimumRewardPerPerson = amount;
        emit Set_Minimum_Reward_Per_Person(amount);
    }

    function deposit_reward(uint amount) external {
        uint rewardPerPerson = amount / userCount;
        require(rewardPerPerson >= minimumRewardPerPerson, "Reward is too small");
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        totalRewardPerPerson += rewardPerPerson;
        emit Deposit_Reward(amount);
    }

    function collect_ubi() external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.status == Status.Approved, "You are not approved");
        uint reward = totalRewardPerPerson - info.harvestedReward;
        require(reward > 0, "Nothing to harvest");
        IERC20(rewardToken).transfer(msg.sender, reward);
        info.harvestedReward = totalRewardPerPerson;
        emit Collect_UBI(msg.sender, reward);
    }

    function setUserInfo(address user, string calldata idHash, Status newStatus) external onlyAjaxPrime {
        UserInfo storage info = userInfo[user];
        require(info.status != Status.Init, "User is not registered");
        if(newStatus == Status.Approved) {
            if(info.status != Status.Approved) {
                userCount += 1;
                info.harvestedReward = totalRewardPerPerson;
            }
        }
        if(newStatus == Status.Rejected) {
            if(info.status == Status.Approved) {
                userCount -= 1;
            }
        }
        info.idHash = idHash;
        info.status = newStatus;
        emit Set_User_Info(user, idHash, newStatus);
    }

    function register() external {
        UserInfo storage info = userInfo[msg.sender];
        require(info.status == Status.Init, "You already registered");
        userInfo[msg.sender].status = Status.Pending;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _ajaxPrime, address _rewardToken) external initializer {
        ajaxPrime = _ajaxPrime;
        rewardToken = _rewardToken;
    }

    function set_ajax_prime(address newAjaxPrime) external onlyAjaxPrime {
        address oldAjaxPrime = ajaxPrime;
        ajaxPrime = newAjaxPrime;
        emit Set_Ajax_Prime(oldAjaxPrime, newAjaxPrime);
    }

    function withdrawByAdmin(address token, uint amount) external onlyAjaxPrime {
        IERC20(token).transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/IERC20.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeFactory.sol";
import "./interface/IPancakeRouter01.sol";

contract P2P is Ownable {

    struct Seller {
        uint ratio;
        string contactInfo;
    }

    enum Status { Pending, Accepted, Rejected, Completed, Seller_Cancelled, Buyer_Cancelled }

    struct Order {
        uint amount;
        uint timestamp;
        uint ratio;
        uint locked_amount;
        address seller;
        address buyer;
        Status status;
        bool reviewForSeller;
        bool reviewForBuyer;
        bool burnSellerLockedToken;
        bool burnBuyerLockedToken;
    }

    uint public orderCount;
    IERC20 public baseCurrency;
    IERC20 public lockedToken;

    IPancakeRouter01 public router;

    address[] public sellerList;
    Order[] public orderList;

    struct Review {
        uint128 score;
        uint128 timestamp;
        uint256 reviewHash;
    }

    struct User {
        uint balance;
        uint lockedBalance;
        uint score;
        Review[] reviews;        
    }

    mapping(address => User) public userInfo;
    mapping(address => Seller) public sellerInfo;


    event Deposit_Locked_Token(address sender, uint amount);
    event Create_Order(uint orderId, address indexed seller, address indexed buyer, uint amount, uint timestamp);
    event Accept_Order(uint orderId, address indexed seller, address indexed buyer);
    event Reject_Order(uint orderId, address indexed seller, address indexed buyer);
    event Complete_Order(uint orderId, address indexed seller, address indexed buyer);
    event Cancel_Order(uint orderId, address indexed seller, address indexed buyer);

    event Burn_Buyer_Locked_Token(uint orderId, address indexed seller, address indexed buyer);
    event Burn_Seller_Locked_Token(uint orderId, address indexed seller, address indexed buyer);

    event Add_Review_For_Seller(address seller, uint orderId, uint score, uint reviewHash);
    event Add_Review_For_Buyer(address buyer, uint orderId, uint score, uint reviewHash);


    constructor(address pancakeRouter, address _lockedtoken, address _baseCurrency) {
        router = IPancakeRouter01(pancakeRouter);
        lockedToken = IERC20(_lockedtoken);
        baseCurrency = IERC20(_baseCurrency);
    }

    function depositLockedToken(uint amount) external {
        lockedToken.transferFrom(msg.sender, address(this), amount);
        userInfo[msg.sender].balance += amount;
        emit Deposit_Locked_Token(msg.sender, amount);
    }

    function listSeller(uint ratio, string calldata contactInfo) external {
        require(ratio > 0, "Ratio should not be zero");
        Seller storage seller = sellerInfo[msg.sender];
        if(seller.ratio == 0) {
            sellerList.push(msg.sender);
        }
        seller.ratio = ratio;
        seller.contactInfo = contactInfo;
    }

    function createOrder(address seller, uint amount) external {
        Seller memory _seller = sellerInfo[seller];
        require(_seller.ratio > 0, "Not valid seller");
        User storage seller_info = userInfo[seller];
        User storage buyer_info = userInfo[msg.sender];
        uint sellerAvailableBalance = seller_info.balance - seller_info.lockedBalance;
        uint buyerAvailableBalance = buyer_info.balance - buyer_info.lockedBalance;
        uint lock_amount = getLockedTokenAmount(amount);
        require(sellerAvailableBalance >= lock_amount, "Not enough seller locked amount");
        require(buyerAvailableBalance >= lock_amount, "Not enough buyer locked amount");
        seller_info.lockedBalance += lock_amount;
        buyer_info.lockedBalance += lock_amount;
        Order memory order;
        order.buyer = msg.sender;
        order.seller = seller;
        order.locked_amount = lock_amount;
        order.ratio = _seller.ratio;
        order.status = Status.Pending;
        orderList.push(order);
        emit Create_Order(orderCount, seller, msg.sender, amount, block.timestamp);
        orderCount += 1;
    }

    function acceptOrder(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Pending, "Not valid status");
        baseCurrency.transferFrom(msg.sender, address(this), order.amount);
        order.status = Status.Accepted;
        emit Accept_Order(orderId, msg.sender, order.buyer);
    }

    function rejectOrder(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Pending, "Not valid status");
        order.status = Status.Rejected;
        emit Reject_Order(orderId, msg.sender, order.buyer);
    }

    function completeOrder(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Accepted, "Not valid status");
        baseCurrency.transfer(order.buyer, order.amount);
        order.status = Status.Completed;
        order.timestamp = block.timestamp;
        userInfo[msg.sender].lockedBalance -= order.locked_amount;
        userInfo[order.buyer].lockedBalance -= order.locked_amount;
        emit Complete_Order(orderId, msg.sender, order.buyer);
    }

    function cancelOrderSeller(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Accepted, "Not valid status");
        baseCurrency.transfer(msg.sender, order.amount);
        order.status = Status.Seller_Cancelled;
        emit Cancel_Order(orderId, msg.sender, order.buyer);
    }

    function cancelOrderBuyer(uint orderId) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Only Seller can accept Order");
        require(order.status == Status.Accepted, "Not valid status");
        baseCurrency.transfer(order.seller, order.amount);
        order.status = Status.Buyer_Cancelled;
        emit Cancel_Order(orderId, msg.sender, order.buyer);
    }
    
    function burnBuyerLockedToken(uint orderId) external {
        Order storage order = orderList[orderId];
        require(msg.sender == order.seller, "Only seller can burn buyer's locked token");
        require(order.status == Status.Completed || order.status == Status.Buyer_Cancelled, "Order is not completed");
        require(order.burnBuyerLockedToken == false, "Already burned");
        lockedToken.transfer(address(0x0), order.locked_amount);
        userInfo[order.buyer].balance -= order.locked_amount;
        order.burnBuyerLockedToken = true;
        emit Burn_Buyer_Locked_Token(orderId, msg.sender, order.buyer);
    } 

    function burnSellerLockedToken(uint orderId) external {
        Order storage order = orderList[orderId];
        require(msg.sender == order.buyer, "Only buyer can burn buyer's locked token");
        require(order.status == Status.Seller_Cancelled, "Order is not completed");       
        require(order.burnSellerLockedToken == false, "Already burned");
        lockedToken.transfer(address(0x0), order.locked_amount);
        userInfo[order.seller].balance -= order.locked_amount;
        order.burnSellerLockedToken = true;
        emit Burn_Seller_Locked_Token(orderId, msg.sender, order.buyer);
    } 

    function addReviewForSeller(uint orderId, uint128 score, uint reviewHash) external {
        Order storage order = orderList[orderId];
        require(order.buyer == msg.sender, "Not buyer");
        require(order.reviewForSeller == false, "Already exist");
        Review memory review;
        review.score = score;
        review.reviewHash = reviewHash;
        review.timestamp = uint128(block.timestamp);
        userInfo[order.seller].reviews.push(review);
        order.reviewForSeller = true;
        emit Add_Review_For_Seller(order.seller, orderId, score, reviewHash);
    }

    function addReviewForBuyer(uint orderId, uint128 score, uint reviewHash) external {
        Order storage order = orderList[orderId];
        require(order.seller == msg.sender, "Not seller");
        require(order.reviewForBuyer == false, "Already exist");
        Review memory review;
        review.score = score;
        review.reviewHash = reviewHash;
        review.timestamp = uint128(block.timestamp);
        userInfo[order.buyer].reviews.push(review);
        order.reviewForBuyer = true;
        emit Add_Review_For_Buyer(order.buyer, orderId, score, reviewHash);
    }

    function getReviews(address user) external view returns(Review[] memory) {
        return userInfo[user].reviews;
    }

    function getBaseCurrencyAmount(uint locked_amount) internal view returns (uint base_amount) {
        uint price = getPrice(address(lockedToken), address(baseCurrency));
        base_amount = locked_amount * (10 ** baseCurrency.decimals()) * price / (10 ** lockedToken.decimals()) / 1e8;
    }

    function getLockedTokenAmount(uint base_amount) internal view returns (uint locked_amount) {
        uint price = getPrice(address(lockedToken), address(baseCurrency));
        locked_amount = 1e8 * base_amount * (10 ** lockedToken.decimals()) / (10 ** baseCurrency.decimals()) / price;
    }

    function getPrice(address token0, address token1) internal view returns(uint) {
        IPancakePair pair = IPancakePair(IPancakeFactory(router.factory()).getPair(token0, token1));
        (uint res0, uint res1,) = pair.getReserves();
        res0 *= 10 ** (18 - IERC20(pair.token0()).decimals());
        res1 *= 10 ** (18 - IERC20(pair.token1()).decimals());
        if(pair.token0() == token1) {
            if(res1 > 0)
                return 1e8 * res0 / res1;
        } 
        else {
            if(res0 > 0)
                return 1e8 * res1 / res0;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPancakePair {
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

pragma solidity 0.8.9;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// Allows a seperate contract with a unlockTokens() function to be used to override unlock dates
interface IUnlockCondition {
    function unlockTokens() external view returns (bool);
}

library VestingMathLibrary {

  // gets the withdrawable amount from a lock
  function getWithdrawableAmount (uint256 startEmission, uint256 endEmission, uint256 amount, uint256 timeStamp, address condition) internal view returns (uint256) {
    // It is possible in some cases IUnlockCondition(condition).unlockTokens() will fail (func changes state or does not return a bool)
    // for this reason we implemented revokeCondition per lock so funds are never stuck in the contract.
    
    // Prematurely release the lock if the condition is met
    if (condition != address(0) && IUnlockCondition(condition).unlockTokens()) {
      return amount;
    }
    // Lock type 1 logic block (Normal Unlock on due date)
    if (startEmission == 0 || startEmission == endEmission) {
        return endEmission < timeStamp ? amount : 0;
    }
    // Lock type 2 logic block (Linear scaling lock)
    uint256 timeClamp = timeStamp;
    if (timeClamp > endEmission) {
        timeClamp = endEmission;
    }
    if (timeClamp < startEmission) {
        timeClamp = startEmission;
    }
    uint256 elapsed = timeClamp - startEmission;
    uint256 fullPeriod = endEmission - startEmission;
    return FullMath.mulDiv(amount, elapsed, fullPeriod); // fullPeriod cannot equal zero due to earlier checks and restraints when locking tokens (startEmission < endEmission)
  }
}

interface IMigrator {
    function migrate(address token, uint256 sharesDeposited, uint256 sharesWithdrawn, uint256 startEmission, uint256 endEmission, uint256 lockID, address owner, address condition, uint256 amountInTokens, uint256 option) external returns (bool);
}

interface IUnicryptAdmin {
    function userIsAdmin(address _user) external view returns (bool);
}

interface ITokenBlacklist {
    function checkToken(address _token) external view;
}

contract TokenVesting is Ownable, ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct UserInfo {
    EnumerableSet.AddressSet lockedTokens; // records all token addresses the user has locked
    mapping(address => uint256[]) locksForToken; // map erc20 address to lockId for that token
  }

  struct TokenLock {
    address tokenAddress; // The token address
    uint256 sharesDeposited; // the total amount of shares deposited
    uint256 sharesWithdrawn; // amount of shares withdrawn
    uint256 startEmission; // date token emission begins
    uint256 endEmission; // the date the tokens can be withdrawn
    uint256 lockID; // lock id per token lock
    address owner; // the owner who can edit or withdraw the lock
    address condition; // address(0) = no condition, otherwise the condition contract must implement IUnlockCondition
  }
  
  struct LockParams {
    address payable owner; // the user who can withdraw tokens once the lock expires.
    uint256 amount; // amount of tokens to lock
    uint256 startEmission; // 0 if lock type 1, else a unix timestamp
    uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
    address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
  }

  EnumerableSet.AddressSet private TOKENS; // list of all unique tokens that have a lock
  mapping(uint256 => TokenLock) public LOCKS; // map lockID nonce to the lock
  uint256 public NONCE = 0; // incremental lock nonce counter, this is the unique ID for the next lock
  uint256 public MINIMUM_DEPOSIT = 100; // minimum divisibility per lock at time of locking
  
  mapping(address => uint256[]) private TOKEN_LOCKS; // map token address to array of lockIDs for that token
  mapping(address => UserInfo) private USERS;

  mapping(address => uint) public SHARES; // map token to number of shares per token, shares allow rebasing and deflationary tokens to compute correctly
  
  EnumerableSet.AddressSet private ZERO_FEE_WHITELIST; // Tokens that have been whitelisted to bypass all fees
  EnumerableSet.AddressSet private TOKEN_WHITELISTERS; // whitelisting contracts and users who can enable no fee for tokens.
  
  struct FeeStruct {
    uint256 tokenFee;
    uint256 freeLockingFee;
    address payable feeAddress;
    address freeLockingToken; // if this is address(0) then it is the gas token of the network (e.g ETH, BNB, Matic)
  }
  
  FeeStruct public FEES;
  
  IUnicryptAdmin UNCX_ADMINS;
  IMigrator public MIGRATOR;
  ITokenBlacklist public BLACKLIST; // prevent AMM tokens with a blacklisting contract

  event onLock(uint256 lockID, address token, address owner, uint256 amountInTokens, uint256 startEmission, uint256 endEmission);
  event onWithdraw(address lpToken, uint256 amountInTokens);
  event onRelock(uint256 lockID, uint256 unlockDate);
  event onTransferLock(uint256 lockIDFrom, uint256 lockIDto, address oldOwner, address newOwner);
  event onSplitLock(uint256 fromLockID, uint256 toLockID, uint256 amountInTokens);
  event onMigrate(uint256 lockID, uint256 amountInTokens);

  constructor (IUnicryptAdmin _uncxAdmins) {
    UNCX_ADMINS = _uncxAdmins;
    FEES.tokenFee = 35;
    FEES.feeAddress = payable(0xAA3d85aD9D128DFECb55424085754F6dFa643eb1);
    FEES.freeLockingFee = 10e18;
  }
  
  /**
   * @notice set the migrator contract which allows the lock to be migrated
   */
  function setMigrator(IMigrator _migrator) external onlyOwner {
    MIGRATOR = _migrator;
  }
  
  function setBlacklistContract(ITokenBlacklist _contract) external onlyOwner {
    BLACKLIST = _contract;
  }
  
  function setFees(uint256 _tokenFee, uint256 _freeLockingFee, address payable _feeAddress, address _freeLockingToken) external onlyOwner {
    FEES.tokenFee = _tokenFee;
    FEES.freeLockingFee = _freeLockingFee;
    FEES.feeAddress = _feeAddress;
    FEES.freeLockingToken = _freeLockingToken;
  }
  
  /**
   * @notice whitelisted accounts and contracts who can call the editZeroFeeWhitelist function
   */
  function adminSetWhitelister(address _user, bool _add) external onlyOwner {
    if (_add) {
      TOKEN_WHITELISTERS.add(_user);
    } else {
      TOKEN_WHITELISTERS.remove(_user);
    }
  }
  
  // Pay a once off fee to have free use of the lockers for the token
  function payForFreeTokenLocks (address _token) external payable {
      require(!ZERO_FEE_WHITELIST.contains(_token), 'PAID');
      // charge Fee
      if (FEES.freeLockingToken == address(0)) {
          require(msg.value == FEES.freeLockingFee, 'FEE NOT MET');
          FEES.feeAddress.transfer(FEES.freeLockingFee);
      } else {
          TransferHelper.safeTransferFrom(address(FEES.freeLockingToken), address(msg.sender), FEES.feeAddress, FEES.freeLockingFee);
      }
      ZERO_FEE_WHITELIST.add(_token);
  }
  
  // Callable by UNCX_ADMINS or whitelisted contracts (such as presale contracts)
  function editZeroFeeWhitelist (address _token, bool _add) external {
    require(UNCX_ADMINS.userIsAdmin(msg.sender) || TOKEN_WHITELISTERS.contains(msg.sender), 'ADMIN');
    if (_add) {
      ZERO_FEE_WHITELIST.add(_token);
    } else {
      ZERO_FEE_WHITELIST.remove(_token);
    }
  }

  /**
   * @notice Creates one or multiple locks for the specified token
   * @param _token the erc20 token address
   * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission, condition]]
   * owner: user or contract who can withdraw the tokens
   * amount: must be >= 100 units
   * startEmission = 0 : LockType 1
   * startEmission != 0 : LockType 2 (linear scaling lock)
   * use address(0) for no premature unlocking condition
   * Fails if startEmission is not less than EndEmission
   * Fails is amount < 100
   */
  function lock (address _token, LockParams[] calldata _lock_params) external nonReentrant {
    require(_lock_params.length > 0, 'NO PARAMS');
    if (address(BLACKLIST) != address(0)) {
        BLACKLIST.checkToken(_token);
    }
    uint256 totalAmount = 0;
    for (uint256 i = 0; i < _lock_params.length; i++) {
        totalAmount += _lock_params[i].amount;
    }

    uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
    TransferHelper.safeTransferFrom(_token, address(msg.sender), address(this), totalAmount);
    uint256 amountIn = IERC20(_token).balanceOf(address(this)) - balanceBefore;

    // Fees
    if (!ZERO_FEE_WHITELIST.contains(_token)) {
      uint256 lockFee = FullMath.mulDiv(amountIn, FEES.tokenFee, 10000);
      TransferHelper.safeTransfer(_token, FEES.feeAddress, lockFee);
      amountIn -= lockFee;
    }
    
    uint256 shares = 0;
    for (uint256 i = 0; i < _lock_params.length; i++) {
        LockParams memory lock_param = _lock_params[i];
        require(lock_param.startEmission < lock_param.endEmission, 'PERIOD');
        require(lock_param.endEmission < 1e10, 'TIMESTAMP INVALID'); // prevents errors when timestamp entered in milliseconds
        require(lock_param.amount >= MINIMUM_DEPOSIT, 'MIN DEPOSIT');
        uint256 amountInTokens = FullMath.mulDiv(lock_param.amount, amountIn, totalAmount);

        if (SHARES[_token] == 0) {
          shares = amountInTokens;
        } else {
          shares = FullMath.mulDiv(amountInTokens, SHARES[_token], balanceBefore == 0 ? 1 : balanceBefore);
        }
        require(shares > 0, 'SHARES');
        SHARES[_token] += shares;
        balanceBefore += amountInTokens;

        TokenLock memory token_lock;
        token_lock.tokenAddress = _token;
        token_lock.sharesDeposited = shares;
        token_lock.startEmission = lock_param.startEmission;
        token_lock.endEmission = lock_param.endEmission;
        token_lock.lockID = NONCE;
        token_lock.owner = lock_param.owner;
        if (lock_param.condition != address(0)) {
            // if the condition contract does not implement the interface and return a bool
            // the below line will fail and revert the tx as the conditional contract is invalid
            IUnlockCondition(lock_param.condition).unlockTokens();
            token_lock.condition = lock_param.condition;
        }
    
        // record the lock globally
        LOCKS[NONCE] = token_lock;
        TOKENS.add(_token);
        TOKEN_LOCKS[_token].push(NONCE);
    
        // record the lock for the user
        UserInfo storage user = USERS[lock_param.owner];
        user.lockedTokens.add(_token);
        user.locksForToken[_token].push(NONCE);
        
        NONCE ++;
        emit onLock(token_lock.lockID, _token, token_lock.owner, amountInTokens, token_lock.startEmission, token_lock.endEmission);
    }
  }
  
   /**
   * @notice withdraw a specified amount from a lock. _amount is the ideal amount to be withdrawn.
   * however, this amount might be slightly different in rebasing tokens due to the conversion to shares,
   * then back into an amount
   * @param _lockID the lockID of the lock to be withdrawn
   * @param _amount amount of tokens to withdraw
   */
  function withdraw (uint256 _lockID, uint256 _amount) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    // convert _amount to its representation in shares
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 shareDebit = FullMath.mulDiv(SHARES[userLock.tokenAddress], _amount, balance);
    // round _amount up to the nearest whole share if the amount of tokens specified does not translate to
    // at least 1 share.
    if (shareDebit == 0 && _amount > 0) {
      shareDebit ++;
    }
    require(shareDebit > 0, 'ZERO WITHDRAWL');
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockID);
    // dust clearance block, as mulDiv rounds down leaving one share stuck, clear all shares for dust amounts
    if (shareDebit + 1 == withdrawableShares) {
      if (FullMath.mulDiv(SHARES[userLock.tokenAddress], balance / SHARES[userLock.tokenAddress], balance) == 0){
        shareDebit++;
      }
    }
    require(withdrawableShares >= shareDebit, 'AMOUNT');
    userLock.sharesWithdrawn += shareDebit;

    // now convert shares to the actual _amount it represents, this may differ slightly from the 
    // _amount supplied in this methods arguments.
    uint256 amountInTokens = FullMath.mulDiv(shareDebit, balance, SHARES[userLock.tokenAddress]);
    SHARES[userLock.tokenAddress] -= shareDebit;
    
    TransferHelper.safeTransfer(userLock.tokenAddress, msg.sender, amountInTokens);
    emit onWithdraw(userLock.tokenAddress, amountInTokens);
  }
  
  /**
   * @notice extend a lock with a new unlock date, if lock is Type 2 it extends the emission end date
   */
  function relock (uint256 _lockID, uint256 _unlock_date) external nonReentrant {
    require(_unlock_date < 1e10, 'TIME'); // prevents errors when timestamp entered in milliseconds
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.endEmission < _unlock_date, 'END');
    // percent fee
    if (!ZERO_FEE_WHITELIST.contains(userLock.tokenAddress)) {
        uint256 remainingShares = userLock.sharesDeposited - userLock.sharesWithdrawn;
        uint256 feeInShares = FullMath.mulDiv(remainingShares, FEES.tokenFee, 10000);
        uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
        uint256 feeInTokens = FullMath.mulDiv(feeInShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
        TransferHelper.safeTransfer(userLock.tokenAddress, FEES.feeAddress, feeInTokens);
        userLock.sharesWithdrawn += feeInShares;
        SHARES[userLock.tokenAddress] -= feeInShares;
    }
    userLock.endEmission = _unlock_date;
    emit onRelock(_lockID, _unlock_date);
  }
  
  /**
   * @notice increase the amount of tokens per a specific lock, this is preferable to creating a new lock
   * Its possible to increase someone elses lock here it does not need to be your own, useful for contracts
   */
  function incrementLock (uint256 _lockID, uint256 _amount) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(_amount >= MINIMUM_DEPOSIT, 'MIN DEPOSIT');
    
    uint256 balanceBefore = IERC20(userLock.tokenAddress).balanceOf(address(this));
    TransferHelper.safeTransferFrom(userLock.tokenAddress, address(msg.sender), address(this), _amount);
    uint256 amountInTokens = IERC20(userLock.tokenAddress).balanceOf(address(this)) - balanceBefore;

    // percent fee
    if (!ZERO_FEE_WHITELIST.contains(userLock.tokenAddress)) {
        uint256 lockFee = FullMath.mulDiv(amountInTokens, FEES.tokenFee, 10000);
        TransferHelper.safeTransfer(userLock.tokenAddress, FEES.feeAddress, lockFee);
        amountInTokens -= lockFee;
    }
    uint256 shares;
    if (SHARES[userLock.tokenAddress] == 0) {
      shares = amountInTokens;
    } else {
      shares = FullMath.mulDiv(amountInTokens, SHARES[userLock.tokenAddress], balanceBefore);
    }
    require(shares > 0, 'SHARES');
    SHARES[userLock.tokenAddress] += shares;
    userLock.sharesDeposited += shares;
    emit onLock(userLock.lockID, userLock.tokenAddress, userLock.owner, amountInTokens, userLock.startEmission, userLock.endEmission);
  }
  
  /**
   * @notice transfer a lock to a new owner, e.g. presale project -> project owner
   * Please be aware this generates a new lock, and nulls the old lock, so a new ID is assigned to the new lock.
   */
  function transferLockOwnership (uint256 _lockID, address payable _newOwner) external nonReentrant {
    require(msg.sender != _newOwner, 'SELF');
    TokenLock storage transferredLock = LOCKS[_lockID];
    require(transferredLock.owner == msg.sender, 'OWNER');
    
    TokenLock memory token_lock;
    token_lock.tokenAddress = transferredLock.tokenAddress;
    token_lock.sharesDeposited = transferredLock.sharesDeposited;
    token_lock.sharesWithdrawn = transferredLock.sharesWithdrawn;
    token_lock.startEmission = transferredLock.startEmission;
    token_lock.endEmission = transferredLock.endEmission;
    token_lock.lockID = NONCE;
    token_lock.owner = _newOwner;
    token_lock.condition = transferredLock.condition;
    
    // record the lock globally
    LOCKS[NONCE] = token_lock;
    TOKEN_LOCKS[transferredLock.tokenAddress].push(NONCE);
    
    // record the lock for the new owner 
    UserInfo storage newOwner = USERS[_newOwner];
    newOwner.lockedTokens.add(transferredLock.tokenAddress);
    newOwner.locksForToken[transferredLock.tokenAddress].push(token_lock.lockID);
    NONCE ++;
    
    // zero the lock from the old owner
    transferredLock.sharesWithdrawn = transferredLock.sharesDeposited;
    emit onTransferLock(_lockID, token_lock.lockID, msg.sender, _newOwner);
  }
  
  /**
   * @notice split a lock into two seperate locks, useful when a lock is about to expire and youd like to relock a portion
   * and withdraw a smaller portion
   * Only works on lock type 1, this feature does not work with lock type 2
   * @param _amount the amount in tokens
   */
  function splitLock (uint256 _lockID, uint256 _amount) external nonReentrant {
    require(_amount > 0, 'ZERO AMOUNT');
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.startEmission == 0, 'LOCK TYPE 2');

    // convert _amount to its representation in shares
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountInShares = FullMath.mulDiv(SHARES[userLock.tokenAddress], _amount, balance);

    require(userLock.sharesWithdrawn + amountInShares <= userLock.sharesDeposited);
    
    TokenLock memory token_lock;
    token_lock.tokenAddress = userLock.tokenAddress;
    token_lock.sharesDeposited = amountInShares;
    token_lock.endEmission = userLock.endEmission;
    token_lock.lockID = NONCE;
    token_lock.owner = msg.sender;
    token_lock.condition = userLock.condition;
    
    // debit previous lock
    userLock.sharesWithdrawn += amountInShares;
    
    // record the new lock globally
    LOCKS[NONCE] = token_lock;
    TOKEN_LOCKS[userLock.tokenAddress].push(NONCE);
    
    // record the new lock for the owner 
    USERS[msg.sender].locksForToken[userLock.tokenAddress].push(token_lock.lockID);
    NONCE ++;
    emit onSplitLock(_lockID, token_lock.lockID, _amount);
  }
  
  /**
   * @notice migrates to the next locker version, only callable by lock owners
   */
  function migrate (uint256 _lockID, uint256 _option) external nonReentrant {
    require(address(MIGRATOR) != address(0), "NOT SET");
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    uint256 sharesAvailable = userLock.sharesDeposited - userLock.sharesWithdrawn;
    require(sharesAvailable > 0, 'AMOUNT');

    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountInTokens = FullMath.mulDiv(sharesAvailable, balance, SHARES[userLock.tokenAddress]);
    
    TransferHelper.safeApprove(userLock.tokenAddress, address(MIGRATOR), amountInTokens);
    MIGRATOR.migrate(userLock.tokenAddress, userLock.sharesDeposited, userLock.sharesWithdrawn, userLock.startEmission,
    userLock.endEmission, userLock.lockID, userLock.owner, userLock.condition, amountInTokens, _option);
    
    userLock.sharesWithdrawn = userLock.sharesDeposited;
    SHARES[userLock.tokenAddress] -= sharesAvailable;
    emit onMigrate(_lockID, amountInTokens);
  }
  
  /**
   * @notice premature unlock conditions can be malicous (prevent withdrawls by failing to evalaute or return non bools)
   * or not give community enough insurance tokens will remain locked until the end date, in such a case, it can be revoked
   */
  function revokeCondition (uint256 _lockID) external nonReentrant {
    TokenLock storage userLock = LOCKS[_lockID];
    require(userLock.owner == msg.sender, 'OWNER');
    require(userLock.condition != address(0)); // already set to address(0)
    userLock.condition = address(0);
  }
  
  // test a condition on front end, added here for convenience in UI, returns unlockTokens() bool, or fails
  function testCondition (address condition) external view returns (bool) {
      return (IUnlockCondition(condition).unlockTokens());
  }
  
  // returns withdrawable share amount from the lock, taking into consideration start and end emission
  function getWithdrawableShares (uint256 _lockID) public view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint8 lockType = userLock.startEmission == 0 ? 1 : 2;
    uint256 amount = lockType == 1 ? userLock.sharesDeposited - userLock.sharesWithdrawn : userLock.sharesDeposited;
    uint256 withdrawable;
    withdrawable = VestingMathLibrary.getWithdrawableAmount (
      userLock.startEmission, 
      userLock.endEmission, 
      amount, 
      block.timestamp, 
      userLock.condition
    );
    if (lockType == 2) {
      withdrawable -= userLock.sharesWithdrawn;
    }
    return withdrawable;
  }
  
  // convenience function for UI, converts shares to the current amount in tokens
  function getWithdrawableTokens (uint256 _lockID) external view returns (uint256) {
    TokenLock storage userLock = LOCKS[_lockID];
    uint256 withdrawableShares = getWithdrawableShares(userLock.lockID);
    uint256 balance = IERC20(userLock.tokenAddress).balanceOf(address(this));
    uint256 amountTokens = FullMath.mulDiv(withdrawableShares, balance, SHARES[userLock.tokenAddress] == 0 ? 1 : SHARES[userLock.tokenAddress]);
    return amountTokens;
  }

  // For UI use
  function convertSharesToTokens (address _token, uint256 _shares) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(_shares, balance, SHARES[_token]);
  }

  function convertTokensToShares (address _token, uint256 _tokens) external view returns (uint256) {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    return FullMath.mulDiv(SHARES[_token], _tokens, balance);
  }
  
  // For use in UI, returns more useful lock Data than just querying LOCKS,
  // such as the real-time token amount representation of a locks shares
  function getLock (uint256 _lockID) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256, uint256, address, address) {
      TokenLock memory tokenLock = LOCKS[_lockID];

      uint256 balance = IERC20(tokenLock.tokenAddress).balanceOf(address(this));
      uint256 totalSharesOr1 = SHARES[tokenLock.tokenAddress] == 0 ? 1 : SHARES[tokenLock.tokenAddress];
      // tokens deposited and tokens withdrawn is provided for convenience in UI, with rebasing these amounts will change
      uint256 tokensDeposited = FullMath.mulDiv(tokenLock.sharesDeposited, balance, totalSharesOr1);
      uint256 tokensWithdrawn = FullMath.mulDiv(tokenLock.sharesWithdrawn, balance, totalSharesOr1);
      return (tokenLock.lockID, tokenLock.tokenAddress, tokensDeposited, tokensWithdrawn, tokenLock.sharesDeposited, tokenLock.sharesWithdrawn, tokenLock.startEmission, tokenLock.endEmission, 
      tokenLock.owner, tokenLock.condition);
  }
  
  function getNumLockedTokens () external view returns (uint256) {
    return TOKENS.length();
  }
  
  function getTokenAtIndex (uint256 _index) external view returns (address) {
    return TOKENS.at(_index);
  }
  
  function getTokenLocksLength (address _token) external view returns (uint256) {
    return TOKEN_LOCKS[_token].length;
  }
  
  function getTokenLockIDAtIndex (address _token, uint256 _index) external view returns (uint256) {
    return TOKEN_LOCKS[_token][_index];
  }
  
  // user functions
  function getUserLockedTokensLength (address _user) external view returns (uint256) {
    return USERS[_user].lockedTokens.length();
  }
  
  function getUserLockedTokenAtIndex (address _user, uint256 _index) external view returns (address) {
    return USERS[_user].lockedTokens.at(_index);
  }
  
  function getUserLocksForTokenLength (address _user, address _token) external view returns (uint256) {
    return USERS[_user].locksForToken[_token].length;
  }
  
  function getUserLockIDForTokenAtIndex (address _user, address _token, uint256 _index) external view returns (uint256) {
    return USERS[_user].locksForToken[_token][_index];
  }
  
  // no Fee Tokens
  function getZeroFeeTokensLength () external view returns (uint256) {
    return ZERO_FEE_WHITELIST.length();
  }
  
  function getZeroFeeTokenAtIndex (uint256 _index) external view returns (address) {
    return ZERO_FEE_WHITELIST.at(_index);
  }
  
  function tokenOnZeroFeeWhitelist (address _token) external view returns (bool) {
    return ZERO_FEE_WHITELIST.contains(_token);
  }
  
  // whitelist
  function getTokenWhitelisterLength () external view returns (uint256) {
    return TOKEN_WHITELISTERS.length();
  }
  
  function getTokenWhitelisterAtIndex (uint256 _index) external view returns (address) {
    return TOKEN_WHITELISTERS.at(_index);
  }
  
  function getTokenWhitelisterStatus (address _user) external view returns (bool) {
    return TOKEN_WHITELISTERS.contains(_user);
  }
}


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
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
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

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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



// Sourced from https://gist.github.com/paulrberg/439ebe860cd2f9893852e2cab5655b65, credits to Paulrberg for porting to solidity v0.8
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}


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


// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

contract UnicryptAdmin is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private ADMINS;
  
  function ownerEditAdmin (address _user, bool _add) public onlyOwner {
    if (_add) {
      ADMINS.add(_user);
    } else {
      ADMINS.remove(_user);
    }
  }
  
  // Admin getters
  function getAdminsLength () external view returns (uint256) {
    return ADMINS.length();
  }
  
  function getAdminAtIndex (uint256 _index) external view returns (address) {
    return ADMINS.at(_index);
  }
  
  function userIsAdmin (address _user) external view returns (bool) {
    return ADMINS.contains(_user);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ref/UniswapRouter.sol";
import "./ref/ITokenVesting.sol";

contract LockedTokenSale is Ownable {

    ITokenVesting public tokenVesting;
    IUniswapV2Router01 public router;
    AggregatorInterface public ref;
    address public token;

    uint constant plan1_price_limit = 97 * 1e16; // ie18
    uint constant plan2_price_limit = 87 * 1e16; // ie18

    uint[] lockedTokenPrice;

    uint public referral_ratio = 1e7; //1e8

    uint public eth_collected;

    struct AccountantInfo {
        address accountant;
        address withdrawal_address;
    }

    AccountantInfo[] accountantInfo;
    mapping(address => address) withdrawalAddress;

    uint min_withdrawal_amount;

    event Set_Accountant(AccountantInfo[] info);
    event Set_Min_Withdrawal_Amount(uint amount);
    event Set_Referral_Ratio(uint ratio);

    modifier onlyAccountant() {
        address withdraw_address = withdrawalAddress[msg.sender];
        require(withdraw_address != address(0x0), "Only Accountant can perform this operation");
        _;
    }

    constructor(address _router, address _tokenVesting, address _ref, address _token) {
        router = IUniswapV2Router01(_router); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        tokenVesting = ITokenVesting(_tokenVesting); // 0x63570e161Cb15Bb1A0a392c768D77096Bb6fF88C 0xDB83E3dDB0Fa0cA26e7D8730EE2EbBCB3438527E
        ref = AggregatorInterface(_ref); // 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 bscTestnet
        token = _token; //0x5Ca372019D65f49cBe7cfaad0bAA451DF613ab96
        lockedTokenPrice.push(0);
        lockedTokenPrice.push(plan1_price_limit); // plan1
        lockedTokenPrice.push(plan2_price_limit); // plan2
        IERC20(_token).approve(_tokenVesting, 1e25);
    }

    function balanceOfToken() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getUnlockedTokenPrice() public view returns (uint) {
        address pair = IUniswapV2Factory(router.factory()).getPair(token, router.WETH());
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint pancake_price;
        if( IUniswapV2Pair(pair).token0() == token ){
            pancake_price = reserve1 * (10 ** IERC20(token).decimals()) / reserve0;
        }
        else {
            pancake_price = reserve0 * (10 ** IERC20(token).decimals()) / reserve1;
        }
        return pancake_price;
    }

    function setLockedTokenPrice(uint plan, uint price) public onlyOwner{
        if(plan == 1)
            require(plan1_price_limit <= price, "Price should not below the limit");
        if(plan == 2)
            require(plan2_price_limit <= price, "Price should not below the limit");
        lockedTokenPrice[plan] = price;
    }

    function getLockedTokenPrice(uint plan) public view returns (uint){
        return lockedTokenPrice[plan] * 1e8 / ref.latestAnswer();
    }

    function buyLockedTokens(uint plan, uint amount, address referrer) public payable{

        require(amount > 0, "You should buy at least 1 locked token");

        uint price = getLockedTokenPrice(plan);
        
        uint amount_eth = amount * price;
        uint referral_value = amount_eth * referral_ratio / 1e8;

        require(amount_eth <= msg.value, 'EXCESSIVE_INPUT_AMOUNT');
        if(referrer != address(0x0) && referrer != msg.sender) {
            payable(referrer).transfer(referral_value);
        }
        
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient fund");
        uint256 lockdays;
        if(plan == 1)
        {
            lockdays = 465;
        } else {
            lockdays = 730;
        }
        uint256 endEmission = block.timestamp + 60 * 60 * 24 * lockdays;
        ITokenVesting.LockParams[] memory lockParams = new ITokenVesting.LockParams[](1);
        ITokenVesting.LockParams memory lockParam;
        lockParam.owner = payable(msg.sender);
        lockParam.amount = amount;
        lockParam.startEmission = 0;
        lockParam.endEmission = endEmission;
        lockParam.condition = address(0);
        lockParams[0] = lockParam;

        tokenVesting.lock(token, lockParams);

        if(amount_eth < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_eth);
        }

        eth_collected += amount_eth;
    }

    function setReferralRatio(uint ratio) external onlyOwner {
        require(ratio >= 1e7 && ratio <= 5e7, "Referral ratio should be 10% ~ 50%");
        referral_ratio = ratio;
        emit Set_Referral_Ratio(ratio);
    }

    function setMinWithdrawalAmount(uint amount) external onlyOwner {
        min_withdrawal_amount = amount;
        emit Set_Min_Withdrawal_Amount(amount);
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyAccountant {
        require(amount >= min_withdrawal_amount, "Below minimum withdrawal amount");
        payable(withdrawalAddress[msg.sender]).transfer(amount);
    }

    function setAccountant(AccountantInfo[] calldata _accountantInfo) external onlyOwner {
        uint length = accountantInfo.length;
        for(uint i; i < length; i++) {
            withdrawalAddress[accountantInfo[i].accountant] = address(0x0);
        }
        delete accountantInfo;
        length = _accountantInfo.length;
        for(uint i; i < length; i++) {
            accountantInfo.push(_accountantInfo[i]);
            withdrawalAddress[_accountantInfo[i].accountant] = _accountantInfo[i].withdrawal_address;
        }
        emit Set_Accountant(_accountantInfo);
    }
}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT


pragma solidity 0.8.9;

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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITokenVesting {

   struct LockParams {
        address payable owner; // the user who can withdraw tokens once the lock expires.
        uint256 amount; // amount of tokens to lock
        uint256 startEmission; // 0 if lock type 1, else a unix timestamp
        uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
        address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
    }
  /**
   * @notice Creates one or multiple locks for the specified token
   * @param _token the erc20 token address
   * @param _lock_params an array of locks with format: [LockParams[owner, amount, startEmission, endEmission, condition]]
   * owner: user or contract who can withdraw the tokens
   * amount: must be >= 100 units
   * startEmission = 0 : LockType 1
   * startEmission != 0 : LockType 2 (linear scaling lock)
   * use address(0) for no premature unlocking condition
   * Fails if startEmission is not less than EndEmission
   * Fails is amount < 100
   */
  function lock (address _token, LockParams[] calldata _lock_params) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./lib/Initializable.sol";
import "./IJaxAdmin.sol";
import "./JaxOwnable.sol";

interface IJaxPlanet {

  struct Colony {
    uint128 level;
    uint128 transaction_tax;
    bytes32 _policy_hash;
    string _policy_link;
  }

  function ubi_tax_wallet() external view returns (address);
  function ubi_tax() external view returns (uint);
  function jaxcorp_dao_wallet() external view returns (address);
  function getMotherColonyAddress(address) external view returns(address);
  function getColony(address addr) external view returns(Colony memory);
  function getUserColonyAddress(address user) external view returns(address);
}

contract JaxPlanet is Initializable, IJaxPlanet, JaxOwnable{
  
  IJaxAdmin public jaxAdmin;

  address public ubi_tax_wallet;
  address public jaxcorp_dao_wallet;
  
  // ubi tax
  uint public ubi_tax;
  
  uint128 public min_transaction_tax;

  mapping (address => address) private mother_colony_addresses;
  mapping (address => address) private user_colony_addresses;
  mapping (address => Colony) private colonies;


  event Set_Jax_Admin(address old_admin, address new_admin);
  event Set_Ubi_Tax(uint ubi_tax, address ubi_tax_wallet);
  event Register_Colony(address colony_external_key, uint128 tx_tax, string colony_policy_link, bytes32 colony_policy_hash, address mother_colony_external_key);
  event Set_Colony_Address(address addr, address colony);
  event Set_Jax_Corp_Dao(address jax_corp_dao_wallet, uint128 tx_tax, string policy_link, bytes32 policy_hash);
  event Set_Min_Transaction_Tax(uint min_tx_tax);

  modifier onlyAdmin() {
    require(jaxAdmin.userIsAdmin(msg.sender) || msg.sender == owner, "Not_Admin"); //Only Admin can perform this operation.
    _;
  }

  modifier onlyGovernor() {
    require(jaxAdmin.userIsGovernor(msg.sender), "Not_Governor"); //Only Governor can perform this operation.
    _;
  }

  modifier onlyAjaxPrime() {
    require(jaxAdmin.userIsAjaxPrime(msg.sender) || msg.sender == owner, "Not_AjaxPrime"); //Only AjaxPrime can perform this operation.
    _;
  }

  modifier isActive() {
      require(jaxAdmin.system_status() == 2, "Swap_Paused"); //Swap has been paused by Admin.
      _;
  }

  function setJaxAdmin(address newJaxAdmin) external onlyAdmin {
    address oldAdmin = address(jaxAdmin);
    jaxAdmin = IJaxAdmin(newJaxAdmin);
    jaxAdmin.system_status();
    emit Set_Jax_Admin(oldAdmin, newJaxAdmin);
  }

  function setUbiTax(uint _ubi_tax, address wallet) external onlyAjaxPrime {
      require(_ubi_tax <= 1e8 * 50 / 100 , "UBI tax can't be more than 50.");
      ubi_tax = _ubi_tax;
      ubi_tax_wallet = wallet;
      emit Set_Ubi_Tax(_ubi_tax, wallet);
  }

  function registerColony(uint128 tx_tax, string memory colony_policy_link, bytes32 colony_policy_hash, address mother_colony_external_key) external {

    require(tx_tax <= (1e8) * 20 / 100, "Tx tax can't be more than 20%");
    require(msg.sender != mother_colony_external_key, "Mother colony can't be set");
    require(user_colony_addresses[msg.sender] == address(0), "User can't be a colony");
    
    if (colonies[mother_colony_external_key].level == 0) {
      mother_colony_addresses[msg.sender] = address(0);
      colonies[msg.sender].level = 2;
    } else {
      if (colonies[mother_colony_external_key].level < colonies[msg.sender].level || colonies[msg.sender].level == 0) {
        mother_colony_addresses[msg.sender] = mother_colony_external_key;
        colonies[msg.sender].level = colonies[mother_colony_external_key].level + 1;
      }
    }
    
    colonies[msg.sender].transaction_tax = tx_tax;
    colonies[msg.sender]._policy_link = colony_policy_link;
    colonies[msg.sender]._policy_hash = colony_policy_hash;
    emit Register_Colony(msg.sender, tx_tax, colony_policy_link, colony_policy_hash, mother_colony_external_key);
  }

  function getColony(address addr) external view returns(Colony memory) {
      Colony memory colony = colonies[addr];
      if(colony.transaction_tax < min_transaction_tax)
        colony.transaction_tax = min_transaction_tax;
      return colony;
  }

  function getUserColonyAddress(address addr) external view returns(address) {
      return user_colony_addresses[addr];
  }

  function getMotherColonyAddress(address account) external view returns(address) {
    return mother_colony_addresses[account];
  }

  function setColonyAddress(address colony) external {
    require(mother_colony_addresses[msg.sender] == address(0), "Colony can't be a user");
    require(msg.sender != colony && colonies[colony].level != 0, "Mother Colony is invalid");
    user_colony_addresses[msg.sender] = colony;
    emit Set_Colony_Address(msg.sender, colony);
  }

  function setJaxCorpDAO(address jaxCorpDao_wallet, uint128 tx_tax, string memory policy_link, bytes32 policy_hash) external onlyAjaxPrime {
      require(tx_tax <= (1e8) * 20 / 100, "Tx tax can't be more than 20%");
      jaxcorp_dao_wallet = jaxCorpDao_wallet;

      colonies[address(0)].transaction_tax = tx_tax;
      colonies[address(0)]._policy_link = policy_link;
      colonies[address(0)]._policy_hash = policy_hash;
      colonies[address(0)].level = 1;

      emit Set_Jax_Corp_Dao(jaxCorpDao_wallet, tx_tax, policy_link, policy_hash);
  }

  function setMinTransactionTax(uint128 min_tx_tax) external onlyAjaxPrime {
    min_transaction_tax = min_tx_tax;
    emit Set_Min_Transaction_Tax(min_tx_tax);
  }

  function initialize(address _jaxAdmin) external initializer {
    jaxAdmin = IJaxAdmin(_jaxAdmin);
    owner = msg.sender;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./BEP20.sol";

/**
 * @title XBEP20
 * @dev Implementation of the XBEP20
 */
contract CommonBEP20 is BEP20 {

    constructor (
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        BEP20(name, symbol)
        payable
    {
        _setupDecimals(decimals);
    }

    function _mint(address account, uint256 amount) internal override(BEP20) onlyOwner {
        super._mint(account, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(BEP20) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public override(BEP20) returns (bool) {
        return super.transfer(recipient, amount);
    }

}