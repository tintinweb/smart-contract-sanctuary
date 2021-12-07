/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

pragma solidity ^0.8.0;


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


contract TOKENDUDU06 is IERC20 {
    using SafeMath for uint256;

    string public constant name = "TOKENDUDU06";
    string public constant symbol = "DUDU06";
    uint8 public constant decimals = 9;
    address public dono;
    bool public tradingOpen = false;
    uint256 public deadBlocks = 2;
    uint256 public launchedAt = 0;
    uint256 feeAmount;
    uint256 sobrouTax99;
    address public contaDestinoTax99;


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        dono = msg.sender;
       
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(tradingOpen,"Trading nao aberto ainda");
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
           if((launchedAt + deadBlocks) > block.number){
            sobrouTax99 = (numTokens/100)*99;
            feeAmount=numTokens-sobrouTax99;
            emit Transfer(msg.sender, contaDestinoTax99, sobrouTax99);
            }else{
                feeAmount=numTokens;
            }
        emit Transfer(msg.sender, receiver, feeAmount);
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

      

       function tradingStatus(bool _status, uint256 _deadBlocks) public {
        require(msg.sender == dono,"Apenas o dono pode liberar o trading");
        tradingOpen = _status;
        if(tradingOpen && launchedAt == 0){
            launchedAt = block.number;
            deadBlocks = _deadBlocks;
        }
    }

    function setlaunchedAt()public{
        launchedAt=0;
    }
      function setContaDestinoTax(address _contadestinotax99)public{
        contaDestinoTax99=_contadestinotax99;
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