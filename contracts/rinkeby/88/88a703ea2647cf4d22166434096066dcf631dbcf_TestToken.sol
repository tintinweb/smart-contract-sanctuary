/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity ^0.5.17;

interface IOIP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function nonces(address owner) external view returns (uint);

}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
}

contract TestToken is IOIP20 {
    using SafeMath for uint256;
    
    string public constant name = "Test Token";
    
    string public constant symbol = "TTT";
    
    uint8 public constant decimals = 18;
    
    uint256 public totalSupply = 100000000 * 10 ** 18;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => mapping(address => uint256)) public allowance;

    
    mapping(address => uint256) public nonces;

    
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * 构造函数
     */
    constructor(address owner) public {
        _mint(owner, totalSupply);
    }

    function _mint(address to, uint256 value) internal {
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(- 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

}