/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMinter {
    function execute(bytes memory data) external returns (bytes memory);
}

interface ICupCat {
    function mintCupCat(uint numberOfTokens) external payable;
}

contract Minter {
    ICupCat public constant cats = ICupCat(0x8Cd8155e1af6AD31dd9Eec2cEd37e04145aCFCb3);

    address public creator;

    modifier onlyCreator() {
        require(creator == msg.sender);
        _;
    }

    constructor(address caller, uint256 amount) payable {
        creator = caller;
        cats.mintCupCat{value: msg.value}(amount);
    }

    function execute(bytes memory data) external onlyCreator returns (bytes memory) {
        (bool success, bytes memory result) = address(cats).call(data);
        require(success, "Call failed");
        return result;
    }

    function sweep() external onlyCreator {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

contract MunchCat {
    uint256 public constant CATS_PER_MINT = 3;
    uint256 public constant PRICE_PER_CAT = 0.02 ether;

    address public creator;

    Minter[] public minters;

    constructor() { }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    function mint(uint256 amount) external payable {
        while (amount > 0) {
            uint256 mintAmount = amount > CATS_PER_MINT ? CATS_PER_MINT : amount;
            minters.push((new Minter){value: mintAmount * PRICE_PER_CAT}(msg.sender, mintAmount));
            amount -= mintAmount;
        }
    }

    function sweep() external onlyCreator {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}