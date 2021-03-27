/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.26;


contract MVM {

  struct Record {
    bool exists;
    string info;
  }

  mapping(string => Record[]) data;

  // If you want to iterate the whole thing, you can use this:
  string[] keysNames;

  function set(string key, string value) {
      // Remove this if, if you don't need iteration
      if (data[key].length == 0) {
          keysNames.push(key);
      }

      data[key].push(Record(true, value));
  }

  function num_of(string key) constant returns (uint) {
    return data[key].length;
  }

  function get(string key, uint index) constant returns (string) {
    if (data[key][index].exists == false) {
      throw;
    }
    return data[key][index].info;
  }

  function exampleIterate() constant returns (string last) {
      uint keysLen = keysNames.length;

      for(uint i = 0; i < keysLen; i++) {
        uint recordsLen = data[keysNames[i]].length;

        for(uint j = 0; j < recordsLen; j++) {          
          last = data[keysNames[i]][j].info;
        }
      }
  }

}