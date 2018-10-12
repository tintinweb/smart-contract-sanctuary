/**
 * Copyright 2017–2018, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract UnlimitedAllowanceToken is StandardToken {

    uint internal constant MAX_UINT = 2**256 - 1;
    
    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited allowance, and to add revert reasons.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        require(_value <= balances[_from], "insufficient balance");
        require(_value <= allowance, "insufficient allowance");
        require(_to != address(0), "token burn not allowed");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] = allowance.sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Transfer token for a specified address, modified to add revert reasons.
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(
        address _to,
        uint256 _value)
        public 
        returns (bool)
    {
        require(_value <= balances[msg.sender], "insufficient balance");
        require(_to != address(0), "token burn not allowed");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}

contract BZRxToken is UnlimitedAllowanceToken, DetailedERC20, Ownable {

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event LockingFinished();

    bool public mintingFinished = false;
    bool public lockingFinished = false;

    mapping (address => bool) public minters;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(minters[msg.sender]);
        _;
    }

    modifier isLocked() {
        require(!lockingFinished);
        _;
    }

    constructor()
        public
        DetailedERC20(
            "bZx Protocol Token",
            "BZRX", 
            18
        )
    {
        minters[msg.sender] = true;
    }

    /// @dev ERC20 transferFrom function
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool)
    {
        if (lockingFinished || minters[msg.sender]) {
            return super.transferFrom(
                _from,
                _to,
                _value
            );
        }

        revert("this token is locked for transfers");
    }

    /// @dev ERC20 transfer function
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transfer(
        address _to, 
        uint256 _value) 
        public 
        returns (bool)
    {
        if (lockingFinished || minters[msg.sender]) {
            return super.transfer(
                _to,
                _value
            );
        }

        revert("this token is locked for transfers");
    }

    /// @dev Allows minter to initiate a transfer on behalf of another spender
    /// @param _spender Minter with permission to spend.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function minterTransferFrom(
        address _spender,
        address _from,
        address _to,
        uint256 _value)
        public
        hasMintPermission
        canMint
        returns (bool)
    {
        require(canTransfer(
            _spender,
            _from,
            _value),
            "canTransfer is false");

        require(_to != address(0), "token burn not allowed");

        uint allowance = allowed[_from][_spender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (allowance < MAX_UINT) {
            allowed[_from][_spender] = allowance.sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(
        address _to,
        uint256 _amount)
        public
        hasMintPermission
        canMint
        returns (bool)
    {
        require(_to != address(0), "token burn not allowed");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() 
        public 
        onlyOwner 
        canMint 
    {
        mintingFinished = true;
        emit MintFinished();
    }

    /**
    * @dev Function to stop locking token.
    * @return True if the operation was successful.
    */
    function finishLocking() 
        public 
        onlyOwner 
        isLocked 
    {
        lockingFinished = true;
        emit LockingFinished();
    }

    /**
    * @dev Function to add minter address.
    * @return True if the operation was successful.
    */
    function addMinter(
        address _minter) 
        public 
        onlyOwner 
        canMint 
    {
        minters[_minter] = true;
    }

    /**
    * @dev Function to remove minter address.
    * @return True if the operation was successful.
    */
    function removeMinter(
        address _minter) 
        public 
        onlyOwner 
        canMint 
    {
        minters[_minter] = false;
    }

    /**
    * @dev Function to check balance and allowance for a spender.
    * @return True transfer will succeed based on balance and allowance.
    */
    function canTransfer(
        address _spender,
        address _from,
        uint256 _value)
        public
        view
        returns (bool)
    {
        return (
            balances[_from] >= _value && 
            (_spender == _from || allowed[_from][_spender] >= _value)
        );
    }
}

interface WETHInterface {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract BZRxTokenSale is Ownable {
    using SafeMath for uint256;

    uint public constant tokenPrice = 73 * 10**12; // 0.000073 ETH

    struct TokenPurchases {
        uint totalETH;
        uint totalTokens;
        uint totalTokenBonus;
    }

    event BonusChanged(uint oldBonus, uint newBonus);
    event TokenPurchase(address indexed buyer, uint ethAmount, uint tokensReceived);
    
    event SaleOpened(uint bonusMultiplier);
    event SaleClosed(uint bonusMultiplier);
    
    bool public saleClosed = true;

    address public bZRxTokenContractAddress;    // BZRX Token
    address public bZxVaultAddress;             // bZx Vault
    address public wethContractAddress;         // WETH Token

    // The current token bonus offered to purchasers (example: 110 == 10% bonus)
    uint public bonusMultiplier;

    uint public ethRaised;

    address[] public purchasers;
    mapping (address => TokenPurchases) public purchases;

    bool public whitelistEnforced = false;
    mapping (address => uint) public whitelist;

    modifier saleOpen() {
        require(!saleClosed, "sale is closed");
        _;
    }

    modifier whitelisted(address user, uint value) {
        require(canPurchaseAmount(user, value), "not whitelisted");
        _;
    }

    constructor(
        address _bZRxTokenContractAddress,
        address _bZxVaultAddress,
        address _wethContractAddress,
        uint _bonusMultiplier,
        uint _previousAmountRaised)
        public
    {
        require(_bonusMultiplier > 100);
        
        bZRxTokenContractAddress = _bZRxTokenContractAddress;
        bZxVaultAddress = _bZxVaultAddress;
        wethContractAddress = _wethContractAddress;
        bonusMultiplier = _bonusMultiplier;
        ethRaised = _previousAmountRaised;
    }

