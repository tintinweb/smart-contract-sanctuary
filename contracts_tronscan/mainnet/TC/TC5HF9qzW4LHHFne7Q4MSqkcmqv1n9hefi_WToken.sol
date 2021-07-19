//SourceUnit: SafeMath.sol

pragma solidity >=0.5.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint a, uint b) internal pure returns (uint z) {
        require(b > 0);
        return a / b;
    }
    
    function mod(uint a, uint b) internal pure returns (uint z) {
        require(b != 0, 'ds-math-mod-overflow');
        return a % b;
    }
}


//SourceUnit: Token.sol

pragma solidity >=0.5.8;

import './SafeMath.sol';

contract Token {
    using SafeMath for uint;

    uint public totalSupply;
    uint public constant decimals = 18;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function burn(uint value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)){
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _burn(from, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}


//SourceUnit: WToken.sol

pragma solidity >=0.5.8;

import "./Token.sol";

contract WToken is Token {
    string public constant name = "World";
    string public constant symbol = "W";

    constructor() public {
        _mint(msg.sender, 2100e22);
    }
}