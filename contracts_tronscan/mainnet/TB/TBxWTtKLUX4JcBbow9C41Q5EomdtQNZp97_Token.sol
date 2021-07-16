//SourceUnit: Token.sol

/*

"Participation in Immutable Transparency (PITcoin)

Regulating the Regulators

Taking the business out of law, banking and politics."

"A Blockchain For What Is Best Creation"

*/

pragma solidity 0.5.8;


interface Erc20 {
    function transfer(address _to, uint256 _value) external;
}


library Math {
    /// @return uint256 = a + b
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    /// @return uint256 = a - b
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "too big value");
        return a - b;
    }

    /// @return uint256 = a * b
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /// @return uint256 = a / b
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /// @return int256 = a + b
    function signedAdd(int256 a, uint256 b) internal pure returns (int256) {
        int256 c = a + int256(b);
        assert(c >= a);
        return c;
    }

    /// @return int256 = a - b
    function signedSub(int256 a, uint256 b) internal pure returns (int256) {
        int256 c = a - int256(b);
        assert(c <= a);
        return c;
    }
}


/// @title PITcoin Bond
/// @author aqoleg
contract Token {
    using Math for uint256;
    using Math for int256;

    uint256 public totalSupply; // tokens, erc20
    mapping(address => uint256) public balanceOf; // tokens, erc20
    mapping(address => mapping(address => uint256)) public allowance; // tokens = allowance[owner][spender], erc20
    uint8 public constant decimals = 18; // erc20
    string public name; // erc20
    string public symbol; // erc20

    // trx*price = totalSupply + totalSupply*profitPerToken/multiplicator - sum(payoutsOf) + sum(refDividendsOf)
    // dividendsOf = balanceOf*profitPerToken/multiplicator - payoutsOf
    // allDividends = dividendsOf + refDividendsOf
    uint256 public constant price = 1000000000000; // tokens/trx
    uint256 public profitPerToken;
    uint256 public constant multiplicator = 2**64;
    mapping(address => int256) public payoutsOf; // tokens
    mapping(address => uint256) public refDividendsOf; // tokens
    uint256 public constant refRequirement = 10**21; // tokens

    /// @dev erc20
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @dev erc20
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @param _increase increase of the dividends, tokens*2**-64
    event Sell(address indexed _seller, uint256 _value, uint256 _increase);

    event Withdraw(address indexed _owner, uint256 _value);

    event Reinvest(address indexed _owner, uint256 _value);

    /// @param _increase increase of the dividends, tokens*2**-64
    event Buy(address indexed _buyer, address _referral, uint256 _tokens, uint256 _increase);

    /// @param _increase increase of the dividends, tokens*2**-64
    event Send(address indexed _sender, uint256 _increase);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    /// @notice converts 90% of incoming trx in tokens, spreads rest as dividends
    function () external payable {
        buy(address(0));
    }

    /// @notice keep clean from other tokens
    function clean(address _contract, uint256 _value) external {
        Erc20(_contract).transfer(msg.sender, _value);
    }

    /// @notice converts 90% in user dividends, spreads rest as dividends
    function sell(uint256 _tokens) external {
        // w*pr = T + T*ppt/m - P + R
        // w*pr = T-t + (T-t)*(ppt + f*m/(T-t))/m - (P - ((t-f) + t*ppt/m)) + R

        uint256 fee = _tokens.div(10);
        uint256 withdraw = _tokens.sub(fee);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        require(totalSupply != 0, "zero total supply");
        emit Transfer(msg.sender, address(0), _tokens);

        uint256 payout = withdraw.add(_tokens.mul(profitPerToken).div(multiplicator));
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedSub(payout);

        uint256 increaseProfitPerToken = fee.mul(multiplicator).div(totalSupply);
        profitPerToken = profitPerToken.add(increaseProfitPerToken);

        emit Sell(msg.sender, _tokens, increaseProfitPerToken);
    }

    /// @notice withdraws all of the dividends, including referral
    function withdraw() external {
        // w*pr = T + T*ppt/m - P + R
        // (w - (d+r)/pr)*pr = T + T*ppt/m - (P + d) + (R - r)

        uint256 dividends = dividendsOf(msg.sender);
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedAdd(dividends);

        dividends = dividends.add(refDividendsOf[msg.sender]);
        refDividendsOf[msg.sender] = 0;

        require(dividends != 0, "zero dividends");

        emit Withdraw(msg.sender, dividends);

        msg.sender.transfer(dividends.div(price));
    }

    /// @notice converts all of the dividends (including referral) in tokens
    function reinvest() external {
        // w*pr = T + T*ppt/m - P + R
        // w*pr = T+d+r + (T+d+r)*ppt/m - (P + d + (d+r)*ppt/m) + (R - r)

        uint256 dividends = dividendsOf(msg.sender);

        uint256 allDividends = dividends.add(refDividendsOf[msg.sender]);
        refDividendsOf[msg.sender] = 0;

        require(allDividends != 0, "zero dividends");

        balanceOf[msg.sender] = balanceOf[msg.sender].add(allDividends);
        totalSupply = totalSupply.add(allDividends);
        emit Transfer(address(0), msg.sender, allDividends);

        uint256 payout = dividends.add(allDividends.mul(profitPerToken).div(multiplicator));
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedAdd(payout);

        emit Reinvest(msg.sender, allDividends);
    }

    /// @notice converts 90% of incoming eth in tokens, spreads rest as dividends
    /// @param _ref referral address that gets 3%, or zero address
    function buy(address _ref) public payable {
        // w*pr = T + T*ppt/m - P + R
        // with ref
        // in*pr = t + f + r
        // (w + in)*pr = T+t + (T+t)*(ppt + f*m/T)/m - (P + t*(ppt + f*m/T)/m) + (R + r)
        // no ref
        // in*pr = t + f
        // (w + in)*pr = T+t + (T+t)*(ppt + f*m/T)/m - (P + t*(ppt + f*m/T)/m) + R
        // first
        // in*pr = t
        // (w + in)*pr = T+t + (T+t)*ppt/m - (P + t*ppt/m) + R

        uint256 tokens = msg.value.mul(price);
        uint256 fee = tokens.div(10);
        tokens = tokens.sub(fee);

        if (_ref != address(0) && balanceOf[_ref] >= refRequirement) {
            require(_ref != msg.sender, "_ref is sender");
            uint256 refBonus = fee.mul(3).div(10);
            fee = fee.sub(refBonus);
            refDividendsOf[_ref] = refDividendsOf[_ref].add(refBonus);
        }

        uint256 increaseProfitPerToken = 0;
        if (totalSupply != 0) {
            increaseProfitPerToken = fee.mul(multiplicator).div(totalSupply);
            profitPerToken = profitPerToken.add(increaseProfitPerToken);
        } else {
            tokens = tokens.add(fee);
        }

        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        totalSupply = totalSupply.add(tokens);
        emit Transfer(address(0), msg.sender, tokens);

        uint256 payout = tokens.mul(profitPerToken).div(multiplicator);
        payoutsOf[msg.sender] = payoutsOf[msg.sender].signedAdd(payout);

        emit Buy(msg.sender, _ref, tokens, increaseProfitPerToken);
    }

    /// @notice transfers tokens, spreads plus 5% among all
    /// @dev erc20
    function transfer(address _to, uint256 _value) public returns (bool) {
        send(msg.sender, _to, _value);

        return true;
    }

    /// @notice transfers tokens, spreads plus 5% among all
    /// @dev erc20
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        send(_from, _to, _value);

        return true;
    }

    /// @notice approves other address to spend your tokens
    /// @dev erc20
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "zero _spender");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /// @notice not including referral dividends
    function dividendsOf(address _owner) public view returns (uint256) {
        // dividendsOf = balanceOf*profitPerToken/multiplicator - payoutsOf

        uint256 a = balanceOf[_owner].mul(profitPerToken).div(multiplicator);
        int256 b = payoutsOf[_owner];
        // a - b
        if (b < 0) {
            return a.add(uint256(-b));
        } else {
            uint256 c = uint256(b);
            if (c > a) {
                return 0;
            }
            return a - c;
        }
    }

    function send(address _from, address _to, uint256 _value) private {
        // w*pr = T + T*ppt/m - P + R
        // newPpt = ppt + f*m/(T-v-f)
        // w*pr = T-f + (T-f)*newPpt/m - (P - (v+f)*ppt/m + v*newPpt/m) + R

        require(_to != address(0), "zero _to");
        uint256 fee = _value.div(20);
        uint256 cost = _value.add(fee);

        balanceOf[_from] = balanceOf[_from].sub(cost);
        balanceOf[_to] = balanceOf[_to].add(_value);
        totalSupply = totalSupply.sub(fee);
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, address(0), fee);

        uint256 payout = cost.mul(profitPerToken).div(multiplicator);
        payoutsOf[_from] = payoutsOf[_from].signedSub(payout);

        uint256 increaseProfitPerToken = fee.mul(multiplicator).div(totalSupply.sub(_value));
        profitPerToken = profitPerToken.add(increaseProfitPerToken);

        payout = _value.mul(profitPerToken).div(multiplicator);
        payoutsOf[_to] = payoutsOf[_to].signedAdd(payout);

        emit Send(msg.sender, increaseProfitPerToken);
    }
}