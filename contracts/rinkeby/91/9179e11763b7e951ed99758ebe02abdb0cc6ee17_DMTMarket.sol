// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title: DMT Market
/// @author: www.sadat.pk

import "./IERC1155Interface.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                          ░░░░░░░░░  ░░░░░░░░░  ░░░░░░░░   ░░░░░░░░               //
//                         ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░              //
//                        ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░         //
//                       ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░        //
//                      ░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░        //
//                   ░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░         //
//                 ░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░            //
//                ░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░           //
//               ░░░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░          //
//                ░░░░░░░░░░░░░ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ ░░░░░░░░░░          //
//                 ░░░░░░░░░░░   ░░░░░░░░░ ░░░░░░░░░  ░░░░░░░░░  ░░░░░░░░░          //
//                    ░░░░░░       ░░░░       ░░░░       ░░░       ░░░░             //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////

contract DMTMarket {
    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => uint256) public balances;

    struct Listing {
    uint256 price;
    address seller;
    }
    function sell(uint256 price, address contractAddr, uint256 tokenId) public {
        IERC1155 token = IERC1155(contractAddr);
        require(token.balanceOf(msg.sender, tokenId) > 0, "caller must own given token");
        require(token.isApprovedForAll(msg.sender, address(this)), "contract not approved");

        listings[contractAddr][tokenId] = Listing(price, msg.sender);
    }
    function buy(address contractAddr, uint256 tokenId, uint256 amount) public payable {
        IERC1155 token = IERC1155(contractAddr);
        Listing memory item = listings[contractAddr][tokenId];
        require(token.balanceOf(item.seller, tokenId) > 0, "sold");
        require(msg.value >= item.price * amount, "insufficient eth");
        balances[item.seller] += msg.value;
        token.safeTransferFrom(item.seller, msg.sender, tokenId, amount, "");
    }
    function withdraw(uint256 amount, address payable destAddr) public {
        require(amount <= balances[msg.sender], "insufficient funds");
        balances[msg.sender] -= amount;
        destAddr.transfer(amount);
    }
}