// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./Include.sol";

contract Starter is Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    
    address public currency;
    address public underlying;
    uint public price;
    uint public time;
    uint public totalPurchasedCurrency;
    mapping (address => uint) public purchasedCurrencyOf;
    bool public completed;
    uint public totalSettledUnderlying;
    mapping (address => uint) public settledUnderlyingOf;
    uint public settleRate;
    uint public timeSettle;
    uint public totalSettledCurrency;
    mapping (address => uint) public settledCurrencyOf;
    
    function __Starter_init(address governor_, address currency_, address underlying_, uint price_, uint time_, uint timeSettle_) external initializer {
		__Governable_init_unchained(governor_);
		__Starter_init_unchained(currency_, underlying_, price_, time_, timeSettle_);
	}
	
    function __Starter_init_unchained(address currency_, address underlying_, uint price_, uint time_, uint timeSettle_) public governance {
        currency    = currency_;
        underlying  = underlying_;
        price       = price_;
        time        = time_;
        timeSettle  = timeSettle_;
        require(timeSettle_ >= time_, 'timeSettle_ should >= time_');
    }
    
    function purchase(uint amount) external {
        require(now < time, 'expired');
        IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);
        purchasedCurrencyOf[msg.sender] = purchasedCurrencyOf[msg.sender].add(amount);
        totalPurchasedCurrency = totalPurchasedCurrency.add(amount);
        emit Purchase(msg.sender, amount, totalPurchasedCurrency);
    }
    event Purchase(address indexed acct, uint amount, uint totalCurrency);
    
    function purchaseHT() public payable {
		require(address(currency) == address(0), 'should call purchase(uint amount) instead');
        require(now < time, 'expired');
        uint amount = msg.value;
        purchasedCurrencyOf[msg.sender] = purchasedCurrencyOf[msg.sender].add(amount);
        totalPurchasedCurrency = totalPurchasedCurrency.add(amount);
        emit Purchase(msg.sender, amount, totalPurchasedCurrency);
    }

    function totalSettleable() public view  returns (bool completed_, uint amount, uint volume, uint rate) {
        return settleable(address(0));
    }
    
    function settleable(address acct) public view returns (bool completed_, uint amount, uint volume, uint rate) {
        completed_ = completed;
        if(completed_) {
            rate = settleRate;
        } else {
            uint totalCurrency = currency == address(0) ? address(this).balance : IERC20(currency).balanceOf(address(this));
            uint totalUnderlying = IERC20(underlying).balanceOf(address(this));
            if(totalUnderlying.mul(price) < totalCurrency.mul(1e18))
                rate = totalUnderlying.mul(price).div(totalCurrency);
            else
                rate = 1 ether;
        }
        uint purchasedCurrency = acct == address(0) ? totalPurchasedCurrency : purchasedCurrencyOf[acct];
        uint settleAmount = purchasedCurrency.mul(rate).div(1e18);
        amount = purchasedCurrency.sub(settleAmount).sub(acct == address(0) ? totalSettledCurrency : settledCurrencyOf[acct]);
        volume = settleAmount.mul(1e18).div(price).sub(acct == address(0) ? totalSettledUnderlying : settledUnderlyingOf[acct]);
    }
    
    function settle() public {
        require(now >= time, "It is not time yet");
        require(settledUnderlyingOf[msg.sender] == 0 || settledCurrencyOf[msg.sender] == 0 , 'settled already');
        (bool completed_, uint amount, uint volume, uint rate) = settleable(msg.sender);
        if(!completed_) {
            completed = true;
            settleRate = rate;
        }
        
        settledCurrencyOf[msg.sender] = settledCurrencyOf[msg.sender].add(amount);
        totalSettledCurrency = totalSettledCurrency.add(amount);
        if(currency == address(0))
            msg.sender.transfer(amount);
        else
            IERC20(currency).safeTransfer(msg.sender, amount);
            
        require(amount > 0 || now >= timeSettle, 'It is not time to settle underlying');
        if(now >= timeSettle) {
            settledUnderlyingOf[msg.sender] = settledUnderlyingOf[msg.sender].add(volume);
            totalSettledUnderlying = totalSettledUnderlying.add(volume);
            IERC20(underlying).safeTransfer(msg.sender, volume);
        }
        emit Settle(msg.sender, amount, volume, rate);
    }
    event Settle(address indexed acct, uint amount, uint volume, uint rate);
    
    function withdrawable() public view returns (uint amt, uint vol) {
        if(!completed)
            return (0, 0);
        //amt = currency == address(0) ? address(this).balance : IERC20(currency).balanceOf(address(this));
        //amt = amt.add(totalSettledUnderlying.mul(price).div(settleRate).mul(uint(1e18).sub(settleRate)).div(1e18)).sub(totalPurchasedCurrency.mul(uint(1e18).sub(settleRate)).div(1e18));
        amt = totalPurchasedCurrency.mul(settleRate).div(1e18);
        vol = IERC20(underlying).balanceOf(address(this)).add(totalSettledUnderlying).sub(totalPurchasedCurrency.mul(settleRate).div(price));
    }
    
    function withdraw(address payable to, uint amount, uint volume) external governance {
        require(completed, "uncompleted");
        (uint amt, uint vol) = withdrawable();
        amount = Math.min(amount, amt);
        volume = Math.min(volume, vol);
        if(currency == address(0))
            to.transfer(amount);
        else
            IERC20(currency).safeTransfer(to, amount);
        IERC20(underlying).safeTransfer(to, volume);
        emit Withdrawn(to, amount, volume);
    }
    event Withdrawn(address to, uint amount, uint volume);
    
    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    function rescueTokens(address _token, address _dst) public governance {
        require(_token != currency && _token != underlying);
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_dst, balance);
    }
    
    //function withdrawToken(address _dst) external governance {
    //    rescueTokens(address(underlying), _dst);
    //}
    //
    //function withdrawToken() external governance {
    //    rescueTokens(address(underlying), msg.sender);
    //}
    
    function withdrawHT(address payable _dst) external governance {
        require(currency != address(0));
        _dst.transfer(address(this).balance);
    }
    
    function withdrawHT() external governance {
        require(currency != address(0));
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable{
        if(msg.value > 0)
            purchaseHT();
        else
            settle();
    }
    
    fallback() external {
        settle();
    }
}

