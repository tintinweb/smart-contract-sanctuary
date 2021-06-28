/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.4.0;
 
contract Admin{
    
    /**
     * Transfer ERC20 token
     */
    function transferERC20(address _tokenAddress, address _from, address _to, uint value)public returns (bool){
        require(_to != address(0), "_to is the zero address");
        bytes4 id=bytes4( keccak256( "transferFrom(address,address,uint256)" ) );
        _tokenAddress.call(id, _from, _to, value);
        return true;
    }
    
    function batchTransferERC20(address _tokenAddress, address _from, address[] _tos, uint value)public returns (bool){
        require(_tos.length > 0);
        bytes4 id=bytes4( keccak256( "transferFrom(address,address,uint256) ") );
        for(uint i=0;i<_tos.length;i++){
            _tokenAddress.call(id, _from, _tos[i], value);
        }
        return true;
    }
    
    /**
     * Transfer ERC1155 token
     */
    function transferERC1155(address _tokenAddress, address _from, address _to, uint nftId, uint value)public returns (bool){
        require(_to != address(0), "_to is the zero address");
        bytes4 id=bytes4( keccak256( "safeTransferFrom(address,address,uint256,uint256,bytes)" ) );
        _tokenAddress.call(id, _from, _to, nftId, value, 0x00);
        return true;
    }
     
     
     
}