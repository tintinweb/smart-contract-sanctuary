// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "./ERC20.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Roles.sol";
import "./MinterRole.sol";

contract TESTToken is ERC20("TEST", "TEST"),MinterRole {
    
    address public NOBURN;
    function newNOBURN (address _NOBURN) public onlyMinter {
        NOBURN =_NOBURN;
    }
  
    constructor() public {
        mint(msg.sender, 88888888e18);
    }

    function mint(address _to, uint256 _amount) public onlyMinter {
        _mint(_to, _amount);
    }
    function burn(uint256 _amount) external {
    _burn(address(msg.sender), _amount);
    }
    function _transfer(address sender, address recipient, uint256 amount)
        internal
        virtual
        override{
             if (sender == NOBURN|| recipient == NOBURN) {
            super._transfer(sender, recipient, amount);
             }
            
        else {
          uint256 rateAmount = 2;
          uint256 burnAmount = amount.mul(rateAmount).div(100); // 2)%f every transfer burnt         
          uint256 sendAmount = amount.sub(burnAmount);
          require(amount == sendAmount + burnAmount, "Burn value invalid");
          super._burn(sender, burnAmount);         
          super._transfer(sender, recipient, sendAmount);
          amount = sendAmount; 
        }
                 
}
}