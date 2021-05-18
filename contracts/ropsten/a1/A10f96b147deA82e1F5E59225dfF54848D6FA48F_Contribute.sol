/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity =0.8.1;


contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {

        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }
}

interface ContributeFace {
    
}

contract Contribute is Owner {
    
    string private title;
    uint private price;
    uint private amountMember;
    uint private time;
    uint private timeBegin;
    bool private status = false;
    
    struct Member {
        address address_Member;
        string name;
        uint amount;
  
    }
    
    Member[] public member; 
    
    event ContributeUser(string name, address sender, uint amount, uint balance);
    event Withdraw(uint amount, uint balance);
    event Transfer(address sender, uint amount, uint balance);
    
    modifier statusTrue() {
        require(status == true, "Contribute has not been initiated");
        _;
    }
    
    modifier checkTime() {
        require(timeBegin + time > block.timestamp , "Contribute has not been initiated");
        _;
    }
    
    function setContribute(string memory _title,uint _price, uint _amountMember, uint _time) public isOwner {
        require(status==false);
        title = _title;
        price = _price;
        amountMember = _amountMember;
        time = _time;
        status = true;
        timeBegin = block.timestamp;
        member.push(Member(getOwner(), "Owner", 0));
    }
    
    function contributeUser(string memory _name) public statusTrue checkTime payable 
    {
        require(msg.value == price);
        require(getLength() < amountMember);
        member.push(Member(msg.sender, _name, msg.value));
        emit ContributeUser(_name, msg.sender, msg.value, address(this).balance);
    }
    
    function contributeOwenr() public statusTrue checkTime isOwner payable 
    {
        require(msg.value == price*amountMember);
        member[0]=Member(getOwner(), "Owner", (msg.value));
        emit ContributeUser("owner", msg.sender, msg.value, address(this).balance);
        
    }
    
    function withdraw(uint _amount) public isOwner 
    {
        payable(getOwner()).transfer(_amount); 
        emit Withdraw(_amount, address(this).balance);
    }
    
    function transfer(address payable _to, uint _amount) public isOwner 
    {
        _to.transfer(_amount);   
        emit Transfer(_to, _amount,  address(this).balance);
    }
    
    function reset() public isOwner {
        //payable(getOwner()).transfer(address(this).balance);
        withdraw(getBalance());
        delete member;
        status = false;
    }

    
    function getTitle() public view statusTrue returns (string memory)
    {
        return title;
    }
    
    function getPrice() public view statusTrue returns (uint)
    {
        return price;
    }
    
    function getAmountMember() public view statusTrue returns (uint)
    {
        return amountMember;
    }
    
    function getStatus() public view returns (bool)
    {
        return status;
    }
    
    
    function getLength() public view statusTrue returns (uint)
    {
        return member.length-1;
    }
    
    function getBalance() public view returns (uint) 
    {
        return address(this).balance;
    }
    
    function getMember(uint _i) public statusTrue view returns (address, string memory)
    {
        return (member[_i].address_Member, member[_i].name);
    }
    
    function getMember2() public statusTrue view returns (Member[] memory)
    {
        return member;
    }
    
    function getTimeBegin() public statusTrue view returns (uint) 
    {
        return timeBegin;
    }
    
    function getTime() public statusTrue view returns (uint) {
        return time;
    }
    
}