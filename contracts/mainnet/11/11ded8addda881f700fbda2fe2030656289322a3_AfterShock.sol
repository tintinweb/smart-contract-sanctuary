/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity 0.5.8;

interface IERC20 
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

library SafeMath 
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) 
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

contract ERC20Detailed is IERC20 
{
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}

contract AfterShock is ERC20Detailed 
{
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    string constant tokenName = "AfterShock";//"AfterShock";
    string constant tokenSymbol = "SHOCK";//"SHOCK"; 
    uint8  constant tokenDecimals = 18;
    uint256 _totalSupply = 0;
    
    // ------------------------------------------------------------------------
  
    address public contractOwner;

    uint256 public fullUnitsStaked_total = 0;
    mapping (address => bool) public excludedFromStaking; //exchanges/other contracts will be excluded from staking

    uint256 _totalRewardsPerUnit = 0;
    mapping (address => uint256) private _totalRewardsPerUnit_positions;
    mapping (address => uint256) private _savedRewards;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // ------------------------------------------------------------------------
    
    constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) 
    {
        contractOwner = msg.sender;
        excludedFromStaking[msg.sender] = true;
        excludedFromStaking[address(this)] = true;
        _mint(msg.sender, 1000000 * (10**uint256(tokenDecimals)));
    }
    
    // ------------------------------------------------------------------------

    function transferOwnership(address newOwner) public 
    {
        require(msg.sender == contractOwner);
        require(newOwner != address(0));
        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
    }
    
    function totalSupply() public view returns (uint256) 
    {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view returns (uint256) 
    {
        return _balances[owner];
    }
    
    function fullUnitsStaked(address owner) public view returns (uint256) 
    {
        return toFullUnits(_balances[owner]);
    }
    
    function toFullUnits(uint256 valueWithDecimals) public pure returns (uint256) 
    {
        return valueWithDecimals.div(10**uint256(tokenDecimals));
    }
    
    function allowance(address owner, address spender) public view returns (uint256) 
    {
        return _allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) 
    {
        _executeTransfer(msg.sender, to, value);
        return true;
    }
    
    function multiTransfer(address[] memory receivers, uint256[] memory values) public
    {
        require(receivers.length == values.length);
        for(uint256 i = 0; i < receivers.length; i++)
            _executeTransfer(msg.sender, receivers[i], values[i]);
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) 
    {
        require(value <= _allowed[from][msg.sender]);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _executeTransfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) 
    {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        require(spender != address(0));
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function _mint(address account, uint256 value) internal 
    {
        require(value != 0);
        
        uint256 initalBalance = _balances[account];
        uint256 newBalance = initalBalance.add(value);
        
        _balances[account] = newBalance;
        _totalSupply = _totalSupply.add(value);
        
        //update full units staked
        if(!excludedFromStaking[account])
        {
            uint256 fus_total = fullUnitsStaked_total;
            fus_total = fus_total.sub(toFullUnits(initalBalance));
            fus_total = fus_total.add(toFullUnits(newBalance));
            fullUnitsStaked_total = fus_total;
        }
        emit Transfer(address(0), account, value);
    }
    
    function burn(uint256 value) external 
    {
        _burn(msg.sender, value);
    }
    
    function burnFrom(address account, uint256 value) external 
    {
        require(value <= _allowed[account][msg.sender]);
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
    
    function _burn(address account, uint256 value) internal 
    {
        require(value != 0);
        require(value <= _balances[account]);
        
        uint256 initalBalance = _balances[account];
        uint256 newBalance = initalBalance.sub(value);
        
        _balances[account] = newBalance;
        _totalSupply = _totalSupply.sub(value);
        
        //update full units staked
        if(!excludedFromStaking[account])
        {
            uint256 fus_total = fullUnitsStaked_total;
            fus_total = fus_total.sub(toFullUnits(initalBalance));
            fus_total = fus_total.add(toFullUnits(newBalance));
            fullUnitsStaked_total = fus_total;
        }
        
        emit Transfer(account, address(0), value);
    }
    
    /*
    *   transfer with additional burn and stake rewards
    *   the receiver gets 94% of the sent value
    *   6% are split to be burnt and distributed to holders
    */
    function _executeTransfer(address from, address to, uint256 value) private
    {
        require(value <= _balances[from]);
        require(to != address(0) && to != address(this));

        //Update sender and receivers rewards - changing balances will change rewards shares
        updateRewardsFor(from);
        updateRewardsFor(to);
        
        uint256 sixPercent = value.mul(6).div(100);
        
        //set a minimum burn rate to prevent no-burn-txs due to precision loss
        if(sixPercent == 0 && value > 0)
            sixPercent = 1;
            
        uint256 initalBalance_from = _balances[from];
        uint256 newBalance_from = initalBalance_from.sub(value);
        
        value = value.sub(sixPercent);
        
        uint256 initalBalance_to = _balances[to];
        uint256 newBalance_to = initalBalance_to.add(value);
        
        //transfer
        _balances[from] = newBalance_from;
        _balances[to] = newBalance_to;
        emit Transfer(from, to, value);
         
        //update full units staked
        uint256 fus_total = fullUnitsStaked_total;
        if(!excludedFromStaking[from])
        {
            fus_total = fus_total.sub(toFullUnits(initalBalance_from));
            fus_total = fus_total.add(toFullUnits(newBalance_from));
        }
        if(!excludedFromStaking[to])
        {
            fus_total = fus_total.sub(toFullUnits(initalBalance_to));
            fus_total = fus_total.add(toFullUnits(newBalance_to));
        }
        fullUnitsStaked_total = fus_total;
        
        uint256 amountToBurn = sixPercent;
        
        if(fus_total > 0)
        {
            uint256 stakingRewards = sixPercent.div(2);
            //split up to rewards per unit in stake
            uint256 rewardsPerUnit = stakingRewards.div(fus_total);
            //apply rewards
            _totalRewardsPerUnit = _totalRewardsPerUnit.add(rewardsPerUnit);
            _balances[address(this)] = _balances[address(this)].add(stakingRewards);
            emit Transfer(msg.sender, address(this), stakingRewards);
    
            amountToBurn = amountToBurn.sub(stakingRewards);
        }
        
        //update total supply
        _totalSupply = _totalSupply.sub(amountToBurn);
        emit Transfer(msg.sender, address(0), amountToBurn);
    }
    
    //catch up with the current total rewards. This needs to be done before an addresses balance is changed
    function updateRewardsFor(address staker) private
    {
        _savedRewards[staker] = viewUnpaidRewards(staker);
        _totalRewardsPerUnit_positions[staker] = _totalRewardsPerUnit;
    }
    
    //get all rewards that have not been claimed yet
    function viewUnpaidRewards(address staker) public view returns (uint256)
    {
        if(excludedFromStaking[staker])
            return _savedRewards[staker];
        uint256 newRewardsPerUnit = _totalRewardsPerUnit.sub(_totalRewardsPerUnit_positions[staker]);
        
        uint256 newRewards = newRewardsPerUnit.mul(fullUnitsStaked(staker));
        return _savedRewards[staker].add(newRewards);
    }
    
    //pay out unclaimed rewards
    function payoutRewards() public
    {
        updateRewardsFor(msg.sender);
        uint256 rewards = _savedRewards[msg.sender];
        require(rewards > 0 && rewards <= _balances[address(this)]);
        
        _savedRewards[msg.sender] = 0;
        
        uint256 initalBalance_staker = _balances[msg.sender];
        uint256 newBalance_staker = initalBalance_staker.add(rewards);
        
        //update full units staked
        if(!excludedFromStaking[msg.sender])
        {
            uint256 fus_total = fullUnitsStaked_total;
            fus_total = fus_total.sub(toFullUnits(initalBalance_staker));
            fus_total = fus_total.add(toFullUnits(newBalance_staker));
            fullUnitsStaked_total = fus_total;
        }
        
        //transfer
        _balances[address(this)] = _balances[address(this)].sub(rewards);
        _balances[msg.sender] = newBalance_staker;
        emit Transfer(address(this), msg.sender, rewards);
    }
    
    //exchanges or other contracts can be excluded from receiving stake rewards
    function excludeAddressFromStaking(address excludeAddress, bool exclude) public
    {
        require(msg.sender == contractOwner);
        require(excludeAddress != address(this)); //contract may never be included
        require(exclude != excludedFromStaking[excludeAddress]);
        updateRewardsFor(excludeAddress);
        excludedFromStaking[excludeAddress] = exclude;
        fullUnitsStaked_total = exclude ? fullUnitsStaked_total.sub(fullUnitsStaked(excludeAddress)) : fullUnitsStaked_total.add(fullUnitsStaked(excludeAddress));
    }
    
    //withdraw tokens that were sent to this contract by accident
    function withdrawERC20Tokens(address tokenAddress, uint256 amount) public
    {
        require(msg.sender == contractOwner);
        require(tokenAddress != address(this));
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
    
}