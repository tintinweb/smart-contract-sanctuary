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

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn&#39;t abstract since the compiler emits automatically generated getter functions as external
    function owner() public constant returns (address owner) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

/*
    Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still need to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
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

/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

/*
    We consider every contract to be a &#39;token holder&#39; since it&#39;s currently not possible
    for a contract to deny receiving tokens.

    The TokenHolder&#39;s contract sole purpose is to provide a safety mechanism that allows
    the owner to send tokens that were sent to the contract by mistake back to their sender.
*/
contract TokenHolder is ITokenHolder, Owned {
    /**
        @dev constructor
    */
    function TokenHolder() {
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    /**
        @dev withdraws tokens held by the contract and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

/*
    Smart Token interface
*/
contract ISmartToken is ITokenHolder, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

/*
    The smart token controller is an upgradable part of the smart token that allows
    more functionality as well as fixes for bugs/exploits.
    Once it accepts ownership of the token, it becomes the token&#39;s sole controller
    that can execute any of its functions.

    To upgrade the controller, ownership must be transferred to a new controller, along with
    any relevant data.

    The smart token must be set on construction and cannot be changed afterwards.
    Wrappers are provided (as opposed to a single &#39;execute&#39; function) for each of the token&#39;s functions, for easier access.

    Note that the controller can transfer token ownership to a new controller that
    doesn&#39;t allow executing any function on the token, for a trustless solution.
    Doing that will also remove the owner&#39;s ability to upgrade the controller.
*/
contract SmartTokenController is TokenHolder {
    ISmartToken public token;   // smart token

    /**
        @dev constructor
    */
    function SmartTokenController(ISmartToken _token)
        validAddress(_token)
    {
        token = _token;
    }

    // ensures that the controller is the token&#39;s owner
    modifier active() {
        assert(token.owner() == address(this));
        _;
    }

    // ensures that the controller is not the token&#39;s owner
    modifier inactive() {
        assert(token.owner() != address(this));
        _;
    }

    /**
        @dev allows transferring the token ownership
        the new owner still need to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new token owner
    */
    function transferTokenOwnership(address _newOwner) public ownerOnly {
        token.transferOwnership(_newOwner);
    }

    /**
        @dev used by a new owner to accept a token ownership transfer
        can only be called by the contract owner
    */
    function acceptTokenOwnership() public ownerOnly {
        token.acceptOwnership();
    }

    /**
        @dev disables/enables token transfers
        can only be called by the contract owner

        @param _disable    true to disable transfers, false to enable them
    */
    function disableTokenTransfers(bool _disable) public ownerOnly {
        token.disableTransfers(_disable);
    }

    /**
        @dev allows the owner to execute the token&#39;s issue function

        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issueTokens(address _to, uint256 _amount) public ownerOnly {
        token.issue(_to, _amount);
    }

    /**
        @dev allows the owner to execute the token&#39;s destroy function

        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroyTokens(address _from, uint256 _amount) public ownerOnly {
        token.destroy(_from, _amount);
    }

    /**
        @dev withdraws tokens held by the token and sends them to an account
        can only be called by the owner

        @param _token   ERC20 token contract address
        @param _to      account to receive the new amount
        @param _amount  amount to withdraw
    */
    function withdrawFromToken(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        token.withdrawTokens(_token, _to, _amount);
    }
}

/*
    Bancor Formula interface
*/
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint16 _reserveRatio, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint16 _reserveRatio, uint256 _sellAmount) public constant returns (uint256);
}

/*
    EIP228 Token Changer interface
*/
contract ITokenChanger {
    function changeableTokenCount() public constant returns (uint16 count);
    function changeableToken(uint16 _tokenIndex) public constant returns (address tokenAddress);
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public constant returns (uint256 amount);
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 amount);
}

/*
    Open issues:
    - Add miner front-running attack protection. The issue is somewhat mitigated by the use of _minReturn when changing
    - Possibly add getters for reserve fields so that the client won&#39;t need to rely on the order in the struct
*/