contract Offering is Configurable {
	using SafeMath for uint;
	using SafeERC20 for IERC20;
	
	IERC20 public currency;
	IERC20 public token;
	uint public ratio;
	address payable public recipient;
	uint public timeOffer;
	uint public timeClaim;
	
	uint public totalQuota;
	uint public totalOffered;
	uint public totalClaimed;
	mapping (address => uint) public quotaOf;
	mapping (address => uint) public offeredOf;
	mapping (address => uint) public claimedOf;

	function __Offering_init(address governor_, address currency_, address token_, uint ratio_, address payable recipient_, uint timeOffer_, uint timeClaim_) external initializer {
		__Governable_init_unchained(governor_);
		__Offering_init_unchained(currency_, token_, ratio_, recipient_, timeOffer_, timeClaim_);
	}
	
	function __Offering_init_unchained(address currency_, address token_, uint ratio_, address payable recipient_, uint timeOffer_, uint timeClaim_) public governance {
		currency = IERC20(currency_);
		token = IERC20(token_);
		ratio = ratio_;
		recipient = recipient_;
	    timeOffer = timeOffer_;
	    timeClaim = timeClaim_;
	}
	
    function setQuota(address addr, uint amount) public governance {
        totalQuota = totalQuota.add(amount).sub(quotaOf[addr]);
        quotaOf[addr] = amount;
        emit Quota(addr, amount, totalQuota);
    }
    event Quota(address indexed addr, uint amount, uint total);
    
    function setQuotas(address[] memory addrs, uint amount) external {
        for(uint i=0; i<addrs.length; i++)
            setQuota(addrs[i], amount);
    }
    
    function setQuotas(address[] memory addrs, uint[] memory amounts) external {
        for(uint i=0; i<addrs.length; i++)
            setQuota(addrs[i], amounts[i]);
    }
    
	function offer(uint amount) external {
		require(address(currency) != address(0), 'should call offerHT() instead');
		require(now >= timeOffer, "it's not time yet");
		require(now < timeClaim, "expired");
		amount = Math.min(amount, quotaOf[msg.sender]);
		require(amount > 0, 'no quota');
		require(currency.allowance(msg.sender, address(this)) >= amount, 'allowance not enough');
		require(currency.balanceOf(msg.sender) >= amount, 'balance not enough');
		require(offeredOf[msg.sender] == 0, 'offered already');
		
		currency.safeTransferFrom(msg.sender, recipient, amount);
		uint volume = amount.mul(ratio).div(1e18);
		offeredOf[msg.sender] = volume;
		totalOffered = totalOffered.add(volume);
		require(totalOffered <= token.balanceOf(address(this)), 'Quota is full');
		emit Offer(msg.sender, amount, volume, totalOffered);
	}
	event Offer(address indexed addr, uint amount, uint volume, uint total);
	
	function offerHT() public payable {
		require(address(currency) == address(0), 'should call offer(uint amount) instead');
		require(now >= timeOffer, "it's not time yet");
		require(now < timeClaim, "expired");
		uint amount = Math.min(msg.value, quotaOf[msg.sender]);
		require(amount > 0, 'no quota');
		require(offeredOf[msg.sender] == 0, 'offered already');
		
		recipient.transfer(amount);
		uint volume = amount.mul(ratio).div(1e18);
		offeredOf[msg.sender] = volume;
		totalOffered = totalOffered.add(volume);
		require(totalOffered <= token.balanceOf(address(this)), 'Quota is full');
		if(msg.value > amount)
		    msg.sender.transfer(msg.value.sub(amount));
		emit Offer(msg.sender, amount, volume, totalOffered);
	}

    function claim() public {
        require(now >= timeClaim, "it's not time yet");
        require(claimedOf[msg.sender] == 0, 'claimed already'); 
		if(token.balanceOf(address(this)).add(totalClaimed) > totalOffered)
			token.safeTransfer(recipient, token.balanceOf(address(this)).add(totalClaimed).sub(totalOffered));
        uint volume = offeredOf[msg.sender];
        claimedOf[msg.sender] = volume;
        totalClaimed = totalClaimed.add(volume);
        token.safeTransfer(msg.sender, volume);
        emit Claim(msg.sender, volume, totalClaimed);
    }
    event Claim(address indexed addr, uint volume, uint total);
    
    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    function rescueTokens(address _token, address _dst) public governance {
        require(now > timeClaim);
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_dst, balance);
    }
    
    function withdrawToken(address _dst) external governance {
        rescueTokens(address(token), _dst);
    }

    function withdrawToken() external governance {
        rescueTokens(address(token), msg.sender);
    }
    
    function withdrawHT(address payable _dst) external governance {
        require(address(currency) != address(0));
        _dst.transfer(address(this).balance);
    }
    
    function withdrawHT() external governance {
        require(address(currency) != address(0));
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable{
        if(msg.value > 0)
            offerHT();
        else
            claim();
    }
    
    fallback() external {
        claim();
    }
}