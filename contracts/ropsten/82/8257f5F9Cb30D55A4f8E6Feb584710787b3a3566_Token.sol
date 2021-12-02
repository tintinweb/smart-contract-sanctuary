/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Token {
    using SafeMath for uint256;
    
    string public name = "FraudCoin";
    string public symbol = "FRC";
    uint8 public decimals = 18; // 소수점 자리수
    uint256 public totalSupply = 5000000 * 10**18; // 10000개  (소수점 자리수 18자리도 같이 곱해줘야함, 10**18 == 10^18)
    
    // 누가     얼마를 가지고있다.
    // Address  uint256
    mapping(address => uint256) _balances;
        
    // 누가     누구에게    얼마만큼을 허락
    // Address  Address    UINT256
    mapping(address => mapping(address => uint256)) _allowed;
    //      (Owner)            (Spender)

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        _balances[msg.sender] = totalSupply;

        // 이더스캔(테스트넷)에 배포를 했을때 Transfer 이벤트를 띄워줘야 이더스캔에서 토큰으로 인식함
        emit Transfer(address(0), msg.sender, totalSupply);
        //            최초 발행이므로 _from == 0으로 설정
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        //require(_value <= _balances[msg.sender]); // 보내려는 금액이 내가 가진 금액보다 커야 아래 코드 실행
        //_balances[msg.sender] -= _value;
        //_balances[_to] += _value;       
        return _transfer(msg.sender, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        /*
        if(_allowed[_from][msg.sender] < _value){ // 허락받은 금액보다 더 큰 금액을 보내는 경우에는 revert()
            revert();
        }else{
            _balances[_from] -= _value;
            _balances[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        */
        require(_value <= _allowed[_from][msg.sender], "_value > allowed"); // require()의 조건을 만족하는 경우에 아래 코드 실행 (위의 if문과 동일한 의미)
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns(bool) {
        require(_value <= _balances[_from]);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // approve() 함수를 호출하는 사람 == Owner
        _allowed[msg.sender][_spender] = _value;
        //         Owner

        emit Approval(msg.sender, _spender, _value);
        success = true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        remaining = _allowed[_owner][_spender];
    }

    
}