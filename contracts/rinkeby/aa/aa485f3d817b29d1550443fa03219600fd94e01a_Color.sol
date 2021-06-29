pragma solidity >=0.5.0;
//pragma solidity >=0.5.0;
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC721.sol";

contract Color is ERC721 {

    string[] public colors;
    mapping(string => bool) _colorExists;

    constructor() ERC721("Color","COLOR") public {
    }

    function mint(string memory _color) public {
        //require()
        require(!_colorExists[_color]);
        colors.push(_color);
        uint _id = totalSupply();
        _mint(msg.sender, _id);
        _colorExists[_color] = true;
    
    }
  
}