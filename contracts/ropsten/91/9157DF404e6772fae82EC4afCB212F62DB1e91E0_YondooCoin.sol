/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function percentageOf(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a * b / 100;
    }
    
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract YondooCoin is ERC20Interface, Owned {
    using SafeMath for uint;

    string constant public name = "Yondoo coin";
    string constant public symbol = "YONDOO";
    uint8 constant public decimals = 2;
    bool public mintingFinished = false;
    uint public sharedRewardCounter;
    uint public sharedRewardAmount;
    
    uint identifier;
    uint _totalSupply;
    uint _rewardSupply;
    uint luckyNumber;
    uint luckyCounter;
    uint nonce;
   
    uint rangeMin;
    uint rangeMax;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

  
    // ------------------------------------------------------------------------
    // LuckyShot
    // ------------------------------------------------------------------------
    event LuckyShot(address indexed to, uint tokens);
    
    function lucky(uint256 min, uint256 max) private returns (uint) {
        uint randomNumber = uint(
            uint256(keccak256(abi.encodePacked(identifier, nonce, block.timestamp, block.difficulty, msg.sender))) % (max - min + 1)
        );
        nonce++;
        randomNumber = randomNumber + min;
        return randomNumber;
    }
    
    function wheelRange(uint min, uint max) onlyOwner public {
        require(min < max, "min can't greater than max");
        rangeMin = min;
        rangeMax = max;
        generateLuckyNumber();
    }

    function generateLuckyNumber() internal {
        luckyCounter = 0;
        luckyNumber = lucky(rangeMin, rangeMax);
    }
    
    function spinWheel(address to, uint transferAmount) internal {
        if(transferAmount <= 0) {
            return;
        }
        
        luckyCounter++;
        if(luckyNumber != luckyCounter || to == owner) {
            return;
        }
        
        uint max = _rewardSupply.percentageOf(1);
        uint min = max.div(2);
        if(max <=0 && min <=0) {
            return;
        }
        
        if(min <=0) {
            min = 1;
        }
        
        uint amount = lucky(min, max);
        if(amount <= 0 || _rewardSupply < amount) {
            return;
        }
        
        generateLuckyNumber();
        _rewardSupply = _rewardSupply.sub(amount);
        balances[to] = balances[to].add(amount);
        sharedRewardAmount = sharedRewardAmount.add(amount);
        sharedRewardCounter++;
        emit Transfer(address(0), to, amount);
        emit LuckyShot(to, amount);
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
    }

    function init(uint256 id, uint256 initSupply, uint256 reward) onlyOwner public  returns (bool) {
        require(!mintingFinished, "mint is finished");
        identifier = id;
        initSupply = initSupply * 10**uint(decimals);
        _rewardSupply = reward * 10**uint(decimals);
        _totalSupply  = initSupply + _rewardSupply;
        balances[owner] =  initSupply;
        generateLuckyNumber();
        mintingFinished = true;
        emit Transfer(address(0), owner, initSupply);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Reward supply
    // ------------------------------------------------------------------------
    function rewardSupply() public view returns (uint) {
        return _rewardSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        spinWheel(to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Charging reward supply
    // ------------------------------------------------------------------------
    event ChargeReward(address indexed charger, uint value);
    
    function chargeReward(uint _value) onlyOwner public {
        _chargeReward(msg.sender, _value);
    }
    
    function _chargeReward(address _who, uint _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        _rewardSupply = _rewardSupply.add(_value);
        emit ChargeReward(_who, _value);
    }
    
    // ------------------------------------------------------------------------
    // Burning 
    // ------------------------------------------------------------------------
    event Burn(address indexed burner, uint value);

    // ------------------------------------------------------------------------
    // Burns a specific amount of tokens
    // ------------------------------------------------------------------------
    function burn(uint _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
   
}