/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);
    function approve(address spender, uint256 value)
        external
        returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 decimalPlaces);
    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);
    function increaseApproval(address spender, uint256 subtractedValue)
        external;
    function name() external view returns (string memory tokenName);
    function symbol() external view returns (string memory tokenSymbol);
    function totalSupply() external view returns (uint256 totalTokensIssued);
    function transfer(address to, uint256 value)
        external
        returns (bool success);
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}
pragma solidity ^0.8.0;
contract VRFRequestIDBase {
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce))
            );
    }
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}
pragma solidity ^0.8.0;
abstract contract VRFConsumerBase is VRFRequestIDBase {
    function fulfillRandomness(bytes32 requestId, uint256  randomness)
        internal
        virtual;
    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        uint256 vRFSeed = makeVRFInputSeed(
            _keyHash,
            _seed,
            address(this),
            nonces[_keyHash]
        );
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }
    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }
    function rawFulfillRandomness(bytes32 requestId, uint256  randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}
pragma solidity ^0.8.4;
interface IRandomNumberGenerator {
    function getRandomNumber(uint256 _seed) external;
    function viewLatestLotteryId() external view returns (uint256);
    function viewRandomResult() external view returns (uint32);
}
pragma solidity ^0.8.4;
contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    constructor()
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.5 * 10**18;
    }
    function getRandomNumber(uint256 _seed) public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        requestRandomness(keyHash, fee, _seed);
    }
    function expand(uint256 randomValue, uint256 n)
        public
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }
    function rollDice(uint256 userProvidedSeed)
        public
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - fill contract with faucet"
        );
        uint256 seed = uint256(
            keccak256(abi.encode(userProvidedSeed, blockhash(block.number)))
        ); // Hash user seed and blockhash
        return requestRandomness(keyHash, fee, seed);
    }
    function fulfillRandomness(bytes32 requestId, uint256  randomness)
        internal
        override
    {
        randomResult = (randomness % 50) + 1;
    }
       function getDraw(uint256 userProvidedSeed) public returns(uint256[] memory) {
         uint256[] memory draw = new uint256[](5);
         
         for(uint i = 0; i < 5; i++) {
             draw[i] = uint256(rollDice(userProvidedSeed));
         }
         return draw;
    }
}