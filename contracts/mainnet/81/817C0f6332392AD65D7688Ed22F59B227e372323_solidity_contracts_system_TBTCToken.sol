pragma solidity 0.5.17;

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {ERC20Detailed} from "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import {VendingMachineAuthority} from "./VendingMachineAuthority.sol";
import {ITokenRecipient} from "../interfaces/ITokenRecipient.sol";

/// @title  TBTC Token.
/// @notice This is the TBTC ERC20 contract.
/// @dev    Tokens can only be minted by the `VendingMachine` contract.
contract TBTCToken is ERC20Detailed, ERC20, VendingMachineAuthority {
    /// @dev Constructor, calls ERC20Detailed constructor to set Token info
    ///      ERC20Detailed(TokenName, TokenSymbol, NumberOfDecimals)
    constructor(address _VendingMachine)
        ERC20Detailed("tBTC", "TBTC", 18)
        VendingMachineAuthority(_VendingMachine)
    public {
        // solium-disable-previous-line no-empty-blocks
    }

    /// @dev             Mints an amount of the token and assigns it to an account.
    ///                  Uses the internal _mint function.
    /// @param _account  The account that will receive the created tokens.
    /// @param _amount   The amount of tokens that will be created.
    function mint(address _account, uint256 _amount) external onlyVendingMachine returns (bool) {
        // NOTE: this is a public function with unchecked minting. Only the
        // vending machine is allowed to call it, and it is in charge of
        // ensuring minting is permitted.
        _mint(_account, _amount);
        return true;
    }

    /// @dev             Burns an amount of the token from the given account's balance.
    ///                  deducting from the sender's allowance for said account.
    ///                  Uses the internal _burn function.
    /// @param _account  The account whose tokens will be burnt.
    /// @param _amount   The amount of tokens that will be burnt.
    function burnFrom(address _account, uint256 _amount) external {
        _burnFrom(_account, _amount);
    }

    /// @dev Destroys `amount` tokens from `msg.sender`, reducing the
    /// total supply.
    /// @param _amount   The amount of tokens that will be burnt.
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    /// @notice           Set allowance for other address and notify.
    ///                   Allows `_spender` to spend no more than `_value`
    ///                   tokens on your behalf and then ping the contract about
    ///                   it.
    /// @dev              The `_spender` should implement the `ITokenRecipient`
    ///                   interface to receive approval notifications.
    /// @param _spender   Address of contract authorized to spend.
    /// @param _value     The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    /// @return true if the `_spender` was successfully approved and acted on
    ///         the approval, false (or revert) otherwise.
    function approveAndCall(
        ITokenRecipient _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool) { // not external to allow bytes memory parameters
        if (approve(address(_spender), _value)) {
            _spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
        return false;
    }
}
