// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GOVIAirdrop is Ownable {

    IERC20 public token;

    event TokenDistributed(address[] addresses, uint256[] amounts);

    constructor(IERC20 _token) public {
        token = _token;
    }

      /**
     * @dev admin function to bulk distribute to users after TVL threshold is reached
     */
    function distribute(address[] memory addresses, uint256[] memory amounts) public onlyOwner {
        uint256 numAddresses = addresses.length;
        uint256 numAmounts = amounts.length;
        require(numAddresses == numAmounts, "Invalid parameters");

        for (uint256 i = 0; i < addresses.length; i++) {
            require(amounts[i] > 0, "Invalid transfer amount");
            require(addresses[i] != address(0), "Invalid destination address");
            require(token.transfer(addresses[i], amounts[i]), "Token transfer failed");
        }

        emit TokenDistributed(addresses, amounts);
    }
}