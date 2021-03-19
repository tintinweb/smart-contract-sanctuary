/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: GPL-v3-or-later
pragma solidity 0.8.1;

interface EMAOracle {
    function updateAndQuery() external returns (bool updated, uint256 value);
    function UPDATE_INTERVAL() external view returns (uint256);
    function lastUpdateTimestamp() external view returns (uint256);
}

contract EMAOracleWrapper {
    bool public initialized;
    EMAOracle public oracle;

    function init(address _oracle) external {
        require(!initialized, "EMAOracleWrapper: initialized");
        initialized = true;
        
        oracle = EMAOracle(_oracle);
    }
    
    function canExecute() public view returns (bool) {
      uint256 timeElapsed = block.timestamp - oracle.lastUpdateTimestamp();
      return timeElapsed >= oracle.UPDATE_INTERVAL();
    }

    function execute() external {
      require(canExecute(), "EMAOracleWrapper: Cannot execute");
      oracle.updateAndQuery();
    }
}