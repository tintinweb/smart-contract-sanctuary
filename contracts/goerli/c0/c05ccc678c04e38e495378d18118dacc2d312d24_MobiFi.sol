//SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./ERC20.sol";

contract MobiFi is ERC20("MobiFi", "MoFi"), Ownable {
    mapping(address => bool) public Minter;
    uint256 constant MaxSupply = 150e24;

    constructor(address _masterAddress, uint256 _preMintAmount) public {
        _mint(_masterAddress, _preMintAmount);
    }

    function AddMinter(address _minter) public onlyOwner {
        Minter[_minter] = true;
    }

    function RemoveMinter(address _minter) public onlyOwner {
        Minter[_minter] = false;
    }

    modifier onlyMinter {
        require(Minter[msg.sender]);
        _;
    }

    function mint(address account, uint256 amount) public onlyMinter {
        uint256 TotalSupply = totalSupply();
        if (TotalSupply.add(amount) > MaxSupply) {
            _mint(account, MaxSupply.sub(TotalSupply));
        } else {
            _mint(account, amount);
        }
    }

    function burn(address account, uint256 amount) public onlyMinter {
        _burn(account, amount);
    }
}