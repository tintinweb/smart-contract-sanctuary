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


contract WHEXcosystemTimelock is Context, Ownable
{
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private _release_time;

    constructor(address _beneficiary, uint256 _unix_release_time)
    {
        require(_unix_release_time > block.timestamp, "WHEXcosystemTimelock: release time is before current time");
        
        _owner        = _beneficiary;
        _release_time = _unix_release_time;
    }

    function beneficiary() public view virtual returns(address)
    {
        return owner();
    }

    function release_time() public view virtual returns(uint256)
    {
        return _release_time;
    }
    
    function extend_release_time(uint256 _new_release_time) public onlyOwner
    {
        require(_new_release_time > release_time(), "WHEXcosystemTimelock: new release time is before current release time");
        
        _release_time = _new_release_time;
    }
    
    function release_token(address token_address) public onlyOwner
    {
        require(block.timestamp >= release_time(), "WHEXcosystemTimelock: premature release attempt");
        
        IERC20 token = IERC20(token_address);
        
        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "WHEXcosystemTimelock: token balance is zero");

        token.safeTransfer(beneficiary(), amount);
    }
}