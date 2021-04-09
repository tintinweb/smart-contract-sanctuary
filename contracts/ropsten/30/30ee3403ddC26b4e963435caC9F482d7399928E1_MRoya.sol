// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC20.sol";
contract MRoya is ERC20 {

    address public wallet;
    address public nominatedWallet;
    mapping(address => bool) public minter;

    constructor(address _wallet) public ERC20("mRoya Token", "mRoya") {
        wallet = _wallet;
    }


    modifier onlyWallet {
        require(msg.sender == wallet, "not authorized");
        _;
    }

    modifier onlyMinter {
        require(minter[msg.sender] == true, "not authorized");
        _;
    }

    function nominateNewOwner(address _wallet) external onlyWallet {
        nominatedWallet = _wallet;
        emit walletNominated(_wallet);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedWallet, "You must be nominated before you can accept ownership");
        emit walletChanged(wallet, nominatedWallet);
        wallet = nominatedWallet;
        nominatedWallet = address(0);
    }

    function addMinter(address addr) external onlyWallet returns(bool) {
        minter[addr] = true;
        emit minterAdded(addr);
        return true;
    }

    function removeMinter(address addr) external onlyWallet returns(bool) {
        minter[addr] = false;
        emit minterRemoved(addr);
        return true;
    }

    function mint(address recipient, uint256 amount) external onlyMinter {
        _mint(recipient, amount);
    }

    function burn(address sender, uint256 amount) external onlyMinter {
        _burn(sender, amount);
    }

    event walletNominated(address newOwner);
    event walletChanged(address oldOwner, address newOwner);
    event minterAdded(address minter);
    event minterRemoved(address minter);
}