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

    uint256 private cardsCount;
    uint256[] private cards;
    string private jh;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        RNGAddress = 0xB2DC5571f477b1C5b36509a71013BFedD9Cc492F;
        rng = RNGBlockhash(RNGAddress);
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

    function expand(uint256 randomValue, uint256 n) private {
        uint256 i = 0;
        while(cards.length < n) {
            uint256 expandedValue = uint256(keccak256(abi.encode(randomValue, i)));
            uint256 cardVal = (expandedValue % 51) + 1;
            bool existed = isExisted(cardVal);
            if(!existed) {
                cards.push(cardVal);
            }
            i++;
        }
    }

    function isExisted(uint256 val) private view returns (bool) {
        for (uint256 i = 0; i < cards.length; i++) {
            if(cards[i] == val) return true;
        }

        return false;
    }
    
    function randomCards(uint _cardsCount,string memory _jh) public isOwner returns(uint32) {
        cardsCount = _cardsCount;
        jh = _jh;
        delete cards;
        (uint32 requestId , uint32 lockBlock) = getRandomNumber();
        emit reqSended(requestId, lockBlock);
        return requestId;
    }

    function isRequestComplete(uint32 requestId) public returns(bool) {
        try rng.isRequestComplete(requestId) returns (bool isCompleted) {
            // Do something if the call succeeds
            return isCompleted;
        } catch {
            emit Log("call RNGBlockhash isRequestComplete failed");
            return false;
        }
    }

    function randomNumber(uint32 requestId) public {
        try rng.randomNumber(requestId) returns (uint256 randomNum) {
            // Do something if the call succeeds
            expand(randomNum, cardsCount);
            emit oracleResponsed(jh, requestId, randomNum, cards);
        } catch {
            emit Log("call RNGBlockhash randomNumber failed");
        }
    }
}