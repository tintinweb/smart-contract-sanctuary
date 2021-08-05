/**
 *Submitted for verification at Etherscan.io on 2020-08-20
*/

pragma solidity 0.6.8;


interface ERC20 {
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address, uint256) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address, uint) external returns (bool);
    
    function transferFrom(address, address, uint256) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
}


contract Hedget is ERC20 {
    
    using SafeMath for uint256;
    
    uint256 public decimals = 18;
    string public name;
    string public symbol;
    
    uint256 public override totalSupply = 1000000000 * (10 ** decimals);
    
    
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override balanceOf;
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        name = "Hedget";
        symbol = "HGET";
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(balanceOf[_to] <= balanceOf[_to].add(_value));
        
        balanceOf[_from] = balanceOf[_from].sub(_value);    
        balanceOf[_to] = balanceOf[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
    }

    function transfer(address to, uint256 value) public override returns (bool success) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }
}