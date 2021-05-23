/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.25;
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
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
	 *
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
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	 *
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
	 *
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
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
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
	 *
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
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface relationship{
    function getFather(address _addr) external view returns(address);
    function getGrandFather(address _addr) external view returns(address);
}
contract SGRToken is ERC20, ERC20Detailed, Ownable{
    
    relationship RP;
    
    address walletA;
    address walletB;
    mapping(address => bool) whiteList;//白名单 用于项目方配置相关
    mapping(address => bool) PairList;
    
    uint256 public maxHoldTokens;
    uint256 public startTransaction;//空投和众筹结束后才可以开始交易
    uint256 public startSell;//添加流动性后 半个小时后才可以开始卖
    uint256 public initSupply;
    bool emergencyPause;
    bool toERC20;
    
    uint256 public walletAGate;
    uint256 public walletBGate;
    uint256 public fatherGate;
    uint256 public grandFatherGate;
    uint256 public brunGate;
    uint256 minTotalSupply;
    
    constructor() public ERC20Detailed("Sagittarius", "SGR", 18){
        
        minTotalSupply = 10000000 * 10 ** uint256(decimals()); //TODO 设置最小销毁量，销毁到这么多即不再销毁
        initSupply = 100000000 * 10** uint256(decimals());

        _mint(msg.sender, 100000000 * 10** uint256(decimals()));//设置接受代币的地址
        setWhiteList(msg.sender, true);
    }

    function init(address _RP, uint256 _walletAGate, uint256 _walletBGate, uint256 _fatherGate, uint256 _grandFatherGate, uint256 _brunGate, address _buyContract, address _airDrop, address _IDOConttact, uint256 _startSell, uint256 _startTransaction) public onlyOwner(){
        RP = relationship(_RP);
        
        walletAGate = _walletAGate;
        walletBGate = _walletBGate;
        fatherGate = _fatherGate;
        grandFatherGate = _grandFatherGate;
        brunGate = _brunGate;
        startSell = _startSell;
        startTransaction = _startTransaction;
        maxHoldTokens = 300 * 10 ** uint256(decimals());//TODO 设置最大持币量
        
        setWhiteList(_buyContract, true);
        setWhiteList(_airDrop, true);
        setWhiteList(_IDOConttact, true);
    }
    
    modifier whenNotPaused() {
        require(!emergencyPause, "Pausable: paused");
        _;
    }
    
    function transfer(address recipient, uint256 amount) public  whenNotPaused() returns (bool){
        if(isWhiteList(msg.sender) || toERC20) return super.transfer(recipient, amount); //set whiteList for addLiquidtion
        require(now > startTransaction,"time can't transaction!");
        if(isPair(recipient)){ //is sell
          require(now > startSell,"is not time to sell!");  
        }
        
        (uint256 toWalletB, uint256 toWalletA, uint256 toFather, uint256 toGrandFather) = sendFees(msg.sender, recipient, amount);
        uint256 toBrun = brunSome(msg.sender, amount);
        uint256 trueAmount = amount.sub(toWalletA+toWalletB+toFather+toGrandFather+toBrun);
        require(_balances[recipient].add(trueAmount) < maxHoldTokens,"Exceeded the maximum holding amount！");
        return super.transfer(recipient, trueAmount);
    }
    
    
    function transferFrom(address sender, address recipient, uint256 amount) public  whenNotPaused() returns (bool) {
        if(isWhiteList(sender) || toERC20) return super.transferFrom(sender, recipient, amount); //set whiteList for addLiquidtion
        require(now > startTransaction,"time can't transaction!");
        if(isPair(recipient)){ //is sell
          require(now > startSell,"is not time to sell!");  
        }
        if(isWhiteList(sender)) return super.transferFrom(sender, recipient, amount); //set whiteList for addLiquidtion
        (uint256 toWalletB, uint256 toWalletA, uint256 toFather, uint256 toGrandFather) = sendFees(sender, recipient, amount);
        uint256 toBrun = brunSome(sender, amount);
        uint256 trueAmount = amount.sub(toWalletA+toWalletB+toFather+toGrandFather+toBrun);
        require(_balances[recipient].add(trueAmount) < maxHoldTokens,"Exceeded the maximum holding amount！");
        return super.transferFrom(sender, recipient, trueAmount);
    }
    
    function sendFees(address sender, address recipient, uint256 _amount) internal returns(uint256 toWalletB, uint256 toWalletA, uint256 toFather, uint256 toGrandFather){
        toWalletB = walletBGate.mul(_amount).div(10**2);
        toWalletA = walletAGate.mul(_amount).div(10**2);
        toFather = fatherGate.mul(_amount).div(10**2);
        toGrandFather = grandFatherGate.mul(_amount).div(10**2);
        

        address _father;
        address _grandFather;
        if(isPair(sender)){//如果是从池子地址出来的，那就是买的行为
            _father = getFather(recipient);
            _grandFather = getGrandfather(recipient);
        }
        else{
            _father = getFather(sender);
            _grandFather = getGrandfather(sender);
        }

        _balances[sender] = _balances[sender].sub(toWalletB+toWalletA+toFather+toGrandFather);
        _balances[walletB] = _balances[walletB].add(toWalletB);
        _balances[walletA] = _balances[walletA].add(toWalletA);
        _balances[_father] = _balances[_father].add(toFather);
        _balances[_grandFather] = _balances[_grandFather].add(toGrandFather);
    }
    

    function brunSome(address _sender, uint256 _amount) internal returns(uint256){
        uint256 toBrun = _amount.mul(brunGate).div(10**2);
        toBrun = _totalSupply.sub(minTotalSupply) < toBrun ? _totalSupply.sub(minTotalSupply) : toBrun;

        if (toBrun > 0 ){
            _burn(_sender, toBrun);
        }
        
        return toBrun;
    }

    function isPair(address _addr) public view returns(bool){
        return PairList[_addr];
    }

    function isWhiteList(address _addr) public view returns (bool){
        return whiteList[_addr];
    }
    
    function getFather(address _addr) public view returns(address){
        return RP.getFather(_addr);
    }
    function getGrandfather(address _addr) public view returns(address){
        return RP.getGrandFather(_addr);
    }
    
    
    //****************************************//
    //*
    //* admin function
    //*
    //****************************************//
    
    function setEmergencyPause() public onlyOwner{
        emergencyPause = !emergencyPause;
    }
    
    function setPairList(address _addr, bool no_yes) public onlyOwner() {
        PairList[_addr] = no_yes;
    }

    function setWhiteList(address _addr, bool no_yes) public onlyOwner() {
        whiteList[_addr] = no_yes;
    }
    
    function setGate(uint256 V_walletA, uint256 V_walletB, uint256 V_father, uint256 V_granFather, uint256 V_brun) public onlyOwner {
        walletAGate = V_walletA;
        walletBGate = V_walletB;
        fatherGate = V_father;
        grandFatherGate = V_granFather;
        brunGate = V_brun;
    }

    function setToERC20(bool no_yes) public onlyOwner {
        toERC20 = no_yes;
    }

}