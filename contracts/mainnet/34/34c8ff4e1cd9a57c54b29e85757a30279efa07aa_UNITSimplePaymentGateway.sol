pragma solidity ^0.4.18;

//Interfaces

// https://github.com/ethereum/EIPs/issues/20
interface ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() public constant returns (uint);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
}

contract UnilotToken is ERC20 {
    struct TokenStage {
        string name;
        uint numCoinsStart;
        uint coinsAvailable;
        uint bonus;
        uint startsAt;
        uint endsAt;
        uint balance; //Amount of ether sent during this stage
    }

    //Token symbol
    string public constant symbol = "UNIT";
    //Token name
    string public constant name = "Unilot token";
    //It can be reeeealy small
    uint8 public constant decimals = 18;

    //This one duplicates the above but will have to use it because of
    //solidity bug with power operation
    uint public constant accuracy = 1000000000000000000;

    //500 mln tokens
    uint256 internal _totalSupply = 500 * (10**6) * accuracy;

    //Public investor can buy tokens for 30 ether at maximum
    uint256 public constant singleInvestorCap = 30 ether; //30 ether

    //Distribution units
    uint public constant DST_ICO     = 62; //62%
    uint public constant DST_RESERVE = 10; //10%
    uint public constant DST_BOUNTY  = 3;  //3%
    //Referral and Bonus Program
    uint public constant DST_R_N_B_PROGRAM = 10; //10%
    uint public constant DST_ADVISERS      = 5;  //5%
    uint public constant DST_TEAM          = 10; //10%

    //Referral Bonuses
    uint public constant REFERRAL_BONUS_LEVEL1 = 5; //5%
    uint public constant REFERRAL_BONUS_LEVEL2 = 4; //4%
    uint public constant REFERRAL_BONUS_LEVEL3 = 3; //3%
    uint public constant REFERRAL_BONUS_LEVEL4 = 2; //2%
    uint public constant REFERRAL_BONUS_LEVEL5 = 1; //1%

    //Token amount
    //25 mln tokens
    uint public constant TOKEN_AMOUNT_PRE_ICO = 25 * (10**6) * accuracy;
    //5 mln tokens
    uint public constant TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE1 = 5 * (10**6) * accuracy;
    //5 mln tokens
    uint public constant TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE2 = 5 * (10**6) * accuracy;
    //5 mln tokens
    uint public constant TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE3 = 5 * (10**6) * accuracy;
    //5 mln tokens
    uint public constant TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE4 = 5 * (10**6) * accuracy;
    //122.5 mln tokens
    uint public constant TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE5 = 1225 * (10**5) * accuracy;
    //265 mln tokens
    uint public constant TOKEN_AMOUNT_ICO_STAGE2 = 1425 * (10**5) * accuracy;

    uint public constant BONUS_PRE_ICO = 40; //40%
    uint public constant BONUS_ICO_STAGE1_PRE_SALE1 = 35; //35%
    uint public constant BONUS_ICO_STAGE1_PRE_SALE2 = 30; //30%
    uint public constant BONUS_ICO_STAGE1_PRE_SALE3 = 25; //25%
    uint public constant BONUS_ICO_STAGE1_PRE_SALE4 = 20; //20%
    uint public constant BONUS_ICO_STAGE1_PRE_SALE5 = 0; //0%
    uint public constant BONUS_ICO_STAGE2 = 0; //No bonus

    //Token Price on Coin Offer
    uint256 public constant price = 79 szabo; //0.000079 ETH

    address public constant ADVISORS_WALLET = 0x77660795BD361Cd43c3627eAdad44dDc2026aD17;
    address public constant RESERVE_WALLET = 0x731B47847352fA2cFf83D5251FD6a5266f90878d;
    address public constant BOUNTY_WALLET = 0x794EF9c680bDD0bEf48Bef46bA68471e449D67Fb;
    address public constant R_N_D_WALLET = 0x794EF9c680bDD0bEf48Bef46bA68471e449D67Fb;
    address public constant STORAGE_WALLET = 0xE2A8F147fc808738Cab152b01C7245F386fD8d89;

    // Owner of this contract
    address public administrator;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    //Mostly needed for internal use
    uint256 internal totalCoinsAvailable;

    //All token stages. Total 6 stages
    TokenStage[7] stages;

    //Index of current stage in stage array
    uint currentStage;

    //Enables or disables debug mode. Debug mode is set only in constructor.
    bool isDebug = false;

    event StageUpdated(string from, string to);

    // Functions with this modifier can only be executed by the owner
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }

    modifier notAdministrator() {
        require(msg.sender != administrator);
        _;
    }

    modifier onlyDuringICO() {
        require(currentStage < stages.length);
        _;
    }

    modifier onlyAfterICO(){
        require(currentStage >= stages.length);
        _;
    }

    modifier meetTheCap() {
        require(msg.value >= price); // At least one token
        _;
    }

    modifier isFreezedReserve(address _address) {
        require( ( _address == RESERVE_WALLET ) && now > (stages[ (stages.length - 1) ].endsAt + 182 days));
        _;
    }

    // Constructor
    function UnilotToken()
        public
    {
        administrator = msg.sender;
        totalCoinsAvailable = _totalSupply;
        //Was as fn parameter for debugging
        isDebug = false;

        _setupStages();
        _proceedStage();
    }

    function prealocateCoins()
        public
        onlyAdministrator
    {
        totalCoinsAvailable -= balances[ADVISORS_WALLET] += ( ( _totalSupply * DST_ADVISERS ) / 100 );
        totalCoinsAvailable -= balances[RESERVE_WALLET] += ( ( _totalSupply * DST_RESERVE ) / 100 );

        address[7] memory teamWallets = getTeamWallets();
        uint teamSupply = ( ( _totalSupply * DST_TEAM ) / 100 );
        uint memberAmount = teamSupply / teamWallets.length;

        for(uint i = 0; i < teamWallets.length; i++) {
            if ( i == ( teamWallets.length - 1 ) ) {
                memberAmount = teamSupply;
            }

            balances[teamWallets[i]] += memberAmount;
            teamSupply -= memberAmount;
            totalCoinsAvailable -= memberAmount;
        }
    }

    function getTeamWallets()
        public
        pure
        returns (address[7] memory result)
    {
        result[0] = 0x40e3D8fFc46d73Ab5DF878C751D813a4cB7B388D;
        result[1] = 0x5E065a80f6635B6a46323e3383057cE6051aAcA0;
        result[2] = 0x0cF3585FbAB2a1299F8347a9B87CF7B4fcdCE599;
        result[3] = 0x5fDd3BA5B6Ff349d31eB0a72A953E454C99494aC;
        result[4] = 0xC9be9818eE1B2cCf2E4f669d24eB0798390Ffb54;
        result[5] = 0x77660795BD361Cd43c3627eAdad44dDc2026aD17;
        result[6] = 0xd13289203889bD898d49e31a1500388441C03663;
    }

    function _setupStages()
        internal
    {
        //Presale stage
        stages[0].name = &#39;Presale stage&#39;;
        stages[0].numCoinsStart = totalCoinsAvailable;
        stages[0].coinsAvailable = TOKEN_AMOUNT_PRE_ICO;
        stages[0].bonus = BONUS_PRE_ICO;

        if (isDebug) {
            stages[0].startsAt = now;
            stages[0].endsAt = stages[0].startsAt + 30 seconds;
        } else {
            stages[0].startsAt = 1515610800; //10th of January 2018 at 19:00UTC
            stages[0].endsAt = 1518894000; //17th of February 2018 at 19:00UTC
        }

        //ICO Stage 1 pre-sale 1
        stages[1].name = &#39;ICO Stage 1 pre-sale 1&#39;;
        stages[1].coinsAvailable = TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE1;
        stages[1].bonus = BONUS_ICO_STAGE1_PRE_SALE1;

        if (isDebug) {
            stages[1].startsAt = stages[0].endsAt;
            stages[1].endsAt = stages[1].startsAt + 30 seconds;
        } else {
            stages[1].startsAt = 1519326000; //22th of February 2018 at 19:00UTC
            stages[1].endsAt = 1521745200; //22th of March 2018 at 19:00UTC
        }

        //ICO Stage 1 pre-sale 2
        stages[2].name = &#39;ICO Stage 1 pre-sale 2&#39;;
        stages[2].coinsAvailable = TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE2;
        stages[2].bonus = BONUS_ICO_STAGE1_PRE_SALE2;

        stages[2].startsAt = stages[1].startsAt;
        stages[2].endsAt = stages[1].endsAt;

        //ICO Stage 1 pre-sale 3
        stages[3].name = &#39;ICO Stage 1 pre-sale 3&#39;;
        stages[3].coinsAvailable = TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE3;
        stages[3].bonus = BONUS_ICO_STAGE1_PRE_SALE3;

        stages[3].startsAt = stages[1].startsAt;
        stages[3].endsAt = stages[1].endsAt;

        //ICO Stage 1 pre-sale 4
        stages[4].name = &#39;ICO Stage 1 pre-sale 4&#39;;
        stages[4].coinsAvailable = TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE4;
        stages[4].bonus = BONUS_ICO_STAGE1_PRE_SALE4;

        stages[4].startsAt = stages[1].startsAt;
        stages[4].endsAt = stages[1].endsAt;

        //ICO Stage 1 pre-sale 5
        stages[5].name = &#39;ICO Stage 1 pre-sale 5&#39;;
        stages[5].coinsAvailable = TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE5;
        stages[5].bonus = BONUS_ICO_STAGE1_PRE_SALE5;

        stages[5].startsAt = stages[1].startsAt;
        stages[5].endsAt = stages[1].endsAt;

        //ICO Stage 2
        stages[6].name = &#39;ICO Stage 2&#39;;
        stages[6].coinsAvailable = TOKEN_AMOUNT_ICO_STAGE2;
        stages[6].bonus = BONUS_ICO_STAGE2;

        if (isDebug) {
            stages[6].startsAt = stages[5].endsAt;
            stages[6].endsAt = stages[6].startsAt + 30 seconds;
        } else {
            stages[6].startsAt = 1524250800; //20th of April 2018 at 19:00UTC
            stages[6].endsAt = 1526842800; //20th of May 2018 at 19:00UTC
        }
    }

    function _proceedStage()
        internal
    {
        while (true) {
            if ( currentStage < stages.length
            && (now >= stages[currentStage].endsAt || getAvailableCoinsForCurrentStage() == 0) ) {
                currentStage++;
                uint totalTokensForSale = TOKEN_AMOUNT_PRE_ICO
                                    + TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE1
                                    + TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE2
                                    + TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE3
                                    + TOKEN_AMOUNT_ICO_STAGE1_PRE_SALE4
                                    + TOKEN_AMOUNT_ICO_STAGE2;

                if (currentStage >= stages.length) {
                    //Burning all unsold tokens and proportionally other for deligation
                    _totalSupply -= ( ( ( stages[(stages.length - 1)].coinsAvailable * DST_BOUNTY ) / 100 )
                                    + ( ( stages[(stages.length - 1)].coinsAvailable * DST_R_N_B_PROGRAM ) / 100 ) );

                    balances[BOUNTY_WALLET] = (((totalTokensForSale - stages[(stages.length - 1)].coinsAvailable) * DST_BOUNTY)/100);
                    balances[R_N_D_WALLET] = (((totalTokensForSale - stages[(stages.length - 1)].coinsAvailable) * DST_R_N_B_PROGRAM)/100);

                    totalCoinsAvailable = 0;
                    break; //ICO ended
                }

                stages[currentStage].numCoinsStart = totalCoinsAvailable;

                if ( currentStage > 0 ) {
                    //Move all left tokens to last stage
                    stages[(stages.length - 1)].coinsAvailable += stages[ (currentStage - 1 ) ].coinsAvailable;
                    StageUpdated(stages[currentStage - 1].name, stages[currentStage].name);
                }
            } else {
                break;
            }
        }
    }

    function getTotalCoinsAvailable()
        public
        view
        returns(uint)
    {
        return totalCoinsAvailable;
    }

    function getAvailableCoinsForCurrentStage()
        public
        view
        returns(uint)
    {
        TokenStage memory stage = stages[currentStage];

        return stage.coinsAvailable;
    }

    //------------- ERC20 methods -------------//
    function totalSupply()
        public
        constant
        returns (uint256)
    {
        return _totalSupply;
    }


    // What is the balance of a particular account?
    function balanceOf(address _owner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }


    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount)
        public
        onlyAfterICO
        isFreezedReserve(_to)
        returns (bool success)
    {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);

            return true;
        } else {
            return false;
        }
    }


    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        onlyAfterICO
        isFreezedReserve(_from)
        isFreezedReserve(_to)
        returns (bool success)
    {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount)
        public
        onlyAfterICO
        isFreezedReserve(_spender)
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
    //------------- ERC20 Methods END -------------//

    //Returns bonus for certain level of reference
    function calculateReferralBonus(uint amount, uint level)
        public
        pure
        returns (uint bonus)
    {
        bonus = 0;

        if ( level == 1 ) {
            bonus = ( ( amount * REFERRAL_BONUS_LEVEL1 ) / 100 );
        } else if (level == 2) {
            bonus = ( ( amount * REFERRAL_BONUS_LEVEL2 ) / 100 );
        } else if (level == 3) {
            bonus = ( ( amount * REFERRAL_BONUS_LEVEL3 ) / 100 );
        } else if (level == 4) {
            bonus = ( ( amount * REFERRAL_BONUS_LEVEL4 ) / 100 );
        } else if (level == 5) {
            bonus = ( ( amount * REFERRAL_BONUS_LEVEL5 ) / 100 );
        }
    }

    function calculateBonus(uint amountOfTokens)
        public
        view
        returns (uint)
    {
        return ( ( stages[currentStage].bonus * amountOfTokens ) / 100 );
    }

    event TokenPurchased(string stage, uint valueSubmitted, uint valueRefunded, uint tokensPurchased);

    function ()
        public
        payable
        notAdministrator
        onlyDuringICO
        meetTheCap
    {
        _proceedStage();
        require(currentStage < stages.length);
        require(stages[currentStage].startsAt <= now && now < stages[currentStage].endsAt);
        require(getAvailableCoinsForCurrentStage() > 0);

        uint requestedAmountOfTokens = ( ( msg.value * accuracy ) / price );
        uint amountToBuy = requestedAmountOfTokens;
        uint refund = 0;

        if ( amountToBuy > getAvailableCoinsForCurrentStage() ) {
            amountToBuy = getAvailableCoinsForCurrentStage();
            refund = ( ( (requestedAmountOfTokens - amountToBuy) / accuracy ) * price );

            // Returning ETH
            msg.sender.transfer( refund );
        }

        TokenPurchased(stages[currentStage].name, msg.value, refund, amountToBuy);
        stages[currentStage].coinsAvailable -= amountToBuy;
        stages[currentStage].balance += (msg.value - refund);

        uint amountDelivered = amountToBuy + calculateBonus(amountToBuy);

        balances[msg.sender] += amountDelivered;
        totalCoinsAvailable -= amountDelivered;

        if ( getAvailableCoinsForCurrentStage() == 0 ) {
            _proceedStage();
        }

        STORAGE_WALLET.transfer(this.balance);
    }

    //It doesn&#39;t really close the stage
    //It just needed to push transaction to update stage and update block.now
    function closeStage()
        public
        onlyAdministrator
    {
        _proceedStage();
    }
}

