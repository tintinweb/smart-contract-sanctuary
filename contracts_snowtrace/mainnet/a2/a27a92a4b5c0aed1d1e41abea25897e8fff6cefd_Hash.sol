// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

/// @custom:security-contact [email protected]
contract Hash is ERC20 {
    constructor() ERC20("Hash", "$HASH") {
        _mint(msg.sender, 250000000 * 10 ** decimals());
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _shouldBurn(uint256 amount, address recipient, address sender) internal view returns (bool) {
        uint256 minSendToBurn = 1000 * 10 ** decimals();

        if (amount > minSendToBurn && 
            !_isContract(recipient) && 
            allowance(recipient, sender) == 0 && 
            allowance(sender, recipient) == 0) 
        {
            return true;
        } 

        return false;
    }

    // Burn .001% on transfers to those not in allowed list
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 burnAmount = 0;
        bool retVal = false;        

        if (_shouldBurn(amount, recipient, msg.sender)) {
          // we are okay with losing some 
          // precision to ensure we do not overflow
          burnAmount = (amount / 10000) * 1; // Burn 0.01%            
          amount = amount - burnAmount;
        }

        retVal = super.transfer(recipient, amount);
        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return retVal;
    }
}