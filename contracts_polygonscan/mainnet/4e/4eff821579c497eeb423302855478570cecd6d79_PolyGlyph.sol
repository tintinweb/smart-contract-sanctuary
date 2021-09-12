// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

/**

██████╗░░█████╗░██╗░░░░░██╗░░░██╗░██████╗░██╗░░░░░██╗░░░██╗██████╗░██╗░░██╗
██╔══██╗██╔══██╗██║░░░░░╚██╗░██╔╝██╔════╝░██║░░░░░╚██╗░██╔╝██╔══██╗██║░░██║
██████╔╝██║░░██║██║░░░░░░╚████╔╝░██║░░██╗░██║░░░░░░╚████╔╝░██████╔╝███████║
██╔═══╝░██║░░██║██║░░░░░░░╚██╔╝░░██║░░╚██╗██║░░░░░░░╚██╔╝░░██╔═══╝░██╔══██║
██║░░░░░╚█████╔╝███████╗░░░██║░░░╚██████╔╝███████╗░░░██║░░░██║░░░░░██║░░██║
╚═╝░░░░░░╚════╝░╚══════╝░░░╚═╝░░░░╚═════╝░╚══════╝░░░╚═╝░░░╚═╝░░░░░╚═╝░░╚═╝

*/


pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";



contract PolyGlyph is ERC721, Ownable {
    
    using SafeMath for uint256;

    string public PolyGlyph_PROVENANCE = "";

    uint256 public constant MAX_TOKENS = 10000;
    
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;

    uint256 private price = 50000000000000000000; // 50 Matic

    bool public isSaleActive = true;

    constructor() ERC721("PolyGlyph", "PolyGlyph") {}

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        PolyGlyph_PROVENANCE = _provenanceHash;
    }
        
    function reserveTokens(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }
    
    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();

        require(isSaleActive, "Sale is not active" );
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");
        require(totalSupply + _count < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price.mul(_count), "Ether value sent is not correct");
        
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }
     
    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    
    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}