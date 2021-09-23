/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract devfee {
    address public admin;
    address public token = 0x69983f6f40B77505C1E63CfBedaCF571F7f61D6a;
    
    constructor() public {
        admin = msg.sender;
    }
    
    function withdraw(uint amount) external onlyAdmin() {
        IERC20(token).transfer(msg.sender, amount);    
    }
    
        modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
}