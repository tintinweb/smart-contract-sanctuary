// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract RPToken is ERC20 {
    address public minter;
    address public wallet;
    address public nominatedWallet;
    

    constructor(address _wallet) public ERC20("Royale Protocol", "RPT") {
           wallet=_wallet;
    }
    
    modifier onlyMinter {
        require(msg.sender==minter, "not authorized");
        _;
    }
    
    modifier onlyWallet(){
      require(wallet==msg.sender, "Not Authorized");
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
    
    function setMinter(address addr) external  onlyWallet{
        minter = addr;
        emit minterAdded(addr);
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
}