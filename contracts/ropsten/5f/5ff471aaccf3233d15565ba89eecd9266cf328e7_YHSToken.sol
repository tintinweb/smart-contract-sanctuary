/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity 0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b;  
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract YHSToken is ERC20Interface, SafeMath {
    string public  name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor () public {
        name  = "YHSToken";
        symbol = "YHST";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}




  //*******************************************************************//
 //                 Contract to Manage Ownership		      //
//*******************************************************************//
    
contract owned {
    address payable public owner;
    address payable private newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 

interface tokenInterface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
} 

 
//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//

contract MoscowSale is owned {

    /*===============================
    =         DATA STORAGE          =
    ===============================*/

    // Public variables for private sale
       
        address public moscowContractAddress;              // main token address to run ICO on
   	uint256 public exchangeRate = 100;                // exchange rate  1 ETH = 100 tokens
   	uint256 public icoETHReceived;                   // how many ETH Received through ICO
   	uint256 public totalTokenSold;                  // how many tokens sold
	uint256 public minimumContribution =100;       // Minimum amount to invest - 0.01 ETH (in 18 decimal format)


    //nothing happens in constructor
    constructor() public{ }    

   mapping(address => uint ) balances;
    /**
        * Fallback function. It accepts incoming ETH and issue tokens
    */
    function () payable external {
        buyToken();
    }

    event buyTokenEvent (address sender,uint amount, uint tokenPaid);
    
    function buyToken() payable public returns(uint)
    {
		
		//checking conditions
        require(msg.value >= minimumContribution, "less then minimum contribution"); 
        
        //calculating tokens to issue
        uint256 tokenTotal = msg.value * exchangeRate;

        //updating state variables
        icoETHReceived += msg.value;
        totalTokenSold += tokenTotal;
       
        //sending tokens. This crowdsale contract must hold enough tokens.
        tokenInterface(moscowContractAddress).transfer(msg.sender, tokenTotal);
        
        
        //send ether to owner
        forwardETHToOwner();
        
        //logging event
        emit buyTokenEvent(msg.sender,msg.value, tokenTotal);
        
        return tokenTotal;

    }


	//Automatocally forwards ether from smart contract to owner address
	function forwardETHToOwner() internal {
		owner.transfer(msg.value); 
	}
	
	
	// exchange rate => 1 ETH = how many tokens
    function setExchangeRate(uint256 _exchangeRatePercent) onlyOwner public returns (bool)
    {
        exchangeRate = _exchangeRatePercent;
        return true;
    }



    function setMinimumContribution(uint256 _minimumContribution) onlyOwner public returns (bool)
    {
        minimumContribution = _minimumContribution;
        return true;
    }
    
    
    function updateMoscowContract(address _newMoscowContract) onlyOwner public returns (bool)
    {
        moscowContractAddress = _newMoscowContract;
        return true;
    }
    
	
	function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string memory){
        // no need for overflow checking as that will be done in transfer function
        tokenInterface(moscowContractAddress).transfer(msg.sender, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }

    function manualWithdrawEther() public onlyOwner returns(string memory){
        address(owner).transfer(address(this).balance);
        return "Ether withdrawn to owner wallet";
    }
    


}