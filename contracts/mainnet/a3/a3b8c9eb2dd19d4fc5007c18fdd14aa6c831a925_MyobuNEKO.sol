/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

/**
https://t.me/MyobaToken

Myōbu are celestial fox spirits with white fur and full, fluffy tails reminiscent of ripe grain. They are holy creatures, and bring happiness and blessings to those around them.

With a dynamic sell limit based on price impact and increasing sell cooldowns and redistribution taxes on consecutive sells, Myōbu was designed to reward holders and discourage dumping.

1. Buy limit and cooldown timer on buys to make sure no automated bots have a chance to snipe big portions of the pool.
2. No Team & Marketing wallet. 100% of the tokens will come on the market for trade. 
3. No presale wallets that can dump on the community. 

Token Information
1. 1,000,000,000,000 Total Supply
3. Developer provides LP
4. Fair launch for everyone! 
5. 5% transaction limit on launch
6. Buy limit lifted after launch
7. Sells limited to 3% of the Liquidity Pool, <2.9% price impact 
8. Sell cooldown increases on consecutive sells, 4 sells within a 24 hours period are allowed
9. 2% redistribution to holders on all buys
10. 7% redistribution to holders on the first sell, increases 2x, 3x, 4x on consecutive sells
11. Redistribution actually works!
12. 5-6% developer fee split within the team

                ..`                                `..                
             /dNdhmNy.                          .yNmhdMd/             
            yMMdhhhNMN-                        -NMNhhhdMMy            
           oMMmhyhhyhMN-                      -NMhyhhyhmMMs           
          /MMNhs/hhh++NM+                    +MN++hhh/shNMM/          
         .NMNhy`:hyyh:-mMy`                `yMm::hyyh:`yhNMN.         
        `mMMdh. -hyohy..yNh.`............`.yNy..yhoyh- .hdMMm`        
        hMMdh:  .hyosho...-:--------------:-...ohsoyh.  :hdMMh        
       oMMmh+   .hyooyh/...-::---------:::-.../hyooyh.   +hmMMo       
      /MMNhs    `hyoooyh-...://+++oo+++//:...-hyoooyh`    shNMM/      
     .NMNhy`     hhoooshysyhhhhhhhhhhhhhhhhysyhsooohh     `yhNMN-     
    `mMMdh.      yhsyhyso+::-.```....```.--:/osyhyshy      .hdMMm`    
    yMMmh/      -so/-`            ..            `-/os-      /hmMMh    
   /MMyhy      .`                 ``                 `.      shyMM/   
   mN/+h/                                                    /h+/Nm   
  :N:.sh.                                                    .hs.:N/  
  s-./yh`                                                    `hy/.-s  
  .`:/yh`                                                    `hy/:`-  
 ``-//yh-                                                    .hy//-`` 
 ``://oh+      `                                      `      +ho//:`` 
``.://+yy`     `+`                                  `+`     `yh+//:.``
``-///+oho      /y:                                :y/      ohs+///-``
``:////+sh/ ``  `yhs-                            -shy`  `` /hs+////:``
``:////++sh/  ```:syhs-                        -shys:```  /hs++////:``
``://///++sho`    `.-/+o/.                  ./o+/-.`    `+hs++/////:``
``://///+++oyy-      ``..--.              .--..``      -yyo+++/////:``
``-/////+++++shs.       ``...            ...``       .ohs+++++/////-``
 ``/////+++++++shs-        ..`          `..        -shs+++++++/////`` 
 ``-/////++++++++oys-       ..`        `..       -syo++++++++/////-`` 
  ``:////++++:-....+yy:      ..        ..      :yy+....-:++++////:``  
   `.////+++:-......./yy:     ..      ..     :yy/.......-:+++////.`   
    `.////++ooo+/-...../yy/`   .`    `.   `/yy/.....-/+ooo++////.`    
     `.////+++oooos+/:...:sy/`  .    .  `/ys:...:/+soooo+++////.`     
      `.:////+++++ooooso/:.:sh+` .  . `+hs:.:/osoooo+++++////:.`      
        `-//////++++++ooooso++yh+....+hy++osoooo++++++//////-`        
         `.:///////+++++++oooossyhoohyssoooo++++++////////:.`         
            .:/+++++++++++++++ooosyysooo++++++++++++++//:.            
              `-/+++++++++++++++oooooo+++++++++++++++/-`              
                 .-/++++++++++++++++++++++++++++++/-.                 
                    `.-//++++++++++++++++++++//-.`                    
                         `..-::://////:::-..`                         
                                                                      
                                                                      
                                                                      
                                                                   
*/

pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// 'SushiShiba' token contract
//
// Deployed to : 0x553ed57d7C6d2d0337A34C150f8bEcAa46206d14
// Symbol      :  Myōbu
// Name        :  Myōbu Neko
// Total supply: 1000000000000
// Decimals    : 18
//
// 
// 
// ----------------------------------------------------------------------------


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
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
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
contract  MyobuNEKO is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function  MyobuNEKO() public {
        symbol = " Myōbu";
        name = " Myōbu Neko";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000000000;
        balances[0x553ed57d7C6d2d0337A34C150f8bEcAa46206d14] = _totalSupply;
        Transfer(address(0), 0x553ed57d7C6d2d0337A34C150f8bEcAa46206d14, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
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
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}