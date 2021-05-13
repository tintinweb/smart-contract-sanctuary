/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract NoswapDistributor {
    address private _owner;
    mapping(address => uint) public balances;
    IERC20 metis;

   constructor(address token) public{
       _owner = msg.sender;
       metis = IERC20(token);
       // TODO record user's balance here
       balances[0x333796B82356b0Dc7Cac4C9012379D50Df8118F5]= 0x14a4f999adc748;
       balances[0x57eF1486FB0DCb7253eA45868cE8f53a2e3ACDa6]= 0x30ca024f987b900000;
   }
   
   function claim() public returns (bool) {
       uint balance = balances[msg.sender];
       require(balance > 0, "NoswapDistributor:Drop already claimed.");
       require(metis.transfer(msg.sender, balance), "NoswapDistributor:Require transfer success.");
       balances[msg.sender] = 0;
       return true;
   }
   
   function ownerClaim(uint256 amount) public returns (bool) {
        require(_owner == msg.sender, "NoswapDistributor:caller is not the owner");
        require(metis.transfer(_owner, amount), 'NoswaDistributor:Transfer failed.');
        return true;
    }
    
}