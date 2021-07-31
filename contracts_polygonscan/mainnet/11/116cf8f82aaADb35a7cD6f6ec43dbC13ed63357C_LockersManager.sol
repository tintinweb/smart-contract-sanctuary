/**
 *Submitted for verification at polygonscan.com on 2021-07-31
*/

/*
PolyFOMO is "DeFi Staking Rewards" on Polygon Chain, three dimensional crypto currency that generates you MATIC just by holding the tokens!
Website: https://polyfomo.com
Telegram: https://t.me/PolygonFOMO
*/

pragma solidity ^0.4.26;

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function balanceOf(address _customerAddress) view external returns(uint256);
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
}

contract LockersManager {
    event CreatedLockers(address indexed owner, address indexed strongHand);
    
    mapping (address => address) public strongHands;
    
    function isGodlyChad() public view returns (bool) {return strongHands[msg.sender] != address(0);}
    
    function myLockers() external view returns (address) {  
        require(isGodlyChad(), "You are not a Strong Hand Investor!");
        return strongHands[msg.sender];
    }
    
    function create(uint256 _unlockAfterNDays) public {
        require(!isGodlyChad(), "You are already a Strong Hand Investor!");
        require(_unlockAfterNDays > 0);
        
        address owner = msg.sender;
        strongHands[owner] = new Lockers(owner, _unlockAfterNDays);
        emit CreatedLockers(owner, strongHands[owner]);
    }
}

contract Lockers {
    HourglassInterface constant PolyFOMOContract = HourglassInterface(0x9F8bFf0a3F355E57fc3D488771489ae9da302A47);
    
    address public developer = 0x4C01389Cf4b273D885638fdEBB9ff37303cbE752;
    
    address public owner;
    uint256 public creationDate;
    uint256 public unlockAfterNDays;
    
    modifier timeLocked() {
        require(now >= creationDate + unlockAfterNDays * 1 days);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor(address _owner, uint256 _unlockAfterNDays) public {
        owner = _owner;
        unlockAfterNDays =_unlockAfterNDays;
        creationDate = now;
    }
    
    function() public payable {}
    
    function isLocked() public view returns(bool) {return now < creationDate + unlockAfterNDays * 1 days;}
    function lockedUntil() external view returns(uint256) {return creationDate + unlockAfterNDays * 1 days;}
    
    function extendLock(uint256 _howManyDays) external onlyOwner {
        uint256 newLockTime = unlockAfterNDays + _howManyDays;
        require(newLockTime > unlockAfterNDays);
        unlockAfterNDays = newLockTime;
    }
    
    function withdraw() external onlyOwner {owner.transfer(address(this).balance);}
    function reinvest() external onlyOwner {PolyFOMOContract.reinvest();}
    function transfer(address _toAddress, uint256 _amountOfTokens) external timeLocked onlyOwner returns(bool) {return PolyFOMOContract.transfer(_toAddress, _amountOfTokens);}
    
    function buy() external payable onlyOwner {PolyFOMOContract.buy.value(msg.value)(developer);}
    function buyWithBalance() external onlyOwner {PolyFOMOContract.buy.value(address(this).balance)(developer);}

    function balanceOf() external view returns(uint256) {return PolyFOMOContract.balanceOf(address(this));}
    function dividendsOf() external view returns(uint256) {return PolyFOMOContract.myDividends(true);}
    
    function withdrawDividends() external onlyOwner {
        PolyFOMOContract.withdraw();
        owner.transfer(address(this).balance);
    }
    
    function sell(uint256 _amount) external timeLocked onlyOwner {
        PolyFOMOContract.sell(_amount);
        owner.transfer(address(this).balance);
    }
}