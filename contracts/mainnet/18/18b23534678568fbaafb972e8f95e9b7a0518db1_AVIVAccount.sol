pragma solidity ^0.4.24;

contract BasicTokenInterface{
    
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX
    uint public totalSupply;
    mapping (address => uint256) internal balances;
    
    modifier checkpayloadsize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    } 
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
}


// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    event ApprovalReceived(address indexed from, uint256 indexed amount, address indexed tokenAddr, bytes data);
    function receiveApproval(address from, uint256 amount, address tokenAddr, bytes data) public{
        emit ApprovalReceived(from, amount, tokenAddr, data);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20TokenInterface is BasicTokenInterface, ApproveAndCallFallBack{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);   
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function transferTokens(address token, uint amount) public returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ManagedInterface{
    address manager;
    event ManagerChanged(address indexed oldManager, address indexed newManager);
    modifier restricted(){
        require(msg.sender == manager,"Function can only be used by manager");
        _;
    }

    //Sweep out any other ERC20 tokens that got sent to the contract, sends to the manager
    function sweepTokens(address token, address destination) public restricted {
        uint balance = ERC20TokenInterface(token).balanceOf(address(this));
        ERC20TokenInterface(token).transfer(destination,balance);
    }

    //Manager may drain the ETH on the contract
    function sweepFunds(address destination, uint amount) public restricted{
        amount = amount > address(this).balance ? address(this).balance : amount;
        address(destination).transfer(amount);
    }
    
    function setManager(address newManager) public;

}

contract ManagedContract is ManagedInterface{
    
    constructor(address creator) public{
        manager = creator;
    }

    function setManager(address newManager) public restricted{
        address oldManager = manager; 
        manager = newManager;
        emit ManagerChanged(oldManager,manager);
    }
}

library SafeMath {
    
    //Guard overflow by making 0 an impassable barrier
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        return (c >= a && c >= b) ? c : 0;
    }

    //Guard underflow by making 0 an impassable barrier
    function sub(uint a, uint b) internal pure returns (uint) {
        return (a >=b) ? (a - b): 0;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || b == 0 || c / a == b);
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(a > 0 && b > 0);
        c = a / b;
        return c;
    }
}

contract AVIVAccountInterface is ManagedInterface{
    using SafeMath for uint;
    uint verified_users;
    uint public alias_price = 100000000000000000;
    struct Account{
        string name;
        string country;
        mapping(string => byte[]) pubkeys;
        mapping(address => bool) communities;
        bool verified;
        uint donations;
    }
    
    mapping(string => address) internal names;
    mapping(address => Account) internal accounts;

    //Emitted when manager verifies account
    event AccountVerified(address user, string name, string country);

    //Emitted when user changes keys
    event KeyChanged(address user, string label, byte[] key);

    //Emitted when user joins a community
    event JoinedCommunity(string name, address community);

    //Emitted when user leaves a community
    event LeftCommunity(string name, address community);

    event DonationReceived(address sender, uint value);

    //Emitted when an alias is purchased
    event NewAlias(address user, string name);
    
    function() public payable{
        accounts[msg.sender].donations = accounts[msg.sender].donations.add(msg.value);
        emit DonationReceived(msg.sender,msg.value);
    }

    //Manager can set minimum donation price to purchase an alias
    function setAliasPrice(uint price) public;
    
    //Names can be set by anyone for a donation, manager does this for free in order to reserve names
    function addAlias(address user, string alias) public payable;

    //Only the manager can verify accounts, this is restricted in the implementation
    function verifyAccount(address holder, string name, string country) public restricted;

    //Accounts function as part of PKI, this is the PK in PKI
    function changeKeys(string label, byte[] key) public;

    //Joining a community allows the community to credit or debit your AVIV and VIP balances
    function joinCommunity(address community) public;

    //Leaving a community prevents that community from crediting or debiting your AVIV and VIP balances
    function leaveCommunity(address community) public;

    //are they part of a community
    function inCommunity(address user, address community) public view returns (bool);

     //get the name of an account
    function getName(address user) public view returns (string);

    //get the address of an account alias
    function getByAlias(string name) public view returns (address);

    //Is the account verified
    function isVerified(address user) public view returns (bool);

    //get the total of donations from a user
    function donationsFrom(address user) public view returns (uint);

}

contract AVIVAccount is ManagedContract(msg.sender), AVIVAccountInterface{
 
    //Only the manager can verify accounts
    function verifyAccount(address holder, string name, string country) public restricted{
        require((names[name] == address(0) || names[name] == holder),"NAMEINUSE");
        names[name] = holder;
        Account storage account = accounts[holder];
        account.name = name;
        account.verified = true;
        verified_users++;
        emit AccountVerified(holder, name, country);
        emit NewAlias(holder, name);
    }

    //Manager can set minimum donation price to purchase an alias
    function setAliasPrice(uint price) public restricted{
        alias_price = price;
    }    

    //Names can be set by anyone for a donation, manager does this for free in order to reserve names
    function addAlias(address user, string alias) public payable{
        if(msg.sender != manager){
            require(msg.value >= alias_price,"MINIMUMDONATIONREQUIRED");
            emit DonationReceived(msg.sender, msg.value);
        }
        require(names[alias] == address(0),"NAMEINUSE");
        names[alias] = user; //This will not set the name attribute on the account
        emit NewAlias(user, alias);
    }

    //Allows a user to specify a key mapped to a label, useful for PKI, not a good place to share a symmetric key
    function changeKeys(string label, byte[] key) public{
        accounts[msg.sender].pubkeys[label] = key;
        emit KeyChanged(msg.sender,label,key);    
    }

    //Joining a community allows the community to credit or debit your AVIV and VIP balances
    function joinCommunity(address community) public{
        accounts[msg.sender].communities[community] = true;
        emit JoinedCommunity(accounts[msg.sender].name, community);
    }

    //Leaving a community prevents that community from crediting or debiting your AVIV and VIP balances
    function leaveCommunity(address community) public{
        accounts[msg.sender].communities[community] = true;
        emit LeftCommunity(accounts[msg.sender].name, community);
    }

    //are they part of a community
    function inCommunity(address user, address community) public view returns (bool){
        return accounts[user].communities[community];
    }

    //key with a specific label
    function getKey(address user, string label) public view returns (byte[]){
        return accounts[user].pubkeys[label];
    }

    //get the name of an account
    function getName(address user) public view returns (string){
        return accounts[user].name;
    }

    //get the address of an account alias
    function getByAlias(string name) public view returns (address){
        return names[name];
    }

    //check if user is verified
    function isVerified(address user) public view returns (bool){
        return accounts[user].verified;
    }
    
    //return the total that this user has donated
    function donationsFrom(address user) public view returns (uint){
        return accounts[user].donations;
    }
}