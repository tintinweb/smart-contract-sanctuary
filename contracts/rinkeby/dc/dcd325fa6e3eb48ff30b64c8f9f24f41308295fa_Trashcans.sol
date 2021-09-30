// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './TrashFunctions.sol';
import './Metadata.sol';

contract Trashcans is ERC721Enumerable, Ownable, TrashFunctions, Metadata {
  
    using Strings for uint256;
  
  uint256 public constant FREE_DROP = 1000;  
  uint256 public constant MAIN_DROP = 9000;
  uint256 public constant BURN_1 = 10000;  
  uint256 public constant BURN_2 = 10000;    
  uint256 public constant BURN_3 = 10000;    

  uint256 public constant NFT_MAX = FREE_DROP + MAIN_DROP + BURN_1 + BURN_2 + BURN_3;
  uint256 public constant PURCHASE_LIMIT = 30;
  
  uint256 public constant MAIN_PRICE = 0.01 ether;
  uint256 public constant FREE_PRICE = 0 ether;

  bool public isBurnActive = false;
  bool public isMasterActive = false;

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalFreeSupply;
  uint256 public totalMainSupply;
  uint256 public totalBurn1Supply;
  uint256 public totalBurn2Supply;  
  uint256 public totalBurn3Supply;  

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  
  event Burn1(
      uint256 oneTokenId1, 
      uint256 twoTokenId1,
      uint256 threeTokenId1,
      uint256 fourTokenId1,
      uint256 fiveTokenId1,
      uint256 sixTokenId1,
      uint256 sevenTokenId1,
      uint256 eightTokenId1,
      uint256 nineTokenId1,
      uint256 tenTokenId1,
            uint256 newTokenId1);
            
  event Burn2(
          uint256 oneTokenId2, 
      uint256 twoTokenId2,
      uint256 threeTokenId2,
      uint256 fourTokenId2,
      uint256 fiveTokenId2,
      uint256 sixTokenId2,
      uint256 sevenTokenId2,
      uint256 eightTokenId2,
      uint256 nineTokenId2,
      uint256 tenTokenId2,
            uint256 newTokenId2);
  
  event Burn3(
        uint256 matchBurn1,
        uint256 matchBurn2,
            uint256 newTokenId3);



    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
}
  
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {

  }
  
  function mintTrash(uint256 numberOfTokens) external override payable {

    if (totalSupply() < 1000) {  
      
    require(isMasterActive, 'Contract is not active');
    
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
    require(totalFreeSupply + numberOfTokens <= FREE_DROP, 'Purchase would exceed max supply');
    
    require(FREE_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId =  totalFreeSupply + 1;

      totalFreeSupply += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }
    
     if (totalSupply() >= 1000) {  
      
    require(isMasterActive, 'Contract is not active');
    
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
    require(totalFreeSupply + totalMainSupply + numberOfTokens <= FREE_DROP + MAIN_DROP, 'Purchase would exceed max supply');
    
    require(MAIN_PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId =  totalFreeSupply + totalMainSupply + 1;

      totalMainSupply += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }

  }
      
  

  function MasterActive(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
  }
  
    function BurnActive(bool _isBurnActive) external override onlyOwner {
    isBurnActive = _isBurnActive;
  }
 
  
  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    /// @dev Convert string to bytes so we can check if it's empty or not.
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
  
    function burn1(uint256 oneTokenId1, uint256 twoTokenId1, uint256 threeTokenId1, 
            uint256 fourTokenId1, uint256 fiveTokenId1, uint256 sixTokenId1, uint256 sevenTokenId1, 
                uint256 eightTokenId1, uint256 nineTokenId1, uint256 tenTokenId1) public  {
        
        require(isMasterActive, 'Contract is not active');
        require(isBurnActive, "Burn is not active");
        
        require(_isApprovedOrOwner(_msgSender(), oneTokenId1) 
        && _isApprovedOrOwner(_msgSender(), twoTokenId1)
        && _isApprovedOrOwner(_msgSender(), threeTokenId1) 
        && _isApprovedOrOwner(_msgSender(), fourTokenId1) 
        && _isApprovedOrOwner(_msgSender(), fiveTokenId1) 
        && _isApprovedOrOwner(_msgSender(), sixTokenId1) 
        && _isApprovedOrOwner(_msgSender(), sevenTokenId1) 
        && _isApprovedOrOwner(_msgSender(), eightTokenId1) 
        && _isApprovedOrOwner(_msgSender(), nineTokenId1) 
                && _isApprovedOrOwner(_msgSender(), tenTokenId1), "Caller is not owner nor approved");

        
        // burn the 10 tokens
        _burn(oneTokenId1);
        _burn(twoTokenId1);
        _burn(threeTokenId1);
        _burn(fourTokenId1);
        _burn(fiveTokenId1);
        _burn(sixTokenId1);  
        _burn(sevenTokenId1);          
        _burn(eightTokenId1);  
        _burn(nineTokenId1);  
        _burn(tenTokenId1); 
        

        // mint new token
        uint256 newTokenId1 = FREE_DROP + MAIN_DROP + 1;
        _safeMint(msg.sender, newTokenId1);
        totalBurn1Supply += 1;

        // fire event in logs
        emit Burn1(oneTokenId1, twoTokenId1, threeTokenId1, fourTokenId1, 
            fiveTokenId1, sixTokenId1, sevenTokenId1, eightTokenId1, nineTokenId1, tenTokenId1, newTokenId1);
    }
    
   function burn2(uint256 oneTokenId2, uint256 twoTokenId2, uint256 threeTokenId2, 
            uint256 fourTokenId2, uint256 fiveTokenId2, uint256 sixTokenId2, uint256 sevenTokenId2, 
                uint256 eightTokenId2, uint256 nineTokenId2, uint256 tenTokenId2) public  {
        
        require(isMasterActive, 'Contract is not active');
        require(isBurnActive, "Burn is not active");
        
                require(_isApprovedOrOwner(_msgSender(), oneTokenId2) 
        && _isApprovedOrOwner(_msgSender(), twoTokenId2)
        && _isApprovedOrOwner(_msgSender(), threeTokenId2) 
        && _isApprovedOrOwner(_msgSender(), fourTokenId2) 
        && _isApprovedOrOwner(_msgSender(), fiveTokenId2) 
        && _isApprovedOrOwner(_msgSender(), sixTokenId2) 
        && _isApprovedOrOwner(_msgSender(), sevenTokenId2) 
        && _isApprovedOrOwner(_msgSender(), eightTokenId2) 
        && _isApprovedOrOwner(_msgSender(), nineTokenId2) 
                && _isApprovedOrOwner(_msgSender(), tenTokenId2), "Caller is not owner nor approved");
        
        // burn the 10 tokens
        _burn(oneTokenId2);
        _burn(twoTokenId2);
        _burn(threeTokenId2);
        _burn(fourTokenId2);
        _burn(fiveTokenId2);
        _burn(sixTokenId2);  
        _burn(sevenTokenId2);          
        _burn(eightTokenId2);  
        _burn(nineTokenId2);  
        _burn(tenTokenId2); 
        

        // mint new token
        uint256 newTokenId2 = FREE_DROP + MAIN_DROP + BURN_1 + 1;
        _safeMint(msg.sender, newTokenId2);
        totalBurn2Supply += 1;

        // fire event in logs
        emit Burn2(oneTokenId2, twoTokenId2, threeTokenId2, fourTokenId2, 
            fiveTokenId2, sixTokenId2, sevenTokenId2, eightTokenId2, nineTokenId2, tenTokenId2, newTokenId2);
    }
    
   function burn3(uint256 matchBurn1, uint256 matchBurn2) public  {
        
        require(matchBurn1 >= 10000, 'Token ID need to be within the burn1 range');
        require(matchBurn1 < 20000, 'Token ID need to be within the burn1 range');
        require(matchBurn2 >= 20000, 'Token ID need to be within the burn2 range');
        require(matchBurn2 < 30000, 'Token ID need to be within the burn2 range');

               require(_isApprovedOrOwner(_msgSender(), matchBurn1) 
                && _isApprovedOrOwner(_msgSender(), matchBurn2), "Caller is not owner nor approved");

        require(isMasterActive, 'Contract is not active');
        require(isBurnActive, "Burn is not active");
        
        // burn
        _burn(matchBurn1);
        _burn(matchBurn2);

        // mint new token
        uint256 newTokenId3 = FREE_DROP + MAIN_DROP + BURN_1 + BURN_2 + 1;
        _safeMint(msg.sender, newTokenId3);
        totalBurn3Supply += 1;

        // fire event in logs
        emit Burn3(matchBurn1, matchBurn2, newTokenId3);
    }
    
  

}