contract ERC20Contract is ERC20 {
    //Token symbol
    string public constant symbol = "UNIT";

    //Token name
    string public constant name = "Unilot token";

    //It can be reeeealy small
    uint8 public constant decimals = 18;

    // Balances for each account
    mapping(address => uint96) public balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint96)) allowed;

    function totalSupply()
        public
        constant
        returns (uint);


    // What is the balance of a particular account?
    function balanceOf(address _owner)
        public
        constant
        returns (uint balance)
    {
        return uint(balances[_owner]);
    }


    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint _amount)
        public
        returns (bool success)
    {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= uint96(_amount);
            balances[_to] += uint96(_amount);
            Transfer(msg.sender, _to, _amount);

            return true;
        } else {
            return false;
        }
    }


    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        returns (bool success)
    {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= uint96(_amount);
            allowed[_from][msg.sender] -= uint96(_amount);
            balances[_to] += uint96(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }


    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint _amount)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = uint96(_amount);
        Approval(msg.sender, _spender, _amount);
        return true;
    }


    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }
}

interface TokenStagesManager {
    function isDebug() public constant returns(bool);
    function setToken(address tokenAddress) public;
    function getPool() public constant returns (uint96);
    function getBonus() public constant returns (uint8);
    function isFreezeTimeout() public constant returns (bool);
    function isTimeout() public constant returns (bool);
    function isICO() public view returns(bool);
    function isCanList() public view returns (bool);
    function calculateBonus(uint96 amount) public view returns (uint88);
    function delegateFromPool(uint96 amount) public;
    function delegateFromBonus(uint88 amount) public;
    function delegateFromReferral(uint88 amount) public;

