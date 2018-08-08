pragma solidity ^0.4.20;

contract ERC20Interface {
 
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

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
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Common uitility functions
// ----------------------------------------------------------------------------
contract Common {
    
    function Common() internal {

    }

    function getIndexOfTarget(address[] list, address addr) internal pure returns (int) {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == addr) {
                return int(i);
            }
        }
        return -1;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    address public operator;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event OperatorTransfered(address indexed _from, address indexed _to);

    function Owned() internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrOperator {
        require(msg.sender == owner || msg.sender == operator);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function transferOperator(address _newOperator) public onlyOwner {
        address originalOperator = operator;
        operator = _newOperator;
        OperatorTransfered(originalOperator, _newOperator);
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract TokenHeld {
    
    address[] public addressIndices;

    event OnPushedAddress(address addr, uint index);

    function TokenHeld() internal {
    }

    // ------------------------------------------------------------------------
    // Scan the addressIndices for ensuring the target address is included
    // ------------------------------------------------------------------------
    function scanAddresses(address addr) internal {
        bool isAddrExist = false;
        for (uint i = 0;i < addressIndices.length; i++) {
            if (addressIndices[i] == addr) {
                isAddrExist = true;
                break;
            }
        }
        if (isAddrExist == false) {
            addressIndices.push(addr);
            OnPushedAddress(addr, addressIndices.length);
        }
    }
}

contract Restricted is Common, Owned {

    bool isChargingTokenTransferFee;
    bool isAllocatingInterest;
    bool isChargingManagementFee;
    bool isTokenTransferOpen;

    address[] tokenTransferDisallowedAddresses;

    event OnIsChargingTokenTransferFeeUpdated(bool from, bool to);
    event OnIsAllocatingInterestUpdated(bool from, bool to);
    event OnIsChargingManagementFeeUpdated(bool from, bool to);
    event OnIsTokenTransferOpenUpdated(bool from, bool to);
    event OnTransferDisallowedAddressesChanged(string action, address indexed addr);
    
    modifier onlyWhenAllocatingInterestOpen {
        require(isAllocatingInterest == true);
        _;
    }

    modifier onlyWhenChargingManagementFeeOpen {
        require(isChargingManagementFee == true);
        _;
    }

    modifier onlyWhenTokenTransferOpen {
        require(isTokenTransferOpen == true);
        _;
    }

    modifier shouldBeAllowed(address[] list, address addr) {
        require(getIndexOfTarget(list, addr) == -1);
        _;
    }
    
    function Restricted() internal {
        isChargingTokenTransferFee = false;
        isAllocatingInterest = false;
        isChargingManagementFee = false;
        isTokenTransferOpen = true;
    }
    
    function setIsChargingTokenTransferFee(bool onOff) public onlyOwnerOrOperator {
        bool original = isChargingTokenTransferFee;
        isChargingTokenTransferFee = onOff;
        OnIsChargingTokenTransferFeeUpdated(original, onOff);
    }

    function setIsAllocatingInterest(bool onOff) public onlyOwnerOrOperator {
        bool original = isAllocatingInterest;
        isAllocatingInterest = onOff;
        OnIsAllocatingInterestUpdated(original, onOff);
    }

    function setIsChargingManagementFee(bool onOff) public onlyOwnerOrOperator {
        bool original = isChargingManagementFee;
        isChargingManagementFee = onOff;
        OnIsChargingManagementFeeUpdated(original, onOff);
    }

    function setIsTokenTransferOpen(bool onOff) public onlyOwnerOrOperator {
        bool original = isTokenTransferOpen;
        isTokenTransferOpen = onOff;
        OnIsTokenTransferOpenUpdated(original, onOff);
    }

    function addToTokenTransferDisallowedList(address addr) public onlyOwnerOrOperator {
        int idx = getIndexOfTarget(tokenTransferDisallowedAddresses, addr);
        if (idx == -1) {
            tokenTransferDisallowedAddresses.push(addr);
            OnTransferDisallowedAddressesChanged("add", addr);
        }
    }

    function removeFromTokenTransferDisallowedAddresses(address addr) public onlyOwnerOrOperator {
        int idx = getIndexOfTarget(tokenTransferDisallowedAddresses, addr);
        if (idx >= 0) {
            uint uidx = uint(idx);
            delete tokenTransferDisallowedAddresses[uidx];
            OnTransferDisallowedAddressesChanged("remove", addr);
        }
    }
}

contract TokenTransaction is Common, Owned {

    bool isTokenTransactionOpen;

    address[] transactionDisallowedAddresses;

    uint exchangeRateFor1Eth;

    event OnIsTokenTransactionOpenUpdated(bool from, bool to);
    event OnTransactionDisallowedAddressesChanged(string action, address indexed addr);
    event OnExchangeRateUpdated(uint from, uint to);

    modifier onlyWhenTokenTransactionOpen {
        require(isTokenTransactionOpen == true);
        _;
    }

    function TokenTransaction() internal {
        isTokenTransactionOpen = true;
        exchangeRateFor1Eth = 1000;
    }

    function setIsTokenTransactionOpen(bool onOff) public onlyOwnerOrOperator {
        bool original = isTokenTransactionOpen;
        isTokenTransactionOpen = onOff;
        OnIsTokenTransactionOpenUpdated(original, onOff);
    }

    function addToTransactionDisallowedList(address addr) public constant onlyOwnerOrOperator {
        int idx = getIndexOfTarget(transactionDisallowedAddresses, addr);
        if (idx == -1) {
            transactionDisallowedAddresses.push(addr);
            OnTransactionDisallowedAddressesChanged("add", addr);
        }
    }

    function removeFromTransactionDisallowedList(address addr) public constant onlyOwnerOrOperator {
        int idx = getIndexOfTarget(transactionDisallowedAddresses, addr);
        if (idx >= 0) {
            uint uidx = uint(idx);
            delete transactionDisallowedAddresses[uidx];
            OnTransactionDisallowedAddressesChanged("remove", addr);
        }
    }

    function updateExchangeRate(uint newExchangeRate) public onlyOwner {
        uint originalRate = exchangeRateFor1Eth;
        exchangeRateFor1Eth = newExchangeRate;
        OnExchangeRateUpdated(originalRate, newExchangeRate);
    }
}

contract Distributed is Owned {
    using SafeMath for uint;
    
    // Allocation related
    uint tokenTransferPercentageNumerator;
    uint tokenTransferPercentageDenominator;
    uint interestAllocationPercentageNumerator;
    uint interestAllocationPercentageDenominator;
    uint managementFeeChargePercentageNumerator;
    uint managementFeeChargePercentageDenominator;

    uint distCompanyPercentage;
    uint distTeamPercentage;
    uint distOfferPercentage;

    event OnPercentageChanged(string state, uint _m, uint _d, uint m, uint d);
    event OnDistributionChanged(uint _c, uint _t, uint _o, uint c, uint t, uint o);
    
    modifier onlyWhenPercentageSettingIsValid(uint c, uint t, uint o) {
        require((c.add(t).add(o)) == 100);
        _;
    }

    function Distributed() internal {

        tokenTransferPercentageNumerator = 1;
        tokenTransferPercentageDenominator = 100;
        interestAllocationPercentageNumerator = 1;
        interestAllocationPercentageDenominator = 100;
        managementFeeChargePercentageNumerator = 1;
        managementFeeChargePercentageDenominator = 100;

        distCompanyPercentage = 20;
        distTeamPercentage = 10;
        distOfferPercentage = 70;
    }

    function setTokenTransferPercentage(uint numerator, uint denominator) public onlyOwnerOrOperator {
        uint m = tokenTransferPercentageNumerator;
        uint d = tokenTransferPercentageDenominator;
        tokenTransferPercentageNumerator = numerator;
        tokenTransferPercentageDenominator = denominator;
        OnPercentageChanged("TokenTransferFee", m, d, numerator, denominator);
    }

    function setInterestAllocationPercentage(uint numerator, uint denominator) public onlyOwnerOrOperator {
        uint m = interestAllocationPercentageNumerator;
        uint d = interestAllocationPercentageDenominator;
        interestAllocationPercentageNumerator = numerator;
        interestAllocationPercentageDenominator = denominator;
        OnPercentageChanged("InterestAllocation", m, d, numerator, denominator);
    }

    function setManagementFeeChargePercentage(uint numerator, uint denominator) public onlyOwnerOrOperator {
        uint m = managementFeeChargePercentageNumerator;
        uint d = managementFeeChargePercentageDenominator;
        managementFeeChargePercentageNumerator = numerator;
        managementFeeChargePercentageDenominator = denominator;
        OnPercentageChanged("ManagementFee", m, d, numerator, denominator);
    }

    function setDistributionPercentage(uint c, uint t, uint o) public onlyWhenPercentageSettingIsValid(c, t, o) onlyOwner {
        uint _c = distCompanyPercentage;
        uint _t = distTeamPercentage;
        uint _o = distOfferPercentage;
        distCompanyPercentage = c;
        distTeamPercentage = t;
        distOfferPercentage = o;
        OnDistributionChanged(_c, _t, _o, distCompanyPercentage, distTeamPercentage, distOfferPercentage);
    }
}

contract FeeCalculation {
    using SafeMath for uint;
    
    function FeeCalculation() internal {

    }

    // ------------------------------------------------------------------------
    // Calculate the fee tokens for transferring.
    // ------------------------------------------------------------------------
    function calculateTransferFee(uint tokens) internal pure returns (uint) {
        uint calFee = 0;
        if (tokens > 0 && tokens <= 1000)
            calFee = 1;
        else if (tokens > 1000 && tokens <= 5000)
            calFee = tokens.mul(1).div(1000);
        else if (tokens > 5000 && tokens <= 10000)
            calFee = tokens.mul(2).div(1000);
        else if (tokens > 10000)
            calFee = 30;
        return calFee;
    }
}

// ----------------------------------------------------------------------------
// initial fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface, Distributed, TokenHeld, Restricted, TokenTransaction, FeeCalculation {
    using SafeMath for uint;

    // Token information related
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event OnAllocated(address indexed addr, uint allocatedTokens);
    event OnCharged(address indexed addr, uint chargedTokens);
    
    modifier onlyWhenOfferredIsLowerThanDistOfferPercentage {
        uint expectedTokens = msg.value.mul(1000);
        uint totalOfferredTokens = 0;
        for (uint i = 0; i < addressIndices.length; i++) {
            totalOfferredTokens += balances[addressIndices[i]];
        }
        require(_totalSupply.mul(distOfferPercentage).div(100) - expectedTokens >= 0);
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function FixedSupplyToken() public {
        symbol = "AGC";
        name = "Agile Coin";
        decimals = 0;
        _totalSupply = 100000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        uint balance = balances[address(0)];
        return _totalSupply - balance;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public onlyWhenTokenTransferOpen shouldBeAllowed(transactionDisallowedAddresses, msg.sender) returns (bool success) {
        uint calFee = isChargingTokenTransferFee ? calculateTransferFee(tokens) : 0;
        scanAddresses(to);
        balances[msg.sender] = balances[msg.sender].sub(tokens + calFee);
		balances[owner] = balances[owner].add(calFee);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        Transfer(msg.sender, owner, calFee);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint tokens) public onlyWhenTokenTransferOpen shouldBeAllowed(tokenTransferDisallowedAddresses, msg.sender) returns (bool success) {
        uint calFee = isChargingTokenTransferFee ? calculateTransferFee(tokens) : 0;
        scanAddresses(to);
        balances[from] = balances[from].sub(tokens + calFee);
        balances[owner] = balances[owner].add(calFee);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        Transfer(from, owner, calFee);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable onlyWhenTokenTransactionOpen onlyWhenOfferredIsLowerThanDistOfferPercentage {
        // Exchange: ETH --> ETTA Coin
        revert();
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Allocate interest.
    // ------------------------------------------------------------------------
    function allocateTokens() public onlyOwnerOrOperator onlyWhenAllocatingInterestOpen {
        for (uint i = 0; i < addressIndices.length; i++) {
            address crntAddr = addressIndices[i];
            uint balanceOfCrntAddr = balances[crntAddr];
            uint allocatedTokens = balanceOfCrntAddr.mul(interestAllocationPercentageNumerator).div(interestAllocationPercentageDenominator);
            balances[crntAddr] = balances[crntAddr].add(allocatedTokens);
            balances[owner] = balances[owner].sub(allocatedTokens);
            Transfer(owner, crntAddr, allocatedTokens);
            OnAllocated(crntAddr, allocatedTokens);
        }
    }

    // ------------------------------------------------------------------------
    // Charge investers for management fee.
    // ------------------------------------------------------------------------
    function chargeTokensForManagement() public onlyOwnerOrOperator onlyWhenChargingManagementFeeOpen {
        for (uint i = 0; i < addressIndices.length; i++) {
            address crntAddr = addressIndices[i];
            uint balanceOfCrntAddr = balances[crntAddr];
            uint chargedTokens = balanceOfCrntAddr.mul(managementFeeChargePercentageNumerator).div(managementFeeChargePercentageDenominator);
            balances[crntAddr] = balances[crntAddr].sub(chargedTokens);
            balances[owner] = balances[owner].add(chargedTokens);
            Transfer(crntAddr,owner, chargedTokens);
            OnCharged(crntAddr, chargedTokens);
        }
    }

    // ------------------------------------------------------------------------
    // Distribute more token of contract and transfer to owner 
    // ------------------------------------------------------------------------
    function mintToken(uint256 mintedAmount) public onlyOwner {
        require(mintedAmount > 0);
        balances[owner] = balances[owner].add(mintedAmount);
        _totalSupply = _totalSupply.add(mintedAmount);
        Transfer(address(0), owner, mintedAmount);
    }

    event OnTokenBurned(uint256 totalBurnedTokens);

    // ------------------------------------------------------------------------
    // Remove `numerator / denominator` % of tokens from the system irreversibly
    // ------------------------------------------------------------------------
    function burnByPercentage(uint8 m, uint8 d) public onlyOwner returns (bool success) {
        require(m > 0 && d > 0 && m <= d);
        uint totalBurnedTokens = balances[owner].mul(m).div(d);
        balances[owner] = balances[owner].sub(totalBurnedTokens);
        _totalSupply = _totalSupply.sub(totalBurnedTokens);
        Transfer(owner, address(0), totalBurnedTokens);
        OnTokenBurned(totalBurnedTokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Remove a quantity of tokens
    // ------------------------------------------------------------------------
    function burnByAmount(uint256 tokens) public onlyOwner returns (bool success) {
        require(tokens > 0 && tokens <= balances[owner]);
        balances[owner] = balances[owner].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        Transfer(owner, address(0), tokens);
        OnTokenBurned(tokens);
        return true;
    }
}