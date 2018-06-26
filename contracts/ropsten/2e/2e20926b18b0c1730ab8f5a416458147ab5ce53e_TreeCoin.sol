pragma solidity ^0.4.18;
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}







// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function balanceOf(address _owner) public view returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);

}



// ERC20
contract ERC20Token is ERC20Interface, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);



    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn&#39;t
    */

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn&#39;t
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        also, to minimize the risk of the approve/transferFrom attack vector
        (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn&#39;t
    */

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address _owner, address _spender) view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }


}



// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract TreeCoin is ERC20Token, Owned {

    string public constant name = &quot;Tree Coin&quot;;
    string public constant symbol = &quot;TREE&quot;;
    uint8 public constant decimals = 8;

    uint256 constant public TREE_UNIT = 1 * 10**8;

    uint256 public totalSupply = 1 * 10**9 * TREE_UNIT;
    uint256 constant public maxPresaleSupply = 150 * 10**6 * TREE_UNIT;                            // Total presale supply at max bonus
    uint256 constant public incentivisationAllocation = (13 * 10**6 + 5 * 10**5) * TREE_UNIT;      // Incentivisation Allocation = 1.35%
    uint256 constant public advisorsAllocation = 30 * 10**6 * TREE_UNIT;                           // Advisors Allocation = 3%
    uint256 constant public treeTeamAllocation = 70 * 10**6 * TREE_UNIT;                           // Tree Team Allocation
    uint256 constant public miningAllocation = 150 * 10**6 * TREE_UNIT;                            // Mining Allocation
    uint256 constant public reservedAllocation = 250 * 10**6 * TREE_UNIT;                          // Money Tree Reserved Allocation

    uint256 public totalAllocatedToAdvisors;                                                       // Counter to keep track of advisor token allocation
    uint256 public totalAllocatedToTeam;                                                           // Counter to keep track of team token allocation

    uint256 public startDate;
    uint256 public endDate;
    bool internal isReleasedToPublic = false;

    uint256 public weiRaised;

    address public fundsWallet;
    address public advisorAddress;
    address public treeTeamAddress;

    uint256 internal teamTranchesReleased = 0;                          // Track how many tranches (allocations of 12.5% team tokens) have been released
    uint256 internal maxTeamTranches = 6;                               // The number of tranches allowed to the team until depleted



    event PrivateSaleTokenPushed(address indexed buyer, uint256 amount);
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);



    // ----------------------- Modifiers ------------------------


    //Advisor Timelock
    modifier advisorTimelock() {
        // require(now >= endTime + ? * 4 weeks);
        _;
    }

    //Tree Team Timelock
    modifier treeTeamTimelock() {
        // require(now >= endTime + ? * ? weeks);
        _;
    }

    modifier projectUninitialized() {
        require(fundsWallet == 0x0);
        _;
    }



    // -----------------------



    function TreeCoin() {
    }


    function initializeTreeCoinProject(address _fundsWallet, uint256 _startDate, uint256 _endDate, address treeTeamAddress, address advisorAddress)
                        onlyOwner projectUninitialized {

        require(_fundsWallet != 0x0);
        require(_startDate >= getCurrentTimestamp());
        require(_startDate < _endDate);

        startDate = _startDate;
        endDate = _endDate;
        fundsWallet = _fundsWallet;

        balances[0xb1] = safeMul(safeDiv(totalSupply, 100), 50);
        balances[fundsWallet] = safeMul(safeDiv(totalSupply, 100), 50);
    }


    function() payable {
        buyTreeTokens(msg.sender, msg.value);
    }


    function supply() internal returns (uint256) {
        return balances[0xb1];
    }


    function getRateAt(uint256 at) constant returns (uint256) {
        // Rate at preslae and public sale
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 30 days)) {
            return 30000;
        } else if (at < (startDate + 90 days)) {
            return 25000;
        } else {
            return 0;
        }
    }


    function getCurrentTimestamp() internal returns (uint256) {
        return now;
    }

    function push(address buyer, uint256 amount) onlyOwner {
        require(balances[0xb1] >= amount);

        balances[0xb1] = safeSub(balances[0xb1], amount);
        balances[buyer] = safeAdd(balances[buyer], amount);
        PrivateSaleTokenPushed(buyer, amount);
    }


    function buyTreeTokens(address sender, uint256 value) internal {
        require(saleActive());
        require(value >= 1 ether);


        // Match WEI to TREE_UNIT
        uint256 TREEAmount = value / 10 ** 10;
        uint256 updatedWeiRaised = safeAdd(weiRaised, value);

        // Calculate token amount to be purchased and referee check
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 amount = safeMul(TREEAmount, actualRate);

        // We have enough token to sale
        require(supply() >= amount);

        // Transfer
        balances[0xb1] = safeSub(balances[0xb1], amount);
        balances[sender] = safeAdd(balances[sender], amount);
        TokenPurchase(sender, value, amount);

        // Update state.
        weiRaised = updatedWeiRaised;

        // Forward the fund to fund collection wallet.
        fundsWallet.transfer(msg.value);
    }


    function saleActive() public view returns (bool) {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() < endDate && supply() > 0);
    }


    function finalize() onlyOwner {
        require(!saleActive());

        balances[fundsWallet] = safeAdd(balances[fundsWallet], balances[0xb1]);
        balances[0xb1] = 0;
    }



    function releaseAdvisorTokens() advisorTimelock onlyOwner returns(bool) {
        require(totalAllocatedToAdvisors == 0);

        balances[fundsWallet] = safeSub(balances[fundsWallet], advisorsAllocation);
        balances[advisorAddress] = safeAdd(balances[advisorAddress], advisorsAllocation);
        totalAllocatedToAdvisors = advisorsAllocation;

        Transfer(fundsWallet, advisorAddress, advisorsAllocation);
        return true;
    }


    function releaseTeamTokens() treeTeamTimelock onlyOwner returns(bool) {
        require(totalAllocatedToTeam < treeTeamAllocation);

        uint256 alloc = treeTeamAllocation / 1000;
        uint256 currentTranche = uint256(now - endDate) / 4 weeks;

        if(teamTranchesReleased < maxTeamTranches && currentTranche > teamTranchesReleased) {
            teamTranchesReleased++;

            uint256 amount = safeMul(alloc, 125);
            balances[fundsWallet] = safeSub(balances[fundsWallet], amount);
            balances[treeTeamAddress] = safeAdd(balances[treeTeamAddress], amount);
            Transfer(fundsWallet, treeTeamAddress, amount);
            totalAllocatedToTeam = safeAdd(totalAllocatedToTeam, amount);
            return true;
        }
        revert();
    }

    function allowTransfers() onlyOwner {
        isReleasedToPublic = true;
    }

    function isTransferAllowed() internal view returns(bool) {
        if (now > endDate || isReleasedToPublic == true) {
            return true;
        }
        return false;
    }

    // Override ERC20 transfer
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (isTransferAllowed() == true || msg.sender == fundsWallet) {
            assert(super.transfer(_to, _value));
            return true;
        }
        revert();
    }

    // Override ERC20 transferFrom
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (isTransferAllowed() == true || msg.sender == fundsWallet) {
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }


}