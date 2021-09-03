/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts/helpers/Ownable.sol

pragma solidity 0.8.7;

contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File contracts/token/AIOW.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract AIOW is Ownable {
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 constant PERC_BASE = 10000; // = 100.00 %
    uint256 public constant SECONDS_IN_ONE_DAY = 86400;

    mapping(address => TransferRuleOutbound) public transferRulesOutbound;
    mapping(address => TransferRuleInbound[]) public transferRulesInbound;
    enum TransferRuleType { inbound, outbound }
    uint256 private ruleIdCounter;
    
    struct TransferRuleOutbound {
        uint8 id;
        uint32 timelockUntil;        
        uint16 vestingDurationDays;
        uint16 vestingStartsAfterDays;
        uint16 percUnlockedAtTimeUnlock;
    }
    
    struct TransferRuleInbound {
        uint8 id;
        uint32 timelockUntil;
        uint16 vestingDurationDays;
        uint16 vestingStartsAfterDays;
        uint16 percUnlockedAtTimeUnlock;
        uint96 tokens;
        bool isPool;
    }
    
    event TransferRuleInboundRegistered(address addr, TransferRuleInbound rule);  
    event TransferRuleOutboundRegistered(address addr, TransferRuleOutbound rule);  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 totalSupply_) {
        name = "AIOW";
        symbol = "AIOW";
        decimals = 18;
        
        // mint the total supply to the deployer
        totalSupply += totalSupply_;
        _balances[msg.sender] += totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {
        // apply all the rules to verify the transferred amount is not above the total amount of unlocked tokens
        require(amount_ <= calcBalanceUnlocked(from_), "insufficient unlocked tokens");
        
        // if the recipient is a pool, transfer the tokens to the inbound rule of the pool
        if (transferRulesInbound[to_].length >= 1 && transferRulesInbound[to_][0].isPool) {
            transferRulesInbound[to_][0].tokens += uint96(amount_);
            return;
        }
        
        // if there is an outbound rule we need to apply the outbound rule
        if (transferRulesOutbound[from_].id != 0) {
        
            TransferRuleOutbound memory trFromOutbound = transferRulesOutbound[from_];
                        
            bool foundMatchingToRule = false;
            
            // check if this outbound rule already exists inside the inbound rules of the recipient
            for (uint256 i = 0; i < transferRulesInbound[to_].length; i++) {
                if (trFromOutbound.id == transferRulesInbound[to_][i].id) {
                    // if so increment the balance inside that rule
                    foundMatchingToRule = true;
                    transferRulesInbound[to_][i].tokens += uint96(amount_);
                    break;
                }
            }
            
            // if we didnt find a matching rule, create it for the recipient
            if (!foundMatchingToRule) {
                transferRulesInbound[to_].push(TransferRuleInbound({
                    id: trFromOutbound.id,
                    timelockUntil: trFromOutbound.timelockUntil,
                    vestingStartsAfterDays: trFromOutbound.vestingStartsAfterDays,
                    vestingDurationDays: trFromOutbound.vestingDurationDays,
                    percUnlockedAtTimeUnlock: trFromOutbound.percUnlockedAtTimeUnlock,
                    tokens: uint96(amount_),
                    isPool: false
                })); 
            }  
        }
    }

    function calcBalanceUnlocked(address account_) public view returns (uint) {
        return _balances[account_] - calcBalanceLocked(account_);
    }
    
    function calcBalanceLockedOfInboundRule(TransferRuleInbound memory trInbound) internal view returns (uint) {
        if (trInbound.timelockUntil > uint32(block.timestamp)) {
            // the tokens of this rule are still all locked
            return trInbound.tokens;
        }
        
        if (trInbound.percUnlockedAtTimeUnlock > 0) {
            // deduct the immediately unlocked amount of tokens from the rule's amount of locked tokens
            trInbound.tokens -= uint96(trInbound.tokens * trInbound.percUnlockedAtTimeUnlock / PERC_BASE);
        }
        
        if (trInbound.vestingDurationDays > 0) {
            uint256 daysPassedSinceUnlock = (uint32(block.timestamp) - trInbound.timelockUntil) / SECONDS_IN_ONE_DAY;
            if (daysPassedSinceUnlock <= trInbound.vestingStartsAfterDays) {
                // vesting didnt yet start
                return trInbound.tokens;
            }
            
            uint256 daysPassedSinceVestingStart = daysPassedSinceUnlock - trInbound.vestingStartsAfterDays;
            
            if (daysPassedSinceVestingStart >= trInbound.vestingDurationDays) {
                // the entire vesting period has ended, so all tokens of this rule are unlocked
                // this also ensures the last day's tokens pays out all the remaining tokens
                // since due to integer floor division the per day amount might be slightly less than the
                // total amount
                return 0;
            }
            
            // calculate how many of the tokens are still locked
            uint256 amountUnlockedPerDay = trInbound.tokens / trInbound.vestingDurationDays;
            uint256 totalUnlocked = daysPassedSinceVestingStart * amountUnlockedPerDay;
            return trInbound.tokens - totalUnlocked;
        } 
        
        // this can only mean there is no vesting, and the timelock already passed, so all tokens are unlocked
        return 0;
    }
    
    function calcBalanceLocked(address account_) public view returns (uint) {
        uint256 lockedTokens = 0;
        
        // check the amount of locked tokens for each of the inbound rules on this account
        for (uint256 i = 0; i < transferRulesInbound[account_].length; i++) {
            TransferRuleInbound memory trFromInbound = transferRulesInbound[account_][i];
            lockedTokens += calcBalanceLockedOfInboundRule(trFromInbound);
        }

        return lockedTokens;
    }
    
    function registerTransferRule(
        address account_, 
        TransferRuleType ruleType, 
        uint32 timelockUntil_, 
        uint16 vestingStartsAfterDays_,
        uint16 vestingDurationDays_, 
        uint16 percUnlockedAtTimeUnlock_, 
        bool isPool_
    ) public onlyOwner {
        require(account_ != address(0), 'account is address zero');
        require(timelockUntil_ > uint32(block.timestamp), 'timelockUntil already passed');
        require(percUnlockedAtTimeUnlock_ > 0 || vestingDurationDays_ > 0, 'percUnlockedAtTimeUnlock and vestingDurationDays are zero');
        require(percUnlockedAtTimeUnlock_ <= uint16(PERC_BASE), 'percUnlockedAtTimeUnlock above 100%');
        
        if (ruleType == TransferRuleType.outbound) {
            require(transferRulesOutbound[account_].id == 0, 'account already has outbound rule');
            
            transferRulesOutbound[account_] = TransferRuleOutbound({
                id: uint8(++ruleIdCounter), // first rule will get id 1
                timelockUntil: timelockUntil_,
                vestingDurationDays: vestingDurationDays_,
                vestingStartsAfterDays: vestingStartsAfterDays_,
                percUnlockedAtTimeUnlock: percUnlockedAtTimeUnlock_
            });

            emit TransferRuleOutboundRegistered(account_, transferRulesOutbound[account_]);
        }
        else { // ruleType == TransferRuleType.inbound
            transferRulesInbound[account_].push(TransferRuleInbound({
                id: uint8(++ruleIdCounter), // first rule will get id 1
                timelockUntil: timelockUntil_,
                vestingDurationDays: vestingDurationDays_,
                vestingStartsAfterDays: vestingStartsAfterDays_,                
                percUnlockedAtTimeUnlock: percUnlockedAtTimeUnlock_,
                tokens: 0,
                isPool: isPool_
            }));

            emit TransferRuleInboundRegistered(account_, transferRulesInbound[account_][transferRulesInbound[account_].length - 1]);
        }
    }
        
    function balanceOf(address account_) public view returns (uint256) {
        return _balances[account_];
    }
    
    function allowance(address owner_, address spender_) public view returns (uint256) {
        return _allowances[owner_][spender_];
    }
    
    function transfer(address recipient_, uint256 amount_) public returns (bool) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }
    
    function transferFrom(address sender_, address recipient_, uint256 amount_) public returns (bool) {
        _transfer(sender_, recipient_, amount_);
        uint256 currentAllowance = _allowances[sender_][msg.sender];
        require(currentAllowance >= amount_, "ERC20: transfer amount exceeds allowance");
        _approve(sender_, msg.sender, currentAllowance - amount_);
        return true;
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender_, recipient_, amount_);
        uint256 senderBalance = _balances[sender_];
        require(senderBalance >= amount_, "ERC20: transfer amount exceeds balance");
        _balances[sender_] = senderBalance - amount_;
        _balances[recipient_] += amount_;
        emit Transfer(sender_, recipient_, amount_);
    }
    
    function approve(address spender_, uint256 amount_) public returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }
    
    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
        _approve(msg.sender, spender_, _allowances[msg.sender][spender_] + addedValue_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender_];
        require(currentAllowance >= subtractedValue_, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender_, currentAllowance - subtractedValue_);
        return true;
    }
    
    function _approve(address owner_, address spender_, uint256 amount_) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
    
    function balanceStatsOf(address account_) public view returns (
        uint256 balanceTotal, 
        uint256 balanceLocked, 
        uint256 balanceUnlocked
    ) {
        return (
            _balances[account_],
            calcBalanceLocked(account_),
            calcBalanceUnlocked(account_)
        );
    }
    
    // gives incorrect results if percUnlockedAtUnlock > 0, i.e. do not use if percUnlockedAtUnlock > 0
    function inboundRuleStatsOf(address account_, uint256 ruleId_) public view returns (
        uint256 ruleBalanceTotal,
        uint256 ruleBalanceLocked,
        uint256 ruleBalanceUnlocked
    ) {
        for (uint256 i = 0; i < transferRulesInbound[account_].length; i++) {
            if (transferRulesInbound[account_][i].id == ruleId_) {
                TransferRuleInbound memory trFromInbound = transferRulesInbound[account_][i];
                uint lockedTokens = calcBalanceLockedOfInboundRule(trFromInbound);
                uint unlockedTokens = trFromInbound.tokens - lockedTokens;
                return (trFromInbound.tokens, lockedTokens, unlockedTokens);
            }
        }
        revert('didnt find matching rule');
    }
    
    function getInboundTransferRules(address _a) external view returns (TransferRuleInbound[] memory) {
        return transferRulesInbound[_a];
    }    
}