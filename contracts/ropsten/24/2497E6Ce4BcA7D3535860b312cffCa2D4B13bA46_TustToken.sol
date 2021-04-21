/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity 0.6.12;

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


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
        require(b > 0, errorMessage);
        uint256 c = a / b;

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


library Address {
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract TustToken is Context, IERC20, Ownable {
    
    string public constant name = "Tust Token";
    string public constant symbol = "TUST";
    uint8 public constant decimals = 18;  

    using SafeMath for uint256;

    uint256 public constant DECIMALS = 18; 
    uint256 public _totalSupply = 100 * 10**6 * 10**DECIMALS;
    uint256 private _initialLiquidity = 25 * 10**6 * 10**DECIMALS;
    uint256 public totalTokensICO; 
    uint256 public maxBuyICO;
    uint256 public unclaimedFees;
    address public _debtUniswapLPContract;

    // info of each user.
    struct UserInfo {
        uint256 rewardDebt;     // reward debt. See explanation below.
        uint256 lastUpdate;     // time at which the user made his last transaction.
        uint256 currentTier;    // user's current tier.
        //
        // we do some fancy math here. basically, any point in time, the pending reward
        // and pending debt of an user is:
        //
        //   pending reward = (balance * tier.accDebtPerShare) - user.rewardDebt
        //   pending debt = (balance * tier.dailyHoldingFee * (current time - user.lastUpdate)) / 86 400.
        //  
        // whenever a user buys, sells or transfers tokens, here's what happens:
        //   1. user's pending debt, pending reward and transaction fee are calculated.
        //   2. the pending debt is transfered to the above tier's pool and its `accDebtPerShare` is updated.
        //   3. the transaction fee is transfered to the below tier's pool and its `accDebtPerShare` is updated
        //   4. the pending reward is transfered from the current tier's pool to the user.
        //   5. the tokens bought, sold or transfered are sent.
        //   6. user's `rewardDebt`, `lastUpdate` and `currentTier` are updated.
        //   7. `tierSupply` from the user's new tier is updated.
    }

    // info of each tier.
    struct TierInfo {
        uint256 threshold;          // the amount needed to be part of that tier
        uint256 sellingFee;         // the transaction fee for all users from this tier when selling tokens. 1 = 1%
        uint256 dailyHoldingFee;    // the daily fee an user pays to the above tier. 1 = 1%
        uint256 accDebtPerShare;  // accumulated TINGs per share, times 1e12. 
        uint256 tierSupply;        // sum of the amounts owned by all users of a tier (at the time they joined the tier).
    } 
    
    TierInfo[] public tierInfo;                         
    mapping(address => UserInfo) public userInfo;                   
    
    mapping(address => bool) private hodlUser;          // Users who never sold any token
    uint256 hodlBoost = 100;                            // Bonus for determining the user's Tier. 100 = 100% bonus for amount owned

    uint256 public antiBotTimer;                        // Prevent transactions for 5mins when activated to avoid bots when adding liquidity
    bool public transfersPaused = true;
    mapping(address => bool) public transferPauseExemptList;
    bool public redistributionPaused;
	    
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    mapping (address => uint256)  _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;


    constructor() public { 
        _balances[_msgSender()] = _totalSupply;
        _isExcluded[_msgSender()] = true;
        _isExcluded[address(this)] = true;
	    transferPauseExemptList[_msgSender()] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
  }
  
 

//------------------------------------------------------------//
//     Functions for setting up the contract and parameters   //
//------------------------------------------------------------//


    function addTier(uint256 _threshold, uint256 _sellingFee, uint256 _dailyHoldingFee) 
        public 
        onlyOwner 
    {
        require(_sellingFee >= 0 && _dailyHoldingFee >= 0, "Fees cannot be negative");
        tierInfo.push(
            TierInfo({
                threshold : _threshold * 10 ** 18,
                sellingFee : _sellingFee,    
                dailyHoldingFee : _dailyHoldingFee, 
                accDebtPerShare : 0,
                tierSupply : 0
            })
        );
    }
    
    function changeFeesOfTier(uint256 _tier, uint256 _newSellingFee, uint256 _newDailyHoldingFee)
        public
        onlyOwner
    {
        tierInfo[_tier].sellingFee = _newSellingFee;
        tierInfo[_tier].dailyHoldingFee = _newDailyHoldingFee;
    }
    
    function changeThresholdOfTier(uint256 _tier, uint256 _newThreshold)
        public
        onlyOwner
    {
        tierInfo[_tier].threshold = _newThreshold * 10 ** 18;
    }
    
    function changeHodlBoost(uint256 _newHodlBoost)
        public
        onlyOwner
    {
        hodlBoost = _newHodlBoost;
    }

    function setAntiBotTimer()
        public
        onlyOwner
    {
        antiBotTimer = now;
    }

    function setTransfersPaused(bool _transfersPaused)
        public
        onlyOwner
    {
        transfersPaused = _transfersPaused;
    }

    function setTransferPauseExempt(address user, bool exempt)
        public
        onlyOwner
    {
        if (exempt) {
            transferPauseExemptList[user] = true;
        } else {
            delete transferPauseExemptList[user];
        }
    }
    
	function setRedistributionPaused(bool _redistributionPaused)	
        public	
        onlyOwner	
    {	
        redistributionPaused = _redistributionPaused;	
    }
    
    function setDebtUniswapLPContract(address _newDebtUniswapLPContract)
        public
        onlyOwner
    {
        _debtUniswapLPContract = _newDebtUniswapLPContract;
        excludeAccount(_newDebtUniswapLPContract);
    }
    
    function excludeAccount(address account) 
        public 
        onlyOwner 
    {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) 
        public 
        onlyOwner 
    {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function claimUnclaimedFees() 	
        public 	
        onlyOwner 	
    {	
        _balances[msg.sender] = _balances[msg.sender].add(unclaimedFees);	
        _balances[address(this)] = _balances[address(this)].sub(unclaimedFees);	
        unclaimedFees = 0;	
    }   
    
    
//------------------------------------------------------------//
//              Usual overridden ERC20 functions              //
//------------------------------------------------------------//   

    function totalSupply() 
        public 
        view 
        override 
        returns (uint256) 
    {
        return _totalSupply;
    }

    function balanceOf(address account) 
        public 
        override 
        view 
        returns (uint256) 
    {
        if (_isExcluded[account] || redistributionPaused) return _balances[account];
        else return _balances[account].add(pendingReward(account)).sub(pendingDebt(account));
    }

    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        _allowances[msg.sender][spender] = _allowances[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
//------------------------------------------------------------//
//                      View Functions                        //
//------------------------------------------------------------//  

    function tierLength() public view returns (uint256) {
        return tierInfo.length;
    }
    
    function getTierOfUser(address _user) public view returns (uint256) {
        return userInfo[_user].currentTier;
    }

    function pendingDebt(address _user) public view returns (uint256) {
        uint256 userTier = getTierOfUser(_user);
        uint256 maxTier = tierInfo.length.sub(1);
        if (userTier == maxTier || _balances[_user] == 0 || isExcluded(_user)) {
            return 0;
        }
        else {
            uint256 duration = now.sub(userInfo[_user].lastUpdate);
            uint256 debtCycles = ((duration) - (duration % 600)).div(600);          // debt is updated every 10 minutes in the user's balance	
            uint256 pending = _balances[_user].mul(tierInfo[userTier].dailyHoldingFee).div(100).mul(debtCycles);	
            if (pending.div(144) > _balances[_user]) return _balances[_user];	
            else return pending.div(144);
        }
    }
    
    function pendingReward(address _user) public view returns (uint256) {
        if (isExcluded(_user) || _balances[_user] == 0) return 0;
        else {
            uint256 userTier = getTierOfUser(_user);
            uint256 pending = _balances[_user].mul(tierInfo[userTier].accDebtPerShare).div(1e12).sub(userInfo[_user].rewardDebt);
            return pending;
        }
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    
//------------------------------------------------------------//
//                    Internal functions                      //
//------------------------------------------------------------//  
    
    function manageTier(address _user, uint256 _newBalance, uint256 _oldBalance) internal {
        uint256 boost = 100;
        if (hodlUser[_user]) boost = boost.add(hodlBoost);
        uint256 boostBalance = _newBalance.mul(boost).div(100);
        
        TierInfo[] storage tiers = tierInfo;
        UserInfo storage user = userInfo[_user];
        uint256 oldTier = user.currentTier;
        uint256 length = tiers.length;
        
        for (uint256 i = 0; i < length; i++) {
            if (boostBalance < tiers[i].threshold) {
                TierInfo storage tierA = tiers[oldTier];
                TierInfo storage tierB = tiers[i];
                user.rewardDebt = _newBalance.mul(tierB.accDebtPerShare).div(1e12);
                user.lastUpdate = now;
                if (oldTier != i) {
                    user.currentTier = i;
                    if (_newBalance != _initialLiquidity) tierB.tierSupply = tierB.tierSupply.add(_newBalance);  // Prevents the initial liquidity to count in the upper tier
                    if (_oldBalance != 0) tierA.tierSupply = tierA.tierSupply.sub(_oldBalance);
                }
                else tierA.tierSupply = tierA.tierSupply.add(_newBalance).sub(_oldBalance);
                break;
            }
        }
    }
    
    function manageDebt(address _user, uint256 _debt) internal {
        uint256 _userTier = getTierOfUser(_user);
        uint256 maxTier = tierInfo.length.sub(1);
        if (_userTier != maxTier && _debt > 0) {
            TierInfo storage aboveTier = tierInfo[_userTier.add(1)];
            if (aboveTier.tierSupply != 0) {	
                uint256 accDebt = aboveTier.accDebtPerShare;	
                uint256 supply = aboveTier.tierSupply;	
                accDebt = accDebt.add(_debt.mul(1e12).div(supply));	
                aboveTier.accDebtPerShare = accDebt;	
            }	
            else unclaimedFees = unclaimedFees.add(_debt);
            _balances[_user] = _balances[_user].sub(_debt);
            _balances[address(this)] = _balances[address(this)].add(_debt); 
        }
    }
    
    function manageFee(address _user, uint256 _fee) internal {
        uint256 _userTier = getTierOfUser(_user);
        TierInfo storage lowerTier;
        if (_userTier == 0) lowerTier = tierInfo[0];
        else lowerTier = tierInfo[_userTier.sub(1)];
        
        if (lowerTier.tierSupply != 0) {	
            uint256 accDebt = lowerTier.accDebtPerShare;	
            uint256 supply = lowerTier.tierSupply;	
            accDebt = accDebt.add(_fee.mul(1e12).div(supply));	
            lowerTier.accDebtPerShare = accDebt;	
        }	
        else unclaimedFees = unclaimedFees.add(_fee);
        
        _balances[_user] = _balances[_user].sub(_fee);
        _balances[address(this)] = _balances[address(this)].add(_fee); 
    }
    
    function manageReward(address _user, uint256 _reward) internal {
        if (_reward > 0) {
            _balances[_user] = _balances[_user].add(_reward);
            _balances[address(this)] = _balances[address(this)].sub(_reward); 
        }
    }

    
//------------------------------------------------------------//
//                  Transfer functions                        //
//------------------------------------------------------------//  
  
    
    function transfer(address recipient, uint256 amount) 
        public 
        override
        returns (bool) 
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");
        require(now.sub(antiBotTimer) >= 300 || amount <= 300000 * 10**DECIMALS, "Max buy 300000 DEBT right after launch");
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) 
        public 
        override 
        returns (bool) 
    {
        require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");
        
        _transfer(sender, recipient, amount);
        approve(sender, _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }  
   

    function _transfer(address sender, address recipient, uint256 amount) 
        internal 
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (redistributionPaused) {	
            _transferBothExcluded(sender, recipient, amount);	
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }
    
    function _transferStandard(address sender, address recipient, uint256 debtAmount) private {
        hodlUser[sender] = false;
        uint256[4] memory pending = [pendingReward(sender), pendingDebt(sender), pendingReward(recipient), pendingDebt(recipient)];
        uint256[2] memory oldBalances = [_balances[sender], _balances[recipient]];
        
        manageReward(sender, pending[0]);
        manageDebt(sender, pending[1]);
        if (oldBalances[1] > 0) {
            manageReward(recipient, pending[2]);
            manageDebt(recipient, pending[3]);
        }
            
        _balances[recipient] = _balances[recipient].add(debtAmount);
        _balances[sender] = _balances[sender].sub(debtAmount); 
            
        uint256[2] memory newBalances = [_balances[sender], _balances[recipient]];            
        manageTier(sender, newBalances[0], oldBalances[0]);
        manageTier(recipient, newBalances[1], oldBalances[1]);
        emit Transfer(sender, recipient, debtAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 debtAmount) private {
        hodlUser[sender] = false;
        uint256[2] memory pending = [pendingReward(sender), pendingDebt(sender)];
        uint256 userTier = getTierOfUser(sender);
        uint256 oldBalance = _balances[sender];
        uint256 fee = debtAmount.mul(tierInfo[userTier].sellingFee).div(100);

        manageReward(sender, pending[0]);
        manageDebt(sender, pending[1]);
        manageFee(sender, fee);
        
        uint256 debtTransferAmount = debtAmount.sub(fee);
        _balances[recipient] = _balances[recipient].add(debtTransferAmount);
        _balances[sender] = _balances[sender].sub(debtTransferAmount); 
            
        uint256 newBalance = _balances[sender];
        manageTier(sender, newBalance, oldBalance);
        emit Transfer(sender, recipient, debtTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 debtAmount) private {
        uint256 oldBalance = _balances[recipient];
        if (oldBalance == 0) hodlUser[recipient] = true; 
        if (oldBalance > 0) {
            uint256[2] memory pending = [pendingReward(recipient), pendingDebt(recipient)];
        
            manageDebt(recipient, pending[1]);
            manageReward(recipient, pending[0]);
        }

        _balances[recipient] = _balances[recipient].add(debtAmount);
        _balances[sender] = _balances[sender].sub(debtAmount); 
        
        uint256 newBalance = _balances[recipient];
        manageTier(recipient, newBalance, oldBalance);
        emit Transfer(sender, recipient, debtAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 debtAmount) private {
        _balances[recipient] = _balances[recipient].add(debtAmount);
        _balances[sender] = _balances[sender].sub(debtAmount); 
        emit Transfer(sender, recipient, debtAmount);
    }
}