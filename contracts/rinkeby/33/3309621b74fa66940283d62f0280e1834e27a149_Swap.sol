/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity 0.7.6 ;

// SPDX-License-Identifier: Unlicense

interface USDCtoETHswap {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function WETH() external returns (address);
}

interface ERC20token {
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Swap{
    
    
    address private router02Address;
    address private addressUSDC;
    constructor(address _router, address _usdc){
       router02Address = _router;
       addressUSDC = _usdc;
    }


    function tokenSwapV02(uint _amount, uint _amountOutMin) public {
            
            // take token from that user 
            require(ERC20token(addressUSDC).transferFrom(msg.sender, address(this), _amount), 'transferFrom failed.');
            
            // approve that uniswap
            require(ERC20token(addressUSDC).approve(address(router02Address), _amount), 'approve failed.');


            // initiate swap it will transfer ether to my contract
            address[] memory path = new address[](2);
            path[0] = addressUSDC;
            path[1] = USDCtoETHswap(router02Address).WETH();
            uint time = block.timestamp + 10 minutes;
            USDCtoETHswap(router02Address).swapExactTokensForETH(_amount, _amountOutMin, path, msg.sender, time);

            // transfer that ether to user (msg.sender)

            msg.sender.transfer(address(this).balance);
        }


     receive() external payable {
    }

}