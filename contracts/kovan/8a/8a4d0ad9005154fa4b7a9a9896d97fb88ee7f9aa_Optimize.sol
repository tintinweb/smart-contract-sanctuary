/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity 0.6.10;


interface ComptrollerLike {
    function claimComp(address holder, address[] calldata bTokens) external;  
}

interface Erc20Like {
    function balanceOf(address a) external view returns(uint);
}

contract Optimize {
    function profit(address bcomptroller,
                    address comp,
                    address holder,
                    address[] calldata bTokens) external returns(uint[] memory deltaComp) {
        deltaComp = new uint[](bTokens.length);
    
        for(uint i = 0 ; i < bTokens.length ; i++) {
            address[] memory token = new address[](1);
            token[0] = bTokens[i];
            uint compBefore = Erc20Like(comp).balanceOf(holder);
            ComptrollerLike(bcomptroller).claimComp(holder, token);        
            uint compAfter = Erc20Like(comp).balanceOf(holder);
            
            deltaComp[i] = compAfter - compBefore;
        }
    }
}