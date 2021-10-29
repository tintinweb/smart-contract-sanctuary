// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import './StakingB.sol';
import './StakingB_OLD.sol';

contract USDRIDO is Ownable {
    Staking_OLD public STK_OLD;
    Staking public STK;
    IERC20 public BUSD;
    IERC20 public TKN;

    uint32 public REGISTRATION_DATE = 1635498000;
    uint32 public REST_DATE = 1635699600;
    uint32 public DRAW_DATE = 1635782400;
    uint32 public FILLED_DATE = 1641052800;
    bool public DRAW_DONE = false;
    uint256 public constant PLACES = 1000;
    uint256 public constant BUSD_AMOUNT = 200e18;
    uint256 public constant TKN_AMOUNT = 250e6;
    uint256 public constant TOTAL_BUSD_AMOUNT = 200_000e18;
    uint256 public constant TOTAL_TKN_AMOUNT = 250_000e6;
    uint256 public CLAIMED;
    uint256 public constant STAKED_PER_TICKET = 100e18;

    address[] public participants;
    address[] public list;
    mapping(address => bool) public hasRegistered;
    mapping(address => bool) public hasClaimed;
    mapping(address => bool) public isWinner;
    mapping(address => uint256) public ticketCount;

    uint256[3] public _refererShares = [10, 5, 3];
    mapping(address => uint256[3]) public refCumulativeRewards;
    mapping(address => uint256[3]) public refCumulativeParticipants;
    event RefRewardDistributed(address indexed referer, address indexed staker, uint8 indexed level, uint256 amount, uint256 timestamp);

    // Service variables
    uint256 public nextDrawIndex;
    bool public EMERGENCY_ALLOWED = true; // For the case if draw() function turns out to be a problem for >1k users. If so, we will move users (and tokens) to a new, valid contract

    event DrawFinished(bool finished);

    function seeTickets(address _user) public view returns (uint256 t) {
        if (hasRegistered[_user]) return ticketCount[_user];
        (Staking.Stake[] memory _s, ) = STK.myStakes(_user);
        for (uint256 i = 0; i < _s.length; i++) {
            if (_s[i].finalTimestamp >= DRAW_DATE) t += _s[i].amount / STAKED_PER_TICKET;
        }
        try this.seeTickets_OLD(_user) returns (uint256 t_OLD) {
            t += t_OLD;
        } catch {}
    }

    function seeTickets_OLD(address _user) public view returns (uint256 t) {
        (Staking_OLD.Stake[] memory _s, ) = STK_OLD.myStakes(_user);
        uint8[3] memory rates_OLD = [106, 121, 140];
        uint24[3] memory periods_OLD = [30 days, 90 days, 150 days];
        for (uint256 i = 0; i < _s.length; i++) {
            if (_s[i].timestamp + periods_OLD[_s[i].class] >= DRAW_DATE) t += ((_s[i].finalAmount * 100) / rates_OLD[_s[i].class]) / STAKED_PER_TICKET;
        }
    }

    function register() public {
        require(block.timestamp >= REGISTRATION_DATE, 'registration not open yet');
        require(block.timestamp < REST_DATE, 'registration is closed already');
        require(!hasRegistered[msg.sender], 'you have already registered');
        uint256 _tickets = seeTickets(msg.sender);
        require(_tickets > 0, 'you have no stakes that will be still active at draw date');
        BUSD.transferFrom(msg.sender, address(this), BUSD_AMOUNT);
        participants.push(msg.sender);
        for (uint256 i = 0; i < _tickets; i++) list.push(msg.sender);
        hasRegistered[msg.sender] = true;
        ticketCount[msg.sender] = _tickets;
        _distributeRefParticipants(msg.sender);
    }

    function draw(uint256 _gasLimit) public restricted {
        require(block.timestamp >= DRAW_DATE, 'draw not allowed yet');
        require(!DRAW_DONE, 'draw already done');
        if (nextDrawIndex == 0 && participants.length <= PLACES) for (uint256 i = 0; i < participants.length; i++) {
            isWinner[participants[i]] = true;
            delete list;
        }
        else {
            uint256 gasUsed;
            uint256 gasLeft = gasleft();
            for (uint256 i = nextDrawIndex; i < PLACES; i++) {
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
                if (gasUsed > _gasLimit) {
                    nextDrawIndex = i;
                    emit DrawFinished(false);
                    return;
                }
                address _winner = list[_generateRandom(list.length, i)];
                isWinner[_winner] = true;
                _removeFromList(_winner, ticketCount[_winner]);
            }
        }
        DRAW_DONE = true;
        emit DrawFinished(true);
    }

    function _generateRandom(uint256 range, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % range;
    }

    function _removeFromList(address _winner, uint256 _ticketCount) internal {
        for (uint256 i = 0; i < list.length && _ticketCount > 0; i++) {
            if (list[list.length - i - 1] == _winner) {
                list[list.length - i - 1] = list[list.length];
                list.pop();
                _ticketCount--;
            }
        }
    }

    function claim() public {
        require(DRAW_DONE, 'draw not done yet');
        require(hasRegistered[msg.sender], 'you were not participating');
        require(!hasClaimed[msg.sender], 'you have claimed already');
        require(block.timestamp < FILLED_DATE, 'too late');
        if (isWinner[msg.sender]) {
            require(CLAIMED + TKN_AMOUNT <= TOTAL_TKN_AMOUNT, 'whole reserve has already been claimed');
            TKN.transfer(msg.sender, TKN_AMOUNT);
            _distributeRefRewards(BUSD_AMOUNT, msg.sender);
            CLAIMED += TKN_AMOUNT;
        } else {
            BUSD.transfer(msg.sender, BUSD_AMOUNT);
        }
        hasClaimed[msg.sender] = true;
    }

    function _distributeRefParticipants(address _staker) internal {
        address _referer = _staker;
        for (uint8 i = 0; i < 3; i++) {
            _referer = STK.refererOf(_referer);
            if (_referer == address(0)) break;
            refCumulativeParticipants[_referer][i]++;
        }
    }

    function _distributeRefRewards(uint256 _amount, address _staker) internal {
        uint8 _distributed;
        address _referer = _staker;
        for (uint8 i = 0; i < 10 && _distributed < 3; i++) {
            _referer = STK.refererOf(_referer);
            if (_referer == address(0)) break;
            if (STK.myPendingStakesCount(_referer) == 0) continue;
            uint256 _refReward = (_amount * _refererShares[_distributed]) / 100;
            BUSD.transfer(_referer, _refReward);
            emit RefRewardDistributed(_referer, _staker, _distributed, _refReward, block.timestamp);
            refCumulativeRewards[_referer][_distributed] += _refReward;
            _distributed++;
        }
    }

    function disallowEmergency() external restricted {
        EMERGENCY_ALLOWED = false;
    }

    function take(IERC20 _TKN, uint256 _amount) public restricted {
        require(block.timestamp >= FILLED_DATE || EMERGENCY_ALLOWED, '1 week must pass since the draw');
        _TKN.transfer(msg.sender, _amount > 0 ? _amount : _TKN.balanceOf(address(this)));
    }

    function getParticipantsList()
        public
        view
        returns (
            address[] memory user,
            bool[] memory won,
            bool[] memory claimed
        )
    {
        user = participants;
        won = new bool[](participants.length);
        claimed = new bool[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            won[i] = isWinner[participants[i]];
            claimed[i] = hasClaimed[participants[i]];
        }
    }

    function getTicketsList() public view returns (address[] memory tickets) {
        tickets = list;
    }

    function getParticipantsLength() public view returns (uint256 length) {
        length = participants.length;
    }

    function getListLength() public view returns (uint256 length) {
        length = list.length;
    }

    function getRefCumulativeRewards(address _user) public view returns (uint256[3] memory rewards) {
        rewards = refCumulativeRewards[_user];
    }

    function infoBundle(address _user)
        public
        view
        returns (
            uint256 claimed,
            bool draw_done,
            uint256 busd_all,
            uint256 busd_bal,
            uint256 tkn_bal,
            bool uRegistered,
            bool uWinner,
            bool uClaimed,
            uint256 tickets
        )
    {
        claimed = CLAIMED;
        draw_done = DRAW_DONE;
        busd_all = BUSD.allowance(_user, address(this));
        busd_bal = BUSD.balanceOf(_user);
        tkn_bal = TKN.balanceOf(_user);
        uRegistered = hasRegistered[_user];
        uWinner = isWinner[_user];
        uClaimed = hasClaimed[_user];
        tickets = seeTickets(_user);
    }

    function infoBundleStd()
        public
        view
        returns (
            uint32[] memory dates,
            address busd,
            address tkn,
            string memory tkn_name,
            string memory tkn_symbol,
            uint8 tkn_decimals,
            uint256 places,
            uint256 busd_in,
            uint256 tkn_out,
            uint256 busd_in_total,
            uint256 tkn_out_total
        )
    {
        dates = new uint32[](4);
        dates[0] = REGISTRATION_DATE;
        dates[1] = REST_DATE;
        dates[2] = DRAW_DATE;
        dates[3] = FILLED_DATE;
        busd = address(BUSD);
        tkn = address(TKN);
        tkn_name = TKN.name();
        tkn_symbol = TKN.symbol();
        tkn_decimals = TKN.decimals();
        places = PLACES;
        busd_in = BUSD_AMOUNT;
        tkn_out = TKN_AMOUNT;
        busd_in_total = TOTAL_BUSD_AMOUNT;
        tkn_out_total = TOTAL_TKN_AMOUNT;
    }

    constructor(
        Staking _STK,
        Staking_OLD _STK_OLD,
        IERC20 _BUSD,
        IERC20 _TKN
    ) {
        STK = _STK;
        STK_OLD = _STK_OLD;
        BUSD = _BUSD;
        TKN = _TKN;
    }
}