/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT
// DecentAPI - 2021
pragma solidity >= 0.5.16 < 0.9.0;
  
contract NFT_Asset_Response {

    address admin;
    mapping (address => uint) index;
    address[] allowedAddresses;
    

    constructor()  {
        admin = msg.sender;
    }

    function addAllowed(address _allowedAddress) external {
        if (msg.sender != admin) {
            revert('wrong owner, cant add');
        }
        
        if (!isAllowed(_allowedAddress)) {
            index[_allowedAddress] = allowedAddresses.length;
            allowedAddresses.push(_allowedAddress);
        }

    }
    
    function isAllowed(address _uA) public view returns (bool) {
        
        if (index[_uA] > 0) {
            return true;
        }
        return false;
    }

    event nftAssetData(
        string sender_address,
        string asset_info_on_ipfs,
        string image_original_on_ipfs,
        string animation_original_on_ipfs  
    );

    function emitNftAssetData(
        string calldata _sender_address,
        string calldata _asset_info_on_ipfs,
        string calldata _image_original_on_ipfs,
        string calldata _animation_original_on_ipfs      
        ) external {

        if (!isAllowed(msg.sender)) {
        revert('wrong address, cant emit');
        }

        emit nftAssetData(
            _sender_address, 
            _asset_info_on_ipfs,
            _image_original_on_ipfs,
            _animation_original_on_ipfs
  
            );



    }

    


}