/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.5;

contract MyContract {
    //struct entspricht 'Tabellenspalten'
    struct DataType {
        string name;
        uint256 age;
    }
    
    //Liste der Tabellenspalten: Zeilen
    mapping (uint256 => DataType) table;

  function addRow(uint256 _indexId, string memory _name, uint256 _age) public {
        require(_indexId > 0);
        table[_indexId] = DataType(_name, _age);
    }

    function getRow(uint256 _indexId) public view returns (string memory _name, uint256 _age){
        _name = table[_indexId].name;
        _age = table[_indexId].age;
        
    }
}