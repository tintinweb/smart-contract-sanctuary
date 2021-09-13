// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

contract longhu2 is VRFConsumerBase {
    address private owner;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 private cardsCount;
    uint256[] private cards;
    string private jh;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    event oracleResponsed(
        string indexed _jh,
        bytes32  _requestId,
        uint256  _randomResult,
        uint256[]  _cards
    );
    event reqSended(
        bytes32 _requestId
    );

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK

         owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    /** 
     * Requests randomness 
     */
    function getRandomNumber() private returns (bytes32 requestId)  {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        requestId = requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        expand(randomness, cardsCount);
        emit oracleResponsed(jh, requestId, randomness, cards);
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
    
    function randomCards(uint _cardsCount,string memory _jh) public isOwner {
        cardsCount = _cardsCount;
        jh = _jh;
        delete cards;
        bytes32 requestId = getRandomNumber();
        emit reqSended(requestId);
    }
}