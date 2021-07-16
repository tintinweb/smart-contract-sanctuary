//SourceUnit: FragContractFinalFragV5p13p2.sol

pragma solidity ^0.5.8;

library SafeMath {

	/**
	* @dev Returns the lowest value of the two integers
	*/
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}

	/**
	* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function percentageOf(uint256 total, uint256 percentage) internal pure returns (uint256) {
		return div(mul(total, percentage), 100);
	}

	function getPercentage(uint256 total, uint256 piece) internal pure returns (uint256) {
		return div(piece, total);
	}
}

interface Token {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract Protected {
  bool public active = false;
  address payable public ceoAddress;
  mapping (address => bool) public admin;

  function isAdmin (address _adr) public view returns (bool) {
    return admin[_adr];
  }

  function addAdmin (address _adr) external adminOnly {
    admin[_adr] = true;
  }

  function removeAdmin (address _adr) external adminOnly {
    require(_adr != msg.sender, "Action not allowed");
    admin[_adr] = false;
  }

  modifier adminOnly () {
    require(admin[msg.sender] == true, "Unauthorized");
    _;
  }

  modifier activeOnly () {
    require(active == true, "Inactive");
    _;
  }

  constructor () public {
    ceoAddress = msg.sender;
    admin[msg.sender] = true;
  }

  function toggleActive () external adminOnly returns (bool) {
    active = !active;
    return active;
  }

  function getCEOAddress () public view returns (address payable) {
    return ceoAddress;
  }
}


contract Moon is Protected, ApproveAndCallFallBack {

  // ----------------------- Unit System
  struct Unit {
    string name;
    uint256 cookies_per_second;
    uint256 starting_price;
    uint256 price_inc;
    uint256 shares;
    uint256 buy_fee;
    uint256 sell_fee;
    uint256 unlocks_at;
    bool unlocked;
  }

  Token public token;
  uint256 admin_withdrawal_at = 0;

  mapping (uint256 => Unit) private units;
  mapping (uint256 => uint256) private unit_price;
  uint256 private total_units;

  // Dividend System
  mapping (address => uint256) public last_withdraw; // Should probably rename to something that reflects "last withdraw/unclaimed update"
  mapping (address => uint256) public shares;
  mapping (address => uint256) public unclaimed;

  // Dividend System
  uint256 public pot = 0; // We'll get back to this later
  uint256 public legacy_pot = 0;
  uint256 public total_shares = 0;
  uint256 private precision_multiplier = 1000000;

  // Buying
  address payable private dev_lax;
  address payable private dev_math;
  address payable private marketer1;
  address payable private marketer2;
  uint256 private dfp_buy = 1; // 0.5 each dev
  uint256 private mfp_buy = 1; // 0.5 each marketer
  uint256 private dfp_sell = 3; // 1.5 each dev
  uint256 private rfp_buy = 3; // referrer
  uint256 private rfp_sell = 3; // referrer

  // Charity
  mapping (address => uint256) public donations;
  address public top_donater;
  uint256 public top_donater_value;


  // --------------------- Unit Data System
  mapping (uint256 => mapping (address => uint256)) private unit;
  mapping (uint256 => uint256) private unit_count;
  mapping (address => uint256) private cookies;
  mapping (address => uint256) private production_start;
  uint256 public total_produced_cookies = 0;
  uint256 public total_sold_cookies = 0;
  uint256 public last_update = 0;

  // Dividend System
  event Withdraw (address user, uint256 value, uint256 timestamp);
  event Deposit (address user, uint256 value, uint256 bought_shares, uint256 timestamp);
  event Remove (address user, uint256 sold_shares, uint256 timestamp);

  constructor (
    address payable _dev_lax,
    address payable _dev_math,
    address payable _marketer1,
    address payable _marketer2,
    address _token
  ) Protected() public {
    dev_lax = _dev_lax;
    dev_math = _dev_math;
    marketer1 = _marketer1;
    marketer2 = _marketer2;
    token = Token(_token);
    admin_withdrawal_at = SafeMath.add(now, SafeMath.mul(86400, 365)); // 86400 = 1 day in seconds, 365 = days in a year

    // Add units
    addUnit("unitone", 1, 500000000000000, 7550000, 1, 5, 10, 176400, true);
    addUnit("unittwo", 6, 2500000000000000, 250000000, 4, 7, 10, 608400, true);
    addUnit("unitthree", 15, 5000000000000000, 125000000, 5, 13, 7, 1213200, true);
    addUnit("unitfour", 24, 10000000000000000, 400000000, 11, 15, 10, 1818000, true);
  }

  function canAdminWithdraw () public view returns (bool) {
    return (now >= admin_withdrawal_at);
  }

  // -------------------- Dividend System

  function update (address user) internal {
    // Update share related stuff
    unclaimed[user] = SafeMath.add(unclaimed[user], calculateGains(user));
    last_withdraw[user] = legacy_pot;

    // Update cookie production stuff
    cookies[user] = SafeMath.add(cookies[user], getProducedCookiesForPlayer(user));
    production_start[user] = now;

    // Tracking max cookies
    total_produced_cookies = SafeMath.add(total_produced_cookies, calculateProducedCookiesSinceLastUpdate());
    last_update = now;
  }

  function getTotalUnits () public view returns (uint256) {
    return total_units;
  }

  function calculateProducedCookiesSinceLastUpdate() internal view returns (uint256) {
    if (last_update == 0) {
      return 0;
    }
    uint256 cps = 0;
    uint256 total_unit_count = getTotalUnits();

    for (uint8 i = 0; i < total_unit_count; i++) {
      if (unit_count[i] > 0) {
        uint256 cookies_per_second = getUnitCookiesPerSecond(i);
        uint256 total_cookies_per_second = SafeMath.mul(cookies_per_second, unit_count[i]);
        cps = SafeMath.add(cps, total_cookies_per_second);
      }
    }

    uint256 produced_time = SafeMath.sub(now, last_update);
    uint256 produced = SafeMath.mul(cps, produced_time);
    return produced;
  }

  function getTotalProducedCookies() public view returns (uint256) {
    return SafeMath.add(total_produced_cookies, calculateProducedCookiesSinceLastUpdate());
  }

  function getTotalCookiesInExistence() public view returns (uint256) {
    return SafeMath.sub(getTotalProducedCookies(), total_sold_cookies);
  }

  function calculateGains (address user) public view returns (uint256) {
    uint256 available_pot = SafeMath.sub(legacy_pot, last_withdraw[user]);
    if (available_pot == 0 || shares[user] == 0) {
      return 0;
    }
    uint256 p_in_m = SafeMath.div(SafeMath.mul(shares[user], precision_multiplier), total_shares);
    uint256 gains = SafeMath.div(SafeMath.mul(p_in_m, available_pot), precision_multiplier);

    return gains;
  }

  function depositSharesForPlayer (address player, uint256 value, uint256 bought_shares) internal {
    require (value > 0, "Invalid amount");
    require (bought_shares > 0, "Invalid amount of shares");
    // Ensure previous gains are calculated and stored
    update(player);

    pot = SafeMath.add(pot, value);
    legacy_pot = SafeMath.add(legacy_pot, value);
    total_shares = SafeMath.add(total_shares, bought_shares);
    shares[player] = SafeMath.add(shares[player], bought_shares);

    emit Deposit(player, value, bought_shares, now);
  }

  function removeSharesForPlayer (address player, uint256 sold_shares) private {
    require (sold_shares > 0, "Invalid amount of shares");
    // Ensure previous gains are calculated and stored
    update(player);

    total_shares = SafeMath.sub(total_shares, sold_shares);
    shares[player] = SafeMath.sub(shares[player], sold_shares);

    emit Remove(player, sold_shares, now);
  }

  function withdrawGains () external {
    // Calculate total gains (previously unclaimed + gains since last calculation)
    uint256 total_gains = SafeMath.add(unclaimed[msg.sender], calculateGains(msg.sender));

    // Ensure there are funds to withdraw
    assert (total_gains > 0);
    assert (pot >= total_gains);

    // Withdraw from dividend pot
    pot = SafeMath.sub(pot, total_gains);

    // Reset user stats to reflect a withdrawal
    unclaimed[msg.sender] = 0;
    last_withdraw[msg.sender] = legacy_pot;

    // Transfer funds
    token.transfer(msg.sender, total_gains);

    emit Withdraw(msg.sender, total_gains, now);
  }

  function getUnitName(uint256 unit_id) public view returns (string memory) {
    return units[unit_id].name;
  }

  function getUnitPrice(uint256 unit_id) public view returns (uint256) {
    if (unit_price[unit_id] == 0) {
      return units[unit_id].starting_price;
    }

    return unit_price[unit_id];
  }

  function getUnitPriceInc(uint256 unit_id) public view returns (uint256) {
    return units[unit_id].price_inc;
  }

  function getUnitBuyFee(uint256 unit_id) public view returns (uint256) {
    return units[unit_id].buy_fee;
  }

  function getUnitSellFee(uint256 unit_id) public view returns (uint256) {
    return units[unit_id].sell_fee;
  }

  function getUnitCookiesPerSecond(uint256 unit_id) public view returns (uint256) {
    return units[unit_id].cookies_per_second;
  }

  function getUnitSharesById(uint256 unit_id) public view returns (uint256) {
    return units[unit_id].shares;
  }

  function setUnitPrice(uint256 unit_id, uint256 _unit_price) internal {
    unit_price[unit_id] = _unit_price;
  }

  function getUnitUnlocksAt(uint256 unit_id) public view returns (uint256) {
    return units[unit_id].unlocks_at;
  }

  function isUnitUnlocked(uint256 unit_id) public view returns (bool) {
    if (!units[unit_id].unlocked) {
      return false;
    }

    if (getUnitUnlocksAt(unit_id) < now) {
      return true;
    }

    return false;
  }

  function getUnit(uint256 unit_id) public view returns (
    string memory,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    bool
  ) {
    Unit memory u = units[unit_id];
    return (u.name, u.cookies_per_second, u.starting_price, u.price_inc, u.shares, u.buy_fee, u.sell_fee, u.unlocks_at, u.unlocked);
  }

  function addUnit(
    string memory name,
    uint256 cookies_per_second,
    uint256 starting_price,
    uint256 price_inc,
    uint256 shares_per_unit,
    uint256 buy_fee,
    uint256 sell_fee,
    uint256 unlocks_at,
    bool unlocked
  ) private {
    // Create Unit
    uint256 unlocks = SafeMath.add(now, unlocks_at);
    units[total_units] = Unit({
      name:name,
      cookies_per_second:cookies_per_second,
      starting_price:starting_price,
      price_inc:price_inc,
      shares:shares_per_unit,
      buy_fee:buy_fee,
      sell_fee:sell_fee,
      unlocks_at:unlocks,
      unlocked:unlocked
    });

    // Update total units
    total_units = SafeMath.add(total_units, 1);
  }

  // -------------------- Banking System
  uint256 private cookie_pot;
  mapping (uint256 => uint256) private unit_pot;

  function getUnitPot (uint256 unit_id) public view returns (uint256) {
    return unit_pot[unit_id];
  }

  function getCookiePot () public view returns (uint256) {
    return cookie_pot;
  }

  function depositToCookiePot (uint256 value) private returns (bool) {
    require(value > 0, "Invalid amount");
    cookie_pot = SafeMath.add(cookie_pot, value);
    return true;
  }

  function depositToUnitPot (uint256 unit_id, uint256 value) private returns (bool) {
    require(value > 0, "Invalid amount");
    unit_pot[unit_id] = SafeMath.add(unit_pot[unit_id], value);
    return true;
  }

  function withdrawFromCookiePot (address payable _to, uint256 amount) external adminOnly returns (bool) {
    require (canAdminWithdraw(), "Admin withdrawal not allowed yet");
    require (amount > 0, "Invalid amount");
    require (amount <= getCookiePot(), "Insufficient funds");

    cookie_pot = SafeMath.sub(cookie_pot, amount);
    token.transfer(_to, amount);

    return true;
  }

  function withdrawFromUnitPot (address payable _to, uint256 unit_id, uint256 amount) internal returns (bool) {
    require (amount > 0, "Invalid amount");
    require (amount <= getUnitPot(unit_id), "Insufficient funds");

    unit_pot[unit_id] = SafeMath.sub(unit_pot[unit_id], amount);
    token.transfer(_to, amount);

    return true;
  }

  function getPlayerUnitsById(uint256 unit_id, address player) public view returns (uint256) {
    return unit[unit_id][player];
  }

  function getUnitCountById(uint256 unit_id) public view returns (uint256) {
    return unit_count[unit_id];
  }

  function getProductionStartForPlayer(address player) public view returns (uint256) {
    return production_start[player];
  }

  function setTotalUnitCount(uint256 unit_id, uint256 count) internal {
    require (count >= 0, 'Invalid count');
    unit_count[unit_id] = count;
  }

  function setUnitsForPlayer(uint256 unit_id, address player, uint256 value) internal {
    require (value >= 0, "Invalid value");
    unit[unit_id][player] = value;

    assert (unit[unit_id][player] == value);
  }

  function getOldProducedCookiesForPlayer(address player) public view returns (uint256) {
    uint256 production_from = getProductionStartForPlayer(player);
    if (production_from == 0) {
      return 0;
    }
    uint256 total_unit_count = getTotalUnits();
    uint256 produced_time = SafeMath.sub(now, production_from);
    uint256 produced = 0;

    for (uint8 i = 0; i < total_unit_count; i++) {
      if (unit[i][player] > 0) {
        uint256 cookies_per_second = getUnitCookiesPerSecond(i);
        uint256 produced_cookies = SafeMath.mul(cookies_per_second, produced_time);
        produced = SafeMath.add(produced, produced_cookies);
      }
    }

    return produced;
  }

  function getCookiesPerSecondForPlayerUnit(address player, uint256 unit_id) public view returns (uint256) {
    return SafeMath.mul(getUnitCookiesPerSecond(unit_id), getPlayerUnitsById(unit_id, player));
  }

  function getCookiesPerSecondForPlayer(address player) public view returns (uint256) {
    uint256 cps = 0;
    uint256 total_unit_count = getTotalUnits();
    for (uint8 i = 0; i < total_unit_count; i++) {
      if (unit[i][player] > 0) {
        cps = SafeMath.add(cps, SafeMath.mul(getUnitCookiesPerSecond(i), getPlayerUnitsById(i, player)));
      }
    }

    return cps;
  }

  function getProducedCookiesForPlayer(address player) public view returns (uint256) {
    uint256 production_from = getProductionStartForPlayer(player);
    if (production_from == 0) {
      return 0;
    }
    uint256 total_unit_count = getTotalUnits();
    uint256 produced_time = SafeMath.sub(now, production_from);
    uint256 produced = 0;

    for (uint8 i = 0; i < total_unit_count; i++) {
      if (unit[i][player] > 0) {
        uint256 cookies_per_second = SafeMath.mul(getUnitCookiesPerSecond(i), getPlayerUnitsById(i, player));
        uint256 produced_cookies = SafeMath.mul(cookies_per_second, produced_time);
        produced = SafeMath.add(produced, produced_cookies);
      }
    }

    return produced;
  }

  function getPlayerCookies(address player) public view returns (uint256) {
    uint256 cookies_on_hand = cookies[player];
    uint256 produced_cookies = getProducedCookiesForPlayer(player);
    // Add produced cookies
    uint256 total_cookies = SafeMath.add(cookies_on_hand, produced_cookies);
    return total_cookies;
  }

  function setCookiesForPlayer(address player, uint256 value) internal {
    require (value >= 0, "Invalid value");
    cookies[player] = value;

    assert (cookies[player] == value);
  }

  function calculateBoughtUnits(uint256 unit_id, uint256 value) public view returns (uint256) {
    return SafeMath.div(SafeMath.sub(value, SafeMath.div(value, 100)), getUnitPrice(unit_id));
  }

  function calculateNewUnitPric (uint256 unit_id, uint256 value) public view returns (uint256) {
    return SafeMath.add(SafeMath.mul(calculateBoughtUnits(unit_id, value), getUnitPriceInc(unit_id)), getUnitPrice(unit_id));
  }

  function calculateNewPlayerUnits(uint256 unit_id, uint256 value, address player) public view returns (uint256) {
    return SafeMath.add(calculateBoughtUnits(unit_id, value), getPlayerUnitsById(unit_id, player));
  }

  function calculateSharesBought(uint256 unit_id, uint256 value) public view returns (uint256) {
    return SafeMath.mul(calculateBoughtUnits(unit_id, value), getUnitSharesById(unit_id));
  }

  function calculateTotalBuyFees(uint256 unit_id, uint256 value) public view returns (uint256) {
    uint256 df = SafeMath.percentageOf(value, dfp_buy);
    uint256 mf = SafeMath.percentageOf(value, mfp_buy);
    uint256 rf = SafeMath.percentageOf(value, rfp_buy);
    uint256 for_cookie_and_unit_divs = SafeMath.percentageOf(value, getUnitBuyFee(unit_id));
    return SafeMath.add(
                          df,
                          SafeMath.add(
                            SafeMath.add(mf, rf),
                            for_cookie_and_unit_divs
                          ));
  }

  function calculateForUnitPot(uint256 unit_id, uint256 value) public view returns (uint256) {
    uint256 total_fees = calculateTotalBuyFees(unit_id, value);
    return SafeMath.sub(value, total_fees);
  }

  function handleBuyUnits (address player, uint256 value, uint256 unit_id, uint256 for_shares) internal {
    uint256 bought_units = SafeMath.div(value, getUnitPrice(unit_id));
    uint256 new_unit_price = SafeMath.add(SafeMath.mul(bought_units, getUnitPriceInc(unit_id)), getUnitPrice(unit_id));
    uint256 player_units = SafeMath.add(bought_units, getPlayerUnitsById(unit_id, player));
    uint256 shares_bought = SafeMath.mul(bought_units, getUnitSharesById(unit_id));
    uint256 new_unit_count = SafeMath.add(getUnitCountById(unit_id), bought_units);

    depositSharesForPlayer(player, for_shares, shares_bought);
    setUnitPrice(unit_id, new_unit_price);
    setTotalUnitCount(unit_id, new_unit_count);
    setUnitsForPlayer(unit_id, player, player_units);
  }

  function parseUnitIdFromBytes(bytes memory data) public pure returns (uint256) {
    uint256 parsed;
    assembly {parsed := mload(add(data, 32))}
    return parsed;
  }

  function parseRefAdrFromBytes(bytes memory data) public pure returns (address) {
    address parsed;
    assembly {parsed := mload(add(data, 64))}
    return parsed;
  }

  // Will act as the token approach to buying units
  function receiveApproval(address from, uint256 tokens, address _token, bytes calldata data) external {
    require(_token == address(token), "Unauthorized");
    uint256 unit_id = parseUnitIdFromBytes(data);
    require(isUnitUnlocked(unit_id), 'Unit locked');
    address ref = parseRefAdrFromBytes(data);

    // Transfer tokens here
    assert(token.transferFrom(from, address(this), tokens));

    // Remove burn from tokens
    uint256 tokensMinusBurn = SafeMath.sub(tokens, SafeMath.div(tokens, 100));

    // Handle charity - unit_id 4
    if (unit_id >= 4) {
      depositToCookiePot(tokensMinusBurn);
      donations[from] = SafeMath.add(donations[from], tokensMinusBurn);
      if (donations[from] > top_donater_value) {
        top_donater = from;
        top_donater_value = donations[from];
      }
      return;
    }

    // Make all monetary calculations
    uint256 df = SafeMath.percentageOf(tokensMinusBurn, dfp_buy);
    uint256 mf = SafeMath.percentageOf(tokensMinusBurn, mfp_buy);
    uint256 rf = SafeMath.percentageOf(tokensMinusBurn, rfp_buy);
    uint256 for_cookie_and_unit_divs = SafeMath.percentageOf(tokensMinusBurn, getUnitBuyFee(unit_id));
    uint256 total_fees = SafeMath.add(
                          df,
                          SafeMath.add(
                            SafeMath.add(mf, rf),
                            for_cookie_and_unit_divs
                          ));
    uint256 for_pots = SafeMath.div(for_cookie_and_unit_divs, 2);
    uint256 for_unit_pot = SafeMath.sub(tokensMinusBurn, total_fees);

    handleBuyUnits(from, tokensMinusBurn, unit_id, for_pots);
    depositToCookiePot(for_pots);
    depositToUnitPot(unit_id, for_unit_pot);

    // Distribute funds
    token.transfer(dev_lax, SafeMath.div(df, 2));
    token.transfer(dev_math, SafeMath.div(df, 2));
    token.transfer(marketer1, SafeMath.div(mf, 2));
    token.transfer(marketer2, SafeMath.div(mf, 2));

    // Handle no ref
    if (ref == address(this) || ref == address(0)) {
      depositToCookiePot(rf);
    } else {
      token.transfer(ref, rf);
    }
  }

  function calculateSellPricePerUnitWithFees(uint256 unit_id) public view returns (uint256) {
    return SafeMath.div(getUnitPot(unit_id), getUnitCountById(unit_id));
  }

  function calculateUnitSellAllValueWithFees(uint256 unit_id, address payable player) public view returns (uint256) {
    uint256 units_count = getPlayerUnitsById(unit_id, player);
    uint256 price_per_unit = calculateSellPricePerUnitWithFees(unit_id);
    return SafeMath.mul(units_count, price_per_unit);
  }

  function calculateUnitSellValueWithFees(uint256 unit_id, uint256 amount) public view returns (uint256) {
    uint256 price_per_unit = calculateSellPricePerUnitWithFees(unit_id);
    return SafeMath.mul(amount, price_per_unit);
  }

  function handleSellUnits (uint256 unit_id, address player, uint256 sold_units) internal {
    uint256 sold_shares = SafeMath.mul(sold_units, getUnitSharesById(unit_id));
    uint256 new_unit_price = SafeMath.sub(getUnitPrice(unit_id), SafeMath.mul(sold_units, getUnitPriceInc(unit_id)));
    uint256 new_unit_count = SafeMath.sub(getUnitCountById(unit_id), sold_units);
    uint256 new_player_unit_count = SafeMath.sub(getPlayerUnitsById(unit_id, player), sold_units);

    removeSharesForPlayer(player, sold_shares);
    setUnitPrice(unit_id, new_unit_price);
    setTotalUnitCount(unit_id, new_unit_count);
    setUnitsForPlayer(unit_id, player, new_player_unit_count);
  }

  function handleSellAllUnits (uint256 unit_id, address player) internal {
    uint256 sold_units = getPlayerUnitsById(unit_id, player);
    uint256 sold_shares = SafeMath.mul(sold_units, getUnitSharesById(unit_id));
    uint256 new_unit_price = SafeMath.sub(getUnitPrice(unit_id), SafeMath.mul(sold_units, getUnitPriceInc(unit_id)));
    uint256 new_unit_count = SafeMath.sub(getUnitCountById(unit_id), sold_units);

    removeSharesForPlayer(player, sold_shares);
    setUnitPrice(unit_id, new_unit_price);
    setTotalUnitCount(unit_id, new_unit_count);
    setUnitsForPlayer(unit_id, player, 0);
  }

  /*
   * This function should do the following:
   * It should stop the cookie production where it is
   * It should distribute dev fees
   * It should update & distribute shares
   */
  function sellUnits (uint256 unit_id, uint256 amount, address payable ref) external returns (bool) {
    require(isUnitUnlocked(unit_id), 'Unit locked');
    require(amount <= getPlayerUnitsById(unit_id, msg.sender), 'Invalid amount');
    // Make all monetary calculations
    uint256 value = calculateUnitSellValueWithFees(unit_id, amount);
    uint256 df = SafeMath.percentageOf(value, dfp_sell);
    uint256 rf = SafeMath.percentageOf(value, rfp_sell);
    uint256 for_cookie_and_unit_divs = SafeMath.percentageOf(value, getUnitSellFee(unit_id));
    uint256 for_cookie_pot = SafeMath.div(for_cookie_and_unit_divs, 2);

    uint256 total_fees = SafeMath.add(
                          df,
                          SafeMath.add(
                            rf,
                            for_cookie_and_unit_divs
                          ));
    uint256 value_dist = SafeMath.sub(value, total_fees);

    handleSellUnits(unit_id, msg.sender, amount);
    depositToCookiePot(for_cookie_pot);
    withdrawFromUnitPot(msg.sender, unit_id, value_dist);

    // Distribute funds
    token.transfer(dev_lax, SafeMath.div(df, 2));
    token.transfer(dev_math, SafeMath.div(df, 2));

    // Handle no ref
    if (ref == address(this) || ref == address(0)) {
      depositToCookiePot(rf);
    } else {
      token.transfer(ref, rf);
    }

    return true;
  }

  function sellAllUnits (uint256 unit_id, address payable ref) external returns (bool) {
    require(isUnitUnlocked(unit_id), 'Unit locked');
    // Make all monetary calculations
    uint256 value = calculateUnitSellAllValueWithFees(unit_id, msg.sender);
    uint256 df = SafeMath.percentageOf(value, dfp_sell);
    uint256 rf = SafeMath.percentageOf(value, rfp_sell);
    uint256 for_cookie_and_unit_divs = SafeMath.percentageOf(value, getUnitSellFee(unit_id));
    uint256 for_cookie_pot = SafeMath.div(for_cookie_and_unit_divs, 2);

    uint256 total_fees = SafeMath.add(
                          df,
                          SafeMath.add(
                            rf,
                            for_cookie_and_unit_divs
                          ));
    uint256 value_dist = SafeMath.sub(value, total_fees);

    handleSellAllUnits(unit_id, msg.sender);
    depositToCookiePot(for_cookie_pot);
    withdrawFromUnitPot(msg.sender, unit_id, value_dist);

    // Distribute funds
    token.transfer(dev_lax, SafeMath.div(df, 2));
    token.transfer(dev_math, SafeMath.div(df, 2));

    // Handle no ref
    if (ref == address(this) || ref == address(0)) {
      depositToCookiePot(rf);
    } else {
      token.transfer(ref, rf);
    }

    return true;
  }

  function calculateCookieValue (uint256 cookie_count) public view returns (uint256) {
    if (cookie_count == 0) {
      return 0;
    }
    uint256 total_cookies_in_existence = getTotalCookiesInExistence();
    uint256 available_pot = SafeMath.percentageOf(cookie_pot, 10);
    uint256 cookie_p = SafeMath.div(SafeMath.mul(precision_multiplier, cookie_count), total_cookies_in_existence);
    uint256 p_value = SafeMath.mul(available_pot, cookie_p);
    uint256 value = SafeMath.div(p_value, precision_multiplier);
    if (value > cookie_pot) {
      return cookie_pot;
    }
    return value;
  }

  function calculateCookieValueForPlayer() external view returns (uint256) {
    return calculateCookieValue(getPlayerCookies(msg.sender));
  }

  function sellCookies() external returns (bool) {
    uint256 produced_cookies = getPlayerCookies(msg.sender);
    uint256 cookie_value = calculateCookieValue(produced_cookies);
    assert(cookie_value > 0);

    cookies[msg.sender] = 0;
    production_start[msg.sender] = now;
    cookie_pot = SafeMath.sub(cookie_pot, cookie_value);
    total_sold_cookies = SafeMath.add(total_sold_cookies, produced_cookies);

    token.transfer(msg.sender, cookie_value);

    return true;
  }
}