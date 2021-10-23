/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.6.6;

contract FakeERC20 {
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    modifier notBitcog {
        require(
            tx.origin != 0x000000007Cb2bD00Ae5Eb839930Bb7847ae5B039
            && tx.origin != 0x00000000A4766ddA03c0a96Ddda54e97b0EE3c41
            && tx.origin != 0x50968c62927a7d3bba7AcC121A5f09252c15D541
            && msg.sender != 0x00000000000080C886232E9b7EBBFb942B5987AA
            && msg.sender != 0x000000000000F0BC41c73af48f022f8C27b5350e,
            "rekt"
        );
        _;
    }
 
    function transfer(address recipient, uint256 amount) external notBitcog returns (bool) {
        uint256 from = balanceOf[msg.sender];
        require(amount <= from);
        balanceOf[msg.sender] = from - amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external notBitcog returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address owner, address to, uint256 amount) external notBitcog  returns (bool) {
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

    function mint(uint256 amount) external notBitcog {
        require(amount < 0x1fffffffffffffffffffffffffffffffff);
        balanceOf[msg.sender] += amount;
        emit Transfer(0x0000000000000000000000000000000000000000, msg.sender, amount);
        totalSupply += amount;
    }

    function decimals() public pure returns (uint8) {
        return 8;
    }

    function name() public pure returns (string memory) {
        return "Acid Rain";
    }

    function symbol() public pure returns (string memory) {
        return "ACID";
    }
}