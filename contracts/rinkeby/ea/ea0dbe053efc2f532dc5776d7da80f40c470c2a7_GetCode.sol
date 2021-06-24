/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.4.0;
contract GetCode {
    function at(address _addr) public view returns (bytes o_code) {
        assembly {
            // 獲取代碼大小，這需要組合語言
            let size := extcodesize(_addr)

            // 分配輸出字節數組 – 這也可以不用組合語言來實現
            // 通過使用 o_code = new bytes（size）
            o_code := mload(0x40)
            
            // 包括補位在內新的“memory end”
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            
            // 把長度保存到內存中
            mstore(o_code, size)
            
            // 實際獲取代碼，這需要組合語言
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }

    function isContract(address _addr) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}