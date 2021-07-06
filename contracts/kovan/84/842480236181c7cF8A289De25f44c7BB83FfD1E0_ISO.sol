/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface UniswapV2Router{
    function WETH(
        ) external pure returns (address);
    function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external payable returns (
        uint amountToken, 
        uint amountETH, 
        uint liquidity);
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA, 
        address tokenB
    ) external view returns (address pair);
}

interface Whitelist {
    function isWhitelisted(address _user) external view returns(bool);
    function getAmount(address _user) external view returns(uint);
    function getBatch(uint _batchId) external view returns(address[] memory batchList);
}

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract ISO is Ownable {
    
    IERC20 private token;
    UniswapV2Router private uniswap;
    IUniswapV2Factory private factory;
    Whitelist private _whitelist;
    
    address payable public platformWallet;
    address public poolStake;
    uint private _scaling = uint(10) ** 12;
    uint public price;
    uint private start;
    uint private duration;
    uint private _scaledRemainder;
    uint private _totalBought;
    uint private _totalBonus;
    uint private _totalDividends;
    uint private _phase = 1;
    uint private _totalRestakedDividends;
    bool public isOpen;
    bool public initialized;
    uint public softcap;
    uint public hardcap;
    uint public minInvest;
    uint public maxInvest;
    uint public percentLiquidity;                       //1% = 10000
    uint public teamTokenShare;                         //1% = 10000
    uint public platformShare;                         //1% = 10000
    uint public salePeriod;
    uint public stakePeriod;
    uint public lpLockPeriod;
    uint public totalSupply;
    uint public totalToSell;
    uint public totalToLiquidate;
    uint public totalForBonus;
    uint private constant DIVISOR = 100 * 10000;
    
    struct User {
        uint contribution;
        uint tokenBought;
        uint bonus;
        uint remainder;
        uint phase;
        uint fromTotalDivs;
        uint restakedDivs;
    }
    
    mapping(address => User) private _users;
    mapping(uint => uint) private _payouts;
    
    event SalesStarted(
            address indexed sender, 
            uint timestamp);
    
    event NewInvestment(
            address indexed sender, 
            uint amount,
            uint tokenAmount,
            uint bonus);
    
    event LiquidityDeposited(
            address indexed sender, 
            uint timestamp,
            uint ethAmount,
            uint tokenAmount,
            uint liquidity );
    
    event Claimed(
            address indexed sender, 
            uint amount);
    
    event Unstaked(
            address indexed sender, 
            uint basic, 
            uint bonus,
            uint lostBonus);
            
    event Withdrawn(
            address indexed sender, 
            uint basic, 
            uint bonus);
            
    event Restaked(
            address indexed sender, 
            uint amount);
            
    event Refunded(
            address indexed sender, 
            uint amount);
    
    event TeamRefunded(
            address indexed sender, 
            uint amount);

    constructor(
        address __whitelist,
        address _token,
        address _poolStake,
        uint _softcap,
        uint _hardcap,
        uint _percentLiquidity,
        uint _salePeriod,
        uint _stakePeriod,
        uint _teamTokenShare,
        uint _totalSupply
    ) {
        _whitelist = Whitelist(__whitelist);
        poolStake = _poolStake;
        token = IERC20(_token);
        softcap = _softcap;
        hardcap = _hardcap;
        percentLiquidity = _percentLiquidity;
        salePeriod = _salePeriod;
        stakePeriod = _stakePeriod;
        teamTokenShare = _teamTokenShare;
        totalSupply = _totalSupply;
        platformShare = 20000;
        uniswap = UniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);      //kovan
        factory = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);    //kovan
    }
    
    modifier onlyWhitelisted(
        address _user
        ) {
        require(
            _whitelist.isWhitelisted(_user),
            "Only whitelisted users allowed"
        );
        _;
    }
    
    function initialize(
        uint _softcap,
        uint _hardcap,
        uint _minInvest,
        uint _maxInvest,
        uint _percentLiquidity,
        uint _salePeriod,
        uint _stakePeriod,
        uint _lpLockPeriod,
        uint _teamTokenShare,
        uint _totalSupply
        ) external onlyOwner returns(bool _initialized) {
        require(!initialized, "already been initialized");
        require(
            token.transferFrom(
                msg.sender, 
                address(this), 
                totalSupply
            ),
            "Error in taking total supply"
        );
        
        uint quantity = (
            _totalSupply - (
                _totalSupply * (
                    _teamTokenShare / (
                        DIVISOR)))) / 3;
        totalToLiquidate = quantity;
        totalToSell = quantity;
        totalForBonus = quantity;
        price = _hardcap / quantity;
        softcap = _softcap;
        hardcap = _hardcap;
        minInvest = _minInvest;
        maxInvest = _maxInvest;
        totalSupply = _totalSupply;
        lpLockPeriod = _lpLockPeriod + block.timestamp;
        teamTokenShare = _teamTokenShare;
        percentLiquidity = _percentLiquidity;
        salePeriod = _salePeriod + block.timestamp;
        stakePeriod = _stakePeriod + block.timestamp;
        initialized = true;
        isOpen = true;
        emit SalesStarted(msg.sender, block.timestamp);
        return true;
    }

    function invest(
        ) external 
        payable 
        onlyWhitelisted(msg.sender) {
        require(
            initialized, 
            "entry not initialized"
        );
        require(
            isOpen, 
            "entry not open"
        );
        require(
            msg.value >= minInvest && 
            msg.value <= maxInvest,
            "Must invest within range"
        );

        uint quantity = price * msg.value;
        require(
            totalToSell >= quantity, 
            "Not enough tokens available"
        );
        
        totalToSell -= quantity;
        _totalBought += quantity;
        _totalBonus += quantity;
        _users[msg.sender].contribution += msg.value;
        _users[msg.sender].tokenBought += quantity;
        _users[msg.sender].bonus += quantity;

        emit NewInvestment(
            msg.sender, msg.value, quantity, quantity
        );
    }
    
    function depositLiquidity(
        ) external 
        returns(bool) {
            
        require(
            initialized, 
            "entry has not been initialized"
        );
        require(
            isOpen, 
            "entry is already closed"
        );
        
        uint raised = address(this).balance;
        require(
            raised >= softcap, 
            "project did not reach softcap"
        );
        
        require(
            block.timestamp > salePeriod 
            || raised >= hardcap,
            "sale period still ongoing"
        );
        
        isOpen = false;
        start = block.timestamp;
        
        uint forLiquidity = raised * (percentLiquidity / DIVISOR);
        uint fee = (raised - forLiquidity) * (platformShare / DIVISOR);
        
        platformWallet.transfer(fee);
        
        token.approve(address(uniswap), totalToLiquidate);

        (uint amountToken, uint amountETH, uint liquidity) = 
        uniswap.addLiquidityETH{ value: forLiquidity }(
            address(token), 
            totalToLiquidate, 
            0, 
            0, 
            address(this), 
            block.timestamp);
        
        emit LiquidityDeposited(
            msg.sender, block.timestamp, amountETH, amountToken, liquidity
        );
        return true;
    }
    
    function userRefund(
        ) external onlyWhitelisted(msg.sender) returns(bool returned) {
        
        require(
            initialized, 
            "entry has not been initialized"
        );
        require(
            isOpen, 
            "entry is already closed"
        );
        require(
            block.timestamp > salePeriod, 
            "sale period still ongoing"
        );
        uint raised = address(this).balance;
        require(
            raised < softcap, 
            "project reached softcap"
        );
        
        uint contribution = _users[msg.sender].contribution;
        require(
            contribution > 0, 
            "No contribution was made"
        );
        
        _users[msg.sender].contribution = 0;
        
        uint bought = _users[msg.sender].tokenBought;
        _users[msg.sender].tokenBought = 0;
        _users[msg.sender].bonus = 0;
        
        totalToSell -= bought;
        _totalBought -= bought;
        _totalBonus -= bought;
        
        payable(msg.sender).transfer(contribution);
        emit Refunded(msg.sender, contribution);
        return true;
    }
    
    function teamRefund(
        ) external onlyOwner returns(bool returned) {
        
        require(
            initialized, 
            "entry has not been initialized"
        );
        require(
            isOpen, 
            "entry is already closed"
        );
        require(
            block.timestamp > salePeriod, 
            "sale period still ongoing"
        );
        uint raised = address(this).balance;
        require(
            raised < softcap, 
            "project reached softcap"
        );
        
        uint balance = token.balanceOf(address(this));
        require(
            token.transfer(
                msg.sender, 
                balance
            ), 
            "Error in returning token"
        );
        emit TeamRefunded(msg.sender, balance);
        return true;
    }
    
    function unstake(
        ) external
        onlyWhitelisted(msg.sender) {
        uint balance = _users[msg.sender].tokenBought;
        require(
            balance > 0, 
            "You have nothing staked"
        );
        require(
            block.timestamp < stakePeriod, 
            "use WITHDRAW instead"
        );
        
        uint released = _calculateReleased(msg.sender);
        uint bonus = _users[msg.sender].bonus;
        uint lostBonus = bonus - released;
        uint halfOfLostBonus = lostBonus / 2;
        
        if(_totalDividends > _users[msg.sender].fromTotalDivs)
        _claimDivs();
        
        _users[msg.sender].tokenBought = 0;
        _users[msg.sender].contribution = 0;
        _users[msg.sender].remainder = 0;
        _users[msg.sender].bonus = 0;
        
        _addDividends(halfOfLostBonus);
        require(
            token.transfer(
                poolStake,  halfOfLostBonus
            ),
            "error in sending token"
        );
        
        require(
            token.transfer(
                msg.sender,  balance + released
            ),
            "error in sending token"
        );
        
        emit Unstaked(
            msg.sender, balance, bonus, lostBonus
        );
    }
    
    function claimDivs(
        ) external 
        onlyWhitelisted(msg.sender) {
        require(
            start != 0, 
            "term has not started"
        );
        
        uint balance = _users[msg.sender].tokenBought;
        require(
            balance > 0, 
            "You have nothing staked"
        );
        if(_totalDividends > _users[msg.sender].fromTotalDivs)
        _claimDivs();
        else revert("You do not have dividends to claim");
    }
    
    function _claimDivs(
        ) internal {
        uint pending = _pendingDividends(msg.sender);
        pending += _users[msg.sender].remainder;
            
        require(
            pending >= 0, "You do not have dividends to claim"
        );
          
        _users[msg.sender].phase = _phase;
        _users[msg.sender].remainder = 0;
        _users[msg.sender].fromTotalDivs = _totalDividends;
          
        _totalBonus -= pending;

        require(
            token.transfer(
                msg.sender, pending
            ), 
            "Error in sending reward from contract"
        );
        emit Claimed(
            msg.sender, pending
        );
    }
    
    function restakeDividends(
        ) external
        onlyWhitelisted(msg.sender) {
        uint pending = _pendingDividends(msg.sender);
        pending += _users[msg.sender].remainder;
        require(
            pending >= 0, 
            "You do not have dividends to restake"
        );
        
        _users[msg.sender].remainder = 0;
        _totalBonus -= pending;
        _totalRestakedDividends += pending;
        _users[msg.sender].phase = _phase;
        _users[msg.sender].fromTotalDivs = _totalDividends;
        _users[msg.sender].restakedDivs += pending;
        emit Restaked(
            msg.sender, pending
        );
    }
    
    function withdrawToken(
        ) external 
        onlyWhitelisted(msg.sender) {
        uint balance = _users[msg.sender].tokenBought;
        require(
            balance > 0, 
            "You have nothing staked"
        );
        require(
            stakePeriod <= block.timestamp, 
            "Can't withdraw before period"
        );
        
        uint released = _calculateReleased(msg.sender);
        
        require(
            token.transfer(
                msg.sender,  balance + released
            ),
            "error in sending token"
        );
        
        if(_totalDividends > _users[msg.sender].fromTotalDivs)
        _claimDivs();
        
        _users[msg.sender].tokenBought = 0;
        _users[msg.sender].contribution = 0;
        _users[msg.sender].remainder = 0;
        _users[msg.sender].bonus = 0;
        
        emit Withdrawn(
            msg.sender, balance, released
        );
    }
    
    function withdrawLP(
        ) external onlyOwner returns(bool success) {
        
        require(
            block.timestamp >= lpLockPeriod,
            "Must wait for lp lockup"
        );
        uint balance = IERC20(uniswap.WETH()).balanceOf(address(this));
        require(
            IERC20(uniswap.WETH()).transfer(msg.sender, balance),
            "Error in sending LP tokens"
        );
        return true;
    }
    
    function getUserTotal(
        address _user
        ) external 
        view
        returns(uint total) {
        return _getUserTotal(_user);
    }
        
    function getClaimableDivs(
        address _user
        ) external 
        view 
        returns(uint) {
        uint amount = (
            (_totalDividends - (_payouts[_users[_user].phase - 1])) 
            * _getUserTotal(_user)) / _scaling;
        amount += (
            (_totalDividends - (_payouts[_users[_user].phase - 1]))
            * _getUserTotal(_user)) % _scaling ;
        return (amount + _users[_user].remainder);
    }
  
    function _calculateReleased(
        address _user
        ) internal 
        view 
        returns(uint) {
            
        uint releasedPct;
        uint release = salePeriod;
        uint bonus = _users[_user].bonus;
        uint _start = start;
        
        if (_start == 0) return 0;
        if (block.timestamp >= release) releasedPct = 100;
        else releasedPct = (
            (block.timestamp - _start) * 10000) / ((release - _start) * 100
        );
        
        return (((bonus * releasedPct)) / 100);
    }

    function _addDividends(
        uint _amount
        ) private {
        uint latest = (_amount * _scaling) + _scaledRemainder;
        uint dividendPerToken = latest / (_totalBought + _totalRestakedDividends);
        _scaledRemainder = latest % (_totalBought + _totalRestakedDividends);
        _totalDividends = _totalDividends + dividendPerToken;
        _payouts[_phase] = _payouts[_phase-1] + dividendPerToken;
        _phase++;
    }
     
    function _pendingDividends(
        address _user
        ) private 
        returns(uint) {
        uint amount = ((
            _totalDividends - _payouts[_users[_user].phase - 1])) 
            * (_users[_user].tokenBought) % (_scaling);
        _users[_user].remainder += ((
            _totalDividends 
                - _payouts[_users[_user].phase - 1]) 
                    * _users[_user].contribution) % _scaling;
        return amount;
    }
    
    function _getUserTotal(
        address _user
        ) internal 
        view
        returns(uint total) {
        uint tokenBalance = _users[_user].tokenBought;
        uint bonus = _users[_user].bonus;
        uint restakedDivs = _users[_user].restakedDivs;
        return tokenBalance + bonus + restakedDivs;
    }
}