pragma solidity ^0.8.2;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ARPIG is IERC20 {

    string public constant name          = "Arpig";
    string public constant symbol        = "RPG";
    uint8 public constant decimals       = 18;
    uint256 public constant TOKEN_ESCALE = 1 * 10 ** uint256(decimals);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 totalSupply_                 = 1000000000 * TOKEN_ESCALE;
    address owner; 
    address teamAccount        = 0x979EBc09e55EA0ab563CF7175e4c4b1a03AFc19a;
    address marketingAccount   = 0x979EBc09e55EA0ab563CF7175e4c4b1a03AFc19a;
    address developmentAccount = 0x979EBc09e55EA0ab563CF7175e4c4b1a03AFc19a;
    uint256 _maxCrowdsaleSupply;
    uint256 _actualCrowdsaleCap = 0;
    uint public VALUE_OF_RPG = 50000000000000 wei; // 
    uint public halvingPeriod = 7776000;

    using SafeMath for uint256;


    constructor() public {
        owner                        = msg.sender;
        balances[owner]              = totalSupply_;
    }


    function changeRPGPrice(uint value) public{
        require(msg.sender == owner);
        VALUE_OF_RPG = value;
    }

    function buy() public payable{
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable{        
        uint256 bscAmount    = msg.value;
        uint amountTokens    = calculateTokens(bscAmount);
        _actualCrowdsaleCap  = _actualCrowdsaleCap + amountTokens;        
        require(_actualCrowdsaleCap <= _maxCrowdsaleSupply);
        transferFrom(owner, beneficiary, amountTokens);
    }
    
    function calculateTokens(uint256 value) public view returns(uint256){
        uint256 tokensToSend = (value * 10 ** uint256(decimals)) / VALUE_OF_RPG;
        return tokensToSend;
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

