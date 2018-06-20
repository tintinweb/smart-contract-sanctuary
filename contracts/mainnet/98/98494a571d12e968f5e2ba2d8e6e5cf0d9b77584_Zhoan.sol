pragma solidity ^0.4.24;

contract Zhoan {
    string public token_name;
    
    //contract admin&#39;s address
    address private admin_add;
    //decimal setting
    uint8 private decimals = 18;
    //new user can get money when first register
    uint private present_money=0;
    //the circulation limit of token
    uint256 private max_circulation;
    
    //transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    //save the msg of contract_users
    mapping(address => uint) public contract_users;
    
    // constructor
    constructor(uint limit,string symbol) public {
        admin_add=msg.sender;
        max_circulation=limit * 10 ** uint256(decimals);
        contract_users[admin_add]=max_circulation;
        token_name = symbol;
    }
    
    //for admin user to change present_money
    function setPresentMoney (uint money) public{
        address opt_user=msg.sender;
        if(opt_user == admin_add){
            present_money = money;
        }
    }
    
    //add new user to contract
    function addNewUser(address newUser) public{
        address opt_user=msg.sender;
        if(opt_user == admin_add){
            transfer_opt(admin_add,newUser,present_money);
        }
    }
    
    //transfer action between users
    function userTransfer(address from,address to,uint256 value) public{
        transfer_opt(from,to,value);
    }
    
    //admin account transfer money to users
    function adminSendMoneyToUser(address to,uint256 value) public{
        address opt_add=msg.sender;
        if(opt_add == admin_add){
            transfer_opt(admin_add,to,value);
        }
    }
    
    //burn account hold money
    function burnAccountMoeny(address add,uint256 value) public{
        address opt_add=msg.sender;
        require(opt_add == admin_add);
        require(contract_users[add]>value);
        
        contract_users[add]-=value;
        max_circulation -=value;
    }

    //util for excute transfer action
    function transfer_opt(address from,address to,uint value) private{
        //sure target no be 0x0
        require(to != 0x0);
        //check balance of sender
        require(contract_users[from] >= value);
        //sure the amount of the transfer is greater than 0
        require(contract_users[to] + value >= contract_users[to]);
        
        uint previousBalances = contract_users[from] + contract_users[to];
        contract_users[from] -= value;
        contract_users[to] += value;
        
        emit Transfer(from,to,value);
        
        assert(contract_users[from] + contract_users[to] == previousBalances);
    }
    
    //view balance
    function queryBalance(address add) public view returns(uint){
        return contract_users[add];
    }
    
    //view surplus
    function surplus() public view returns(uint,uint){
        return (contract_users[admin_add],max_circulation);
    }
}