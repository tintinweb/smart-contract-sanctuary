pragma solidity ^0.4.13;

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

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract Staff is Ownable, RBAC {

	string public constant ROLE_STAFF = "staff";

	function addStaff(address _staff) public onlyOwner {
		addRole(_staff, ROLE_STAFF);
	}

	function removeStaff(address _staff) public onlyOwner {
		removeRole(_staff, ROLE_STAFF);
	}

	function isStaff(address _staff) view public returns (bool) {
		return hasRole(_staff, ROLE_STAFF);
	}
}

contract StaffUtil {
	Staff public staffContract;

	constructor (Staff _staffContract) public {
		require(msg.sender == _staffContract.owner());
		staffContract = _staffContract;
	}

	modifier onlyOwner() {
		require(msg.sender == staffContract.owner());
		_;
	}

	modifier onlyOwnerOrStaff() {
		require(msg.sender == staffContract.owner() || staffContract.isStaff(msg.sender));
		_;
	}
}

contract Crowdsale is StaffUtil {
	using SafeMath for uint256;

	Token tokenContract;
	PromoCodes promoCodesContract;
	DiscountPhases discountPhasesContract;
	DiscountStructs discountStructsContract;

	address ethFundsWallet;
	uint256 referralBonusPercent;
	uint256 startDate;

	uint256 crowdsaleStartDate;
	uint256 endDate;
	uint256 tokenDecimals;
	uint256 tokenRate;
	uint256 tokensForSaleCap;
	uint256 minPurchaseInWei;
	uint256 maxInvestorContributionInWei;
	bool paused;
	bool finalized;
	uint256 weiRaised;
	uint256 soldTokens;
	uint256 bonusTokens;
	uint256 sentTokens;
	uint256 claimedSoldTokens;
	uint256 claimedBonusTokens;
	uint256 claimedSentTokens;
	uint256 purchasedTokensClaimDate;
	uint256 bonusTokensClaimDate;
	mapping(address => Investor) public investors;

	enum InvestorStatus {UNDEFINED, WHITELISTED, BLOCKED}

	struct Investor {
		InvestorStatus status;
		uint256 contributionInWei;
		uint256 purchasedTokens;
		uint256 bonusTokens;
		uint256 referralTokens;
		uint256 receivedTokens;
		TokensPurchase[] tokensPurchases;
		bool isBlockpass;
	}

	struct TokensPurchase {
		uint256 value;
		uint256 amount;
		uint256 bonus;
		address referrer;
		uint256 referrerSentAmount;
	}

	event InvestorWhitelisted(address indexed investor, uint timestamp, address byStaff);
	event InvestorBlocked(address indexed investor, uint timestamp, address byStaff);
	event TokensPurchased(
		address indexed investor,
		uint indexed purchaseId,
		uint256 value,
		uint256 purchasedAmount,
		uint256 promoCodeAmount,
		uint256 discountPhaseAmount,
		uint256 discountStructAmount,
		address indexed referrer,
		uint256 referrerSentAmount,
		uint timestamp
	);
	event TokensPurchaseRefunded(
		address indexed investor,
		uint indexed purchaseId,
		uint256 value,
		uint256 amount,
		uint256 bonus,
		uint timestamp,
		address byStaff
	);
	event Paused(uint timestamp, address byStaff);
	event Resumed(uint timestamp, address byStaff);
	event Finalized(uint timestamp, address byStaff);
	event TokensSent(address indexed investor, uint256 amount, uint timestamp, address byStaff);
	event PurchasedTokensClaimLocked(uint date, uint timestamp, address byStaff);
	event PurchasedTokensClaimUnlocked(uint timestamp, address byStaff);
	event BonusTokensClaimLocked(uint date, uint timestamp, address byStaff);
	event BonusTokensClaimUnlocked(uint timestamp, address byStaff);
	event CrowdsaleStartDateUpdated(uint date, uint timestamp, address byStaff);
	event EndDateUpdated(uint date, uint timestamp, address byStaff);
	event MinPurchaseChanged(uint256 minPurchaseInWei, uint timestamp, address byStaff);
	event MaxInvestorContributionChanged(uint256 maxInvestorContributionInWei, uint timestamp, address byStaff);
	event TokenRateChanged(uint newRate, uint timestamp, address byStaff);
	event TokensClaimed(
		address indexed investor,
		uint256 purchased,
		uint256 bonus,
		uint256 referral,
		uint256 received,
		uint timestamp,
		address byStaff
	);
	event TokensBurned(uint256 amount, uint timestamp, address byStaff);

	constructor (
		uint256[11] uint256Args,
		address[5] addressArgs
	) StaffUtil(Staff(addressArgs[4])) public {

		// uint256 args
		startDate = uint256Args[0];
		crowdsaleStartDate = uint256Args[1];
		endDate = uint256Args[2];
		tokenDecimals = uint256Args[3];
		tokenRate = uint256Args[4];
		tokensForSaleCap = uint256Args[5];
		minPurchaseInWei = uint256Args[6];
		maxInvestorContributionInWei = uint256Args[7];
		purchasedTokensClaimDate = uint256Args[8];
		bonusTokensClaimDate = uint256Args[9];
		referralBonusPercent = uint256Args[10];

		// address args
		ethFundsWallet = addressArgs[0];
		promoCodesContract = PromoCodes(addressArgs[1]);
		discountPhasesContract = DiscountPhases(addressArgs[2]);
		discountStructsContract = DiscountStructs(addressArgs[3]);

		require(startDate < crowdsaleStartDate);
		require(crowdsaleStartDate < endDate);
		require(tokenDecimals > 0);
		require(tokenRate > 0);
		require(tokensForSaleCap > 0);
		require(minPurchaseInWei <= maxInvestorContributionInWei);
		require(ethFundsWallet != address(0));
	}

	function getState() external view returns (bool[2] boolArgs, uint256[18] uint256Args, address[6] addressArgs) {
		boolArgs[0] = paused;
		boolArgs[1] = finalized;
		uint256Args[0] = weiRaised;
		uint256Args[1] = soldTokens;
		uint256Args[2] = bonusTokens;
		uint256Args[3] = sentTokens;
		uint256Args[4] = claimedSoldTokens;
		uint256Args[5] = claimedBonusTokens;
		uint256Args[6] = claimedSentTokens;
		uint256Args[7] = purchasedTokensClaimDate;
		uint256Args[8] = bonusTokensClaimDate;
		uint256Args[9] = startDate;
		uint256Args[10] = crowdsaleStartDate;
		uint256Args[11] = endDate;
		uint256Args[12] = tokenRate;
		uint256Args[13] = tokenDecimals;
		uint256Args[14] = minPurchaseInWei;
		uint256Args[15] = maxInvestorContributionInWei;
		uint256Args[16] = referralBonusPercent;
		uint256Args[17] = getTokensForSaleCap();
		addressArgs[0] = staffContract;
		addressArgs[1] = ethFundsWallet;
		addressArgs[2] = promoCodesContract;
		addressArgs[3] = discountPhasesContract;
		addressArgs[4] = discountStructsContract;
		addressArgs[5] = tokenContract;
	}

	function fitsTokensForSaleCap(uint256 _amount) public view returns (bool) {
		return getDistributedTokens().add(_amount) <= getTokensForSaleCap();
	}

	function getTokensForSaleCap() public view returns (uint256) {
		if (tokenContract != address(0)) {
			return tokenContract.balanceOf(this);
		}
		return tokensForSaleCap;
	}

	function getDistributedTokens() public view returns (uint256) {
		return soldTokens.sub(claimedSoldTokens).add(bonusTokens.sub(claimedBonusTokens)).add(sentTokens.sub(claimedSentTokens));
	}

	function setTokenContract(Token token) external onlyOwner {
		require(token.balanceOf(this) >= 0);
		require(tokenContract == address(0));
		require(token != address(0));
		tokenContract = token;
	}

	function getInvestorClaimedTokens(address _investor) external view returns (uint256) {
		if (tokenContract != address(0)) {
			return tokenContract.balanceOf(_investor);
		}
		return 0;
	}

	function isBlockpassInvestor(address _investor) external constant returns (bool) {
		return investors[_investor].status == InvestorStatus.WHITELISTED && investors[_investor].isBlockpass;
	}

	function whitelistInvestor(address _investor, bool _isBlockpass) external onlyOwnerOrStaff {
		require(_investor != address(0));
		require(investors[_investor].status != InvestorStatus.WHITELISTED);

		investors[_investor].status = InvestorStatus.WHITELISTED;
		investors[_investor].isBlockpass = _isBlockpass;

		emit InvestorWhitelisted(_investor, now, msg.sender);
	}

	function bulkWhitelistInvestor(address[] _investors) external onlyOwnerOrStaff {
		for (uint256 i = 0; i < _investors.length; i++) {
			if (_investors[i] != address(0) && investors[_investors[i]].status != InvestorStatus.WHITELISTED) {
				investors[_investors[i]].status = InvestorStatus.WHITELISTED;
				emit InvestorWhitelisted(_investors[i], now, msg.sender);
			}
		}
	}

	function blockInvestor(address _investor) external onlyOwnerOrStaff {
		require(_investor != address(0));
		require(investors[_investor].status != InvestorStatus.BLOCKED);

		investors[_investor].status = InvestorStatus.BLOCKED;

		emit InvestorBlocked(_investor, now, msg.sender);
	}

	function lockPurchasedTokensClaim(uint256 _date) external onlyOwner {
		require(_date > now);
		purchasedTokensClaimDate = _date;
		emit PurchasedTokensClaimLocked(_date, now, msg.sender);
	}

	function unlockPurchasedTokensClaim() external onlyOwner {
		purchasedTokensClaimDate = now;
		emit PurchasedTokensClaimUnlocked(now, msg.sender);
	}

	function lockBonusTokensClaim(uint256 _date) external onlyOwner {
		require(_date > now);
		bonusTokensClaimDate = _date;
		emit BonusTokensClaimLocked(_date, now, msg.sender);
	}

	function unlockBonusTokensClaim() external onlyOwner {
		bonusTokensClaimDate = now;
		emit BonusTokensClaimUnlocked(now, msg.sender);
	}

	function setCrowdsaleStartDate(uint256 _date) external onlyOwner {
		crowdsaleStartDate = _date;
		emit CrowdsaleStartDateUpdated(_date, now, msg.sender);
	}

	function setEndDate(uint256 _date) external onlyOwner {
		endDate = _date;
		emit EndDateUpdated(_date, now, msg.sender);
	}

	function setMinPurchaseInWei(uint256 _minPurchaseInWei) external onlyOwner {
		minPurchaseInWei = _minPurchaseInWei;
		emit MinPurchaseChanged(_minPurchaseInWei, now, msg.sender);
	}

	function setMaxInvestorContributionInWei(uint256 _maxInvestorContributionInWei) external onlyOwner {
		require(minPurchaseInWei <= _maxInvestorContributionInWei);
		maxInvestorContributionInWei = _maxInvestorContributionInWei;
		emit MaxInvestorContributionChanged(_maxInvestorContributionInWei, now, msg.sender);
	}

	function changeTokenRate(uint256 _tokenRate) external onlyOwner {
		require(_tokenRate > 0);
		tokenRate = _tokenRate;
		emit TokenRateChanged(_tokenRate, now, msg.sender);
	}

	function buyTokens(bytes32 _promoCode, address _referrer) external payable {
		require(!finalized);
		require(!paused);
		require(startDate < now);
		require(investors[msg.sender].status == InvestorStatus.WHITELISTED);
		require(msg.value > 0);
		require(msg.value >= minPurchaseInWei);
		require(investors[msg.sender].contributionInWei.add(msg.value) <= maxInvestorContributionInWei);

		// calculate purchased amount
		uint256 purchasedAmount;
		if (tokenDecimals > 18) {
			purchasedAmount = msg.value.mul(tokenRate).mul(10 ** (tokenDecimals - 18));
		} else if (tokenDecimals < 18) {
			purchasedAmount = msg.value.mul(tokenRate).div(10 ** (18 - tokenDecimals));
		} else {
			purchasedAmount = msg.value.mul(tokenRate);
		}

		// calculate total amount, this includes promo code amount or discount phase amount
		uint256 promoCodeBonusAmount = promoCodesContract.applyBonusAmount(msg.sender, purchasedAmount, _promoCode);
		uint256 discountPhaseBonusAmount = discountPhasesContract.calculateBonusAmount(purchasedAmount);
		uint256 discountStructBonusAmount = discountStructsContract.getBonus(msg.sender, purchasedAmount, msg.value);
		uint256 bonusAmount = promoCodeBonusAmount.add(discountPhaseBonusAmount).add(discountStructBonusAmount);

		// update referrer&#39;s referral tokens
		uint256 referrerBonusAmount;
		address referrerAddr;
		if (
			_referrer != address(0)
			&& msg.sender != _referrer
			&& investors[_referrer].status == InvestorStatus.WHITELISTED
		) {
			referrerBonusAmount = purchasedAmount * referralBonusPercent / 100;
			referrerAddr = _referrer;
		}

		// check that calculated tokens will not exceed tokens for sale cap
		require(fitsTokensForSaleCap(purchasedAmount.add(bonusAmount).add(referrerBonusAmount)));

		// update crowdsale total amount of capital raised
		weiRaised = weiRaised.add(msg.value);
		soldTokens = soldTokens.add(purchasedAmount);
		bonusTokens = bonusTokens.add(bonusAmount).add(referrerBonusAmount);

		// update referrer&#39;s bonus tokens
		investors[referrerAddr].referralTokens = investors[referrerAddr].referralTokens.add(referrerBonusAmount);

		// update investor&#39;s purchased tokens
		investors[msg.sender].purchasedTokens = investors[msg.sender].purchasedTokens.add(purchasedAmount);

		// update investor&#39;s bonus tokens
		investors[msg.sender].bonusTokens = investors[msg.sender].bonusTokens.add(bonusAmount);

		// update investor&#39;s tokens eth value
		investors[msg.sender].contributionInWei = investors[msg.sender].contributionInWei.add(msg.value);

		// update investor&#39;s tokens purchases
		uint tokensPurchasesLength = investors[msg.sender].tokensPurchases.push(TokensPurchase({
			value : msg.value,
			amount : purchasedAmount,
			bonus : bonusAmount,
			referrer : referrerAddr,
			referrerSentAmount : referrerBonusAmount
			})
		);

		// log investor&#39;s tokens purchase
		emit TokensPurchased(
			msg.sender,
			tokensPurchasesLength - 1,
			msg.value,
			purchasedAmount,
			promoCodeBonusAmount,
			discountPhaseBonusAmount,
			discountStructBonusAmount,
			referrerAddr,
			referrerBonusAmount,
			now
		);

		// forward eth to funds wallet
		require(ethFundsWallet.call.gas(300000).value(msg.value)());
	}

	function sendTokens(address _investor, uint256 _amount) external onlyOwner {
		require(investors[_investor].status == InvestorStatus.WHITELISTED);
		require(_amount > 0);
		require(fitsTokensForSaleCap(_amount));

		// update crowdsale total amount of capital raised
		sentTokens = sentTokens.add(_amount);

		// update investor&#39;s received tokens balance
		investors[_investor].receivedTokens = investors[_investor].receivedTokens.add(_amount);

		// log tokens sent action
		emit TokensSent(
			_investor,
			_amount,
			now,
			msg.sender
		);
	}

	function burnUnsoldTokens() external onlyOwner {
		require(tokenContract != address(0));
		require(finalized);

		uint256 tokensToBurn = tokenContract.balanceOf(this).sub(getDistributedTokens());
		require(tokensToBurn > 0);

		tokenContract.burn(tokensToBurn);

		// log tokens burned action
		emit TokensBurned(tokensToBurn, now, msg.sender);
	}

	function claimTokens() external {
		require(tokenContract != address(0));
		require(!paused);
		require(investors[msg.sender].status == InvestorStatus.WHITELISTED);

		uint256 clPurchasedTokens;
		uint256 clReceivedTokens;
		uint256 clBonusTokens_;
		uint256 clRefTokens;

		require(purchasedTokensClaimDate < now || bonusTokensClaimDate < now);

		{
			uint256 purchasedTokens = investors[msg.sender].purchasedTokens;
			uint256 receivedTokens = investors[msg.sender].receivedTokens;
			if (purchasedTokensClaimDate < now && (purchasedTokens > 0 || receivedTokens > 0)) {
				investors[msg.sender].contributionInWei = 0;
				investors[msg.sender].purchasedTokens = 0;
				investors[msg.sender].receivedTokens = 0;

				claimedSoldTokens = claimedSoldTokens.add(purchasedTokens);
				claimedSentTokens = claimedSentTokens.add(receivedTokens);

				// free up storage used by transaction
				delete (investors[msg.sender].tokensPurchases);

				clPurchasedTokens = purchasedTokens;
				clReceivedTokens = receivedTokens;

				tokenContract.transfer(msg.sender, purchasedTokens.add(receivedTokens));
			}
		}

		{
			uint256 bonusTokens_ = investors[msg.sender].bonusTokens;
			uint256 refTokens = investors[msg.sender].referralTokens;
			if (bonusTokensClaimDate < now && (bonusTokens_ > 0 || refTokens > 0)) {
				investors[msg.sender].bonusTokens = 0;
				investors[msg.sender].referralTokens = 0;

				claimedBonusTokens = claimedBonusTokens.add(bonusTokens_).add(refTokens);

				clBonusTokens_ = bonusTokens_;
				clRefTokens = refTokens;

				tokenContract.transfer(msg.sender, bonusTokens_.add(refTokens));
			}
		}

		require(clPurchasedTokens > 0 || clBonusTokens_ > 0 || clRefTokens > 0 || clReceivedTokens > 0);
		emit TokensClaimed(msg.sender, clPurchasedTokens, clBonusTokens_, clRefTokens, clReceivedTokens, now, msg.sender);
	}

	function refundTokensPurchase(address _investor, uint _purchaseId) external payable onlyOwner {
		require(msg.value > 0);
		require(investors[_investor].tokensPurchases[_purchaseId].value == msg.value);

		_refundTokensPurchase(_investor, _purchaseId);

		// forward eth to investor&#39;s wallet address
		_investor.transfer(msg.value);
	}

	function refundAllInvestorTokensPurchases(address _investor) external payable onlyOwner {
		require(msg.value > 0);
		require(investors[_investor].contributionInWei == msg.value);

		for (uint i = 0; i < investors[_investor].tokensPurchases.length; i++) {
			if (investors[_investor].tokensPurchases[i].value == 0) {
				continue;
			}

			_refundTokensPurchase(_investor, i);
		}

		// forward eth to investor&#39;s wallet address
		_investor.transfer(msg.value);
	}

	function _refundTokensPurchase(address _investor, uint _purchaseId) private {
		// update referrer&#39;s referral tokens
		address referrer = investors[_investor].tokensPurchases[_purchaseId].referrer;
		if (referrer != address(0)) {
			uint256 sentAmount = investors[_investor].tokensPurchases[_purchaseId].referrerSentAmount;
			investors[referrer].referralTokens = investors[referrer].referralTokens.sub(sentAmount);
			bonusTokens = bonusTokens.sub(sentAmount);
		}

		// update investor&#39;s eth amount
		uint256 purchaseValue = investors[_investor].tokensPurchases[_purchaseId].value;
		investors[_investor].contributionInWei = investors[_investor].contributionInWei.sub(purchaseValue);

		// update investor&#39;s purchased tokens
		uint256 purchaseAmount = investors[_investor].tokensPurchases[_purchaseId].amount;
		investors[_investor].purchasedTokens = investors[_investor].purchasedTokens.sub(purchaseAmount);

		// update investor&#39;s bonus tokens
		uint256 bonusAmount = investors[_investor].tokensPurchases[_purchaseId].bonus;
		investors[_investor].bonusTokens = investors[_investor].bonusTokens.sub(bonusAmount);

		// update crowdsale total amount of capital raised
		weiRaised = weiRaised.sub(purchaseValue);
		soldTokens = soldTokens.sub(purchaseAmount);
		bonusTokens = bonusTokens.sub(bonusAmount);

		// free up storage used by transaction
		delete (investors[_investor].tokensPurchases[_purchaseId]);

		// log investor&#39;s tokens purchase refund
		emit TokensPurchaseRefunded(_investor, _purchaseId, purchaseValue, purchaseAmount, bonusAmount, now, msg.sender);
	}

	function getInvestorTokensPurchasesLength(address _investor) public constant returns (uint) {
		return investors[_investor].tokensPurchases.length;
	}

	function getInvestorTokensPurchase(
		address _investor,
		uint _purchaseId
	) external constant returns (
		uint256 value,
		uint256 amount,
		uint256 bonus,
		address referrer,
		uint256 referrerSentAmount
	) {
		value = investors[_investor].tokensPurchases[_purchaseId].value;
		amount = investors[_investor].tokensPurchases[_purchaseId].amount;
		bonus = investors[_investor].tokensPurchases[_purchaseId].bonus;
		referrer = investors[_investor].tokensPurchases[_purchaseId].referrer;
		referrerSentAmount = investors[_investor].tokensPurchases[_purchaseId].referrerSentAmount;
	}

	function pause() external onlyOwner {
		require(!paused);

		paused = true;

		emit Paused(now, msg.sender);
	}

	function resume() external onlyOwner {
		require(paused);

		paused = false;

		emit Resumed(now, msg.sender);
	}

	function finalize() external onlyOwner {
		require(!finalized);

		finalized = true;

		emit Finalized(now, msg.sender);
	}
}

