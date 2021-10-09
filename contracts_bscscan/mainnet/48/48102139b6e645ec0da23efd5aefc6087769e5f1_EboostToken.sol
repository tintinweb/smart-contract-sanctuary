/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

pragma solidity ^0.5.2;

// Safe math library for mathemarical operations
library SafeMath {
    
    // Operation for multiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    // Operation for division
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    // Operation for substraction
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    // Operation for addition
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// Main EBoost Token Contract
contract EboostToken {
    
    // Using safemath 
    using SafeMath for uint256;

    // Basic token information
    string  public name     = "eBoost";
    string  public symbol   = "EBST";
    uint256 public decimals = 8;
    
    // Mapping for balances and allowances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    // Total initial supply of token
    uint256 public totalSupply  = 80838159 * (10 ** uint256(decimals));

    // Wallet variables for address
    address owner;

    // Modifier is Owner address
    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }
    
    // Constructor @when deployed
    constructor() public {
        owner               = msg.sender;
        balanceOf[owner]    = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    // ERC20 Transfer function
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // ERC20 Transfer from wallet
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0) && _to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Approve to allow tranfer tokens
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        require(_value <= balanceOf[msg.sender]);
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}