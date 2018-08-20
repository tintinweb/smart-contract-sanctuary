pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract MinimalTokenInterface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function decimals() public returns (uint8);
}

contract TokenPriveProviderInterface {
    function tokenPrice() public constant returns (uint);
}

// ----------------------------------------------------------------------------
// Dividends implementation interface
// ----------------------------------------------------------------------------
contract SNcoin_CountrySale is Owned {
    MinimalTokenInterface public tokenContract;
    address public spenderAddress;
    address public vaultAddress;
    address public ambassadorAddress;
    bool public fundingEnabled;
    uint public totalCollected;         // In wei
    TokenPriveProviderInterface public tokenPriceProvider;         // In wei
    string public country;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _tokenAddress, address _spenderAddress, address _vaultAddress, address _ambassadorAddress, bool _fundingEnabled, address _tokenPriceProvider, string _country) public {
        require (_tokenAddress != 0);
        require (_spenderAddress != 0);
        require (_vaultAddress != 0);
        require (_tokenPriceProvider != 0);
        require (bytes(_country).length > 0);
        tokenContract = MinimalTokenInterface(_tokenAddress);
        spenderAddress = _spenderAddress;
        vaultAddress = _vaultAddress;
        ambassadorAddress = _ambassadorAddress;
        fundingEnabled = _fundingEnabled;
        tokenPriceProvider = TokenPriveProviderInterface(_tokenPriceProvider);
        country = _country;
    }

    function setSpenderAddress(address _spenderAddress) public onlyOwner {
        require (_spenderAddress != 0);
        spenderAddress = _spenderAddress;
        return;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        require (_vaultAddress != 0);
        vaultAddress = _vaultAddress;
        return;
    }

    function setAmbassadorAddress(address _ambassadorAddress) public onlyOwner {
        require (_ambassadorAddress != 0);
        ambassadorAddress = _ambassadorAddress;
        return;
    }

    function setFundingEnabled(bool _fundingEnabled) public onlyOwner {
        fundingEnabled = _fundingEnabled;
        return;
    }

    function updateTokenPriceProvider(address _newTokenPriceProvider) public onlyOwner {
        require(_newTokenPriceProvider != 0);
        tokenPriceProvider = TokenPriveProviderInterface(_newTokenPriceProvider);
        require(tokenPriceProvider.tokenPrice() > 10**9);
        return;
    }

    function () public payable {
        require (fundingEnabled);
        require (ambassadorAddress != 0);
        uint tokenPrice = tokenPriceProvider.tokenPrice(); // In wei
        require (tokenPrice > 10**9);
        require (msg.value >= tokenPrice);

        totalCollected += msg.value;
        uint ambVal = (20 * msg.value)/100;
        uint tokens = (msg.value * 10**uint256(tokenContract.decimals())) / tokenPrice;

        require (tokenContract.transferFrom(spenderAddress, msg.sender, tokens));

        //Send the ether to the vault
        ambassadorAddress.transfer(ambVal);
        vaultAddress.transfer(msg.value - ambVal);

        return;
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }

        MinimalTokenInterface token = MinimalTokenInterface(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}