    function getBonusPool() public constant returns(uint88);
    function getReferralPool() public constant returns(uint88);
}

interface Whitelist {
    function add(address _wlAddress) public;
    function addBulk(address[] _wlAddresses) public;
    function remove(address _wlAddresses) public;
    function removeBulk(address[] _wlAddresses) public;
    function getAll() public constant returns(address[]);
    function isInList(address _checkAddress) public constant returns(bool);
}

contract Administrated {
    address public administrator;

    modifier onlyAdministrator() {
        require(administrator == tx.origin);
        _;
    }

    modifier notAdministrator() {
        require(administrator != tx.origin);
        _;
    }

    function setAdministrator(address _administrator)
        internal
    {
        administrator = _administrator;
    }
}

contract UNITv2 is ERC20Contract,Administrated {
    //Token symbol
    string public constant symbol = "UNIT";
    //Token name
    string public constant name = "Unilot token";
    //It can be reeeealy small
    uint8 public constant decimals = 18;

    //Total supply 500mln in the start
    uint96 public _totalSupply = uint96(500000000 * (10**18));

    UnilotToken public sourceToken;

    Whitelist public transferWhiteList;

    Whitelist public paymentGateways;

    TokenStagesManager public stagesManager;

    bool public unlocked = false;

    bool public burned = false;

    //tokenImport[tokenHolder][sourceToken] = true/false;
    mapping ( address => mapping ( address => bool ) ) public tokenImport;

    event TokensImported(address indexed tokenHolder, uint96 amount, address indexed source);
    event TokensDelegated(address indexed tokenHolder, uint96 amount, address indexed source);
    event Unlocked();
    event Burned(uint96 amount);

    modifier isLocked() {
        require(unlocked == false);
        _;
    }

    modifier isNotBurned() {
        require(burned == false);
        _;
    }

    modifier isTransferAllowed(address _from, address _to) {
        if ( sourceToken.RESERVE_WALLET() == _from ) {
            require( stagesManager.isFreezeTimeout() );
        }
        require(unlocked
                || ( stagesManager != address(0) && stagesManager.isCanList() )
                || ( transferWhiteList != address(0) && ( transferWhiteList.isInList(_from) || transferWhiteList.isInList(_to) ) )
        );
        _;
    }

    function UNITv2(address _sourceToken)
        public
    {
        setAdministrator(tx.origin);
        sourceToken = UnilotToken(_sourceToken);

        /*Transactions:
        0x99c28675adbd0d0cb7bd783ae197492078d4063f40c11139dd07c015a543ffcc
        0x86038d11ee8da46703309d2fb45d150f1dc4e2bba6d0a8fee158016111104ff1
        0x0340a8a2fb89513c0086a345973470b7bc33424e818ca6a32dcf9ad66bf9d75c
        */
        balances[0xd13289203889bD898d49e31a1500388441C03663] += 1400000000000000000 * 3;
        markAsImported(0xdBF98dF5DAd9077f457e1dcf85Aa9420BcA8B761, 0xd13289203889bD898d49e31a1500388441C03663);

        //Tx: 0xec9b7b4c0f1435282e2e98a66efbd7610de7eacce3b2448cd5f503d70a64a895
        balances[0xE33305B2EFbcB302DA513C38671D01646651a868] += 1400000000000000000;
        markAsImported(0xdBF98dF5DAd9077f457e1dcf85Aa9420BcA8B761, 0xE33305B2EFbcB302DA513C38671D01646651a868);

        //Assigning bounty
        balances[0x794EF9c680bDD0bEf48Bef46bA68471e449D67Fb] += uint96(
            ( uint(_totalSupply) * uint8( sourceToken.DST_BOUNTY() ) ) / 100
        );

        //Don&#39;t import bounty and R&B tokens
        markAsImported(0xdBF98dF5DAd9077f457e1dcf85Aa9420BcA8B761, 0x794EF9c680bDD0bEf48Bef46bA68471e449D67Fb);
        markAsImported(sourceToken, 0x794EF9c680bDD0bEf48Bef46bA68471e449D67Fb);

        markAsImported(0xdBF98dF5DAd9077f457e1dcf85Aa9420BcA8B761, 0x91D740D87A8AeED1fc3EA3C346843173c529D63e);
    }

    function setTransferWhitelist(address whiteListAddress)
        public
        onlyAdministrator
        isNotBurned
    {
        transferWhiteList = Whitelist(whiteListAddress);
    }

    function disableTransferWhitelist()
        public
        onlyAdministrator
        isNotBurned
    {
        transferWhiteList = Whitelist(address(0));
    }

    function setStagesManager(address stagesManagerContract)
        public
        onlyAdministrator
        isNotBurned
    {
        stagesManager = TokenStagesManager(stagesManagerContract);
    }

    function setPaymentGatewayList(address paymentGatewayListContract)
        public
        onlyAdministrator
        isNotBurned
    {
        paymentGateways = Whitelist(paymentGatewayListContract);
    }

    //START Import related methods
    function isImported(address _sourceToken, address _tokenHolder)
        internal
        constant
        returns (bool)
    {
        return tokenImport[_tokenHolder][_sourceToken];
    }

    function markAsImported(address _sourceToken, address _tokenHolder)
        internal
    {
        tokenImport[_tokenHolder][_sourceToken] = true;
    }

    function importFromSource(ERC20 _sourceToken, address _tokenHolder)
        internal
    {
        if ( !isImported(_sourceToken, _tokenHolder) ) {
            uint96 oldBalance = uint96(_sourceToken.balanceOf(_tokenHolder));
            balances[_tokenHolder] += oldBalance;
            markAsImported(_sourceToken, _tokenHolder);

            TokensImported(_tokenHolder, oldBalance, _sourceToken);
        }
    }

    //Imports from source token
    function importTokensFromSourceToken(address _tokenHolder)
        internal
    {
        importFromSource(ERC20(sourceToken), _tokenHolder);
    }

    function importFromExternal(ERC20 _sourceToken, address _tokenHolder)
        public
        onlyAdministrator
        isNotBurned
    {
        return importFromSource(_sourceToken, _tokenHolder);
    }

    //Imports from provided token
    function importTokensSourceBulk(ERC20 _sourceToken, address[] _tokenHolders)
        public
        onlyAdministrator
        isNotBurned
    {
        require(_tokenHolders.length <= 256);

        for (uint8 i = 0; i < _tokenHolders.length; i++) {
            importFromSource(_sourceToken, _tokenHolders[i]);
        }
    }
    //END Import related methods

    //START ERC20
    function totalSupply()
        public
        constant
        returns (uint)
    {
        return uint(_totalSupply);
    }

    function balanceOf(address _owner)
        public
        constant
        returns (uint balance)
    {
        balance = super.balanceOf(_owner);

        if (!isImported(sourceToken, _owner)) {
            balance += sourceToken.balanceOf(_owner);
        }
    }

    function transfer(address _to, uint _amount)
        public
        isTransferAllowed(msg.sender, _to)
        returns (bool success)
    {
        return super.transfer(_to, _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        isTransferAllowed(_from, _to)
        returns (bool success)
    {
        return super.transferFrom(_from, _to, _amount);
    }

    function approve(address _spender, uint _amount)
        public
        isTransferAllowed(msg.sender, _spender)
        returns (bool success)
    {
        return super.approve(_spender, _amount);
    }
    //END ERC20

    function delegateTokens(address tokenHolder, uint96 amount)
        public
        isNotBurned
    {
        require(paymentGateways.isInList(msg.sender));
        require(stagesManager.isICO());
        require(stagesManager.getPool() >= amount);

        uint88 bonus = stagesManager.calculateBonus(amount);
        stagesManager.delegateFromPool(amount);

        balances[tokenHolder] += amount + uint96(bonus);

        TokensDelegated(tokenHolder, amount, msg.sender);
    }

    function delegateBonusTokens(address tokenHolder, uint88 amount)
        public
        isNotBurned
    {
        require(paymentGateways.isInList(msg.sender) || tx.origin == administrator);
        require(stagesManager.getBonusPool() >= amount);

        stagesManager.delegateFromBonus(amount);

        balances[tokenHolder] += amount;

        TokensDelegated(tokenHolder, uint96(amount), msg.sender);
    }

    function delegateReferalTokens(address tokenHolder, uint88 amount)
        public
        isNotBurned
    {
        require(paymentGateways.isInList(msg.sender) || tx.origin == administrator);
        require(stagesManager.getReferralPool() >= amount);

        stagesManager.delegateFromReferral(amount);

        balances[tokenHolder] += amount;

        TokensDelegated(tokenHolder, amount, msg.sender);
    }

    function delegateReferralTokensBulk(address[] tokenHolders, uint88[] amounts)
        public
        isNotBurned
    {
        require(paymentGateways.isInList(msg.sender) || tx.origin == administrator);
        require(tokenHolders.length <= 256);
        require(tokenHolders.length == amounts.length);

        for ( uint8 i = 0; i < tokenHolders.length; i++ ) {
            delegateReferalTokens(tokenHolders[i], amounts[i]);
        }
    }

    function unlock()
        public
        isLocked
        onlyAdministrator
    {
        unlocked = true;
        Unlocked();
    }

    function burn()
        public
        onlyAdministrator
    {
        require(!stagesManager.isICO());

        uint96 burnAmount = stagesManager.getPool()
                        + stagesManager.getBonusPool()
                        + stagesManager.getReferralPool();

        _totalSupply -= burnAmount;
        burned = true;
        Burned(burnAmount);
    }
}

contract UNITSimplePaymentGateway is Administrated {
    UNITv2 public token;

    bool public locked = false;

    uint48 public constant PRICE = 79 szabo;

    address public storageAddress = 0x1b5DE6153c86F92a63A680896e9F088943c0Ead8;

    event Payment(address indexed payer, uint amount, uint refund, uint96 numTokens);

    function UNITSimplePaymentGateway(address _token)
        public
    {
        token = UNITv2(_token);
        setAdministrator(tx.origin);
    }

    function setToken(address _token)
        public
        onlyAdministrator
    {
        token = UNITv2(_token);
    }

    function ()
        public
        payable
    {
        require(locked == false);

        TokenStagesManager stagesManager = token.stagesManager();

        uint maxAmount = uint( ( uint(stagesManager.getPool()) * PRICE ) / (10**18) );
        uint refund = 0;

        if ( maxAmount < msg.value ) {
            refund = msg.value - maxAmount;
        }

        uint96 numTokens = uint96( ( ( msg.value - refund ) * (10**18) ) / PRICE );

        Payment(msg.sender, msg.value, refund, numTokens);

        token.delegateTokens(msg.sender, numTokens);

        msg.sender.transfer(refund);
        storageAddress.transfer(this.balance);
    }

    function lock()
        public
        onlyAdministrator
    {
        locked = true;
    }

    function unlock()
        public
        onlyAdministrator
    {
        locked = false;
    }
}