// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface pancake_router_interface {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface token_interface {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferfrom(address sender, address recipient, uint256 amount) external returns (bool);
 
}

contract IntractingContract {
    address public pancake_factory_address;
    address public token_address;
    address public pancake_router_address;
    address public WBNB_address;

    constructor(
        address pancake_factory,
        address pancake_router,
        address token,
        address WBNB
    ) {
        pancake_factory_address = pancake_factory;
  
        pancake_router_address = pancake_router;
        token_address = token;
        WBNB_address = WBNB;




    }
    
    function addLiq(address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline) public payable {
        
        token_interface(token).approve(pancake_router_address, amountTokenDesired);
        pancake_router_interface(pancake_router_address).addLiquidityETH(token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline);
    }

    function run() public {
        addLiq(token_address, 100, 50, 100000000000000000, msg.sender,  block.timestamp + 100000);
    }



}