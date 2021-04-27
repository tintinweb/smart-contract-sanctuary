/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.5.2;
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;


contract Manageable is Ownable {
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);
    event ManagementRenounced(address indexed manager);
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    mapping (address => bool) private _managers;

    function addManager(address manager) public onlyOwner {
        if (!isManager(manager)) {
            _managers[manager] = true;
            emit ManagerAdded(manager);
        }
    }

    function removeManager(address manager) public onlyOwner {
        if (isManager(manager)) {
            _managers[manager] = false;
            emit ManagerRemoved(manager);
        }
    }

    function transferManagement(address manager) public onlyManager {
        if (!isManager(manager)) {
            _managers[manager] = true;
            _managers[msg.sender] = false;
            emit ManagementTransferred(msg.sender, manager);
        }
    }

    function renounceManagement() public onlyManager {
        _managers[msg.sender] = false;
        emit ManagementRenounced(msg.sender);
    }

    function isManager(address client) public view returns (bool) {
        return _managers[client];
    }

    modifier onlyManager() {
        require(isManager(msg.sender));
        _;
    }
}

pragma solidity ^0.5.2;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // benefit is lost if 'b' is also tested.
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // than to check the size of the code at that address.
        // for more details about how this works.
        // contracts then.
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.2;
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
        // or when resetting it to zero. To increase and decrease it, use
        require((value == 0) || (token.allowance(address(this), spender) == 0));
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
        // we're implementing it ourselves.
        //  1. The target address is checked to verify it contains contract code
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

pragma solidity ^0.5.2;




