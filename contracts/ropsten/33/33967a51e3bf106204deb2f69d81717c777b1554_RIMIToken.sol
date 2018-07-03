pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

interface ERC20Interface {
    function totalSupply() external constant returns (uint);				// 총 토큰량 조회
    function balanceOf(address tokenOwner) external constant returns (uint balance);		// tokenOwner 의 잔액 조회
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining); 	// tokenOwner 계좌에서 spender 에게 부여된 권한량 조회
    function transfer(address to, uint tokens) external returns (bool success);			// to 에게 tokens 만큼 송금
    function approve(address spender, uint tokens) external returns (bool success);		// spender에게 tokens 만큼 송금 권한 부여 
    function transferFrom(address from, address to, uint tokens) external returns (bool success);	// from의 계좌에서 to 에게 tokens 만큼 송금 (spender 호출)

    event Transfer(address indexed from, address indexed to, uint tokens);			// 송금 로그
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);		// 위임 로그
}

contract RIMIToken is ERC20Interface {				// 계약 선언
    using SafeMath for uint;					// 연산 함수 (0으로 나누기 등)
    string public constant name = &quot;RIMIToken&quot;;				// 토큰명
    string public constant symbol = &quot;RIM&quot;;				// 토큰 기호
    uint8 public constant decimals = 18;				// 소수점 수
    
    uint private _tokenSupply;					// 총 발행 수
    uint private _totalProvided;                // 총 제공된 양
    address private _owner;					// 소유자
    mapping(address => uint) private _balances;			// 사용자당 잔액
    mapping(address => mapping(address => uint)) private _allowed;		// a의 돈 중 b에게 거래 위임된 잔액
    
    constructor() public {
        _tokenSupply = 15000000000 * (uint(10) ** decimals);					// 총 발행양 할당(1000000000 wei = 1Gwei = 0.000000001 ether)
        _owner = msg.sender;						// 토큰 소유자
        
        _balances[_owner] = _tokenSupply;					// 소유자에게 토큰 할당
    }
    
    function totalSupply() public constant returns (uint) {
        return _tokenSupply;
    }
    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return _balances[tokenOwner]; // 해당 사용자의 잔액 조회
    }
    
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return _allowed[tokenOwner][spender]; // 출금 가능액 조회
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        if (tokens > 0 && balanceOf(msg.sender) >= tokens) {
            _balances[msg.sender] = _balances[msg.sender].sub(tokens);		// 보내는 사람 계좌에서 잔액 감소 
            _balances[to] = _balances[to].add(tokens);				// 받는 사람 계좌에서 잔액 증가
            emit Transfer(msg.sender, to, tokens);					// 송금 내역 저장 (이더스캔에서 조회)
            return true;
        }
        return false;
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        if (tokens > 0 && balanceOf(msg.sender) >= tokens) {			
            _allowed[msg.sender][spender] = tokens;				// 계좌주와 spender 등록
            emit Approval(msg.sender, spender, tokens);				// 권한 위임 내역 저장
            return true;
        }
        return false;

    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if (tokens > 0 && balanceOf(from) >= tokens && _allowed[from][msg.sender] >= tokens) {	// 출금 허용액 보다 작은 경우
            _balances[from] = _balances[from].sub(tokens);					// 출금 진행
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);			// 허용액 조정
            _balances[to] = _balances[to].add(tokens);					// 입금 진행
            emit Transfer(msg.sender, to, tokens);					
            return true;
        }
        return false;

    }
}