pragma solidity >=0.6.2;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";


contract abre is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _mock;
    mapping(address => uint256) private _scores;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private constant _totalSupply = 10 * 10**6 * 10**18;
    uint256 private constant _antiBotsPeriod = 45;

    uint256 private _totalFees;
    uint256 private _totalScores;
    uint256 private _rate;

    mapping(address => bool) private _exchanges;
    mapping(address => uint256) private _lastTransactionPerUser;

    string private _name = 'Abre.Finance';
    string private _symbol = 'ABRE';
    uint8 private _decimals = 18;

    constructor() public {
        _balances[_msgSender()] = _totalSupply;
        _exchanges[_msgSender()] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    // ERC20 STRUCTURE

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_exchanges[account]) return _balances[account];

        return _calculateBalance(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance'));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero'));
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        if (_exchanges[sender] && !_exchanges[recipient]) {
            _transferFromExchangeToUser(sender, recipient, amount);
        }
        else if (!_exchanges[sender] && _exchanges[recipient]) {
            _transferFromUserToExchange(sender, recipient, amount);
        }
        else if (!_exchanges[sender] && !_exchanges[recipient]) {
            _transferFromUserToUser(sender, recipient, amount);
        }
        else if (_exchanges[sender] && _exchanges[recipient]) {
            _transferFromExchangeToExchange(sender, recipient, amount);
        } else {
            _transferFromUserToUser(sender, recipient, amount);
        }
    }

    // SETTERS

    function _transferFromExchangeToUser(
        address exchange,
        address user,
        uint256 amount
    ) private {
        require(_calculateBalance(exchange) >= amount, 'ERC20: transfer amount exceeds balance');

        (uint256 fees,, uint256 scoreRate, uint256 amountSubFees) = _getWorth(_calculateBalance(user).add(amount), user, amount, true);

        _balances[exchange] = _calculateBalance(exchange).sub(amount);
        _balances[user] = _calculateBalance(user).add(amountSubFees);

        _reScore(user, scoreRate);
        _reRate(fees);
        _lastTransactionPerUser[user] = block.number;

        emit Transfer(exchange, user, amount);
    }

    function _transferFromUserToExchange(
        address user,
        address exchange,
        uint256 amount
    ) private {
        require(_calculateBalance(user) >= amount, 'ERC20: transfer amount exceeds balance');

        (uint256 fees,, uint256 scoreRate, uint256 amountSubFees) = _getWorth(_calculateBalance(user), user, amount, true);

        _balances[exchange] = _calculateBalance(exchange).add(amountSubFees);
        _balances[user] = _calculateBalance(user).sub(amount);

        _reScore(user, scoreRate);
        _reRate(fees);
        _lastTransactionPerUser[user] = block.number;

        emit Transfer(user, exchange, amount);
    }

    function _transferFromUserToUser(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(_calculateBalance(sender) >= amount, 'ERC20: transfer amount exceeds balance');

        (uint256 fees,, uint256 senderScoreRate, uint256 amountSubFees) = _getWorth(_calculateBalance(sender), sender, amount, true);
        (,, uint256 recipientScoreRate,) = _getWorth(_calculateBalance(recipient).add(amount), recipient, amount, false);

        _balances[recipient] = _calculateBalance(recipient).add(amountSubFees);
        _balances[sender] = _calculateBalance(sender).sub(amount);

        _reScore(sender, senderScoreRate);
        _reScore(recipient, recipientScoreRate);
        _reRate(fees);
        _lastTransactionPerUser[sender] = block.number;

        emit Transfer(sender, recipient, amount);
    }

    function _transferFromExchangeToExchange(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(_calculateBalance(sender) >= amount, 'ERC20: transfer amount exceeds balance');

        _balances[sender] = _calculateBalance(sender).sub(amount);
        _balances[recipient] = _calculateBalance(recipient).add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _reScore(address account, uint256 score) private {
        _totalScores = _totalScores.sub(_scores[account]);
        _scores[account] = _balances[account].mul(score);
        _mock[account] = _scores[account].mul(_rate).div(1e18);
        _totalScores = _totalScores.add(_scores[account]);
    }

    function _reRate(uint256 fees) private {
        _totalFees = _totalFees.add(fees);
        if(_totalScores > 0)
            _rate = _rate.add(fees.mul(1e18).div(_totalScores));
    }

    function setExchange(address account) public onlyOwner() {
        require(!_exchanges[account], 'Account is already exchange');

        _balances[account] = _calculateBalance(account);
        _totalScores = _totalScores.sub(_scores[account]);
        _scores[account] = 0;
        _exchanges[account] = true;
    }

    function removeExchange(address account) public onlyOwner() {
        require(_exchanges[account], 'Account not exchange');

        (,, uint256 scoreRate,) = _getWorth(_calculateBalance(account), account, _calculateBalance(account), false);
        _balances[account] = _calculateBalance(account);
        if (scoreRate > 0) _reScore(account, scoreRate);
        _exchanges[account] = false;
    }

    // PUBLIC GETTERS

    function getScore(address account) public view returns (uint256) {
        return _scores[account];
    }

    function getTotalScores() public view returns (uint256) {
        return _totalScores;
    }

    function getTotalFees() public view returns (uint256) {
        return _totalFees;
    }

    function isExchange(address account) public view returns (bool) {
        return _exchanges[account];
    }

    function getTradingFees(address account) public view returns (uint256) {
        (, uint256 feesRate,,) = _getWorth(_calculateBalance(account), account, 0, true);
        return feesRate;
    }

    function getLastTransactionPerUser(address account) public view returns (uint256) {
        return _lastTransactionPerUser[account];
    }

    // PRIVATE GETTERS

    function _getWorth(
        uint256 balance,
        address account,
        uint256 amount,
        bool antiBots
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fees;
        uint256 feesRate;
        uint256 scoreRate;

        uint256 _startCategory = 500 * 10**18;

        if (balance < _startCategory) {
            feesRate = 120;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 10;
        } else if (balance >= _startCategory && balance < _startCategory.mul(10)) {
            feesRate = 110;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 100;
        } else if (balance >= _startCategory.mul(10) && balance < _startCategory.mul(50)) {
            feesRate = 100;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 110;
        } else if (balance >= _startCategory.mul(50) && balance < _startCategory.mul(100)) {
            feesRate = 90;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 120;
        } else if (balance >= _startCategory.mul(100) && balance < _startCategory.mul(200)) {
            feesRate = 75;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 130;
        } else if (balance >= _startCategory.mul(200)) {
            feesRate = 50;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 140;
        } else {
            feesRate = 100;
            fees = amount.mul(feesRate).div(10000);
            scoreRate = 0;
        }

        if (antiBots == true && block.number < _lastTransactionPerUser[account].add(_antiBotsPeriod)) {
            feesRate = 500;
            fees = amount.mul(feesRate).div(10000);
        }
        uint256 amountSubFees = amount.sub(fees);

        return (fees, feesRate, scoreRate, amountSubFees);
    }

    function _calculateFeesForUser(address account) private view returns (uint256) {
        return _scores[account] > 0 ? _scores[account].mul(_rate).div(1e18).sub(_mock[account]) : 0;
    }

    function _calculateBalance(address account) private view returns (uint256) {
        return _calculateFeesForUser(account) > 0 ? _calculateFeesForUser(account).add(_balances[account]) : _balances[account];
    }
}