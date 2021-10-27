/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Bounty {

    uint256 number;


    constructor () payable {}
    
    function solve(uint256 x) public {
        require(x**5 - 12983719283*x**4 + 123103038*x**3 - 1598335288276481754*x**2 + 12310293800*x - 159833398990455345400 == 0);
        payable(msg.sender).transfer(address(this).balance);
    }
    
}