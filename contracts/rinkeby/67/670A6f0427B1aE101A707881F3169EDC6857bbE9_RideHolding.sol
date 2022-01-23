//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";
import {RideLibHolding} from "../../libraries/core/RideLibHolding.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

import {IRideHolding} from "../../interfaces/core/IRideHolding.sol";

contract RideHolding is IRideHolding, ReentrancyGuard {
    /**
     * placeDeposit allows users to deposit token into RideHub contract
     *
     * @dev call token contract's "approve" first
     *
     * @param _amount | unit in token
     *
     * @custom:event TokensDeposited
     */
    function depositTokens(bytes32 _key, uint256 _amount) external override {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        RideLibCurrencyRegistry._requireIsCrypto(_key);
        require(_amount > 0, "zero amount");
        address token = address(bytes20(_key)); // convert to address
        require(token != address(0), "zero token address");

        require(
            IERC20(token).allowance(msg.sender, address(this)) >= _amount,
            "check token allowance"
        );
        bool sent = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        require(sent, "tx failed");

        RideLibHolding._storageHolding().userToCurrencyKeyToHolding[msg.sender][
                _key
            ] += _amount;

        emit TokensDeposited(msg.sender, _amount);
    }

    /**
     * removeDeposit allows users to remove token from RideHub contract
     *
     * @custom:event TokensRemoved
     */
    function withdrawTokens(bytes32 _key, uint256 _amount)
        external
        override
        nonReentrant
    {
        RideLibTicket._requireNotActive();
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        RideLibCurrencyRegistry._requireIsCrypto(_key);
        require(_amount > 0, "zero amount");
        address token = address(bytes20(_key)); // convert to address
        require(token != address(0), "zero token address");

        RideLibHolding.StorageHolding storage s1 = RideLibHolding
            ._storageHolding();
        require(
            s1.userToCurrencyKeyToHolding[msg.sender][_key] >= _amount,
            "insufficient holdings"
        );
        require(
            IERC20(token).balanceOf(address(this)) >= _amount,
            "contract insufficient funds"
        ); // note: if no bugs then this should never be called

        s1.userToCurrencyKeyToHolding[msg.sender][_key] -= _amount;
        bool sent = IERC20(token).transfer(msg.sender, _amount);
        // bool sent = token.transferFrom(address(this), msg.sender, _amount);
        require(sent, "tx failed");

        emit TokensRemoved(msg.sender, _amount);
    }

    function getHolding(address _user, bytes32 _key)
        external
        view
        override
        returns (uint256)
    {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        return
            RideLibHolding._storageHolding().userToCurrencyKeyToHolding[_user][
                _key
            ];
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

// CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library RideLibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
        mapping(bytes32 => bool) currencyKeyToSupported;
        mapping(bytes32 => bool) currencyKeyToCrypto;
    }

    function _storageCurrencyRegistry()
        internal
        pure
        returns (StorageCurrencyRegistry storage s)
    {
        bytes32 position = STORAGE_POSITION_CURRENCYREGISTRY;
        assembly {
            s.slot := position
        }
    }

    function _requireCurrencySupported(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToSupported[_key],
            "currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "not crypto"
        );
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        bytes32 key = keccak256(abi.encode(_code));
        _register(key);
        return key;
    }

    function _registerCrypto(address _token) internal returns (bytes32) {
        require(_token != address(0), "zero token address");
        bytes32 key = bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        RideLibOwnership._requireIsContractOwner();
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    // // _getKeyFiat to be called externally ONLY
    // function _getKeyFiat(string memory _code) internal view returns (bytes32) {
    //     bytes32 key = keccak256(abi.encode(_code));
    //     _requireCurrencySupported(key);
    //     return key;
    // }

    // // _getKeyCrypto to be called externally ONLY
    // function _getKeyCrypto(address _token) internal view returns (bytes32) {
    //     bytes32 key = bytes32(uint256(uint160(_token)) << 96);
    //     _requireCurrencySupported(key);
    //     return key;
    // }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        RideLibOwnership._requireIsContractOwner();
        _requireCurrencySupported(_key);
        StorageCurrencyRegistry storage s1 = _storageCurrencyRegistry();
        delete s1.currencyKeyToSupported[_key]; // delete cheaper than set false
        // require(!s1.currencyKeyToSupported[_key], "failed to remove 1");

        if (s1.currencyKeyToCrypto[_key]) {
            delete s1.currencyKeyToCrypto[_key];
            // require(!s1.currencyKeyToCrypto[_key], "failed to remove 2");
        }

        emit CurrencyRemoved(msg.sender, _key);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";

library RideLibHolding {
    bytes32 constant STORAGE_POSITION_HOLDING = keccak256("ds.holding");

    struct StorageHolding {
        mapping(address => mapping(bytes32 => uint256)) userToCurrencyKeyToHolding;
    }

    function _storageHolding()
        internal
        pure
        returns (StorageHolding storage s)
    {
        bytes32 position = STORAGE_POSITION_HOLDING;
        assembly {
            s.slot := position
        }
    }

    event CurrencyTransferred(
        address indexed decrease,
        bytes32 indexed tixId,
        address increase,
        bytes32 key,
        uint256 amount
    );

    /**
     * _transfer rebalances _amount tokens from one address to another
     *
     * @param _tixId Ticket ID
     * @param _key currency key
     * @param _amount | unit in token
     * @param _decrease address to decrease tokens by
     * @param _increase address to increase tokens by
     *
     * @custom:event CurrencyTransferred
     *
     * not use msg.sender instead of _decrease param? in case admin is required to sort things out
     */
    function _transferCurrency(
        bytes32 _tixId,
        bytes32 _key,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        StorageHolding storage s1 = _storageHolding();

        s1.userToCurrencyKeyToHolding[_decrease][_key] -= _amount;
        s1.userToCurrencyKeyToHolding[_increase][_key] += _amount;

        emit CurrencyTransferred(_decrease, _tixId, _increase, _key, _amount); // note decrease is sender
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
        bytes32 keyLocal;
        bytes32 keyPay;
        uint256 requestFee;
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
        mapping(address => bytes32) userToTixId;
        mapping(bytes32 => Ticket) tixIdToTicket;
        mapping(bytes32 => DriverEnd) tixToDriverEnd;
    }

    function _storageTicket() internal pure returns (StorageTicket storage s) {
        bytes32 position = STORAGE_POSITION_TICKET;
        assembly {
            s.slot := position
        }
    }

    function _requireNotActive() internal view {
        require(
            _storageTicket().userToTixId[msg.sender] == 0,
            "caller is active"
        );
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
        delete s1.userToTixId[_passenger];
        delete s1.userToTixId[_driver];

        emit TicketCleared(msg.sender, _tixId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideHolding {
    event TokensDeposited(address indexed sender, uint256 amount);

    function depositTokens(bytes32 _key, uint256 _amount) external;

    event TokensRemoved(address indexed sender, uint256 amount);

    function withdrawTokens(bytes32 _key, uint256 _amount) external;

    function getHolding(address _user, bytes32 _key)
        external
        view
        returns (uint256);

    event CurrencyTransferred(
        address indexed decrease,
        bytes32 indexed tixId,
        address increase,
        bytes32 key,
        uint256 amount
    );
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

    function _setContractOwner(address _newOwner) internal {
        StorageOwnership storage s1 = _storageOwnership();
        address previousOwner = s1.contractOwner;
        s1.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address) {
        return _storageOwnership().contractOwner;
    }

    function _requireIsContractOwner() internal view {
        require(
            msg.sender == _storageOwnership().contractOwner,
            "not contract owner"
        );
    }
}