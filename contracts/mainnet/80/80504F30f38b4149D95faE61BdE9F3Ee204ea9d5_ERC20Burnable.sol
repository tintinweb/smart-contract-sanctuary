pragma solidity 0.6.5;

import "./ERC20.sol";
import "./Pausable.sol";

abstract contract ERC20Burnable is ERC20, Pausable {
    event Burn(address indexed burned, uint256 amount);

    function burn(uint256 amount)
        external
        whenNotPaused
        returns (bool success)
    {
        success = _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
        success = true;
    }

    function burnFrom(address burned, uint256 amount)
        external
        whenNotPaused
        returns (bool success)
    {
        _burn(burned, amount);
        emit Burn(burned, amount);
        success = _approve(
            burned,
            msg.sender,
            _allowances[burned][msg.sender].sub(
                amount,
                "ERC20Burnable/burnFrom : Cannot burn more than allowance"
            )
        );
    }
}
