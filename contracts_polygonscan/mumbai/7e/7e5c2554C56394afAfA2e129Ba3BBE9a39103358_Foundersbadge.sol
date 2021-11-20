/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// File: contracts/foundersbadge.sol



pragma solidity >=0.7.0 <0.9.0;

contract Foundersbadge {
    mapping( address => uint256) public addressToCounter;
    address public c1;
    address public c2;
    address public c3;
    address public c4;

    constructor () {
       
    }
    function setCallersAddress(address _c1, address _c2, address _c3, address _c4) external {
        c1 = _c1;
        c2 = _c2;
        c3 = _c3;
        c4 = _c4;
    }
    function setTokenCounter(address minter, uint256 _amount ) external {
        require(msg.sender == c1 || msg.sender == c2 || msg.sender == c3 || msg.sender == c4);
        addressToCounter[minter] += _amount;
    }
    function getCounter(address minter) external view returns(uint256) {
        return addressToCounter[minter];
    }
}