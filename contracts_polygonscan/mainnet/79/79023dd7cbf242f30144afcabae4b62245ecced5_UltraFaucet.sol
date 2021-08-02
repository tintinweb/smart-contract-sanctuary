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
    function withdrawYield(uint256 _amount, address _recipient) external payable;
    function transferOwnership(address newOwner) external;
    function withdrawDeposit(uint256 _amount, address _recipient) external payable;
}

contract UltraFaucet is Ownable
{
    event NewDeposit(uint date,address sender,uint amount);
    event NewWithdrawal(uint date,address withdrawer,uint yield,bool taxAccepted);
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
        emit NewWithdrawal(block.timestamp, msg.sender, yieldToPay,false);
    }

    function Withdraw(uint256 _amount, bool _acceptEarlyWithdrawalTax)
    public
    {
        Holder storage account = Account[msg.sender];
        require(account.balance >= _amount, "You're trying to withdraw more than your deposited balance.");
        uint256 balanceAvailableForWithdrawal = 0;
        uint256 withdrawalTax = 0;
        for(uint i = 0; i < account.deposits.length; i++) {
            DepositLog memory dep = account.deposits[i];
            uint256 missingAmount = _amount-balanceAvailableForWithdrawal;
            if((dep.transactionTime + 10 days <= block.timestamp || _acceptEarlyWithdrawalTax) && missingAmount > 0)
            {
                // If it hasn't been 10 days since the deposit was made, and we haven't found enough eligible funds - apply tax.
                if(dep.transactionTime + 10 days > block.timestamp)
                {
                    if(dep.amount >= missingAmount) // If the amount available from this deposit is larger than missing amount, tax only the part missing.
                        withdrawalTax += (missingAmount / 100) * 10;
                    else if(dep.amount < missingAmount) // If it is lower, tax the whole amount and move on to next.
                        withdrawalTax += (dep.amount / 100) * 10;
                }
                    
                balanceAvailableForWithdrawal += dep.amount > missingAmount ? missingAmount : dep.amount;
            }
        }
        require(balanceAvailableForWithdrawal >= _amount, "Not enough withdrawable balance.");
        uint256 newBalance = account.balance-_amount;
        account.balance = newBalance;
        _yieldContract.withdrawDeposit(_amount-withdrawalTax, msg.sender);
        emit NewWithdrawal(block.timestamp, msg.sender, _amount,_acceptEarlyWithdrawalTax);
    }
    
    function getDeposits() public view returns(DepositLog[] memory) 
    {
        Holder storage account = Account[msg.sender];
        return account.deposits;
    }
    
    function getBalance() public view returns(uint256){
        Holder storage account = Account[msg.sender];
        return account.balance;
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
    }
}