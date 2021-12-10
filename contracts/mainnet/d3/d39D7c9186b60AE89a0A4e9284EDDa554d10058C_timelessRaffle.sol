//SPDX-License-Identifier: MIT

//This contract allows the recovered 33 rare Timeless NFTs to be claimed by 
//a series of addresses that interacted with the NFTSale contract within
//5 minutes of the sale becoming active.
//The raffle and assigning tokenIds to winning addresses is performed offchain
//The raffle algorithm can be verified here: https://treeverse.mypinata.cloud/ipfs/QmWMUb9P5VpQbWZj2GqTjHLFNLFkYJcbX85RAsqBx4YJkm 

pragma solidity 0.8.10;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract timelessRaffle  {

    address public owner;
    address public timelessAddr;
    address public addressHoldingNFTs;

    mapping(uint256 => address) public tokenIdToAddress;
    mapping(uint256 => bool) claimed;
    uint256 public leftUnclaimed;

    constructor() {
        owner = msg.sender;
        timelessAddr = 0x704bf12276f5c4Bc9349d0e119027eAD839b081b;  
        addressHoldingNFTs = 0x229c487eaF50369e1ADA49893A1ECdDD4d513114; 
        leftUnclaimed = 33;
    }

    function updateTokenIdToAddress(address[] calldata winningAddresses, uint256[] calldata timelessIds) external {
        require(msg.sender == owner, "only owner can pull this off");
        require(winningAddresses.length == timelessIds.length, "Two arrays must be of same length");

        for (uint256 i; i < winningAddresses.length; i++) {
            tokenIdToAddress[timelessIds[i]] = winningAddresses[i];
        }
    }

    function changeAddressHoldingNFTs(address _newAddress) external {
         require(msg.sender == owner, "only owner can pull this off");
         addressHoldingNFTs = _newAddress;
    }

    //@dev Prior approval by the "addressHoldingNFTs" of this deployed contract
    // to the Timeless contract is required for all IDs that should be allowed to be exchanged

    function exchangeTimeless(uint256 tokenId) external payable {
        require(tokenIdToAddress[tokenId] == msg.sender, "You are not allowed to buy one!");
        require(claimed[tokenId] == false, "TokenID already claimed!");
        require(msg.value == 0.222 ether, "Please send exactly 0.222 ETH");

        IERC721(timelessAddr).safeTransferFrom(addressHoldingNFTs, msg.sender, tokenId);

        claimed[tokenId] = true;
        leftUnclaimed--;
    }

    function isClaimed(uint256 _tokenId) public view returns (bool) {
        return claimed[_tokenId];
    }

    function getTokenIdForAddress(address addrToCheck, uint256[] calldata tokenIdsUpForclaim) public view returns (uint256) {
        for (uint256 i; i < tokenIdsUpForclaim.length; i++) {
            if (tokenIdToAddress[tokenIdsUpForclaim[i]] == addrToCheck && !isClaimed(tokenIdsUpForclaim[i])) {
                return tokenIdsUpForclaim[i];
            }
        }
        return 0;
    }

    receive() external payable {}
    fallback() external payable {}
   
    function withdrawNativeToken(uint256 amount) external payable {
        require(msg.sender == owner, "only owner can pull this off");

        if (amount > 0) {
            payable(owner).transfer(amount);
        }
        else if (amount <= 0) {
            payable(owner).transfer(address(this).balance);
        }
    } 

}