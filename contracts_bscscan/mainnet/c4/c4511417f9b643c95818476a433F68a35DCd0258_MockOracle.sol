pragma solidity 0.6.12;

import "./Mock.sol";


contract MockOracle is Mock {
    bool private _validity = true;
    uint256 private _data;
    string public name;

    constructor(string memory name_) public {
        name = name_;
    }

    // Mock methods
    function getData()
        external view
        returns (uint256, bool)
    {
        return (_data, _validity);
    }

    // Methods to mock data on the chain
    function storeData(uint256 data)
        public
    {
        _data = data;
    }

    function storeValidity(bool validity)
        public
    {
        _validity = validity;
    }
}