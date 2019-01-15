pragma solidity ^0.4.24;


contract ERC20Interface {
    function name() public view returns(bytes32);
    function symbol() public view returns(bytes32);
    function balanceOf (address _owner) public view returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


contract AppCoins is ERC20Interface{
    // Public variables of the token
    address public owner;
    bytes32 private token_name;
    bytes32 private token_symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function AppCoins() public {
        owner = msg.sender;
        token_name = "AppCoins";
        token_symbol = "APPC";
        uint256 _totalSupply = 1000000;
        totalSupply = _totalSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[owner] = totalSupply;                // Give the creator all initial tokens
    }

    function name() public view returns(bytes32) {
        return token_name;
    }

    function symbol() public view returns(bytes32) {
        return token_symbol;
    }

    function balanceOf (address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    // /**
    //  * Transfer tokens
    //  *
    //  * Send `_value` tokens to `_to` from your account
    //  *
    //  * @param _to The address of the recipient
    //  * @param _value the amount to send
    //  */
    // function transfer(address _to, uint256 _value) public {
    //     _transfer(msg.sender, _to, _value);
    // }
    function transfer (address _to, uint256 _amount) public returns (bool success) {
        if( balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (uint) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return allowance[_from][msg.sender];
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}
library CampaignLibrary {

    struct Campaign {
        bytes32 bidId;
        uint price;
        uint budget;
        uint startDate;
        uint endDate;
        bool valid;
        address  owner;
    }


    /**
    @notice Set campaign id 
    @param _bidId Id of the campaign
     */
    function setBidId(Campaign storage _campaign, bytes32 _bidId) internal {
        _campaign.bidId = _bidId;
    }

    /**
    @notice Get campaign id
    @return {&#39;_bidId&#39; : &#39;Id of the campaign&#39;}
     */
    function getBidId(Campaign storage _campaign) internal view returns(bytes32 _bidId){
        return _campaign.bidId;
    }
   
    /**
    @notice Set campaing price per proof of attention
    @param _price Price of the campaign
     */
    function setPrice(Campaign storage _campaign, uint _price) internal {
        _campaign.price = _price;
    }

    /**
    @notice Get campaign price per proof of attention
    @return {&#39;_price&#39; : &#39;Price of the campaign&#39;}
     */
    function getPrice(Campaign storage _campaign) internal view returns(uint _price){
        return _campaign.price;
    }

    /**
    @notice Set campaign total budget 
    @param _budget Total budget of the campaign
     */
    function setBudget(Campaign storage _campaign, uint _budget) internal {
        _campaign.budget = _budget;
    }

    /**
    @notice Get campaign total budget
    @return {&#39;_budget&#39; : &#39;Total budget of the campaign&#39;}
     */
    function getBudget(Campaign storage _campaign) internal view returns(uint _budget){
        return _campaign.budget;
    }

    /**
    @notice Set campaign start date 
    @param _startDate Start date of the campaign (in milisecounds)
     */
    function setStartDate(Campaign storage _campaign, uint _startDate) internal{
        _campaign.startDate = _startDate;
    }

    /**
    @notice Get campaign start date 
    @return {&#39;_startDate&#39; : &#39;Start date of the campaign (in milisecounds)&#39;}
     */
    function getStartDate(Campaign storage _campaign) internal view returns(uint _startDate){
        return _campaign.startDate;
    }
 
    /**
    @notice Set campaign end date 
    @param _endDate End date of the campaign (in milisecounds)
     */
    function setEndDate(Campaign storage _campaign, uint _endDate) internal {
        _campaign.endDate = _endDate;
    }

    /**
    @notice Get campaign end date 
    @return {&#39;_endDate&#39; : &#39;End date of the campaign (in milisecounds)&#39;}
     */
    function getEndDate(Campaign storage _campaign) internal view returns(uint _endDate){
        return _campaign.endDate;
    }

    /**
    @notice Set campaign validity 
    @param _valid Validity of the campaign
     */
    function setValidity(Campaign storage _campaign, bool _valid) internal {
        _campaign.valid = _valid;
    }

    /**
    @notice Get campaign validity 
    @return {&#39;_valid&#39; : &#39;Boolean stating campaign validity&#39;}
     */
    function getValidity(Campaign storage _campaign) internal view returns(bool _valid){
        return _campaign.valid;
    }

    /**
    @notice Set campaign owner 
    @param _owner Owner of the campaign
     */
    function setOwner(Campaign storage _campaign, address _owner) internal {
        _campaign.owner = _owner;
    }

    /**
    @notice Get campaign owner 
    @return {&#39;_owner&#39; : &#39;Address of the owner of the campaign&#39;}
     */
    function getOwner(Campaign storage _campaign) internal view returns(address _owner){
        return _campaign.owner;
    }

    /**
    @notice Converts country index list into 3 uints
      
        Expects a list of country indexes such that the 2 digit country code is converted to an 
        index. Countries are expected to be indexed so a "AA" country code is mapped to index 0 and 
        "ZZ" country is mapped to index 675.
    @param countries List of country indexes
    @return {
        "countries1" : "First third of the byte array converted in a 256 bytes uint",
        "countries2" : "Second third of the byte array converted in a 256 bytes uint",
        "countries3" : "Third third of the byte array converted in a 256 bytes uint"
    }
    */
    function convertCountryIndexToBytes(uint[] countries) public pure
        returns (uint countries1,uint countries2,uint countries3){
        countries1 = 0;
        countries2 = 0;
        countries3 = 0;
        for(uint i = 0; i < countries.length; i++){
            uint index = countries[i];

            if(index<256){
                countries1 = countries1 | uint(1) << index;
            } else if (index<512) {
                countries2 = countries2 | uint(1) << (index - 256);
            } else {
                countries3 = countries3 | uint(1) << (index - 512);
            }
        }

        return (countries1,countries2,countries3);
    }    
}



interface StorageUser {
    function getStorageAddress() external view returns(address _storage);
}

interface ErrorThrower {
    event Error(string func, string message);
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }


  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);


  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }


}


contract Ownable is ErrorThrower {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
    *  The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner(string _funcName) {
        if(msg.sender != owner){
            emit Error(_funcName,"Operation can only be performed by contract owner");
            return;
        }
        _;
    }

    /**
    *  Allows the current owner to relinquish control of the contract.
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    function renounceOwnership() public onlyOwner("renounceOwnership") {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    *  Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner("transferOwnership") {
        _transferOwnership(_newOwner);
    }

    /**
    *  Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        if(_newOwner == address(0)){
            emit Error("transferOwnership","New owner&#39;s address needs to be different than 0x0");
            return;
        }

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract SingleAllowance is Ownable {

    address allowedAddress;

    modifier onlyAllowed() {
        require(allowedAddress == msg.sender);
        _;
    }

    modifier onlyOwnerOrAllowed() {
        require(owner == msg.sender || allowedAddress == msg.sender);
        _;
    }

    function setAllowedAddress(address _addr) public onlyOwner("setAllowedAddress"){
        allowedAddress = _addr;
    }
}


contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";

    /**
    *  Throws Error event if operator is not whitelisted.
    * @param _operator address
    */
    modifier onlyIfWhitelisted(string _funcname, address _operator) {
        if(!hasRole(_operator, ROLE_WHITELISTED)){
            emit Error(_funcname, "Operation can only be performed by Whitelisted Addresses");
            return;
        }
        _;
    }

    /**
    *  add an address to the whitelist
    * @param _operator address
    * @return true if the address was added to the whitelist, false if the address was already in the whitelist
    */
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner("addAddressToWhitelist")
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    /**
    *  getter to determine if address is in whitelist
    */
    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

    /**
    *  add addresses to the whitelist
    * @param _operators addresses
    * @return true if at least one address was added to the whitelist,
    * false if all addresses were already in the whitelist
    */
    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner("addAddressesToWhitelist")
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    /**
    *  remove an address from the whitelist
    * @param _operator address
    * @return true if the address was removed from the whitelist,
    * false if the address wasn&#39;t in the whitelist in the first place
    */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner("removeAddressFromWhitelist")
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
    *  remove addresses from the whitelist
    * @param _operators addresses
    * @return true if at least one address was removed from the whitelist,
    * false if all addresses weren&#39;t in the whitelist in the first place
    */
    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner("removeAddressesFromWhitelist")
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

}

contract BaseAdvertisementStorage is Whitelist {
    using CampaignLibrary for CampaignLibrary.Campaign;

    mapping (bytes32 => CampaignLibrary.Campaign) campaigns;

    bytes32 lastBidId = 0x0;

    modifier onlyIfCampaignExists(string _funcName, bytes32 _bidId) {
        if(campaigns[_bidId].owner == 0x0){
            emit Error(_funcName,"Campaign does not exist");
            return;
        }
        _;
    }
    
    event CampaignCreated
        (
            bytes32 bidId,
            uint price,
            uint budget,
            uint startDate,
            uint endDate,
            bool valid,
            address owner
    );

    event CampaignUpdated
        (
            bytes32 bidId,
            uint price,
            uint budget,
            uint startDate,
            uint endDate,
            bool valid,
            address  owner
    );

    /**
    @notice Get a Campaign information
     
        Based on a camapaign Id (bidId), returns all stored information for that campaign.
    @param campaignId Id of the campaign
    @return {
        "bidId" : "Id of the campaign",
        "price" : "Value to pay for each proof-of-attention",
        "budget" : "Total value avaliable to be spent on the campaign",
        "startDate" : "Start date of the campaign (in miliseconds)",
        "endDate" : "End date of the campaign (in miliseconds)"
        "valid" : "Boolean informing if the campaign is valid",
        "campOwner" : "Address of the campaing&#39;s owner"
    }
    */
    function _getCampaign(bytes32 campaignId)
        internal
        returns (CampaignLibrary.Campaign storage _campaign) {


        return campaigns[campaignId];
    }


    /**
    @notice Add or update a campaign information
    
        Based on a campaign Id (bidId), a campaign can be created (if non existent) or updated.
        This function can only be called by the set of allowed addresses registered earlier.
        An event will be emited during this function&#39;s execution, a CampaignCreated event if the 
        campaign does not exist yet or a CampaignUpdated if the campaign id is already registered.

    @param bidId Id of the campaign
    @param price Value to pay for each proof-of-attention
    @param budget Total value avaliable to be spent on the campaign
    @param startDate Start date of the campaign (in miliseconds)
    @param endDate End date of the campaign (in miliseconds)
    @param valid Boolean informing if the campaign is valid
    @param owner Address of the campaing&#39;s owner
    */
    function _setCampaign (
        bytes32 bidId,
        uint price,
        uint budget,
        uint startDate,
        uint endDate,
        bool valid,
        address owner
    )
    public
    onlyIfWhitelisted("setCampaign",msg.sender) {

        CampaignLibrary.Campaign storage campaign = campaigns[bidId];
        campaign.setBidId(bidId);
        campaign.setPrice(price);
        campaign.setBudget(budget);
        campaign.setStartDate(startDate);
        campaign.setEndDate(endDate);
        campaign.setValidity(valid);

        bool newCampaign = (campaigns[bidId].getOwner() == 0x0);

        campaign.setOwner(owner);



        if(newCampaign){
            emitCampaignCreated(campaign);
            setLastBidId(bidId);
        } else {
            emitCampaignUpdated(campaign);
        }
    }

    /**
    @notice Constructor function
    
        Initializes contract and updates allowed addresses to interact with contract functions.
    */
    constructor() public {
        addAddressToWhitelist(msg.sender);
    }

      /**
    @notice Get the price of a campaign
    
        Based on the Campaign id, return the value paid for each proof of attention registered.
    @param bidId Campaign id to which the query refers
    @return { "price" : "Reward (in wei) for each proof of attention registered"} 
    */
    function getCampaignPriceById(bytes32 bidId)
        public
        view
        returns (uint price) {
        return campaigns[bidId].getPrice();
    }

    /** 
    @notice Set a new price for a campaign
    
        Based on the Campaign id, updates the value paid for each proof of attention registered.
        This function can only be executed by allowed addresses and emits a CampaingUpdate event.
    @param bidId Campaing id to which the update refers
    @param price New price for each proof of attention
    */
    function setCampaignPriceById(bytes32 bidId, uint price)
        public
        onlyIfWhitelisted("setCampaignPriceById",msg.sender) 
        onlyIfCampaignExists("setCampaignPriceById",bidId)      
        {
        campaigns[bidId].setPrice(price);
        emitCampaignUpdated(campaigns[bidId]);
    }

    /**
    @notice Get the budget avaliable of a campaign
    
        Based on the Campaign id, return the total value avaliable to pay for proofs of attention.
    @param bidId Campaign id to which the query refers
    @return { "budget" : "Total value (in wei) spendable in proof of attention rewards"} 
    */
    function getCampaignBudgetById(bytes32 bidId)
        public
        view
        returns (uint budget) {
        return campaigns[bidId].getBudget();
    }

    /**
    @notice Set a new campaign budget
    
        Based on the Campaign id, updates the total value avaliable for proof of attention 
        registrations. This function can only be executed by allowed addresses and emits a 
        CampaignUpdated event. This function does not transfer any funds as this contract only works
        as a data repository, every logic needed will be processed in the Advertisement contract.
    @param bidId Campaign id to which the query refers
    @param newBudget New value for the total budget of the campaign
    */
    function setCampaignBudgetById(bytes32 bidId, uint newBudget)
        public
        onlyIfCampaignExists("setCampaignBudgetById",bidId)
        onlyIfWhitelisted("setCampaignBudgetById",msg.sender)
        {
        campaigns[bidId].setBudget(newBudget);
        emitCampaignUpdated(campaigns[bidId]);
    }

    /** 
    @notice Get the start date of a campaign
    
        Based on the Campaign id, return the value (in miliseconds) corresponding to the start Date
        of the campaign.
    @param bidId Campaign id to which the query refers
    @return { "startDate" : "Start date (in miliseconds) of the campaign"} 
    */
    function getCampaignStartDateById(bytes32 bidId)
        public
        view
        returns (uint startDate) {
        return campaigns[bidId].getStartDate();
    }

    /**
    @notice Set a new start date for a campaign
    
        Based of the Campaign id, updates the start date of a campaign. This function can only be 
        executed by allowed addresses and emits a CampaignUpdated event.
    @param bidId Campaign id to which the query refers
    @param newStartDate New value (in miliseconds) for the start date of the campaign
    */
    function setCampaignStartDateById(bytes32 bidId, uint newStartDate)
        public
        onlyIfCampaignExists("setCampaignStartDateById",bidId)
        onlyIfWhitelisted("setCampaignStartDateById",msg.sender)
        {
        campaigns[bidId].setStartDate(newStartDate);
        emitCampaignUpdated(campaigns[bidId]);
    }
    
    /** 
    @notice Get the end date of a campaign
    
        Based on the Campaign id, return the value (in miliseconds) corresponding to the end Date
        of the campaign.
    @param bidId Campaign id to which the query refers
    @return { "endDate" : "End date (in miliseconds) of the campaign"} 
    */
    function getCampaignEndDateById(bytes32 bidId)
        public
        view
        returns (uint endDate) {
        return campaigns[bidId].getEndDate();
    }

    /**
    @notice Set a new end date for a campaign
    
        Based of the Campaign id, updates the end date of a campaign. This function can only be 
        executed by allowed addresses and emits a CampaignUpdated event.
    @param bidId Campaign id to which the query refers
    @param newEndDate New value (in miliseconds) for the end date of the campaign
    */
    function setCampaignEndDateById(bytes32 bidId, uint newEndDate)
        public
        onlyIfCampaignExists("setCampaignEndDateById",bidId)
        onlyIfWhitelisted("setCampaignEndDateById",msg.sender)
        {
        campaigns[bidId].setEndDate(newEndDate);
        emitCampaignUpdated(campaigns[bidId]);
    }
    /** 
    @notice Get information regarding validity of a campaign.
    
        Based on the Campaign id, return a boolean which represents a valid campaign if it has 
        the value of True else has the value of False.
    @param bidId Campaign id to which the query refers
    @return { "valid" : "Validity of the campaign"} 
    */
    function getCampaignValidById(bytes32 bidId)
        public
        view
        returns (bool valid) {
        return campaigns[bidId].getValidity();
    }

    /**
    @notice Set a new campaign validity state.
    
        Updates the validity of a campaign based on a campaign Id. This function can only be 
        executed by allowed addresses and emits a CampaignUpdated event.
    @param bidId Campaign id to which the query refers
    @param isValid New value for the campaign validity
    */
    function setCampaignValidById(bytes32 bidId, bool isValid)
        public
        onlyIfCampaignExists("setCampaignValidById",bidId)
        onlyIfWhitelisted("setCampaignValidById",msg.sender)
        {
        campaigns[bidId].setValidity(isValid);
        emitCampaignUpdated(campaigns[bidId]);
    }

    /**
    @notice Get the owner of a campaign 
     
        Based on the Campaign id, return the address of the campaign owner.
    @param bidId Campaign id to which the query refers
    @return { "campOwner" : "Address of the campaign owner" } 
    */
    function getCampaignOwnerById(bytes32 bidId)
        public
        view
        returns (address campOwner) {
        return campaigns[bidId].getOwner();
    }

    /**
    @notice Set a new campaign owner 
    
        Based on the Campaign id, update the owner of the refered campaign. This function can only 
        be executed by allowed addresses and emits a CampaignUpdated event.
    @param bidId Campaign id to which the query refers
    @param newOwner New address to be the owner of the campaign
    */
    function setCampaignOwnerById(bytes32 bidId, address newOwner)
        public
        onlyIfCampaignExists("setCampaignOwnerById",bidId)
        onlyIfWhitelisted("setCampaignOwnerById",msg.sender)
        {
        campaigns[bidId].setOwner(newOwner);
        emitCampaignUpdated(campaigns[bidId]);
    }

    /**
    @notice Function to emit campaign updates
    
        It emits a CampaignUpdated event with the new campaign information. 
    */
    function emitCampaignUpdated(CampaignLibrary.Campaign storage campaign) private {
        emit CampaignUpdated(
            campaign.getBidId(),
            campaign.getPrice(),
            campaign.getBudget(),
            campaign.getStartDate(),
            campaign.getEndDate(),
            campaign.getValidity(),
            campaign.getOwner()
        );
    }

    /**
    @notice Function to emit campaign creations
    
        It emits a CampaignCreated event with the new campaign created. 
    */
    function emitCampaignCreated(CampaignLibrary.Campaign storage campaign) private {
        emit CampaignCreated(
            campaign.getBidId(),
            campaign.getPrice(),
            campaign.getBudget(),
            campaign.getStartDate(),
            campaign.getEndDate(),
            campaign.getValidity(),
            campaign.getOwner()
        );
    }

    /**
    @notice Internal function to set most recent bidId
    
        This value is stored to avoid conflicts between
        Advertisement contract upgrades.
    @param _newBidId Newer bidId
     */
    function setLastBidId(bytes32 _newBidId) internal {    
        lastBidId = _newBidId;
    }

    /**
    @notice Returns the greatest BidId ever registered to the contract
    @return { &#39;_lastBidId&#39; : &#39;Greatest bidId registered to the contract&#39;}
     */
    function getLastBidId() 
        external 
        returns (bytes32 _lastBidId){
        
        return lastBidId;
    }
}

contract ExtendedAdvertisementStorage is BaseAdvertisementStorage {

    mapping (bytes32 => string) campaignEndPoints;

    event ExtendedCampaignEndPointCreated(
        bytes32 bidId,
        string endPoint
    );

    event ExtendedCampaignEndPointUpdated(
        bytes32 bidId,
        string endPoint
    );

    /**
    @notice Get a Campaign information
     
        Based on a camapaign Id (bidId), returns all stored information for that campaign.
    @param _campaignId Id of the campaign
    @return {
        "_bidId" : "Id of the campaign",
        "_price" : "Value to pay for each proof-of-attention",
        "_budget" : "Total value avaliable to be spent on the campaign",
        "_startDate" : "Start date of the campaign (in miliseconds)",
        "_endDate" : "End date of the campaign (in miliseconds)"
        "_valid" : "Boolean informing if the campaign is valid",
        "_campOwner" : "Address of the campaing&#39;s owner",
    }
    */
    function getCampaign(bytes32 _campaignId)
        public
        view
        returns (
            bytes32 _bidId,
            uint _price,
            uint _budget,
            uint _startDate,
            uint _endDate,
            bool _valid,
            address _campOwner
        ) {

        CampaignLibrary.Campaign storage campaign = _getCampaign(_campaignId);

        return (
            campaign.getBidId(),
            campaign.getPrice(),
            campaign.getBudget(),
            campaign.getStartDate(),
            campaign.getEndDate(),
            campaign.getValidity(),
            campaign.getOwner()
        );
    }

    /**
    @notice Add or update a campaign information
    
        Based on a campaign Id (bidId), a campaign can be created (if non existent) or updated.
        This function can only be called by the set of allowed addresses registered earlier.
        An event will be emited during this function&#39;s execution, a CampaignCreated and a 
        ExtendedCampaignEndPointCreated event if the campaign does not exist yet or a 
        CampaignUpdated and a ExtendedCampaignEndPointUpdated event if the campaign id is already 
        registered.

    @param _bidId Id of the campaign
    @param _price Value to pay for each proof-of-attention
    @param _budget Total value avaliable to be spent on the campaign
    @param _startDate Start date of the campaign (in miliseconds)
    @param _endDate End date of the campaign (in miliseconds)
    @param _valid Boolean informing if the campaign is valid
    @param _owner Address of the campaing&#39;s owner
    @param _endPoint URL of the signing serivce
    */
    function setCampaign (
        bytes32 _bidId,
        uint _price,
        uint _budget,
        uint _startDate,
        uint _endDate,
        bool _valid,
        address _owner,
        string _endPoint
    )
    public
    onlyIfWhitelisted("setCampaign",msg.sender) {
        
        bool newCampaign = (getCampaignOwnerById(_bidId) == 0x0);
        _setCampaign(_bidId, _price, _budget, _startDate, _endDate, _valid, _owner);
        
        campaignEndPoints[_bidId] = _endPoint;

        if(newCampaign){
            emit ExtendedCampaignEndPointCreated(_bidId,_endPoint);
        } else {
            emit ExtendedCampaignEndPointUpdated(_bidId,_endPoint);
        }
    }

    /**
    @notice Get campaign signing web service endpoint
    
        Get the end point to which the user should submit the proof of attention to be signed
    @param _bidId Id of the campaign
    @return { "_endPoint": "URL for the signing web service"}
    */

    function getCampaignEndPointById(bytes32 _bidId) public returns (string _endPoint){
        return campaignEndPoints[_bidId];
    }

    /**
    @notice Set campaign signing web service endpoint
    
        Sets the webservice&#39;s endpoint to which the user should submit the proof of attention
    @param _bidId Id of the campaign
    @param _endPoint URL for the signing web service
    */
    function setCampaignEndPointById(bytes32 _bidId, string _endPoint) 
        public 
        onlyIfCampaignExists("setCampaignEndPointById",_bidId)
        onlyIfWhitelisted("setCampaignEndPointById",msg.sender) 
        {
        campaignEndPoints[_bidId] = _endPoint;
        emit ExtendedCampaignEndPointUpdated(_bidId,_endPoint);
    }

}


contract BaseAdvertisement is StorageUser,Ownable {
    
    AppCoins appc;
    BaseFinance advertisementFinance;
    BaseAdvertisementStorage advertisementStorage;

    mapping( bytes32 => mapping(address => uint256)) userAttributions;

    bytes32[] bidIdList;
    bytes32 lastBidId = 0x0;


    /**
    @notice Constructor function
    
        Initializes contract with default validation rules
    @param _addrAppc Address of the AppCoins (ERC-20) contract
    @param _addrAdverStorage Address of the Advertisement Storage contract to be used
    @param _addrAdverFinance Address of the Advertisement Finance contract to be used
    */
    constructor(address _addrAppc, address _addrAdverStorage, address _addrAdverFinance) public {
        appc = AppCoins(_addrAppc);

        advertisementStorage = BaseAdvertisementStorage(_addrAdverStorage);
        advertisementFinance = BaseFinance(_addrAdverFinance);
        lastBidId = advertisementStorage.getLastBidId();
    }


    /**
    @notice Upgrade finance contract used by this contract
    
        This function is part of the upgrade mechanism avaliable to the advertisement contracts.
        Using this function it is possible to update to a new Advertisement Finance contract without
        the need to cancel avaliable campaigns.
        Upgrade finance function can only be called by the Advertisement contract owner.
    @param addrAdverFinance Address of the new Advertisement Finance contract
    */
    function upgradeFinance (address addrAdverFinance) public onlyOwner("upgradeFinance") {
        BaseFinance newAdvFinance = BaseFinance(addrAdverFinance);

        address[] memory devList = advertisementFinance.getUserList();
        
        for(uint i = 0; i < devList.length; i++){
            uint balance = advertisementFinance.getUserBalance(devList[i]);
            newAdvFinance.increaseBalance(devList[i],balance);
        }
        
        uint256 initBalance = appc.balanceOf(address(advertisementFinance));
        advertisementFinance.transferAllFunds(address(newAdvFinance));
        uint256 oldBalance = appc.balanceOf(address(advertisementFinance));
        uint256 newBalance = appc.balanceOf(address(newAdvFinance));
        
        require(initBalance == newBalance);
        require(oldBalance == 0);
        advertisementFinance = newAdvFinance;
    }

    /**
    @notice Upgrade storage contract used by this contract
    
        Upgrades Advertisement Storage contract addres with no need to redeploy
        Advertisement contract. However every campaign in the old contract will
        be canceled.
        This function can only be called by the Advertisement contract owner.
    @param addrAdverStorage Address of the new Advertisement Storage contract
    */

    function upgradeStorage (address addrAdverStorage) public onlyOwner("upgradeStorage") {
        for(uint i = 0; i < bidIdList.length; i++) {
            cancelCampaign(bidIdList[i]);
        }
        delete bidIdList;

        lastBidId = advertisementStorage.getLastBidId();
        advertisementFinance.setAdsStorageAddress(addrAdverStorage);
        advertisementStorage = BaseAdvertisementStorage(addrAdverStorage);
    }


    /**
    @notice Get Advertisement Storage Address used by this contract
    
        This function is required to upgrade Advertisement contract address on Advertisement
        Finance contract. This function can only be called by the Advertisement Finance
        contract registered in this contract.
    @return {
        "storageContract" : "Address of the Advertisement Storage contract used by this contract"
        }
    */

    function getStorageAddress() public view returns(address storageContract) {
        require (msg.sender == address(advertisementFinance));

        return address(advertisementStorage);
    }


    /**
    @notice Creates a campaign 
     
        Method to create a campaign of user aquisition for a certain application.
        This method will emit a Campaign Information event with every information 
        provided in the arguments of this method.
    @param packageName Package name of the appication subject to the user aquisition campaign
    @param countries Encoded list of 3 integers intended to include every 
    county where this campaign will be avaliable.
    For more detain on this encoding refer to wiki documentation.
    @param vercodes List of version codes to which the user aquisition campaign is applied.
    @param price Value (in wei) the campaign owner pays for each proof-of-attention.
    @param budget Total budget (in wei) the campaign owner will deposit 
    to pay for the proof-of-attention.
    @param startDate Date (in miliseconds) on which the campaign will start to be 
    avaliable to users.
    @param endDate Date (in miliseconds) on which the campaign will no longer be avaliable to users.
    */

    function _generateCampaign (
        string packageName,
        uint[3] countries,
        uint[] vercodes,
        uint price,
        uint budget,
        uint startDate,
        uint endDate)
        internal returns (CampaignLibrary.Campaign memory) {

        require(budget >= price);
        require(endDate >= startDate);


        //Transfers the budget to contract address
        if(appc.allowance(msg.sender, address(this)) >= budget){
            appc.transferFrom(msg.sender, address(advertisementFinance), budget);

            advertisementFinance.increaseBalance(msg.sender,budget);

            uint newBidId = bytesToUint(lastBidId);
            lastBidId = uintToBytes(++newBidId);
            

            CampaignLibrary.Campaign memory newCampaign;
            newCampaign.price = price;
            newCampaign.startDate = startDate;
            newCampaign.endDate = endDate;
            newCampaign.budget = budget;
            newCampaign.owner = msg.sender;
            newCampaign.valid = true;
            newCampaign.bidId = lastBidId;
        } else {
            emit Error("createCampaign","Not enough allowance");
        }
        
        return newCampaign;
    }

    function _getStorage() internal returns (BaseAdvertisementStorage) {
        return advertisementStorage;
    }

    function _getFinance() internal returns (BaseFinance) {
        return advertisementFinance;
    }

    function _setUserAttribution(bytes32 _bidId,address _user,uint256 _attributions) internal{
        userAttributions[_bidId][_user] = _attributions;
    }


    function getUserAttribution(bytes32 _bidId,address _user) internal returns (uint256) {
        return userAttributions[_bidId][_user];
    }

    /**
    @notice Cancel a campaign and give the remaining budget to the campaign owner
    
        When a campaing owner wants to cancel a campaign, the campaign owner needs
        to call this function. This function can only be called either by the campaign owner or by
        the Advertisement contract owner. This function results in campaign cancelation and
        retreival of the remaining budget to the respective campaign owner.
    @param bidId Campaign id to which the cancelation referes to
     */
    function cancelCampaign (bytes32 bidId) public {
        address campaignOwner = getOwnerOfCampaign(bidId);

		// Only contract owner or campaign owner can cancel a campaign
        require(owner == msg.sender || campaignOwner == msg.sender);
        uint budget = getBudgetOfCampaign(bidId);

        advertisementFinance.withdraw(campaignOwner, budget);

        advertisementStorage.setCampaignBudgetById(bidId, 0);
        advertisementStorage.setCampaignValidById(bidId, false);
    }

     /**
    @notice Get a campaign validity state
    @param bidId Campaign id to which the query refers
    @return { "state" : "Validity of the campaign"}
    */
    function getCampaignValidity(bytes32 bidId) public view returns(bool state){
        return advertisementStorage.getCampaignValidById(bidId);
    }

    /**
    @notice Get the price of a campaign
    
        Based on the Campaign id return the value paid for each proof of attention registered.
    @param bidId Campaign id to which the query refers
    @return { "price" : "Reward (in wei) for each proof of attention registered"}
    */
    function getPriceOfCampaign (bytes32 bidId) public view returns(uint price) {
        return advertisementStorage.getCampaignPriceById(bidId);
    }

    /**
    @notice Get the start date of a campaign
    
        Based on the Campaign id return the value (in miliseconds) corresponding to the start Date
        of the campaign.
    @param bidId Campaign id to which the query refers
    @return { "startDate" : "Start date (in miliseconds) of the campaign"}
    */
    function getStartDateOfCampaign (bytes32 bidId) public view returns(uint startDate) {
        return advertisementStorage.getCampaignStartDateById(bidId);
    }

    /**
    @notice Get the end date of a campaign
    
        Based on the Campaign id return the value (in miliseconds) corresponding to the end Date
        of the campaign.
    @param bidId Campaign id to which the query refers
    @return { "endDate" : "End date (in miliseconds) of the campaign"}
    */
    function getEndDateOfCampaign (bytes32 bidId) public view returns(uint endDate) {
        return advertisementStorage.getCampaignEndDateById(bidId);
    }

    /**
    @notice Get the budget avaliable of a campaign
    
        Based on the Campaign id return the total value avaliable to pay for proofs of attention.
    @param bidId Campaign id to which the query refers
    @return { "budget" : "Total value (in wei) spendable in proof of attention rewards"}
    */
    function getBudgetOfCampaign (bytes32 bidId) public view returns(uint budget) {
        return advertisementStorage.getCampaignBudgetById(bidId);
    }


    /**
    @notice Get the owner of a campaign
    
        Based on the Campaign id return the address of the campaign owner
    @param bidId Campaign id to which the query refers
    @return { "campaignOwner" : "Address of the campaign owner" }
    */
    function getOwnerOfCampaign (bytes32 bidId) public view returns(address campaignOwner) {
        return advertisementStorage.getCampaignOwnerById(bidId);
    }

    /**
    @notice Get the list of Campaign BidIds registered in the contract
    
        Returns the list of BidIds of the campaigns ever registered in the contract
    @return { "bidIds" : "List of BidIds registered in the contract" }
    */
    function getBidIdList() public view returns(bytes32[] bidIds) {
        return bidIdList;
    }

    function _getBidIdList() internal returns(bytes32[] storage bidIds){
        return bidIdList;
    }

    /**
    @notice Check if a certain campaign is still valid
    
        Returns a boolean representing the validity of the campaign
        Has value of True if the campaign is still valid else has value of False
    @param bidId Campaign id to which the query refers
    @return { "valid" : "validity of the campaign" }
    */
    function isCampaignValid(bytes32 bidId) public view returns(bool valid) {
        uint startDate = advertisementStorage.getCampaignStartDateById(bidId);
        uint endDate = advertisementStorage.getCampaignEndDateById(bidId);
        bool validity = advertisementStorage.getCampaignValidById(bidId);

        uint nowInMilliseconds = now * 1000;
        return validity && startDate < nowInMilliseconds && endDate > nowInMilliseconds;
    }

     /**
    @notice Returns the division of two numbers
    
        Function used for division operations inside the smartcontract
    @param numerator Numerator part of the division
    @param denominator Denominator part of the division
    @return { "result" : "Result of the division"}
    */
    function division(uint numerator, uint denominator) public view returns (uint result) {
        uint _quotient = numerator / denominator;
        return _quotient;
    }

    /**
    @notice Converts a uint256 type variable to a byte32 type variable
    
        Mostly used internaly
    @param i number to be converted
    @return { "b" : "Input number converted to bytes"}
    */
    function uintToBytes (uint256 i) public view returns(bytes32 b) {
        b = bytes32(i);
    }

    function bytesToUint(bytes32 b) public view returns (uint) 
    {
        return uint(b) & 0xfff;
    }

}

contract Signature {

    /**
    @notice splitSignature
    
        Based on a signature Sig (bytes32), returns the r, s, v
    @param sig Signature
    @return {
        "uint8" : "recover Id",
        "bytes32" : "Output of the ECDSA signature",
        "bytes32" : "Output of the ECDSA signature",
    }
    */
    function splitSignature(bytes sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
        {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /**
    @notice recoverSigner
    
        Based on a message and signature returns the address
    @param message Message
    @param sig Signature
    @return {
        "address" : "Address of the private key that signed",
    }
    */
    function recoverSigner(bytes32 message, bytes sig)
        public
        pure
        returns (address)
        {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }
}


contract BaseFinance is SingleAllowance {

    mapping (address => uint256) balanceUsers;
    mapping (address => bool) userExists;

    address[] users;

    address advStorageContract;

    AppCoins appc;

    /**
    @notice Constructor function
     
        Initializes contract with the AppCoins contract address
    @param _addrAppc Address of the AppCoins (ERC-20) contract
    */
    constructor (address _addrAppc) 
        public {
        appc = AppCoins(_addrAppc);
        advStorageContract = 0x0;
    }


    /**
    @notice Sets the Storage contract address used by the allowed contract
    
        The Storage contract address is mostly used as part of a failsafe mechanism to
        ensure contract upgrades are executed using the same Storage 
        contract. This function returns every value of AppCoins stored in this contract to their 
        owners. This function can only be called by the 
        Finance contract owner or by the allowed contract registered earlier in 
        this contract.
    @param _addrStorage Address of the new Storage contract
    */
    function setAdsStorageAddress (address _addrStorage) external onlyOwnerOrAllowed {
        reset();
        advStorageContract = _addrStorage;
    }

        /**
    @notice Sets the Advertisement contract address to allow calls from Advertisement contract
    
        This function is used for upgrading the Advertisement contract without need to redeploy 
        Advertisement Finance and Advertisement Storage contracts. The function can only be called 
        by this contract&#39;s owner. During the update of the Advertisement contract address, the 
        contract for Advertisement Storage used by the new Advertisement contract is checked. 
        This function reverts if the new Advertisement contract does not use the same Advertisement 
        Storage contract earlier registered in this Advertisement Finance contract.
    @param _addr Address of the newly allowed contract 
    */
    function setAllowedAddress (address _addr) public onlyOwner("setAllowedAddress") {
        // Verify if the new Ads contract is using the same storage as before 
        if (allowedAddress != 0x0){
            StorageUser storageUser = StorageUser(_addr);
            address storageContract = storageUser.getStorageAddress();
            require (storageContract == advStorageContract);
        }
        
        //Update contract
        super.setAllowedAddress(_addr);
    }

    /**
    @notice Increases balance of a user
    
        This function can only be called by the registered Advertisement contract and increases the 
        balance of a specific user on this contract. This function does not transfer funds, 
        this step need to be done earlier by the Advertisement contract. This function can only be 
        called by the registered Advertisement contract.
    @param _user Address of the user who will receive a balance increase
    @param _value Value of coins to increase the user&#39;s balance
    */
    function increaseBalance(address _user, uint256 _value) 
        public onlyAllowed{

        if(userExists[_user] == false){
            users.push(_user);
            userExists[_user] = true;
        }

        balanceUsers[_user] += _value;
    }

     /**
    @notice Transfers coins from a certain user to a destination address
    
        Used to release a certain value of coins from a certain user to a destination address.
        This function updates the user&#39;s balance in the contract. It can only be called by the 
        Advertisement contract registered.
    @param _user Address of the user from which the value will be subtracted
    @param _destination Address receiving the value transfered
    @param _value Value to be transfered in AppCoins
    */
    function pay(address _user, address _destination, uint256 _value) public onlyAllowed;

    /**
    @notice Withdraws a certain value from a user&#39;s balance back to the user&#39;s account
    
        Can be called from the Advertisement contract registered or by this contract&#39;s owner.
    @param _user Address of the user
    @param _value Value to be transfered in AppCoins
    */
    function withdraw(address _user, uint256 _value) public onlyOwnerOrAllowed;


    /**
    @notice Resets this contract and returns every amount deposited to each user registered
    
        This function is used in case a contract reset is needed or the contract needs to be 
        deactivated. Thus returns every fund deposited to it&#39;s respective owner.
    */
    function reset() public onlyOwnerOrAllowed {
        for(uint i = 0; i < users.length; i++){
            withdraw(users[i],balanceUsers[users[i]]);
        }
    }
    /**
    @notice Transfers all funds of the contract to a single address
    
        This function is used for finance contract upgrades in order to be more cost efficient.
    @param _destination Address receiving the funds
     */
    function transferAllFunds(address _destination) public onlyAllowed {
        uint256 balance = appc.balanceOf(address(this));
        appc.transfer(_destination,balance);
    }

      /**
    @notice Get balance of coins stored in the contract by a specific user
    
        This function can only be called by the Advertisement contract
    @param _user Developer&#39;s address
    @return { &#39;_balance&#39; : &#39;Balance of coins deposited in the contract by the address&#39; }
    */
    function getUserBalance(address _user) public view onlyAllowed returns(uint256 _balance){
        return balanceUsers[_user];
    }

    /**
    @notice Get list of users with coins stored in the contract 
    
        This function can only be called by the Advertisement contract        
    @return { &#39;_userList&#39; : &#39; List of users registered in the contract&#39;}
    */
    function getUserList() public view onlyAllowed returns(address[] _userList){
        return users;
    }
}

contract ExtendedFinance is BaseFinance {

    mapping ( address => uint256 ) rewardedBalance;

    constructor(address _appc) public BaseFinance(_appc){

    }


    function pay(address _user, address _destination, uint256 _value)
        public onlyAllowed{

        require(balanceUsers[_user] >= _value);

        balanceUsers[_user] -= _value;
        rewardedBalance[_destination] += _value;
    }


    function withdraw(address _user, uint256 _value) public onlyOwnerOrAllowed {

        require(balanceUsers[_user] >= _value);

        balanceUsers[_user] -= _value;
        appc.transfer(_user, _value);

    }

    /**
    @notice Withdraws user&#39;s rewards
    
        Function to transfer a certain user&#39;s rewards to his address 
    @param _user Address who&#39;s rewards will be withdrawn
    @param _value Value of the withdraws which will be transfered to the user 
    */
    function withdrawRewards(address _user, uint256 _value) public onlyOwnerOrAllowed {
        require(rewardedBalance[_user] >= _value);

        rewardedBalance[_user] -= _value;
        appc.transfer(_user, _value);
    }
    /**
    @notice Get user&#39;s rewards balance
    
        Function returning a user&#39;s rewards balance not yet withdrawn
    @param _user Address of the user
    @return { "_balance" : "Rewards balance of the user" }
    */
    function getRewardsBalance(address _user) public onlyOwnerOrAllowed returns (uint256 _balance) {
        return rewardedBalance[_user];
    }

}


contract ExtendedAdvertisement is BaseAdvertisement, Whitelist, Signature {

    event BulkPoARegistered(bytes32 bidId, bytes32 rootHash, bytes signedrootHash, uint256 newPoAs, uint256 convertedPoAs);
    event CampaignInformation
        (
            bytes32 bidId,
            address  owner,
            string ipValidator,
            string packageName,
            uint[3] countries,
            uint[] vercodes,
            string endpoint
    );

    constructor(address _addrAppc, address _addrAdverStorage, address _addrAdverFinance) public
        BaseAdvertisement(_addrAppc,_addrAdverStorage,_addrAdverFinance) {
        addAddressToWhitelist(msg.sender);
    }


    /**
    @notice Creates an extebded campaign
    
        Method to create an extended campaign of user aquisition for a certain application.
        This method will emit a Campaign Information event with every information
        provided in the arguments of this method.
    @param packageName Package name of the appication subject to the user aquisition campaign
    @param countries Encoded list of 3 integers intended to include every
    county where this campaign will be avaliable.
    For more detain on this encoding refer to wiki documentation.
    @param vercodes List of version codes to which the user aquisition campaign is applied.
    @param price Value (in wei) the campaign owner pays for each proof-of-attention.
    @param budget Total budget (in wei) the campaign owner will deposit
    to pay for the proof-of-attention.
    @param startDate Date (in miliseconds) on which the campaign will start to be
    avaliable to users.
    @param endDate Date (in miliseconds) on which the campaign will no longer be avaliable to users.
    @param endPoint URL of the signing serivce
    */
    function createCampaign (
        string packageName,
        uint[3] countries,
        uint[] vercodes,
        uint price,
        uint budget,
        uint startDate,
        uint endDate,
        string endPoint)
        external
        {

        CampaignLibrary.Campaign memory newCampaign = _generateCampaign(packageName, countries, vercodes, price, budget, startDate, endDate);

        if(newCampaign.owner == 0x0){
            // campaign was not generated correctly (revert)
            return;
        }

        _getBidIdList().push(newCampaign.bidId);

        ExtendedAdvertisementStorage(address(_getStorage())).setCampaign(
            newCampaign.bidId,
            newCampaign.price,
            newCampaign.budget,
            newCampaign.startDate,
            newCampaign.endDate,
            newCampaign.valid,
            newCampaign.owner,
            endPoint);

        emit CampaignInformation(
            newCampaign.bidId,
            newCampaign.owner,
            "", // ipValidator field
            packageName,
            countries,
            vercodes,
            endPoint);
    }

    /**
    @notice Function to submit in bulk PoAs
    
        This function can only be called by whitelisted addresses and provides a cost efficient
        method to submit a batch of validates PoAs at once. This function emits a PoaRegistered
        event containing the campaign id, root hash, signed root hash, number of new hashes since
        the last submission and the effective number of conversions.

    @param bidId Campaign id for which the Proof of attention root hash refferes to
    @param rootHash Root hash of all submitted proof of attention to a given campaign
    @param signedRootHash Root hash signed by the signing service of the campaign
    @param newHashes Number of new proof of attention hashes since last submission
    */
    function bulkRegisterPoA(bytes32 bidId, bytes32 rootHash, bytes signedRootHash, uint256 newHashes)
        public
        onlyIfWhitelisted("createCampaign",msg.sender)
        {

        address addressSig = recoverSigner(rootHash, signedRootHash);

        if (msg.sender != addressSig) {
            emit Error("bulkRegisterPoA","Invalid signature");
            return;
        }

        uint price = _getStorage().getCampaignPriceById(bidId);
        uint budget = _getStorage().getCampaignBudgetById(bidId);
        address owner = _getStorage().getCampaignOwnerById(bidId);
        uint maxConversions = division(budget,price);
        uint effectiveConversions;
        uint totalPay;
        uint newBudget;

        if (maxConversions >= newHashes){
            effectiveConversions = newHashes;
        } else {
            effectiveConversions = maxConversions;
        }

        totalPay = price*effectiveConversions;
        newBudget = budget - totalPay;

        _getFinance().pay(owner,msg.sender,totalPay);
        _getStorage().setCampaignBudgetById(bidId,newBudget);

        if(newBudget < price){
            _getStorage().setCampaignValidById(bidId,false);
        }

        emit BulkPoARegistered(bidId,rootHash,signedRootHash,newHashes,effectiveConversions);
    }

    /**
    @notice Function to withdraw PoA convertions
    
        This function is restricted to addresses allowed to submit bulk PoAs and enable those
        addresses to withdraw funds previously collected by bulk PoA submissions
    */

    function withdraw()
        public
        onlyIfWhitelisted("withdraw",msg.sender)
        {
        uint256 balance = ExtendedFinance(address(_getFinance())).getRewardsBalance(msg.sender);
        ExtendedFinance(address(_getFinance())).withdrawRewards(msg.sender,balance);
    }
    /**
    @notice Get user&#39;s balance of funds obtainded by rewards
    
        Anyone can call this function and get the rewards balance of a certain user.
    @param _user Address from which the balance refers to
    @return { "_balance" : "" } */
    function getRewardsBalance(address _user) public view returns (uint256 _balance) {
        return ExtendedFinance(address(_getFinance())).getRewardsBalance(_user);
    }

    /**
    @notice Returns the signing Endpoint of a camapign
    
        Function returning the Webservice URL responsible for validating and signing a PoA
    @param bidId Campaign id to which the Endpoint is associated
    @return { "url" : "Validation and signature endpoint"}
    */

    function getEndPointOfCampaign (bytes32 bidId) public view returns (string url){
        return ExtendedAdvertisementStorage(address(_getStorage())).getCampaignEndPointById(bidId);
    }
}