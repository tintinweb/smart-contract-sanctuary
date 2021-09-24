/**
 *Submitted for verification at polygonscan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
 
contract Admin{
    
    function transfer(address _tokenAddress, address _to, uint _value) public returns (bytes memory) {
        require(_to != address(0), "_to is the zero address");
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transfer(address,uint256)", _to, _value));
        if (!success)
            revert();
        return returndata;
    }
    
    function transferFrom(address _tokenAddress, address _from, address _to, uint _value) public returns (bytes memory) {
        require(_to != address(0), "_to is the zero address");
        
        (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value));
        if (!success)
            revert();
        return returndata;
    }
    
    function batchTransfer(address _tokenAddress, address[] memory _to, uint256 _value) public returns (bytes memory) {
        for(uint256 i = 0; i < _to.length; i++){
            require(_to[i] != address(0), "_to is the zero address");
        
            (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transfer(address,uint256)", _to[i], _value));
            if (!success)
                revert();
            return returndata;
        }
    }

    function batchTransferFrom(address _tokenAddress, address _from, address[] memory _to, uint256 _value) public returns (bytes memory) {
        for(uint256 i = 0; i < _to.length; i++){
            require(_to[i] != address(0), "_to is the zero address");
        
            (bool success, bytes memory returndata) = address(_tokenAddress).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to[i], _value));
            if (!success)
                revert();
            return returndata;
        }
    }

}