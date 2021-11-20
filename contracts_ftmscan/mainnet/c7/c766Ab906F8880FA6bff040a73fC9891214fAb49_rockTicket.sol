/**
 *Submitted for verification at FtmScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT   
pragma solidity 0.8.7;

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
}

abstract contract Authority {
    address private owner;
    address[] private caller;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddCaller(address indexed _caller);
    event DeleteCaller(address indexed _caller);

    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function showOwner() public view virtual returns (address) {
        return owner;
    }

    function showCaller() public view virtual returns (address[] memory) {
        return caller;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Authority: caller is not the owner");
        _;
    }

    modifier onlyCaller() {
        bool flag = false;
        for(uint16 i = 0; i < caller.length; i++) {
            if (caller[i] == msg.sender) {
                flag = true;
                break;
            }
        }        
        require(flag, "Authority: caller is not authorized");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addCaller(address _caller) public virtual onlyOwner {
        caller.push(_caller);
        emit AddCaller(_caller);
    }
    
    function deleteCaller(address _caller) public virtual onlyOwner {
        for(uint16 i = 0; i < caller.length; i++) {
            if (caller[i] == _caller) {
                caller[i] = caller[caller.length-1];
                caller.pop();
                emit DeleteCaller(_caller);
                return;
            }
        }
    }    
    
}

contract rockTicket is Authority  {
    using SafeMath for uint256;
    
    string public constant name = "Rarity-Vine rockTicket";
    string public constant symbol = "ROCKT";
    uint8 public constant decimals = 0;

    uint256 public totalSupply;
     
    mapping (address => uint256) public balanceOf;    
    mapping (address => mapping (address => uint256)) public allowance;    
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);


    function mint(address dst, uint256 amount) external onlyCaller {
        require(dst != address(0));
        totalSupply = totalSupply.add(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        emit Transfer(address(0), dst, amount);

    }
    
   function burn(address src, uint256 amount) external onlyCaller {
        balanceOf[src] = balanceOf[src].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(src,address(0),amount);
    }     

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }


    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }


    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[src][spender];

        if (spender != src) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        require(src != address(0));
        require(dst != address(0));

        balanceOf[src] = balanceOf[src].sub(amount);
        balanceOf[dst] = balanceOf[dst].add(amount);
        emit Transfer(src, dst, amount);
    }

}