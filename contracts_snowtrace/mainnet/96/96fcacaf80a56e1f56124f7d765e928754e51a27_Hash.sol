// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

/// @custom:security-contact [email protected]
contract Hash is ERC20 {
    constructor() ERC20("Hash", "$HASH") {
        _mint(msg.sender, 250000000 * 10 ** decimals());
    }
    // Burn .001% on transfers to those not in allowed list
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 burnAmount = 0;

        // min transfer amount to burn at 10000 wei        
        if (amount > 10000 && allowance(msg.sender, recipient) == 0) {
          // we are okay with losing some 
          // precision to ensure we do not overflow
          burnAmount = (amount / 10000) * 1; // Burn 0.01%            
          amount = amount - burnAmount;
        }
        
        super.transfer(recipient, amount);
        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }
        return true;
    }
}