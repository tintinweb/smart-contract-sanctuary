pragma solidity ^0.5.2;

contract IsItConstantinopleYet {
    
    function isItConstantinopleYet() external view returns(bool) {
        return block.number >= 7080000 ? true : false;
    }
    
}