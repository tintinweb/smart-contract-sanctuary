/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT

/*
________                __        _____
\______ \ _____ _______|  | __   /  _  \    ____   ____
 |    |  \\__  \\_  __ \  |/ /  /  /_\  \  / ___\_/ __ \
 |    `   \/ __ \|  | \/    <  /    |    \/ /_/  >  ___/
/_______  (____  /__|  |__|_ \ \____|__  /\___  / \___  >
        \/     \/           \/         \//_____/      \/
                    ________   _____
                    \_____  \_/ ____\
                     /   |   \   __\
                    /    |    \  |
                    \_______  /__|
                            \/
         __________                        __
         \______   \ ____ _____    _______/  |_
          |    |  _// __ \\__  \  /  ___/\   __\
          |    |   \  ___/ / __ \_\___ \  |  |
          |______  /\___  >____  /____  > |__|
                 \/     \/     \/     \/
________________________________________________________
                         INFO:                          |
________________________________________________________|
This contract is published by RISING CORPORATION for    |
the DarkAgeOfBeast network ( DAOB ) on BSC.             |
Name        : SwampWolfPresale                          |
Token link  : SWAMPWOLF                                 |
Solidity    : 0.8.6                                     |
________________________________________________________|
                  WEBSITE AND SOCIAL:                   |
________________________________________________________|
website :   https://wolfswamp.daob.finance/             |
Twitter :   https://twitter.com/DarkAgeOfBeast          |
Medium  :   https://medium.com/@daob.wolfswamp          |
Reddit  :   https://www.reddit.com/r/DarkAgeOfTheBeast/ |
TG_off  :   https://t.me/DarkAgeOfBeastOfficial         |
TG_chat :   https://t.me/Darkageofbeast                 |
________________________________________________________|
                 SECURITY AND FEATURES:                 |
________________________________________________________|
The owner can use certain functions.                    |
All sensitive functions are limited.                    |
Can not be used without the DarkAgeOfBeastReferral      |
contract.                                               |
The total amount to be sold is 100% + X% for referrers. |
            !  THERE ARE NO HIDDEN FEES  !              |
________________________________________________________|
                     ! WARNING !                        |
________________________________________________________|
Any token manually transferred to this contract will be |
considered a donation and cannot be claimed or recovered|
under any circumstances.                                |
________________________________________________________|
            Creative Commons (CC) license:              |
________________________________________________________|
You can reuse this contract by mentioning at the top :  |
    https://creativecommons.org/licenses/by-sa/4.0/     |
        CC BY MrRise from RisingCorporation.            |
________________________________________________________|

Thanks !
Best Regards !
by MrRise
2021-07-21
*/

pragma solidity >=0.6.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b);
        // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


pragma solidity 0.8.6;

abstract contract Ownable {
    address payable owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity 0.8.6;

contract Whitelisted is Ownable {
    mapping(address => uint8) public whitelist;

    // Only whitelisted
    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender), "Not whitelisted");
        _;
    }
    // Set purchaser to whitelist with zone code
    function joinWhitelist(address _purchaser, uint8 _zone) public {
        whitelist[_purchaser] = _zone;
    }
    // Delete purchaser from whitelist
    function deleteFromWhitelist(address _purchaser) public onlyOwner {
        whitelist[_purchaser] = 0;
    }
    // Check if purchaser is whitelisted : return true or false
    function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity 0.8.6;

interface ISwampWolfToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function burnUnsoldPresale(uint256 amount) external;
}

pragma solidity 0.8.6;

interface IPresaleSwampWolfToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function burnUnsoldPresale(uint256 amount) external;

    function burn(address presaleHolder, uint256 _amount) external;
}



pragma solidity 0.8.6;

interface IDarkAgeOfBeastReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

pragma solidity 0.8.6;

