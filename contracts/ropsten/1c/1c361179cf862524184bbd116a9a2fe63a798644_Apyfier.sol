/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * Strategy contract interface
 */
interface IApyfierStrategy {
    function getName() external view returns (string memory);
    function getToken() external view returns (address);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;    
    function emergencyWithdraw() external;
    function balance() external view returns (uint256);
    function maintenanceValues() external view returns (uint256[] memory); // returns risk for risk depending maintenace
    function maintenance() external; // harvesting, etc...
    function setMaxSlippage(uint256 _maxSlippage) external;
    function setOwner(address _owner) external;
}


/**
 * Apyfier Contract
 * Manages all strategies for a given base token
 */
contract Apyfier is Ownable {

    struct User {
        mapping(uint256 => uint256) strategyShares;
    }

    // Active <-> Inactive -> Removed
    enum StrategyStatus { Active, Inactive, Removed }

    struct Strategy {
        IApyfierStrategy instance;
        uint256 lastBalance; // balance @last sharevalue update
        uint256 shareValue; // shareValue @last sharevalue update
        uint256 shareTotal;
        uint256 pendingBalance; // balance outside of strategy
        uint256 lockedBalance; // balance which is part of this strategy but not part of sharevalue calculation
        StrategyStatus status;
    }
    
    mapping(address => User) users;
    mapping(uint256 => Strategy) strategies;
    uint256 public strategyCount;

    IERC20 public token; // strategy base token

    // configuration for performance
    uint256 public performanceFee = 0; // fee on gains 0%

    // configuration how money is moved between contract and strategies
    uint256 public minMovementAmount = 0; // 100e18 100 tokens
    uint256 public pendingBalanceFactor = 0; // 1e17 10% pending

    // poor mans flash loan protection
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "onlyEOA");
        _;
    }

    constructor(IERC20 _token) {  
        token = _token;
    }

    /**
    * Invest funds in strategy
    */
    function deposit(uint256 _sid, uint256 _amount) external onlyEOA {
        require(_amount > 0, '_amount=0'); 
        require(_sid < strategyCount, '?_sid'); 
        
        // collect deposit (fails if not enough)
        token.transferFrom(msg.sender, address(this), _amount);

        // update strategies
        _updateStrategy(_sid, _amount, true);

        emit Deposit(msg.sender, _sid, _amount);
    }

    /**
     * Withdraw all funds
     */
    function withdrawAll(uint256 _sid) external onlyEOA {
        require(_sid < strategyCount, '?_sid'); 
        uint256 _balance = _balanceOf(_sid, strategies[_sid], msg.sender); 
        _withdraw(_sid, _balance);
    }

    /**
     * Withdraw funds (if _amount > balance - withdraw all)
     */
    function withdraw(uint256 _sid, uint256 _amount) external onlyEOA {
        require(_sid < strategyCount, '?_sid'); 
        uint256 _balance = _balanceOf(_sid, strategies[_sid], msg.sender); 
        if (_amount > _balance) {
            _amount = _balance;
        }    
        _withdraw(_sid, _amount);    
    }

    function _withdraw(uint256 _sid, uint256 _amount) private {
        require(_amount > 0, '_amount=0');      

        _updateStrategy(_sid, _amount, false);

        uint256 _tokenBalance = token.balanceOf(address(this));
        if (_amount > _tokenBalance) {
            _amount = _tokenBalance;
        }        
        token.transfer(msg.sender, _amount);
        emit Withdrawal(msg.sender, _sid, _amount);
    }   

    /**
     * Calculates current strategy balance of user (updating each block)
     */
    function balanceOf(uint256 _sid, address _account) external view returns(uint256) {
        return _balanceOf(_sid, strategies[_sid], _account);
    }

    /**
     * Calculates total balance of user (updating each block)
     */
    function totalBalanceOf(address _account) external view returns(uint256) {
        uint256 _total;
        for (uint256 i = 0; i < strategyCount; i++) {     
            Strategy storage _strategy = strategies[i];
            if (_strategy.status != StrategyStatus.Removed) { 
                _total += _balanceOf(i, _strategy, _account);
            }
        }
        return _total;
    }
    
    function _balanceOf(uint256 _sid, Strategy storage _strategy, address _account) private view returns(uint256) {        
        (,, uint256 _shareValue, ) = _calculateShareValue(_strategy);      
        return users[_account].strategyShares[_sid] * _shareValue / 1e18;
    }

    /**
    * Gets strategy info
    */
    function getStrategyInfo(uint256 _sid) external view returns(string memory _name, uint256 _tvl, StrategyStatus _status, uint256 _shareValue) {
        require(_sid < strategyCount, '>=strategyCount');
        Strategy storage _strategy = strategies[_sid];
        (,,_shareValue,) = _calculateShareValue(_strategy);         
        _name = _strategy.instance.getName();       
        _tvl = _shareValue * _strategy.shareTotal / 1e18;
        _status = _strategy.status;
    }

    /**
     * Updates strategy after deposit / withdrawal
     */
    function _updateStrategy(uint256 _sid, uint256 _amount, bool _isDeposit) private {

        User storage _user = users[msg.sender];
        Strategy storage _strategy = strategies[_sid];

        // update stats for strategy
        (uint256 _strategyBalance,, uint256 _shareValue) = _updateStats(_sid, _strategy);

        uint256 _oldShareAmount = _user.strategyShares[_sid];
        uint256 _oldAmount = _oldShareAmount * _shareValue / 1e18;  
        uint256 _newAmount = _oldAmount;

        if (_isDeposit) {
            _newAmount += _amount;
            _strategy.pendingBalance += _amount;
            _strategy.lastBalance += _amount;
            if (_strategy.status == StrategyStatus.Active) {
                _rebalance(_strategy, _strategyBalance, 0, false);  
            }      
        } else {
            if (_newAmount > _amount) {
                _newAmount -= _amount;
            } else {
                _amount = _newAmount;
                _newAmount = 0;
            }
            // only rebalance when strategy active
            if (_strategy.status == StrategyStatus.Active) {
                _rebalance(_strategy, _strategyBalance, _amount, false);
            }
            _strategy.pendingBalance -= _amount > _strategy.pendingBalance ? _strategy.pendingBalance : _amount;
            _strategy.lastBalance -= _amount > _strategy.lastBalance ? _strategy.lastBalance : _amount;            
        }

        uint256 _newShareAmount = _newAmount > 0 ? _newAmount * 1e18 / _shareValue : 0; 
        _user.strategyShares[_sid] = _newShareAmount;       

        if (_newShareAmount >= _oldShareAmount) {
            _strategy.shareTotal += (_newShareAmount - _oldShareAmount);
        } else {
            uint256 _diff = (_oldShareAmount - _newShareAmount);
            if (_strategy.shareTotal > _diff) {
                _strategy.shareTotal -= _diff;
            } else {
                _strategy.shareTotal = 0;
            }            
        }
    }

    /**
     * Rebalances funds for strategy (move amount from strategy to pending or back)
     */
    function _rebalance(Strategy storage _strategy, uint256 _strategyBalance, uint256 _withdrawalAmount, bool _force) private {
        uint256 _pending = _strategy.pendingBalance;    
        uint256 _total = _strategyBalance + _pending;
         // fix for last withdrawal imprecision
        if (_withdrawalAmount > _total) {
            _withdrawalAmount = _total;
        }
        uint256 _perfectPendingBalance = _withdrawalAmount + ((_total - _withdrawalAmount) * pendingBalanceFactor) / 1e18;
        if (_pending > _perfectPendingBalance) {
            uint256 _moveAmount = _pending - _perfectPendingBalance;
            uint256 _tokenAvailable = token.balanceOf(address(this));
            if (_moveAmount > _tokenAvailable) {
                _moveAmount = _tokenAvailable;
            }
            if (_moveAmount > minMovementAmount || _force) {
                if (_moveAmount > 0) {
                    _strategy.instance.deposit(_moveAmount);
                    _strategy.pendingBalance -= _moveAmount;
                }
            }
        } else if (_pending < _perfectPendingBalance) {
            uint256 _moveAmount = _perfectPendingBalance - _pending;
            if (_moveAmount > minMovementAmount || (_withdrawalAmount > 0 && _pending < _withdrawalAmount) || _force) {
                if (_moveAmount > _strategyBalance) {
                    _moveAmount = _strategyBalance;
                }
                if (_moveAmount > 0) {
                    // cant assume that strategies always return full amount (eg for converting strategies)
                    uint256 _tokenBefore = token.balanceOf(address(this));
                    _strategy.instance.withdraw(_moveAmount);      
                    uint256 _tokenAfter = token.balanceOf(address(this));
                    _strategy.pendingBalance += (_tokenAfter - _tokenBefore);
                }
            }
        }
    }

    /**
     * Updates strategy stats
     * Should be called in intervals - but can be called by anyone if needed
     */
    function updateStats(uint256[] memory _sids) external onlyEOA {         
        uint8 _count = uint8(_sids.length);
        for (uint8 i = 0; i < _count; i++) {
            _updateStats(_sids[i], strategies[_sids[i]]);               
        }
    }

    /**
     * Stores current share values to strategy and emits event for logging
     */
    function _updateStats(uint256 _sid, Strategy storage _strategy) private returns (uint256 _strategyBalance, uint256 _balance, uint256 _shareValue) {        
        uint256 _gain;

        (_strategyBalance, _balance, _shareValue, _gain) = _calculateShareValue(_strategy);        

        _strategy.shareValue = _shareValue;
        _strategy.lastBalance = _balance;
        _strategy.lockedBalance += _gain;

        emit ShareValueUpdate(_sid, _shareValue);    
    }    
    
    /**
     * Calculates current share value
     */
    function _calculateShareValue(Strategy storage _strategy) private view returns (uint256 _strategyBalance, uint256 _balance, uint256 _shareValue, uint256 _gain) {
        _strategyBalance = _strategy.status == StrategyStatus.Active ? _strategy.instance.balance() : 0;
        _balance = _strategyBalance + _strategy.pendingBalance;
        if (_balance > _strategy.lockedBalance) {
            _balance -= _strategy.lockedBalance;
        } else {
            _balance = 0;
        }
        _gain = 0;
        if (_balance > _strategy.lastBalance) {
            _gain = (_balance - _strategy.lastBalance) * performanceFee / 1e18;  
            _balance -= _gain;      
        }        
        _shareValue = _strategy.shareTotal > 0 ? _balance * 1e18 / _strategy.shareTotal : _strategy.shareValue;  
    }

    /**
     * Deposits / withdraws from strategies to keep healthy amount of balance (follows configured rules)
     * Can be called by anyone / force only by owner
     */
    function rebalance(uint256[] memory _sids, bool _force) external onlyEOA {
        require(!_force || owner() == msg.sender, '!owner');
        uint8 _count = uint8(_sids.length);
        for (uint8 i = 0; i < _count; i++) {
            Strategy storage _strategy = strategies[_sids[i]];
            if (_strategy.status == StrategyStatus.Active) {
                (uint256 _strategyBalance,,) = _updateStats(_sids[i], _strategy);
                _rebalance(_strategy, _strategyBalance, 0, _force);    
            }
        }
    }

    /**
     * Changes max slippage for strategy (only needed in situations when swaps don't work anymore)
     */
    function setMaxSlippage(uint256[] memory _sids, uint256 _maxSlippage) external onlyOwner {         
        uint8 _count = uint8(_sids.length);
        for (uint8 i = 0; i < _count; i++) {
            strategies[_sids[i]].instance.setMaxSlippage(_maxSlippage);            
        }
    }

    /**
     * Withdraws all funds from each specified strategy immediately to pendingBalance
     */
    function emergencyWithdraw(uint256[] memory _sids) external onlyOwner {
        uint8 _count = uint8(_sids.length);
        for (uint8 i = 0; i < _count; i++) {
            Strategy storage _strategy = strategies[_sids[i]];
            if (_strategy.status == StrategyStatus.Active) {
                _emergencyWithdraw(_strategy);
            }
        }
    }

    function _emergencyWithdraw(Strategy storage _strategy) private {
        uint256 _balanceBefore = token.balanceOf(address(this));
        _strategy.instance.emergencyWithdraw();
        uint256 _balanceAfter = token.balanceOf(address(this));
        _strategy.pendingBalance += (_balanceAfter - _balanceBefore);
    }
       
    /**
     * Withdraws locked profits funds to account
     */
    function profitWithdraw(address _ad) external onlyOwner {

        uint256 _neededFunds = 0;

        for (uint256 i = 0; i < strategyCount; i++) {     

            Strategy storage _strategy = strategies[i];

            if (_strategy.status == StrategyStatus.Removed) { 
                continue;
            } else if (_strategy.status == StrategyStatus.Active) {
                _updateStats(i, _strategy);   
            }

            uint256 _pending = _strategy.pendingBalance;            
            if (_pending > 0) {
                uint256 _locked = _strategy.lockedBalance;
                if (_locked > _pending) {
                    _strategy.pendingBalance = 0;
                    _strategy.lockedBalance = _locked - _pending;
                } else {
                    _strategy.lockedBalance = 0;
                    _strategy.pendingBalance = _pending - _locked;
                }
                _neededFunds += _strategy.pendingBalance;
            }
        }

        uint256 _tokenBalance = token.balanceOf(address(this));
        if (_tokenBalance > _neededFunds) {
            uint256 _available = _tokenBalance - _neededFunds;
            token.transfer(_ad, _available);
        }
    }

    function setPerformanceConfig(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee <= 5e17, 'fee>50%');        
        performanceFee = _performanceFee;
    }
 
    function setPendingConfig(uint256 _minMovementAmount, uint256 _pendingBalanceFactor) external onlyOwner {
        require(_pendingBalanceFactor <= 1e18, 'factor>100%');
        minMovementAmount = _minMovementAmount;
        pendingBalanceFactor = _pendingBalanceFactor;
    }

    function addStrategy(IApyfierStrategy _strategy) external onlyOwner {
        require(_strategy.getToken() == address(token), '!=token');
        token.approve(address(_strategy), type(uint256).max);
        strategies[strategyCount] = Strategy(_strategy, 0, 1e18, 0, 0, 0, StrategyStatus.Active);  
        strategyCount++;  
    }

    function setStrategyStatus(uint256 _sid, StrategyStatus _status) external onlyOwner {
        require(_sid < strategyCount, '>=strategyCount');        
        
        Strategy storage _strategy = strategies[_sid];

        if (_strategy.status == StrategyStatus.Active && _status == StrategyStatus.Inactive) {
            // force update stats
            _emergencyWithdraw(_strategy);
            _updateStats(_sid, _strategy);
            _strategy.status = StrategyStatus.Inactive;
        } else if (_strategy.status == StrategyStatus.Inactive && _status == StrategyStatus.Active) {
            _strategy.status = StrategyStatus.Active;  
        } else if (_strategy.status == StrategyStatus.Inactive && _status == StrategyStatus.Removed) {
            // if removing - only possible when no shares anymore 
            require(_strategy.shareTotal == 0, 'shareTotal>0');
            _strategy.pendingBalance = 0;
            _strategy.lockedBalance = 0;
            _strategy.lastBalance = 0;
            _strategy.status = StrategyStatus.Removed; 
        }
    }

    event Deposit(address indexed owner, uint256 indexed sid, uint256 amount);
    event Withdrawal(address indexed owner, uint256 indexed sid, uint256 amount);
    event ShareValueUpdate(uint256 indexed sid, uint256 shareValue);
}