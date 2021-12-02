/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

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
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
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
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ColorbayMultiSign {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionSuccess(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

    struct Transaction {
        address destination;
        uint256 value;
        bool executed;
        uint256 beginTime;
    }

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping(address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public dTime = 48*3600;
    uint256 public transactionCount;
    IERC20 public token;


    constructor(address _token, address[] memory _owners, uint256 _required) public validRequirement(_owners.length, _required){
        require(_owners.length >= _required ,"ColorbayMultiSign: Required bigger than Owner num");
        token = IERC20(_token);
        require(_owners.length <= 100);
        for (uint256 i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /* ========== VIEWS ========== */
    function getConfirmationCount(uint256 transactionId) public view returns (uint256 count){
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count = count.add(1);
            }
        }
    }

    function getLastTransactionId() public view returns (uint256 lastID){
       return transactionCount.sub(1);
    }

    function getTransactionCount(bool pending, bool executed) public view returns (uint256 count){
        for (uint256 i=0; i<transactionCount; i++) {
            if ((pending && !transactions[i].executed) || (executed && transactions[i].executed)) {
                count = count.add(1);
            }
        }
    }

    function getOwners() public view returns (address[] memory){
        return owners;
    }

    function getConfirmationAddress(uint256 transactionId) public view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count = count.add(1);
            }
        }
        _confirmations = new address[](count);
        for (uint256 i=0; i<count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }
    function isConfirmed(uint256 transactionId) public view returns (bool){
        uint256 count = 0;
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count = count.add(1);
            }
            if (count >= required) {
                return true;
            }
        }
        return false;
    }


    //---write---//
    modifier validRequirement(uint256 tLenOwner , uint256 tRequired) {
        require(tLenOwner >= tRequired ,"ColorbayMultiSign: Required bigger than Owner num");
        _;
    }
    modifier ownerExists(address addr) {
        require(isOwner[addr] ,"ColorbayMultiSign: not Owner");
        _;
    }
    function submitTransaction(address destination, uint256 value) public ownerExists(msg.sender) returns (uint256 transactionId){
        require(destination != address(0), "transfer from 0");
        require(value <= token.balanceOf(address(this)), "value too big");
        transactionId = addTransaction(destination, value);

        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint256 transactionId) public ownerExists(msg.sender){
        require(transactionId< transactionCount,"ColorbayMultiSign: transactionId not exit");
        require(!transactions[transactionId].executed,"ColorbayMultiSign: transactionId executed");
        require(!confirmations[transactionId][msg.sender],"ColorbayMultiSign: transactionId Confirmed");
        require(block.timestamp <= transactions[transactionId].beginTime + dTime,"ColorbayMultiSign: onwer can only confirm in 48 hours!");

        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint256 transactionId) public ownerExists(msg.sender){
        require(transactionId< transactionCount,"ColorbayMultiSign: transactionId not exit");
        require(!transactions[transactionId].executed,"ColorbayMultiSign: transactionId executed");
        require(confirmations[transactionId][msg.sender],"ColorbayMultiSign: transactionId not Confirmed");
        require(block.timestamp <= transactions[transactionId].beginTime + dTime,"ColorbayMultiSign: onwer can only revoke confirm in 48 hours!");

        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint256 transactionId) internal {
        require(!transactions[transactionId].executed,"ColorbayMultiSign: transactionId executed");
        if (isConfirmed(transactionId)) {
            Transaction storage ta = transactions[transactionId];
            ta.executed = true;
            token.safeTransfer(ta.destination, ta.value);
            emit ExecutionSuccess(transactionId);
        }
    }

    function addTransaction(address destination, uint256 value) internal returns (uint256 transactionId){
        require(destination != address(0),"ColorbayMultiSign: destination 0");
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            executed: false,
            beginTime: block.timestamp
        });
        transactionCount = transactionCount.add(1);
        emit Submission(transactionId);
    }


    function removeOwner() public ownerExists(msg.sender){
        require(owners.length >1,"ColorbayMultiSign: only one owner");
        isOwner[msg.sender] = false;

        for (uint256 i=0; i<owners.length.sub(1); i++) {
            if (owners[i] == msg.sender) {
                owners[i] = owners[owners.length.sub(1)];
                break;
            }
        }
        owners.pop();
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoval(msg.sender);
    }

    function changeRequirement(uint256 _required) private validRequirement(owners.length, _required){
        required = _required;
        emit RequirementChange(_required);
    }

}