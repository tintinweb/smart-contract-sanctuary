/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";

// contract GameItem is ERC721 {
//     using Counters for Counters.Counter;
//     Counters.Counter private _tokenIds;

//     constructor() public ERC721("GameItem", "ITM") {}

//     function awardItem(address player, string memory tokenURI)
//         public
//         returns (uint256)
//     {
//         _tokenIds.increment();

//         uint256 newItemId = _tokenIds.current();
//         _mint(player, newItemId);
//         // _setTokenURI(newItemId, tokenURI);

//         return newItemId;
//     }
// }

contract GameItem {
    uint public count = 0;
    
    function increment() public returns (uint){
        count += 1;
        return count;
    }
    
    
}