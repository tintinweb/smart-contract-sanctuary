// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// This is an airdrop NFT for Pulsr www.pulsr.ai 
//
// Thanks to Galactic and 0x420 for their gas friendly ERC721S implementation.
//

import "./ERC721S.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./PaymentSplitter.sol";

contract PulsrNFT is
    ERC721Sequential,
    PaymentSplitter,
    Ownable
{

    uint256 public constant MAX_SUPPLY = 3909;
    string public baseURI = "https://ipfs.io/ipfs/QmPNvHxvfBEGYKTQCcX5RtaX7Nd5qK66eFGuFUqKdvHkPL/";
    string private constant _name = "Pulsr Community Badge Special-Edition 001";
    string private constant _symbol = "PULSR";
    address[] private _payees = [msg.sender];
    uint256[] private _shares = [100];

    constructor() ERC721Sequential(_name, _symbol) PaymentSplitter(_payees, _shares) payable {
    }

    // @dev Minting by owner to a list of addresses for airdrop
    function mint(address[] calldata _addresses) external onlyOwner {
        uint256 numTokens;

        numTokens = _addresses.length;
        require(totalMinted() + numTokens <= MAX_SUPPLY, "PulsrNFT: Sold Out");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(_addresses[i]);
        }
    }

    // @dev Return the base url path to the metadata used by opensea
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // @dev Set the base url path to the metadata used by opensea
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    // @dev Add payee for payment splitter
    function addPayee(address account, uint256 shares_) public onlyOwner {
        _addPayee(account, shares_);
    }

    // @dev Set the number of shares for payment splitter
    function setShares(address account, uint256 shares_) public onlyOwner {
        _setShares(account, shares_);
    }

    function addToken(address account) public onlyOwner {
        _addToken(account);
    }
}