// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract UrlShortener {
  struct URLStruct {
    address owner;
    string url;
    bool exists;
    bool paid;
  }
  mapping (bytes => URLStruct) lookupTable;
  mapping (address => bytes[]) public shortenedURLs;
  address[] accts;
  address payable owner;
  event URLShortened(string url, bytes slug, address owner);

  constructor() { 
      msg.sender==owner;
}

  function shortenURLWithSlug(string memory _url, bytes memory _short, bool paid) public payable {
    bool paidDefault = false;
    if (!lookupTable[_short].exists){
      lookupTable[_short] = URLStruct(msg.sender, _url, true, paid||paidDefault);
      shortenedURLs[msg.sender].push(_short);
      if(shortenedURLs[msg.sender].length < 1) {
        accts.push(msg.sender);
      } 
      emit URLShortened(_url, _short, msg.sender);
    }  
  }

  function shortenURL(string memory url, bool paid) public payable {
    bool paidDefault = false;
    bytes memory shortHash = getShortSlug(url);
    return shortenURLWithSlug(url, shortHash, paid||paidDefault);
  }

  function listAccts() public view returns (address[] memory){
    return accts;
  }

  function getURL(bytes memory _short) public view returns (string memory) {
    URLStruct storage result = lookupTable[_short];
    if(result.exists){
      return result.url;
    } 
    return "FAIL";
  }

  function kill() public {
    if (msg.sender == owner) selfdestruct(owner);
  }

  // privates
  function getShortSlug(string memory str) internal pure returns (bytes memory) {
    bytes32 hash = sha256(abi.encodePacked(str));
    uint main_shift = 15;
    bytes32 mask = 0xffffff0000000000000000000000000000000000000000000000000000000000;
    return abi.encodePacked(bytes3(hash<<(main_shift*6)&mask));
  }
}

