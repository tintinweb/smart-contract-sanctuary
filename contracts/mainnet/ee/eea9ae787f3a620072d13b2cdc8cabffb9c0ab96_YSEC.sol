/*
__/\\\________/\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\________/\\\\\\\\\_        
 _\///\\\____/\\\/____/\\\/////////\\\_\/\\\///////////______/\\\////////__       
  ___\///\\\/\\\/_____\//\\\______\///__\/\\\_______________/\\\/___________      
   _____\///\\\/________\////\\\_________\/\\\\\\\\\\\______/\\\_____________     
    _______\/\\\____________\////\\\______\/\\\///////______\/\\\_____________    
     _______\/\\\_______________\////\\\___\/\\\_____________\//\\\____________   
      _______\/\\\________/\\\______\//\\\__\/\\\______________\///\\\__________  
       _______\/\\\_______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\____\////\\\\\\\\\_ 
        _______\///__________\///////////_____\///////////////________\/////////__

Visit and follow!

* Website:  https://www.ysec.finance
* Twitter:  https://twitter.com/YearnSecure
* Telegram: https://t.me/YearnSecure
* Medium:   https://medium.com/@yearnsecure

*/

// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity 0.7.0;

contract YSEC is ERC20{
    using SafeMath for uint;

    address public Governance;

    constructor () ERC20("YearnSecure", "YSEC", 1000000) {
        Governance = msg.sender;
    }

    function burn(uint256 amount) external {
        require(msg.sender == Governance, "Caller does not have governance");
        _burn(msg.sender, amount);
    }

    function burnGovernance() external{
        require(msg.sender == Governance, "Caller does not have governance");
        Governance = address(0x0);
    }
}
