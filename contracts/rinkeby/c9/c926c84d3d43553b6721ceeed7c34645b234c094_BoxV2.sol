/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 <= 0.9.0 ;

contract BoxV2 {
  uint256 private _value ;

  // Emitted when the stored value changes
  event ValueChanged( uint256 newValue ) ;

  // Stores a new value in the contract
  function store( uint256 newValue ) public {
    _value = newValue ;
    emit ValueChanged( newValue ) ;
  }

  // Reads the last stored value
  function retrieve() public view returns ( uint256 ) {
    return _value ;
  }

  function retrieveV2() public view returns ( uint256 ) {
    return _value + 5 ;
  } 

  // Increments the stored value by 1
  function increment() public {
    _value += 1 ;
    emit ValueChanged( _value ) ;
  }
}