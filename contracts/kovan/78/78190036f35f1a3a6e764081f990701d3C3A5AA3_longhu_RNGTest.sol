/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract longhu_RNGTest {
    address private owner;
    mapping(uint32=>reqData) public reqDatas;
    uint256 randomNum = 4395695679398248783097225969524184471599276791017852724321654367077722312952;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    struct reqData {
        uint cardsCount;
        string jh;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    event oracleResponsed(
        string indexed _jh,
        uint32  _requestId,
        uint256  _randomResult,
        uint256[]  _cards
    );
    event reqSended(
        uint32 _requestId,
        uint32 _lockBlock
    );
    event Log(string message);

    function expand(uint256 randomValue, uint n) private pure returns (uint256[] memory) {
        uint256[] memory cards = new uint256[](n);
        uint256 i = 0; uint256 j = 0;
        // while(cards.length < n) {
        while(isExisted(cards, 0)) {
            uint256 expandedValue = uint256(keccak256(abi.encode(randomValue, i)));
            uint256 cardVal = (expandedValue % 52) + 1;
            bool existed = isExisted(cards, cardVal);
            if(!existed) {
                cards[j] = cardVal;
                j++;
                // cards.push(cardVal);
            }
            i++;
        }
        return cards;
    }

    function isExisted(uint256[] memory cards, uint256 val) private pure returns (bool) {
        for (uint256 i = 0; i < cards.length; i++) {
            if(cards[i] == val) return true;
        }

        return false;
    }
    
    function emitRandomNumber(uint32 requestId, string memory jh) public isOwner {
        // Do something if the call succeeds
        reqDatas[requestId] = reqData(2,jh);
        reqData memory data = reqDatas[requestId];
        
        uint256[] memory cards = expand(randomNum, data.cardsCount);
        for (uint256 i = 0; i < cards.length; i++) { //之前计算的是1-52 这里扣1 表示0-51
            cards[i] -=1;
        }
        emit oracleResponsed(data.jh, requestId, randomNum, cards);
    
    }
}