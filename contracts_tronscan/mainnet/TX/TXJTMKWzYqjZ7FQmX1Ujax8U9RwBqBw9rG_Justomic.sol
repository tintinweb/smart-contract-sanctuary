//SourceUnit: JSTStake.sol

pragma solidity >=0.4.25 <0.7.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function mintTo(address account, uint256 amount) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Justomic {
    IERC20 jst;
    IERC20 jtm;
    uint256 feeWithdraw = 3e19;
    address devWallet;
    address jtmFund;
    address owner;

    struct Today {
        uint256 deposit;
        address[4] topReference;
    }
    uint256 claimed = now / 1 days;
    mapping(uint256 => Today) todayStatis;
    mapping(uint256 => mapping(address => uint256)) public myTodayReference;
    uint256[4] percentTop = [40, 30, 20, 10];
    uint256[4] maxDeposit = [1e22, 2e22, 5e22, 1e23];

    struct User {
        uint256 totalInvest;
        address parent;
        uint256 refs;
        uint256 matching;
        uint256 poolBonus;
        uint256 depositAmount;
        uint256 depositTime;
        uint256 cycle;
        uint256 payed;
    }
    mapping(address => User) public users;
    mapping(uint256 => uint256[15]) percentRef;
    uint256 _totalStake;
    uint256 _totalPayout;

    constructor(
        address _jst,
        address _jtm,
        address _dev,
        address _jtmFund
    ) public {
        owner = msg.sender;
        devWallet = _dev;
        jtmFund = _jtmFund;
        jst = IERC20(_jst);
        jtm = IERC20(_jtm);
        percentRef[0] = [10, 3, 3, 3, 3, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1];
        percentRef[1] = [12, 4, 4, 4, 4, 3, 3, 3, 2, 2, 2, 1, 1, 1, 1];
        percentRef[2] = [15, 5, 5, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2];
    }

    function getSystemInformation()
        public
        view
        returns (
            uint256 totalStake,
            uint256 totalPayout,
            uint256 remaining,
            uint256 todayStake
        )
    {
        return (
            _totalStake,
            _totalPayout,
            jst.balanceOf(address(this)),
            todayStatis[now / 1 days].deposit
        );
    }

    function getTodayStatistic()
        public
        view
        returns (
            uint256 todayStake,
            address[4] memory todayTop,
            uint256[4] memory todayReference
        )
    {
        uint256 today = now / 1 days;
        todayStake = todayStatis[today].deposit;
        todayTop = todayStatis[today].topReference;
        for (uint256 i = 0; i < 4; i++) {
            todayReference[i] = myTodayReference[today][
                todayStatis[today].topReference[i]
            ];
        }
    }

    function() external payable {}

    function deposit(uint256 _amount, address _ref) external {
        jst.transferFrom(msg.sender, address(this), _amount);
        jst.transfer(devWallet, (_amount * 5) / 100);
        jst.transfer(jtmFund, (_amount * 3) / 100);

        // TODO enable gift JTM
        jtm.mintTo(msg.sender, _amount);
        _totalStake += _amount;
        User storage user = users[msg.sender];
        require(_amount >= user.depositAmount && _amount >= 1e21, "Bad Amount");
        if (user.cycle < 4) {
            require(_amount <= maxDeposit[user.cycle], "Max deposit");
        } else {
            require(_amount <= maxDeposit[3], "Max deposit 2");
        }
        require((user.depositAmount * 12) / 10 <= user.payed, "Deposit active");
        user.cycle++;
        if (user.totalInvest == 0) {
            require(
                users[_ref].totalInvest > 0 || _ref == owner,
                "Must be active sponsor"
            );
            if (msg.sender != owner) {
                user.parent = _ref;
            }
            users[_ref].refs++;
        }
        user.totalInvest += _amount;
        user.depositTime = now;
        user.depositAmount = _amount;
        user.payed = 0;
        user.matching = 0;
        user.poolBonus = 0;
        _addTodayStatis(now / 1 days, _amount, user.parent);
        if (now / 1 days > claimed) {
            _topClaim();
        }
    }

    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "Must be owner");
        feeWithdraw = _fee;
    }

    function withdraw() public {
        uint256 amount = getWithdrawAmount(msg.sender);
        require(amount >= 0, "Must be have");
        if (amount > feeWithdraw) {
            jst.transfer(msg.sender, amount - feeWithdraw);
        }
        User storage user = users[msg.sender];
        user.depositTime = now;
        user.matching = 0;
        user.poolBonus = 0;
        user.payed += amount;
        _totalPayout += amount;
        _payRef(msg.sender, amount);
    }

    function _payRef(address _user, uint256 _amount) private {
        address parent = _user;
        for (uint256 i = 0; i < 15; i++) {
            parent = users[parent].parent;
            if (parent == address(0x0)) break;
            if (users[parent].refs > i) {
                users[parent].matching +=
                    (_amount * percentRef[getUserLevel(parent)][i]) /
                    600;
            }
        }
    }

    function getUserLevel(address _user) public view returns (uint256) {
        if (users[_user].depositAmount >= 5e22) return 2;
        if (users[_user].depositAmount >= 1e22) return 1;
        return 0;
    }

    function getWithdrawAmount(address _user)
        public
        view
        returns (uint256 amount)
    {
        User memory user = users[_user];
        uint256 maxOut = (user.depositAmount * 12) / 10 - user.payed;

        //TODO change to 1 days
        amount =
            user.matching +
            user.poolBonus +
            (((now - user.depositTime) / 1 days) * user.depositAmount) /
            30;
        if (amount > maxOut) {
            amount = maxOut;
        }
    }

    function _addTodayStatis(
        uint256 _today,
        uint256 _amount,
        address _parent
    ) private {
        if (_parent == address(0x0)) return;
        todayStatis[_today].deposit += _amount;
        myTodayReference[_today][_parent] += _amount;
        for (uint8 i = 0; i < 4; i++) {
            if (_parent == todayStatis[_today].topReference[i]) break;
            if (todayStatis[_today].topReference[i] == address(0)) {
                todayStatis[_today].topReference[i] = _parent;
                break;
            }
            if (
                myTodayReference[_today][_parent] >
                myTodayReference[_today][todayStatis[_today].topReference[i]]
            ) {
                for (uint8 j = i + 1; j < 4; j++) {
                    if (todayStatis[_today].topReference[j] == _parent) {
                        for (uint8 k = j; k < 3; k++) {
                            todayStatis[_today].topReference[k] = todayStatis[
                                _today
                            ]
                                .topReference[k + 1];
                        }
                        break;
                    }
                }
                for (uint8 z = 3; z > i; z--) {
                    todayStatis[_today].topReference[z] = todayStatis[_today]
                        .topReference[z - 1];
                }

                todayStatis[_today].topReference[i] = _parent;
                break;
            }
        }
    }

    function _topClaim() private {
        uint256 amount = (todayStatis[claimed].deposit * 2) / 1e5;
        for (uint256 i = 0; i < 4; i++) {
            users[todayStatis[claimed].topReference[i]].poolBonus +=
                amount *
                percentTop[i];
        }
        claimed++;
    }
}