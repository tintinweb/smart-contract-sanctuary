/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity ^0.5.16;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, owner);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract PixelToken is ERC20Interface, Owned, SafeMath {
    string public name = "PixelVerse";
    string public symbol = "PIXEL";
    uint8 public decimals = 18;
    uint public _totalSupply = 1000000000e18;
    bool public isLocked;
    
    address[]   private     blackList;
    address[]   private     vaultList;
    mapping(address => uint) vaultAmount;
    mapping(address => uint) vaultReleaseTime;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address multisig) public {
        balances[multisig] = safeAdd(balances[multisig], _totalSupply);
        isLocked = false;
    }

    modifier isNotLocked {
        require(!isLocked);
        _;
    }

    function setIsLocked(bool _isLocked) public onlyOwner{
        isLocked = _isLocked;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    function isBlacklisted(address account) private view returns(bool) {
        uint i;
        for (i = 0; i < blackList.length; i++) {
            if (blackList[i] == account)
                return true;
        }
        return false;
    }
    
    
    function addBlacklist(address account) public onlyOwner {
        require(account != address(0));
        blackList.push(account);
    }
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public isNotLocked returns (bool success) {
        require(isBlacklisted(msg.sender) == false);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
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
        require(isBlacklisted(msg.sender) == false);
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
    function transferFrom(address from, address to, uint tokens) public isNotLocked returns (bool success) {
        require(isBlacklisted(msg.sender) == false);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
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


    function () external payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // DECREASE token supply
    // ------------------------------------------------------------------------
    function burn(uint amount) public {
        require(amount > 0);
        _burn(msg.sender, amount);
    }

    // ------------------------------------------------------------------------
    // DECREASE token supply
    // ------------------------------------------------------------------------
    function burnFrom(address from, uint amount) public {
        require(allowance(from, msg.sender) >= amount);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], amount);
        _burn(from, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));

        balances[account] = safeSub(balances[account], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Transfer(account, address(0), amount);
    }


    function tokenToVault(address to, uint amount, uint releastTime) public onlyOwner {
        require(to != address(0x0));
        vaultAmount[to] = safeAdd(vaultAmount[to], amount);
        vaultReleaseTime[to] = releastTime;
        _totalSupply = safeAdd(_totalSupply, amount);
        balances[address(this)] = safeAdd(balances[address(this)], amount);
        vaultList.push(to);
    }

    function releaseToken() public {
        require(vaultAmount[msg.sender] > 0);
        require(block.timestamp >= vaultReleaseTime[msg.sender]);
        require(balances[address(this)] >= vaultAmount[msg.sender]);

        balances[msg.sender] = safeAdd(balances[msg.sender], vaultAmount[msg.sender]);
        balances[address(this)] = safeSub(balances[address(this)], vaultAmount[msg.sender]);
        vaultAmount[msg.sender] = 0;
        _removeFromVault(msg.sender);
    }

    function releateTokenTo(address to) public onlyOwner {
        require(vaultAmount[to] > 0);
        require(block.timestamp >= vaultReleaseTime[to]);
        require(balances[address(this)] >= vaultAmount[to]);

        balances[to] = safeAdd(balances[to], vaultAmount[to]);
        balances[address(this)] = safeSub(balances[address(this)], vaultAmount[to]);
        vaultAmount[to] = 0;
        _removeFromVault(to);
    }

    function _removeFromVault(address addr) internal {
        uint index;
        uint length = vaultList.length;
        for (index = 0; index < length; index++){
            if (vaultList[index] == addr) {
              break;
            }
        }

        /// There is no use-case for inexistent
        assert(index < length);
        /// Remove out of list and map
        if ( index + 1 != length ) {
            /// Move the last to the current
            vaultList[index] = vaultList[length - 1];
        }
        delete vaultList[length - 1];
        vaultList.length--;
        delete vaultReleaseTime[addr];
        delete vaultAmount[addr];
    }

    function getVaultAmountFrom(address from) public view onlyOwner returns (uint amount) {
        return vaultAmount[from];
    }

    function getVaultAmount() public view returns (uint amount) {
        return vaultAmount[msg.sender];
    }

    function getVaultReleaseTimeFrom(address from) public view onlyOwner returns (uint releaseTime) {
        return vaultReleaseTime[from];
    }

    function getVaultReleaseTime() public view returns (uint releaseTime) {
        return vaultReleaseTime[msg.sender];
    }

    function getVaultList() public view onlyOwner returns (address[] memory list) {
        return vaultList;
    }
}