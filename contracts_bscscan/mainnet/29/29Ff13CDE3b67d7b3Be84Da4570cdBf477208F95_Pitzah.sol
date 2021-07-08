/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity 0.8.6;

// SPDX-License-Identifier: 0BSD


//  /$$$$$$$  /$$   /$$                        /$$      
// | $$__  $$|__/  | $$                       | $$      
// | $$  \ $$ /$$ /$$$$$$  /$$$$$$$$  /$$$$$$ | $$$$$$$ 
// | $$$$$$$/| $$|_  $$_/ |____ /$$/ |____  $$| $$__  $$
// | $$____/ | $$  | $$      /$$$$/   /$$$$$$$| $$  \ $$
// | $$      | $$  | $$ /$$ /$$__/   /$$__  $$| $$  | $$
// | $$      | $$  |  $$$$//$$$$$$$$|  $$$$$$$| $$  | $$
// |__/      |__/   \___/ |________/ \_______/|__/  |__/
                                                     
                                                     
// Social links:
// Telegram: t.me/PitzahBSC
// Website: pitzah.org

// Pitzah is the first ever BSC token to bridge cryptocurrencies and food delivery. Join our socials to learn more about our mission.


/** BEP-20 token interface standard. */
interface IBEP20 {
    /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  // This will be defined within the Ownable contract
  // function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

/**
 *  @dev Contract ownership logic implementation.
 */ 
abstract contract Ownable {
    
    /**
        @dev The owner of the contract.
    */
    address internal _owner;
    address private _deadAddress;

    /**
        @dev Initializes the owner to be the deployer of the contract
    */
    constructor() {
        _owner = msg.sender;
    }

    /**
        @dev Checks whether the message sender is the current owner of the contract.
    */
    modifier creator {
        require(msg.sender == _owner); _;
    }

    /**
        @dev Returns the owner of the contract.
    */
    function getOwner() external view returns(address) {
        return _owner;
    }

    /**
        @dev Transfers the ownership of the contract to a dead address.
        This action is irreversible!
    */
    function renounceOwnership() external creator returns(bool) {
        _owner = _deadAddress;
        return true;
    }
}

/**
 *  @dev Internal tracker of the external Stake contract addresses.
 */
abstract contract Stakeable {
    /**
     *  @dev Internal structure to keep track of registered Stake contract adresses.
     */ 
    mapping(address => bool) private _farms;

    /**
     *  @dev Checks whether the sender is an external Stake contract.
     */
    modifier farm {
        require(_farms[msg.sender]); _;
    }

    /** 
     *  @dev Abstract functions to be implemented in a child contract.
     */ 
    function realizeStakeGains(address wallet, uint256 amount) virtual external returns(bool);
    function registerStakeContract(address sContract) virtual external returns(bool); 

    /**
     *  @dev Register an external contract as a stake farm. 
     */ 
    function _registerStakeContract_Internal(address sContract) internal returns(bool) {
        _farms[sContract] = true;
        return true;
    }
}

/**
 *  @dev Implementation of the BEP-20 interface functions.
 */ 
abstract contract BEP20 is IBEP20, Ownable, Stakeable {
    /**
        @dev Private structure to keep track of token balances.
    */
    mapping(address => uint256) private _balances;
    /**
        @dev Private structure to keep track of allowed 3rd party spending.
        First hierarchy level represents wallets whose funds are being spent.
        Inner hierarchy represents wallets who have the right to spend owned tokens.
    */
    mapping(address => mapping(address => uint256)) private _allowances;
    
     /**
        IBEP-20 defined variables.
        NOTE: These must be defined from a child contract!
    */
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _supply;

    /**
        Implementation of the default view functions of the IBEP-20 interface.
    */
    function name() override external view returns(string memory) {
        return _name;
    }

    function symbol() override external view returns(string memory) {
        return _symbol;
    }

    function decimals() override external view returns(uint8) {
        return _decimals;
    }

    function totalSupply() override external view returns(uint256) {
        return _supply;
    }
    
    function balanceOf(address wallet) override public view returns(uint256) {
        return _balances[wallet];
    }
    
    function _balances_Internal(address wallet) private view returns(uint256) {
        return _balances[wallet];
    }

    function _setBalance_Internal(address wallet, uint256 amount) internal returns(bool) {
        _balances[wallet] = amount;
        return true;
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _setAllowance_Internal(address fundsOwner, address spender, uint256 amount) internal returns(bool) {
        _allowances[fundsOwner][spender] = amount;
        return true;
    }
    
    /** 
        Stake contract management implementation
     */
    function realizeStakeGains(address wallet, uint256 amount) override external farm returns(bool) {
        _setBalance_Internal(wallet, _balances_Internal(wallet) + amount);
        _supply += amount;
        emit Transfer(address(this), wallet, amount);
        return true;
    }

    function registerStakeContract(address sContract) override external creator returns(bool) {
        _registerStakeContract_Internal(sContract);
        return true;
    }
    
    /**
        TX management implementation
     */
    uint256 private _txFeeCoefficient = 10;
    
    uint256 private _txSlice = 10;
    address private _lpAddress;
    address private _pitzahAddress;
    address private _burnAddress;
    
    uint256 _lpFee = 6;
    uint256 _pitzahTax = 2;
    uint256 _burn = 2;

    
    function setLPAddress(address addr) external creator returns(bool) {
        _lpAddress = addr;
        return true;
    }
    
    function setPitzahAddress(address addr) external creator returns(bool) {
        _pitzahAddress = addr;
        return true;
    }

    function _excludedFromTxFee(address addr) private view returns(bool) {
        return addr == _owner;
    }

    function _transfer_Internal(address sender, address recipient, uint256 amount) private returns(bool) {
        _setBalance_Internal(sender, _balances_Internal(sender) - amount);
        _setBalance_Internal(recipient, _balances_Internal(recipient) + amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) override external returns(bool) {
        uint256 transactableAmount = amount;
        if (!_excludedFromTxFee(msg.sender)) {
            uint256 txAmount = amount/_txFeeCoefficient;
            transactableAmount -= txAmount;
            _distributeTax(msg.sender, txAmount);
        }
        _transfer_Internal(msg.sender, recipient, transactableAmount);
        return true;
    }
    
    function _distributeTax(address from, uint256 amount) private returns(bool) {
        uint256 taxSlice = amount / _txSlice;
        uint256 pitzahTax = taxSlice * _pitzahTax;
        uint256 burnTax = taxSlice * _burn;
        uint256 lpTax = taxSlice * _lpFee;
        
        _transfer_Internal(from, _pitzahAddress, pitzahTax);
        _transfer_Internal(from, _burnAddress, burnTax);
        _transfer_Internal(from, _lpAddress, lpTax);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override external returns(bool) {
        _setAllowance_Internal(sender, msg.sender, allowance(sender, msg.sender) - amount);
        uint256 transactableAmount = amount;
        if (!_excludedFromTxFee(sender)) {
            uint256 txAmount = amount / _txFeeCoefficient;
            _distributeTax(sender, txAmount);
            transactableAmount -= txAmount;
        }
        _transfer_Internal(sender, recipient, transactableAmount);
        return true;
    }

    function approve(address spender, uint256 amount) override external returns(bool) {
        _setAllowance_Internal(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}

/**
 *  PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH 
 *  PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH
 *  PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH PITZAH
 */
contract Pitzah is BEP20 {

    constructor() {
        _name = "Pitzah";
        _symbol =  "SLICES";
        _decimals = 18;
        
        uint256 numberOfTokens = 10_000_000_000; // 10 billion initial supply
        _supply =  numberOfTokens * (10 ** _decimals);
        
        _setBalance_Internal(msg.sender, _supply);
        emit Transfer(address(this), msg.sender, _supply);
    }
}