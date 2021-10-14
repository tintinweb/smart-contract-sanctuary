// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import './TokenTimelock.sol';
import "./ERC20.sol";

contract DinoLandToken is ERC20, Ownable {
    uint256 private _maxTotalSupply;
    address public constant SEED_ADDRESS  = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant PRIVATE_SALE_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant IDO_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant LIQUIDITY_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant GAME_INCENTIVES_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant FARMING_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant MARKETING_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant AIRDROP_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant TEAM_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    address public constant ADVISOR_ADDRESS = 0xb40eA1DA6A55bDf2b5BFbd054cC7dDB53F8ac615;
    
    constructor() ERC20("Dino Land Token", "DNL") {
        _maxTotalSupply = 500e24;
        // init timelock factory
        TimelockFactory timelockFactory = new TimelockFactory();

        //Seed: 2% - 10e24 15% at listing, unlock in month 3, linear released in 12 months
        //Total: 10,000,000 : 1,500,00 at listing, locked 8,500,000
        mint(SEED_ADDRESS, 15e23);
        address seedERC20Lock = timelockFactory.createTimelock(this, SEED_ADDRESS, block.timestamp + 90 days, 7e23, 30 days);
        mint(seedERC20Lock, 85e23);
        
        //Private: 10% - 15% at listing, unlock in month 3, linear released in 12 months
        //Total: 50,000,000: 7,500,000 at listing, locked 42,500,000
        mint(PRIVATE_SALE_ADDRESS, 75e23);
        address privateERC20Lock = timelockFactory.createTimelock(this, PRIVATE_SALE_ADDRESS, block.timestamp + 90 days, 354e22, 30 days);
        mint(privateERC20Lock, 425e23);
        
        //IDO: 10% -  No Lock
        //Total: 50,000,000 
        mint(IDO_ADDRESS, 50e24);
        
        //Liquidity:5% -  15% at listing, unlock in month 3, linear released in 12 months
        //Total: 25,000,000 - 3,750,000 at listing, locked 21,250,000 
        mint(LIQUIDITY_ADDRESS, 375e22);
        address liquiidtyERC20Lock = timelockFactory.createTimelock(this, LIQUIDITY_ADDRESS, block.timestamp + 90 days, 177e22, 30 days);
        mint(liquiidtyERC20Lock, 2125e22);
        //Game incentives: 30%
        //Total: 150,000,000
        mint(GAME_INCENTIVES_ADDRESS, 150e24);
        
        //Farming: 19%
        //Total: 95,000,000
        mint(FARMING_ADDRESS, 95e24);
        
        //Marketing: 10%
        //Total: 50,000,000
        mint(MARKETING_ADDRESS, 50e24);
        
        //Airdrop: 1%
        //Total: 5,000,000
        mint(AIRDROP_ADDRESS, 5e24);
        
        //Team: 10% - Unlock in month 6, linear released in 12 months
        //Total: 50,000,000 - all locked
        address teamERC20Lock = timelockFactory.createTimelock(this, TEAM_ADDRESS, block.timestamp + 180 days, 4e24, 30 days);
        mint(teamERC20Lock, 50e24);
        
        //Advisor: 3% - 16% at listing, unlock in month 6, linear released in 12 months  
        // Total: 15,000,000 - 2,400,000 at listing, locked 12,600,000
        mint(ADVISOR_ADDRESS, 24e23);
        address advisorERC20Lock = timelockFactory.createTimelock(this, ADVISOR_ADDRESS, block.timestamp + 180 days, 105e22, 30 days);
        mint(advisorERC20Lock, 126e23);
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply() + amount <= _maxTotalSupply, "Mint more than the max total supply");
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
}