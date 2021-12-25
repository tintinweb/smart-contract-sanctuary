pragma solidity ^0.8.6;

import "./Libraries.sol";

contract Example {
    IUniswapV2Router02 constant router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    function check_liquiditypool_balance(address first_token, address second_token) view external returns(uint256){
        address pancakePairAddress = IPancakeFactory(router.factory()).getPair(first_token, second_token);
        require(pancakePairAddress != address(0), "This pair pool has not been created");
        return pancakePairAddress.balance;
    }
}