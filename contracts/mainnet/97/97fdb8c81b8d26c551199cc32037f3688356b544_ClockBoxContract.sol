/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.8.1;

contract ClockBoxContract {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    // lockedBalances of sender
    mapping(address => uint256) internal _lockedBalances;

    mapping(bytes32 => Keeper) internal keepers;

    uint256 internal feePercentage;

    // address to pay fee to
    address payable internal feeAddress;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public admin;

    struct Keeper {
        address sender;
        uint256 value;
        address recipient;
        uint256 dateLocked;
        uint256 lockUntill;
    }

    event NewKeeper(
        address indexed sender,
        uint256 value,
        address indexed recipient,
        uint256 dateLocked, // block.timestamp
        uint256 indexed lockUntill, // timestamp (millisecond)
        bytes32 hash
    );

    event Transfer(address from, address to, uint256 value);

    event Approval(address from, address recipient, uint256 amount);

    constructor(address _admin, address _feeAddress) {
        _name = "ClockBox";
        _symbol = "CLOCK";
        _decimals = 16;
        admin = _admin;
        mint(100000000 * 10**decimals());

        // 0.25% of value stored in the contract
        feePercentage = 25;
        feeAddress = payable(_feeAddress);
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// Transfer value from sender to recipient
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    /// Returns the amount of value a spender is allowed to spend on behalf of the owner
    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }

    // Set amount that a spender is allowed to spend on behalf of the sender
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    /// Allows spender transfer from owner using allowance
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance + addedValue);
        return true;
    }

    // Create new token
    function mint(uint256 _amount) public onlyAdmin returns (bool) {
        _mint(msg.sender, _amount);

        return true;
    }

    // destroy tokens
    function burn(uint256 _amount) public onlyAdmin returns (bool) {
        _burn(msg.sender, _amount);

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /// Set amount a spender can spend on behalf of the owner
    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0), "Approve from zero address");
        require(spender != address(0), "Approve to zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Transfering from zero address");
        require(recipient != address(0), "Transfering to zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insuffiencet balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /// create new tokens and emit event from the zero address
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /// Destroy tokens - Send amount
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /*
        ## Overview

        Accept ETH from users, deduct 0.25% from the value sent
        store the new amount in the smart contract (vault).
        Emits a NewKeeper event for every new storage to the vault
        When the lock time elapses, the stored value is sent to the intended recipient
        The withdraw function is called by the dapp and this is trigger by outside schecdular
        A `Transfer` event is also emited after every withdrawal

        The smart contract is uses an owner priviliage to prevent anyone from sending ETH out.
        Only the smart contract creator has priviliage to send ETH out.
    */

    // recieves ether from recipient
    function vault(address _recipient, uint256 _lockTime) external payable {
        uint256 fee = calculateFee(msg.value);
        uint256 value = deductFeeFromValue(msg.value);
        _lockedBalances[msg.sender] += value;

        bytes32 hash = makeHash(msg.sender, _recipient, _lockTime);

        // register keeper
        keepers[hash] = (Keeper(msg.sender, value, _recipient, block.timestamp, _lockTime));

        feeAddress.transfer(fee);
        emit NewKeeper(msg.sender, value, _recipient, block.timestamp, _lockTime, hash);
    }

    function calculateFee(uint256 _valueSent) public view largerThen10000wie(_valueSent) returns (uint256) {
        uint256 fee = (_valueSent * feePercentage) / 10000;

        return fee;
    }

    function deductFeeFromValue(uint256 _valueSent) public view largerThen10000wie(_valueSent) returns (uint256) {
        uint256 _value = _valueSent - calculateFee(_valueSent);

        return _value;
    }

    function makeHash(
        address _sender,
        address _recipient,
        uint256 _lockTime
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(abi.encode(_sender, _recipient, _lockTime));

        return hash;
    }

    /// Returns sender locked balance
    function balanceOfInValut() external view returns (uint256) {
        return _lockedBalances[msg.sender];
    }

    /// Returns balance in the vault after fee has been deducted
    function balanceOfvault() external view returns (uint256) {
        return address(this).balance;
    }

    /// Returns  the balnce of the address fees are been paid to
    /// restricted to onlyOwner
    function balanceOfFeeAddress() external view onlyAdmin returns (uint256) {
        return address(feeAddress).balance;
    }

    /// Returns the record of a keeper
    function getKeeper(bytes32 _hash) external view returns (Keeper memory) {
        return keepers[_hash];
    }

    /// withdraw from the vault. Restricted to onlyOwner
    function withdraw(bytes32 _hash) external onlyAdmin returns (bool) {
        _withdrawFromvault(_hash);

        return true;
    }

    // transfer ether from this smart contract to recipient
    function _withdrawFromvault(bytes32 _hash) internal returns (bool) {
        address to = keepers[_hash].recipient;
        address payable recipient = payable(to);
        address from = keepers[_hash].sender;
        uint256 value = keepers[_hash].value;

        // delete the record from valut - prevent double withdrawal(spending)
        delete keepers[_hash];
        /// @Review: should the record be deleted or should a field be updated that it has been withdrawn??

        // transfer the value to the recipient
        recipient.transfer(value);

        emit Transfer(from, to, value);

        return true;
    }

    modifier largerThen10000wie(uint256 _value) {
        require((_value / 10000) * 10000 == _value, "Amount is too low.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only owner can perform this operation");

        _;
    }
}