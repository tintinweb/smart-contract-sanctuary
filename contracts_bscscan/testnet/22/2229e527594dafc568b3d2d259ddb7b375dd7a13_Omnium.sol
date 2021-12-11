// SPDX-License-Identifier:MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";

// pragma solidity >=0.6.2;

contract Omnium is Context, IBEP20, Ownable {
    
    //Libraries to Use
    using SafeMath for uint256;
    using Address for address;
 
    //Properties
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address[] private _holders;

    address private _comunityAccount = address(0x5E0B838471b4867f3d9A94a3B1D9FdBd222cd253);
    address private _lockAccount = address(0x27d5f103a05a6a8206d07E0343C1fCda7313ACf0);
    address private _inv1 = address(0x7c10E8548B844617a95Ac9DCC7fA76001DcfbAb7);
    address private _inv2 = address(0x3Db37b16381cFB3Ef1Dd691802302e682Eb09FF1);
    address private _inv3 = address(0x9c4fAEFd86e6dbA1E438e65601064EB94642592E);
  
    uint256 private _totalSupply;
    uint256 private _comunitySupply;
    uint256 private _altheraSupply;
    uint256 private _inversorSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    //Fees declaration
    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _deflectionFee = 1;
    uint256 private _previousDeflectionFee = _deflectionFee;
  
    constructor(){
      _name = "Omnium";
      _symbol = "ONM";
      _decimals = 5;
      _totalSupply = 2000000000000 * 10 ** 5;
      _comunitySupply = _totalSupply / 2;
      _altheraSupply = (_totalSupply / 2) - 60000000 * 10 **5;
      _inversorSupply = 20000000 * 10 **5;

      _balances[_comunityAccount] = _comunitySupply;
      _balances[_lockAccount] = _altheraSupply;
      _balances[_inv1] = _inversorSupply;
      _balances[_inv2] = _inversorSupply;
      _balances[_inv3] = _inversorSupply;

      _holders.push(_inv1);
      _holders.push(_inv2);
      _holders.push(_inv3);

  
      emit Transfer(address(0), _comunityAccount, _comunitySupply);
      emit Transfer(address(0), _lockAccount, _altheraSupply);
      emit Transfer(address(0), _inv1, _inversorSupply);
      emit Transfer(address(0), _inv2, _inversorSupply);
      emit Transfer(address(0), _inv3, _inversorSupply);
    }
  
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
      return owner();
    }
  
    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8) {
      return _decimals;
    }
  
    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory) {
      return _symbol;
    }
  
    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory) {
      return _name;
    }
  
    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
      return _totalSupply;
    }
  
    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
      return _balances[account];
    }
  
    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
    }
  
    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
      return _allowances[owner][spender];
    }
  
    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
    }
  
    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
      _transfer(sender, recipient, amount);
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
      return true;
    }
  
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
      return true;
    }
  
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
      return true;
    }

    function removeBurnFee() private {
      if(_burnFee == 0) return;
      
      _previousBurnFee = _burnFee;
      
      _burnFee = 0;
    }

    function restoreBurnFee() private {
      _burnFee = _previousBurnFee;
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
      return _amount.mul(_burnFee).div(
          10**2
      );
    }

    /**
     * @dev Chqnges `burn Fee` aplied to transactions
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function ChangeBurnFee(uint256 newFee) public onlyOwner returns (bool) {
       _previousBurnFee = _burnFee;
       _burnFee = newFee;
        return true;
    }

    function removeDeflectFee() private {
      if(_deflectionFee == 0) return;
      
      _previousDeflectionFee = _deflectionFee;
      
      _deflectionFee = 0;
    }
  
    function restoreDeflectFee() private {
      _deflectionFee = _previousDeflectionFee;
    }

    function calculateDefelctFee(uint256 _amount) private view returns (uint256) {
      return _amount.mul(_deflectionFee).div(
          10**2
      );
    }

    /**
     * @dev Chqnges `Deflection Fee` aplied to transactions
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function ChangeDeflectFee(uint256 newFee) public onlyOwner returns (bool) {
      _previousDeflectionFee = _deflectionFee;
      _deflectionFee = newFee;
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero address");
  
      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      
      emit Transfer(sender, recipient, amount);
      _enlistAccount(recipient);
      if(_balances[_lockAccount] > 100000000){
        uint256 _totalBurning = calculateBurnFee(amount) + calculateDefelctFee(amount);
        _defburn(_totalBurning);
        _deflex(calculateDefelctFee(amount));
      }
      
    }

    function _enlistAccount (address toEnlist) private{
      bool isEnlisted = false;

      if(_holders.length > 0){
        for(uint256 icounter = 0; icounter < _holders.length; icounter++){
          if(toEnlist == _holders[icounter]){
           isEnlisted = true;
           break;
          }
       }
       if(! isEnlisted && toEnlist != _lockAccount && toEnlist != _comunityAccount)
          _holders.push(toEnlist); 
      }
      
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
    function _burn(address account, uint256 amount) internal {
      require(account != address(0), "BEP20: burn from the zero address");
  
      _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
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
    function _approve(address owner, address spender, uint256 amount) internal {
      require(owner != address(0), "BEP20: approve from the zero address");
      require(spender != address(0), "BEP20: approve to the zero address");
  
      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
    }
  
    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
      _burn(account, amount);
      _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    }

    /**
     * @dev Destroy tokens from the lockAccount width every transaction
     */
    function _defburn(uint256 amount) internal {
      require(amount > 0, "BEP20: burn some thing");
  
      _balances[_lockAccount] = _balances[_lockAccount].sub(amount, "BEP20: burn amount exceeds balance");
      _totalSupply = _totalSupply.sub(amount);
      emit Burn(_lockAccount, address(0), amount);
    }

    /**
     * Deflect tokens from the lockAccount width every transaction
     * among token holders
     */
    function _deflex(uint256 amount) internal{
      if(_holders.length > 0){
        uint256 _deflectAmount = amount / _holders.length;
        for(uint256 icounter = 0; icounter < _holders.length; icounter++){
          _balances[_holders[icounter]] = _balances[_holders[icounter]].add(_deflectAmount);
          emit DeflectOut(address(0), _holders[icounter], _deflectAmount);
        }
      }
      
    }
}