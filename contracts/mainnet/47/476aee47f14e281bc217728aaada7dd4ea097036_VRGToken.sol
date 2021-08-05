/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

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

contract VRGToken is Ownable, StandardToken {

    using SafeMath for uint256;
    string public name = "Virtual Reality Games and Bets";
    uint8 public decimals = 18;
    string public symbol = "VRG";
    address public sellingcontract;
    mapping (address => bool) lockedWallets;
    mapping (address => uint256) lockedBalances;
    struct BalanceUnlock {
        bool released;
        uint256 amount;
        uint256 rdate;
    }
    mapping (address => mapping(uint8 => BalanceUnlock)) progressiveRelease;
    uint256 public walletUnlockDate = 1609711800;
    event Burn(address indexed from, uint256 value);

    
    constructor() {
        _totalSupply = 100000000 ether;
        // Selling Contract - 17000000 tokens
        sellingcontract = (0xbFB7B47d332Db4aCD120A4E8cb263E0d89C70430);
        balances[sellingcontract] = 17000000 ether;
        emit Transfer(address(0x0), sellingcontract, (17000000 ether));
        
        // Marketing wallet - 4000000 tokens
        address marketing = 0xe317f3DB5f170c90b89c95C1B61a5811AD6d9794;
        balances[marketing] = 4000000 ether;
        emit Transfer(address(0x0), marketing, (4000000 ether));
        
        // Team wallet - 4000000 tokens (Locked - progressive release)
        address team = 0x80884b6102Af05C118E6bf56cc733E0747621685;
        balances[team] = 4000000 ether;
        emit Transfer(address(0x0), team, (4000000 ether));
        // locking balances
        lockedBalances[team] = 4000000 ether;
        // First release
        createUnlockPoint(team, uint8(1), (1000000 ether), (block.timestamp + (180 days)));
        // second release
        createUnlockPoint(team, uint8(2), (1000000 ether), (block.timestamp + (270 days)));
        // third release
        createUnlockPoint(team, uint8(3), (1000000 ether), (block.timestamp + (360 days)));
        // fourth release
        createUnlockPoint(team, uint8(4), (1000000 ether), (block.timestamp + (450 days)));
        
        // Uniswap and exchanges - 25000000 tokens locked until crowdsale ends
        address exchanges = 0x4a9753A90808D91E51fb6590ec940CE99a60B84b;  
        balances[exchanges] = 25000000 ether;
        emit Transfer(address(0x0), exchanges, (25000000 ether));
        // locking balances
        lockedBalances[exchanges] = 25000000 ether;
        createUnlockPoint(exchanges, uint8(1), (25000000 ether), 1609693500);
        
        // Betting Platform tokens
        // Development - 2000000 for inmediate release and 
        // 48000000 locked - Releasing 12000000 every 90 days
        address BettingPlatform = 0x0296dfbfF01C81FA7E2eB4D6cE035e555ce62Fe4;  
        balances[BettingPlatform] = 50000000 ether;
        emit Transfer(address(0x0), BettingPlatform, (50000000 ether));
        // locking balances
        lockedBalances[BettingPlatform] = 48000000 ether;
        // First release
        createUnlockPoint(BettingPlatform, uint8(1), (12000000 ether), (block.timestamp + (90 days)));
        // second release
        createUnlockPoint(BettingPlatform, uint8(2), (12000000 ether), (block.timestamp + (180 days)));
        // third release
        createUnlockPoint(BettingPlatform, uint8(3), (12000000 ether), (block.timestamp + (270 days)));
        // fourth release
        createUnlockPoint(BettingPlatform, uint8(4), (12000000 ether), (block.timestamp + (360 days)));
        
    }
    
    function transfer(address _to, uint256 _value) override public returns (bool success) {
        require(canTransfer(msg.sender));
        require(_value <= (balances[msg.sender] - lockedBalances[msg.sender]));
        return super.transfer(_to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(canTransfer(_from));
        require(_value <= (balances[_from] - lockedBalances[_from]));
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
    
    function createUnlockPoint(address _wallet, uint8 _releaseId, uint256 _amount, uint256 _releaseTime) private {
        BalanceUnlock memory unlockPoint;
        unlockPoint = BalanceUnlock(false, _amount, _releaseTime);
        progressiveRelease[_wallet][_releaseId] = unlockPoint;
    }
    
    function releaseTokens(uint8 _unlockPoint) public returns (bool success) {
        if (progressiveRelease[msg.sender][_unlockPoint].released == false) {
            if (progressiveRelease[msg.sender][_unlockPoint].amount > 0 ) {
                if (progressiveRelease[msg.sender][_unlockPoint].rdate < block.timestamp) {
                    lockedBalances[msg.sender] -= progressiveRelease[msg.sender][_unlockPoint].amount;
                    progressiveRelease[msg.sender][_unlockPoint].released = true;
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    
    function tokensSold(address buyer, uint256 amount) public returns (bool success) {
        require(msg.sender == sellingcontract);
        lockedWallets[buyer] = true;
        return super.transfer(buyer, amount);
    }
    
    function canTransfer(address _wallet) private returns (bool) {
        if (lockedWallets[_wallet] == true) {
            if (block.timestamp > walletUnlockDate) {
                lockedWallets[_wallet] = false;
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    
    function isWalletLocked(address _wallet) public view returns (bool isLocked) {
        return lockedWallets[_wallet];
    }
    
    function isBalanceReleased(address _wallet, uint8 _unlockPoint) public view returns (bool released) {
        return progressiveRelease[_wallet][_unlockPoint].released;
    }
    
    function getLockedBalance(address _wallet) public view returns (uint256 lockedBalance) {
        return lockedBalances[_wallet];
    }
    

}