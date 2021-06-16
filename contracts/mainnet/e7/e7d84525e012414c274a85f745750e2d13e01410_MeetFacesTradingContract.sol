/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity >=0.4.21 <0.6.0;

interface ERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        //
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function uintSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MeetFacesTradingContract is ERC20 {
    string  internal _name              = "MeetFaces Trading";
    string  internal _symbol            = "MFT";
    string  internal _standard          = "ERC20";
    uint8   internal _decimals          = 18;
    uint    internal _totalSupply       = 70000000 * 1 ether;
    
    address internal _contractOwner;

    mapping(address => uint256)                     internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event OwnershipTransferred(
        address indexed _oldOwner,
        address indexed _newOwner
    );

    constructor () public {
        balances[msg.sender] = totalSupply();
        _contractOwner = msg.sender;
    }
    // Try to prevent sending ETH to SmartContract by mistake.
    function () external payable  {
        revert("This SmartContract is not payable");
    }
    //
    // Getters and Setters
    //
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function standard() public view returns (string memory) {
        return _standard;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
 
    function contractOwner() public view returns (address) {
        return _contractOwner;
    }
    //
    // Contract common functions
    //
    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0), "'_to' address has to be set");
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require (_spender != address(0), "_spender address has to be set");
        require (_value > 0, "'_value' parameter has to be greater than 0");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_from != address(0), "'_from' address has to be set");
        require(_to != address(0), "'_to' address has to be set");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowed[_from][msg.sender], "Insufficient allowance");

        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Only owner can do that");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _contractOwner;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner returns (bool success) {
        require(_newOwner != address(0) && _contractOwner != _newOwner);
        emit OwnershipTransferred(_contractOwner, _newOwner);
        _contractOwner = _newOwner;
        return true;
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        _totalSupply = SafeMath.sub(_totalSupply, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
    
    function mint(uint256 _value) public onlyOwner returns(bool success) {
        _totalSupply = SafeMath.add(_totalSupply, _value);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _value);
        emit Transfer(address(0), msg.sender, _value);
        return true;
    }
}