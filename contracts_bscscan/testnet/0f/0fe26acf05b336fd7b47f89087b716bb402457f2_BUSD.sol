// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BUSD is ERC20 {
    address public admin;
    address public receiver;
    address public minter;
    address public burner;


    constructor(address _minter, address _burner, address _receiver,uint _amount) ERC20("BUSD","BUSD") {
        admin = msg.sender;
        minter = _minter;
        burner = _burner;
        receiver = _receiver;

        _mint(receiver, _amount);
    }

    modifier onlyMinter {
        require(msg.sender == minter, "User must be Minter to call this function");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "User must be Admin to call this function");
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