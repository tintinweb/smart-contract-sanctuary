pragma solidity ^0.5.16;

import "./ERC721Full.sol";

contract CryptonautToken is ERC721Full  {


    constructor() ERC721Full("NFT Cryptonaut", "CRYPTONAUT") public {
    }

    function mint(address _to, string memory _tokenURI) public returns(bool) {
       uint _tokenId = totalSupply().add(1);
       _mint(_to, _tokenId);
       _setTokenURI(_tokenId, _tokenURI);
       return true;
    }

    function tipAuthor() public payable {
        address payable _author = address(0x7bE06ae6dDDF1Ac4a665E06f801504f44452271a);
        bool sent = _author.send(msg.value);
        require(sent, "Failed to send");
  }

}