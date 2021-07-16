//SourceUnit: peacock.sol

pragma solidity ^0.4.25;

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public;
}

// ----------------------------------------------------------------------------
// TRON TRC20
// ----------------------------------------------------------------------------
contract TRC20Interface {
    function totalSupply() public constant returns (uint256);

    function balanceOf(address tokenOwner)
        public
        constant
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        constant
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event ReceiveTRX(address sender, uint256 amount);

    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// NAME : PEACOCK
// PEACOCK.io
// ----------------------------------------------------------------------------
contract PEACOCK is Owned, TRC20Interface {
    string public symbol;
    string public name;

    // support variable
    uint256 public decimals;
    uint256 public _mega;

    uint256 _totalSupply;

    uint256 _playCount;
    uint256 _winCount;
    uint256 _totalBet;
    uint256 _totalReward;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) public receivedTRX;

    event ReceiveTRX(address buyer, uint256 amount);
    event TakeFee(uint256 amount);
    event Bet(address player, uint256 amount);
    event BetInfo(address player, uint256 amount, string info);
    event Reward(address player, uint256 amount);

    constructor() public {
        decimals = 6;

        symbol = "PCKF";
        name = "PEACOCK";
        _totalSupply = 333333333e6;
        balances[owner] = _totalSupply;

        _playCount = 0;
        _winCount = 0;
        _totalBet = 0;
        _totalReward = 0;

        emit Transfer(address(0), owner, _totalSupply);
    }

    // ----------------------------------------------------------------------------
    // TRC20
    // ----------------------------------------------------------------------------
    function totalSupply() public view returns (uint256 amount) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        require(msg.sender == address(owner));

        require(balances[from] >= tokens);
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    // ----------------------------------------------------------------------------
    // CUSTOM
    // ----------------------------------------------------------------------------
    function mintToken(address to, uint256 amount) public onlyOwner {
        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(owner), to, amount);
    }

    function() public payable {
        receivedTRX[msg.sender] = msg.value;
        emit ReceiveTRX(msg.sender, msg.value);
    }

    // ----------------------------------------------------------------------------
    // Player buy chips : TRX TO TOKEN
    // ----------------------------------------------------------------------------
    function buy() external payable {
        address ownAddress = address(owner);
        address to = msg.sender;
        transferFrom(ownAddress, to, msg.value);
    }

    function buyFrom(address from) external {
        address ownAddress = address(owner);
        transferFrom(ownAddress, from, msg.value);
    }

    // ----------------------------------------------------------------------------
    // Player sell chips : TOKEN TO TRX
    // ----------------------------------------------------------------------------
    function sell(uint256 tokens) public {
        address ownAddress = address(owner);
        require(ownAddress.balance >= tokens);
        require(balances[msg.sender] >= tokens);

        transferFrom(msg.sender, ownAddress, tokens);
        msg.sender.transfer(tokens);
    }

    function sellFrom(address from, uint256 tokens) public {
        address ownAddress = address(owner);
        require(ownAddress.balance >= tokens);
        require(balances[from] >= tokens);

        transferFrom(from, ownAddress, tokens);
        from.transfer(tokens);
    }

    // ----------------------------------------------------------------------------
    // Bet & Reward
    // ----------------------------------------------------------------------------
    function bet() external payable returns (uint256 amount) {
        _totalBet += msg.value;
        _playCount += 1;

        address player = msg.sender;
        emit Bet(player, msg.value);

        return msg.value;
    }

    function betinfo(string info) external payable returns (string) {
        _totalBet += msg.value;
        _playCount += 1;

        address player = msg.sender;
        emit BetInfo(player, msg.value, info);

        return info;
    }

    function reward(
        address player,
        uint256 _reward,
        uint256 _draw
    ) public onlyOwner returns (uint256 profit) {
        _totalReward += _reward;
        if (_reward > _draw) {
            _winCount += 1;
        }

        address ownAddress = address(owner);
        require(ownAddress.balance >= _reward);
        player.transfer(_reward);
        emit Reward(player, _reward);

        if (_reward < _draw) return 0;
        else return _reward - _draw;
    }

    function betreward() external payable returns (uint256 amount) {
        _totalBet += msg.value;
        _playCount += 1;

        address player = msg.sender;
        emit Bet(player, msg.value);

        address ownAddress = address(owner);
        require(ownAddress.balance >= msg.value);

        player.transfer(msg.value);
        emit Reward(player, msg.value);

        return msg.value;
    }

    // ----------------------------------------------------------------------------
    // TAKE TRX
    // ----------------------------------------------------------------------------
    function takeFee(uint256 amount)
        public
        onlyOwner
        returns (uint256 balance)
    {
        address cont = address(this);
        require(cont.balance >= amount);

        msg.sender.transfer(amount);
        emit TakeFee(amount);
        return cont.balance;
    }

    // ----------------------------------------------------------------------------
    // INFO
    // ----------------------------------------------------------------------------
    function balance() view returns (uint256 balance) {
        address cont = address(this);
        return cont.balance;
    }

    function balanceToken() view returns (uint256 balance) {
        address ownAddress = address(owner);
        return balances[ownAddress];
    }

    function totalBet() view returns (uint256 bet) {
        return _totalBet;
    }

    function playCount() view returns (uint256 count) {
        return _playCount;
    }

    function totalReward() view returns (uint256 reward) {
        return _totalReward;
    }

    function winCount() view returns (uint256 count) {
        return _winCount;
    }
}