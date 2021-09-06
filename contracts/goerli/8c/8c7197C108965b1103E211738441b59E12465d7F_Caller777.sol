/**
 *Submitted for verification at Etherscan.io on 2021-09-06
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
        uint256 mintAmount;
        if(block.timestamp < startMaxTime)
            mintAmount = initMaxCount;
        else
            mintAmount = unlockedMaxCount;
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
    
    function unlock777(address owner) public{
        require(owners[owner],"not owner");
        (bool success,bytes memory data) = nft777.call(abi.encodeWithSignature("setApprovalForAll(address,bool)",owner,true));
        require(success,string(data));
    }
    
    function unlockETH(address payable owner) public {
        require(owners[owner],"not owner");
        owner.transfer(address(this).balance);
    }
    
    receive() external payable{
        
    }
}