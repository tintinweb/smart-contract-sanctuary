/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

/**
 * Simple staking contract with delayed withdrawals.
 * https://risingsun.finance/
 */
contract InfluenceStaking is Auth {
    address public token;
    uint public lockPeriod = 7 days;
    mapping(address => Balance) public balances;
    address[] public addresses; // contains duplicates
    mapping(address => Withdrawal[]) public withdrawals;

    struct Balance {
        uint128 total;
        uint128 pending;    // allow viewing pending withdrawals with O(1)
    }

    /**
     * Valid state transitions:
     * Start:
     * Pending => Cancelled
     * Pending => Done
     */
    enum WithdrawalState {
        Pending,
        Cancelled,
        Done
    }

    struct Withdrawal {
        uint56 unlockTimestamp;
        uint128 amount;
        WithdrawalState state;
    }

    event Deposited(address indexed staker, uint amount);
    event WithdrawStarted(address indexed staker, uint amount, uint index);
    event WithdrawCancelled(address indexed staker, uint amount, uint index);
    event WithdrawDone(address indexed staker, uint amount, uint index);

    constructor(address _token) Auth(msg.sender) {
        token = _token;
    }

    /**
     * Deposit tokens to start or increase a balance.
     */
    function deposit(uint128 _amount) external {
        IBEP20 t = IBEP20(token);
        require(t.balanceOf(msg.sender) >= _amount, "You do not own enough tokens");

        incrementBalance(_amount, 0);
        addresses.push(msg.sender);

        // INTERACTIONS
        require(t.transferFrom(msg.sender, address(this), _amount), "We didn't receive the tokens");

        emit Deposited(msg.sender, _amount);
    }

    /**
     * Start a delayed withdrawal.
     */
    function startWithdraw(uint128 _amount) external {
        Balance memory balance = balances[msg.sender];
        require(_amount <= balance.total - balance.pending, "Not enough balance");
        Withdrawal[] storage _withdrawals = withdrawals[msg.sender];
        uint index = _withdrawals.length;

        _withdrawals.push(Withdrawal({
            unlockTimestamp: uint56(block.timestamp + lockPeriod),
            amount: _amount,
            state: WithdrawalState.Pending
        }));

        incrementBalance(0, _amount);

        emit WithdrawStarted(msg.sender, _amount, index);
    }

    /**
     * Complete a delayed withdrawal and return tokens to despositor.
     */
    function completeWithdraw(uint index) external {
        IBEP20 t = IBEP20(token);
        Withdrawal memory withdrawal = withdrawals[msg.sender][index];
        require(block.timestamp > withdrawal.unlockTimestamp, "Withdrawal is not unlocked");
        require(withdrawal.state == WithdrawalState.Pending, "Withdrawal state not pending");

        // update storage
        withdrawals[msg.sender][index].state = WithdrawalState.Done;
        decrementBalance(withdrawal.amount, withdrawal.amount);

        // INTERACTIONS
        require(t.transfer(msg.sender, withdrawal.amount), "Failed to transfer tokens");

        emit WithdrawDone(msg.sender, withdrawal.amount, index);
    }

    /**
     * Cancel a delayed withdrawal. This can be done at any time to a pending withdrawal.
     */
    function cancelWithdraw(uint index) external {
        Withdrawal memory withdrawal = withdrawals[msg.sender][index];
        require(withdrawal.state == WithdrawalState.Pending, "Withdrawal state not pending");

        // update storage
        withdrawals[msg.sender][index].state = WithdrawalState.Cancelled;
        decrementBalance(0, withdrawal.amount);

        emit WithdrawCancelled(msg.sender, withdrawal.amount, index);
    }

    /**
     * Existing items on the array are ordered and never changed.
     */
    function getAddresses(uint start, uint end) public view returns (address[] memory) {
        address[] memory _addresses = new address[](end - start);
        for (uint i = start; i < end; i++) {
            _addresses[i] = addresses[i];
        }
        return _addresses;
    }

    function getAddressesLength() external view returns (uint) {
        return addresses.length;
    }

    function getAddress(uint index) external view returns (address) {
        return addresses[index];
    }

    function getWithdrawals(address user) external view returns (Withdrawal[] memory) {
        return withdrawals[user];
    }

    function getWithdrawalsLength(address user) external view returns (uint) {
        return withdrawals[user].length;
    }

    /**
     * Set lock period for withdrawing.
     */
    function setLockPeriod(uint period) external authorized {
        lockPeriod = period;
    }

    /**
     * Retreive stuck tokens.
     */
    function retrieveTokens(address _token, uint amount) external authorized {
        require(IBEP20(_token).transfer(msg.sender, amount), "Transfer failed");
    }

    /**
     * Retreive stuck BNB. 
     */
    function retrieveBNB(uint amount) external authorized {
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to retrieve BNB");
    }

    function incrementBalance(uint128 _total, uint128 _pending) internal {
        Balance memory balance = balances[msg.sender];
        balances[msg.sender] = Balance({
            total: balance.total + _total,
            pending: balance.pending + _pending
        });
    }

    function decrementBalance(uint128 _total, uint128 _pending) internal {
        Balance memory balance = balances[msg.sender];
        balances[msg.sender] = Balance({
            total: balance.total - _total,
            pending: balance.pending - _pending
        });
    }
}