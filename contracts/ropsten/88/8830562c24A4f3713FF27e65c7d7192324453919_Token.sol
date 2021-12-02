/**
 *Submitted for verification at Etherscan.io on 2021-12-02
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
    using SafeMath for uint256; // uints256 자료형이 SafeMath 메서드 기능을 부여하겠다는 의미

    // 변동이 없는 값들은 굳이 함수로 만들 필요 없음
    string public name = "SJ_Token";
    string public symbol = "SJT";
    uint8 public decimals = 18; // 소수점을 표현하기 위한 갯수
    uint256 public totalSupply = 10000*10**18; // 10000개의 토큰을 발행
    
    // 누가 얼마를 가지고 있는지 표현하기 위한 테이블(address,value)
    // address 키는 uint256(value) 값을 가진다
    // address(누가), value(얼마를)
    mapping(address=>uint256) _balances;

    // 누가 누구에게 얼마를 허락하는지 표현하는 테이블
    // address(누가), address,value(누구에게,얼마를)
    mapping(address=>mapping(address=>uint256)) _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event a(address indexed a);

    constructor() public{
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }
    
    // owner가 현재 소유중인 토큰의 양 조회
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require(_balances[msg.sender] >= _value,"보낼 금액이 충분하지 않음");

        // //_balances[msg.sender] -= _value; // 보내는 사람 잔고에서 빼고
        // _balances[msg.sender] = _balances[msg.sender].sub(_value);
        // //_balances[_to] += _value; // 받는 사람 잔고에 추가
        // _balances[_to] = _balances[_to].add(_value);
        
        // // transfer 함수 호출 시 아래 이벤트를 호출해줘야함
        // emit Transfer(msg.sender, _to ,_value);
        // return true;
        return _transfer(msg.sender,_to,_value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // transfer를 호출하는 사람이 from 에게 허락을 받았는지 체크
        // 허락한 한도보다 크거나 같은지 체크

        /*if(_allowed[_from][msg.sender] >= _value){
            _balances[_from] -= _value; // 보내는 사람 잔고에서 빼고
            _balances[_to] += _value; // 받는 사람 잔고에 추가
            
            // transfer 함수 호출 시 아래 이벤트를 호출해줘야함
            emit Transfer(_from, _to ,_value);
            return true;
        }
        else
            revert();*/

        // 조건을 만족해야만 아래를 실행하겠다
        // 조건을 만족하지 않으면 프로그램을 강제종료
        // 위 if~else문을 require로 표현
        // 메시지도 넣을 수 있음
        require(_allowed[_from][msg.sender] >= _value, "보내려는 금액이 허가된 한도보다 큼.");

        //_allowed[_from][msg.sender] -= _value; // 사용한 만큼 차감
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

        // require(_balances[_from] >= _value, "보내려는 금액이 허가된 한도보다 큼.");

        return _transfer(_from, _to, _value);

        // //_balances[_from] -= _value; // 보내는 사람 잔고에서 빼고
        // _balances[_from] = SafeMath.sub(_balances[_from],_value);
        // //_balances[_to] += _value; // 받는 사람 잔고에 추가
        // _balances[_to] = SafeMath.add(_balances[_to],_value);
            
        // transfer 함수 호출 시 아래 이벤트를 호출해줘야함
        // emit Transfer(_from, _to ,_value);
        //return true;
    }

    // internal 함수를 통해 기존에 사용하던 소스코드를 현저하게 줄일 수 있음
    function _transfer(address _from, address _to, uint256 _value) internal returns(bool){
        require(_balances[_from] >= _value, "보낼 금액이 충분하지 않음.");

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to ,_value);

        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;

        // approve 함수 호출 시 아래 이벤트를 호출해줘야함
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender]; // 오너가 스팬더에게 허락하는 금액
    }
}