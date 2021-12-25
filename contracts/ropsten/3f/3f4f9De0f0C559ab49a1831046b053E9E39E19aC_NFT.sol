// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC2981.sol";

contract NFT is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    
    constructor() ERC721("CodeTestNFT", "NFT") {}
    
    uint256 private token_id = 0;

    address private royaltyReceiver;

    uint256 private tokenPrice = 1000000000000000000;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    event Purchased(uint256 tokenId, address seller, address indexed buyer, uint256 value);

    function safeMint(address to, uint256 count) public onlyOwner{
        for(uint16 i = 0; i < count; i++){
            token_id++;
            _safeMint(to, token_id);
        }
    }

    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal view returns (bool) {
        IERC2981(_contract).
        supportsInterface(_INTERFACE_ID_ERC2981);
        return true;
    }

    function mint(uint256 tokenId) public payable{
        require(msg.value > 0 && msg.value == tokenPrice, "Amount sent too low"); 
         // Pay royalties if applicable
        if (_checkRoyalties(address(this))) {
            payable(ownerOf(tokenId)).transfer(msg.value.mul(5).div(100));      // Transfer 5% royalty to the creator.
            payable(royaltyReceiver).transfer(msg.value.mul(3).div(100));     // Transfer 3% royalty to the mint.
        }     
       
        payable(owner()).transfer(address(this).balance);             // Transfer remaining funds to the admin.
        emit Purchased(tokenId, ownerOf(tokenId), msg.sender, msg.value);
        _transfer(ownerOf(tokenId), msg.sender, tokenId);  
    }

    function setTokenPrice(uint256 price) public onlyOwner{
        tokenPrice = price;
    }

    function setRoyaltyReceiver(address receiver) public onlyOwner {
        royaltyReceiver = receiver;
    }

    function setBaseURI(string memory baseURI) external onlyOwner virtual {
        _setBaseURI(baseURI);
    }  

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);        
    }
    
    function getToken(uint256 tokenId) public view virtual returns (address, string memory) {
        address owner = ownerOf(tokenId);
        string memory ipfs =  tokenURI(tokenId);
        return (owner, ipfs);
    }

    function getPrice() public view virtual returns (uint256){
        return tokenPrice;
    }

    function getRoyalityReceiver() public view virtual returns (address){
        return royaltyReceiver;
    }

}