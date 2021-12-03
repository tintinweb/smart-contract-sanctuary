/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract ReferralContract{
    address operator;
    address owner;

    constructor() {
        owner = msg.sender;
        Users[address(0)].exist = true;
    }

    struct User{
        address referrer;
        bool isRefferBonusPaid;
        address[] refferals;
        uint totalRefferalRewards;
        bool exist;
    }

    mapping(address => User) Users;

    event operatorChanged(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event registered(address indexed User,address indexed Refferer);
    event ReferalPaid(address indexed User,address indexed Refferer,uint amount);   
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "OperatorRole: caller does not have the Operator role");
        _;
    }

    /** change the OperatorRole address
        @param newOperator :trade address 
    */

    function changeOperator(address newOperator) public onlyOwner returns(bool) {
        require(newOperator != address(0), "Operator: new operator is the zero address");
        emit operatorChanged(operator, newOperator);
        operator = newOperator;
        return true;
    }

    /** change the Ownership from current owner to newOwner address
    @param newOwner : newOwner address 
    */

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
        return true;
    }

    function register(address referrerAddress) external{
        require(Users[referrerAddress].exist,"Refferer not exists");
        if(referrerAddress == address(0)) {
            Users[msg.sender].isRefferBonusPaid = true;
        }
        Users[msg.sender].referrer = referrerAddress;
        Users[referrerAddress].refferals.push(msg.sender);
        Users[msg.sender].exist = true;
        emit registered(msg.sender, referrerAddress);
    }


    function getRefferer(address _user) external view returns(address){
        return Users[_user].referrer;
    }

    function isRefferBonusPaid(address _user) view external returns(bool){
        return Users[_user].isRefferBonusPaid;
    }

    function updateUserDetails(address account,uint amount) external onlyOperator {
        address refferer = Users[account].referrer;
        Users[account].isRefferBonusPaid = true;
        Users[refferer].totalRefferalRewards += amount;
        emit ReferalPaid(account,refferer,amount); 
    }

    function getRefferals(address _user) external view returns(address[] memory){
        return Users[_user].refferals;
    }
}