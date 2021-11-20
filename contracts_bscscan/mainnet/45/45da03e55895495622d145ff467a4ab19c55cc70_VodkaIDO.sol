// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import './StakingB.sol';
import './StakingB_OLD.sol';

contract VodkaIDO is Ownable {
    Staking_OLD public STK_OLD;
    Staking public STK;
    IERC20 public BUSD;
    IERC20 public TKN;

    uint32 public constant VESTING_FREEZE = 360 days;
    uint32 public constant VESTING_PERIOD = 360 days;
    uint32 public constant REGISTRATION_DATE = 1637496000;
    uint32 public constant REST_DATE = 1637506800;
    uint32 public constant DRAW_DATE = 1637514000;
    uint32 public constant FILLED_DATE = REGISTRATION_DATE + VESTING_FREEZE + VESTING_PERIOD;
    bool public DRAW_DONE = false;
    uint256 public constant PLACES = 50;
    uint256 public constant BUSD_AMOUNT = 1000 ether;
    uint256 public constant TKN_AMOUNT = 10_000_000 ether;
    uint256 public constant TOTAL_BUSD_AMOUNT = BUSD_AMOUNT * PLACES;
    uint256 public constant TOTAL_TKN_AMOUNT = TKN_AMOUNT * PLACES;
    uint256 public CLAIMED;
    uint256 public constant STAKED_PER_TICKET = 100 ether;

    address[] public participants;
    address[] public list;
    struct User {
        bool hasRegistered;
        uint256 claimed;
        bool isWinner;
        uint256 ticketCount;
        uint256[3] refCumulativeRewards;
        uint256[3] refCumulativeParticipants;
    }
    mapping(address => User) public users;

    // REF PROGRAM
    bool public refRewardsActive = true;
    uint256[3] public refererShares = [10, 5, 3];
    event RefRewardDistributed(
        address indexed referer,
        address indexed staker,
        uint8 indexed level,
        uint256 amount,
        uint256 timestamp
    );

    // Service variables
    bool public EMERGENCY_ALLOWED = true; // For the case if draw() function turns out to be a problem for >1k users. If so, we will move users (and tokens) to a new, valid contract

    event DrawFinished(bool finished);

    constructor(
        Staking staking,
        Staking_OLD staking_old,
        IERC20 busd,
        IERC20 token
    ) {
        STK = staking;
        STK_OLD = staking_old;
        BUSD = busd;
        TKN = token;
    }

    // USER ACTIONS

    function register() public {
        require(block.timestamp >= REGISTRATION_DATE, 'registration not open yet');
        require(block.timestamp < REST_DATE, 'registration is closed already');
        User memory user = users[msg.sender];
        require(!user.hasRegistered, 'you have already registered');
        uint256 tickets = seeTickets(msg.sender);
        require(tickets > 0, 'you have no stakes that will be still active at draw date');
        BUSD.transferFrom(msg.sender, address(this), BUSD_AMOUNT);
        participants.push(msg.sender);
        for (uint256 i = 0; i < tickets; i++) {
            list.push(msg.sender);
        }
        user.hasRegistered = true;
        user.ticketCount = tickets;
        _distributeRefParticipants(msg.sender);
    }

    function claim() public {
        require(DRAW_DONE, 'draw not done yet');
        User memory user = users[msg.sender];
        require(user.hasRegistered, 'you were not participating');
        require(user.claimed < TKN_AMOUNT, 'you have claimed already');
        if (user.isWinner) {
            uint256 amountToClaim = getActualClaimable(msg.sender);
            require(CLAIMED + amountToClaim <= TOTAL_TKN_AMOUNT, 'whole reserve has already been claimed');
            TKN.transfer(msg.sender, amountToClaim);
            user.claimed += amountToClaim;
            _distributeRefRewards(BUSD_AMOUNT, msg.sender);
        } else {
            BUSD.transfer(msg.sender, BUSD_AMOUNT);
            user.claimed = 1; // Unique value to distinct users that has claimed his BUSD back
        }
    }

    // INTERNAL

    function _generateRandom(uint256 range, uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt))) % range;
    }

    function _removeFromList(address who, uint256 ticketCount) internal {
        for (uint256 i = 0; i < list.length && ticketCount > 0; i++) {
            if (list[list.length - i - 1] == who) {
                list[list.length - i - 1] = list[list.length];
                list.pop();
                ticketCount--;
            }
        }
    }

    // REF PROGRAM

    function _distributeRefParticipants(address staker) internal {
        address referer = staker;
        for (uint8 i = 0; i < 3; i++) {
            referer = STK.refererOf(referer);
            if (referer == address(0)) {
                break;
            }
            users[referer].refCumulativeParticipants[i]++;
        }
    }

    function _distributeRefRewards(uint256 amount, address staker) internal {
        if (!refRewardsActive) return;
        uint8 distributed;
        address referer = staker;
        for (uint8 i = 0; i < 10 && distributed < 3; i++) {
            referer = STK.refererOf(referer);
            if (referer == address(0)) {
                break;
            }
            if (STK.myPendingStakesCount(referer) == 0) {
                continue;
            }
            uint256 refReward = (amount * refererShares[distributed]) / 100;
            BUSD.transfer(referer, refReward);
            emit RefRewardDistributed(referer, staker, distributed, refReward, block.timestamp);
            users[referer].refCumulativeRewards[distributed] += refReward;
            distributed++;
        }
    }

    // OWNER ACTIONS

    uint256 public nextDrawIndex;
    function draw(uint256 gasLimit) public restricted {
        require(block.timestamp >= DRAW_DATE, 'draw not allowed yet');
        require(!DRAW_DONE, 'draw already done');
        if (nextDrawIndex == 0 && participants.length <= PLACES) {
            for (uint256 i = 0; i < participants.length; i++) {
                users[participants[i]].isWinner = true;
                delete list;
            }
        } else {
            uint256 gasUsed;
            uint256 gasLeft = gasleft();
            for (uint256 i = nextDrawIndex; i < PLACES; i++) {
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
                if (gasUsed > gasLimit) {
                    nextDrawIndex = i;
                    emit DrawFinished(false);
                    return;
                }
                address winner = list[_generateRandom(list.length, i)];
                users[winner].isWinner = true;
                _removeFromList(winner, users[winner].ticketCount);
            }
        }
        DRAW_DONE = true;
        emit DrawFinished(true);
    }

    function take(IERC20 token, uint256 amount) public restricted {
        require(
            (block.timestamp >= (DRAW_DATE + VESTING_PERIOD)) || EMERGENCY_ALLOWED,
            'Vesting period must finish first'
        );
        token.transfer(msg.sender, amount > 0 ? amount : token.balanceOf(address(this)));
    }

    // SETTERS

    function disallowEmergency() external restricted {
        EMERGENCY_ALLOWED = false;
    }

    function setRefRewardsActive(bool value) external restricted {
        refRewardsActive = value;
    }

    // GETTERS

    function seeTickets(address who) public view returns (uint256 t) {
        User memory user = users[who];
        if (user.hasRegistered) {
            return user.ticketCount;
        }
        (Staking.Stake[] memory stakes, ) = STK.myStakes(who);
        for (uint256 i = 0; i < stakes.length; i++) {
            if (stakes[i].finalTimestamp >= DRAW_DATE) {
                t += stakes[i].amount / STAKED_PER_TICKET;
            }
        }
        try this.seeTickets_OLD(who) returns (uint256 t_OLD) {
            t += t_OLD;
        } catch {}
    }

    function seeTickets_OLD(address who) public view returns (uint256 t) {
        (Staking_OLD.Stake[] memory stakes, ) = STK_OLD.myStakes(who);
        uint8[3] memory rates_OLD = [106, 121, 140];
        uint24[3] memory periods_OLD = [30 days, 90 days, 150 days];
        for (uint256 i = 0; i < stakes.length; i++) {
            Staking_OLD.Stake memory stake = stakes[i];
            if (stake.timestamp + periods_OLD[stake.class] >= DRAW_DATE) {
                t += ((stake.finalAmount * 100) / rates_OLD[stake.class]) / STAKED_PER_TICKET;
            }
        }
    }

    function getAbsoluteClaimable(address who) public view returns (uint256 amount) {
        if (!users[who].isWinner) {
            return 0;
        }
        if (block.timestamp < DRAW_DATE + VESTING_FREEZE) {
            return 0;
        } else if (block.timestamp <= FILLED_DATE) {
            uint256 timePassed = block.timestamp - (DRAW_DATE + VESTING_FREEZE);
            return (TKN_AMOUNT * timePassed) / VESTING_PERIOD;
        } else {
            return TKN_AMOUNT;
        }
    }

    function getActualClaimable(address who) public view returns (uint256 amount) {
        if (!users[who].isWinner) {
            return 0;
        }
        return getAbsoluteClaimable(who) - users[who].claimed;
    }

    function getParticipantsList()
        public
        view
        returns (
            address[] memory user,
            bool[] memory won,
            uint256[] memory claimed
        )
    {
        user = participants;
        won = new bool[](participants.length);
        claimed = new uint256[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            won[i] = users[participants[i]].isWinner;
            claimed[i] = users[participants[i]].claimed;
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

    function getRefCumulativeRewards(address who) public view returns (uint256[3] memory rewards) {
        rewards = users[who].refCumulativeRewards;
    }

    function infoBundle(address who)
        public
        view
        returns (
            User memory user,
            uint256 claimed,
            uint256 absolute,
            bool draw_done,
            uint256 busd_all,
            uint256 busd_bal,
            uint256 tkn_bal,
            uint256 tickets
        )
    {
        user = users[who];
        claimed = CLAIMED;
        absolute = getAbsoluteClaimable(who);
        draw_done = DRAW_DONE;
        busd_all = BUSD.allowance(who, address(this));
        busd_bal = BUSD.balanceOf(who);
        tkn_bal = TKN.balanceOf(who);
        tickets = seeTickets(who);
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
}