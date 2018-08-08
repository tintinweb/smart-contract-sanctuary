pragma solidity ^ 0.4.17;


library SafeMath {

    function mul(uint a, uint b) internal pure returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal pure  returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal  pure returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}


contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns(uint);

    function allowance(address owner, address spender) public view returns(uint);

    function transfer(address to, uint value) public returns(bool ok);

    function transferFrom(address from, address to, uint value) public returns(bool ok);

    function approve(address spender, uint value) public returns(bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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
    function Ownable() public {
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
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


// DeployTokenContract Smart Contract 
// This smart contract collects ETH and in return creates Token contract
// based on the amount of money sent it will create two kinds of contract
// 1. Simple ERC20 token contract
// 2. As aboove with option to purchase tokens with set exchange rate to ETH
contract DeployTokenContract is Ownable {
    
    address public commissionAddress;           // address to deposit commissions
    uint public deploymentCost;                 // cost of deployment with exchange feature
    uint public tokenOnlyDeploymentCost;        // cost of deployment with basic ERC20 feature
    uint public exchangeEnableCost;             // cost of upgrading existing ERC20 to exchange feature
    uint public codeExportCost;                 // cost of exporting the code
    MultiToken multiToken;                      // ERC20 token with exchange feature

    event TokenDeployed(address newToken, uint amountPaid);    
    event ExchangeEnabled(address token, uint amountPaid);
    event CodeExportEnabled(address sender);

    // @notice deploy token with exchnge functionality
    // @param _initialSupply {uint} initial supply of token
    // @param _tokenName {string} name of token
    // @param _decimalUnits {uint} how many decimal units token will have
    // @param _tokenSymbol {string} ticker for the token
    // @param _version {string} version of the token
    // @param _tokenPriceETH {uint} price of token for exchange functionality
    function deployMultiToken () public returns (address) {

        MultiToken token;

        token = new MultiToken();                                                       
        TokenDeployed(token, 0);
        return token;                                                
    }   

    // @notice to enable code export functionality
    // @param _token {address} to token contract 
    function enableCodeExport(address _token) public payable {

        require(msg.value == codeExportCost);
        require(_token != address(0));
        multiToken = MultiToken(_token);
        if (!multiToken.enableCodeExport())
            revert();
        commissionAddress.transfer(msg.value); 
        CodeExportEnabled(msg.sender);
    }

}


// The  Exchange token
contract MultiToken is ERC20, Ownable {

    using SafeMath for uint;
    // Public variables of the token
    string public name;
    string public symbol;
    uint public decimals; // How many decimals to show.
    string public version;
    uint public totalSupply;
    uint public tokenPrice;
    bool public exchangeEnabled;
    address public parentContract;
    bool public codeExportEnabled;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    modifier onlyAuthorized() {
        if (msg.sender != parentContract) 
            revert();
        _;
    }

    // The Token constructor     
    function MultiToken() public 
    {

        totalSupply = 10000 * (10**8);                                             
        name = "ICO";          // Set the name for display purposes
        symbol = "ICO";      // Set the symbol for display purposes
        decimals = 8;   // Amount of decimals for display purposes
        version = "1.0";         // Version of token
        tokenPrice = 1 ether / 100;   // Token price in ETH
        codeExportEnabled = true; // If true allow code export
        exchangeEnabled = true;
        balances[owner] = totalSupply;    
        parentContract = msg.sender;    // save parent contract address to allow enabling of exchange                                       // feature if required later for onlyAuthorized()
    }

    event TransferSold(address indexed to, uint value);

    // @noice To be called by parent contract to enable exchange functionality
    // @param _tokenPrice {uint} costo of token in ETH
    // @return true {bool} if successful
    function enableExchange(uint _tokenPrice) public onlyAuthorized() returns(bool) {
        exchangeEnabled = true;
        tokenPrice = _tokenPrice;
        return true; 
    }

        // @notice to enable code export functionality
    function enableCodeExport() public onlyAuthorized() returns(bool) {        
        codeExportEnabled = true;
        return true;
    }

    // @notice It will send tokens to sender based on the token price    
    function swapTokens() public payable {     

        require(exchangeEnabled);   
        uint tokensToSend;
        tokensToSend = (msg.value * (10**decimals)) / tokenPrice; 
        require(balances[owner] >= tokensToSend);
        balances[msg.sender] += tokensToSend;
        balances[owner] -= tokensToSend;
        Transfer(owner, msg.sender, tokensToSend);
        TransferSold(msg.sender, tokensToSend);       
    }

    // @notice will be able to mint tokens in the future
    // @param _target {address} address to which new tokens will be assigned
    // @parm _mintedAmount {uint256} amouont of tokens to mint
    function mintToken(address _target, uint256 _mintedAmount) public onlyOwner() {        
        
        balances[_target] += _mintedAmount;
        totalSupply += _mintedAmount;
        Transfer(0, _target, _mintedAmount);       
    }
  
    // @notice transfer tokens to given address
    // @param _to {address} address or recipient
    // @param _value {uint} amount to transfer
    // @return  {bool} true if successful
    function transfer(address _to, uint _value) public returns(bool) {

        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // @notice transfer tokens from given address to another address
    // @param _from {address} from whom tokens are transferred
    // @param _to {address} to whom tokens are transferred
    // @param _value {uint} amount of tokens to transfer
    // @return  {bool} true if successful
    function transferFrom(address _from, address _to, uint256 _value) public  returns(bool success) {

        require(_to != address(0));
        require(balances[_from] >= _value); // Check if the sender has enough
        require(_value <= allowed[_from][msg.sender]); // Check if allowed is greater or equal
        balances[_from] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient
        allowed[_from][msg.sender] -= _value;  // adjust allowed
        Transfer(_from, _to, _value);
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
    function approve(address _spender, uint _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    // @notice to query of allowance of one user to the other
    // @param _owner {address} of the owner of the account
    // @param _spender {address} of the spender of the account
    // @return remaining {uint} amount of remaining allowance
    function allowance(address _owner, address _spender) public view returns(uint remaining) {
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
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}