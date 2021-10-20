pragma solidity ^0.8.9;

contract PUNKSMock {
    mapping (uint => address) public punkIndexToAddress;

    function mintSourceToken(address newTokenOwner, uint256 tokenId)
        public
        returns (uint256)
    {
      punkIndexToAddress[tokenId] = newTokenOwner;
    }
}