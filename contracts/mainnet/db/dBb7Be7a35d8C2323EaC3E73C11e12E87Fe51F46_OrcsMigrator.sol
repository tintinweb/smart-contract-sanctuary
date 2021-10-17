// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


import { EtherOrcs } from "./EtherOrcs.sol";
import { ERC20 } from "./ERC20.sol";

contract Migrator {

    address implementation_;
    address public admin;
    EtherOrcs public  oldOrcs;
    EtherOrcs public  newOrcs;
    ERC20     public  zug;

    address  public burningAddress;
    uint256  public startingTime;

    mapping(uint256 => bool) public migrated;

    function initialize(address oldOrcs_,address newOrcs_, address zug_, address burningAddress_) public {
        require(msg.sender == admin);
        oldOrcs        = EtherOrcs(oldOrcs_);
        newOrcs        = EtherOrcs(newOrcs_);
        zug            = ERC20(zug_);
        burningAddress = burningAddress_;

        startingTime = block.timestamp;
    }
    
    function implementation() public view returns (address impl) {
        impl = implementation_;
    }

    function migrateMany(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            justMigrate(ids[index]);
        }
    }

    function migrateManyAndFarm(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            migrateAndFarm(ids[index]);
        }
    }

    function migrateManyAndTrain(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            migrateAndTrain(ids[index]);
        }
    }

    function migrateAndFarm(uint256 tokenId) public {
        _migrate(tokenId);
        //give retroactive time
        newOrcs.migrationAction(tokenId, msg.sender, EtherOrcs.Actions.FARMING);
    }

    function migrateAndTrain(uint256 tokenId) public {
        _migrate(tokenId);
        //give retroactive time
        newOrcs.migrationAction(tokenId, msg.sender, EtherOrcs.Actions.TRAINING);
    }

    function justMigrate(uint256 tokenId) public {
        _migrate(tokenId);
    }

    function _migrate(uint256 tokenId) internal {
        require(!migrated[tokenId], "already migrated");

        //Check what the orc is doing
        (address owner, uint88 timestamp, EtherOrcs.Actions action_) = oldOrcs.activities(tokenId);
        require(msg.sender == oldOrcs.ownerOf(tokenId) || (action_ == EtherOrcs.Actions.FARMING && owner == msg.sender), "not allowed");


        (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level ,uint16 zugModifier , uint32 lvlProgress) = oldOrcs.orcs(tokenId);
        

        uint zugAmount;
        if (action_ == EtherOrcs.Actions.FARMING) {
            // We cant't transfer here, but it's safe there
            zugAmount = claimableZug(block.timestamp - timestamp, zugModifier);
        } else {
            // Transfer From to here
            oldOrcs.transferFrom(msg.sender, address(burningAddress), tokenId);
        }
        
        (helm, mainhand, offhand) = getEquipment(helm,mainhand,offhand);
        // Mint an excatly the the same orcs
        newOrcs.craft(msg.sender, tokenId,body,helm,mainhand,offhand,level,lvlProgress);

        migrated[tokenId] = true;

        if (block.timestamp - 25 hours < startingTime) zug.mint(owner,1 ether + zugAmount);
    } 
    
    function getEquipment(uint8 helm_, uint8 mainhand_, uint8 offhand_) internal returns (uint8 helm, uint8 mainhand, uint8 offhand) {
        uint maxTier = 6;
        helm     = _tier(helm)     > maxTier ? helm - 4     : helm;
        mainhand = _tier(mainhand) > maxTier ? mainhand - 4 : mainhand;
        offhand  = _tier(offhand)  > maxTier ? offhand - 4  : offhand;
    }

    function claimableZug(uint256 timeDiff, uint16 zugModifier) internal pure returns (uint256 zugAmount) {
        zugAmount = timeDiff * (4 + zugModifier) * 1 ether / 1 days;
    }

    function _tier(uint16 id) internal pure returns (uint16) {
        if (id == 0) return 0;
        return ((id - 1) / 4 );
    }
    

}
/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract OrcsMigrator {

    uint256 constant sal = 22;
    address implementation_;
    address public admin;

    constructor(address impl) {
        implementation_ = impl;
        admin = msg.sender;
    }

    function setImplementation(address newImpl) public {
        require(msg.sender == admin);
        if (sal == 22) {
            implementation_ = newImpl;
        }
        implementation_ = newImpl;
    }
    
    function implementation() public view returns (address impl) {
        impl = implementation_;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view returns (address) {
        return implementation_;
    }


    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _delegate(_implementation());
    }

}