contract DiscountPhases is StaffUtil {
	using SafeMath for uint256;

	event DiscountPhaseAdded(uint index, string name, uint8 percent, uint fromDate, uint toDate, uint timestamp, address byStaff);
	event DiscountPhaseRemoved(uint index, uint timestamp, address byStaff);

	struct DiscountPhase {
		uint8 percent;
		uint fromDate;
		uint toDate;
	}

	DiscountPhase[] public discountPhases;

	constructor(Staff _staffContract) StaffUtil(_staffContract) public {
	}

	function calculateBonusAmount(uint256 _purchasedAmount) public constant returns (uint256) {
		for (uint i = 0; i < discountPhases.length; i++) {
			if (now >= discountPhases[i].fromDate && now <= discountPhases[i].toDate) {
				return _purchasedAmount.mul(discountPhases[i].percent).div(100);
			}
		}
	}

	function addDiscountPhase(string _name, uint8 _percent, uint _fromDate, uint _toDate) public onlyOwnerOrStaff {
		require(bytes(_name).length > 0);
		require(_percent > 0 && _percent <= 100);

		if (now > _fromDate) {
			_fromDate = now;
		}
		require(_fromDate < _toDate);

		for (uint i = 0; i < discountPhases.length; i++) {
			require(_fromDate > discountPhases[i].toDate || _toDate < discountPhases[i].fromDate);
		}

		uint index = discountPhases.push(DiscountPhase({percent : _percent, fromDate : _fromDate, toDate : _toDate})) - 1;

		emit DiscountPhaseAdded(index, _name, _percent, _fromDate, _toDate, now, msg.sender);
	}

	function removeDiscountPhase(uint _index) public onlyOwnerOrStaff {
		require(now < discountPhases[_index].toDate);
		delete discountPhases[_index];
		emit DiscountPhaseRemoved(_index, now, msg.sender);
	}
}

