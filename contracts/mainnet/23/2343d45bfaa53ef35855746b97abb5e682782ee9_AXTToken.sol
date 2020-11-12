pragma solidity >=0.4.24 <0.6.0;

import "./ERC20Detailed.sol";
//import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Stopable.sol";

contract AXTToken is ERC20Detailed, /*ERC20,*/ ERC20Burnable, Stoppable {

    constructor (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint8 decimals
    ) ERC20Detailed(name, symbol, decimals)
    public {
        _mint(owner(), totalSupply * 10**uint(decimals));
    }

    // Don't accept ETH
    function () payable external {
        revert();
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    //------------------------
    // Lock account transfer 

    mapping (address => uint256) private _lockTimes;
    mapping (address => uint256) private _lockAmounts;

    event LockChanged(address indexed account, uint256 releaseTime, uint256 amount);

    function setLock(address account, uint256 releaseTime, uint256 amount) onlyOwner public {
        _lockTimes[account] = releaseTime; 
        _lockAmounts[account] = amount;
        emit LockChanged( account, releaseTime, amount ); 
    }

    function getLock(address account) public view returns (uint256 lockTime, uint256 lockAmount) {
        return (_lockTimes[account], _lockAmounts[account]);
    }

    function _isLocked(address account, uint256 amount) internal view returns (bool) {
        return _lockTimes[account] != 0 && 
            _lockAmounts[account] != 0 && 
            _lockTimes[account] > block.timestamp &&
            (
                balanceOf(account) <= _lockAmounts[account] ||
                balanceOf(account).sub(_lockAmounts[account]) < amount
            );
    }

    function transfer(address recipient, uint256 amount) enabled public returns (bool) {
        require( !_isLocked( msg.sender, amount ) , "ERC20: Locked balance");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) enabled public returns (bool) {
        require( !_isLocked( sender, amount ) , "ERC20: Locked balance");
        return super.transferFrom(sender, recipient, amount);
    }


}