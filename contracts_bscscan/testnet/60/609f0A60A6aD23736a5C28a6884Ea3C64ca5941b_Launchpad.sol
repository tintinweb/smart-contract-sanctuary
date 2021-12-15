// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./IBEP20.sol";
import "./Ownable.sol";

contract Launchpad is Ownable, DataStorage, Access, Events {
    using SafeMath for uint256;

    constructor(
        address payable wallet,
        IBEP20 _saleToken,
        IBEP20 _buyToken, 
        uint256 startTime,
        uint256 endTime
    ) public {
        saleWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        saleToken = _saleToken;
        buyToken = _buyToken;
        _startTime = startTime;
        _endTime = endTime;
    }

    function registerBuy(uint256 amount) public payable blockReEntry()
    {
       _registerBuy(msg.sender, amount);
    }

    function _registerBuy(address _beneficiary, uint256 amount) internal {
        User storage user = users[_beneficiary];
        require(user.tokenBuy == 0, "Required: Only one time register");
        require(msg.value == PROJECT_FEE, "Required: Must be paid fee to register");
        require(
            buyToken.allowance(_beneficiary, address(this)) >= amount,
            "Token allowance too low"
        );
        uint256 weiAmount = amount;
        require(
            weiAmount >= minInvest,
            "Requried: Amount to buy token not enough"
        );   
        require(
            weiAmount <= maxInvest,
            "Requried: Amount to buy token too much"
        );      
        require(
            wasSale <= totalSupply,
            "Requried: Token was sold all"
        );
        
        _preValidatePurchase(_beneficiary, weiAmount);
        totalRegister += 1;
        require(totalRegister <= TOTAL_SLOT, "Required: Not engough slot to register");
        tokenHolders[_beneficiary] = quantityToken;
        // update state
        wasSale = wasSale.add(quantityToken);
        user.owner = _beneficiary;
        user.amountInvest = user.amountInvest.add(amount);
        user.tokenBuy = user.tokenBuy.add(quantityToken);
        _forwardFunds(amount, _beneficiary);
        emit TokenPurchase(_beneficiary, weiAmount, quantityToken);
        emit FeePayed(_beneficiary, PROJECT_FEE);
    }

    function claimToken() public payable alreadyClosed hasTokens blockReEntry {
        User storage user = users[msg.sender];
        require(user.countClaimed <= LIMIT_CLAIMED, "Required: claimed almost done");
        require(block.timestamp >= user.lastClaimed.add(TIME_STEP),"Required: waiting enough time to claim");
        require(user.tokenBuy > 0,"Required: Must be register to claim token");
        require(msg.value == CLAIM_FEE, "Required: Must be paid fee to claim token");
        user.lastClaimed = block.timestamp;
        user.countClaimed = user.countClaimed.add(1);
        totalClaim = totalClaim.add(user.tokenBuy);
        _deliverTokens(msg.sender, user.tokenBuy);
        emit FeePayed(msg.sender, CLAIM_FEE);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
        hasStarted
        hasClosed
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
        saleWallet.transfer(msg.value);
        saleToken.transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Determines how BNB is stored/forwarded on purchases.
     */
    function _forwardFunds(uint256 amount, address userAddress) internal {
        saleWallet.transfer(msg.value);
        buyToken.transferFrom(userAddress, saleWallet, amount);
    }

    function setMinInvestBNB(uint256 _amount) external onlyOwner {
        minInvest = _amount;
    }  

    function setMaxInvestBNB(uint256 _amount) external onlyOwner {
        maxInvest = _amount;
    } 

     function setBuyToken(address _token) external onlyOwner {
        buyToken = IBEP20(_token);
    }   

    function setProjectFee(uint256 _fee) external onlyOwner {
        PROJECT_FEE = _fee;
    }
    
    function setClaimFee(uint256 _fee) external onlyOwner {
        CLAIM_FEE = _fee;
    }

    function setSlotRegister(uint256 _slot) external onlyOwner {
        TOTAL_SLOT = _slot;
    }

    function setTimeStep(uint256 _time) external onlyOwner {
        TIME_STEP = _time;
    }

    function setLimitClaimed(uint256 _count) external onlyOwner {
        LIMIT_CLAIMED = _count;
    }

    function setPriceToken(uint256 _totalSuply, uint256 _quantity)
        external
        onlyOwner
    {
        quantityToken = _quantity;
        totalSupply = _totalSuply;
    }

    function setStartTime(uint256 time) external onlyOwner {
        _startTime = time;
    }
 
    function setEndTime(uint256 time) external onlyOwner {
        _endTime = time;
    }

    function setSaleWallet(address payable _saleAddress) external onlyOwner {
        saleWallet = _saleAddress;
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) public onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IBEP20(coinAddress).transfer(to, value);
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