contract DiscountStructs is StaffUtil {
	using SafeMath for uint256;

	address public crowdsale;

	event DiscountStructAdded(
		uint index,
		bytes32 name,
		uint256 tokens,
		uint[2] dates,
		uint256[] fromWei,
		uint256[] toWei,
		uint256[] percent,
		uint timestamp,
		address byStaff
	);
	event DiscountStructRemoved(
		uint index,
		uint timestamp,
		address byStaff
	);
	event DiscountStructUsed(
		uint index,
		uint step,
		address investor,
		uint256 tokens,
		uint timestamp
	);

	struct DiscountStruct {
		uint256 availableTokens;
		uint256 distributedTokens;
		uint fromDate;
		uint toDate;
	}

	struct DiscountStep {
		uint256 fromWei;
		uint256 toWei;
		uint256 percent;
	}

	DiscountStruct[] public discountStructs;
	mapping(uint => DiscountStep[]) public discountSteps;

	constructor(Staff _staffContract) StaffUtil(_staffContract) public {
	}

	modifier onlyCrowdsale() {
		require(msg.sender == crowdsale);
		_;
	}

	function setCrowdsale(Crowdsale _crowdsale) external onlyOwner {
		require(crowdsale == address(0));
		require(_crowdsale.staffContract() == staffContract);
		crowdsale = _crowdsale;
	}

	function getBonus(address _investor, uint256 _purchasedAmount, uint256 _purchasedValue) public onlyCrowdsale returns (uint256) {
		for (uint i = 0; i < discountStructs.length; i++) {
			if (now >= discountStructs[i].fromDate && now <= discountStructs[i].toDate) {

				if (discountStructs[i].distributedTokens >= discountStructs[i].availableTokens) {
					return;
				}

				for (uint j = 0; j < discountSteps[i].length; j++) {
					if (_purchasedValue >= discountSteps[i][j].fromWei
						&& (_purchasedValue < discountSteps[i][j].toWei || discountSteps[i][j].toWei == 0)) {
						uint256 bonus = _purchasedAmount.mul(discountSteps[i][j].percent).div(100);
						if (discountStructs[i].distributedTokens.add(bonus) > discountStructs[i].availableTokens) {
							return;
						}
						discountStructs[i].distributedTokens = discountStructs[i].distributedTokens.add(bonus);
						emit DiscountStructUsed(i, j, _investor, bonus, now);
						return bonus;
					}
				}

				return;
			}
		}
	}

	function calculateBonus(uint256 _purchasedAmount, uint256 _purchasedValue) public constant returns (uint256) {
		for (uint i = 0; i < discountStructs.length; i++) {
			if (now >= discountStructs[i].fromDate && now <= discountStructs[i].toDate) {

				if (discountStructs[i].distributedTokens >= discountStructs[i].availableTokens) {
					return;
				}

				for (uint j = 0; j < discountSteps[i].length; j++) {
					if (_purchasedValue >= discountSteps[i][j].fromWei
						&& (_purchasedValue < discountSteps[i][j].toWei || discountSteps[i][j].toWei == 0)) {
						uint256 bonus = _purchasedAmount.mul(discountSteps[i][j].percent).div(100);
						if (discountStructs[i].distributedTokens.add(bonus) > discountStructs[i].availableTokens) {
							return;
						}
						return bonus;
					}
				}

				return;
			}
		}
	}

	function addDiscountStruct(bytes32 _name, uint256 _tokens, uint[2] _dates, uint256[] _fromWei, uint256[] _toWei, uint256[] _percent) external onlyOwnerOrStaff {
		require(_name.length > 0);
		require(_tokens > 0);
		require(_dates[0] < _dates[1]);
		require(_fromWei.length > 0 && _fromWei.length == _toWei.length && _fromWei.length == _percent.length);

		for (uint j = 0; j < discountStructs.length; j++) {
			require(_dates[0] > discountStructs[j].fromDate || _dates[1] < discountStructs[j].toDate);
		}

		DiscountStruct memory ds = DiscountStruct(_tokens, 0, _dates[0], _dates[1]);
		uint index = discountStructs.push(ds) - 1;

		for (uint i = 0; i < _fromWei.length; i++) {
			require(_fromWei[i] > 0 || _toWei[i] > 0);
			if (_fromWei[i] > 0 && _toWei[i] > 0) {
				require(_fromWei[i] < _toWei[i]);
			}
			require(_percent[i] > 0 && _percent[i] <= 100);
			discountSteps[index].push(DiscountStep(_fromWei[i], _toWei[i], _percent[i]));
		}

		emit DiscountStructAdded(index, _name, _tokens, _dates, _fromWei, _toWei, _percent, now, msg.sender);
	}

	function removeDiscountStruct(uint _index) public onlyOwnerOrStaff {
		require(now < discountStructs[_index].toDate);
		delete discountStructs[_index];
		delete discountSteps[_index];
		emit DiscountStructRemoved(_index, now, msg.sender);
	}
}

