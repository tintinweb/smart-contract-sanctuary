/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CliffTimelock {
    uint256 public unlockBlock;
    address public owner;
    
    constructor(address _owner, uint256 _unlock){
        owner = _owner;
        unlockBlock = _unlock;
    }
    
    function collect(address _token) external {
        require(msg.sender == owner, '!owner');
        require(block.number >= unlockBlock, 'Not unlocked yet'); 
        
        IERC20 token = IERC20(_token);
        
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    
    //call any contract, in case if it's not standard ERC20 
    function call(address target, uint value, string memory signature, bytes memory data) external {
        require(msg.sender == owner, '!owner');
        require(block.number >= unlockBlock, 'Not unlocked yet'); 
    
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, ) = target.call{value:value}(callData);
        require(success, "Transaction execution reverted.");
    }
}