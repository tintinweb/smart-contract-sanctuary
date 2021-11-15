pragma solidity 0.8.4;

contract IronTreasuryProxy {
    mapping(address => bool) public hasPool;

    constructor(address[] memory pools) {
        for (uint256 i = 0; i < pools.length; i++) {
            hasPool[pools[i]] = true;
        }
    }
}

