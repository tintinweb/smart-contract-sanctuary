// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

contract longhu_vrf_polygon is VRFConsumerBase {
    address private owner;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint private cardsCount = 2;

    mapping(bytes32 => reqData) private reqDatas;

    struct reqData {
        string jh;
    }
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    event oracleResponsed(
        bytes32 indexed _jh_hashed,
        string  _jh,
        bytes32  _requestId,
        uint256  _randomResult,
        uint256[]  _cards
    );
    event reqSended(
        bytes32 _requestId
    );

    /**
     * Constructor inherits VRFConsumerBase
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
       58741669393253340326268332937571486087266889818332602468013398455040739414842
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        reqData memory data = reqDatas[requestId];
        bytes memory tempEmptyStringTest = bytes(data.jh);
        require((tempEmptyStringTest).length > 0, "fulfillRandomness callback with wrong requestId");

        uint256[] memory cards = expand(randomness, cardsCount);
        emit oracleResponsed(keccak256(abi.encodePacked(data.jh)), data.jh, requestId, randomness, cards);
    }

    function expand(uint256 randomValue, uint n) private pure returns (uint256[] memory) {
        uint256[] memory cards = new uint256[](n);
        uint256 i = 0; uint256 j = 0;
        while(isExisted(cards, 0)) {
            uint256 expandedValue = uint256(keccak256(abi.encode(randomValue, i)));
            uint256 cardVal = (expandedValue % 52) + 1;
            bool existed = isExisted(cards, cardVal);
            if(!existed) {
                cards[j] = cardVal;
                j++;
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
    
    function randomCards(string memory _jh) public isOwner returns(bytes32) {
        bytes32 requestId = getRandomNumber();
        reqDatas[requestId] = reqData(_jh);
        emit reqSended(requestId);
        return requestId;
    }
}