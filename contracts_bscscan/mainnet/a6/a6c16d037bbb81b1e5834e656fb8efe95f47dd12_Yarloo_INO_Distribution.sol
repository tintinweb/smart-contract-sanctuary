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

contract Yarloo_INO_Distribution is
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

    uint256[] public petty;
    uint256[] public bronze;
    uint256[] public silver;
    uint256[] public gold;
    uint256[] public sapphire;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 private randomResult;
    mapping(bytes32 => address) public requestIdToAddress;
    mapping(bytes32 => uint256) public requestIdToRequestNumberIndex;
    mapping(bytes32 => uint256) public requestIdToType;
    mapping(bytes32 => uint256) public requestIdToAmount;
    mapping(uint256 => address) public requestNumberToId;
    mapping(address => bool) public mintProgress;

    uint256 public requestCounter;
    uint256 public fulfilledCounter;

    event NftDistributed(uint256 _tokenId, address _to);

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
            0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, // VRF Coordinator
            0x404460C6A5EdE2D891e8297795264fDe62ADBB75 // LINK Token
        )
        ERC1155("https://ipfs.io/ipfs/")
    {
        keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
        fee = 0.2 * 10**18;
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

    function distributeIno(
        address _userAddress,
        uint256 _type,
        uint256 _amount
    ) public onlyOwner nonReentrant returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        require(_type == 1 || _type == 2 || _type == 3, "Wrong type selection");
        requestId = requestRandomness(keyHash, fee);
        requestIdToAddress[requestId] = _userAddress;
        requestIdToRequestNumberIndex[requestId] = requestCounter;
        requestIdToType[requestId] = _type;
        requestIdToAmount[requestId] = _amount;
        requestCounter += 1;
        mintProgress[_userAddress] = true;
    }

    function distributeMultiIno(
        address[] memory _userAddress,
        uint256 _type,
        uint256[] memory _amount
    ) public onlyOwner nonReentrant returns (bytes32 requestId) {
        require(_userAddress.length == _amount.length, "Length not equal");
        for (uint256 i = 0; i < _userAddress.length; i++) {
            require(
                LINK.balanceOf(address(this)) >= fee,
                "Not enough LINK - fill contract with faucet"
            );
            require(
                _type == 1 || _type == 2 || _type == 3,
                "Wrong type selection"
            );
            requestId = requestRandomness(keyHash, fee);
            requestIdToAddress[requestId] = _userAddress[i];
            requestIdToRequestNumberIndex[requestId] = requestCounter;
            requestIdToType[requestId] = _type;
            requestIdToAmount[requestId] = _amount[i];
            requestCounter += 1;
            mintProgress[_userAddress[i]] = true;
        }
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

    function addNft(uint256 _tokenID, uint256 _quantity) external onlyOwner {
        nft.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenID,
            _quantity,
            "0x"
        );
    }

    function expand(uint256 randomValue, uint256 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)))
                .mod(255)
                .add(1);
        }
        return expandedValues;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness.mod(255).add(1);
        address requestAddress = requestIdToAddress[requestId];
        uint256 requestNumber = requestIdToRequestNumberIndex[requestId];
        uint256 typeRequest = requestIdToType[requestId];
        uint256 totalAmount = requestIdToAmount[requestId];
        requestNumberToId[requestNumber] = requestAddress;
        uint256 tokenId;
        uint256[] memory randomSeries = expand(randomness, 5);
        if (typeRequest == 1) {
            for (uint256 i = 0; i < totalAmount; i++) {
                for (uint256 j = 0; j < 5; j++) {
                    tokenId = randomRewardsBronze(randomSeries[i]);
                    nft.safeTransferFrom(
                        address(this),
                        requestAddress,
                        tokenId,
                        1,
                        "0x"
                    );
                    emit NftDistributed(tokenId, requestAddress);
                }
            }
        } else if (typeRequest == 2) {
            for (uint256 i = 0; i < totalAmount; i++) {
                for (uint256 j = 0; j < 5; j++) {
                    tokenId = randomRewardsSilver(randomSeries[i]);
                    nft.safeTransferFrom(
                        address(this),
                        requestAddress,
                        tokenId,
                        1,
                        "0x"
                    );
                    emit NftDistributed(tokenId, requestAddress);
                }
            }
        } else if (typeRequest == 3) {
            for (uint256 i = 0; i < totalAmount; i++) {
                for (uint256 j = 0; j < 5; j++) {
                    tokenId = randomRewardsGold(randomSeries[i]);
                    nft.safeTransferFrom(
                        address(this),
                        requestAddress,
                        tokenId,
                        1,
                        "0x"
                    );
                    emit NftDistributed(tokenId, requestAddress);
                }
            }
        }

        fulfilledCounter += 1;
        mintProgress[requestAddress] = false;
    }

    function randomRewardsBronze(uint256 _randomResult)
        internal
        view
        returns (uint256 tokenId)
    {
        // 1- petty 2- bronze 3- silver 4- gold 5- sapphire
        uint256 randomLength;
        uint256 totalChance = 256;
        if (_randomResult < 150) {
            randomLength = randomResult.mod(petty.length);
            tokenId = petty[randomLength];
        } else if (_randomResult > 150 && _randomResult < 200) {
            randomLength = randomResult.mod(bronze.length);
            tokenId = bronze[randomLength];
        } else if (_randomResult > 200 && _randomResult < 240) {
            randomLength = randomResult.mod(silver.length);
            tokenId = silver[randomLength];
        } else if (_randomResult == (totalChance / 2)) {
            randomLength = randomResult.mod(sapphire.length);
            tokenId = sapphire[randomLength];
        } else {
            randomLength = randomResult.mod(gold.length);
            tokenId = gold[randomLength];
        }
    }

    function randomRewardsSilver(uint256 _randomResult)
        internal
        view
        returns (uint256 tokenId)
    {
        // 1- petty 2- bronze 3- silver 4- gold 5- sapphire
        uint256 randomLength;
        uint256 totalChance = 256;
        if (_randomResult < 100) {
            randomLength = randomResult.mod(petty.length);
            tokenId = petty[randomLength];
        } else if (_randomResult > 100 && _randomResult < 180) {
            randomLength = randomResult.mod(bronze.length);
            tokenId = bronze[randomLength];
        } else if (_randomResult > 180 && _randomResult < 220) {
            randomLength = randomResult.mod(silver.length);
            tokenId = silver[randomLength];
        } else if (_randomResult == (totalChance / 2)) {
            randomLength = randomResult.mod(sapphire.length);
            tokenId = sapphire[randomLength];
        } else {
            randomLength = randomResult.mod(gold.length);
            tokenId = gold[randomLength];
        }
    }

    function randomRewardsGold(uint256 _randomResult)
        internal
        view
        returns (uint256 tokenId)
    {
        // 1- petty 2- bronze 3- silver 4- gold 5- sapphire
        uint256 randomLength;
        uint256 totalChance = 256;
        if (_randomResult < 65) {
            randomLength = randomResult.mod(petty.length);
            tokenId = petty[randomLength];
        } else if (_randomResult > 65 && _randomResult < 130) {
            randomLength = randomResult.mod(bronze.length);
            tokenId = bronze[randomLength];
        } else if (_randomResult > 130 && _randomResult < 200) {
            randomLength = randomResult.mod(silver.length);
            tokenId = silver[randomLength];
        } else if (_randomResult == (totalChance / 2)) {
            randomLength = randomResult.mod(sapphire.length);
            tokenId = sapphire[randomLength];
        } else {
            randomLength = randomResult.mod(gold.length);
            tokenId = gold[randomLength];
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
        //Selector: 1- petty 2- bronze 3- silver 4- gold 5- sapphire
        require(
            selector == 1 ||
                selector == 2 ||
                selector == 3 ||
                selector == 4 ||
                selector == 5,
            "Wrong Reward Pool Selected"
        );

        if (selector == 1) {
            petty.push(tokenId);
        } else if (selector == 2) {
            bronze.push(tokenId);
        } else if (selector == 3) {
            silver.push(tokenId);
        } else if (selector == 4) {
            gold.push(tokenId);
        } else if (selector == 5) {
            sapphire.push(tokenId);
        }

        return true;
    }

    function removeRewards(uint256 selector, uint256 index)
        external
        onlyOwner
        returns (bool)
    {
        //Selector: 1- petty 2- bronze 3- silver 4- gold 5- sapphire
        require(
            selector == 1 ||
                selector == 2 ||
                selector == 3 ||
                selector == 4 ||
                selector == 5,
            "Wrong Reward Pool Selected"
        );

        if (selector == 1) {
            require(index < petty.length);
            petty[index] = petty[petty.length - 1];
            petty.pop();
        } else if (selector == 2) {
            require(index < bronze.length);
            bronze[index] = bronze[bronze.length - 1];
            bronze.pop();
        } else if (selector == 3) {
            require(index < silver.length);
            silver[index] = silver[silver.length - 1];
            silver.pop();
        } else if (selector == 4) {
            require(index < gold.length);
            gold[index] = gold[gold.length - 1];
            gold.pop();
        } else if (selector == 5) {
            require(index < sapphire.length);
            sapphire[index] = sapphire[sapphire.length - 1];
            sapphire.pop();
        }
        return true;
    }

    function viewRewards()
        public
        view
        returns (
            uint256[] memory _commonRewards,
            uint256[] memory _uncommonRewards,
            uint256[] memory _rareRewards,
            uint256[] memory _extremelyRareRewards,
            uint256[] memory _legendaryRewards
        )
    {
        return (petty, bronze, silver, gold, sapphire);
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