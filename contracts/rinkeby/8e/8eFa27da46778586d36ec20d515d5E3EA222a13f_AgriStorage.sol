// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract AgriStorage {
    mapping(string => string) public Ledger;
    string public product_name;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function set_productname(string memory _productname) public {
        product_name = _productname;
    }

    function updateLedger(string memory _hashes) public {
        require(
            msg.sender == owner,
            "This can only be called by the contract owner!"
        );
        Ledger[product_name] = _hashes;
    }

    function check_ledger(string memory _productname)
        public
        view
        returns (string memory)
    {
        return Ledger[_productname];
    }
}