    function()  
        public
        payable 
    {
        if (msg.sender != wethContractAddress && msg.sender != owner)
            buyToken();
    }

    function buyToken()
        public
        payable 
        saleOpen
        whitelisted(msg.sender, msg.value)
        returns (bool)
    {
        require(msg.value > 0, "no ether sent");
        
        ethRaised += msg.value;

        uint tokenAmount = msg.value                        // amount of ETH sent
                            .mul(10**18).div(tokenPrice);   // fixed ETH price per token (0.000073 ETH)

        uint tokenAmountAndBonus = tokenAmount
                                        .mul(bonusMultiplier).div(100);

        TokenPurchases storage purchase = purchases[msg.sender];
        
        if (purchase.totalETH == 0) {
            purchasers.push(msg.sender);
        }
        
        purchase.totalETH += msg.value;
        purchase.totalTokens += tokenAmountAndBonus;
        purchase.totalTokenBonus += tokenAmountAndBonus.sub(tokenAmount);

        emit TokenPurchase(msg.sender, msg.value, tokenAmountAndBonus);

        return BZRxToken(bZRxTokenContractAddress).mint(
            msg.sender,
            tokenAmountAndBonus
        );
    }

    // conforms to ERC20 transferFrom function for BZRX token support
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        saleOpen
        returns (bool)
    {
        require(msg.sender == bZxVaultAddress, "only the bZx vault can call this function");
        
        if (BZRxToken(bZRxTokenContractAddress).canTransfer(msg.sender, _from, _value)) {
            return BZRxToken(bZRxTokenContractAddress).minterTransferFrom(
                msg.sender,
                _from,
                _to,
                _value
            );
        } else {
            uint wethValue = _value                             // amount of BZRX
                                .mul(tokenPrice).div(10**18);   // fixed ETH price per token (0.000073 ETH)

            require(canPurchaseAmount(_from, wethValue), "not whitelisted");

            require(StandardToken(wethContractAddress).transferFrom(
                _from,
                this,
                wethValue
            ), "weth transfer failed");

            ethRaised += wethValue;

            TokenPurchases storage purchase = purchases[_from];

            if (purchase.totalETH == 0) {
                purchasers.push(_from);
            }

            purchase.totalETH += wethValue;
            purchase.totalTokens += _value;

            return BZRxToken(bZRxTokenContractAddress).mint(
                _to,
                _value
            );
        }
    }

    /**
    * @dev Function to close the token sale for this contract.
    * @return True if the operation was successful.
    */
    function closeSale(
        bool _closed) 
        public 
        onlyOwner 
        returns (bool)
    {
        saleClosed = _closed;

        if (_closed)
            emit SaleClosed(bonusMultiplier);
        else
            emit SaleOpened(bonusMultiplier);

        return true;
    }

    function changeBZRxTokenContract(
        address _bZRxTokenContractAddress) 
        public 
        onlyOwner 
        returns (bool)
    {
        bZRxTokenContractAddress = _bZRxTokenContractAddress;
        return true;
    }

    function changeBZxVault(
        address _bZxVaultAddress) 
        public 
        onlyOwner 
        returns (bool)
    {
        bZxVaultAddress = _bZxVaultAddress;
        return true;
    }

    function changeWethContract(
        address _wethContractAddress) 
        public 
        onlyOwner 
        returns (bool)
    {
        wethContractAddress = _wethContractAddress;
        return true;
    }

    function changeBonusMultiplier(
        uint _newBonusMultiplier) 
        public 
        onlyOwner 
        returns (bool)
    {
        require(bonusMultiplier != _newBonusMultiplier && _newBonusMultiplier > 100);
        emit BonusChanged(bonusMultiplier, _newBonusMultiplier);
        bonusMultiplier = _newBonusMultiplier;
        return true;
    }

    function unwrapEth() 
        public 
        onlyOwner 
        returns (bool)
    {
        uint balance = StandardToken(wethContractAddress).balanceOf.gas(4999)(this);
        if (balance == 0)
            return false;

        WETHInterface(wethContractAddress).withdraw(balance);
        return true;
    }

    function transferEther(
        address _to,
        uint _value)
        public
        onlyOwner
        returns (bool)
    {
        uint amount = _value;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        return (_to.send(amount));
    }

    function transferToken(
        address _tokenAddress,
        address _to,
        uint _value)
        public
        onlyOwner
        returns (bool)
    {
        uint balance = StandardToken(_tokenAddress).balanceOf.gas(4999)(this);
        if (_value > balance) {
            return StandardToken(_tokenAddress).transfer(
                _to,
                balance
            );
        } else {
            return StandardToken(_tokenAddress).transfer(
                _to,
                _value
            );
        }
    }

    function enforceWhitelist(
        bool _isEnforced) 
        public 
        onlyOwner 
        returns (bool)
    {
        whitelistEnforced = _isEnforced;

        return true;
    }

    function setWhitelist(
        address[] _users,
        uint[] _values) 
        public 
        onlyOwner 
        returns (bool)
    {
        require(_users.length == _values.length, "users and values count mismatch");
        
        for (uint i=0; i < _users.length; i++) {
            whitelist[_users[i]] = _values[i];
        }

        return true;
    }


    function canPurchaseAmount(
        address _user,
        uint _value)
        public
        view
        returns (bool)
    {
        if (!whitelistEnforced || (whitelist[_user] > 0 && purchases[_user].totalETH.add(_value) <= whitelist[_user])) {
            return true;
        } else {
            return false;
        }
    }
}