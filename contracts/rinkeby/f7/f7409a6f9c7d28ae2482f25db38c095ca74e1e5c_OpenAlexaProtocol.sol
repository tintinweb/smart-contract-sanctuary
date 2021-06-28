/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-16
*/

pragma solidity 0.5.14;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when divide by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: Modulo by zero");
        return a % b;
    }
}


contract ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract OpenAlexaProtocol is ERC20 {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public burnAddress;
    address public owner;
    address public sigAddress;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (bytes32 => bool) private hashConfirmation;

    constructor (address _burnAddress, address _sigAddress) public {
        symbol = "OAP";
        name = "Open Alexa Protocol";
        decimals = 18;
        burnAddress = _burnAddress;
        owner = msg.sender;
        sigAddress = _sigAddress;
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
        uint256 burnFee = (_value.mul(0.1 ether)).div(10**20);
        uint256 balanceFee = _value.sub(burnFee);
        balances[burnAddress] = balances[burnAddress].add(burnFee);
        balances[_to] = balances[_to].add(balanceFee);
        
        emit Transfer(msg.sender, _to, balanceFee);
        emit Transfer(msg.sender, burnAddress, burnFee);
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
        uint256 burnFee = (_value.mul(0.1 ether)).div(10**20);
        uint256 balanceFee = _value.sub(burnFee);
        balances[burnAddress] = balances[burnAddress].add(burnFee);
        balances[msg.sender] = balances[msg.sender].add(balanceFee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, balanceFee);
        emit Transfer(_from, burnAddress, burnFee);
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
     * @dev To change burnt Address
     * @param _newOwner New owner address
     */ 
    function changeowner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
        return true;
    }
   
    
    /**
     * @dev To change burnt Address
     * @param _burnAddress New burn address
     */ 
    function changeburnt(address _burnAddress) public onlyOwner returns(bool) {
        require(_burnAddress != address(0), "Invalid Address");
        burnAddress = _burnAddress;
        return true;
    }
    
    /**
     * @dev To change signature Address
     * @param _newSigAddress New sigOwner address
     */ 
    function changesigAddress(address _newSigAddress) public onlyOwner returns(bool) {
        require(_newSigAddress != address(0), "Invalid Address");
        sigAddress = _newSigAddress;
        return true;
    }
    
    /**
     * @dev To mint OAP Tokens
     * @param _receiver Reciever address
     * @param _amount Amount to mint
     * @param _mrs _mrs[0] - message hash _mrs[1] - r of signature _mrs[2] - s of signature 
     * @param _v  v of signature
     */ 
    function mint(address _receiver, uint256 _amount,bytes32[3] memory _mrs, uint8 _v) public returns (bool) {
        require(_receiver != address(0), "Invalid address");
        require(_amount >= 0, "Invalid amount");
        require(hashConfirmation[_mrs[0]] != true, "Hash exists");
        require(ecrecover(_mrs[0], _v, _mrs[1], _mrs[2]) == sigAddress, "Invalid Signature");
        totalSupply = totalSupply.add(_amount);
        balances[_receiver] = balances[_receiver].add(_amount);
        hashConfirmation[_mrs[0]] = true;
        emit Transfer(address(0), _receiver, _amount);
        return true;
    }
    
    /**
     * @dev To mint OAP Tokens
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