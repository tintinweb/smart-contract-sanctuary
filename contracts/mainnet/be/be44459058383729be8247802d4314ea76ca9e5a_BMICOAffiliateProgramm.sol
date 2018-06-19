pragma solidity ^0.4.16;


contract BMICOAffiliateProgramm {
    mapping (address => uint256) referralsInfo;

    mapping (bytes32 => address) partnersPromo;
    struct itemPartners {
        uint256 attracted_investments;
        bytes32 promo;
        uint16 personal_percent;
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
    address public contractICO;

    function BMICOAffiliateProgramm(){
        owner = msg.sender;
        contractICO = address(0x0);
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

    function setPartnerFromPreICOAffiliate(address[] partners, bytes32[] promo_codes, uint256[] attracted_invests) isOwner {
        assert(partners.length==promo_codes.length && partners.length==attracted_invests.length);

        for(uint256 i=0; i<partners.length; i++){
            if(!partnersInfo[partners[i]].create){
                partnersPromo[promo_codes[i]] = partners[i];
                partnersInfo[partners[i]].attracted_investments = attracted_invests[i];
                partnersInfo[partners[i]].promo = promo_codes[i];
                partnersInfo[partners[i]].create = true;
            }
        }
    }

    function setReferralPercent(uint16 new_percent) isOwner {
        ref_percent = new_percent;
    }

    function setPartnerPercent(address partner, uint16 new_percent) isOwner {
        assert(partner!=address(0x0));
        assert(partner!=address(this));
        assert(partnersInfo[partner].create==true);
        assert(new_percent<=1500);
        partnersInfo[partner].personal_percent = new_percent;
    }

    function setContractICO(address new_address) isOwner {
        assert(contractICO==address(0x0));
        assert(new_address!=address(0x0));
        assert(new_address!=address(this));

        contractICO = new_address;
    }

    function stringTobytes32(string str) constant returns (bytes32){
        bytes32 result;
        assembly {
            result := mload(add(str, 6))
        }
        return result;
    }

    function str_length(string x) constant internal returns (uint256) {
        return bytes(x).length;
    }

    function setPromoToPartner(string code) {
        bytes32 promo = stringTobytes32(code);
        assert(partnersPromo[promo]==address(0x0));
        assert(partnersInfo[msg.sender].create==false);
        assert(str_length(code)>0 && str_length(code)<=6);

        partnersPromo[promo] = msg.sender;
        partnersInfo[msg.sender].attracted_investments = 0;
        partnersInfo[msg.sender].promo = promo;
        partnersInfo[msg.sender].create = true;
    }

    function checkPromo(string promo) constant returns(bool){
        bytes32 result = stringTobytes32(promo);
        return partnersPromo[result]!=address(0x0);
    }

    function checkPartner(address partner_address) constant returns(bool isPartner, bytes32 promo){
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

    function partnerInfo(address partner_address) isOwner constant returns(bytes32 promo, uint256 attracted_investments, uint256[] h_datetime, uint256[] h_invest, address[] h_referrals){
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

    function referralAmountInvest(address referral) constant external returns (uint256 amount){
        amount = referralsInfo[referral];
    }

    function add_referral(address referral, string promo, uint256 amount) external returns(address partner, uint256 p_partner, uint256 p_referral){
        bytes32 promo_code = stringTobytes32(promo);

        p_partner = 0;
        p_referral = 0;
        partner = address(0x0);
        if(partnersPromo[promo_code] != address(0x0) && partnersPromo[promo_code] != referral){
            partner = partnersPromo[promo_code];
            if (msg.sender == contractICO){
                referralsInfo[referral] += amount;
                amount_referral_invest += amount;
                partnersInfo[partner].attracted_investments += amount;
                history[partner].push(itemHistory(now, referral, amount));
                p_partner = (amount*uint256(calc_partnerPercent(partner)))/10000;
                p_referral = (amount*uint256(ref_percent))/10000;
            }
        }
    }
}