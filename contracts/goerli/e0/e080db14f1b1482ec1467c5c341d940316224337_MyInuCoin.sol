// SPDX-License-Identifier: MIT

/*

 __  __            ___
|  \/  | _   _    |_ _|  __ _  _   _
| |\/| || | | |    | |  / _` || | | |
| |  | || |_| |    | | | | | || |_| |
|_|  |_|| .__/    |___||_| |_||_.__/
         \___|

1% Rewards
9% Marketing and Development
Website: https://kittyinuerc20.io/
Telegram: https://t.me/kittyinutoken
Twitter: https://twitter.com/KittyInuErc20
Medium: https://medium.com/@kittyinu
Github: https://github.com/KittyInu
Instagram: https://www.instagram.com/kittyinuerc20/
Facebook: https://www.facebook.com/profile.php?id=100073769243131

*/

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title MyInuCoin
 *
 * @dev Standard ERC20 token with burning and optional functions implemented.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract MyInuCoin is Ownable, ERC20 {

   /**
     * @dev Constructor.
   * @param tokenOwnerAddress address that gets 100% of token supply
   */
    constructor(address tokenOwnerAddress) ERC20('MyInuCoin', 'MIC') {
        _mint(tokenOwnerAddress, 40 * (10**9) * (10**18));
    }

    /**
     * @dev Burns a specific amount of tokens.
   * @param value The amount of lowest token units to be burned.
   */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function withdrawEther(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }

    function kill() public onlyOwner {
        selfdestruct(payable (owner()));
    }

}