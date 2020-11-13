// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface TownInterface {
    function checkProposal(address proposal) external returns (bool);
    function voteOn(address externalToken, uint256 amount) external returns (bool);
    
}

interface Token {
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function getHoldersCount() external view returns (uint256);

    function getHolderByIndex(uint256 index) external view returns (address);
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



contract Town is TownInterface {
    using SafeMath for uint256;

    uint256 private _distributionPeriod;
    uint256 private _distributionPeriodsNumber;
    uint256 private _startRate;
    uint256 private _minTokenGetAmount;
    uint256 private _durationOfMinTokenGetAmount;
    uint256 private _maxTokenGetAmount;
    uint256 private _minExternalTokensAmount;
    uint256 private _minSignAmount;
    uint256 private _lastDistributionsDate;

    uint256 private _transactionsCount;

   
    struct ExternalTokenDistributionsInfo {
        address _official;
        uint256 _distributionAmount;
        uint256 _distributionsCount;
    }

    struct ExternalToken {
        ExternalTokenDistributionsInfo[] _entities;
        uint256 _weight;
    }

    struct TransactionsInfo {
        uint256 _rate;
        uint256 _amount;
    }

    struct TownTokenRequest {
        address _address;
        TransactionsInfo _info;
    }

    struct RemunerationsInfo {
        address payable _address;
        uint256 _priority;
        uint256 _amount;
    }

    struct RemunerationsOfficialsInfo {
        uint256 _amount;
        uint256 _decayTimestamp;
    }

    Token private _token;

    mapping (address => TransactionsInfo[]) private _historyTransactions;

    TownTokenRequest[] private _queueTownTokenRequests;

    RemunerationsInfo[] private _remunerationsQueue;

    mapping (address => ExternalToken) private _externalTokens;
    address[] private _externalTokensAddresses;

    mapping (address => mapping (address => uint256)) private _townHoldersLedger;
    mapping (address => address[]) private _ledgerExternalTokensAddresses;

    mapping (address => RemunerationsOfficialsInfo) private _officialsLedger;

    address[] private _externalTokensWithWight;

    event Proposal(uint256 value, address indexed _official, uint256 _distributionAmount, uint256 _distributionsCount, address indexed externalToken);
    event Vote(address indexed externalToken, uint256 value);
    event Init(uint256 _distributionPeriod,uint256 _distributionPeriodsNumber,uint256 _startRate,address indexed tokenAddress,uint256 _transactionsCount, uint256 _minTokenGetAmount,uint256 _durationOfMinTokenGetAmount,uint256 _maxTokenGetAmount,uint256 _minExternalTokensAmount,uint256 _lastDistributionsDate, uint256 _minSignAmount);

    modifier onlyTownTokenSmartContract {
        require(msg.sender == address(_token), "only town token smart contract can call this function");
        _;
    }

    constructor (
        uint256 distributionPeriod,
        uint256 distributionPeriodsNumber,
        uint256 startRate,
        uint256 minTokenGetAmount,
        uint256 durationOfMinTokenGetAmount,
        uint256 maxTokenGetAmount,
        uint256 minExternalTokensAmount,
        address tokenAddress) {
        require(distributionPeriod > 0, "distributionPeriod wrong");
        require(distributionPeriodsNumber > 0, "distributionPeriodsNumber wrong");
        require(minTokenGetAmount > 0, "minTokenGetAmount wrong");
        require(durationOfMinTokenGetAmount > 0, "durationOfMinTokenGetAmount wrong");
        require(maxTokenGetAmount > 0, "maxTokenGetAmount wrong");
        require(minExternalTokensAmount > 0, "minExternalTokensAmount wrong");

        _distributionPeriod = distributionPeriod * 1 days;
        _distributionPeriodsNumber = distributionPeriodsNumber;
        _startRate = startRate;

        _token = Token(tokenAddress);

        _transactionsCount = 0;
        _minTokenGetAmount = minTokenGetAmount;
        _durationOfMinTokenGetAmount = durationOfMinTokenGetAmount;
        _maxTokenGetAmount = maxTokenGetAmount;
        _minExternalTokensAmount = minExternalTokensAmount;
        _lastDistributionsDate = (block.timestamp.div(86400).add(1)).mul(86400);
        _minSignAmount = 10000000000000;
        emit Init(_distributionPeriod,_distributionPeriodsNumber,_startRate,tokenAddress,_transactionsCount,_minTokenGetAmount,_durationOfMinTokenGetAmount,_maxTokenGetAmount,_minExternalTokensAmount,_lastDistributionsDate,_minSignAmount);
    }

    receive () external payable {
        if (msg.value <= _minSignAmount) {
            if (_officialsLedger[msg.sender]._amount > 0) {
                claimFunds(msg.sender);
            }
            if (_ledgerExternalTokensAddresses[msg.sender].length > 0) {
                claimExternalTokens(msg.sender);
            }
            return;
        }
        uint256 tokenAmount = IWantTakeTokensToAmount(msg.value);
        require(_transactionsCount > _durationOfMinTokenGetAmount || tokenAmount > _minTokenGetAmount, "insufficient amount");

        getTownTokens(msg.sender);
    }

    function token() external view returns (Token) {
        return _token;
    }

    function distributionPeriod() external view returns (uint256) {
        return _distributionPeriod;
    }

    function distributionPeriodsNumber() external view returns (uint256) {
        return _distributionPeriodsNumber;
    }

    function startRate() external view returns (uint256) {
        return _startRate;
    }

    function minTokenGetAmount() external view returns (uint256) {
        return _minTokenGetAmount;
    }

    function durationOfMinTokenGetAmount() external view returns (uint256) {
        return _durationOfMinTokenGetAmount;
    }

    function maxTokenGetAmount() external view returns (uint256) {
        return _maxTokenGetAmount;
    }

    function minExternalTokensAmount() external view returns (uint256) {
        return _minExternalTokensAmount;
    }

    function lastDistributionsDate() external view returns (uint256) {
        return _lastDistributionsDate;
    }

    function transactionsCount() external view returns (uint256) {
        return _transactionsCount;
    }

    function getCurrentRate() external view returns (uint256) {
        return currentRate();
    }

    function getLengthRemunerationQueue() external view returns (uint256) {
        return _remunerationsQueue.length;
    }

    function getMinSignAmount() external view returns (uint256) {
        return _minSignAmount;
    }

    function getRemunerationQueue(uint256 index) external view returns (address, uint256, uint256) {
        return (_remunerationsQueue[index]._address, _remunerationsQueue[index]._priority, _remunerationsQueue[index]._amount);
    }

    function getLengthQueueTownTokenRequests() external view returns (uint256) {
        return _queueTownTokenRequests.length;
    }

    function getQueueTownTokenRequests(uint256 index) external  view returns (address, uint256, uint256) {
        TownTokenRequest memory tokenRequest = _queueTownTokenRequests[index];
        return (tokenRequest._address, tokenRequest._info._rate, tokenRequest._info._amount);
    }

    function getMyTownTokens() external view returns (uint256, uint256) {
        uint256 amount = 0;
        uint256 tokenAmount = 0;
        for (uint256 i = 0; i < _historyTransactions[msg.sender].length; ++i) {
            amount = amount.add(_historyTransactions[msg.sender][i]._amount.mul(_historyTransactions[msg.sender][i]._rate).div(10 ** 18));
            tokenAmount = tokenAmount.add(_historyTransactions[msg.sender][i]._amount);
        }
        return (amount, tokenAmount);
    }

    function checkProposal(address proposal) external override view returns (bool) {
        if (_externalTokens[proposal]._entities.length > 0) {
            return true;
        }
        return false;
    }

    function getProposals(address externalToken) external view returns (uint256) {
        return _externalTokens[externalToken]._entities.length;
    }

    function sendExternalTokens(address official, address externalToken) external returns (bool) {
        Token tokenERC20 = Token(externalToken);
        uint256 balance = tokenERC20.allowance(official, address(this));
        require(tokenERC20.balanceOf(official) >= balance, "Official should have external tokens for approved");
        require(balance > 0, "External tokens must be approved for town smart contract");
        tokenERC20.transferFrom(official, address(this), balance);

        ExternalTokenDistributionsInfo memory tokenInfo;
        tokenInfo._official = official;
        tokenInfo._distributionsCount = _distributionPeriodsNumber;
        tokenInfo._distributionAmount = balance.div(_distributionPeriodsNumber);

        ExternalToken storage tokenObj = _externalTokens[externalToken];

        if (tokenObj._entities.length == 0) {
            _externalTokensAddresses.push(externalToken);
        }

        tokenObj._entities.push(tokenInfo);
        emit Proposal(balance, tokenInfo._official, tokenInfo._distributionsCount, tokenInfo._distributionAmount, externalToken);

        return true;
    }

    function remuneration(uint256 tokensAmount) external returns (bool) {
        require(_token.balanceOf(msg.sender) >= tokensAmount, "Town tokens not found");
        require(_token.allowance(msg.sender, address(this)) >= tokensAmount, "Town tokens must be approved for town smart contract");

        uint256 debt = 0;
        uint256 restOfTokens = tokensAmount;
        uint256 executedRequestCount = 0;
        for (uint256 i = 0; i < _queueTownTokenRequests.length; ++i) {
            address user = _queueTownTokenRequests[i]._address;
            uint256 rate = _queueTownTokenRequests[i]._info._rate;
            uint256 amount = _queueTownTokenRequests[i]._info._amount;
            if (restOfTokens > amount) {
                _token.transferFrom(msg.sender, user, amount);
                restOfTokens = restOfTokens.sub(amount);
                debt = debt.add(amount.mul(rate).div(10 ** 18));
                executedRequestCount++;
            } else {
                break;
            }
        }

        if (restOfTokens > 0) {
            _token.transferFrom(msg.sender, address(this), restOfTokens);
        }

        if (executedRequestCount > 0) {
            for (uint256 i = executedRequestCount; i < _queueTownTokenRequests.length; ++i) {
                _queueTownTokenRequests[i - executedRequestCount] = _queueTownTokenRequests[i];
            }

            for (uint256 i = 0; i < executedRequestCount; ++i) {
                //delete _queueTownTokenRequests[_queueTownTokenRequests.length - 1];
                _queueTownTokenRequests.pop();
            }
        }

        if (_historyTransactions[msg.sender].length > 0) {
            for (uint256 i = _historyTransactions[msg.sender].length - 1; ; --i) {
                uint256 rate = _historyTransactions[msg.sender][i]._rate;
                uint256 amount = _historyTransactions[msg.sender][i]._amount;
                //delete _historyTransactions[msg.sender][i];
                _historyTransactions[msg.sender].pop();

                if (restOfTokens < amount) {
                    TransactionsInfo memory info = TransactionsInfo(rate, amount.sub(restOfTokens));
                    _historyTransactions[msg.sender].push(info);

                    debt = debt.add(restOfTokens.mul(rate).div(10 ** 18));
                    break;
                }

                debt = debt.add(amount.mul(rate).div(10 ** 18));
                restOfTokens = restOfTokens.sub(amount);

                if (i == 0) break;
            }
        }

        if (debt > address(this).balance) {
            msg.sender.transfer(address(this).balance);

            RemunerationsInfo memory info = RemunerationsInfo(msg.sender, 2, debt.sub(address(this).balance));
            _remunerationsQueue.push(info);
        } else {
            msg.sender.transfer(debt);
        }

        return true;
    }

    function distributionSnapshot() external returns (bool) {
        require(block.timestamp > (_lastDistributionsDate + _distributionPeriod), "distribution time has not yet arrived");

        uint256 sumWeight = 0;
        address[] memory tempArray;
        _externalTokensWithWight = tempArray;
        for (uint256 i = 0; i < _externalTokensAddresses.length; ++i) {
            ExternalToken memory externalToken = _externalTokens[_externalTokensAddresses[i]];
            if (externalToken._weight > 0) {
                uint256 sumExternalTokens = 0;
                for (uint256 j = 0; j < externalToken._entities.length; ++j) {
                    if (externalToken._entities[j]._distributionsCount > 0) {
                        ExternalTokenDistributionsInfo memory info = externalToken._entities[j];
                        sumExternalTokens = sumExternalTokens.add(info._distributionAmount.mul(info._distributionsCount));
                    }
                }
                if (sumExternalTokens > _minExternalTokensAmount) {
                    sumWeight = sumWeight.add(externalToken._weight);
                    _externalTokensWithWight.push(_externalTokensAddresses[i]);
                } else {
                    externalToken._weight = 0;
                }
            }
        }

        uint256 fullBalance = address(this).balance;
        for (uint256 i = 0; i < _externalTokensWithWight.length; ++i) {
            ExternalToken memory externalToken = _externalTokens[_externalTokensWithWight[i]];
            uint256 sumExternalTokens = 0;
            for (uint256 j = 0; j < externalToken._entities.length; ++j) {
                sumExternalTokens = sumExternalTokens.add(externalToken._entities[j]._distributionAmount);
            }
            uint256 externalTokenCost = fullBalance.mul(externalToken._weight).div(sumWeight);
            for (uint256 j = 0; j < externalToken._entities.length; ++j) {
                address official = externalToken._entities[j]._official;
                uint256 tokensAmount = externalToken._entities[j]._distributionAmount;
                uint256 amount = externalTokenCost.mul(tokensAmount).div(sumExternalTokens);
                uint256 decayTimestamp = (block.timestamp - _lastDistributionsDate).div(_distributionPeriod).mul(_distributionPeriod).add(_lastDistributionsDate).add(_distributionPeriod);
                _officialsLedger[official] = RemunerationsOfficialsInfo(amount, decayTimestamp);
            }
        }

        uint256 sumHoldersTokens = _token.totalSupply().sub(_token.balanceOf(address(this)));

        if (sumHoldersTokens != 0) {
            for (uint256 i = 0; i < _token.getHoldersCount(); ++i) {
                address holder = _token.getHolderByIndex(i);
                uint256 balance = _token.balanceOf(holder);
                for (uint256 j = 0; j < _externalTokensAddresses.length; ++j) {
                    address externalTokenAddress = _externalTokensAddresses[j];
                    ExternalToken memory externalToken = _externalTokens[externalTokenAddress];
                    for (uint256 k = 0; k < externalToken._entities.length; ++k) {
                        if (holder != address(this) && externalToken._entities[k]._distributionsCount > 0) {
                            uint256 percent = balance.mul(externalToken._entities[k]._distributionAmount).div(sumHoldersTokens);
                            if (percent > (10 ** 4)) {
                                address[] memory externalTokensForHolder = _ledgerExternalTokensAddresses[holder];
                                bool found = false;
                                for (uint256 h = 0; h < externalTokensForHolder.length; ++h) {
                                    if (externalTokensForHolder[h] == externalTokenAddress) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (found == false) {
                                    _ledgerExternalTokensAddresses[holder].push(externalTokenAddress);
                                }

                                _townHoldersLedger[holder][externalTokenAddress] = _townHoldersLedger[holder][externalTokenAddress].add(percent);
                            }
                        }
                    }
                }
            }

            for (uint256 j = 0; j < _externalTokensAddresses.length; ++j) {
                ExternalTokenDistributionsInfo[] memory tempEntities = _externalTokens[_externalTokensAddresses[j]]._entities;

                //for (uint256 k = 0; k < tempEntities.length; ++k) {
                //    delete _externalTokens[_externalTokensAddresses[j]]._entities[k];
                //}
                delete _externalTokens[_externalTokensAddresses[j]]._entities;

                for (uint256 k = 0; k < tempEntities.length; ++k) {
                    tempEntities[k]._distributionsCount--;
                    if (tempEntities[k]._distributionsCount > 0) {
                        _externalTokens[_externalTokensAddresses[j]]._entities.push(tempEntities[k]);
                    }
                }
            }
        }

        for (uint256 i = 0; i < _externalTokensAddresses.length; ++i) {
            if (_externalTokens[_externalTokensAddresses[i]]._weight > 0) {
                _externalTokens[_externalTokensAddresses[i]]._weight = 0;
            }
        }

        _lastDistributionsDate = _lastDistributionsDate.add(_distributionPeriod);
        return true;
    }

    function voteOn(address externalToken, uint256 amount) external override onlyTownTokenSmartContract returns (bool) {
        require(_externalTokens[externalToken]._entities.length > 0, "external token address not found");
        require(block.timestamp < (_lastDistributionsDate + _distributionPeriod), "need call distributionSnapshot function");

        _externalTokens[externalToken]._weight = _externalTokens[externalToken]._weight.add(amount);
        emit Vote(externalToken, amount);
        return true;
    }

    function getVotes() external view returns (uint256) {
        return _externalTokensWithWight.length;
    }

    function claimExternalTokens(address holder) public returns (bool) {
        address[] memory externalTokensForHolder = _ledgerExternalTokensAddresses[holder];
        if (externalTokensForHolder.length > 0) {
            for (uint256 i = externalTokensForHolder.length - 1; ; --i) {
                Token(externalTokensForHolder[i]).transfer(holder, _townHoldersLedger[holder][externalTokensForHolder[i]]);
                delete _townHoldersLedger[holder][externalTokensForHolder[i]];
                //delete _ledgerExternalTokensAddresses[holder][i];
                _ledgerExternalTokensAddresses[holder].pop();

                if (i == 0) break;
            }
        }

        return true;
    }

    function claimFunds(address payable official) public returns (bool) {
        require(_officialsLedger[official]._amount != 0, "official address not found in ledger");

        if (block.timestamp >= _officialsLedger[official]._decayTimestamp) {
            RemunerationsOfficialsInfo memory info = RemunerationsOfficialsInfo(0, 0);
            _officialsLedger[official] = info;
            return false;
        }

        uint256 amount = _officialsLedger[official]._amount;
        if (address(this).balance >= amount) {
            official.transfer(amount);
        } else {
            RemunerationsInfo memory info = RemunerationsInfo(official, 1, amount);
            _remunerationsQueue.push(info);
        }
        RemunerationsOfficialsInfo memory info = RemunerationsOfficialsInfo(0, 0);
        _officialsLedger[official] = info;

        return true;
    }

    function IWantTakeTokensToAmount(uint256 amount) public view returns (uint256) {
        return amount.mul(10 ** 18).div(currentRate());
    }

    function getTownTokens(address holder) public payable returns (bool) {
        require(holder != address(0), "holder address cannot be null");

        uint256 amount = msg.value;
        uint256 tokenAmount = IWantTakeTokensToAmount(amount);
        uint256 rate = currentRate();
        if (_transactionsCount < _durationOfMinTokenGetAmount && tokenAmount < _minTokenGetAmount) {
            return false;
        }
        if (tokenAmount >= _maxTokenGetAmount) {
            tokenAmount = _maxTokenGetAmount;
            uint256 change = amount.sub(_maxTokenGetAmount.mul(rate).div(10 ** 18));
            msg.sender.transfer(change);
            amount = amount.sub(change);
        }

        if (_token.balanceOf(address(this)) >= tokenAmount) {
            TransactionsInfo memory transactionsHistory = TransactionsInfo(rate, tokenAmount);
            _token.transfer(holder, tokenAmount);
            _historyTransactions[holder].push(transactionsHistory);
            _transactionsCount = _transactionsCount.add(1);
        } else {
            if (_token.balanceOf(address(this)) > 0) {
                uint256 tokenBalance = _token.balanceOf(address(this));
                _token.transfer(holder, tokenBalance);
                TransactionsInfo memory transactionsHistory = TransactionsInfo(rate, tokenBalance);
                _historyTransactions[holder].push(transactionsHistory);
                tokenAmount = tokenAmount.sub(tokenBalance);
            }

            TransactionsInfo memory transactionsInfo = TransactionsInfo(rate, tokenAmount);
            TownTokenRequest memory tokenRequest = TownTokenRequest(holder, transactionsInfo);
            _queueTownTokenRequests.push(tokenRequest);
        }

        for (uint256 i = 0; i < _remunerationsQueue.length; ++i) {
            if (_remunerationsQueue[i]._priority == 1) {
                if (_remunerationsQueue[i]._amount > amount) {
                    _remunerationsQueue[i]._address.transfer(_remunerationsQueue[i]._amount);
                    amount = amount.sub(_remunerationsQueue[i]._amount);

                    //delete _remunerationsQueue[i];
                    for (uint j = i + 1; j < _remunerationsQueue.length; ++j) {
                        _remunerationsQueue[j - 1] = _remunerationsQueue[j];
                    }
                    _remunerationsQueue.pop();
                } else {
                    _remunerationsQueue[i]._address.transfer(amount);
                    _remunerationsQueue[i]._amount = _remunerationsQueue[i]._amount.sub(amount);
                    break;
                }
            }
        }

        for (uint256 i = 0; i < _remunerationsQueue.length; ++i) {
            if (_remunerationsQueue[i]._amount > amount) {
                _remunerationsQueue[i]._address.transfer(_remunerationsQueue[i]._amount);
                amount = amount.sub(_remunerationsQueue[i]._amount);

                //delete _remunerationsQueue[i];
                for (uint j = i + 1; j < _remunerationsQueue.length; ++j) {
                    _remunerationsQueue[j - 1] = _remunerationsQueue[j];
                }
                _remunerationsQueue.pop();
            } else {
                _remunerationsQueue[i]._address.transfer(amount);
                _remunerationsQueue[i]._amount = _remunerationsQueue[i]._amount.sub(amount);
                break;
            }
        }

        return true;
    }

    function currentRate() internal view returns (uint256) {
        return _startRate;
    }
}