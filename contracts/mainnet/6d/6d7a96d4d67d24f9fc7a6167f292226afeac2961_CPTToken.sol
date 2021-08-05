/**
 *Submitted for verification at Etherscan.io on 2020-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

interface IERC20Token {
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 value) external  returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256 );
}

interface ApproveAndCallFallback { 
    function receiveApproval(address from, uint256 value, address token, bytes calldata data) external returns (bool); 
}

interface ApproveStakeFallback { 
    function createStake(address _wallet, uint8 _timeFrame, uint256 _value) external returns (bool); 
}

contract Ownable {
    address private owner;
    
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender; 
        emit OwnershipTransferred(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
        require(_to != address(0x0));
		require(_value >= 0); 
		require(balances[msg.sender] >= _value);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0));
		require(_value >= 0); 
		require(balances[_from] >= _value);
		require(allowed[_from][msg.sender] >= _value);
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

contract CPTToken is Ownable, StandardToken {

    using SafeMath for uint256;
    string public name;
    uint8 public decimals;
    string public symbol;
    address public stakeContract;
    address public crowdSaleContract;
    uint256 public soldTokensUnlockTime;
    mapping (address => uint256) frozenBalances;
    mapping (address => uint256) timelock;
    
    event Burn(address indexed from, uint256 value);
    event StakeContractSet(address indexed contractAddress);
    
    constructor() {
        name = "Capiteum";
        decimals = 18;
        symbol = "CPT";
        stakeContract = address(0x0);
        crowdSaleContract = 0xc0B18EE109212791079aaa7011fa5d770Cf26fDc;  

        address teamWallet =  0x4607951Bf1A2263715cC3842F3f2Fd83f1fafDeE;
        address teamWalletUnlocked = 0x387720d79D675ae815a9A47F7418b8701538b9D9;          

        address privateSaleWallet = 0x572D4Dd0bf45293744762d3E85211C8ba2C284D7;        
        address marketingWallet = 0x19544E83cb66855dFeEF638474438f9dA51FA192;          
        address exchangesLiquidity = 0x48887F49140614312ea1cBB6C27aeDb1ED18F248;       
        address stakeWallet = 0x44b3E70145D13a946f9edCFcadBc013864Db8A3f;              
        uint256 teamReleaseTime = 1614102946;                       
        uint256 marketingReleaseTime = 1606939200;                  
        uint256 stakesReleaseTime = 1607385600;

        balances[teamWallet] = 1500 ether;
        emit Transfer(address(0x0), teamWallet, (1500 ether));
        frozenBalances[teamWallet] = 1500 ether;
        timelock[teamWallet] = teamReleaseTime;

        balances[teamWalletUnlocked] = 1500 ether;
        emit Transfer(address(0x0), teamWalletUnlocked, (1500 ether));
        
        balances[stakeWallet] = 7500 ether;
        emit Transfer(address(0x0), address(stakeWallet), (7500 ether));
        frozenBalances[stakeWallet] = 7500 ether;
        timelock[stakeWallet] = stakesReleaseTime;
        
        balances[marketingWallet] = 2000 ether;
        emit Transfer(address(0x0), address(marketingWallet), (2000 ether));
        frozenBalances[marketingWallet] = 1000 ether;
        timelock[marketingWallet] = marketingReleaseTime;
        
        balances[privateSaleWallet] = 1500 ether;
        emit Transfer(address(0x0), address(privateSaleWallet), (1500 ether));
        
        balances[crowdSaleContract] = 5000 ether;
        emit Transfer(address(0x0), address(crowdSaleContract), (5000 ether));

        balances[exchangesLiquidity] = 9000 ether;
        emit Transfer(address(0x0), address(exchangesLiquidity), (9000 ether));

        _totalSupply = 28000 ether;
        
        soldTokensUnlockTime = 1606950405;

    }
    
    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return frozenBalances[_owner];
    }
    
    function unlockTimeOf(address _owner) public view returns (uint256 time) {
        return timelock[_owner];
    }
    
    function transfer(address _to, uint256 _value) override public  returns (bool success) {
        require(isAllowedTx(msg.sender, _value));
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(isAllowedTx(msg.sender, _value));
        return super.transferFrom(_from, _to, _value);
    }
    
    function setStakeContract(address _contractAddress) onlyOwner public {
        stakeContract = _contractAddress;
        emit StakeContractSet(_contractAddress);
    }
    
    function setCrowdSaleContract(address _contractAddress) onlyOwner public {
        crowdSaleContract = _contractAddress;
    }
    
    function isAllowedTx(address sender, uint256 amount) private returns (bool isAllowed) {
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
    
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
		require(_value >= 0); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function approveStake(uint8 period, uint256 tokens) public returns (bool success) {
        require(stakeContract != address(0x0));
        allowed[msg.sender][stakeContract] = tokens;
        emit Approval(msg.sender, stakeContract, tokens);
        require(ApproveStakeFallback(stakeContract).createStake(msg.sender, period, tokens));
        return true;
    }
    
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        require(ApproveAndCallFallback(spender).receiveApproval(msg.sender, tokens, address(this), data));
        return true;
    }
    
    function tokensSold(address buyer, uint256 amount) public returns (bool success) {
        require(msg.sender == crowdSaleContract);
        frozenBalances[buyer] += amount;
        if (timelock[buyer] == 0 ) timelock[buyer] = soldTokensUnlockTime;
        return super.transfer(buyer, amount);
    }
}