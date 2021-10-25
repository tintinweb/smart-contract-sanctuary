// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BFTest {

    
    string private _contractVersion;


    constructor() {
        _contractVersion = "0.0.1";
    }


    function setContractVersion(string memory version) public virtual  {
        _contractVersion = version;
    }

    function getContractVersion() public virtual view returns (string memory){
        return _contractVersion;
    }

}