pragma solidity 0.4.24;

library SafeMathExt{
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function pow(uint256 a, uint256 b) internal pure returns (uint256) {
    if (b == 0){
      return 1;
    }
    if (b == 1){
      return a;
    }
    uint256 c = a;
    for(uint i = 1; i<b; i++){
      c = mul(c, a);
    }
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

  function roundUp(uint256 a, uint256 b) public pure returns(uint256){
    // ((a + b - 1) / b) * b
    uint256 c = (mul(div(sub(add(a, b), 1), b), b));
    return c;
  }
}

library PureAmber{

    /*==============================
    =             BUY              =
    ==============================*/
    function isValidBuy(uint256 price_, uint256 msgValue_) public pure returns(bool){
        return (price_ == msgValue_);
    }
    function refererAllowed(address msgSender_, address currentReferer_, address newReferer_) public pure returns(bool){
        return (addressNotSet(currentReferer_) && isAddress(newReferer_) && isNotSelf(msgSender_, newReferer_));
    }
    function addressNotSet(address address_) public pure returns(bool){
        return (address_ == 0x0);
    }
    function isAddress(address address_) public pure returns(bool){
        return (address_ != 0x0);
    }
    function isNotSelf(address msgSender_, address compare_) public pure returns(bool){
        return (msgSender_ != compare_);
    }

    /*==============================
    =         BADGE SYSTEM         =
    ==============================*/
    function isFirstBadgeEle(uint256 badgeID_) public pure returns(bool){
        return (badgeID_ == 0);
    }
    function isLastBadgeEle(uint256 badgeID_, uint256 badgeLength_) public pure returns(bool){
        assert(badgeID_ <= SafeMathExt.sub(badgeLength_, 1));
        return (badgeID_ == SafeMathExt.sub(badgeLength_, 1));
    }

    function roundUp(uint256 input_, uint256 decimals_) public pure returns(uint256){
        return ((input_ + decimals_ - 1) / decimals_) * decimals_;
    }

    /*==============================
    =          DIVI SPLIT          =
    ==============================*/   
    function calcShare(uint256 msgValue_, uint256 ratio_) public pure returns(uint256){
        assert(ratio_ <= 100 && msgValue_ >= 0);
        return SafeMathExt.div((SafeMathExt.mul(msgValue_, ratio_)), 100);
    }
    function calcDiviDistribution(uint256 value_, uint256 userCount_) public pure returns(uint256){
        assert(value_ >= 0);
        return SafeMathExt.div(value_, userCount_);
    }
}


contract BadgeFactoryInterface{
	function _initBadges(address admin_, uint256 badgeBasePrice_, uint256 badgeStartMultiplier_, uint256 badgeStartQuantity_) external;
	function _createNewBadge(address owner_, uint256 price_) external;
	function _setOwner(uint256 badgeID_, address owner_) external;
	function getOwner(uint256 badgeID_) public view returns(address);
	function _increasePrice(uint256 badgeID_) external;
	function getPrice(uint256 badgeID_) public view returns(uint256);
	function _increaseTotalDivis(uint256 badgeID_, uint256 divis_) external;
	function getTotalDivis(uint256 badgeID_) public view returns(uint256);
	function _setBuyTime(uint256 badgeID_, uint32 timeStamp_) external;
	function getBuyTime(uint256 badgeID_) public view returns(uint32);
	function getCreationTime(uint256 badgeID_) public view returns(uint32);
	function getChainLength() public view returns(uint256);
}

contract TeamAmberInterface{
    function distribute() public payable;
}


contract Amber{
	using SafeMathExt for uint256;

    /*===============================================================================
    =                      DATA SET                     DATA SET                    =
    ===============================================================================*/
    /*==============================
    =          INTERFACES          =
    ==============================*/
    BadgeFactoryInterface internal _badgeFactory;
    TeamAmberInterface internal _teamAmber;

    /*==============================
    =          CONSTANTS           =
    ==============================*/
    uint256 internal constant FINNEY = 10**15;

    uint256 internal constant _sharePreviousOwnerRatio = 50;
    uint256 internal constant _shareReferalRatio = 5;
    uint256 internal constant _shareDistributionRatio = 45;

    /*==============================
    =          VARIABLES           =
    ==============================*/
    address internal _contractOwner;
    address internal _admin;

    uint256 internal _badgeBasePrice; // = 5 * FINNEY;

    uint256 internal _startTime;

    /*==============================
    =        USER MAPPINGS         =
    ==============================*/
    mapping(address => uint256) private _balanceDivis;
    mapping(address => address) private _referer;

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onContractStart(uint256 startTime_);
    event onRefererSet(address user_, address referer_);
    event onBadgeBuy(uint256 badgeID_, address buyer_, uint256 price_, uint256 newPrice_);
    event onWithdraw(address receiver_, uint256 amount_);

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier onlyContractOwner(){
    	require(msg.sender == _contractOwner, &#39;Sender is not the contract owner.&#39;);
    	_;
    }
    modifier isNotAContract(){
        require (msg.sender == tx.origin, &#39;Contracts are not allowed to interact.&#39;);
        _;
    }
    modifier isRunning(){
    	require(_startTime != 0 && _startTime <= now, &#39;The contract is not running yet.&#39;);
    	_;
    }

    /*===============================================================================
    =                       FUNCTIONS                       FUNCTIONS               =
    ===============================================================================*/
    /*==============================
    =           OWNER ONLY         =
    ==============================*/
    constructor(address admin_, address teamAmberAddress_) public{
    	_contractOwner = msg.sender;
        _admin = admin_;
        _teamAmber = TeamAmberInterface(teamAmberAddress_);
    }

    function initGame(address badgesFactoryAddress_, uint256 badgeBasePrice_, uint256 badgeStartMultiplier_, uint256 badgeStartQuantity_) external onlyContractOwner{
        require(_badgeBasePrice == 0);

        _badgeBasePrice = badgeBasePrice_;
        _badgeFactory = BadgeFactoryInterface(badgesFactoryAddress_);
        _badgeFactory._initBadges(_admin, badgeBasePrice_, badgeStartMultiplier_, badgeStartQuantity_);
    }

    function _startContract(uint256 delay_) external onlyContractOwner{
    	require(_startTime == 0);
        _startTime = now + delay_;

    	emit onContractStart(_startTime);
    }

    /*==============================
    =             BUY              =
    ==============================*/
    function buy(uint256 badgeID_, address newReferer_) public payable isNotAContract isRunning{
    	_refererUpdate(msg.sender, newReferer_);
    	_buy(badgeID_, msg.sender, msg.value);
    }

    function _buy(uint256 badgeID_, address msgSender_, uint256 msgValue_) internal{
        address previousOwner = _badgeFactory.getOwner(badgeID_);
        require(PureAmber.isValidBuy(_badgeFactory.getPrice(badgeID_), msgValue_), &#39;It is not a valid buy.&#39;);

        _diviSplit(badgeID_, previousOwner, msgSender_, msgValue_);
        _extendBadges(badgeID_, msgSender_, _badgeBasePrice);
        _badgeOwnerChange(badgeID_, msgSender_);
        _badgeFactory._increasePrice(badgeID_);

        emit onBadgeBuy (badgeID_, msgSender_, msgValue_, _badgeFactory.getPrice(badgeID_));
    }

    function _refererUpdate(address user_, address newReferer_) internal{
    	if (PureAmber.refererAllowed(user_, _referer[user_], newReferer_)){
    		_referer[user_] = newReferer_;
    		emit onRefererSet(user_, newReferer_);
    	}
    }

    /*==============================
    =         BADGE SYSTEM         =
    ==============================*/
    function _extendBadges(uint256 badgeID_, address owner_, uint256 price_) internal{
        if (PureAmber.isLastBadgeEle(badgeID_, _badgeFactory.getChainLength())){
            _badgeFactory._createNewBadge(owner_, price_);
        }
    }

    function _badgeOwnerChange(uint256 badgeID_, address newOwner_) internal{      
        _badgeFactory._setOwner(badgeID_, newOwner_);
        _badgeFactory._setBuyTime(badgeID_, uint32(now));
    }

    /*==============================
    =          DIVI SPLIT          =
    ==============================*/
    function _diviSplit(uint256 badgeID_, address previousOwner_, address msgSender_, uint256 msgValue_) internal{
    	_shareToPreviousOwner(previousOwner_, msgValue_, _sharePreviousOwnerRatio);
    	_shareToReferer(_referer[msgSender_], msgValue_, _shareReferalRatio);
    	_shareToDistribution(badgeID_, previousOwner_, msgValue_, _shareDistributionRatio);
    }

    function _shareToPreviousOwner(address previousOwner_, uint256 msgValue_, uint256 ratio_) internal{
    	_increasePlayerDivis(previousOwner_, PureAmber.calcShare(msgValue_, ratio_));
    }

    function _shareToReferer(address referer_, uint256 msgValue_, uint256 ratio_) internal{
    	if (PureAmber.addressNotSet(referer_)){
    		_increasePlayerDivis(_admin, PureAmber.calcShare(msgValue_, ratio_));
    	} else {
    		_increasePlayerDivis(referer_, PureAmber.calcShare(msgValue_, ratio_));
    	}
    }

    function _shareToDistribution(uint256 badgeID_, address previousOwner_, uint256 msgValue_, uint256 ratio_) internal{
    	uint256 share = PureAmber.calcShare(msgValue_, ratio_);

    	if (PureAmber.isFirstBadgeEle(badgeID_)){
    		_specialDistribution(previousOwner_, share);
    	} else {
    		_normalDistribution(badgeID_, PureAmber.calcDiviDistribution(share, badgeID_));
    	}
    }

    function _normalDistribution(uint256 badgeID_, uint256 divis_) internal{
    	for(uint256 i = 0; i<badgeID_; i++){
            _badgeFactory._increaseTotalDivis(i, divis_);
            _increasePlayerDivis(_badgeFactory.getOwner(i), divis_);
        }
    }

    function _specialDistribution(address previousOwner_, uint256 divis_) internal{
        _badgeFactory._increaseTotalDivis(0, divis_);
        _increasePlayerDivis(previousOwner_, divis_);
    }

    function _increasePlayerDivis(address user_, uint256 amount_) internal{
        _balanceDivis[user_] = SafeMathExt.add(_balanceDivis[user_], amount_);
    }

    /*==============================
    =           WITHDRAW           =
    ==============================*/
    function withdrawDivis() public isNotAContract{
    	_withdrawDivis(msg.sender);
    }

    function _withdrawDivis(address msgSender_) internal{
    	require (_balanceDivis[msgSender_] >= 0, &#39;Hack attempt: Sender does not have enough Divis to withdraw.&#39;);
    	uint256 payout = _balanceDivis[msgSender_];
        _resetBalanceDivis(msgSender_);
        _transferDivis(msgSender_, payout);

        emit onWithdraw (msgSender_, payout);
    }

    function _transferDivis(address msgSender_, uint256 payout_) internal{
    	assert(address(this).balance >= payout_);
    	if(msgSender_ == _admin){
    		_teamAmber.distribute.value(payout_)();
    	} else {
    		msgSender_.transfer(payout_); 		
    	}
    }

    function _resetBalanceDivis(address user_) internal{
    	_balanceDivis[user_] = 0;
    }

    /*==============================
    =            HELPERS           =
    ==============================*/
    function getStartTime() public view returns (uint256){
        return _startTime;
    }

    function getBalanceDivis(address user_) public view returns(uint256){
    	return _balanceDivis[user_];
    }

    function getReferer(address user_) public view returns(address){
    	return _referer[user_];
    }

    function getBalanceContract() public view returns(uint256){
    	return address(this).balance;
    }

    function getBadges() public view returns(address[], uint256[], uint256[], uint32[], uint32[]){
    	uint256 length = _badgeFactory.getChainLength();
    	address[] memory owner = new address[](length);
    	uint256[] memory price = new uint256[](length);
    	uint256[] memory totalDivis = new uint256[](length);
    	uint32[] memory buyTime = new uint32[](length);
        uint32[] memory creationTime = new uint32[](length);

    	for (uint256 i = 0; i < length; i++) {
           owner[i] = _badgeFactory.getOwner(i);
           price[i] = _badgeFactory.getPrice(i);
           totalDivis[i] = _badgeFactory.getTotalDivis(i);
           buyTime[i] = _badgeFactory.getBuyTime(i);
           creationTime[i] = _badgeFactory.getCreationTime(i);
       }
       return (owner, price, totalDivis, buyTime, creationTime);
   }
}