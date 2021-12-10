// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

/*
$$$$$$\ $$\      $$\ $$\      $$\ $$\   $$\ $$$$$$$$\  $$$$$$\  $$$$$$$\  $$\       $$$$$$$$\  $$$$$$\
\_$$  _|$$$\    $$$ |$$$\    $$$ |$$ |  $$ |\__$$  __|$$  __$$\ $$  __$$\ $$ |      $$  _____|$$  __$$\
  $$ |  $$$$\  $$$$ |$$$$\  $$$$ |$$ |  $$ |   $$ |   $$ /  $$ |$$ |  $$ |$$ |      $$ |      $$ /  \__|
  $$ |  $$\$$\$$ $$ |$$\$$\$$ $$ |$$ |  $$ |   $$ |   $$$$$$$$ |$$$$$$$\ |$$ |      $$$$$\    \$$$$$$\
  $$ |  $$ \$$$  $$ |$$ \$$$  $$ |$$ |  $$ |   $$ |   $$  __$$ |$$  __$$\ $$ |      $$  __|    \____$$\
  $$ |  $$ |\$  /$$ |$$ |\$  /$$ |$$ |  $$ |   $$ |   $$ |  $$ |$$ |  $$ |$$ |      $$ |      $$\   $$ |
$$$$$$\ $$ | \_/ $$ |$$ | \_/ $$ |\$$$$$$  |   $$ |   $$ |  $$ |$$$$$$$  |$$$$$$$$\ $$$$$$$$\ \$$$$$$  |
\______|\__|     \__|\__|     \__| \______/    \__|   \__|  \__|\_______/ \________|\________| \______/
$$$$$$$\   $$$$$$\ $$\     $$\  $$$$$$\  $$\    $$$$$$$$\ $$\     $$\
$$  __$$\ $$  __$$\\$$\   $$  |$$  __$$\ $$ |   \__$$  __|\$$\   $$  |
$$ |  $$ |$$ /  $$ |\$$\ $$  / $$ /  $$ |$$ |      $$ |    \$$\ $$  /
$$$$$$$  |$$ |  $$ | \$$$$  /  $$$$$$$$ |$$ |      $$ |     \$$$$  /
$$  __$$< $$ |  $$ |  \$$  /   $$  __$$ |$$ |      $$ |      \$$  /
$$ |  $$ |$$ |  $$ |   $$ |    $$ |  $$ |$$ |      $$ |       $$ |
$$ |  $$ | $$$$$$  |   $$ |    $$ |  $$ |$$$$$$$$\ $$ |       $$ |
\__|  \__| \______/    \__|    \__|  \__|\________|\__|       \__|
$$\      $$\  $$$$$$\  $$\   $$\  $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$\
$$$\    $$$ |$$  __$$\ $$$\  $$ |$$  __$$\ $$  __$$\ $$  _____|$$  __$$\
$$$$\  $$$$ |$$ /  $$ |$$$$\ $$ |$$ /  $$ |$$ /  \__|$$ |      $$ |  $$ |
$$\$$\$$ $$ |$$$$$$$$ |$$ $$\$$ |$$$$$$$$ |$$ |$$$$\ $$$$$\    $$$$$$$  |
$$ \$$$  $$ |$$  __$$ |$$ \$$$$ |$$  __$$ |$$ |\_$$ |$$  __|   $$  __$$<
$$ |\$  /$$ |$$ |  $$ |$$ |\$$$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |
$$ | \_/ $$ |$$ |  $$ |$$ | \$$ |$$ |  $$ |\$$$$$$  |$$$$$$$$\ $$ |  $$ |
\__|     \__|\__|  \__|\__|  \__|\__|  \__| \______/ \________|\__|  \__|
*/

pragma solidity ^0.8.0;

/**
 * @royaltyRecipient Gutenblock.eth
 * @title ImmutablesPageRoyaltyManager
 * @dev This contract allows to split Ether royalty payments between the
 * Immutables.co contract and an Immutables.co page royaltyRecipient.
 *
 * `ImmutablesPageRoyaltyManager` follows a _pull payment_ model. This means that payments
 * are not automatically forwarded to the accounts but kept in this contract,
 * and the actual transfer is triggered as a separate step by calling the
 * {release} function.
 *
 * The contract is written to serve as an implementation for minimal proxy clones.
 */

import "./Context.sol";
import "./Address.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";

