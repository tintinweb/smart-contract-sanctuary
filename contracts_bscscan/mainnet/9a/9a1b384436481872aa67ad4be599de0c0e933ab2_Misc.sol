/**
 *Submitted for verification at BscScan.com on 2021-08-25
*/

/**
 * 
   #POLE
   
    ::::::::   ::::::::  :::    ::: ::::::::::: :::    ::: :::::::::   ::::::::  :::        :::::::::: 
    :+:    :+: :+:    :+: :+:    :+:     :+:     :+:    :+: :+:    :+: :+:    :+: :+:        :+:        
    +:+        +:+    +:+ +:+    +:+     +:+     +:+    +:+ +:+    +:+ +:+    +:+ +:+        +:+        
    +#++:++#++ +#+    +:+ +#+    +:+     +#+     +#++:++#++ +#++:++#+  +#+    +:+ +#+        +#++:++#   
           +#+ +#+    +#+ +#+    +#+     +#+     +#+    +#+ +#+        +#+    +#+ +#+        +#+        
    #+#    #+# #+#    #+# #+#    #+#     #+#     #+#    #+# #+#        #+#    #+# #+#        #+#        
     ########   ########   ########      ###     ###    ### ###         ########  ########## ##########
 

   SouthPole was here....
   https://t.me/SouthPoleToken



 */

 // SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

library Misc {
  /**
    * @dev Returns true if `account` is a contract.
    *
    * [IMPORTANT]
    * ====
    * It is unsafe to assume that an address for which this function returns
    * false is an externally-owned account (EOA) and not a contract.
    *
    * Among others, `isContract` will return false for the following
    * types of addresses:
    *
    *  - an externally-owned account
    *  - a contract in construction
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
    */
  function isContract(address account) external view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function today() external view returns (uint256) {
    return block.timestamp / 1 days;
  }
}