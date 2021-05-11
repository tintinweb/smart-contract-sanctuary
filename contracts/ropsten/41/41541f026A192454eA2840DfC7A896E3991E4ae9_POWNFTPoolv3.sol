/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-XX-XX
*/

// SPDX-License-Identifier: This smart contract is guarded by an angry ghost

pragma solidity ^0.8.0;


contract POWNFTPoolv3 {
    
    address POWNFT = 0x88066567a7F90409Ced36D4030C47909Eb910926;
    
    address[] STATIC_OWNERS = [0xD59aFC841f3e78130B7bCF488A67134C5b8e6eFF,0xc2E4E94cb74E24342F10aa10673f510c7998D134,0x2a670aB4C73594D68f91256B9F114a4cAe3f5216,0x4EB6BCF7312E8e87EE9f631842c8E710B4B641CD];
    
    constructor(){
        supportedInterfaces[0x150b7a02] = true; //ERC721TokenReceiver
    }
    event RewardReceived(uint indexed _tokenId);
    event Debug(uint _msg);
    uint256[] TOKENS; //Array of all tokens [tokenId,tokenId,...]
    mapping (uint256 => mapping (address => uint)) internal TOKEN_OWNERS_SHARE; //Mapping of owners share
    mapping (uint256 => address[]) internal TOKEN_OWNERS; //Mapping of owners share
    mapping (uint256 => bytes) internal TOKENS_DATA; //Mapping of Token data
    //////===721TokenReceiver Implementation
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4){
        require(_from == POWNFT, "Not from POWNFTv3."); //&& 
                    //(msg.sender == POWNFT));
        //require(tokenExists(_tokenId));
        require(_operator == address(this));
        TOKENS.push(_tokenId);
        TOKENS_DATA[_tokenId] = _data;
        TOKEN_OWNERS[_tokenId] = STATIC_OWNERS;
        
        for (uint i = 0; i < STATIC_OWNERS.length; i++) {
            //Equal share for now 
            TOKEN_OWNERS_SHARE[_tokenId][STATIC_OWNERS[i]] = (100/STATIC_OWNERS.length)*100;
        }

        
        //OWNERS_SHARE[_tokenId][_operator] = 100;
        emit RewardReceived(_tokenId);
        //return bytes4(keccak256(abi.encodePacked(_operator,_from,_tokenId,_data)));
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
    //==End 721TokenReceiver Implementation
    
    // ENUMERABLE FUNCTIONS
    function totalSupply() external view returns (uint256){
        return TOKENS.length;
    }
    
    ///////===165 Implementation
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    ///==End 165
}