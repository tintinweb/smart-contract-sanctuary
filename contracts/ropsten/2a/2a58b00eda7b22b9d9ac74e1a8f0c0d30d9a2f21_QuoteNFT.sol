// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";

interface IQuoteNFT is IERC721 {
    function mint(string memory quote)
        external
        payable
        returns (uint256 tokenId);

    function quote(uint256 tokenId) external view returns (string memory);
}

interface IWithdrawer {
    function withdraw() external payable;
}

contract Withdrawer is IWithdrawer {
    address public owner = msg.sender;

    function withdraw() external payable override {
        payable(owner).transfer(address(this).balance);
    }
}

contract QuoteNFT is ERC721, IQuoteNFT, Withdrawer {
    using Counters for Counters.Counter;
    Counters.Counter private _counter;

    // TODO ydm: Can I use an array here?
    //   - Is it cheaper (less gas)?
    //   - Is it reliable?  What if a token gets burnt?
    mapping(uint256 => string) public quote;

    //solhint-disable-next-line no-empty-blocks
    constructor() ERC721("QuoteNFT", "QFT") {}

    function mint(string memory text)
        external
        payable
        override
        returns (uint256 tokenId)
    {
        uint256 price = 10**17;
        require(msg.value >= price, "Minting costs 0.1 ETH");

        // It's important to mint the NFT first before introducing any
        // state changes as _mint() may revert the transaction.
        uint256 next = _counter.current() + 1;
        _mint(msg.sender, next);

        // Once the NFT is minted successfully, we can increment the
        // ID counter and store the quote text.
        _counter.increment();
        quote[next] = text;

        return next;
    }
}