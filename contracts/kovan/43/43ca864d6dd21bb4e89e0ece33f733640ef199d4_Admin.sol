/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
 
contract Admin{
    
    function createNfts(address _nftTokenAddress, string memory _nftName, uint256 _nftIdStart, 
                        uint256 _nftIdEnd, address _initialOwner, bytes memory _data) 
                        public returns (bytes memory){
        for (uint256 i=_nftIdStart; i<(_nftIdEnd-_nftIdStart+1); i++) {
            string memory _uri = _nftName;
            uint256 _initialSupply = 1;
            uint256 _cap = 2;
            (bool success, bytes memory returndata) 
            = address(_nftTokenAddress).call(abi.encodeWithSignature("create(address,uint256,uint256,string memory,bytes memory)", _initialOwner,_initialSupply,_cap,_uri,_data));
        
        }
        //if (!success)
            //revert();
        //return returndata;
    }
    
 
    
     
}