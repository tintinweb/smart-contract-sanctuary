// SPDX-License-Identifier: MIT

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./MinterRole.sol";

contract TripToken is ERC20, MinterRole {
    using SafeMath for uint256;

    struct StakeInfo {
        address beneficiary;
        uint256 amount;
        uint256 releaseAmount;
        uint256 releaseTime;
    }

    // string private _name;
    // string private _symbol;
    // uint8 private _decimals;
    uint256 private _cap;

    uint256 private _stakeTotal;
    uint256 private _stakeCount;

    mapping (uint256 => StakeInfo) private _stakes;

    constructor () public  {
        // _name = "Trip Token";
        // _symbol = "TRIP";
        // _decimals = 6;
        _cap = 650000000000000;
        _mint(msg.sender, 195000000000000);
    }

    event Stake(address indexed beneficiary, uint256 id, uint256 amount, uint256 releaseTime);

    function name() public pure returns (string memory) {
        // return _name;
        return "Trip Token";
    }

    function symbol() public pure returns (string memory) {
        // return _symbol;
        return "TRIP";
    }

    function decimals() public pure returns (uint8) {
        // return _decimals;
        return uint8(6);
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function stakeTotal() public view returns (uint256) {
        return _stakeTotal;
    }

    function stakeCount() public view returns (uint256) {
        return _stakeCount;
    }

    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) public returns (bool) {
        _burnFrom(from, value);
        return true;
    }

    function stakeCreate(uint256 id, address beneficiary, uint256 amount, uint256 releaseTime) public onlyMinter returns (bool) {
        require(beneficiary != address(0), "Stake beneficiary is the zero address");
        require(_stakes[id].amount == 0, "Stake already existed");

        _stakes[id].beneficiary = beneficiary;
        _stakes[id].amount = amount;
        _stakes[id].releaseAmount = amount.div(20);
        _stakes[id].releaseTime = releaseTime;
        _stakeTotal = _stakeTotal.add(amount);
        _stakeCount = _stakeCount.add(1);

        // send token to smart contract and lock there!
        _transfer(msg.sender, address(this), amount);
        emit Stake(beneficiary, id, amount, releaseTime);
        return true;
    }

    function stakeRelease(uint256 id) public returns (bool) {
        require(_stakes[id].amount > 0, "Stake is out of token");
        require(block.timestamp >= _stakes[id].releaseTime, "Current time is before release time");

        uint256 releasableAmount = (_stakes[id].amount > _stakes[id].releaseAmount) ? _stakes[id].releaseAmount : _stakes[id].amount;

        // release period 1 week, 7-days (7 * 24* 3600 = 604,800)
        _stakes[id].releaseTime = _stakes[id].releaseTime.add(604800);
        _stakes[id].amount = _stakes[id].amount.sub(releasableAmount);

        _transfer(address(this), _stakes[id].beneficiary, releasableAmount);
        return true;
    }

    function stakeInfo(uint256 id) public view returns (address, uint256, uint256, uint256) {
        return (_stakes[id].beneficiary, _stakes[id].amount, _stakes[id].releaseAmount, _stakes[id].releaseTime);
    }

}