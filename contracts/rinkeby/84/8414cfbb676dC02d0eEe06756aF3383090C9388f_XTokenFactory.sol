// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "./OwnableRegular.sol";
// import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {ClonesUpgradeable} from "./ClonesUpgradeable.sol";
import "./XTokenClonable.sol";

contract XTokenFactory is Ownable {
    address public template;

    event NewXToken(address _xTokenAddress);

    constructor(address _template) public {
        template = _template;
    }

    function createXToken(string calldata name, string calldata symbol)
        external
        returns (address)
    {
        XTokenClonable x = XTokenClonable(ClonesUpgradeable.clone(template));
        x.initialize(name, symbol);
        x.transferOwnership(owner());
        address xAddress = address(x);
        emit NewXToken(xAddress);
        return xAddress;
    }
}