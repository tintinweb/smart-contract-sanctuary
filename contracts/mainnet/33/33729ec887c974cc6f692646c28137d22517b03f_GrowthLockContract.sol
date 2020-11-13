pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT
interface ERC20Interface {
    function totalSupply() 
		external 
		view 
		returns (uint);

    function balanceOf(address tokenOwner) 
		external 
		view 
		returns (uint balance);
    
	function allowance
		(address tokenOwner, address spender) 
		external 
		view 
		returns (uint remaining);

    function transfer(address to, uint tokens) 				external 
		returns (bool success);
    
	function approve(address spender, uint tokens) 		external 
		returns (bool success);

    function transferFrom 
		(address from, address to, uint tokens) 				external 
		returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    
}

///Contract that vests 200K GRO then payout after every month for the next 24 months. 
contract GrowthLockContract {
    
    address private owner; 
    address private safe;
    address private mike;
    address private ghost;
    address private dev; 
    uint256 public time; 
    uint private constant devAmount = 4166.66 * 1 ether;
    uint private constant managementAmount = 1388.88 * 1 ether;
    
    //2629743 = 30 days. 
    uint public constant locktime = 2629743; 
    
    //0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0 is Growth Token address
    ERC20Interface private constant token = ERC20Interface(0x09e64c2B61a5f1690Ee6fbeD9baf5D6990F8dFd0);
    
    
    constructor () {
        owner = msg.sender;
        
        time = block.timestamp; 
        
        
        mike = 0x70F5FB6BE943162545a496eD120495B05dC5ce07;
        ghost = 0x6811101D884557Eba52DF3Ea0417A3036D5b9FCd;
        safe = 0xC4faC8CA576B9c8B971fA36916aEE062d84b4901;
        dev = 0xB0632a01ee778E09625BcE2a257e221b49E79696;
        

  
    }
    
    //Modifier to prevent everyone except owner from using contract.  
    modifier onlyOwner(){
        require(msg.sender == owner, "Unauthorized to call. ");
        _;
    }
    
    //Admin can deposit the initial vested amount.  You can only use this function once.  
    function depositToken(uint amount) public onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        
        require(token.transferFrom(msg.sender, address(this), amount) == true, "Inefficient balance or Unauthorized to pay. ");

    }
    
    
    //Admin pays dev and management team.
    function payToken() public onlyOwner {
        //check if it's past the next payperiod.  
        require(block.timestamp >= (time + locktime), "Period not reached yet. ");

        
        //Sends dev payment. 
        require(token.transfer(dev, devAmount) == true, "You don't have enough in balance. ");
        
        //sends management payments.
        require(token.transfer(safe, managementAmount) == true, "You don't have enough in balance. ");
        require(token.transfer(mike, managementAmount) == true, "You don't have enough in balance. ");
        require(token.transfer(ghost, managementAmount) == true, "You don't have enough in balance. ");
        
        time += locktime; 
        
    }
    
    
    //Used to check contract balance. 
    function getBalance() view public returns (uint) {
        return token.balanceOf(address(this));
    }
    
    ///Updates the owner of the contract
    function updateOwner(address newOwner) public onlyOwner {

        owner = newOwner; 
    }
    
    //Used incase management teams lost their wallet and needs to updated.  
    function updateManagement(address _mike, address _ghost, address _safe, address _dev) public onlyOwner {

        mike = _mike;
        ghost = _ghost;
        safe = _safe;
        dev = _dev;
    }
    
    //Check who owner is. 
    function getOwner() view public returns (address) {
        return owner; 
    }
    
    
}