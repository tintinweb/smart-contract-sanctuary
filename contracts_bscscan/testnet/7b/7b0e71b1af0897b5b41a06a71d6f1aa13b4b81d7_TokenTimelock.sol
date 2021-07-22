/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.7.1;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not inclusde
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenTimelock {

    IERC20 private _token;

    address private _beneficiary;

    uint256 private _releaseTime;

    constructor (IERC20 token, address beneficiary, uint256 timeLockMinutes) public {
        // solhint-disable-next-line not-rely-on-time
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = block.timestamp + (timeLockMinutes*60);
        require(_releaseTime > block.timestamp, "ERROR");
    }
    function token() public view returns (IERC20) {
        return _token;
    }
    function balance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }
    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
    function canRelease() public view returns (bool) {
        if(_releaseTime < block.timestamp){return true;}
        else {return false;}
    }
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.transfer(_beneficiary, amount);
    }
}