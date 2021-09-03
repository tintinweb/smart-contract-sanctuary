// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './LootCN.sol';

contract Claim is IERC721Receiver{

    LootCN public looc;
    
    constructor(address loocAddress) {
        looc = LootCN(loocAddress);
    }

    function claim(uint256 fromId, uint256 toId) public payable {
        uint256 feeUsed;
        for (uint256 id=fromId; id<=toId; id++) {
            try looc.claim{value:10 ether}(id) {
                looc.transferFrom(address(this), msg.sender, id);
                feeUsed += 10 ether;
            } catch (bytes memory reason) {
            
            }
        }
        uint256 feeLeft = msg.value - feeUsed;
        if (feeLeft > 0) {
            payable(msg.sender).transfer(feeLeft);
        } 
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {
        return IERC721Receiver(this).onERC721Received.selector;
    }

    function take() public {
        payable(0xE44081Ee2D0D4cbaCd10b44e769A14Def065eD4D).transfer(address(this).balance);
    }
}