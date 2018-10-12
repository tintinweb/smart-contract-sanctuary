//LAB 3 WETH
//This lab will focus on re-creating a simplified weth contract. see weth.io.

pragma solidity ^0.4.25;
    
contract modifiedWETH{
    address public owner;
    mapping (address => uint) public balanceOf;
    
    //constructor
    constructor() public{
        owner=msg.sender;
    }
    //must modify balanceOf such that balanceOf the msg.sender is increased by msg.value
    function deposit() public payable{
        balanceOf[msg.sender] += msg.value;
    }
    
    // Fallback function to call the deposit function IE. deposit()
    function() public payable{
        deposit();
    }
    //withdraws the weth into senders account only if the sender has sufficient weth
    function withdraw(uint amount) public{
        require(balanceOf[msg.sender] >= amount);
            balanceOf[msg.sender]-= amount;
            msg.sender.transfer(amount);
    }
    //transfers Weth from msg.sender to dst address
    //assume we are transfering them Weth and not real eth
    function transfer(address dst, uint amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount);
            balanceOf[msg.sender]-= amount;
            balanceOf[dst] += amount;
            //replace line above with dst.transfer(amount); if the function should send real eth instead
            return true;
    }
    
    //returns total supply of weth
    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }
}


//pragma solidity ^0.4.25;
contract WethAgent{
    
    address public owner;
    modifiedWETH w;
    
    //used so that other people can&#39;t take eth from my instance of WethAgent as WethAgent holds my Ethereum and Wrapped Ethereum&#39;
    modifier isOwner{
        require(msg.sender==owner); 
        _;
    }
    
    //set owner to msg.sender
    constructor() public payable{
        owner=msg.sender;
        //delete this line below later
        //w = modifiedWETH(0xbbf289d846208c16edc8474705c748aff07732db);
    }
    
    //set w to be a new contract of type WETH
    function set_modified_weth_address(address addr) isOwner public{
        w = modifiedWETH(addr);
    }
    
    //takes eth from what the contract was initialized with and puts it in modifiedWETH
    function callDeposit(uint amount) isOwner public{
        //may also be doable with modifiedWETH&#39;s fallback function?&#39;
        address(w).call.value(amount)(bytes4(keccak256("deposit()")));//address(w).call.value(amount)(0xd0e30db0);
    }
    
    //transfers the contract&#39;s WETH to another address&#39;
    function callTransfer(address dst, uint amount) isOwner public {
        w.transfer(dst, amount);
    }
    
    //withdraws WETH from ModifiedWETH back to this contract
    function callWithdraw(uint amount) isOwner public{
        w.withdraw(amount);
    }
    //returns balance of modified weth this contract has
    function getBalanceOfModifiedWeth() public view returns (uint){
        return w.totalSupply();
    }
    
    //debugging function to find out how much eth this contract has
    function getBalanceofEthAgent() public view returns (uint){
        return address(this).balance;
    }
    
     //debugging function to to find the address of the ModifierWETH contract this contract is linked to
    function getLinkedWETHAddress() public view returns (address){
        return address(w);
    }
}