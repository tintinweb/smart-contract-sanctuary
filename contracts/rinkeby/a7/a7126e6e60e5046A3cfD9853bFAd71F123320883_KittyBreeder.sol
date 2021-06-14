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


// File contracts/levels/KittyBreeder.sol

pragma solidity ^0.5.17;


interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function balanceOf(address _owner) external view returns (uint256);
}

// Send a non-fungible token to this contract
contract KittyBreeder is ILevelContract {
    string public name = "Kitty Breeder";
    uint256 public credits = 20e18;
    ICourseContract public course;
    mapping(address => bool) nullifier;

    constructor(address courseContract) public {
        course = ICourseContract(courseContract);
    }

    function hereTakeThis(address kittyFactory, uint256 id)
        public
        nullify(kittyFactory)
    {
        ERC721 token = ERC721(kittyFactory);
        require(token.balanceOf(address(this)) == 1, "Send me one cat");
        require(token.ownerOf(id) == address(this), "The cat must be mine");
        course.creditToken(msg.sender);
    }

    modifier nullify(address addr) {
        require(!nullifier[addr], "Not allowed to use this address");
        nullifier[addr] = true;
        _;
    }
}