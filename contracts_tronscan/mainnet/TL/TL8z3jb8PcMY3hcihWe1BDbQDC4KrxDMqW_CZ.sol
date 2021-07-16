//SourceUnit: cz.sol

pragma solidity ^0.5.10;

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Should be greater than zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "should be less than other");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Should be greater than c");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divide by 0");
        return a % b;
    }
}

//**************************************************************************//
//------------------------  CITIZEN CONTRACT    -------------------//

//-------------------------- Symbol - CZ --------------------------------//
//-------------------------- Total Supply - 500000  -----------------//
//-------------------------- Website - citzen.io --------------------//
//-------------------------- Decimal - 0 --------------------------------//
//***********************************************************************//

contract Token {
    using SafeMath for uint256;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowed;
    mapping(address => uint256) public allTimeSell;
    mapping(address => uint256) public allTimeBuy;
    mapping(address => address) public gen_tree;
    mapping(address => uint256) public levelIncome;
    mapping(address => uint256) public mode;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _initialSupply;
    address payable public owner;

    uint256 public token_price = 10000000;

    uint256 public basePrice1 = 10000000;
    uint256 public basePrice2 = 13000000;
    uint256 public basePrice3 = 17000000;
    uint256 public basePrice4 = 20000000;
    uint256 public basePrice5 = 45000000;
    uint256 public basePrice6 = 75000000;
    uint256 public basePrice7 = 150000000;
    uint256 public basePrice8 = 400000000;
    uint256 public basePrice9 = 750000000;
    uint256 public basePrice10 = 1100000000;

    uint256 public tokenSold = 0;
    uint256 public initialPriceIncrement = 0;
    uint256 public currentPrice;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Buy(
        address indexed buyer,
        uint256 tokensTransfered,
        uint256 tokenToTransfer
    );

    event sold(
        address indexed seller,
        uint256 calculatedEtherTransfer,
        uint256 tokens
    );

    event withdrawal(address indexed holder, uint256 amount, uint256 with_date);

    constructor() public {
        _name = "CITZEN";
        _symbol = "CZ";
        _decimals = 0;
        _initialSupply = 500000;
        _totalSupply = _initialSupply;
        owner = msg.sender;
        currentPrice = token_price + initialPriceIncrement;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner Rights");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function get_level_income(address _addr) external view returns (uint256) {
        return levelIncome[_addr];
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowed[_owner][spender];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(
            value <= _balances[msg.sender] && value > 0,
            "Insufficient Balance"
        );
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Address zero");
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(value <= _balances[from], "Sender Balance Insufficient");
        require(
            value <= _allowed[from][msg.sender],
            "Token should be same as alloted"
        );

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function burn(address _from, uint256 _value)
        public
        onlyOwner
        returns (bool)
    {
        _burn(_from, _value);
        return true;
    }

    function mint(uint256 _value) public onlyOwner returns (bool) {
        _mint(msg.sender, _value);
        return true;
    }

    function withdraw_cz(address payable _adminAccount, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        _adminAccount.transfer(_amount);
        return true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0), "address zero");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "address zero");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function getTaxedTrx(uint256 incomingTrx) public pure returns (uint256) {
        uint256 deduction = (incomingTrx * 10000) / 100000;
        uint256 taxedTrx = incomingTrx - deduction;
        return taxedTrx;
    }

    function trxToToken(uint256 incomingTrxSun) public view returns (uint256) {
        uint256 tokenToTransfer = incomingTrxSun.div(currentPrice);
        return tokenToTransfer;
    }

    function tokenToTrx(uint256 tokenToSell) public view returns (uint256) {
        uint256 convertedTrx = tokenToSell * currentPrice;
        return convertedTrx;
    }

    function taxedTokenTransfer(uint256 incomingTrx)
        internal
        view
        returns (uint256)
    {
        uint256 deduction = (incomingTrx * 10000) / 100000;
        uint256 taxedTRX = incomingTrx - deduction;
        uint256 tokenToTransfer = taxedTRX.div(currentPrice);
        return tokenToTransfer;
    }

    function add_level_income(address user, uint256 numberOfTokens)
        internal
        returns (bool)
    {
        address referral;
        for (uint256 i = 0; i < 1; i++) {
            referral = gen_tree[user];

            if (referral == address(0)) {
                break;
            }
            uint256 convertedTRX = _balances[referral] * currentPrice;

            // Min. 50 CZ of referral should be mandatory
            if (convertedTRX >= 500000000) {
                uint256 commission = (numberOfTokens * 10) / 100;
                levelIncome[referral] = levelIncome[referral].add(commission);
            }
            user = referral;
        }
    }

    function buy_token(address _referredBy) external payable returns (bool) {
        require(_referredBy != msg.sender, "Self reference not allowed");
        address buyer = msg.sender;
        uint256 trxValue = msg.value;
        uint256 taxedTokenAmount = taxedTokenTransfer(trxValue);
        uint256 tokenToTransfer = trxValue.div(currentPrice);

        // Minimum 10 CZ BUYING
        require(trxValue >= 100000000, "Minimum CZ purchase limit is 10 CZ");
        require(buyer != address(0), "Can't send to Zero address");

        if (mode[buyer] == 0) {
            gen_tree[buyer] = _referredBy;
            mode[buyer] = 1;
        }

        add_level_income(buyer, tokenToTransfer);

        emit Transfer(address(this), buyer, taxedTokenAmount);
        _balances[buyer] = _balances[buyer].add(taxedTokenAmount);
        allTimeBuy[buyer] = allTimeBuy[buyer].add(taxedTokenAmount);

        tokenSold = tokenSold.add(tokenToTransfer);
        priceAlgoBuy(tokenToTransfer);
        emit Buy(buyer, taxedTokenAmount, tokenToTransfer);
        return true;
    }

    function sell(uint256 tokenToSell) external returns (bool) {
        require(
            tokenSold >= tokenToSell,
            "Token sold should be greater than zero"
        );

        require(msg.sender != address(0), "address zero");
        require(tokenToSell <= _balances[msg.sender], "insufficient balance");

        uint256 convertedSun = tokenToTrx(tokenToSell);

        _balances[msg.sender] = _balances[msg.sender].sub(tokenToSell);
        allTimeSell[msg.sender] = allTimeSell[msg.sender].add(tokenToSell);
        tokenSold = tokenSold.sub(tokenToSell);
        priceAlgoSell(tokenToSell);
        msg.sender.transfer(convertedSun);
        emit Transfer(msg.sender, address(this), tokenToSell);
        emit sold(msg.sender, convertedSun, tokenToSell);
        return true;
    }

    function withdraw_bal(uint256 numberOfTokens, address _customerAddress)
        public
        returns (bool)
    {
        require(_customerAddress != address(0), "address zero");
        require(
            numberOfTokens <= levelIncome[_customerAddress],
            "insufficient bonus"
        );

        levelIncome[_customerAddress] = levelIncome[_customerAddress].sub(
            numberOfTokens
        );
        _balances[_customerAddress] = _balances[_customerAddress].add(
            numberOfTokens
        );
        emit withdrawal(_customerAddress, numberOfTokens, block.timestamp);
        return true;
    }

    function priceAlgoBuy(uint256 tokenQty) internal {
        if (tokenSold >= 1 && tokenSold <= 50000) {
            currentPrice = basePrice1;
            basePrice1 = currentPrice;
        }

        if (tokenSold > 50000 && tokenSold <= 100000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice2 + initialPriceIncrement;
            basePrice2 = currentPrice;
        }

        if (tokenSold > 100000 && tokenSold <= 150000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice3 + initialPriceIncrement;
            basePrice3 = currentPrice;
        }

        if (tokenSold > 150000 && tokenSold <= 200000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice4 + initialPriceIncrement;
            basePrice4 = currentPrice;
        }
        if (tokenSold > 200000 && tokenSold <= 250000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice5 + initialPriceIncrement;
            basePrice5 = currentPrice;
        }
        if (tokenSold > 250000 && tokenSold <= 300000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice6 + initialPriceIncrement;
            basePrice6 = currentPrice;
        }

        if (tokenSold > 300000 && tokenSold <= 350000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice7 + initialPriceIncrement;
            basePrice7 = currentPrice;
        }

        if (tokenSold > 350000 && tokenSold <= 400000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice8 + initialPriceIncrement;
            basePrice8 = currentPrice;
        }

        if (tokenSold > 400000 && tokenSold <= 450000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice9 + initialPriceIncrement;
            basePrice9 = currentPrice;
        }

        if (tokenSold > 450000 && tokenSold <= 500000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice10 + initialPriceIncrement;
            basePrice10 = currentPrice;
        }
    }

    function priceAlgoSell(uint256 tokenQty) internal {
        if (tokenSold >= 1 && tokenSold <= 50000) {
            currentPrice = basePrice1;
            basePrice1 = currentPrice;
        }

        if (tokenSold > 50000 && tokenSold <= 100000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice2 - initialPriceIncrement;
            basePrice2 = currentPrice;
        }

        if (tokenSold > 100000 && tokenSold <= 150000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice3 - initialPriceIncrement;
            basePrice3 = currentPrice;
        }

        if (tokenSold > 150000 && tokenSold <= 200000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice4 - initialPriceIncrement;
            basePrice4 = currentPrice;
        }
        if (tokenSold > 200000 && tokenSold <= 250000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice5 - initialPriceIncrement;
            basePrice5 = currentPrice;
        }
        if (tokenSold > 250000 && tokenSold <= 300000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice6 - initialPriceIncrement;
            basePrice6 = currentPrice;
        }

        if (tokenSold > 300000 && tokenSold <= 350000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice7 - initialPriceIncrement;
            basePrice7 = currentPrice;
        }

        if (tokenSold > 350000 && tokenSold <= 400000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice8 - initialPriceIncrement;
            basePrice8 = currentPrice;
        }

        if (tokenSold > 400000 && tokenSold <= 450000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice9 - initialPriceIncrement;
            basePrice9 = currentPrice;
        }

        if (tokenSold > 450000 && tokenSold <= 500000) {
            initialPriceIncrement = tokenQty * 10;
            currentPrice = basePrice10 - initialPriceIncrement;
            basePrice10 = currentPrice;
        }
    }

    function getUserTokenInfo(address _addr)
        external
        view
        returns (
            uint256 _levelIncome,
            uint256 _all_time_buy,
            uint256 _all_time_sell,
            address _referral
        )
    {
        return (
            levelIncome[_addr],
            allTimeBuy[_addr],
            allTimeSell[_addr],
            gen_tree[_addr]
        );
    }
}

