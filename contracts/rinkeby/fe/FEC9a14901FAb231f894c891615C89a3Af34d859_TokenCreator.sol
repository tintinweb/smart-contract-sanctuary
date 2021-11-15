pragma solidity ^0.5.0;
// SPDX-License-Identifier: LGPL-3.0-only

import "./TRCToken.sol";



contract TokenCreator {
    TRCToken trcToken;
    
    function createToken(string memory _name,string memory _symbol,uint256 _decimals,uint256 __totalSupply)
       public
    {
        // 创建一个新的 Token 合约并且返回它的地址。
        // 从 JavaScript 方面来说，返回类型是简单的 `address` 类型，因为
        // 这是在 ABI 中可用的最接近的类型。
        trcToken = new TRCToken(_name,_symbol,_decimals,__totalSupply,msg.sender);
       
    }
    function get() public view returns(address){
        return address(trcToken);
    }

    
}