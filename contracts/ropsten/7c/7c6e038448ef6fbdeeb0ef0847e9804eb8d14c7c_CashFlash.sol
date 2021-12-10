// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract CashFlash is ERC20, AccessControl, ERC20Burnable, Pausable {
    using SafeMath for uint256;

    uint256 internal  _maxAmountMintable = 10000000000e18;


    constructor() ERC20("CashFlash", "CFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdminRole() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "!admin"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyAdminRole {
        require(msg.sender != newOwner, "!same address");
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint256 _amount) public onlyAdminRole whenNotPaused {
        require(ERC20.totalSupply().add(_amount) <= _maxAmountMintable, "Max mintable exceeded");
        super._mint(_to, _amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    function pause() external onlyAdminRole {
        super._pause();
    }

    function unpause() external onlyAdminRole {
        super._unpause();
    }
}