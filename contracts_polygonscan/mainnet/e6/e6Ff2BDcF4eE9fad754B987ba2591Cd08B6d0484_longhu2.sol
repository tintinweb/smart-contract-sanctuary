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
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
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