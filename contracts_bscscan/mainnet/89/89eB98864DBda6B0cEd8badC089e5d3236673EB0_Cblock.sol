/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Cblock {
    function getBlock() public view returns(uint256){
        return block.number;
    }
     function getBlock2() public view returns(uint256){
        return (block.number+1);
    }
}