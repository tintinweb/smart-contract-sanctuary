//SPDX- License - Identifier: GPL-3.0

pragma solidity ^0.5.0;

import "./ERC721Full.sol";




contract OnerareCollections is ERC721Full {
    uint256 public tokenCounter;
    address[] public winners; 
    address public admin;
    string public tokenHash="QmZL76eoJeA6tGgY5HngEN4T6rAhCGSbvvD3HPgptv5BnK";
    
    constructor() public ERC721Full("OneRare Ingredients", "ORAREI") {
          admin=msg.sender;
        }

    function createItem(address user, string memory tokenURI)
        public
        returns (uint256)
    {
    require(msg.sender==admin,'Only admin can mint NFTs');
       uint256 newItemId=tokenCounter;
       _mint(user,newItemId);
       _setTokenURI(newItemId,tokenURI);
       
       tokenCounter=tokenCounter+1;
       return newItemId;

    }
    
 function addMulWinners(address[] memory users)
        public
       
    {
         require(msg.sender==admin,'Only admin can add winners');
        for (uint256 i = 0; i < users.length; i++) {
            uint256 currentWinners = winners.length;
            
             if (currentWinners >= 1000) {
              break;
            }
            winners.push(users[i]);
           
            
        }
       
    }
    
    function winnersCount()
        public
        view returns (uint256)
       
    {
       return winners.length;
       
    }
        
 function distributeAirdrop(uint256 startsFrom)
        public
    {
        require(msg.sender==admin,'Only admin can distrubute reward');
        
        for (uint256 i = startsFrom; i < startsFrom+50; i++) {
           
           createItem(winners[i], tokenHash);
            
        }
    }
    
}