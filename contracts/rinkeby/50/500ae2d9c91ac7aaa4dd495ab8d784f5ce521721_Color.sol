pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "./ERC721.sol";
import "./ERC721Enumerable.sol";
  
contract Color is ERC721Enumerable {

  constructor() ERC721("Color", "COLOR") public {

  }

  string[] public colors;   //  a total colors set (for now it can't recognize repeat color)

  // so we need a map to log color
  mapping (string => bool) _colorExist;

  function mint(string memory _color) public {
    // require unique color
    require(!_colorExist[_color], "THis NFT token has been registered");
    // Color - add it
    colors.push(_color);
    uint _id = colors.length - 1;
    // call the _mint function
    _mint(msg.sender, _id);
    // add to _colorExist map
    _colorExist[_color] = true;
    // Color - track it

  }

}