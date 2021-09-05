// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeERC20.sol";


contract Airdrop is Ownable{
    
    event batchAirdropComplete(address tokenAddress,address[] addresses,uint256[] tokenAmount);
    event batchAirdropSameAmountComplete(address tokenAddress,address[] addresses,uint256 tokenAmount);
    event AdminTokenRecovery(address tokenAddress,uint256 tokenAmount);
    
   function batchAirdrop(address  tokenAddress,address[] calldata addresses,uint256[] calldata tokenAmount) external onlyOwner{
        require( addresses.length == tokenAmount.length, "Address and amount length do not match");
        for(uint32 i = 0; i < addresses.length; i++){
            require(!_isContract(addresses[i]), "Contract not allowed");
            IERC20(tokenAddress).transferFrom(address(msg.sender),addresses[i], tokenAmount[i]);
        }
        emit batchAirdropComplete(tokenAddress,addresses,tokenAmount);
    }
    
    function batchAirdropSameAmount(address tokenAddress,address[] calldata addresses,uint256 tokenAmount) external onlyOwner{
        for(uint32 i = 0; i < addresses.length; i++){
            require(!_isContract(addresses[i]), "Contract not allowed");
            IERC20(tokenAddress).transferFrom(address(msg.sender),addresses[i], tokenAmount);
        }
        emit batchAirdropSameAmountComplete(tokenAddress,addresses,tokenAmount);
    }
    
    
    function recoverWrongTokens(address  tokenAddress, uint256  tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(address(msg.sender), tokenAmount);
        emit AdminTokenRecovery(tokenAddress, tokenAmount);
    }

    
    /**
     * 检查是否是合约
     */ 
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
    
    
}