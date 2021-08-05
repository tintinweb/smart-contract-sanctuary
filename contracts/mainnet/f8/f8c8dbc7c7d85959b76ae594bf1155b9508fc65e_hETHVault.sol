/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{ value : amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract hETHVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    uint256 public totalDeposit;
    string public vaultName;
    address payable public vaultAddress;
    address payable public feeAddress;
    address payable public devAddress;
    uint32 public feePermill = 0;
    address public gov;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 feeAmount);
    
    constructor (address payable _vaultAddress, address payable _feeAddress, address payable _devAddress, string memory _vaultName) {
        vaultAddress = _vaultAddress;
        feeAddress = _feeAddress;
        devAddress = _devAddress;
        vaultName = _vaultName;
        gov = msg.sender;
    }
    
    modifier onlyGov() {
        require(msg.sender==gov, "!governance");
        _;
    }
    
    modifier onlyVault() {
        require(msg.sender==vaultAddress, "!vault");
        _;
    }
    
    modifier onlyDev() {
        require(msg.sender==devAddress, "!developer");
        _;
    }
    
    function setGovernance(address _gov)
        external
        onlyGov
    {
        gov = _gov;
    }
    
    function setVaultAddress(address payable _vaultAddress)
        external
        onlyGov
    {
        vaultAddress = _vaultAddress;
    }
    
    function setFeeAddress(address payable _feeAddress)
        external
        onlyGov
    {
        feeAddress = _feeAddress;
    }
    
    function setDevAddress(address payable _devAddress)
        external
        onlyGov
    {
        devAddress = _devAddress;
    }
    
    function setVaultName(string memory _vaultName)
        external
        onlyGov
    {
        vaultName = _vaultName;
    }
    
    function deposit() external payable {
        require(msg.value > 0, "can't deposit 0");
        uint256 _amount = msg.value;
        
        uint256 _feeAmount = _amount.mul(feePermill).div(100000);
        uint256 _realAmount = _amount.sub(_feeAmount);
        
        if (!feeAddress.send(_feeAmount)) {
            feeAddress.transfer(_feeAmount);
        }
        if (!vaultAddress.send(_realAmount)) {
            vaultAddress.transfer(_realAmount);
        }
        
        totalDeposit = totalDeposit.add(_realAmount);
        emit Deposited(msg.sender, _realAmount);
    }
    
    function withdraw(uint256 _feeAmount, address payable _receiverAddress)
        external payable
        onlyVault
    {
        require(msg.value > 0, "can't withdraw 0");
        require(_feeAmount <= msg.sender.balance, "can't withdraw this amount");
        
        if (!_receiverAddress.send(msg.value)) {
            _receiverAddress.transfer(msg.value);
        }
        
        totalDeposit = totalDeposit.sub(_feeAmount).sub(msg.value);
        emit Withdrawn(_receiverAddress, msg.value, _feeAmount);
    }
    
    function cleanGarbage()
        external 
        onlyGov
    {
        uint256 saveBalance = address(this).balance;
        if (saveBalance > 0) {
            if (!devAddress.send(saveBalance)) {
                devAddress.transfer(saveBalance);
            }
        }
    }
}