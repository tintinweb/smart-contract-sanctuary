/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

/*
 * Copyright 2019 Authpaper Team
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.5.10;

contract TokenERC20 {
    mapping (address => uint256) public balanceOf;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract bountySend{
    uint256 sentAmount = 0;
    TokenERC20 bcontract;
    
    constructor(address baseAddr) public {
        bcontract = TokenERC20(baseAddr);
    }
    
    function() external payable { 
        revert();
    }
    
    function sendOutToken(address[] memory addrs, uint256[] memory sendAmount) public {
        require(addrs.length >0);
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            if(sendAmount[i] < 1) continue;
            else{
              bcontract.transferFrom(msg.sender,addrs[i], sendAmount[i] * (10 ** uint256(18)));  
              sentAmount += sendAmount[i];
            } 
        }
    }
}