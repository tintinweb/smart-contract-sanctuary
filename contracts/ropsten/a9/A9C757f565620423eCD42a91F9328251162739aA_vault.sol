/**
 *Submitted for verification at Etherscan.io on 2021-09-25
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

contract vault {
    
    
    
    event BuyEggsDB(uint pointt, address account);
    address public token = 0x91dF5E54dd8E90D59A53D38B13f8dCbc012c12D7;
    address public devaddress = 0xecb17Eee101bF0dB51F27B7cD0A9F0b463468433;  //AdminContract Address where the token holds
    function BuyEggs(uint amount, uint _fees) external {
        
        IERC20(token).transferFrom(msg.sender, address(this) , amount);
        IERC20(token).transferFrom(msg.sender, devaddress , _fees);
        uint eggs = amount;
        emit BuyEggsDB(eggs, msg.sender);
        
    }
    
    function SellEggs(uint _eggs) external {
        uint amount = _eggs;
        IERC20(token).transfer(msg.sender, amount);
        
    }
}