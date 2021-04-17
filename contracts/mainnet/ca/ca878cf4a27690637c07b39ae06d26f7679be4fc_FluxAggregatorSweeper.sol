// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./IFluxAggregator.sol";
import "./Sweeper.sol";

/**
 * @title FluxAggregatorSweeper
 * @dev Handles withdrawing of rewards from flux aggregator Chainlink contracts.
 */
contract FluxAggregatorSweeper is Sweeper {
    address public oracle;

    constructor(
        address _nodeRewards,
        uint256 _minTowithdraw,
        address _oracle
    ) Sweeper(_nodeRewards, _minTowithdraw) {
        oracle = _oracle;
    }

    /**
     * @dev returns withdrawable amount for each flux aggregator
     * @return withdrawable balance of each flux aggregator
     **/
    function withdrawable() external view override returns (uint256[] memory) {
        uint256[] memory _withdrawable = new uint256[](contracts.length);
        for (uint i = 0; i < contracts.length; i++) {
            _withdrawable[i] = IFluxAggregator(contracts[i]).withdrawablePayment(oracle);
        }
        return _withdrawable;
    }

    /**
     * @dev withdraw rewards from flux aggregators
     * @param _contractIdxs indexes corresponding to the flux aggregators
     **/
    function _withdraw(uint256[] calldata _contractIdxs) internal override {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            require(_contractIdxs[i] < contracts.length, "contractIdx must be < contracts length");
            IFluxAggregator aggregator = IFluxAggregator(contracts[_contractIdxs[i]]);
            uint256 amount = aggregator.withdrawablePayment(oracle);
            if (amount >= minToWithdraw) {
                aggregator.withdrawPayment(oracle, msg.sender, amount);
            }
        }
    }

    /**
     * @dev transfers admin to new address for selected flux aggregators
     * @param _contractIdxs indexes corresponsing to flux aggregators
     * @param _newAdmin address to transfer admin to
     **/
    function _transferAdmin(uint256[] calldata _contractIdxs, address _newAdmin) internal override {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            require(_contractIdxs[i] < contracts.length, "contractIdx must be < contracts length");
            IFluxAggregator(contracts[_contractIdxs[i]]).transferAdmin(oracle, _newAdmin);
        }
    }

    /**
     * @dev accepts admin for flux aggregators
     * @param _contractIdxs corresponding to the flux aggregators
     **/
    function _acceptAdmin(uint256[] calldata _contractIdxs) internal override {
        for (uint i = 0; i < _contractIdxs.length; i++) {
            require(_contractIdxs[i] < contracts.length, "contractIdx must be < contracts length");
            IFluxAggregator(contracts[_contractIdxs[i]]).acceptAdmin(oracle);
        }
    }
}