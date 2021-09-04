/**
 *Submitted for verification at polygonscan.com on 2021-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import {IERC20} from "../github/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract check {
    
    // 0xa9059cbb
    bytes4 public constant SELECTOR_ERC20 = bytes4(keccak256(bytes('transfer(address,uint256)')));
    
    // 0x23b872dd
    bytes4 public constant SELECTOR_ERC721 = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    
    
    function _safeTransferERC20(address token, address to, uint value) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR_ERC20, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'uNiFTswapV1: TRANSFER_FAILED');
    }
    
    function _safeTransferERC721(address token, address to, uint tokenId) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR_ERC721, address(this), to, tokenId));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'uNiFTswapV1: TRANSFER_FAILED');
    }
    
    
}