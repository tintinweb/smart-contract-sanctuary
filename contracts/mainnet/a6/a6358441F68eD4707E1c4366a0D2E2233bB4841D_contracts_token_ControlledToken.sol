// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

import "../utils/RelayRecipient.sol";
import "./TokenControllerInterface.sol";

/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
contract ControlledToken is RelayRecipient, ERC20UpgradeSafe {

  /// @notice Interface to the contract responsible for controlling mint/burn
  TokenControllerInterface public controller;

  /// @notice Initializes the Controlled Token with Token Details and the Controller
  /// @param _name The name of the Token
  /// @param _symbol The symbol for the Token
  /// @param _decimals The number of decimals for the Token
  /// @param _trustedForwarder Address of the Forwarding Contract for GSN Meta-Txs
  /// @param _controller Address of the Controller contract for minting & burning
  function initialize(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _trustedForwarder,
    TokenControllerInterface _controller
  )
    public
    virtual
    initializer
  {
    trustedForwarder = _trustedForwarder;
    __ERC20_init(_name, _symbol);
    controller = _controller;
    _setupDecimals(_decimals);
  }

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount) external virtual onlyController {
    _mint(_user, _amount);
  }

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external virtual onlyController {
    _burn(_user, _amount);
  }

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _operator Address of the operator performing the burn action via the controller contract
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external virtual onlyController {
    if (_operator != _user) {
      uint256 decreasedAllowance = allowance(_user, _operator).sub(_amount, "ControlledToken/exceeds-allowance");
      _approve(_user, _operator, decreasedAllowance);
    }
    _burn(_user, _amount);
  }

  /// @dev Function modifier to ensure that the caller is the controller contract
  modifier onlyController {
    require(_msgSender() == address(controller), "ControlledToken/only-controller");
    _;
  }

  /// @dev Controller hook to provide notifications & rule validations on token transfers to the controller.
  /// This includes minting and burning.
  /// May be overridden to provide more granular control over operator-burning
  /// @param from Address of the account sending the tokens (address(0x0) on minting)
  /// @param to Address of the account receiving the tokens (address(0x0) on burning)
  /// @param amount Amount of tokens being transferred
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    controller.beforeTokenTransfer(from, to, amount);
  }

  /// @dev Provides information about the current execution context for GSN Meta-Txs.
  /// @return The payable address of the message sender
  function _msgSender()
    internal
    override(BaseRelayRecipient, ContextUpgradeSafe)
    virtual
    view
    returns (address payable)
  {
    return BaseRelayRecipient._msgSender();
  }

  /// @dev Provides information about the current execution context for GSN Meta-Txs.
  /// @return The payable address of the message sender
  function _msgData()
    internal
    override(BaseRelayRecipient, ContextUpgradeSafe)
    virtual
    view
    returns (bytes memory)
  {
    return BaseRelayRecipient._msgData();
  }
}
