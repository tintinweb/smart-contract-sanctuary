// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC165.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Context.sol";

interface ILink is IERC20 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);
}

interface IApymonPack {
    function depositErc1155IntoEgg(
        uint256 eggId,
        address token,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    function isOpened(uint256 eggId) external view returns (bool);
}

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

abstract contract VRFConsumerBase is VRFRequestIDBase {
    using SafeMath for uint256;

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual;

    function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee,
        uint256 _seed
    ) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        uint256 vRFSeed =
            makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;

    address private immutable vrfCoordinator;
    /* keyHash */
    /* nonce */
    mapping(bytes32 => uint256) private nonces;

    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
    {
        require(
            msg.sender == vrfCoordinator,
            "Only VRFCoordinator can fulfill"
        );
        fulfillRandomness(requestId, randomness);
    }
}

contract RandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    bool private progress = false;
    uint256 private winner = 0;
    address private distributer;

    modifier onlyDistributer() {
        require(distributer == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Mainnet
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     */
    constructor(address _distributer)
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10**18; // 2 LINK
        distributer = _distributer;
    }

    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed)
        public
        onlyDistributer
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        require(!progress, "now getting an random number.");
        winner = 0;
        progress = true;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        requestId = 0;
        progress = false;
        winner = randomness;
    }

    function getWinner() external view onlyDistributer returns (uint256) {
        if(progress)
            return 0;
        return winner;
    }
}

contract Distribution is ERC165, IERC1155Receiver, Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    RandomNumberConsumer public rnGenerator;

    IApymonPack public _apymonPack =
        IApymonPack(0x3dFCB488F6e96654e827Ab2aB10a463B9927d4f9);

    uint256 public _randomCallCount = 0;
    uint256 public _prevRandomCallCount = 0;

    event WithdrawERC1155(
        address indexed owner,
        address indexed token,
        uint256 tokenId,
        uint256 amount
    );

    constructor() {
        rnGenerator = new RandomNumberConsumer(address(this));
    }

    function getRandomNumber() external onlyOwner {
        rnGenerator.getRandomNumber(_randomCallCount);
        _randomCallCount = _randomCallCount + 1;
    }

    // Function to distribute ERC1155 token prizes.
    function distributeERC1155Token(address token, uint256 tokenId, uint256 amount)
        external
        onlyOwner
    {
        require(token != address(0));
        require(
            _prevRandomCallCount != _randomCallCount,
            "Please generate random number."
        );
        require(
            rnGenerator.getWinner() != 0,
            "Please wait until random number generated."
        );

        _prevRandomCallCount = _randomCallCount;

        uint256 eggId = rnGenerator.getWinner().mod(6400);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = tokenId;
        amounts[0] = amount;

        IERC1155(token).setApprovalForAll(address(_apymonPack), true);
        _apymonPack.depositErc1155IntoEgg(eggId, token, tokenIds, amounts);
    }

    function withdrawERC1155ToOwner(address token, uint256 tokenId, uint256 amount)
        external
        onlyOwner
    {

        IERC1155(token).safeTransferFrom(address(this), owner(), tokenId, amount, bytes(""));
        emit WithdrawERC1155(owner(), token, tokenId, amount);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}