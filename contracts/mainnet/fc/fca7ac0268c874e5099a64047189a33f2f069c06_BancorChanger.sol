/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

// File: 22May2017/solidity/contracts/SafeMath.sol

pragma solidity ^0.4.11;

/*
    Overflow protected math functions
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() {
    }

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

// File: 22May2017/solidity/contracts/ITokenChanger.sol

pragma solidity ^0.4.11;

/*
    EIP228 Token Changer interface
*/
contract ITokenChanger {
    function changeableTokenCount() public constant returns (uint16 count);
    function changeableToken(uint16 _tokenIndex) public constant returns (address tokenAddress);
    function getReturn(address _fromToken, address _toToken, uint256 _amount) public constant returns (uint256 amount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 amount);
}

// File: 22May2017/solidity/contracts/IOwned.sol

pragma solidity ^0.4.11;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address owner) { owner; }
}

// File: 22May2017/solidity/contracts/IERC20Token.sol

pragma solidity ^0.4.11;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: 22May2017/solidity/contracts/ISmartToken.sol

pragma solidity ^0.4.11;




/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function changer() public constant returns (ITokenChanger changer) { changer; }

    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
    function setChanger(ITokenChanger _changer) public;
}

// File: 22May2017/solidity/contracts/IBancorFormula.sol

pragma solidity ^0.4.11;

/*
    Bancor Formula interface
*/
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint16 _reserveRatio, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint16 _reserveRatio, uint256 _sellAmount) public constant returns (uint256);
}

// File: 22May2017/solidity/contracts/BancorChanger.sol

pragma solidity ^0.4.11;





/*
    Open issues:
    - Add miner front-running attack protection. The issue is somewhat mitigated by the use of _minReturn when changing
    - Possibly add getters for reserve fields so that the client won't need to rely on the order in the struct
*/

