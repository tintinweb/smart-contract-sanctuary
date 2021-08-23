/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract STest {
    struct Item {
        address owner;          // Address of owner
        bool reserved;          // Is reserved for merging
        uint hash;              // item hash
        bool waitingForHash;    // item already got a hash
    }
    
    struct Owner {
        uint[] items;
    }
    
    // Mapping from token ID to owner address
    mapping(uint => Item) private _items;
    
    // Mapping owner address to token count
    uint256[] private _waitingForHash;
    
    uint256 private _itemCount;
    
    mapping(address => Owner) private _owners;

    function getToken(uint256 tokenId) public view returns (Item memory item){
        require(_items[tokenId].owner == address(0), "Token is not claimed yet!");
        
        return _items[tokenId];
    }
    
    function balanceOf(address owner) public view returns (Owner memory rOwner) {
        return _owners[owner];
    }
    
    function mint() public payable {
        uint256 amount = msg.value;
        address sender = msg.sender;
        
        require(amount < 10000000000000000, "Amount too low!");
        
        _items[_itemCount] = Item({
            owner: sender,
            reserved: false,
            hash: 0,
            waitingForHash: true
        });
        
        _owners[sender].items.push(_itemCount);
        
        _itemCount += 1;
        
    }
}