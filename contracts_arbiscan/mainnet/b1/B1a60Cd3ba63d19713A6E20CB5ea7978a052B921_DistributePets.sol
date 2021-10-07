//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ERC721 {
    function mint(address _to) external;

    function totalSupply() external view returns (uint256);
}

contract DistributePets {
    ERC721 public cudlPets;

    bool public isOpen;
    address public owner;
    uint256 public price;
    uint256 public sold;

    constructor(address _cudlPets) {
        isOpen = false;
        owner = msg.sender;
        price = 0.1 ether;
        cudlPets = ERC721(_cudlPets);
    }

    //  Buy an NFT for 0.1 or x for 0.1 eth by x limitted to 5
    function mint(uint256 qty) public payable {
        require(isOpen || msg.sender == owner, "!start");
        require(qty <= 5, "!count limit");
        require(msg.value >= price * qty, "!value");
        require(sold <= 2000, "!max reached");

        for (uint256 i = 0; i < qty; i++) {
            sold += 1;

            cudlPets.mint(msg.sender);
        }
    }

    function openSale() public {
        require(msg.sender == owner, "!forbidden");
        isOpen = true;
    }

    receive() external payable {}

    function withdrawEth(address to) public {
        require(msg.sender == owner, "!forbidden");

        address payable muse = payable(
            0x4B5922ABf25858d012d12bb1184e5d3d0B6D6BE4
        ); //send to multisig after as no multisig on arbitrum)
        (bool sentMuse, ) = muse.call{value: (address(this).balance / 2)}("");
        require(sentMuse, "Failed to send Ether");

        address payable _to = payable(to); //multisig
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
}