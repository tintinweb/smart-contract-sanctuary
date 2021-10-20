/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage2 {

    string[] private allNames;
    mapping (string => uint8) private nameToNumber;
    
    /**
     * @dev verify if a name exist in the storing array
     * @param _name the name to verify
     */
    modifier nameExist(string memory _name) {
        bool exist = false;
        
        for(uint i = 0; i < allNames.length; i++){
            if(keccak256(bytes(allNames[i])) == keccak256(bytes(_name))){
                exist = true;
            }
        }
        
        require(exist == true, "The name doesn't exist");
        _;
    }
    
    /**
     * @dev create a name, store value in array
     * @param _name value to store
     */
    function createName(string calldata _name) external {
        allNames.push(_name);
    }
    
     /**
     * @dev associate a number to an existing name
     * @param _name the existing name
     * @param _number a number to associate with the name
     */
    function setNumberOfName(string calldata _name, uint8 _number) external nameExist(_name){
        nameToNumber[_name] = _number;
    }
    
    /**
     * @dev Return array
     * @return values of 'allNames'
     */
    function getNames() external view returns (string[] memory){
        return allNames;
    }
    
    function getNumberByName(string calldata _name) external view nameExist(_name) returns (uint8){
        return nameToNumber[_name];
    }
}