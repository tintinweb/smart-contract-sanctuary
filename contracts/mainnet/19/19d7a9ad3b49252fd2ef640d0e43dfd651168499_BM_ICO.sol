pragma solidity ^0.4.16;

contract BMToken
{
    function totalSupply() constant external returns (uint256);
    function mintTokens(address holder, uint256 amount) external;
}

contract BMmkPreICO
{
    function getDataHolders(address holder) external constant returns(uint256);
}

contract BMPreICO
{
    function getDataHolders(address holder) external constant returns(uint256);
}

contract BMPreICOAffiliateProgramm
{
    function refferalPreICOBonus(address referral) constant external returns (uint256 bonus);
    function partnerPreICOBonus(address partner) constant external returns (uint256 bonus);
}

contract BMICOAffiliateProgramm
{
    function add_referral(address referral, string promo, uint256 amount) external returns(address, uint256, uint256);
}

contract BM_ICO
{
    BMToken    contractTokens;
    BMmkPreICO contractMKPreICO;
    BMPreICO   contractPreICO;
    BMPreICOAffiliateProgramm contractAffiliatePreICO;
    BMICOAffiliateProgramm contractAffiliateICO;

    address public owner;
    address public exchangesOwner;

    mapping (uint8 => uint256)                       public holdersBonus;
    mapping (address => bool)                        public claimedMK;
    mapping (address => bool)                        public claimedPreICO;

    mapping (uint8 => uint256)                       public partnerBonus;
    mapping (address => bool)                        public claimedPartnerPreICO;

    uint256 public startDate      = 1505001600; //10.09.2017 00:00 GMT
    uint256 public endDate        = 1507593600; //10.10.2017 00:00 GMT

    bool isOwnerEmit = false;

    uint256 public icoTokenSupply = 7*(10**26);

    mapping (uint8 => uint256) public priceRound;

    mapping(address => bool) exchanges;

    function BM_ICO()
    {
        owner          = msg.sender;
        exchangesOwner = address(0xCa92b75B7Ada1B460Eb5C012F1ebAd72c27B19D9);

        contractTokens          = BMToken(0xf028adee51533b1b47beaa890feb54a457f51e89);
        contractAffiliatePreICO = BMPreICOAffiliateProgramm(0x6203188c0dd1a4607614dbc8af409e91ed46def0);
        contractAffiliateICO    = BMICOAffiliateProgramm(0xbe44459058383729be8247802d4314ea76ca9e5a);
        contractMKPreICO        = BMmkPreICO(0xe9958afac6a3e16d32d3cb62a82f84d3c43c8012);
        contractPreICO          = BMPreICO(0x7600431745bd5bb27315f8376971c81cc8026a78);

        priceRound[0] = 0.000064 ether; //MK
        priceRound[1] = 0.000071 ether; //PreICO
        priceRound[2] = 0.000107 ether; //1 round 10.09.2017-20.09.2017
        priceRound[3] = 0.000114 ether; //2 round 20.09.2017-25.09.2017
        priceRound[4] = 0.000121 ether; //3 round 25.09.2017-30.09.2017
        priceRound[5] = 0.000143 ether; //4 round 30.09.2017-10.10.2017
    }

    modifier isOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwner(address new_owner) isOwner {
        assert(new_owner!=address(0x0));
        assert(new_owner!=address(this));
        owner = new_owner;
    }

    function addExchange(address new_exchange) isOwner
    {
        assert(new_exchange!=address(0x0));
        assert(new_exchange!=address(this));
        assert(exchanges[new_exchange]==false);
        exchanges[new_exchange] = true;
    }

    function cast(uint256 x) constant internal returns (uint128 z)
    {
        assert((z = uint128(x)) == x);
    }

    function etherToTokens(uint256 etherAmount, uint256 tokenPrice) constant returns(uint256)
    {
        return uint256(cast((etherAmount * (10**18) + cast(tokenPrice) / 2) / cast(tokenPrice)));
    }

    function tokensToEther(uint256 tokenAmount, uint256 tokenPrice) constant returns(uint256)
    {
        return uint256(cast((tokenPrice * cast(tokenAmount) + (10**18) / 2) / (10**18)));
    }

    function periodNow() constant returns (uint8 period) {
        if(now >= 1505001600 && now < 1505865600){
            period = 2;
        }
        else if(now >= 1505865600 && now < 1506297600){
            period = 3;
        }
        else if(now >= 1506297600 && now < 1506729600){
            period = 4;
        }
        else if(now >= 1506729600 && now < 1507593600){
            period = 5;
        }
        else {
            period = 6;
        }
    }

    function claim_PreICOTokens(address holder)
    {
        uint256 reward = 0;

        if(claimedMK[holder]==false){
            reward = etherToTokens(contractMKPreICO.getDataHolders(holder), priceRound[0]);
            icoTokenSupply -= reward;
            claimedMK[holder] = true;
        }

        if(claimedPreICO[holder]==false){
            uint256 preico_reward = etherToTokens(contractPreICO.getDataHolders(holder), priceRound[1]);
            reward += preico_reward;
            icoTokenSupply -= preico_reward;
            reward += etherToTokens(contractAffiliatePreICO.refferalPreICOBonus(holder), priceRound[1]);
            claimedPreICO[holder] = true;
        }

        assert(reward>0);

        if(exchanges[holder] == true)
        {
            contractTokens.mintTokens(exchangesOwner, reward);
        }
        else
        {
            contractTokens.mintTokens(holder, reward);
        }
    }

    function claim_partnerPreICOTokens(address partner)
    {
        assert(claimedPartnerPreICO[partner]==false);
        uint256 reward = etherToTokens(contractAffiliatePreICO.partnerPreICOBonus(partner), priceRound[1]);

        assert(reward>0);

        contractTokens.mintTokens(partner, reward);
        claimedPartnerPreICO[partner] = true;
    }

    function buy(string promo) payable
    {
        uint8 period_number = periodNow();
        assert(exchanges[msg.sender]==false);
        assert(period_number >= 2 && period_number <= 5);
        assert(icoTokenSupply > 0);
        assert(msg.value >= 0.1 ether);

        uint256 amount_invest = msg.value;
        uint256 reward = etherToTokens(amount_invest, priceRound[period_number]);

        if(reward > icoTokenSupply)
        {
            reward = icoTokenSupply;
            amount_invest = tokensToEther(reward, priceRound[period_number]);
            assert(msg.value > amount_invest);
            msg.sender.transfer(msg.value - amount_invest);
        }

        icoTokenSupply -= reward;

        if (bytes(promo).length > 0)
		{
            var (partner_address, partner_bonus, referral_bonus) = contractAffiliateICO.add_referral(msg.sender, promo, amount_invest);

            if(partner_bonus > 0 && partner_address != address(0x0))
            {
                uint256 p_bonus = etherToTokens(partner_bonus, priceRound[period_number]);
                partnerBonus[period_number] += p_bonus;
                contractTokens.mintTokens(partner_address, p_bonus);
            }

            if(referral_bonus > 0)
            {
                uint256 bonus = etherToTokens(referral_bonus, priceRound[period_number]);
                holdersBonus[period_number] += bonus;
                reward += bonus;
            }
        }
        contractTokens.mintTokens(msg.sender, reward);
    }

    function () payable
    {
        buy(&#39;&#39;);
    }

    function collect() isOwner
    {
        assert(this.balance > 0);
        msg.sender.transfer(this.balance);
    }

    function ownerEmit() isOwner
    {
        assert(now > endDate);
        assert(isOwnerEmit==false);

        uint256 users_emit = ((7*(10**26))-icoTokenSupply); // 700 000 000
        // ico amount   - 70% supply
        // funds amount - 30% supply
        // funds amount = ico amount * 3 / 7
        uint256 dev_emit = users_emit * 30 / 70;

        // contractTokens.totalSupply() = users_emit + partner_rewards + users_bouns
        // uint256 partner_and_bouns_rewards = contractTokens.totalSupply() - users_emit;
        // dev_emit = dev_emit - partner_and_bouns_rewards;
        dev_emit = dev_emit + users_emit - contractTokens.totalSupply();

        isOwnerEmit = true;
        contractTokens.mintTokens(msg.sender, dev_emit);
    }
}