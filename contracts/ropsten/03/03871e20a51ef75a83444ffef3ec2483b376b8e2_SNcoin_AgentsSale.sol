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
contract SNcoin_AgentsSale is Owned {
    MinimalTokenInterface public tokenContract;
    address public spenderAddress;
    address public vaultAddress;
    bool public fundingEnabled;
    uint public totalCollected;         // In wei
    TokenPriveProviderInterface public tokenPriceProvider;         // In wei
    mapping(address => address) agents;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _tokenAddress, address _spenderAddress, address _vaultAddress, bool _fundingEnabled, address _tokenPriceProvider) public {
        require (_tokenAddress != 0);
        require (_spenderAddress != 0);
        require (_vaultAddress != 0);
        require (_tokenPriceProvider != 0);
        tokenContract = MinimalTokenInterface(_tokenAddress);
        spenderAddress = _spenderAddress;
        vaultAddress = _vaultAddress;
        fundingEnabled = _fundingEnabled;
        tokenPriceProvider = TokenPriveProviderInterface(_tokenPriceProvider);
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

    function setAgentAddress(address _agentSigner, address _agentAddress) public onlyOwner {
        require (_agentSigner != 0);
        agents[_agentSigner] = _agentAddress;
        return;
    }

    function buy(uint _discount, bytes _promocode) public payable {
        require (fundingEnabled);
        uint tokenPrice = tokenPriceProvider.tokenPrice(); // In wei
        require (tokenPrice > 10**9);
        require (msg.value >= tokenPrice);
        require (_discount <= 20);
        require (_promocode.length == 97);


        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes32 h;
        assembly {
          r := mload(add(_promocode, 32))
          s := mload(add(_promocode, 64))
          v := and(mload(add(_promocode, 65)), 255)
          h := mload(add(_promocode, 97))
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        require ((v == 27) || (v == 28));

        address agentSigner = ecrecover(h, v, r, s);
        require (agentSigner != 0);
        require (agents[agentSigner] != 0);
        bytes32 check_h = keccak256(abi.encodePacked(_discount, msg.sender));
        require (check_h == h);

        uint remVal = ((20 - _discount)*msg.value)/100;
        totalCollected += msg.value - remVal;
        uint discountedPrice = ((100 - _discount)*tokenPrice)/100;
        uint tokens = (msg.value * 10**uint256(tokenContract.decimals())) / discountedPrice;

        require (tokenContract.transferFrom(spenderAddress, msg.sender, tokens));
        //Send the ether to the vault
        vaultAddress.transfer(msg.value - remVal);
        agents[agentSigner].transfer(remVal);

        return;
    }

    // ------------------------------------------------------------------------
    // Don&#39;t accept plain ETH transfers
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
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