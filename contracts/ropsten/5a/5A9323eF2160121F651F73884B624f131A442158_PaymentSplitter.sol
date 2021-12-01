// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract PaymentSplitter {
    uint public totalSplitters = 0;
    
    mapping(uint => address[]) splitterAddresses;
    mapping(uint => uint[]) splitterPercentages;
    
    function createSplitter(address[] memory addresses, uint[] memory percentages) public returns (uint) {
        require(addresses.length == percentages.length, "addresses and percentages must have same length");
        uint percentagesSum = 0;
        for (uint i = 0; i < percentages.length; i++) {
            percentagesSum += percentages[i];
        }
        require(percentagesSum == 10000000, "percentages sum must be 100%");
        
        uint splitterIndex = totalSplitters++;
        
        splitterAddresses[splitterIndex] = addresses;
        splitterPercentages[splitterIndex] = percentages;
        
        return splitterIndex;
    }
    
    function getSplitter(uint id) public view returns (address[] memory addresses, uint[] memory percentages) {
        uint length = splitterAddresses[id].length;
        address[] memory _addresses = new address[](length);
        uint[] memory _percentages = new uint[](length);
        
        for (uint i = 0; i < length; i++) {
            _addresses[i] = splitterAddresses[id][i];
            _percentages[i] = splitterPercentages[id][i];
        }
        
        return (_addresses, _percentages);
    }
    
    function pay(uint id) public payable {
        require(id < totalSplitters, "splitter does not exists");
        uint length = splitterAddresses[id].length;
        for (uint i = 0; i < length; i++) {
            payable(splitterAddresses[id][i]).transfer(msg.value * splitterPercentages[id][i] / 10000000);
        }
    }
}