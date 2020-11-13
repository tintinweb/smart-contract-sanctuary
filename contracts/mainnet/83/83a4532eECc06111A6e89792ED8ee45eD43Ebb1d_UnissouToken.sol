// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './ERC20.sol';
import './Roleplay.sol';
import './Pauseable.sol';
import './Minteable.sol';
import './Burneable.sol';

/// @title UnissouToken
///
/// @notice This contract covers everything related
/// to the Unissou ERC20
///
/// @dev Inehrit {ERC20}, {Roleplay}, {Pauseable},
/// {Minteable} and {Burneable}
///
abstract contract UnissouToken is 
ERC20, Roleplay, Pauseable, Minteable, Burneable {

  /// @notice Original contract's deployer are granted
  /// with Owner role and Manager role and the initial
  /// supply are minted onto his wallet.
  ///
  /// @dev See {ERC20}
  ///
  constructor()
  public ERC20(
    "Unissou",
    "YTG",
    384400 * (10**8),
    96100 * (10**8)
  ) {
    _setupRole(ROLE_OWNER, msg.sender);
    _setupRole(ROLE_MANAGER, msg.sender);
    _mint(msg.sender, initialSupply());
  }
  
  /// @notice This function allows to transfer tokens to multiple
  /// addresses in only one transaction, that help to reduce fees.
  /// The amount cannot be dynamic and is constant for all transfer
  ///
  /// @param _receivers - Represent an array of address
  /// @param _amount - Represent the amount of token to transfer
  ///
  function transferBatch(
    address[] memory _receivers,
    uint256 _amount
  ) public virtual {
    uint256 i = 0;
    uint256 len = _receivers.length;

    require(
      balanceOf(msg.sender) >= ((_amount * len) * (10**8)),
      "UT:470"
    );

    while (i < len) {
      transfer(_receivers[i], _amount);
      i++;
    }
  } 

  /// @notice This function allows the sender to mint
  /// an {_amount} of token unless the {_amount}
  /// exceed the total supply cap
  ///
  /// @dev Once the minting is down, minting is disabled
  ///
  /// Requirements:
  /// See {Minteable::isMinteable()}
  ///
  /// @param _amount - Represent the amount of token
  /// to be minted
  ///
  function mint(
    uint256 _amount
  ) public virtual isMinteable(
    _amount,
    hasRole(ROLE_MINTER, msg.sender)
  ) {
    _mint(msg.sender, (_amount * (10**8)));
    _disableMinting();
  }

  /// @notice This function allows the sender to mint
  /// an {_amount} of token directly onto the address {_to}
  /// unless the {_amount} exceed the total supply cap
  ///
  /// @dev Once the minting is down, minting is disabled
  ///
  /// Requirements:
  /// See {Minteable::isMinteable()}
  ///
  /// @param _to - Represent the token's receiver
  /// @param _amount - Represent the amount of token
  /// to be minted
  ///
  function mintTo(
    address _to,
    uint256 _amount
  ) public virtual isMinteable(
    _amount,
    hasRole(ROLE_MINTER, msg.sender)
  ) {
    _mint(_to, (_amount * (10**8)));
    _disableMinting();
  }

  /// @notice This function allows the sender to burn
  /// an {_amount} of token
  ///
  /// @dev Once the burning is down, burning is disabled
  ///
  /// Requirements:
  /// See {Burneable::isBurneable()}
  ///
  /// @param _amount - Represent the amount of token
  /// to be burned
  ///
  function burn(
    uint256 _amount
  ) public virtual isBurneable(
    _amount,
    hasRole(ROLE_BURNER, msg.sender)
  ) {
    _burn(msg.sender, (_amount * (10**8)));
    _disableBurning();
  }

  /// @notice This function allows the sender to burn
  /// an {_amount} of token directly from the address {_from}
  /// only if the token allowance is superior or equal
  /// to the requested {_amount}
  ///
  /// @dev Once the burning is down, burning is disabled
  ///
  /// Requirements:
  /// See {Burneable::isBurneable()}
  ///
  /// @param _from - Represent the token's receiver
  /// @param _amount - Represent the amount of token
  /// to be burned
  ///
  function burnFrom(
    address _from,
    uint256 _amount
  ) public virtual isBurneable(
    _amount,
    hasRole(ROLE_BURNER, msg.sender)
  ) {
    uint256 decreasedAllowance = allowance(_from, msg.sender).sub((_amount * (10**8)));
    _approve(_from, msg.sender, decreasedAllowance);
    _burn(_from, (_amount * (10**8)));
    _disableBurning();
  }

  /// @notice This function does verification before
  /// any token transfer. The actual verification are:
  /// - If the total supply don't exceed the total
  /// supply cap (for example, when token are minted),
  /// - If the token's transfer are not paused
  ///
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    if (from == address(0)) {
      require(
        totalSupply().add(amount) <= totalSupplyCap(),
        "UT:20"
      );
    }

    require(
      !paused(),
      "UT:400"
    );
  }
}