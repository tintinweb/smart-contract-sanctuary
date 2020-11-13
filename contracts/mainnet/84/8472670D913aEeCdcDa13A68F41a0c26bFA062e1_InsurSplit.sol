// File: contracts/collateralSplits/ICollateralSplit.sol



pragma solidity >=0.4.21 <0.7.0;

/// @title Collateral Split interface
/// @notice Contains mathematical functions used to calculate relative claim
/// on collateral of primary and complement assets after settlement.
/// @dev Created independently from specification and published to the CollateralSplitRegistry
interface ICollateralSplit {

    /// @notice Proof of collateral split contract
    /// @dev Verifies that contract is a collateral split contract
    /// @return true if contract is a collateral split contract
    function isCollateralSplit() external pure returns(bool);

    /// @notice Symbol of the collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split specification symbol
    function symbol() external view returns (string memory);

    /// @notice Calcs primary asset class' share of collateral at settlement.
    /// @dev Returns ranged value between 0 and 1 multiplied by 10 ^ 12
    /// @param _underlyingStartRoundHints specify for each oracle round of the start of Live period
    /// @param _underlyingEndRoundHints specify for each oracle round of the end of Live period
    /// @return _split primary asset class' share of collateral at settlement
    /// @return _underlyingStart underlying value in the start of Live period
    /// @return _underlyingEnd underlying value in the end of Live period
    function split(
        address[] memory _oracles,
        address[] memory _oracleIterators,
        uint _liveTime,
        uint _settleTime,
        uint[] memory _underlyingStartRoundHints,
        uint[] memory _underlyingEndRoundHints)
    external view returns(uint _split, int _underlyingStart, int _underlyingEnd);
}

// File: contracts/oracleIterators/IOracleIterator.sol



pragma solidity >=0.4.21 <0.7.0;

interface IOracleIterator {
    /// @notice Proof of oracle iterator contract
    /// @dev Verifies that contract is a oracle iterator contract
    /// @return true if contract is a oracle iterator contract
    function isOracleIterator() external pure returns(bool);

    /// @notice Symbol of the oracle iterator
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbol
    function symbol() external view returns (string memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    //  finds the value closest to a given timestamp
    /// @param _oracle iteratable oracle through
    /// @param _timestamp a given timestamp
    /// @param _roundHint specified round for a given timestamp
    /// @return the value closest to a given timestamp
    function getUnderlingValue(address _oracle, uint _timestamp, uint _roundHint) external view returns(int);
}

// File: contracts/collateralSplits/CollateralSplitParent.sol



pragma solidity >=0.4.21 <0.7.0;



abstract contract CollateralSplitParent is ICollateralSplit {
    int public constant FRACTION_MULTIPLIER = 10**12;
    int public constant NEGATIVE_INFINITY = type(int256).min;

    function isCollateralSplit() external override pure returns(bool) {
        return true;
    }

    function split(
        address[] memory _oracles,
        address[] memory _oracleIterators,
        uint _liveTime,
        uint _settleTime,
        uint[] memory _underlyingStartRoundHints,
        uint[] memory _underlyingEndRoundHints)
    external override virtual view returns(uint _split, int _underlyingStart, int _underlyingEnd) {
        require(_oracles.length == 1, "More than one oracle");
        require(_oracles[0] != address(0), "Oracle is empty");
        require(_oracleIterators[0] != address(0), "Oracle iterator is empty");

        IOracleIterator iterator = IOracleIterator(_oracleIterators[0]);
        require(iterator.isOracleIterator(), "Not oracle iterator");

        _underlyingStart = iterator.getUnderlingValue(_oracles[0], _liveTime, _underlyingStartRoundHints[0]);
        _underlyingEnd = iterator.getUnderlingValue(_oracles[0], _settleTime, _underlyingEndRoundHints[0]);

        _split = range(
            splitNominalValue(
                normalize( _underlyingStart, _underlyingEnd )
            )
        );
    }

    function splitNominalValue(int _normalizedValue) public virtual pure returns(int);

    function normalize(int _u_0, int _u_T) public virtual pure returns(int){
        require(_u_0 != NEGATIVE_INFINITY, "u_0 is absent");
        require(_u_T != NEGATIVE_INFINITY, "u_T is absent");
        require(_u_0 > 0, "u_0 is less or equal zero");

        if(_u_T < 0) {
            _u_T = 0;
        }

        return (_u_T - _u_0) * FRACTION_MULTIPLIER / _u_0;
    }

    function range(int _split) public pure returns(uint) {
        if(_split >= FRACTION_MULTIPLIER) {
            return uint(FRACTION_MULTIPLIER);
        }
        if(_split <= 0) {
            return 0;
        }
        return uint(_split);
    }
}

// File: contracts/collateralSplits/InsurSplit.sol

// "SPDX-License-Identifier: GNU General Public License v3.0"

pragma solidity >=0.4.21 <0.7.0;


contract InsurSplit is CollateralSplitParent{
    function symbol() external override view returns (string memory) {
        return 'Insur';
    }

    function splitNominalValue(int _normalizedValue) public override pure returns(int _split){
        _split = 0;
        if(_normalizedValue >= 0) {
            _split = FRACTION_MULTIPLIER / 2; // 0.5
        }

        if(_normalizedValue < -(FRACTION_MULTIPLIER/2)) {
            _split = FRACTION_MULTIPLIER; // 1
        }

        if(_normalizedValue >= -(FRACTION_MULTIPLIER/2) && _normalizedValue < 0) {
            _split = (FRACTION_MULTIPLIER * FRACTION_MULTIPLIER) / ((2 * (FRACTION_MULTIPLIER + _normalizedValue)));  // 1 / 2 * ( 1 + U_T)
        }
    }
}