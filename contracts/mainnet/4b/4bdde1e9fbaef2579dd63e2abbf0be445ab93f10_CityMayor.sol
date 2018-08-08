pragma solidity ^0.4.19;

library SafeMath {

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
 // we don&#39;t need "div"
/*  function div(uint256 a, uint256 b) internal pure returns (uint256) {
  	// assert(b > 0); // Solidity automatically throws when dividing by 0
  	uint256 c = a / b;
  	// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
  	return c;
  }
*/
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
}


contract CityMayor {

	using SafeMath for uint256;

	//
	// ERC-20
	//

   	string public name = "CityCoin";
   	string public symbol = "CITY";
   	uint8 public decimals = 0;

	mapping(address => uint256) balances;

	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	* @dev total number of tokens in existence
	*/
	uint256 totalSupply_;
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

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	mapping (address => mapping (address => uint256)) internal allowed;


	/**
	* @dev Transfer tokens from one address to another
	* @param _from address The address which you want to send tokens from
	* @param _to address The address which you want to transfer to
	* @param _value uint256 the amount of tokens to be transferred
	*/
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		Transfer(_from, _to, _value);
		return true;
	}

	/**
	* @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
	*
	* Beware that changing an allowance with this method brings the risk that someone may use both the old
	* and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
	* race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
	* https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	* @param _spender The address which will spend the funds.
	* @param _value The amount of tokens to be spent.
	*/
	function approve(address _spender, uint256 _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	/**
	* @dev Function to check the amount of tokens that an owner allowed to a spender.
	* @param _owner address The address which owns the funds.
	* @param _spender address The address which will spend the funds.
	* @return A uint256 specifying the amount of tokens still available for the spender.
	*/
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	/**
	* @dev Increase the amount of tokens that an owner allowed to a spender.
	*
	* approve should be called when allowed[_spender] == 0. To increment
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* @param _spender The address which will spend the funds.
	* @param _addedValue The amount of tokens to increase the allowance by.
	*/
	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	/**
	* @dev Decrease the amount of tokens that an owner allowed to a spender.
	*
	* approve should be called when allowed[_spender] == 0. To decrement
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* @param _spender The address which will spend the funds.
	* @param _subtractedValue The amount of tokens to decrease the allowance by.
	*/
	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
			} else {
				allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
			}
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

   	//
   	// Game Meta values
   	//

   	address public unitedNations; // the UN organisation

   	uint16 public MAX_CITIES = 5000; // maximum amount of cities in our world
   	uint256 public UNITED_NATIONS_FUND = 5000000; // initial funding for the UN
   	uint256 public ECONOMY_BOOST = 5000; // minted CITYs when a new city is being bought 

   	uint256 public BUY_CITY_FEE = 3; // UN fee (% of ether) to buy a city from someon / 100e
   	uint256 public ECONOMY_BOOST_TRADE = 100; // _immutable_ gift (in CITY) from the UN when a city is traded (shared among the cities of the relevant country)

   	uint256 public MONUMENT_UN_FEE = 3; // UN fee (CITY) to buy a monument
   	uint256 public MONUMENT_CITY_FEE = 3; // additional fee (CITY) to buy a monument (shared to the monument&#39;s city)

   	//
   	// Game structures
   	//

   	struct country {
   		string name;
   		uint16[] cities;
   	}

   	struct city {
   		string name;
   		uint256 price;
   		address owner;

   		uint16 countryId;
   		uint256[] monuments;

   		bool buyable; // set to true when it can be bought

   		uint256 last_purchase_price;
   	}

   	struct monument {
   		string name;
   		uint256 price;
   		address owner;

   		uint16 cityId;
   	}

   	city[] public cities; // cityId -> city
   	country[] public countries; // countryId -> country
   	monument[] public monuments; // monumentId -> monument

   	// total amount of offers (escrowed money)
	uint256 public totalOffer;

   	//
   	// Game events
   	//


	event NewCity(uint256 cityId, string name, uint256 price, uint16 countryId);
	event NewMonument(uint256 monumentId, string name, uint256 price, uint16 cityId);

	event CityForSale(uint16 cityId, uint256 price);
	event CitySold(uint16 cityId, uint256 price, address previousOwner, address newOwner, uint256 offerId);

	event MonumentSold(uint256 monumentId, uint256 price);

   	// 
   	// Admin stuff
   	//

   	// constructor
   	function CityMayor() public {
   		unitedNations = msg.sender;
   		balances[unitedNations] = UNITED_NATIONS_FUND; // initial funding for the united nations
   		uint256 perFounder = 500000;
   		balances[address(0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b)] = perFounder; // david
   		balances[address(0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4)] = perFounder; // simon
   		balances[address(0xD5d6301dE62D82F461dC29824FC597D38d80c424)] = perFounder; // eric
   		// total supply updated
   		totalSupply_ = UNITED_NATIONS_FUND + 3 * perFounder;
   	}

   	// this function is used to let admins give cities back to owners of previous contracts
   	function AdminBuyForSomeone(uint16 _cityId, address _owner) public {
   		// admin only
   		require(msg.sender == unitedNations);
	   	// fetch
	   	city memory fetchedCity = cities[_cityId];
	   	// requires
		require(fetchedCity.buyable == true);
		require(fetchedCity.owner == 0x0); 
	   	// transfer ownership
	   	cities[_cityId].owner = _owner;
	   	// update city metadata
	   	cities[_cityId].buyable = false;
	   	cities[_cityId].last_purchase_price = fetchedCity.price;
	   	// increase economy of region according to ECONOMY_BOOST
	   	uint16[] memory fetchedCities = countries[fetchedCity.countryId].cities;
	   	uint256 perCityBoost = ECONOMY_BOOST / fetchedCities.length;
	   	for(uint16 ii = 0; ii < fetchedCities.length; ii++){
	   		address _to = cities[fetchedCities[ii]].owner;
	   		if(_to != 0x0) { // MINT only if address exists
	   			balances[_to] = balances[_to].add(perCityBoost);
	   			totalSupply_ += perCityBoost; // update the total supply
	   		}
	   	}
	   	// event
	   	CitySold(_cityId, fetchedCity.price, 0x0, _owner, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);	
   	}

   	// this function allows to make an offer from someone else
	function makeOfferForCityForSomeone(uint16 _cityId, uint256 _price, address from) public payable {
		// only for admins
		require(msg.sender == unitedNations);
		// requires
		require(cities[_cityId].owner != 0x0);
		require(_price > 0);
		require(msg.value >= _price);
		require(cities[_cityId].owner != from);
		// add the offer
		uint256 lastId = offers.push(offer(_cityId, _price, from)) - 1;
		// increment totalOffer
		totalOffer = totalOffer.add(_price);
		// event
		OfferForCity(lastId, _cityId, _price, from, cities[_cityId].owner);
	}

	// withdrawing funds
	function adminWithdraw(uint256 _amount) public {
		require(msg.sender == 0xD5d6301dE62D82F461dC29824FC597D38d80c424 || msg.sender == 0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4 || msg.sender == 0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b || msg.sender == unitedNations);
		// do not touch the escrowed money
		uint256 totalAvailable = this.balance.sub(totalOffer);
		if(_amount > totalAvailable) {
			_amount = totalAvailable;
		}
		// divide the amount for founders
		uint256 perFounder = _amount / 3;
		address(0xD5d6301dE62D82F461dC29824FC597D38d80c424).transfer(perFounder); // eric
		address(0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4).transfer(perFounder); // simon
		address(0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b).transfer(perFounder); // david
	}

	//
	// Admin adding stuff
	//

	// we need to add a country before we can add a city
	function adminAddCountry(string _name) public returns (uint256) {
		// requires
		require(msg.sender == unitedNations);
		// add country
		uint256 lastId = countries.push(country(_name, new uint16[](0))) - 1; 
		//
		return lastId;
	}
	// adding a city will mint ECONOMY_BOOST citycoins (country must exist)
	function adminAddCity(string _name, uint256 _price, uint16 _countryId) public returns (uint256) {
		// requires
		require(msg.sender == unitedNations);
		require(cities.length < MAX_CITIES);
		// add city
		uint256 lastId = cities.push(city(_name, _price, 0, _countryId, new uint256[](0), true, 0)) - 1;
		countries[_countryId].cities.push(uint16(lastId));
		// event
		NewCity(lastId, _name, _price, _countryId);
		//
		return lastId;
	}

	// adding a monument (city must exist)
	function adminAddMonument(string _name, uint256 _price, uint16 _cityId) public returns (uint256) {
		// requires
		require(msg.sender == unitedNations);
		require(_price > 0);
		// add monument
		uint256 lastId = monuments.push(monument(_name, _price, 0, _cityId)) - 1;
		cities[_cityId].monuments.push(lastId);
		// event
		NewMonument(lastId, _name, _price, _cityId);
		//
		return lastId;
	}

	// Edit a city if it hasn&#39;t been bought yet
	function adminEditCity(uint16 _cityId, string _name, uint256 _price, address _owner) public {
		// requires
		require(msg.sender == unitedNations);
		require(cities[_cityId].owner == 0x0);
		//
		cities[_cityId].name = _name;
		cities[_cityId].price = _price;
		cities[_cityId].owner = _owner;
	}

	// 
	// Buy and manage a city
	//

	function buyCity(uint16 _cityId) public payable {
		// fetch
		city memory fetchedCity = cities[_cityId];
		// requires
		require(fetchedCity.buyable == true);
		require(fetchedCity.owner == 0x0); 
		require(msg.value >= fetchedCity.price);
		// transfer ownership
		cities[_cityId].owner = msg.sender;
		// update city metadata
		cities[_cityId].buyable = false;
		cities[_cityId].last_purchase_price = fetchedCity.price;
		// increase economy of region according to ECONOMY_BOOST
		uint16[] memory fetchedCities = countries[fetchedCity.countryId].cities;
		uint256 perCityBoost = ECONOMY_BOOST / fetchedCities.length;
		for(uint16 ii = 0; ii < fetchedCities.length; ii++){
			address _to = cities[fetchedCities[ii]].owner;
			if(_to != 0x0) { // MINT only if address exists
				balances[_to] = balances[_to].add(perCityBoost);
				totalSupply_ += perCityBoost; // update the total supply
			}
		}
		// event
		CitySold(_cityId, fetchedCity.price, 0x0, msg.sender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
	}

	//
	// Economy boost:
	// this is called by functions below that will "buy a city from someone else"
	// it will draw ECONOMY_BOOST_TRADE CITYs from the UN funds and split them in the relevant country
	//

	function economyBoost(uint16 _countryId, uint16 _excludeCityId) private {
		if(balances[unitedNations] < ECONOMY_BOOST_TRADE) {
			return; // unless the UN has no more funds
		}
		uint16[] memory fetchedCities = countries[_countryId].cities;
		if(fetchedCities.length == 1) {
			return;
		}
		uint256 perCityBoost = ECONOMY_BOOST_TRADE / (fetchedCities.length - 1); // excluding the bought city
		for(uint16 ii = 0; ii < fetchedCities.length; ii++){
			address _to = cities[fetchedCities[ii]].owner;
			if(_to != 0x0 && fetchedCities[ii] != _excludeCityId) { // only if address exists AND not the current city
				balances[_to] = balances[_to].add(perCityBoost);
				balances[unitedNations] -= perCityBoost;
			}
		}
	}

	//
	// Sell a city
	//

	// step 1: owner sets buyable = true
	function sellCityForEther(uint16 _cityId, uint256 _price) public {
		// requires
		require(cities[_cityId].owner == msg.sender);
		// for sale
		cities[_cityId].price = _price;
		cities[_cityId].buyable = true;
		// event
		CityForSale(_cityId, _price);
	}

	event CityNotForSale(uint16 cityId);

	// step 2: owner can always cancel 
	function cancelSellCityForEther(uint16 _cityId) public {
		// requires
		require(cities[_cityId].owner == msg.sender);
		//
		cities[_cityId].buyable = false;
		// event
		CityNotForSale(_cityId);
	}

	// step 3: someone else accepts the offer
	function resolveSellCityForEther(uint16 _cityId) public payable {
		// fetch
		city memory fetchedCity = cities[_cityId];
		// requires
		require(fetchedCity.buyable == true);
		require(msg.value >= fetchedCity.price);
		require(fetchedCity.owner != msg.sender);
		// calculate the fee
		uint256 fee = BUY_CITY_FEE.mul(fetchedCity.price) / 100;
		// pay the price
		address previousOwner =	fetchedCity.owner;
		previousOwner.transfer(fetchedCity.price.sub(fee));
		// transfer of ownership
		cities[_cityId].owner = msg.sender;
		// update metadata
		cities[_cityId].buyable = false;
		cities[_cityId].last_purchase_price = fetchedCity.price;
		// increase economy of region
		economyBoost(fetchedCity.countryId, _cityId);
		// event
		CitySold(_cityId, fetchedCity.price, previousOwner, msg.sender, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
	}

	//
	// Make an offer for a city
	//

	struct offer {
		uint16 cityId;
		uint256 price;
		address from;
	}

	offer[] public offers;

	event OfferForCity(uint256 offerId, uint16 cityId, uint256 price, address offererAddress, address owner);
	event CancelOfferForCity(uint256 offerId);

	// 1. we make an offer for some cityId that we don&#39;t own yet (we deposit money in escrow)
	function makeOfferForCity(uint16 _cityId, uint256 _price) public payable {
		// requires
		require(cities[_cityId].owner != 0x0);
		require(_price > 0);
		require(msg.value >= _price);
		require(cities[_cityId].owner != msg.sender);
		// add the offer
		uint256 lastId = offers.push(offer(_cityId, _price, msg.sender)) - 1;
		// increment totalOffer
		totalOffer = totalOffer.add(_price);
		// event
		OfferForCity(lastId, _cityId, _price, msg.sender, cities[_cityId].owner);
	}

	// 2. we cancel it (getting back our money)
	function cancelOfferForCity(uint256 _offerId) public {
		// fetch
		offer memory offerFetched = offers[_offerId];
		// requires
		require(offerFetched.from == msg.sender);
		// refund
		msg.sender.transfer(offerFetched.price);
		// decrement totaloffer
		totalOffer = totalOffer.sub(offerFetched.price);
		// remove offer
		offers[_offerId].cityId = 0;
		offers[_offerId].price = 0;
		offers[_offerId].from = 0x0;
		// event
		CancelOfferForCity(_offerId);
	}

	// 3. the city owner can accept the offer
	function acceptOfferForCity(uint256 _offerId, uint16 _cityId, uint256 _price) public {
		// fetch
		city memory fetchedCity = cities[_cityId];
		offer memory offerFetched = offers[_offerId];
		// requires
		require(offerFetched.cityId == _cityId);
		require(offerFetched.from != 0x0);
		require(offerFetched.from != msg.sender);
		require(offerFetched.price == _price);
		require(fetchedCity.owner == msg.sender);
		// compute the fee
		uint256 fee = BUY_CITY_FEE.mul(_price) / 100;
		// transfer the escrowed money
		uint256 priceSubFee = _price.sub(fee);
		cities[_cityId].owner.transfer(priceSubFee);
		// decrement tracked amount of escrowed ethers
		totalOffer = totalOffer.sub(priceSubFee);
		// transfer of ownership
		cities[_cityId].owner = offerFetched.from;
		// update metadata
		cities[_cityId].last_purchase_price = _price;
		cities[_cityId].buyable = false; // in case it was also set to be purchasable
		// increase economy of region 
		economyBoost(fetchedCity.countryId, _cityId);
		// event
		CitySold(_cityId, _price, msg.sender, offerFetched.from, _offerId);
		// remove offer
		offers[_offerId].cityId = 0;
		offers[_offerId].price = 0;
		offers[_offerId].from = 0x0;
	}

	//
	// in-game use of CITYs
	//

	/* 
   	uint256 public MONUMENT_UN_FEE = 3; // UN fee (CITY) to buy a monument
   	uint256 public MONUMENT_CITY_FEE = 3; // additional fee (CITY) to buy a monument (shared to the monument&#39;s city)
   	*/

	// anyone can buy a monument from someone else (with CITYs)
	function buyMonument(uint256 _monumentId, uint256 _price) public {
		// fetch
		monument memory fetchedMonument = monuments[_monumentId];
		// requires
		require(fetchedMonument.price > 0);
		require(fetchedMonument.price == _price);
		require(balances[msg.sender] >= _price);
		require(fetchedMonument.owner != msg.sender);
		// pay first!
		balances[msg.sender] = balances[msg.sender].sub(_price);
		// compute fee
		uint256 UN_fee = MONUMENT_UN_FEE.mul(_price) / 100;
		uint256 city_fee = MONUMENT_CITY_FEE.mul(_price) / 100;
		// previous owner gets paid
		uint256 toBePaid = _price.sub(UN_fee);
		toBePaid = toBePaid.sub(city_fee);
		balances[fetchedMonument.owner] = balances[fetchedMonument.owner].add(toBePaid);
		// UN gets a fee
		balances[unitedNations] = balances[unitedNations].add(UN_fee);
		// city gets a fee
		address cityOwner = cities[fetchedMonument.cityId].owner;
		balances[cityOwner] = balances[cityOwner].add(city_fee);
		// transfer of ownership
		monuments[_monumentId].owner = msg.sender;
		// price increase of the monument
		monuments[_monumentId].price = monuments[_monumentId].price.mul(2);
		// event
		MonumentSold(_monumentId, _price);
	}

}