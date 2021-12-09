//SourceUnit: DirectMyDollarTrx.sol

pragma solidity ^0.6.0;

//pragma experimental ABIEncoderV2;

contract MyDollar {
    address payable public wallet1;

    uint256 public decimals = 6;
    uint256 public subscriptionFee = 1600 * (10**decimals); // 165 fix

    struct User {
        uint256 id;
        address addr;
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 direct_referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_structure;
    }

    mapping(address => User) public users;
    address[] public addressIndices;

    uint256[] public cycles;
    uint256[] public ref_bonuses;

    uint256 public owner_total_earn = 0;
    uint256 public total_users = 0;
    uint256 public total_deposited;
    uint256 public levelCommission = 50 * (10**decimals);
    uint256 public directCommission = 30 * (10**decimals);

    event Upline(address indexed addr, address indexed upline);
    event NewSubscription(address indexed addr, uint256 amount);
    event DirectPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event MatchPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event PoolPayout(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event TransferRequest(address indexed addr, uint256 amount);

    constructor(
        address payable _wallet1,
        uint256 _subscriptionFee,
        uint256 _levelCommission,
        uint256 _directCommission,
        uint256 _decimals
    ) public {
        wallet1 = _wallet1;
        subscriptionFee = _subscriptionFee;
        levelCommission = _levelCommission;
        directCommission = _directCommission;
        decimals = _decimals;

        // create root user
        users[wallet1].addr = wallet1;
        users[wallet1].deposit_time = uint40(block.timestamp);
        users[wallet1].total_deposits += subscriptionFee;
        addressIndices.push(wallet1);
        // end create root user

        for (int256 i = 0; i < 30; i++) {
            ref_bonuses.push(levelCommission); // 2.
        }

        // 1600 TRX
        cycles.push(subscriptionFee);

        total_users++;
    }

    function join(address _upline, address _direct) external payable returns(bool) {
        address sender = msg.sender;

        // check upline must be existy otherwise reject
        require((users[_upline].deposit_time > 0), "upline not exist");
        require(_upline != address(0), "without upline can't join");

        uint256 paid = 0;
        // check _direct : if existy so proccess if No skip
        if (_direct != address(0) && users[_direct].deposit_time > 0) {
            // proccess pay _directCommission
            transferFund(payable(_direct), directCommission);
            paid = directCommission;
            users[_direct].direct_bonus += directCommission; 
            users[_direct].payouts += directCommission; 
            if(users[sender].deposit_time == 0){
                // update
                users[_direct].direct_referrals++;
            }
            
            emit DirectPayout(_direct, sender, directCommission);
        }
        // end direct proccess

        require(sender != wallet1, "admin can't join");

        // check if user joined before and try pay new subscript must be allow
        require(
            _getChildCount(_upline) < 2 || users[sender].deposit_time > 0,
            "max direct is full "
        );

        if (users[sender].deposit_time > 0) {
            _upline = users[sender].upline;
        }

        require(msg.value == subscriptionFee, "balance: value wrong");

        _setUpline(sender, _upline);
        paid += _join(sender, subscriptionFee);

        uint256 spends = subscriptionFee - (_refPayout(_upline) + paid);
        
        owner_total_earn += spends;

        transferFund(wallet1, spends);
        
        return(true);
    }

    function _setUpline(address _addr, address _upline) private {
        if (
            users[_addr].upline == address(0) &&
            _upline != _addr &&
            (_addr != wallet1)
        ) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            users[_addr].id = total_users;

            for (uint8 i = 0; i < ref_bonuses.length; i++) {
                if (_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _join(address _addr, uint256 _amount)
        private
        returns (uint256 paid)
    {
        if (users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
        } else {
            // start adding address in array
        users[_addr].addr = _addr;
            addressIndices.push(_addr);
        }

        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;

        emit NewSubscription(_addr, _amount);

        // transfer upline ref_bonuses
        if (users[_addr].upline != address(0)) {
            uint256 bonus = ref_bonuses[0];
            address level1 = users[_addr].upline;
            users[level1].payouts += bonus;
            transferFund(payable(level1), bonus);
            paid = bonus;
        }
    }

    function transferFund(address payable to, uint256 amount) private {
        if (to != address(0)) {
            emit TransferRequest(to, amount);
            to.transfer(amount);
        }
    }

    function _refPayout(address _addr) private returns (uint256 total) {
        address up = users[_addr].upline;

        for (uint8 i = 0; i < ref_bonuses.length - 1; i++) {
            if (up == address(0)) break;

            uint256 bonus = ref_bonuses[i];

            users[up].match_bonus += bonus;

            if (up != address(this) || up != wallet1) {
                users[up].payouts += bonus;
                transferFund(payable(address(up)), bonus);
                total += bonus;
            }
            emit MatchPayout(up, _addr, bonus);

            up = users[up].upline;
        }
    }

    function _getChildCount(address _upline) private returns (uint8 count) {
        address[2][] memory ret = new address[2][](total_users);
        for (uint256 i = 0; i < total_users; i++) {
            if (users[addressIndices[i]].upline == _upline) {
                count++;
            }
        }
        return count;
    }

    function _getUserIndex(address addr) private returns (uint256 index) {
        for (uint256 i = 0; i < total_users; i++) {
            if (addressIndices[i] == addr) {
                index = i;
                break;
            }
        }
        return index;
    }

    /*
      admin Only
      */
    function setCommission(
        uint256 _subscriptionFee,
        uint256 _levelCommission,
        uint256 _directCommission
    ) public returns (bool) {
        require(msg.sender == wallet1, "only owner can set");

        subscriptionFee = _subscriptionFee;
        levelCommission = _levelCommission;
        directCommission = _directCommission;

        for (uint256 i = 0; i < 30; i++) {
            ref_bonuses[i] = levelCommission;
        }
        return true;
    }

    function setOwner(address newOwner) public returns (bool) {
        require(msg.sender == wallet1, "only admin can set");
        wallet1 = payable(newOwner);
        return true;
    }

    /*
        Only external call
    */
    function userInfo(address _addr)
        external
        view
        returns (
            address addr,
            address upline,
            uint40 deposit_time,
            uint256 deposit_amount,
            uint256 payouts,
            uint256 direct_bonus,
            uint256 match_bonus
        )
    {
        return (
            _addr,
            users[_addr].upline,
            users[_addr].deposit_time,
            subscriptionFee,
            users[_addr].payouts,
            users[_addr].direct_bonus,
            users[_addr].match_bonus
        );
    }

    function getAddressIndices() external view returns (address[] memory) {
        return addressIndices;
    }

    function getSubscriptionFee() external view returns (uint256) {
        return subscriptionFee;
    }

    function getAll() public view returns (address[2][] memory) {
        address[2][] memory ret = new address[2][](total_users);
        for (uint256 i = 0; i < total_users; i++) {
            ret[i][0] = users[addressIndices[i]].addr;
            ret[i][1] = users[addressIndices[i]].upline;
        }
        return ret;
    }

    function stages() external view returns (uint256[] memory) {
        uint256[] memory st = new uint256[](ref_bonuses.length);
        for (uint256 i = 0; i < ref_bonuses.length; i++) {
            uint256 s = ref_bonuses[i];
            st[i] = s;
        }
        return st;
    }

    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 referrals,
            uint256 deposits,
            uint256 total_payouts,
            uint256 total_structure
        )
    {
        return (
            users[_addr].referrals,
            users[_addr].total_deposits,
            users[_addr].payouts,
            users[_addr].total_structure
        );
    }

    function contractInfo()
        external
        view
        returns (uint256 _total_users, uint256 _total_deposited,  uint256 _owner_total_earn)
    {
        return (total_users, total_deposited,owner_total_earn);
    }
}