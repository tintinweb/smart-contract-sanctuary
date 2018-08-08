pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
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
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}



/**
 * @title Authorizable
 * @dev Allows to authorize access to certain function calls
 *
 * ABI
 * [{"constant":true,"inputs":[{"name":"authorizerIndex","type":"uint256"}],"name":"getAuthorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"}],"name":"addAuthorized","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"isAuthorized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"}]
 */
contract Authorizable {

    address[] authorizers;
    mapping(address => uint) authorizerIndex;

    /**
     * @dev Throws if called by any account tat is not authorized.
     */
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

    /**
     * @dev Contructor that authorizes the msg.sender.
     */
    function Authorizable() {
        authorizers.length = 2;
        authorizers[1] = msg.sender;
        authorizerIndex[msg.sender] = 1;
    }

    /**
     * @dev Function to get a specific authorizer
     * @param authorizerIndex index of the authorizer to be retrieved.
     * @return The address of the authorizer.
     */
    function getAuthorizer(uint authorizerIndex) external constant returns(address) {
        return address(authorizers[authorizerIndex + 1]);
    }

    /**
     * @dev Function to check if an address is authorized
     * @param _addr the address to check if it is authorized.
     * @return boolean flag if address is authorized.
     */
    function isAuthorized(address _addr) constant returns(bool) {
        return authorizerIndex[_addr] > 0;
    }

    /**
     * @dev Function to add a new authorizer
     * @param _addr the address to add as a new authorizer.
     */
    function addAuthorized(address _addr) external onlyAuthorized {
        authorizerIndex[_addr] = authorizers.length;
        authorizers.length++;
        authorizers[authorizers.length - 1] = _addr;
    }

}

/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        require(assertion);
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require( ! ((_value != 0) && (allowed[msg.sender][_spender] != 0)) );

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifing the amount of tokens still avaible for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}






/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint value);
    event MintFinished();

    bool public mintingFinished = false;
    uint public totalSupply = 0;


    modifier canMint() {
        require(! mintingFinished);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}






/**
 * @title TopChainToken
 * @dev The main TPC token contract
 *
 * ABI
 * [{"constant":true,"inputs":[],"name":"mintingFinished","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"startTrading","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"tradingStarted","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[],"name":"MintFinished","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]
 */
