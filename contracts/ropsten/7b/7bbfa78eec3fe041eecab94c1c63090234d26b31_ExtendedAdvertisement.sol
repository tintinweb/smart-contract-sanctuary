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


    function setBidId(Campaign storage _campaign, bytes32 _bidId) internal {
        _campaign.bidId = _bidId;
    }

    function getBidId(Campaign storage _campaign) internal view returns(bytes32 _bidId){
        return _campaign.bidId;
    }

    function setPrice(Campaign storage _campaign, uint _price) internal {
        _campaign.price = _price;
    }

    function getPrice(Campaign storage _campaign) internal view returns(uint _price){
        return _campaign.price;
    }

    function setBudget(Campaign storage _campaign, uint _budget) internal {
        _campaign.budget = _budget;
    }

    function getBudget(Campaign storage _campaign) internal view returns(uint _budget){
        return _campaign.budget;
    }

    function setStartDate(Campaign storage _campaign, uint _startDate) internal{
        _campaign.startDate = _startDate;
    }

    function getStartDate(Campaign storage _campaign) internal view returns(uint _startDate){
        return _campaign.startDate;
    }
 
    function setEndDate(Campaign storage _campaign, uint _endDate) internal {
        _campaign.endDate = _endDate;
    }

    function getEndDate(Campaign storage _campaign) internal view returns(uint _endDate){
        return _campaign.endDate;
    }

    function setValidity(Campaign storage _campaign, bool _valid) internal {
        _campaign.valid = _valid;
    }

    function getValidity(Campaign storage _campaign) internal view returns(bool _valid){
        return _campaign.valid;
    }

    function setOwner(Campaign storage _campaign, address _owner) internal {
        _campaign.owner = _owner;
    }

    function getOwner(Campaign storage _campaign) internal view returns(address _owner){
        return _campaign.owner;
    }

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


interface ErrorThrower {
    event Error(string func, string message);
}

contract Ownable is ErrorThrower {
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function renounceOwnership() public onlyOwner("renounceOwnership") {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner("transferOwnership") {
        _transferOwnership(_newOwner);
    }


    function _transferOwnership(address _newOwner) internal {
        if(_newOwner == address(0)){
            emit Error("transferOwnership","New owner&#39;s address needs to be different than 0x0");
            return;
        }

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";

    modifier onlyIfWhitelisted(string _funcname, address _operator) {
        if(!hasRole(_operator, ROLE_WHITELISTED)){
            emit Error(_funcname, "Operation can only be performed by Whitelisted Addresses");
            return;
        }
        _;
    }

    function addAddressToWhitelist(address _operator)
        public
        onlyOwner("addAddressToWhitelist")
    {
        addRole(_operator, ROLE_WHITELISTED);
    }


    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }


    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner("addAddressesToWhitelist")
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner("removeAddressFromWhitelist")
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }


    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner("removeAddressesFromWhitelist")
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

}

interface StorageUser {
    function getStorageAddress() external view returns(address _storage);
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

    function _getCampaign(bytes32 campaignId)
        internal
        returns (CampaignLibrary.Campaign storage _campaign) {


        return campaigns[campaignId];
    }

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

    constructor() public {
        addAddressToWhitelist(msg.sender);
    }

    function getCampaignPriceById(bytes32 bidId)
        public
        view
        returns (uint price) {
        return campaigns[bidId].getPrice();
    }

    function setCampaignPriceById(bytes32 bidId, uint price)
        public
        onlyIfWhitelisted("setCampaignPriceById",msg.sender) 
        onlyIfCampaignExists("setCampaignPriceById",bidId)      
        {
        campaigns[bidId].setPrice(price);
        emitCampaignUpdated(campaigns[bidId]);
    }

    function getCampaignBudgetById(bytes32 bidId)
        public
        view
        returns (uint budget) {
        return campaigns[bidId].getBudget();
    }

    function setCampaignBudgetById(bytes32 bidId, uint newBudget)
        public
        onlyIfCampaignExists("setCampaignBudgetById",bidId)
        onlyIfWhitelisted("setCampaignBudgetById",msg.sender)
        {
        campaigns[bidId].setBudget(newBudget);
        emitCampaignUpdated(campaigns[bidId]);
    }

    function getCampaignStartDateById(bytes32 bidId)
        public
        view
        returns (uint startDate) {
        return campaigns[bidId].getStartDate();
    }

