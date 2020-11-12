
pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";

// PEPEToken with Governance.
contract PEPEToken is ERC20("PEPEFinance", "PEPE"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (PEPEFrog).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
