// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./EnumerableSet.sol";

contract GojiFarmFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private farms;
    EnumerableSet.AddressSet private farmGenerators;
    
    mapping(address => EnumerableSet.AddressSet) private userFarms;
    
    function adminAllowFarmGenerator (address _address, bool _allow) public onlyOwner {
        if (_allow) {
            farmGenerators.add(_address);
        } else {
            farmGenerators.remove(_address);
        }
    }
    
    /**
     * @notice called by a registered FarmGenerator upon Farm creation
     */
    function registerFarm (address _farmAddress) public {
        require(farmGenerators.contains(msg.sender), 'FORBIDDEN');
        farms.add(_farmAddress);
    }
    
    /**
     * @notice Number of allowed FarmGenerators
     */
    function farmGeneratorsLength() external view returns (uint256) {
        return farmGenerators.length();
    }
    
    /**
     * @notice Gets the address of a registered FarmGenerator at specifiex index
     */
    function farmGeneratorAtIndex(uint256 _index) external view returns (address) {
        return farmGenerators.at(_index);
    }
    
    /**
     * @notice The length of all farms on the platform
     */
    function farmsLength() external view returns (uint256) {
        return farms.length();
    }
    
    /**
     * @notice gets a farm at a specific index. Although using Enumerable Set, since farms are only added and not removed this will never change
     * @return the address of the Farm contract at index
     */
    function farmAtIndex(uint256 _index) external view returns (address) {
        return farms.at(_index);
    }
    
    /**
     * @notice called by a Farm contract when lp token balance changes from 0 to > 0 to allow tracking all farms a user is active in
     */
    function userEnteredFarm(address _user) public {
        // msg.sender = farm contract
        require(farms.contains(msg.sender), 'FORBIDDEN');
        EnumerableSet.AddressSet storage set = userFarms[_user];
        set.add(msg.sender);
    }
    
    /**
     * @notice called by a Farm contract when all LP tokens have been withdrawn, removing the farm from the users active farm list
     */
    function userLeftFarm(address _user) public {
        // msg.sender = farm contract
        require(farms.contains(msg.sender), 'FORBIDDEN');
        EnumerableSet.AddressSet storage set = userFarms[_user];
        set.remove(msg.sender);
    }
    
    /**
     * @notice returns the number of farms the user is active in
     */
    function userFarmsLength(address _user) external view returns (uint256) {
        EnumerableSet.AddressSet storage set = userFarms[_user];
        return set.length();
    }
    
    /**
     * @notice called by a Farm contract when all LP tokens have been withdrawn, removing the farm from the users active farm list
     * @return the address of the Farm contract the user is farming
     */
    function userFarmAtIndex(address _user, uint256 _index) external view returns (address) {
        EnumerableSet.AddressSet storage set = userFarms[_user];
        return set.at(_index);
    }
    
}