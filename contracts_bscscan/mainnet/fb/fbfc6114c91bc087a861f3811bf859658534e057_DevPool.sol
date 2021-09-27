/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

/**
 * The BNBPower contract does this and that...
 */
contract DevPool {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address[7] founders;
    address dev;
    uint256 timeblock;

    uint256 private totalTokenLock = 10 * 10**9 * 1 ether;

    IERC20 public token;
    mapping (address => bool) public isOwners;
    mapping (address => bool) public isAdmin;
    mapping (address => uint256) public percent;
    
    mapping (address => bool) public tokenClaimed;
    
    modifier onlyOwner() { 
        require (isOwners[msg.sender]);
        _; 
    }
    
    modifier onlyAdmin() { 
        require (isAdmin[msg.sender]);
        _; 
    }
  
    constructor(){
        dev = msg.sender;
        timeblock = block.timestamp + 180 days;
    }

    function addFounder(
        address[7] calldata addr
    ) external {
        require (msg.sender == dev);

        isOwners[addr[0]] = true;
        isOwners[addr[1]] = true;
        isOwners[addr[2]] = true;
        isOwners[addr[3]] = true;
        isOwners[addr[4]] = true;
        isOwners[addr[5]] = true;
        isOwners[addr[6]] = true;
        percent[addr[0]] = 35;
        percent[addr[1]] = 20;
        percent[addr[2]] = 20;
        percent[addr[3]] = 10;
        percent[addr[4]] = 5;
        percent[addr[5]] = 5;
        percent[addr[6]] = 5;
        founders = addr;
    }

    function addAdmin (
        address addr1,
        address addr2
    ) external {
         require (msg.sender == dev);
        isAdmin[addr1] = true;
        isAdmin[addr2] = true;
    }
    

    function transferFounderAddress (address _newAddr) external onlyOwner {
        isOwners[msg.sender] = false;
        isOwners[_newAddr] = true;
        percent[_newAddr] = percent[msg.sender];
        percent[msg.sender] = 0;
        tokenClaimed[_newAddr] = tokenClaimed[msg.sender];
        for(uint256 i=0; i< founders.length; i++){
            if(founders[i] == msg.sender){
                founders[i] = _newAddr;
            }
        }
    }
    
    function claimToken() external onlyOwner {
        require(block.timestamp >= timeblock);
        require(!tokenClaimed[msg.sender]);
        uint256 amount = totalTokenLock.mul(percent[msg.sender]).div(100);
        token.safeTransfer(msg.sender, amount);
        tokenClaimed[msg.sender] = true;
    }

    function withdrawFee() external onlyAdmin {
        uint256 balance = address(this).balance;
        for(uint256 i=0; i< founders.length; i++){
            uint256 amount = balance.mul(percent[founders[i]]).div(100);
            Address.sendValue(payable(founders[i]), amount);
        }
    }

    function addToken (address _token) external {
         require (msg.sender == dev);
         require (_token != address(0));        
         token = IERC20(_token);
    }

    fallback () external payable {}
    
    receive() external payable {}
}