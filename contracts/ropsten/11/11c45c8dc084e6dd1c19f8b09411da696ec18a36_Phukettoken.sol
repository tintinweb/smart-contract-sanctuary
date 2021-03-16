/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

pragma solidity 0.5.17;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract ERC20{
    
    function totalSupply() public view returns (uint256);
    function transfer(address _to, uint256 _value)public returns(bool);
    function approve(address _spender,uint _value)public returns(bool);
    function transferFrom(address _from,address _to,uint256 _value)public returns(bool);
    function allowance(address _owner, address _spender)public view returns(uint256);
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
}

contract Phukettoken is ERC20{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public _totalSupply;
    address public owner;
    
    mapping(address => uint)public balances;
    mapping(address => mapping (address => uint)) public allowed; 
    
    constructor()public{
        name = "Phuket";
        symbol = "Phuket";
        decimals = 18;
        _totalSupply = 500000000*(10**uint256(decimals));
        owner = msg.sender;
        balances[owner] = balances[owner].add(_totalSupply);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "UnAuthorized");
         _;
     }
    
      /**
     * @dev allowance : Check approved balance
     */
    
    function allowance(address _owner,address _spender)public view returns(uint256){
        return allowed[_owner][_spender];
    }
    
     /**
     * @dev approve : Approve token for spender
     */ 
    
    function approve(address _spender,uint256 _value)public returns(bool){
        require(_spender != address(0), "invalid");
        require(_value <= balances[msg.sender], "insufficient");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
    }
   
    /**
     * @dev transfer : Transfer token to another etherum address
     */ 
    
    function transfer(address _to,uint256 _value)public returns(bool){
        require(_to != address(0), "invalid");
        require(_value > 0, "insufficient");
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    
    /**
     * @dev transferFrom : Transfer token after approval 
     */ 
    
    function transferFrom(address _from,address _to,uint256 _value)public returns(bool){
        require(_from != address(0), "invalid");
        require(_to != address(0), "invalid");
         require(_value <= balances[_from], "Insufficient Balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient Allowance");
        balances[_from] = balances[_from].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }
    
   
     /**
     * @dev totalSupply : Display total supply of token
     */ 
    
    function totalSupply()public view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev balanceOf : Display token balance of given address
     */ 
   
    function balanceOf(address account)public view returns(uint256){
       return balances[account];
    }
    
   function mint( address account,uint256 amount) public onlyOwner {
          require(account != address(0),"ERC20: mint to the zero address");
          balances[account] = balances[account].add(amount);
          _totalSupply = _totalSupply.add(amount);
          emit Transfer(address(0), account, amount);
        
    }
    
   
}