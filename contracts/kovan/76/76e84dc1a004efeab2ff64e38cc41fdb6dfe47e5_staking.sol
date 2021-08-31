/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract Context {
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

 contract Owned {

address private owner;
address private newOwner;


/// @notice The Constructor assigns the message sender to be `owner`
constructor() {
    owner = msg.sender;
}

modifier onlyOwner() {
    require(msg.sender == owner,"Owner only function");
    _;
}


}

contract ERC20 is Context, Owned, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
   
    
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public override  returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
       
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
   
 
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function burn(uint256 amount) external
    {
    _burn(msg.sender, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  

}

contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;
        
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Codex is ERC20, ERC20Detailed {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  address public marketingWallet = 0x0bD042059368389fdC3968d671c40319dEb39F2c;
  address public originWallet    = 0xE9fe09A55377f760128800e6813F2E2C07db60Ad;
  address public FoundingPartners = 0x454d1252EC7c1Dc7E4D0A92A84A3Da2BD158b1D7;
  address public blockedFoundingPartners = 0x8f7F2243A34169931741ba7eB257841C639Bc165;
  address public socialPartners = 0xe307d66905D10e7e51B0BFb12E7e64C876a04215;
  address public programmers = 0xc21713ef49a48396c1939233F3B24E1c4CCD09a4;
  address public privateInvestors = 0x252Fa9eD5F51e3A9CF1b1890f479775eFeaa653d;
  address public aidPartners = 0x1EEffDA40C880a93E19ecAF031e529C723072e51;
  uint256 public deploymentTime = block.timestamp;
 
  
  constructor () ERC20Detailed("Codex", "COdex", 18)
  {
    _totalSupply = 1000000000000000  * (10**uint256(18));
    
	_balances[originWallet] = 400000000000000 * (10**uint256(18));
	_balances[marketingWallet] = 100000000000000 * (10**uint256(18));
	_balances[FoundingPartners] = 90000000000000 * (10**uint256(18));
	_balances[blockedFoundingPartners] = 10000000 * (10**uint256(18));
	_balances[socialPartners] = 100000000000000 * (10**uint256(18));
	_balances[programmers] = 180000000000000  * (10**uint256(18));
	_balances[privateInvestors] = 70000000000000 * (10**uint256(18));
	_balances[aidPartners] = 50000000000000 * (10**uint256(18));


  }
  
  function withdrawFromMarketing() public onlyOwner
  {
      if(block.timestamp > deploymentTime + 365 days)
      {
        _transfer(marketingWallet, originWallet, (20000000000000000 * (10**18)));
      }
      deploymentTime = block.timestamp;
  }
}



contract staking is Owned {
    using SafeMath for uint;
    
    struct StakingInfo {
        uint amount;
        uint depositDate;
        uint rewardPercent;
    }
    
    uint maxStakeAmount = 100000000 * 10**18; 
    uint REWARD_DIVIDER = 10**8;
    
    IERC20 stakingToken;
    uint rewardPercent; 

    
    uint ownerTokensAmount;
    address[] internal stakeholders;
    mapping(address => StakingInfo[]) internal stakes;
    uint256 stakeDeploymentTime = block.timestamp;

    constructor(IERC20 _stakingToken) {
        stakingToken = _stakingToken;
     
    }
    
    event Staked(address staker, uint amount);
    event Unstaked(address staker, uint amount);
    
    function changeRewardPercent(uint _rewardPercent) public onlyOwner {
        rewardPercent = _rewardPercent;
    }
    
    function changeMinStakeAmount(uint _maxStakeAmount) public onlyOwner {
        maxStakeAmount = _maxStakeAmount;
    }
    
    function totalStakes() public view returns(uint256) {
        uint _totalStakes = 0;
        for (uint i = 0; i < stakeholders.length; i += 1) {
            for (uint j = 0; j < stakes[stakeholders[i]].length; j += 1)
             _totalStakes = _totalStakes.add(stakes[stakeholders[i]][j].amount);
        }
        return _totalStakes;
    }
    
    function isStakeholder(address _address) public view returns(bool, uint256) {
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            if (_address == stakeholders[s]) 
                return (true, s);
        }
        return (false, 0);
    }

    function addStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if (!_isStakeholder)
            stakeholders.push(_stakeholder);
    }

    function removeStakeholder(address _stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if (_isStakeholder) {
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }
    
    function stake(uint256 _amount) public {
        require(_amount <= maxStakeAmount);
        require(block.timestamp <= stakeDeploymentTime + 730 days);
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Stake required!");
        if (stakes[msg.sender].length == 0) {
            addStakeholder(msg.sender);
        }
        stakes[msg.sender].push(StakingInfo(_amount, block.timestamp, rewardPercent));
        emit Staked(msg.sender, _amount);
    }
    uint rewardAmount;
    function unstake() public {
        uint withdrawAmount = 0;
        for (uint j = 0; j < stakes[msg.sender].length; j += 1) {
            uint amount = stakes[msg.sender][j].amount;
            withdrawAmount = withdrawAmount.add(amount);
            if(((block.timestamp - stakes[msg.sender][j].depositDate) >=365 days) && ((block.timestamp - stakes[msg.sender][j].depositDate) <=730 days))
            { 
               rewardAmount = amount + ((amount * 1844 / 10000) * (block.timestamp - stakes[msg.sender][j].depositDate));
               
            }
            else if(( block.timestamp - stakes[msg.sender][j].depositDate) > 730 days )
            { 
                rewardAmount = amount + ((amount * 822 / 10000) * (block.timestamp - stakes[msg.sender][j].depositDate));
            }
          
            
            withdrawAmount = withdrawAmount.add(rewardAmount);
        }
        
        require(stakingToken.transfer(msg.sender, withdrawAmount), "Not enough tokens in contract!");
        delete stakes[msg.sender];
        removeStakeholder(msg.sender);
        emit Unstaked(msg.sender, withdrawAmount);
    }
    
    function sendTokens(uint _amount) public onlyOwner {
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfering not approved!");
        ownerTokensAmount = ownerTokensAmount.add(_amount);
    }
    
    function withdrawTokens(address receiver, uint _amount) public onlyOwner {
        ownerTokensAmount = ownerTokensAmount.sub(_amount);
        require(stakingToken.transfer(receiver, _amount), "Not enough tokens on contract!");
    }
}