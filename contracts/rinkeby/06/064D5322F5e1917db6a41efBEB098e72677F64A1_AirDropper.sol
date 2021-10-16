// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.0;

/*  This contract supports minting and sending large amount of tokens
 *  It can be flexibly used to send an amount of tokens in a run, but it should be tested where limits are based on gas restrictions
 *  The using contract has to implement airdropperMint and allowedToken
 */

abstract contract externalInterface{
    function airdropperMint(address to, uint256 tokenId) public virtual;
    function allowedToken(uint256 tokenId) public virtual returns(bool);
}

contract AirDropper{
    externalInterface ext;
    address owner;

    constructor(address _externalContract){
        ext = externalInterface(_externalContract);
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Not owner");
        _;
    }

    function airdrop(address[] memory receivers, uint256 startIndex) public onlyOwner(){
        for (uint8 i = 0; i < receivers.length; i++) {
            require(ext.allowedToken(startIndex + i), "Token not allowed");
            ext.airdropperMint(receivers[i], startIndex + i);
        }
    }

    function airdrop(address[] memory receivers, uint256[] memory indexes) public onlyOwner(){
        require(receivers.length == indexes.length, "Wrong amount");
        for (uint8 i = 0; i < receivers.length; i++) {
            require(ext.allowedToken(indexes[i]), "Token not allowed");
            ext.airdropperMint(receivers[i], indexes[i]);
        }
    }

}