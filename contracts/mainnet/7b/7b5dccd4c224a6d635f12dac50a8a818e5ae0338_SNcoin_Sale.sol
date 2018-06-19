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
    function decimals() public returns (uint8);
}

// ----------------------------------------------------------------------------
// Dividends implementation interface
// ----------------------------------------------------------------------------
contract SNcoin_Sale is Owned {
    MinimalTokenInterface public tokenContract;
    address public vaultAddress;
    bool public fundingEnabled;
    uint public totalCollected;         // In wei
    uint public tokenPrice;         // In wei

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _tokenAddress, address _vaultAddress, bool _fundingEnabled, uint _newTokenPrice) public {
        require((_tokenAddress != 0) && (_vaultAddress != 0) && (_newTokenPrice > 0));
        tokenContract = MinimalTokenInterface(_tokenAddress);
        vaultAddress = _vaultAddress;
        fundingEnabled = _fundingEnabled;
        tokenPrice = _newTokenPrice;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
        return;
    }

    function setFundingEnabled(bool _fundingEnabled) public onlyOwner {
        fundingEnabled = _fundingEnabled;
        return;
    }

    function updateTokenPrice(uint _newTokenPrice) public onlyOwner {
        require(_newTokenPrice > 0);
        tokenPrice = _newTokenPrice;
        return;
    }

    function () public payable {
        require (fundingEnabled && (tokenPrice > 0) && (msg.value >= tokenPrice));
        
        totalCollected += msg.value;

        //Send the ether to the vault
        vaultAddress.transfer(msg.value);

        uint tokens = (msg.value * 10**uint256(tokenContract.decimals())) / tokenPrice;
        require (tokenContract.transfer(msg.sender, tokens));

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