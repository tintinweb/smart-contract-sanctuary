// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract someKeys is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Total supply of key.
    uint256 public constant MAX_key = 7250;

    // The maximum nr. of mints per tx.
    uint256 public constant MAX_TO_MINT = 20;

    // key price in wei. (0.08 ETH)
    uint256 public constant key_PRICE = 80000000000000000;

    // Boolean that lest people participate in sale or not.
    bool public saleIsActive = false;
    
    constructor() public ERC721("someKeys", "key") {}
    
    /*
    * At deployment sale is inactive.
    * Owner of the smart contract can change the
    * sale form inactive to active and backwards.
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    /*
    * Withdraw ETH to the owner of
    * the smart-contract.
    * Must be changed to send ETH to
    * a multisig account e.g. Gnosis Safe.
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
    * Reserve 30 (hard-coded) key for
    * the owner of the smart-contract.
    * Must be changed to send NFTs to
    * a multisig account e.g. Gnosis Safe. 
    */    
    function reserveKey() public onlyOwner {
        for (uint i = 0; i < 30; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        }
    }

    /*
    * Metadata for NFTs.
    * Setup JSON to IPFS for every NFT in one file.
    * E.g. ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/
    * Here is metadata for every NFT.
    * E.g. ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/1
    * Here is metadata for one NFT.
    */
    function setBaseURI (string memory newBaseURI) public onlyOwner {
        _newBaseURI = newBaseURI;
    }
    
    /*
    * Minting function.
    * Depends on saleIsActive boolean
    * true means you can buy, false 
    * means you cannot.
    * Checks if there are key available.
    * Checks if you are minting only 20 key.
    * Checks if you have sent enough ETH.
    * If everything is okaym you get to
    * mint you key.
    */
    function mintKey(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint key");
        require(_tokenIds.current() + numberOfTokens <= MAX_key, "There are not enough key available.");
        require(numberOfTokens <= MAX_TO_MINT, "Can only mint 20 key at a time.");
        require(key_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct.");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            if (_tokenIds.current() <= MAX_key) {
                _safeMint(msg.sender, newItemId);
            }
        }
    }
}