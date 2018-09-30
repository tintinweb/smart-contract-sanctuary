pragma solidity ^0.4.24;

/*
* Wall Street Market presents......

.______    __       __    __   _______      ______  __    __   __  .______        _______      ___      .___  ___.  _______ 
|   _  \  |  |     |  |  |  | |   ____|    /      ||  |  |  | |  | |   _  \      /  _____|    /   \     |   \/   | |   ____|
|  |_)  | |  |     |  |  |  | |  |__      |  ,----&#39;|  |__|  | |  | |  |_)  |    |  |  __     /  ^  \    |  \  /  | |  |__   
|   _  <  |  |     |  |  |  | |   __|     |  |     |   __   | |  | |   ___/     |  | |_ |   /  /_\  \   |  |\/|  | |   __|  
|  |_)  | |  `----.|  `--&#39;  | |  |____    |  `----.|  |  |  | |  | |  |         |  |__| |  /  _____  \  |  |  |  | |  |____ 
|______/  |_______| \______/  |_______|    \______||__|  |__| |__| | _|          \______| /__/     \__\ |__|  |__| |_______|
                                                                                                                            
(BCHIP)

website:    https://wallstreetmarket.tk

discord:    https://discord.gg/8AFP9gS

25% Dividends Fees/Payouts

5% of Buy In Fee Will Go into Buying Tokens from the contract for "THE 82" group until 
400,000 tokens have been distributed.  25% Fee will apply for these transactions.

After this the 5% fee will be reserved for use in additional card and lending games using BCHIP tokens.

Referral Program pays out 33% of Buy-in/Sell Fees to user of masternode link

*/





