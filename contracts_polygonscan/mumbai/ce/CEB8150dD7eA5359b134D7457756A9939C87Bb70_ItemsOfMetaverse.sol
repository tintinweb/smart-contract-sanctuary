// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./HexStrings.sol";
import "./Base64.sol";

contract ItemsOfMetaverse is ERC1155 {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;
    using HexStrings for uint160;
    address public minter;
    address public owner;
    mapping (uint256 => Metadata) private itemMetadata;

    event MinterChanged(address indexed from, address to);

    constructor() ERC1155("") {
      minter = msg.sender;
      owner = msg.sender;
      addItemMetadata("KING", 0, 1, 1, 1, '<defs><image width="217" height="279" id="king" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAANkAAAEXAgMAAABdRQmVAAAAAXNSR0IB2cksfwAAAAxQTFRFAAAAYTwG27GAeXyAQlZMDwAAAAR0Uk5TAP///7MtQIgAAACHSURBVHic7dqxCYAwEEDRNDY27uE8uo/jSBoXFLXRwhBIOhXf7wL36sBxIdxrxmxDKMRxHMdxb3BtzDZzHMdx3BfcVX+C2nmO4ziOe8TFe8uebUvGJo7jOI57hUvq8m4t/Zccx3Ecx3Ecx3Ecx3Ecx/3XtcnC8XxW35VwHMdxHMdxHMdxde4ABo2T2xYweN0AAAAASUVORK5CYII="/></defs><style></style><use href="#king" x="31" y="31"/>');
      addItemMetadata("EXPLORER'S CHEST", 1, 0, 10, 10, '<defs><image  width="93" height="124" id="chest" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF0AAAB8AgMAAAB271TDAAAAAXNSR0IB2cksfwAAAAlQTFRFAAAAOT1EMzhB3biazAAAAAN0Uk5TAP//RFDWIQAAADRJREFUeJxjYIAAxlAICGBAA6MSoxIjQCIUO3AYlRiVGEESq7CDhlGJUYlRiVGJUYkRJAEAQxQYmQX6ijQAAAAASUVORK5CYII="/></defs><style>tspan { white-space:pre }</style><use  href="#chest" x="93" y="93" />');
      addItemMetadata("EXPLORER'S LEGS", 2, 0, 5, 10, '<defs><image  width="93" height="62" id="legs" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF0AAAA+AgMAAAA0f/+kAAAAAXNSR0IB2cksfwAAAAlQTFRFOT1EGh0hAAAAjc4yGgAAAAN0Uk5T//8A18oNQQAAAB9JREFUeJxjYBgFo2AUhEJA2CoIWArlO4xKjEqMHAkAPqBGaS5Pkd8AAAAASUVORK5CYII="/></defs><style>tspan { white-space:pre }</style><use  href="#legs" x="93" y="217" />');
      addItemMetadata("EXPLORER'S HEAD", 3, 0, 5, 10, '<defs><image  width="93" height="93" id="head" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF0AAABdBAMAAAA1X3fwAAAAAXNSR0IB2cksfwAAAA9QTFRFAAAAGh0hKSsuXzQ0LBkZYRx+xQAAAAV0Uk5TAP////8c0CZSAAAAQklEQVR4nO3KsQ2AMBAEwacEOrCoAAlKoP+aHJ8Ti+yD2XSnKjvOrDbxPM/zTfz1q8HzPM839U/2ftmyb57neb6nn/JhIUk2hXQcAAAAAElFTkSuQmCC"/></defs><style>tspan { white-space:pre }</style><use  href="#head" x="93" y="0" />');
      addItemMetadata("EXPLORER'S BOOTS", 4, 0, 2, 10, '<defs><image  width="93" height="31" id="boots" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF0AAAAfAQMAAAC/L1PnAAAAAXNSR0IB2cksfwAAAAZQTFRFKSsuAAAAczgrKQAAAAJ0Uk5T/wDltzBKAAAAGElEQVR4nGNgYGBg/P///x8GKBjlDDQHAA+0e0cUnWvcAAAAAElFTkSuQmCC"/></defs><style>tspan { white-space:pre }</style><use  href="#boots" x="93" y="279" />');
      addItemMetadata("EXPLORER'S SHIELD", 5, 5, 20, 10, '<defs><image  width="93" height="93" id="shield" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF0AAABdAQMAAAD9v/iAAAAAAXNSR0IB2cksfwAAAAZQTFRFKSsuGh0h0YxxzQAAABtJREFUeJxjYBgFgxAw/v///88oZzBxRsGgAgAtantH42VRCQAAAABJRU5ErkJggg=="/></defs><style>tspan { white-space:pre }</style><use  href="#shield" x="31" y="124" />');
      addItemMetadata("EXPLORER'S SWORD", 6, 10, 0, 10, '<defs><image  width="93" height="155" id="sword" href="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAF0AAACbAgMAAAB9rn/5AAAAAXNSR0IB2cksfwAAAAlQTFRFAAAAQkhQGh0hwMkEaQAAAAN0Uk5TAP//RFDWIQAAADxJREFUeJzt07EVACAIA9HIhDbu4yjUTmkBFc8J5K7MryNFY0VTJQAAAAAAgBZw3m0AaASZ5eD1OADwP1zXAoJ0yps+ngAAAABJRU5ErkJggg=="/></defs><style>tspan { white-space:pre }</style><use  href="#sword" x="186" y="31" />');
       _mint(msg.sender, 0, 1, "");
       _mint(msg.sender, 1, 1, "");
       _mint(msg.sender, 2, 1, "");
       _mint(msg.sender, 3, 1, "");
       _mint(msg.sender, 4, 1, "");
       _mint(msg.sender, 5, 1, "");
       _mint(msg.sender, 6, 1, "");
    }

    struct Metadata {
      string name;
      uint256 itemType;
      uint256 damage;
      uint256 armor;
      uint256 multiplier;
      string svg;
    }

    function awardItem(address player, uint256 id) public returns (uint256) {
        require(msg.sender==minter, 'Error, msg.sender does not have minter role');
        _mint(player, id, 1, "");
        return id;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
      return generateSVGofTokenById(id);
    }

    function uriBatch(uint256[] memory ids) public view virtual returns (string memory) {
      return generateSVGofTokenByIds(ids);
    }

  function generateSVGofTokenById(uint256 id) public view returns (string memory) {
    Metadata memory item = itemMetadata[id];
     string memory svg = string(abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes( string(abi.encodePacked(
                                '{"name":"', 
                                    item.name,
                                '", "damage": "',
                                    uint2str(item.damage),
                                '", "armor": "',
                                    uint2str(item.armor),
                                '", "multiplier": "',
                                    uint2str(item.multiplier),
                                '","image": "',
                                '<svg version="1.2" baseProfile="tiny-ps" xmlns="http://www.w3.org/2000/svg" width="279" height="310">',
                                  item.svg,
                                '</svg>'
                                '"}'
                              ))))));

    return svg;
  }

  function getMetadata(uint256 id) internal pure returns(string memory) {
    
  }

    function generateSVGofTokenByIds(uint256[] memory ids) public view returns (string memory) {
      string memory items;
      string memory name;
      for(uint i = 0; i < ids.length; i++) {
        name = string(abi.encodePacked(name, " ",itemMetadata[i].name));
        items = string(abi.encodePacked(items, itemMetadata[i].svg));
      }

      string memory svg = string(abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes( string(abi.encodePacked(
       '{"name":"',
       name,
       '", "image": "',
       '<svg version="1.2" baseProfile="tiny-ps" xmlns="http://www.w3.org/2000/svg" width="279" height="310">',
       items,
       '</svg>'
       '"}'
    ))))));

    return svg;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }

    function passMinterRole(address _contract) public returns (bool) {
        require(msg.sender==minter, 'Error, only owner can change pass minter role');
        minter = _contract;

        emit MinterChanged(msg.sender, _contract);
        return true;
    }

    function passMinterRoleBack() public returns (bool) {
        require(msg.sender==owner, 'Error, only owner can change pass minter role back');
        minter = owner;

        emit MinterChanged(msg.sender, owner);
        return true;
    }

    function addItemMetadata(
        string memory name, 
        uint256 itemType,
        uint256 damage, 
        uint256 armor, 
        uint256 multiplier,
        string memory svg
      ) public returns (Metadata memory) {   
          require(msg.sender==minter, 'Error, msg.sender does not have minter role');
          uint256 newItemId = _tokenIds.current();
          Metadata memory metadata = Metadata(
            name,
            itemType,
            damage,
            armor,
            multiplier,
            svg
          );
          itemMetadata[newItemId] = metadata;
          _tokenIds.increment();   
          return metadata;
    }

    function getItemType(uint256 id) public view returns(uint256) {
       return itemMetadata[id].itemType;
    }
}