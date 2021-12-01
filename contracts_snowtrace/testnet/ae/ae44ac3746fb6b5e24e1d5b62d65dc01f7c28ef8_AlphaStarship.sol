// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract AlphaStarship is ERC20 {
    address public admin;
    address public minter;
    address public burner;


    constructor(address _minter, address _burner, uint amount) ERC20("Alpha STARSHIP","aSTARSHIP") {
        admin = msg.sender;
        minter = _minter;
        burner = _burner;

        _mint(msg.sender, amount);
    }

    modifier onlyMinter {
        require(msg.sender == minter, "User must be Minter to call this function");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "User must be Minter to call this function");
        _;
    }
    modifier onlyBurner {
        require(msg.sender == burner, "User must be Burner to call this function");
        _;
    }

    function mint(uint256 amount, address to) external onlyMinter {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyBurner {
        _burn(msg.sender, amount);
    }

    function setMinter(address addr) external onlyAdmin {
        minter = addr;
    }

    function setBurner(address addr) external onlyAdmin {
        burner = addr;
    }


}