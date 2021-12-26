// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./IERC1155_EXT.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ReentrancyGuard.sol";

contract OpenTreasure is
    VRFConsumerBase,
    ERC1155,
    Ownable,
    IERC1155Receiver,
    ReentrancyGuard
{
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    IERC1155_EXT public nft;

    uint256 public platformFee = 5000000000000000;
    address private feeCollector;
    bool public feeStatus = true;

    uint256[] private commonRewards;
    uint256[] private uncommonRewards;
    uint256[] private rareRewards;
    uint256[] private extremelyRareRewards;
    uint256[] private legendaryRewards;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 private randomResult;
    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => uint256) public requestIdToRequestNumberIndex;
    mapping(uint256 => address) public requestNumberToId;
    mapping(address => bool) public mintProgress;
    mapping(uint256 => bool) private validKeyId;
    mapping(uint256 => bool) private validChestId;
    mapping(uint256 => bool) private validYARLTokenId;
    mapping(uint256 => uint256) private yarlRewardExchange;

    uint256 public requestCounter;
    uint256 public fulfilledCounter;

    event MintTreasure(
        address _owner,
        uint256 _amount,
        string _hash,
        uint256 _tokenID
    );

    event ChestOpened(uint256 _tokenId, address _to);

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: BSC Mainnet
     * Chainlink VRF Coordinator address: 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31
     * LINK token address:                0x404460C6A5EdE2D891e8297795264fDe62ADBB75
     * Key Hash: 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c
     * Fee :     0.2 * 10 ** 18 //0.2 LINK
     *
     *
     * Network: BSC Testnet
     * Chainlink VRF Coordinator address: 0xa555fC018435bef5A13C6c6870a9d4C11DEC329C
     * LINK token address:                0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
     * Key Hash: 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186
     * Fee :     0.1 * 10 ** 18 //0.1 LINK
     */
    constructor(address _nftAddress)
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06 // LINK Token
        )
        ERC1155("https://ipfs.io/ipfs/")
    {
        keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        fee = 0.1 * 10**18;
        require(
            _nftAddress.isContract() &&
                _nftAddress != address(0) &&
                _nftAddress != address(this)
        );
        nft = IERC1155_EXT(_nftAddress);
    }

    modifier nonZeroAddress(address _to) {
        require(_to != address(0), "Address should not be address 0");
        _;
    }

    function toggleFeeStatus() external onlyOwner returns (bool success) {
        if (feeStatus) {
            feeStatus = false;
        } else {
            feeStatus = true;
        }
        return feeStatus;
    }

    function openTreasureChest(uint256 _keyTokenId, uint256 _chestTokenId)
        public
        payable
        nonReentrant
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(validKeyId[_keyTokenId], "Not a Valid Key Token ID");
        require(validChestId[_chestTokenId], "Not a Valid Chest Token ID");

        require(
            nft.ownerOf(msg.sender, _keyTokenId),
            "Only Key Owner can open the Chest"
        );
        require(
            nft.balanceOf(msg.sender, _keyTokenId) > 0,
            "You Dont have a key to open chest"
        );
        require(
            nft.balanceOf(msg.sender, _chestTokenId) > 0,
            "You Dont have a chest to open"
        );

        if (feeStatus) {
            require(msg.value == platformFee, "Fee value Not correct");
            (bool success, ) = payable(feeCollector).call{value: msg.value}("");
            require(success, "Fee Transfer failed.");
        }

        nft.safeTransferFrom(msg.sender, address(this), _chestTokenId, 1, "0x");
        nft.safeTransferFrom(msg.sender, address(this), _keyTokenId, 1, "0x");

        requestId = requestRandomness(keyHash, fee);
        requestIdToAddress[requestId] = msg.sender;
        requestIdToRequestNumberIndex[requestId] = requestCounter;
        requestCounter += 1;
        mintProgress[msg.sender] = true;
    }

    function drawNft(
        uint256 _tokenID,
        address _to,
        uint256 _quantity
    ) external onlyOwner {
        nft.safeTransferFrom(address(this), _to, _tokenID, _quantity, "0x");
    }

    function burnNft(uint256 _tokenID, uint256 _quantity) external onlyOwner {
        nft.safeTransferFrom(
            address(this),
            address(0),
            _tokenID,
            _quantity,
            "0x"
        );
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness.mod(255).add(1);
        address requestAddress = requestIdToAddress[requestId];
        uint256 requestNumber = requestIdToRequestNumberIndex[requestId];
        requestNumberToId[requestNumber] = requestAddress;
        uint256 tokenId = randomRewardsTokenID(randomResult);
        if (nft.balanceOf(address(this), tokenId) > 0) {
            nft.safeTransferFrom(
                address(this),
                requestAddress,
                tokenId,
                1,
                "0x"
            );
        } else {
            tokenId = commonRewards[randomResult.mod(commonRewards.length)];
            nft.safeTransferFrom(
                address(this),
                requestAddress,
                tokenId,
                1,
                "0x"
            );
        }
        emit ChestOpened(tokenId, requestAddress);
        fulfilledCounter += 1;
        mintProgress[requestAddress] = false;
    }

    function randomRewardsTokenID(uint256 _randomResult)
        internal
        view
        returns (uint256 tokenId)
    {
        // 1- commonRewards 2- uncommonRewards 3- rareRewards 4- extremelyRareRewards 5- legendaryRewards
        uint256 randomLength;
        uint256 totalChance = 256;
        if (_randomResult < 100) {
            randomLength = randomResult.mod(commonRewards.length);
            tokenId = commonRewards[randomLength];
        } else if (_randomResult > 100 && _randomResult < 200) {
            randomLength = randomResult.mod(uncommonRewards.length);
            tokenId = uncommonRewards[randomLength];
        } else if (_randomResult > 200 && _randomResult < 250) {
            randomLength = randomResult.mod(rareRewards.length);
            tokenId = rareRewards[randomLength];
        } else if (_randomResult == (totalChance / 2)) {
            randomLength = randomResult.mod(legendaryRewards.length);
            tokenId = legendaryRewards[randomLength];
        } else {
            randomLength = randomResult.mod(extremelyRareRewards.length);
            tokenId = extremelyRareRewards[randomLength];
        }
    }

    function withdrawToken(address _tokenAddress)
        external
        onlyOwner
        nonReentrant
        returns (bool)
    {
        require(_tokenAddress != address(0), "Should be a valid Address");
        require(
            IERC20(_tokenAddress).balanceOf(address(this)) > 0,
            "Not enough balance of the token mentioned"
        );
        require(
            IERC20(_tokenAddress).transfer(
                msg.sender,
                IERC20(_tokenAddress).balanceOf(address(this))
            ),
            "Transfer Failed"
        );
        return true;
    }

    function rescueBnb(address payable beneficiary)
        external
        nonReentrant
        nonZeroAddress(beneficiary)
        onlyOwner
    {
        require(address(this).balance > 0, "No Crypto inside contract");
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addRewards(uint256 selector, uint256 tokenId)
        external
        onlyOwner
        returns (bool)
    {
        //Selector: 1- commonRewards 2- uncommonRewards 3- rareRewards 4- extremelyRareRewards 5- legendaryRewards
        require(
            selector == 1 ||
                selector == 2 ||
                selector == 3 ||
                selector == 4 ||
                selector == 5,
            "Wrong Reward Pool Selected"
        );

        if (selector == 1) {
            commonRewards.push(tokenId);
        } else if (selector == 2) {
            uncommonRewards.push(tokenId);
        } else if (selector == 3) {
            rareRewards.push(tokenId);
        } else if (selector == 4) {
            extremelyRareRewards.push(tokenId);
        } else if (selector == 5) {
            legendaryRewards.push(tokenId);
        }

        return true;
    }

    function removeRewards(uint256 selector, uint256 index)
        external
        onlyOwner
        returns (bool)
    {
        //Selector: 1- commonRewards 2- uncommonRewards 3- rareRewards 4- extremelyRareRewards 5- legendaryRewards
        require(
            selector == 1 ||
                selector == 2 ||
                selector == 3 ||
                selector == 4 ||
                selector == 5,
            "Wrong Reward Pool Selected"
        );

        if (selector == 1) {
            require(index < commonRewards.length);
            commonRewards[index] = commonRewards[commonRewards.length - 1];
            commonRewards.pop();
        } else if (selector == 2) {
            require(index < uncommonRewards.length);
            uncommonRewards[index] = uncommonRewards[
                uncommonRewards.length - 1
            ];
            uncommonRewards.pop();
        } else if (selector == 3) {
            require(index < rareRewards.length);
            rareRewards[index] = rareRewards[rareRewards.length - 1];
            rareRewards.pop();
        } else if (selector == 4) {
            require(index < extremelyRareRewards.length);
            extremelyRareRewards[index] = extremelyRareRewards[
                extremelyRareRewards.length - 1
            ];
            extremelyRareRewards.pop();
        } else if (selector == 5) {
            require(index < legendaryRewards.length);
            legendaryRewards[index] = legendaryRewards[
                legendaryRewards.length - 1
            ];
            legendaryRewards.pop();
        }
        return true;
    }

    function viewRewards()
        public
        view
        onlyOwner
        returns (
            uint256[] memory _commonRewards,
            uint256[] memory _uncommonRewards,
            uint256[] memory _rareRewards,
            uint256[] memory _extremelyRareRewards,
            uint256[] memory _legendaryRewards
        )
    {
        return (
            commonRewards,
            uncommonRewards,
            rareRewards,
            extremelyRareRewards,
            legendaryRewards
        );
    }

    function addValidKeyId(uint256 _tokenId, bool _status) external onlyOwner {
        validKeyId[_tokenId] = _status;
    }

    function checkValidKeyId(uint256 _tokenId)
        public
        view
        onlyOwner
        returns (bool)
    {
        return validKeyId[_tokenId];
    }

    function addValidYARLTokenId(
        uint256 _tokenId,
        uint256 _yarlValue,
        bool _status
    ) external onlyOwner {
        validYARLTokenId[_tokenId] = _status;
        yarlRewardExchange[_tokenId] = _yarlValue;
    }

    function changeFeeCollector(address _newFeeCollector)
        external
        onlyOwner
        returns (bool)
    {
        feeCollector = _newFeeCollector;
        return true;
    }

    function changePlatformFee(uint256 _newPlatformFee)
        external
        onlyOwner
        returns (bool)
    {
        platformFee = _newPlatformFee;
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        //Not allowed
        // return "";
        revert();
    }
}