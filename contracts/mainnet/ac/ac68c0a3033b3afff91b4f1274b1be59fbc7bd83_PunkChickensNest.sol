// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

// just in case functions
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

interface IPunkChickens { 
    function chickensNestMint(address to_, uint mintAmount_) external; 
    function transferFrom(address from_, address to_, uint tokenId_) external;
}

contract PunkChickensNest is Ownable {

    IPunkChickens PunkChickens;

    event MintAsNest(address indexed to, uint indexed amount);
    event ChickenSent(address indexed to, uint indexed tokenId);

    constructor(){ 
    }

    function setPunkChickensAddress(address contractAddress_) external onlyOwner { 
        PunkChickens = IPunkChickens(contractAddress_); 
    }

    function mintAsChickensNest(address to_, uint mintAmount_) external onlyOwner { 
        PunkChickens.chickensNestMint(to_, mintAmount_);
        emit MintAsNest(to_, mintAmount_);
    }
    function sendChicken(address to_, uint tokenId_) external onlyOwner { 
        PunkChickens.transferFrom(address(this), to_, tokenId_); 
        emit ChickenSent(to_, tokenId_);
    }

    /// just-in-case functions
    fallback () external payable {}
    receive () external payable {}

    /// withdrawal functions just in case
    function withdrawERC20(address contractAddress_) external onlyOwner {
        IERC20 _token = IERC20(contractAddress_);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    function withdrawERC721(address contractAddress_, uint tokenId_) external onlyOwner {
        IERC721(contractAddress_).safeTransferFrom(address(this), msg.sender, tokenId_);
    }
    function withdrawERC1155(address contractAddress_, uint tokenId_, uint amount_, bytes memory data_) external onlyOwner {
        IERC1155(contractAddress_).safeTransferFrom(address(this), msg.sender, tokenId_, amount_, data_);
    }
}