/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity ^0.8.0;

interface Token {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface vToken {
    function mint(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOf(address) external view returns (uint256);
}

// NFT Interference

interface NFT {
    function setBaseURI(string memory) external;

    function mint(address) external;

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract Controller {
    address NFTADDR = 0x0cBdb75cb27222E35b4970a96C209a3771B1956d;

    function random() public view returns (uint256) {
        return
            uint256(
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.number
                        )
                    )
                ) % 100)
            );
    }

    function random2() public view returns (uint256) {
        return
            uint256(
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.number
                        )
                    )
                ) % NFT(NFTADDR).totalSupply())
            );
    }

    function mint() public {
        NFT(NFTADDR).mint(msg.sender);
    }

}