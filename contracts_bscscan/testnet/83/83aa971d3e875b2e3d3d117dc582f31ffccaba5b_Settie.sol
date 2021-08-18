/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
interface IContract{
    function store(uint256 num) external;
    function retrieve() external returns (uint256);
}
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Settie is IContract{

    uint public number = 0;
    IContract public anotherContract;
    function setContract(address contractAddress) public {
        anotherContract = IContract(contractAddress);
    }
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint num) public override {
        IContract(anotherContract).store(num);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public override returns (uint256){
        return IContract(anotherContract).retrieve();
    }
    function getContract()public view returns(address){
        return address(anotherContract);
    }
}