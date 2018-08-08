pragma solidity ^0.4.23;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        emit onOwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title Lockable
 * @dev Base contract which allows to implement an emergency stop mechanism.
 */
contract Lockable is Ownable {
    event onLock();

    bool public locked = false;
    /**
     * @dev Modifier to make a function callable only when the contract is not locked.
     */
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev called by the owner to set lock state, triggers stop/continue state
     */
    function setLock(bool _value) onlyOwner public {
        locked = _value;
        emit onLock();
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function actualCap() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Lockable {
    using SafeMath for uint256;

    uint8 public constant decimals = 18; // solium-disable-line uppercase
    mapping(address => uint256) balances;
    uint256 totalSupply_;
    uint256 actualCap_;

    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev actual CAP
     */
    function actualCap() public view returns (uint256) {
        return actualCap_;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!locked || msg.sender == owner);
        //owner can do even locked
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!locked || msg.sender == owner);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
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
        require(!locked || msg.sender == owner);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
        require(!locked || msg.sender == owner);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        require(!locked || msg.sender == owner);
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
    event onMint(address indexed to, uint256 amount);
    event onSetMintable();

    bool public mintable = true;

    modifier canMint() {
        require(mintable);
        _;
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) onlyOwner whenNotLocked canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit onMint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
     * @dev Function to stop/continue minting new tokens.
     * @return True if the operation was successful.
     */
    function setMintable(bool _value) onlyOwner public returns (bool) {
        mintable = _value;
        emit onSetMintable();
        return true;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {
    event onBurn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) whenNotLocked public returns (bool)  {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        actualCap_ = actualCap_.sub(_value);
        emit onBurn(burner, _value);
        emit Transfer(burner, address(0), _value);
        return true;
    }
}

/**
 * @title Dropable
 * @dev Base contract which allows to implement air drop mechanism.
 */
contract DropableToken is MintableToken {
    event onSetDropable();
    event onSetDropAmount();

    bool public dropable = false;
    uint256 dropAmount_ = 100000 * (10 ** uint256(decimals)); // 0.00001% per drop

    /**
     * @dev Modifier to make a function callable only when the contract is dropable.
     */
    modifier whenDropable() {
        require(dropable);
        _;
    }
    /**
     * @dev called by the owner to set dropable
     */
    function setDropable(bool _value) onlyOwner public {
        dropable = _value;
        emit onSetDropable();
    }

    /**
    * @dev called by the owner to set default airdrop amount
    */
    function setDropAmount(uint256 _value) onlyOwner public {
        dropAmount_ = _value;
        emit onSetDropAmount();
    }

    /**
     * @dev called by anyone to get the drop amount
     */
    function getDropAmount() public view returns (uint256) {
        return dropAmount_;
    }

    /*batch airdrop functions*/
    function airdropWithAmount(address [] _recipients, uint256 _value) onlyOwner canMint whenDropable external {
        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            require(totalSupply_.add(_value) <= actualCap_);
            mint(recipient, _value);
        }
    }

    function airdrop(address [] _recipients) onlyOwner canMint whenDropable external {
        for (uint i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            require(totalSupply_.add(dropAmount_) <= actualCap_);
            mint(recipient, dropAmount_);
        }
    }

    /*get airdrop function*/
    //one can get airdrop by themselves as long as they are willing to pay gas
    function getAirdrop() whenNotLocked canMint whenDropable external returns (bool) {
        require(totalSupply_.add(dropAmount_) <= actualCap_);
        mint(msg.sender, dropAmount_);
        return true;
    }
}


/**
 * @title Purchasable token
 */
contract PurchasableToken is StandardToken {
    event onPurchase(address indexed to, uint256 etherAmount, uint256 tokenAmount);
    event onSetPurchasable();
    event onSetTokenPrice();
    event onWithdraw(address to, uint256 amount);

    bool public purchasable = true;
    uint256 tokenPrice_ = 0.0000000001 ether;
    uint256 etherAmount_;

    modifier canPurchase() {
        require(purchasable);
        _;
    }

    /**
     * @dev Function to purchase tokens
     * @return A boolean that indicates if the operation was successful.
     */
    function purchase() whenNotLocked canPurchase public payable returns (bool) {
        uint256 ethAmount = msg.value;
        uint256 tokenAmount = ethAmount.div(tokenPrice_).mul(10 ** uint256(decimals));
        require(totalSupply_.add(tokenAmount) <= actualCap_);
        totalSupply_ = totalSupply_.add(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);
        etherAmount_ = etherAmount_.add(ethAmount);
        emit onPurchase(msg.sender, ethAmount, tokenAmount);
        emit Transfer(address(0), msg.sender, tokenAmount);
        return true;
    }

    /**
     * @dev Function to stop/continue purchase new tokens.
     * @return True if the operation was successful.
     */
    function setPurchasable(bool _value) onlyOwner public returns (bool) {
        purchasable = _value;
        emit onSetPurchasable();
        return true;
    }

    /**
     * @dev called by the owner to set default airdrop amount
     */
    function setTokenPrice(uint256 _value) onlyOwner public {
        tokenPrice_ = _value;
        emit onSetTokenPrice();
    }

    /**
     * @dev called by anyone to get the token price for purchase
     */
    function getTokenPrice() public view returns (uint256) {
        return tokenPrice_;
    }

    /**
     * Withdraw the amount of ethers from the contract if any
     */
    function withdraw(uint256 _amountOfEthers) onlyOwner public returns (bool){
        address ownerAddress = msg.sender;
        require(etherAmount_>=_amountOfEthers);
        ownerAddress.transfer(_amountOfEthers);
        etherAmount_ = etherAmount_.sub(_amountOfEthers);
        emit onWithdraw(ownerAddress, _amountOfEthers);
        return true;
    }
}

contract RBTToken is DropableToken, BurnableToken, PurchasableToken {
    string public name = "RBT - a flexible token which can be rebranded";
    string public symbol = "RBT";
    string public version = &#39;1.0&#39;;
    string public desc = "";
    uint256 constant CAP = 100000000000 * (10 ** uint256(decimals)); // total
    uint256 constant STARTUP = 100000000 * (10 ** uint256(decimals)); // 0.1% startup

    /**
     * @dev Constructor that gives msg.sender the STARTUP tokens.
     */
    function RBTToken() public {
        mint(msg.sender, STARTUP);
        actualCap_ = CAP;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH, fallback function
    // ------------------------------------------------------------------------
    function() public payable {
        revert();
    }

    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name) onlyOwner public {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol) onlyOwner public {
        symbol = _symbol;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setVersion(string _version) onlyOwner public {
        version = _version;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setDesc(string _desc) onlyOwner public {
        desc = _desc;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        if (approve(_spender, _value)) {
            //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
            //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
            //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
            if (!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {revert();}
            return true;
        }
    }

    /* Approves and then calls the contract code*/
    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        if (approve(_spender, _value)) {
            //Call the contract code
            if (!_spender.call(_extraData)) {revert();}
            return true;
        }
    }

}