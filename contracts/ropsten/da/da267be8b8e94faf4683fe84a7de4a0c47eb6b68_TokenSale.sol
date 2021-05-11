/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity ^0.4.24;

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


contract Owned {
    
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x60BD067E7436819Ec7532A07D20FC0D51f8AbACB;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    // transfer Ownership to other address
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferred(owner,_newOwner);
        owner = _newOwner;
    }
    
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function mint(address to, uint tokens) public returns (bool success);
    function burn(address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}





contract TokenSale is ERC20Interface, Owned {
    
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    uint public RATE;
    uint public DENOMINATOR;
    uint256 public OPENINGTIME;
    uint256 public CLOSINGTIME;
    bool public isStopped = false;
    
    uint256 constant public maxGasPrice =  1000000000000;    // 1000 Gwei
    uint256 public investorMinCap  = 500000000000000000;    // 0.5 ether
    
    uint256 internal constant lock_total = 10000000 ether;
    address private constant  team_address =0x7b1AB54FC38859C7A443941eAA79C1EAFf01a65b;
    
    uint256 private start_time;
    uint256 private one_year = 31536000;
    
    uint16 public referralCommissionRate = 200;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => bool) public operators;
    mapping(address => address) public referrers; // user address => referrer address
    mapping(address => uint256) public referralsCount; // referrer address => referrals count
    
    event Mint(address indexed to, uint256 amount);
    event ChangeRate(uint256 amount);
    event ChangeOpeningTime(uint256 timestamp);
    event ChangeClosingTime(uint256 timestamp);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    
    event ReferralRecorded(address indexed user, address indexed referrer);
    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyWhenRunning {
        require(!isStopped);
        _;
    }
    
    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }
    

    
    constructor() public {
        symbol = "AXA";
        name = "AXA";
        decimals = 18;
        _totalSupply = 100000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        RATE = 80000000;
        DENOMINATOR = 10000;
        OPENINGTIME = 1620681606;// 
        CLOSINGTIME = 1625952006;// 
        
        start_time = now.add(one_year*2);
        
        emit Transfer(address(0), owner, _totalSupply);
        _lock(team_address);
    }
    
    function _lock(address account) internal {
        balances[account] = balances[account].add(lock_total);
        emit Transfer(owner, account, lock_total);
    }
    
    function() public payable {
        address referrer;
        buyTokens(referrer);
    }
    
    function recordReferral(address _user, address _referrer) internal {
        if (_user != address(0)
            && _referrer != address(0)
            && _user != _referrer
            && referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            referralsCount[_referrer] += 1;
            emit ReferralRecorded(_user, _referrer);
        }
    }
    
    // Pay referral commission to the referrer who referred this user.
    // function payReferralCommission(address _user, uint256 _pending) internal {
    //     // if (address(icebergReferral) != address(0) && referralCommissionRate > 0) {
    //     //     address referrer = icebergReferral.getReferrer(_user);
    //     //     uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

    //     //     if (referrer != address(0) && commissionAmount > 0) {
    //     //         tit.mint(referrer, commissionAmount);//change 
    //     //         emit ReferralCommissionPaid(_user, referrer, commissionAmount);
    //     //     }
    //     // }
        
        
    // }
    
    // Get the referrer address that referred the user
    function getReferrer(address _user) public  view returns (address) {
        return referrers[_user];
    }
    
    function buyTokens(address referrer) onlyWhenRunning public payable {
        require(msg.value > 0);
        require(msg.value >= investorMinCap,"minimum 0.5eth");
        require(block.timestamp >= OPENINGTIME && block.timestamp <= CLOSINGTIME,"timestamp: error");
        uint tokens = msg.value.mul(RATE).div(DENOMINATOR);
        require(balances[owner] >= tokens,"token error");
        
        //record the referrer
        if (referrer != address(0) && msg.sender != referrer ) {
            recordReferral(msg.sender,referrer);
        }
        // address referrer = getReferrer(msg.sender);
        
        if (referrer != address(0)) {
            uint256 commissionAmount = msg.value.mul(referralCommissionRate).div(10000);
            emit ReferralCommissionPaid(msg.sender, referrer, commissionAmount);
        }
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        
        emit Transfer(owner, msg.sender, tokens);
        owner.transfer(msg.value);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        
        if (msg.sender == team_address) {
            require(now > start_time,"transfer timestamp: error");
        }
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        require(spender != address(0));
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(from != address(0));
        require(to != address(0));
        require(tokens > 0);
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        
        if (msg.sender == team_address) {
            require(now > start_time,"transfer timestamp: error");
        }
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require(_spender != address(0));
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    
    function mint(address to, uint256 tokens) public onlyOwner returns (bool success) {
        require(to != address(0), "mint to the zero address");
        _totalSupply = _totalSupply.add(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(address(0), to, tokens);
        return true;
    }
    
    function burn(address to, uint256 tokens) public onlyOwner returns (bool success) {
        require(to != address(0), "burn from the zero address");
        balances[to] = balances[to].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(to, address(0), tokens);
        return true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        RATE =_rate;
        emit ChangeRate(_rate);
    }
    
    function changeOpeningTime(uint256 timestamp) public onlyOwner {
        require(timestamp > 0);
        OPENINGTIME =timestamp;
        emit ChangeOpeningTime(timestamp);
    }
    
    function changeClosingTime(uint256 timestamp) public onlyOwner {
        require(timestamp > 0);
        CLOSINGTIME =timestamp;
        emit ChangeClosingTime(timestamp);
    }
}