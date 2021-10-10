pragma solidity ^0.8.0; 
 
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol"; 
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol"; 
// import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721.sol";

contract MorarableToken is ERC721 { 
    using Counters for Counters.Counter; 
    Counters.Counter private _tokenIds; 
    address Owner;
    address Creatorx = 0xf3fa94CD79cf118EB44B0de10C123E7E3d301504;
 
    constructor ()  ERC721("MorarableToken", "MORA") {
        Owner = msg.sender;
    } 

 
    struct Item { 
        uint256 id; 
        address creator; 
        string uri; 
    } 
 
    mapping (uint256 => Item) public Items; 

    function TakeCreateItem(string memory uri) external payable returns(uint256){
        payable(Owner).transfer(0.01 ether);
       return _createItem(uri);
    }
 
    function _createItem(string memory _uri) private returns (uint256){ 
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current(); 
        _safeMint(msg.sender, newItemId); 
 
        Items[newItemId] = Item(newItemId, msg.sender, _uri); 
 
        return newItemId; 
    } 
 
    function tokenURI(uint256 tokenId) public view override returns (string memory) { 
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token"); 
 
       return Items[tokenId].uri; 
    } 
}