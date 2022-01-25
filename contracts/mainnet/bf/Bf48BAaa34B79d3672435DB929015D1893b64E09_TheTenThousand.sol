// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract TheTenThousand {

    string public name = "The Ten Thousand";
    string public symbol = "TTT";
    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return unicode"💩";
    }

    function mint(uint256 quantity) public {
        require(totalSupply + quantity <= 10000);
        for (uint256 i; i < quantity; i++) {
            emit Transfer(address(0), msg.sender, totalSupply++);
        }
    }

    function owner() public view returns(address) {
        return IERC721(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85).ownerOf(48470876519710777708258103201204544426167522678893968848486433251871114915301);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == bytes4(0x01ffc9a7) || interfaceId == bytes4(0x80ac58cd) || interfaceId == bytes4(0x5b5e139f) || interfaceId == bytes4(0x780e9d63);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}