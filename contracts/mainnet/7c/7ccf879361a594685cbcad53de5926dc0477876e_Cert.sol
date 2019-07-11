/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

// File: ../3rdparty/openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: ../3rdparty/openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: ../3rdparty/openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/Whitelist.sol

pragma solidity >=0.4.25 <0.6.0;


contract Whitelist is Ownable{
    mapping (uint256 => uint8) private _partners;
    mapping (address => uint256) private _partner_ids;
    mapping (uint256 => address) private _partner_address;
    uint256 public partners_counter=1;
    mapping (address => uint8) private _whitelist;
    mapping (address => uint256) private _referrals;
    mapping (uint256 => mapping(uint256=>address)) private _partners_referrals;
    mapping (uint256 => uint256) _partners_referrals_counter;

    uint8 public constant STATE_NEW = 0;
    uint8 public constant STATE_WHITELISTED = 1;
    uint8 public constant STATE_BLACKLISTED = 2;
    uint8 public constant STATE_ONHOLD = 3;

    event Whitelisted(address indexed partner, address indexed subscriber);
    event AddPartner(address indexed partner, uint256 partner_id);

    function _add_partner(address partner) private returns (bool){
        _partner_ids[partner] = partners_counter;
        _partner_address[partners_counter] = partner;
        _partners[partners_counter] = STATE_WHITELISTED;
        _whitelist[partner] = STATE_WHITELISTED;
        emit AddPartner(partner, partners_counter);
        partners_counter++;
    }
    
    constructor () public {
        _add_partner(msg.sender);
    }

    function getPartnerId(address partner) public view returns (uint256){
        return _partner_ids[partner];
    }

    modifier onlyWhiteisted(){
        require(_whitelist[msg.sender] == STATE_WHITELISTED, "Ownable: caller is not whitelisted");
        _;
    }

    function isPartner() public view returns (bool){
        return _partners[_partner_ids[msg.sender]] == STATE_WHITELISTED;
    }

    function partnerStatus(address partner) public view returns (uint8){
        return _partners[_partner_ids[partner]];
    }


    modifier onlyPartnerOrOwner(){
        require(isOwner() || isPartner(), "Ownable: caller is not the owner or partner");
        _;
    }

    function setPartnerState(address partner, uint8 state) public onlyOwner returns(bool){
        uint256 partner_id = getPartnerId(partner);
        if( partner_id == 0 && state == STATE_WHITELISTED){
            _add_partner(partner);
        }else{
            _partners[partner_id] = state;
        }
        return true;
    }


    function addPartner(address partner) public onlyOwner returns(bool){
        _add_partner(partner);
        return true;
    }

    function whitelist(address referral) public onlyPartnerOrOwner returns (bool){
        require(_whitelist[referral] == STATE_NEW, "Referral is already whitelisted");
        uint256 partner_id = getPartnerId(msg.sender);
        require(partner_id != 0, "Partner not found");
        _whitelist[referral] = STATE_WHITELISTED;
        _referrals[referral] = partner_id;
        _partners_referrals[partner_id][_partners_referrals_counter[partner_id]] = referral;
        _partners_referrals_counter[partner_id] ++;
        emit Whitelisted(msg.sender, referral);

    }

    function setWhitelistState(address referral, uint8 state) public onlyOwner returns (bool){
        require(_whitelist[referral] != STATE_NEW, "Referral is not in list");
        _whitelist[referral] = state;
    }

    function getWhitelistState(address referral) public view returns (uint8){
        return _whitelist[referral];
    }

    function getPartner(address referral) public view returns (address){
        return _partner_address[_referrals[referral]];
    }

    function setPartnersAddress(uint256 partner_id, address new_partner) public onlyOwner returns (bool){
        _partner_address[partner_id] = new_partner;
        _partner_ids[new_partner] = partner_id;
        return true;
    }

    function bulkWhitelist(address[] memory address_list) public returns(bool){
        for(uint256 i = 0; i < address_list.length; i++){
            whitelist(address_list[i]);
        }
        return true;
    }

}

// File: contracts/Periods.sol

pragma solidity >=0.4.25 <0.6.0;


