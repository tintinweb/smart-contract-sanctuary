// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Utils.sol";


abstract contract HWArt {
  function randomInt(uint256 min, uint256 max, uint256 seed) internal pure returns (uint256) {
    require(max > min, "err: min > max");
    
    return min + (seed % (max - min + 1));
  }

  function getCircle(uint256 cx, uint256 cy, uint256 r, uint256 c) internal pure returns (string memory) {
    return string(abi.encodePacked(        
      '<circle cx="', Strings.toString(cx),
      '" cy="', Strings.toString(cy),
      '" r="', Strings.toString(r),
      '" fill="hsl(', Strings.toString(c), 'deg, 100%, 50%)"/>'
    ));
  }
  
  function getTrapezium(uint256 cx, uint256 cy, uint256 r, uint256 c, uint256 seed) internal pure returns (string memory) {
    string memory p;

    for (uint256 i = 0; i < 3; i++) {
      bool f = i == 0;
      uint256 x = randomInt(r * (f ? 1 : 5), r * (f ? 3 : 8), seed + i);
      uint256 y = randomInt(r * (f ? 3 : 5), r * (f ? 5 : 8), seed + i + 4);
      p = string(abi.encodePacked(p, 
        Strings.toString(i == 1 ? cx + x : cx - x), ',', 
        Strings.toString(f ? cy - y : cy + y), ' '
      ));
    }
    
    return string(abi.encodePacked(
      '<polygon fill="hsl(',
      Strings.toString(c), 'deg, 100%, 50%)" stroke="none" points="',
      p, '"/>'
    ));
  }


  function getLines(uint256 cx, uint256 cy, uint256 seed) internal pure returns (string memory) {
    string memory p;

    for (uint256 i = 0; i < 3; i++) {
      bool f = i == 1;
      uint256 x = randomInt(f ? 10 : 50, f ? 30 : 80, seed + i);
      p = string(abi.encodePacked(p, 
        Strings.toString(i >= 1 ? cx + x : cx - x), ',', 
        Strings.toString(cy - randomInt(30, f ? 50 : 80, seed + i + 4)), ' '
      ));
    }
    
    return string(abi.encodePacked(
      '<polyline fill="none" stroke="black" stroke-linecap="round" stroke-width="',
      Strings.toString(randomInt(1, 3, seed)), '" points="', 
      p, '"/>'
    ));
  }

  
  function getColors(uint256 seed) internal pure returns (uint256, uint256, uint256, uint256) {
    uint256[4] memory arr;
    uint256 c = randomInt(0, 350, seed);
  
    arr[0] = c;
    
    for (uint256 i = 1; i < 4; i++) {
      c = c + randomInt(50, 80, seed + i);
      if (c >= 350) c = c - 350;

      arr[i] = c;
    }

    for (uint256 i = 0; i < 4; i++) {
      uint256 j = i + (seed + i) % (4 - i);
      uint256 n = arr[j];
      arr[j] = arr[i];
      arr[i] = n;
    }
    
    return (arr[0], arr[1], arr[2], arr[3]);
  }


  function randomHelloWorld(uint256 seed) internal pure returns (string memory) {
    string[4] memory arr = ["Hel","lo","Wor","ld"];

    for (uint256 i = 0; i < 4; i++) {
      uint256 j = i + (seed + i) % (4 - i);
      string memory n = arr[j];
      arr[j] = arr[i];
      arr[i] = n;
    } 

    return string(abi.encodePacked(
      arr[0], arr[1], arr[2], arr[3]
    ));
  }


  function getTokenJson(uint256 tokenId, uint256 seed) internal pure returns (string memory) {
    (uint256 c1, uint256 c2, uint256 c3, uint256 c4) = getColors(seed);
    (uint256 r1, uint256 r2) = (randomInt(30, 50, seed), randomInt(8, 13, seed));
    string memory helloWorld = randomHelloWorld(seed);

    string memory s = string(abi.encodePacked(
      getCircle(100, 90, r1, c2),
      getTrapezium(250, 80, r2, c3, seed),
      getLines(150, 300, seed)
    ));

    string memory svg = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><rect width="350" height="350" fill="hsl(',
      Strings.toString(c1), 'deg, 100%, 50%)"/><text x="8" y="338" fill="white" font-family="sans-serif" font-weight="bold" font-size="13px">',
      Strings.toString(tokenId), '</text>',
      s, '<text x="80" y="200" font-family="sans-serif" font-size="35px" fill="hsl(',
      Strings.toString(c4), 'deg, 100%, 50%)">',
      helloWorld, '</text></svg>'
    ));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "HelloWorld ', Strings.toString(tokenId), '", "description": "HelloWorld. On chain svg art by random.", "image": "data:image/svg+xml;base64,', 
      Base64.encode(bytes(svg)), 
      '","attributes": [{"trait_type": "radius", "value": ', Strings.toString(r1), 
      '},{"trait_type": "size", "value": ', Strings.toString(r2), 
      '},{"trait_type": "background", "value": ', Strings.toString(c1),
      '},{"trait_type": "circle", "value": ', Strings.toString(c2), 
      '},{"trait_type": "trapezium", "value": ', Strings.toString(c3), 
      '},{"trait_type": "text", "value": ', Strings.toString(c4), 
      '},{"trait_type": "word", "value": "', helloWorld, '"}]}'
    ))));

    json = string(abi.encodePacked('data:application/json;base64,', json));
    
    return json;
  }
}


contract HWA is HWArt, ERC721Enumerable, ReentrancyGuard, Ownable {
  mapping (uint256 => uint256) private obj;

  function mint(uint256 tokenId) payable public nonReentrant {
    require(msg.value == 0.01 ether, "0.01 ETH to mint");
    require(tokenId > 100 && tokenId <= 1000, "Token ID invalid");
    
    _safeMint(_msgSender(), tokenId);
    obj[tokenId] = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, Strings.toString(tokenId))));
  }

  function mintPromo(uint256 tokenId) public nonReentrant {
    require(tokenId > 0 && tokenId <= 100, "Token ID invalid");
    require(balanceOf(_msgSender()) == 0, "Already Promo");
    
    _safeMint(_msgSender(), tokenId);
    obj[tokenId] = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, Strings.toString(tokenId))));
  }

  function mintOwner(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId > 1000 && tokenId <= 1010, "Token ID invalid");
    require(totalSupply() >= 1000, "Not all minted");
    
    _safeMint(_msgSender(), tokenId);
    obj[tokenId] = uint256(keccak256(abi.encodePacked(_msgSender(), block.timestamp, Strings.toString(tokenId))));
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    return getTokenJson(tokenId, obj[tokenId]);
  }

  function withdraw() public nonReentrant onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
  
  constructor() ERC721("HelloWorldArt", "HWArt") Ownable() {}
}