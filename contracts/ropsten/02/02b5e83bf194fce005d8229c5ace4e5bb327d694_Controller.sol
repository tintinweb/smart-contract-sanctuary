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
    uint256 randNonce;

    function random() internal returns (uint256) {
        randNonce++;
        return
            uint256(
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.number,
                            randNonce
                        )
                    )
                ) % 100)
            );
    }

    function random2() internal returns (uint256) {
        randNonce++;
        return
            uint256(
                (uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            block.number,
                            randNonce
                        )
                    )
                ) %
                    NFT(0xee5ed3597F81a2863345ba10068e51aBca26b11E)
                        .totalSupply())
            );
    }

    // function that generates a number from 0 to totalsupply()
    function mint() public {
        NFT(0xee5ed3597F81a2863345ba10068e51aBca26b11E).mint(msg.sender);
    }

    function callRandom() public returns (uint256) {
        return random();
    }

    function callRandom2() public returns (uint256) {
        return random2();
    }
}