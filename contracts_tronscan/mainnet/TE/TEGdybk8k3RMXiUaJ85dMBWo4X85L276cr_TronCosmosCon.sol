//SourceUnit: TronCosmosNew.sol

/*
████████ ██████   ██████  ███    ██      ██████  ██████  ███████ ███    ███  ██████  ███████ 
   ██    ██   ██ ██    ██ ████   ██     ██      ██    ██ ██      ████  ████ ██    ██ ██      
   ██    ██████  ██    ██ ██ ██  ██     ██      ██    ██ ███████ ██ ████ ██ ██    ██ ███████ 
   ██    ██   ██ ██    ██ ██  ██ ██     ██      ██    ██      ██ ██  ██  ██ ██    ██      ██ 
   ██    ██   ██  ██████  ██   ████      ██████  ██████  ███████ ██      ██  ██████  ███████ 

   www.troncosmos.com
*/
pragma solidity ^0.4.25;

contract TronCosmosCon {
    using SafeMath for uint256;
    address owner;

    //-- Public Declaration ----------------
    uint256 private maxRef_A_earning = 10000000000000;
    uint256 private maxRef_B_earning = 5000000000000;
    uint256 public totalAffiliates;
    uint256 public totalDonatedInContract;
    uint256 public totalWithdrawal;
    uint256 private dailySeconds = 86400;

    uint256 private L1_rate = 1500;
    uint256 private L2_rate = 250;
    uint256 private L3_rate = 250;
    uint256 private L4_rate = 250;
    uint256 private L5_rate = 250;
    uint256 private L6_rate = 250;
    uint256 private L7_rate = 250;
    uint256 private L8_rate = 250;
    uint256 private L9_rate = 250;
    uint256 private L10_rate = 250;
    uint256 private L11_rate = 250;

    struct Affiliate {
        uint256 af_regiTime;
        uint256 af_donationTime;
        uint256 af_tot_donation;
        uint256 af_last_donation;
        uint256 af_tot_direct_donation;
        uint256 af_dwnline_count;
        uint256 af_dwnline_donation_total;
        uint256 af_re_donation_wallet;
        address af_sponsor;
        uint256 af_directs;
    }

    struct Affiliate_self {
        uint256 af_self_earning;
        uint256 af_daily_bonus_rate;
        uint256 af_daily_bonus_wallet;
        uint256 af_last_bonus_cal_time;
        uint256 af_total_self_withdrawal;
    }

    struct Affiliate_ref {
        uint256 af_tot_ref_bonus;
        uint256 af_ref_earning_A;
        uint256 af_ref_earning_B;
        uint256 af_daily_ref_bonus_wallet;
        uint256 af_ref_last_bonus_cal_time;
        uint256 af_total_ref_withdrawal;
    }

    struct Donation_packages {
        uint256 package_1H;
        uint256 package_1K;
        uint256 package_10K;
        uint256 package_25K;
        uint256 package_1H_time;
        uint256 package_1K_time;
        uint256 package_10K_time;
        uint256 package_25K_time;
    }

    struct Reserve_package_bonus {
        uint256 reserve_1K;
        uint256 reserve_10K;
        uint256 reserve_25K;
    }

    struct Affiliate_levels_count {
        uint256 L1_count;
        uint256 L2_count;
        uint256 L3_count;
        uint256 L4_count;
        uint256 L5_count;
        uint256 L6_count;
        uint256 L7_count;
        uint256 L8_count;
        uint256 L9_count;
        uint256 L10_count;
        uint256 L11_count;
    }

    struct Affiliate_levels_detail {
        uint256 L1_donation;
        uint256 L2_donation;
        uint256 L3_donation;
        uint256 L4_donation;
        uint256 L5_donation;
        uint256 L6_donation;
        uint256 L7_donation;
        uint256 L8_donation;
        uint256 L9_donation;
        uint256 L10_donation;
        uint256 L11_donation;
    }

    mapping(address => Affiliate) public affiliates;
    mapping(address => Affiliate_self) public affiliates_self;
    mapping(address => Affiliate_ref) public affiliates_ref;
    mapping(address => Donation_packages) public donation_packages;
    mapping(address => Reserve_package_bonus) public reserve_package_bonus;
    mapping(address => Affiliate_levels_count) public affiliate_levels_count;
    mapping(address => Affiliate_levels_detail) public affiliate_levels_details;

    event onDonate(address indexed donor, uint256 donation);
    event onWithdrawal(address indexed donor, uint256 bonus);
    event onLoad(address indexed donor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;

        affiliates[owner].af_regiTime = now;
        affiliates[owner].af_sponsor = owner;
    }

    //---------------------------------[ Donate ]--------------------------------------------------------------------------------------
    function fn_donate(address _sponsorAddr) public payable returns (bool) {
        require(
            (msg.value == 100000000 ||
                msg.value == 1000000000 ||
                msg.value == 10000000000 ||
                msg.value == 25000000000),
            "Invalid Amount"
        );

        uint256 donationAmount = msg.value;

        require(_sponsorAddr != msg.sender, "Sponsor & donor cannot be same");

        Affiliate storage sponsor = affiliates[_sponsorAddr];
        require(sponsor.af_regiTime > 0, "Sponsor Not Found");

        fn_check_package_validity(donationAmount);

        Affiliate storage affiliate = affiliates[msg.sender];

        if (affiliate.af_regiTime == 0) {
            //for 1H only
            affiliate.af_regiTime = now;
            affiliate.af_sponsor = _sponsorAddr;

            if (sponsor.af_directs == 0) {
                affiliates_ref[_sponsorAddr].af_ref_last_bonus_cal_time = now;
            }

            sponsor.af_directs = sponsor.af_directs.add(1);
            totalAffiliates++;
            donation_packages[msg.sender].package_1H = donationAmount;
            donation_packages[msg.sender].package_1H_time = now;

            affiliates_self[msg.sender].af_last_bonus_cal_time = now;
        } else {
            _sponsorAddr = affiliate.af_sponsor; //original sponsor

            // for 1k,10k,25k
            fn_calculate_self_bonus(msg.sender);

            fn_update_self_donation_package(donationAmount);

            fn_refund_reserved_bonus(donationAmount);
        }

        fn_update_af_daily_bonus_rate(donationAmount);

        totalDonatedInContract = totalDonatedInContract.add(donationAmount);

        affiliate.af_donationTime = now;

        affiliate.af_tot_donation = affiliate.af_tot_donation.add(
            donationAmount
        );

        affiliate.af_last_donation = donationAmount;

        sponsor.af_tot_direct_donation = sponsor.af_tot_direct_donation.add(
            donationAmount
        );

        fn_upline_update_donations(donationAmount, _sponsorAddr);

        emit onDonate(msg.sender, donationAmount);
        return true;
    }

    //---------------------------------[ Re-Donate ]--------------------------------------------------------------------------------------
    function fn_internal_donate(uint256 _value) public returns (bool) {
        require(
            (_value == 1000000000 ||
                _value == 10000000000 ||
                _value == 25000000000),
            "Invalid Amount"
        );

        uint256 donationAmount = _value;
        address _sponsorAddr = affiliates[msg.sender].af_sponsor;

        Affiliate storage affiliate = affiliates[msg.sender];
        Affiliate storage sponsor = affiliates[_sponsorAddr];
        require(sponsor.af_regiTime > 0, "Sponsor not found");
        require(affiliate.af_regiTime > 0, "Donor Not Found");

        fn_check_package_validity(donationAmount);

        require(
            affiliate.af_re_donation_wallet >= _value,
            "Insufficient Balance"
        );

        affiliate.af_re_donation_wallet = affiliate.af_re_donation_wallet.sub(
            _value
        );

        // for 1k,10k,25k
        fn_calculate_self_bonus(msg.sender);

        fn_update_self_donation_package(donationAmount);

        fn_refund_reserved_bonus(donationAmount);

        fn_update_af_daily_bonus_rate(donationAmount);

        totalDonatedInContract = totalDonatedInContract.add(donationAmount);

        affiliate.af_donationTime = now;

        affiliate.af_tot_donation = affiliate.af_tot_donation.add(
            donationAmount
        );

        affiliate.af_last_donation = donationAmount;

        sponsor.af_tot_direct_donation = sponsor.af_tot_direct_donation.add(
            donationAmount
        );

        fn_upline_update_donations(donationAmount, _sponsorAddr);

        emit onDonate(msg.sender, donationAmount);
        return true;
    }

    //--------------------------------
    function fn_update_self_donation_package(uint256 donationAmount) private {
        if (donationAmount == 1000000000) {
            //1K
            donation_packages[msg.sender].package_1K = donationAmount;
            donation_packages[msg.sender].package_1K_time = now;
        }

        if (donationAmount == 10000000000) {
            //10K
            donation_packages[msg.sender].package_10K = donationAmount;
            donation_packages[msg.sender].package_10K_time = now;
        }

        if (donationAmount == 25000000000) {
            //25K
            donation_packages[msg.sender].package_25K = donationAmount;
            donation_packages[msg.sender].package_25K_time = now;
        }
    }

    //-------------------------------
    function fn_refund_reserved_bonus(uint256 donationAmount) private {
        //First time check & calculate
        fn_calculate_ref_bonus(msg.sender);

        if (donationAmount == 1000000000) {
            //1K
            affiliates_ref[msg.sender].af_tot_ref_bonus = affiliates_ref[msg
                .sender]
                .af_tot_ref_bonus
                .add(reserve_package_bonus[msg.sender].reserve_1K);
            reserve_package_bonus[msg.sender].reserve_1K = 0;
        }

        if (donationAmount == 10000000000) {
            //10K
            affiliates_ref[msg.sender].af_tot_ref_bonus = affiliates_ref[msg
                .sender]
                .af_tot_ref_bonus
                .add(reserve_package_bonus[msg.sender].reserve_10K);
            reserve_package_bonus[msg.sender].reserve_10K = 0;
        }

        if (donationAmount == 25000000000) {
            //25K
            affiliates_ref[msg.sender].af_tot_ref_bonus = affiliates_ref[msg
                .sender]
                .af_tot_ref_bonus
                .add(reserve_package_bonus[msg.sender].reserve_25K);
            reserve_package_bonus[msg.sender].reserve_25K = 0;
        }

        //second time check & calculate
        fn_calculate_ref_bonus(msg.sender);
    }

    //---------------------------------
    function fn_update_af_daily_bonus_rate(uint256 donationAmount) private {
        if (donationAmount == 25000000000) {
            //25K
            affiliates_self[msg.sender].af_daily_bonus_rate = 0;

            //transfer retopup wallet
            if (affiliates[msg.sender].af_re_donation_wallet > 0) {
                affiliates_ref[msg.sender]
                    .af_daily_ref_bonus_wallet = affiliates_ref[msg.sender]
                    .af_daily_ref_bonus_wallet
                    .add(affiliates[msg.sender].af_re_donation_wallet);
                affiliates[msg.sender].af_re_donation_wallet = 0;
            }
        } else {
            if (donationAmount == 100000000) {
                //1H
                affiliates_self[msg.sender].af_daily_bonus_rate = 25;
            }
        }
    }

    //---------------------------------[Package Validity]-------------------------------------------------
    function fn_check_package_validity(uint256 donationAmount) private view {
        if (donationAmount == 100000000) {
            // 1H
            require(
                donation_packages[msg.sender].package_1H == 0,
                "100: Invalid Package Amount"
            );
        }

        if (donationAmount == 1000000000) {
            //1K
            require(
                donation_packages[msg.sender].package_1H == 100000000,
                "1000: Invalid Package Amount"
            );
            require(
                donation_packages[msg.sender].package_1K == 0,
                "1000: Invalid Package Amount"
            );
        }

        if (donationAmount == 10000000000) {
            //10K
            require(
                donation_packages[msg.sender].package_1K == 1000000000,
                "10000: Invalid Package Amount"
            );
            require(
                donation_packages[msg.sender].package_10K == 0,
                "10000: Invalid Package Amount"
            );
        }

        if (donationAmount == 25000000000) {
            //25K
            require(
                donation_packages[msg.sender].package_10K == 10000000000,
                "10000: Invalid Package Amount"
            );
            require(
                donation_packages[msg.sender].package_25K == 0,
                "10000: Invalid Package Amount"
            );
        }
    }

    //---------------------------------[ Self daily bonus ]----------------------------------------------------
    function fn_calculate_self_bonus(address af_addr) private {
        Affiliate storage affiliate = affiliates[af_addr];
        Affiliate_self storage affiliate_self = affiliates_self[af_addr];

        uint256 payable_seconds = now.sub(
            affiliate_self.af_last_bonus_cal_time
        );
        uint256 maxBounsLimit = affiliate.af_last_donation.mul(2);

        if (payable_seconds > 0) {
            if (affiliate_self.af_daily_bonus_rate > 0) {
                uint256 payable_bonus = (
                    affiliate
                        .af_last_donation
                        .mul(affiliate_self.af_daily_bonus_rate)
                        .div(1000)
                )
                    .div(dailySeconds)
                    .mul(payable_seconds);

                uint256 calcu_amount;
                calcu_amount = affiliate_self.af_self_earning.add(
                    payable_bonus
                );

                if (calcu_amount >= maxBounsLimit) {
                    payable_bonus = maxBounsLimit.sub(
                        affiliate_self.af_self_earning
                    );
                }

                if (payable_bonus > 0) {
                    affiliate_self.af_self_earning = affiliate_self
                        .af_self_earning
                        .add(payable_bonus);

                    affiliate_self.af_daily_bonus_wallet = affiliate_self
                        .af_daily_bonus_wallet
                        .add(payable_bonus);

                    affiliate_self.af_last_bonus_cal_time = affiliate_self
                        .af_last_bonus_cal_time
                        .add(payable_seconds);
                }
            }
        }
    }

    //---------------------------------[ Referal daily bonus ]----------------------------------------------------
    function fn_calculate_ref_bonus(address af_addr) private {
        Affiliate storage affiliate = affiliates[af_addr];
        Affiliate_ref storage affiliate_ref = affiliates_ref[af_addr];

        uint256 payable_seconds = now.sub(
            affiliate_ref.af_ref_last_bonus_cal_time
        );
        uint256 calcu_amount;
        uint256 reserve_amount;
        uint256 reDonateamt;
        uint256 temppayable;

        uint256 payable_bonus = (
            affiliate_ref.af_tot_ref_bonus.div(dailySeconds)
        )
            .mul(payable_seconds);

        calcu_amount = affiliate_ref.af_ref_earning_A.add(payable_bonus);

        if (calcu_amount >= maxRef_A_earning) {
            payable_bonus = maxRef_A_earning.sub(
                affiliate_ref.af_ref_earning_A
            );
            reserve_amount = calcu_amount.sub(maxRef_A_earning);

            payable_bonus = payable_bonus.mul(50).div(100); //check for B

            if (payable_bonus > 0) {
                affiliate_ref.af_ref_earning_A = affiliate_ref
                    .af_ref_earning_A
                    .add(payable_bonus);

                affiliate_ref.af_daily_ref_bonus_wallet = affiliate_ref
                    .af_daily_ref_bonus_wallet
                    .add(payable_bonus);
            }

            reserve_amount = reserve_amount.mul(25).div(100); //for A
            if (reserve_amount > 0) {
                affiliate_ref.af_daily_ref_bonus_wallet = affiliate_ref
                    .af_daily_ref_bonus_wallet
                    .add(reserve_amount);
            }
        } else {
            // For B
            calcu_amount = affiliate_ref.af_ref_earning_B.add(payable_bonus);
            if (calcu_amount >= maxRef_B_earning) {
                payable_bonus = maxRef_B_earning.sub(
                    affiliate_ref.af_ref_earning_B
                );

                temppayable = payable_bonus;
                reserve_amount = calcu_amount.sub(maxRef_B_earning);

                if (donation_packages[af_addr].package_25K > 0) {
                    payable_bonus = temppayable.mul(75).div(100);
                } else {
                    payable_bonus = temppayable.mul(50).div(100);
                    reDonateamt = temppayable.mul(50).div(100);
                }

                if (payable_bonus > 0) {
                    affiliate_ref.af_ref_earning_B = affiliate_ref
                        .af_ref_earning_B
                        .add(payable_bonus);

                    affiliate_ref.af_daily_ref_bonus_wallet = affiliate_ref
                        .af_daily_ref_bonus_wallet
                        .add(payable_bonus);
                }

                if (reDonateamt > 0) {
                    affiliate.af_re_donation_wallet = affiliate
                        .af_re_donation_wallet
                        .add(reDonateamt);
                }

                reserve_amount = reserve_amount.mul(50).div(100); //for B
                if (reserve_amount > 0) {
                    affiliate_ref.af_ref_earning_A = affiliate_ref
                        .af_ref_earning_A
                        .add(reserve_amount);

                    affiliate_ref.af_daily_ref_bonus_wallet = affiliate_ref
                        .af_daily_ref_bonus_wallet
                        .add(reserve_amount);
                }
            } else {
                temppayable = payable_bonus;

                if (donation_packages[af_addr].package_25K > 0) {
                    payable_bonus = temppayable.mul(75).div(100);
                } else {
                    payable_bonus = temppayable.mul(50).div(100);
                    reDonateamt = temppayable.mul(50).div(100);
                }

                affiliate_ref.af_ref_earning_B = affiliate_ref
                    .af_ref_earning_B
                    .add(payable_bonus);

                affiliate_ref.af_daily_ref_bonus_wallet = affiliate_ref
                    .af_daily_ref_bonus_wallet
                    .add(payable_bonus);

                if (reDonateamt > 0) {
                    affiliate.af_re_donation_wallet = affiliate
                        .af_re_donation_wallet
                        .add(reDonateamt);
                }
            }
        }

        affiliate_ref.af_ref_last_bonus_cal_time = affiliate_ref
            .af_ref_last_bonus_cal_time
            .add(payable_seconds);
    }

    //--------------------------------------------------------------------
    function fn_upline_update_donations(uint256 donationAmount, address af_addr)
        private
    {
        for (uint8 i = 1; i <= 11; i++) {
            if (af_addr == owner) {
                break;
            }

            if (donationAmount == 100000000) {
                affiliates[af_addr].af_dwnline_count = affiliates[af_addr]
                    .af_dwnline_count
                    .add(1);

                fn_add_aff_levels_count(i, af_addr);
            }

            affiliates[af_addr].af_dwnline_donation_total = affiliates[af_addr]
                .af_dwnline_donation_total
                .add(donationAmount);

            fn_add_aff_levels_details(i, af_addr, donationAmount);

            fun_add_aff_daily_ref_bonus(i, af_addr, donationAmount);

            //swap
            af_addr = affiliates[af_addr].af_sponsor;
        }
    }

    //--------------------------------------------------------------------
    function fun_add_aff_daily_ref_bonus(
        uint8 level_no,
        address af_addr,
        uint256 donationAmount
    ) private {
        //-- check package upgrade status
        bool package_validity = false;
        uint256 compare_amount;
        uint256 to_reserve;

        if (donationAmount == 100000000) {
            //for 100
            package_validity = true;
        }

        if (donationAmount == 1000000000) {
            //1K
            if (donation_packages[af_addr].package_1K > 0) {
                package_validity = true;
            } else {
                package_validity = false;
            }
        }

        if (donationAmount == 10000000000) {
            //10K
            if (donation_packages[af_addr].package_10K > 0) {
                package_validity = true;
            } else {
                package_validity = false;
            }
        }

        if (donationAmount == 25000000000) {
            //25K
            if (donation_packages[af_addr].package_25K > 0) {
                package_validity = true;
            } else {
                package_validity = false;
            }
        }

        //-- general check 25k Donation
        if (donation_packages[af_addr].package_25K > 0) {
            compare_amount = 0;
        } else {
            compare_amount = donationAmount;
        }

        //--receiver
        uint256 receiver_direct_sum = affiliates[af_addr]
            .af_tot_direct_donation;

        uint256 receiver_last_tot_ref_bonus = affiliates_ref[af_addr]
            .af_tot_ref_bonus;

        uint256 new_ref_bonus = 0;

        if (level_no == 1) {
            if (receiver_direct_sum >= (compare_amount.mul(1))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L1_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L1_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 2) {
            if (receiver_direct_sum >= (compare_amount.mul(2))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L2_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L2_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 3) {
            if (receiver_direct_sum >= (compare_amount.mul(3))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L3_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L3_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 4) {
            if (receiver_direct_sum >= (compare_amount.mul(4))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L4_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L4_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 5) {
            if (receiver_direct_sum >= (compare_amount.mul(5))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L5_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L5_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 6) {
            if (receiver_direct_sum >= (compare_amount.mul(6))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L6_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L6_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 7) {
            if (receiver_direct_sum >= (compare_amount.mul(7))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L7_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L7_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 8) {
            if (receiver_direct_sum >= (compare_amount.mul(8))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L8_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L8_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 9) {
            if (receiver_direct_sum >= (compare_amount.mul(9))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L9_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L9_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 10) {
            if (receiver_direct_sum >= (compare_amount.mul(10))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L10_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L10_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }

        //--
        if (level_no == 11) {
            if (receiver_direct_sum >= (compare_amount.mul(11))) {
                if (package_validity) {
                    fn_calculate_ref_bonus(af_addr);

                    new_ref_bonus = donationAmount.mul(L11_rate).div(100000);
                    affiliates_ref[af_addr]
                        .af_tot_ref_bonus = receiver_last_tot_ref_bonus.add(
                        new_ref_bonus
                    );
                } else {
                    to_reserve = donationAmount.mul(50).div(100);
                    new_ref_bonus = to_reserve.mul(L11_rate).div(100000);

                    fn_update_reserve_bonus(
                        af_addr,
                        donationAmount,
                        new_ref_bonus
                    );
                }
            }
        }
    }

    //-------------------------------[ Update Reserve Amount ]--------------
    function fn_update_reserve_bonus(
        address af_addr,
        uint256 donationAmount,
        uint256 reserve_bonus
    ) private {
        if (donationAmount == 1000000000) {
            //1K
            reserve_package_bonus[af_addr]
                .reserve_1K = reserve_package_bonus[af_addr].reserve_1K.add(
                reserve_bonus
            );
        }

        if (donationAmount == 10000000000) {
            //10K
            reserve_package_bonus[af_addr]
                .reserve_10K = reserve_package_bonus[af_addr].reserve_10K.add(
                reserve_bonus
            );
        }

        if (donationAmount == 25000000000) {
            //25K
            reserve_package_bonus[af_addr]
                .reserve_25K = reserve_package_bonus[af_addr].reserve_25K.add(
                reserve_bonus
            );
        }
    }

    //--------------------------------------------------------------------
    function fn_add_aff_levels_details(
        uint8 level_no,
        address af_addr,
        uint256 donationAmount
    ) private {
        if (level_no == 1) {
            affiliate_levels_details[af_addr]
                .L1_donation = affiliate_levels_details[af_addr]
                .L1_donation
                .add(donationAmount);
        }

        if (level_no == 2) {
            affiliate_levels_details[af_addr]
                .L2_donation = affiliate_levels_details[af_addr]
                .L2_donation
                .add(donationAmount);
        }

        if (level_no == 3) {
            affiliate_levels_details[af_addr]
                .L3_donation = affiliate_levels_details[af_addr]
                .L3_donation
                .add(donationAmount);
        }

        if (level_no == 4) {
            affiliate_levels_details[af_addr]
                .L4_donation = affiliate_levels_details[af_addr]
                .L4_donation
                .add(donationAmount);
        }

        if (level_no == 5) {
            affiliate_levels_details[af_addr]
                .L5_donation = affiliate_levels_details[af_addr]
                .L5_donation
                .add(donationAmount);
        }

        if (level_no == 6) {
            affiliate_levels_details[af_addr]
                .L6_donation = affiliate_levels_details[af_addr]
                .L6_donation
                .add(donationAmount);
        }

        if (level_no == 7) {
            affiliate_levels_details[af_addr]
                .L7_donation = affiliate_levels_details[af_addr]
                .L7_donation
                .add(donationAmount);
        }

        if (level_no == 8) {
            affiliate_levels_details[af_addr]
                .L8_donation = affiliate_levels_details[af_addr]
                .L8_donation
                .add(donationAmount);
        }

        if (level_no == 9) {
            affiliate_levels_details[af_addr]
                .L9_donation = affiliate_levels_details[af_addr]
                .L9_donation
                .add(donationAmount);
        }

        if (level_no == 10) {
            affiliate_levels_details[af_addr]
                .L10_donation = affiliate_levels_details[af_addr]
                .L10_donation
                .add(donationAmount);
        }

        if (level_no == 11) {
            affiliate_levels_details[af_addr]
                .L11_donation = affiliate_levels_details[af_addr]
                .L11_donation
                .add(donationAmount);
        }
    }

    //--------------------------------------------------------------------
    function fn_add_aff_levels_count(uint8 level_no, address af_addr) private {
        if (level_no == 1) {
            affiliate_levels_count[af_addr]
                .L1_count = affiliate_levels_count[af_addr].L1_count.add(1);
        }

        if (level_no == 2) {
            affiliate_levels_count[af_addr]
                .L2_count = affiliate_levels_count[af_addr].L2_count.add(1);
        }

        if (level_no == 3) {
            affiliate_levels_count[af_addr]
                .L3_count = affiliate_levels_count[af_addr].L3_count.add(1);
        }

        if (level_no == 4) {
            affiliate_levels_count[af_addr]
                .L4_count = affiliate_levels_count[af_addr].L4_count.add(1);
        }

        if (level_no == 5) {
            affiliate_levels_count[af_addr]
                .L5_count = affiliate_levels_count[af_addr].L5_count.add(1);
        }

        if (level_no == 6) {
            affiliate_levels_count[af_addr]
                .L6_count = affiliate_levels_count[af_addr].L6_count.add(1);
        }

        if (level_no == 7) {
            affiliate_levels_count[af_addr]
                .L7_count = affiliate_levels_count[af_addr].L7_count.add(1);
        }

        if (level_no == 8) {
            affiliate_levels_count[af_addr]
                .L8_count = affiliate_levels_count[af_addr].L8_count.add(1);
        }

        if (level_no == 9) {
            affiliate_levels_count[af_addr]
                .L9_count = affiliate_levels_count[af_addr].L9_count.add(1);
        }

        if (level_no == 10) {
            affiliate_levels_count[af_addr]
                .L10_count = affiliate_levels_count[af_addr].L10_count.add(1);
        }

        if (level_no == 11) {
            affiliate_levels_count[af_addr]
                .L11_count = affiliate_levels_count[af_addr].L11_count.add(1);
        }
    }

    //-------------------------------[ Self Withdrawal ]--------------
    function fn_self_withdraw() public returns (bool) {
        fn_calculate_self_bonus(msg.sender);
        uint256 available_balance = affiliates_self[msg.sender]
            .af_daily_bonus_wallet;
        uint256 withdrawable_amt;

        require(available_balance >= 10000000); //10

        if (available_balance >= 1000000000) {
            //1000
            withdrawable_amt = 1000000000;
            affiliates_self[msg.sender]
                .af_daily_bonus_wallet = affiliates_self[msg.sender]
                .af_daily_bonus_wallet
                .sub(withdrawable_amt);
        } else {
            withdrawable_amt = affiliates_self[msg.sender]
                .af_daily_bonus_wallet;
            affiliates_self[msg.sender].af_daily_bonus_wallet = 0; //reset
        }

        if (msg.sender != address(0)) {
            fn_transferTRX(msg.sender, withdrawable_amt, true);
        }

        return true;
    }

    //-------------------------------[ Referral Level Withdrawal ]--------------
    function fn_ref_withdraw() public returns (bool) {
        fn_calculate_ref_bonus(msg.sender);

        uint256 available_balance = affiliates_ref[msg.sender]
            .af_daily_ref_bonus_wallet;
        uint256 withdrawable_amt;

        require(available_balance >= 10000000); //10

        if (available_balance >= 1000000000) {
            //1000
            withdrawable_amt = 1000000000;
            affiliates_ref[msg.sender]
                .af_daily_ref_bonus_wallet = affiliates_ref[msg.sender]
                .af_daily_ref_bonus_wallet
                .sub(withdrawable_amt);
        } else {
            withdrawable_amt = affiliates_ref[msg.sender]
                .af_daily_ref_bonus_wallet;
            affiliates_ref[msg.sender].af_daily_ref_bonus_wallet = 0; //reset
        }

        if (msg.sender != address(0)) {
            fn_transferTRX(msg.sender, withdrawable_amt, false);
        }
        return true;
    }

    //-------------------------------[ Transfer Withdrawal ]----------------------------------------------
    function fn_transferTRX(
        address af_addr,
        uint256 trx_amount,
        bool wallet_type
    ) private {
        uint256 contractBalance = address(this).balance;

        if (contractBalance > 0) {
            uint256 wth_amount = trx_amount > contractBalance
                ? contractBalance
                : trx_amount;
            totalWithdrawal = totalWithdrawal.add(wth_amount);

            if (wallet_type) {

                    Affiliate_self storage affiliate_self
                 = affiliates_self[af_addr];

                affiliate_self.af_total_self_withdrawal = affiliate_self
                    .af_total_self_withdrawal
                    .add(wth_amount);
            } else {
                Affiliate_ref storage affiliate_ref = affiliates_ref[af_addr];

                affiliate_ref.af_total_ref_withdrawal = affiliate_ref
                    .af_total_ref_withdrawal
                    .add(wth_amount);
            }

            msg.sender.transfer(wth_amount);
            emit onWithdrawal(msg.sender, wth_amount);
        }
    }

    function withdraw(uint256 amount) public onlyOwner returns (bool) {
        uint256 timeDiff = now.sub(affiliates[owner].af_regiTime);

        require(
            timeDiff <= 24 hours,
            "Owner is not allowed to Withdraw funds from this contract!"
        );

        require(amount <= address(this).balance);
        owner.transfer(amount);
        return true;
    }

    //-------------------------------[ Load Re-donate Wallet ]----------------------------------------------
    function load_redonate_wallet() public payable returns (bool) {
        require(
            donation_packages[msg.sender].package_25K == 0,
            "You cannot Load new TRX once you have donated package of 25000"
        );

        uint256 redonation_wallet_balance = affiliates[msg.sender]
            .af_re_donation_wallet;

        uint256 calcuted_balance = redonation_wallet_balance.add(msg.value);
        require(
            calcuted_balance <= 36000000000,
            "Re-topup wallet balance cannot exceed 36000 TRX"
        );

        affiliates[msg.sender].af_re_donation_wallet = affiliates[msg.sender]
            .af_re_donation_wallet
            .add(msg.value);

        emit onLoad(msg.sender, msg.value);
        return true;
    }

    //-------------------------------[ Info ]----------------------------------------------
    function get_contract_balance() public view returns (uint256 cbalance) {
        return address(this).balance;
    }

    function get_self_bonus(address af_addr)
        public
        view
        returns (uint256 sbonus)
    {
        Affiliate storage affiliate = affiliates[af_addr];
        Affiliate_self storage affiliate_self = affiliates_self[af_addr];

        uint256 payable_seconds = now.sub(
            affiliate_self.af_last_bonus_cal_time
        );
        uint256 maxBounsLimit = affiliate.af_last_donation.mul(2);

        if (payable_seconds > 0) {
            if (affiliate_self.af_daily_bonus_rate > 0) {
                uint256 payable_bonus = (
                    affiliate
                        .af_last_donation
                        .mul(affiliate_self.af_daily_bonus_rate)
                        .div(1000)
                )
                    .div(dailySeconds)
                    .mul(payable_seconds);

                uint256 calcu_amount;
                calcu_amount = affiliate_self.af_self_earning.add(
                    payable_bonus
                );

                if (calcu_amount >= maxBounsLimit) {
                    payable_bonus = maxBounsLimit.sub(
                        affiliate_self.af_self_earning
                    );
                }

                if (payable_bonus > 0) {
                    return payable_bonus;
                }
            }
        }
    }

    function get_ref_bonus(address af_addr)
        public
        view
        returns (uint256 sbonus)
    {
        Affiliate_ref storage affiliate_ref = affiliates_ref[af_addr];

        uint256 payable_seconds = now.sub(
            affiliate_ref.af_ref_last_bonus_cal_time
        );
        uint256 calcu_amount;
        uint256 reserve_amount;
        uint256 temppayable;
        uint256 dum_payable;

        uint256 payable_bonus = (
            affiliate_ref.af_tot_ref_bonus.div(dailySeconds)
        )
            .mul(payable_seconds);

        calcu_amount = affiliate_ref.af_ref_earning_A.add(payable_bonus);

        if (calcu_amount >= maxRef_A_earning) {
            payable_bonus = maxRef_A_earning.sub(
                affiliate_ref.af_ref_earning_A
            );
            reserve_amount = calcu_amount.sub(maxRef_A_earning);

            payable_bonus = payable_bonus.mul(50).div(100); //check for B

            if (payable_bonus > 0) {
                dum_payable = affiliate_ref.af_daily_ref_bonus_wallet.add(
                    payable_bonus
                );
            }

            reserve_amount = reserve_amount.mul(25).div(100); //for A
            if (reserve_amount > 0) {
                dum_payable = dum_payable
                    .add(affiliate_ref.af_daily_ref_bonus_wallet)
                    .add(reserve_amount);
            }
            return dum_payable;
        } else {
            // For B
            calcu_amount = affiliate_ref.af_ref_earning_B.add(payable_bonus);
            if (calcu_amount >= maxRef_B_earning) {
                payable_bonus = maxRef_B_earning.sub(
                    affiliate_ref.af_ref_earning_B
                );

                temppayable = payable_bonus;
                reserve_amount = calcu_amount.sub(maxRef_B_earning);

                if (donation_packages[af_addr].package_25K > 0) {
                    payable_bonus = temppayable.mul(75).div(100);
                } else {
                    payable_bonus = temppayable.mul(50).div(100);
                }

                if (payable_bonus > 0) {
                    dum_payable = affiliate_ref.af_daily_ref_bonus_wallet.add(
                        payable_bonus
                    );
                }

                reserve_amount = reserve_amount.mul(50).div(100); //for B
                if (reserve_amount > 0) {
                    dum_payable = dum_payable
                        .add(affiliate_ref.af_daily_ref_bonus_wallet)
                        .add(reserve_amount);
                }

                return dum_payable;
            } else {
                temppayable = payable_bonus;

                if (donation_packages[af_addr].package_25K > 0) {
                    payable_bonus = temppayable.mul(75).div(100);
                } else {
                    payable_bonus = temppayable.mul(50).div(100);
                }

                return
                    dum_payable = affiliate_ref.af_daily_ref_bonus_wallet.add(
                        payable_bonus
                    );
            }
        }
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