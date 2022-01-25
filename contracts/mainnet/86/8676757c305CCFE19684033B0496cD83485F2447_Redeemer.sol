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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/chainlink/IAggregatorV3.sol";
import "./interfaces/IVUSD.sol";
import "./interfaces/ITreasury.sol";

/// @title VUSD Redeemer, User can redeem their VUSD with any supported tokens
contract Redeemer is Context, ReentrancyGuard {
    string public constant NAME = "VUSD-Redeemer";
    string public constant VERSION = "1.3.0";

    IVUSD public immutable vusd;

    uint256 public redeemFee = 30; // Default 0.3% fee
    uint256 public constant MAX_REDEEM_FEE = 10_000; // 10_000 = 100%

    event UpdatedRedeemFee(uint256 previousRedeemFee, uint256 newRedeemFee);

    constructor(address _vusd) {
        require(_vusd != address(0), "vusd-address-is-zero");
        vusd = IVUSD(_vusd);
    }

    modifier onlyGovernor() {
        require(_msgSender() == governor(), "caller-is-not-the-governor");
        _;
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /// @notice Update redeem fee
    function updateRedeemFee(uint256 _newRedeemFee) external onlyGovernor {
        require(_newRedeemFee <= MAX_REDEEM_FEE, "redeem-fee-limit-reached");
        require(redeemFee != _newRedeemFee, "same-redeem-fee");
        emit UpdatedRedeemFee(redeemFee, _newRedeemFee);
        redeemFee = _newRedeemFee;
    }

    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Redeem token and burn VUSD amount less redeem fee, if any.
     * @param _token Token to redeem, it should be 1 of the supported tokens from treasury.
     * @param _vusdAmount VUSD amount to burn
     */
    function redeem(address _token, uint256 _vusdAmount) external nonReentrant {
        _redeem(_token, _vusdAmount, _msgSender());
    }

    /**
     * @notice Redeem token and burn VUSD amount less redeem fee, if any.
     * @param _token Token to redeem, it should be 1 of the supported tokens from treasury.
     * @param _vusdAmount VUSD amount to burn. VUSD will be burnt from caller
     * @param _tokenReceiver Address of token receiver
     */
    function redeem(
        address _token,
        uint256 _vusdAmount,
        address _tokenReceiver
    ) external nonReentrant {
        _redeem(_token, _vusdAmount, _tokenReceiver);
    }

    /**
     * @notice Current redeemable amount for given token and vusdAmount.
     * If token is not supported by treasury it will return 0.
     * If vusdAmount is higher than current total redeemable of token it will return 0.
     * @param _token Token to redeem
     * @param _vusdAmount VUSD amount to burn
     */
    function redeemable(address _token, uint256 _vusdAmount) external view returns (uint256) {
        ITreasury _treasury = ITreasury(treasury());
        if (_treasury.isWhitelistedToken(_token)) {
            uint256 _redeemable = _calculateRedeemable(_token, _vusdAmount);
            return _redeemable > redeemable(_token) ? 0 : _redeemable;
        }
        return 0;
    }

    /// @dev Current redeemable amount for given token
    function redeemable(address _token) public view returns (uint256) {
        return ITreasury(treasury()).withdrawable(_token);
    }

    /// @dev Governor is defined in VUSD token contract only
    function governor() public view returns (address) {
        return vusd.governor();
    }

    /// @dev Treasury is defined in VUSD token contract only
    function treasury() public view returns (address) {
        return vusd.treasury();
    }

    function _redeem(
        address _token,
        uint256 _vusdAmount,
        address _tokenReceiver
    ) internal {
        // In case of redeemFee, We will burn vusdAmount from user and withdraw (vusdAmount - fee) from treasury.
        uint256 _redeemable = _calculateRedeemable(_token, _vusdAmount);
        // Burn vusdAmount
        vusd.burnFrom(_msgSender(), _vusdAmount);
        // Withdraw _redeemable
        ITreasury(treasury()).withdraw(_token, _redeemable, _tokenReceiver);
    }

    /**
     * @notice Calculate redeemable amount based on oracle price and redeemFee, if any.
     * Also covert 18 decimal VUSD amount to _token defined decimal amount.
     * @return Token amount that user will get after burning vusdAmount
     */
    function _calculateRedeemable(address _token, uint256 _vusdAmount) internal view returns (uint256) {
        IAggregatorV3 _oracle = IAggregatorV3(ITreasury(treasury()).oracles(_token));
        (, int256 _price, , , ) = IAggregatorV3(_oracle).latestRoundData();
        uint256 _redeemable = (_vusdAmount * uint256(_price)) / (10**IAggregatorV3(_oracle).decimals());
        if (redeemFee != 0) {
            _redeemable -= (_redeemable * redeemFee) / MAX_REDEEM_FEE;
        }
        // convert redeemable to _token defined decimal
        return _redeemable / 10**(18 - IERC20Metadata(_token).decimals());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface ITreasury {
    function withdraw(address _token, uint256 _amount) external;

    function withdraw(
        address _token,
        uint256 _amount,
        address _tokenReceiver
    ) external;

    function isWhitelistedToken(address _address) external view returns (bool);

    function oracles(address _token) external view returns (address);

    function withdrawable(address _token) external view returns (uint256);

    function whitelistedTokens() external view returns (address[] memory);

    function vusd() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVUSD is IERC20, IERC20Permit {
    function burnFrom(address _user, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool);

    function updateMinter(address _newMinter) external;

    function updateTreasury(address _newTreasury) external;

    function governor() external view returns (address _governor);

    function minter() external view returns (address _minter);

    function treasury() external view returns (address _treasury);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}