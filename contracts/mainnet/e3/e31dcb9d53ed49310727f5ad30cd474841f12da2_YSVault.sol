/**
 *Submitted for verification at Etherscan.io on 2020-09-21
*/

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

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
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
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

interface IVault {
    function token() external view returns (address);
    function deposit(uint) external;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
}

contract YSVault is ERC20, ERC20Detailed, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    string private constant NAME = "yfSCAN Tether USD";
    string private constant SYMBOL = "ysUSDT";
    uint8 private constant DECIMALS = 6;
    address private constant ADDRESS_TOKEN = 0xdAC17F958D2ee523a2206206994597C13D831ec7;    // USDT
    address private constant ADDRESS_VAULT = 0x2f08119C6f07c006695E079AAFc638b8789FAf18;    // yearn USDT vault

    IERC20 public token;
    IVault public vault;

    mapping(address => uint256) public balancesToken;
    mapping(address => uint256) public balancesVault;

    address public governance;
    address public pool;
    bool public lockedDeposit = true;

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor () public
    ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        token = IERC20(ADDRESS_TOKEN);
        vault = IVault(ADDRESS_VAULT);
        governance = msg.sender;
    }



    function balanceToken() public view returns (uint) {
        return token.balanceOf(address(this));
    }
    function balanceVault() public view returns (uint) {
        return vault.balanceOf(address(this));
    }



    function depositAll() external {
        deposit(token.balanceOf(msg.sender));
    }

    function deposit(uint _amount) public {
        require(lockedDeposit == false, 'Deposits are locked');

        uint256 _totalVaultBalanceBefore = vault.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        token.safeApprove(address(vault), _amount);
        vault.deposit(_amount);
        uint256 _totalVaultBalanceAfter = vault.balanceOf(address(this));

        uint256 _amountInVaultShares = _totalVaultBalanceAfter.sub(_totalVaultBalanceBefore);

        balancesToken[msg.sender] = balancesToken[msg.sender].add(_amount);
        balancesVault[msg.sender] = balancesVault[msg.sender].add(_amountInVaultShares);

        _mint(msg.sender, _amountInVaultShares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public {
        _burn(msg.sender, _shares);

        uint256 _totalTokenBalanceBefore = token.balanceOf(address(this));
        vault.withdraw(_shares);
        uint256 _totalTokenBalanceAfter = token.balanceOf(address(this));

        uint256 _tokensTransfered = _totalTokenBalanceAfter.sub(_totalTokenBalanceBefore);

        uint256 _tokensToUser = _shares.mul(balancesToken[msg.sender]).div(balancesVault[msg.sender]);

        if(_tokensToUser > _tokensTransfered) {
            _tokensToUser = _tokensTransfered;
        }
        if(_tokensToUser > balancesToken[msg.sender]) {
            _tokensToUser = balancesToken[msg.sender];
        }

        balancesToken[msg.sender] = balancesToken[msg.sender].sub(_tokensToUser);
        balancesVault[msg.sender] = balancesVault[msg.sender].sub(_shares);

        token.safeTransfer(msg.sender, _tokensToUser);
    }



    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        address _sender = _msgSender();

        _transfer(_msgSender(), _recipient, _amount);
        if(msg.sender != pool) {
            uint256 _amountInToken = _amount.mul(balancesToken[_sender]).div(balancesVault[_sender]);

            balancesVault[_sender] = balancesVault[_sender].sub(_amount, "Vault: transfer amount exceeds balance");
            balancesVault[_recipient] = balancesVault[_recipient].add(_amount);

            balancesToken[_sender] = balancesToken[_sender].sub(_amountInToken, "Vault: transfer amount exceeds balance");
            balancesToken[_recipient] = balancesToken[_recipient].add(_amountInToken);
        }

        return true;
    }



    function setPool(address _pool) public onlyGovernance {
        pool = _pool;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }

    function withdrawProfits() public onlyGovernance {
        token.safeTransfer(governance, balanceToken());
    }

    function withdrawTokenProfits(address _token) public onlyGovernance {
        require(_token != address(token), 'You can only withdraw reward token.');
        IERC20 _rewardToken = IERC20(_token);
        _rewardToken.safeTransfer(governance, _rewardToken.balanceOf(address(this)));
    }

    function lockDeposits() public onlyGovernance {
        require(lockedDeposit == false, 'Deposits are already locked');
        lockedDeposit = true;
    }
    function unlockDeposits() public onlyGovernance {
        require(lockedDeposit == true, 'Deposits are already unlocked');
        lockedDeposit = false;
    }
    function depositIsLocked() public view returns (bool) {
        return lockedDeposit;
    }
}