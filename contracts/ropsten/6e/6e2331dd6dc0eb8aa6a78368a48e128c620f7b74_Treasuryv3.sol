pragma solidity 0.5.17;

import "./TreasuryBasev3.sol";

/**
 * @author Quant Network
 * @title Treasuryv3
 * @dev This contract holds a specific treasury's information
 * After V1.0 audit
 */
contract Treasuryv3 is TreasuryBasev3 {

            //**All variables are in the following format so there is no overiding of variables in the EVM
            //**Variables are prefixed with the upgrade version they first appear in
        // The QNT address variables in the speed bump
        bytes constant private speedBumpQNTAddress2 = '2.speedBump.qntAddress';
        // The operator address variables in the speed bump
        bytes constant private speedBumpOperatorAddress2 = '2.speedBump.operatorAddress';
        // The treasury factory address variables in the speed bump
        bytes constant private speedBumpFactoryAddress2 = '2.speedBump.factoryAddress';
        // What time this SpeedBump was created at
        bytes constant private speedBumpTimeCreated1 = '1.speedBump.timeCreated';
        // this contract's pending speedBumpHours
        bytes constant private speedBumpNextSBHours1 = '1.speedBump.nextSBHours';
        // this contract's current speed bump time period
        bytes constant private speedBumpCurrentSBHours1 = '1.speedBump.currentSBHours';

        // The event fired when the other elements of the treasury's config has been changed
        event updatedTreasuryConfigVariables(address factory, uint256 speedBumpHours);
        // The event fired when the treasury's key variables have been updated:
        event updatedTreasuryAccountVariables(address newQNTAddress, address newOperator);
        // The event fired when a speed bump has been created:
        event updatedSpeedBump(uint speedBumpIndex,uint256 timeCreated,uint256 speedBumpHours);
        
        /**
         * All functions with this modifier can only be called by the current treasury admin
         */    
        modifier onlyAdmin(){
            if (msg.sender != getAdmin(msg.sender)){
                revert("Only the admin can perform this function");
            } else {
                _; //means carry on with the computation
            }
        }
        
                /**
         * Sets the treasury's initial variables
         * @param thisQNTAddress  - the QNT cold wallet address associated to the treasury
         * @param thisOperatorAddress  - the operator address of this contract to perform payment channel operations
         * @param thisAdminAddress - the admin address of this contract to change the treasury variables after the speed bump
         * @param speedBumpTime - the initial speed bump time in hours
         */ 
        function initialize (address thisQNTAddress, address thisOperatorAddress, address thisAdminAddress, uint16 speedBumpTime) external {
            require(!getInitialized(),"contract can only be initialised once");
            setQNTAddress(thisQNTAddress);
            setOperatorAddress(thisOperatorAddress);
            setSpeedBumpHours(speedBumpTime);
            //set the admin who can upgrade:
            addressStorage[keccak256('proxy.admin')] = thisAdminAddress;
            initializeNow(); //sets this contract to initialized
        }
        
        
        /**
         * Updates the treasury's QNT and operator addresses, as saved via speedBumpAccountChange
         */
        function updateTreasuryAccountVariables() external onlyAdmin() {
            uint8 sb = 0;  // set as a separator between the two speed bumps
            uint256 sBTimeCreated = getSpeedBumpTimeCreated(sb);
            require(sBTimeCreated > 0, "Time created must be >0 (to stop replays of the speed bump)");
            require(block.timestamp > sBTimeCreated + (getSpeedBumpCurrentSBHours(sb)*1 hours), "The speed bump time period must have passed");            
            //make the key state changes
            setQNTAddress(getSpeedBumpQNTAddress());
            setOperatorAddress(getSpeedBumpOperatorAddress());
            //wipe the speed bump - so it cannot be immediately reused
            setSpeedBumpQNTAddress(address(0));
            setSpeedBumpOperatorAddress(address(0));
            setSpeedBumpTimeCreated(sb,0);
            setSpeedBumpCurrentSBHours(sb,0);
            //emit event
            emit updatedTreasuryAccountVariables(getQNTAddress(),getOperatorAddress());
        }

        
        /**
         * Updates the treasury's factory address& speedBumpHours as saved via speedBumpConfigChange
         */
        function updateTreasuryConfigVariables() external onlyAdmin() {
            uint8 sb = 1;
            uint256 sBTimeCreated = getSpeedBumpTimeCreated(sb);
            require(sBTimeCreated > 0, "Time created must be >0 (to stop replays of the speed bump)");
            require(block.timestamp > sBTimeCreated + (getSpeedBumpCurrentSBHours(sb)*1 hours), "The speed bump time period must have passed");
            // make the key state changes
            setTreasurysFactory(getSpeedBumpFactoryAddress());
            setSpeedBumpHours(getSpeedBumpNextSBHours());
            // wipe the speed bump - so it cannot be immediately reused
            setSpeedBumpFactoryAddress(address(0));
            setSpeedBumpNextSBHours(0);
            setSpeedBumpTimeCreated(sb,0);
            setSpeedBumpCurrentSBHours(sb,0);
            //emit event
            emit updatedTreasuryConfigVariables(getTreasurysFactory(),getSpeedBumpHours());
        }
        

        /**
         * adds a new speed bump for the updateTreasuryAccountVariables function
         * @param newQNTaddress - the new QNT wallet address for the treasury
         * @param newOperatorAddress - the new operator address for the treasury
         */
        function speedBumpAccountChange(address newQNTaddress, address newOperatorAddress) external onlyAdmin() {
            uint8 sb = 0; // set as a separator between the two speed bumps
            require((newQNTaddress != address(0))&&(newOperatorAddress != address(0)),"Addresses must have values");
            // record variables to change 
            setSpeedBumpQNTAddress(newQNTaddress);
            setSpeedBumpOperatorAddress(newOperatorAddress);
            // set the time as now
            setSpeedBumpTimeCreated(sb, block.timestamp);
            // set the speedBump hours as they are now
            setSpeedBumpCurrentSBHours(sb,getSpeedBumpHours());
            // emit event
            emit updatedSpeedBump(sb,block.timestamp,getSpeedBumpHours());
        }
 
        
        /**
         * adds a new speed bump for the updateTreasuryConfigVariables function
         * @param newFactory - the addresses of the new treasury factory
         * @param newSpeedBumpHours - the new speed bump hours
         */
        function speedBumpConfigChange(address newFactory,uint16 newSpeedBumpHours) external onlyAdmin() {
            uint8 sb = 1; // set as a separator between the two speed bumps
            require(newFactory != address(0),"Factory must have a value");
            // record variables to change 
            setSpeedBumpFactoryAddress(newFactory);
            setSpeedBumpNextSBHours(newSpeedBumpHours);
            // set the time as now
            setSpeedBumpTimeCreated(sb, block.timestamp);
            // set the speedBump hours as they are now
            setSpeedBumpCurrentSBHours(sb,getSpeedBumpHours());
            // emit event
            emit updatedSpeedBump(sb,block.timestamp,getSpeedBumpHours());
        }
        
        
        /**
        * Sets the QNT address variable in the SpeedBump
        * @param newSBQNTAddress - the new speed bump QNT address
         */        
        function setSpeedBumpQNTAddress(address newSBQNTAddress) internal {
            // sb=1 to align with the above
            addressStorage[keccak256(abi.encodePacked(speedBumpQNTAddress2,int(1)))] = newSBQNTAddress;
        }
        
        /**
        * Sets the operator address variable in the SpeedBump
        * @param newSBOperatorAddress - the new speed bump operator address
         */        
        function setSpeedBumpOperatorAddress(address newSBOperatorAddress) internal {
            // sb=1 to align with the above
            addressStorage[keccak256(abi.encodePacked(speedBumpOperatorAddress2,int(1)))] = newSBOperatorAddress;
        }
        
        /**
        * Sets the treasury factory address variable in the SpeedBump
        * @param newSBFactoryAddress - the new treasury factory address
         */        
        function setSpeedBumpFactoryAddress(address newSBFactoryAddress) internal {
            // sb=0 to align with the above
            addressStorage[keccak256(abi.encodePacked(speedBumpFactoryAddress2,int(0)))] = newSBFactoryAddress;
        }
        
       /**
        *  Sets the next scheduled speedBump wait time
        * @param newSBhours - the new speed bump hours
         */
        function setSpeedBumpNextSBHours(uint16 newSBhours) internal {
            // sb=0 to align with the above
            uint16Storage[keccak256(abi.encodePacked(speedBumpNextSBHours1,int(0)))] = newSBhours;
        }
        
        
        /**
         * Sets the time the speedBump was created at
         * @param index - the speed bump to modify
         * @param timeCreated - the time the speed bump was created
         */      
        function setSpeedBumpTimeCreated(uint8 index, uint256 timeCreated) internal {
            uint256Storage[keccak256(abi.encodePacked(speedBumpTimeCreated1,index))] = timeCreated;
        } 
        
        /**
         * Sets the number of hours until the SpeedBump can be used
         * @param index - the speed bump to modify
         * @param newCurrentSBHours - the number of hours
         */       
        function setSpeedBumpCurrentSBHours(uint8 index, uint16 newCurrentSBHours) internal {
            uint16Storage[keccak256(abi.encodePacked(speedBumpCurrentSBHours1,index))] = newCurrentSBHours;
        }
        
        
        /**
        * Reads the QNT address variable in the SpeedBump
        * @return - the specific address
         */        
        function getSpeedBumpQNTAddress() public view returns (address){
            return addressStorage[keccak256(abi.encodePacked(speedBumpQNTAddress2,int(1)))];
        }
        
        /**
        * Reads the operator address variable in the SpeedBump
        * @return - the specific address
         */        
        function getSpeedBumpOperatorAddress() public view returns (address){
            return addressStorage[keccak256(abi.encodePacked(speedBumpOperatorAddress2,int(1)))];
        }
        
        /**
        * Reads the treasury factory address variable in the SpeedBump
        * @return - the specific address
         */        
        function getSpeedBumpFactoryAddress() public view returns (address){
            return addressStorage[keccak256(abi.encodePacked(speedBumpFactoryAddress2,int(0)))];
        }
        
        
       /**
        *  Reads the next scheduled speedBump time
         * @return - the specific speedBump time
         */
        function getSpeedBumpNextSBHours() public view returns (uint16){
            return uint16Storage[keccak256(abi.encodePacked(speedBumpNextSBHours1,int(0)))];
        }

        /**
         * Reads the time the speedBump was created at
         * @param index - the speed bump to read
         * @return - the creation time
         */ 
        function getSpeedBumpTimeCreated(uint8 index) public view returns (uint256){
            return uint256Storage[keccak256(abi.encodePacked(speedBumpTimeCreated1,index))];
        } 
        
    
       /**
         * @return - the time this contract's pending request was created
         */
        function getSpeedBumpCurrentSBHours(uint8 index) public view returns (uint16){
            return uint16Storage[keccak256(abi.encodePacked(speedBumpCurrentSBHours1,index))];
        }

}