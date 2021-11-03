/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

pragma solidity 0.5.16;

interface IVaultMetaProvider {
    function getTokenURI(address vault_address, uint256 tokenId) external view returns (string memory);
    function getBaseURI() external view returns (string memory);
}

// File: contracts/VaultMetaProvider.sol

pragma solidity 0.5.16;


contract VaultMetaProvider {

    string public _tokenURI;

    constructor (string memory tokenURI) public {
        _tokenURI = tokenURI;
    }

    function getTokenURI(address vault_address, uint256 tokenId) public view returns (string memory) {
        return _tokenURI;
    }
}