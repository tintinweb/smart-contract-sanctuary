// SPDX-License-Identifier: MIT
/// @title Deadfellaz Infected S1

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXXXXXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxolc::;;;;;;;:::cldkKNWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWKko:;;:ldxkO0KKKKOOOOkdoc:;;cd0NWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWKxc,;lx0KXWMNdcxNMMO::co0WXOO0kd:,;oONMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMW0l,;lOXKxoldKM0;.,xNNx'od'oKc'clkNN0x:,:xXMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMW0l':xXNNNO;.:lONO,,';oOd'cc;kd';oOKxclkKOl,;kNMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMXo,;xX0occcxk;.:okklxOxx00doxK0cdKK0o''ccdXW0c'cKWMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMW0:'lXMXo.;xo,o0ocd0NWWMMMMMMMMMWXWMXl'coxK0ddKNd,;OWMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWO;'xNMMMNOl::;dNWWMMMMMMMMMMMMMMMMMMW0oo00o:cxXMWk,,kWMMMMMMMMMMM
// MMMMMMMMMMMMMMM0;'kWMMMMMMW0dkNMMMMMMMMMMMMMMMMMMMMMMMWNO;,kWMWNXNk,;OMMMMMMMMMMM
// MMMMMMMMMMMMMMXc.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNklk0xlcl0Nd.cXMMMMMMMMMM
// MMMMMMMMMMMMMWx.cXMWXOxxk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl,lk0NWMK:'xWMMMMMMMMM
// MMMMMMMMMMMMMX:.xW0l'.....:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNdcOWMMMMWd.lNMMMMMMMMM
// MMMMMMMMMMMMMO';0O,...;;...'kWMMWWMMMMMMMMMMMWNXXNWMMMMMMMMNxlloookNO';KMMMMMMMMM
// MMMMMMMMMMMMNo.oKc..'xNNx...cXMNdl0Kk0WMMMMNOl;,',cxXMMMMMMWO;.,''lX0,,0MMMMMMMMM
// MMMMMMMMMMMMK;'OK:..,kWNd...lNNd.;Oo.oNMMMXl........:KMMMMMNxcok0XNM0,,0MMMMMMMMM
// MMMMMMMMMMMWx.:XWd...':;...,ONx'.lO;.lNMNKo...:kkc...lNMMMMKl;lOXkkNk':KMMMMMMMMM
// MMMMMMMMMMMNl.dWMNx;.....'l0WO,.'xx..cXMKx;..,OMMO,..cXMMMWx:do::,oXd.lNMMMMMMMMM
// MMMMMMMMMMM0,,0MMMMXOxddkKWMMXxokXk;'oNMX0l...:xd;...xWMMMWXKWW0c:OK;'kMMMMMMMMMM
// MMMMMMMMMMWd.cNMMMWNNWMMMMMMMMMMMMWNXNMMMW0:.......'dNMMMMMMMMMMWNNd.cXMMMMMMMMMM
// MMMMMMMMMMNl.dWMWOl;,:oKMMN0XMMMWMMMMMMMMMMNkl:;;cdKWMMMMMMMMMMMMMO,,OMMMMMMMMMMM
// MMMMMMMMMMX:'kMWx......:KNd,xWWkl0MWK0NMMMMMMMWNWWMMMMMMMMMMMMMMMKc'dWMMMMMMMMMMM
// MMMMMMMMMMX:'kMNc.......;c'.ckx,'kWK:;0MMWNOdox0WMMMMMMMMMMMMMMMXl.lNMMMMMMMMMMMM
// MMMMMMMMMMWd.lXWk,....'okc.,cc,..;c;.'okxo:.....oNMMMMMMMMMMMMMXl'lXMMMMMMMMMMMMM
// MMMMMMMMMMMXc.oXWKxooxKWWo,xWXc.oOx,.:l:'.......,OMMMMMMMMMMMWO:'oXMMMMMMMMMMMMMM
// MMMMMMMMMMMMKl':ONMMMMMMWXKNMNxdXMK::KMNo'......cXMMMMMMMMMNOl':kNMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMNk:,:xKNMMMMMMMMMMMMMWKXWMMN0x:,,:dXMMMMMMMNOo;,ckNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMNOo:,:ldOKXNWMMMMMMMMMMMMMMMWNXWMMMMMWXko;,:dKWMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMN0xoc:;;:clodxO0KXNWMMMMMMMMWNX0ko:;;cxKWMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMWNX0Oxdolc:;;;:ccllllllcc:;;:lx0NWMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkxddooddxxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

