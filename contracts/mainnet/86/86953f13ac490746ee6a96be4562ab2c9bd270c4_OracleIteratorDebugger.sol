// File: contracts/oracleIterators/IOracleIterator.sol

// "SPDX-License-Identifier: GNU General Public License v3.0"

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
    /// @param _roundHints specified rounds for a given timestamp
    /// @return the value closest to a given timestamp
    function getUnderlingValue(address _oracle, uint _timestamp, uint[] memory _roundHints) external view returns(int);
}

// File: contracts/oracleIterators/OracleIteratorDebugger.sol

pragma solidity >=0.4.21 <0.7.0;


contract OracleIteratorDebugger {

    int public underlingValue;

    function updateUnderlingValue(address _oracleIterator, address _oracle, uint _timestamp, uint[] memory _roundHints) public {
        require(_timestamp > 0, "Zero timestamp");
        require(_oracle != address(0), "Zero oracle");
        require(_oracleIterator != address(0), "Zero oracle iterator");

        IOracleIterator oracleIterator = IOracleIterator(_oracleIterator);
        underlingValue = oracleIterator.getUnderlingValue(_oracle, _timestamp, _roundHints);
    }
}