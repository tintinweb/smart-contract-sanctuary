pragma solidity ^0.4.15;


contract BMICOAffiliateProgramm {
    mapping (string => address) partnersPromo;
    mapping (address => uint256) referrals;

    struct itemPartners {
        uint256 balance;
        string promo;
        bool create;
    }
    mapping (address => itemPartners) partnersInfo;

    uint256 public ref_percent = 100; //1 = 0.01%, 10000 = 100%


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

    function setReferralPercent(uint256 new_percent) isOwner {
        ref_percent = new_percent;
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

        assert(str_length(promo)>0 && str_length(promo)<=6);

        partnersPromo[promo] = msg.sender;
        partnersInfo[msg.sender].balance = 0;
        partnersInfo[msg.sender].promo = promo;
        partnersInfo[msg.sender].create = true;
    }

    function checkPromo(string promo) constant returns(bool){
        return partnersPromo[promo]!=address(0x0);
    }

    function calc_partnerPercent(uint256 ref_amount_invest) constant internal returns(uint16 percent){
        percent = 0;
        if(ref_amount_invest > 0){
            if(ref_amount_invest < 2 ether){
                percent = 100; //1 = 0.01%, 10000 = 100%
            }
            else if(ref_amount_invest >= 2 ether && ref_amount_invest < 3 ether){
                percent = 200;
            }
            else if(ref_amount_invest >= 3 ether && ref_amount_invest < 4 ether){
                percent = 300;
            }
            else if(ref_amount_invest >= 4 ether && ref_amount_invest < 5 ether){
                percent = 400;
            }
            else if(ref_amount_invest >= 5 ether){
                percent = 500;
            }
        }
    }

    function partnerInfo(address partner_address) constant internal returns(string promo, uint256 balance, uint256[] h_datetime, uint256[] h_invest, address[] h_referrals){
        if(partner_address != address(0x0) && partnersInfo[partner_address].create){
            promo = partnersInfo[partner_address].promo;
            balance = partnersInfo[partner_address].balance;

            h_datetime = new uint256[](history[partner_address].length);
            h_invest = new uint256[](history[partner_address].length);
            h_referrals = new address[](history[partner_address].length);

            for(var i=0; i<history[partner_address].length; i++){
                h_datetime[i] = history[partner_address][i].datetime;
                h_invest[i] = history[partner_address][i].amount_invest;
                h_referrals[i] = history[partner_address][i].referral;
            }
        }
        else{
            promo = &#39;-1&#39;;
            balance = 0;
            h_datetime = new uint256[](0);
            h_invest = new uint256[](0);
            h_referrals = new address[](0);
        }
    }

    function partnerInfo_for_Partner(bytes32 hash, uint8 v, bytes32 r, bytes32 s) constant returns(string, uint256, uint256[], uint256[], address[]){
        address partner_address = ecrecover(hash, v, r, s);
        return partnerInfo(partner_address);
    }

    function partnerInfo_for_Owner (address partner) isOwner constant returns(string, uint256, uint256[], uint256[], address[]){
        return partnerInfo(partner);
    }

    function add_referral(address referral, string promo, uint256 amount) external returns(address partner, uint256 p_partner, uint256 p_referral){
        p_partner = 0;
        p_referral = 0;
        partner = address(0x0);
        if (msg.sender == contractPreICO || msg.sender == contractICO){
            if(partnersPromo[promo] != address(0x0) && partnersPromo[promo] != referral){
                partner = partnersPromo[promo];
                referrals[referral] += amount;
                amount_referral_invest += amount;
                partnersInfo[partnersPromo[promo]].balance += amount;
                history[partnersPromo[promo]].push(itemHistory(now, referral, amount));
                p_partner = (amount*uint256(calc_partnerPercent(amount)))/10000;
                p_referral = (amount*ref_percent)/10000;
            }
        }
    }


    /*delete function before release contract*/
    function kill() isOwner {
        selfdestruct(msg.sender);
    }
}