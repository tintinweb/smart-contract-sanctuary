/**
 *Submitted for verification at Etherscan.io on 2021-07-14
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
     
     
    /**
     * Transfer ERC1155 token and ERC20 token
     */
    function transfer(address _ERC20Address, address _ERC20From, address _ERC20To, uint _ERC20Value, address _ERC1155Address, address _ERC1155From, address _ERC1155To, uint _ERC1155NftId, uint _ERC1155Value, bytes memory _ERC1155Bytes )public returns (bytes memory){
        require(_ERC20To != address(0), "_to is the zero address");
        
        (bool successERC20, bytes memory returndataERC20) = address(_ERC20Address).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _ERC20From, _ERC20To, _ERC20Value));
        (bool successERC1155, bytes memory returndataERC1155) = address(_ERC1155Address).call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", _ERC1155From, _ERC1155To, _ERC1155NftId, _ERC1155Value, _ERC1155Bytes));
        
        if (!(successERC20 && successERC1155) )
            revert();
        return returndataERC1155;
    }
     
}