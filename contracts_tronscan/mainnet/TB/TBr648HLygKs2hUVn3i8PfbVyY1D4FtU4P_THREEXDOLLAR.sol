//SourceUnit: 3xd.sol

pragma solidity ^0.5.8;

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

contract TRC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed _from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract THREEXDOLLAR is TRC20 {
    
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public newAddress;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
   
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor () public {
        symbol = "3XD";
        name = "3X DOLLAR";
        decimals = 18;
        owner = msg.sender;
        totalSupply = 320000000*(10**uint256(decimals));
        balances[address(this)] = balances[address(this)].add(totalSupply);
    }
    
    /**
     * @dev To change Owner Address
     * @param _newOwner New owner address
     */ 
    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
        return true;
    }
    
    /**
     * @dev To change Address 
     * @param _newAddress New address
     */ 
    function changeAddress(address _newAddress) public onlyOwner returns(bool) {
        require(_newAddress != address(0), "Invalid Address");
        newAddress = _newAddress;
        return true;
    }
    
    /**
     * @dev To Share  Tokens by Admin
     * @param _receiver Reciever address
     * @param _amount Amount to mint
     */ 
    function adminShare(address _receiver, uint256 _amount) public onlyOwner returns (bool) {
        require(_receiver != address(0), "Invalid Address");
        require(balances[address(this)] >= _amount, "Insufficient Token");
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(address(this), _receiver, _amount);
        return true;
    }
    
    /**
     * @dev To Distribute Tokens 
     * @param _receiver Reciever address
     * @param _amount Amount to mint
     */ 
    function distribute(address _receiver, uint256 _amount) public returns (bool) {
        require(_receiver != address(0), "Invalid Address");
        require(_amount >= 0, "Invalid Amount");
        require(msg.sender == newAddress,"Only From contract");
        require(balances[address(this)] >= _amount, "Insufficient Token");
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(address(this), _receiver, _amount);
        return true;
    }
    
    /**
     * @dev Transfer token to specified address
     * @param _to Receiver address
     * @param _value Amount of the tokens
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid Address");
        require(_value <= balances[msg.sender], "Insufficient Balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from  The holder address
     * @param _to  The Receiver address
     * @param _value  the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0), "Invalid from Address");
        require(_to != address(0), "Invalid to Address");
        require(_value <= balances[_from], "Insufficient Balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient Allowance");
        balances[_from] = balances[_from].sub(_value);
        balances[msg.sender] = balances[msg.sender].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @dev Approve respective tokens for spender
     * @param _spender Spender address
     * @param _value Amount of tokens to be allowed
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Null Address");
        require(_value > 0, "Invalid Value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Check balance of the holder
     * @param _owner Token holder address
     */ 
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
   
    /**
     * @dev To view approved balance
     * @param _owner Holder address
     * @param _spender Spender address
     */ 
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    } 
  
}