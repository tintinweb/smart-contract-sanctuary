/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

/*
 
          _       _________ _______           _______ 
|\     /|( (    /|\__   __/(  ___  )|\     /|(  ____ \
| )   ( ||  \  ( |   ) (   | (   ) || )   ( || (    \/
| |   | ||   \ | |   | |   | |   | || |   | || (__    
| |   | || (\ \) |   | |   | |   | || |   | ||  __)   
| |   | || | \   |   | |   | | /\| || |   | || (      
| (___) || )  \  |___) (___| (_\ \ || (___) || (____/\
(_______)|/    )_)\_______/(____\/_)(_______)(_______/
                                                      
 _______  _        _______ 
(  ___  )( (    /|(  ____ \
| (   ) ||  \  ( || (    \/
| |   | ||   \ | || (__    
| |   | || (\ \) ||  __)   
| |   | || | \   || (      
| (___) || )  \  || (____/\
(_______)|/    )_)(_______/
 
 
 https://unique.one
 
*/

pragma solidity ^0.5.0;

contract Support {
    function generateBytes(address add, uint256 id) public pure returns (bytes memory) {
        bytes memory mesageByte = abi.encodePacked(add, id);
        return mesageByte;
    }

    function generateBytesForString(string memory message) public pure returns (bytes memory) {
        bytes memory mesageByte = abi.encodePacked(message);
        return mesageByte;
    }

    function generateBytesForPermissioned(address contractAdd, uint256 id, address userWallet) public pure returns (bytes memory) {
        bytes memory mesageByte = abi.encodePacked(contractAdd, id, userWallet);
        return mesageByte;
    }

    function generateBytesAuction(address erc721Token, uint256 tokenId, address seller, address buyer, address erc20Token, uint256 bid, string memory start, string memory end, uint256 nonce) public pure returns (bytes memory) {
        return abi.encodePacked(erc721Token, tokenId, seller, buyer, erc20Token, bid, start, end, nonce);
    }
}