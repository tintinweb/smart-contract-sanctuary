/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

pragma solidity ^0.6.0;

    //ERC20 기본 인터페이스 (추상클래스 개념)
interface IERC20 { 
    
    /* 
    접근제어자
    public : 모든 방법으로 접근 가능
    private : contract 내부에서만 접근 가능
    internal : contract 내부와 상속된 contract에서만 접근가능 
    external : 다른 contract와 transaction으로만 호출 가능

    특수 키워드
    view : 읽기 전용, 데이터를 저장하지 않고 가스비를 소모 하지 않음.
    indexed : 이벤트에서 해당 변수는 검색에 사용될 것을 명시하는 키워드 (송금이력 검색) 

    */

    //기본 송금 기능
    function totalSupply() external view returns (uint256);   
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    //3자 송금 기능
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "UKNOW";
    string public constant symbol = "YUN";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));
 
    uint256 totalSupply_;
    using SafeMath for uint256;

    //기본 송금
    mapping(address => uint256) balances; 
    //event Transfer(address indexed from, address indexed to, uint tokens);

     //3자 송금
    mapping(address => mapping (address => uint256)) allowed;
    //event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}