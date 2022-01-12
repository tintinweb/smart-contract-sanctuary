/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.5.1;

/// @title BEAN - Beans are designed for global trusted talent chain
/// @author zhouhang

/**
 * @title 安全数学库
 * @dev 用于uint256的安全计算，合约内的积分操作均使用这个库的函数代替加减乘除，来避免上溢、下溢等问题
 */
library SafeMath {

	/**
	 * @dev 乘法
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b);
		return c;
	}

	/**
	 * @dev 除法
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;

		return c;
	}

	/**
	 * @dev 减法
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;
    require(c <= a);

    return c;
	}

	/**
	 * @dev 加法
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
    require(c >= a);

    return c;
	}
}

/**
 * @title 所有权合约
 * @dev 用于控制合约的所有权，包括转让所有权
 */
contract Ownable {
	address internal owner_; //合约所有者

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); //合约所有权转让事件

	/**
	 * @dev 构造函数
	 */
	constructor() public {
		owner_ = msg.sender; //合约所有者为合约创建者
	}

	/**
     * @dev 合约所有者
     */
	function owner() public view returns (address) {
		return owner_;
	}

	/**
     * @dev onlyOwner函数修改器：判断合约使用者是不是合约拥有者，是合约拥有者才能执行
     */
	modifier onlyOwner() {
		require(msg.sender == owner_);
		_;
	}

	/**
	 * @dev 转让合约所有权：只有合约所有者能使用，转让合约所有权给newOwner
	 * @param  newOwner 新的合约所有者
	 */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner_, newOwner);
		owner_ = newOwner;
	}
}

/**
 * @title BALC可暂停标准积分合约
 * @dev 可暂停的标准积分合约包括查询余额、积分转账、授权额度、查询授额、授额转账、增加授额、减少授额、暂停合约、重启合约功能，继承Ownable合约功能
 */
contract BALC is Ownable {

	using SafeMath for uint256; //uint256类型使用SafeMath库

	string private name_; //积分名称
	string private symbol_; //积分符号，类似货币符号
	uint256 private decimals_; //小数点后位数
	uint256 private totalSupply_; //发行总量
	bool private paused_; //是否暂停合约

	mapping(address => uint256) internal balances; //地址余额映射
	mapping(address => mapping(address => uint256)) internal allowed; //授权额度映射

	event Transfer(address indexed from, address indexed to, uint256 value); //积分转账事件
	event Approval(address indexed owner, address indexed spender, uint256 value); //授权额度事件
	event Pause(); //合约暂停事件
	event Unpause(); //合约重启事件

	/**
	 * @dev 构造函数：web3代码生成后，需要自定义_name,_symbol,_decimals,_totalSupply
	 */
	constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply, address _owner) public {
		name_ = _name;
		symbol_ = _symbol;
		decimals_ = _decimals;
		totalSupply_ = _totalSupply.mul(10 ** decimals_); //发行总量按小数点后位数转换
		paused_ = false; //默认合约不暂停
		owner_ = _owner;
		balances[owner_] = totalSupply_; //合约发布者持有初始所有积分
	}

	/**
	 * @dev 积分名称
	 */
	function name() public view returns (string memory) {
		return name_;
	}

	/**
	 * @dev 积分符号
	 */
	function symbol() public view returns (string memory) {
		return symbol_;
	}

	/**
	 * @dev 小数点后位数
	 */
	function decimals() public view returns (uint256) {
		return decimals_;
	}

	/**
	 * @dev 发行总量
	 */
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	/**
	 * @dev 是否暂停
	 */
	function isPaused() public view returns (bool) {
		return paused_;
	}

	/**
	 * @dev whenNotPaused函数修改器：判断合约是否未暂停，未暂停时才能执行
	 */
	modifier whenNotPaused() {
		require(!paused_);
		_;
	}

	/**
	 * @dev whenNotPaused函数修改器：判断合约是否暂停，暂停时才能执行
	 */
	modifier whenPaused() {
		require(paused_);
		_;
	}

	/**
	 * @dev 积分转账：在合约未暂停时，由合约使用者msg.sender，向_to转入_value数量的积分
	 * @param  _to 转入地址 _value 积分数量
	 * @return  bool 是否转账成功
	 */
	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	 * @dev 余额查询：查询_account地址的积分余额
	 * @param  _account 积分账户地址
	 * @return  uint256 积分余额
	 */
	function balanceOf(address _account) public view returns (uint256) {
		return balances[_account];
	}

	/**
	 * @dev 授权额度：在合约未暂停时，由合约使用者msg.sender，向_spender授权_value数量积分额度
	 * @param  _spender 被授权地址 _value 授权额度
	 * @return  bool 是否授权成功
	 */
	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		require(_spender != address(0));
		require(_value < totalSupply_);
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
     * @dev 授额转账：在合约未暂停时，由合约使用者msg.sender，从_from向_to转入_value数量的积分，转账数量不能超过_from的授权额度和余额
     * @param  _from 授额地址 _to转入地址 _value 积分数量
     * @return  bool 是否转账成功
     */
	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
    
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	/**
	 * @dev 查询授额：查询由_owner向_spender授权的积分额度
	 * @param  _owner 授权地址 _spender 被授权地址
	 * @return  uint256 授权额度
	 */
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/**
	 * @dev 增加授额：在合约未暂停时，由合约使用者msg.sender向_spender增加_addValue数量的积分额度
	 * @param  _spender 被授权地址 _addedValue 增加的授权额度
	 * @return  bool 是否增加授额成功
	 */
	function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool success) {
        require(_spender != address(0));
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	 * @dev 减少授额：在合约未暂停时，由合约使用者msg.sender向_spender减少_subtractedValue数量的积分额度
	 * @param  _spender 被授权地址 _subtractedValue 减少的授权额度
	 * @return  bool 是否减少授额成功
	 */
	function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool success) {
        require(_spender != address(0));
		uint256 oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	 * @dev 暂停合约：只有合约所有者能使用，在合约未暂停时，暂停合约
	 */
	function pause() onlyOwner whenNotPaused public returns (bool) {
		paused_ = true;
		emit Pause();
		return true;
	}

	/**a
	 * @dev 重启合约：只有合约所有者能使用，在合约暂停时，重启合约
	 */
	function unpause() onlyOwner whenPaused public returns (bool) {
		paused_ = false;
		emit Unpause();
		return true;
	}
}