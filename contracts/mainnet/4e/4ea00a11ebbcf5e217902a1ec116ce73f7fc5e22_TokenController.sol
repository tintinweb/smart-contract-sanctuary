/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// File: contracts/controllableToken/TokenControllerI.sol

pragma solidity 0.4.19;

/// @title Interface for token controllers. The controller specifies whether a transfer can be done.
contract TokenControllerI {

    /// @dev Specifies whether a transfer is allowed or not.
    /// @return True if the transfer is allowed
    function transferAllowed(address _from, address _to) external view returns (bool);
}

// File: contracts/Ownable.sol

pragma solidity 0.4.19;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/controllableToken/TokenController.sol

pragma solidity 0.4.19;



contract TokenController is TokenControllerI, Ownable {

    event ContractReady();
    event SourceAddressDenyListed(address denyListedAddress);
    event SourceAddressAllowed(address allowedAddress);
    event TargetAddressAllowListed(address allowedAddress);
    event TargetAddressDisallowed(address disallowedAddress);

    bool public isReady;

    mapping(address=>bool) public sourceDenyMapping;
    mapping(address=>bool) public targetAllowMapping;

    modifier whenPreparing(){
        require(!isReady);
        _;
    }

    function transferAllowed(address _from, address _to) external view returns (bool){
        if(!isReady){
            return false;
        }
        return !sourceDenyMapping[_from] || targetAllowMapping[_to];
    }

    function addToSourceDenyList(address[] addressesToDenyTransfers) external onlyOwner {
        for(uint i = 0; i< addressesToDenyTransfers.length; i++){
            address addressToDeny = addressesToDenyTransfers[i];
            sourceDenyMapping[addressToDeny] = true;
            SourceAddressDenyListed(addressToDeny);
        }
    }

    function removeFromSourceDenyList(address[] addressesToAllowTransfers) external onlyOwner {
        for(uint i = 0; i< addressesToAllowTransfers.length; i++){
            address addressToAllow = addressesToAllowTransfers[i];
            sourceDenyMapping[addressToAllow] = false;
            SourceAddressAllowed(addressToAllow);
        }
    }

    function addToTargetAllowList(address[] targetAddressesToAllow) external onlyOwner {
        for(uint i = 0; i< targetAddressesToAllow.length; i++){
            address targetAddressToAllow = targetAddressesToAllow[i];
            targetAllowMapping[targetAddressToAllow] = true;
            TargetAddressAllowListed(targetAddressToAllow);
        }
    }

    function removeFromTargetAllowList(address[] addressesToDenyTransfers) external onlyOwner {
        for(uint i = 0; i< addressesToDenyTransfers.length; i++){
            address addressToDeny = addressesToDenyTransfers[i];
            targetAllowMapping[addressToDeny] = false;
            TargetAddressDisallowed(addressToDeny);
        }
    }

    function setReady() external onlyOwner whenPreparing {
        isReady = true;
        ContractReady();
    }

}