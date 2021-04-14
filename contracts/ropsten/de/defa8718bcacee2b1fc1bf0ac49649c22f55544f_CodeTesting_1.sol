// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";


contract CodeTesting_1 is ERC721,Pausable, Ownable, ERC721Burnable {
            
            using Counters for Counters.Counter;
            Counters.Counter private _tokenIds;
            constructor(string memory myName, string memory mySymbol) ERC721(myName, mySymbol) public {}
           

            function minttoken(address recipient,  string memory metadata )public returns (uint256)
            {
               uint256 newItemId ;
                  
               _tokenIds.increment();
               newItemId = _tokenIds.current();
               _mint(recipient, newItemId);
               _setTokenURI(newItemId, metadata);               
               return newItemId;  
            }

            function pause() public onlyOwner {
               _pause();
            }

            function unpause() public onlyOwner {
               _unpause();
            }

            function _beforeTokenTransfer(address from, address to, uint256 tokenId)
            internal
            whenNotPaused
            override
            {
               super._beforeTokenTransfer(from, to, tokenId);
            }

            

}