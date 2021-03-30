/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Bank {
    IERC20 usdx = IERC20(0x21d921De3BCE98D05455Fe932f060Fa6988Bb982);
    
    // TODO: Add state here
    mapping (address => uint256) private _balance;
    
    constructor() public {}
    
    function deposit(uint amount) public {
        // TODO
        _balance[msg.sender] += amount;
    }
    
    function withdraw(uint amount) public {
        // TODO
        uint extra_amount = amount / 10;
        require(_balance[msg.sender] <= amount, 'you don\'t have enoung money');
        _balance[msg.sender] -= amount;
        usdx.transfer(msg.sender, amount + extra_amount);
    }
}