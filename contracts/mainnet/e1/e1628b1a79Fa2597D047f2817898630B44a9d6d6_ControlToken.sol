// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./Ownable.sol";
import "./ERC721.sol";
import "./VanityToken.sol";
import "./Deployer.sol";

contract ControlToken is Ownable, ERC721 {
    uint256 constant private TOKEN_BITS = 0xc << 252;
    Deployer immutable deployer;
    VanityToken vanityToken;

    function toControl(uint256 vanityId) private pure returns (uint256) {
        return vanityId | TOKEN_BITS;
    }

    function toVanity(uint256 controlId) private pure returns (uint256) {
        return controlId & ~TOKEN_BITS;
    }

    function setVanityToken(VanityToken _vanityToken) external onlyOwner {
        require(vanityToken == VanityToken(0), "VFC: VFA already set");
        vanityToken = _vanityToken;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function mint(uint256 vanityId, address owner) external {
        require(msg.sender == address(vanityToken), "VFC: not vanity token");
        _safeMint(owner, toControl(vanityId));
    }

    function addressOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: address query for nonexistent token");
        return address(toVanity(tokenId));
    }

    function redeem(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: redeem caller is not owner nor approved"
        );

        address addr = addressOf(tokenId);

        uint256 size;
        assembly {
            size := extcodesize(addr)
        }

        require(0 == size, "VFC: account in use");

        _burn(tokenId);

        vanityToken.remint(addr, _msgSender());
    }

    function proxy(uint256 tokenId, bytes calldata data) external payable {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: redeem caller is not owner nor approved"
        );

        deployer.proxy(addressOf(tokenId), data);

        assembly {
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }

    constructor(Deployer _deployer) ERC721("VanityFarmControl", "VFC") {
        deployer = _deployer;
    }
}