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
        external
        returns (uint256, bool)
    {
        emit FunctionCalled(name, "getData", msg.sender);
        uint256[] memory uintVals = new uint256[](0);
        int256[] memory intVals = new int256[](0);
        emit FunctionArguments(uintVals, intVals);
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