/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;

contract Incrementer {
    uint256 public number = 7;
    string private _name = "Shib";
    string private _symbol = "SHIB";
    address payable public marketingAddress = payable(0x2CD87904B77Eb4658408f8b8c35D9F98A05A4Ea9); // Marketing Address
    address payable public devAddress = payable(0x5e7377fB18a55770Fd27d6e2D3b578A3a5EBD5Ba); // DEV Address
    address public rewardsAddress = 0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3; // REWARDS Address
    uint256 public _rewardsFee = 5;
    uint256 public _liquidityFee = 2;
    uint256 public _marketingFee = 3;
    uint256 public _devFee = 1;
    mapping (address => uint256) private _balances;
    uint8 public _decimals;

    constructor() {
        _balances[msg.sender] = 100000;
        _decimals = 18;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function increment(uint256 _value) public {
        number = number + _value;
    }

    function reset() public {
        number = 0;
    }
}