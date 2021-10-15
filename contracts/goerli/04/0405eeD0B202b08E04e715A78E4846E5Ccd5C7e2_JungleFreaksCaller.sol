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

    function price() external returns (uint256);
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

    function mintMul(uint256 txAmount, uint256 mintAmount) public onlyOwner {
        uint256 price = IJungleFreaks(jungleFreaks).price();
        for (uint256 i; i < txAmount; i++) {
            (bool s,) = jungleFreaks.call{value : price * mintAmount}(abi.encodeWithSignature("mint(uint256)", mintAmount));
            require(s);
        }
    }

    function unlockETH(address owner) public {
        require(owners[owner], "not owner");
        payable(owner).transfer(address(this).balance);
    }

    function transferSelfNFTs(address to, uint256[] calldata tokenIDs) public onlyOwner {
        for (uint256 i; i < tokenIDs.length; i++) {
            IJungleFreaks(jungleFreaks).transferFrom(address(this), to, tokenIDs[i]);
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

    receive() external payable {

    }

    modifier onlyOwner(){
        require(owners[msg.sender], "not owner");
        _;
    }
}