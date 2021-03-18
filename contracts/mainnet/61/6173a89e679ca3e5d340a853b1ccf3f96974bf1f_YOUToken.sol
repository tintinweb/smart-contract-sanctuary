pragma solidity=0.5.16;

import 'SafeMath.sol';
import 'IERCMint20.sol';

contract YOUToken is IERCMint20 {
    using SafeMath for uint;

    string public constant name = 'YOU';
    string public constant symbol = 'YOU';
    uint8 public constant decimals = 18;
    uint public constant max_mint_number = 200000 * (10 ** uint(decimals));
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => mapping(address=>uint)) public user_swap_payblock;
    address public owner;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        owner = msg.sender;
    }
    function changeOwner(address new_owner) external{
        require(msg.sender == owner);
        owner = new_owner;
    }
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value); // is initial value 0?
        emit Transfer(address(0), to, value);
    }

    function _approve(address origen_owner, address spender, uint value) private {
        allowance[origen_owner][spender] = value;
        emit Approval(origen_owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }
    function mint(address to, uint value) external{
        require(msg.sender == owner);
        uint realMint = value;
        if(totalSupply.add(value) > max_mint_number){
            realMint = max_mint_number.sub(totalSupply);
        }
        if(realMint == 0){
            return;
        }
        _mint(to,realMint);
    }

    function getStartblock(address user,address swap_addr) external view returns (uint256 lastblocknum){
        return user_swap_payblock[user][swap_addr];
    }
	function setAddressBlock(address user,address swap_addr,uint256 lastblocknum) external returns (bool success){
	    require(msg.sender == owner);
	    user_swap_payblock[user][swap_addr] = lastblocknum;
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