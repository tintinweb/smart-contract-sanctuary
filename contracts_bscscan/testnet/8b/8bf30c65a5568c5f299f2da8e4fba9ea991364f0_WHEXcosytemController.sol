// SPDX-License-Identifier: Unlicensed

/*

  _____           _            __   _   _          
 |  __ \         | |          / _| | | | |         
 | |__) |_ _ _ __| |_    ___ | |_  | |_| |__   ___ 
 |  ___/ _` | '__| __|  / _ \|  _| | __| '_ \ / _ \
 | |  | (_| | |  | |_  | (_) | |   | |_| | | |  __/
 |_|   \__,_|_|   \__|  \___/|_|    \__|_| |_|\___|

 __          ___    _ ________   __                       _                 
 \ \        / / |  | |  ____\ \ / /                      | |                
  \ \  /\  / /| |__| | |__   \ V / ___ ___  ___ _   _ ___| |_ ___ _ __ ___  
   \ \/  \/ / |  __  |  __|   > < / __/ _ \/ __| | | / __| __/ _ \ '_ ` _ \ 
    \  /\  /  | |  | | |____ / . \ (_| (_) \__ \ |_| \__ \ ||  __/ | | | | |
     \/  \/   |_|  |_|______/_/ \_\___\___/|___/\__, |___/\__\___|_| |_| |_|
                                                 __/ |                      
                                                |___/                       

*/

pragma solidity ^0.8.4;

// Third-party library imports.
import './Address.sol';
import './Context.sol';
import './Ownable.sol';
import './SafeERC20.sol';
import './SafeMath.sol';

// Local imports.
import './WHEXcosystemToken.sol';
import './WHEXcosystemTimelock.sol';


contract WHEXcosytemController is Context, Ownable
{
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    address private constant PCSv2_mainnet = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant PCSv2_testnet = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    uint256 private constant _decimals        = 9;
    address private constant _autolp_address  = PCSv2_testnet;
    address private constant _charity_address = 0xdc0f0c4A2294266b9850265297632eC6503703C9;
    address private constant _original_owner  = 0xdc0f0c4A2294266b9850265297632eC6503703C9;
    
    bool public SLEX_is_deployed     = false;
    bool public CDEX_is_deployed     = false;
    bool public ANEX_is_deployed     = false;
    bool public KREX_is_deployed     = false;
    bool public CRYPTO_is_deployed   = false;
    bool public TIMELOCK_is_deployed = false;
    
    address[] private _tax_exempt;
    
    WHEXcosystemToken public SLEX;
    WHEXcosystemToken public CDEX;
    WHEXcosystemToken public ANEX;
    WHEXcosystemToken public KREX;
    WHEXcosystemToken public CRYPTO;
    
    WHEXcosystemTimelock public TIMELOCK;
    
    constructor()
    {
        _owner = _original_owner;
        
        _tax_exempt.push(_owner);
        _tax_exempt.push(_charity_address);
        _tax_exempt.push(0x6F1a82362c94Adf7beC36590540cd6B87FA8C1Fa);
        _tax_exempt.push(0xEa5fB420F3B593cEa7BB5289C88f3163F9Bd99E3);
        _tax_exempt.push(0xc42d122C8EF2562873804Ab0dC6CE3Cba5283523);
        _tax_exempt.push(0x220ab255A080236085bA210a006848b02a34b2F6);
    }
    
    function deploy_SLEX() public onlyOwner
    {
        require(!SLEX_is_deployed, "WHEXcosytemController: SLEX is already deployed");
        
        SLEX = new WHEXcosystemToken(
            "Seal Exploder",
            "SLEX",
            _decimals,
            500000000000000000000000000000,
            8,  // Reflection tax rate.
            8,  // Auto-LP tax rate.
            8,  // Charity tax rate.
            _autolp_address,
            _charity_address,
            _owner,
            _tax_exempt
        );
        
        SLEX_is_deployed = true;
    }
    
    function deploy_CDEX() public onlyOwner
    {
        require(!CDEX_is_deployed, "WHEXcosytemController: CDEX is already deployed");
        
        CDEX = new WHEXcosystemToken(
            "Cod Exploder",
            "CDEX",
            _decimals,
            250000000000000000000000000000,
            4,  // Reflection tax rate.
            4,  // Auto-LP tax rate.
            4,  // Charity tax rate.
            _autolp_address,
            _charity_address,
            _owner,
            _tax_exempt
        );
        
        CDEX_is_deployed = true;
    }
    
    function deploy_ANEX() public onlyOwner
    {
        require(!ANEX_is_deployed, "WHEXcosytemController: ANEX is already deployed");
        
        ANEX = new WHEXcosystemToken(
            "Anchovy Exploder",
            "ANEX",
            _decimals,
            125000000000000000000000000000,
            2,  // Reflection tax rate.
            2,  // Auto-LP tax rate.
            2,  // Charity tax rate.
            _autolp_address,
            _charity_address,
            _owner,
            _tax_exempt
        );
        
        ANEX_is_deployed = true;
    }
    
    function deploy_KREX() public onlyOwner
    {
        require(!KREX_is_deployed, "WHEXcosytemController: KREX is already deployed");
        
        KREX = new WHEXcosystemToken(
            "Krill Exploder",
            "KREX",
            _decimals,
            62500000000000000000000000000,
            1,  // Reflection tax rate.
            1,  // Auto-LP tax rate.
            1,  // Charity tax rate.
            _autolp_address,
            _charity_address,
            _owner,
            _tax_exempt
        );
        
        KREX_is_deployed = true;
    }
    
    function deploy_CRYPTO() public onlyOwner
    {
        require(!CRYPTO_is_deployed, "WHEXcosytemController: CRYPTO is already deployed");
        
        CRYPTO = new WHEXcosystemToken(
            "Cryptophyte",
            "CRYPTO",
            _decimals,
            31250000000000000000000000000,
            0,  // Reflection tax rate.
            0,  // Auto-LP tax rate.
            0,  // Charity tax rate.
            _autolp_address,
            _charity_address,
            _owner,
            _tax_exempt
        );
        
        CRYPTO_is_deployed = true;
    }
    
    function deploy_TIMELOCK() public onlyOwner
    {
        require(!TIMELOCK_is_deployed, "WHEXcosytemController: TIMELOCK is already deployed");
        
        TIMELOCK = new WHEXcosystemTimelock(
            _owner,
            block.timestamp + 1200
        );
        
        TIMELOCK_is_deployed = true;
    }
    
    function change_owners_on_all(address account) public onlyOwner
    {
        // Transfers token contract ownerships.
        SLEX.transferOwnership(account);
        CDEX.transferOwnership(account);
        ANEX.transferOwnership(account);
        KREX.transferOwnership(account);
        CRYPTO.transferOwnership(account);
        
        // Transfers timelock contract ownership and beneficiary.
        TIMELOCK.transferOwnership(account);
        
        // Transfers controller ownership.
        transferOwnership(account);
    }
    
    function recover_tokens(address token_address) public onlyOwner
    {
        // Releases a random token sent to this contract to the contract owner.
        IERC20 token = IERC20(token_address);

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "WHEXcosystemController: token balance is zero");

        token.safeTransfer(owner(), amount);
    }
}