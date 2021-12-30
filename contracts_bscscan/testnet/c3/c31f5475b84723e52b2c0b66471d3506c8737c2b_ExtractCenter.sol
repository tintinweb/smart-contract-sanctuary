/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.6;

library Bep20TransferHelper {


    function safeApprove(address token, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

}

contract ExtractCenter {
    
    address private owner;// 发行此合约地址
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only publisher can operate");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // 提取跟销毁都走这里
    function extract(address contractAddress, address user, uint256 qty) public onlyOwner {
        require(Bep20TransferHelper.safeTransfer(contractAddress, user, qty), "asset insufficient");
    }
    
}