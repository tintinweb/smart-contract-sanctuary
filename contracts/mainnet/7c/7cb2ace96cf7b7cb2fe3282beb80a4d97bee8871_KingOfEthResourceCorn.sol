// File: contracts/GodMode.sol

/****************************************************
 *
 * Copyright 2018 BurzNest LLC. All rights reserved.
 *
 * The contents of this file are provided for review
 * and educational purposes ONLY. You MAY NOT use,
 * copy, distribute, or modify this software without
 * explicit written permission from BurzNest LLC.
 *
 ****************************************************/

pragma solidity ^0.4.24;

/// @title God Mode
/// @author Anthony Burzillo <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ee8c9b9c94ae8c9b9c94808b9d9ac08d8183">[email&#160;protected]</a>>
/// @dev This contract provides a basic interface for God
///  in a contract as well as the ability for God to pause
///  the contract
contract GodMode {
    /// @dev Is the contract paused?
    bool public isPaused;

    /// @dev God&#39;s address
    address public god;

    /// @dev Only God can run this function
    modifier onlyGod()
    {
        require(god == msg.sender);
        _;
    }

    /// @dev This function can only be run while the contract
    ///  is not paused
    modifier notPaused()
    {
        require(!isPaused);
        _;
    }

    /// @dev This event is fired when the contract is paused
    event GodPaused();

    /// @dev This event is fired when the contract is unpaused
    event GodUnpaused();

    constructor() public
    {
        // Make the creator of the contract God
        god = msg.sender;
    }

    /// @dev God can change the address of God
    /// @param _newGod The new address for God
    function godChangeGod(address _newGod) public onlyGod
    {
        god = _newGod;
    }

    /// @dev God can pause the game
    function godPause() public onlyGod
    {
        isPaused = true;

        emit GodPaused();
    }

    /// @dev God can unpause the game
    function godUnpause() public onlyGod
    {
        isPaused = false;

        emit GodUnpaused();
    }
}

// File: contracts/KingOfEthResourcesInterfaceReferencer.sol

/****************************************************
 *
 * Copyright 2018 BurzNest LLC. All rights reserved.
 *
 * The contents of this file are provided for review
 * and educational purposes ONLY. You MAY NOT use,
 * copy, distribute, or modify this software without
 * explicit written permission from BurzNest LLC.
 *
 ****************************************************/

pragma solidity ^0.4.24;


/// @title King of Eth: Resources Interface Referencer
/// @author Anthony Burzillo <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f09285828ab09285828a9e958384de939f9d">[email&#160;protected]</a>>
/// @dev Provides functionality to reference the resource interface contract
contract KingOfEthResourcesInterfaceReferencer is GodMode {
    /// @dev The interface contract&#39;s address
    address public interfaceContract;

    /// @dev Only the interface contract can run this function
    modifier onlyInterfaceContract()
    {
        require(interfaceContract == msg.sender);
        _;
    }

    /// @dev God can set the realty contract
    /// @param _interfaceContract The new address
    function godSetInterfaceContract(address _interfaceContract)
        public
        onlyGod
    {
        interfaceContract = _interfaceContract;
    }
}

// File: contracts/KingOfEthResource.sol

/****************************************************
 *
 * Copyright 2018 BurzNest LLC. All rights reserved.
 *
 * The contents of this file are provided for review
 * and educational purposes ONLY. You MAY NOT use,
 * copy, distribute, or modify this software without
 * explicit written permission from BurzNest LLC.
 *
 ****************************************************/

pragma solidity ^0.4.24;



