pragma solidity 0.4.24;

contract ReentrancyGuard {
    /**
    * @dev We use a single lock for the whole contract.
    */
    bool private reentrancyLock = false;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * @notice If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one nonReentrant function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and a `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
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

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;
    
    mapping (address=>bool) private whiteList;

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused || whiteList[msg.sender]);

        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused || whiteList[msg.sender]);

        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;

        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;

        emit Unpause();
    }

    function addToWhiteList(address[] _whiteList) external onlyOwner {
        require(_whiteList.length > 0);

        for(uint8 i = 0; i < _whiteList.length; i++) {
            assert(_whiteList[i] != address(0));

            whiteList[_whiteList[i]] = true;
        }
    }

    function removeFromWhiteList(address[] _blackList) external onlyOwner {
        require(_blackList.length > 0);

        for(uint8 i = 0; i < _blackList.length; i++) {
            assert(_blackList[i] != address(0));

            whiteList[_blackList[i]] = true;
        }
    }
}

contract W12TokenDistributor is Ownable {
    W12Token public token;

    mapping(uint32 => bool) public processedTransactions;

    constructor() public {
        token = new W12Token();
    }

    function isTransactionSuccessful(uint32 id) external view returns (bool) {
        return processedTransactions[id];
    }

    modifier validateInput(uint32[] _payment_ids, address[] _receivers, uint256[] _amounts) {
        require(_receivers.length == _amounts.length);
        require(_receivers.length == _payment_ids.length);

        _;
    }

    function transferTokenOwnership() external onlyOwner {
        token.transferOwnership(owner);
    }
}

contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    constructor (ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        // solium-disable-next-line security/no-block-members
        require(_releaseTime > block.timestamp);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
    * @notice Transfers tokens held by timelock to beneficiary.
    */
    function release() public {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

contract W12Crowdsale is W12TokenDistributor, ReentrancyGuard {
    uint public presaleStartDate = 1526817600;
    uint public presaleEndDate = 1532088000;
    uint public crowdsaleStartDate = 1532692800;
    uint public crowdsaleEndDate = 1538049600;

    uint public presaleTokenBalance = 20 * (10 ** 24);
    uint public crowdsaleTokenBalance = 80 * (10 ** 24);

    address public crowdsaleFundsWallet;

    enum Stage { Inactive, FlashSale, Presale, Crowdsale }

    event LockCreated(address indexed wallet, address timeLock1, address timeLock2, address timeLock3);

    constructor(address _crowdsaleFundsWallet) public {
        require(_crowdsaleFundsWallet != address(0));

        // Wallet to hold collected Ether
        crowdsaleFundsWallet = address(_crowdsaleFundsWallet);
    }
    
    function setUpCrowdsale() external onlyOwner {
        uint tokenDecimalsMultiplicator = 10 ** 18;

        // Tokens to sell during the first two phases of ICO
        token.mint(address(this), presaleTokenBalance + crowdsaleTokenBalance);
        // Partners
        token.mint(address(0xDbdCEa0B020D4769D7EA0aF47Df8848d478D67d1),  8 * (10 ** 6) * tokenDecimalsMultiplicator);
        // Bounty and support of ecosystem
        token.mint(address(0x1309Bb4DBBB6F8B3DE1822b4Cf22570d44f79cde),  8 * (10 ** 6) * tokenDecimalsMultiplicator);
        // Airdrop
        token.mint(address(0x0B2F4A122c34c4ccACf4EBecE15dE571d67b4D0a),  4 * (10 ** 6) * tokenDecimalsMultiplicator);
        
        address[] storage whiteList;

        whiteList.push(address(this));
        whiteList.push(address(0xDbdCEa0B020D4769D7EA0aF47Df8848d478D67d1));
        whiteList.push(address(0x1309Bb4DBBB6F8B3DE1822b4Cf22570d44f79cde));
        whiteList.push(address(0x0B2F4A122c34c4ccACf4EBecE15dE571d67b4D0a));
        whiteList.push(address(0xd13B531160Cfe6CC2f9a5615524CA636A0A94D88));
        whiteList.push(address(0x3BAF5A51E6212d311Bc567b60bE84Fc180d39805));

        token.addToWhiteList(whiteList);
    }

    function () payable external {
        Stage currentStage = getStage();

        require(currentStage != Stage.Inactive);

        uint currentRate = getCurrentRate();
        uint tokensBought = msg.value * (10 ** 18) / currentRate;

        token.transfer(msg.sender, tokensBought);
        advanceStage(tokensBought, currentStage);
    }

    function getCurrentRate() public view returns (uint) {
        uint currentSaleTime;
        Stage currentStage = getStage();

        if(currentStage == Stage.Presale) {
            currentSaleTime = now - presaleStartDate;
            uint presaleCoef = currentSaleTime * 100 / (presaleEndDate - presaleStartDate);
            
            return 262500000000000 + 35000000000000 * presaleCoef / 100;
        }
        
        if(currentStage == Stage.Crowdsale) {
            currentSaleTime = now - crowdsaleStartDate;
            uint crowdsaleCoef = currentSaleTime * 100 / (crowdsaleEndDate - crowdsaleStartDate);

            return 315000000000000 + 35000000000000 * crowdsaleCoef / 100;
        }

        if(currentStage == Stage.FlashSale) {
            return 234500000000000;
        }

        revert();
    }

    function getStage() public view returns (Stage) {
        if(now >= crowdsaleStartDate && now < crowdsaleEndDate) {
            return Stage.Crowdsale;
        }

        if(now >= presaleStartDate) {
            if(now < presaleStartDate + 1 days)
                return Stage.FlashSale;

            if(now < presaleEndDate)
                return Stage.Presale;
        }

        return Stage.Inactive;
    }

    function bulkTransfer(uint32[] _payment_ids, address[] _receivers, uint256[] _amounts)
        external onlyOwner validateInput(_payment_ids, _receivers, _amounts) {

        bool success = false;

        for (uint i = 0; i < _receivers.length; i++) {
            if (!processedTransactions[_payment_ids[i]]) {
                success = token.transfer(_receivers[i], _amounts[i]);
                processedTransactions[_payment_ids[i]] = success;

                if (!success)
                    break;

                advanceStage(_amounts[i], getStage());
            }
        }
    }

    function transferTokensToOwner() external onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function advanceStage(uint tokensBought, Stage currentStage) internal {
        if(currentStage == Stage.Presale || currentStage == Stage.FlashSale) {
            if(tokensBought <= presaleTokenBalance)
            {
                presaleTokenBalance -= tokensBought;
                return;
            }
        }
        
        if(currentStage == Stage.Crowdsale) {
            if(tokensBought <= crowdsaleTokenBalance)
            {
                crowdsaleTokenBalance -= tokensBought;
                return;
            }
        }

        revert();
    }

    function withdrawFunds() external nonReentrant {
        require(crowdsaleFundsWallet == msg.sender);

        crowdsaleFundsWallet.transfer(address(this).balance);
    }

    function setPresaleStartDate(uint32 _presaleStartDate) external onlyOwner {
        presaleStartDate = _presaleStartDate;
    }

    function setPresaleEndDate(uint32 _presaleEndDate) external onlyOwner {
        presaleEndDate = _presaleEndDate;
    }

    function setCrowdsaleStartDate(uint32 _crowdsaleStartDate) external onlyOwner {
        crowdsaleStartDate = _crowdsaleStartDate;
    }

    function setCrowdsaleEndDate(uint32 _crowdsaleEndDate) external onlyOwner {
        crowdsaleEndDate = _crowdsaleEndDate;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
    * @dev total number of tokens in existence
    */
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

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
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

contract StandardToken is ERC20, BasicToken {

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

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
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
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
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
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);

        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_ + _amount;
        balances[_to] = balances[_to] + _amount;

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();

        return true;
    }
}

contract DetailedERC20 is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract CappedToken is MintableToken {

    uint256 public cap;

    constructor(uint256 _cap) public {
        require(_cap > 0);

        cap = _cap;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_ + _amount <= cap);

        return super.mint(_to, _amount);
    }
}

contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who] - _value;
        totalSupply_ = totalSupply_ - _value;
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

contract StandardBurnableToken is BurnableToken, StandardToken {

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _value uint256 The amount of token to be burned
    */
    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender]);
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        _burn(_from, _value);
    }
}

contract W12Token is StandardBurnableToken, CappedToken, DetailedERC20, PausableToken  {
    constructor() CappedToken(400*(10**24)) DetailedERC20("W12 Token", "W12", 18) public { }
}