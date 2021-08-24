// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ChildMintableERC721.sol";

contract NFTreatsMintable is ChildMintableERC721  {
    // https://github.com/maticnetwork/static/blob/master/network/mainnet/v1/index.json
    // https://github.com/maticnetwork/static/blob/master/network/testnet/mumbai/index.json
    constructor()
    public
    ChildMintableERC721("NFTreats Mintable", "NFTRTS", 0xa40Fc0782bEE28dd2CF8cB4AC2ECdB05C537f1B5) // testnet: 0x2e5e27d50EFa501D90Ad3638ff8441a0C0C0d75e
    {
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    function mintToCaller(address caller, string memory tokenURI)
    public
    returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(caller, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }


    modifier onlyOwner() {
        require(msg.sender == msgSender());
        _;
    }

    // tokenURI points to a JSON file that conforms to the "ERC721 Metadata JSON Schema".

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}