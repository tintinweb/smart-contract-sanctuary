// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ECDSA.sol";

contract ShonenJunkNft is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private baseURI;

    address addr_1 = 0x3DF14804E2013A0D7c7afb7071bad8324AFeAb02;

    // (800 NFTs reserved by the team): 8,201 NFTs for community
    // 60% whitelisting reservations:   5,501 NFTs
    // 30% public drop with quiz:       2,700 NFTs

    // reserved for giveaways
    uint256 private reserved = 800;

    // 5*15=75

    // 2 max NFTs
    // Max mint count based on quiz score
    // OpenSea royalties 5%
    // Apply to coinbase and rarible NFT.

    // total NFTs that can be minted
    uint256 private maxSupply = 9001;

    // floor prices
    uint256 private tier0Price = 0.00 ether;
    uint256 private tier1Price = 0.05 ether;
    uint256 private tier2Price = 0.08 ether;

    bool public paused = true;

    event Purchase(address purchaser, uint256 num);
    event GiveAway(address recipient, uint256 num);
    event PriceChanged(uint256 tier, uint256 newPrice);
    event PauseChanged(bool val);
    event BaseURIChanged(string url);
    event WithdrawAll();

    constructor(
      string memory name,
      string memory symbol,
      string memory initBaseURI
    ) ERC721(name, symbol) {
        setBaseURI(initBaseURI);
    }

    // Purchase requires a _signature from the author.
    // So this is a 2-party authenticated purchase: the contract owner and minter.
    // Purchaser pays gas fees.
    function purchase(uint256 num, uint256 _timestamp, uint256 priceTier, bytes memory _signature) public payable {

        uint256 supply = _tokenIds.current();
        require( !paused,                              "Sale paused" );
        require( num < 21,                             "You can purchase a maximum of 20 NFTs" );
        require( supply + num < maxSupply - reserved,  "Exceeds maximum NFTs supply" );

        address wallet = _msgSender();
        address signerOwner = signatureWallet(wallet,num,_timestamp,_signature);
        require(signerOwner == owner(), "Not authorized to mint");
        require(block.timestamp >= _timestamp - 30, "Signature expired, out of time");

        if (priceTier == 0) {
            require( msg.value >= tier0Price * num, "Ether sent is not correct" );
        }
        else if (priceTier == 1) {
            require( msg.value >= tier1Price * num, "Ether sent is not correct" );
        }
        else if (priceTier == 2) {
            require( msg.value >= tier2Price * num, "Ether sent is not correct" );
        }
        else {
            revert("Invalid price tier");
        }


        for(uint8 i = 0; i < num; i++){
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint( msg.sender, newItemId );
        }

        emit Purchase(msg.sender, num);

    }

    function signatureWallet(address wallet, uint256 _num, uint256 _timestamp, bytes memory _signature) public pure returns (address){
        //return ECDSA.recover(keccak256(abi.encode(wallet, _num, _timestamp)), _signature);
        return ECDSA.recover(ethSignedMessage(keccak256(abi.encode(wallet, _num, _timestamp))), _signature);
    }

    function ethSignedMessage(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    // Contract owner pays gas fee
    function giveAway(address recipient, uint256 num) public onlyOwner {
        require( num <= reserved, "Exceeds reserved NFTs supply" );

        for(uint256 i; i < num; i++){
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint( recipient, newItemId );
        }

        reserved -= num;

       emit GiveAway(recipient, num);
    }

    // Set floor price
    function setPrice(uint256 priceTier, uint256 newPrice) public onlyOwner {
        if (priceTier == 0) {
            tier0Price = newPrice;
        }
        else if (priceTier == 1) {
            tier1Price = newPrice;
        }
        else if (priceTier == 2) {
            tier2Price = newPrice;
        }
        else {
            revert("Invalid price tier");
        }
        emit PriceChanged(priceTier, newPrice);
    }

    // Toggle active or not active contract
    function setPause(bool val) public onlyOwner {
        paused = val;
        emit PauseChanged(val);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Include trailing slash, e.g. https://example.com/api/my-nft/
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
        emit BaseURIChanged(uri);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 all = address(this).balance;
        require(payable(addr_1).send(all));
        emit WithdrawAll();
    }

    // Hook for Enumerable
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

}