// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/INftTypeRegistry.sol";
import "../interfaces/IPermittedPartners.sol";

import "../utils/Ownable.sol";

/**
 * @title  PermittedPartners
 * @author NFTfi
 * @dev Registry for partners permitted for reciving a revenue share.
 * Each partner's address is associated with the percent of the admin fee shared.
 */
contract PermittedPartners is Ownable, IPermittedPartners {
    /* ******* */
    /* STORAGE */
    /* ******* */

    uint256 public constant HUNDRED_PERCENT = 10000;

    /**
     * @notice A mapping from a partner's address to the percent of the admin fee shared with them. A zero indicates
     * non-permitted.
     */
    mapping(address => uint16) private partnerRevenueShare;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admin sets a partner's revenue share.
     *
     * @param partner - The address of the partner.
     * @param revenueShareInBasisPoints - The percent (measured in basis points) of the admin fee amount that will be
     * taken as a revenue share for a the partner.
     */
    event PartnerRevenueShare(address indexed partner, uint16 revenueShareInBasisPoints);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Sets the admin of the contract.
     *
     * @param _admin - Initial admin of this contract.
     */
    constructor(address _admin) Ownable(_admin) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice This function can be called by admins to change the revenue share status of a partner. This includes
     * adding an partner to the revenue share list, removing it and updating the revenue share percent.
     *
     * @param _partner - The address of the partner.
     * @param _revenueShareInBasisPoints - The percent (measured in basis points) of the admin fee amount that will be
     * taken as a revenue share for a the partner.
     */
    function setPartnerRevenueShare(address _partner, uint16 _revenueShareInBasisPoints) external onlyOwner {
        require(_partner != address(0), "Partner is address zero");
        require(_revenueShareInBasisPoints <= HUNDRED_PERCENT, "Revenue share too big");
        partnerRevenueShare[_partner] = _revenueShareInBasisPoints;
        emit PartnerRevenueShare(_partner, _revenueShareInBasisPoints);
    }

    /**
     * @notice This function can be called by anyone to get the revenue share parcent associated with the partner.
     *
     * @param _partner - The address of the partner.
     *
     * @return Returns the partner's revenue share
     */
    function getPartnerPermit(address _partner) external view override returns (uint16) {
        return partnerRevenueShare[_partner];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title INftTypeRegistry
 * @author NFTfi
 * @dev Interface for NFT Types Registry supported by NFTfi.
 */
interface INftTypeRegistry {
    function setNftType(bytes32 _nftType, address _nftWrapper) external;

    function getNftTypeWrapper(bytes32 _nftType) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPermittedPartners {
    function getPartnerPermit(address _partner) external view returns (uint16);
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