/// @title ERC20Interface
/// @dev ERC20 token interface contract
contract ERC20Interface {
    function totalSupply() public constant returns(uint);
    function balanceOf(address _tokenOwner) public constant returns(uint balance);
    function allowance(address _tokenOwner, address _spender) public constant returns(uint remaining);
    function transfer(address _to, uint _tokens) public returns(bool success);
    function approve(address _spender, uint _tokens) public returns(bool success);
    function transferFrom(address _from, address _to, uint _tokens) public returns(bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/// @title King of Eth: Resource
/// @author Anthony Burzillo <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d4b6a1a6ae94b6a1a6aebab1a7a0fab7bbb9">[email&#160;protected]</a>>
/// @dev Common contract implementation for resources
contract KingOfEthResource is
      ERC20Interface
    , GodMode
    , KingOfEthResourcesInterfaceReferencer
{
    /// @dev Current resource supply
    uint public resourceSupply;

    /// @dev ERC20 token&#39;s decimals
    uint8 public constant decimals = 0;

    /// @dev mapping of addresses to holdings
    mapping (address => uint) holdings;

    /// @dev mapping of addresses to amount of tokens frozen
    mapping (address => uint) frozenHoldings;

    /// @dev mapping of addresses to mapping of allowances for an address
    mapping (address => mapping (address => uint)) allowances;

    /// @dev ERC20 total supply
    /// @return The current total supply of the resource
    function totalSupply()
        public
        constant
        returns(uint)
    {
        return resourceSupply;
    }

    /// @dev ERC20 balance of address
    /// @param _tokenOwner The address to look up
    /// @return The balance of the address
    function balanceOf(address _tokenOwner)
        public
        constant
        returns(uint balance)
    {
        return holdings[_tokenOwner];
    }

    /// @dev Total resources frozen for an address
    /// @param _tokenOwner The address to look up
    /// @return The frozen balance of the address
    function frozenTokens(address _tokenOwner)
        public
        constant
        returns(uint balance)
    {
        return frozenHoldings[_tokenOwner];
    }

    /// @dev The allowance for a spender on an account
    /// @param _tokenOwner The account that allows withdrawels
    /// @param _spender The account that is allowed to withdraw
    /// @return The amount remaining in the allowance
    function allowance(address _tokenOwner, address _spender)
        public
        constant
        returns(uint remaining)
    {
        return allowances[_tokenOwner][_spender];
    }

    /// @dev Only run if player has at least some amount of tokens
    /// @param _owner The owner of the tokens
    /// @param _tokens The amount of tokens required
    modifier hasAvailableTokens(address _owner, uint _tokens)
    {
        require(holdings[_owner] - frozenHoldings[_owner] >= _tokens);
        _;
    }

    /// @dev Only run if player has at least some amount of tokens frozen
    /// @param _owner The owner of the tokens
    /// @param _tokens The amount of frozen tokens required
    modifier hasFrozenTokens(address _owner, uint _tokens)
    {
        require(frozenHoldings[_owner] >= _tokens);
        _;
    }

    /// @dev Set up the exact same state in each resource
    constructor() public
    {
        // God gets 200 to put on exchange
        holdings[msg.sender] = 200;

        resourceSupply = 200;
    }

    /// @dev The resources interface can burn tokens for building
    ///  roads or houses
    /// @param _owner The owner of the tokens
    /// @param _tokens The amount of tokens to burn
    function interfaceBurnTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
        hasAvailableTokens(_owner, _tokens)
    {
        holdings[_owner] -= _tokens;

        resourceSupply -= _tokens;

        // Pretend the tokens were sent to 0x0
        emit Transfer(_owner, 0x0, _tokens);
    }

    /// @dev The resources interface contract can mint tokens for houses
    /// @param _owner The owner of the tokens
    /// @param _tokens The amount of tokens to burn
    function interfaceMintTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
    {
        holdings[_owner] += _tokens;

        resourceSupply += _tokens;

        // Pretend the tokens were sent from the interface contract
        emit Transfer(interfaceContract, _owner, _tokens);
    }

    /// @dev The interface can freeze tokens
    /// @param _owner The owner of the tokens
    /// @param _tokens The amount of tokens to freeze
    function interfaceFreezeTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
        hasAvailableTokens(_owner, _tokens)
    {
        frozenHoldings[_owner] += _tokens;
    }

    /// @dev The interface can thaw tokens
    /// @param _owner The owner of the tokens
    /// @param _tokens The amount of tokens to thaw
    function interfaceThawTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
        hasFrozenTokens(_owner, _tokens)
    {
        frozenHoldings[_owner] -= _tokens;
    }

    /// @dev The interface can transfer tokens
    /// @param _from The owner of the tokens
    /// @param _to The new owner of the tokens
    /// @param _tokens The amount of tokens to transfer
    function interfaceTransfer(address _from, address _to, uint _tokens)
        public
        onlyInterfaceContract
    {
        assert(holdings[_from] >= _tokens);

        holdings[_from] -= _tokens;
        holdings[_to]   += _tokens;

        emit Transfer(_from, _to, _tokens);
    }

    /// @dev The interface can transfer frozend tokens
    /// @param _from The owner of the tokens
    /// @param _to The new owner of the tokens
    /// @param _tokens The amount of frozen tokens to transfer
    function interfaceFrozenTransfer(address _from, address _to, uint _tokens)
        public
        onlyInterfaceContract
        hasFrozenTokens(_from, _tokens)
    {
        // Make sure to deduct the tokens from both the total and frozen amounts
        holdings[_from]       -= _tokens;
        frozenHoldings[_from] -= _tokens;
        holdings[_to]         += _tokens;

        emit Transfer(_from, _to, _tokens);
    }

    /// @dev ERC20 transfer
    /// @param _to The address to transfer to
    /// @param _tokens The amount of tokens to transfer
    function transfer(address _to, uint _tokens)
        public
        hasAvailableTokens(msg.sender, _tokens)
        returns(bool success)
    {
        holdings[_to]        += _tokens;
        holdings[msg.sender] -= _tokens;

        emit Transfer(msg.sender, _to, _tokens);

        return true;
    }

    /// @dev ERC20 approve
    /// @param _spender The address to approve
    /// @param _tokens The amount of tokens to approve
    function approve(address _spender, uint _tokens)
        public
        returns(bool success)
    {
        allowances[msg.sender][_spender] = _tokens;

        emit Approval(msg.sender, _spender, _tokens);

        return true;
    }

    /// @dev ERC20 transfer from
    /// @param _from The address providing the allowance
    /// @param _to The address using the allowance
    /// @param _tokens The amount of tokens to transfer
    function transferFrom(address _from, address _to, uint _tokens)
        public
        hasAvailableTokens(_from, _tokens)
        returns(bool success)
    {
        require(allowances[_from][_to] >= _tokens);

        holdings[_to]          += _tokens;
        holdings[_from]        -= _tokens;
        allowances[_from][_to] -= _tokens;

        emit Transfer(_from, _to, _tokens);

        return true;
    }
}

// File: contracts/resources/KingOfEthResourceCorn.sol

/****************************************************
 *
 * Copyright 2018 BurzNest LLC. All rights reserved.
 *
 * The contents of this file are provided for review
 * and educational purposes ONLY. You MAY NOT use,
 * copy, distribute, or modify this software without
 * explicit written permission from BurzNest LLC.
 *
 ****************************************************/

pragma solidity ^0.4.24;


/// @title King of Eth Resource: Corn
/// @author Anthony Burzillo <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="86e4f3f4fcc6e4f3f4fce8e3f5f2a8e5e9eb">[email&#160;protected]</a>>
/// @dev ERC20 contract for the corn resource
contract KingOfEthResourceCorn is KingOfEthResource {
    /// @dev The ERC20 token name
    string public constant name = "King of Eth Resource: Corn";

    /// @dev The ERC20 token symbol
    string public constant symbol = "KECO";
}