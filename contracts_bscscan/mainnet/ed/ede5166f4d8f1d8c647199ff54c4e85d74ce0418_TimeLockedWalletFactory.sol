// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25;

import "./TimeLockedWallet.sol";

contract TimeLockedWalletFactory {
    
    address _owner;
    
    constructor() {
        _owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    
    //Maps all created Lockers to creators
    mapping(address => address[]) public wallets;
    mapping(address => address) public lockerToOwner;
    
    
    //Returns all the Lockers created by a user
    function getWallets(address _user) public view returns(address[] memory) {
        address[] storage userLockers = wallets[_user];
    }
    
    //Creates a new locker as a subcontract and assigns an owner, a target token and a lock timestamp.
    function newTimeLockedWallet (address _LockTarget, uint256 _unlockDate, address _beneficiary) payable public returns(address payable wallet) {
        TimeLockedWallet _wallet = new TimeLockedWallet(_LockTarget, _beneficiary, address(this), _unlockDate);
        wallet = payable(_wallet);
        wallets[_beneficiary].push(wallet);
        lockerToOwner[wallet] = payable(_beneficiary);
        wallet.transfer(msg.value);
        emit Created(wallet, _beneficiary, address(this),block.timestamp, _unlockDate, msg.value);
    }
    //Calls the withdrawtokens function from a subcontract through the main contract
    function withdraw_tokens(address payable locker) public {
        require(msg.sender == lockerToOwner[locker]);
        TimeLockedWallet _userLocker = TimeLockedWallet(locker);
        _userLocker.withdrawTokens();
    }
    
    function harakiri() public onlyOwner {
        selfdestruct(payable(_owner));
    }
    
    event Created (address wallet, address owner, address factory, uint createdAt, uint unlockDate, uint amount);
    
    
    
}