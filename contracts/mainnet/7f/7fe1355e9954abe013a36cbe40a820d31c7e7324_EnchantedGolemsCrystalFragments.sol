// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract EnchantedGolemsCrystalFragments is ERC1155, Ownable {
    using Address for address;
    
    bool public manualMintAllowed = true;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory _uri)
        ERC1155(_uri)
    {}
    
    /**
     * @dev Lock further manual minting by owner
     */
    function disableManualMint() public onlyOwner {
        manualMintAllowed = false;
    }
    
    /**
     * @dev Updates the metadata URI
     */
    function updateUri(string calldata newUri) public onlyOwner {
        _setURI(newUri);
    }
            
    /**
     * @dev Airdrop tokens to owners
     */
    function mintOwner(address[] calldata owners) public onlyOwner {
      require(manualMintAllowed, "Not allowed");
         
      for (uint256 i = 0; i < owners.length; i++) {
        _mint(owners[i], 0, 1, "");
      }
    }
}