contract ImmutablesPageRoyaltyManager is Context, Initializable, ReentrancyGuard {
    using Address for address payable;

    /// @dev Reentrancy protection.
    //bool locked = false;

    /// @dev The address of the ImmutablesPage contract.
    address public immutablesPageContract;
    /// @dev The tokenId of the associated ImmutablesPage.
    uint256 public immutablesPageTokenId;
    /// @dev The name of the associated ImmutablesPage.
    string public immutablesPage;

    /// @dev The address of the royaltyRecipient.
    address public royaltyRecipient;
    /// @dev The address of the additionalPayee set by the royaltyRecipient.
    address public additionalPayee;
    /// @dev The royaltyRecipient's percentage of the total expressed as 1/1000ths.
    ///      The royaltyRecipient can allot up to all of this to an additionalPayee.
    uint16 public royaltyRecipientPercent;
    /// @dev The royaltyRecipient's percentage, after additional payee,
    ///      of the total expressed in basis points.
    uint16 public royaltyRecipientPercentMinusAdditionalPayeePercent;
    /// @dev The royaltyRecipient's additional payee percentae of the total
    /// @dev expressed in basis points.  Valid from 0 to royaltyRecipientPercent.
    uint16 public additionalPayeePercent;

    /// EVENTS

    event PayeeAdded(address account, uint256 percent);
    event PayeeRemoved(address account, uint256 percent);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    /**
     * @dev Creates an uninitialized instance of `ImmutablesPageRoyaltyManager`.
     */
    constructor() { }

    /**
     * @dev Initialized an instance of `ImmutablesPageRoyaltyManager`
     */
    function initialize(address _immutablesPageContract,
                        uint256 _immutablesPageTokenId, string calldata _immutablesPage,
                        address _royaltyRecipient, uint16 _royaltyRecipientPercent,
                        address _additionalPayee, uint16 _additionalPayeePercent
                        ) public initializer() {
        immutablesPageContract = _immutablesPageContract;
        immutablesPageTokenId = _immutablesPageTokenId;
        immutablesPage = _immutablesPage;

        royaltyRecipient = _royaltyRecipient;
        royaltyRecipientPercent = _royaltyRecipientPercent;
        additionalPayee = _additionalPayee;
        additionalPayeePercent = _additionalPayeePercent;
        royaltyRecipientPercentMinusAdditionalPayeePercent = _royaltyRecipientPercent - _additionalPayeePercent;

        emit PayeeAdded(immutablesPageContract, 10000 - royaltyRecipientPercent);
        emit PayeeAdded(royaltyRecipient, royaltyRecipientPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeAdded(additionalPayee, additionalPayeePercent);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /** @dev Allows the current royalty recipient to set/update the royalty recipieint address.
      * @param _newRoyaltyRecipient The new royalty recipieint.
      */
    function royaltyRecipientUpdateAddress(address _newRoyaltyRecipient) public {
        // only the parent contract and the royaltyRecipient can call this function.
        // the parent contract only calls this function at the request of the royaltyRecipient.
        require(_msgSender() == immutablesPageContract || _msgSender() == royaltyRecipient, "auth");

        // update the royaltyRecipient address
        emit PayeeRemoved(royaltyRecipient, royaltyRecipientPercentMinusAdditionalPayeePercent);
        royaltyRecipient = _newRoyaltyRecipient;
        emit PayeeAdded(royaltyRecipient, royaltyRecipientPercentMinusAdditionalPayeePercent);
    }

    /** @dev Allows the current royalty recipient to update additional payee information.
      * @param _newAdditionalPayee The new additional payee.
      * @param _newPercent A new additional payee percentage in basis points.
      */

    /** @dev Allows the royaltyRecipient to update additional payee info.
      * @param _newAdditionalPayee the additional payee address.
      * @param _newPercent the basis point (1/10,000th) share for the _additionalPayee up to artistPercent (e.g., 5000 = 50.0%).
      */
    function royaltyRecipientUpdateAdditionalPayeeInfo(address _newAdditionalPayee, uint16 _newPercent) public {
        // only the parent contract and the royaltyRecipient can call this function.
        // the parent contract only calls this function at the request of the royaltyRecipient.
        require(_msgSender() == immutablesPageContract || _msgSender() == royaltyRecipient, "auth");

        // the maximum amount the royaltyRecipient can give to an additional payee is
        // the current royaltyRecipientPercent plus the current additionalPayeePercent.
        require(_newPercent <= royaltyRecipientPercent, "percent too big");

        // Before changing the additional payee information,
        // payout everyone as indicated when prior payments were made.
        release();

        // Change the additional payee and relevant percentages.
        emit PayeeRemoved(royaltyRecipient, royaltyRecipientPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeRemoved(additionalPayee, additionalPayeePercent);
        }

        additionalPayee = _newAdditionalPayee;
        additionalPayeePercent = _newPercent;
        royaltyRecipientPercentMinusAdditionalPayeePercent = royaltyRecipientPercent - _newPercent;

        emit PayeeAdded(royaltyRecipient, royaltyRecipientPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeAdded(additionalPayee, additionalPayeePercent);
        }
    }

    /**
     * @dev Triggers payout of all royalties.
     */
    function release() public virtual nonReentrant() {
        // checks
        // effects
        uint256 _startingBalance = address(this).balance;
        uint256 _royaltyRecipientAmount = _startingBalance * royaltyRecipientPercentMinusAdditionalPayeePercent / 10000;
        uint256 _additionalPayeeAmount = _startingBalance * additionalPayeePercent / 10000;
        uint256 _contractAmount = _startingBalance - _royaltyRecipientAmount - _additionalPayeeAmount;

        // interactions
        if(_startingBalance > 0) {
          payable(immutablesPageContract).sendValue(_contractAmount);
          emit PaymentReleased(immutablesPageContract, _contractAmount);

          payable(royaltyRecipient).sendValue(_royaltyRecipientAmount);
          emit PaymentReleased(royaltyRecipient, _royaltyRecipientAmount);
        }

        if(_startingBalance > 0 && additionalPayee != address(0) && additionalPayeePercent > 0) {
          payable(additionalPayee).sendValue(_additionalPayeeAmount);
          emit PaymentReleased(additionalPayee, _additionalPayeeAmount);
        }
    }
}