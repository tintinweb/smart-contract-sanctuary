/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract OXYI is Ownable{
    using SafeMath for uint256;
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public whitelist;

    string public name = "Oxyi Value Token";
    string public symbol = "OXYI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);
    uint256 public totalPooled;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        totalPooled = 50 * (uint256(10) ** decimals);
        
        // Initially assign all non-pooled tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply.sub(totalPooled);
        
        emit Transfer(address(0), msg.sender, totalSupply.sub(totalPooled));
    }
    
    // Ensure a redemption is profitable before allowing a redeem()
    modifier profitable() {
        require(is_profitable(), "Redeeming is not yet profitable.");
        _;
    } 
    
    // VIEWS 
    
    // Get the number of tokens to be redeemed from the pool
    function numberRedeemed(uint256 amount) 
        public 
        view 
        returns (uint256 profit) {
        uint256 numerator = amount.mul(totalPooled);  
        uint256 denominator = totalSupply.sub(totalPooled);  
        return numerator.div(denominator);
    }
    
    // Check if more than 50% of the token is pooled
    function is_profitable() 
        public 
        view 
        returns (bool _profitable) {
        return totalPooled > totalSupply.sub(totalPooled);
    }


    // SETTERS

    function addToWhitelist(address _addr) 
        public 
        onlyOwner {
        whitelist[_addr] = true;
    }
    
    function removeFromWhitelist(address _addr) 
        public 
        onlyOwner {
        whitelist[_addr] = false;
    }
    
    // TRANSFER FUNCTIONS 
    
    // BOA-TOKEN <- Sell taxed
    // TOKEN-BOA <- Buy (not taxed)
    
    function transfer(address to, uint256 value) 
        public 
        returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        
        if(whitelist[msg.sender]) return regular_transfer(to, value);
        else return burn_transfer(to, value);
    }
    
    function burn_transfer(address to, uint256 value) 
        private 
        returns (bool success) {
        // send 1% to the pooled ledger
        uint256 burned_amount = value.div(100);
        
        // withdraw from the user's balance
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(burned_amount);
        // increment the total pooled amount
        totalPooled = totalPooled.add(burned_amount);
        
        value = value.sub(burned_amount);
        
        // perform a normal transfer on the remaining 99%
        return regular_transfer(to, value);
    }

    function regular_transfer(address to, uint256 value) 
        private 
        returns (bool success) {
        // perform a normal transfer 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);  
        balanceOf[to] = balanceOf[to].add(value);                   
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        // allow feeless for the RED-BLUE uniswap pool
        if(whitelist[msg.sender]) return regular_transferFrom(from, to, value);
        else return burn_transferFrom(from, to, value); 

    }
    
    function burn_transferFrom(address from, address to, uint256 value) 
        private 
        returns (bool success) {
        // send 1% to the pooled ledger
        uint256 burned_amount = value.div(100);
        
        // remove from the spender's balance
        balanceOf[from] = balanceOf[from].sub(burned_amount);
        // increment the total pooled amount
        totalPooled = totalPooled.add(burned_amount);
        
        // burn allowance (for approved spenders)
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(burned_amount);
        
        value = value.sub(burned_amount);
        
        // perform a normal transfer on the 99%
        return regular_transferFrom(from, to, value);
    }
    
    function regular_transferFrom(address from, address to, uint256 value) 
        private
        returns (bool success) {
        // transfer without adding to a pool
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        
        // remove allowance (for approved spenders)
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    // REDEEM AND BURN FUNCTIONS
    
    // amount = number of tokens to burn
    function redeem(uint256 amount) 
        public 
        profitable 
        returns (bool success) {
        // the amount must be less than the total amount pooled
        require(amount <= balanceOf[msg.sender]);
        require(totalPooled >= amount); 
    	uint256 num_redeemed = numberRedeemed(amount);
        
        // make sure the number available to be redeemed is smaller than the available pool
	    require(num_redeemed < totalPooled);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(num_redeemed);
        
        emit Transfer(_owner, msg.sender, num_redeemed);
        totalPooled = totalPooled.sub(num_redeemed);
        
        // burn the amount sent
        return burn(amount);
    }
    
    function burn(uint256 value) 
        private 
        returns (bool success) {
        // burn from the user's ledger, transfer to 0x0
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);  
        balanceOf[address(0)] = balanceOf[address(0)].add(value);
        emit Transfer(msg.sender, address(0), value);
        
        // remove the burned amount from the total supply
        totalSupply = totalSupply.sub(value);
        return true;
    }
    
    // APPROVAL FUNCTIONS
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}