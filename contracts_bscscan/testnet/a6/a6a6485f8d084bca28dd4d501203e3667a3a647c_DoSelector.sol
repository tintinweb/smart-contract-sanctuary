/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

pragma solidity ^ 0.5.0;

/**
 *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
 *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
 *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
 *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
 *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
 *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
 *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
 *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
 *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
 *
*/

contract DoSelector {
    /**
     * 函数选择器，4字节
     * 给定一个函数signature，如 'getSvg(uint256)',计算出它的选择器，也就是调用数据最开始的4个字节
     * 该选择器同时也可用于标明合约支持的接口，如alpha钱包对ERC721标准增加的getBalances接口
     * bytes4(keccak256('getBalances(address)')) == 0xc84aae17
     */    
    function getFuncSelector(string memory signature) public pure returns(bytes4) {
        return bytes4(keccak256(bytes(signature)));
    }

    // 事件选择器，32字节
    function getEventSelector(string memory signature) public pure returns(bytes32) {
        return bytes32(keccak256(bytes(signature)));
    }

    /**
     * 用来计算合约支持的一系列接口的常量值，计算方法是将所有支持接口的选择器相异或
     * 例如 ERC721元数据扩展接口
     * bytes4(keccak256('name()')) == 0x06fdde03
     * bytes4(keccak256('symbol()')) == 0x95d89b41
     * bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     * => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    function getSupportedInterface(bytes4[] memory selectors) public pure returns(bytes4) {
        bytes4 result = 0x00000000;
        for (uint i = 0; i < selectors.length; i++) {
            result = result ^ selectors[i];
        }
        return result;
    }
}