/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity  = 0.8.9;
contract encodeOriginMessage {
    
    struct exchangeInfo{
        address _tokenA;
        address _tokenB;
        uint256 _chainIDB;
        uint256 _amount;
        // address _to;
        // bytes32 _r;
        // bytes32 _s;
        // uint8 _v;
        uint256 _deadline;
        uint256 _fee;
        bytes16 _challenge;
    }
    
    function getChainId() internal view returns(uint256){
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
    
    /***************************************************************************************************************************************
    *说明：将原始数据构造成所需的exchangeInfo结构体传入，生成打包好的签名源数据（需要被签名的内容）
    *参数示例：
    *["0xE2c01dA02284c62f4bC3bC83971B86705747153E","0xA11f20Ac248D1FFAe2D361177188B621CeD94CAC","10001","200000000","0x347451eC4f762972d4E04F68b185418A3a2952a7", "1635933251","1000000","0x00000000000000000000000000000000"]
    ****************************************************************************************************************************************/
    function myEncodeMessage(exchangeInfo memory info) view public returns (bytes memory) {
        bytes  memory salt=abi.encodePacked(info._tokenA, info._tokenB, getChainId(), info._chainIDB, info._amount, info._deadline, info._fee, info._challenge);
        bytes  memory Message=abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    salt.length,
                    salt
                );
        return Message;
    }
}