/**
 *Submitted for verification at polygonscan.com on 2021-08-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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

interface IYieldManager {
    function getCurrentYieldPercentage() external pure returns(uint);
    function withdrawYield(uint256 _amount, address _recipient) external;
    function withdrawDeposit(uint256 _amount, address _recipient) external;
}

contract UltraFaucet is Ownable
{
    event NewDeposit(uint date,address sender,uint amount);
    event NewWithdrawal(uint date,address withdrawer,uint yield);
    event SpotsOpened(uint date,uint newSpots,uint availableSpots);

    mapping (address => Holder) public Account;

    IYieldManager private _yieldContract;
    address private _yieldContractAddress;
    
    uint public SpotsLeft = 100;
    
    struct DepositLog {uint256 transactionTime;uint256 lastCollection;uint256 amount;}
    struct Holder {uint256 balance;DepositLog[] deposits;}
    
    constructor() {}
    receive() external payable{}
    
    function Deposit() public payable {
        Holder storage account = Account[msg.sender];
        require(SpotsLeft > 0, "There are no spots left.");
        if(account.deposits.length == 0)
            SpotsLeft--;
        DepositLog memory log;
        log.transactionTime = block.timestamp;
        log.amount = msg.value;
        log.lastCollection = block.timestamp;
        account.deposits.push(log);
        payable(_yieldContractAddress).transfer(msg.value);
        account.balance += msg.value;
        emit NewDeposit(block.timestamp, msg.sender, msg.value);
    }
    
    function CollectYield() public {
        Holder storage account = Account[msg.sender];
        uint256 yieldToPay = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            if(dep.lastCollection + 1 days <= block.timestamp)
            {
                uint daysSinceCollection = (block.timestamp - dep.lastCollection) / 60 / 60 / 24;
                dep.lastCollection = block.timestamp;
                yieldToPay += ((account.deposits[i].amount / 100) * _yieldContract.getCurrentYieldPercentage())*daysSinceCollection;    
            }
        }
        require(yieldToPay > 0, "No deposits fulfill requirements for yield payments.");
        _yieldContract.withdrawYield(yieldToPay, msg.sender);
        emit NewWithdrawal(block.timestamp, msg.sender, yieldToPay);
    }

    function Withdraw(uint256 _amount, bool _acceptEarlyWithdrawalTax)
    public
    {
        Holder memory account = Account[msg.sender];
        require(account.balance >= _amount, "You're trying to withdraw more than your deposited balance.");
        uint256 balanceAvailableForWithdrawal = 0;
        uint256 withdrawalTax = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            if(dep.transactionTime + 10 days <= block.timestamp || _acceptEarlyWithdrawalTax)
            {
                balanceAvailableForWithdrawal += dep.amount;
                if(dep.transactionTime + 10 days > block.timestamp)
                {
                    uint256 tax = (dep.amount / 100) * 10;
                    withdrawalTax += tax;
                }
            }
        }
        require(balanceAvailableForWithdrawal <= _amount, "Not enough withdrawable balance.");
        account.balance -= balanceAvailableForWithdrawal + withdrawalTax;
        _yieldContract.withdrawDeposit(_amount-withdrawalTax, msg.sender);
    }
    
    function getDeposits() public view returns(DepositLog[] memory) 
    {
        return Account[msg.sender].deposits;
    }
    
    function getBalance() public view returns(uint256){
        return Account[msg.sender].balance;
    }
    
    // Sets the address of the YieldManager
    function setYieldContract(address payable contractAddress) public onlyOwner {
        _yieldContract = IYieldManager(contractAddress);
        _yieldContractAddress = contractAddress;
    }
    
    // Called to add more open spots to the contract to allow for growth.
    function openMoreSpots(uint _spotsToAdd) public onlyOwner {
        SpotsLeft += _spotsToAdd;
        emit SpotsOpened(block.timestamp, _spotsToAdd, SpotsLeft);
    }

    fallback() 
    external
    payable
    {
        Deposit();
    }
}