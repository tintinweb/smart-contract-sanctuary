pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract WrappedPolis is ERC20("WrappedPolis", "WPOLIS"), Ownable {
    event Burned(address indexed burner, uint256 burnAmount);
    event Minted(
        address indexed minter,
        address indexed receiver,
        uint256 mintAmount
    );

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        emit Minted(owner(), _to, _amount);
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }
}
