/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

pragma solidity ^0.6.6;
contract airdrop_contract {
    function airdrop(address _token,address[] memory _arr,uint256 _amount) public{
        for(uint256 i = 0; i < _arr.length;i++){
            TransferHelper.safeTransferFrom(_token,msg.sender, _arr[i], _amount);
        }
    }
}
library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}