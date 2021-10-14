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

interface IJungleFreaks {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract JungleFreaksCaller is IERC721Receiver {
    address public jungleFreaks;
    mapping(address => bool) public owners;

    constructor(address jungleFreaks_, address[] memory owners_){
        jungleFreaks = jungleFreaks_;
        for (uint256 i; i < owners_.length; i++) {
            owners[owners_[i]] = true;
        }
    }

    function mintMul(uint256 txAmount, uint256 mintAmount, uint256 price) public {
        require(owners[msg.sender], "only owner");
        for (uint256 i; i < txAmount; i++) {
            (bool success,bytes memory data) = jungleFreaks.call{value : price * mintAmount}(abi.encodeWithSignature("mint(uint256)", mintAmount));
            require(success, string(data));
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
        require(owners[owner], "not owner");
        owner.transfer(address(this).balance);
    }

    function transferSelfNFTs(address to, uint256[] calldata tokenIDs) public {
        require(owners[msg.sender], "not owner");
        for (uint256 i; i < tokenIDs.length; i++) {
            IJungleFreaks(jungleFreaks).transferFrom(address(this), to, tokenIDs[i]);
        }
    }

    receive() external payable {

    }
}