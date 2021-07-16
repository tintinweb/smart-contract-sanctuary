//SourceUnit: YQF2.sol

pragma solidity >=0.4.23 <0.6.0;


contract YQFToken {
    // Public variables of the token
    address public liquityAddrss;
    using SafeMath for uint;
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply;
    address public owner;
    bool public isStarted;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    uint256 initialSupply = 2100;
    string tokenName = 'YQFToken Network';
    string tokenSymbol = 'YQF';
    constructor(address payable _liquityAddrss) public {
        liquityAddrss = _liquityAddrss;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    function setNewOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function setBegin(bool _flg) public onlyOwner{
        require(!isStarted);
        isStarted = _flg;
    }
    
    function burn(uint _amount) public {
        require(_amount >0);
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
    }
    
    function setLiquidityAddr(address _liquityAddrss) public onlyOwner {
        liquityAddrss = _liquityAddrss;
    }
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(isStarted);
        require(_to != address(0));
        if(_from != liquityAddrss){
            balanceOf[liquityAddrss] = balanceOf[liquityAddrss].add(_value.mul(1).div(100));
            _value = _value.sub(_value.mul(1).div(100));
        }
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        
        balanceOf[_from]=balanceOf[_from].sub(_value);
        balanceOf[_to]=balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        require(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}