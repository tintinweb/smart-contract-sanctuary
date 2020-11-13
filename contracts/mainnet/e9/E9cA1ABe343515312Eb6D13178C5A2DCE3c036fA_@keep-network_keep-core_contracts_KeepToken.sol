pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


/// @dev Interface of recipient contract for approveAndCall pattern.
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

/// @title KEEP Token
/// @dev Standard ERC20Burnable token
contract KeepToken is ERC20Burnable, ERC20Detailed {
    string public constant NAME = "KEEP Token";
    string public constant SYMBOL = "KEEP";
    uint8 public constant DECIMALS = 18; // The number of digits after the decimal place when displaying token values on-screen.
    uint256 public constant INITIAL_SUPPLY = 10**27; // 1 billion tokens, 18 decimal places.

    /// @dev Gives msg.sender all of existing tokens.
    constructor() public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// @notice Set allowance for other address and notify.
    /// Allows `_spender` to spend no more than `_value` tokens
    /// on your behalf and then ping the contract about it.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

}
