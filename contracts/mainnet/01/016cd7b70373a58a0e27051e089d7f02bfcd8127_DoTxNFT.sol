pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract DoTxNFT is ERC721, ERC721Burnable, ERC721Pausable, Ownable {

    mapping(uint256 => uint256) public nextHouseId;
    mapping(uint256 => uint256) public supply;
    

    uint32 public constant ID_TO_HOUSE = 1000000;
    event NewHouse(uint256 id, uint256 maxSupply);

    constructor(string memory _baseUrl) public ERC721("DeFi of Thrones", "DoTxNFT"){
        setBaseURI(_baseUrl);
    }
    
    function newHouse(uint256 _houseId, uint256 _maxSupply) external onlyOwner {
        require(_maxSupply <= ID_TO_HOUSE, "DoTxNFT: max supply too high");
        require(supply[_houseId] == 0, "DoTxNFT: house already exist");

        supply[_houseId] = _maxSupply;
        NewHouse(_houseId, _maxSupply);
    }
    
    function mintHousesBatch(address _to, uint256[] memory _houseIds, uint256[] memory _count) public onlyOwner {
        for(uint256 i=0; i < _houseIds.length; i++){
            mintBatch(_to, _houseIds[i], _count[i]);
        }
    }
    
    function mintBatch(address _to, uint256 _houseId, uint256 _count) public onlyOwner {
        require(supply[_houseId] != 0, "DoTxNFT: house does not exist");
        
        for(uint256 i=0; i < _count; i++){
            mint(_to, _houseId);
        }
    }
    
    function mint(address _to, uint256 _houseId) private onlyOwner {
        require(nextHouseId[_houseId] < supply[_houseId], "DoTxNFT: house sold out");
        
        nextHouseId[_houseId]++;
        uint256 tokenId = _houseId * ID_TO_HOUSE + nextHouseId[_houseId];
        
        _mint(_to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function setBaseURI(string memory _baseUrl) public onlyOwner{
        _setBaseURI(_baseUrl);
    }

    function getTokensByOwner(address _owner) public view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);

            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }

            return result;
        }
    }
}