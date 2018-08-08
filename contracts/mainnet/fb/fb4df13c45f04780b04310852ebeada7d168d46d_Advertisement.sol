pragma solidity ^0.4.8;


contract AppCoins {
    mapping (address => mapping (address => uint256)) public allowance;
    function balanceOf (address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
}


/**
 * The Advertisement contract collects campaigns registered by developers
 * and executes payments to users using campaign registered applications
 * after proof of Attention.
 */
contract Advertisement {

	struct Filters {
		string countries;
		string packageName;
		uint[] vercodes;
	}

	struct ValidationRules {
		bool vercode;
		bool ipValidation;
		bool country;
		uint constipDailyConversions;
		uint walletDailyConversions;
	}

	struct Campaign {
		bytes32 bidId;
		uint price;
		uint budget;
		uint startDate;
		uint endDate;
		string ipValidator;
		bool valid;
		address  owner;
		Filters filters;
	}

	ValidationRules public rules;
	bytes32[] bidIdList;
	mapping (bytes32 => Campaign) campaigns;
	mapping (bytes => bytes32[]) campaignsByCountry;
	AppCoins appc;
	bytes2[] countryList;
    address public owner;
	mapping (address => mapping (bytes32 => bool)) userAttributions;



	// This notifies clients about a newly created campaign
	event CampaignCreated(bytes32 bidId, string packageName,
							string countries, uint[] vercodes,
							uint price, uint budget,
							uint startDate, uint endDate);

	event PoARegistered(bytes32 bidId, string packageName,
						uint64[] timestampList,uint64[] nonceList,
						string walletName);

    /**
    * Constructor function
    *
    * Initializes contract with default validation rules
    */
    function Advertisement () public {
        rules = ValidationRules(false, true, true, 2, 1);
        owner = msg.sender;
        appc = AppCoins(0x1a7a8bd9106f2b8d977e08582dc7d24c723ab0db);
    }


	/**
	* Creates a campaign for a certain package name with
	* a defined price and budget and emits a CampaignCreated event
	*/
	function createCampaign (string packageName, string countries,
							uint[] vercodes, uint price, uint budget,
							uint startDate, uint endDate) external {
		Campaign memory newCampaign;
		newCampaign.filters.packageName = packageName;
		newCampaign.filters.countries = countries;
		newCampaign.filters.vercodes = vercodes;
		newCampaign.price = price;
		newCampaign.startDate = startDate;
		newCampaign.endDate = endDate;

		//Transfers the budget to contract address
        require(appc.allowance(msg.sender, address(this)) >= budget);

        appc.transferFrom(msg.sender, address(this), budget);

		newCampaign.budget = budget;
		newCampaign.owner = msg.sender;
		newCampaign.valid = true;
		newCampaign.bidId = uintToBytes(bidIdList.length);
		addCampaign(newCampaign);

		CampaignCreated(
			newCampaign.bidId,
			packageName,
			countries,
			vercodes,
			price,
			budget,
			startDate,
			endDate);

	}

	function addCampaign(Campaign campaign) internal {
		//Add to bidIdList
		bidIdList.push(campaign.bidId);
		//Add to campaign map
		campaigns[campaign.bidId] = campaign;

		//Assuming each country is represented in ISO country codes
		bytes memory country =  new bytes(2);
		bytes memory countriesInBytes = bytes(campaign.filters.countries);
		uint countryLength = 0;

		for (uint i=0; i<countriesInBytes.length; i++){

			//if &#39;,&#39; is found, new country ahead
			if(countriesInBytes[i]=="," || i == countriesInBytes.length-1){

				if(i == countriesInBytes.length-1){
					country[countryLength]=countriesInBytes[i];
				}

				addCampaignToCountryMap(campaign,country);

				country =  new bytes(2);
				countryLength = 0;
			} else {
				country[countryLength]=countriesInBytes[i];
				countryLength++;
			}
		}

	}


	function addCampaignToCountryMap (Campaign newCampaign,bytes country) internal {
		// Adds a country to countryList if the country is not in this list
		if (campaignsByCountry[country].length == 0){
			bytes2 countryCode;
			assembly {
			       countryCode := mload(add(country, 32))
			}

			countryList.push(countryCode);
		}

		//Adds Campaign to campaignsByCountry map
		campaignsByCountry[country].push(newCampaign.bidId);

	}

	function registerPoA (string packageName, bytes32 bidId,
						uint64[] timestampList, uint64[] nonces,
						address appstore, address oem,
						string walletName) external {

        require (isCampaignValid(bidId));
		require (timestampList.length == nonces.length);
		//Expect ordered array arranged in ascending order
		for(uint i = 0; i < timestampList.length-1; i++){
		        uint timestamp_diff = (timestampList[i+1]-timestampList[i]);
			require((timestamp_diff / 1000) == 10);
		}

		verifyNonces(bytes(packageName),timestampList,nonces);

		require(!userAttributions[msg.sender][bidId]);
		//atribute
		userAttributions[msg.sender][bidId] = true;

		payFromCampaign(bidId,appstore, oem);

		PoARegistered(bidId,packageName,timestampList,nonces, walletName);
	}

	function cancelCampaign (bytes32 bidId) external {
		address campaignOwner = getOwnerOfCampaign(bidId);

		// Only contract owner or campaign owner can cancel a campaign
		require (owner == msg.sender || campaignOwner == msg.sender);
		uint budget = getBudgetOfCampaign(bidId);

		appc.transfer(campaignOwner, budget);

		setBudgetOfCampaign(bidId,0);
		setCampaignValidity(bidId,false);



	}

	function setBudgetOfCampaign (bytes32 bidId, uint budget) internal {
		campaigns[bidId].budget = budget;
	}

	function setCampaignValidity (bytes32 bidId, bool val) internal {
		campaigns[bidId].valid = val;
	}

	function getCampaignValidity(bytes32 bidId) public view returns(bool){
		return campaigns[bidId].valid;
	}


	function getCountryList () public view returns(bytes2[]) {
			return countryList;
	}

	function getCampaignsByCountry(string country)
			public view returns (bytes32[]){
		bytes memory countryInBytes = bytes(country);

		return campaignsByCountry[countryInBytes];
	}


	function getTotalCampaignsByCountry (string country)
			public view returns (uint){
		bytes memory countryInBytes = bytes(country);

		return campaignsByCountry[countryInBytes].length;
	}

	function getPackageNameOfCampaign (bytes32 bidId)
			public view returns(string) {

		return campaigns[bidId].filters.packageName;
	}

	function getCountriesOfCampaign (bytes32 bidId)
			public view returns(string){

		return campaigns[bidId].filters.countries;
	}

	function getVercodesOfCampaign (bytes32 bidId)
			public view returns(uint[]) {

		return campaigns[bidId].filters.vercodes;
	}

	function getPriceOfCampaign (bytes32 bidId)
			public view returns(uint) {

		return campaigns[bidId].price;
	}

	function getStartDateOfCampaign (bytes32 bidId)
			public view returns(uint) {

		return campaigns[bidId].startDate;
	}

	function getEndDateOfCampaign (bytes32 bidId)
			public view returns(uint) {

		return campaigns[bidId].endDate;
	}

	function getBudgetOfCampaign (bytes32 bidId)
			public view returns(uint) {

		return campaigns[bidId].budget;
	}

	function getOwnerOfCampaign (bytes32 bidId)
			public view returns(address) {

		return campaigns[bidId].owner;
	}

	function getBidIdList ()
			public view returns(bytes32[]) {
		return bidIdList;
	}

    function isCampaignValid(bytes32 bidId) public view returns(bool) {
        Campaign storage campaign = campaigns[bidId];
        uint nowInMilliseconds = now * 1000;
        return campaign.valid && campaign.startDate < nowInMilliseconds && campaign.endDate > nowInMilliseconds;
	}

	function payFromCampaign (bytes32 bidId, address appstore, address oem)
			internal{
		uint dev_share = 85;
                uint appstore_share = 10;
                uint oem_share = 5;

		//Search bid price
		Campaign storage campaign = campaigns[bidId];

		require (campaign.budget > 0);
		require (campaign.budget >= campaign.price);

		//transfer to user, appstore and oem
		appc.transfer(msg.sender, division(campaign.price * dev_share,100));
		appc.transfer(appstore, division(campaign.price * appstore_share,100));
		appc.transfer(oem, division(campaign.price * oem_share,100));

		//subtract from campaign
		campaign.budget -= campaign.price;
	}

	function verifyNonces (bytes packageName,uint64[] timestampList, uint64[] nonces) internal {

		for(uint i = 0; i < nonces.length; i++){
			bytes8 timestamp = bytes8(timestampList[i]);
			bytes8 nonce = bytes8(nonces[i]);
			bytes memory byteList = new bytes(packageName.length + timestamp.length);

			for(uint j = 0; j < packageName.length;j++){
				byteList[j] = packageName[j];
			}

			for(j = 0; j < timestamp.length; j++ ){
				byteList[j + packageName.length] = timestamp[j];
			}

			bytes32 result = sha256(byteList);

			bytes memory noncePlusHash = new bytes(result.length + nonce.length);

			for(j = 0; j < nonce.length; j++){
				noncePlusHash[j] = nonce[j];
			}

			for(j = 0; j < result.length; j++){
				noncePlusHash[j + nonce.length] = result[j];
			}

			result = sha256(noncePlusHash);

			bytes2[1] memory leadingBytes = [bytes2(0)];
			bytes2 comp = 0x0000;

			assembly{
				mstore(leadingBytes,result)
			}

			require(comp == leadingBytes[0]);

		}
	}


	function division(uint numerator, uint denominator) public constant returns (uint) {
                uint _quotient = numerator / denominator;
        return _quotient;
    }

	function uintToBytes (uint256 i) constant returns(bytes32 b)  {
		b = bytes32(i);
	}

}