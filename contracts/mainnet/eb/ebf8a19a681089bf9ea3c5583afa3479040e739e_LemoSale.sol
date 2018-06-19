pragma solidity ^0.4.18;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
    public
    auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
    public
    auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
}

contract ERC20 {
    /// @return total amount of tokens
    function totalSupply() constant public returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract LemoSale is DSAuth, DSMath {
    ERC20 public token;                  // The LemoCoin token

    bool public funding = true; // funding state

    uint256 public startTime = 0; // crowdsale start time (in seconds)
    uint256 public endTime = 0; // crowdsale end time (in seconds)
    uint256 public finney2LemoRate = 0; // how many tokens one wei equals
    uint256 public tokenContributionCap = 0; // max amount raised during crowdsale
    uint256 public tokenContributionMin = 0; // min amount raised during crowdsale
    uint256 public soldAmount = 0; // total sold token amount
    uint256 public minPayment = 0; // min eth each time
    uint256 public contributionCount = 0;

    // triggered when contribute successful
    event Contribution(address indexed _contributor, uint256 _amount, uint256 _return);
    // triggered when refund successful
    event Refund(address indexed _from, uint256 _value);
    // triggered when crowdsale is over
    event Finalized(uint256 _time);

    modifier between(uint256 _startTime, uint256 _endTime) {
        require(block.timestamp >= _startTime && block.timestamp < _endTime);
        _;
    }

    function LemoSale(uint256 _tokenContributionMin, uint256 _tokenContributionCap, uint256 _finney2LemoRate) public {
        require(_finney2LemoRate > 0);
        require(_tokenContributionMin > 0);
        require(_tokenContributionCap > 0);
        require(_tokenContributionCap > _tokenContributionMin);

        finney2LemoRate = _finney2LemoRate;
        tokenContributionMin = _tokenContributionMin;
        tokenContributionCap = _tokenContributionCap;
    }

    function initialize(uint256 _startTime, uint256 _endTime, uint256 _minPaymentFinney) public auth {
        require(_startTime < _endTime);
        require(_minPaymentFinney > 0);

        startTime = _startTime;
        endTime = _endTime;
        // Ether is to big to pass in the function, So we use Finney. 1 Finney = 0.001 Ether
        minPayment = _minPaymentFinney * 1 finney;
    }

    function setTokenContract(ERC20 tokenInstance) public auth {
        assert(address(token) == address(0));
        require(tokenInstance.balanceOf(owner) > tokenContributionMin);

        token = tokenInstance;
    }

    function() public payable {
        contribute();
    }

    function contribute() public payable between(startTime, endTime) {
        uint256 max = tokenContributionCap;
        uint256 oldSoldAmount = soldAmount;
        require(oldSoldAmount < max);
        require(msg.value >= minPayment);

        uint256 reward = mul(msg.value, finney2LemoRate) / 1 finney;
        uint256 refundEth = 0;

        uint256 newSoldAmount = add(oldSoldAmount, reward);
        if (newSoldAmount > max) {
            uint over = newSoldAmount - max;
            refundEth = over / finney2LemoRate * 1 finney;
            reward = max - oldSoldAmount;
            soldAmount = max;
        } else {
            soldAmount = newSoldAmount;
        }

        token.transferFrom(owner, msg.sender, reward);
        Contribution(msg.sender, msg.value, reward);
        contributionCount++;
        if (refundEth > 0) {
            Refund(msg.sender, refundEth);
            msg.sender.transfer(refundEth);
        }
    }

    function finalize() public auth {
        require(funding);
        require(block.timestamp >= endTime);
        require(soldAmount >= tokenContributionMin);

        funding = false;
        Finalized(block.timestamp);
        owner.transfer(this.balance);
    }

    // Withdraw in 3 month after failed. So funds not locked in contract forever
    function withdraw() public auth {
        require(this.balance > 0);
        require(block.timestamp >= endTime + 3600 * 24 * 30 * 3);

        owner.transfer(this.balance);
    }

    function destroy() public auth {
        require(block.timestamp >= endTime + 3600 * 24 * 30 * 3);

        selfdestruct(owner);
    }

    function refund() public {
        require(funding);
        require(block.timestamp >= endTime && soldAmount <= tokenContributionMin);

        uint256 tokenAmount = token.balanceOf(msg.sender);
        require(tokenAmount > 0);

        // need user approve first
        token.transferFrom(msg.sender, owner, tokenAmount);
        soldAmount = sub(soldAmount, tokenAmount);

        uint256 refundEth = tokenAmount / finney2LemoRate * 1 finney;
        Refund(msg.sender, refundEth);
        msg.sender.transfer(refundEth);
    }
}