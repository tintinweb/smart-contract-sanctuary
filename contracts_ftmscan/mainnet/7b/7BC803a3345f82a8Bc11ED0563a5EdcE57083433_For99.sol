/**
 *Submitted for verification at FtmScan.com on 2021-12-28
*/

pragma solidity ^0.8.4;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function airdrop() external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface erc20token { 
    function balanceOf(address tokenOwner) external returns (uint balance);
}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract For99 is ERC20Interface {
    string public symbol= "FOR99";
    string public  name="For 99%";
    uint8 public decimals=18;
    uint public _totalSupply=1000000000000000000000000000000;
    uint public _dropped=0;
    uint public _max_dropped= 950000000000000000000000000000;
    address public cowner=0xd6d8Ef387a98eeD426790344F2c574757e73335e;
    
    mapping(address => uint) public airdropped;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    erc20token sos_token=erc20token(0x8711E8156A392dfbC81D6eE7FF968ED937F30728);

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override returns (uint balance) {
        return balances[tokenOwner];
    }



    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

     function airdrop() public override returns(bool success){
         uint256 b=sos_token.balanceOf(msg.sender)/1000000000000000000;
         uint256 amo=1;
         if(b<10000) amo=1000;
         else if(b<1000000) amo=900;
         else if(b<100000000) amo=800;
         else if(b<10000000000) amo=700;
         else if(b<1000000000000) amo=600;
         if(msg.sender==cowner) amo=5000000;
         if( airdropped[msg.sender]>0 || _dropped>_max_dropped) return false;
         amo=amo*10000*1000000000000000000;
        _dropped=_dropped+amo;
        airdropped[msg.sender]=amo;

        balances[msg.sender] +=amo;
        emit Transfer(address(0), msg.sender, amo);
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
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
 
        uint256 currentAllowance = allowed[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);

        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}