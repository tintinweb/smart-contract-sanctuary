/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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

}

interface ItokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external returns (bool); 
}

interface IstakeContract { 
    function createStake(address _wallet, uint8 _timeFrame, uint256 _value) external returns (bool); 
}

interface IERC20Token {
    function totalSupply() external view returns (uint256 supply);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract Ownable {

    address private owner;
    address private priceManager;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    modifier onlyPriceManager() {
        require(msg.sender == priceManager, "Caller is not priceManager");
        _;
    }
    
    

    constructor() {
        owner = msg.sender; 
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function setPriceManager (address newPriceManager) public onlyOwner {
        priceManager = newPriceManager;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract StandardToken is IERC20Token {
    
    using SafeMath for uint256;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public _totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function totalSupply() override public view returns (uint256 supply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                               // Prevent transfer to 0x0 address. Use burn() instead
		require(_value >= 0, "Invalid amount"); 
		require(balances[msg.sender] >= _value, "Not enough balance");
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                               // Prevent transfer to 0x0 address. Use burn() instead
		require(_value >= 0, "Invalid amount"); 
		require(balances[_from] >= _value, "Not enough balance");
		require(allowed[_from][msg.sender] >= _value, "You need to increase allowance");
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) override public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}

contract UTRINToken is Ownable, StandardToken {

    using SafeMath for uint256;
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public subscriptionPrice;
    address public stakeContract;
    address public crowdSaleContract;
    address public preSaleContract;
    address public dividendPool;
    uint256 public soldTokensUnlockTime;
    mapping (address => uint256) frozenBalances;
    mapping (address => uint256) timelock;
    
    event Burn(address indexed from, uint256 value);
    event StakeContractSet(address indexed contractAddress);

    
    constructor() {
        name = "Universal Trade Interface";
        decimals = 18;
        symbol = "UTRIN";
        
        crowdSaleContract = 0x1eB807fA2ec2aEDE1736Fd0c5300e462CFafF2d9;			  
	 	preSaleContract =   0x09f9A8a61f9f634a93A52B7d358a651fc1127B2E;	
	 	
        address teamWallet = 0x41dA08f916Fc534C25FB3B388a0859b9e4A42ADa;          
        address legalAndLiquidity = 0x298843E6C4Cedd1Eae5327A39847F0A170D32D26;
        address developmentFund = 0x0e70bB808E549147E3073937f13eCdc08E5d5775; 
        dividendPool = 0xd1c16226FF031Fcd961221aD25c6a43B4FB96d7E;
        
        balances[teamWallet] = 1500000 ether;                                           
        emit Transfer(address(0x0), teamWallet, (1500000 ether));                       
        
        balances[legalAndLiquidity] = 1000000 ether;                                           
        emit Transfer(address(0x0), legalAndLiquidity, (1000000 ether));
        
        balances[developmentFund] = 1500000 ether;                                    
        emit Transfer(address(0x0), developmentFund, (1500000 ether));     

        balances[preSaleContract] = 1000000 ether;                                    
        emit Transfer(address(0x0), address(preSaleContract), (1000000 ether));       
        
        balances[crowdSaleContract] = 4000000 ether;                                    
        emit Transfer(address(0x0), address(crowdSaleContract), (4000000 ether));       

        _totalSupply = 9000000 ether;

    }
    
    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return frozenBalances[_owner];
    }

    function unlockTimeOf(address _owner) public view returns (uint256 time) {
        return timelock[_owner];
    }
    
    function transfer(address _to, uint256 _value) override public  returns (bool success) {
        require(txAllowed(msg.sender, _value), "Tokens are still frozen");
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) { ///??
        require(txAllowed(msg.sender, _value), "Crowdsale tokens are still frozen");
        return super.transferFrom(_from, _to, _value);
    }
    
    function setStakeContract(address _contractAddress) onlyOwner public {
        stakeContract = _contractAddress;
        emit StakeContractSet(_contractAddress);
    }
    
    function setDividenPool(address _DividenPool) onlyOwner public {
        dividendPool = _DividenPool;
    }
    
        // Tokens sold by crowdsale contract will be frozen ultil crowdsale ends
    function txAllowed(address sender, uint256 amount) private returns (bool isAllowed) {
        if (timelock[sender] > block.timestamp) {
            return isBalanceFree(sender, amount);
        } else {
            if (frozenBalances[sender] > 0) frozenBalances[sender] = 0;
            return true;
        }
        
    }
    
    function isBalanceFree(address sender, uint256 amount) private view returns (bool isfree) {
        if (amount <= (balances[sender] - frozenBalances[sender])) {
            return true;
        } else {
            return false;
        }
    }
    
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough balance");
		require(_value >= 0, "Invalid amount"); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function approveStake(uint8 _timeFrame, uint256 _value) public returns (bool success) {
        require(stakeContract != address(0x0));
        allowed[msg.sender][stakeContract] = _value;
        emit Approval(msg.sender, stakeContract, _value);
        IstakeContract recipient = IstakeContract(stakeContract);
        require(recipient.createStake(msg.sender, _timeFrame, _value));
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ItokenRecipient recipient = ItokenRecipient(_spender);
        require(recipient.receiveApproval(msg.sender, _value, address(this), _extraData));
        return true;
    }
   
    function tokensSoldCrowdSale(address buyer, uint256 amount) public returns (bool success) {
        require(msg.sender == crowdSaleContract, "Error with tokensSoldCrowdSale function.");
        frozenBalances[buyer] += amount;
        if (timelock[buyer] == 0 ) timelock[buyer] = soldTokensUnlockTime;
        return super.transfer(buyer, amount);
    }
    
    function tokensSoldPreSale(address buyer, uint256 amount) public returns (bool success) {
        require(msg.sender == preSaleContract, "Error with tokensSoldPreSale function.");
        frozenBalances[buyer] += amount;
        if (timelock[buyer] == 0 ) timelock[buyer] = soldTokensUnlockTime;
        return super.transfer(buyer, amount);
    }
    
	function setPrice(uint256 newPrice) public onlyPriceManager {
		subscriptionPrice = newPrice;
	}

	function redeemTokens(uint256 amount) public{
	    require(amount > subscriptionPrice, "Insufficient Utrin tokens sent to cover your fee!");
		    address account = msg.sender;        	

        	balances[account] = balances[account].sub(amount);
        	emit Transfer(account, dividendPool, amount);
	}
	
	


    

}