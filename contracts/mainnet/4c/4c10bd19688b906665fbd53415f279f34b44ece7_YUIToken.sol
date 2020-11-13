// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

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
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
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

contract YUIToken is Ownable, StandardToken {

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
        name = "YUI Token";
        decimals = 18;
        symbol = "YUI";
        stakeContract = address(0x0);
        crowdSaleContract = 0x5530AF4758A33bE9Fd62165ef543b5E2e6742953;                 // contract for ICO tokens
        address teamWallet =  0x07B8DcbDF4d52B9C1f4251373A289D803Cc670f8;               // wallet for team tokens
        address privateSaleWallet = 0xC5f1f4fdbFAb7F73CfC814d72408B648059514A0;         // wallet for private sale tokens
        address marketingWallet = 0x5e0e67AA4f29aD2920Fa8BFe3ae38B52D4f2ceb1;           // wallet for marketing
        address exchangesLiquidity = 0x7e47b3C642A72520fF7DbFDc052535A0c804fC3C;        // add liquidity to exchanges
        address stakeWallet = 0x16B92c0473C0491D1509c447285B7c925355e3D3;               // tokens for the stake contract
        uint256 teamReleaseTime = 1620324000;                                           // lock team tokens for 6 months
        uint256 marketingReleaseTime = 1612548000;                                      // lock marketing tokens - 1k tokens for 3 months
        uint256 stakesReleaseTime = 1606586400;                                         // lock stakeContract tokens - 7.5k tokens for 3 weeks

        balances[teamWallet] = 3000 ether;
        emit Transfer(address(0x0), teamWallet, (3000 ether));
        frozenBalances[teamWallet] = 3000 ether;
        timelock[teamWallet] = teamReleaseTime;
        
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
        
        soldTokensUnlockTime = 1605636300;

    }
    
    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return frozenBalances[_owner];
    }
    
    function unlockTimeOf(address _owner) public view returns (uint256 time) {
        return timelock[_owner];
    }
    
    function transfer(address _to, uint256 _value) override public  returns (bool success) {
        require(txAllowed(msg.sender, _value), "Crowdsale tokens are still frozen");
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(txAllowed(msg.sender, _value), "Crowdsale tokens are still frozen");
        return super.transferFrom(_from, _to, _value);
    }
    
    function setStakeContract(address _contractAddress) onlyOwner public {
        stakeContract = _contractAddress;
        emit StakeContractSet(_contractAddress);
    }
    
    function setCrowdSaleContract(address _contractAddress) onlyOwner public {
        crowdSaleContract = _contractAddress;
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
    
    function burn(uint256 _value) public returns (bool success) {
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
    
    function tokensSold(address buyer, uint256 amount) public returns (bool success) {
        require(msg.sender == crowdSaleContract);
        frozenBalances[buyer] += amount;
        if (timelock[buyer] == 0 ) timelock[buyer] = soldTokensUnlockTime;
        return super.transfer(buyer, amount);
    }
    

}