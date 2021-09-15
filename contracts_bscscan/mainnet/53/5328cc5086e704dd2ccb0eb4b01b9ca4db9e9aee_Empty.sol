// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/proxy/utils/Initializable.sol 
import "./Initializable.sol";

contract Empty is Initializable {    
    // Upgradable Contract Test
    uint public _uptest;
    address public _owner;
    
    function initialize(address owner_) public initializer {
        _owner = owner_;
    }
    
    function setUptest(uint uptest_) external {
        _uptest = uptest_;
    }
}