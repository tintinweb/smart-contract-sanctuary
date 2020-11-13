pragma solidity 0.6.7;

import "../lib/erc20.sol";
import "../lib/ownable.sol";

// PickleToken with Governance.
contract PickleToken is ERC20("PickleToken", "PICKLE"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
