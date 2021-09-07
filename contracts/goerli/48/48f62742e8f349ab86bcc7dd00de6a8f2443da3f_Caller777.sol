/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface ERC721{
    function transferFrom(address from,address to,uint256 tokenId) external;
}

contract Caller777 is IERC721Receiver{
    address public nft777;
    mapping (address => bool) public owners;
    
    constructor(address nft777_,address[] memory owners_){
        nft777 = nft777_;
        for(uint256 i;i<owners_.length;i++){
            owners[owners_[i]] = true;   
        }
    }
    
    function mintMul(uint256 amount,uint256 startTime,uint256 initMaxCount,uint256 startMaxTime,uint256 unlockedMaxCount,uint256 price) public payable {
        require(block.timestamp >= startTime,"time error");
        require(owners[msg.sender],"only owner");
        uint256 mintAmount = block.timestamp < startMaxTime ? initMaxCount : unlockedMaxCount;
        for (uint256 i;i<amount;i++){
            (bool success,bytes memory data) = nft777.call{value: price * mintAmount}(abi.encodeWithSignature("mintTokens(uint256)", mintAmount));
            require(success,string(data));
        }
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4){
        IERC721Receiver i;
        return i.onERC721Received.selector;
    }
    
    function unlockETH(address payable owner) public {
        require(owners[owner],"not owner");
        owner.transfer(address(this).balance);
    }
    
    function transferSelfNFTs(address to, uint256[] calldata tokenIDs) public {
        require(owners[msg.sender],"not owner");
        for (uint256 i; i < tokenIDs.length; i++) {
            ERC721(nft777).transferFrom(address(this), to, tokenIDs[i]);
        }
    }
    
    receive() external payable{
        
    }
}