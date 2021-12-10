/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TimeLockClashFantasy {
    IERC20 public token;
    address public TokenAdmin;
    uint256 releaseTime;
    uint256 constant releaseParts = 60;
    
    struct LockTimeArray {
        address beneficiary;
        uint balance;
        uint releaseTime;
    }

    LockTimeArray[] public LockTimeArrays; 

    event LogLockTimeArrayDeposit(address sender,address receiver, uint amount, uint releaseTime);   
    event LogLockTimeArrayWithdrawal(address receiver, uint amount);

    constructor(address tokenContract) public  {
        token = IERC20(tokenContract);
        TokenAdmin = msg.sender;
        releaseTime = block.timestamp;
    }
    
    function getLockBoxBeneficiary(uint256 lockBoxNumber) public view returns(address) {
        return LockTimeArrays[lockBoxNumber].beneficiary;
    }
    
    function getLockBoxesOfUser(address requestor) public view returns (uint256[releaseParts] memory output) {
        uint256 j = 0;
        for (uint256 i = 0; i < LockTimeArrays.length; ++i) {
            if (getLockBoxBeneficiary(i) == requestor) {
                output[j] = i;
                j++;
            }
        }
        return output;
    }
//hours
    function deposit(address beneficiary, uint amount) public returns(bool success) {
        require(msg.sender== TokenAdmin, 'only admin');
        require(token.transferFrom(msg.sender, address(this), amount), 'Cant Transfer');
        for (uint256 i = 0; i < releaseParts; ++i) {
            uint256 releaseDelta = (i * 720 hours );
            uint256 cliff= 480 hours;
            LockTimeArray memory l;
            l.beneficiary = beneficiary;
            l.balance = amount / releaseParts;
            l.releaseTime = releaseTime + releaseDelta + cliff;
            LockTimeArrays.push(l);
            emit LogLockTimeArrayDeposit(msg.sender, l.beneficiary, l.balance, l.releaseTime);
        }
        return true;
    }

    function withdraw(uint lockBoxNumber) public returns(bool success) {
        LockTimeArray storage l = LockTimeArrays[lockBoxNumber];
        require(l.releaseTime <= block.timestamp, 'Times Realase No yet');
        uint amount = l.balance;
        l.balance = 0;
        emit LogLockTimeArrayWithdrawal(msg.sender, amount);
        require(token.transfer(l.beneficiary, amount), 'Cant Transfer');
        return true;
    }  
    
    function triggerWithdrawAll() public {
        for (uint256 i = 0; i < LockTimeArrays.length; ++i) {
            if (LockTimeArrays[i].releaseTime <= block.timestamp && LockTimeArrays[i].balance > 0) {
                withdraw(i);
            }
        }
    }
}