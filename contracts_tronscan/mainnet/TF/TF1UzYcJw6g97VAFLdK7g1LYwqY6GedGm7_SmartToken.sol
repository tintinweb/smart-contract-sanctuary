//SourceUnit: SmartTokenFinal_Data_transfer.sol

/*
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.   .----------------.  .----------------.  .----------------.  .----------------.  .-----------------.
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |    _______   | || | ____    ____ | || |      __      | || |  _______     | || |  _________   | | | |  _________   | || |     ____     | || |  ___  ____   | || |  _________   | || | ____  _____  | |
| |   /  ___  |  | || ||_   \  /   _|| || |     /  \     | || | |_   __ \    | || | |  _   _  |  | | | | |  _   _  |  | || |   .'    `.   | || | |_  ||_  _|  | || | |_   ___  |  | || ||_   \|_   _| | |
| |  |  (__ \_|  | || |  |   \/   |  | || |    / /\ \    | || |   | |__) |   | || | |_/ | | \_|  | | | | |_/ | | \_|  | || |  /  .--.  \  | || |   | |_/ /    | || |   | |_  \_|  | || |  |   \ | |   | |
| |   '.___`-.   | || |  | |\  /| |  | || |   / ____ \   | || |   |  __ /    | || |     | |      | | | |     | |      | || |  | |    | |  | || |   |  __'.    | || |   |  _|  _   | || |  | |\ \| |   | |
| |  |`\____) |  | || | _| |_\/_| |_ | || | _/ /    \ \_ | || |  _| |  \ \_  | || |    _| |_     | | | |    _| |_     | || |  \  `--'  /  | || |  _| |  \ \_  | || |  _| |___/ |  | || | _| |_\   |_  | |
| |  |_______.'  | || ||_____||_____|| || ||____|  |____|| || | |____| |___| | || |   |_____|    | | | |   |_____|    | || |   `.____.'   | || | |____||____| | || | |_________|  | || ||_____|\____| | |
| |              | || |              | || |              | || |              | || |              | | | |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'   '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 
    
    www.smarttoken4u.com                                                                                                                                                                       
*/

pragma solidity ^0.4.25;

