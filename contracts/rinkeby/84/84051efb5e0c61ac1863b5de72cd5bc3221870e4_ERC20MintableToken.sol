/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.6;

// safe math is already ensured in solidity with version >= 0.8.0
// so here is just an encapsulation for safe math usage
// NOTICE: if you change solidity version to some < 0.8.0, never use this impl!
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x * y;
    }
}

contract ERC20Token {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, _totalSupply);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
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

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}

contract ERC20MintableToken is ERC20Token {
    address public owner;
    address[] public minters;
    mapping(address => bool) public isMinter;

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier onlyMinter() {
        require(isMinter[msg.sender], "only minter");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) ERC20Token(_name, _symbol, _decimals, _totalSupply) {
        owner = msg.sender;
    }

    function getMintersCount() external view returns (uint256) {
        return minters.length;
    }

    function getAllMinters() external view returns (address[] memory) {
        return minters;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
    }

    function addMinter(address minter) external onlyOwner {
        require(!isMinter[minter], "minter exist");
        isMinter[minter] = true;
        minters.push(minter);
    }

    function revokeMinter(address minter) external onlyOwner {
        require(isMinter[minter], "minter not exist");
        isMinter[minter] = false;
        for (uint256 i = 0; i < minters.length; ++i) {
            if (minters[i] != minter) {
                continue;
            }
            for (; i+1 < minters.length; ++i) {
                minters[i] = minters[i+1];
            }
            minters.pop();
        }
    }

    function mint(address to, uint256 amount) external onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }
}