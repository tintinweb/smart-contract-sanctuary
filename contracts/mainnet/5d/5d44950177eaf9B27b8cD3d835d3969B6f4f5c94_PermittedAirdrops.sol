// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IPermittedAirdrops.sol";
import "../utils/Ownable.sol";

/**
 * @title  PermittedAirdrops
 * @author NFTfi
 * @dev Registry for airdropa supported by NFTfi. Each Airdrop is associated with a boolean permit.
 */
contract PermittedAirdrops is Ownable, IPermittedAirdrops {
    /* ******* */
    /* STORAGE */
    /* ******* */

    /**
     * @notice A mapping from an airdrop to whether that airdrop
     * is permitted to be used by NFTfi.
     */
    mapping(bytes => bool) private airdropPermits;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admin sets a ERC20 permit.
     *
     * @param airdropContract - Address of the airdrop contract.
     * @param selector - The selector of the permitted function in the `airdropContract`.
     * @param isPermitted - Signals airdrop permit.
     */
    event AirdropPermit(address indexed airdropContract, bytes4 indexed selector, bool isPermitted);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Initialize `airdropPermits` with a batch of permitted airdops
     *
     * @param _admin - Initial admin of this contract.
     * @param _airdopContracts - The batch of airdrop contract addresses initially permitted.
     * @param _selectors - The batch of selector of the permitted functions for each `_airdopContracts`.
     */
    constructor(
        address _admin,
        address[] memory _airdopContracts,
        bytes4[] memory _selectors
    ) Ownable(_admin) {
        require(_airdopContracts.length == _selectors.length, "function information arity mismatch");
        for (uint256 i = 0; i < _airdopContracts.length; i++) {
            _setAirdroptPermit(_airdopContracts[i], _selectors[i], true);
        }
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice This function can be called by admins to change the permitted status of an airdrop. This includes
     * both adding an airdrop to the permitted list and removing it.
     *
     * @param _airdropContract - The address of airdrop contract whose permit list status changed.
     * @param _selector - The selector of the permitted function whose permit list status changed.
     * @param _permit - The new status of whether the airdrop is permitted or not.
     */
    function setAirdroptPermit(
        address _airdropContract,
        bytes4 _selector,
        bool _permit
    ) external onlyOwner {
        _setAirdroptPermit(_airdropContract, _selector, _permit);
    }

    /**
     * @notice This function can be called by admins to change the permitted status of a batch of airdrops. This
     * includes both adding an airdop to the permitted list and removing it.
     *
     * @param _airdropContracts - The addresses of the airdrop contracts whose permit list status changed.
     * @param _selectors - the selector of the permitted functions for each airdop whose permit list status changed.
     * @param _permits - The new statuses of whether the airdrop is permitted or not.
     */
    function setAirdroptPermits(
        address[] memory _airdropContracts,
        bytes4[] memory _selectors,
        bool[] memory _permits
    ) external onlyOwner {
        require(
            _airdropContracts.length == _selectors.length,
            "setAirdroptPermits function information arity mismatch"
        );
        require(_selectors.length == _permits.length, "setAirdroptPermits function information arity mismatch");

        for (uint256 i = 0; i < _airdropContracts.length; i++) {
            _setAirdroptPermit(_airdropContracts[i], _selectors[i], _permits[i]);
        }
    }

    /**
     * @notice This function can be called by anyone to get the permit associated with the airdrop.
     *
     * @param _addressSel - The address of the airdrop contract + function selector.
     *
     * @return Returns whether the airdrop is permitted
     */
    function isValidAirdrop(bytes memory _addressSel) external view override returns (bool) {
        return airdropPermits[_addressSel];
    }

    /**
     * @notice This function can be called by admins to change the permitted status of an airdrop. This includes
     * both adding an airdrop to the permitted list and removing it.
     *
     * @param _airdropContract - The address of airdrop contract whose permit list status changed.
     * @param _selector - The selector of the permitted function whose permit list status changed.
     * @param _permit - The new status of whether the airdrop is permitted or not.
     */
    function _setAirdroptPermit(
        address _airdropContract,
        bytes4 _selector,
        bool _permit
    ) internal {
        require(_airdropContract != address(0), "airdropContract is zero address");
        require(_selector != bytes4(0), "selector is empty");

        airdropPermits[abi.encode(_airdropContract, _selector)] = _permit;

        emit AirdropPermit(_airdropContract, _selector, _permit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPermittedAirdrops {
    function isValidAirdrop(bytes memory _addressSig) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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