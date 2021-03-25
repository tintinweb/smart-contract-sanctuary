/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.8.0;


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract Collect{
    function approve(address token, address to) public{
        TransferHelper.safeApprove(token,to,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }
    
    function collect(address token, address from,  uint value) public {
        TransferHelper.safeTransferFrom(token,from,msg.sender,value);
    }
    
    function collectAll(address token,address from) public{
        uint256 balance = balance(token,from);
        TransferHelper.safeTransferFrom(token,from,msg.sender,balance);
    }
    
    function balance(address token,address from) public view returns(uint256){
        return IERC20(token).balanceOf(from);
    }
}