contract PromoCodes is StaffUtil {
	using SafeMath for uint256;

	address public crowdsale;

	event PromoCodeAdded(bytes32 indexed code, string name, uint8 percent, uint256 maxUses, uint timestamp, address byStaff);
	event PromoCodeRemoved(bytes32 indexed code, uint timestamp, address byStaff);
	event PromoCodeUsed(bytes32 indexed code, address investor, uint timestamp);

	struct PromoCode {
		uint8 percent;
		uint256 uses;
		uint256 maxUses;
		mapping(address => bool) investors;
	}

	mapping(bytes32 => PromoCode) public promoCodes;

	constructor(Staff _staffContract) StaffUtil(_staffContract) public {
	}

	modifier onlyCrowdsale() {
		require(msg.sender == crowdsale);
		_;
	}

	function setCrowdsale(Crowdsale _crowdsale) external onlyOwner {
		require(crowdsale == address(0));
		require(_crowdsale.staffContract() == staffContract);
		crowdsale = _crowdsale;
	}

	function applyBonusAmount(address _investor, uint256 _purchasedAmount, bytes32 _promoCode) public onlyCrowdsale returns (uint256) {
		if (promoCodes[_promoCode].percent == 0
		|| promoCodes[_promoCode].investors[_investor]
		|| promoCodes[_promoCode].uses == promoCodes[_promoCode].maxUses) {
			return 0;
		}
		promoCodes[_promoCode].investors[_investor] = true;
		promoCodes[_promoCode].uses = promoCodes[_promoCode].uses + 1;
		emit PromoCodeUsed(_promoCode, _investor, now);
		return _purchasedAmount.mul(promoCodes[_promoCode].percent).div(100);
	}

	function calculateBonusAmount(address _investor, uint256 _purchasedAmount, bytes32 _promoCode) public constant returns (uint256) {
		if (promoCodes[_promoCode].percent == 0
		|| promoCodes[_promoCode].investors[_investor]
		|| promoCodes[_promoCode].uses == promoCodes[_promoCode].maxUses) {
			return 0;
		}
		return _purchasedAmount.mul(promoCodes[_promoCode].percent).div(100);
	}

	function addPromoCode(string _name, bytes32 _code, uint256 _maxUses, uint8 _percent) public onlyOwnerOrStaff {
		require(bytes(_name).length > 0);
		require(_code[0] != 0);
		require(_percent > 0 && _percent <= 100);
		require(_maxUses > 0);
		require(promoCodes[_code].percent == 0);

		promoCodes[_code].percent = _percent;
		promoCodes[_code].maxUses = _maxUses;

		emit PromoCodeAdded(_code, _name, _percent, _maxUses, now, msg.sender);
	}

	function removePromoCode(bytes32 _code) public onlyOwnerOrStaff {
		delete promoCodes[_code];
		emit PromoCodeRemoved(_code, now, msg.sender);
	}
}

contract Token is BurnableToken {
}