contract Periods is Ownable{
    uint16 private _current_period;
    uint16 private _total_periods;
    mapping (uint16=>uint256) _periods;
    bool _adjustable;

    constructor() public{
        _adjustable = true;
    }

    function getPeriodsCounter() public view returns(uint16){
        return _total_periods;
    }

    function getCurrentPeriod() public view returns(uint16){
        return _checkCurrentPeriod();
    }

    function getCurrentTime() public view returns(uint256){
        return now;
    }


    function getCurrentPeriodTimestamp() public view returns(uint256){
        return _periods[_current_period];
    }

    function getPeriodTimestamp(uint16 period) public view returns(uint256){
        return _periods[period];
    }

    
    function setCurrentPeriod(uint16 period) public onlyOwner returns (bool){
        require(period < _total_periods, "Do not have timestamp for that period");
        _current_period = period;
        return true;
    }


    function addPeriodTimestamp(uint256 timestamp) public onlyOwner returns (bool){
//        require(_total_periods - _current_period < 50, "Cannot add more that 50 periods from now");
//        require((_current_period == 0) || (timestamp - _periods[_total_periods-1] > 28 days && (timestamp - _periods[_total_periods-1] < 32 days )), "Incorrect period)");
        _periods[_total_periods] = timestamp;
        _total_periods++;
        return true;
    }

    function _checkCurrentPeriod() private view returns (uint16){
        uint16 current_period = _current_period;
        while( current_period < _total_periods-1){
            if( now < _periods[current_period] ){
                break;
            }
            current_period ++;
        }
        return current_period;
    }

    function adjustCurrentPeriod( ) public returns (uint16){
        if(!_adjustable){
            return _current_period;
        }
        require(_total_periods > 1, "Periods are not set");
        require(_current_period < _total_periods, "Last period reached");
        //require(_total_periods - _current_period < 50, "Adjust more that 50 periods from now");
        uint16 current_period = _checkCurrentPeriod();
        if(current_period > _current_period){
            _current_period = current_period;
        }
        return current_period;
    }

    function addPeriodTimestamps(uint256[] memory timestamps) public onlyOwner returns(bool){
        //require(timestamps.length < 50, "Cannot set more than 50 periods");
        for(uint16 current_timestamp = 0; current_timestamp < timestamps.length; current_timestamp ++){
            addPeriodTimestamp(timestamps[current_timestamp]);
        }
        return true;
    }

    function setLastPeriod(uint16 period) public onlyOwner returns(bool){
        require(period < _total_periods-1, "Incorrect period");
        require(period > _current_period, "Cannot change passed periods");
        _total_periods = period;
        return true;
    }


}

// File: contracts/Subscriptions.sol

pragma solidity >=0.4.25 <0.6.0;




