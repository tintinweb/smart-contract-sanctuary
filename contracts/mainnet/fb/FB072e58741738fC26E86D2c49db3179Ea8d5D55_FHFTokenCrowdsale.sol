pragma solidity 0.4.18;

contract FHFTokenInterface {
    /* Public parameters of the token */
    string public standard = &#39;Token 0.1&#39;;
    string public name = &#39;Forever Has Fallen&#39;;
    string public symbol = &#39;FC&#39;;
    uint8 public decimals = 18;

    function approveCrowdsale(address _crowdsaleAddress) external;
    function balanceOf(address _address) public constant returns (uint256 balance);
    function vestedBalanceOf(address _address) public constant returns (uint256 balance);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _currentValue, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract CrowdsaleParameters {
    ///////////////////////////////////////////////////////////////////////////
    // Configuration Independent Parameters
    ///////////////////////////////////////////////////////////////////////////

    struct AddressTokenAllocation {
        address addr;
        uint256 amount;
    }

    uint256 public maximumICOCap = 350e6;

    // ICO period timestamps:
    // 1525777200 = May 8, 2018. 11am GMT
    // 1529406000 = June 19, 2018. 11am GMT
    uint256 public generalSaleStartDate = 1525777200;
    uint256 public generalSaleEndDate = 1529406000;

    // Vesting
    // 1592564400 = June 19, 2020. 11am GMT
    uint32 internal vestingTeam = 1592564400;
    // 1529406000 = Bounty to ico end date - June 19, 2018. 11am GMT
    uint32 internal vestingBounty = 1529406000;

    ///////////////////////////////////////////////////////////////////////////
    // Production Config
    ///////////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////////
    // QA Config
    ///////////////////////////////////////////////////////////////////////////

    AddressTokenAllocation internal generalSaleWallet = AddressTokenAllocation(0x265Fb686cdd2f9a853c519592078cC4d1718C15a, 350e6);
    AddressTokenAllocation internal communityReserve =  AddressTokenAllocation(0x76d472C73681E3DF8a7fB3ca79E5f8915f9C5bA5, 450e6);
    AddressTokenAllocation internal team =              AddressTokenAllocation(0x05d46150ceDF59ED60a86d5623baf522E0EB46a2, 170e6);
    AddressTokenAllocation internal advisors =          AddressTokenAllocation(0x3d5fa25a3C0EB68690075eD810A10170e441413e, 48e5);
    AddressTokenAllocation internal bounty =            AddressTokenAllocation(0xAc2099D2705434f75adA370420A8Dd397Bf7CCA1, 176e5);
    AddressTokenAllocation internal administrative =    AddressTokenAllocation(0x438aB07D5EC30Dd9B0F370e0FE0455F93C95002e, 76e5);

    address internal playersReserve = 0x8A40B0Cf87DaF12C689ADB5C74a1B2f23B3a33e1;
}


contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    *  Constructor
    *
    *  Sets contract owner to address of constructor caller
    */
    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    *  Change Owner
    *
    *  Changes ownership of this contract. Only owner can call this method.
    *
    * @param newOwner - new owner&#39;s address
    */
    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(newOwner != owner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract FHFTokenCrowdsale is Owned, CrowdsaleParameters {
    /* Token and records */
    FHFTokenInterface private token;
    address private saleWalletAddress;
    uint private tokenMultiplier = 10;
    uint public totalCollected = 0;
    uint public saleGoal;
    bool public goalReached = false;

    /* Events */
    event TokenSale(address indexed tokenReceiver, uint indexed etherAmount, uint indexed tokenAmount, uint tokensPerEther);
    event FundTransfer(address indexed from, address indexed to, uint indexed amount);

    /**
    * Constructor
    *
    * @param _tokenAddress - address of token (deployed before this contract)
    */
    function FHFTokenCrowdsale(address _tokenAddress) public {
        token = FHFTokenInterface(_tokenAddress);
        tokenMultiplier = tokenMultiplier ** token.decimals();
        saleWalletAddress = CrowdsaleParameters.generalSaleWallet.addr;

        // Initialize sale goal
        saleGoal = CrowdsaleParameters.generalSaleWallet.amount;
    }

    /**
    * Is sale active
    *
    * @return active - True, if sale is active
    */
    function isICOActive() public constant returns (bool active) {
        active = ((generalSaleStartDate <= now) && (now < generalSaleEndDate) && (!goalReached));
        return active;
    }

    /**
    *  Process received payment
    *
    *  Determine the integer number of tokens that was purchased considering current
    *  stage, tier bonus, and remaining amount of tokens in the sale wallet.
    *  Transfer purchased tokens to backerAddress and return unused portion of
    *  ether (change)
    *
    * @param backerAddress - address that ether was sent from
    * @param amount - amount of Wei received
    */
    function processPayment(address backerAddress, uint amount) internal {
        require(isICOActive());

        // Before Metropolis update require will not refund gas, but
        // for some reason require statement around msg.value always throws
        assert(msg.value > 0 finney);

        // Tell everyone about the transfer
        FundTransfer(backerAddress, address(this), amount);

        // Calculate tokens per ETH for this tier
        uint tokensPerEth = 10000;

        // Calculate token amount that is purchased,
        uint tokenAmount = amount * tokensPerEth;

        // Check that stage wallet has enough tokens. If not, sell the rest and
        // return change.
        uint remainingTokenBalance = token.balanceOf(saleWalletAddress);
        if (remainingTokenBalance <= tokenAmount) {
            tokenAmount = remainingTokenBalance;
            goalReached = true;
        }

        // Calculate Wei amount that was received in this transaction
        // adjusted to rounding and remaining token amount
        uint acceptedAmount = tokenAmount / tokensPerEth;

        // Update crowdsale performance
        totalCollected += acceptedAmount;

        // Transfer tokens to baker and return ETH change
        token.transferFrom(saleWalletAddress, backerAddress, tokenAmount);

        TokenSale(backerAddress, amount, tokenAmount, tokensPerEth);

        // Return change (in Wei)
        uint change = amount - acceptedAmount;
        if (change > 0) {
            if (backerAddress.send(change)) {
                FundTransfer(address(this), backerAddress, change);
            }
            else revert();
        }
    }

    /**
    *  Transfer ETH amount from contract to owner&#39;s address.
    *  Can only be used if ICO is closed
    *
    * @param amount - ETH amount to transfer in Wei
    */
    function safeWithdrawal(uint amount) external onlyOwner {
        require(this.balance >= amount);
        require(!isICOActive());

        if (owner.send(amount)) {
            FundTransfer(address(this), msg.sender, amount);
        }
    }

    /**
    *  Default method
    *
    *  Processes all ETH that it receives and credits FHF tokens to sender
    *  according to current stage bonus
    */
    function () external payable {
        processPayment(msg.sender, msg.value);
    }

    /**
    * Close main sale and move unsold tokens to playersReserve wallet
    */
    function closeMainSaleICO() external onlyOwner {
        require(!isICOActive());
        require(generalSaleStartDate < now);

        var amountToMove = token.balanceOf(generalSaleWallet.addr);
        token.transferFrom(generalSaleWallet.addr, playersReserve, amountToMove);
        generalSaleEndDate = now;
    }

    /**
    *  Kill method
    *
    *  Double-checks that unsold general sale tokens were moved off general sale wallet and
    *  destructs this contract
    */
    function kill() external onlyOwner {
        require(!isICOActive());
        if (now < generalSaleStartDate) {
            selfdestruct(owner);
        } else if (token.balanceOf(generalSaleWallet.addr) == 0) {
            FundTransfer(address(this), msg.sender, this.balance);
            selfdestruct(owner);
        } else {
            revert();
        }
    }
}