/*
    Bancor Changer v0.1

    The Bancor version of the token changer, allows changing between a smart token and other ERC20 tokens and between different ERC20 tokens and themselves

    ERC20 reserve token balance can be virtual, meaning that the calculations are based on the virtual balance instead of relying on
    the actual reserve balance. This is a security mechanism that prevents the need to keep a very large (and valuable) balance in a single contract

    The changer is upgradable - the token owner can replace it with a new version by calling setTokenChanger (it's also a safety mechanism in case of bugs/exploits)
*/
contract BancorChanger is SafeMath, ITokenChanger {
    struct Reserve {
        uint256 virtualBalance;         // virtual balance
        uint8 ratio;                    // constant reserve ratio (CRR), 1-100
        bool isVirtualBalanceEnabled;   // true if virtual balance is enabled, false if not
        bool isPurchaseEnabled;         // is purchase of the smart token enabled with the reserve, can be set by the token owner
        bool isSet;                     // used to tell if the mapping element is defined
    }

    string public version = '0.1';
    string public changerType = 'bancor';

    ISmartToken public token;                       // smart token governed by the changer
    IBancorFormula public formula;                  // bancor calculation formula contract
    address[] public reserveTokens;                 // ERC20 standard token addresses
    mapping (address => Reserve) public reserves;   // reserve token addresses -> reserve data
    uint8 private totalReserveRatio = 0;            // used to prevent increasing the total reserve ratio above 100% efficiently

    // triggered when a change between two tokens occurs
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _trader, uint256 _amount, uint256 _return);

    /**
        @dev constructor

        @param _token      smart token governed by the changer
        @param _formula    address of a bancor formula contract
    */
    function BancorChanger(ISmartToken _token, IBancorFormula _formula, IERC20Token _reserveToken, uint8 _reserveRatio)
        validAddress(_token)
        validAddress(_formula)
    {
        token = _token;
        formula = _formula;

        if (address(_reserveToken) != 0x0)
            addReserve(_reserveToken, _reserveRatio, false);
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // validates a reserve token address - verifies that the address belongs to one of the reserve tokens
    modifier validReserve(address _address) {
        require(reserves[_address].isSet);
        _;
    }

    // validates a token address - verifies that the address belongs to one of the changeable tokens
    modifier validToken(address _address) {
        require(_address == address(token) || reserves[_address].isSet);
        _;
    }

    // validates reserve ratio range
    modifier validReserveRatio(uint8 _ratio) {
        require(_ratio > 0 && _ratio <= 100);
        _;
    }

    // verifies that an amount is greater than zero
    modifier validAmount(uint256 _amount) {
        require(_amount > 0);
        _;
    }

    // allows execution by the token owner only
    modifier tokenOwnerOnly {
        assert(msg.sender == token.owner());
        _;
    }

    // ensures that token changing is connected to the smart token
    modifier active() {
        assert(token.changer() == this);
        _;
    }

    // ensures that token changing is not conneccted to the smart token
    modifier inactive() {
        assert(token.changer() != this);
        _;
    }

    /**
        @dev returns the number of reserve tokens defined

        @return number of reserve tokens
    */
    function reserveTokenCount() public constant returns (uint16 count) {
        return uint16(reserveTokens.length);
    }

    /**
        @dev returns the number of changeable tokens supported by the contract
        note that the number of changeable tokens is the number of reserve token, plus 1 (that represents the smart token)

        @return number of changeable tokens
    */
    function changeableTokenCount() public constant returns (uint16 count) {
        return reserveTokenCount() + 1;
    }

    /**
        @dev given a changeable token index, returns the changeable token contract address

        @param _tokenIndex  changeable token index

        @return number of changeable tokens
    */
    function changeableToken(uint16 _tokenIndex) public constant returns (address tokenAddress) {
        if (_tokenIndex == 0)
            return token;
        return reserveTokens[_tokenIndex - 1];
    }

    /**
        @dev defines a new reserve for the token
        can only be called by the token owner while the changer is inactive

        @param _token                  address of the reserve token
        @param _ratio                  constant reserve ratio, 1-100
        @param _enableVirtualBalance   true to enable virtual balance for the reserve, false to disable it
    */
    function addReserve(IERC20Token _token, uint8 _ratio, bool _enableVirtualBalance)
        public
        tokenOwnerOnly
        inactive
        validAddress(_token)
        validReserveRatio(_ratio)
    {
        require(_token != address(this) && _token != address(token) && !reserves[_token].isSet && totalReserveRatio + _ratio <= 100); // validate input

        reserves[_token].virtualBalance = 0;
        reserves[_token].ratio = _ratio;
        reserves[_token].isVirtualBalanceEnabled = _enableVirtualBalance;
        reserves[_token].isPurchaseEnabled = true;
        reserves[_token].isSet = true;
        reserveTokens.push(_token);
        totalReserveRatio += _ratio;
    }

    /**
        @dev updates one of the token reserves
        can only be called by the token owner

        @param _reserveToken           address of the reserve token
        @param _ratio                  constant reserve ratio, 1-100
        @param _enableVirtualBalance   true to enable virtual balance for the reserve, false to disable it
        @param _virtualBalance         new reserve's virtual balance
    */
    function updateReserve(IERC20Token _reserveToken, uint8 _ratio, bool _enableVirtualBalance, uint256 _virtualBalance)
        public
        tokenOwnerOnly
        validReserve(_reserveToken)
        validReserveRatio(_ratio)
    {
        Reserve reserve = reserves[_reserveToken];
        require(totalReserveRatio - reserve.ratio + _ratio <= 100); // validate input

        totalReserveRatio = totalReserveRatio - reserve.ratio + _ratio;
        reserve.ratio = _ratio;
        reserve.isVirtualBalanceEnabled = _enableVirtualBalance;
        reserve.virtualBalance = _virtualBalance;
    }

    /**
        @dev disables purchasing with the given reserve token in case the reserve token got compromised
        can only be called by the token owner
        note that selling is still enabled regardless of this flag and it cannot be disabled by the token owner

        @param _reserveToken    reserve token contract address
        @param _disable         true to disable the token, false to re-enable it
    */
    function disableReservePurchases(IERC20Token _reserveToken, bool _disable)
        public
        tokenOwnerOnly
        validReserve(_reserveToken)
    {
        reserves[_reserveToken].isPurchaseEnabled = !_disable;
    }

    /**
        @dev returns the reserve's virtual balance if one is defined, otherwise returns the actual balance

        @param _reserveToken    reserve token contract address

        @return reserve balance
    */
    function getReserveBalance(IERC20Token _reserveToken)
        public
        constant
        validReserve(_reserveToken)
        returns (uint256 balance)
    {
        Reserve reserve = reserves[_reserveToken];
        return reserve.isVirtualBalanceEnabled ? reserve.virtualBalance : _reserveToken.balanceOf(this);
    }

    /**
        @dev allows the token owner to execute the token's issue function

        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issueTokens(address _to, uint256 _amount) public tokenOwnerOnly {
        token.issue(_to, _amount);
    }

    /**
        @dev allows the token owner to execute the token's destroy function

        @param _from       account to remove the new amount from
        @param _amount     amount to decrease the supply by
    */
    function destroyTokens(address _from, uint256 _amount) public tokenOwnerOnly {
        token.destroy(_from, _amount);
    }

    /**
        @dev withdraws tokens from the reserve and sends them to an account
        can only be called by the token owner

        @param _reserveToken    reserve token contract address
        @param _to              account to receive the new amount
        @param _amount          amount to withdraw (in the reserve token)
    */
    function withdraw(IERC20Token _reserveToken, address _to, uint256 _amount)
        public
        tokenOwnerOnly
        validReserve(_reserveToken)
        validAddress(_to)
        validAmount(_amount)
    {
        require(_to != address(this) && _to != address(token)); // validate input

        assert(_reserveToken.transfer(_to, _amount));

        // update virtual balance if relevant
        Reserve reserve = reserves[_reserveToken];
        if (reserve.isVirtualBalanceEnabled)
            reserve.virtualBalance = safeSub(reserve.virtualBalance, _amount);
    }

    /**
        @dev sets the smart token's changer address to a different one instead of the current contract address
        can only be called by the token owner
        the changer can be set to null to transfer ownership from the changer to the original smart token's owner

        @param _changer    new changer contract address (can also be set to 0x0 to remove the current changer)
    */
    function setTokenChanger(ITokenChanger _changer) public tokenOwnerOnly {
        require(_changer != this && _changer != address(token)); // validate input
        token.setChanger(_changer);
    }

    /**
        @dev returns the expected return for changing a specific amount of _fromToken to _toToken

        @param _fromToken  token to change from
        @param _toToken    token to change to
        @param _amount     amount to change, in fromToken

        @return expected change return amount
    */
    function getReturn(address _fromToken, address _toToken, uint256 _amount)
        public
        constant
        validToken(_fromToken)
        validToken(_toToken)
        returns (uint256 amount)
    {
        require(_fromToken != _toToken); // validate input
        IERC20Token fromToken = IERC20Token(_fromToken);
        IERC20Token toToken = IERC20Token(_toToken);

        // change between the token and one of its reserves
        if (toToken == token)
            return getPurchaseReturn(fromToken, _amount);
        else if (fromToken == token)
            return getSaleReturn(toToken, _amount);

        // change between 2 reserves
        uint256 purchaseReturnAmount = getPurchaseReturn(fromToken, _amount);
        return getSaleReturn(toToken, purchaseReturnAmount, safeAdd(token.totalSupply(), purchaseReturnAmount));
    }

    /**
        @dev returns the expected return for buying the token for a reserve token

        @param _reserveToken   reserve token contract address
        @param _depositAmount  amount to deposit (in the reserve token)

        @return expected purchase return amount
    */
    function getPurchaseReturn(IERC20Token _reserveToken, uint256 _depositAmount)
        public
        constant
        active
        validReserve(_reserveToken)
        validAmount(_depositAmount)
        returns (uint256 amount)
    {
        Reserve reserve = reserves[_reserveToken];
        require(reserve.isPurchaseEnabled); // validate input

        uint256 tokenSupply = token.totalSupply();
        uint256 reserveBalance = getReserveBalance(_reserveToken);
        return formula.calculatePurchaseReturn(tokenSupply, reserveBalance, reserve.ratio, _depositAmount);
    }

    /**
        @dev returns the expected return for selling the token for one of its reserve tokens

        @param _reserveToken   reserve token contract address
        @param _sellAmount     amount to sell (in the smart token)

        @return expected sale return amount
    */
    function getSaleReturn(IERC20Token _reserveToken, uint256 _sellAmount) public constant returns (uint256 amount) {
        return getSaleReturn(_reserveToken, _sellAmount, token.totalSupply());
    }

    /**
        @dev changes a specific amount of _fromToken to _toToken

        @param _fromToken  token to change from
        @param _toToken    token to change to
        @param _amount     amount to change, in fromToken
        @param _minReturn  if the change results in an amount smaller than the minimum return, it is cancelled

        @return change return amount
    */
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn)
        public
        validToken(_fromToken)
        validToken(_toToken)
        returns (uint256 amount)
    {
        require(_fromToken != _toToken); // validate input
        IERC20Token fromToken = IERC20Token(_fromToken);
        IERC20Token toToken = IERC20Token(_toToken);

        // change between the token and one of its reserves
        if (toToken == token)
            return buy(fromToken, _amount, _minReturn);
        else if (fromToken == token)
            return sell(toToken, _amount, _minReturn);

        // change between 2 reserves
        uint256 purchaseAmount = buy(fromToken, _amount, 0);
        return sell(toToken, purchaseAmount, _minReturn);
    }

    /**
        @dev buys the token by depositing one of its reserve tokens

        @param _reserveToken   reserve token contract address
        @param _depositAmount  amount to deposit (in the reserve token)
        @param _minReturn      if the change results in an amount smaller than the minimum return, it is cancelled

        @return buy return amount
    */
    function buy(IERC20Token _reserveToken, uint256 _depositAmount, uint256 _minReturn) public returns (uint256 amount) {
        amount = getPurchaseReturn(_reserveToken, _depositAmount);
        assert(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        // update virtual balance if relevant
        Reserve reserve = reserves[_reserveToken];
        if (reserve.isVirtualBalanceEnabled)
            reserve.virtualBalance = safeAdd(reserve.virtualBalance, _depositAmount);

        assert(_reserveToken.transferFrom(msg.sender, this, _depositAmount)); // transfer _depositAmount funds from the caller in the reserve token
        token.issue(msg.sender, amount); // issue new funds to the caller in the smart token

        Change(_reserveToken, token, msg.sender, _depositAmount, amount);
        return amount;
    }

    /**
        @dev sells the token by withdrawing from one of its reserve tokens

        @param _reserveToken   reserve token contract address
        @param _sellAmount     amount to sell (in the smart token)
        @param _minReturn      if the change results in an amount smaller the minimum return, it is cancelled

        @return sell return amount
    */
    function sell(IERC20Token _reserveToken, uint256 _sellAmount, uint256 _minReturn) public returns (uint256 amount) {
        require(_sellAmount <= token.balanceOf(msg.sender)); // validate input

        amount = getSaleReturn(_reserveToken, _sellAmount);
        assert(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        uint256 reserveBalance = getReserveBalance(_reserveToken);
        assert(amount <= reserveBalance); // ensure that the trade won't result in negative reserve

        uint256 tokenSupply = token.totalSupply();
        assert(amount < reserveBalance || _sellAmount == tokenSupply); // ensure that the trade will only deplete the reserve if the total supply is depleted as well
        token.destroy(msg.sender, _sellAmount); // destroy _sellAmount from the caller's balance in the smart token
        assert(_reserveToken.transfer(msg.sender, amount)); // transfer funds to the caller in the reserve token
                                                           // note that it might fail if the actual reserve balance is smaller than the virtual balance

        // update virtual balance if relevant
        Reserve reserve = reserves[_reserveToken];
        if (reserve.isVirtualBalanceEnabled)
            reserve.virtualBalance = safeSub(reserve.virtualBalance, amount);

        // if the supply was totally depleted, disconnect from the smart token
        if (_sellAmount == tokenSupply)
            token.setChanger(ITokenChanger(0x0));

        Change(token, _reserveToken, msg.sender, _sellAmount, amount);
        return amount;
    }

    /**
        @dev utility, returns the expected return for selling the token for one of its reserve tokens, given a total supply override

        @param _reserveToken   reserve token contract address
        @param _sellAmount     amount to sell (in the smart token)
        @param _totalSupply    total token supply, overrides the actual token total supply when calculating the return

        @return sale return amount
    */
    function getSaleReturn(IERC20Token _reserveToken, uint256 _sellAmount, uint256 _totalSupply)
        private
        constant
        active
        validReserve(_reserveToken)
        validAmount(_sellAmount)
        validAmount(_totalSupply)
        returns (uint256 amount)
    {
        Reserve reserve = reserves[_reserveToken];
        uint256 reserveBalance = getReserveBalance(_reserveToken);
        return formula.calculateSaleReturn(_totalSupply, reserveBalance, reserve.ratio, _sellAmount);
    }

    // fallback
    function() {
        assert(false);
    }
}