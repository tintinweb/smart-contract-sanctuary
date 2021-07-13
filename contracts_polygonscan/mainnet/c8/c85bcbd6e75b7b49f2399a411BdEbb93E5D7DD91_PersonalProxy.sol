pragma solidity 0.6.12;


import "./TransparentUpgradeableProxy.sol";

contract PersonalProxy is TransparentUpgradeableProxy {

    constructor(address admin, address logic) TransparentUpgradeableProxy(logic, admin ,"") public {

    }

}