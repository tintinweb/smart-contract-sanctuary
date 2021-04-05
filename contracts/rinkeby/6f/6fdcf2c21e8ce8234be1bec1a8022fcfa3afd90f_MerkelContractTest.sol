/**
 *Submitted for verification at Etherscan.io on 2021-04-04
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    
    contract MathLib{
    //Int256 Library all functions	
    	//Basics
    	function Add(int _X, int _Y) public returns (int _Z){} 		//
    	function Add(int[] memory _X, int[] memory _Y) public returns (int[] memory _Z){}
    	function Sum(int[] memory _a)public returns(int _Z){}
    	
    }
    
    
    contract CallProxy {
    
      /**
      * @dev Tells the address of the implementation where every fuction  will be called.
      * @return address of the implementation to which it will be delegated
      */
      function implementation() public pure returns (address){
          return 0x1B2cEa38CAf753186a9a25B487ec1b784B34Df59; //rinkeby
      }
    
      /**
      * @dev Fallback function allowing to perform a delegatecall to the given implementation.
      * This function will return whatever the implementation call returns
      */
        fallback()  external {
        address _impl = implementation();
        bytes memory data = msg.data;   
        
        assembly {
          let result := call(gas(), _impl,0, add(data, 0x20), mload(data), 0, 0)
          //let result := callcode(gas, _impl,0, add(data, 0x20), mload(data), 0, 0)
          //let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
          let size := returndatasize()
    
          let ptr := mload(0x40)
          returndatacopy(ptr, 0, size)
    
          switch result
          case 0 { revert(ptr, size) }
          default { return(ptr, size) }
        }
      }
    }
    
    contract MerkelContractTest{
        MathLib M;
        int256 public counter =0;
        constructor(address _LibraryLocal) {
            M = MathLib(_LibraryLocal);
        }
        function AddAdd(int[] memory _X, int[] memory _Y) public returns (int _Z){
            _Z=M.Sum(M.Add(_X,_Y));
            counter=_Z;
        }
        function Add(int _W) public returns (int _Z){
            _Z = M.Add(_W,counter);
            counter = _Z;
        }
    }