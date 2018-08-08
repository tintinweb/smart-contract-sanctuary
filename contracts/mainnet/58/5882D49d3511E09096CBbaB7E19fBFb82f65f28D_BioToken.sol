pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

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
        if (msg.sender != owner) {
            revert();
        }
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint256 public tokenTotalSupply;

    function balanceOf(address who) constant returns(uint256);

    function allowance(address owner, address spender) constant returns(uint256);

    function transfer(address to, uint256 value) returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address from, address to, uint256 value) returns (bool success);

    function approve(address spender, uint256 value) returns (bool success);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() constant returns (uint256 availableSupply);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract BioToken is ERC20, Ownable {
    using SafeMath for uint;

    string public name = "BIONT Token";
    string public symbol = "BIONT";
    uint public decimals = 18;

    bool public tradingStarted = false;
    bool public mintingFinished = false;
    bool public salePaused = false;

    uint256 public tokenTotalSupply = 0;
    uint256 public trashedTokens = 0;
    uint256 public hardcap = 140000000 * (10 ** decimals); // 140 million tokens
    uint256 public ownerTokens = 14000000 * (10 ** decimals); // 14 million tokens

    uint public ethToToken = 300; // 1 eth buys 300 tokens
    uint public noContributors = 0;

    uint public start = 1503346080; // 08/21/2017 @ 20:08pm (UTC)
    uint public initialSaleEndDate = start + 9 weeks;
    uint public ownerGrace = initialSaleEndDate + 182 days;
    uint public fiveYearGrace = initialSaleEndDate + 5 * 365 days;

    address public multisigVault;
    address public lockedVault;
    address public ownerVault;

    address public authorizerOne;
    address public authorizerTwo;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) authorizedWithdrawal;

    event Mint(address indexed to, uint256 value);
    event MintFinished();
    event TokenSold(address recipient, uint256 ether_amount, uint256 pay_amount, uint256 exchangerate);
    event MainSaleClosed();

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
            revert();
        }
        _;
    }

    modifier canMint() {
        if (mintingFinished) {
            revert();
        }

        _;
    }

    /**
     * @dev modifier that throws if trading has not started yet
     */
    modifier hasStartedTrading() {
        require(tradingStarted);
        _;
    }

    /**
     * @dev modifier to allow token creation only when the sale IS ON
     */
    modifier saleIsOn() {
        require(now > start && now < initialSaleEndDate && salePaused == false);
        _;
    }

    /**
     * @dev modifier to allow token creation only when the hardcap has not been reached
     */
    modifier isUnderHardCap() {
        require(tokenTotalSupply <= hardcap);
        _;
    }

    function BioToken(address _ownerVault, address _authorizerOne, address _authorizerTwo, address _lockedVault, address _multisigVault) {
        ownerVault = _ownerVault;
        authorizerOne = _authorizerOne;
        authorizerTwo = _authorizerTwo;
        lockedVault = _lockedVault;
        multisigVault = _multisigVault;

        mint(ownerVault, ownerTokens);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) private canMint returns(bool) {
        tokenTotalSupply = tokenTotalSupply.add(_amount);

        require(tokenTotalSupply <= hardcap);

        balances[_to] = balances[_to].add(_amount);
        noContributors = noContributors.add(1);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will recieve the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function masterMint(address _to, uint256 _amount) public canMint onlyOwner returns(bool) {
        tokenTotalSupply = tokenTotalSupply.add(_amount);

        require(tokenTotalSupply <= hardcap);

        balances[_to] = balances[_to].add(_amount);
        noContributors = noContributors.add(1);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() private onlyOwner returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) hasStartedTrading returns (bool success) {
        // don&#39;t allow the vault to make transfers
        if (msg.sender == lockedVault && now < fiveYearGrace) {
            revert();
        }

        // owner needs to wait as well
        if (msg.sender == ownerVault && now < ownerGrace) {
            revert();
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) hasStartedTrading returns (bool success) {
        if (_from == lockedVault && now < fiveYearGrace) {
            revert();
        }

        // owner needs to wait as well
        if (_from == ownerVault && now < ownerGrace) {
            revert();
        }

        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another according to off exchange agreements
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function masterTransferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public hasStartedTrading onlyOwner returns (bool success) {
        if (_from == lockedVault && now < fiveYearGrace) {
            revert();
        }

        // owner needs to wait as well
        if (_from == ownerVault && now < ownerGrace) {
            revert();
        }

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    function totalSupply() constant returns (uint256 availableSupply) {
        return tokenTotalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) returns (bool success) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) {
            revert();
        }

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Allows the owner to enable the trading. This can not be undone
     */
    function startTrading() onlyOwner {
        tradingStarted = true;
    }

    /**
     * @dev Allows the owner to enable the trading. This can not be undone
     */
    function pauseSale() onlyOwner {
        salePaused = true;
    }

    /**
     * @dev Allows the owner to enable the trading. This can not be undone
     */
    function resumeSale() onlyOwner {
        salePaused = false;
    }

    /**
     * @dev Allows the owner to enable the trading. This can not be undone
     */
    function getNoContributors() constant returns(uint contributors) {
        return noContributors;
    }

    /**
     * @dev Allows the owner to set the multisig wallet address.
     * @param _multisigVault the multisig wallet address
     */
    function setMultisigVault(address _multisigVault) public onlyOwner {
        if (_multisigVault != address(0)) {
            multisigVault = _multisigVault;
        }
    }

    function setAuthorizedWithdrawalAmount(uint256 _amount) public {
        if (_amount < 0) {
            revert();
        }

        if (msg.sender != authorizerOne && msg.sender != authorizerTwo) {
            revert();
        }

        authorizedWithdrawal[msg.sender] = _amount;
    }

    /**
     * @dev Allows the owner to send the funds to the vault.
     * @param _amount the amount in wei to send
     */
    function withdrawEthereum(uint256 _amount) public onlyOwner {
        require(multisigVault != address(0));
        require(_amount <= this.balance); // wei

        if (authorizedWithdrawal[authorizerOne] != authorizedWithdrawal[authorizerTwo]) {
            revert();
        }

        if (_amount > authorizedWithdrawal[authorizerOne]) {
            revert();
        }

        if (!multisigVault.send(_amount)) {
            revert();
        }

        authorizedWithdrawal[authorizerOne] = authorizedWithdrawal[authorizerOne].sub(_amount);
        authorizedWithdrawal[authorizerTwo] = authorizedWithdrawal[authorizerTwo].sub(_amount);
    }

    function showAuthorizerOneAmount() constant public returns(uint256 remaining) {
        return authorizedWithdrawal[authorizerOne];
    }

    function showAuthorizerTwoAmount() constant public returns(uint256 remaining) {
        return authorizedWithdrawal[authorizerTwo];
    }

    function showEthBalance() constant public returns(uint256 remaining) {
        return this.balance;
    }

    function retrieveTokens() public onlyOwner {
        require(lockedVault != address(0));

        uint256 capOut = hardcap.sub(tokenTotalSupply);
        tokenTotalSupply = hardcap;

        balances[lockedVault] = balances[lockedVault].add(capOut);
        Transfer(this, lockedVault, capOut);
    }

    function trashTokens(address _from, uint256 _amount) onlyOwner returns(bool) {
        balances[_from] = balances[_from].sub(_amount);
        trashedTokens = trashedTokens.add(_amount);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);
    }

    function decreaseSupply(uint256 value, address from) onlyOwner returns (bool) {
      balances[from] = balances[from].sub(value);
      trashedTokens = trashedTokens.add(value);
      tokenTotalSupply = tokenTotalSupply.sub(value);
      Transfer(from, 0, value);
      return true;
    }

    function finishSale() public onlyOwner {
        finishMinting();
        retrieveTokens();
        startTrading();

        MainSaleClosed();
    }

    function saleOn() constant returns(bool) {
        return (now > start && now < initialSaleEndDate && salePaused == false);
    }

    /**
     * @dev Allows anyone to create tokens by depositing ether.
     * @param recipient the recipient to receive tokens.
     */
    function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
        uint bonus = 0;
        uint period = 1 weeks;
        uint256 tokens;

        if (now <= start + 2 * period) {
            bonus = 20;
        } else if (now > start + 2 * period && now <= start + 3 * period) {
            bonus = 15;
        } else if (now > start + 3 * period && now <= start + 4 * period) {
            bonus = 10;
        } else if (now > start + 4 * period && now <= start + 5 * period) {
            bonus = 5;
        }

        // the bonus is in percentages, solidity is doing standard integer division, basically rounding &#39;down&#39;
        if (bonus > 0) {
            tokens = ethToToken.mul(msg.value) + ethToToken.mul(msg.value).mul(bonus).div(100);
        } else {
            tokens = ethToToken.mul(msg.value);
        }

        if (tokens <= 0) {
            revert();
        }

        mint(recipient, tokens);

        TokenSold(recipient, msg.value, tokens, ethToToken);
    }

    function() external payable {
        createTokens(msg.sender);
    }
}