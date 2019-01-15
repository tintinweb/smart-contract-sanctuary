pragma solidity ^0.4.24;


contract ERC20Interface{ //제 3자 송금기능은 빠진 컨트랙트로 기본적인 인터페이스를 선언하는것!
  function totalSupply() public view returns (uint);
  //발행한 전체 토큰의 자산이 얼마인가?, 리턴값 : 전체 토큰 발행량
  function balanceOf(address who) public view returns (uint);
  //who 주소의 계정에 자산이 얼마 있는가?, 리턴값 : 계정에 보유한 토큰 수
  function transfer(address to, uint value) public returns (bool);
  //내가 가진 토큰 value 개를 to 에게 보내라. 여기서 &#39;나&#39; 는 가스를 소모하여 transfer 함수를 호출한 계정입니다. , 리턴값 : 성공/실패
  event Transfer(address indexed from, address indexed to, uint value);
  //이벤트는 외부에서 호출하는 함수가 아닌 소스 내부에서 호출되는 이벤트 함수입니다.
  //ERC20 에 따르면 &#39;토큰이 이동할 때에는 반드시 Transfer 이벤트를 발생시켜라.&#39; 라고 규정 짓고 있습니다.
}


contract ERC20 is ERC20Interface{
  // 제3자의 송금기능을 추가한 컨트랙트를 선언 하는 것!
  function allowance(address owner, address spender) public view returns (uint);
  // owner 가 spender 에게 인출을 허락한 토큰의 개수는 몇개인가? , 리턴값 : 허용된 토큰의 개수
  function transferFrom(address from, address to, uint value) public returns (bool);
  // from 의 계좌에서 value 개의 토큰을 to 에게 보내라. 단, 이 함수는 approve 함수를 통해 인출할 권리를 받은 spender 만 실행할 수 있다. , 리턴값: 성공/실패
  function approve (address spender, uint value) public returns (bool);
  // spender 에게 value 만큼의 토큰을 인출할 권리를 부여한다. 이 함수를 이용할 때는 반드시 Approval 이벤트 함수를 호출해야 한다. , 리턴값: 성공/실패
  event Approval (address indexed owner, address indexed spender, uint value);
  // owner가 spender에게 인출을 용한 value개수를 블록체인상에 영구적으로 기록한다. => 검색가능.
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

//해당 컨트랙트는 인터페이스에서 선언한 함수들의 기능을 구현해준다.
contract BasicToken is ERC20Interface{
  using SafeMath for uint256;
//using A for B : B 자료형에 A 라이브러리 함수를 붙여라.
//dot(.)으로 호출 할수 있게됨.
//ex) using SafeMath for uint256 이면 uint256자료형에 SafeMath 라이브러리 함수를 .을 이용해 사용가능하다는 뜻 => a.add(1) ,b.sub(2)를 사용가능하게 함.

  mapping (address => uint256) balances;


  uint totalSupply_;

// 토큰의 총 발행량을 구하는 함수.
  function totalSupply() public view returns (uint){
    return totalSupply_;
  }

  function transfer(address _to, uint _value) public returns (bool){
    require (_to != address(0));
    // address(0)은 값이 없다는 것.
    // require란 참이면 실행하는 것.
    require (_value <= balances[msg.sender]);
    // 함수를 호출한 &#39;나&#39;의 토큰 잔고가 보내는 토큰의 개수보다 크거나 같을때 실행.

    balances[msg.sender] = balances[msg.sender].sub(_value);
    //sub는 뺄셈. , 보낸 토큰개수만큼 뺀다.
    balances[_to] = balances[_to].add(_value);
    //add는 덧셈. , 받은 토큰개수 만큼 더한다.

    emit Transfer(msg.sender,_to,_value);
    // Transfer라는 이벤트를 실행하여 이더리움 블록체인상에 거래내역을 기록한다. 물론, 등록됬으므로 검색 가능.
    return true; //모든것이 실행되면 참을 출력.

  }

  function balanceOf(address _owner) public view returns(uint balance){
    return balances[_owner];
  }



}


contract StandardToken is ERC20, BasicToken{
  //ERC20에 선언된 인터페이스를 구현하는 컨트랙트.

  mapping (address => mapping (address => uint)) internal allowed;
  // allowed 매핑은 &#39;누가&#39;,&#39;누구에게&#39;,&#39;얼마의&#39; 인출권한을 줄지를 저장하는 것. ex) allowed[누가][누구에게] = 얼마;

  function transferFrom(address _from, address _to, uint _value) public returns (bool){
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    //보내려는 토큰개수가 계좌주인 _from이 돈을 빼려는 msg.sender에게 허용한 개수보다 작거나 같으면 참.
    //_fromr에게 인출권한을 받은 msg.sender가 가스비를 소모함.

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from,_to,_value);
    return true;

  }

  function approve(address _spender, uint _value) public returns (bool){
    allowed[msg.sender][_spender] = _value;
    //msg.sender의 계좌에서 _value 만큼 인출해 갈 수 있는 권리를 _spender 에게 부여한다.
    emit Approval(msg.sender,_spender,_value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint){
    return allowed[_owner][_spender];
  }

  // 권한을 부여하는사람이 권한을 받는사람에게 허용하는 값을 바꾸려고할때,
  // 채굴순서에의해 코드의 실행순서가 뒤바뀔 수 있다.
  // 그렇게 되면 허용값을 10을줬다가 생각이 바껴서 1을 주게되면
  // 권한을 받은사람은 그것을 눈치채고, 11을 지불할 수 있다.
  // 그런 문제점을 보안하기 위해서 밑의 함수를 추가하였다.
  /* function increaseApproval(address _spender, uint _addedValue) public returns(bool){
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender,_spender,allowed[msg.sender][_spender]);
    return true;

  }

  function decreaseApproval(address _spender, uint _substractedValue) public returns (bool){
    oldValue = allowed[msg.sender][_spender];
    if (_substractedValue > oldValue){
      allowed[msg.sender][_spender] = 0;
    }
    else {
      allowed[msg.sender][_spender] = oldValue.sub(_substractedValue);
    }


    Approval(msg.sender,_spender, allowed[msg.sender][_spender]);

    return true;

  } */

}


contract CreateToken is StandardToken{

  string public constant name = "JHT";
  string public constant symbol = "JHT";
  uint8 public constant decimals = 18;

  //uint256 public constant INITIAL_SUPPLY =            10000000000 * (10**uint(decimals));
  uint256 public constant INITIAL_SUPPLY =  4000000000 * (10**uint(decimals));
  
  constructor() public{
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0,msg.sender,INITIAL_SUPPLY);

  }
}
// 이더스캔에 코드배포시 optimization,컨트랙트네임,컴파일버전등 리믹스와 똑같이 해줄것! , 버전2.0에서 할것.