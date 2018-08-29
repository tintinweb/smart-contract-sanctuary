pragma solidity ^0.4.11;

/// @title DNNToken contract - Main DNN contract
/// @author Dondrey Taylor - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="73171c1d1701160a33171d1d5d1e16171a12">[email&#160;protected]</a>>
contract DNNToken {
    enum DNNSupplyAllocations {
        EarlyBackerSupplyAllocation,
        PRETDESupplyAllocation,
        TDESupplyAllocation,
        BountySupplyAllocation,
        WriterAccountSupplyAllocation,
        AdvisorySupplyAllocation,
        PlatformSupplyAllocation
    }
    function issueTokens(address, uint256, DNNSupplyAllocations) public returns (bool) {}
}

/// @title DNNRedemption contract - Issues DNN tokens
/// @author Dondrey Taylor - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d2b6bdbcb6a0b7ab92b6bcbcfcbfb7b6bbb3">[email&#160;protected]</a>>
contract DNNRedemption {

    /////////////////////////
    // DNN Token Contract  //
    /////////////////////////
    DNNToken public dnnToken;

    //////////////////////////////////////////
    // Addresses of the co-founders of DNN. //
    //////////////////////////////////////////
    address public cofounderA;
    address public cofounderB;

    /////////////////////////////////////////////////
    // Number of tokens distributed (in atto-DNN) //
    /////////////////////////////////////////////////
    uint256 public tokensDistributed = 0;

    //////////////////////////////////////////////////////////////////
    // Maximum number of tokens for this distribution (in atto-DNN) //
    //////////////////////////////////////////////////////////////////
    uint256 public maxTokensToDistribute = 30000000 * 1 ether;

    ///////////////////////////////////////////////
    // Used to generate number of tokens to send //
    ///////////////////////////////////////////////
    uint256 public seed = 8633926795440059073718754917553891166080514579013872221976080033791214;

    /////////////////////////////////////////////////
    // We&#39;ll keep track of who we have sent DNN to //
    /////////////////////////////////////////////////
    mapping(address => uint256) holders;

    /////////////////////////////////////////////////////////////////////////////
    // Event triggered when tokens are transferred from one address to another //
    /////////////////////////////////////////////////////////////////////////////
    event Redemption(address indexed to, uint256 value);


    ////////////////////////////////////////////////////
    // Checks if CoFounders are performing the action //
    ////////////////////////////////////////////////////
    modifier onlyCofounders() {
        require (msg.sender == cofounderA || msg.sender == cofounderB);
        _;
    }

    ///////////////////////////////////////////////////////////////
    // @des DNN Holder Check                                     //
    // @param Checks if we sent DNN to the benfeficiary before   //
    ///////////////////////////////////////////////////////////////
    function hasDNN(address beneficiary) public view returns (bool) {
        return holders[beneficiary] > 0;
    }

    ///////////////////////////////////////////////////
    // Make sure that user did no redeeem DNN before //
    ///////////////////////////////////////////////////
    modifier doesNotHaveDNN(address beneficiary) {
        require(hasDNN(beneficiary) == false);
        _;
    }

    //////////////////////////////////////////////////////////
    //  @des Updates max token distribution amount          //
    //  @param New amount of tokens that can be distributed //
    //////////////////////////////////////////////////////////
    function updateMaxTokensToDistribute(uint256 maxTokens)
      public
      onlyCofounders
    {
        maxTokensToDistribute = maxTokens;
    }

    ///////////////////////////////////////////////////////////////
    // @des Issues bounty tokens                                 //
    // @param beneficiary Address the tokens will be issued to.  //
    ///////////////////////////////////////////////////////////////
    function issueTokens(address beneficiary)
        public
        doesNotHaveDNN(beneficiary)
        returns (uint256)
    {
        // Number of tokens that we&#39;ll send
        uint256 tokenCount = (uint(keccak256(abi.encodePacked(blockhash(block.number-1), seed ))) % 1000);

        // If the amount is over 200 then we&#39;ll cap the tokens we&#39;ll
        // give to 200 to prevent giving too many. Since the highest amount
        // of tokens earned in the bounty was 99 DNN, we&#39;ll be issuing a bonus to everyone
        // for the long wait.
        if (tokenCount > 200) {
            tokenCount = 200;
        }

        // Change atto-DNN to DNN
        tokenCount = tokenCount * 1 ether;

        // If we have reached our max tokens then we&#39;ll bail out of the transaction
        if (tokensDistributed+tokenCount > maxTokensToDistribute) {
            revert();
        }

        // Update holder balance
        holders[beneficiary] = tokenCount;

        // Update total amount of tokens distributed (in atto-DNN)
        tokensDistributed = tokensDistributed + tokenCount;

        // Allocation type will be Platform
        DNNToken.DNNSupplyAllocations allocationType = DNNToken.DNNSupplyAllocations.PlatformSupplyAllocation;

        // Attempt to issue tokens
        if (!dnnToken.issueTokens(beneficiary, tokenCount, allocationType)) {
            revert();
        }

        // Emit redemption event
        Redemption(beneficiary, tokenCount);

        return tokenCount;
    }

    ///////////////////////////////
    // @des Contract constructor //
    ///////////////////////////////
    constructor() public
    {
        // Set token address
        dnnToken = DNNToken(0x9d9832d1beb29cc949d75d61415fd00279f84dc2);

        // Set cofounder addresses
        cofounderA = 0x3Cf26a9FE33C219dB87c2e50572e50803eFb2981;
        cofounderB = 0x9FFE2aD5D76954C7C25be0cEE30795279c4Cab9f;
    }

    ////////////////////////////////////////////////////////
    // @des ONLY SEND 0 ETH TRANSACTIONS TO THIS CONTRACT //
    ////////////////////////////////////////////////////////
    function () public payable {
        if (!hasDNN(msg.sender)) issueTokens(msg.sender);
        else revert();
    }
}