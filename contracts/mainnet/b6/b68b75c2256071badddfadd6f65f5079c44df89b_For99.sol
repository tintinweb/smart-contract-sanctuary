/**
 *Submitted for verification at Etherscan.io on 2021-12-30
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
    function airdrop(address inviter) external returns(bool success);
    function stake() external returns(bool success);
    function unstake() external returns(bool success);
     
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
    string public symbol= "SOS99";
    string public  name="SOSDAO";
    uint8 public decimals=18;
    uint public _totalSupply=1000000000000000000000000000000;
    uint public _maxairdrop= 950000000000000000000000000000;
    uint public _stakedTotal=0;
    uint public _stakeAmount=10000*10000*1000000000000000000;//100m
    uint public _stakeRewardPerDay=1000*10000*1000000000000000000;//10m per day

    uint public _dropped=0;
    uint public _burn=2;
    address public cowner=0xf7f3dC9f2410c557e015923941ecf9EaE26ddD74;
    erc20token sos_token=erc20token(0x3b484b82567a09e2588A13D54D032153f0c0aEe0);
    
    mapping(address => uint) public airdropped;
    mapping(address => uint) public staked;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

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
        uint256 burnamo=(amount*_burn)/100;
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount-burnamo;
        balances[address(0)]+=burnamo;

        emit Transfer(sender, recipient, amount);

    }

     function airdrop(address inviter) public override returns(bool success){
         require(inviter != address(0), "Inviter can not be a zero address");
         require(inviter != msg.sender, "Inviter can not be a its self");
         uint256 b=sos_token.balanceOf(msg.sender)/1000000000000000000;
         uint256 amo=1;
         uint256 rewards=100*10000*1000000000000000000;
         if(b<10000) amo=1000;
         else if(b<1000000) amo=900;
         else if(b<100000000) amo=800;
         else if(b<10000000000) amo=700;
         else if(b<1000000000000) amo=600;
         if(msg.sender==cowner) amo=5000000;
         if( airdropped[msg.sender]>0 || _dropped>_maxairdrop) return false;
         amo=amo*10000*1000000000000000000;
        _dropped+=amo+rewards;
        airdropped[msg.sender]=amo;

        balances[msg.sender] +=amo;
        balances[inviter] +=rewards;
        balances[cowner] +=rewards;
        emit Transfer(address(0), msg.sender, amo);
        return true;
     }
     
     function stake() public override returns(bool success){
         if(balances[msg.sender]>= _stakeAmount && staked[msg.sender]==0){
            _stakedTotal+=_stakeAmount;
            balances[msg.sender]-= _stakeAmount;
            staked[msg.sender]=block.timestamp;
            emit Transfer(msg.sender, address(0), _stakeAmount);
            return true;
         }else{
             return false;
         }
     }
    function unstake() public override returns(bool success){
        if(staked[msg.sender]>0){
            uint d=10000*(block.timestamp-staked[msg.sender])/(24*60*60);
            uint reward=_stakeRewardPerDay*d/10000;
            if( (_dropped+reward)>_maxairdrop) reward=0;

            staked[msg.sender]=0;
            _stakedTotal-=_stakeAmount;
            balances[msg.sender]+= _stakeAmount+reward;
            _dropped+=reward;
            emit Transfer(address(0), msg.sender, _stakeAmount+reward);
            return true;
        }else{
            return false;
        }

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