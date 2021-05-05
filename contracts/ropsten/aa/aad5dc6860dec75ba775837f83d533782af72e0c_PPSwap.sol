/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity =0.5.0;

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface { // six  functions
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
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

contract PPSwap is ERC20Interface, SafeMath {
    string public constant name = "PPSwap";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1000000000*10**18;
    uint public exchangeRateETH = 3463; // 1ETH = $3463, 5/4/2021, we set PPS at $1/PPS initially
    address  payable public contractOwner;
    bool public isPresaleOpen = true;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    
    event Error(uint errorcode);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        contractOwner = msg.sender;
        balances[msg.sender] = _totalSupply;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    


    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // called by the owner
    function approve(address spender, uint rawAmt) public returns (bool success) {
        allowed[msg.sender][spender] = rawAmt;
        emit Approval(msg.sender, spender, rawAmt);
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) {
        balances[from] = safeSub(balances[from], rawAmt);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(from, to, rawAmt);
        return true;
    }
    
     /**
      * approve the owner of this contract, be a spender of the caller, msg.sender,  for token with amt
       *this is to be called by the ownerAccount.
       * */
    function safeApprove(address token, 
                        uint amt) 
                        external 
                        returns (bool){
        
        bytes4 selector = bytes4(keccak256(bytes('approve(address, uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(selector, this.contractOwner, amt));
       
        if(success == false){
             emit Error(1111);
             if (data.length == 0) emit Error(2222);
        }
        // require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: approval of spending tokens fails');
        
        require(success, 'swapNoSwapfee failure: approval of spending tokens fails 111');
        return true;
    }
    
    
    function swapNoSwapfee(address accountA, 
                        address accountB, 
                        address tokenA, 
                        address tokenB, 
                        uint amtA, 
                        uint amtB) 
                        external
                        onlyOwner
                        returns(bool){
        bytes4 selector = bytes4(keccak256(bytes('transfer(address, uint)')));
        
        // transfer amtA of tokenA from accountA to accountB
        // bool success = token.approve()
        (bool success, bytes memory data) = tokenA.call(abi.encodeWithSelector(selector, accountA, accountB, amtA));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: transfer amtA of tokenA from accountA to accountB');
        
         // transfer amtB of tokenB from accountB to accountA
        (success, data) = tokenB.call(abi.encodeWithSelector(selector, accountB, accountA, amtB));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'swapNoSwapfee failure: transfer amtB of tokenB from accountB to accountA');
        
        return true;
    }
    
    modifier onlyOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }
    
    function setPresale(bool _isPresaleOpen, 
                        uint _exchangeRateETH) 
                        external
                        onlyOwner
                        returns(bool){
        isPresaleOpen = _isPresaleOpen;
        exchangeRateETH = _exchangeRateETH;
    }
    
    function() external payable {
        require(isPresaleOpen == true, "The presale is not open right now.");
        uint rawAmt = safeMul(msg.value, exchangeRateETH);
        balances[contractOwner] = safeSub(balances[contractOwner], rawAmt);
        balances[msg.sender] = safeAdd(balances[msg.sender], rawAmt);
        contractOwner.transfer(msg.value); // save the ETH to the contractOwner
        emit Transfer(contractOwner, msg.sender, msg.value*exchangeRateETH);
    }    
}