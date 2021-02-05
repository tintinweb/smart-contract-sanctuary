pragma solidity ^0.5.0;
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./Stopable.sol";

/// @author 
/// @title Token contract
contract ATTToken is ERC20Detailed, ERC20Burnable, Stoppable {

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
    
    //------------------------
    // Lock account transfer 

    mapping (address => uint256) private _lockTimes;
    mapping (address => uint256) private _lockAmounts;

    event LockChanged(address indexed account, uint256 releaseTime, uint256 amount);

    /// Lock user amount.  (run only owner)
    /// @param account account to lock
    /// @param releaseTime Time to release from lock state.
    /// @param amount  amount to lock.
    /// @return Boolean
    function setLock(address account, uint256 releaseTime, uint256 amount) onlyOwner public {
        //require(now < releaseTime, "ERC20 : Current time is greater than release time");
        require(block.timestamp < releaseTime, "ERC20 : Current time is greater than release time");
        require(amount != 0, "ERC20: Amount error");
        _lockTimes[account] = releaseTime; 
        _lockAmounts[account] = amount;
        emit LockChanged( account, releaseTime, amount ); 
    }

    /// Get Lock information  (run anyone)
    /// @param account user acount
    /// @return lokced time and locked amount.
    function getLock(address account) public view returns (uint256 lockTime, uint256 lockAmount) {
        return (_lockTimes[account], _lockAmounts[account]);
    }

    /// Check lock state  (run anyone)
    /// @param account user acount
    /// @param amount amount to check.
    /// @return Boolean : Don't use balance (true)
    function _isLocked(address account, uint256 amount) internal view returns (bool) {
        return _lockAmounts[account] != 0 && 
            _lockTimes[account] > block.timestamp &&
            (
                balanceOf(account) <= _lockAmounts[account] ||
                balanceOf(account).sub(_lockAmounts[account]) < amount
            );
    }

    /// Transfer token  (run anyone)
    /// @param recipient Token trasfer destination acount.
    /// @param amount Token transfer amount.
    /// @return Boolean 
    function transfer(address recipient, uint256 amount) enabled public returns (bool) {
        require( !_isLocked( msg.sender, amount ) , "ERC20: Locked balance");
        return super.transfer(recipient, amount);
    }

    /// Transfer token  (run anyone)
    /// @param sender Token trasfer source acount.
    /// @param recipient Token transfer destination acount.
    /// @param amount Token transfer amount.
    /// @return Boolean 
    function transferFrom(address sender, address recipient, uint256 amount) enabled public returns (bool) {
        require( !_isLocked( sender, amount ) , "ERC20: Locked balance");
        return super.transferFrom(sender, recipient, amount);
    }

    /// Decrease token balance (run only owner)
    /// @param value Amount to decrease.
    function burn(uint256 value) onlyOwner public {
        require( !_isLocked( msg.sender, value ) , "ERC20: Locked balance");
        super.burn(value);
    }
}