    function setCampaignStartDateById(bytes32 bidId, uint newStartDate)
        public
        onlyIfCampaignExists("setCampaignStartDateById",bidId)
        onlyIfWhitelisted("setCampaignStartDateById",msg.sender)
        {
        campaigns[bidId].setStartDate(newStartDate);
        emitCampaignUpdated(campaigns[bidId]);
    }

    function getCampaignEndDateById(bytes32 bidId)
        public
        view
        returns (uint endDate) {
        return campaigns[bidId].getEndDate();
    }

    function setCampaignEndDateById(bytes32 bidId, uint newEndDate)
        public
        onlyIfCampaignExists("setCampaignEndDateById",bidId)
        onlyIfWhitelisted("setCampaignEndDateById",msg.sender)
        {
        campaigns[bidId].setEndDate(newEndDate);
        emitCampaignUpdated(campaigns[bidId]);
    }

    function getCampaignValidById(bytes32 bidId)
        public
        view
        returns (bool valid) {
        return campaigns[bidId].getValidity();
    }

    function setCampaignValidById(bytes32 bidId, bool isValid)
        public
        onlyIfCampaignExists("setCampaignValidById",bidId)
        onlyIfWhitelisted("setCampaignValidById",msg.sender)
        {
        campaigns[bidId].setValidity(isValid);
        emitCampaignUpdated(campaigns[bidId]);
    }


    function getCampaignOwnerById(bytes32 bidId)
        public
        view
        returns (address campOwner) {
        return campaigns[bidId].getOwner();
    }

    function setCampaignOwnerById(bytes32 bidId, address newOwner)
        public
        onlyIfCampaignExists("setCampaignOwnerById",bidId)
        onlyIfWhitelisted("setCampaignOwnerById",msg.sender)
        {
        campaigns[bidId].setOwner(newOwner);
        emitCampaignUpdated(campaigns[bidId]);
    }

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

    function setLastBidId(bytes32 _newBidId) internal {    
        lastBidId = _newBidId;
    }

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

    function getCampaignEndPointById(bytes32 _bidId) public returns (string _endPoint){
        return campaignEndPoints[_bidId];
    }

