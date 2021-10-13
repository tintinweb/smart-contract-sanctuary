/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity =0.6.6;


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

contract CatCoin is IERC20 {
    using SafeMath for uint256;
    address public owner;

    string  _name;
    string  _symbol;
    uint8  _decimals;
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    // transfer fee, ten thousandth ratio
    uint256 public fee = 30;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public posAddress;
    //0xA15F3c9860A26593aE28A2266c9f51DD5734bd3f
    address public foundationAddress;

    event Burn(address indexed from, uint256 value);
    event Foundation(address indexed from, uint256 value);
    event PoS(address indexed from, uint256 value);

    constructor(address _pos, address _foundation) public {
        owner = msg.sender;
        _decimals = 18;
        _symbol = "CAT";
        _name = "Cat Coin";
        //1,000,000,000,000 token
        _totalSupply = 1000000000000 * (10 ** uint256(_decimals));
        posAddress = _pos;
        foundationAddress = _foundation;
        //mint
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner address can call this");
        _;
    }

    function setPoSAddress(address _pos) onlyOwner public {
        posAddress = _pos;
    }

    function setFoundationAddress(address _foundation) onlyOwner public {
        foundationAddress = _foundation;
    }

    function name() public override view returns (string memory){
        return _name;
    }

    function symbol() public override view returns (string memory){
        return _symbol;
    }

    function decimals() public override view returns (uint8){
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) override public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) override public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        _transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool){
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = balances[_from].sub(_value);
        uint256 _fee = _value.mul(fee).div(10000) / 3 * 3;
        uint256 _realValue = _value.sub(_fee);
        balances[_to] = balances[_to].add(_realValue);
        balances[posAddress] = balances[posAddress].add(_fee / 3);
        balances[foundationAddress] = balances[foundationAddress].add(_fee / 3);
        balances[burnAddress] = balances[burnAddress].add(_fee / 3);
        emit Burn(_from, _fee / 3);
        emit Foundation(_from, _fee / 3);
        emit PoS(_from, _fee / 3);
    }

    function approve(address _spender, uint256 _value) override public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256){
        return allowed[_owner][_spender];
    }
}

contract PoSPool {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 stakedCat;
        uint256 poolWhenStaked;
    }

    address public owner;
    address public catCoinAddress;

    uint256 public totalStaked;

    mapping(address => UserInfo) public userInfo;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner address can call this");
        _;
    }

    function setTokenAddress(address _cat) onlyOwner public {
        catCoinAddress = _cat;
    }


    function stake(uint256 amount) public returns (bool){
        require(IERC20(catCoinAddress).transferFrom(msg.sender, address(this), amount), "transferFrom failed!");
        uint256 _fee = amount.mul(CatCoin(catCoinAddress).fee()).div(10000) / 3 * 3;
        totalStaked = totalStaked.add(amount.sub(_fee));
        userInfo[msg.sender].stakedCat = userInfo[msg.sender].stakedCat.add(amount.sub(_fee));
        userInfo[msg.sender].poolWhenStaked = IERC20(catCoinAddress).balanceOf(address(this)).sub(totalStaked);
        return true;
    }

    function unstake(uint256 amount) public returns (bool){
        require(userInfo[msg.sender].stakedCat >= amount, "unstake overflow");
        _harvest(msg.sender);

        totalStaked = totalStaked.sub(amount);

        IERC20(catCoinAddress).transfer(msg.sender, amount);
        userInfo[msg.sender].stakedCat = userInfo[msg.sender].stakedCat.sub(amount);
        return true;
    }

    function harvest() public returns (bool){
        return _harvest(msg.sender);
    }


    function _harvest(address user) private returns (bool){
        uint256 poolBefore = userInfo[user].poolWhenStaked;
        uint256 poolNow = IERC20(catCoinAddress).balanceOf(address(this)).sub(totalStaked);
        // uint256 rewards = userInfo[user].stakedCat / totalStaked * (poolNow - poolBefore);
        uint256 rewards = userInfo[user].stakedCat.mul(poolNow.sub(poolBefore)).div(totalStaked);
        IERC20(catCoinAddress).transfer(user, rewards);
        //update pool
        userInfo[user].poolWhenStaked = IERC20(catCoinAddress).balanceOf(address(this)).sub(totalStaked);

        return true;
    }

    receive() payable external {}

    fallback() payable external {}
}