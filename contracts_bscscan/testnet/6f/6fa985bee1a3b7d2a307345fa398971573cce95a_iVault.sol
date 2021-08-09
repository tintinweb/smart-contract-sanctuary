/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping(address=>uint256) private _mintLastBlockHeight;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(block.number>_mintLastBlockHeight[sender],"ERC20: sender account locked");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _mintLastBlockHeight[account] = block.number;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
        (bool success, ) = recipient.call.value(amount)("");
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

interface IPlayerBook {
    function bindRefer( address from,string calldata  affCode )  external returns (bool);
    function hasRefer(address from) external returns(bool);
}


interface WBNB {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface Controller {
    function withdraw(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function earn(address, uint) external;
}

contract iVault is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    uint public min = 9500;
    uint public constant max = 10000;

    uint public depositWithdrawInterval = 60;

    mapping(address => bool) public approved;
    mapping(address => uint256) userDepoistTime;
    address public feeAddress;
    
    uint public fee1 = 100;       //fee within 24 hours
    uint public fee2 = 5;       //fee within 1 week
    uint public fee3 = 3;       //fee without 1 week
    uint public feeMax = 1000;

    uint256 public totalDepositCap = uint256(-1);
    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address public playerBook;
    address public governance;
    address public controller;
	address public timelock;

    modifier onlyRestrictContractCall() {
         address s = msg.sender;
        require(approved[msg.sender] ||  msg.sender == tx.origin, "Sorry we do not accept contract");
        _;
    }

    function () external payable {
        if (msg.sender != wbnb) {
            depositBNB("");
        }
    }

    constructor (address _playerBook,address _feeAddress) public ERC20Detailed(
        "inx:vault:BNB","iBNB",18
    ) {
        governance = tx.origin;
        controller = 0xb06baDE8d55e0be6E235674527299b73dCdE1552;
        feeAddress = _feeAddress;
		timelock = tx.origin;
        playerBook = _playerBook;
    }

    function balance() public view returns (uint) {
        return IERC20(wbnb).balanceOf(address(this))
                .add(Controller(controller).balanceOf(wbnb));
    }

    function setMin(uint _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == timelock, "!timelock");
        controller = _controller;
    }

    function setTotalDepositCap(uint256 _totalDepositCap) public {
        require(msg.sender == governance, "!governance");
        totalDepositCap = _totalDepositCap;
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint) {
        return IERC20(wbnb).balanceOf(address(this)).mul(min).div(max);
    }

    function earn() public {
        require( msg.sender == governance,"!governance");
        uint _bal = available();
        IERC20(wbnb).safeTransfer(controller, _bal);
        Controller(controller).earn(wbnb, _bal);
    }

    function depositBNB(string memory inviter) public payable onlyRestrictContractCall{
        if (bytes(inviter).length != 0){
            if (!IPlayerBook(playerBook).hasRefer(msg.sender)) {
                IPlayerBook(playerBook).bindRefer(msg.sender, inviter);
            }
        }
        uint _pool = balance();
        uint _before = IERC20(wbnb).balanceOf(address(this));
        uint _amount = msg.value;
        WBNB(address(wbnb)).deposit.value(_amount)();
        uint _after = IERC20(wbnb).balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        require(_amount <= totalDepositCap, ">totalDepositCap");
        uint shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
        userDepoistTime[msg.sender] = now;
    }

    function withdrawAllETH() external {
        withdrawBNB(balanceOf(msg.sender));
    }

    function withdrawBNB(uint _shares) public onlyRestrictContractCall{
        require(_shares > 0, "Cannot withdraw 0");
        require((now - userDepoistTime[msg.sender])>depositWithdrawInterval,"Deposit and withdraw must be 60 seconds apart!");

        uint r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint b = IERC20(wbnb).balanceOf(address(this));
        if (b < r) {
            uint _withdraw = r.sub(b);
            Controller(controller).withdraw(wbnb, _withdraw);
            uint _after = IERC20(wbnb).balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }
        uint feeRatio = getFeeRatio();
        if(feeRatio>0){
            uint fee = r.mul(feeRatio).div(feeMax);
            r = r.sub(fee);
            IERC20(wbnb).safeTransfer(feeAddress,fee);
        }
        WBNB(address(wbnb)).withdraw(r);
        address(msg.sender).transfer(r);
    }

    function getFeeRatio() internal view returns(uint)
    {
        uint256 t = now - userDepoistTime[msg.sender];
        if(t > 604800) {//7*24*60*60
            return fee3;
        }
        if(t>86400) {//24*60*60
            return fee2;
        }
        return fee1;
    }

    function getPricePerFullShare() public view returns (uint) {
        if (totalSupply()==0) {
            return 0;
        }
        return balance().mul(1e18).div(totalSupply());
    }

    function setFeeRatio(uint[3] memory fees) public
    {
        require(msg.sender == timelock, "!timelock");
        require(fees[0]<=200&&fees[1]<=200&&fees[2]<=200,"The fee is too high");
        fee1 = fees[0];
        fee2 = fees[1];
        fee3 = fees[2];
    }

    function setFeeAddress(address fadd) public
    {
        require(msg.sender == timelock, "!timelock");
        feeAddress = fadd;
    }

	function setTimeLock(address _timelock) public
    {
        require(msg.sender == timelock, "!timelock");
        timelock = _timelock;
    }

    function approveContractAccess(address account) external {
        require(msg.sender == governance, "!governance");
        approved[account] = true;
    }

    function revokeContractAccess(address account) external {
        require(msg.sender == governance, "!governance");
        approved[account] = false;
    }

    function SetPlayerBook(address _playerbook) public {
        require(msg.sender == governance, "!governance");
        playerBook = _playerbook;
    }
}