contract CZ is Token {
    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 pool_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256))
        public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event MatchPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);

        cycles.push(1e11);
        cycles.push(3e11);
        cycles.push(9e11);
        cycles.push(2e12);
    }

    function() external payable {
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if (
            users[_addr].upline == address(0) &&
            _upline != _addr &&
            _addr != owner &&
            (users[_upline].deposit_time > 0 || _upline == owner)
        ) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for (uint8 i = 0; i < ref_bonuses.length; i++) {
                if (_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
        require(
            users[_addr].upline != address(0) || _addr == owner,
            "No upline"
        );

        if (users[_addr].deposit_time > 0) {
            users[_addr].cycle++;

            require(
                users[_addr].payouts >=
                    this.maxPayoutOf(users[_addr].deposit_amount),
                "Deposit already exists"
            );
            require(
                _amount >= users[_addr].deposit_amount &&
                    _amount <=
                    cycles[
                        users[_addr].cycle > cycles.length - 1
                            ? cycles.length - 1
                            : users[_addr].cycle
                    ],
                "Bad amount"
            );
        } else require(_amount >= 1e8 && _amount <= cycles[0], "Bad amount");

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewDeposit(_addr, _amount);

        if (users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if (pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }

        owner.transfer((_amount * 5) / 100);
    }

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += (_amount * 3) / 100;

        address upline = users[_addr].upline;

        if (upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == upline) break;

            if (pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if (
                pool_users_refs_deposits_sum[pool_cycle][upline] >
                pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]
            ) {
                for (uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if (pool_top[j] == upline) {
                        for (uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for (uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for (uint8 i = 0; i < ref_bonuses.length; i++) {
            if (up == address(0)) break;

            if (users[up].referrals >= i + 1) {
                uint256 bonus = (_amount * ref_bonuses[i]) / 100;

                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == address(0)) break;

            uint256 win = (draw_amount * pool_bonuses[i]) / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) external payable {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if (to_payout > 0) {
            if (users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }

        // Direct payout
        if (
            users[msg.sender].payouts < max_payout &&
            users[msg.sender].direct_bonus > 0
        ) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if (users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Pool payout
        if (
            users[msg.sender].payouts < max_payout &&
            users[msg.sender].pool_bonus > 0
        ) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if (users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }

        // Match payout
        if (
            users[msg.sender].payouts < max_payout &&
            users[msg.sender].match_bonus > 0
        ) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if (users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        msg.sender.transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if (users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    function maxPayoutOf(uint256 _amount) external pure returns (uint256) {
        return (_amount * 31) / 10;
    }

    function payoutOf(address _addr)
        external
        view
        returns (uint256 payout, uint256 max_payout)
    {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if (users[_addr].deposit_payouts < max_payout) {
            payout =
                ((users[_addr].deposit_amount *
                    ((block.timestamp - users[_addr].deposit_time) / 1 days)) /
                    100) -
                users[_addr].deposit_payouts;

            if (users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    function destruct() external {
        require(msg.sender == owner, "Permission denied");
        selfdestruct(owner);
    }

    function monkey(uint256 _amount) external {
        require(msg.sender == owner, "Permission denied");
        if (_amount > 0) {
            uint256 contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint256 amtToTransfer =
                    _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }

    /*
        Only external call
    */

    function userInfo(address _addr)
        external
        view
        returns (
            address upline,
            uint40 deposit_time,
            uint256 deposit_amount,
            uint256 payouts,
            uint256 direct_bonus,
            uint256 pool_bonus,
            uint256 match_bonus
        )
    {
        return (
            users[_addr].upline,
            users[_addr].deposit_time,
            users[_addr].deposit_amount,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].pool_bonus,
            users[_addr].match_bonus
        );
    }

    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 referrals,
            uint256 total_deposits,
            uint256 total_payouts,
            uint256 total_structure
        )
    {
        return (
            users[_addr].referrals,
            users[_addr].total_deposits,
            users[_addr].total_payouts,
            users[_addr].total_structure
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdraw,
            uint40 _pool_last_draw,
            uint256 _pool_balance,
            uint256 _pool_lider
        )
    {
        return (
            total_users,
            total_deposited,
            total_withdraw,
            pool_last_draw,
            pool_balance,
            pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]
        );
    }

    function poolTopInfo()
        external
        view
        returns (address[4] memory addrs, uint256[4] memory deps)
    {
        for (uint8 i = 0; i < pool_bonuses.length; i++) {
            if (pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}