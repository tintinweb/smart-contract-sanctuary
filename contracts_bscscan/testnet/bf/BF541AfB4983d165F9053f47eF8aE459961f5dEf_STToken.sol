pragma solidity 0.5.8;

import "./Ownable.sol";
import "./TRC20.sol";

contract STToken is TRC20("ST", "ST"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (master).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function setMaxSupply(uint256 _max_supply) public onlyOwner {
        MAX_SUPPLY = _max_supply;
    }
}