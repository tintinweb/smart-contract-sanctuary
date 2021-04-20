/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
interface IStorage {
    event change_value(uint256 value);
    function store(uint256) external;
    function retrieve() external view returns(uint256);
}

contract Storage is IStorage, Initializable{
    uint256 public number;
    address public thisadmin;
    modifier Owner {
        require(msg.sender == thisadmin, 'You are not the admin!');
        _;
    }
    function initilize(address aadmin) public payable initializer {
        thisadmin = aadmin;
    }
    function store(uint256 num) external override Owner {
        number = num;
        emit change_value(num);
    }

    function retrieve() external view override returns (uint256){
        return number;
    }
}