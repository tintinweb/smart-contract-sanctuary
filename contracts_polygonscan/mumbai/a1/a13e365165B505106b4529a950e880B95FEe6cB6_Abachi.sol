// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IERC20.sol";

interface IABI is IERC20 {
  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}
import "./ERC20Permit.sol";

import "./AbachiAccessControlled.sol";

contract Abachi is ERC20Permit, IABI, AbachiAccessControlled {
  using SafeMath for uint256;

    constructor(address _authority)
    ERC20("Abachi", "ABI", 9)
    ERC20Permit("Abachi")
    AbachiAccessControlled(IAbachiAuthority(_authority)) {}

    function mint(address account_, uint256 amount_) external override onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(amount_, "ERC20: burn amount exceeds allowance");

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}