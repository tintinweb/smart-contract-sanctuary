// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ITheNinjaHideout.sol";

contract TheFemaleNinjaHideout is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NINJAS = 444;
    uint256 public reservedNinjas = 44;

    // Withdrawal addresses
    address public constant ADD = 0xa64b407D4363E203F682f7D95eB13241B039E580;

    bool public claimStarted;

    mapping(uint256 => bool) public claimed;

    ITheNinjaHideout public ITNH =
        ITheNinjaHideout(0x97e41d5cE9C8cB1f83947ef82a86E345Aed673F3);

    constructor() ERC721("The Ninja Hideout (Females)", "TNHF") {}

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= MAX_NINJAS, "MAX_MINT");
        require(receivers.length <= reservedNinjas, "No reserved ninjas left");

        for (uint256 i = 0; i < receivers.length; i++) {
            reservedNinjas--;
            _safeMint(receivers[i], totalSupply());
        }
    }

    function claim() external returns (bool) {
        require(claimStarted, "Claim not started!");
        require(!_isContract(msg.sender), "Caller cannot be a contract");
        require(
            ITNH.tokensOfOwner(_msgSender()).length > 1,
            "Not enough to claim"
        );

        uint256[] memory ownedTokens = ITNH.tokensOfOwner(_msgSender());
        uint256 claimCount = 0;
        uint256 firstClaim;
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            if (!claimed[ownedTokens[i]]) {
                if (claimCount == 0) firstClaim = ownedTokens[i];
                claimCount++;
                claimed[ownedTokens[i]] = true;
            }

            if (claimCount == 2) {
                claimCount = 0;
                if (totalSupply() < MAX_NINJAS) {
                    uint256 tokenIndex = totalSupply();
                    _safeMint(_msgSender(), tokenIndex);
                }
            }
        }

        if (claimCount == 1) claimed[firstClaim] = false;

        return true;
    }

    function claimableAmount() external view returns (uint256) {
        uint256[] memory ownedTokens = ITNH.tokensOfOwner(_msgSender());
        uint256 claimCount = 0;
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            if (!claimed[ownedTokens[i]]) {
                claimCount++;
            }
        }
        return claimCount;
    }

    function isClaimed(uint256 tokenId) external view returns (bool) {
        return claimed[tokenId];
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
            for (uint256 i; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId < totalSupply(), "Token not exist.");

        string memory _tokenURI = _tokenUriMapping[tokenId];

        //return tokenURI if it is set
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        //If tokenURI is not set, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(baseURI(), tokenId.toString(), ".json"));
    }

    function toggleClaim() public onlyOwner {
        claimStarted = !claimStarted;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function withdrawAll() public payable onlyOwner {
        //withdraw half
        require(
            payable(ADD).send(address(this).balance),
            "Withdraw Unsuccessful"
        );
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint32 _size;
        assembly {
            _size := extcodesize(_addr)
        }
        return (_size > 0);
    }
}