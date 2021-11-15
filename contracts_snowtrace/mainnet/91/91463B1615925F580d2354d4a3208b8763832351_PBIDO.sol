/**
 *Submitted for verification at snowtrace.io on 2021-11-10
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) external;
}

// ----------------------------------------------------------------------------
// Admin contract
// ----------------------------------------------------------------------------
contract Administration {
    event CEOTransferred(address indexed _from, address indexed _to);
    event Pause();
    event Unpause();

    address payable CEOAddress;

    bool public paused = true;

    modifier onlyCEO() {
        require(msg.sender == CEOAddress);
        _;
    }
    function setCEO(address payable _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        emit CEOTransferred(CEOAddress, _newCEO);
        CEOAddress = _newCEO;
        
    }

    function withdrawBalance() external onlyCEO {
        CEOAddress.transfer(address(this).balance);
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() public onlyCEO whenNotPaused returns(bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyCEO whenPaused returns(bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

contract ERC20 is Context, IERC20, Administration {
    using SafeMath for uint256;
    
    string public symbol;
    string public  name;
    uint256 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) freezed;
    mapping(address => uint256) freezeAmount;
    mapping(address => uint256) unlockTime;
    
    MIMERC20 public mimERC20;
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public override returns (bool success) {
        if(freezed[msg.sender] == false){
            balances[msg.sender] = balances[msg.sender].sub(tokens, "ERC20: transfer amount exceeds allowance");
            balances[to] = balances[to].add(tokens);
            emit Transfer(msg.sender, to, tokens);
        } else {
            if(balances[msg.sender] > freezeAmount[msg.sender]) {
                require(tokens <= balances[msg.sender].sub(freezeAmount[msg.sender], "ERC20: transfer amount exceeds allowance"));
                balances[msg.sender] = balances[msg.sender].sub(tokens, "ERC20: transfer amount exceeds allowance");
                balances[to] = balances[to].add(tokens);
                emit Transfer(msg.sender, to, tokens);
            }
        }
            
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
    function approve(address spender, uint256 tokens) public override returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
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
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens, "ERC20: transfer amount exceeds allowance");
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens, "ERC20: transfer amount exceeds allowance");
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        require(freezed[msg.sender] != true);
        return allowed[tokenOwner][spender];
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function freeze(address user, uint256 amount, uint256 period) public onlyCEO {
        require(balances[user] >= amount);
        freezed[user] = true;
        unlockTime[user] = uint256(now) + period;
        freezeAmount[user] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function unFreeze() public whenNotPaused {
        require(freezed[msg.sender] == true);
        require(unlockTime[msg.sender] < uint256(now));
        freezed[msg.sender] = false;
        freezeAmount[msg.sender] = 0;
    }
    
    function ifFreeze(address user) public view returns (
        bool check, 
        uint256 amount, 
        uint256 timeLeft
    ) {
        check = freezed[user];
        amount = freezeAmount[user];
        timeLeft = unlockTime[user] - uint256(now);
    }

    // ------------------------------------------------------------------------
    // Accept & Send ETH
    // ------------------------------------------------------------------------
    receive() external payable {}
    fallback() external payable {}
    
    function mutipleSendETH(address[] memory receivers, uint256[] memory ethValues) public payable onlyCEO {
        require(receivers.length == ethValues.length);
        uint256 totalAmount;
        for(uint256 k = 0; k < ethValues.length; k++) {
            totalAmount = totalAmount.add(ethValues[k]);
        }
        require(msg.value >= totalAmount);
        for (uint256 i = 0; i < receivers.length; i++) {
            bool sent = payable(receivers[i]).send(ethValues[i]);
            require(sent, "Failed to send Ether");
        }
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, address receiver, uint256 tokens) public payable onlyCEO returns (bool success) {
        return IERC20(tokenAddress).transfer(receiver, tokens);
    }
    
    function mutlipleTransferAnyERC20Token(address tokenAddress, address[] memory receivers, uint256[] memory tokens) public payable onlyCEO {
        for (uint256 i = 0; i < receivers.length; i++) {
            IERC20(tokenAddress).transfer(receivers[i], tokens[i]);
        }
    }
}

interface MIMERC20 {
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract PBIDO is ERC20 {
    using SafeMath for uint256;
    event PBIDOSold(address indexed buyer, uint256 indexed amount);
    
    uint256 public totalPreSale = 3000*10**9;
    uint256 public totalPreSaleLeft = 3000*10**9;
    
    uint256 public mimPrice = 20*10**18;
    
    uint256 public maxPurchase = 100*10**9;
    mapping(address=>uint256) public BuyerQuota;
    mapping(address=>bool) whitelist;
    
    constructor(string memory _name, string memory _symbol, address _MIMaddress) public payable{
        CEOAddress = msg.sender;
        symbol = _symbol;
        name = _name;
        decimals = 9;
        _totalSupply = 0;
        
        MIMERC20 candidateContract = MIMERC20(_MIMaddress);
        mimERC20 = candidateContract;
    }
    
    function setMIMAddress(address _address) external onlyCEO {
        MIMERC20 candidateContract = MIMERC20(_address);
        mimERC20 = candidateContract;
    }
    
    function setMIMPrice(uint256 _amount) public onlyCEO {
        require(_amount > 0);
        mimPrice = _amount;
    }
    
    function setMax(uint256 _max) public onlyCEO {
        require(_max > 0);
        maxPurchase = _max;
    }
    
    function setWhitelist(address _user) public onlyCEO {
        require(!whitelist[_user]);
        whitelist[_user] = true;
    }
    
    function ifWhitelist(address _user) public view returns(bool){
        return whitelist[_user];
    }
    
    function buyPBIDO(uint256 _amount) public whenNotPaused returns(uint256) {
        require(whitelist[msg.sender], "Not on whitelist!");
        require(BuyerQuota[msg.sender].add(_amount) <= maxPurchase, "Exceed MaxPurachse");
        require(mimERC20.allowance(msg.sender, address(this)) >= mimPrice.mul(_amount).div(10**9), "Insuffcient approved MIM");
        mimERC20.transferFrom(msg.sender, address(this), mimPrice.mul(_amount).div(10**9));
        
        _mint(msg.sender, _amount);
        BuyerQuota[msg.sender] = BuyerQuota[msg.sender].add(_amount);
        
        emit PBIDOSold(msg.sender, _amount);
    }
    
    function _mint(address _buyer, uint256 _amount) internal {
        require(totalPreSaleLeft >= _amount, "Not enough IDO quota left");
        _totalSupply = _totalSupply.add(_amount);
        totalPreSaleLeft = totalPreSaleLeft.sub(_amount);
        balances[_buyer] = balances[_buyer].add(_amount);
    }
}