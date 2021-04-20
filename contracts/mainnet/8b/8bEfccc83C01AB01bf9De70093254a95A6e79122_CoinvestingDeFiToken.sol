// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract CoinvestingDeFiToken is Ownable, ERC20 {
    // Public variables
    address public saleReserve;
    address public technicalAndOperationalReserve;

    // Events
    event Received(address, uint);
    
    // Constructor
    constructor (
        string memory name,
        string memory symbol,
        uint _initialSupply,
        address _saleReserve,
        address _technicalAndOperationalReserve          
    ) payable ERC20 (name, symbol) {
        saleReserve = _saleReserve;
        technicalAndOperationalReserve = _technicalAndOperationalReserve;
        if (_initialSupply > 0) {
            require((_initialSupply % 10) == 0, "_initialSupply has to be a multiple of 10!");
            uint eightyFivePerCent = _initialSupply * 85 / 100;
            uint fifteenPerCent = _initialSupply * 15 / 100; 
            mint(saleReserve, fifteenPerCent); 
            mint(technicalAndOperationalReserve, eightyFivePerCent);       
            mintingFinished = true;
        }
    }

    // Receive function 
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // External functions
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Insuficient funds!");
        uint amount = address(this).balance;
        // sending to prevent re-entrancy attacks
        address(this).balance - amount;
        payable(msg.sender).transfer(amount);
    }
    
    // Public functions
    function mint(address account, uint amount) public onlyOwner canMint {
        _mint(account, amount);
    }
}