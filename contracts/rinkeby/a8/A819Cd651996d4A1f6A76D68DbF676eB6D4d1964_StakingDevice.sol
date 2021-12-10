// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";

interface IRandomNumGenerator {
    function getRandomNumber(
        uint256 _seed,
        uint256 _limit,
        uint256 _random
    ) external view returns (uint16);
}

interface IRibbitToken {
    function burn(address from, uint256 amount) external;
}

interface IGoldStaking {
    function stakeDevice(address owner, uint16[] memory tokenIds) external;

    function randomHunterOwner(uint256 seed) external view returns (address);
}

/**
 * @title StakingDevice Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract StakingDevice is ERC721Burnable {
    using SafeMath for uint256;

    uint16 public MAX_SUPPLY;

    uint256 public mintPrice;
    uint16 public maxByMint;

    address public stakingAddress;
    address public tokenAddress;
    IRandomNumGenerator randomGen;

    mapping(uint16 => uint8) private multifiers;

    event Steel(address from, address to, uint16 tokenId);

    constructor() ERC721("Staking Device", "StakingDevice") {
        MAX_SUPPLY = 10000;
        mintPrice = 2000 ether;
        maxByMint = 20;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxByMint(uint16 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    function setMaxSupply(uint16 _max_supply) external onlyOwner {
        MAX_SUPPLY = _max_supply;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setRandomContract(IRandomNumGenerator _randomGen)
        external
        onlyOwner
    {
        randomGen = _randomGen;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function getMultifier(uint16 tokenId) public view returns (uint8) {
        return multifiers[tokenId];
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        if (_msgSender() != stakingAddress)
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        _transfer(from, to, tokenId);
    }

    function getTokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    function _getRandom(uint256 _tokenId) public view returns (uint8) {
        uint256 random = randomGen.getRandomNumber(_tokenId, 10, totalSupply());

        return uint8(random);
    }

    function mintByUser(
        uint8 _numberOfTokens,
        uint256 _amount,
        bool _stake
    ) external payable {
        require(tx.origin == msg.sender, "Only EOA");
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");

        require(mintPrice.mul(_numberOfTokens) <= _amount, "Low Price To Mint");

        IRibbitToken(tokenAddress).burn(msg.sender, _amount);

        uint16[] memory tokenIds = _stake
            ? new uint16[](_numberOfTokens)
            : new uint16[](0);

        for (uint8 i = 0; i < _numberOfTokens; i += 1) {
            address recipient = _selectRecipient(i);
            uint16 tokenId = uint16(totalSupply());

            uint8 randomNumber = _getRandom(tokenId);
            multifiers[tokenId] = randomNumber;

            if (recipient != msg.sender) {
                emit Steel(msg.sender, recipient, tokenId);
            }

            if (_stake && recipient == msg.sender) {
                tokenIds[i] = tokenId;
                _safeMint(stakingAddress, tokenId);
            } else {
                _safeMint(msg.sender, tokenId);
            }
        }

        if (_stake && tokenIds.length > 0) {
            IGoldStaking(stakingAddress).stakeDevice(msg.sender, tokenIds);
        }
    }

    function _selectRecipient(uint256 seed) private view returns (address) {
        if (
            randomGen.getRandomNumber(
                totalSupply() + seed,
                100,
                totalSupply()
            ) >= 10
        ) {
            return msg.sender;
        }

        address thief = IGoldStaking(stakingAddress).randomHunterOwner(
            totalSupply() + seed
        );
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }
}