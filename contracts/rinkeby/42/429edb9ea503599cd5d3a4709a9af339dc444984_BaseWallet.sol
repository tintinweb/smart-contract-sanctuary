/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

/**
 * @title BaseWallet
 * @notice Simple modular wallet that authorises modules to call its invoke() method.
 */
contract BaseWallet {

    // The owner
    address public owner;

    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);

    /**
     * @notice Inits the wallet by setting the owner.
     * @param _owner The owner.
     */
    function init(address _owner) external {
        require(owner == address(0), "BW: wallet already initialised");
        owner = _owner;
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }

   
    /**
     * @notice Sets owner of the wallet.
     * @param _newOwner The address of new owner.
     */
    function setOwner(address _newOwner) external {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /**
     * @notice Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invoke(address _target, uint _value, bytes calldata _data) external returns (bytes memory _result) {
        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }

    receive() external payable {
    }
}