// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Ownable.sol";
import "./ERC721.sol";


interface TheTigersGuild {
    function ownerOf(uint256) external view returns (address);
}


contract TheTigersCubs is ERC721, Ownable {
    using Strings for uint256;

    string _baseMetadataUri;
    address _tigersContract = 0x22216C967cB9f69ceFC0b4f010682A47fD8bfBE5;
    bool public _saleIsActive = false;
    uint256 public _cubsSupply = 4444;
    mapping(uint256 => uint256) _adoptedCubs;

    constructor(string memory baseMetadataUri) ERC721("TheTigersCubs", "TTC") {
        setBaseMetadataUri(baseMetadataUri);
    }

    function setBaseMetadataUri(string memory baseMetadataUri) public onlyOwner {
        _baseMetadataUri = baseMetadataUri;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(_baseMetadataUri, tokenId.toString()));
    }

    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function getCubIdByTigerId(uint256 tigerId) public view returns (uint256) {
        return _adoptedCubs[tigerId];
    }
    
    function adoptCubs(uint256[] memory tigerIds) public {
        // 1. Проверка на то, открыта ли продажа
        require(_saleIsActive, "Sale must be active to adpot a cub");

        uint256 totalSupply = totalSupply();
        uint256 cubId = totalSupply + 1;

        for (uint i = 0; i < tigerIds.length; i++) {
            uint256 tigerId = tigerIds[i];
            cubId += i;

            // 2. Проверка на то, является ли msg.sender, владельцем тигра с id tigerId
            address tigerOwner = TheTigersGuild(_tigersContract).ownerOf(tigerId);
            require(msg.sender == tigerOwner, "msg.sender is not the owner of tiger with id tigerId");

            // 3. Проверка на то, связан ли тигр с id tigerId с тигрёнком
            require(_adoptedCubs[tigerId] == 0, "Cub for tiger with id tigerId is already adopted");

            // 4. Проверка на то, не распроданы ли все тигрята
            require(cubId <= totalSupply, "Purchase would exceed max supply of cubs");

            _safeMint(msg.sender, cubId);
            _adoptedCubs[tigerId] = cubId;
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint i = 0; i < tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}