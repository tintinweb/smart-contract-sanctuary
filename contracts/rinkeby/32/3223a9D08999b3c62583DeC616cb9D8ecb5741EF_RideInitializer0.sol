// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IERC165} from "../interfaces/utils/IERC165.sol";
import {IERC173} from "../interfaces/utils/IERC173.sol";
import {IRideCut} from "../interfaces/utils/IRideCut.sol";
import {IRideLoupe} from "../interfaces/utils/IRideLoupe.sol";

import {IRideBadge} from "../interfaces/core/IRideBadge.sol";
import {IRideFee} from "../interfaces/core/IRideFee.sol";
import {IRidePenalty} from "../interfaces/core/IRidePenalty.sol";
import {IRideTicket} from "../interfaces/core/IRideTicket.sol";
import {IRideUser} from "../interfaces/core/IRideUser.sol";
import {IRidePassenger} from "../interfaces/core/IRidePassenger.sol";
import {IRideDriver} from "../interfaces/core/IRideDriver.sol";

import {RideBadge} from "../facets/core/RideBadge.sol";
import {RideFee} from "../facets/core/RideFee.sol";
import {RidePenalty} from "../facets/core/RidePenalty.sol";
import {RidePassenger} from "../facets/core/RidePassenger.sol";
import {RideDriver} from "../facets/core/RideDriver.sol";

import {RideLibCutAndLoupe} from "../libraries/utils/RideLibCutAndLoupe.sol";
import {RideLibUser} from "../libraries/core/RideLibUser.sol";

