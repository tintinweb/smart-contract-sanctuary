// https://testnet.ftmscan.com/address/0xd90db5d6d58e9d028fd1ac1fe271478a1911849c#code
//0x82222bD9579800Befaa92757D1E43e9d4EBFbA9d   NFTaddress

pragma solidity 0.8.7;

import "./mms.sol";

// interface IERC721Receiver {
//     function onERC721Received(address operator,address from,uint256 tokenId, bytes calldata data) external returns (bytes4);
// }

contract mmsOperate is IERC721Receiver{
    address addressOwner;
    ERC721 nftContract = ERC721(0x2D2f7462197d4cfEB6491e254a16D3fb2d2030EE);
    Monster monsterContract = Monster(0x2D2f7462197d4cfEB6491e254a16D3fb2d2030EE);
    constructor() {
        addressOwner = msg.sender;
        nftContract.setApprovalForAll(msg.sender,true);
    }
    

    function mintNFT(uint256 tokenId) public payable{
        monsterContract.claim{value:msg.value}();
        require(nftContract.ownerOf(tokenId) == address(this),"failed claim this NFT for you");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns(bytes4) {
        return this.onERC721Received.selector;
    }
}