pragma solidity ^0.8.6;

import { ERC721, Ownable, ProxyRegistry } from "./OpenZeppelinDependencies.sol";

contract DeadfellazInfectedS1 is ERC721, Ownable {

  uint public constant MAX_SUPPLY = 186;

  string private _contractURI = "https://gateway.pinata.cloud/ipfs/QmRxcx4KsWRLjFdXTCpzm4CdRmAAcKyHBNkm2WDauLgdKm";

  string public baseURI = "https://gateway.pinata.cloud/ipfs/QmPZGihQSfXFbuuPMmreB3GqYkijUMtu6TKYtXQPwrK9Mi/";

  /// @notice OpenSea Mainnet Proxy Registry
  address public constant proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

  uint public constant decimals = 0;

  uint public totalSupply = 0;

  constructor() ERC721("Deadfellaz Infected S1", "DFINFECTEDS1") {}

  /// @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
  function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {

      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

      // Whitelist OpenSea proxy contract for easy trading.
      if (proxyRegistry.proxies(owner) == operator) {
          return true;
      }
      return super.isApprovedForAll(owner, operator);
  }

  /// @notice Reserved for owner to batch mint
  function ownerMint(uint amount) public onlyOwner {
    uint currentTotalSupply = totalSupply;

    require(currentTotalSupply+amount<=MAX_SUPPLY, "DFIS1: Max supply reached");

    totalSupply = currentTotalSupply + amount;

    for (uint i = 0; i<amount; i++){
      _mint(msg.sender, currentTotalSupply+i+1);
    }
  }

  /// @notice Reserved for owner to mint specific tokens
  function ownerMintIds(uint[] calldata ids) public onlyOwner {
    uint amount = ids.length;
    uint currentTotalSupply = totalSupply;

    require(currentTotalSupply+amount<=MAX_SUPPLY, "DFIS1: Max supply reached");

    totalSupply = currentTotalSupply+amount;

    for (uint i=0; i<amount; i++){
      /// @notice id 0, and id greater than 186 not allowed
      require(ids[i] != 0 && ids[i] <= MAX_SUPPLY, "DFIS1: tokenId not allowed");
      _mint(msg.sender, ids[i]);
    }
  }

  /// @notice Reserved for owner to transfer specific owned tokens
  function ownerTransferIds(uint[] calldata ids, address[] calldata addresses) public onlyOwner {
    uint amount = ids.length;

    require(amount == addresses.length, "DFIS1: tokenId and address lengths does not match");

    for (uint i=0; i<amount; i++){
      /// @notice `ERC721.transferFrom` will revert if `msg.sender` is not the owner of the tokenId
      transferFrom(msg.sender, addresses[i], ids[i]);
    }
  }

  /// @notice Reserved for owner to burn specific owned ids
  function ownerBurnIds(uint[] calldata ids) public onlyOwner {
    uint amount = ids.length;

    totalSupply = totalSupply-amount;

    for (uint i=0; i<amount; i++){
      require(ownerOf(ids[i]) == msg.sender, "DFIS1: tokenId not owned");
      _burn(ids[i]);
    }
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  function setContractURI(string memory newContractURI) external onlyOwner {
    _contractURI = newContractURI;
  }

  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  receive() external payable {
    revert();
  }

}