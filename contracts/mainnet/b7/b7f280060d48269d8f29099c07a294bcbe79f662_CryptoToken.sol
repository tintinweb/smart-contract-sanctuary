/**
 *Submitted for verification at Etherscan.io on 2020-04-21
*/

pragma solidity ^0.6.0;

abstract contract Resolver {
    function get(string memory key, uint256 tokenId) public virtual view returns (string memory);
}
abstract contract Registry {
    function resolverOf(uint256 tokenId) external virtual view returns (address);
    
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);
}

contract CryptoToken {
    uint256 private constant _CRYPTO_HASH =
        0x0f4a10a4f46c288cea365fcf45cccf0e9d901b945b9829ccdb54c10dc3cb7a6f;
    address private constant _REGISTRY_CONTRACT = 0xD1E5b0FF1287aA9f9A268759062E4Ab08b9Dacbe;

    function resolver(uint256 tokenId) private view returns(address) {
        return Registry(_REGISTRY_CONTRACT).resolverOf(tokenId);
    }
    fallback() external{}
    
    function getTokenId(string memory label) public view returns(uint256) {
        require(bytes(label).length != 0);
        uint256 _tokenId = uint256(keccak256(abi.encodePacked(_CRYPTO_HASH, keccak256(abi.encodePacked(label)))));
        require(Registry(_REGISTRY_CONTRACT).ownerOf(_tokenId) != address(0), "This domain doesn't not exist");
        return _tokenId;
    }
    
    function getIpfsFromToken(uint256 tokenId) public view returns(string memory) {
        return Resolver(resolver(tokenId)).get("ipfs.html.value",tokenId);
    }
    
    function getIpfsFromLabel(string memory label) public view returns(string memory) {
        require(bytes(label).length != 0);
        uint256 _tokenId = getTokenId(label);
        return Resolver(resolver(_tokenId)).get("ipfs.html.value",_tokenId);
    }

}