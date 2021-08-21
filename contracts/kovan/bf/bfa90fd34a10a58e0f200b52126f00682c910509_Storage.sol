/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    address addr = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    
    function check(int24 tickLower, int24 tickUpper) public view returns (bytes32){
        return keccak256(abi.encodePacked(addr, tickLower, tickUpper));
    }
}