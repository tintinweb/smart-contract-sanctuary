/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.4.24;

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


contract CrowdsaleInterface {

    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    mapping(address => uint8) whitelist;
    mapping(uint256 => address) holders;
    mapping(address => uint) maxInvestLimitList;

    uint256 _totalHolders; // you should initialize this to 0 in the constructor

    function enableWhitelist(address[] _addresses) public returns (bool success);
    function setMaximumInvest(address _address, uint _amount) public returns (bool success);

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == 2);
        _;
    }




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

    /**
      * @dev Allows the current owner to transfer control of the contract to a newOwner.
      * @param newOwner The address to transfer ownership to.
      */
    // function transferOwnership(address newOwner) public onlyOwner {
    //     _transferOwnership(newOwner);
    // }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract TokenTemplate is ERC20Interface, CrowdsaleInterface, Owned {
    using SafeMath for uint;

    bytes32 public symbol;
    uint public priceRate;
    uint public minimumInvest;
    bytes32 public  name;
    uint8 public decimals;
    uint _totalSupply;
    uint amountRaised;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(bytes32 _name, bytes32 _symbol, uint _total, uint _weiCostOfEachToken, uint _weiMinimumInvest) public {
        symbol = _symbol;
        name = _name;
        decimals = 18;
        priceRate= _weiCostOfEachToken;
        minimumInvest= _weiMinimumInvest;
        _totalSupply = _total * 10**uint(decimals);

        _totalHolders = 0;

        balances[owner] = _totalSupply;
        holders[_totalHolders] = owner;
        whitelist[owner] = 2;
        maxInvestLimitList[owner] = 0;
        _totalHolders++;


        emit Transfer(address(0), owner, _totalSupply);


    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) onlyWhitelist public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
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
    function approve(address spender, uint tokens) onlyWhitelist public returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) onlyWhitelist public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function enableWhitelist(address[] _addresses) public onlyOwner returns (bool success) {
        for (uint i = 0; i < _addresses.length; i++) {
            _addWalletToWhitelist(_addresses[i]);
        }
        return true;
    }
    function _addWalletToWhitelist(address addr) internal {
        if (whitelist[addr] == 2) {
        } else if (whitelist[addr] == 1) {
            whitelist[addr] = 2;
        } else {
            whitelist[addr] = 2;
            holders[_totalHolders] = addr;
            maxInvestLimitList[addr] = 0;
            _totalHolders++;
        }
    }

    function disableWhitelist(address[] _addresses) public onlyOwner returns (bool success) {
        for (uint i = 0; i < _addresses.length; i++) {
            _disableWhitelist(_addresses[i]);
        }
        return true;
    }

    function _disableWhitelist(address addr) internal {
        if (whitelist[addr] == 2) {
            whitelist[addr] = 1;
        } else {
        }
    }

    function getWhitelist() public view returns (address[] addresses) {

        uint256 j;
        uint256 count = 0;

        for (j=0; j<_totalHolders; j++) {
            if (whitelist[holders[j]] == 2) {
                count = count+1;
            } else {
            }
        }
        address[] memory wlist = new address[](count);

        for (j=0; j<count; j++) {
            if (whitelist[holders[j]] == 2) {
                wlist[j] = holders[j];
            } else {
            }
        }
        return wlist;
    }

    function getBalances() public view returns (address[] _addresses, uint256[] _balances) {
        address[] memory wlist1 = new address[](_totalHolders);
        uint256[] memory wlist2 = new uint256[](_totalHolders);

        for (uint256 j=0; j<_totalHolders; j++) {
            //////if (whitelist[holders[j]] == 2) {
                wlist1[j] = holders[j];
                wlist2[j] = balances[holders[j]];
            //////}
        }
        return (wlist1,wlist2);
    }

    function getBalancesAndMaxLimit() public view returns (address[] _addresses, uint256[] _balances, uint256[] _limits) {
        address[] memory wlist1 = new address[](_totalHolders);
        uint256[] memory wlist2 = new uint256[](_totalHolders);
        uint256[] memory wlist3 = new uint256[](_totalHolders);

        for (uint256 j=0; j<_totalHolders; j++) {
            //////if (whitelist[holders[j]] == 2) {
                wlist1[j] = holders[j];
                wlist2[j] = balances[holders[j]];
                wlist3[j] = maxInvestLimitList[holders[j]];
            //////}
        }
        return (wlist1,wlist2,wlist3);
    }

    function closeCrowdsale() public onlyOwner  {
        crowdsaleClosed = true;
    }

    function safeWithdrawal() public onlyOwner {
        require(crowdsaleClosed);
        require(!fundingGoalReached);

        if (msg.sender.send(amountRaised)) {
            fundingGoalReached = true;
        } else {
            fundingGoalReached = false;
        }

    }

    // immediate withdrawal withou funding goal reached and without crowdsale close
    function immediateWithdrawal() public onlyOwner {
        if (msg.sender.send(amountRaised)) {
            //fundingGoalReached = true;
            amountRaised = 0;
        } else {
            //fundingGoalReached = false;
        }
    }

    function burnTokens(uint token_amount) public onlyOwner {

        require(!crowdsaleClosed);
        balances[owner] = balances[owner].sub(token_amount);
        _totalSupply = _totalSupply.sub(token_amount);
        emit Transfer(owner, address(0), token_amount);
    }

    function mintTokens(uint token_amount) public onlyOwner {
        require(!crowdsaleClosed);
        _totalSupply = _totalSupply.add(token_amount);
        balances[owner] = balances[owner].add(token_amount);
        emit Transfer(address(0), owner, token_amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {

        require(!crowdsaleClosed);

        // enable newOwner to whitelist
        _addWalletToWhitelist(newOwner);

        // puts unrealized tokens to new owner
        uint token_amount = balances[owner];
        balances[owner] = 0;
        balances[newOwner] = balances[newOwner].add(token_amount);
        emit Transfer(owner, newOwner, token_amount);

        // change owner
        _transferOwnership(newOwner);

    }

    function setMaximumInvest(address _address, uint _amount) public onlyOwner returns (bool success) {
        if (whitelist[_address] == 2) {
            maxInvestLimitList[_address] = _amount;
            return true;
        } else {
            return false;
        }
    }

    function setMinimumInvest(uint _weiMinimumInvest) public onlyOwner {
        minimumInvest = _weiMinimumInvest;
    }

    function setPriceRate(uint _weiCostOfEachToken) public onlyOwner {
        priceRate = _weiCostOfEachToken;
    }

    function () payable onlyWhitelist public {

        require(!crowdsaleClosed);
        uint amount = msg.value;
        require(amount >= minimumInvest);
        require(amount.div(priceRate) > 0);
        require( maxInvestLimitList[msg.sender]>=amount || maxInvestLimitList[msg.sender] == 0 );

        uint token_amount = (amount.div(priceRate))*10**18;

        amountRaised = amountRaised.add(amount);

        balances[owner] = balances[owner].sub(token_amount);
        balances[msg.sender] = balances[msg.sender].add(token_amount);
        emit Transfer(owner, msg.sender, token_amount);

    }


}