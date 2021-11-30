/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// contracts/SimpleStore.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract SimpleStore {
  struct Item {
    uint price;
    uint units; 
  }
  
  Item[] public items;

  function newItem(uint _price, uint _units)
  public
  {
    Item memory item = Item(_price, _units);
    items.push(item);
  }

  function getUsingStorage(uint _itemIdx)
  public view
  returns (uint)
  {
    Item storage item = items[_itemIdx];
    return item.units;
  }

  function addItemUsingStorage(uint _itemIdx, uint _units)
  public
  {
    Item storage item = items[_itemIdx];
    item.units += _units;
  }

}