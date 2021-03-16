pragma solidity ^0.6.0;

import './interfaces/IDistributor.sol';

contract Distributor {
    IDistributor[] public distributors;

    constructor(IDistributor[] memory _distributors) public {
        distributors = _distributors;
    }

    function distribute() public {
        for (uint256 i = 0; i < distributors.length; i++) {
            distributors[i].distribute();
        }
    }
}

pragma solidity ^0.6.0;

interface IDistributor {
    function distribute() external;
}