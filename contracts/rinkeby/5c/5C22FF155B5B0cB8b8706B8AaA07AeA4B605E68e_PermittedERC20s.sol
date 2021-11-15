// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IPermittedERC20s.sol";
import "../utils/Ownable.sol";

/**
 * @title  PermittedERC20s
 * @author NFTfi
 * @dev Registry for ERC20 currencies supported by NFTfi. Each ERC20 is
 * associated with a boolean permit.
 */
contract PermittedERC20s is Ownable, IPermittedERC20s {
    /* ******* */
    /* STORAGE */
    /* ******* */

    /**
     * @notice A mapping from an ERC20 currency address to whether that currency
     * is permitted to be used by this contract.
     */
    mapping(address => bool) private erc20Permits;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admin sets a ERC20 permit.
     *
     * @param erc20Contract - Address of the ERC20 contract.
     * @param isPermitted - Signals ERC20 permit.
     */
    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Initialize `erc20Permits` with a batch of permitted ERC20s
     *
     * @param _admin - Initial admin of this contract.
     * @param _permittedErc20s - The batch of addresses initially permitted.
     */
    constructor(address _admin, address[] memory _permittedErc20s) Ownable(_admin) {
        for (uint256 i = 0; i < _permittedErc20s.length; i++) {
            _setERC20Permit(_permittedErc20s[i], true);
        }
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice This function can be called by admins to change the permitted status of an ERC20 currency. This includes
     * both adding an ERC20 currency to the permitted list and removing it.
     *
     * @param _erc20 - The address of the ERC20 currency whose permit list status changed.
     * @param _permit - The new status of whether the currency is permitted or not.
     */
    function setERC20Permit(address _erc20, bool _permit) external onlyOwner {
        _setERC20Permit(_erc20, _permit);
    }

    /**
     * @notice This function can be called by admins to change the permitted status of a batch of ERC20 currency. This
     * includes both adding an ERC20 currency to the permitted list and removing it.
     *
     * @param _erc20s - The addresses of the ERC20 currencies whose permit list status changed.
     * @param _permits - The new statuses of whether the currency is permitted or not.
     */
    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits) external onlyOwner {
        require(_erc20s.length == _permits.length, "setERC20Permits function information arity mismatch");

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    /**
     * @notice This function can be called by anyone to get the permit associated with the erc20 contract.
     *
     * @param _erc20 - The address of the erc20 contract.
     *
     * @return Returns whether the erc20 is permitted
     */
    function getERC20Permit(address _erc20) external view override returns (bool) {
        return erc20Permits[_erc20];
    }

    /**
     * @notice This function can be called by admins to change the permitted status of an ERC20 currency. This includes
     * both adding an ERC20 currency to the permitted list and removing it.
     *
     * @param _erc20 - The address of the ERC20 currency whose permit list status changed.
     * @param _permit - The new status of whether the currency is permitted or not.
     */
    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPermittedERC20s {
    function getERC20Permit(address _erc20) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * Modified version from openzeppelin/contracts/access/Ownable.sol that allows to
 * initialize the owner using a parameter in the constructor
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(_newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Sets the owner.
     */
    function _setOwner(address _newOwner) private {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}