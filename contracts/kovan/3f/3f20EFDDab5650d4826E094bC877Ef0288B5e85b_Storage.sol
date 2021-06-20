/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256 public y;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        y= 10;
        number=number+y;
    }
    // function getAbi() public pure returns(bytes32 ){
    //     return keccak256(abi.encode("addAllowedToken()",address(0x6Aed25b31fb0453ae64d10Aa3d2ebC02ECC8b20b)));
    // }
    // function getAbii()public pure returns(bytes memory){
    //     return abi.encode("addAllowedToken(addAllowedToken)",address(0x6Aed25b31fb0453ae64d10Aa3d2ebC02ECC8b20b));
    // }
    function retrieve() public view returns (uint256){
        return number+12;
    }
    
    // function getData() public pure returns(bytes memory){
    //     return abi.encodeWithSignature("startUpgrade()");
    // }
    
}