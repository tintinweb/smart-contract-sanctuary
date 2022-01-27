//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;


import "./IERC20.sol";
import "./console.sol";

contract LockContract {
    constructor(){}

    //Contract unique key
    function test(uint256 tokenAmount, address tokenAddress) external returns (bool){
        IERC20 token = IERC20(tokenAddress);        

        bool tokenTranferStatus = token.transferFrom(0x0a8b0ae65a7062F6BdFD5e4C577E5CC3629971A5, address(this), tokenAmount);
        
       return tokenTranferStatus;
    }

    function getLendingPoolAddress() external returns (address){
        IERC20 token = IERC20(0x88757f2f99175387aB4C6a4b3067c77A695b0349);
        address abc = token.getLendingPool();
        console.logAddress(abc);
        return abc;
    }
}