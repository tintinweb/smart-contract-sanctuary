/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

//SPDX-License-Identifier: Unlicense

// File contracts/ILevelContract.sol

pragma solidity ^0.5.17;

interface ILevelContract {
    function name() external returns (string memory);

    function credits() external returns (uint256);
}


// File contracts/ICourseContract.sol

pragma solidity ^0.5.17;

interface ICourseContract {
    function creditToken(address challenger) external;

    function addLevel(address levelContract) external;
}


// File contracts/levels/IfYouGotItFlauntIt.sol

// Show me 5 NFTs
pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

// Show me 5 NFT from different contracts here
contract IfYouGotItFlauntIt is ILevelContract {
    string public name = "If You Got It Flaunt It";
    uint256 public credits = 20e18;
    ICourseContract public course;
    mapping(bytes32 => bool) nullifier;

    struct NFT {
        address contractAddr;
        uint256 id;
    }

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function showOff(NFT[5] memory nfts) public {
        require(nfts.length == 5, "Show me 5 NFTs");
        for (uint256 i = 0; i < nfts.length; i++) {
            ERC721 token = ERC721(nfts[i].contractAddr);
            require(token.ownerOf(nfts[i].id) == msg.sender);

            // Prevents the submission of the same NFT
            nullify(
                keccak256(abi.encodePacked(nfts[i].contractAddr, nfts[i].id))
            );
        }
        course.creditToken(msg.sender);
    }

    function nullify(bytes32 h) internal {
        require(!nullifier[h], "Not allowed to use this hash");
        nullifier[h] = true;
    }
}