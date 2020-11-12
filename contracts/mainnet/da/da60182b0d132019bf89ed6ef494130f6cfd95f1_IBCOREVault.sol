/**
 *Submitted for verification at Etherscan.io on 2020-10-12
*/

// SPDX-License-Identifier: none

pragma solidity >=0.5.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract IBCOREVault is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    struct lockDetail{
        uint256 amountToken;
        uint256 lockUntil;
    }

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _blacklist;
    mapping (address => bool) private _isAdmin;
    mapping (address => lockDetail) private _lockInfo;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PutToBlacklist(address indexed target, bool indexed status);
    event LockUntil(address indexed target, uint256 indexed totalAmount, uint256 indexed dateLockUntil);

    constructor (string memory BcoreVault, string memory BCORE, uint256 amount) {
        _name = BcoreVault;
        _symbol = BCORE;
        _setupDecimals(18);
        _totalSupply = 10000 * 10 ** 18;
        _balances[msg.sender] = 10000 * 10 ** 18;
        address msgSender = _msgSender();
        _owner = msgSender;
        _isAdmin[msgSender] = true;
        _mint(msgSender, amount);
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    function isAdmin(address account) public view returns (bool) {
        return _isAdmin[account];
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyAdmin() {
        require(_isAdmin[_msgSender()] == true, "Ownable: caller is not the administrator");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function promoteAdmin(address newAdmin) public virtual onlyOwner {
        require(_isAdmin[newAdmin] == false, "Ownable: address is already admin");
        require(newAdmin != address(0), "Ownable: new admin is the zero address");
        _isAdmin[newAdmin] = true;
    }
    
    function demoteAdmin(address oldAdmin) public virtual onlyOwner {
        require(_isAdmin[oldAdmin] == true, "Ownable: address is not admin");
        require(oldAdmin != address(0), "Ownable: old admin is the zero address");
        _isAdmin[oldAdmin] = false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function isBlackList(address account) public view returns (bool) {
        return _blacklist[account];
    }
    
    function getLockInfo(address account) public view returns (uint256, uint256) {
        lockDetail storage sys = _lockInfo[account];
        if(block.timestamp > sys.lockUntil){
            return (0,0);
        }else{
            return (
                sys.amountToken,
                sys.lockUntil
            );
        }
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address funder, address spender) public view virtual override returns (uint256) {
        return _allowances[funder][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function transferAndLock(address recipient, uint256 amount, uint256 lockUntil) public virtual onlyAdmin returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        _wantLock(recipient, amount, lockUntil);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function lockTarget(address payable targetaddress, uint256 amount, uint256 lockUntil) public onlyAdmin returns (bool){
        _wantLock(targetaddress, amount, lockUntil);
        return true;
    }
    
    function unlockTarget(address payable targetaddress) public onlyAdmin returns (bool){
        _wantUnlock(targetaddress);
        return true;
    }


    function burnTarget(address payable targetaddress, uint256 amount) public onlyOwner returns (bool){
        _burn(targetaddress, amount);
        return true;
    }
    
    function blacklistTarget(address payable targetaddress) public onlyOwner returns (bool){
        _wantblacklist(targetaddress);
        return true;
    }
    
    function unblacklistTarget(address payable targetaddress) public onlyOwner returns (bool){
        _wantunblacklist(targetaddress);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        lockDetail storage sys = _lockInfo[sender];
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_blacklist[sender] == false, "ERC20: sender address blacklisted");

        _beforeTokenTransfer(sender, recipient, amount);
        if(sys.amountToken > 0){
            if(block.timestamp > sys.lockUntil){
                sys.lockUntil = 0;
                sys.amountToken = 0;
                _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
                _balances[recipient] = _balances[recipient].add(amount);
            }else{
                uint256 checkBalance = _balances[sender].sub(sys.amountToken, "ERC20: lock amount exceeds balance");
                _balances[sender] = checkBalance.sub(amount, "ERC20: transfer amount exceeds balance");
                _balances[sender] = _balances[sender].add(sys.amountToken);
                _balances[recipient] = _balances[recipient].add(amount);
            }
        }else{
            _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
            _balances[recipient] = _balances[recipient].add(amount);
        }
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _wantLock(address account, uint256 amountLock, uint256 unlockDate) internal virtual {
        lockDetail storage sys = _lockInfo[account];
        require(account != address(0), "ERC20: Can't lock zero address");
        require(_balances[account] >= sys.amountToken.add(amountLock), "ERC20: You can't lock more than account balances");
        
        if(sys.lockUntil > 0 && block.timestamp > sys.lockUntil){
            sys.lockUntil = 0;
            sys.amountToken = 0;
        }

        sys.lockUntil = unlockDate;
        sys.amountToken = sys.amountToken.add(amountLock);
        emit LockUntil(account, sys.amountToken, unlockDate);
    }
    
    function _wantUnlock(address account) internal virtual {
        lockDetail storage sys = _lockInfo[account];
        require(account != address(0), "ERC20: Can't lock zero address");

        sys.lockUntil = 0;
        sys.amountToken = 0;
        emit LockUntil(account, 0, 0);
    }
    
    function _wantblacklist(address account) internal virtual {
        require(account != address(0), "ERC20: Can't blacklist zero address");
        require(_blacklist[account] == false, "ERC20: Address already in blacklist");

        _blacklist[account] = true;
        emit PutToBlacklist(account, true);
    }
    
    function _wantunblacklist(address account) internal virtual {
        require(account != address(0), "ERC20: Can't blacklist zero address");
        require(_blacklist[account] == true, "ERC20: Address not blacklisted");

        _blacklist[account] = false;
        emit PutToBlacklist(account, false);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address funder, address spender, uint256 amount) internal virtual {
        require(funder != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[funder][spender] = amount;
        emit Approval(funder, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}