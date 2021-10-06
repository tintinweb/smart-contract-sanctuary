/*
  
    
=======================================================================================

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
=======================================================================================
*/

pragma solidity ^0.8.0;

import './Context.sol';
import './Address.sol';
import './SafeMath.sol';
import './IERC20.sol';
import './ERC721.sol';
import './Payment.sol';
import './StringUtils.sol';

contract SideKickNames {
    
    // Import Address and SafeMath libraries
    using Address for address;
    using SafeMath for uint256;
    
    /////////////////////////////////
    // CONFIGURABLES AND VARIABLES //
    /////////////////////////////////

    address payable public devWallet;
    address payable public feeCollector;

    struct Subscription {
        uint planId;
        uint tier;
    }
    struct SubRedemption{
        bool nameRedemption;
        bool nftRedemption;
    }
    
    uint256 public price;
    uint256 public taxedPrice;
    uint256 public txs;
    IERC20 public rooted;
    Payment subscription; 
    
    ///////////////////
    // DATA MAPPINGS //
    ///////////////////
    
    mapping(address => string) private addressNameMap; // Used to find usernames tied to an address.
    mapping(address=> address) private addressNFTMap; //Map user to NFT Address, put in user address and spit out the NFT Contract currently tied to account for profile picture 
    mapping(string => address) private nameAddressMap; // Used to find addresses tied to a username.
    mapping(string => address) private nameAddressUpperCaseMap; // Used to find addresses tied to a username.
    mapping(uint => uint) private planIdMapping;
    mapping(uint => Subscription) private planTierMap;
    //todo ctrl z
    mapping(address => SubRedemption) public redeemedSubscriptionNaming;
    // Blacklists for names and addresses
    // You really don't wanna end up on these lists...
    mapping(address => bool) internal _isBlacklistedAddress;
    mapping(string => bool) internal _isBlacklistedName;
    
    // Track list of Super Sidekicks (addresses which can control this contract)
    mapping(address => bool) internal _isSuperSidekick;
    uint subscriptionPlans = 0;
    ////////////////////////
    // CONTRACT MODIFIERS //
    ////////////////////////
    
    // Only owner
    modifier onlyOwner() {
        require(msg.sender == devWallet, "Owner required");
        _;
    }
    
    // Only Sidekicks - They're in charge when the owneris not...
    modifier onlySuperSidekick() {
        require(_isSuperSidekick[msg.sender], "Address is not a Super Sidekick");
        _;
    }
    
    /////////////////////
    // CONTRACT EVENTS //
    /////////////////////

    event onSetNameForAddress(address indexed caller, address addr, string name, bool _isContract);
    
    event onUpdateBlacklistForAddress(address indexed _blacklistedAddress, address indexed _sidekick, uint256 _timestamp, string _reason);
    event onUpdateBlacklistForName(string _blacklistedName, string _reason, uint256 _timestamp);
    
    event onToggleSuperSidekick(address indexed caller, address indexed _user, bool _status, uint256 timestamp);

    event onCollectFunds(address indexed caller, uint256 _amount, uint256 _timestamp);
    
    event onSetPrice(address indexed caller, uint256 oldPrice, uint256 newPrice, uint256 _timestamp);
    
    event onReceiveDonation(uint256 _amount, uint256 _timestamp);

    //////////////////////////////
    // CONSTRUCTOR AND FALLBACK //
    //////////////////////////////
    
    constructor(IERC20 _rooted, address payable _dev, address payable _feeCollector, Payment _subscription ) {
        rooted = _rooted;
        //100 Rooted / SK
        price = 1e20;
        taxedPrice = 5e20;
        subscription = _subscription;
        devWallet = _dev;
        feeCollector = _feeCollector;
        _isSuperSidekick[devWallet] = true;
        
    }
    
    receive () external payable {
        emit onReceiveDonation(msg.value, block.timestamp);
    }
    
    ///////////////////////////
    // PUBLIC VIEW FUNCTIONS //
    ///////////////////////////
    
    // Find an address by its Sidekick Name
    function getAddressByName(string memory name) public view returns (address) {
        return nameAddressMap[name];
    }
    
    // Find if an address owns a Sidekick Name
    function getNameByAddress(address addr) public view returns (string memory name) {
        return addressNameMap[addr];
    }
    function getNFTbyHeroAddress(address addr) public view returns(address){
        //Check if user still holds NFT 
        if (addressNFTMap[addr] != address(0)){
            address nftAddress = addressNFTMap[addr];
            if (_checkForNFT721(addr, nftAddress) != true){
                return address(0);
            }
        }
        
     return addressNFTMap[addr];
    }
    
    // Check if a Sidekick Name is available...
    function checkAvailability(string memory name) public view returns (bool) {
        string memory upperCaseName = StringUtils.upper(name);

        // Validate characters in the name...
        if (_checkCharacters(bytes(name))) {
            //check that username is not in use
          return (nameAddressUpperCaseMap[upperCaseName] == address(0));
        }
        return false;
    }
    
    // Check if a name is on the blacklist...
    function checkIsBlacklistedName(string memory name) public view returns (bool) {
        return _isBlacklistedName[name];
    }
    
    // Check if an address is banned or not...
    function checkIsBlacklistedAddress(address addr) public view returns (bool) {
        return _isBlacklistedAddress[addr];
    }
    function _checkSubscribed(address sender) internal view returns (uint planTier){
        for (uint i = 0; i < subscriptionPlans; i++){
            bool isSubbed = subscription.checkSubscription(planIdMapping[subscriptionPlans], sender);
            if (isSubbed == true){
                planTier = planTierMap[i].tier;
                return planTier;
            }
        }
        return 0;
    }
    

    
    ///////////////////////////////////////
    // PUBLIC & EXTERNAL WRITE FUNCTIONS //
    ///////////////////////////////////////
    
    // Set a name. Caller's address receives the name passed as the _name argument.
    function setNameRecord(string calldata _name) public returns (bool _success) {	
        bool _isNamed;	
        if(keccak256(abi.encodePacked(getNameByAddress(msg.sender))) == keccak256(abi.encodePacked(""))){	
            _isNamed = false;	
        } else {	
            _isNamed = true;	
        }	
        	
        address _addr = msg.sender;	
        uint subscriptionCheck = _checkSubscribed(_addr);
        //tier 0 means user not subscribed
        if(subscriptionCheck == 0){
            payRooted(_isNamed);
            //tier one subscription pays for name after first payment	
        }if (subscriptionCheck == 1 && _isNamed == true && redeemedSubscriptionNaming[msg.sender].nameRedemption == true){
            redeemedSubscriptionNaming[msg.sender].nameRedemption = true;
            payRooted(_isNamed);
        } if (subscriptionCheck > 0 && redeemedSubscriptionNaming[msg.sender].nameRedemption == false){
            redeemedSubscriptionNaming[msg.sender].nameRedemption == true;
        }
        	
        return _setNameRecord(_addr, _name);	
    }
    function setNFT721(address _nftAddr) public returns (bool _success){
        address _addr = msg.sender;
        uint subscriptionCheck = _checkSubscribed(_addr);
        if(subscriptionCheck == 0){
            if (getNFTbyHeroAddress(_addr) == address(0)){
                payRooted(false);
                return _setNFTRecord(_addr, _nftAddr);    
            } else {
                payRooted(true);
            }
        }
        if(subscriptionCheck == 1 && getNFTbyHeroAddress(_addr) != address(0) && redeemedSubscriptionNaming[_addr].nftRedemption == true){
            redeemedSubscriptionNaming[_addr].nftRedemption = true;
            payRooted(true);
        } if (subscriptionCheck > 0 && redeemedSubscriptionNaming[msg.sender].nftRedemption == false){
            redeemedSubscriptionNaming[msg.sender].nftRedemption == true;
        }
        
        
        return _setNFTRecord(_addr, _nftAddr);
    }
    function payRooted(bool isNamed) private returns (bool _success) {	
        if (isNamed){	
            rooted.transferFrom(msg.sender, address(this), taxedPrice);	
        } else {
            rooted.transferFrom(msg.sender, address(this), price);
        }	
        	
        return _success;	
    }
    
    function setNameRecordOf(address _addr, string calldata _name) onlySuperSidekick() public returns (bool _success) {
        return _setNameRecord(_addr, _name);
    }
    function setEligiblePlans(uint planId, uint tier) onlyOwner() public {
        planIdMapping[subscriptionPlans] = planId;
        
        planTierMap[subscriptionPlans] = Subscription(planId, tier);
        subscriptionPlans++;
    }


    // Distribute the tokens received from buybacks to the recipient
    function sweep() public returns (bool _success) {

        // Get the whole balance of this contract...
        uint _balance = address(this).balance;
        uint _rootedBal = rooted.balanceOf(address(this));
        
        // Transfer it to the recipient...
        devWallet.transfer(_balance);
        rooted.transfer(devWallet, _rootedBal);
        
        // Tell the network, successful function!
        emit onCollectFunds(devWallet, _balance, block.timestamp);
        return true;
    }

    ///////////////////////////////////////
    // Sidekick-ONLY FUNCTIONS                 //
    ///////////////////////////////////////
    
    function setBlacklistAddressStatus(address _addr, bool _isBlacklisted, string memory _reason) onlySuperSidekick() public returns (bool _success) {
        require(!_isSuperSidekick[_addr], "Cannot blacklist an Super Sidekick!");
        
        _isBlacklistedAddress[_addr] = _isBlacklisted;
        
        // Tell the network, successful function!
        emit onUpdateBlacklistForAddress(_addr, msg.sender, block.timestamp, _reason);
        return true;
    }
    
    function setBlacklistNameStatus(string memory _name, string memory _reason) onlySuperSidekick() public returns (bool _success) {
        require(!_isSuperSidekick[getAddressByName(_name)], "Cannot blacklist an Super Sidekick!");
        
        _isBlacklistedName[_name] = true;
        
        // Tell the network, successful function!
        emit onUpdateBlacklistForName(_name, _reason, block.timestamp);
        return true;
    }
    
    ///////////////////////////////////////
    // Owner-ONLY FUNCTIONS                //
    ///////////////////////////////////////
    
    // This function allows the owner to add users to and remove users from a whitelist.
    function toggleSuperSidekick(address _user) public onlyOwner() returns (bool _success) {
        return _toggleSuperSidekick(_user);
    }
    
    // This function allows the Owner to choose where this contract's fees should go.
    function setPrice(uint256 _price) public onlyOwner() returns (bool _success) {
        
        uint256 _oldPrice = price;
        price = _price;
        
        emit onSetPrice(msg.sender, _oldPrice, price, block.timestamp);
        return true;
    }
    // This function allows the Owner to choose where this contract's fees should go.
    function setTaxedPrice(uint256 _price) public onlyOwner() returns (bool _success) {
        
        //uint256 _oldPrice = price;
        taxedPrice = _price;
        
        //emit onSetPrice(msg.sender, _oldPrice, price, block.timestamp);
        return true;
    }
    function setNewSubscription(Payment _contract) public onlyOwner() {
        subscription = _contract;
    }
    function setCollector(address payable _address) public onlyOwner(){
        feeCollector = _address;
    }
    function setNewPaymentToken(IERC20 _contract) public onlyOwner(){
        rooted = _contract;
    }
    //////////////////////////////////
    // INTERNAL & PRIVATE FUNCTIONS //
    //////////////////////////////////
    
    // Incremental Tx counter
    function _countTx() internal {
        txs += 1;
    }
    
    // Set name record
    function _setNameRecord(address _addr, string memory _name) internal returns (bool) {
        require(!_isBlacklistedAddress[_addr], "address is blacklisted!");
        require(!_isBlacklistedName[_name], "name is blacklisted!");
        
        require(bytes(_name).length <= 64, "name must be fewer than 64 bytes");
        require(bytes(_name).length >= 3, "name must be more than 3 bytes");
        
        require(_checkCharacters(bytes(_name)));

        require(nameAddressMap[_name] == address(0), "name in use");
        
        string memory oldName = addressNameMap[_addr];
        
        if (bytes(oldName).length > 0) {nameAddressMap[oldName] = address(0);}
        
        addressNameMap[_addr] = _name;
        nameAddressMap[_name] = _addr;
        //add uppercase name to mapping for comparison
        nameAddressUpperCaseMap[StringUtils.upper(_name)] = _addr; 
        // Count the Tx...
        _countTx();
        
        // Tell the network, successful function!
        emit onSetNameForAddress(msg.sender, _addr, _name, (Address.isContract(_addr)));
        return true;
    }
    
    function _setNFTRecord(address _addr,address _nftAddr) internal returns (bool){
        require(!_isBlacklistedAddress[_nftAddr], "address is blacklisted!");
        require(_checkForNFT721(_addr, _nftAddr) == true, "Must hold NFT in your wallet");

        addressNFTMap[_addr] = _nftAddr;
        return true;


    }
    function _checkForNFT721(address _addr, address _nftAddr) internal view returns (bool){
        ERC721 nft = ERC721(_nftAddr);
        if (nft.balanceOf(_addr) > 0){
            return true;
        }
        return false;
    }
    
    // Toggle Sidekick Powers on or off
    function _toggleSuperSidekick(address _addr) internal returns (bool) {
        
        // Log current status and switch...
        bool _status = _isSuperSidekick[_addr];
        _isSuperSidekick[_addr] = !_status;
        
        // Tell the network, successful function!
        emit onToggleSuperSidekick(msg.sender, _addr, _isSuperSidekick[_addr], block.timestamp);
        return true;
    }
    
    // Validation
    function _checkCharacters(bytes memory name) internal pure returns (bool) {
        
        // Check for only letters and numbers
        for(uint i; i<name.length; i++){
            
            bytes1 char = name[i];
            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A)    //a-z
            )
            
            // invalid characters
            return false;
        }
        
        // valid characters
        return true;
    }
    
    function _isSidekick(address _addr) internal view returns (bool) {
        return _isSuperSidekick[_addr];
    }
    
    function _isOwner(address _addr) internal view returns (bool) {
        return (_addr == devWallet);
    }
}