contract SwampWolfPresale is Ownable, Whitelisted {

    using SafeMath for uint256;
    using SafeMath for uint16;

    // The start time of presale.
    uint256 public startTime;
    // The end time of presale.
    uint256 public endTime;
    // The list of buyers.
    mapping(address => uint256) public BuyerList;
    // Buyers' array to exchange presale tokens.
    address[] public buyers;
    // Indexing the buyers.
    mapping(address => bool) public isBuyer;
    // Maximum purchase per buyer ( 10 BNB ).
    uint256 public MAX_BUY_LIMIT = 10000000000000000001;
    // The referral commission rate in basis points.
    uint16 public referralReward = 300;
    // The Rate of SWAMPWOLF token by BNB ( 2430 SWAMPWOLF / 1 BNB )
    uint256 public rate = 243e1;
    // The BNB raised in wei.
    uint256 public weiRaised;
    // The PresaleSwampWolfToken contract.
    IPresaleSwampWolfToken public presaleSwampWolfToken;
    // The SwampWolfToken contract.
    ISwampWolfToken public swampWolfToken;
    // The DarkAgeOfBeastReferral contract.
    IDarkAgeOfBeastReferral public swampWolfReferral;
    // if presale is stopped.
    bool public isPresaleStopped = false;
    // if presale is paused.
    bool public isPresalePaused = false;

    //event
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transferred(address indexed purchaser, address indexed referral, uint256 amount);
    event NewBuyer(address _address );


    constructor(
        IPresaleSwampWolfToken _presaleSwampWolf,
        IDarkAgeOfBeastReferral _referral,
        uint256 _startTime,
        uint256 _endTime
    ) {
        presaleSwampWolfToken = _presaleSwampWolf;
        swampWolfReferral = _referral;
        startTime = _startTime;
        endTime = _endTime;
        require(endTime >= startTime);
    }

    /**
     * @dev fallback function to prevent mistake.
     *
     */
    fallback() external payable {
        buy(msg.sender, owner);
    }

    /**
     * @dev To receive the pre-sales BNB
     *
     */
    receive() external payable {}


    /**
     * @dev The Buy tokens function.
     *
     * Requirements
     *
     * Buyer must be whitelisted.
     */
    function buy(address _beneficiary, address _referrer) public onlyWhitelisted payable {
        require(isPresaleStopped != true, 'Presale is stopped');
        require(isPresalePaused != true, 'Presale is paused');
        require(_beneficiary != address(0), 'User asking for tokens sent to be on 0 address');
        require(validPurchase(), 'Its not a valid purchase');
        require(BuyerList[msg.sender] < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT Achieved already for this wallet');
        // The BNB amount sent by the buyer
        uint256 weiAmount = msg.value;
        require(weiAmount < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT is 10 BNB');
        // Calc how many SWAMPWOLF this makes
        uint256 tokens = weiAmount.mul(rate);
        // Calc the referrer reward
        uint256 refReward = tokens.mul(referralReward).div(10000);
        weiRaised = weiRaised.add(weiAmount);
        uint256 remainingTokens = tokensRemainingForSale();
        uint256 tokensNeeded = tokens.add(refReward);
        require(tokensNeeded <= remainingTokens, 'Not enough tokens');
        require(address(swampWolfReferral) != address(0), 'Need referral contract' );
        require(_referrer != address(0), 'Referrer can not be zero address');
        require(_referrer != _beneficiary, 'Referrer can not be beneficiary');
        swampWolfReferral.recordReferral(_beneficiary, _referrer);
        address referrer = swampWolfReferral.getReferrer(_beneficiary);
        createBuyer(_beneficiary);
        payReferral(referrer, refReward);
        presaleSwampWolfToken.transfer(_beneficiary, tokens);
        BuyerList[msg.sender] = BuyerList[msg.sender].add(msg.value);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

    /**
     * @dev Pay the referral commission to the referrer
     *
     */
    function payReferral(address _referrer, uint256 _amount) internal {
        presaleSwampWolfToken.transfer(_referrer, _amount);
        swampWolfReferral.recordReferralCommission(_referrer,_amount);
        createBuyer(_referrer);
    }

    /**
     * @dev Indexing the buyers
     *
     */
    function createBuyer(address _address) internal {
        if(!isBuyer[_address]){
            buyers.push(_address);
            emit NewBuyer(_address);
            isBuyer[_address] = true;
        }
    }

    /**
     * @dev Swap the presale token for the real token and burn unsold tokens.
     *
     * Requirements
     *
     * This can only be called by the owner.
     * Presale must be ended.
     */
    function swapPresaleAndBurnUnsoldTokens() public onlyOwner {
        require(hasEnded(), 'Presale not ended');
        uint256 arrayLength = buyers.length;
        for (uint256 bid = 0; bid < arrayLength.sub(1); ++bid) {
            address buyer = buyers[bid];
            uint256 presaleAmount = presaleSwampWolfToken.balanceOf(buyer);
            safeSwampWolfTransfer(buyer, presaleAmount);
            presaleSwampWolfToken.burn(buyer, presaleAmount);
        }

        uint256 unsold = swampWolfToken.balanceOf(address(this));
        uint256 unsoldPresale = presaleSwampWolfToken.balanceOf(address(this));
        presaleSwampWolfToken.burnUnsoldPresale(unsoldPresale);
        swampWolfToken.burnUnsoldPresale(unsold);
    }

    /**
     * @dev Safe swampWolf transfer function, just in case if rounding error.
     *
     */
    function safeSwampWolfTransfer(address _to, uint256 _amount) internal {
        uint256 swampWolfBal = swampWolfToken.balanceOf(address(this));
        if (_amount > swampWolfBal) {
            swampWolfToken.transfer(_to, swampWolfBal);
        } else {
            swampWolfToken.transfer(_to, _amount);
        }
    }

    /**
     * @dev Update the swampWolf token contract address
     *
     * Requirements
     *
     * This can only be called by the Owner.
     */
    function setSwampWolfToken(address _swampWolfToken) public onlyOwner {
        require(_swampWolfToken != address(0), "Can not be zero address");
        swampWolfToken = ISwampWolfToken(_swampWolfToken);
    }

    /**
    * @dev Check is the purchase is valid
    *
    * Internal purpose
    */
    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    /**
    * @dev Check is the presale has ended
    *
    */
    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

    /**
    * @dev Display the current balance of `msg.sender`
    *
    */
    function showMyTokenBalance() public view returns (uint256 tokenBalance) {
        tokenBalance = presaleSwampWolfToken.balanceOf(msg.sender);
    }

    /**
    * @dev Set the end date of presale
    *
    */
    function setEndDate(uint256 daysToEndFromToday) public onlyOwner returns (bool) {
        daysToEndFromToday = daysToEndFromToday * 1 days;
        endTime = block.timestamp + daysToEndFromToday;
        return true;
    }

    /**
    * @dev Set the SWAMPWOLF/BNB price rate
    *
    * Requirement
    *
    * This can only be called by the owner
    */
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
        return true;
    }

    /**
    * @dev Set the referral reward rate in basis points
    *
    * Requirements
    *
    * This can only be called by the owner.
    */
    function setReferralReward(uint16 newReward) public onlyOwner returns (bool) {
        referralReward = newReward;
        return true;
    }

    /**
    * @dev Pause the presale
    *
    * Requirements
    *
    * This can only be called by the owner.
    */
    function pausePresale() public onlyOwner returns (bool) {
        isPresalePaused = true;
        return isPresalePaused;
    }

    /**
    * @dev Resume the presale
    *
    * Requirements
    *
    * This can only be called by the owner.
    */
    function resumePresale() public onlyOwner returns (bool) {
        isPresalePaused = false;
        return !isPresalePaused;
    }

    /**
    * @dev Stop the presale
    *
    * Requirements
    *
    * This can only be called by the owner.
    */
    function stopPresale() public onlyOwner returns (bool) {
        isPresaleStopped = true;
        return true;
    }

    /**
    * @dev Start the presale
    *
    * Requirements
    *
    * This can only be called by the owner.
    */
    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        startTime = block.timestamp;
        return true;
    }

    /**
     * @dev Transfers BNB from the presale to `msg.sender` to put them in liquidity.
     *
     * Requirements
     *
     * This can only be called by the owner.
     */
    function transferPresaleBNB() public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    /**
     * @dev Drain tokens that are sent here for donation
     *
     * Requirements
     *
     * This can only be called by the owner.
     * Ensure requested tokens aren't SWAMPWOLF tokens.
     */
    function drainTokensExceptOurTokens(address _token) public onlyOwner {
        require(_token != address(presaleSwampWolfToken) && _token != address(swampWolfToken), "Cannot recover SWAMPWOLF tokens");
        uint256 amount = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(msg.sender, amount);
    }

    /**
     * @dev Check how many SWAMPWOLF tokens remaining for sale.
     *
     */
    function tokensRemainingForSale() public view returns (uint256 balance) {
        uint256 tokenBalance = presaleSwampWolfToken.balanceOf(address(this));
        // The total current balance is 100% + 3% for referral
        uint256 totalBP = referralReward.add(10000);
        uint256 rewardBalance = tokenBalance.div(totalBP).mul(referralReward);
        balance = tokenBalance.sub(rewardBalance);
    }
}