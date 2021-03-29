"""
@title Greenwood Registry
@notice A storage contract for Greenwood Protocol contract addresses
@author Greenwood Labs
"""

# define the events used by the contract
event SetAddress:
    previousAddress: address
    newAddress: address
    contractName: String[20]
    version: String[11]
    governance: address
    blockNumber: uint256

event SetGovernance:
    previousGovernance: address
    newGovernance: address
    blockNumber: uint256

# define the storage variables used by the contract
governance: public(address)
versions: public(HashMap[String[11], HashMap[String[20], address]])

@external
def __init__(_governance: address):
    """
    @notice Contract constructor
    @param _governance The address of the Greenwood governance
    """

    # set the address of the Governance
    self.governance = _governance

@internal
def isGovernance(_caller: address, _role: String[20]) -> bool:
    """
    @notice Method for role-based security
    @param _caller The address that called the permissioned method
    @param _role The requested authorization level
    @return True if the caller is the Governance, False otherwise
    """

    # check if the requested role is "governance"
    if keccak256(_role) == keccak256("governance"):

        # return the equality comparison
        return self.governance == _caller

    # catch extraneous role arguments
    else:

        # revert
        raise "Unhandled role argument"
        
@external
def getAddress(_contract: String[20], _version: String[11]) -> address:
    """
    @notice Gets the address of a specified Greenwood contract
    @param _contract The name of the contract
    @param _version The version of the Greenwood Protocol that the contract belongs to
    @return An address
    """

    # get the address for the specified contract from storage and return it
    return self.versions[_version][_contract]

@external
def setAddress(_contract: String[20], _address: address, _version: String[11],):
    """
    @notice Stores the address of a specified Greenwood contract
    @param _contract The name of the contract that is being stored
    @param _address The address of the contract that is being stored
    @param _version The version of the Greenwood Protocol that the contract belongs to
    @dev Only the Governance can call this method
    """

    # require that the method caller is the governance
    assert self.isGovernance(msg.sender, "governance") == True, "Only Governance can call this method"

    # get the previous address for the contract
    previousAddress: address = self.versions[_version][_contract]

    # set the contract name and adddress for the specified version
    self.versions[_version][_contract] = _address

    # emit a SetAddress event
    log SetAddress(previousAddress, _address, _contract, _version, msg.sender, block.number) 

@external
def setGovernance(_new_governance: address):
    """
    @notice Updates the address of the Governance
    @param _new_governance The address of the new GReenwood governance
    @dev Only the Governance can call this method
    """

    # require that msg.sender is the current Governance
    assert self.isGovernance(msg.sender, "governance") == True, "Only Governance can call this method"

    # get the previous Governance 
    previousGovernance: address = self.governance

    # set the Registry Governance to be the value of _new_governance
    self.governance = _new_governance

    # emit a SetGovernance event
    log SetGovernance(previousGovernance, _new_governance, block.number)