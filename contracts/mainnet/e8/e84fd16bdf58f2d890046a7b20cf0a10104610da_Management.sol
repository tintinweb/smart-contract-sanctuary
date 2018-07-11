pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract TokenInterface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function getMaxTotalSupply() public view returns (uint256);
    function mint(address _to, uint256 _amount) public returns (bool);
    function transfer(address _to, uint256 _amount) public returns (bool);

    function allowance(
        address _who,
        address _spender
    )
        public
        view
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool);
}


contract MiningTokenInterface {
    function multiMint(address _to, uint256 _amount) external;
    function getTokenTime(uint256 _tokenId) external returns(uint256);
    function mint(address _to, uint256 _id) external;
    function ownerOf(uint256 _tokenId) public view returns (address);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function tokenByIndex(uint256 _index) public view returns (uint256);

    function arrayOfTokensByAddress(address _holder)
        public
        view
        returns(uint256[]);

    function getTokensCount(address _owner) public returns(uint256);

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId);
}


contract Management {
    using SafeMath for uint256;

    uint256 public startPriceForHLPMT = 10000;
    uint256 public maxHLPMTMarkup = 40000;
    uint256 public stepForPrice = 1000;

    uint256 public startTime;
    uint256 public lastMiningTime;

    // default value
    uint256 public decimals = 18;

    TokenInterface public token;
    MiningTokenInterface public miningToken;

    address public dao;
    address public fund;
    address public owner;

    // num of mining times
    uint256 public numOfMiningTimes;

    mapping(address => uint256) public payments;
    mapping(address => uint256) public paymentsTimestamps;

    // mining time => mining reward
    mapping(uint256 => uint256) internal miningReward;

    // id mining token => getting reward last mining
    mapping(uint256 => uint256) internal lastGettingReward;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyDao() {
        require(msg.sender == dao);
        _;
    }

    constructor(
        address _token,
        address _miningToken,
        address _dao,
        address _fund
    )
        public
    {
        require(_token != address(0));
        require(_miningToken != address(0));
        require(_dao != address(0));
        require(_fund != address(0));

        startTime = now;
        lastMiningTime = startTime - (startTime % (1 days)) - 1 days;
        owner = msg.sender;

        token = TokenInterface(_token);
        miningToken = MiningTokenInterface(_miningToken);
        dao = _dao;
        fund = _fund;
    }

    /**
     * @dev Exchanges the HLT tokens to HLPMT tokens. Works up to 48 HLPMT
     * tokens at one-time buying. Should call after approving HLT tokens to
     * manager address.
     */
    function buyHLPMT() external {

        uint256 _currentTime = now;
        uint256 _allowed = token.allowance(msg.sender, address(this));
        uint256 _currentPrice = getPrice(_currentTime);
        require(_allowed >= _currentPrice);

        //remove the remainder
        uint256 _hlpmtAmount = _allowed.div(_currentPrice);
        _allowed = _hlpmtAmount.mul(_currentPrice);

        require(token.transferFrom(msg.sender, fund, _allowed));

        for (uint256 i = 0; i < _hlpmtAmount; i++) {
            uint256 _id = miningToken.totalSupply();
            miningToken.mint(msg.sender, _id);
            lastGettingReward[_id] = numOfMiningTimes;
        }
    }

    /**
     * @dev Produces the mining process and sends reward to dao and fund.
     */
    function mining() external {

        uint256 _currentTime = now;
        require(_currentTime > _getEndOfLastMiningDay());


        uint256 _missedDays = (_currentTime - lastMiningTime) / (1 days);

        updateLastMiningTime(_currentTime);

        for (uint256 i = 0; i < _missedDays; i++) {
            // 0.1% daily from remaining unmined tokens.
            uint256 _dailyTokens = token.getMaxTotalSupply().sub(token.totalSupply()).div(1000);

            uint256 _tokensToDao = _dailyTokens.mul(3).div(10); // 30 percent
            token.mint(dao, _tokensToDao);

            uint256 _tokensToFund = _dailyTokens.mul(3).div(10); // 30 percent
            token.mint(fund, _tokensToFund);

            uint256 _miningTokenSupply = miningToken.totalSupply();
            uint256 _tokensToMiners = _dailyTokens.mul(4).div(10); // 40 percent
            uint256 _tokensPerMiningToken = _tokensToMiners.div(_miningTokenSupply);

            miningReward[++numOfMiningTimes] = _tokensPerMiningToken;

            token.mint(address(this), _tokensToMiners);
        }
    }

    /**
     * @dev Sends the daily mining reward to HLPMT holder.
     */
    function getReward(uint256[] tokensForReward) external {
        uint256 _rewardAmount = 0;
        for (uint256 i = 0; i < tokensForReward.length; i++) {
            if (
                msg.sender == miningToken.ownerOf(tokensForReward[i]) &&
                numOfMiningTimes > getLastRewardTime(tokensForReward[i])
            ) {
                _rewardAmount += _calculateReward(tokensForReward[i]);
                setLastRewardTime(tokensForReward[i], numOfMiningTimes);
            }
        }

        require(_rewardAmount > 0);
        token.transfer(msg.sender, _rewardAmount);
    }

    function checkReward(uint256[] tokensForReward) external view returns (uint256) {
        uint256 reward = 0;

        for (uint256 i = 0; i < tokensForReward.length; i++) {
            if (numOfMiningTimes > getLastRewardTime(tokensForReward[i])) {
                reward += _calculateReward(tokensForReward[i]);
            }
        }

        return reward;
    }

    /**
     * @param _tokenId token id
     * @return timestamp of token creation
     */
    function getLastRewardTime(uint256 _tokenId) public view returns(uint256) {
        return lastGettingReward[_tokenId];
    }

    /**
    * @dev Sends the daily mining reward to HLPMT holder.
    */
    function sendReward(uint256[] tokensForReward) public onlyOwner {
        for (uint256 i = 0; i < tokensForReward.length; i++) {
            if (numOfMiningTimes > getLastRewardTime(tokensForReward[i])) {
                uint256 reward = _calculateReward(tokensForReward[i]);
                setLastRewardTime(tokensForReward[i], numOfMiningTimes);
                token.transfer(miningToken.ownerOf(tokensForReward[i]), reward);
            }
        }
    }

    /**
     * @dev Returns the HLPMT token amount of holder.
     */
    function miningTokensOf(address holder) public view returns (uint256[]) {
        return miningToken.arrayOfTokensByAddress(holder);
    }

    /**
     * @dev Sets the DAO address
     * @param _dao DAO address.
     */
    function setDao(address _dao) public onlyOwner {
        require(_dao != address(0));
        dao = _dao;
    }

    /**
     * @dev Sets the fund address
     * @param _fund Fund address.
     */
    function setFund(address _fund) public onlyOwner {
        require(_fund != address(0));
        fund = _fund;
    }

    /**
     * @dev Sets the token address
     * @param _token Token address.
     */
    function setToken(address _token) public onlyOwner {
        require(_token != address(0));
        token = TokenInterface(_token);
    }

    /**
     * @dev Sets the mining token address
     * @param _miningToken Mining token address.
     */
    function setMiningToken(address _miningToken) public onlyOwner {
        require(_miningToken != address(0));
        miningToken = MiningTokenInterface(_miningToken);
    }

    /**
     * @return uint256 the current HLPMT token price in HLT (without decimals).
     */
    function getPrice(uint256 _timestamp) public view returns(uint256) {
        uint256 _raising = _timestamp.sub(startTime).div(30 days);
        _raising = _raising.mul(stepForPrice);
        if (_raising > maxHLPMTMarkup) _raising = maxHLPMTMarkup;
        return (startPriceForHLPMT + _raising) * 10 ** 18;
    }

    /**
     * @param _numOfMiningTime is time
     * @return getting token reward
     */
    function getMiningReward(uint256 _numOfMiningTime) public view returns (uint256) {
        return miningReward[_numOfMiningTime];
    }

    /**
     * @dev Returns the calculated reward amount.
     */
    function _calculateReward(uint256 tokenID)
        internal
        view
        returns (uint256 reward)
    {
        for (uint256 i = getLastRewardTime(tokenID) + 1; i <= numOfMiningTimes; i++) {
            reward += miningReward[i];
        }
        return reward;
    }

    /**
     * @dev set last getting token reward time
     */
    function setLastRewardTime(uint256 _tokenId, uint256 _num) internal {
        lastGettingReward[_tokenId] = _num;
    }

    /**
     * @dev set last getting token reward time
     */
    function updateLastMiningTime(uint256 _currentTime) internal {
        lastMiningTime = _currentTime - _currentTime % (1 days);
    }

    /**
     * @return uint256 the unix timestamp of the end of the last mining day.
     */
    function _getEndOfLastMiningDay() internal view returns(uint256) {
        return lastMiningTime + 1 days;
    }

    /**
     * @dev Withdraw accumulated balance, called by payee.
     */
    function withdrawPayments() public {
        address payee = msg.sender;
        uint256 payment = payments[payee];
        uint256 timestamp = paymentsTimestamps[payee];

        require(payment != 0);
        require(now >= timestamp);

        payments[payee] = 0;

        require(token.transfer(msg.sender, payment));
    }

    /**
     * @dev Called by the payer to store the sent _amount as credit to be pulled.
     * @param _dest The destination address of the funds.
     * @param _amount The amount to transfer.
     */
    function asyncSend(address _dest, uint256 _amount, uint256 _timestamp) external onlyDao {
        payments[_dest] = payments[_dest].add(_amount);
        paymentsTimestamps[_dest] = _timestamp;
        require(token.transferFrom(dao, address(this), _amount));
    }
}