contract Vault is Ownable, Manageable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed token, address indexed client, uint256 amount, uint256 fee, uint256 balance);
    event Withdrawal(address indexed token, address indexed client, uint256 amount, uint256 fee, uint256 balance);
    event Transfer(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 fromFee, uint256 toFee);
    event BankChanged(address indexed bank);
    event PermissionChanged(address indexed token, bool depositPermission, bool withdrawalPermission);
    event FeeRateChanged(address indexed token, uint256 depositFeeRate, uint256 withdrawalFeeRate);
    event BlacklistChanged(address indexed client, bool depositBlacklist, bool withdrawalBlacklist);

    address private _bank;
    mapping (address => mapping (address => uint256)) private _balances;
    mapping (address => bool) private _depositPermissions;
    mapping (address => bool) private _withdrawalPermissions;
    mapping (address => bool) private _depositBlacklist;
    mapping (address => bool) private _withdrawalBlacklist;
    mapping (address => uint256) private _depositFeeRates;
    mapping (address => uint256) private _withdrawalFeeRates;

    constructor () public {
        addManager(msg.sender);
    } 
    
    function renounceOwnership() public onlyOwner {
        revert();
    }

    function bank() public view returns (address) {
        return _bank;
    }

    function setBank(address account) public onlyManager {
        if (bank() != account) {
            _bank = account;
            emit BankChanged(bank());
        }
    }

    function balanceOf(address token, address client) public view returns (uint256) {
        return _balances[token][client];
    }

    function _setBalance(address token, address client, uint256 amount) private {
        _balances[token][client] = amount;
    }

    function isDepositPermitted(address token) public view returns (bool) {
        return _depositPermissions[token];
    }

    function isWithdrawalPermitted(address token) public view returns (bool) {
        return _withdrawalPermissions[token];
    }

    function setPermission(address token, bool depositPermission, bool withdrawalPermission) public onlyManager {
        if (isDepositPermitted(token) != depositPermission || isWithdrawalPermitted(token) != withdrawalPermission) {
            _depositPermissions[token] = depositPermission;
            _withdrawalPermissions[token] = withdrawalPermission;
            emit PermissionChanged(token, isDepositPermitted(token), isWithdrawalPermitted(token));
        }
    }

    function multiSetPermission(address[] memory tokens, bool[] memory depositPermissions, bool[] memory withdrawalPermissions) public onlyManager {
        require(tokens.length == depositPermissions.length && tokens.length == withdrawalPermissions.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            setPermission(tokens[i], depositPermissions[i], withdrawalPermissions[i]);
        }
    }

    function isDepositBlacklisted(address client) public view returns (bool) {
        return _depositBlacklist[client];
    }

    function isWithdrawalBlacklisted(address client) public view returns (bool) {
        return _withdrawalBlacklist[client];
    }

    function setBlacklist(address client, bool depositBlacklist, bool withdrawalBlacklist) public onlyManager {
        if (isDepositBlacklisted(client) != depositBlacklist || isWithdrawalBlacklisted(client) != withdrawalBlacklist) {
            _depositBlacklist[client] = depositBlacklist;
            _withdrawalBlacklist[client] = withdrawalBlacklist;
            emit BlacklistChanged(client, isDepositBlacklisted(client), isWithdrawalBlacklisted(client));
        }
    }
    
    function multiSetBlacklist(address[] memory clients, bool[] memory depositBlacklists, bool[] memory withdrawalBlacklists) public onlyManager {
        require(clients.length == depositBlacklists.length && clients.length == withdrawalBlacklists.length);
        for (uint256 i = 0; i < clients.length; i++) {
            setBlacklist(clients[i], depositBlacklists[i], withdrawalBlacklists[i]);
        }
    }

    function depositFeeRateOf(address token) public view returns (uint256) {
        return _depositFeeRates[token];
    }    

    function withdrawalFeeRateOf(address token) public view returns (uint256) {
        return _withdrawalFeeRates[token];
    }    

    function setFeeRate(address token, uint256 depositFeeRate, uint256 withdrawalFeeRate) public onlyManager {
        if (depositFeeRateOf(token) != depositFeeRate || withdrawalFeeRateOf(token) != withdrawalFeeRate) {
            _depositFeeRates[token] = depositFeeRate;
            _withdrawalFeeRates[token] = withdrawalFeeRate;
            emit FeeRateChanged(token, depositFeeRateOf(token), withdrawalFeeRateOf(token));
        }
    }
    
    function multiSetFeeRate(address[] memory tokens, uint256[] memory depositFees, uint256[] memory withdrawalFees) public onlyManager {
        require(tokens.length == depositFees.length && tokens.length == withdrawalFees.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            setFeeRate(tokens[i], depositFees[i], withdrawalFees[i]);
        }
    }

    function () payable external {
        deposit(address(0x0), msg.value);
    }

    function deposit(address token, uint256 amount) payable public {
        if (token == address(0x0)) {
            require(amount == msg.value);
        }
        else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
        require(amount > 0 && isDepositPermitted(token) && !isDepositBlacklisted(msg.sender));
        uint256 fee = calculateFee(amount, depositFeeRateOf(token));
        _setBalance(token, msg.sender, balanceOf(token, msg.sender).add(amount.sub(fee)));
        _setBalance(token, bank(), balanceOf(token, bank()).add(fee));
        emit Deposit(token, msg.sender, amount, fee, balanceOf(token, msg.sender));
    }

    function multiDeposit(address[] memory tokens, uint256[] memory amounts) payable public {
        require(tokens.length == amounts.length);
        bool etherProcessed = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            bool isEther = tokens[i] == address(0x0);
            require(!isEther || !etherProcessed);
            deposit(tokens[i], amounts[i]);
            if (isEther) {
                etherProcessed = true;
            }
        }
    }

    function withdraw(address token, uint256 amount) public {
        require(amount > 0 && isWithdrawalPermitted(token) && !isWithdrawalBlacklisted(msg.sender) && balanceOf(token, msg.sender) >= amount);
        uint256 fee = calculateFee(amount, withdrawalFeeRateOf(token));
        if (token == address(0x0)) {    
            msg.sender.transfer(amount - fee);
        }
        else {
            IERC20(token).safeTransfer(msg.sender, amount - fee);
        }
        _setBalance(token, msg.sender, balanceOf(token, msg.sender).sub(amount));
        _setBalance(token, bank(), balanceOf(token, bank()).add(fee));
        emit Withdrawal(token, msg.sender, amount, fee, balanceOf(token, msg.sender));
    }

    function multiWithdraw(address[] memory tokens, uint256[] memory amounts) public {
        require(tokens.length == amounts.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            withdraw(tokens[i], amounts[i]);
        }
    }

    function transfer(address token, address from, address to, uint256 amount, uint256 fromFeeRate, uint256 toFeeRate) public onlyManager {
        uint256 fromFee = calculateFee(amount, fromFeeRate);
        uint256 toFee = calculateFee(amount, toFeeRate);
        require (amount > 0 && balanceOf(token, from) >= amount.add(fromFee));
        _setBalance(token, from, balanceOf(token, from).sub(amount.add(fromFee)));
        _setBalance(token, to, balanceOf(token, to).add(amount.sub(toFee)));
        _setBalance(token, bank(), balanceOf(token, bank()).add(fromFee).add(toFee));
        emit Transfer(token, from, to, amount, fromFee, toFee);
    }

    function multiTransfer(address[] memory tokens, address[] memory froms, address[] memory tos, uint256[] memory amounts, uint256[] memory fromFeeRates, uint256[] memory toFeeRates) public onlyManager {
        require (tokens.length == froms.length && tokens.length == tos.length && tokens.length == amounts.length && tokens.length == fromFeeRates.length && tokens.length == toFeeRates.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            transfer(tokens[i], froms[i], tos[i], amounts[i], fromFeeRates[i], toFeeRates[i]);
        }
    }

    function calculateFee(uint256 amount, uint256 feeRate) public pure returns (uint256) {
        return amount.mul(feeRate).div(1 ether);
    }
}