/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";

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

contract Auction {
    
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
        
    constructor(){
       // _setupRole(TRANSFER_ROLE, msg.sender);
    }
    
    function setBid(uint256 item_id, bytes32 bid_data) public {
        
    }
    
    function transfer(address from_address, address to_address, uint256 amount) public {
        //require(hasRole(TRANSFER_ROLE, msg.sender), "Caller cannot transfer");
        
        IERC20 usdt = IERC20(address(0x01547Ef97f9140dbDF5ae50f06B77337B95cF4BB));
        usdt.transferFrom(from_address, to_address, amount);
    }
}