/*
    Bancor Changer v0.1

    The Bancor version of the token changer, allows changing between a smart token and other ERC20 tokens and between different ERC20 tokens and themselves.

    ERC20 reserve token balance can be virtual, meaning that the calculations are based on the virtual balance instead of relying on
    the actual reserve balance. This is a security mechanism that prevents the need to keep a very large (and valuable) balance in a single contract.

    The changer is upgradable (just like any SmartTokenController).

    WARNING: It is NOT RECOMMENDED to use the changer with Smart Tokens that have less than 8 decimal digits
             or with very small numbers because of precision loss
*/
contract BancorChanger is ITokenChanger, SmartTokenController, SafeMath {
    struct Reserve {
        uint256 virtualBalance;         // virtual balance
        uint8 ratio;                    // constant reserve ratio (CRR), 1-100
        bool isVirtualBalanceEnabled;   // true if virtual balance is enabled, false if not
        bool isPurchaseEnabled;         // is purchase of the smart token enabled with the reserve, can be set by the token owner
        bool isSet;                     // used to tell if the mapping element is defined
    }

    string public version = &#39;0.1&#39;;
    string public changerType = &#39;bancor&#39;;

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
        SmartTokenController(_token)
        validAddress(_formula)
    {
        formula = _formula;

        if (address(_reserveToken) != 0x0)
            addReserve(_reserveToken, _reserveRatio, false);
    }

    // verifies that an amount is greater than zero
    modifier validAmount(uint256 _amount) {
        require(_amount > 0);
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

    /*
        @dev allows the owner to update the formula contract address

        @param _formula    address of a bancor formula contract
    */
    function setFormula(IBancorFormula _formula)
        public
        ownerOnly
        validAddress(_formula)
        notThis(_formula)
    {
        require(_formula != formula); // validate input
        formula = _formula;
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
        ownerOnly
        inactive
        validAddress(_token)
        notThis(_token)
        validReserveRatio(_ratio)
    {
        require(_token != address(token) && !reserves[_token].isSet && totalReserveRatio + _ratio <= 100); // validate input

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
        @param _virtualBalance         new reserve&#39;s virtual balance
    */
    function updateReserve(IERC20Token _reserveToken, uint8 _ratio, bool _enableVirtualBalance, uint256 _virtualBalance)
        public
        ownerOnly
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
        ownerOnly
        validReserve(_reserveToken)
    {
        reserves[_reserveToken].isPurchaseEnabled = !_disable;
    }

    /**
        @dev returns the reserve&#39;s virtual balance if one is defined, otherwise returns the actual balance

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
        @dev returns the expected return for changing a specific amount of _fromToken to _toToken

        @param _fromToken  ERC20 token to change from
        @param _toToken    ERC20 token to change to
        @param _amount     amount to change, in fromToken

        @return expected change return amount
    */
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount)
        public
        constant
        validToken(_fromToken)
        validToken(_toToken)
        returns (uint256 amount)
    {
        require(_fromToken != _toToken); // validate input

        // change between the token and one of its reserves
        if (_toToken == token)
            return getPurchaseReturn(_fromToken, _amount);
        else if (_fromToken == token)
            return getSaleReturn(_toToken, _amount);

        // change between 2 reserves
        uint256 purchaseReturnAmount = getPurchaseReturn(_fromToken, _amount);
        return getSaleReturn(_toToken, purchaseReturnAmount, safeAdd(token.totalSupply(), purchaseReturnAmount));
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

        @param _fromToken  ERC20 token to change from
        @param _toToken    ERC20 token to change to
        @param _amount     amount to change, in fromToken
        @param _minReturn  if the change results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return change return amount
    */
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn)
        public
        validToken(_fromToken)
        validToken(_toToken)
        returns (uint256 amount)
    {
        require(_fromToken != _toToken); // validate input

        // change between the token and one of its reserves
        if (_toToken == token)
            return buy(_fromToken, _amount, _minReturn);
        else if (_fromToken == token)
            return sell(_toToken, _amount, _minReturn);

        // change between 2 reserves
        uint256 purchaseAmount = buy(_fromToken, _amount, 1);
        return sell(_toToken, purchaseAmount, _minReturn);
    }

    /**
        @dev buys the token by depositing one of its reserve tokens

        @param _reserveToken   reserve token contract address
        @param _depositAmount  amount to deposit (in the reserve token)
        @param _minReturn      if the change results in an amount smaller than the minimum return - it is cancelled, must be nonzero

        @return buy return amount
    */
    function buy(IERC20Token _reserveToken, uint256 _depositAmount, uint256 _minReturn)
        public
        validAmount(_minReturn)
        returns (uint256 amount) {
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
        @param _minReturn      if the change results in an amount smaller the minimum return - it is cancelled, must be nonzero

        @return sell return amount
    */
    function sell(IERC20Token _reserveToken, uint256 _sellAmount, uint256 _minReturn)
        public
        validAmount(_minReturn)
        returns (uint256 amount) {
        require(_sellAmount <= token.balanceOf(msg.sender)); // validate input

        amount = getSaleReturn(_reserveToken, _sellAmount);
        assert(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        uint256 reserveBalance = getReserveBalance(_reserveToken);
        assert(amount <= reserveBalance); // ensure that the trade won&#39;t result in negative reserve

        uint256 tokenSupply = token.totalSupply();
        assert(amount < reserveBalance || _sellAmount == tokenSupply); // ensure that the trade will only deplete the reserve if the total supply is depleted as well

        // update virtual balance if relevant
        Reserve reserve = reserves[_reserveToken];
        if (reserve.isVirtualBalanceEnabled)
            reserve.virtualBalance = safeSub(reserve.virtualBalance, amount);

        token.destroy(msg.sender, _sellAmount); // destroy _sellAmount from the caller&#39;s balance in the smart token
        assert(_reserveToken.transfer(msg.sender, amount)); // transfer funds to the caller in the reserve token
                                                            // note that it might fail if the actual reserve balance is smaller than the virtual balance
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
        validAmount(_totalSupply)
        returns (uint256 amount)
    {
        Reserve reserve = reserves[_reserveToken];
        uint256 reserveBalance = getReserveBalance(_reserveToken);
        return formula.calculateSaleReturn(_totalSupply, reserveBalance, reserve.ratio, _sellAmount);
    }
}