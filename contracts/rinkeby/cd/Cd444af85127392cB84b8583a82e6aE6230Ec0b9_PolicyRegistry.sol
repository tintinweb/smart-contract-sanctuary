pragma solidity ^0.4.24;

/**
 *  @title PolicyRegistry
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A contract to maintain a policy for each subcourt.
 */
contract PolicyRegistry {
    /* Events */

    /** @dev Emitted when a policy is updated.
     *  @param _subcourtID The ID of the policy's subcourt.
     *  @param _policy The URI of the policy JSON.
     */
    event PolicyUpdate(uint indexed _subcourtID, string _policy);

    /* Storage */

    address public governor;
    mapping(uint => string) public policies;

    /* Modifiers */

    /** @dev Requires that the sender is the governor. */
    modifier onlyByGovernor() {require(governor == msg.sender, "Can only be called by the governor."); _;}

    /* Constructor */

    /** @dev Constructs the `PolicyRegistry` contract.
     *  @param _governor The governor's address.
     */
    constructor(address _governor) public {governor = _governor;}

    /* External */

    /** @dev Changes the `governor` storage variable.
     *  @param _governor The new value for the `governor` storage variable.
     */
    function changeGovernor(address _governor) external onlyByGovernor {governor = _governor;}

    /** @dev Sets the policy for the specified subcourt.
     *  @param _subcourtID The ID of the specified subcourt.
     *  @param _policy The URI of the policy JSON.
     */
    function setPolicy(uint _subcourtID, string _policy) external onlyByGovernor {
        policies[_subcourtID] = _policy;
        emit PolicyUpdate(_subcourtID, policies[_subcourtID]);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}