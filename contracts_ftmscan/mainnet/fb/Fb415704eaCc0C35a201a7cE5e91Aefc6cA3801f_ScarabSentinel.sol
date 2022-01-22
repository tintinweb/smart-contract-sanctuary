/**
 *Submitted for verification at FtmScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ScarabStrategy {
    function pause() external;
    function unpause() external;
    function panic() external;
}

pragma solidity ^0.6.0;

contract ScarabSentinel {

    address public owner;
    address[] strategy;
    address public zeroAddress = address(0x0000000000000000000000000000000000000000);

    struct ZeroStrat {
        uint256[] strat;
    }

    constructor ()
    public {
        owner = msg.sender;
    }

    ////////////
    // Public //
    ////////////

    function reportStrategyLength() public view returns (uint256) {
        return strategy.length;
    }

    function strategyIndex(uint256 index) public view returns (address) {
        return strategy[index];
    }
        
    function findStrategyIndex(address _strategy) public view returns (uint256) {
        uint256 index;

        for (uint256 i = 0; i < strategy.length; i++) {
            if (strategy[i] == _strategy) {
                index = i;
            }
        }

        return index;
    }

    function findZeroStrategy() public view returns (uint256) {
        uint256 zero;

        for (uint256 i = 0; i < strategy.length; i++){
            if (strategy[i] == address(0x0000000000000000000000000000000000000000)) {
                zero = i;
            }
        }

        return zero;
    }

    ////////////////
    // Restricted //
    ////////////////

    function overwriteStrategyIndex(uint256 index, address _newStrategy) external {
        require(msg.sender == owner, "!auth");

        strategy[index] = _newStrategy;
    }

    function removeStrategyFromIndex(address _strategyToRemove) external {
        require(msg.sender == owner, "!auth");
        for (uint256 i = 0; i < strategy.length; i++) {
            if (strategy[i] == _strategyToRemove) {
                delete strategy[i];
            }
        }
    }

    function addNewStrategy(address _strat) external {
        require(msg.sender == owner, "!auth");
        strategy.push(_strat);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "!auth");
        owner = _owner;
    }

    function pauseAll(uint8 start, uint8 end) external {
        require(msg.sender == owner, "!auth");

        for(uint8 i = start; i < end + 1; i++) {
            if (strategy[i] != zeroAddress) {
                try ScarabStrategy(strategy[i]).pause()
                {} catch {}
            }
        }
    }

    function unpauseAll(uint8 start, uint8 end) external {
        require(msg.sender == owner, "!auth");
        
        for(uint8 i = start; i < end + 1; i++) {
            if (strategy[i] != zeroAddress) {
                try ScarabStrategy(strategy[i]).unpause()
                {} catch {}
            }
        }
    }
}