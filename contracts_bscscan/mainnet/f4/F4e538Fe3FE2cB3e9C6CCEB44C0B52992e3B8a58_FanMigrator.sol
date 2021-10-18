// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";

/**
 * @title FanMigrator
 * @notice This contract implements the migration from old to new FAN token.
 */
contract FanMigrator is Ownable {
    IERC20 public immutable oldFAN;
    IERC20 public immutable newFAN;

    uint256 public deadline;
    uint256 public totalFanMigrated;

    /**
     * @dev emitted on migration
     * @param sender the caller of the migration
     * @param amount the amount being migrated
     */
    event FanMigrated(address indexed sender, uint256 indexed amount);

    /**
     * @param _oldFan the address of the old FAN token
     * @param _newFan the address of the new FAN token
     * @param _deadline timestamp of the deadline for the migration
     */
    constructor(
        IERC20 _oldFan,
        IERC20 _newFan,
        uint256 _deadline
    ) {
        oldFAN = _oldFan;
        newFAN = _newFan;
        deadline = _deadline;
    }

    /**
     * @dev executes the migration from old FAN to new FAN.
     * Users need to give allowance to this contract to transfer old FAN before executing
     * this transaction.
     * Migration needs to be done before the deadline.
     * @param _amount the amount of old FAN to be migrated
     */
    function migrateFAN(uint256 _amount) external {
        require(deadline >= block.timestamp, "Migration finished");

        totalFanMigrated += _amount;
        oldFAN.transferFrom(msg.sender, address(this), _amount);
        newFAN.transfer(msg.sender, _amount);
        emit FanMigrated(msg.sender, _amount);
    }

    /**
     * @dev recover BNB from the contract
     */
    function recoverBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev recover BEP20 token from the contract.
     * Old and new FAN tokens can be withdraw to be burned
     * after the migration deadline.
     * @param _token Bep20 token address
     */
    function recoverBep20(address _token) external onlyOwner {
        require((_token != address(oldFAN) && _token != address(newFAN)) || deadline < block.timestamp, "Not possible yet");
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "Nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
     */
    function transferOwnership(address _newOwner, bool _direct) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0), "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}