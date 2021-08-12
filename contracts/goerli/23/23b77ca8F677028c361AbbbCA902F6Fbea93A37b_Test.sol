/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
}

library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

contract Test {
    
    address internal owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function sendToken(address token, uint256 amount, address[] calldata to) external {
        require(to.length > 0);
        require(to.length < 10000);
        for (uint i = 0; i < to.length; i++) {
            TransferHelper.safeTransferFrom(token, msg.sender, to[i], amount);
        }
    }
    
}