contract AcceptsExchange {
    BlueChipGame public tokenContract;

    function AcceptsExchange(address _tokenContract) public {
        tokenContract = BlueChipGame(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
    function tokenFallbackExpanded(address _from, uint256 _value, bytes _data, address _sender, address _referrer) external returns (bool);
}


contract BlueChipGame {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    // only people with profits
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }

    modifier notContract() {
      require (msg.sender == tx.origin);
      _;
    }

    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress]);
        _;
    }


    modifier onlyActive(){
        
        require(boolContractActive);
        _;
    }

 
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );

    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "BlueChipExchange";
    string public symbol = "BCHIP";
    uint8 constant public decimals = 18;

    uint256 constant internal tokenPriceInitial_ = 0.00000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000001 ether;
    uint256 constant internal magnitude = 2**64;

   
    uint256 public totalEthFundRecieved; // total ETH Bond recieved from this contract
    uint256 public totalEthFundCollected; // total ETH Bond collected in this contract

    // proof of stake (defaults at 25 tokens)
    uint256 public stakingRequirement = 25e18;

    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 2.5 ether;
    uint256 constant internal ambassadorQuota_ = 2.5 ether;

    uint constant internal total82Tokens = 390148;



   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    mapping(uint => address) internal theGroupofEightyTwo;
    mapping(uint => uint) internal theGroupofEightyTwoAmount;

    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;


    uint8 public dividendFee_ = 20; // 20% dividend fee on each buy and sell
    uint8 public fundFee_ = 0; // 5% bond fund fee on each buy and sell
    uint8 public altFundFee_ = 5; // Fund fee rate on each buy and sell for future game

    bool boolPay82 = false;
    bool bool82Mode = true;
    bool boolContractActive = true;

    uint bondFund = 0;


    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;

    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;

    // Special Wall Street Market Platform control from scam game contracts on Wall Street Market platform
    mapping(address => bool) public canAcceptTokens_; // contracts, which can accept Wall Street tokens

    mapping(address => address) public stickyRef;

     address public bondFundAddress = 0x1822435de9b923a7a8c4fbd2f6d0aa8f743d3010;   //Bond Fund
     address public altFundAddress = 0x1822435de9b923a7a8c4fbd2f6d0aa8f743d3010;    //Alternate Fund for Future Game

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    function BlueChipGame()
        public
    {
        // add administrators here
        administrators[msg.sender] = true;

    //*  Populate the 82 Mappings 
        theGroupofEightyTwo[1] = 0x41fe3738b503cbafd01c1fd8dd66b7fe6ec11b01;
        theGroupofEightyTwo[2] = 0x96762288ebb2560a19f8eadaaa2012504f64278b;
        theGroupofEightyTwo[3] = 0xc29a6dd21801e58566df9f003b7011e30724543e;
        theGroupofEightyTwo[4] = 0xc63ea85cc823c440319013d4b30e19b66466642d;
        theGroupofEightyTwo[5] = 0xc6f827796a2e1937fd7f97c4e0a4906c476794f6;
        theGroupofEightyTwo[6] = 0xe74b1ea522b9d558c8e8719c3b1c4a9050b531ca;
        theGroupofEightyTwo[7] = 0x6b90d498062140c607d03fd642377eeaa325703e;
        theGroupofEightyTwo[8] = 0x5f1088110edcba27fc206cdcc326b413b5867361;
        theGroupofEightyTwo[9] = 0xc92fd0e554b12eb10f584819eec2394a9a6f3d1d;
        theGroupofEightyTwo[10] = 0xb62a0ac2338c227748e3ce16d137c6282c9870cf;
        theGroupofEightyTwo[11] = 0x3f6c42409da6faf117095131168949ab81d5947d;
        theGroupofEightyTwo[12] = 0xd54c47b3165508fb5418dbdec59a0d2448eeb3d7;
        theGroupofEightyTwo[13] = 0x285d366834afaa8628226e65913e0dd1aa26b1f8;
        theGroupofEightyTwo[14] = 0x285d366834afaa8628226e65913e0dd1aa26b1f8;
        theGroupofEightyTwo[15] = 0x5f5996f9e1960655d6fc00b945fef90672370d9f;
        theGroupofEightyTwo[16] = 0x3825c8ba07166f34ce9a2cd1e08a68b105c82cb9;
        theGroupofEightyTwo[17] = 0x7f3e05b4f258e1c15a0ef49894cffa1d89ceb9d3;
        theGroupofEightyTwo[18] = 0x3191acf877495e5f4e619ec722f6f38839182660;
        theGroupofEightyTwo[19] = 0x14f981ec7b0f59df6e1c56502e272298f221d763;
        theGroupofEightyTwo[20] = 0xae817ec70d8b621bb58a047e63c31445f79e20dc;
        theGroupofEightyTwo[21] = 0xc43af3becac9c810384b69cf061f2d7ec73105c4;
        theGroupofEightyTwo[22] = 0x0743469569ed5cc44a51216a1bf5ad7e7f90f40e;
        theGroupofEightyTwo[23] = 0xff6a4d0ed374ba955048664d6ef5448c6cd1d56a;
        theGroupofEightyTwo[24] = 0x62358a483311b3de29ae987b990e19de6259fa9c;
        theGroupofEightyTwo[25] = 0xa0fea1bcfa32713afdb73b9908f6cb055022e95f;
        theGroupofEightyTwo[26] = 0xb2af816608e1a4d0fb12b81028f32bac76256eba;
        theGroupofEightyTwo[27] = 0x977193d601b364f38ab1a832dbaef69ca7833992;
        theGroupofEightyTwo[28] = 0xed3547f0ed028361685b39cd139aa841df6629ab;
        theGroupofEightyTwo[29] = 0xe40ff298079493cba637d92089e3d1db403974cb;
        theGroupofEightyTwo[30] = 0xae3dc7fa07f9dd030fa56c027e90998ed9fe9d61;
        theGroupofEightyTwo[31] = 0x2dd35e7a6f5fcc28d146c04be641f969f6d1e403;
        theGroupofEightyTwo[32] = 0x2afe21ec5114339922d38546a3be7a0b871d3a0d;
        theGroupofEightyTwo[33] = 0x6696fee394bb224d0154ea6b58737dca827e1960;
        theGroupofEightyTwo[34] = 0xccdf159b1340a35c3567b669c836a88070051314;
        theGroupofEightyTwo[35] = 0x1c3416a34c86f9ddcd05c7828bf5693308d19e0b;
        theGroupofEightyTwo[36] = 0x846dedb19b105edafac2c9410fa2b5e73b596a14;
        theGroupofEightyTwo[37] = 0x3e9294f9b01bc0bcb91413112c75c3225c65d0b3;
        theGroupofEightyTwo[38] = 0x3a5ce61c74343dde474bad4210cccf1dac7b1934;
        theGroupofEightyTwo[39] = 0x38e123f89a7576b2942010ad1f468cc0ea8f9f4b;
        theGroupofEightyTwo[40] = 0xdcd8bad894035b5c554ad450ca84ae6be0b73122;
        theGroupofEightyTwo[41] = 0xcfab320d4379a84fe3736eccf56b09916e35097b;
        theGroupofEightyTwo[42] = 0x12f53c1d7caea0b41010a0e53d89c801ed579b5a;
        theGroupofEightyTwo[43] = 0x5145a296e1bb9d4cf468d6d97d7b6d15700f39ef;
        theGroupofEightyTwo[44] = 0xac707a1b4396a309f4ad01e3da4be607bbf14089;
        theGroupofEightyTwo[45] = 0x38602d1446fe063444b04c3ca5ecde0cba104240;
        theGroupofEightyTwo[46] = 0xc951d3463ebba4e9ec8ddfe1f42bc5895c46ec8f;
        theGroupofEightyTwo[47] = 0x69e566a65d00ad5987359db9b3ced7e1cfe9ac69;
        theGroupofEightyTwo[48] = 0x533b14f6d04ed3c63a68d5e80b7b1f6204fb4213;
        theGroupofEightyTwo[49] = 0x5fa0b03bee5b4e6643a1762df718c0a4a7c1842f;
        theGroupofEightyTwo[50] = 0xb74d5f0a81ce99ac1857133e489bc2b4954935ff;
        theGroupofEightyTwo[51] = 0xc371117e0adfafe2a3b7b6ba71b7c0352ca7789d;
        theGroupofEightyTwo[52] = 0xcade49e583bc226f19894458f8e2051289f1ac85;
        theGroupofEightyTwo[53] = 0xe3fc95aba6655619db88b523ab487d5273db484f;
        theGroupofEightyTwo[54] = 0x22e4d1433377a2a18452e74fd4ba9eea01824f7d;
        theGroupofEightyTwo[55] = 0x32ae5eff81881a9a70fcacada5bb1925cabca508;
        theGroupofEightyTwo[56] = 0xb864d177c291368b52a63a95eeff36e3731303c1;
        theGroupofEightyTwo[57] = 0x46091f77b224576e224796de5c50e8120ad7d764;
        theGroupofEightyTwo[58] = 0xc6407dd687a179aa11781b8a1e416bd0515923c2;
        theGroupofEightyTwo[59] = 0x2502ce06dcb61ddf5136171768dfc08d41db0a75;
        theGroupofEightyTwo[60] = 0x6b80ca9c66cdcecc39893993df117082cc32bb16;
        theGroupofEightyTwo[61] = 0xa511ddba25ffd74f19a400fa581a15b5044855ce;
        theGroupofEightyTwo[62] = 0xce81d90ae52d34588a95db59b89948c8fec487ce;
        theGroupofEightyTwo[63] = 0x6d60dbf559bbf0969002f19979cad909c2644dad;
        theGroupofEightyTwo[64] = 0x45101255a2bcad3175e6fda4020a9b77e6353a9a;
        theGroupofEightyTwo[65] = 0xe9078d7539e5eac3b47801a6ecea8a9ec8f59375;
        theGroupofEightyTwo[66] = 0x41a21b264f9ebf6cf571d4543a5b3ab1c6bed98c;
        theGroupofEightyTwo[67] = 0x471e8d970c30e61403186b6f245364ae790d14c3;
        theGroupofEightyTwo[68] = 0x6eb7f74ff7f57f7ba45ca71712bccef0588d8f0d;
        theGroupofEightyTwo[69] = 0xe6d6bc079d76dc70fcec5de84721c7b0074d164b;
        theGroupofEightyTwo[70] = 0x3ec5972c2177a08fd5e5f606f19ab262d28ceffe;
        theGroupofEightyTwo[71] = 0x108b87a18877104e07bd870af70dfc2487447262;
        theGroupofEightyTwo[72] = 0x3129354440e4639d2b809ca03d4ccc6277ac8167;
        theGroupofEightyTwo[73] = 0x21572b6a855ee8b1392ed1003ecf3474fa83de3e;
        theGroupofEightyTwo[74] = 0x75ab98f33a7a60c4953cb907747b498e0ee8edf7;
        theGroupofEightyTwo[75] = 0x0fe6967f9a5bb235fc74a63e3f3fc5853c55c083;
        theGroupofEightyTwo[76] = 0x49545640b9f3266d13cce842b298d450c0f8d776;
        theGroupofEightyTwo[77] = 0x9327128ead2495f60d41d3933825ffd8080d4d42;
        theGroupofEightyTwo[78] = 0x82b4e53a7d6bf6c72cc57f8d70dae90a34f0870f;
        theGroupofEightyTwo[79] = 0xb74d5f0a81ce99ac1857133e489bc2b4954935ff;
        theGroupofEightyTwo[80] = 0x3749d556c167dd73d536a6faaf0bb4ace8f7dab9;
        theGroupofEightyTwo[81] = 0x3039f6857071692b540d9e1e759a0add93af3fed;
        theGroupofEightyTwo[82] = 0xb74d5f0a81ce99ac1857133e489bc2b4954935ff;
        theGroupofEightyTwo[83] = 0x13015632fa722C12E862fF38c8cF2354cbF26c47;   //This one is for testing


        theGroupofEightyTwoAmount[1] = 100000;
        theGroupofEightyTwoAmount[2] = 30000;
        theGroupofEightyTwoAmount[3] = 24400;
        theGroupofEightyTwoAmount[4] = 21111;
        theGroupofEightyTwoAmount[5] = 14200;
        theGroupofEightyTwoAmount[6] = 13788;
        theGroupofEightyTwoAmount[7] = 12003;
        theGroupofEightyTwoAmount[8] = 11000;
        theGroupofEightyTwoAmount[9] = 11000;
        theGroupofEightyTwoAmount[10] = 8800;
        theGroupofEightyTwoAmount[11] = 7000;
        theGroupofEightyTwoAmount[12] = 7000;
        theGroupofEightyTwoAmount[13] = 6000;
        theGroupofEightyTwoAmount[14] = 5400;
        theGroupofEightyTwoAmount[15] = 5301;
        theGroupofEightyTwoAmount[16] = 5110;
        theGroupofEightyTwoAmount[17] = 5018;
        theGroupofEightyTwoAmount[18] = 5000;
        theGroupofEightyTwoAmount[19] = 5000;
        theGroupofEightyTwoAmount[20] = 5000;
        theGroupofEightyTwoAmount[21] = 5000;
        theGroupofEightyTwoAmount[22] = 4400;
        theGroupofEightyTwoAmount[23] = 4146;
        theGroupofEightyTwoAmount[24] = 4086;
        theGroupofEightyTwoAmount[25] = 4000;
        theGroupofEightyTwoAmount[26] = 4000;
        theGroupofEightyTwoAmount[27] = 3500;
        theGroupofEightyTwoAmount[28] = 3216;
        theGroupofEightyTwoAmount[29] = 3200;
        theGroupofEightyTwoAmount[30] = 3183;
        theGroupofEightyTwoAmount[31] = 3100;
        theGroupofEightyTwoAmount[32] = 3001;
        theGroupofEightyTwoAmount[33] = 2205;
        theGroupofEightyTwoAmount[34] = 2036;
        theGroupofEightyTwoAmount[35] = 2000;
        theGroupofEightyTwoAmount[36] = 2000;
        theGroupofEightyTwoAmount[37] = 1632;
        theGroupofEightyTwoAmount[38] = 1600;
        theGroupofEightyTwoAmount[39] = 1500;
        theGroupofEightyTwoAmount[40] = 1500;
        theGroupofEightyTwoAmount[41] = 1478;
        theGroupofEightyTwoAmount[42] = 1300;
        theGroupofEightyTwoAmount[43] = 1200;
        theGroupofEightyTwoAmount[44] = 1127;
        theGroupofEightyTwoAmount[45] = 1050;
        theGroupofEightyTwoAmount[46] = 1028;
        theGroupofEightyTwoAmount[47] = 1011;
        theGroupofEightyTwoAmount[48] = 1000;
        theGroupofEightyTwoAmount[49] = 1000;
        theGroupofEightyTwoAmount[50] = 1000;
        theGroupofEightyTwoAmount[51] = 1000;
        theGroupofEightyTwoAmount[52] = 1000;
        theGroupofEightyTwoAmount[53] = 1000;
        theGroupofEightyTwoAmount[54] = 983;
        theGroupofEightyTwoAmount[55] = 980;
        theGroupofEightyTwoAmount[56] = 960;
        theGroupofEightyTwoAmount[57] = 900;
        theGroupofEightyTwoAmount[58] = 900;
        theGroupofEightyTwoAmount[59] = 839;
        theGroupofEightyTwoAmount[60] = 800;
        theGroupofEightyTwoAmount[61] = 800;
        theGroupofEightyTwoAmount[62] = 800;
        theGroupofEightyTwoAmount[63] = 798;
        theGroupofEightyTwoAmount[64] = 750;
        theGroupofEightyTwoAmount[65] = 590;
        theGroupofEightyTwoAmount[66] = 500;
        theGroupofEightyTwoAmount[67] = 500;
        theGroupofEightyTwoAmount[68] = 500;
        theGroupofEightyTwoAmount[69] = 500;
        theGroupofEightyTwoAmount[70] = 415;
        theGroupofEightyTwoAmount[71] = 388;
        theGroupofEightyTwoAmount[72] = 380;
        theGroupofEightyTwoAmount[73] = 300;
        theGroupofEightyTwoAmount[74] = 300;
        theGroupofEightyTwoAmount[75] = 170;
        theGroupofEightyTwoAmount[76] = 164;
        theGroupofEightyTwoAmount[77] = 142;
        theGroupofEightyTwoAmount[78] = 70;
        theGroupofEightyTwoAmount[79] = 69;
        theGroupofEightyTwoAmount[80] = 16;
        theGroupofEightyTwoAmount[81] = 5;
        theGroupofEightyTwoAmount[82] = 1;
        theGroupofEightyTwoAmount[83] = 1;  //This one is for testing

    }
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy)
        public
        payable
        onlyActive()
        returns(uint256)
    {
        
        require(tx.gasprice <= 0.05 szabo);
        purchaseTokens(msg.value, _referredBy);
    }

    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
        onlyActive()
    {
        require(tx.gasprice <= 0.05 szabo);

        if (boolPay82) {  //Add to the Eth Fund if boolPay82 set to true
            
           totalEthFundCollected = SafeMath.add(totalEthFundCollected, msg.value);

        } else{
            purchaseTokens(msg.value, 0x0);
        }

        
    }


    function buyTokensfor82()
        public
        onlyAdministrator()
    {
        //Periodically Use the Bond Fund to buy tokens and distribute to the Group of 82
        if(bool82Mode) 
        {
            uint counter = 83;
            uint _ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);

            totalEthFundRecieved = SafeMath.add(totalEthFundRecieved, _ethToPay);

            while (counter > 0) { 

                uint _distAmountLocal = SafeMath.div(SafeMath.mul(_ethToPay, theGroupofEightyTwoAmount[counter]),total82Tokens);

                purchaseTokensfor82(_distAmountLocal, 0x0, counter);
               
                counter = counter - 1;
            } 
           
        }
    }


    /**
     * Sends Bondf Fund ether to the bond contract
     * 
     */
    function payFund() payable public 
    onlyAdministrator()
    {
        
        uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);
        require(ethToPay > 1);

        uint256 _altEthToPay = SafeMath.div(SafeMath.mul(ethToPay,altFundFee_),100);
      
        uint256 _bondEthToPay = SafeMath.div(SafeMath.mul(ethToPay,fundFee_),100);
 

        totalEthFundRecieved = SafeMath.add(totalEthFundRecieved, ethToPay);

        if(_bondEthToPay > 0){
            if(!bondFundAddress.call.value(_bondEthToPay).gas(400000)()) {
                totalEthFundRecieved = SafeMath.sub(totalEthFundRecieved, _bondEthToPay);
            }
        }

        if(_altEthToPay > 0){
            if(!altFundAddress.call.value(_altEthToPay).gas(400000)()) {
                totalEthFundRecieved = SafeMath.sub(totalEthFundRecieved, _altEthToPay);
            }
        }
      
    }

    /**
     * Converts all of caller&#39;s dividends to tokens.
     */
    function reinvest()
        onlyStronghands()
        public
    {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code

        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, 0x0);

        // fire event
        onReinvestment(_customerAddress, _dividends, _tokens);
    }

    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);

        // lambo delivery service
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code

        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // lambo delivery service
        _customerAddress.transfer(_dividends);

        // fire event
        onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);

        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_ + altFundFee_), 100);
        
        uint256 _refPayout = _dividends / 3;
        _dividends = SafeMath.sub(_dividends, _refPayout);
        (_dividends,) = handleRef(stickyRef[msg.sender], _refPayout, _dividends, 0);

        // Take out dividends and then _fundPayout
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);

        // Add ethereum to send to fund
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
        onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }


    /**
     * Transfer tokens from the caller to a new holder.
     * REMEMBER THIS IS 0% TRANSFER FEE
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);


        // fire event
        Transfer(_customerAddress, _toAddress, _amountOfTokens);

        // ERC20
        return true;
    }

    /**
    * Transfer token to a specified address and forward the data to recipient
    * ERC-677 standard
    * https://github.com/ethereum/EIPs/issues/677
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data  Transaction metadata.
    */
    function transferAndCall(address _to, uint256 _value, bytes _data) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true); // security check that contract approved by Wall Street Exchange platform
      require(transfer(_to, _value)); // do a normal token transfer to the contract

      if (isContract(_to)) {
        AcceptsExchange receiver = AcceptsExchange(_to);
        require(receiver.tokenFallback(msg.sender, _value, _data));
      }

      return true;
    }


 /**
    * Transfer token to a specified address and forward the data to recipient
    * ERC-677 standard
    * https://github.com/ethereum/EIPs/issues/677
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data  Transaction metadata.
    * We add ability to track the initial sender so we pass that to determine the bond holder
    */
    function transferAndCallExpanded(address _to, uint256 _value, bytes _data, address _sender, address _referrer) external returns (bool) {
      require(_to != address(0));
      require(canAcceptTokens_[_to] == true); // security check that contract approved by Wall Street Exchange platform
      require(transfer(_to, _value)); // do a normal token transfer to the contract

      if (isContract(_to)) {
        AcceptsExchange receiver = AcceptsExchange(_to);
        require(receiver.tokenFallbackExpanded(msg.sender, _value, _data, msg.sender, _referrer));
      }

      return true;
    }


    /**
     * Additional check that the game address we are sending tokens to is a contract
     * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
     */
     function isContract(address _addr) private constant returns (bool is_contract) {
       // retrieve the size of the code on target address, this needs assembly
       uint length;
       assembly { length := extcodesize(_addr) }
       return length > 0;
     }

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    /**
     * In case the amassador quota is not met, the administrator can manually disable the ambassador phase.
     */
    //function disableInitialStage()
    //    onlyAdministrator()
    //    public
    //{
    //    onlyAmbassadors = false;
    //}

    
  
    function setBondFundAddress(address _newBondFundAddress)
        onlyAdministrator()
        public
    {
        bondFundAddress = _newBondFundAddress;
    }

    
    function setAltFundAddress(address _newAltFundAddress)
        onlyAdministrator()
        public
    {
        altFundAddress = _newAltFundAddress;
    }


    /**
     * Set fees/rates
     */
    function setFeeRates(uint8 _newDivRate, uint8 _newFundFee, uint8 _newAltRate)
        onlyAdministrator()
        public
    {
        require(_newDivRate <= 25);
        require(_newAltRate + _newFundFee <= 5);

        dividendFee_ = _newDivRate;
        fundFee_ = _newFundFee;
        altFundFee_ = _newAltRate;
    }


    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier, bool _status)
        onlyAdministrator()
        public
    {
        administrators[_identifier] = _status;
    }

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }

    /**
     * Add or remove game contract, which can accept Wall Street Market tokens
     */
    function setCanAcceptTokens(address _address, bool _value)
      onlyAdministrator()
      public
    {
        canAcceptTokens_[_address] = _value;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }


      /**
     * Set if we will pay the 82 group with funds in
     */
    function setBool82(bool _bool)
        onlyAdministrator()
        public
    {
        boolPay82 = _bool;
    }


      /**
     *Set if we will use 5% fund to purchase new tokens for 82 group
     */
    function set82Mode(bool _bool)
        onlyAdministrator()
        public
    {
        bool82Mode = _bool;
    }

     /**
     *Set flag for contract to accept ether
     */
    function setContractActive(bool _bool)
        onlyAdministrator()
        public
    {
        boolContractActive = _bool;
    }

    


    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return this.balance;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }

 

    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice()
        public
        view
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_ + altFundFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice()
        public
        view
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
            uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_ + altFundFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _ethereumToSpend)
        public
        view
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, fundFee_ + altFundFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _fundPayout);
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEthereumReceived(uint256 _tokensToSell)
        public
        view
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_ + altFundFee_), 100);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
        return _taxedEthereum;
    }

    /**
     * Function for the frontend to show ether waiting to be send to fund in contract
     */
    function etherToSendFund()
        public
        view
        returns(uint256) {
        return SafeMath.sub(totalEthFundCollected, totalEthFundRecieved);
    }


    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/

    // Make sure we will send back excess if user sends more then 5 ether before 10 ETH in contract
    function purchaseInternal(uint256 _incomingEthereum, address _referredBy)
      notContract()// no contracts allowed
      internal
      returns(uint256) {

      uint256 purchaseEthereum = _incomingEthereum;
      uint256 excess;
      if(purchaseEthereum > 2.5 ether) { // check if the transaction is over 2.5 ether
          if (SafeMath.sub(address(this).balance, purchaseEthereum) <= 10 ether) { // if so check the contract is less then 100 ether
              purchaseEthereum = 2.5 ether;
              excess = SafeMath.sub(_incomingEthereum, purchaseEthereum);
          }
      }

      purchaseTokens(purchaseEthereum, _referredBy);

      if (excess > 0) {
        msg.sender.transfer(excess);
      }
    }

    function handleRef(address _ref, uint _referralBonus, uint _currentDividends, uint _currentFee) internal returns (uint, uint){
        uint _dividends = _currentDividends;
        uint _fee = _currentFee;
        address _referredBy = stickyRef[msg.sender];
        if (_referredBy == address(0x0)){
            _referredBy = _ref;
        }
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != msg.sender &&

            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            if (stickyRef[msg.sender] == address(0x0)){
                stickyRef[msg.sender] = _referredBy;
            }
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus/2);
            address currentRef = stickyRef[_referredBy];
            if (currentRef != address(0x0) && tokenBalanceLedger_[currentRef] >= stakingRequirement){
                referralBalance_[currentRef] = SafeMath.add(referralBalance_[currentRef], (_referralBonus/10)*3);
                currentRef = stickyRef[currentRef];
                if (currentRef != address(0x0) && tokenBalanceLedger_[currentRef] >= stakingRequirement){
                    referralBalance_[currentRef] = SafeMath.add(referralBalance_[currentRef], (_referralBonus/10)*2);
                }
                else{
                    _dividends = SafeMath.add(_dividends, _referralBonus - _referralBonus/2 - (_referralBonus/10)*3);
                    _fee = _dividends * magnitude;
                }
            }
            else{
                _dividends = SafeMath.add(_dividends, _referralBonus - _referralBonus/2);
                _fee = _dividends * magnitude;
            }
            
            
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        return (_dividends, _fee);
    }


    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
       
        internal
        returns(uint256)
    {
        // data setup
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundFee_ + altFundFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _fee;
        (_dividends, _fee) = handleRef(_referredBy, _referralBonus, _dividends, _fee);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _dividends), _fundPayout);
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);


        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));



        // we can&#39;t give people infinite ethereum
        if(tokenSupply_ > 0){
 
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[msg.sender] = SafeMath.add(tokenBalanceLedger_[msg.sender], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[msg.sender] += _updatedPayouts;

        // fire event
        onTokenPurchase(msg.sender, _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }


    //*Seperate function to handle internal purchases for the 82 Group
    function purchaseTokensfor82(uint256 _incomingEthereum, address _referredBy, uint _playerIndex)
       
        internal
        returns(uint256)
    {
        // data setup
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundFee_ + altFundFee_), 100);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _fee;
        (_dividends, _fee) = handleRef(_referredBy, _referralBonus, _dividends, _fee);
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _dividends), _fundPayout);
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);

        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);


        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));



        // we can&#39;t give people infinite ethereum
        if(tokenSupply_ > 0){
 
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[theGroupofEightyTwo[_playerIndex]] = SafeMath.add(tokenBalanceLedger_[theGroupofEightyTwo[_playerIndex]], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them;
        //really i know you think you do but you don&#39;t
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[theGroupofEightyTwo[_playerIndex]] += _updatedPayouts;

        // fire event
        onTokenPurchase(theGroupofEightyTwo[_playerIndex], _incomingEthereum, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;

        return _tokensReceived;
    }

    /**
     * Calculate token sell value.
     * It&#39;s an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }


    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

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