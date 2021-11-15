/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// File: contracts/utils/Access.sol

// SPDX-License-Identifier: MIT
/*

            888      .d88888b.   .d8888b.
            888     d88P" "Y88b d88P  Y88b
            888     888     888 Y88b.
            888     888     888  "Y888b.
            888     888     888     "Y88b.
            888     888     888       "888
            888     Y88b. .d88P Y88b..d88P
            88888888 "Y88888P"   "Y8888P"


*/

pragma solidity ^0.8.0;


contract Access {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able,address indexed owner);

    constructor(){
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }
    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0),"zero address");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }
    function becomeOwner() external {
        require(msg.sender == _pendingOwner,"not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }
    function paused() public view virtual returns (bool) {
        return _pause;
    }
    function setPaused(bool p) external onlyOwner{
        _pause = p;
    }


    modifier checkContractCall() {
        require(contractCallable() || msg.sender == tx.origin, "non contract");
        _;
    }
    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }
    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able,_owner);
    }

}

// File: contracts/InvitationV1.sol

pragma solidity ^0.8.0;


contract InvitationV1 is Access {

    struct Account {
        address inviter;
        address[] invitees;
        uint bnbBonus;
        uint losBonus;
    }
    mapping(address=>Account) public accounts;
    address public templar;

    event Bind(address indexed inviter, address indexed invitee);
    event Bonus(address indexed inviter, address indexed invitee, uint bnbAmount, uint losAmount);

    constructor(){
        setPendingOwner(address(0xc074c1aBC3fE8F49FB3597c16a1d52c5Ce5d8601));
    }

    function bind(address inviter) external checkContractCall checkPaused {

        require(inviter != address(0), "not zero account");
        require(inviter != msg.sender, "can not be yourself");
        require(accounts[msg.sender].inviter == address(0), "already bind");
        accounts[msg.sender].inviter = inviter;
        accounts[inviter].invitees.push(msg.sender);
        emit Bind(inviter, msg.sender);
    }

    function bonus(address inviter, address invitee, uint bnbAmount, uint losAmount) external {

        require(msg.sender == templar, "not templar");
        accounts[inviter].bnbBonus += bnbAmount;
        accounts[inviter].losBonus += losAmount;
        emit Bonus(inviter,invitee,bnbAmount,losAmount);
    }

    function setTemplar(address t) external onlyOwner {
        templar = t;
    }

    function getInvitation(address account) external view returns (address inviter,uint bnbBonus, uint losBonus, address[] memory invitees) {
        Account memory info = accounts[account];
        return (info.inviter, info.bnbBonus, info.losBonus, info.invitees);
    }

    function getInviter(address account) view external returns(address){
        return accounts[account].inviter;
    }
}