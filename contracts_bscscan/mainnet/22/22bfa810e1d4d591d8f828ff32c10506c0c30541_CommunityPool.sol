/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");

        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

interface ERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        ERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        ERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        ERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract CommunityPool is Ownable {
    using SafeMath for uint256;

    using SafeERC20 for ERC20;

    uint256 constant public PERIOD = 63113852; // 2 years
    uint256 public START_TIME = 1639612800; // 12:00:00 GMT 16/12/2021
    ERC20 public TOKEN = ERC20(0x6ef238E9E8CD2A96740897761C18894Fc086B9d0); //MYRA token

    uint256 public lockToken = 21000000 * 10**18;
    uint256 public lastTimeRelease;
    uint256 public countRelease;
    uint256 public tokenUnlocked;
    uint256 public totalVestingCycle;
    address public whitelistAddress;

    bool isPaused;

    event Release(address addr, uint256 amount, uint256 timestamp);

    modifier whenNotPaused() {
        require(!isPaused, "Contract paused");
        _;
    }
    constructor(address _addr) {
        whitelistAddress = _addr;
        lastTimeRelease = START_TIME.sub(PERIOD);
        totalVestingCycle = 730;
    }

    function release() public whenNotPaused {
        require(msg.sender == whitelistAddress, "Only whitelist address can claim");
        require(tokenUnlocked < lockToken, "Token has been unlocked successfully");
        require(block.timestamp >= START_TIME, "Token until lock");
        uint256 cliff = uint256(block.timestamp).sub(lastTimeRelease).div(PERIOD);
        uint256 tokenCanRelease = lockToken.div(totalVestingCycle).mul(cliff);
        require(tokenCanRelease > 0, "Can not release zero token");
        if(tokenUnlocked.add(tokenCanRelease) > lockToken){
            TOKEN.safeTransfer(whitelistAddress, lockToken.sub(tokenUnlocked));
            emit Release(msg.sender, lockToken.sub(tokenUnlocked), block.timestamp);
            tokenUnlocked = lockToken;
        } else {
            TOKEN.safeTransfer(whitelistAddress, tokenCanRelease);
            tokenUnlocked = tokenUnlocked.add(tokenCanRelease);
            emit Release(msg.sender, tokenCanRelease, block.timestamp);
        }
        countRelease++;
        lastTimeRelease = lastTimeRelease.add(cliff * PERIOD);
    }
    
    function getTokenCanRelease() public view returns(uint256) {
        if(block.timestamp < START_TIME){
            return 0;
        }
        uint256 cliff = uint256(block.timestamp).sub(lastTimeRelease).div(PERIOD);
        uint256 tokenCanRelease = lockToken.div(totalVestingCycle).mul(cliff);
        if(tokenUnlocked.add(tokenCanRelease) > lockToken){
            return lockToken.sub(tokenUnlocked);
        } else {
            return tokenCanRelease;
        }
    }

    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }
    
    function getTimeReleaseNext() public view returns(uint256) {
        return lastTimeRelease.add(PERIOD);
    }

    function updateAddress(address _newAddress) public {
        require(msg.sender == whitelistAddress, "Only whitelist address can update");
        require(_newAddress != address(0), "Not accept zero address");
        whitelistAddress = _newAddress;
    }

    function updateTotalVestingCycle(uint256 _newTotalVesting) external onlyOwner {
        totalVestingCycle = _newTotalVesting;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }
    
    function unpause() external onlyOwner {
        isPaused = false;
    }

    function setTokenAddress(address _addr) external onlyOwner {
        TOKEN = ERC20(_addr);
    }

    function setTotalTokenLock(uint256 _total) external onlyOwner {
        lockToken = _total;
    }

    function emergencyWithdrawToken(uint256 _amount) external onlyOwner {
        TOKEN.safeTransfer(owner(), _amount); 
    }

    function getBalance() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

}