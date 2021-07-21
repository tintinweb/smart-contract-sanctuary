/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public _totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function totalSupply() override public view returns (uint256 supply) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                              
		require(_value >= 0, "Invalid amount"); 
		require(balances[msg.sender] >= _value, "Not enough balance");
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual public returns (bool success) {
        require(_to != address(0x0), "Use burn function instead");                               
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

contract JOYToken is Ownable, StandardToken {

    using SafeMath for uint256;
    string public name = "Joy City";
    uint8 public decimals = 18;
    string public symbol = "JOY";

    // Time lock for progressive release of team, marketing and platform balances
    struct TimeLock {
        uint256 totalAmount;
        uint256 lockedBalance;
        uint128 baseDate;
        uint64 step;
        uint64 tokensStep;
    }
    mapping (address => TimeLock) public timeLocks; 

    // Prevent Bots - If true, limits transactions to 1 transfer per block (whitelisted can execute multiple transactions)
    bool public limitTransactions;
    mapping (address => bool) public contractsWhiteList;
    mapping (address => uint) public lastTXBlock;
    event Burn(address indexed from, uint256 value);

// token sale

    // Wallet for the tokens to be sold, and receive ETH
    address payable public salesWallet;
    uint256 public soldOnCSale;
    uint256 public constant CROWDSALE_START = 1627956740;
    uint256 public constant CROWDSALE_END = 1628656740;
    uint256 public constant CSALE_WEI_FACTOR = 15000;
    uint256 public constant CSALE_HARDCAP = 7500000 ether;
    
    constructor() {
        _totalSupply = 250000000 ether;
        
        // Base date to calculate team, marketing and platform tokens lock
        uint256 lockStartDate = 1627956740;
        
        // Team wallet - 10000000 tokens
        // 0 tokens free, 10000000 tokens locked - progressive release of 5% every 30 days (after 180 days of waiting period)
        address team = 0x9dA43D2eC9D228327f435d7B9cDc6CBdC72Ac9f4;
        balances[team] = 10000000 ether;
        timeLocks[team] = TimeLock(10000000 ether, 10000000 ether, uint128(lockStartDate + (180 days)), 30 days, 500000);
        emit Transfer(address(0x0), team, balances[team]);

        // Marketing wallet - 5000000 tokens
        // 1000000 tokens free, 4000000 tokens locked - progressive release of 5% every 30 days
        address marketingWallet = 0x3522BBC527F758C8692984008e680679Baa36C55;
        balances[marketingWallet] = 5000000 ether;
        timeLocks[marketingWallet] = TimeLock(4000000 ether, 4000000 ether, uint128(lockStartDate), 30 days, 200000);
        emit Transfer(address(0x0), marketingWallet, balances[marketingWallet]);
        
        // Private sale wallet - 2500000 tokens
        address privateWallet = 0xC1989eA6f62935a4Fa3EF36F3B1dF977b589b600;
        balances[privateWallet] = 2500000 ether;
        emit Transfer(address(0x0), privateWallet, balances[privateWallet]);
        
        // Sales wallet, holds Pre-Sale balance - 7500000 tokens
        salesWallet = payable(0xbD01F9a24b5B4fFC00FAa52127Af037FC130c684);
        balances[salesWallet] = 7500000 ether;
        emit Transfer(address(0x0), salesWallet, balances[salesWallet]);
        
        // Exchanges - 25000000 tokens
        address exchanges = 0xB5cA62899086dd0a7CCfD294d1c45F080A5eec2b;  
        balances[exchanges] = 25000000 ether;
        emit Transfer(address(0x0), exchanges, balances[exchanges]);
        
        // Platform wallet - 200000000 tokens
        // 50000000 tokens free, 150000000 tokens locked - progressive release of 25000000 every 90 days
        address platformWallet = 0xfE5B4AECd3e18dB44F6BAb09C2B23973f7a9e5Cb;
        balances[platformWallet] = 200000000 ether;
        timeLocks[platformWallet] = TimeLock(150000000 ether, 150000000 ether, uint128(lockStartDate), 90 days, 25000000);
        emit Transfer(address(0x0), platformWallet, balances[platformWallet]);
        


    }
    
    function transfer(address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");
        require(_value <= (balances[msg.sender] - timeLocks[msg.sender].lockedBalance));
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");
        require(_value <= (balances[_from] - timeLocks[_from].lockedBalance));
        return super.transferFrom(_from, _to, _value);
    }
    
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Not enough balance");
		require(_value >= 0, "Invalid amount"); 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ItokenRecipient recipient = ItokenRecipient(_spender);
        require(recipient.receiveApproval(msg.sender, _value, address(this), _extraData));
        return true;
    }
    

    function releaseTokens(address _account) public {
        uint256 timeDiff = block.timestamp - uint256(timeLocks[_account].baseDate);
        require(timeDiff > uint256(timeLocks[_account].step), "Unlock point not reached yet");
        uint256 steps = (timeDiff / uint256(timeLocks[_account].step));
        uint256 unlockableAmount = ((uint256(timeLocks[_account].tokensStep) * 1 ether) * steps);
        if (unlockableAmount >=  timeLocks[_account].totalAmount) {
            timeLocks[_account].lockedBalance = 0;
        } else {
            timeLocks[_account].lockedBalance = timeLocks[_account].totalAmount - unlockableAmount;
        }
    }
       
    function checkTransferLimit() internal returns (bool txAllowed) {
        address _caller = msg.sender;
        if (limitTransactions == true && contractsWhiteList[_caller] != true) {
            if (lastTXBlock[_caller] == block.number) {
                return false;
            } else {
                lastTXBlock[_caller] = block.number;
                return true;
            }
        } else {
            return true;
        }
    }
    
    function enableTXLimit() public onlyOwner {
        limitTransactions = true;
    }
    
    function disableTXLimit() public onlyOwner {
        limitTransactions = false;
    }
    
    function includeWhiteList(address _contractAddress) public onlyOwner {
        contractsWhiteList[_contractAddress] = true;
    }
    
    function removeWhiteList(address _contractAddress) public onlyOwner {
        contractsWhiteList[_contractAddress] = false;
    }
    
    function getLockedBalance(address _wallet) public view returns (uint256 lockedBalance) {
        return timeLocks[_wallet].lockedBalance;
    }
    
    function buy() public payable {
        require((block.timestamp > CROWDSALE_START) && (block.timestamp < CROWDSALE_END), "Contract is not selling tokens");
        uint weiValue = msg.value;
        require(weiValue >= (5 * (10 ** 16)), "Minimum amount is 0.05 eth");
        require(weiValue <= (20 ether), "Maximum amount is 20 eth");
        uint amount = CSALE_WEI_FACTOR * weiValue;
        require((soldOnCSale) <= (CSALE_HARDCAP), "That quantity is not available");
        soldOnCSale += amount;
        balances[salesWallet] = balances[salesWallet].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        require(salesWallet.send(weiValue));
        emit Transfer(salesWallet, msg.sender, amount);

    }
    
    function burnUnsold() public onlyOwner {
        require(block.timestamp > CROWDSALE_END);
        uint currentBalance = balances[salesWallet];
        balances[salesWallet] = 0;
        _totalSupply = _totalSupply.sub(currentBalance);
        emit Burn(salesWallet, currentBalance);
    }
}