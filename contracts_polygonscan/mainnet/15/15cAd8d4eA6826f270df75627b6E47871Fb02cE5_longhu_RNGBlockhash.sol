/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract RNGBlockhash {
    function requestRandomNumber() public returns (uint32 requestId, uint32 lockBlock) {}
    function isRequestComplete(uint32 requestId) public view returns (bool isCompleted) {}
    function randomNumber(uint32 requestId) external returns (uint256 randomNum) {}
}

contract longhu_RNGBlockhash {
    address private RNGAddress;
    RNGBlockhash rng;

    address private owner;

    // uint256 private cardsCount;
    // string private jh;
    // uint256[] private cards;
    mapping(uint32=>reqData) public reqDatas;

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
        RNGAddress = 0xB2DC5571f477b1C5b36509a71013BFedD9Cc492F;
        rng = RNGBlockhash(RNGAddress);
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

    /** 
     * Requests randomness 
     */
    function getRandomNumber() private returns (uint32,uint32)  {
        try rng.requestRandomNumber() returns (uint32 requestId, uint32 lockBlock) {
            // Do something if the call succeeds
            return (requestId,lockBlock);
        } catch {
            emit Log("call RNGBlockhash requestRandomNumber failed");
            return (0,0);
        }
        // (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
        // return (requestId,lockBlock);
        // return (requestId,lockBlock);

        // require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        // requestId = requestRandomness(keyHash, fee);
    }

    function expand(uint256 randomValue, uint256 n) private pure returns (uint256[] memory) {
        uint256[] memory cards;
        uint256 i = 0;
        while(cards.length < n) {
            uint256 expandedValue = uint256(keccak256(abi.encode(randomValue, i)));
            uint256 cardVal = (expandedValue % 51) + 1;
            bool existed = isExisted(cards, cardVal);
            if(!existed) {
                cards[i] = cardVal;
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
    
    function randomCards(uint _cardsCount,string memory _jh) public isOwner returns(uint32) {
        // cardsCount = _cardsCount;
        // jh = _jh;
        // delete cards;
        (uint32 requestId , uint32 lockBlock) = getRandomNumber();
        require(requestId > 0 ,"call RNGBlockhash getRandomNumber failed");
        emit reqSended(requestId, lockBlock);
        reqDatas[requestId] = reqData(_cardsCount, _jh);
        return requestId;
    }

    function isRequestComplete(uint32 requestId) public isOwner returns(bool) {
        try rng.isRequestComplete(requestId) returns (bool isCompleted) {
            // Do something if the call succeeds
            if (isCompleted) {
                emitRandomNumber(requestId);
            } 
            return isCompleted;
        } catch {
            emit Log("call RNGBlockhash isRequestComplete failed");
            return false;
        }
    }

    function emitRandomNumber(uint32 requestId) private isOwner {
        try rng.randomNumber(requestId) returns (uint256 randomNum) {
            // Do something if the call succeeds
            reqData memory data = reqDatas[requestId];
            // bytes memory tempEmptyStringTest = bytes(data.jh);
            // require(tempEmptyStringTest.length > 0, "call emitRandomNumber with wrong requestId");
            // uint256[] memory cards = expand(randomNum, data.cardsCount);
            uint256[] memory cards =  new uint256[](3);
            cards[0] = 10;
            cards[1] = 20;
            emit oracleResponsed(data.jh, requestId, randomNum, cards);
        } catch {
            emit Log("call RNGBlockhash randomNumber failed");
        }
    }
}