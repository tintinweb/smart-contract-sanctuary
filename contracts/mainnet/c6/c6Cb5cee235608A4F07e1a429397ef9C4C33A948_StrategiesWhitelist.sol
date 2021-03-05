pragma solidity 0.6.6;

import "./Ownable.sol";

contract StrategiesWhitelist is Ownable {
    mapping(address => uint8) public whitelistedAllocationStrategies;

    event AllocationStrategyWhitelisted(address indexed submittedBy, address indexed allocationStrategy);
    event AllocationStrategyRemovedFromWhitelist(address indexed submittedBy, address indexed allocationStrategy);

    constructor() public {
        _setOwner(msg.sender);
    }

    function isWhitelisted(address _allocationStrategy) external view returns (uint8 answer) {
        return whitelistedAllocationStrategies[_allocationStrategy];
    }

    function addToWhitelist(address _allocationStrategy) external onlyOwner {
        whitelistedAllocationStrategies[_allocationStrategy] = 1;
        emit AllocationStrategyWhitelisted(msg.sender, _allocationStrategy);
    }

    function removeFromWhitelist(address _allocationStrategy) external onlyOwner {
        whitelistedAllocationStrategies[_allocationStrategy] = 0;
        emit AllocationStrategyRemovedFromWhitelist(msg.sender, _allocationStrategy);
    }
}

pragma solidity 0.6.6;

// Copied from PieDAO smart pools repo. Which is audited

contract Ownable {

    bytes32 constant public oSlot = keccak256("Ownable.storage.location");

    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    // Ownable struct
    struct os {
        address owner;
    }

    modifier onlyOwner(){
        require(msg.sender == los().owner, "Ownable.onlyOwner: msg.sender not owner");
        _;
    }

    /**
        @notice Get owner
        @return Address of the owner
    */
    function owner() public view returns(address) {
        return los().owner;
    }

    /**
        @notice Transfer ownership to a new address
        @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) onlyOwner external {
        _setOwner(_newOwner);
    }

    /**
        @notice Internal method to set the owner
        @param _newOwner Address of the new owner
    */
    function _setOwner(address _newOwner) internal {
        emit OwnerChanged(los().owner, _newOwner);
        los().owner = _newOwner;
    }

    /**
        @notice Load ownable storage
        @return s Storage pointer to the Ownable storage struct
    */
    function los() internal pure returns (os storage s) {
        bytes32 loc = oSlot;
        assembly {
            s_slot := loc
        }
    }

}