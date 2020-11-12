pragma solidity >=0.5.6 <0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DigiExchange {
    using SafeMath for *;

    struct Roadmap {
        uint256 supply;
        uint256 startPrice;
        uint256 incPrice;
    }

    string constant public _name = "Digi Exchange";
    string constant public _symbol = "DIGIX";
    uint8 constant public _decimals = 0;
    uint256 public _totalSupply = 1600000;
    uint256 public _rewardsSupply = 240000;
    uint256 public circulatingSupply = 514538;

    mapping(address => bool) private administrators;

    address commissionHolder;
    address stakeHolder;
    uint256 commissionFunds = 0;
    uint256 public commissionPercent = 400;
    uint256 public sellCommission = 600;
    uint256 public tokenCommissionPercent = 250;
    uint256 public buyPrice;
    uint256 public sellPrice;
    uint8 public currentRoadmap = 3;
    uint8 public sellRoadmap = 3;
    uint8 constant public LAST_ROADMAP = 18;
    uint256 public currentRoadmapUsedSupply = 14538;
    uint256 public sellRoadmapUsedSupply = 14538;
    uint256 public totalStakeTokens = 0;
    uint256 public totalLockInTokens = 0;
    uint256 public locakablePercent = 750;
    bool buyLimit = true;
    uint256 buyLimitToken = 2100;
    uint256 minBuyToken = 10;

    address dev; //Backend Operation
    address dev1; //  Operations
    address dev2; // Research Funds
    address dev3; //Marketing
    address dev4; // Development
    address dev5; //Compliance

    uint256 dev1Com;
    uint256 dev2Com;
    uint256 dev3Com;
    uint256 dev4Com;
    uint256 dev5Com;


    mapping(address => uint256) commissionOf;
    mapping(address => uint256) userIncomes;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public stakeBalanceOf;
    mapping(uint8 => Roadmap) public priceRoadmap;
    mapping(address => uint256) public _lockInBalances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Stake(address indexed staker, uint256 value, uint256 totalInStake);
    event UnStake(address indexed staker, uint256 value, uint256 totalInStake);
    event CommissionWithdraw(address indexed user, uint256 amount);
    event WithdrawTokenCommission(address indexed user, uint256 amount, uint256 nonce);
    event WithdrawStakingCommission(address indexed user, uint256 amount, uint256 nonce);
    event Price(uint256 buyPrice, uint256 sellPrice, uint256 circulatingSupply);
    event StakeUser(address indexed user, uint256 value, uint256 totalInStake, uint256 nonce);
    event LockIn(address indexed from, address indexed to, uint256 value);
    event TransactionFees(address to, uint256 totalValue);

    constructor(address _commissionHolder, address _stakeHolder) public {
        administrators[msg.sender] = true;
        administrators[_commissionHolder] = true;
        dev = msg.sender;
        commissionHolder = _commissionHolder;
        stakeHolder = _stakeHolder;
        createRoadmap();
        buyPrice = 867693750000000;
        sellPrice = 867688750000000;
    }

    function() external payable {
        revert();
    }

    modifier onlyAdministrators{
        require(administrators[msg.sender], "Only administrators can execute this function");
        _;
    }

    function upgradeContract(address[] memory users) public onlyAdministrators {
        for (uint i = 0; i < users.length; i++) {
            _balances[users[i]] += 500;
            _lockInBalances[users[i]] += 1500;
            _balances[commissionHolder] += 666;
            emit Transfer(address(this), users[i], _balances[users[i]]);
            emit LockIn(users[i], address(this), _lockInBalances[users[i]]);
        }
    }

    function upgradeDetails(uint256 _bp, uint256 _sp, uint256 _circSup, uint8 _currentRp, uint8 _sellRp, uint256 _crs, uint256 _srs, uint256 _commFunds) public onlyAdministrators {
        buyPrice = _bp;
        sellPrice = _sp;
        circulatingSupply = _circSup;
        currentRoadmap = _currentRp;
        sellRoadmap = _sellRp;
        currentRoadmapUsedSupply = _crs;
        sellRoadmapUsedSupply = _srs;
        commissionFunds = _commFunds;
    }

    function stake(address _user, uint256 _tokens, uint256 nonce) public onlyAdministrators {
        require(_tokens <= _balances[_user], "User dont have enough tokens to stake");
        _balances[_user] -= _tokens;
        stakeBalanceOf[_user] += _tokens;
        totalStakeTokens += _tokens;
        emit StakeUser(_user, _tokens, totalStakeTokens, nonce);
    }

    function stakeExt(address _user, uint256 _tokens) private {
        require(_tokens <= _balances[_user], "You dont have enough tokens to stake");
        _balances[_user] -= _tokens;
        stakeBalanceOf[_user] += _tokens;
        totalStakeTokens += _tokens;
        emit Stake(_user, _tokens, totalStakeTokens);
    }

    function unStake(address _user, uint256 _tokens) public onlyAdministrators {
        require(_tokens <= stakeBalanceOf[_user], "User doesnt have amount of token in stake");
        stakeBalanceOf[_user] -= _tokens;
        totalStakeTokens -= _tokens;
        _balances[_user] += _tokens;
        emit UnStake(_user, _tokens, totalStakeTokens);
    }

    function lockInExt(address _user, uint256 _tokens) private {
        _lockInBalances[_user] += _tokens;
        totalLockInTokens += _tokens;
    }

    function releaseLockIn(address _user, uint256 _tokens) public onlyAdministrators {
        require(_tokens <= _lockInBalances[_user], "User dont have enough balance in Tokens");
        _lockInBalances[_user] = _lockInBalances[_user] - _tokens;
        _balances[_user] = _balances[_user] + _tokens;

        totalLockInTokens = totalLockInTokens - _tokens;
        emit LockIn(address(this), _user, _tokens);
    }

    function addLiquidity() external payable returns (bool){
        return true;
    }

    function purchase(uint256 tokens) external payable {
        purchaseExt(msg.sender, tokens, msg.value);
    }

    function sell(uint256 _tokens) public {
        require(_tokens > 0, "Tokens can not be zero");
        require(_tokens <= _balances[msg.sender], "You dont have enough amount of token");
        sellExt(msg.sender, _tokens);

    }

    function sellExt(address _user, uint256 _tokens) private {
        uint256 saleAmount = updateSale(_tokens);
        _balances[_user] -= _tokens;
        uint256 _commission = saleAmount.mul(sellCommission).div(10000);
        uint256 _balanceAfterCommission = saleAmount.sub(_commission);
        uint256 txnFees = _commission * 200 / 1000;
        commissionOf[dev] += txnFees;
        uint256 userInc = _commission * 50 / 10000;
        userIncomes[commissionHolder] += userInc;
        commissionFunds += (_commission - txnFees) - userInc;

        emit Transfer(_user, address(this), _tokens);
        emit Price(buyPrice, sellPrice, circulatingSupply);
        emit TransactionFees(address(this), _commission);
        sendBalanceAmount(_user, _balanceAfterCommission);
    }

    function purchaseExt(address _user, uint256 _tokens, uint256 _amountInEth) private {
        require(_tokens >= minBuyToken, "Minimum tokens should be buy");
        require(_tokens + circulatingSupply <= _totalSupply, "All tokens has purchased");
        require(_amountInEth > 0 ether, "amount can not be zero");


        if (buyLimit) {
            uint256 tokenWithoutComm = _tokens.sub(_tokens.mul(tokenCommissionPercent).div(1000));
            require(_balances[_user] + stakeBalanceOf[_user] + tokenWithoutComm + _lockInBalances[_user] <= buyLimitToken, "Exceeding buy Limit");
        }

        uint32 size;
        assembly {
            size := extcodesize(_user)
        }
        require(size == 0, "cannot be a contract");

        uint256 _commission = _amountInEth.mul(commissionPercent).div(10000);
        uint256 _balanceEthAfterCommission = _amountInEth - _commission;
        uint256 purchaseAmount = updatePurchase(_tokens, _balanceEthAfterCommission);
        uint256 txnFees = _commission * 200 / 1000;
        uint256 userInc = _commission * 100 / 10000;
        commissionOf[dev] += txnFees;
        userIncomes[commissionHolder] += userInc;
        commissionFunds += (_commission - txnFees) - userInc;
        uint256 _tokenCommission = _tokens.mul(tokenCommissionPercent).div(1000);
        uint256 _tokensAfterCommission = _tokens - _tokenCommission;
        if (buyLimit) {
            uint256 lockableTokens = _tokensAfterCommission.mul(locakablePercent).div(1000);
            _balances[commissionHolder] += _tokenCommission;
            _balances[_user] += _tokensAfterCommission - lockableTokens;
            lockInExt(_user, lockableTokens);

            emit Transfer(address(this), _user, _tokensAfterCommission.sub(lockableTokens));
            emit Price(buyPrice, sellPrice, circulatingSupply);
            emit LockIn(_user, address(this), lockableTokens);


        } else {
            _balances[commissionHolder] += _tokenCommission;
            _balances[_user] += _tokens - _tokenCommission;

            emit Transfer(address(this), _user, _tokens.sub(_tokenCommission));
            emit Price(buyPrice, sellPrice, circulatingSupply);
        }
        emit TransactionFees(address(this), _commission);

        if (purchaseAmount < _balanceEthAfterCommission) {
            sendBalanceAmount(_user, _balanceEthAfterCommission - purchaseAmount);
        }
    }


    function updateSale(uint256 _tokens) private returns (uint256 saleAmount){
        uint256 _saleAmount = uint256(0);

        Roadmap memory _roadmap = priceRoadmap[sellRoadmap];

        uint256 _sellRoadmapUsedSupply = sellRoadmapUsedSupply;

        uint256 _balanceSupplyInCurrentRoadmap = _sellRoadmapUsedSupply;

        _roadmap = priceRoadmap[sellRoadmap];
        if (_tokens < _balanceSupplyInCurrentRoadmap) {
            _saleAmount += ((2 * sellPrice * _tokens) - (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;

            sellPrice = _roadmap.startPrice + ((_balanceSupplyInCurrentRoadmap - _tokens) * _roadmap.incPrice) - _roadmap.incPrice;
            buyPrice = _roadmap.startPrice + (((_balanceSupplyInCurrentRoadmap + 1) - _tokens) * _roadmap.incPrice) - _roadmap.incPrice;
            sellRoadmapUsedSupply -= _tokens;
            currentRoadmapUsedSupply = sellRoadmapUsedSupply;
            circulatingSupply -= _tokens;
            currentRoadmap = sellRoadmap;
            return _saleAmount;

        } else if (_tokens == _balanceSupplyInCurrentRoadmap) {
            _saleAmount += ((2 * sellPrice * _tokens) - (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            if (sellRoadmap == 1) {
                sellPrice = priceRoadmap[1].startPrice;
                buyPrice = priceRoadmap[1].startPrice;
                currentRoadmap = 1;
                sellRoadmapUsedSupply = 0;
                currentRoadmapUsedSupply = 0;
            } else {
                sellPrice = priceRoadmap[sellRoadmap - 1].startPrice + (priceRoadmap[sellRoadmap - 1].supply * priceRoadmap[sellRoadmap - 1].incPrice) - priceRoadmap[sellRoadmap - 1].incPrice;
                buyPrice = priceRoadmap[sellRoadmap].startPrice;
                currentRoadmap = sellRoadmap;
                sellRoadmap -= 1;
                sellRoadmapUsedSupply = priceRoadmap[sellRoadmap].supply;
                currentRoadmapUsedSupply = 0;
            }
            circulatingSupply -= _tokens;
            return _saleAmount;
        }

        uint256 noOfTokensToSell = _tokens;
        uint256 _sellPrice = uint256(0);
        for (uint8 i = sellRoadmap; i > 0; i--) {
            _roadmap = priceRoadmap[i];
            _balanceSupplyInCurrentRoadmap = _sellRoadmapUsedSupply;
            if (i == sellRoadmap) {
                _sellPrice = sellPrice;
            } else {
                _sellPrice = _roadmap.startPrice + (_roadmap.supply * _roadmap.incPrice) - _roadmap.incPrice;
            }
            if (noOfTokensToSell > _balanceSupplyInCurrentRoadmap) {
                _saleAmount += ((2 * _sellPrice * _balanceSupplyInCurrentRoadmap) - (_balanceSupplyInCurrentRoadmap * _balanceSupplyInCurrentRoadmap * _roadmap.incPrice) - (_balanceSupplyInCurrentRoadmap * _roadmap.incPrice)) / 2;
                noOfTokensToSell -= _balanceSupplyInCurrentRoadmap;
                _sellRoadmapUsedSupply = priceRoadmap[i - 1].supply;
            } else if (noOfTokensToSell < _balanceSupplyInCurrentRoadmap) {
                _saleAmount += ((2 * _sellPrice * noOfTokensToSell) - (noOfTokensToSell * noOfTokensToSell * _roadmap.incPrice) - (noOfTokensToSell * _roadmap.incPrice)) / 2;

                sellPrice = _roadmap.startPrice + ((_balanceSupplyInCurrentRoadmap - noOfTokensToSell) * _roadmap.incPrice) - _roadmap.incPrice;
                buyPrice = _roadmap.startPrice + (((_balanceSupplyInCurrentRoadmap + 1) - noOfTokensToSell) * _roadmap.incPrice) - _roadmap.incPrice;
                sellRoadmapUsedSupply = _balanceSupplyInCurrentRoadmap - noOfTokensToSell;
                currentRoadmapUsedSupply = sellRoadmapUsedSupply;

                circulatingSupply -= _tokens;
                currentRoadmap = i;
                sellRoadmap = i;
                return _saleAmount;

            } else {
                _saleAmount += ((2 * _sellPrice * noOfTokensToSell) - (noOfTokensToSell * noOfTokensToSell * _roadmap.incPrice) - (noOfTokensToSell * _roadmap.incPrice)) / 2;

                sellPrice = priceRoadmap[i - 1].startPrice + (priceRoadmap[i - 1].supply * priceRoadmap[i - 1].incPrice) - priceRoadmap[i - 1].incPrice;
                buyPrice = priceRoadmap[i].startPrice;
                sellRoadmap = i - 1;
                sellRoadmapUsedSupply = priceRoadmap[sellRoadmap].supply;
                currentRoadmapUsedSupply = 0;
                circulatingSupply -= _tokens;
                currentRoadmap = i;
                return _saleAmount;
            }
        }
    }

    function updatePurchase(uint256 _tokens, uint256 _userEthAmount) private returns (uint256 purchaseAmount){
        uint256 _purchaseAmount = uint256(0);

        Roadmap memory _roadmap = priceRoadmap[currentRoadmap];

        uint256 _currentRoadmapUsedSupply = currentRoadmapUsedSupply;

        uint256 _balanceSupplyInCurrentRoadmap = _currentRoadmapUsedSupply > _roadmap.supply ? _currentRoadmapUsedSupply - _roadmap.supply : _roadmap.supply - _currentRoadmapUsedSupply;
        if (_tokens < _balanceSupplyInCurrentRoadmap) {
            _purchaseAmount += ((2 * buyPrice * _tokens) + (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            require(_purchaseAmount <= _userEthAmount, "Dont have sufficient balance to purchase");

            sellPrice = buyPrice + (_tokens * _roadmap.incPrice) - _roadmap.incPrice;
            buyPrice = buyPrice + (_tokens * _roadmap.incPrice);

            currentRoadmapUsedSupply += _tokens;
            sellRoadmapUsedSupply = currentRoadmapUsedSupply;
            circulatingSupply += _tokens;
            sellRoadmap = currentRoadmap;
            return _purchaseAmount;

        } else if (_tokens == _balanceSupplyInCurrentRoadmap) {
            _purchaseAmount += ((2 * buyPrice * _tokens) + (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            require(_purchaseAmount <= _userEthAmount, "Dont have sufficient balance to purchase");

            sellPrice = buyPrice + (_tokens * _roadmap.incPrice) - _roadmap.incPrice;
            buyPrice = priceRoadmap[currentRoadmap + 1].startPrice;
            currentRoadmapUsedSupply = 0;
            sellRoadmapUsedSupply = priceRoadmap[currentRoadmap].supply;
            currentRoadmap += 1;
            sellRoadmap = currentRoadmap;
            circulatingSupply += _tokens;
            return _purchaseAmount;
        }


        uint256 noOfTokensToBuy = _tokens;
        uint256 _buyPrice = uint256(0);
        for (uint8 i = currentRoadmap; i <= LAST_ROADMAP; i++) {
            _roadmap = priceRoadmap[i];
            _balanceSupplyInCurrentRoadmap = _currentRoadmapUsedSupply > _roadmap.supply ? _currentRoadmapUsedSupply - _roadmap.supply : _roadmap.supply - _currentRoadmapUsedSupply;
            if (i == currentRoadmap) {
                _buyPrice = buyPrice;
            } else {
                _buyPrice = _roadmap.startPrice;
            }
            if (noOfTokensToBuy > _balanceSupplyInCurrentRoadmap) {
                _purchaseAmount += ((2 * _buyPrice * _balanceSupplyInCurrentRoadmap) + (_balanceSupplyInCurrentRoadmap * _balanceSupplyInCurrentRoadmap * _roadmap.incPrice) - (_balanceSupplyInCurrentRoadmap * _roadmap.incPrice)) / 2;
                require(_purchaseAmount <= _userEthAmount, "Dont have sufficient balance to purchase");
                noOfTokensToBuy -= _balanceSupplyInCurrentRoadmap;
                _currentRoadmapUsedSupply = 0;

            } else if (noOfTokensToBuy < _balanceSupplyInCurrentRoadmap) {
                _purchaseAmount += ((2 * _buyPrice * noOfTokensToBuy) + (noOfTokensToBuy * noOfTokensToBuy * _roadmap.incPrice) - (noOfTokensToBuy * _roadmap.incPrice)) / 2;
                require(_purchaseAmount <= _userEthAmount, "Dont have sufficient balance to purchase");
                if (noOfTokensToBuy == 1) {
                    sellPrice = priceRoadmap[i - 1].startPrice + (priceRoadmap[i - 1].supply * priceRoadmap[i - 1].incPrice) - priceRoadmap[i - 1].incPrice;
                    buyPrice = priceRoadmap[i].startPrice + (noOfTokensToBuy * priceRoadmap[i].incPrice);
                    sellRoadmapUsedSupply = priceRoadmap[i - 1].supply;
                    sellRoadmap = i - 1;
                } else {
                    sellPrice = _buyPrice + (noOfTokensToBuy * _roadmap.incPrice) - _roadmap.incPrice;
                    buyPrice = _buyPrice + (noOfTokensToBuy * _roadmap.incPrice);
                    sellRoadmapUsedSupply = noOfTokensToBuy;
                    sellRoadmap = i;

                }

                currentRoadmap = i;
                currentRoadmapUsedSupply = noOfTokensToBuy;
                circulatingSupply += _tokens;
                return _purchaseAmount;
            } else {
                _purchaseAmount += ((2 * _buyPrice * noOfTokensToBuy) + (noOfTokensToBuy * noOfTokensToBuy * _roadmap.incPrice) - (noOfTokensToBuy * _roadmap.incPrice)) / 2;
                require(_purchaseAmount <= _userEthAmount, "Dont have sufficient balance to purchase");
                sellPrice = _buyPrice + (noOfTokensToBuy * _roadmap.incPrice) - _roadmap.incPrice;
                buyPrice = priceRoadmap[i + 1].startPrice;
                currentRoadmapUsedSupply = 0;
                sellRoadmapUsedSupply = priceRoadmap[i].supply;
                circulatingSupply += _tokens;
                currentRoadmap = i + 1;
                sellRoadmap = i;
                return _purchaseAmount;
            }
        }

    }

    function releaseUserIncome(address _user, uint256 _etherAmount) public onlyAdministrators {
        require(_etherAmount <= userIncomes[commissionHolder], "Not enough amount");
        commissionOf[_user] += _etherAmount;
    }

    function addCommissionFunds(uint256 _amount) private {
        commissionFunds += _amount;
    }

    function getSaleSummary(uint256 _tokens) public view returns (uint256 saleAmount){
        uint256 _saleAmount = uint256(0);

        Roadmap memory _roadmap = priceRoadmap[sellRoadmap];

        uint256 _sellRoadmapUsedSupply = sellRoadmapUsedSupply;

        uint256 _balanceSupplyInCurrentRoadmap = _sellRoadmapUsedSupply;

        _roadmap = priceRoadmap[sellRoadmap];
        if (_tokens < _balanceSupplyInCurrentRoadmap) {
            _saleAmount += ((2 * sellPrice * _tokens) - (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            return _saleAmount;


        } else if (_tokens == _balanceSupplyInCurrentRoadmap) {
            _saleAmount += ((2 * sellPrice * _tokens) - (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            return _saleAmount;
        }

        uint256 noOfTokensToSell = _tokens;
        uint256 _sellPrice = uint256(0);
        for (uint8 i = sellRoadmap; i > 0; i--) {
            _roadmap = priceRoadmap[i];
            _balanceSupplyInCurrentRoadmap = _sellRoadmapUsedSupply;
            if (i == sellRoadmap) {
                _sellPrice = sellPrice;
            } else {
                _sellPrice = _roadmap.startPrice + (_roadmap.supply * _roadmap.incPrice) - _roadmap.incPrice;
            }
            if (noOfTokensToSell > _balanceSupplyInCurrentRoadmap) {
                _saleAmount += ((2 * _sellPrice * _balanceSupplyInCurrentRoadmap) - (_balanceSupplyInCurrentRoadmap * _balanceSupplyInCurrentRoadmap * _roadmap.incPrice) - (_balanceSupplyInCurrentRoadmap * _roadmap.incPrice)) / 2;
                noOfTokensToSell -= _balanceSupplyInCurrentRoadmap;
                _sellRoadmapUsedSupply = priceRoadmap[i - 1].supply;
            } else if (noOfTokensToSell < _balanceSupplyInCurrentRoadmap) {
                _saleAmount += ((2 * _sellPrice * noOfTokensToSell) - (noOfTokensToSell * noOfTokensToSell * _roadmap.incPrice) - (noOfTokensToSell * _roadmap.incPrice)) / 2;
                return _saleAmount;

            } else {
                _saleAmount += ((2 * _sellPrice * noOfTokensToSell) - (noOfTokensToSell * noOfTokensToSell * _roadmap.incPrice) - (noOfTokensToSell * _roadmap.incPrice)) / 2;
                return _saleAmount;
            }
        }
    }

    function getPurchaseSummary(uint256 _tokens) public view returns (uint256){
        uint256 _purchaseAmount = uint256(0);

        Roadmap memory _roadmap = priceRoadmap[currentRoadmap];

        uint256 _currentRoadmapUsedSupply = currentRoadmapUsedSupply;

        uint256 _balanceSupplyInCurrentRoadmap = _currentRoadmapUsedSupply > _roadmap.supply ? _currentRoadmapUsedSupply - _roadmap.supply : _roadmap.supply - _currentRoadmapUsedSupply;
        if (_tokens < _balanceSupplyInCurrentRoadmap) {
            _purchaseAmount += ((2 * buyPrice * _tokens) + (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            return _purchaseAmount;

        } else if (_tokens == _balanceSupplyInCurrentRoadmap) {
            _purchaseAmount += ((2 * buyPrice * _tokens) + (_tokens * _tokens * _roadmap.incPrice) - (_tokens * _roadmap.incPrice)) / 2;
            return _purchaseAmount;
        }


        uint256 noOfTokensToBuy = _tokens;
        uint256 _buyPrice = uint256(0);
        for (uint8 i = currentRoadmap; i <= LAST_ROADMAP; i++) {
            _roadmap = priceRoadmap[i];
            _balanceSupplyInCurrentRoadmap = _currentRoadmapUsedSupply > _roadmap.supply ? _currentRoadmapUsedSupply - _roadmap.supply : _roadmap.supply - _currentRoadmapUsedSupply;
            if (i == currentRoadmap) {
                _buyPrice = buyPrice;
            } else {
                _buyPrice = _roadmap.startPrice;
            }
            if (noOfTokensToBuy > _balanceSupplyInCurrentRoadmap) {
                _purchaseAmount += ((2 * _buyPrice * _balanceSupplyInCurrentRoadmap) + (_balanceSupplyInCurrentRoadmap * _balanceSupplyInCurrentRoadmap * _roadmap.incPrice) - (_balanceSupplyInCurrentRoadmap * _roadmap.incPrice)) / 2;
                noOfTokensToBuy -= _balanceSupplyInCurrentRoadmap;
                _currentRoadmapUsedSupply = 0;

            } else if (noOfTokensToBuy < _balanceSupplyInCurrentRoadmap) {
                _purchaseAmount += ((2 * _buyPrice * noOfTokensToBuy) + (noOfTokensToBuy * noOfTokensToBuy * _roadmap.incPrice) - (noOfTokensToBuy * _roadmap.incPrice)) / 2;
                return _purchaseAmount;
            } else {
                _purchaseAmount += ((2 * _buyPrice * noOfTokensToBuy) + (noOfTokensToBuy * noOfTokensToBuy * _roadmap.incPrice) - (noOfTokensToBuy * _roadmap.incPrice)) / 2;
                return _purchaseAmount;
            }
        }
    }

    function kill(address payable addr) public onlyAdministrators {
        selfdestruct(addr);
    }

    function totalCommissionFunds() public onlyAdministrators view returns (uint256){
        return commissionFunds;
    }

    function addAdministrator(address admin) public onlyAdministrators {
        require(administrators[admin] != true, "address already exists");
        administrators[admin] = true;
    }

    function removeAdministrator(address admin) public onlyAdministrators {
        require(administrators[admin] == true, "address not exists");
        administrators[admin] = false;
    }

    function updateCommissionHolders(address _dev1, address _dev2, address _dev3, address _dev4, address _dev5) public onlyAdministrators {
        dev1 = _dev1;
        dev2 = _dev2;
        dev3 = _dev3;
        dev4 = _dev4;
        dev5 = _dev5;
    }

    function updateCommissionPercent(uint256 _percent) public onlyAdministrators {
        commissionPercent = _percent;
    }

    function updateSellCommissionPercentage(uint256 _percent) public onlyAdministrators {
        sellCommission = _percent;
    }

    function updateTokenCommissionPercent(uint256 _percent) public onlyAdministrators {
        tokenCommissionPercent = _percent;
    }

    function getCommBalance() public view returns (uint256){
        return commissionOf[msg.sender];
    }

    function getCommBalanceAdmin(address _address) public onlyAdministrators view returns (uint256){
        return commissionOf[_address];
    }

    function distributeCommission(uint256 _amount) public onlyAdministrators {
        require(_amount <= commissionFunds, "Dont have enough funds to distribute");
        uint256 totalComPer = dev1Com + dev2Com + dev3Com + dev4Com + dev5Com;
        require(totalComPer == 1000, "Invalid Percent structure");


        commissionOf[dev1] += (_amount * dev1Com) / 1000;
        commissionOf[dev2] += (_amount * dev2Com) / 1000;
        commissionOf[dev3] += (_amount * dev3Com) / 1000;
        commissionOf[dev4] += (_amount * dev4Com) / 1000;
        commissionOf[dev5] += (_amount * dev5Com) / 1000;

        commissionFunds -= _amount;

    }

    function upgradeContract(uint256 _dev1, uint256 _dev2, uint256 _dev3, uint256 _dev4, uint256 _dev5) public onlyAdministrators {
        dev1Com = _dev1;
        dev2Com = _dev2;
        dev3Com = _dev3;
        dev4Com = _dev4;
        dev5Com = _dev5;
    }

    function updateTransFeesAdd(address _address) public onlyAdministrators {
        require(dev != _address, "Address already added");
        dev = _address;
    }

    function withdrawCommission(uint256 _amount) public {
        require(_amount <= commissionOf[msg.sender], "Dont have funds to withdraw");
        commissionOf[msg.sender] -= _amount;
        sendBalanceAmount(msg.sender, _amount);
        emit CommissionWithdraw(msg.sender, _amount);
    }

    function withdrawTokenCommission(address _user, uint256 _amount, uint256 nonce) public onlyAdministrators {
        require(_amount <= _balances[commissionHolder], "Dont have enough tokens");
        _balances[commissionHolder] -= _amount;
        _balances[_user] += _amount;
        emit WithdrawTokenCommission(_user, _amount, nonce);
    }

    function withdrawStakeEarning(address _user, uint256 _amount, uint256 nonce) public onlyAdministrators {
        require(_amount <= _balances[stakeHolder], "Dont have enough tokens");
        _balances[_user] += _amount;
        _balances[stakeHolder] -= _amount;
        emit WithdrawStakingCommission(_user, _amount, nonce);
    }

    function updateTokenCommHolder(address _address) public onlyAdministrators {
        require(commissionHolder != _address, "Holder already exist");
        _balances[_address] = _balances[commissionHolder];
        _balances[commissionHolder] -= _balances[_address];

    }

    function updateStakeHolder(address _address) public onlyAdministrators {
        require(stakeHolder != _address, "Holder already exist");
        _balances[_address] = _balances[stakeHolder];
        _balances[stakeHolder] -= _balances[_address];
    }

    function createRoadmap() private {


        Roadmap memory roadmap = Roadmap({
        supply : 100000,
        startPrice : 0.00027 ether,
        incPrice : 0.00000000125 ether
        });

        priceRoadmap[1] = roadmap;

        roadmap = Roadmap({
        supply : 400000,
        startPrice : 0.00039499975 ether,
        incPrice : 0.000000001 ether
        });

        priceRoadmap[2] = roadmap;

        roadmap = Roadmap({
        supply : 100000,
        startPrice : 0.00079500375 ether,
        incPrice : 0.000000005 ether
        });

        priceRoadmap[3] = roadmap;

        roadmap = Roadmap({
        supply : 100000,
        startPrice : 0.00129500875 ether,
        incPrice : 0.00000001 ether
        });

        priceRoadmap[4] = roadmap;

        roadmap = Roadmap({
        supply : 100000,
        startPrice : 0.00229501875 ether,
        incPrice : 0.00000002 ether
        });

        priceRoadmap[5] = roadmap;

        roadmap = Roadmap({
        supply : 90000,
        startPrice : 0.00429504375 ether,
        incPrice : 0.000000045 ether
        });

        priceRoadmap[6] = roadmap;

        roadmap = Roadmap({
        supply : 90000,
        startPrice : 0.00834507875 ether,
        incPrice : 0.00000008 ether
        });

        priceRoadmap[7] = roadmap;

        roadmap = Roadmap({
        supply : 70000,
        startPrice : 0.01554517875 ether,
        incPrice : 0.00000018 ether
        });

        priceRoadmap[8] = roadmap;

        roadmap = Roadmap({
        supply : 70000,
        startPrice : 0.02814534875 ether,
        incPrice : 0.00000035 ether
        });

        priceRoadmap[9] = roadmap;

        roadmap = Roadmap({
        supply : 70000,
        startPrice : 0.052645748750 ether,
        incPrice : 0.00000075 ether
        });

        priceRoadmap[10] = roadmap;

        roadmap = Roadmap({
        supply : 60000,
        startPrice : 0.10514679875 ether,
        incPrice : 0.0000018 ether
        });

        priceRoadmap[11] = roadmap;

        roadmap = Roadmap({
        supply : 60000,
        startPrice : 0.21314779875 ether,
        incPrice : 0.0000028 ether
        });

        priceRoadmap[12] = roadmap;

        roadmap = Roadmap({
        supply : 60000,
        startPrice : 0.38115099875 ether,
        incPrice : 0.000006 ether
        });

        priceRoadmap[13] = roadmap;

        roadmap = Roadmap({
        supply : 50000,
        startPrice : 0.74115699875 ether,
        incPrice : 0.000012 ether
        });

        priceRoadmap[14] = roadmap;

        roadmap = Roadmap({
        supply : 50000,
        startPrice : 1.34116999875 ether,
        incPrice : 0.000025 ether
        });

        priceRoadmap[15] = roadmap;

        roadmap = Roadmap({
        supply : 50000,
        startPrice : 2.59118999875 ether,
        incPrice : 0.000045 ether
        });

        priceRoadmap[16] = roadmap;

        roadmap = Roadmap({
        supply : 40000,
        startPrice : 4.841234998750 ether,
        incPrice : 0.00009 ether
        });

        priceRoadmap[17] = roadmap;

        roadmap = Roadmap({
        supply : 40000,
        startPrice : 8.44126499875 ether,
        incPrice : 0.00012 ether
        });

        priceRoadmap[18] = roadmap;

    }

    function sendBalanceAmount(address _receiver, uint256 _amount) private {
        if (!address(uint160(_receiver)).send(_amount)) {
            address(uint160(_receiver)).transfer(_amount);
        }
    }

    function getBuyPrice() public view returns (uint256){
        return buyPrice;
    }

    function getSellPrice() public view returns (uint256){
        return sellPrice;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalEthBalance() public view returns (uint256){
        return address(this).balance;
    }

    function updateBuyLimit(bool limit) public onlyAdministrators {
        buyLimit = limit;
    }

    function updateBuyLimitToken(uint256 _noOfTokens) public onlyAdministrators {
        buyLimitToken = _noOfTokens;
    }

    function updateMinBuyToken(uint256 _tokens) public onlyAdministrators {
        minBuyToken = _tokens;
    }

    function updateLockablePercent(uint256 _percent) public onlyAdministrators {
        locakablePercent = _percent;
    }
}