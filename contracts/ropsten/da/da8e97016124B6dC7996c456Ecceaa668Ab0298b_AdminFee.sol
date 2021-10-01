/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity ^0.6.0;


// interface 
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


// Contract for DevFee
contract AdminFee {
    address public admin;
    address public token = 0x3a642391357c2b2d6B9765fabF1f11DA7E4d35d0; // Token address 
    
    constructor(address _admin) public {    // Only while deploying 
        admin = _admin;
    }
    
    // function for updating admin only can be updated by the admin
    function updateAdmin(address newAdmin) external {
        require(msg.sender == admin, 'only admin can access this contract');
        admin = newAdmin;
    }

    // function to withdraw token only by admin 
    function withdraw(uint amount) external onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        IERC20(token).transfer(msg.sender, amount);    
    }
    // Modifier only admin
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
}