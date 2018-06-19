pragma solidity ^0.4.15;


contract BMICOAffiliateProgramm {
    struct itemReferrals {
        uint256 amount_investments;
        uint256 preico_holdersBonus;
    }
    mapping (address => itemReferrals) referralsInfo;
    uint256 public preico_holdersAmountInvestWithBonus = 0;

    mapping (string => address) partnersPromo;
    struct itemPartners {
        uint256 attracted_investments;
        string promo;
        uint16 personal_percent;
        uint256 preico_partnerBonus;
        bool create;
    }
    mapping (address => itemPartners) partnersInfo;

    uint16 public ref_percent = 100; //1 = 0.01%, 10000 = 100%

    struct itemHistory {
        uint256 datetime;
        address referral;
        uint256 amount_invest;
    }
    mapping(address => itemHistory[]) history;

    uint256 public amount_referral_invest;

    address public owner;
    address public contractPreICO;
    address public contractICO;

    function BMICOAffiliateProgramm(){
        owner = msg.sender;
        contractPreICO = address(0x0);
        contractICO = address(0x0);
    }

    modifier isOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function str_length(string x) constant internal returns (uint256) {
        bytes32 str;
        assembly {
        str := mload(add(x, 32))
        }
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(str) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        return charCount;
    }

    function changeOwner(address new_owner) isOwner {
        assert(new_owner!=address(0x0));
        assert(new_owner!=address(this));

        owner = new_owner;
    }

    function setReferralPercent(uint16 new_percent) isOwner {
        ref_percent = new_percent;
    }

    function setPartnerPercent(address partner, uint16 new_percent) isOwner {
        assert(partner!=address(0x0));
        assert(partner!=address(this));
        assert(partnersInfo[partner].create==true);
        partnersInfo[partner].personal_percent = new_percent;
    }

    function setContractPreICO(address new_address) isOwner {
        assert(contractPreICO==address(0x0));
        assert(new_address!=address(0x0));
        assert(new_address!=address(this));

        contractPreICO = new_address;
    }

    function setContractICO(address new_address) isOwner {
        assert(contractICO==address(0x0));
        assert(new_address!=address(0x0));
        assert(new_address!=address(this));

        contractICO = new_address;
    }

    function setPromoToPartner(string promo) {
        assert(partnersPromo[promo]==address(0x0));
        assert(partnersInfo[msg.sender].create==false);
        assert(str_length(promo)>0 && str_length(promo)<=6);

        partnersPromo[promo] = msg.sender;
        partnersInfo[msg.sender].attracted_investments = 0;
        partnersInfo[msg.sender].promo = promo;
        partnersInfo[msg.sender].create = true;
    }

    function checkPromo(string promo) constant returns(bool){
        return partnersPromo[promo]!=address(0x0);
    }

    function checkPartner(address partner_address) constant returns(bool isPartner, string promo){
        isPartner = partnersInfo[partner_address].create;
        promo = &#39;-1&#39;;
        if(isPartner){
            promo = partnersInfo[partner_address].promo;
        }
    }

    function calc_partnerPercent(address partner) constant internal returns(uint16 percent){
        percent = 0;
        if(partnersInfo[partner].personal_percent > 0){
            percent = partnersInfo[partner].personal_percent;
        }
        else{
            uint256 attracted_investments = partnersInfo[partner].attracted_investments;
            if(attracted_investments > 0){
                if(attracted_investments < 3 ether){
                    percent = 300; //1 = 0.01%, 10000 = 100%
                }
                else if(attracted_investments >= 3 ether && attracted_investments < 10 ether){
                    percent = 500;
                }
                else if(attracted_investments >= 10 ether && attracted_investments < 100 ether){
                    percent = 700;
                }
                else if(attracted_investments >= 100 ether){
                    percent = 1000;
                }
            }
        }
    }

    function partnerInfo(address partner_address) isOwner constant returns(string promo, uint256 attracted_investments, uint256[] h_datetime, uint256[] h_invest, address[] h_referrals){
        if(partner_address != address(0x0) && partnersInfo[partner_address].create){
            promo = partnersInfo[partner_address].promo;
            attracted_investments = partnersInfo[partner_address].attracted_investments;

            h_datetime = new uint256[](history[partner_address].length);
            h_invest = new uint256[](history[partner_address].length);
            h_referrals = new address[](history[partner_address].length);

            for(uint256 i=0; i<history[partner_address].length; i++){
                h_datetime[i] = history[partner_address][i].datetime;
                h_invest[i] = history[partner_address][i].amount_invest;
                h_referrals[i] = history[partner_address][i].referral;
            }
        }
        else{
            promo = &#39;-1&#39;;
            attracted_investments = 0;
            h_datetime = new uint256[](0);
            h_invest = new uint256[](0);
            h_referrals = new address[](0);
        }
    }

    function refferalPreICOBonus(address referral) constant external returns (uint256 bonus){
        bonus = referralsInfo[referral].preico_holdersBonus;
    }

    function partnerPreICOBonus(address partner) constant external returns (uint256 bonus){
        bonus = partnersInfo[partner].preico_partnerBonus;
    }

    function referralAmountInvest(address referral) constant external returns (uint256 amount){
        amount = referralsInfo[referral].amount_investments;
    }

    function add_referral(address referral, string promo, uint256 amount) external returns(address partner, uint256 p_partner, uint256 p_referral){
        p_partner = 0;
        p_referral = 0;
        partner = address(0x0);
        if(partnersPromo[promo] != address(0x0) && partnersPromo[promo] != referral){
            partner = partnersPromo[promo];
            if(msg.sender == contractPreICO){
                referralsInfo[referral].amount_investments += amount;
                amount_referral_invest += amount;
                partnersInfo[partner].attracted_investments += amount;
                history[partner].push(itemHistory(now, referral, amount));

                uint256 partner_bonus = (amount*uint256(calc_partnerPercent(partner)))/10000;
                if(partner_bonus > 0){
                    partnersInfo[partner].preico_partnerBonus += partner_bonus;
                }
                uint256 referral_bonus = (amount*uint256(ref_percent))/10000;
                if(referral_bonus > 0){
                    referralsInfo[referral].preico_holdersBonus += referral_bonus;
                    preico_holdersAmountInvestWithBonus += amount;
                }
            }
            if (msg.sender == contractICO){
                referralsInfo[referral].amount_investments += amount;
                amount_referral_invest += amount;
                partnersInfo[partner].attracted_investments += amount;
                history[partner].push(itemHistory(now, referral, amount));
                p_partner = (amount*uint256(calc_partnerPercent(partner)))/10000;
                p_referral = (amount*uint256(ref_percent))/10000;
            }
        }
    }
}