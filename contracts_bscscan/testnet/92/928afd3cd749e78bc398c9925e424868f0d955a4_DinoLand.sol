// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import './TokenTimelock.sol';
import "./ERC20.sol";

contract DinoLand is ERC20, Ownable {
    uint256 private _maxTotalSupply;
    
    constructor() ERC20("Dino Land Token", "DNL") {
        _maxTotalSupply = 100e24;
        
        // init timelock factory
        TimelockFactory timelockFactory = new TimelockFactory();

        // ERC20
        
        //Play2earn: Battle: 25% (Battle PVP farming) 
        mint(0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, 25e24);
        // Foundation: 15% - lock 10 months - unlock 10% per month
        address foudationERC20Lock = timelockFactory.createTimelock(this, 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, block.timestamp + 30 days, 15e23, 30 days);
        mint(foudationERC20Lock, 15e24);
        // Presale
        mint(0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, 15e24);
        // Marketing: 15% (lock 3 months)
        address marketingERC20Lock = timelockFactory.createTimelock(this, 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, block.timestamp, 15e24, 90 days);
        mint(marketingERC20Lock, 15e24);
        // Liquidity pool: 20%
        mint(0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, 20e24);
        // Developer and advisor: 10 % (Locked  9 months)
        address teamERC20Lock = timelockFactory.createTimelock(this, 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615, block.timestamp, 10e24, 270 days);
        mint(teamERC20Lock, 10e24);
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply() + amount <= _maxTotalSupply, "DinosCrypto Token: mint more than the max total supply");
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}