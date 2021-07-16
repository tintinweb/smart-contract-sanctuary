//SourceUnit: EtokenTRC20.sol

pragma solidity 0.5.9;


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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Etoken is TRC20 {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;    
    address public owner;    
    address public etokenLink;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    

    constructor () public {
        symbol = "Etoken";
        name = "Etoken link";
        decimals = 8;        
        owner = msg.sender;        
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    /**
     * @dev Check balance of the holder
     * @param _owner Token holder address
     */ 
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev Transfer token to specified address
     * @param _to Receiver address
     * @param _value Amount of the tokens
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balances[msg.sender], "Insufficient balance");
        
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
        require(_from != address(0), "Invalid from address");
        require(_to != address(0), "Invalid to address");
        require(_value <= balances[_from], "Invalid balance");
        require(_value <= allowed[_from][msg.sender], "Invalid allowance");
        
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
        require(_spender != address(0), "Null address");
        require(_value > 0, "Invalid value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev To view approved balance
     * @param _owner Holder address
     * @param _spender Spender address
     */ 
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }  
    
    /**
     * @dev To change Owner Address
     * @param _newOwner New owner address
     */ 
    function changeOwnerAddress(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
        return true;
    }  
    
    
    /**
     * @dev To change etokenlink Address
     * @param _newEtokenLink New etokenlink address
     */ 
    function changeEtokenLink(address _newEtokenLink) public onlyOwner returns(bool) {
        require(_newEtokenLink != address(0), "Invalid Address");
        etokenLink = _newEtokenLink;
        return true;
    }
    
    /**
     * @dev To mint EToken from etokenlink
     * @param _receiver Reciever address
     * @param _amount Amount to mint     
     */ 
    function mint(address _receiver, uint256 _amount) public returns (bool) {
        require(_receiver != address(0), "Invalid address");
        require(msg.sender == etokenLink, "only From etokenlink Contract");
        require(_amount >= 0, "Invalid amount");       
        totalSupply = totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(address(0), _receiver, _amount);
        return true;
    }
    
    /**
     * @dev To mint EToken by admin
     * @param _receiver Reciever address
     * @param _amount Amount to mint
     */ 
    function ownerMint(address _receiver, uint256 _amount) public onlyOwner returns (bool) {
        require(_receiver != address(0), "Invalid address");
        require(_amount >= 0, "Invalid amount");
        totalSupply = totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(address(0), _receiver, _amount);
        return true;
    }
}