contract TopCoin is MintableToken {

    string public name = "TopCoin";
    string public symbol = "TPC";
    uint public decimals = 6;

    bool public tradingStarted = false;

    /**
     * @dev modifier that throws if trading has not started yet
     */
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

    /**
     * @dev Allows the owner to enable the trading. This can not be undone
     */
    function startTrading() onlyOwner {
        tradingStarted = true;
    }

    /**
     * @dev Allows anyone to transfer the PAY tokens once trading has started
     * @param _to the recipient address of the tokens.
     * @param _value number of tokens to be transfered.
     */
    function transfer(address _to, uint _value) hasStartedTrading {
        super.transfer(_to, _value);
    }

    /**
    * @dev Allows anyone to transfer the PAY tokens once trading has started
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
        super.transferFrom(_from, _to, _value);
    }

}


/**
 * @title TopCoinDistribution
 * @dev The main TPC token sale contract
 *
 * ABI
 */
contract TopCoinDistribution is Ownable, Authorizable {
    using SafeMath for uint;
    event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
    event AuthorizedCreate(address recipient, uint pay_amount);
    event TopCoinSaleClosed();

    TopCoin public token = new TopCoin();

    address public multisigVault;

    uint public hardcap = 87500 ether;

    uint public rate = 3600*(10 ** 6); //1 ether : 3600 tpc

    uint totalToken = 2100000000 * (10 ** 6); //tpc

    uint public authorizeMintToken = 210000000 * (10 ** 6); //tpc

    uint public altDeposits = 0; //ether

    uint public start = 1504008000; //new Date("Aug 29 2017 20:00:00 GMT+8").getTime() / 1000;

    address partenersAddress = 0x6F3c01E350509b98665bCcF7c7D88C120C1762ef; //totalToken * 20%
    address operationAddress = 0xb5B802F753bEe90C969aD27a94Da5C179Eaa3334; //totalToken * 20%
    address technicalAddress = 0x62C1eC256B7bb10AA53FD4208454E1BFD533b7f0; //totalToken * 30%

    /**
     * @dev modifier to allow token creation only when the sale IS ON
     */
    modifier saleIsOn() {
        require(now > start && now < start + 28 days);
        _;
    }

    /**
     * @dev modifier to allow token creation only when the hardcap has not been reached
     */
    modifier isUnderHardCap() {
        require(multisigVault.balance + msg.value + altDeposits <= hardcap);
        _;
    }

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
        size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @dev Allows anyone to create tokens by depositing ether.
     * @param recipient the recipient to receive tokens.
     */
    function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
        require(!isContract(recipient));
        uint tokens = rate.mul(msg.value).div(1 ether);
        token.mint(recipient, tokens);
        require(multisigVault.send(msg.value));
        TokenSold(recipient, msg.value, tokens, rate);
    }

    /**
     * @dev Allows to set the authorize mint token
     * @param _authorizeMintToken total amount ETH equivalent
     */
    function setAuthorizeMintToken(uint _authorizeMintToken) public onlyOwner {
        authorizeMintToken = _authorizeMintToken;
    }

    /**
     * @dev Allows to set the total alt deposit measured in ETH to make sure the hardcap includes other deposits
     * @param totalAltDeposits total amount ETH equivalent
     */
    function setAltDeposit(uint totalAltDeposits) public onlyOwner {
        altDeposits = totalAltDeposits;
    }

    /**
     * @dev set eth : tpc rate
     * @param _rate eth:tpc rate
     */
    function setRate(uint _rate) public onlyOwner {
        rate = _rate;
    }


    /**
     * @dev Allows authorized access to create tokens. This is used for Bitcoin and ERC20 deposits
     * @param recipient the recipient to receive tokens.
     * @param _tokens number of tokens to be created.
     */
    function authorizedCreateTokens(address recipient, uint _tokens) public onlyAuthorized {
        uint tokens = _tokens * (10 ** 6);
        uint totalSupply = token.totalSupply();
        require(totalSupply + tokens <= authorizeMintToken);
        token.mint(recipient, tokens);
        AuthorizedCreate(recipient, tokens);
    }

    /**
     * @dev Allows the owner to set the hardcap.
     * @param _hardcap the new hardcap
     */
    function setHardCap(uint _hardcap) public onlyOwner {
        hardcap = _hardcap;
    }

    /**
     * @dev Allows the owner to set the starting time.
     * @param _start the new _start
     */
    function setStart(uint _start) public onlyOwner {
        start = _start;
    }

    /**
     * @dev Allows the owner to set the multisig contract.
     * @param _multisigVault the multisig contract address
     */
    function setMultisigVault(address _multisigVault) public onlyOwner {
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

    /**
     * @dev Allows the owner to finish the minting. This will create the
     * restricted tokens and then close the minting.
     * Then the ownership of the YES token contract is transfered
     * to this owner.
     */
    function finishMinting() public onlyOwner {
        uint issuedTokenSupply = token.totalSupply();
        uint partenersTokens = totalToken.mul(20).div(100);
        uint technicalTokens = totalToken.mul(30).div(100);
        uint operationTokens = totalToken.mul(20).div(100);

        token.mint(partenersAddress, partenersTokens);
        token.mint(technicalAddress, technicalTokens);
        token.mint(operationAddress, operationTokens);

        uint restrictedTokens = totalToken.sub(issuedTokenSupply).sub(partenersTokens).sub(technicalTokens).sub(operationTokens);
        token.mint(multisigVault, restrictedTokens);
        token.finishMinting();
        token.transferOwnership(owner);
        TopCoinSaleClosed();
    }

    /**
     * @dev Allows the owner to transfer ERC20 tokens to the multi sig vault
     * @param _token the contract address of the ERC20 contract
     */
    function retrieveTokens(address _token) public onlyOwner {
        ERC20 token = ERC20(_token);
        token.transfer(multisigVault, token.balanceOf(this));
    }

    /**
     * @dev Fallback function which receives ether and created the appropriate number of tokens for the
     * msg.sender.
     */
    function() external payable {
        createTokens(msg.sender);
    }

}