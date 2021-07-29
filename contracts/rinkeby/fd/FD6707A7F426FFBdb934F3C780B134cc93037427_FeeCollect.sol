// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IConjureFactory.sol";
import "./interfaces/IConjureRouter.sol";

interface Collect{
    function collectFees() external;
    function changeOwner(address payable _newOwner) external;
}

contract FeeCollect {
    // address used for pay out

    address public CNJAddress = 0xBCAA3bEDB1EF9da9AB96a5439cf9B4E18d11Fcc2;
    address public  control = 0xa71A51A4863A2f9c2a83A9FEb284595020CC80A7;
    Collect[] public CollectAddresses;
    address public DAOtimelock = 0xa71A51A4863A2f9c2a83A9FEb284595020CC80A7;

    receive() external payable {
    }

    fallback() external payable{
        pay();
    }

    function collect(Collect[] memory assets) public{
        for (uint c = 0; c < assets.length; c++) {
            assets[c].collectFees();
        }
        pay();
    }
    function pay() public{
        address payable conjureRouter = IConjureFactory(CNJAddress).getConjureRouter();
        IConjureRouter(conjureRouter).deposit{value:address(this).balance}();
    }

    function collectSet(Collect[] memory assets) public{
        require(msg.sender == control, "Must come from controller address");
        CollectAddresses = assets;
    }

    function updateControl(address _control) public{
        require(msg.sender == control, "Must come from controller address");
        control = _control;
    }

    function collect1tap() public{
        for (uint c = 0; c < CollectAddresses.length; c++) {
            CollectAddresses[c].collectFees();
        }
        pay();
    }

    function changeOwner(address cnjContract, address payable newOwner) public {
        require(msg.sender == DAOtimelock, "Must come from DAO address");
        Collect(cnjContract).changeOwner(newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureFactory
/// @notice Interface for interacting with the ConjureFactory Contract
interface IConjureFactory {

    /**
     * @dev gets the current conjure router
     *
     * @return the current conjure router
    */
    function getConjureRouter() external returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureRouter
/// @notice Interface for interacting with the ConjureRouter Contract
interface IConjureRouter {

    /**
     * @dev calls the deposit function
    */
    function deposit() external payable;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}