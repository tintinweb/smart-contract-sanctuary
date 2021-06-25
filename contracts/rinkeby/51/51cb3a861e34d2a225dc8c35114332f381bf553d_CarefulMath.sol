/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
    
    string text;
 function div(uint a, uint b) public view returns(uint){
     return a/b;
 }
 
    function execute(
        bytes calldata _data
    ) public  returns (string memory bought) {
        (
            string memory  bought,
            uint256 minReturn
        ) = abi.decode(
            _data,
            (
                string ,
                uint256
            )
        );
        text =  bought;
        
        return bought;
    }
    
    function directExecute(string memory bought, uint256 minReturn) public returns(string memory){
        text=bought;
        return bought;
        
    }
    
    function encode(string memory bought, uint256 minReturn) public returns(bytes memory){
        return abi.encode(bought, minReturn);
        
    }

}