contract Subscriptions is Ownable, Periods {
    using SafeMath for uint256;

    uint8 STATE_MISSING = 0;
    uint8 STATE_ACTIVE = 1;
    uint8 STATE_WITHDRAWN = 2;
    uint8 STATE_PAID = 3;

    uint256 ROUNDING = 1000;

    struct Subscription{
        uint256 subscriber_id;
        uint256 subscription;
        uint256 certificates;
        uint256 certificate_rate;
        uint256 certificate_partners_rate;
        uint16 period;
        uint16 lockout_period;
        uint16 total_periods;
        uint256 certificates_redeemed;
        uint256 redemption;
        uint256 payout;
        uint256 deposit;
        uint256 commission;
        uint256 paid_to_partner;
        uint256 redeem_requested;
        uint256 redeem_delivered;
    }

    mapping (address=>uint256) private _subscribers;
    mapping (uint256=>address) private _subscribers_id;
    uint256 private _subscribers_counter=1;

    mapping (uint256=>Subscription) private _subscriptions;
    mapping (uint256=>mapping(uint256=>uint256)) private _subscribers_subscriptions;
    mapping (uint256=>mapping(uint16=>uint256)) private _subscribers_subscriptions_by_period;
    mapping (uint256=>uint16) private _subscribers_subscriptions_recent;
    uint256 private _subscriptions_counter=1;
    mapping (uint256=>uint256) private _subscribers_subscriptions_counter;

    uint256 private _commission;

    uint256 private _total_subscription=0;
    uint16 private _lockout_period;
    uint16 private _max_period;

    event Subscribe(address subscriber, uint256 subscription, uint256 certs );
    event Topup(address indexed subscriber, uint256 subscription_id, uint256 amount);
    event Payout(address indexed subscriber, uint256 subscription_id, uint256 amount);
    event Redemption(address indexed subscriber, uint256 subscription_id, uint256 amount);
    event RedemptionPartner(address indexed partner, address indexed subscriber, uint256 subscription_id, uint256 amount);
    event AmountCertNickelWireReceived(address indexed subscriber, uint256 subscription_id, uint256 amount);

    constructor() public{
        _lockout_period = 3;
        _max_period = 24;
        _commission = 1000;
    }

    function floor(uint a, uint m) internal pure returns (uint256 ) {
        return ((a ) / m) * m;
    }

    function ceil(uint a, uint m) internal pure returns (uint256 ) {
        return ((a + m + 1) / m) * m;
    }


    function get_subscriber_id(address subscriber_address) public view returns (uint256){
        return _subscribers[subscriber_address];
    }

    function get_subscriber_address(uint256 subscriber_id) public view returns (address){
        return _subscribers_id[subscriber_id];
    }

    function lockoutPeriod() public view returns(uint16){
        return _lockout_period;
    }

    function setLockoutPeriod(uint16 period) public returns (bool){
        _lockout_period = period;
        return true;
    }

    function maxPeriod() public view returns(uint16){
        return _max_period;
    }

    function setMaxPeriod(uint16 period) public onlyOwner returns(bool){
        _max_period = period;
        return true;
    }

    function commission() public view returns(uint256){
        return _commission;
    }

    function setCommission(uint256 value) public onlyOwner returns(bool){
        _commission = value;
        return true;
    }


    function _new_subscription(uint256 subscriber_id, uint16 period, uint256 amount, uint256 units, uint256 unit_rate, uint256 partners_rate) private returns(bool){
            Subscription memory subscription = Subscription(
                subscriber_id,
                amount, // subscription
                units, // certificates
                unit_rate, // certificate_rate
                partners_rate, // certificate_partners_rate
                period, // period
                _lockout_period, // lockout_period
                _max_period, // total_periods
                0, // certificates_redeemed
                0, // redemption
                0, // redemption
                0, // deposit
                0, // commission
                0,  // paidtopartner
                0, // redemptiuon requested
                0 // redeemption delivered
                );

            uint256 subscription_id = _subscriptions_counter;
            _subscriptions[subscription_id] = subscription;
            uint256 subscribers_subscriptions_counter = _subscribers_subscriptions_counter[subscriber_id];
            _subscribers_subscriptions[subscriber_id][subscribers_subscriptions_counter] = subscription_id;
            _subscribers_subscriptions_by_period[subscriber_id][period] = subscription_id;
            if(_subscribers_subscriptions_recent[subscriber_id] < period){
                _subscribers_subscriptions_recent[subscriber_id] = period;
            }
            _subscribers_subscriptions_counter[subscriber_id]++;
            _subscriptions_counter++;
    }


    function _subscribe(address subscriber, uint256 amount, uint256 units, uint256 unit_rate, uint256 partners_rate ) private returns(bool){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        uint16 current_period = getCurrentPeriod();
        if( subscriber_id == 0 ){
            subscriber_id = _subscribers_counter;
            _subscribers[subscriber] = subscriber_id;
            _subscribers_id[subscriber_id] = subscriber;
            _subscribers_counter ++;
        }

        if(_subscribers_subscriptions_counter[subscriber_id] == 0){
            _new_subscription(subscriber_id, current_period, amount, units, unit_rate, partners_rate);
        }else{
            Subscription storage subscription = _subscriptions[_subscribers_subscriptions_by_period[subscriber_id][_subscribers_subscriptions_recent[subscriber_id]]];
            if( subscription.period == current_period){
                subscription.subscription = subscription.subscription.add(amount);
                if(units != 0){
                    subscription.certificate_rate = subscription.certificate_rate.mul(subscription.certificates).add(units.mul(unit_rate)).div(subscription.certificates.add(units));
                    subscription.certificate_partners_rate = subscription.certificate_partners_rate.mul(subscription.certificates).add(units.mul(partners_rate)).div(subscription.certificates.add(units));
                    subscription.certificates = subscription.certificates.add(units);
                }
            }else{
                _new_subscription(subscriber_id, current_period, amount, units, unit_rate, partners_rate);
            }
        }
        emit Subscribe(subscriber, amount, units);
        return true;
    }

    function _payout(address subscriber, uint256 subscription_id, uint256 amount ) private returns(bool){
        uint subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");

        Subscription storage subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        uint256 total_payout = subscription.payout.add(amount);
        require (subscription.subscription >= total_payout, "Payout exceeds subscription");
        subscription.payout = total_payout;
        return true;
    }

    function _return_payout(address subscriber, uint256 subscription_id, uint256 amount ) private returns(bool){
        uint subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        Subscription storage subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        uint256 total_payout = subscription.payout.sub(amount);
        require(total_payout <= subscription.subscription, "Cannot return more than initial subscription");
        subscription.payout = total_payout;
        return true;
    }


    function _redeem(uint256 subscriber_id, uint256 subscription_id, uint256 amount ) private returns(bool){
        Subscription storage subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        require( subscription.certificates.sub(subscription.certificates_redeemed) >= amount, "Not enough certificates");

        uint256 pay_to_partner_rate = 0;
        if( getCurrentPeriod() >= subscription.period + subscription.lockout_period ){
             pay_to_partner_rate = subscription.certificate_partners_rate.mul( getCurrentPeriod() - subscription.period - subscription.lockout_period).div(subscription.total_periods-subscription.lockout_period);
        }

        uint256 subscription_required = floor(amount.mul(subscription.certificate_rate.add(pay_to_partner_rate).add(commission())), ROUNDING);

        uint256 subscription_debit = subscription.subscription.add(subscription.deposit);
        uint256 subscription_credit = subscription.redemption.add(subscription.payout).add(subscription.commission).add(subscription.paid_to_partner);

        require(subscription_debit > subscription_credit, "Too much credited");
        require(subscription_required <= subscription_debit.sub(subscription_credit), "Not enough funds");

        uint256 redemption_total = floor(amount.mul(subscription.certificate_rate), ROUNDING);

        subscription.certificates_redeemed = subscription.certificates_redeemed.add(amount);
        subscription.redemption = subscription.redemption.add( redemption_total);
        subscription.paid_to_partner = subscription.paid_to_partner.add( _get_partners_payout(subscriber_id, subscription_id, amount) );
        subscription.commission = floor(subscription.commission.add( amount.mul(commission())), ROUNDING);
        return true;
    }

    function _partners_redeem(uint256 partners_subscriber_id, uint256 subscriber_id, uint256 subscription_id, uint256 amount ) private returns(bool){

        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        Subscription storage partners_subscription = _subscriptions[_subscribers_subscriptions_by_period[partners_subscriber_id][subscription.period]]; 

        uint256 redemption_total = amount.mul(subscription.certificate_partners_rate);
        partners_subscription.redemption = partners_subscription.redemption.add( redemption_total);
        partners_subscription.deposit = partners_subscription.deposit.add( _get_partners_payout(subscriber_id, subscription_id, amount ));
        return true;
    }

    function _get_subscriptions_count(uint256 subscriber_id) private view returns(uint256){
        return _subscribers_subscriptions_counter[subscriber_id];
    }


    function getSubscriptionsCountAll() public view returns(uint256) {
        return _subscriptions_counter;
    }

    function getSubscriptionsCount(address subscriber) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return _get_subscriptions_count(subscriber_id);
    }

    function _getSubscription(uint256 subscriber_id, uint256 subscription_id) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        return subscription.subscription;

    }

    function _getPayout(uint256 subscriber_id, uint256 subscription_id) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        return subscription.payout;

    }


    function _getCertificates(uint256 subscriber_id, uint256 subscription_id) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        return subscription.certificates;

    }

 


    function subscribe(address subscriber, uint256 amount, uint256 units, uint256 unit_rate, uint256 partner_rate) internal returns(bool){
        _subscribe(subscriber, amount, units, unit_rate, partner_rate);
        return true;
    }

    function _getCertificatesAvailable(uint256 subscriber_id, uint256 subscription_id) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        uint256 subscription_debit = subscription.subscription.add(subscription.deposit);
        uint256 subscription_credit = subscription.redemption.add(subscription.payout).add(subscription.commission).add(subscription.paid_to_partner);
        if( subscription_credit >= subscription_debit){
            return 0;
        }
        uint256 pay_to_partner_rate = 0;
        if( getCurrentPeriod() >= subscription.period + subscription.lockout_period ){
             pay_to_partner_rate = subscription.certificate_partners_rate.mul( getCurrentPeriod() - subscription.period - subscription.lockout_period).div(subscription.total_periods-subscription.lockout_period);
        }
        uint256 cert_rate = subscription.certificate_rate.add(pay_to_partner_rate).add(commission());
        return ( subscription_debit.sub(subscription_credit).div( floor(cert_rate, ROUNDING)) );
    }    

    function _getTopupAmount(uint256 subscriber_id, uint256 subscription_id, uint256 amount) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        require( amount <= subscription.certificates - subscription.certificates_redeemed, "Cannot calculate for amount greater than available");
        uint256 calc_amount = amount;
        if( amount == 0){
            calc_amount = subscription.certificates - subscription.certificates_redeemed;
        }
        uint256 subscription_debit = subscription.subscription.add(subscription.deposit);
        uint256 subscription_credit = subscription.redemption.add(subscription.payout).add(subscription.commission).add(subscription.paid_to_partner);

        uint256 pay_to_partner_rate = 0;
        if( getCurrentPeriod() >= subscription.period + subscription.lockout_period ){
             pay_to_partner_rate = floor(subscription.certificate_partners_rate.
                                    mul( getCurrentPeriod() - subscription.period - subscription.lockout_period).
                                    div(subscription.total_periods-subscription.lockout_period), ROUNDING);
        }
        uint256 cert_rate = subscription.certificate_rate.add(pay_to_partner_rate).add(commission());
        uint256 required_amount = cert_rate.mul(calc_amount);

        if( required_amount <= subscription_debit.sub(subscription_credit) ) return 0;

        return ( ceil(required_amount.sub(subscription_debit.sub(subscription_credit)), 1000));
    }


    function _get_available_payout(uint256 subscriber_id, uint256 subscription_id) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        uint16 periods_passed = getCurrentPeriod() - subscription.period;
        if( periods_passed <= subscription.lockout_period) {
            return 0;
        }
        if( periods_passed > subscription.total_periods) {
            return subscription.subscription.add(subscription.deposit).sub(subscription.payout).
                sub(subscription.redemption).sub(subscription.commission).sub(subscription.paid_to_partner);
        }
        uint256 debit = subscription.subscription.sub(subscription.redemption).
            div(subscription.total_periods - subscription.lockout_period).mul(periods_passed - subscription.lockout_period).add(subscription.deposit);
        uint256 credit = subscription.paid_to_partner.add(subscription.payout).add(subscription.commission);
        //if (credit >= debit) return 0;
        return floor(debit.sub(credit), 1000);
    }

    function get_available(address subscriber, uint256 subscription_id) private view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return(_get_available_payout(subscriber_id, subscription_id));
    }

    function get_available_certs(address subscriber, uint256 subscription_id) private view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return(_get_available_payout(subscriber_id, subscription_id));
    }
    function _get_partners_payout(uint256 subscriber_id, uint256 subscription_id, uint256 amount) private view returns (uint256){
        Subscription memory subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        uint16 periods_passed = getCurrentPeriod() - subscription.period;
        if( periods_passed <= subscription.lockout_period) {
            return 0;
        }
        if( periods_passed > subscription.total_periods) {
            return floor(amount.mul(subscription.certificate_partners_rate), ROUNDING);
        }
        uint256 partners_payout = floor(amount.mul(subscription.certificate_partners_rate).
                                        div(subscription.total_periods - subscription.lockout_period).
                                        mul(periods_passed - subscription.lockout_period), ROUNDING);
        return partners_payout;
    }

    function get_partners_payout(address subscriber, uint256 subscription_id, uint256 amount) private view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return(_get_partners_payout(subscriber_id, subscription_id, amount));
    }

    function payout(address subscriber, uint256 subscription_id, uint256 amount) internal returns(bool){
        uint256 available = get_available(subscriber, subscription_id);
        require(available >= amount, "Not enough funds for withdrawal");
        _payout(subscriber, subscription_id, amount);
        emit Payout(subscriber, subscription_id, amount);
        return true;
    }

    function redeem(address subscriber, uint256 subscription_id, uint256 amount) internal returns(bool){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        _redeem(subscriber_id, subscription_id, amount);
        emit Redemption(subscriber, subscription_id, amount);

    }

    function partners_redeem(address partner, address subscriber, uint256 subscription_id, uint256 amount) internal returns(bool){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        uint256 partners_subscriber_id = get_subscriber_id(partner);
        require(partners_subscriber_id != 0, "No subscriber id found");
        _partners_redeem(partners_subscriber_id, subscriber_id, subscription_id, amount);
        emit RedemptionPartner(partner, subscriber, subscription_id, amount);
    }

    function return_payout(address subscriber, uint256 subscription_id, uint256 amount) internal returns(bool){
        _return_payout(subscriber, subscription_id, amount);
        return true;
    }

    function getAvailable(address subscriber, uint256 subscription_id) public view returns(uint256){
        return get_available(subscriber, subscription_id);
    }

    function _changeSubscriptionOwner(address old_subscriber_address, address new_subscriber_address) internal returns (bool){
        uint256 subscriber_id = get_subscriber_id(old_subscriber_address);
        require(getSubscriptionsCount(new_subscriber_address) == 0, "New subscriber has subscriptions");
        _subscribers[new_subscriber_address] = subscriber_id;
        _subscribers_id[subscriber_id] = new_subscriber_address;
        return true;
    }

    function _get_subscription(uint256 subscriber_id, uint256 subscription_id) private view returns(Subscription memory){
        return  _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
    }



    function get_subscription(address subscriber, uint256 subscription_id) internal view returns(Subscription memory){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return  _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
    }

    function get_global_subscription(uint256 subscription_id) internal view returns(Subscription memory){
        return  _subscriptions[subscription_id];
    }


    function _top(uint256 subscriber_id, uint256 subscription_id, uint256 amount) private returns(bool){
        Subscription storage subscription =  _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        subscription.deposit = subscription.deposit.add(amount);
        return true;
    }


    function top(address subscriber, uint256 subscription_id, uint256 amount) internal returns(bool){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        //require(_getTopupAmount(subscriber_id, subscription_id, 0) >= amount, "Cannot topup more that available");
        _top(subscriber_id, subscription_id, amount);
        emit Topup(subscriber,subscription_id,amount);
    }


    function getCertSubscriptionStartDate(address subscriber, uint256 subscription_id) public view returns(uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return getPeriodTimestamp(subscription.period);
    }

    function getNWXgrantedToInvestor(address subscriber, uint256 subscription_id) public view returns(uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return subscription.subscription;
    }

    function getNWXgrantedToPartner(address subscriber, uint256 subscription_id) public view returns(uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return _get_partners_payout(subscriber_id, subscription_id, subscription.certificates.sub(subscription.certificates_redeemed) ).add(subscription.paid_to_partner);
    }

    function getNWXpayedToInvestor(address subscriber, uint256 subscription_id) public view returns(uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return subscription.payout;
    }

    function getNWXpayedToPartner(address subscriber, uint256 subscription_id) public view returns(uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return subscription.paid_to_partner;
    }


    function  getAmountCertRedemptionRequested(address subscriber, uint256 subscription_id) public view returns(uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return subscription.certificates_redeemed;
    }

    function  getAmountCertNickelWireReceived(address subscriber, uint256 subscription_id) public view returns(uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return subscription.redeem_delivered;
    }

    function  setAmountCertNickelWireReceived(address subscriber, uint256 subscription_id, uint256 amount ) public onlyOwner returns(bool){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        Subscription storage subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        require(subscription.certificates_redeemed>=amount, "Not enough redeemed certs");
        subscription.redeem_delivered = amount;
        emit AmountCertNickelWireReceived(subscriber, subscription_id, amount);
        return true;
    }
    /*
    function  setAmountCertRedemptionRequested(address subscriber, uint256 subscription_id, uint256 amount ) public onlyOwner returns(bool){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        Subscription storage subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        require(subscription.certificates_redeemed>=amount, "Not enough redeemed certs");
        subscription.redeem_requested = amount;
        return true;
    }
    */
    /*
    function  requestRedemption(uint256 subscription_id, uint256 amount ) public returns(bool){
        uint256 subscriber_id = get_subscriber_id(msg.sender);
        Subscription storage subscription = _subscriptions[_subscribers_subscriptions[subscriber_id][subscription_id]];
        require(subscription.certificates_redeemed>=subscription.redeem_requested.add(amount), "Not enough redeemed certs");
        subscription.redeem_requested = subscription.redeem_requested.add(amount);
        return true;
    }
    */

   function getTopupAmount(address subscriber, uint256 subscription_id, uint256 amount) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return _getTopupAmount(subscriber_id, subscription_id, amount);
    }


    function getSubscription(address subscriber, uint256 subscription_id) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return _getSubscription(subscriber_id, subscription_id);
    }

    function getPayout(address subscriber, uint256 subscription_id) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return _getPayout(subscriber_id, subscription_id);
    }


    function getSubscriptionAll(address subscriber) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        uint256 total_subscription = 0;
        for( uint256 subscription_id = 0; subscription_id < _subscribers_subscriptions_counter[subscriber_id]; subscription_id++){
            total_subscription = total_subscription.add(_getSubscription(subscriber_id, subscription_id));
        }
        return total_subscription;
    }


    function getCertificatesRedeemedQty(address subscriber, uint256 subscription_id) public view returns (uint256){
        Subscription memory subscription = get_subscription(subscriber, subscription_id);
        return subscription.certificates_redeemed;
    }


    function getCertificatesQty(address subscriber, uint256 subscription_id) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return _getCertificates(subscriber_id, subscription_id);
    }


    function getCertificatesQtyAll(address subscriber) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        uint256 total_certificates = 0;
        for( uint256 subscription_id = 0; subscription_id < _subscribers_subscriptions_counter[subscriber_id]; subscription_id++){
            total_certificates = total_certificates.add(_getCertificates(subscriber_id, subscription_id));
        }
        return total_certificates;
    }



    function getCertificatesQtyAvailable(address subscriber, uint256 subscription_id) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        return _getCertificatesAvailable(subscriber_id, subscription_id);
    }

    function getCertificatesQtyAvailableAll(address subscriber) public view returns (uint256){
        uint256 subscriber_id = get_subscriber_id(subscriber);
        require(subscriber_id != 0, "No subscriber id found");
        uint256 total_certificates = 0;
        for( uint256 subscription_id = 0; subscription_id < _subscribers_subscriptions_counter[subscriber_id]; subscription_id++){
            total_certificates = total_certificates.add(_getCertificatesAvailable(subscriber_id, subscription_id));
        }
        return total_certificates;
    }


}

