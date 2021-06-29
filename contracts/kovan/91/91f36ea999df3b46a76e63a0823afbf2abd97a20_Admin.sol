/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
 
contract Admin{
    
    /**
     * Transfer ERC20 token
     */
    function transferERC20(address _tokenAddress, address _from, address _to, uint _value)public returns (bytes memory){
        require(_to != address(0), "_to is the zero address");
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from,_to,_value));
        if (!success)
            revert();
        return returndata;
    }
    
 
    /**
     * Transfer ERC1155 token
     */
    function transferERC1155(address _tokenAddress, address _from, address _to, uint _nftId, uint _value, bytes memory _bytes)public returns (bytes memory){
        require(_to != address(0), "_to is the zero address");
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", _from, _to, _nftId, _value, _bytes));
        if (!success)
            revert();
        return returndata;
    }
     
     
}