/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

/*
           (Bob-a-pult
          /
         /
        / \ ||
      ( )======( )

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFT {
    function mint(uint256 _nbTokens) external payable;

    function totalSupply() external view returns (uint256);

    function getPrice() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Bobapult {
    address private _owner;
    INFT private nft1 = INFT(0xD00D1e06a2680E02919f4F5c5EC5dC45d67bB0b5);

    function setOwner(address bob) public onlyOwner {
        _owner = bob;
    }

    function setMainNFT(address nft) public onlyOwner {
        nft1 = INFT(nft);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    function mintCatapultBob(address to) external payable onlyOwner {
        uint256 price = nft1.getPrice();
        uint256 amount = msg.value / price;
        require(amount > 0 && msg.value >= amount * price, "Not enough money");
        uint256 startIdx = nft1.totalSupply();
        uint256 endCount = startIdx + amount;
        nft1.mint{value: amount * price}(amount);
        for (uint256 i = startIdx; i < endCount; i++) {
            nft1.transferFrom(address(this), to, i);
        }
    }

    function withdrawTo(address to) public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(to).send(_balance));
    }

    function withdrawTokenTo(
        address to,
        address token,
        uint256 param
    ) public onlyOwner {
        INFT(token).transferFrom(address(this), to, param);
    }

    function deposit() external payable {}

    fallback() external payable {}

    receive() external payable {}
}