/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// @author Nextrope
/// @title Ownable 
/// @custom:version 1.0.0
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 * Provides onlyOwnerOrApi modifier, which prevents function from running if it is called by other than above OR from one API code.
 * Provides onlyOwnerOrApiOrContract modifier, which prevents function from running if it is called by other than above OR one smart contract code.
 */
abstract contract Ownable {
    address public superOwnerAddr;
    address public ownerAddr;
    mapping(address => bool) public ApiAddr; // list of allowed apis
    mapping(address => bool) public ContractAddr; // list of allowed contracts

    constructor(address superOwner, address owner, address api) {
        superOwnerAddr = superOwner;
        ownerAddr = owner;
        ApiAddr[api] = true;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwnerAddr, "Access denied for this address [0].");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddr, "Access denied for this address [1].");
        _;
    }

    modifier onlyOwnerOrApi() {
        require(msg.sender == ownerAddr || ApiAddr[msg.sender] == true, "Access denied for this address [2].");
        _;
    }

    modifier onlyOwnerOrApiOrContract() {
        require(msg.sender == ownerAddr || ApiAddr[msg.sender] == true || ContractAddr[msg.sender] == true, "Access denied for this address [3].");
        _;
    }

    function setOwnerAddr(address _address) public onlySuperOwner {
        ownerAddr = _address;
    }
    
    function addApiAddr(address _address) public onlyOwner {
        ApiAddr[_address] = true;
    }

    function removeApiAddr(address _address) public onlyOwner {
        ApiAddr[_address] = false;
    }
}

/// @author Nextrope
/// @title TimeLocker - a vesting contract
/// @custom:version 1.0.3
contract TimeLocker is Ownable {

    uint public constant WITHDRAWAL_STEP = 1 days;
    uint public constant STEPS_AMOUNT = 90;
    uint public constant VAULT_LIMIT = 100;

    IERC20 public immutable token;

    uint public counter;

    struct TimeVault {
        uint initialAmount;
        uint remainingAmount;
        uint releaseTime;
    }

    mapping(address => TimeVault[]) public vaults;
    mapping(uint => address) public receivers;

    event TimeVaultDeposit(address indexed sender, address indexed receiver, uint amount, uint releaseTime);
    event TimeVaultWithdrawal(address indexed receiver, uint amount, uint indexed vaultIndex);

    constructor(address tokenContract, address superOwner, address owner, address api) Ownable(superOwner, owner, api) {
        token = IERC20(tokenContract);
        counter = 0;
    }

    function deposit(address receiver, uint amount, uint releaseTime) public onlyOwnerOrApi returns(bool success) {
        require(token.allowance(msg.sender, address(this)) >= amount, 'Not enough allowance for this receiver');
        require(vaults[receiver].length < VAULT_LIMIT, 'No more vaults possible for this receiver');
        require(amount >= STEPS_AMOUNT, 'Amount not high enough');

        TimeVault memory newVault = TimeVault(amount, amount, releaseTime);
        receivers[counter] = receiver;
        counter += 1;
        require(token.transferFrom(msg.sender, address(this), amount), 'Could not transfer tokens');
        vaults[receiver].push(newVault);
        emit TimeVaultDeposit(msg.sender, receiver, amount, releaseTime);
        success = true;
    }

    function withdraw() public returns(bool success) {
        require(vaults[msg.sender].length > 0, 'None vaults for this address');
        uint len = vaults[msg.sender].length;
        for (uint i = 0; i < len; i++){
            if (vaults[msg.sender][i].remainingAmount > 0 && vaults[msg.sender][i].releaseTime <= block.timestamp) {
                TimeVault storage vault = vaults[msg.sender][i];
                uint omegaPeriod = STEPS_AMOUNT * WITHDRAWAL_STEP;
                uint passedPeriod = block.timestamp - (vault.releaseTime);
                if (passedPeriod >= (omegaPeriod - WITHDRAWAL_STEP)) {
                    uint achievedAmount = vault.remainingAmount;
                    if(achievedAmount > 0) {
                        vault.remainingAmount = 0;
                        require(token.transfer(msg.sender, achievedAmount), 'Could not transfer tokens');
                        emit TimeVaultWithdrawal(msg.sender, achievedAmount, i);
                        success = true;
                    }
                }
                else {
                    uint stepAmount = vault.initialAmount / STEPS_AMOUNT;
                    uint takenAmount = vault.initialAmount - vault.remainingAmount;
                    uint remainingSteps = (omegaPeriod - passedPeriod) / WITHDRAWAL_STEP;
                    uint achievedAmount = (STEPS_AMOUNT - remainingSteps) * stepAmount - takenAmount;
                    if(achievedAmount > 0) {
                        vault.remainingAmount = vault.remainingAmount - achievedAmount;
                        require(token.transfer(msg.sender, achievedAmount), 'Could not transfer tokens');
                        emit TimeVaultWithdrawal(msg.sender, achievedAmount, i);
                        success = true;
                    }
                }
            }
        }
        require(success, 'Nothing to withdraw');
    }

    function nextVaultActivation() public view returns(uint foundTime) {
        require(vaults[msg.sender].length > 0, 'None vaults for this address');
        uint len = vaults[msg.sender].length;
        for(uint i = 0; i < len; i++){
            if (vaults[msg.sender][i].remainingAmount > 0) {
                if (foundTime != 0) {
                    if (vaults[msg.sender][i].releaseTime < foundTime) {
                        foundTime = vaults[msg.sender][i].releaseTime;
                    }
                } else {
                    foundTime = vaults[msg.sender][i].releaseTime;
                }
            }
        }
        require(foundTime != 0, 'No vaults activated');
    }

    function fullOpenValueForAddress(address sender) internal view returns(uint amount) {
        require(vaults[sender].length > 0, 'None vaults for this address');
        uint len = vaults[sender].length;
        for (uint i = 0; i < len; i++){
            if (vaults[sender][i].remainingAmount > 0 && vaults[sender][i].releaseTime <= block.timestamp) {
                TimeVault storage vault = vaults[sender][i];
                uint omegaPeriod = STEPS_AMOUNT * WITHDRAWAL_STEP;
                uint passedPeriod = block.timestamp - (vault.releaseTime);
                if (passedPeriod >= (omegaPeriod - WITHDRAWAL_STEP)) {
                    amount += vault.remainingAmount;
                }
                else {
                    uint stepAmount = vault.initialAmount / STEPS_AMOUNT;
                    uint takenAmount = vault.initialAmount - vault.remainingAmount;
                    uint remainingSteps = (omegaPeriod - passedPeriod) / WITHDRAWAL_STEP;
                    uint achievedAmount = (STEPS_AMOUNT - remainingSteps) * stepAmount - takenAmount;
                    amount += achievedAmount;
                }
            }
        }
    }

    function fullOpenValue() public view returns(uint amount) {
        amount = fullOpenValueForAddress(msg.sender);
    }

    function fullLockedValue() public view returns(uint amount) {
        require(vaults[msg.sender].length > 0, 'None vaults for this address');
        uint len = vaults[msg.sender].length;
        uint remainingAmount = 0;
        for (uint i = 0; i < len; i++){
            remainingAmount += vaults[msg.sender][i].remainingAmount;
        }
        uint openValue = fullOpenValueForAddress(msg.sender);
        amount = remainingAmount - openValue;
    }
}