pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./IBEP20.sol";

contract VeroLaunchpad is DataStorage, Access, Events, Manageable {
    using SafeMath for uint256;

    constructor(
        address payable wallet,
        IBEP20 _saleToken,
        uint256 startTime,
        uint256 endTime
    ) public {
        saleWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        saleToken = _saleToken;
        _startTime = startTime;
        _endTime = endTime;
    }

    fallback() external payable {
        _registerBuy(msg.sender);
    }

    receive() external payable {
        _registerBuy(msg.sender);
    }

    function registerBuy() public payable blockReEntry()
    {
       _registerBuy(msg.sender);
    }

    function _registerBuy(address _beneficiary) internal {
        User storage user = users[_beneficiary];
        require(user.tokenBuy == 0, "Required: Only one time register");
        uint256 weiAmount = msg.value.sub(PROJECT_FEE);
        require(
            weiAmount >= minInvest,
            "Requried: Amount to buy token not enough"
        );        
        require(
            wasSale <= totalSupply,
            "Requried: Token was sold all"
        );
        
        _preValidatePurchase(_beneficiary, weiAmount);
        totalRegister += 1;
        require(totalRegister <= TOTAL_SLOT, "Required: Not engough slot to register");
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        tokenHolders[_beneficiary] = tokens;
        // update state
        wasSale = wasSale.add(tokens);
        user.owner = _beneficiary;
        user.amountInvest = user.amountInvest.add(msg.value.sub(PROJECT_FEE));
        user.tokenBuy = user.tokenBuy.add(tokens);
        user.wasClaimed = false;

        emit TokenPurchase(_beneficiary, weiAmount, tokens);
        emit FeePayed(_beneficiary, PROJECT_FEE);
    }

    function claimToken() public alreadyClosed blockReEntry {
        User storage user = users[msg.sender];
        require(user.wasClaimed == false,"Required: Only one time claim token");
        user.wasClaimed = true;
        _deliverTokens(msg.sender, user.tokenBuy);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
        hasStarted
        hasClosed
        hasTokens
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        saleToken.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        return _weiAmount.div(priceToken).mul(1e18);
    }

    /**
     * @dev Determines how BNB is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        saleWallet.transfer(msg.value.sub(PROJECT_FEE));
    }

    function setMinInvestBNB(uint256 _amount) external onlyAdmins {
        minInvest = _amount;
    }    

    function setProjectFee(uint256 _fee) external onlyAdmins {
        PROJECT_FEE = _fee;
    }

     function setSlotRegister(uint256 _slot) external onlyAdmins {
        TOTAL_SLOT = _slot;
    }

    function setPriceToken(uint256 _totalSuply, uint256 _price)
        external
        onlyAdmins
    {
        priceToken = _price;
        totalSupply = _totalSuply;
    }

    function setStartTime(uint256 time) external onlyAdmins {
        _startTime = time;
    }

    function setEndTime(uint256 time) external onlyAdmins {
        _endTime = time;
    }

    function setSaleWallet(address payable _saleAddress) external onlyAdmins {
        saleWallet = _saleAddress;
    }

    function handleForfeitedBalanceToken(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == saleWallet), "Restricted Access!");

        saleToken.transfer(_addr, _amount);
    }

    function handleForfeitedBalance(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == saleWallet), "Restricted Access!");

        (bool success, ) = _addr.call{value: _amount}("");

        require(success, "Failed");
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (User memory)
    {
        User storage user = users[userAddress];        
        return user;
    }
}