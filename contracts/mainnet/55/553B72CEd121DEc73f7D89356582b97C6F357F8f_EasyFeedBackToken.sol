// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract EasyFeedBackToken is ERC20Capped, Ownable {
    constructor ()
    ERC20("EasyFeedBack", "EASYF")
    ERC20Capped(179141000000 * 1 ether)
    public {
        // Mint 1% of total supply
        mint(msg.sender, (1791410000 * 1 ether));
    }

    event Burned(address indexed burner, uint256 burnAmount);

    event Minted(
        address indexed minter,
        address indexed receiver,
        uint256 mintAmount
    );

    function mint(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0, "ERC20: Cannot mint 0 tokens");
        _mint(_to, _amount);
        emit Minted(owner(), _to, _amount);
    }

    function burn(uint256 _amount) public {
        require(_amount > 0, "ERC20: Cannot burn 0 tokens");
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }
}