    function setCampaignEndPointById(bytes32 _bidId, string _endPoint) 
        public 
        onlyIfCampaignExists("setCampaignEndPointById",_bidId)
        onlyIfWhitelisted("setCampaignEndPointById",msg.sender) 
        {
        campaignEndPoints[_bidId] = _endPoint;
        emit ExtendedCampaignEndPointUpdated(_bidId,_endPoint);
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

contract BaseFinance is SingleAllowance {

    mapping (address => uint256) balanceUsers;
    mapping (address => bool) userExists;

    address[] users;

    address advStorageContract;

    AppCoins appc;

    constructor (address _addrAppc) 
        public {
        appc = AppCoins(_addrAppc);
        advStorageContract = 0x0;
    }

    function setAdsStorageAddress (address _addrStorage) external onlyOwnerOrAllowed {
        reset();
        advStorageContract = _addrStorage;
    }

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

    function increaseBalance(address _user, uint256 _value) 
        public onlyAllowed{

        if(userExists[_user] == false){
            users.push(_user);
            userExists[_user] = true;
        }

        balanceUsers[_user] += _value;
    }

    function pay(address _user, address _destination, uint256 _value) public onlyAllowed;

    function withdraw(address _user, uint256 _value) public onlyOwnerOrAllowed;

    function reset() public onlyOwnerOrAllowed {
        for(uint i = 0; i < users.length; i++){
            withdraw(users[i],balanceUsers[users[i]]);
        }
    }

    function transferAllFunds(address _destination) public onlyAllowed {
        uint256 balance = appc.balanceOf(address(this));
        appc.transfer(_destination,balance);
    }

    function getUserBalance(address _user) public view onlyAllowed returns(uint256 _balance){
        return balanceUsers[_user];
    }

    function getUserList() public view onlyAllowed returns(address[] _userList){
        return users;
    }
}


contract BaseAdvertisement is StorageUser,Ownable {
    
    AppCoins appc;
    BaseFinance advertisementFinance;
    BaseAdvertisementStorage advertisementStorage;

    mapping( bytes32 => mapping(address => uint256)) userAttributions;

    bytes32[] bidIdList;
    bytes32 lastBidId = 0x0;

    constructor(address _addrAppc, address _addrAdverStorage, address _addrAdverFinance) public {
        appc = AppCoins(_addrAppc);

        advertisementStorage = BaseAdvertisementStorage(_addrAdverStorage);
        advertisementFinance = BaseFinance(_addrAdverFinance);
        lastBidId = advertisementStorage.getLastBidId();
    }

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

    function upgradeStorage (address addrAdverStorage) public onlyOwner("upgradeStorage") {
        for(uint i = 0; i < bidIdList.length; i++) {
            cancelCampaign(bidIdList[i]);
        }
        delete bidIdList;

        lastBidId = advertisementStorage.getLastBidId();
        advertisementFinance.setAdsStorageAddress(addrAdverStorage);
        advertisementStorage = BaseAdvertisementStorage(addrAdverStorage);
    }

    function getStorageAddress() public view returns(address storageContract) {
        require (msg.sender == address(advertisementFinance));

        return address(advertisementStorage);
    }

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
        if(appc.allowance(msg.sender, address(this)) < budget){
            emit Error("createCampaign","Not enough allowance");
            return;
        }

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

    function cancelCampaign (bytes32 bidId) public {
        address campaignOwner = getOwnerOfCampaign(bidId);

		// Only contract owner or campaign owner can cancel a campaign
        require(owner == msg.sender || campaignOwner == msg.sender);
        uint budget = getBudgetOfCampaign(bidId);

        advertisementFinance.withdraw(campaignOwner, budget);

        advertisementStorage.setCampaignBudgetById(bidId, 0);
        advertisementStorage.setCampaignValidById(bidId, false);
    }

    function getCampaignValidity(bytes32 bidId) public view returns(bool state){
        return advertisementStorage.getCampaignValidById(bidId);
    }

    function getPriceOfCampaign (bytes32 bidId) public view returns(uint price) {
        return advertisementStorage.getCampaignPriceById(bidId);
    }

    function getStartDateOfCampaign (bytes32 bidId) public view returns(uint startDate) {
        return advertisementStorage.getCampaignStartDateById(bidId);
    }

    function getEndDateOfCampaign (bytes32 bidId) public view returns(uint endDate) {
        return advertisementStorage.getCampaignEndDateById(bidId);
    }

    function getBudgetOfCampaign (bytes32 bidId) public view returns(uint budget) {
        return advertisementStorage.getCampaignBudgetById(bidId);
    }

    function getOwnerOfCampaign (bytes32 bidId) public view returns(address campaignOwner) {
        return advertisementStorage.getCampaignOwnerById(bidId);
    }

    function getBidIdList() public view returns(bytes32[] bidIds) {
        return bidIdList;
    }

    function _getBidIdList() internal returns(bytes32[] storage bidIds){
        return bidIdList;
    }

    function isCampaignValid(bytes32 bidId) public view returns(bool valid) {
        uint startDate = advertisementStorage.getCampaignStartDateById(bidId);
        uint endDate = advertisementStorage.getCampaignEndDateById(bidId);
        bool validity = advertisementStorage.getCampaignValidById(bidId);

        uint nowInMilliseconds = now * 1000;
        return validity && startDate < nowInMilliseconds && endDate > nowInMilliseconds;
    }

    function division(uint numerator, uint denominator) public view returns (uint result) {
        uint _quotient = numerator / denominator;
        return _quotient;
    }

    function uintToBytes (uint256 i) public view returns(bytes32 b) {
        b = bytes32(i);
    }

    function bytesToUint(bytes32 b) public view returns (uint) 
    {
        return uint(b) & 0xfff;
    }

}


contract ExtendedAdvertisement is BaseAdvertisement, Whitelist {

    event BulkPoARegistered(bytes32 bidId,bytes32 rootHash,bytes32 signedrootHash,uint256 newPoAs,uint256 convertedPoAs);
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
    }


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

    function bulkRegisterPoA(bytes32 bidId,bytes32 rootHash,bytes32 signedRootHash, uint256 newHashes) 
        public 
        onlyIfWhitelisted("createCampaign",msg.sender)
        {
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

    function withdraw() 
        public 
        onlyIfWhitelisted("withdraw",msg.sender)
        {
        uint256 balance = _getFinance().getUserBalance(msg.sender);
        _getFinance().withdraw(msg.sender,balance);
    }

    function getBalance()
        public 
        onlyIfWhitelisted("withdraw",msg.sender)
        returns (uint256 _balance)
        {
        return _getFinance().getUserBalance(msg.sender);    
    }

    function getEndPointOfCampaign (bytes32 bidId) public view returns (string url){
        return ExtendedAdvertisementStorage(address(_getStorage())).getCampaignEndPointById(bidId);
    }
}