/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity ^0.4.26;
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

contract owned {
    address public owner;

    /**
     * 初台化构造函数
     */
    function owned () public {
        owner = msg.sender;
    }

    /**
     * 判断当前合约调用者是否是合约的所有者
     */
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    /**
     * 合约的所有者指派一个新的管理员
     * @param  newOwner address 新的管理员帐户地址
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20  is owned{
    using SafeMath for uint256;
    string public name = "BABY BTC";
    string public symbol = "BABY BTC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public ownerAddress;

    bool public _share = true;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public lockAddress;
    mapping (address => bool) public whiteAddress;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);

    address[] public _excluded;
    //分红利率
    uint256 public _shareFee = 0;
    //销毁利率
    uint256 public _burFee = 0;


    function TokenERC20() public {
        totalSupply = 21000000 * 10 ** uint256(decimals);
        ownerAddress = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        whiteAddress[msg.sender] = true;
        _excluded.push(msg.sender);
    }



    function setWhiteAddress(address _whiteAddress,bool bl) {
        require(msg.sender == ownerAddress);
        whiteAddress[_whiteAddress] = bl;
    }


    function setLockAddress(address _lockAddress,bool bl) {
        require(msg.sender == ownerAddress);
        lockAddress[_lockAddress] = bl;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function transferArray(address[] _to, uint256[] _value) public {
        for(uint256 i = 0; i < _to.length; i++){
            _transfer(msg.sender, _to[i], _value[i]);
        }
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        if(!whiteAddress[_from] && !whiteAddress[_to]){
            require(_value <= 20000000 * 10 ** 18);
        }

        if(lockAddress[_from]){
            require(balanceOf[_from].sub(_value) >= totalSupply.mul(90).div(100));
        }

        if(!whiteAddress[_to] && balanceOf[_to] + _value >= totalSupply.mul(90).div(100) && !isContract(_to)){
            require(balanceOf[_to] + _value <= totalSupply.mul(95).div(100));
            lockAddress[_to] = true;
        }
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        if(_share){
            bool exist = true;
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == _to) {
                    exist = false;
                    break;
                }
            }
            if(exist){
                _excluded.push(_to);
            }
        }
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        uint256 burRate = _value.mul(_burFee).div(100);
        if(_share){
            uint256 rate = _value.mul(_shareFee).div(100);
            _transfer(msg.sender, _to, _value.sub(rate).sub(burRate));
            _bonus(rate);
        }else{
            _transfer(msg.sender, _to, _value.sub(burRate));
        }
        _transfer(msg.sender, address(0), burRate);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _bonus(uint _value) private{
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] != msg.sender && _excluded[i] != address(0)) {
                address ads = _excluded[i];
                uint256 balance = balanceOf[ads];
                balanceOf[ads] += _value.mul(balance).div(totalSupply);
            }
        }

    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }

    function setShare(bool _shares) onlyOwner public returns (bool success){
        _share = _shares;
        return true;
    }
   
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {

       
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;

        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}