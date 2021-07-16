//SourceUnit: TronCosmosBackup.sol

/*

████████ ██████   ██████  ███    ██      ██████  ██████  ███████ ███    ███  ██████  ███████     ██████   █████   ██████ ██   ██ ██    ██ ██████  
   ██    ██   ██ ██    ██ ████   ██     ██      ██    ██ ██      ████  ████ ██    ██ ██          ██   ██ ██   ██ ██      ██  ██  ██    ██ ██   ██ 
   ██    ██████  ██    ██ ██ ██  ██     ██      ██    ██ ███████ ██ ████ ██ ██    ██ ███████     ██████  ███████ ██      █████   ██    ██ ██████  
   ██    ██   ██ ██    ██ ██  ██ ██     ██      ██    ██      ██ ██  ██  ██ ██    ██      ██     ██   ██ ██   ██ ██      ██  ██  ██    ██ ██      
   ██    ██   ██  ██████  ██   ████      ██████  ██████  ███████ ██      ██  ██████  ███████     ██████  ██   ██  ██████ ██   ██  ██████  ██      
                                                                                                                                                  
                                                                                                                                                  
   www.troncosmos.com
   Note: This is backup Contract of TronCosmos Main Contract (TEGdybk8k3RMXiUaJ85dMBWo4X85L276cr) -----
*/
pragma solidity ^0.4.25;

contract TronCosmosBackup {
    using SafeMath for uint256;
    address owner;

    //-- Public Declaration ----------------

    uint256 public totalAffiliates;
    uint256 public totalDonatedInContract;

    struct Affiliate {
        uint256 af_regiTime;
        uint256 af_tot_donation;
        uint256 af_last_donation;
    }

    mapping(address => Affiliate) public affiliates;

    event onLoad(address indexed donor, uint256 donation);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;

        affiliates[owner].af_regiTime = now;
    }

    //---------------------------------[ BackUp load ]--------------------------------------------------------------------------------------
    function backup_load() public payable returns (bool) {
        require(msg.value > 0, "Invalid Amount");

        uint256 donationAmount = msg.value;

        Affiliate storage affiliate = affiliates[msg.sender];

        if (affiliate.af_regiTime == 0) {
            affiliate.af_regiTime = now;

            totalAffiliates++;
        }

        totalDonatedInContract = totalDonatedInContract.add(donationAmount);

        affiliate.af_tot_donation = affiliate.af_tot_donation.add(
            donationAmount
        );

        affiliate.af_last_donation = donationAmount;

        emit onLoad(msg.sender, donationAmount);
        return true;
    }

    //-------------------------------[ Transfer Withdrawal ]----------------------------------------------

    function withdraw(uint256 amount) public onlyOwner returns (bool) {
        require(amount <= address(this).balance);
        owner.transfer(amount);
        return true;
    }

    //-------------------------------[ Info ]----------------------------------------------
    function get_contract_balance() public view returns (uint256 cbalance) {
        return address(this).balance;
    }
} //---contract ends

//-----------------------------------------[ Library ]--------------------------------------------------------------------
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}