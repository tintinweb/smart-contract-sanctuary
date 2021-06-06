/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: Apache-2.0
// 2021 (c) Cryptollama
pragma solidity >=0.4.0 <0.7.0;

interface IWool {
    
    function mint(address who, uint amount) external;
    function burnFrom(address who, uint amount) external;
    function balanceOf(address tokenOwner) external returns (uint256);
    
}

contract Token {
    
    address private wool = 0x0000000000000000000000000000000000000000;
    address private exchange = 0x0000000000000000000000000000000000000000;
    address private deployer = 0x0000000000000000000000000000000000000000;

    string public constant name = "Llama token";
    string public constant symbol = "LLAMA";
    uint8 public constant decimals = 0;
    uint256 public totalSupply = 100000000;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    mapping(address => uint256) public checkpointTimestamp;
    mapping(address => uint256) public checkpointAmount;
    mapping(address => uint256) public checkpointUnclaimedReward;
    mapping(address => uint256) public checkpointWolfTimer;
    
    uint256 public wolfTimer = 0;
    uint256 public lastWolfTimestamp = now + 604800;
    uint256 public lastaccountedWolfTimestamp = now;
    uint256 public llamasBought = 0;
    bool public isWolf = false;

    using SafeMath for uint256;

    constructor() public{
        balances[msg.sender] = totalSupply;
        deployer = msg.sender;
        checkout(msg.sender);
    }
    
    function setExchange(address exchangeAddress) public {
        require(msg.sender == deployer);
        require(exchange == 0x0000000000000000000000000000000000000000);
        exchange = exchangeAddress;
    }
    
    function setWool(address woolAddress) public {
        require(msg.sender == deployer);
        require(wool == 0x0000000000000000000000000000000000000000);
        wool = woolAddress;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        if (msg.sender == exchange) {
            llamasBought += numTokens;
        }
        checkout(msg.sender);
        checkout(receiver);
        checkWolf();
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        if (owner == exchange) {
            llamasBought += numTokens;
        }
        checkout(owner);
        checkout(buyer);
        checkWolf();
        return true;
    }
    
    function checkout(address who) private {
        uint256 pendingReward = calculatePendingReward(who);
        checkpointUnclaimedReward[who] += pendingReward;
        checkpointTimestamp[who] = now;
        checkpointWolfTimer[who] = wolfTimer;
        checkpointAmount[who] = balances[who];
        
    }
    
    function calculatePendingReward(address who) public view returns (uint256) {
        uint256 timer = now.add(checkpointWolfTimer[who]);
        uint256 timerDecrement = checkpointTimestamp[who].add(wolfTimer);
        if (timer < timerDecrement) {
            return 0;
        }
        return checkpointAmount[who].mul(timer.sub(timerDecrement)).mul(16530000000);
    }
    
    function claim() public {
        require(!isWolf);
        uint256 pendingReward = calculatePendingReward(msg.sender);
        IWool(wool).mint(msg.sender, pendingReward.add(checkpointUnclaimedReward[msg.sender]));
        checkout(msg.sender);
        checkpointUnclaimedReward[msg.sender] = 0;
    }
    
    function breed(uint256 amount) public {
        require (IWool(wool).balanceOf(msg.sender).div(10000000000000000000) >= amount);
        balances[msg.sender] += amount;
        totalSupply += amount;
        IWool(wool).burnFrom(msg.sender, amount.mul(10000000000000000000));
        checkout(msg.sender);
    }
    
    function checkWolf() private {
        if (now > lastWolfTimestamp) {
            lastWolfTimestamp = lastWolfTimestamp + 604800;
            if (llamasBought < 100000) {
                isWolf = true;
                lastaccountedWolfTimestamp = lastWolfTimestamp - 604800;
            } else {
                llamasBought = 0;
            }
        }
        if (isWolf) {
            wolfTimer += now - lastaccountedWolfTimestamp;
            lastaccountedWolfTimestamp = now;
            if (llamasBought > 100000) {
                isWolf = false;
                llamasBought = 0;
            }
        }
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
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
}