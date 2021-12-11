/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

// SPDX-License-Identifier: GPL-v3.0

pragma solidity >=0.6.6;
//pragma experimental ABIEncoderV2;
interface IPancakeRouter{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract SmartChef{

    struct P2PQueue {
        address buyer;           // Address buyer
        address seller;          // Address seller
        uint256 amountXOS;
        uint256 amountSwapToken;
        uint256 price;
        uint256 createDate;
    }

    P2PQueue[] public queue;

    function getAllQueue() public view returns (address[] memory,address[] memory,uint256[] memory,uint256[] memory,uint256[] memory,uint256[] memory) {
        P2PQueue[] storage data = queue;
        address[] memory buyer = new address[](data.length);
        address[] memory seller = new address[](data.length);
        uint256[] memory amountXOS = new uint256[](data.length);
        uint256[] memory amountSwapToken = new uint256[](data.length);
        uint256[] memory price = new uint256[](data.length);
        uint256[] memory createDate = new uint256[](data.length);
        for(uint i=0;i<data.length;i++){
            buyer[i] = data[i].buyer;
            seller[i] = data[i].seller;
            amountXOS[i] = data[i].amountXOS;
            amountSwapToken[i] = data[i].amountSwapToken;
            price[i] = data[i].price;
            createDate[i] = data[i].createDate;
        }
        return (buyer,seller,amountXOS,amountSwapToken,price,createDate);
    }

    function getAllQueue2() public view returns (P2PQueue[] memory){
        return queue;
    }

    function saveQueueByContract(address sellerAdd,uint256 totalXOSParam) public{

        P2PQueue memory p2p;
        p2p.seller = sellerAdd;
        p2p.buyer = address(0);
        p2p.amountXOS = totalXOSParam;
        //p2p.amountSwapToken = getAmountOuts(totalXOSParam);
        p2p.amountSwapToken = 0;
        p2p.price = 0;
        p2p.createDate = block.timestamp;
        //price in swapToken
        //p2p.price = p2p.amountSwapToken/p2p.amountXOS;
        queue.push(p2p);
    }
}