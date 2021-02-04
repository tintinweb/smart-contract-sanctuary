// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IWrapper.sol";


contract OffchainOracle is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    event OracleAdded(IOracle oracle);
    event OracleRemoved(IOracle oracle);
    event WrapperAdded(IWrapper connector);
    event WrapperRemoved(IWrapper connector);
    event ConnectorAdded(IERC20 connector);
    event ConnectorRemoved(IERC20 connector);

    EnumerableSet.AddressSet private _oracles;
    EnumerableSet.AddressSet private _wrappers;
    EnumerableSet.AddressSet private _connectors;

    function oracles() external view returns (IOracle[] memory allOracles) {
        allOracles = new IOracle[](_oracles.length());
        for (uint256 i = 0; i < _oracles._inner._values.length; i++) {
            allOracles[i] = IOracle(uint256(_oracles._inner._values[i]));
        }
    }

    function wrappers() external view returns (IWrapper[] memory allWrappers) {
        allWrappers = new IWrapper[](_wrappers.length());
        for (uint256 i = 0; i < _wrappers._inner._values.length; i++) {
            allWrappers[i] = IWrapper(uint256(_wrappers._inner._values[i]));
        }
    }

    function connectors() external view returns (IERC20[] memory allConnectors) {
        allConnectors = new IERC20[](_connectors.length());
        for (uint256 i = 0; i < _connectors._inner._values.length; i++) {
            allConnectors[i] = IERC20(uint256(_connectors._inner._values[i]));
        }
    }

    function addOracle(IOracle oracle) external onlyOwner {
        require(_oracles.add(address(oracle)), "Oracle already added");
        emit OracleAdded(oracle);
    }

    function removeOracle(IOracle oracle) external onlyOwner {
        require(_oracles.remove(address(oracle)), "Unknown oracle");
        emit OracleRemoved(oracle);
    }

    function addWrapper(IWrapper wrapper) external onlyOwner {
        require(_wrappers.add(address(wrapper)), "Wrapper already added");
        emit WrapperAdded(wrapper);
    }

    function removeWrapper(IWrapper wrapper) external onlyOwner {
        require(_wrappers.remove(address(wrapper)), "Unknown wrapper");
        emit WrapperRemoved(wrapper);
    }

    function addConnector(IERC20 connector) external onlyOwner {
        require(_connectors.add(address(connector)), "Connector already added");
        emit ConnectorAdded(connector);
    }

    function removeConnector(IERC20 connector) external onlyOwner {
        require(_connectors.remove(address(connector)), "Unknown connector");
        emit ConnectorRemoved(connector);
    }

    function getRate(IERC20 srcToken, IERC20 dstToken) external view returns(uint256 weightedRate) {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "Can not be used onchain");
        require(srcToken != dstToken, "Tokens should not be the same");
        uint256 totalWeight;
        for (uint256 i = 0; i < _oracles._inner._values.length; i++) {
            for (uint256 j = 0; j < _connectors._inner._values.length; j++) {
                for (uint256 k1 = 0; k1 < _wrappers._inner._values.length; k1++) {
                    for (uint256 k2 = 0; k2 < _wrappers._inner._values.length; k2++) {
                        try IWrapper(uint256(_wrappers._inner._values[k1])).wrap(srcToken) returns (IERC20 wrappedSrcToken, uint256 srcRate) {
                            try IWrapper(uint256(_wrappers._inner._values[k2])).wrap(dstToken) returns (IERC20 wrappedDstToken, uint256 dstRate) {
                                try IOracle(uint256(_oracles._inner._values[i])).getRate(wrappedSrcToken, wrappedDstToken, IERC20(uint256(_connectors._inner._values[j]))) returns (uint256 rate, uint256 weight) {
                                    rate = rate.mul(srcRate).mul(dstRate).div(1e18).div(1e18);
                                    weightedRate = weightedRate.add(rate.mul(weight));
                                    totalWeight = totalWeight.add(weight);
                                } catch { continue; }
                            } catch { continue; }
                        } catch { continue; }
                    }
                }
            }
        }
        weightedRate = weightedRate.div(totalWeight);
    }
}