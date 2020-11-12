// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "./Upgradeable.sol";
import "./Address.sol";


/**
* @notice ERC897 - ERC DelegateProxy
*/
interface ERCProxy {
    function proxyType() external pure returns (uint256);
    function implementation() external view returns (address);
}


/**
* @notice Proxying requests to other contracts.
* Client should use ABI of real contract and address of this contract
*/
contract Dispatcher is Upgradeable, ERCProxy {
    using Address for address;

    event Upgraded(address indexed from, address indexed to, address owner);
    event RolledBack(address indexed from, address indexed to, address owner);

    /**
    * @dev Set upgrading status before and after operations
    */
    modifier upgrading()
    {
        isUpgrade = UPGRADE_TRUE;
        _;
        isUpgrade = UPGRADE_FALSE;
    }

    /**
    * @param _target Target contract address
    */
    constructor(address _target) upgrading {
        require(_target.isContract());
        // Checks that target contract inherits Dispatcher state
        verifyState(_target);
        // `verifyState` must work with its contract
        verifyUpgradeableState(_target, _target);
        target = _target;
        finishUpgrade();
        emit Upgraded(address(0), _target, msg.sender);
    }

    //------------------------ERC897------------------------
    /**
     * @notice ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() external pure override returns (uint256) {
        return 2;
    }

    /**
     * @notice ERC897, gets the address of the implementation where every call will be delegated
     */
    function implementation() external view override returns (address) {
        return target;
    }
    //------------------------------------------------------------

    /**
    * @notice Verify new contract storage and upgrade target
    * @param _target New target contract address
    */
    function upgrade(address _target) public onlyOwner upgrading {
        require(_target.isContract());
        // Checks that target contract has "correct" (as much as possible) state layout
        verifyState(_target);
        //`verifyState` must work with its contract
        verifyUpgradeableState(_target, _target);
        if (target.isContract()) {
            verifyUpgradeableState(target, _target);
        }
        previousTarget = target;
        target = _target;
        finishUpgrade();
        emit Upgraded(previousTarget, _target, msg.sender);
    }

    /**
    * @notice Rollback to previous target
    * @dev Test storage carefully before upgrade again after rollback
    */
    function rollback() public onlyOwner upgrading {
        require(previousTarget.isContract());
        emit RolledBack(target, previousTarget, msg.sender);
        // should be always true because layout previousTarget -> target was already checked
        // but `verifyState` is not 100% accurate so check again
        verifyState(previousTarget);
        if (target.isContract()) {
            verifyUpgradeableState(previousTarget, target);
        }
        target = previousTarget;
        previousTarget = address(0);
        finishUpgrade();
    }

    /**
    * @dev Call verifyState method for Upgradeable contract
    */
    function verifyUpgradeableState(address _from, address _to) private {
        (bool callSuccess,) = _from.delegatecall(abi.encodeWithSelector(this.verifyState.selector, _to));
        require(callSuccess);
    }

    /**
    * @dev Call finishUpgrade method from the Upgradeable contract
    */
    function finishUpgrade() private {
        (bool callSuccess,) = target.delegatecall(abi.encodeWithSelector(this.finishUpgrade.selector, target));
        require(callSuccess);
    }

    function verifyState(address _testTarget) public override onlyWhileUpgrading {
        //checks equivalence accessing state through new contract and current storage
        require(address(uint160(delegateGet(_testTarget, this.owner.selector))) == owner());
        require(address(uint160(delegateGet(_testTarget, this.target.selector))) == target);
        require(address(uint160(delegateGet(_testTarget, this.previousTarget.selector))) == previousTarget);
        require(uint8(delegateGet(_testTarget, this.isUpgrade.selector)) == isUpgrade);
    }

    /**
    * @dev Override function using empty code because no reason to call this function in Dispatcher
    */
    function finishUpgrade(address) public override {}

    /**
    * @dev Receive function sends empty request to the target contract
    */
    receive() external payable {
        assert(target.isContract());
        // execute receive function from target contract using storage of the dispatcher
        (bool callSuccess,) = target.delegatecall("");
        if (!callSuccess) {
            revert();
        }
    }

    /**
    * @dev Fallback function sends all requests to the target contract
    */
    fallback() external payable {
        assert(target.isContract());
        // execute requested function from target contract using storage of the dispatcher
        (bool callSuccess,) = target.delegatecall(msg.data);
        if (callSuccess) {
            // copy result of the request to the return data
            // we can use the second return value from `delegatecall` (bytes memory)
            // but it will consume a little more gas
            assembly {
                returndatacopy(0x0, 0x0, returndatasize())
                return(0x0, returndatasize())
            }
        } else {
            revert();
        }
    }

}
