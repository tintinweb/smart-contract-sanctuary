/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function zeroSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : 0;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StandardToken is ERC20, BasicToken {
    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint256 _addedValue)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(
            _addedValue
        );
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        returns (bool success)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract PausableToken is StandardToken, Pausable {
    function transfer(address _to, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint256 _addedValue)
        public
        whenNotPaused
        returns (bool success)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        public
        whenNotPaused
        returns (bool success)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        canMint
        returns (bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(0x0, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract XPZToken is BurnableToken, PausableToken, MintableToken {
    string public constant symbol = "XPZ";

    string public constant name = "Decentraland XPZ";

    uint8 public constant decimals = 18;
    
    constructor(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
    }

    function burn(uint256 _value) public whenNotPaused {
        super.burn(_value);
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant PERCENTS_DIVIDER = 10**5;
    // The token being sold
    XPZToken public token;
    uint8 public tokenDecimals;
    // address where funds are collected
    address public wallet;

    uint8 public maxIndex;
    uint256 public feeRate = 9 * 10**4; // back rate
    uint256 public canBackDay = 60 days;

    mapping(address => ReleaseRule) public whiteList;

    mapping(address => UserInfo) public userInfo;

    mapping(uint8 => IndexSale) public indexInfo;

    struct UserInfo {
        uint8 index;
        uint256 buyTime;
        bool isBack;
        uint256 weiAmount;
        uint256 totalLock;
        uint256 remainLock;
        uint256 lastReceiveTime;
    }

    struct IndexSale {
        uint256 startTime;  // start time 
        uint256 endTime;    // end time
        uint256 rate;       // rate 1eth =?token
        uint256 totalSale;  // totalSale token 
        uint256 totalSold;  // Sold token
        uint256 lockTime;   // lock time
        uint256 releaseRate; // release rate eg: 1000 = 1%
        uint256 timeSpan; // How often is it released
        uint256 weiAmount; // total buy eth 
    }

    struct ReleaseRule {
        bool isWhite;
        uint256 releaseRate;
        uint256 timeSpan;
        uint256 lockTime;
    }

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event ExchangeBack(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value
    );

    constructor(address _wallet, address _tokenAddress) public {
        require(_wallet != address(0));
        token = XPZToken(_tokenAddress);
        tokenDecimals = token.decimals();
        wallet = _wallet;
    }
    
    // Period of time that can be retrieved  second
    function setCanBackTime(uint256 _value) public onlyOwner returns(bool _result){
        require(_value > 0);
        canBackDay = _value;
        _result = true;
    }
    
    // set token
    function setToken(address _tokenAddress) public onlyOwner returns(bool _result){
        require(_tokenAddress != address(0));
        token = XPZToken(_tokenAddress);
        tokenDecimals = token.decimals();
        return true;
    }
    
    /* 
        removeMaxIndex  
    */
    function removeMaxIndex() public onlyOwner returns (bool _result) {
        require(maxIndex > 0);
        delete indexInfo[maxIndex];
        maxIndex -= 1;
        _result = true;
    }

    /*
        setIndexInfo
        index = 0 : add
        index > 0 : update index 
        time : Second timestamp
        The time of all periods cannot coincide
    */
    function setIndexInfo(
        uint8 _index,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _totalSale,
        uint256 _lockTime,
        uint256 _timeSpan,
        uint256 _releaseRate
    ) public onlyOwner returns (bool _result) {
        require(_startTime >= now);
        require(_endTime > _startTime);
        require(_lockTime > canBackDay);
        uint8 _nowIndex = _index > 0 ? _index : maxIndex + 1;
        IndexSale storage _indexInfo = indexInfo[_nowIndex];
        if (_index > 0) {
            require(maxIndex >= _index);
            if (_index - 1 > 0)
                require(indexInfo[_index - 1].endTime <= _startTime);
            if (_index + 1 <= maxIndex)
                require(indexInfo[_index + 1].startTime >= _endTime);
        } else {
            require(indexInfo[maxIndex].endTime <= _startTime);
            maxIndex += 1;
        }
        _indexInfo.startTime = _startTime;
        _indexInfo.endTime = _endTime;
        _indexInfo.rate = _rate;
        _indexInfo.totalSale = _totalSale;
        _indexInfo.lockTime = _lockTime;
        _indexInfo.timeSpan = _timeSpan;
        _indexInfo.releaseRate = _releaseRate;
        _result = true;
    }

    // set
    function setWhiteUserInfo(
        address _userAddress,
        uint256 _timeSpan,
        uint256 _releaseRate,
        uint256 _lockTime
    ) public onlyOwner returns (bool _result) {
        require(_userAddress != address(0));
        ReleaseRule storage rule = whiteList[_userAddress];
        rule.timeSpan = _timeSpan;
        rule.releaseRate = _releaseRate;
        rule.lockTime = _lockTime;
        rule.isWhite = true;
        if (_timeSpan == 0 || _releaseRate == 0) rule.isWhite = false;
        _result = true;
    }

    // fallback function can be used to buy tokens
    function() public payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(userInfo[_beneficiary].index == 0);
        (bool _validPurchase, uint8 _index) = validPurchase();
        require(_validPurchase);

        IndexSale storage _indexInfo = indexInfo[_index];

        uint256 _weiAmount = msg.value;

        uint256 _tokens = _weiAmount.mul(_indexInfo.rate);
        // Simple handling of tokens without 18 decimal places
        if (tokenDecimals < 18) {
            uint8 _a = 10;
            _tokens = _tokens.div(_a**(18 - tokenDecimals));
        }
        require(_indexInfo.totalSale.sub(_indexInfo.totalSold) >= _tokens);
        _indexInfo.totalSold = _indexInfo.totalSold.add(_tokens);
        _indexInfo.weiAmount = _indexInfo.weiAmount.add(_weiAmount);
        UserInfo storage _userInfo = userInfo[_beneficiary];
        _userInfo.totalLock = _tokens;
        _userInfo.remainLock = _tokens;
        _userInfo.index = _index;
        _userInfo.weiAmount = _weiAmount;
        _userInfo.buyTime = now;

        //token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokens);
    }
    
   // go back
   function goBack(address _beneficiary) public returns (bool _result) {
        require(_beneficiary != address(0));
        require(userInfo[msg.sender].index > 0);
        require(!userInfo[msg.sender].isBack);
        require(now - userInfo[msg.sender].buyTime < canBackDay);
        UserInfo storage _userInfo = userInfo[msg.sender];
        uint256 _backAmount = _userInfo
            .weiAmount
            .mul(PERCENTS_DIVIDER.sub(feeRate))
            .div(PERCENTS_DIVIDER);
        _userInfo.isBack = true;
        _userInfo.remainLock = 0;
        _userInfo.totalLock = 0;
        _beneficiary.transfer(_backAmount);
        emit ExchangeBack(_beneficiary, msg.sender, _backAmount);
        _result = true;
    }
    
    // withdraw
    function withdraw() public returns (bool _result) {
        (uint256 _available, uint256 _receiveTime) = _getAvailable(msg.sender);
        if (_available > 0) {
            UserInfo storage _userInfo = userInfo[msg.sender];
            _userInfo.remainLock = _userInfo.remainLock.sub(_available);
            _userInfo.lastReceiveTime = _receiveTime;
            token.transfer(msg.sender, _available);
        }
        _result = true;
    }

    // getAvailable
    function getAvailable(address _userAddress)
        public
        view
        returns (uint256 _result)
    {
        (_result, ) = _getAvailable(_userAddress);
    }

    // _getAvailable
    function _getAvailable(address _userAddress)
        internal
        view
        returns (uint256 _result, uint256 _receiveTime)
    {
        uint8 _userIndex = userInfo[_userAddress].index;
        uint256 _purchasedTime = now - userInfo[_userAddress].buyTime;

        (
            uint256 _timeSpan,
            uint256 _lockTime,
            uint256 _releaseRate
        ) = _getReleaseRule(_userAddress, _userIndex);
        if (
            userInfo[_userAddress].remainLock > 0 &&
            _userIndex > 0 &&
            _timeSpan > 0 &&
            _releaseRate > 0 &&
            _purchasedTime > _lockTime
        ) {
            _purchasedTime = _purchasedTime.sub(
                userInfo[_userAddress].lastReceiveTime
            );
            uint256 _canDrawNum = _purchasedTime.div(_timeSpan);
            _result = _canDrawNum.mul(
                userInfo[_userAddress]
                    .totalLock
                    .mul(indexInfo[_userIndex].releaseRate)
                    .div(PERCENTS_DIVIDER)
            );
            _result = _result.min256(userInfo[_userAddress].remainLock);
            _receiveTime = now - (_purchasedTime % _timeSpan);
        }
    }
    
    // test_getAvailable 
    function test_getAvailable(address _userAddress, uint256 _nowTime)
        public
        view
        returns (uint256 _result, uint256 _receiveTime)
    {
        require(_nowTime > now);
        uint8 _userIndex = userInfo[_userAddress].index;
        uint256 _purchasedTime = _nowTime - userInfo[_userAddress].buyTime;

        (
            uint256 _timeSpan,
            uint256 _lockTime,
            uint256 _releaseRate
        ) = _getReleaseRule(_userAddress, _userIndex);
        if (
            userInfo[_userAddress].remainLock > 0 &&
            _userIndex > 0 &&
            _timeSpan > 0 &&
            _releaseRate > 0 &&
            _purchasedTime > _lockTime
        ) {
            _purchasedTime = _purchasedTime.sub(
                userInfo[_userAddress].lastReceiveTime
            );
            _result =  _purchasedTime.div(_timeSpan).mul(
                userInfo[_userAddress]
                    .totalLock
                    .mul(indexInfo[_userIndex].releaseRate)
                    .div(PERCENTS_DIVIDER)
            );
            _result = _result.min256(userInfo[_userAddress].remainLock);
            _receiveTime = now - (_purchasedTime % _timeSpan);
        }
    }

    // _getReleaseRule
    function _getReleaseRule(address _userAddress, uint8 _index)
        internal
        view
        returns (
            uint256 _timeSpan,
            uint256 _lockTime,
            uint256 _releaseRate
        )
    {
        if (whiteList[_userAddress].isWhite) {
            _timeSpan = whiteList[_userAddress].timeSpan;
            _lockTime = whiteList[_userAddress].lockTime;
            _releaseRate = whiteList[_userAddress].releaseRate;
        } else {
            _timeSpan = indexInfo[_index].timeSpan;
            _lockTime = indexInfo[_index].lockTime;
            _releaseRate = indexInfo[_index].releaseRate;
        }
    }

    function forwardFunds() public onlyOwner returns (uint256 _result) {
        _result = address(this).balance;
        wallet.transfer(address(this).balance);
    }

    // @return true if the transaction can buy tokens
    function validPurchase()
        internal
        view
        returns (bool _validPurchase, uint8 _index)
    {
        bool withinPeriod;
        for (uint8 i = 1; i <= maxIndex; i++) {
            if (indexInfo[i].startTime > now) break;
            if (indexInfo[i].startTime < now && indexInfo[i].endTime > now) {
                _index = i;
                withinPeriod = true;
            }
        }
        bool nonZeroPurchase = msg.value != 0;
        _validPurchase = withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public pure returns (bool) {
        return false;
    }
}