// It is exapected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract RideInitializer0 is
    RideBadge,
    RideFee,
    RidePenalty,
    RidePassenger,
    RideDriver
{
    function init(
        address _tokenAddress,
        uint256[] memory _badgesMaxScores,
        uint256 _requestFee,
        uint256 _baseFee,
        uint256 _costPerMinute,
        uint256[] memory _costPerMetre,
        uint256 _banDuration,
        uint256 _ratingMin,
        uint256 _ratingMax
    ) external {
        // ass inits within this function as needed

        // adding ERC165 data
        RideLibCutAndLoupe.StorageCutAndLoupe storage s1 = RideLibCutAndLoupe
            ._storageCutAndLoupe();
        s1.supportedInterfaces[type(IERC165).interfaceId] = true;
        s1.supportedInterfaces[type(IERC173).interfaceId] = true;
        s1.supportedInterfaces[type(IRideCut).interfaceId] = true;
        s1.supportedInterfaces[type(IRideLoupe).interfaceId] = true;

        s1.supportedInterfaces[type(IRideBadge).interfaceId] = true;
        s1.supportedInterfaces[type(IRideFee).interfaceId] = true;
        s1.supportedInterfaces[type(IRidePenalty).interfaceId] = true;
        s1.supportedInterfaces[type(IRideTicket).interfaceId] = true;
        s1.supportedInterfaces[type(IRideUser).interfaceId] = true;
        s1.supportedInterfaces[type(IRidePassenger).interfaceId] = true;
        s1.supportedInterfaces[type(IRideDriver).interfaceId] = true;

        RideLibUser.StorageUser storage s2 = RideLibUser._storageUser();
        s2.token = ERC20(_tokenAddress);

        setBadgesMaxScores(_badgesMaxScores);

        setRequestFee(_requestFee);
        setBaseFee(_baseFee);
        setCostPerMinute(_costPerMinute);
        setCostPerMetre(_costPerMetre);

        setRatingBounds(_ratingMin, _ratingMax);

        setBanDuration(_banDuration);

        _burnFirstDriverId();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _rideCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function rideCut(
        FacetCut[] calldata _rideCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event RideCut(FacetCut[] _rideCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IRideLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";

interface IRideBadge {
    function setBadgesMaxScores(uint256[] memory _badgesMaxScores) external;

    function getBadgeToBadgeMaxScore(uint256 _badge)
        external
        view
        returns (uint256);

    function getAddressToDriverReputation(address _driver)
        external
        view
        returns (RideLibBadge.DriverReputation memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideFee {
    function setRequestFee(uint256 _requestFee) external;

    function setBaseFee(uint256 _baseFee) external;

    function setCostPerMinute(uint256 _costPerMinute) external;

    function setCostPerMetre(uint256[] memory _costPerMetre) external;

    function getRequestFee() external view returns (uint256);

    function getBaseFee() external view returns (uint256);

    function getCostPerMinute() external view returns (uint256);

    function getBadgeToCostPerMetre(uint256 _badge)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRidePenalty {
    function setBanDuration(uint256 _banDuration) external;

    function getBanDuration() external view returns (uint256);

    function getAddressToBanEndTimestamp(address _address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

interface IRideTicket {
    function getAddressToTixId(address _address)
        external
        view
        returns (bytes32);

    function getTixIdToTicket(bytes32 _tixId)
        external
        view
        returns (RideLibTicket.Ticket memory);

    function getTixToDriverEnd(bytes32 _tixId)
        external
        view
        returns (RideLibTicket.DriverEnd memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideUser {
    function placeDeposit(uint256 _amount) external;

    function removeDeposit() external;

    function getTokenAddress() external view returns (address);

    function getAddressToDeposit(address _address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRidePassenger {
    function requestTicket(
        uint256 _badge,
        bool _strict,
        uint256 _metres,
        uint256 _minutes
    ) external;

    function cancelRequest() external;

    function startTrip(address _driver) external;

    function endTripPax(bool _agree, uint256 _rating) external;

    function forceEndPax() external;

    function setRatingBounds(uint256 _min, uint256 _max) external;

    function getRatingMin() external view returns (uint256);

    function getRatingMax() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideDriver {
    function registerAsDriver(uint256 _maxMetresPerTrip) external;

    function updateMaxMetresPerTrip(uint256 _maxMetresPerTrip) external;

    function acceptTicket(bytes32 _tixId, uint256 _useBadge) external;

    function cancelPickUp() external;

    function endTripDrv(bool _reached) external;

    function forceEndDrv() external;

    function passBackgroundCheck(address _driver, string memory _uri) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

import {IRideBadge} from "../../interfaces/core/IRideBadge.sol";

/// @title Badge rank for drivers
contract RideBadge is IRideBadge {
    enum Badges {
        Newbie,
        Bronze,
        Silver,
        Gold,
        Platinum,
        Veteran
    } // note: if we edit last badge, rmb edit RideLibBadge._getBadgesCount fn as well

    event SetBadgesMaxScores(address indexed sender, uint256[] scores);

    /**
     * TODO:
     * Check if setBadgesMaxScores is used in other contracts after
     * diamond pattern finalized. if no use then change visibility
     * to external
     */
    /**
     * setBadgesMaxScores maps score to badge
     *
     * @param _badgesMaxScores Score that defines a specific badge rank
     */
    function setBadgesMaxScores(uint256[] memory _badgesMaxScores)
        public
        override
    {
        RideLibOwnership.requireIsContractOwner();
        require(
            _badgesMaxScores.length == RideLibBadge._getBadgesCount() - 1,
            "_badgesMaxScores.length must be 1 less than Badges"
        );
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        for (uint256 i = 0; i < _badgesMaxScores.length; i++) {
            s1.badgeToBadgeMaxScore[i] = _badgesMaxScores[i];

            if (!s1._insertedMaxScore[i]) {
                s1._insertedMaxScore[i] = true;
                s1._badges.push(i);
            }
        }

        emit SetBadgesMaxScores(msg.sender, _badgesMaxScores);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getBadgeToBadgeMaxScore(uint256 _badge)
        external
        view
        override
        returns (uint256)
    {
        return RideLibBadge._storageBadge().badgeToBadgeMaxScore[_badge];
    }

    function getAddressToDriverReputation(address _driver)
        external
        view
        override
        returns (RideLibBadge.DriverReputation memory)
    {
        return RideLibBadge._storageBadge().addressToDriverReputation[_driver];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibFee} from "../../libraries/core/RideLibFee.sol";
import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

import {IRideFee} from "../../interfaces/core/IRideFee.sol";

contract RideFee is IRideFee {
    event FeeSetRequest(address indexed sender, uint256 fee);

    /**
     * setRequestFee sets request fee
     *
     * @param _requestFee | unit in token
     */
    function setRequestFee(uint256 _requestFee) public override {
        RideLibOwnership.requireIsContractOwner();
        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        s1.requestFee = _requestFee; // input format: token in Wei

        emit FeeSetRequest(msg.sender, _requestFee);
    }

    event FeeSetBase(address indexed sender, uint256 fee);

    /**
     * setBaseFee sets base fee
     *
     * @param _baseFee | unit in token
     */
    function setBaseFee(uint256 _baseFee) public override {
        RideLibOwnership.requireIsContractOwner();
        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        s1.baseFee = _baseFee; // input format: token in Wei

        emit FeeSetBase(msg.sender, _baseFee);
    }

    event FeeSetCostPerMinute(address indexed sender, uint256 fee);

    /**
     * setCostPerMinute sets cost per minute
     *
     * @param _costPerMinute | unit in token
     */
    function setCostPerMinute(uint256 _costPerMinute) public override {
        RideLibOwnership.requireIsContractOwner();
        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        s1.costPerMinute = _costPerMinute; // input format: token in Wei

        emit FeeSetCostPerMinute(msg.sender, _costPerMinute);
    }

    event FeeSetCostPerMetre(address indexed sender, uint256[] fee);

    /**
     * setCostPerMetre sets cost per metre
     *
     * @param _costPerMetre | unit in token
     */
    function setCostPerMetre(uint256[] memory _costPerMetre) public override {
        RideLibOwnership.requireIsContractOwner();
        require(
            _costPerMetre.length == RideLibBadge._getBadgesCount(),
            "_costPerMetre.length must be equal Badges"
        );
        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        for (uint256 i = 0; i < _costPerMetre.length; i++) {
            s1.badgeToCostPerMetre[i] = _costPerMetre[i]; // input format: token in Wei // rounded down
        }

        emit FeeSetCostPerMetre(msg.sender, _costPerMetre);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getRequestFee() external view override returns (uint256) {
        return RideLibFee._storageFee().requestFee;
    }

    function getBaseFee() external view override returns (uint256) {
        return RideLibFee._storageFee().baseFee;
    }

    function getCostPerMinute() external view override returns (uint256) {
        return RideLibFee._storageFee().costPerMinute;
    }

    function getBadgeToCostPerMetre(uint256 _badge)
        external
        view
        override
        returns (uint256)
    {
        return RideLibFee._storageFee().badgeToCostPerMetre[_badge];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibPenalty} from "../../libraries/core/RideLibPenalty.sol";
import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

import {IRidePenalty} from "../../interfaces/core/IRidePenalty.sol";

contract RidePenalty is IRidePenalty {
    event SetBanDuration(address indexed sender, uint256 _banDuration);

    /**
     * setBanDuration sets user ban duration
     *
     * @param _banDuration | unit in unix timestamp | https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html#time-units
     */
    function setBanDuration(uint256 _banDuration) public override {
        RideLibOwnership.requireIsContractOwner();
        RideLibPenalty.StoragePenalty storage s1 = RideLibPenalty
            ._storagePenalty();
        s1.banDuration = _banDuration;

        emit SetBanDuration(msg.sender, _banDuration);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getBanDuration() external view override returns (uint256) {
        return RideLibPenalty._storagePenalty().banDuration;
    }

    function getAddressToBanEndTimestamp(address _address)
        external
        view
        override
        returns (uint256)
    {
        return
            RideLibPenalty._storagePenalty().addressToBanEndTimestamp[_address];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibFee} from "../../libraries/core/RideLibFee.sol";
import {RideLibPenalty} from "../../libraries/core/RideLibPenalty.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";
import {RideLibUser} from "../../libraries/core/RideLibUser.sol";
import {RideLibPassenger} from "../../libraries/core/RideLibPassenger.sol";
import {RideLibDriver} from "../../libraries/core/RideLibDriver.sol";

import {IRidePassenger} from "../../interfaces/core/IRidePassenger.sol";

contract RidePassenger is IRidePassenger {
    event RequestTicket(
        address indexed sender,
        bytes32 indexed tixId,
        uint256 baseFee,
        uint256 costPerMinute,
        uint256 costPerMetre,
        uint256 minutesTaken,
        uint256 metresTravelled
    );

    /**
     * requestTicket allows passenger to request for ride
     *
     * @param _badge badge rank requested
     * @param _strict whether driver must meet requested badge rank exactly (true) or default - any badge rank equal or greater than (false)
     * @param _metres estimated distance from origin to destination as determined by Maps API
     * @param _minutes estimated time taken from origin to destination as determined by Maps API
     *
     * @custom:event RequestTicket
     */
    function requestTicket(
        uint256 _badge,
        bool _strict,
        uint256 _metres,
        uint256 _minutes
    ) external override {
        RideLibDriver.requireNotDriver();
        RideLibUser.requireNotActive();
        RideLibPenalty.requireNotBanned();

        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();
        RideLibUser.StorageUser storage s3 = RideLibUser._storageUser();

        uint256 fare = RideLibFee._getFare(
            s1.baseFee,
            _metres,
            _minutes,
            s1.badgeToCostPerMetre[_badge],
            s1.costPerMinute
        );
        require(
            s3.addressToDeposit[msg.sender] > fare,
            "passenger's deposit < fare"
        );

        bytes32 tixId = keccak256(abi.encode(msg.sender, block.timestamp));

        s2.tixIdToTicket[tixId].passenger = msg.sender;
        s2.tixIdToTicket[tixId].badge = _badge;
        s2.tixIdToTicket[tixId].strict = _strict;
        s2.tixIdToTicket[tixId].metres = _metres;
        s2.tixIdToTicket[tixId].fare = fare;

        s2.addressToTixId[msg.sender] = tixId;

        emit RequestTicket(
            msg.sender,
            tixId,
            s1.baseFee,
            s1.costPerMinute,
            s1.badgeToCostPerMetre[_badge],
            _minutes,
            _metres
        );
    }

    event RequestCancelled(address indexed sender, bytes32 indexed tixId);

    /**
     * cancelRequest cancels ticket, can only be called before startTrip
     *
     * @custom:event RequestCancelled
     */
    function cancelRequest() external override {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibPassenger.requireTripNotStart();

        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        address driver = s2.tixIdToTicket[tixId].driver;
        if (driver != address(0)) {
            // case when cancel inbetween driver accepted, but haven't reach passenger
            // give warning at frontend to passenger
            RideLibUser._transfer(tixId, s1.requestFee, msg.sender, driver);
        }

        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit RequestCancelled(msg.sender, tixId); // --> update frontend request pool
    }

    event TripStarted(
        address indexed passenger,
        bytes32 indexed tixId,
        address driver
    );

    /**
     * startTrip starts the trip, can only be called once driver reached passenger
     *
     * @param _driver driver's address - get via QR scan?
     *
     * @custom:event TripStarted
     */
    function startTrip(address _driver) external override {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibDriver.requireDrvMatchTixDrv(_driver);
        RideLibPassenger.requireTripNotStart();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        s1.addressToDriverReputation[_driver].countStart += 1;
        s2.tixIdToTicket[tixId].tripStart = true;
        s2.tixIdToTicket[tixId].forceEndTimestamp = block.timestamp + 1 days; // TODO: change 1 day to setter fn

        emit TripStarted(msg.sender, tixId, _driver); // update frontend
    }

    event TripEndedPax(address indexed sender, bytes32 indexed tixId);

    /**
     * endTripPax ends the trip, can only be called once driver has called either endTripDrv
     *
     * @param _agree agreement from passenger that either destination has been reached or not
     * @param _rating refer _giveRating
     *
     * @custom:event TripEndedPax
     *
     * Driver would select destination reached or not, and event will emit to passenger's UI
     * then passenger would agree if this is true or false (via frontend UI), followed by a rating.
     * No matter what, passenger needs to pay fare, so incentive to passenger to be kind so driver
     * get passenger to destination. This prevents passenger abuse.
     */
    function endTripPax(bool _agree, uint256 _rating) external override {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibPassenger.requireTripInProgress();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        address driver = s2.tixToDriverEnd[tixId].driver;
        require(driver != address(0), "driver must end trip");
        require(
            _agree,
            "pax must agree destination reached or not - indicated by driver"
        );

        RideLibUser._transfer(
            tixId,
            s2.tixIdToTicket[tixId].fare,
            msg.sender,
            driver
        );
        if (s2.tixToDriverEnd[tixId].reached) {
            s1.addressToDriverReputation[driver].metresTravelled += s2
                .tixIdToTicket[tixId]
                .metres;
            s1.addressToDriverReputation[driver].countEnd += 1;
        }

        RideLibPassenger._giveRating(driver, _rating);

        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit TripEndedPax(msg.sender, tixId);
    }

    event ForceEndPax(address indexed sender, bytes32 indexed tixId);

    /**
     * forceEndPax can be called after tixIdToTicket[tixId].forceEndTimestamp duration
     * and if driver has NOT called endTripDrv
     *
     * @custom:event ForceEndPax
     *
     * no fare is paid, but driver is temporarily banned for banDuration
     */
    function forceEndPax() external override {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibPassenger.requireTripInProgress(); /** means both parties still active */
        RideLibPassenger.requireForceEndAllowed();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.addressToTixId[msg.sender];
        require(
            s1.tixToDriverEnd[tixId].driver == address(0),
            "driver ended trip"
        ); // TODO: test
        address driver = s1.tixIdToTicket[tixId].driver;

        RideLibPenalty._temporaryBan(driver);
        RideLibPassenger._giveRating(driver, 1);
        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit ForceEndPax(msg.sender, tixId);
    }

    /**
     * setRatingBounds sets bounds for rating
     *
     * @param _min | unitless integer
     * @param _max | unitless integer
     */
    function setRatingBounds(uint256 _min, uint256 _max) public override {
        RideLibOwnership.requireIsContractOwner();
        RideLibPassenger.StoragePassenger storage s1 = RideLibPassenger
            ._storagePassenger();
        s1.ratingMin = _min;
        s1.ratingMax = _max;
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getRatingMin() external view override returns (uint256) {
        return RideLibPassenger._storagePassenger().ratingMin;
    }

    function getRatingMax() external view override returns (uint256) {
        return RideLibPassenger._storagePassenger().ratingMax;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibFee} from "../../libraries/core/RideLibFee.sol";
import {RideLibPenalty} from "../../libraries/core/RideLibPenalty.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";
import {RideLibUser} from "../../libraries/core/RideLibUser.sol";
import {RideLibPassenger} from "../../libraries/core/RideLibPassenger.sol";
import {RideLibDriver} from "../../libraries/core/RideLibDriver.sol";

import {IRideDriver} from "../../interfaces/core/IRideDriver.sol";

contract RideDriver is IRideDriver {
    using Counters for Counters.Counter;
    Counters.Counter private _driverIdCounter;

    event RegisteredAsDriver(address indexed sender);

    /**
     * registerDriver registers approved applicants (has passed background check)
     *
     * @param _maxMetresPerTrip | unit in metre
     *
     * @custom:event RegisteredAsDriver
     */
    function registerAsDriver(uint256 _maxMetresPerTrip) external override {
        RideLibDriver.requireNotDriver();
        RideLibUser.requireNotActive();
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        require(
            bytes(s1.addressToDriverReputation[msg.sender].uri).length != 0,
            "uri not set in bg check"
        );
        require(msg.sender != address(0), "0 address");

        s1.addressToDriverReputation[msg.sender].id = _mint();
        s1
            .addressToDriverReputation[msg.sender]
            .maxMetresPerTrip = _maxMetresPerTrip;
        s1.addressToDriverReputation[msg.sender].metresTravelled = 0;
        s1.addressToDriverReputation[msg.sender].countStart = 0;
        s1.addressToDriverReputation[msg.sender].countEnd = 0;
        s1.addressToDriverReputation[msg.sender].totalRating = 0;
        s1.addressToDriverReputation[msg.sender].countRating = 0;

        emit RegisteredAsDriver(msg.sender);
    }

    event MaxMetresUpdated(address indexed sender, uint256 metres);

    /**
     * updateMaxMetresPerTrip updates maximum metre per trip of driver
     *
     * @param _maxMetresPerTrip | unit in metre
     */
    function updateMaxMetresPerTrip(uint256 _maxMetresPerTrip)
        external
        override
    {
        RideLibDriver.requireIsDriver();
        RideLibUser.requireNotActive();
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        s1
            .addressToDriverReputation[msg.sender]
            .maxMetresPerTrip = _maxMetresPerTrip;

        emit MaxMetresUpdated(msg.sender, _maxMetresPerTrip);
    }

    event AcceptedTicket(address indexed sender, bytes32 indexed tixId);

    /**
     * acceptTicket allows driver to accept passenger's ticket request
     *
     * @param _tixId Ticket ID
     * @param _useBadge allows driver to use any badge rank equal to or lower than current rank 
     (this is to give driver the option of lower cosr per metre rates)
     *
     * @custom:event AcceptedTicket
     *
     * higher badge can charge higher price, but what if passenger always choose lower price?
     * (badgeToCostPerMetre[_badge], at RidePassenger.sol) then higher badge driver wont get chosen at all
     * solution: _useBadge that allows driver to choose which badge rank they want to use up to achieved badge rank
     * at frontend, default _useBadge to driver's current badge rank
     */
    function acceptTicket(bytes32 _tixId, uint256 _useBadge) external override {
        RideLibDriver.requireIsDriver();
        RideLibUser.requireNotActive();
        RideLibPenalty.requireNotBanned();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();
        RideLibUser.StorageUser storage s3 = RideLibUser._storageUser();
        RideLibPassenger.StoragePassenger storage s4 = RideLibPassenger
            ._storagePassenger();

        require(
            s2.tixIdToTicket[_tixId].passenger != address(0),
            "ticket not exists"
        );

        uint256 driverScore = RideLibBadge._calculateScore(
            s1.addressToDriverReputation[msg.sender].metresTravelled,
            s1.addressToDriverReputation[msg.sender].countStart,
            s1.addressToDriverReputation[msg.sender].countEnd,
            s1.addressToDriverReputation[msg.sender].totalRating,
            s1.addressToDriverReputation[msg.sender].countRating,
            s4.ratingMax
        );
        uint256 driverBadge = RideLibBadge._getBadge(driverScore);
        require(_useBadge <= driverBadge, "badge rank not achieved");

        require(
            s3.addressToDeposit[msg.sender] > s2.tixIdToTicket[_tixId].fare,
            "driver's deposit < fare"
        );
        require(
            s2.tixIdToTicket[_tixId].metres <=
                s1.addressToDriverReputation[msg.sender].maxMetresPerTrip,
            "trip too long"
        );
        if (s2.tixIdToTicket[_tixId].strict) {
            require(
                _useBadge == s2.tixIdToTicket[_tixId].badge,
                "driver not meet badge - strict"
            );
        } else {
            require(
                _useBadge >= s2.tixIdToTicket[_tixId].badge,
                "driver not meet badge"
            );
        }

        s2.tixIdToTicket[_tixId].driver = msg.sender;
        s2.addressToTixId[msg.sender] = _tixId;

        emit AcceptedTicket(msg.sender, _tixId); // --> update frontend (also, add warning that if passenger cancel, will incure fee)
    }

    event DriverCancelled(address indexed sender, bytes32 indexed tixId);

    /**
     * cancelPickUp cancels pick up, can only be called before startTrip
     *
     * @custom:event DriverCancelled
     */
    function cancelPickUp() external override {
        RideLibDriver.requireDrvMatchTixDrv(msg.sender);
        RideLibPassenger.requireTripNotStart();

        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        address passenger = s2.tixIdToTicket[tixId].passenger;

        RideLibUser._transfer(tixId, s1.requestFee, msg.sender, passenger);

        RideLibTicket._cleanUp(tixId, passenger, msg.sender);

        emit DriverCancelled(msg.sender, tixId); // --> update frontend
    }

    event TripEndedDrv(
        address indexed sender,
        bytes32 indexed tixId,
        bool reached
    );

    /**
     * endTripDrv allows driver to indicate to passenger to end trip and destination is either reached or not
     *
     * @param _reached boolean indicating whether destination has been reach or not
     *
     * @custom:event TripEndedDrv
     */
    // TODO: test that this fn can be recalled immediately after first call so that driver can change _reached status if needed. Test in remix first.
    function endTripDrv(bool _reached) external override {
        RideLibDriver.requireDrvMatchTixDrv(msg.sender);
        RideLibPassenger.requireTripInProgress();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.addressToTixId[msg.sender];
        // tixToDriverEnd[tixId] = DriverEnd({driver: msg.sender, reached: true}); // takes up more space
        s1.tixToDriverEnd[tixId].driver = msg.sender;
        s1.tixToDriverEnd[tixId].reached = _reached;

        emit TripEndedDrv(msg.sender, tixId, _reached);
    }

    event ForceEndDrv(address indexed sender, bytes32 indexed tixId);

    /**
     * forceEndDrv can be called after tixIdToTicket[tixId].forceEndTimestamp duration
     * and if passenger has not called endTripPax
     *
     * @custom:event ForceEndDrv
     *
     * no fare is paid, but passenger is temporarily banned for banDuration
     */
    function forceEndDrv() external override {
        RideLibDriver.requireDrvMatchTixDrv(msg.sender);
        RideLibPassenger.requireTripInProgress(); /** means both parties still active */
        RideLibPassenger.requireForceEndAllowed();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.addressToTixId[msg.sender];
        require(
            s1.tixToDriverEnd[tixId].driver != address(0),
            "driver must end trip"
        ); // TODO: test
        address passenger = s1.tixIdToTicket[tixId].passenger;

        RideLibPenalty._temporaryBan(passenger);
        RideLibTicket._cleanUp(tixId, passenger, msg.sender);

        emit ForceEndDrv(msg.sender, tixId);
    }

    event ApplicantApproved(address indexed applicant);

    /**
     * passBackgroundCheck of driver applicants
     *
     * @param _driver applicant
     * @param _uri information of applicant
     *
     * @custom:event ApplicantApproved
     */
    function passBackgroundCheck(address _driver, string memory _uri)
        external
        override
    {
        RideLibOwnership.requireIsContractOwner();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();

        require(
            bytes(s1.addressToDriverReputation[_driver].uri).length == 0,
            "uri already set"
        );
        s1.addressToDriverReputation[_driver].uri = _uri;

        emit ApplicantApproved(_driver);
    }

    /**
     * _mint a driver ID
     *
     * @return driver ID
     */
    function _mint() internal returns (uint256) {
        uint256 id = _driverIdCounter.current();
        _driverIdCounter.increment();
        return id;
    }

    /**
     * _burnFirstDriverId burns driver ID 0
     * can only be called at RideHub deployment
     *
     * TODO: call at init ONLY
     */
    function _burnFirstDriverId() internal {
        assert(_driverIdCounter.current() == 0);
        _driverIdCounter.increment();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {IRideCut} from "../../interfaces/utils/IRideCut.sol";

library RideLibCutAndLoupe {
    bytes32 constant STORAGE_POSITION_CUTANDLOUPE = keccak256("ds.cutandloupe");

    struct StorageCutAndLoupe {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
    }

    function _storageCutAndLoupe()
        internal
        pure
        returns (StorageCutAndLoupe storage s)
    {
        bytes32 position = STORAGE_POSITION_CUTANDLOUPE;
        assembly {
            s.slot := position
        }
    }

    event RideCut(IRideCut.FacetCut[] _rideCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of rideCut
    // This code is almost the same as the external rideCut,
    // except it is using 'Facet[] memory _rideCut' instead of
    // 'Facet[] calldata _rideCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function rideCut(
        IRideCut.FacetCut[] memory _rideCut,
        address _init,
        bytes memory _calldata
    ) internal {
        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        uint256 originalSelectorCount = s1.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = s1.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _rideCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _rideCut[facetIndex].facetAddress,
                _rideCut[facetIndex].action,
                _rideCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            s1.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            s1.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit RideCut(_rideCut, _init, _calldata);
        initializeRideCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IRideCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        StorageCutAndLoupe storage s1 = _storageCutAndLoupe();
        require(
            _selectors.length > 0,
            "RideLibCutAndLoupe: No selectors in facet to cut"
        );
        if (_action == IRideCut.FacetCutAction.Add) {
            requireHasContractCode(
                _newFacetAddress,
                "RideLibCutAndLoupe: Add facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "RideLibCutAndLoupe: Can't add function that already exists"
                );
                // add facet for selector
                s1.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    s1.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IRideCut.FacetCutAction.Replace) {
            requireHasContractCode(
                _newFacetAddress,
                "RideLibCutAndLoupe: Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = s1.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "RideLibCutAndLoupe: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "RideLibCutAndLoupe: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "RideLibCutAndLoupe: Can't replace function that doesn't exist"
                );
                // replace old facet address
                s1.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IRideCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "RideLibCutAndLoupe: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = s1.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = s1.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "RideLibCutAndLoupe: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "RideLibCutAndLoupe: Can't remove immutable function"
                    );
                    // replace selector with last selector in s1.facets
                    // gets the last selector
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        s1.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(s1.facets[lastSelector]);
                    }
                    delete s1.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = s1.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    s1.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete s1.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("RideLibCutAndLoupe: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeRideCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "RideLibCutAndLoupe: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "RideLibCutAndLoupe: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                requireHasContractCode(
                    _init,
                    "RideLibCutAndLoupe: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("RideLibCutAndLoupe: _init function reverted");
                }
            }
        }
    }

    function requireHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibUser {
    bytes32 constant STORAGE_POSITION_USER = keccak256("ds.user");

    struct StorageUser {
        ERC20 token;
        mapping(address => uint256) addressToDeposit;
    }

    function _storageUser() internal pure returns (StorageUser storage s) {
        bytes32 position = STORAGE_POSITION_USER;
        assembly {
            s.slot := position
        }
    }

    function requireNotActive() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(s1.addressToTixId[msg.sender] == 0, "caller is active");
    }

    event TokensTransferred(
        address indexed decrease,
        bytes32 indexed tixId,
        address increase,
        uint256 amount
    );

    /**
     * _transfer rebalances _amount tokens from one address to another
     *
     * @param _tixId Ticket ID
     * @param _amount | unit in token
     * @param _decrease address to decrease tokens by
     * @param _increase address to increase tokens by
     *
     * @custom:event TokensTransferred
     *
     * not use msg.sender instead of _decrease param? in case admin is required to sort things out
     */
    function _transfer(
        bytes32 _tixId,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        StorageUser storage s1 = _storageUser();

        s1.addressToDeposit[_decrease] -= _amount;
        s1.addressToDeposit[_increase] += _amount;

        emit TokensTransferred(_decrease, _tixId, _increase, _amount); // note decrease is sender
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideBadge} from "../../facets/core/RideBadge.sol";

library RideLibBadge {
    bytes32 constant STORAGE_POSITION_BADGE = keccak256("ds.badge");

    /**
     * lifetime cumulative values of drivers
     */
    struct DriverReputation {
        uint256 id;
        string uri;
        uint256 maxMetresPerTrip;
        uint256 metresTravelled;
        uint256 countStart;
        uint256 countEnd;
        uint256 totalRating;
        uint256 countRating;
    }

    struct StorageBadge {
        mapping(uint256 => uint256) badgeToBadgeMaxScore;
        mapping(uint256 => bool) _insertedMaxScore;
        uint256[] _badges;
        mapping(address => DriverReputation) addressToDriverReputation;
    }

    function _storageBadge() internal pure returns (StorageBadge storage s) {
        bytes32 position = STORAGE_POSITION_BADGE;
        assembly {
            s.slot := position
        }
    }

    /**
     * _getBadgesCount returns number of recognized badges
     *
     * @return badges count
     */
    function _getBadgesCount() internal pure returns (uint256) {
        return uint256(RideBadge.Badges.Veteran) + 1;
    }

    /**
     * _getBadge returns the badge rank for given score
     *
     * @param _score | unitless integer
     *
     * @return badge rank
     */
    function _getBadge(uint256 _score) internal view returns (uint256) {
        StorageBadge storage s1 = _storageBadge();

        for (uint256 i = 0; i < s1._badges.length; i++) {
            require(
                s1.badgeToBadgeMaxScore[s1._badges[i]] > 0,
                "zero badge score bounds"
            );
        }

        if (_score <= s1.badgeToBadgeMaxScore[0]) {
            return uint256(RideBadge.Badges.Newbie);
        } else if (
            _score > s1.badgeToBadgeMaxScore[0] &&
            _score <= s1.badgeToBadgeMaxScore[1]
        ) {
            return uint256(RideBadge.Badges.Bronze);
        } else if (
            _score > s1.badgeToBadgeMaxScore[1] &&
            _score <= s1.badgeToBadgeMaxScore[2]
        ) {
            return uint256(RideBadge.Badges.Silver);
        } else if (
            _score > s1.badgeToBadgeMaxScore[2] &&
            _score <= s1.badgeToBadgeMaxScore[3]
        ) {
            return uint256(RideBadge.Badges.Gold);
        } else if (
            _score > s1.badgeToBadgeMaxScore[3] &&
            _score <= s1.badgeToBadgeMaxScore[4]
        ) {
            return uint256(RideBadge.Badges.Platinum);
        } else {
            return uint256(RideBadge.Badges.Veteran);
        }
    }

    /**
     * _calculateScore calculates score from driver's reputation details (see params of function)
     *
     * @param _metresTravelled | unit in metre
     * @param _countStart      | unitless integer
     * @param _countEnd        | unitless integer
     * @param _totalRating     | unitless integer
     * @param _countRating     | unitless integer
     * @param _maxRating       | unitless integer
     *
     * @return Driver's score to determine badge rank | unitless integer
     *
     * Derive Driver's Score Formula:-
     *
     * Score is fundamentally determined based on distance travelled, where the more trips a driver makes,
     * the higher the score. Thus, the base score is directly proportional to:
     *
     * _metresTravelled
     *
     * where _metresTravelled is the total cumulative distance covered by the driver over all trips made.
     *
     * To encourage the completion of trips, the base score would be penalized by the amount of incomplete
     * trips, using:
     *
     *  _countEnd / _countStart
     *
     * which is the ratio of number of trips complete to the number of trips started. This gives:
     *
     * _metresTravelled * (_countEnd / _countStart)
     *
     * Driver score should also be influenced by passenger's rating of the overall trip, thus, the base
     * score is further penalized by the average driver rating over all trips, given by:
     *
     * _totalRating / _countRating
     *
     * where _totalRating is the cumulative rating value by passengers over all trips and _countRating is
     * the total number of rates by those passengers. The rating penalization is also divided by the max
     * possible rating score to make the penalization a ratio:
     *
     * (_totalRating / _countRating) / _maxRating
     *
     * The score formula is given by:
     *
     * _metresTravelled * (_countEnd / _countStart) * ((_totalRating / _countRating) / _maxRating)
     *
     * which simplifies to:
     *
     * (_metresTravelled * _countEnd * _totalRating) / (_countStart * _countRating * _maxRating)
     *
     * note: Solidity rounds down return value to the nearest whole number.
     *
     * note: Score is used to determine badge rank. To determine which score corresponds to which rank,
     *       can just determine from _metresTravelled, as other variables are just penalization factors.
     */
    function _calculateScore(
        uint256 _metresTravelled,
        uint256 _countStart,
        uint256 _countEnd,
        uint256 _totalRating,
        uint256 _countRating,
        uint256 _maxRating
    ) internal pure returns (uint256) {
        if (_countStart == 0) {
            return 0;
        } else {
            return
                (_metresTravelled * _countEnd * _totalRating) /
                (_countStart * _countRating * _maxRating);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibOwnership {
    bytes32 constant STORAGE_POSITION_OWNERSHIP = keccak256("ds.ownership");

    struct StorageOwnership {
        address contractOwner;
    }

    function _storageOwnership()
        internal
        pure
        returns (StorageOwnership storage s)
    {
        bytes32 position = STORAGE_POSITION_OWNERSHIP;
        assembly {
            s.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        StorageOwnership storage s1 = _storageOwnership();
        address previousOwner = s1.contractOwner;
        s1.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address) {
        return _storageOwnership().contractOwner;
    }

    function requireIsContractOwner() internal view {
        require(
            msg.sender == _storageOwnership().contractOwner,
            "not contract owner"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibTicket {
    bytes32 constant STORAGE_POSITION_TICKET = keccak256("ds.ticket");

    /**
     * @dev if a ticket exists (details not 0) in tixIdToTicket, then it is considered active
     *
     * @custom:TODO: Make it loopable so that can list to drivers?
     */
    struct Ticket {
        address passenger;
        address driver;
        uint256 badge;
        bool strict;
        uint256 metres;
        uint256 fare;
        bool tripStart;
        uint256 forceEndTimestamp;
    }

    /**
     * *Required to confirm if driver did initiate destination reached or not
     */
    struct DriverEnd {
        address driver;
        bool reached;
    }

    struct StorageTicket {
        mapping(address => bytes32) addressToTixId;
        mapping(bytes32 => Ticket) tixIdToTicket;
        mapping(bytes32 => DriverEnd) tixToDriverEnd;
    }

    function _storageTicket() internal pure returns (StorageTicket storage s) {
        bytes32 position = STORAGE_POSITION_TICKET;
        assembly {
            s.slot := position
        }
    }

    event TicketCleared(address indexed sender, bytes32 indexed tixId);

    /**
     * _cleanUp clears ticket information and set active status of users to false
     *
     * @param _tixId Ticket ID
     * @param _passenger passenger's address
     * @param _driver driver's address
     *
     * @custom:event TicketCleared
     */
    function _cleanUp(
        bytes32 _tixId,
        address _passenger,
        address _driver
    ) internal {
        StorageTicket storage s1 = _storageTicket();
        delete s1.tixIdToTicket[_tixId];
        delete s1.tixToDriverEnd[_tixId];
        delete s1.addressToTixId[_passenger];
        delete s1.addressToTixId[_driver];

        emit TicketCleared(msg.sender, _tixId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibFee {
    bytes32 constant STORAGE_POSITION_FEE = keccak256("ds.fee");

    struct StorageFee {
        uint256 requestFee;
        uint256 baseFee;
        uint256 costPerMinute;
        mapping(uint256 => uint256) badgeToCostPerMetre;
    }

    function _storageFee() internal pure returns (StorageFee storage s) {
        bytes32 position = STORAGE_POSITION_FEE;
        assembly {
            s.slot := position
        }
    }

    /**
     * _getFare calculates the fare of a trip.
     *
     * @param _baseFee        | unit in token
     * @param _metresTravelled | unit in metre
     * @param _minutesTaken    | unit in minute
     * @param _costPerMetre    | unit in token
     * @param _costPerMinute   | unit in token
     *
     * @return Fare | unit in token
     *
     * _metresTravelled and _minutesTaken are rounded down,
     * for example, if _minutesTaken is 1.5 minutes (90 seconds) then round to 1 minute
     * if _minutesTaken is 0.5 minutes (30 seconds) then round to 0 minute
     */
    function _getFare(
        uint256 _baseFee,
        uint256 _metresTravelled,
        uint256 _minutesTaken,
        uint256 _costPerMetre,
        uint256 _costPerMinute
    ) internal pure returns (uint256) {
        return (_baseFee +
            (_metresTravelled * _costPerMetre) +
            (_minutesTaken * _costPerMinute));
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibPenalty {
    bytes32 constant STORAGE_POSITION_PENALTY = keccak256("ds.penalty");

    struct StoragePenalty {
        uint256 banDuration;
        mapping(address => uint256) addressToBanEndTimestamp;
    }

    function _storagePenalty()
        internal
        pure
        returns (StoragePenalty storage s)
    {
        bytes32 position = STORAGE_POSITION_PENALTY;
        assembly {
            s.slot := position
        }
    }

    function requireNotBanned() internal view {
        StoragePenalty storage s1 = _storagePenalty();
        require(
            block.timestamp >= s1.addressToBanEndTimestamp[msg.sender],
            "still banned"
        );
    }

    event UserBanned(address indexed banned, uint256 from, uint256 to);

    /**
     * _temporaryBan user
     *
     * @param _address address to be banned
     *
     * @custom:event UserBanned
     */
    function _temporaryBan(address _address) internal {
        StoragePenalty storage s1 = _storagePenalty();
        uint256 banUntil = block.timestamp + s1.banDuration;
        s1.addressToBanEndTimestamp[_address] = banUntil;

        emit UserBanned(_address, block.timestamp, banUntil);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibPassenger {
    bytes32 constant STORAGE_POSITION_PASSENGER = keccak256("ds.passenger");

    struct StoragePassenger {
        uint256 ratingMin;
        uint256 ratingMax;
    }

    function _storagePassenger()
        internal
        pure
        returns (StoragePassenger storage s)
    {
        bytes32 position = STORAGE_POSITION_PASSENGER;
        assembly {
            s.slot := position
        }
    }

    function requirePaxMatchTixPax() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            msg.sender ==
                s1.tixIdToTicket[s1.addressToTixId[msg.sender]].passenger,
            "pax not match tix pax"
        );
    }

    function requireTripNotStart() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            !s1.tixIdToTicket[s1.addressToTixId[msg.sender]].tripStart,
            "trip already started"
        );
    }

    function requireTripInProgress() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            s1.tixIdToTicket[s1.addressToTixId[msg.sender]].tripStart,
            "trip not started"
        );
    }

    function requireForceEndAllowed() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            block.timestamp >
                s1
                    .tixIdToTicket[s1.addressToTixId[msg.sender]]
                    .forceEndTimestamp,
            "too early"
        );
    }

    /**
     * _giveRating
     *
     * @param _driver driver's address
     * @param _rating unitless integer between RATING_MIN and RATING_MAX
     *
     */
    function _giveRating(address _driver, uint256 _rating) internal {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        StoragePassenger storage s2 = _storagePassenger();

        require(s2.ratingMin > 0, "minimum rating must be more than zero");
        require(s2.ratingMax > 0, "maximum rating must be more than zero");
        require(
            _rating >= s2.ratingMin && _rating <= s2.ratingMax,
            "rating must be within min and max ratings (inclusive)"
        );

        s1.addressToDriverReputation[_driver].totalRating += _rating;
        s1.addressToDriverReputation[_driver].countRating += 1;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibDriver {
    function requireDrvMatchTixDrv(address _driver) internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            _driver == s1.tixIdToTicket[s1.addressToTixId[msg.sender]].driver,
            "drv not match tix drv"
        );
    }

    function requireIsDriver() internal view {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        require(
            s1.addressToDriverReputation[msg.sender].id != 0,
            "caller not driver"
        );
    }

    function requireNotDriver() internal view {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        require(
            s1.addressToDriverReputation[msg.sender].id == 0,
            "caller is driver"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}