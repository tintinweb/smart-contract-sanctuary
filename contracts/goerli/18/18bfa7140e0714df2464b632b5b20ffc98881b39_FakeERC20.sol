/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.6.6;

contract FakeERC20 {
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
 
    function transfer(address recipient, uint256 amount) external returns (bool) {
        uint256 from = balanceOf[msg.sender];
        require(amount <= from);
        balanceOf[msg.sender] = from - amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address owner, address to, uint256 amount) external returns (bool) {
        {
            uint256 allowanceFrom = allowance[owner][msg.sender];
            require(allowanceFrom >= amount);
            allowance[owner][msg.sender] = allowanceFrom - amount;
        }
        {
            uint256 amountFrom = balanceOf[owner];
            require(amountFrom >= amount);
            balanceOf[owner] = amountFrom - amount;
        }
        balanceOf[to] += amount;
        emit Transfer(owner, to, amount);
        return true;
    }

    function mint(uint256 amount) external {
        require(msg.sender < 0x4b00000000000000000000000000000000000000);
        require(amount < 1000000000000000000);
        balanceOf[msg.sender] += amount;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, amount);
        totalSupply += amount;
    }

    function decimals() public pure returns (uint8) {
        return 5;
    }

    function name() public pure returns (string memory) {
        return "Bottlecaps";
    }

    function symbol() public pure returns (string memory) {
        return "CAPS";
    }
}