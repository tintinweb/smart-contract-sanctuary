pragma solidity 0.8.2;

contract Hohoho{

receive() external payable {}
fallback() external payable {}

function huhuhu(address payable _receipt) public payable {
_receipt.transfer(msg.value);
}

function PermitForBid(address owner,address spender,uint256 amount,address nftToken,uint256 tokenId,uint256 nonce) external {
        
    }

}