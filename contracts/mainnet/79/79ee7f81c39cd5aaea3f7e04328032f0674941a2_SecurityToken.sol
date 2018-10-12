pragma solidity  ^0.4.23;

/**
 *  SafeMath <https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol/>
 *  Copyright (c) 2016 Smart Contract Solutions, Inc.
 *  Released under the MIT License (MIT)
 */

/// @title Math operations with safety checks
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor () public {
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
   * @dev Allows the current owner t o transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/// ERC Token Standard #20 Interface (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md)
interface IERC20 {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function totalSupply() external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface ISecurityToken {


    /**
     * @dev Add a verified address to the Security Token whitelist
     * @param _whitelistAddress Address attempting to join ST whitelist
     * @return bool success
     */
    function addToWhitelist(address _whitelistAddress) public returns (bool success);

    /**
     * @dev Add verified addresses to the Security Token whitelist
     * @param _whitelistAddresses Array of addresses attempting to join ST whitelist
     * @return bool success
     */
    function addToWhitelistMulti(address[] _whitelistAddresses) external returns (bool success);

    /**
     * @dev Removes a previosly verified address to the Security Token blacklist
     * @param _blacklistAddress Address being added to the blacklist
     * @return bool success
     */
    function addToBlacklist(address _blacklistAddress) public returns (bool success);

    /**
     * @dev Removes previously verified addresseses to the Security Token whitelist
     * @param _blacklistAddresses Array of addresses attempting to join ST whitelist
     * @return bool success
     */
    function addToBlacklistMulti(address[] _blacklistAddresses) external returns (bool success);

    /// Get token decimals
    function decimals() view external returns (uint);


    // @notice it will return status of white listing
    // @return true if user is white listed and false if is not
    function isWhiteListed(address _user) external view returns (bool);
}

// The  Exchange token
contract SecurityToken is IERC20, Ownable, ISecurityToken {

    using SafeMath for uint;
    // Public variables of the token
    string public name;
    string public symbol;
    uint public decimals; // How many decimals to show.
    string public version;
    uint public totalSupply;
    uint public tokenPrice;
    bool public exchangeEnabled;    
    bool public codeExportEnabled;
    address public commissionAddress;           // address to deposit commissions
    uint public deploymentCost;                 // cost of deployment with exchange feature
    uint public tokenOnlyDeploymentCost;        // cost of deployment with basic ERC20 feature
    uint public exchangeEnableCost;             // cost of upgrading existing ERC20 to exchange feature
    uint public codeExportCost;                 // cost of exporting the code
    string public securityISIN;


    // Security token shareholders
    struct Shareholder {                        // Structure that contains the data of the shareholders        
        bool allowed;                           // allowed - whether the shareholder is allowed to transfer or recieve the security token       
        uint receivedAmt;
        uint releasedAmt;
        uint vestingDuration;
        uint vestingCliff;
        uint vestingStart;
    }

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    mapping(address => Shareholder) public shareholders; // Mapping that holds the data of the shareholder corresponding to investor address


    modifier onlyWhitelisted(address _to) {
        require(shareholders[_to].allowed && shareholders[msg.sender].allowed);
        _;
    }


    modifier onlyVested(address _from) {

        require(availableAmount(_from) > 0);
        _;
    }

    // The Token constructor     
    constructor (
        uint _initialSupply,
        string _tokenName,
        string _tokenSymbol,
        uint _decimalUnits,        
        string _version,                       
        uint _tokenPrice,
        string _securityISIN
                        ) public payable
    {

        totalSupply = _initialSupply * (10**_decimalUnits);                                             
        name = _tokenName;          // Set the name for display purposes
        symbol = _tokenSymbol;      // Set the symbol for display purposes
        decimals = _decimalUnits;   // Amount of decimals for display purposes
        version = _version;         // Version of token
        tokenPrice = _tokenPrice;   // Token price in Wei     
        securityISIN = _securityISIN;// ISIN security registration number        
            
        balances[owner] = totalSupply;    

        deploymentCost = 25e17;             
        tokenOnlyDeploymentCost = 15e17;
        exchangeEnableCost = 15e17;
        codeExportCost = 1e19;   

        codeExportEnabled = true;
        exchangeEnabled = true;  
            
        commissionAddress = 0x80eFc17CcDC8fE6A625cc4eD1fdaf71fD81A2C99;                                   
        commissionAddress.transfer(msg.value);       
        addToWhitelist(owner);  

    }

    event LogTransferSold(address indexed to, uint value);
    event LogTokenExchangeEnabled(address indexed caller, uint exchangeCost);
    event LogTokenExportEnabled(address indexed caller, uint enableCost);
    event LogNewWhitelistedAddress( address indexed shareholder);
    event LogNewBlacklistedAddress(address indexed shareholder);
    event logVestingAllocation(address indexed shareholder, uint amount, uint duration, uint cliff, uint start);
    event logISIN(string isin);



    function updateISIN(string _securityISIN) external onlyOwner() {

        bytes memory tempISIN = bytes(_securityISIN);

        require(tempISIN.length > 0);  // ensure that ISIN has been passed
        securityISIN = _securityISIN;// ISIN security registration number  
        emit logISIN(_securityISIN);  
    }

    function allocateVestedTokens(address _to, uint _value, uint _duration, uint _cliff, uint _vestingStart ) 
                                  external onlyWhitelisted(_to) onlyOwner() returns (bool) 
    {

        require(_to != address(0));        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);        
        if (shareholders[_to].receivedAmt == 0) {
            shareholders[_to].vestingDuration = _duration;
            shareholders[_to].vestingCliff = _cliff;
            shareholders[_to].vestingStart = _vestingStart;
        }
        shareholders[_to].receivedAmt = shareholders[_to].receivedAmt.add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        emit logVestingAllocation(_to, _value, _duration, _cliff, _vestingStart);
        return true;
    }

    function availableAmount(address _from) public view returns (uint256) {                
        
        if (block.timestamp < shareholders[_from].vestingCliff) {            
            return balanceOf(_from).sub(shareholders[_from].receivedAmt);
        } else if (block.timestamp >= shareholders[_from].vestingStart.add(shareholders[_from].vestingDuration)) {
            return balanceOf(_from);
        } else {
            uint totalVestedBalance = shareholders[_from].receivedAmt;
            uint totalAvailableVestedBalance = totalVestedBalance.mul(block.timestamp.sub(shareholders[_from].vestingStart)).div(shareholders[_from].vestingDuration);
            uint lockedBalance = totalVestedBalance - totalAvailableVestedBalance;
            return balanceOf(_from).sub(lockedBalance);
        }
    }

    // @noice To be called by owner of the contract to enable exchange functionality
    // @param _tokenPrice {uint} cost of token in ETH
    // @return true {bool} if successful
    function enableExchange(uint _tokenPrice) public payable {
        
        require(!exchangeEnabled);
        require(exchangeEnableCost == msg.value);
        exchangeEnabled = true;
        tokenPrice = _tokenPrice;
        commissionAddress.transfer(msg.value);
        emit LogTokenExchangeEnabled(msg.sender, _tokenPrice);                          
    }

    // @notice to enable code export functionality
    function enableCodeExport() public payable {   
        
        require(!codeExportEnabled);
        require(codeExportCost == msg.value);     
        codeExportEnabled = true;
        commissionAddress.transfer(msg.value);  
        emit LogTokenExportEnabled(msg.sender, msg.value);        
    }

    // @notice It will send tokens to sender based on the token price    
    function swapTokens() public payable onlyWhitelisted(msg.sender) {     

        require(exchangeEnabled);   
        uint tokensToSend;
        tokensToSend = (msg.value * (10**decimals)) / tokenPrice; 
        require(balances[owner] >= tokensToSend);
        balances[msg.sender] = balances[msg.sender].add(tokensToSend);
        balances[owner] = balances[owner].sub(tokensToSend);
        owner.transfer(msg.value);
        emit Transfer(owner, msg.sender, tokensToSend);
        emit LogTransferSold(msg.sender, tokensToSend);       
    }

    // @notice will be able to mint tokens in the future
    // @param _target {address} address to which new tokens will be assigned
    // @parm _mintedAmount {uint256} amouont of tokens to mint
    function mintToken(address _target, uint256 _mintedAmount) public onlyWhitelisted(_target) onlyOwner() {        
        
        balances[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        emit Transfer(0, _target, _mintedAmount);       
    }
  
    // @notice transfer tokens to given address
    // @param _to {address} address or recipient
    // @param _value {uint} amount to transfer
    // @return  {bool} true if successful
    function transfer(address _to, uint _value) external onlyVested(_to) onlyWhitelisted(_to)  returns(bool) {

        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice transfer tokens from given address to another address
    // @param _from {address} from whom tokens are transferred
    // @param _to {address} to whom tokens are transferred
    // @param _value {uint} amount of tokens to transfer
    // @return  {bool} true if successful
    function transferFrom(address _from, address _to, uint256 _value) 
                          external onlyVested(_to)  onlyWhitelisted(_to) returns(bool success) {

        require(_to != address(0));
        require(balances[_from] >= _value); // Check if the sender has enough
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal

        balances[_from] = balances[_from].sub(_value); // Subtract from the sender
        balances[_to] = balances[_to].add(_value); // Add the same to the recipient
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // adjust allowed
        emit Transfer(_from, _to, _value);
        return true;
    }

    // @notice to query balance of account
    // @return _owner {address} address of user to query balance
    function balanceOf(address _owner) public view returns(uint balance) {
        return balances[_owner];
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
    function approve(address _spender, uint _value) external returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // @notice to query of allowance of one user to the other
    // @param _owner {address} of the owner of the account
    // @param _spender {address} of the spender of the account
    // @return remaining {uint} amount of remaining allowance
    function allowance(address _owner, address _spender) external view returns(uint remaining) {
        return allowed[_owner][_spender];
    }

    /**
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     /**
     * @dev Add a verified address to the Security Token whitelist
     * The Issuer can add an address to the whitelist by themselves by
     * creating their own KYC provider and using it to verify the accounts
     * they want to add to the whitelist.
     * @param _whitelistAddress Address attempting to join ST whitelist
     * @return bool success
     */
    function addToWhitelist(address _whitelistAddress) onlyOwner public returns (bool success) {       
        shareholders[_whitelistAddress].allowed = true;
        emit LogNewWhitelistedAddress(_whitelistAddress);
        return true;
    }

    /**
     * @dev Add verified addresses to the Security Token whitelist
     * @param _whitelistAddresses Array of addresses attempting to join ST whitelist
     * @return bool success
     */
    function addToWhitelistMulti(address[] _whitelistAddresses) onlyOwner external returns (bool success) {
        for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
            addToWhitelist(_whitelistAddresses[i]);
        }
        return true;
    }

    /**
     * @dev Add a verified address to the Security Token blacklist
     * @param _blacklistAddress Address being added to the blacklist
     * @return bool success
     */
    function addToBlacklist(address _blacklistAddress) onlyOwner public returns (bool success) {
        require(shareholders[_blacklistAddress].allowed);
        shareholders[_blacklistAddress].allowed = false;
        emit LogNewBlacklistedAddress(_blacklistAddress);
        return true;
    }

    /**
     * @dev Removes previously verified addresseses to the Security Token whitelist
     * @param _blacklistAddresses Array of addresses attempting to join ST whitelist
     * @return bool success
     */
    function addToBlacklistMulti(address[] _blacklistAddresses) onlyOwner external returns (bool success) {
        for (uint256 i = 0; i < _blacklistAddresses.length; i++) {
            addToBlacklist(_blacklistAddresses[i]);
        }
        return true;
    }

    // @notice it will return status of white listing
    // @return true if user is white listed and false if is not
    function isWhiteListed(address _user) external view returns (bool) {

        return shareholders[_user].allowed;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function decimals() external view returns (uint) {
        return decimals;
    }

}