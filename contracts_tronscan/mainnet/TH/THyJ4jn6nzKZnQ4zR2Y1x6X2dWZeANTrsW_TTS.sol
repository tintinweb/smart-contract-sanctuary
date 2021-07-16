//SourceUnit: tts.sol

pragma solidity ^0.5.4;

/*****
******
Developers Signature(MD5 Hash) : d6b0169c679a33d9fb19562f135ce6ee
******
*****/

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
    }
}

contract Mintable is Ownable {

    mapping (address => bool) private hasAccess;

    event AddToAccessList (address addr);

    function giveMintAccess(address addr) public onlyOwner {
        hasAccess[addr] = true;
        emit AddToAccessList(addr);
    }

    function deleteMintAccess(address addr) public onlyOwner {
        hasAccess[addr] = false;
    }


    modifier onlyAccessor() {
        require(hasAccess[msg.sender], "caller cannot access this function!");
        _;
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


contract TTS is Mintable{
    using SafeMath for uint256;


    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed from, uint256 value);


    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        _totalSupply = initialSupply * 10 ** uint256(decimals);
        _balanceOf[msg.sender] = _totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_from != address(0));
        require(_balanceOf[_from] >= _value);
        require(_balanceOf[_to].add(_value) >= _balanceOf[_to]);
        uint256 previousBalances = _balanceOf[_from].add(_balanceOf[_to]);
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowances[_from][msg.sender]);     // Check allowance
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);  
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_balanceOf[_from] >= _value);   
        require(_value <= _allowances[_from][msg.sender]);    
        _balanceOf[_from] = _balanceOf[_from].sub(_value);                         
        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);  
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }


    function mint(address account, uint256 value) public onlyAccessor{
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balanceOf[account] = _balanceOf[account].add(value);
        emit Mint(account, value);
    }
}