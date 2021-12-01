// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * Gooddollar Kovan IdentityOracle.sol contract address: 0x16985787b2c032a68E24dE1D7DbCeFF10685Bc96
 *  - https://kovan.etherscan.io/address/0x16985787b2c032a68E24dE1D7DbCeFF10685Bc96#code
 */
/**
 * @title A testing contract for Gooddollar
 * @author LinkPool
 * @notice Mocks the method `setFulfillStateHashIPFSCID()` from the contract IdentityOracle.sol, which allows testing
 * the Gooddollar EA.
 */
contract MockIdentityOracle {
    /* ========== CONSUMER STATE VARIABLES ========== */

    bytes32 public stateHash;
    string public stateDataIPFS;

    // Maps
    mapping(address => bool) public oracleState;

    /* ========== MODIFIERS ========== */

    function _onlyOracle() internal view {
        require(oracleState[msg.sender], "only allowed oracle can call this method");
    }

    /* ========== MOCKED FUCNTIONS ========== */

    function setFulfillStateHashIPFSCID(bytes memory _statehashipfscid) public {
        _onlyOracle();
        (bytes32 _statehash, string memory _ipfscid) = abi.decode(_statehashipfscid, (bytes32, string));
        stateHash = _statehash;
        stateDataIPFS = _ipfscid;
    }

    /* ========== OTHER FUNCTIONS ========== */

    function setOracle(address _oracle, bool _isAllowed) public {
        oracleState[_oracle] = _isAllowed;
    }
}