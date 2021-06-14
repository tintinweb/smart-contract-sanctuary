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


// File contracts/levels/CreepyCatLady.sol

pragma solidity ^0.5.17;


interface ERC721 {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function ownerOf(uint256 _tokenId) external view returns (address);
}

// Let me steal a kitty from you
contract CreepyCatLady is ILevelContract {
    string public name = "Creepy Cat Lady";
    uint256 public credits = 20e18;
    ICourseContract public course;
    mapping(address => bool) nullifier;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function notLooking(address addr, uint256 id) public {
        ERC721 nft = ERC721(addr);
        require(
            nft.ownerOf(id) == msg.sender,
            "NFT not owned by message sender"
        );
        nft.safeTransferFrom(msg.sender, address(this), id);
        require(nullifier[addr] == true, "onERC721Received not called");
        require(
            nft.ownerOf(id) == address(this),
            "ownership is not transferred"
        );
        course.creditToken(msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        require(!nullifier[msg.sender]);
        nullifier[msg.sender] = true;
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}