//SourceUnit: defiRoiOnTron.sol

pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address payable internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Standard TRC20 token
 */
contract TRC20 is ITRC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal {
        require(account != address(0), "TRC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "TRC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

/**
 * @title ApproveAndCall Interface.
 * @dev ApproveAndCall system allows to communicate with smart-contracts.
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint amount, address token, bytes calldata extraData) external;
}

/**
 * @title The Token contract.
 */
contract Token is TRC20, Ownable {

    // registered contracts (to prevent loss of token via transfer function)
    mapping (address => bool) private _contracts;

    /**
      * @dev constructor function that is called once at deployment of the contract.
      */
    constructor() public {
        _name = "Defi Token";
        _symbol = "DFT";
        _decimals = 6;
    }

    /**
    * @dev Allows to send tokens (via Approve and TransferFrom) to other smart-contract.
    * @param spender Address of smart contracts to work with.
    * @param amount Amount of tokens to send.
    * @param extraData Any extra data.
    */
    function approveAndCall(address spender, uint amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    /**
     * @dev modified transfer function that allows to safely send tokens to smart-contract.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;
    }

    /**
     * @dev Allows to register other smart-contracts (to prevent loss of tokens via transfer function).
     * @param account Address of smart contracts to work with.
     */
    function registerContract(address account) external onlyOwner {
        require(_isContract(account), "InvestingToken: account is not a smart-contract");
        _contracts[account] = true;
    }

    /**
     * @dev Allows to unregister registered smart-contracts.
     * @param account Address of smart contracts to work with.
     */
    function unregisterContract(address account) external onlyOwner {
        require(isRegistered(account), "InvestingToken: account is not registered yet");
        _contracts[account] = false;
    }

    /**
     * @return true if the address is registered as contract
     * @param account Address to be checked.
     */
    function isRegistered(address account) public view returns (bool) {
        return _contracts[account];
    }

    /**
     * @return true if `account` is a contract.
     * @param account Address to be checked.
     */
    function _isContract(address account) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

/**
 * @title The InvestingToken contract.
 */
contract DefiRoiOnTron is Token {

    uint public startTime;
    uint public startPrice = 10 * 1000000; // trx per token

    uint public adminPercent = 10;
    uint public referrerPercent = 5;
    uint public increasePercent = 4;
    uint public increaseInterval = 1 days;

    uint public totalReferralRewards;
    uint public totalInvestors;

    mapping (address => User) public users;
    struct User {
        bool active;
        address referrer;
        uint totalInvited;
        uint totalEarned;
    }

    constructor() public {
    }

    function distribution(address[] memory recipients, uint[] memory amounts, uint startIndex) public onlyOwner {
        require(startTime == 0, "Only before start");
        require(recipients.length == amounts.length, "Arrays are not equal");

        uint i = startIndex;
        for (i; i < recipients.length; i++) {
            require(amounts[i] > 0, 'Zero amount was met');

            _mint(recipients[i], amounts[i]);
        }
    }

    function reset() public onlyOwner {
        require(address(this).balance <= 100 * 1000000, "Only if balance is less than 100 trx");

        startTime = 0;
    }

    function buy(address referrer) public payable {
        require(msg.value > 0, "Send TRX please");

        if (startTime == 0) {
            startTime = block.timestamp;
        }

        User storage user = users[msg.sender];

        (_owner.send(msg.value.mul(adminPercent).div(100)));

        if (user.referrer == address(0) && users[referrer].active && referrer != msg.sender) {
            user.referrer = referrer;
            users[referrer].totalInvited += 1;
        }

        if (!user.active) {
            user.active = true;
            totalInvestors++;
        }

        uint tokenAmount = trxToToken(msg.value);
        _mint(msg.sender, tokenAmount);

        if (user.referrer != address(0)) {
            tokenAmount = tokenAmount.mul(referrerPercent).div(100);
            _mint(user.referrer, tokenAmount);

            users[user.referrer].totalEarned = users[user.referrer].totalEarned.add(tokenAmount);
            totalReferralRewards = totalReferralRewards.add(tokenAmount);
        }
    }

    function transfer(address to, uint value) public returns(bool) {
        if (to == address(this)) {
            sell(value);
        } else {
            super.transfer(to, value);
        }

        return true;
    }

    function sell(uint tokenAmount) public {
        require(tokenAmount > 0, "Specify the token amount to sell");

        uint trxAmount = tokenToTrx(tokenAmount);
        _burn(msg.sender, tokenAmount);
        (msg.sender.send(trxAmount));
    }

    function getUserReferrer(address account) public view returns(address) {
        return users[account].referrer;
    }

    function getUserRefInfo(address account) public view returns(uint totalInvited, uint totalEarned) {
        return (users[account].totalInvited, users[account].totalEarned);
    }

    function getBuyPrice() public view returns(uint) {
        if (startTime != 0) {
            return startPrice.add(startPrice.mul(increasePercent).mul(block.timestamp.sub(startTime)).div(100).div(increaseInterval));
        } else {
            return startPrice;
        }
    }

    function getSellPrice() public view returns(uint) {
        return getBuyPrice().mul(90).div(100);
    }

    function trxToToken(uint trxAmount) public view returns(uint) {
        return trxAmount.mul(1000000).div(getBuyPrice());
    }

    function tokenToTrx(uint tokenAmount) public view returns(uint) {
        return tokenAmount.mul(getSellPrice()).div(1000000);
    }
}