// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IEGG {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ICryptoPunk {
    function transferPunk(address to, uint256 punkIndex) external;
}

interface ILink is IERC20 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);
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
    uint256 private randomNumber = 0;
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
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA // LINK Token
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
        randomNumber = 0;
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
        randomNumber = randomness;
    }

    function checkRandomNumber()
        external
        view
        onlyDistributer
        returns (uint256)
    {
        if (progress) return 0;
        return randomNumber;
    }
}

contract Creature is ERC721, Ownable {
    using SafeMath for uint256;

    RandomNumberConsumer public rnGenerator;
    uint256 public _randomCallCount = 0;
    uint256 public _prevRandomCallCount = 0;

    uint256 public _punkRandomIndex1 = 6500;
    uint256 public _punkRandomIndex2 = 6500;
    uint256 public _creatureStartIndex = 6500;

    string public APYMON_MONSTER_PROVENANCE = "";

    bool public hasMintStarted = false;
    IEGG public _iEgg;

    bool public _punkDistributed1 = false;
    bool public _punkDistributed2 = false;
    uint16[] private _indexArray1;
    uint16[] private _indexArray2;
    uint16 public _initializedCount1 = 0;
    uint16 public _initializedCount2 = 0;

    // Mapping from egg ID -> minted
    mapping(uint256 => bool) public _minted;

    event WithdrawPunk(address indexed owner, uint256 id);

    ICryptoPunk public _cryptoPunk =
        ICryptoPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    constructor() ERC721("Apymon Monsters", "APYM") {
        rnGenerator = new RandomNumberConsumer(address(this));
        _iEgg = IEGG(0x9C008A22D71B6182029b694B0311486e4C0e53DB);
    }

    function initialize1(uint16 count) external onlyOwner {
        require(count > 0, "count should be greater than 0.");
        uint16 endIndex =
            _initializedCount1 + count > 6400
                ? 6400
                : _initializedCount1 + count;
        for (uint16 i = _initializedCount1; i < endIndex; i++)
            _indexArray1.push(i);
        _initializedCount1 = endIndex;
    }

    function initialize2(uint16 count) external onlyOwner {
        require(count > 0, "count should be greater than 0.");
        uint16 endIndex =
            _initializedCount2 + count > 400 ? 400 : _initializedCount2 + count;
        for (uint16 i = _initializedCount2; i < endIndex; i++)
            _indexArray2.push(i);
        _initializedCount2 = endIndex;
    }

    function getCreatureStartIndexByVRF() external onlyOwner {
        rnGenerator.getRandomNumber(_randomCallCount);
        _randomCallCount = _randomCallCount + 1;
    }

    function setCreatureStartIndex() external onlyOwner {
        require(_creatureStartIndex == 6500, "start index was already set.");
        require(
            _prevRandomCallCount != _randomCallCount,
            "Please generate random number."
        );
        require(
            rnGenerator.checkRandomNumber() != 0,
            "Please wait until random number generated."
        );

        _prevRandomCallCount = _randomCallCount;
        _creatureStartIndex = rnGenerator.checkRandomNumber().mod(6400);
    }

    function getRandomNumberByVRF() external onlyOwner {
        rnGenerator.getRandomNumber(_randomCallCount);
        _randomCallCount = _randomCallCount + 1;
    }

    function pickPunkRandomIndex() external onlyOwner {
        require(
            _punkRandomIndex1 == 6500 || _punkRandomIndex2 == 6500,
            "You already picked all punk random index."
        );
        require(
            _prevRandomCallCount != _randomCallCount,
            "Please generate random number."
        );
        require(
            rnGenerator.checkRandomNumber() != 0,
            "Please wait until random number generated."
        );

        _prevRandomCallCount = _randomCallCount;
        uint256 randomNumber = rnGenerator.checkRandomNumber();

        if (_punkRandomIndex1 == 6500)
            _punkRandomIndex1 = randomNumber.mod(6400);
        else _punkRandomIndex2 = randomNumber.mod(400);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        APYMON_MONSTER_PROVENANCE = _provenance;
    }

    function givePunk(address to, uint256 punkId) internal {
        require(punkId > 0, "Invalid punk id");

        _cryptoPunk.transferPunk(to, punkId);
        emit WithdrawPunk(to, punkId);
    }

    function getRandomNumber() private view returns (uint256) {
        uint256 randomNumber =
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number),
                        block.timestamp,
                        block.number,
                        block.difficulty,
                        block.gaslimit,
                        msg.sender,
                        totalSupply()
                    )
                )
            );
        return randomNumber;
    }

    function mintCreature(uint256 eggId) external {
        require(hasMintStarted, "Minting hasn't started.");

        require(_iEgg.ownerOf(eggId) == msg.sender, "Invalid minter.");

        require(!_minted[eggId], "Already minted for this egg id.");

        _minted[eggId] = true;

        if (!_punkDistributed1 || !_punkDistributed2) {
            uint256 randomNumber = getRandomNumber();

            if (!_punkDistributed1) {
                uint256 index1 = randomNumber.mod(_indexArray1.length);
                if (_indexArray1[index1] == _punkRandomIndex1) {
                    givePunk(msg.sender, 7207);
                    _punkDistributed1 = true;
                }

                _indexArray1[index1] = _indexArray1[_indexArray1.length - 1];
                _indexArray1.pop();
            }

            if (!_punkDistributed2 && eggId >= 6000) {
                uint256 index2 = randomNumber.mod(_indexArray2.length);
                if (_indexArray2[index2] == _punkRandomIndex2) {
                    givePunk(msg.sender, 7006);
                    _punkDistributed2 = true;
                }
                _indexArray2[index2] = _indexArray2[_indexArray2.length - 1];
                _indexArray2.pop();
            }
        }

        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function startMint() public onlyOwner {
        require(
            _initializedCount1 == 6400 && _initializedCount2 == 400,
            "Please initialize all."
        );
        hasMintStarted = true;
    }

    function pauseMint() public onlyOwner {
        hasMintStarted = false;
    }

    function withdrawPunkToOwner(uint256 id) external onlyOwner {
        givePunk(owner(), id);
    }
}