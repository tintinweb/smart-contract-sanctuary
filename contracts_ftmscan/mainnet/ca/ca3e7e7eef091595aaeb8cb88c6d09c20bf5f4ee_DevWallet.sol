/**
 *Submitted for verification at FtmScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {

    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferFTM(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: FTM_TRANSFER_FAILED');
    }
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/DevWallet.sol

contract DevWallet is Ownable {

    uint public totalAllocPoints;
    uint private _totalReleased;
    IERC20 public immutable soul = IERC20(0xe2fb177009FF39F52C0134E8007FA0e4BaAcBd07);

    mapping(address => uint) private allocation;
    mapping(address => uint) private released;
    address[] private users;

    event UserAdded(address account, uint allocation);
    event SharesUpdated(uint index, address account, uint allocation);

    event PaymentReleased(address to, uint amount);
    event PaymentReceived(address from, uint amount);

    // `users` assigned # allocation matching indexed position in the `allocation` array
    constructor() payable {
        addUser(0xFd63Bf84471Bc55DD9A83fdFA293CCBD27e1F4C8, 5000);
        addUser(0xdcD49C36E69bF85FA9c5a25dEA9455602C0B289e, 4500);
        addUser(0x027a3F533149584ae6b33f1D2eA1CFa3dc8ddf84, 1750);
        addUser(0xfdf676a740574Df045A97Fe7476e2584DA6CD309, 750);
        addUser(0x0E4489998a3eAEBa52B3623268E47f62065aC09B, 500);
        addUser(0x81Dd37687c74Df8F957a370A9A4435D873F5e5A9, 500);
        
        transferOwnership(0x81Dd37687c74Df8F957a370A9A4435D873F5e5A9);
    }

    // shows the available SOUL balance of contract
    function available() public view returns (uint) { 
        return soul.balanceOf(address(this)); 
    }

    // getter for the total allocation held by payees
    function totalShares() public view returns (uint) {
        return totalAllocPoints;
    }

    // getter for the total amount of SOUL already released
    function totalReleased() public view returns (uint amountReleased) {
        return _totalReleased;
    }
    // getter for the amount of allocation held by an account
    function userShares(uint index) public view returns (uint amountShares) {
        address account = users[index];
        return allocation[account];
    }

    // getter for the amount of SOUL already released to a payee
    function userReleased(uint index) public view returns (uint amountReleased) {
        address account = users[index];
        return released[account];
    }

    // getter for the address of the payee number `index`.
    function userAddress(uint index) public view returns (address account) {
        return users[index];
    }

    // transfers `account` amount of SOUL owed, according to their % and ttl withdrawals
    function release(uint index) public {
        address account = users[index];
        require(allocation[account] > 0, 'release: account has no allocation');

        // acquires the adjusted ttl received and calcs payment
        available();
        uint totalReceived = soul.balanceOf(address(this)) + _totalReleased;

        uint payment = (totalReceived * allocation[account]) / totalAllocPoints - released[account];

        // requires account is due payment
        require(payment != 0, 'release: account is not due payment');

        // releases payment and increments released
        released[account] += payment;
        _totalReleased += payment;
        
        // sends SOUL to user
        soul.transfer(account, payment);

        emit PaymentReleased(account, payment);
    }

    // adds a new payee to the contract with their corresponding allocation
    function addUser(address account, uint _allocPoints) public onlyOwner {
        require(account != address(0), 'addUser: account is the zero address');
        require(_allocPoints > 0, 'addUser: allocation are 0');
        require(allocation[account] == 0, 'addUser: account already has allocation');

        // pushes new address, updates allocation, updates ttl allocation
        users.push(account);
        allocation[account] = _allocPoints;
        totalAllocPoints += _allocPoints;

        emit UserAdded(account, _allocPoints);
    }

    // updates allocation allocated to an indexed user
    function updateAllocation(uint index, uint _allocPoints) public onlyOwner {
        address account = users[index];
        require(allocation[account] >= 0, 'updateAllocation: user does not exist');

        // [[-]] removes previous user[i] `allocation`
        totalAllocPoints -= allocation[account];
        // updates user[i] `allocation`
        allocation[account] = _allocPoints;
        // [[+]] updated `allocation` to `total allocation`
        totalAllocPoints += _allocPoints;

        emit SharesUpdated(index, account, _allocPoints);
    }

    // displays `account` amount of SOUL owed, according to their % and ttl withdrawals
    function userBalance(uint index) public view returns (uint) {
        address account = users[index];
        require(allocation[account] >= 0, 'userBalance: user does not exist');

        uint totalReceived = soul.balanceOf(address(this)) + _totalReleased;
        uint userAllocation = enWei(allocation[account]);
        // ttl SOUL `released` to user
        uint userClaimed = released[account];

        uint userAllocated =        // share of the total allocaton belonging to user
            fromWei(                    // scales down by factor of 1e18
                totalReceived           // ttl SOUL ever `received` by contract
                * userAllocation        // user's allocation points
                / totalAllocPoints      // ttl alloc points
            );
        

        uint userUnclaimed = userAllocated - userClaimed;
        // returns the remaining share of total (balance) received for given user
        return userUnclaimed;
    }

    // converts to wei
    function enWei(uint amount) public pure returns (uint) { return amount * 1e18; }
    function fromWei(uint amount) public pure returns (uint) { return (amount / 1e18); }
}