// File: contracts/INIWIX.sol

pragma solidity >=0.4.25 <0.6.0;


interface INIWIX {
    function tokenFallback( address from, uint256 value ) external returns(bool);
}

// File: contracts/Cert.sol

pragma solidity >=0.4.25 <0.6.0;
pragma experimental ABIEncoderV2;








contract Cert is Ownable, Whitelist, Subscriptions{
    using SafeMath for uint256;

    string private _name;

    IERC20 _niwix;
    IERC20 _euron;

    uint256 private _deposit_niwix_rate;
    uint256 private _subscription_niwix_rate;
    uint256 private _subscription_partner_rate;
    uint256 private _subscription_unit_rate;

    uint public n;
    address public sender;

    event TokenFallbackCert(address indexed where, address indexed sender, address indexed from, uint256 value);
    event DepositTo(address indexed where, address indexed sender, address indexed to, uint256 value);
    event Redemption(address indexed subscriber, uint256 subscription_id, uint256 amount);
    event ChangeSubscriber(address indexed from, address indexed to);
    event Withdraw(address indexed subscriber, uint256 subscription_id, uint256 amount);
    event Deposit(address indexed subscriber, uint256 amount);
    event SetNIWIXRate(uint256 rate);
    event SetUnitPrice(uint256 rate);
    event SetSubscriptionPartnerRate(uint256 rate);

    mapping (uint256=>uint256) paper_certificate;

    function tokenFallback( address from, uint256 value ) public returns(bool){
        if( msg.sender == address(_euron)){
            if( from != address(_niwix) )
            {
                _euron.transfer(address(_niwix), value);
                INIWIX(address(_niwix)).tokenFallback(from, value);
            }
        }
        return true;
    }


    constructor() public {
        _name = "NiwixCert";
        _deposit_niwix_rate = 1000 * 10 ** 8;
        _subscription_niwix_rate = 10000 * 10 ** 8;
        _subscription_unit_rate = 100 * 10 ** 8;
    }

    function name() public view returns(string memory){
        return _name;
    }

    function setNiwix(address contract_address) public onlyOwner returns(bool){
        _niwix = IERC20(contract_address);
        return true;
    }

    function setEURON(address contract_address) public onlyOwner returns(bool){
        _euron = IERC20(contract_address);
        return true;
    }

    function depositNiwixRate() public view returns(uint256){
        return _deposit_niwix_rate;
    }

    function setDepositNiwixRate(uint256 value) public onlyOwner returns(uint256){
        _deposit_niwix_rate = value;
    }

    function setSubscriptionUnitRate(uint256 value) public onlyOwner returns(uint256){
        _subscription_unit_rate = value;
    }

    function setSubscriptionNiwixRate(uint256 value) public onlyOwner returns(uint256){
        _subscription_niwix_rate = value;
    }

    function getSubscriptionUnitRate() public view returns(uint256){
        return(_subscription_unit_rate);
    }


    function getDepositNiwixValue(uint256 euron_amount) public view returns(uint256){
        return euron_amount.div(_subscription_unit_rate).mul(depositNiwixRate());
    }


    function setSubscriptionParnerRate(uint256 value) public onlyOwner returns(uint256){
        _subscription_partner_rate = value;
    }

    function subscriptionPartnerRate() public view returns(uint256){
        return _subscription_partner_rate;
    }

    function _get_subscription_units(uint256 value) public view returns (uint256){
        return value.div(_subscription_unit_rate);
    }

    function _get_subscription_change(uint256 value) public view returns (uint256){
        uint256 units = value.div(_subscription_unit_rate);
        uint256 subscription = units.mul(_subscription_unit_rate);
        return value.sub(subscription);
    }

    function get_subscription_value(uint256 value) public view returns (uint256, uint256, uint256){
        uint256 units = _get_subscription_units(value);
        uint256 subscription = units.mul(_subscription_unit_rate);
        return (units, subscription, value.sub(subscription));
    }


    function _deposit(address euron_address, uint256 euron_amount, address niwix_address ) private returns (uint256 subscription_value){
        _euron.transferFrom(euron_address, address(this), euron_amount);
        uint256 subscription_change;
        uint256 subscription_units;
        (subscription_units, subscription_value, subscription_change) = get_subscription_value(euron_amount);
        uint256 niwix_amount = getDepositNiwixValue(euron_amount);

        if(niwix_amount>0){
            _niwix.transferFrom(niwix_address, address(this), niwix_amount);
        }
        if(subscription_change > 0 ){
            _euron.transfer(niwix_address, subscription_change);
        }
        address partner = getPartner(niwix_address);
        if (partner != address(0)){
            subscribe(partner, subscription_units.mul(_subscription_partner_rate), 0, 0, 0);
        }

        subscribe(niwix_address, subscription_units.mul(_subscription_niwix_rate), subscription_units, _subscription_niwix_rate, _subscription_partner_rate );
    }

    function depositTo(address address_to, uint256 value) public returns (bool){
        require(getWhitelistState(address_to) == Whitelist.STATE_WHITELISTED, "Address needs to be whitelisted");
        require(partnerStatus(address_to) == Whitelist.STATE_NEW, "Cannot deposit to partner");
        emit DepositTo(address(this), msg.sender, address_to, value);
        _deposit(msg.sender, value, address_to);
        emit Deposit(address_to, value);
        return true;
    }

    function deposit(uint256 value) public returns (bool){
        require(getWhitelistState(msg.sender) == Whitelist.STATE_WHITELISTED, "You need to be whitelisted");
        require(partnerStatus(msg.sender) == Whitelist.STATE_NEW, "Partner cannot deposit");
        uint256 amount = value;
        if(value == 0){
            amount = _euron.allowance(msg.sender, address(this));
        }
        _deposit(msg.sender, amount, msg.sender);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 subscription_id, uint256 value) public returns (bool){
        uint256 amount = value;
        if(value == 0){
            amount = getAvailable(msg.sender, subscription_id);
        }
        require(amount > 0, "Wrong value or no funds availabe for withdrawal");

        payout(msg.sender, subscription_id, amount);
        _niwix.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, subscription_id, amount);
        return true;
    }
    /*
    function return_withdrawal(uint256 subscription_id, uint256 value ) public returns (bool){
        _niwix.transferFrom(msg.sender, address(this), value);
        return_payout(msg.sender, subscription_id, value);
        emit ReturnRedemption(msg.sender, subscription_id, value);
        return true;
    }
    */
    function change_subscribers_address(address from, address to) public onlyOwner returns (bool){
        require(getWhitelistState(to) == Whitelist.STATE_WHITELISTED, "To address must be whitelisted");

        _changeSubscriptionOwner(from, to);
        emit ChangeSubscriber(from, to);
        return true;
    }

    function change_address( address to) public returns (bool){
        require(getWhitelistState(to) == Whitelist.STATE_WHITELISTED, "To address must be whitelisted");
        _changeSubscriptionOwner(msg.sender, to);
        emit ChangeSubscriber(msg.sender, to);
        return true;
    }


    function redemption(uint256 subscription_id, uint256 amount) public  returns (bool){
        address partner = getPartner(msg.sender);
        if (partner != address(0)){
           partners_redeem(partner, msg.sender, subscription_id, amount);
        }

        redeem(msg.sender, subscription_id, amount);
        return true;
    }

    function topup(uint256 subscription_id, uint256 amount) public  returns (bool){
        _niwix.transferFrom(msg.sender, address(this), amount);
        top(msg.sender, subscription_id, amount);
        return true;
    }

    function topupOwner(address to, uint256 subscription_id, uint256 amount) public onlyOwner  returns (bool){
        top(to, subscription_id, amount);
        return true;
    }


    function transfer(address to, uint256 subscription_id, uint256 amount) public returns (bool)
    {
//        Subscription memory subscription = get_subscription(msg.sender, subscription_id);
//        uint256 subscription_certificates = subscription.certificates;
        redemption(subscription_id, amount);
        subscribe(to, amount.mul(_subscription_niwix_rate), amount, _subscription_niwix_rate, _subscription_partner_rate );
        address partner = getPartner(to);
        if (partner != address(0)){
            subscribe(partner, amount.mul(_subscription_partner_rate), 0, 0, 0);
        }

    }

    function viewSubscription(address subscriber, uint256 subscription_id) public view returns(Subscription memory){
        if( subscriber == address(0) )
        {
            return get_global_subscription( subscription_id );
        }
        return get_subscription(subscriber, subscription_id);
    }


    function reclaimEther(address payable _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(IERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_to, balance);
    }

}