contract SmartToken {
    using SafeMath for uint256;
    address owner;
    event onDeposite(address indexed donor, uint256 deposite);
    event onReDeposite(address indexed donor, uint256 deposite);
    event onWithdrawal(address indexed donor, uint256 bonus);
    event onLoad(address indexed donor, uint256 amount);

    uint256 public totalUsers;
    uint256 public totalDeposite;
    uint256 public totalReDeposite;
    uint256 public totalWithdrawal;
    address public last_user;

    uint256 public GFW_Talloted;
    uint256 public GFW_TRX;
    uint256 public token_rate;

    uint256 private resGFW_TRX;
    bool resGFWflag;
    bool compReset;

    struct User {
        uint256 U_regiTime;
        uint256 U_depositTime;
        address U_sponsor;
        uint256 U_direct_count;
        uint256 U_tot_deposit;
        uint256 U_last_deposit;
        uint256 U_tokens;
        uint256 U_dwnline_count;
        uint256 U_dwnline_deposit_total;
        uint256 U_referral_bonus;
        uint256 U_wth_wallet;
        uint256 U_tot_add_donation;
        uint256 U_tot_Re_deposit;
        uint256 U_tot_Withdrawn;
    }
    mapping(address => User) public users;

    struct User_matrix {
        address after_id;
        address UM_pline_id;
        address L_addr;
        address R_addr;
        uint256 UM_matrix_bonus;
    }
    mapping(address => User_matrix) public users_matrix;

    struct User_level_count {
        uint256 L1_users;
        uint256 L2_users;
        uint256 L3_users;
        uint256 L4_users;
        uint256 L5_users;
        uint256 L6_users;
        uint256 L7_users;
        uint256 L8_users;
        uint256 L9_users;
        uint256 L10_users;
        uint256 L11_users;
        uint256 L12_users;
        uint256 L13_users;
    }
    mapping(address => User_level_count) public user_level_count;

    struct User_level_deposite {
        uint256 L1_deposite;
        uint256 L2_deposite;
        uint256 L3_deposite;
        uint256 L4_deposite;
        uint256 L5_deposite;
        uint256 L6_deposite;
        uint256 L7_deposite;
        uint256 L8_deposite;
        uint256 L9_deposite;
        uint256 L10_deposite;
        uint256 L11_deposite;
        uint256 L12_deposite;
        uint256 L13_deposite;
    }
    mapping(address => User_level_deposite) public user_level_deposite;

    struct Deposite_options {
        uint256 option_5H;
        uint256 option_1K;
    }
    mapping(address => Deposite_options) public deposite_options;
    mapping(uint256 => address) private contrib;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    mapping(uint256 => address) private xstakes;

    constructor() public {
        GFW_Talloted = 0;
        GFW_TRX = 0;
        token_rate = 100000000;

        owner = msg.sender;
        last_user = msg.sender;

        users[owner].U_regiTime = now;
        users[owner].U_sponsor = owner;

        users_matrix[owner].UM_pline_id = owner;
        users_matrix[owner].after_id = owner;

        resGFWflag = true;
        compReset = true;
    }

    function deposit(address _sponsorAddr) public payable returns (uint256) {
        require(compReset == true, "System Reset 1");

        require(
            (msg.value == 500000000 || msg.value == 1000000000),
            "Invalid Amount"
        );

        uint256 depositeAmt = msg.value;

        require(
            _sponsorAddr != msg.sender,
            "Sponsor & depositor should be different"
        );

        User storage sponsor = users[_sponsorAddr];
        require(sponsor.U_regiTime > 0, "Sponsor Not Found");

        is_deposite_valid(depositeAmt);

        User storage user = users[msg.sender];
        bool deposite_type;
        bool chk_reset_flag;

        if (user.U_regiTime == 0) {
            address reser_last_user = last_user;

            user.U_regiTime = now;
            user.U_sponsor = _sponsorAddr;
            deposite_type = true;
            sponsor.U_direct_count = sponsor.U_direct_count.add(1);
            totalUsers++;

            last_user = msg.sender;

            if (depositeAmt == 500000000) {
                deposite_options[msg.sender].option_5H = depositeAmt;
            }

            if (depositeAmt == 1000000000) {
                deposite_options[msg.sender].option_1K = depositeAmt;
            }

            if (totalUsers >= 1 && totalUsers <= 7) {
                contrib[totalUsers] = msg.sender;
            }

            if (totalUsers >= 2 && totalUsers <= 5) {
                xstakes[totalUsers - 1] = msg.sender;
            }

            find_matrix_pos(depositeAmt, _sponsorAddr);
            users_matrix[msg.sender].after_id = reser_last_user;
        } else {
            deposite_type = false;
            _sponsorAddr = user.U_sponsor;

            if (depositeAmt == 1000000000) {
                deposite_options[msg.sender].option_1K = depositeAmt;
            }

            address upline_addr = users_matrix[msg.sender].UM_pline_id;
            update_matrix_bonus_upline(depositeAmt, upline_addr);
        }

        totalDeposite = totalDeposite.add(depositeAmt);

        user.U_depositTime = now;

        user.U_tot_deposit = user.U_tot_deposit.add(depositeAmt);

        user.U_last_deposit = depositeAmt;

        update_deposite_upline(depositeAmt, _sponsorAddr, deposite_type);

        add_contrib_share(depositeAmt);

        uint256 Tokens_alloted;
        if (depositeAmt == 500000000) {
            chk_reset_flag = check_and_reset(50000000, 1);
            if (chk_reset_flag == true) {
                add_GFW(50000000);
                Tokens_alloted = allot_tokens(50000000, msg.sender);
                new_rate();
                add_ReGFW(41000000);
            }
        } else {
            chk_reset_flag = check_and_reset(100000000, 1);
            if (chk_reset_flag == true) {
                add_GFW(100000000);
                Tokens_alloted = allot_tokens(100000000, msg.sender);
                new_rate();
                add_ReGFW(82000000);
            }
        }

        emit onDeposite(msg.sender, depositeAmt);
        return Tokens_alloted;
    }

    //-----------------------------------------------------------------------
    function re_deposit(uint256 depositeAmt) public returns (bool) {
        require(compReset == true, "System Reset 4");
        address _sponsorAddr = users[msg.sender].U_sponsor;

        User storage user = users[msg.sender];
        User storage sponsor = users[_sponsorAddr];
        require(sponsor.U_regiTime > 0, "Sponsor Not Found");
        require(user.U_regiTime > 0, "User Not Found");

        is_RE_deposite_valid(depositeAmt);

        require(
            user.U_wth_wallet >= depositeAmt,
            "Insufficient Balance in Wallet"
        );
        user.U_wth_wallet = user.U_wth_wallet.sub(depositeAmt);
        user.U_tot_Re_deposit = user.U_tot_Re_deposit.add(depositeAmt);

        bool deposite_type = false;

        address upline_addr = users_matrix[msg.sender].UM_pline_id;
        update_matrix_bonus_upline(depositeAmt, upline_addr);

        totalReDeposite = totalReDeposite.add(depositeAmt);

        update_deposite_upline(depositeAmt, _sponsorAddr, deposite_type);

        add_contrib_share(depositeAmt);

        uint256 addingTRXin_GFW = depositeAmt.div(1000000000).mul(100000000);
        uint256 addingTRXin_ReGFW = depositeAmt.div(1000000000).mul(82000000);

        bool chk_reset_flag = check_and_reset(addingTRXin_GFW, 0);
        if (chk_reset_flag == true) {
            add_GFW(addingTRXin_GFW);
            new_rate();
            add_ReGFW(addingTRXin_ReGFW);
        }

        emit onReDeposite(msg.sender, depositeAmt);
        return true;
    }

    //--------------------------------------------------------------------
    function add_donation(uint256 depositeAmt) public returns (bool) {
        require(compReset == true, "System Reset 5");
        User storage user = users[msg.sender];
        require(user.U_regiTime > 0, "User Not Found");

        is_add_donation_valid(depositeAmt);

        require(
            user.U_wth_wallet >= depositeAmt,
            "Insufficient Balance in Wallet"
        );
        user.U_wth_wallet = user.U_wth_wallet.sub(depositeAmt);
        user.U_tot_add_donation = user.U_tot_add_donation.add(depositeAmt);

        add_ReGFW(depositeAmt);
        return true;
    }

    //--------------------------------------------------------------------
    function allot_tokens(uint256 token_value, address useraddress)
        private
        returns (uint256)
    {
        uint256 add_tokens =
            (token_value.mul(1000000) * 10**12).div(token_rate);

        users[useraddress].U_tokens = users[useraddress].U_tokens.add(
            add_tokens
        );
        GFW_Talloted = GFW_Talloted.add(add_tokens);

        return add_tokens;
    }

    //--------------------------------------------------------------------
    function sell_tokens(uint256 token_qty) public {
        uint256 token_qtyFull = token_qty * 10**12;
        require(compReset == true, "System Reset 6");

        require(
            users[msg.sender].U_tokens >= token_qtyFull,
            "Insufficient Balance"
        );

        uint256 tot_trx = token_qty.mul(token_rate).div(1000000);

        uint256 add_GFW_trx = tot_trx.mul(10).div(100);
        uint256 add_User_trx = tot_trx.mul(90).div(100);

        users[msg.sender].U_tokens = users[msg.sender].U_tokens.sub(
            token_qtyFull
        );
        minus_GFW(tot_trx);

        GFW_Talloted = GFW_Talloted.sub(token_qtyFull);

        users[msg.sender].U_wth_wallet = users[msg.sender].U_wth_wallet.add(
            add_User_trx
        );

        bool chk_reset_flag = check_and_reset(add_GFW_trx, 0);
        if (chk_reset_flag == true) {
            add_GFW(add_GFW_trx);
            new_rate();
        }
    }

    //--------------------------------------------------------------------
    function bulk_sell_tokens() public onlyOwner {
        address upline_addr = last_user;
        uint256 token_qty;
        uint256 tot_trx;
        uint256 add_GFW_trx;
        uint256 add_User_trx;
        uint256 xstakes_adtot;
        uint256 token_qtyFull;

        for (uint256 i = 1; i <= totalUsers; i++) {
            if (upline_addr == owner) {
                break;
            }

            token_qty = users[upline_addr].U_tokens;
            token_qtyFull = token_qty * 10**12;

            tot_trx = token_qty.mul(token_rate).div(1000000);

            add_GFW_trx = tot_trx.mul(10).div(100);
            add_User_trx = tot_trx.mul(90).div(100);

            users[upline_addr].U_tokens = users[upline_addr].U_tokens.sub(
                token_qtyFull
            );

            users[upline_addr].U_wth_wallet = users[upline_addr]
                .U_wth_wallet
                .add(add_User_trx);

            xstakes_adtot = xstakes_adtot.add(add_GFW_trx);
            //swap
            upline_addr = users_matrix[upline_addr].after_id;
        }

        if (xstakes_adtot > 0) {
            update_xstakes(xstakes_adtot);
        }
        compReset = true;
    }

    //--------------------------------------------------------------------
    function add_GFW(uint256 afund) private {
        uint256 nevfund = afund.mul(1000000);
        GFW_TRX = GFW_TRX.add(nevfund);
    }

    function minus_GFW(uint256 afund) private {
        uint256 nevfund = afund.mul(1000000);
        GFW_TRX = GFW_TRX.sub(nevfund);
    }

    function new_rate() private {
        if (GFW_Talloted != 0) {
            token_rate = GFW_TRX.div((GFW_Talloted).div(10**12));
        }
    }

    function check_and_reset(uint256 token_value, uint256 fresh_tallow)
        private
        returns (bool)
    {
        if (GFW_Talloted != 0) {
            if (fresh_tallow != 0) {
                fresh_tallow = token_value.div(token_rate).mul(1000000);
            }

            uint256 new_token_rate =
                (GFW_TRX.add((token_value).mul(1000000))).div(
                    GFW_Talloted.add(fresh_tallow)
                );

            if (new_token_rate >= 1000000000000) {
                //1
                GFW_Talloted = 0;
                GFW_TRX = 0;
                token_rate = 100000000;
                compReset = false;
                resGFWflag = true;

                update_xstakes(resGFW_TRX);
                resGFW_TRX = 0;
                return false;
            }
        }

        return true;
    }

    function add_ReGFW(uint256 afund) private {
        bool chk_reset_flag;
        if (resGFWflag) {
            if (resGFW_TRX < 20000000000) {
                resGFW_TRX = resGFW_TRX.add(afund);
            } else {
                if (resGFWflag) {
                    resGFWflag = false; //one time

                    chk_reset_flag = check_and_reset(resGFW_TRX, 0);
                    if (chk_reset_flag == true) {
                        add_GFW(resGFW_TRX);
                        new_rate();
                        resGFW_TRX = 0;
                    }
                }
            }
        } else {
            chk_reset_flag = check_and_reset(afund, 0);
            if (chk_reset_flag == true) {
                add_GFW(afund);
                new_rate();
            }
        }
    }

    //--------------------------------------------------------------------
    function find_matrix_pos(uint256 depositeAmt, address upline_addr)
        private
        returns (bool)
    {
        address[] memory newArray = new address[](totalUsers);
        if (upline_addr == owner) {
            if (totalUsers == 1) {
                users_matrix[msg.sender].UM_pline_id = owner;

                users[msg.sender].U_wth_wallet = users[msg.sender]
                    .U_wth_wallet
                    .add(270000000);
            }
            return true;
        } else {
            newArray[0] = upline_addr;
        }

        uint256 counter = 0;

        for (uint8 i = 1; i < totalUsers; i = i + 2) {
            if (users_matrix[newArray[counter]].L_addr == 0x0) {
                users_matrix[msg.sender].UM_pline_id = newArray[counter];
                users_matrix[newArray[counter]].L_addr = msg.sender;
                update_matrix_bonus_upline(depositeAmt, newArray[counter]);
                return true;
            }

            if (users_matrix[newArray[counter]].R_addr == 0x0) {
                users_matrix[msg.sender].UM_pline_id = newArray[counter];
                users_matrix[newArray[counter]].R_addr = msg.sender;
                update_matrix_bonus_upline(depositeAmt, newArray[counter]);
                return true;
            }

            newArray[i] = users_matrix[newArray[counter]].L_addr;
            newArray[i + 1] = users_matrix[newArray[counter]].R_addr;
            counter++;
        }
    }

    //--------------------------------------------------------------------
    function update_matrix_bonus_upline(
        uint256 depositeAmt,
        address upline_addr
    ) private {
        uint256 levelAmt;
        uint256 used_amt = 0;
        uint256 unused_amt = 0;

        if (depositeAmt == 500000000) {
            uint256 max5H_amt = 130000000;
            levelAmt = 13000000;
        } else {
            uint256 max1K_amt = depositeAmt.div(1000000000).mul(270000000);
            levelAmt = depositeAmt.div(1000000000).mul(27000000);
        }

        for (uint8 i = 1; i <= 10; i++) {
            if (upline_addr == owner) {
                break;
            }

            users_matrix[upline_addr].UM_matrix_bonus = users_matrix[
                upline_addr
            ]
                .UM_matrix_bonus
                .add(levelAmt);

            users[upline_addr].U_wth_wallet = users[upline_addr]
                .U_wth_wallet
                .add(levelAmt);

            used_amt = used_amt.add(levelAmt);

            //swap
            upline_addr = users_matrix[upline_addr].UM_pline_id;
        }

        //-
        if (depositeAmt == 500000000) {
            unused_amt = max5H_amt.sub(used_amt);
        } else {
            unused_amt = max1K_amt.sub(used_amt);
        }

        update_xstakes(unused_amt);
    }

    //--------------------------------------------------------------------
    function update_deposite_upline(
        uint256 depositeAmt,
        address upline_addr,
        bool deposite_type
    ) private {
        uint256 levelAmt;
        uint256 used_amt = 0;
        uint256 unused_amt = 0;

        if (depositeAmt == 500000000) {
            uint256 max5H_amt = 234000000;
        } else {
            uint256 max1K_amt = depositeAmt.div(1000000000).mul(468000000);
        }

        for (uint8 i = 1; i <= 13; i++) {
            if (upline_addr == owner) {
                break;
            }

            if (deposite_type) {
                users[upline_addr].U_dwnline_count = users[upline_addr]
                    .U_dwnline_count
                    .add(1);

                add_upline_level_count(i, upline_addr);
            }

            users[upline_addr].U_dwnline_deposit_total = users[upline_addr]
                .U_dwnline_deposit_total
                .add(depositeAmt);

            add_upline_level_deposites(i, upline_addr, depositeAmt);

            // add bonus
            if (users[upline_addr].U_direct_count >= i) {
                if (
                    users[upline_addr].U_last_deposit == 500000000 &&
                    depositeAmt == 500000000
                ) {
                    levelAmt = 18000000;
                } else {
                    if (
                        users[upline_addr].U_last_deposit == 500000000 &&
                        depositeAmt == 1000000000
                    ) {
                        levelAmt = 18000000;
                    } else {
                        if (
                            users[upline_addr].U_last_deposit == 1000000000 &&
                            depositeAmt == 500000000
                        ) {
                            levelAmt = 18000000;
                        } else {
                            levelAmt = depositeAmt.div(1000000000).mul(
                                36000000
                            );
                        }
                    }
                }

                users[upline_addr].U_referral_bonus = users[upline_addr]
                    .U_referral_bonus
                    .add(levelAmt);

                users[upline_addr].U_wth_wallet = users[upline_addr]
                    .U_wth_wallet
                    .add(levelAmt);

                used_amt = used_amt.add(levelAmt);
            }

            //swap
            upline_addr = users[upline_addr].U_sponsor;
        }

        //-
        if (depositeAmt == 500000000) {
            unused_amt = max5H_amt.sub(used_amt);
        } else {
            unused_amt = max1K_amt.sub(used_amt);
        }

        update_xstakes(unused_amt);
    }

    //--------------------------------------------------------------------
    function update_xstakes(uint256 unused_amt) private {
        uint256 add_amt;
        address contriaddr;

        if (unused_amt > 0) {
            for (uint8 i = 1; i <= 4; i++) {
                contriaddr = xstakes[i];
                if (contriaddr != 0x0) {
                    if (i <= 2) {
                        add_amt = unused_amt.mul(20).div(100);
                    } else {
                        add_amt = unused_amt.mul(30).div(100);
                    }
                    users[contriaddr].U_wth_wallet = users[contriaddr]
                        .U_wth_wallet
                        .add(add_amt);
                } else {
                    if (i <= 2) {
                        add_amt = unused_amt.mul(20).div(100);
                    } else {
                        add_amt = unused_amt.mul(30).div(100);
                    }
                    users[contrib[1]].U_wth_wallet = users[contrib[1]]
                        .U_wth_wallet
                        .add(add_amt);
                }
            }
        }
    }

    //--------------------------------------------------------------------
    function add_contrib_share(uint256 depositeAmt) private {
        uint256 add_amtA = depositeAmt.mul(15).div(1000);
        uint256 add_amtB = depositeAmt.mul(1).div(100);

        address contriaddr;
        for (uint8 i = 2; i <= 7; i++) {
            contriaddr = contrib[i];
            if (contriaddr != 0x0) {
                if (i <= 5) {
                    users[contriaddr].U_wth_wallet = users[contriaddr]
                        .U_wth_wallet
                        .add(add_amtA);
                } else {
                    users[contriaddr].U_wth_wallet = users[contriaddr]
                        .U_wth_wallet
                        .add(add_amtB);
                }
            } else {
                if (i <= 5) {
                    users[contrib[1]].U_wth_wallet = users[contrib[1]]
                        .U_wth_wallet
                        .add(add_amtA);
                } else {
                    users[contrib[1]].U_wth_wallet = users[contrib[1]]
                        .U_wth_wallet
                        .add(add_amtB);
                }
            }
        }
    }

    //--------------------------------------------------------------------
    function add_upline_level_deposites(
        uint8 level_no,
        address upline_addr,
        uint256 depositeAmt
    ) private {
        if (level_no == 1) {
            user_level_deposite[upline_addr].L1_deposite = user_level_deposite[
                upline_addr
            ]
                .L1_deposite
                .add(depositeAmt);
        }

        if (level_no == 2) {
            user_level_deposite[upline_addr].L2_deposite = user_level_deposite[
                upline_addr
            ]
                .L2_deposite
                .add(depositeAmt);
        }

        if (level_no == 3) {
            user_level_deposite[upline_addr].L3_deposite = user_level_deposite[
                upline_addr
            ]
                .L3_deposite
                .add(depositeAmt);
        }

        if (level_no == 4) {
            user_level_deposite[upline_addr].L4_deposite = user_level_deposite[
                upline_addr
            ]
                .L4_deposite
                .add(depositeAmt);
        }

        if (level_no == 5) {
            user_level_deposite[upline_addr].L5_deposite = user_level_deposite[
                upline_addr
            ]
                .L5_deposite
                .add(depositeAmt);
        }

        if (level_no == 6) {
            user_level_deposite[upline_addr].L6_deposite = user_level_deposite[
                upline_addr
            ]
                .L6_deposite
                .add(depositeAmt);
        }

        if (level_no == 7) {
            user_level_deposite[upline_addr].L7_deposite = user_level_deposite[
                upline_addr
            ]
                .L7_deposite
                .add(depositeAmt);
        }

        if (level_no == 8) {
            user_level_deposite[upline_addr].L8_deposite = user_level_deposite[
                upline_addr
            ]
                .L8_deposite
                .add(depositeAmt);
        }

        if (level_no == 9) {
            user_level_deposite[upline_addr].L9_deposite = user_level_deposite[
                upline_addr
            ]
                .L9_deposite
                .add(depositeAmt);
        }

        if (level_no == 10) {
            user_level_deposite[upline_addr].L10_deposite = user_level_deposite[
                upline_addr
            ]
                .L10_deposite
                .add(depositeAmt);
        }

        if (level_no == 11) {
            user_level_deposite[upline_addr].L11_deposite = user_level_deposite[
                upline_addr
            ]
                .L11_deposite
                .add(depositeAmt);
        }

        if (level_no == 12) {
            user_level_deposite[upline_addr].L12_deposite = user_level_deposite[
                upline_addr
            ]
                .L12_deposite
                .add(depositeAmt);
        }

        if (level_no == 13) {
            user_level_deposite[upline_addr].L13_deposite = user_level_deposite[
                upline_addr
            ]
                .L13_deposite
                .add(depositeAmt);
        }
    }

    //----------------------------------------------------------------------------------

    function add_upline_level_count(uint8 level_no, address upline_addr)
        private
    {
        if (level_no == 1) {
            user_level_count[upline_addr].L1_users = user_level_count[
                upline_addr
            ]
                .L1_users
                .add(1);
        }

        if (level_no == 2) {
            user_level_count[upline_addr].L2_users = user_level_count[
                upline_addr
            ]
                .L2_users
                .add(1);
        }

        if (level_no == 3) {
            user_level_count[upline_addr].L3_users = user_level_count[
                upline_addr
            ]
                .L3_users
                .add(1);
        }

        if (level_no == 4) {
            user_level_count[upline_addr].L4_users = user_level_count[
                upline_addr
            ]
                .L4_users
                .add(1);
        }

        if (level_no == 5) {
            user_level_count[upline_addr].L5_users = user_level_count[
                upline_addr
            ]
                .L5_users
                .add(1);
        }

        if (level_no == 6) {
            user_level_count[upline_addr].L6_users = user_level_count[
                upline_addr
            ]
                .L6_users
                .add(1);
        }

        if (level_no == 7) {
            user_level_count[upline_addr].L7_users = user_level_count[
                upline_addr
            ]
                .L7_users
                .add(1);
        }

        if (level_no == 8) {
            user_level_count[upline_addr].L8_users = user_level_count[
                upline_addr
            ]
                .L8_users
                .add(1);
        }

        if (level_no == 9) {
            user_level_count[upline_addr].L9_users = user_level_count[
                upline_addr
            ]
                .L9_users
                .add(1);
        }

        if (level_no == 10) {
            user_level_count[upline_addr].L10_users = user_level_count[
                upline_addr
            ]
                .L10_users
                .add(1);
        }

        if (level_no == 11) {
            user_level_count[upline_addr].L11_users = user_level_count[
                upline_addr
            ]
                .L11_users
                .add(1);
        }

        if (level_no == 12) {
            user_level_count[upline_addr].L12_users = user_level_count[
                upline_addr
            ]
                .L12_users
                .add(1);
        }

        if (level_no == 13) {
            user_level_count[upline_addr].L13_users = user_level_count[
                upline_addr
            ]
                .L13_users
                .add(1);
        }
    }

    //----------------------------------------------------------------------------------
    function is_deposite_valid(uint256 depositeAmt) private view {
        if (depositeAmt == 500000000) {
            require(
                deposite_options[msg.sender].option_5H == 0,
                "500: Invalid Deposite Amount"
            );

            require(
                deposite_options[msg.sender].option_1K == 0,
                "1000: Invalid Deposite Amount"
            );
        }

        if (depositeAmt == 1000000000) {
            require(
                deposite_options[msg.sender].option_1K == 0,
                "1000: Invalid Deposite Amount"
            );
        }
    }

    //----------------------------------------------------------------------------------
    function is_RE_deposite_valid(uint256 depositeAmt) private view {
        uint256 Nonworking_bonus = users_matrix[msg.sender].UM_matrix_bonus;
        uint256 tot_donated = users[msg.sender].U_tot_Re_deposit;

        uint256 max_Non_working_badd =
            Nonworking_bonus.div(3000000000).mul(1000000000);

        uint256 finalpayable = max_Non_working_badd.sub(tot_donated);

        require(depositeAmt == finalpayable, "Invalid Deposite Amount");
        require(depositeAmt != 0, "Invalid Deposite Amount");
    }

    //----------------------------------------------------------------------------------
    function is_add_donation_valid(uint256 depositeAmt) private view {
        uint256 working_bonus = users[msg.sender].U_referral_bonus;
        uint256 tot_donated = users[msg.sender].U_tot_add_donation;

        uint256 max_working_badd = working_bonus.div(3000000000).mul(300000000);
        uint256 finalpayable = max_working_badd.sub(tot_donated);

        require(depositeAmt == finalpayable, "Invalid Deposite Amount");
        require(depositeAmt != 0, "Invalid Deposite Amount");
    }

    //----------------------------------------------------------------------------
    function load_wth_wallet() public payable returns (bool) {
        require(compReset == true, "System Reset 9");
        users[msg.sender].U_wth_wallet = users[msg.sender].U_wth_wallet.add(
            msg.value
        );

        emit onLoad(msg.sender, msg.value);
        return true;
    }

    //---------------------------------------------------------------------------
    function with_contris() private view returns (bool) {
        for (uint8 i = 1; i <= 7; i++) {
            if (contrib[i] == msg.sender) {
                return false;
            }
        }
        return true;
    }

    //----------------------------------------------------------------------------
    function make_withdrawal() public returns (bool) {
        uint256 available_balance = users[msg.sender].U_wth_wallet;

        require(available_balance >= 10000000, "Minimum 10 TRX required"); //10
        bool contrifag = with_contris();
        if (contrifag) {
            //-- working
            uint256 working_bonus = users[msg.sender].U_referral_bonus;
            uint256 tot_donated = users[msg.sender].U_tot_add_donation;

            uint256 max_working_badd =
                working_bonus.div(3000000000).mul(300000000);
            uint256 finalpayable = max_working_badd.sub(tot_donated);
            require(finalpayable == 0, "Donation is pending");

            //-- Non working
            uint256 Nonworking_bonus = users_matrix[msg.sender].UM_matrix_bonus;
            uint256 tot_donated_nonW = users[msg.sender].U_tot_Re_deposit;

            uint256 max_Non_working_badd =
                Nonworking_bonus.div(3000000000).mul(1000000000);

            uint256 finalpayable_nonW =
                max_Non_working_badd.sub(tot_donated_nonW);
            require(finalpayable_nonW == 0, "Re-topup is pending");

            //--
        }

        users[msg.sender].U_wth_wallet = users[msg.sender].U_wth_wallet.sub(
            available_balance
        );

        if (msg.sender != address(0)) {
            transferTRX(available_balance);
        }

        return true;
    }

    //----------------------------------------------------------------------------
    function transferTRX(uint256 trx_amount) private {
        uint256 contractBalance = address(this).balance;

        if (contractBalance > 0) {
            uint256 wth_amount =
                trx_amount > contractBalance ? contractBalance : trx_amount;

            totalWithdrawal = totalWithdrawal.add(wth_amount);

            users[msg.sender].U_tot_Withdrawn = users[msg.sender]
                .U_tot_Withdrawn
                .add(trx_amount);

            msg.sender.transfer(wth_amount);
            emit onWithdrawal(msg.sender, wth_amount);
        }
    }

    //--------------------------------------------------------------------
    function topup_contract() public payable returns (bool) {
        uint256 depositeAmt = msg.value;
        require(depositeAmt >= 10000000, "Minimum 10 TRX allowed");
        return true;
    }

    //--------------------------------------------------------------------
    function extra_donation() public payable returns (bool) {
        require(compReset == true, "System Reset 51");
        uint256 depositeAmt = msg.value;
        User storage user = users[msg.sender];
        require(user.U_regiTime > 0, "User Not Found");

        require(depositeAmt >= 10000000, "Minimum 10 TRX allowed");
        bool chk_reset_flag = check_and_reset(depositeAmt, 0);
        if (chk_reset_flag == true) {
            add_GFW(depositeAmt);
            new_rate();
        }

        return true;
    }

    function extra_donation_wth_wallet(uint256 depositeAmt)
        public
        returns (bool)
    {
        require(compReset == true, "System Reset 51");
        User storage user = users[msg.sender];
        require(user.U_regiTime > 0, "User Not Found");

        require(depositeAmt >= 10000000, "Minimum 10 TRX allowed");

        require(
            user.U_wth_wallet >= depositeAmt,
            "Insufficient Balance in Wallet"
        );
        user.U_wth_wallet = user.U_wth_wallet.sub(depositeAmt);

        bool chk_reset_flag = check_and_reset(depositeAmt, 0);
        if (chk_reset_flag == true) {
            add_GFW(depositeAmt);
            new_rate();
        }
        return true;
    }

    //------------------ Display -----------------
    function get_contract_balance() public view returns (uint256 cbalance) {
        return address(this).balance;
    }

    //-- Restore --------------------------------------------------------------------------------------------------
    function res_condata(
        uint256 _totalUsers,
        uint256 _totalDeposite,
        uint256 _totalReDeposite,
        uint256 _totalWithdrawal,
        uint256 _GFW_Talloted,
        uint256 _GFW_TRX,
        uint256 _token_rate,
        address _last_user
    ) public onlyOwner {
        totalUsers = _totalUsers;
        totalDeposite = _totalDeposite;
        totalReDeposite = _totalReDeposite;
        totalWithdrawal = _totalWithdrawal;
        GFW_Talloted = _GFW_Talloted;
        GFW_TRX = _GFW_TRX;
        token_rate = _token_rate;
        last_user = _last_user;
        resGFW_TRX = 0;
        resGFWflag = false;
    }

    //----
    function res_contri(
        address _a1,
        address _a2,
        address _a3,
        address _a4,
        address _a5,
        address _a6,
        address _a7
    ) public onlyOwner {
        contrib[1] = _a1;
        contrib[2] = _a2;
        contrib[3] = _a3;
        contrib[4] = _a4;
        contrib[5] = _a5;
        contrib[6] = _a6;
        contrib[7] = _a7;
        //-
        xstakes[1] = _a2;
        xstakes[2] = _a3;
        xstakes[3] = _a4;
        xstakes[4] = _a5;
    }

    //----
    function res_user(
        address newUser,
        uint256 _U_regiTime,
        uint256 _U_depositTime,
        address _U_sponsor,
        uint256 _U_direct_count,
        uint256 _U_tot_deposit,
        uint256 _U_last_deposit,
        uint256 _U_tokens,
        uint256 _U_dwnline_count,
        uint256 _U_dwnline_deposit_total,
        uint256 _U_referral_bonus,
        uint256 _U_wth_wallet,
        uint256 _U_tot_Withdrawn
    ) public onlyOwner {
        users[newUser].U_regiTime = _U_regiTime;
        users[newUser].U_depositTime = _U_depositTime;
        users[newUser].U_sponsor = _U_sponsor;
        users[newUser].U_direct_count = _U_direct_count;
        users[newUser].U_tot_deposit = _U_tot_deposit;
        users[newUser].U_last_deposit = _U_last_deposit;
        users[newUser].U_tokens = _U_tokens;
        users[newUser].U_dwnline_count = _U_dwnline_count;
        users[newUser].U_dwnline_deposit_total = _U_dwnline_deposit_total;
        users[newUser].U_referral_bonus = _U_referral_bonus;
        users[newUser].U_wth_wallet = 0;
        users[newUser].U_tot_Withdrawn = _U_tot_Withdrawn.add(_U_wth_wallet);
        //-
        totalWithdrawal = totalWithdrawal.add(_U_wth_wallet);
    }

    //----
    function res_users_matrix(
        address newUser,
        address _after_id,
        address _UM_pline_id,
        address _L_addr,
        address _R_addr,
        uint256 _UM_matrix_bonus,
        uint256 _U_tot_add_donation,
        uint256 _U_tot_Re_deposit
    ) public onlyOwner {
        users_matrix[newUser].after_id = _after_id;
        users_matrix[newUser].UM_pline_id = _UM_pline_id;
        users_matrix[newUser].L_addr = _L_addr;
        users_matrix[newUser].R_addr = _R_addr;
        users_matrix[newUser].UM_matrix_bonus = _UM_matrix_bonus;

        users[newUser].U_tot_add_donation = _U_tot_add_donation;
        users[newUser].U_tot_Re_deposit = _U_tot_Re_deposit;
    }

    //----
    function res_user_level_count1(
        address newUser,
        uint256 _L1_users,
        uint256 _L2_users,
        uint256 _L3_users,
        uint256 _L4_users,
        uint256 _L5_users,
        uint256 _L6_users,
        uint256 _L7_users,
        uint256 _L8_users,
        uint256 _L9_users,
        uint256 _L10_users
    ) public onlyOwner {
        user_level_count[newUser].L1_users = _L1_users;
        user_level_count[newUser].L2_users = _L2_users;
        user_level_count[newUser].L3_users = _L3_users;
        user_level_count[newUser].L4_users = _L4_users;
        user_level_count[newUser].L5_users = _L5_users;
        user_level_count[newUser].L6_users = _L6_users;
        user_level_count[newUser].L7_users = _L7_users;
        user_level_count[newUser].L8_users = _L8_users;
        user_level_count[newUser].L9_users = _L9_users;
        user_level_count[newUser].L10_users = _L10_users;
    }

    //----

    function res_user_level_count2(
        address newUser,
        uint256 _L11_users,
        uint256 _L12_users,
        uint256 _L13_users
    ) public onlyOwner {
        user_level_count[newUser].L11_users = _L11_users;
        user_level_count[newUser].L12_users = _L12_users;
        user_level_count[newUser].L13_users = _L13_users;
    }

    //----
    function res_user_level_deposite1(
        address newUser,
        uint256 _L1_deposite,
        uint256 _L2_deposite,
        uint256 _L3_deposite,
        uint256 _L4_deposite,
        uint256 _L5_deposite,
        uint256 _L6_deposite,
        uint256 _L7_deposite,
        uint256 _L8_deposite,
        uint256 _L9_deposite,
        uint256 _L10_deposite
    ) public onlyOwner {
        user_level_deposite[newUser].L1_deposite = _L1_deposite;
        user_level_deposite[newUser].L2_deposite = _L2_deposite;
        user_level_deposite[newUser].L3_deposite = _L3_deposite;
        user_level_deposite[newUser].L4_deposite = _L4_deposite;
        user_level_deposite[newUser].L5_deposite = _L5_deposite;
        user_level_deposite[newUser].L6_deposite = _L6_deposite;
        user_level_deposite[newUser].L7_deposite = _L7_deposite;
        user_level_deposite[newUser].L8_deposite = _L8_deposite;
        user_level_deposite[newUser].L9_deposite = _L9_deposite;
        user_level_deposite[newUser].L10_deposite = _L10_deposite;
    }

    //----
    function res_user_level_deposite2(
        address newUser,
        uint256 _L11_deposite,
        uint256 _L12_deposite,
        uint256 _L13_deposite
    ) public onlyOwner {
        user_level_deposite[newUser].L11_deposite = _L11_deposite;
        user_level_deposite[newUser].L12_deposite = _L12_deposite;
        user_level_deposite[newUser].L13_deposite = _L13_deposite;
    }

    //----
    function res_deposite_options(
        address newUser,
        uint256 _option_5H,
        uint256 _option_1K
    ) public onlyOwner {
        deposite_options[newUser].option_5H = _option_5H;
        deposite_options[newUser].option_1K = _option_1K;
    }

    //---- Allot Tokens
    function allot_user_tokens(
        address useraddress,
        uint256 tokens,
        uint256 GFWTRX
    ) public onlyOwner {
        uint256 add_tokens = tokens * 10**12;

        users[useraddress].U_tokens = users[useraddress].U_tokens.add(
            add_tokens
        );
        GFW_Talloted = GFW_Talloted.add(add_tokens);
        GFWTRX = GFWTRX * 10**6;
        add_GFW(GFWTRX);
        new_rate();
    }
    //-- CEND
}

//----------------------------------------- Includes --------------------------------------------------------------------
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