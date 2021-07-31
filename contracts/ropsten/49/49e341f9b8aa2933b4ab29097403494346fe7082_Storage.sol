/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// Exemple 1 - Simple Storage
// https://ecole.alyra.fr/mod/page/view.php?id=1161

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

/**
* @title Storage 
* @dev Store & retrieve value in a variable
* */


contract Storage {

    event Store (address _address, uint256 _value);
    event Retrieve (address _address, uint256 _value);

    uint256 number;

    /**
     * @dev Store value in variable
     * @param _num value to store
     */
    function store(uint256 _num) public {
        number = _num;
        emit Store( msg.sender, _num );
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public /*view*/ returns (uint256){
        emit Retrieve( msg.sender, number );
        return number;
    }
}