//SourceUnit: IJustSwap.sol

pragma solidity >=0.5.8;

interface IJustSwap {
    function getTrxToTokenInputPrice(uint256 trx_sold)
        external
        view
        returns (uint256);
}


//SourceUnit: Math.sol

pragma solidity >=0.5.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}


//SourceUnit: Ownable.sol

pragma solidity >=0.5.8;

contract Ownable {
    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "CALLER IS NOT OWNER");

        _;
    }

    function changeOwner(address owner) external onlyOwner {
        _owner = owner;
    }
}


//SourceUnit: SafeMath.sol

pragma solidity >=0.5.0;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint a, uint b) internal pure returns (uint z) {
        require(b > 0);
        return a / b;
    }
    
    function mod(uint a, uint b) internal pure returns (uint z) {
        require(b != 0, 'ds-math-mod-overflow');
        return a % b;
    }
}


//SourceUnit: Stake.sol

pragma solidity >=0.5.8;

import "./Math.sol";
import "./SafeMath.sol";


library Stake {
    using SafeMath for uint256;

    struct _stake {
        uint256 value;
        uint256 rate; 
        uint256 dynamic;
        uint256 spread;
        uint256 lastTime;
        uint256 period; 
    }

    struct _receive {
        uint256 dynamic;
        uint256 statics;
        uint256 funds; 
        uint256 clubs; 
        uint256 clubSpread;
        uint256 spread; 
        uint256 total; 
    }

    struct data {
        uint256 outLimit;
        mapping(address => _stake) dict;
        mapping(address => _receive) rece;
        mapping(address => uint256[6][]) stakes; 
    }

    function lastStake(
        data storage p,
        uint256 unix,
        uint256 limit
    ) internal {
        _stake storage stake = p.dict[msg.sender];
        if (stake.lastTime < unix) {
            stake.spread = 0;
        }

        uint256 value = 2e9;
        uint256 size = p.stakes[msg.sender].length;
        if (size > 0) value = p.stakes[msg.sender][size - 1][0];
        require(value <= msg.value, "STAKE VALUE LESS");
        uint256 total = stakeValueOf(p, msg.sender);
        require(total <= limit, "CALLER NOT BE STAKE");
        stake.value = stake.value.add(msg.value);

        if (stake.period == 0) stake.period = block.timestamp;
        p.stakes[msg.sender].push(
            [msg.value, block.timestamp, 0, 0, 0, block.timestamp]
        );
        stake.lastTime = block.timestamp;
    }

    function updateDynamic(
        data storage p,
        address from,
        uint256 value,
        bool spread
    ) internal returns (uint256 already) {
        _stake storage stake = p.dict[from];
        if (stake.period == 0) return already;
        uint256[6][] storage list = p.stakes[from];
        (uint256 _days, uint256 period) = daysOf(p, from);
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i][4] > 0) continue;
            (uint256 reward, bool out) = rewardOf(p, from, i, period, _days);
            if (out) continue;
            uint256 tmax = list[i][0].div(100).mul(p.outLimit);
            uint256 total = reward.add(list[i][2]).add(list[i][3]);
            if (total.add(value) > tmax) {
                uint256 amount = tmax.sub(total);
                value = value.sub(amount);
                already = already.add(amount);
            } else {
                list[i][3] = list[i][3].add(value);
                already = already.add(value);
                break;
            }
        }
        if (!spread) {
            stake.dynamic = stake.dynamic.add(already);
        }
    }

    function updateStake(data storage p) internal returns (uint256 reward) {
        address from = msg.sender;
        uint256[6][] storage list = p.stakes[from];
        (uint256 _days, uint256 period) = daysOf(p, from);
        for (uint256 i = 0; i < list.length; i++) {
            (uint256 value, bool out) = rewardOf(p, from, i, period, _days);
            list[i][4] = out ? p.outLimit.mul(list[i][0]).div(100) : 0;
            list[i][1] = block.timestamp;
            list[i][2] = list[i][2].add(value);
            reward = reward.add(value);
        }
        uint256 rate = rateOf(p, from);
        if (rate == 100) {
            p.dict[from].rate = 100;
        } else {
            p.dict[from].period = period.add(_days.sub(1).mul(1 days));
        }
    }

    function stakeValueOf(data storage p, address from)
        internal
        view
        returns (uint256 value)
    {
        (uint256 _days, uint256 period) = daysOf(p, from);
        uint256[6][] storage list = p.stakes[from];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i][4] > 0) continue;
            (, bool out) = rewardOf(p, from, i, period, _days);
            if (!out) value = value.add(list[i][0]);
        }
    }

    function rewardsOf(data storage p, address from)
        internal
        view
        returns (uint256 reward)
    {
        (uint256 _days, uint256 period) = daysOf(p, from);
        uint256[6][] storage list = p.stakes[from];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i][4] > 0) continue;
            (uint256 value, ) = rewardOf(p, from, i, period, _days);
            reward = reward.add(value);
        }
    }

    function rewardOf(
        data storage p,
        address from,
        uint256 index,
        uint256 period,
        uint256 _days
    ) internal view returns (uint256 reward, bool out) {
        uint256[6] storage list = p.stakes[from][index];
        uint256 smax = list[0].div(100).mul(150);
        if (list[2] >= smax) return (0, true);
        uint256 tmax = list[0].div(100).mul(p.outLimit);
        uint256 unix = list[1];
        uint256 avg = list[0].div(1e4);
        uint256 skip = unix.sub(period).div(1 days);

        uint256 min = Math.min(_days, 16);
        uint256 value = 0;
        if (min > skip) {
            value = min.sub(skip).mul(skip.add(min.sub(1))).mul(avg);
            reward = value.add(min.sub(skip).mul(70).mul(avg));
        }

        if (_days > 16) {
            uint256 real = skip > 16 ? _days.sub(skip) : _days.sub(16);
            reward = reward.add(avg.mul(real.mul(100)));
        }

        uint256 stamp = unix.sub(period).mod(1 days);
        if (stamp > 0) {
            value = Math.min(skip.mul(2).add(70), 100).mul(avg);
            reward = reward.sub(value.div(1 days).mul(stamp));
        }

        stamp = period.add(_days.mul(1 days));
        stamp = stamp.sub(block.timestamp);
        if (stamp > 0) {
            value = _days.sub(1);
            value = value.mul(2).add(70);
            value = Math.min(value, 100).mul(avg);
            reward = reward.sub(value.div(1 days).mul(stamp));
        }

        if (reward.add(list[2]) >= smax) {
            reward = smax.sub(list[2]);
            out = true;
        }
        if (reward.add(list[2]).add(list[3]) >= tmax) {
            reward = tmax.sub(list[3]).sub(list[2]);
            out = true;
        }
    }

    function rateOf(data storage p, address from)
        internal
        view
        returns (uint256)
    {
        uint256 rate = p.dict[from].rate;
        if (rate == 100) return rate;
        (uint256 _days, uint256 period) = daysOf(p, from);
        if (period == 0) return 70;
        return Math.min(_days.sub(1).mul(2).add(70), 100);
    }

    function daysOf(data storage p, address from)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 period = p.dict[from].period;
        uint256 _days = block.timestamp.sub(period).div(1 days);
        if (block.timestamp.sub(period).mod(1 days) >= 0) _days += 1;
        return (_days, period);
    }

    function stakeOf(data storage p, address from)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 size = p.stakes[from].length;
        if (size == 0) {
            return (0, 0);
        }
        return (p.stakes[from][size - 1][0], stakeValueOf(p, from));
    }

    function stakesOf(data storage p, address from)
        internal
        view
        returns (uint256[] memory rets)
    {
        (uint256 _days, uint256 period) = daysOf(p, from);
        uint256[6][] storage list = p.stakes[from];
        rets = new uint256[](list.length * 5); 
        for (uint256 i = 0; i < list.length; i++) {
            uint256 j = i * 5;
            rets[j] = list[i][2];
            rets[j + 1] = list[i][3];
            rets[j + 2] = list[i][0];
            rets[j + 3] = list[i][4];
            rets[j + 4] = list[i][5];
            if (list[i][4] == 0) {
                (uint256 value, ) = rewardOf(p, from, i, period, _days);
                rets[j] = rets[j].add(value);
                rets[j + 3] = p.outLimit.mul(list[i][0]).div(100);
            }
        }
    }
}


//SourceUnit: Wave.sol

pragma solidity >=0.5.8;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./Math.sol";
import "./Stake.sol";
import "./SafeMath.sol";
import "./IJustSwap.sol";


contract WRelationship {
    using SafeMath for uint256;
    using Stake for Stake.data;

    struct Player {
        uint256 club;
        address parent;
        uint256 spread; 
        address[] stakes;
    }

    uint256 public level; 
    uint256 public trxLimit; 
    mapping(address => Player) public players;

    Stake.data _stakes;

    address[] public _rewards;
    address[] public _lastStakes;
    uint256 public spreadRewardStart;
    address[] public spreadRewardList;

    function spreadTop10() external view returns (bytes[] memory) {
        if (block.timestamp.sub(spreadRewardStart) <= 1 days) {
            uint256 size = spreadRewardList.length;
            if (size > 10) size = 10;
            bytes[] memory list = new bytes[](size);
            for (uint256 i = 0; i < size; i++) {
                list[i] = abi.encodePacked(
                    spreadRewardList[i],
                    _stakes.dict[spreadRewardList[i]].spread
                );
            }
            return list;
        }
    }

    function bind(address account) external {
        require(account != address(0), "ACCOUNT IS ZERO");
        Player storage player = players[msg.sender];
        require(player.parent == address(0), "PLAYER HAS PARENT");
        player.parent = account;
        player = players[account];
        player.spread += 1;

        for (uint256 i = 0; player.parent != address(0); i++) {
            require(player.parent != msg.sender, "BIND ERROR");
            player = players[player.parent];
        }

        if (_stakes.dict[msg.sender].value > 0) {
            player = players[msg.sender];
            players[player.parent].stakes.push(msg.sender);
            _updateClubsActive(account);
        }

        emit Bind(msg.sender, account);
    }

    function _playerClub(address account) internal view returns (uint256) {
        return players[account].club - 1;
    }

    function _setPlayerClub(address account, uint256 club) internal {
        require(club >= 0 && club <= 125, "CLUB ID ERR");
        players[account].club = club;
    }

    function _updateLastStake() internal {
        address parent = players[msg.sender].parent;
        if (parent != address(0)) {
            _updateSpreadReward(parent, msg.value);
            if (_stakes.dict[msg.sender].value == 0) {
                players[parent].stakes.push(msg.sender);
                _updateClubsActive(parent);
            }
        }

        uint256 prev = _stakes.dict[msg.sender].lastTime;
        _stakes.lastStake(spreadRewardStart, trxLimit);
        _updateLastStakeTime(msg.sender, block.timestamp.sub(prev));
    }

    function isRewardTop(address from) public view returns (bool) {
        for (uint256 i = 0; i < _rewards.length; i++) {
            if (_rewards[i] == from) return true;
        }
        return false;
    }

    function _updateStakeReward(address account, uint256 value) internal {
        _stakes.rece[account].total = _stakes.rece[account].total.add(value);

        uint256 reward = _stakes.rece[account].total;
        address[] storage list = _rewards;
        uint256 i = list.length;
        if (i == 0) list.push(account);
        if (list[0] == account) return;

        uint256 lastReward = _stakes.rece[list[i - 1]].total;
        uint256 size = list.length;
        if (lastReward > reward.sub(value) && list[i - 1] != account) {
            if (i < 300) list.push(account);
            else if (lastReward < reward) list[--i] = account;
            else return;
        } else {
            while (--i > 0) {
                require(i < size);
                if (list[i] == account) break;
            }
        }

        if (i == 0 || i > list.length) return;

        for (uint256 j = i - 1; j >= 0 && j < i && j < size; j--) {
            if (_stakes.rece[list[j]].total >= reward) break;
            (list[j + 1], list[j]) = (list[j], account);
        }
    }

    function _updateLastStakeTime(address account, uint256 value) internal {
        uint256 unix = block.timestamp;
        address[] storage list = _lastStakes;
        uint256 i = list.length;
        if (i == 0) list.push(account);
        if (list[0] == account) return;

        uint256 lastTime = _stakes.dict[list[i - 1]].lastTime;
        uint256 size = list.length;
        if (lastTime > unix.sub(value) && list[i - 1] != account) {
            if (i < 31) list.push(account);
            else if (lastTime < unix) list[--i] = account;
            else return;
        } else {
            while (--i > 0) {
                require(i < size);
                if (list[i] == account) break;
            }
        }

        if (i == 0 || i > list.length) return;
        for (uint256 j = i - 1; j >= 0 && j < i && j < size; j--) {
            if (_stakes.dict[list[j]].lastTime >= unix) break;
            (list[j + 1], list[j]) = (list[j], account);
        }
    }

    function _updateSpreadReward(address account, uint256 value) internal {
        uint256 spread = _stakes.dict[account].spread.add(value);
        _stakes.dict[account].spread = spread;

        address[] storage list = spreadRewardList;
        uint256 i = list.length;
        if (i == 0) list.push(account);
        if (list[0] == account) return;

        uint256 lastSpread = _stakes.dict[list[i - 1]].spread;
        uint256 size = list.length;
        if (lastSpread > spread.sub(value) && list[i - 1] != account) {
            if (i < 10) list.push(account);
            else if (lastSpread < spread) list[--i] = account;
            else return;
        } else {
            while (--i > 0) {
                require(i < size);
                if (list[i] == account) break;
            }
        }

        if (i == 0 || i > list.length) return;
        for (uint256 j = i - 1; j >= 0 && j < i && j < size; j--) {
            if (_stakes.dict[list[j]].spread >= spread) break;
            (list[j + 1], list[j]) = (list[j], account);
        }
    }

    function _transferTRX(address to, uint256 value) internal {
        require(address(uint160(to)).send(value), "TRANSFER TRX FAIL");
    }

    function _updateClubsActive(address from) internal;

    event Bind(address indexed sender, address indexed parent);
    event LevelChange(address indexed sender, uint256 indexed level);
}

contract WClubs is WRelationship {
    using SafeMath for uint256;

    struct Club {
        address owner;
        address player;
        uint256 rewardA;
        uint256 rewardB;
        uint256 active;
    }

    Club[] public clubs;
    uint256 public clubTotal;
    uint256 public clubSurplusReward;
    uint256 public rushFinish;
    uint256 public rushTotal;
    address public feeTo;

    mapping(address => uint256) clubsDynamic;
    address[] public clubsDynamicList; 
    address[] public clubsDynamicLastList;

    function allClubs() external view returns (bytes[] memory, uint256) {
        bytes[] memory list = new bytes[](clubTotal);
        for (uint256 i = 0; i < clubTotal; i++) {
            Club storage club = clubs[i];
            list[i] = abi.encodePacked(
                club.owner,
                club.player,
                club.rewardA,
                club.rewardB,
                club.active
            );
        }
        return (list, clubSurplusReward);
    }

    function clubsTop10() external view returns (bytes[] memory) {
        uint256 size = clubsDynamicList.length;
        if (size > 10) size = 10;
        bytes[] memory list = new bytes[](size);
        for (uint256 i = 0; i < size; i++) {
            address from = clubsDynamicList[i];
            list[i] = abi.encodePacked(
                _playerClub(from),
                from,
                _clubDynamic(from)
            );
        }
        return list;
    }

    function purchasing() external payable {
        uint256 price = clubTotal.mul(2000e6).add(20e10);
        if (_playerClub(msg.sender) == uint256(-1) && msg.value >= price) {
            uint256 reward = clubSurplusReward.div(uint256(125).sub(clubTotal));
            clubSurplusReward = clubSurplusReward.sub(reward);
            clubs.push(Club(msg.sender, address(0), reward, 0, 0));
            emit Purchasing(msg.sender, clubTotal);
            clubTotal = clubTotal.add(1);
            _setPlayerClub(msg.sender, clubTotal);
            _updateClubsDynamic(msg.sender, 0);
            if (rushFinish == 0) {
                clubsDynamicLastList.push(msg.sender);
            }

            if (clubTotal == 51 && level == 0) _onOpenStage();

            if (msg.value > price) {
                _transferTRX(msg.sender, msg.value.sub(price));
            }

            address parent = players[msg.sender].parent;
            if (_playerClub(parent) != uint256(-1)) {
                uint256 value = price.div(10);
                _transferTRX(parent, value);
                _stakes.rece[parent].clubSpread = _stakes.rece[parent]
                    .clubSpread
                    .add(value);
                _stakes.rece[parent].total = _stakes.rece[parent].total.add(
                    value
                );
                price = price.sub(value);
            }

            if (feeTo != address(0)) {
                _transferTRX(feeTo, price);
            }
        } else {
            _transferTRX(msg.sender, msg.value);
        }
    }

    function rushPurchasing() external payable {
        require(
            rushFinish >= block.timestamp && rushTotal < 50,
            "RUSH NOT OPEN"
        );
        uint256 price = 224e9;
        require(msg.value == price, "RUSH CLUB PRICE FAIL");
        require(_playerClub(msg.sender) == uint256(-1), "HAS CLUB");
        require(isRewardTop(msg.sender), "CALLER NOT IN TOP");

        uint256 size = clubsDynamicLastList.length;
        address owner = clubsDynamicLastList[size.sub(rushTotal).sub(1)];
        uint256 id = _playerClub(owner);
        require(id >= 0 && id <= 125, "CLUB ID ERR");
        Club storage club = clubs[id];
        club.player = msg.sender;
        _transferTRX(club.owner, price);
        _setPlayerClub(msg.sender, id.add(1));
        emit RushClub(msg.sender, id);
        rushTotal = rushTotal.add(1);
    }

    function clubReward() external payable {
        require(_isClubActive(msg.sender), "CALLER NOT ACTIVE");
        Club storage club = clubs[_playerClub(msg.sender)];
        if (club.player == msg.sender) {
            _transferTRX(msg.sender, club.rewardB);
            emit ClubReward(msg.sender, club.rewardB);
            _stakes.rece[msg.sender].clubs = _stakes.rece[msg.sender].clubs.add(
                club.rewardB
            );
            club.rewardB = 0;
        }
        if (club.owner == msg.sender) {
            _transferTRX(msg.sender, club.rewardA);
            emit ClubReward(msg.sender, club.rewardA);
            _stakes.rece[msg.sender].clubs = _stakes.rece[msg.sender].clubs.add(
                club.rewardA
            );
            club.rewardA = 0;
        }
    }

    function _updateClubsReward(uint256 value) internal {
        uint256 avg = value.div(125);
        for (uint256 i = 0; i < clubTotal; i++) {
            Club storage club = clubs[i];
            uint256 amount = avg;
            if (club.player != address(0)) {
                amount = amount.div(2);
                if (_isClubActive(club.player)) {
                    _transferTRX(club.player, amount);
                    emit ClubReward(club.player, amount);
                    _stakes.rece[club.player].clubs = _stakes.rece[club.player]
                        .clubs
                        .add(amount);
                } else {
                    club.rewardB = club.rewardB.add(amount);
                }
            }
            if (_isClubActive(club.owner)) {
                _transferTRX(club.owner, amount);
                emit ClubReward(club.owner, amount);
                _stakes.rece[club.owner].clubs = _stakes.rece[club.owner]
                    .clubs
                    .add(amount);
            } else {
                club.rewardA = club.rewardA.add(amount);
            }
        }
        clubSurplusReward = clubSurplusReward.add(
            avg.mul(uint256(125).sub(clubTotal))
        );
    }

    function _clubDynamic(address from) internal view returns (uint256) {
        return clubsDynamic[from];
    }

    function _setClubDynamic(address from, uint256 value)
        internal
        returns (uint256)
    {
        _stakes.rece[from].clubs = _stakes.rece[from].clubs.add(value);
        return (clubsDynamic[from] = clubsDynamic[from].add(value));
    }

    function _updateClubsDynamic(address from, uint256 value) internal {
        uint256 dynamic = _setClubDynamic(from, value);

        address[] storage list = clubsDynamicList;
        uint256 i = list.length;
        if (i == 0) {
            list.push(from);
            return;
        }

        uint256 last = _clubDynamic(list[i - 1]);
        if (last >= dynamic.sub(value) && list[i - 1] != from) {
            if (i < 10) list.push(from);
            else if (last < dynamic) list[--i] = from;
            else return;
        } else {
            while (--i > 0) if (list[i] == from) break;
        }
        if (i == 0) return;

        for (uint256 j = i - 1; j >= 0 && j < i; j--) {
            if (_clubDynamic(list[j]) >= dynamic) break;
            (list[j + 1], list[j]) = (list[j], from);
        }
    }

    function _updateClubsDynamicLast(address from) internal {
        if (rushFinish != 0) return;

        uint256 dynamic = _clubDynamic(from);
        address[] storage list = clubsDynamicLastList;
        uint256 i = list.length;
        while (--i > 0) if (list[i] == from) break;
        if (i == 0) return;

        for (uint256 j = i - 1; j >= 0 && j < i; j--) {
            if (_clubDynamic(list[j]) >= dynamic) break;
            (list[j + 1], list[j]) = (list[j], from);
        }
    }

    function _calcStakePlayer(address from) internal returns (uint256) {
        uint256 num = players[from].stakes.length;
        if (num >= 50) return num;
        address[] storage stakes = players[from].stakes;
        for (uint256 i = 0; i < stakes.length && num < 50; i++) {
            num += _calcStakePlayer(stakes[i]);
        }
        return num;
    }

    function _isClubActive(address from) internal view returns (bool) {
        uint256 id = _playerClub(from);
        if (id == uint256(-1)) return false;
        uint256 active = clubs[id].active;
        if (clubs[id].owner == from) {
            return active == 1 || active == 3;
        } else if (clubs[id].player == from) {
            return active == 2 || active == 3;
        }
        revert("FROM NOT HAS CLUB");
    }

    function _updateClubsActive(address from) internal {
        uint256 id = _playerClub(from);
        if (_isClubActive(from)) return;

        uint256 num = _calcStakePlayer(from);
        if (num >= 50) {
            if (clubs[id].owner == from) {
                clubs[id].active = clubs[id].active.add(1);
            } else if (clubs[id].player == from) {
                clubs[id].active = clubs[id].active.add(2);
            }

            address parent = players[from].parent;
            while (parent != address(0)) {
                if ((id = _playerClub(parent)) != uint256(-1)) {
                    if (clubs[id].owner == parent) {
                        clubs[id].active = clubs[id].active.add(1);
                    } else if (clubs[id].player == parent) {
                        clubs[id].active = clubs[id].active.add(2);
                    }
                }
            }
        }
    }

    function _onOpenStage() internal {
        level += 1;
        if (level == 1) {
            uint256 step = block.timestamp.sub(spreadRewardStart).div(1 days);
            spreadRewardStart = spreadRewardStart.add(step.mul(1 days));
            _stakes.outLimit = 270;
            trxLimit = 1e11;
        } else if (level == 2) {
            _stakes.outLimit = 300;
            (trxLimit, rushFinish) = (3e11, block.timestamp.add(1 days));
        } else if (level == 3) {
            _stakes.outLimit = 350;
            trxLimit = 1e12;
        }
        emit LevelChange(msg.sender, level);
    }

    event Purchasing(address indexed sender, uint256 num);
    event RushClub(address indexed sender, uint256 index);
    event ClubReward(address indexed to, uint256 value);
}

contract WSwap is WClubs {
    using SafeMath for uint256;

    address public justswap;
    address public ticket;
    uint256 public swapTrx;
    uint256 public swapTicket;
    uint256 public swapTicketBurn;

    function ticketPrice() public view returns (uint256) {
        return swapTicketBurn.div(420e22).mul(40).add(100).mul(5e3);
    }

    function trySwap(uint256 value) public view returns (uint256) {
        require(justswap != address(0), "JUST SWAP IS EMPTY");
        uint256 usdt = IJustSwap(justswap).getTrxToTokenInputPrice(value);
        return usdt.mul(1e18).div(ticketPrice());
    }

    function swap() external payable {
        uint256 value = trySwap(msg.value);
        require(IERC20(ticket).transfer(msg.sender, value), "TRANSFER FAIL");
        _updateClubsReward(msg.value);
        swapTrx = swapTrx.add(msg.value);
        swapTicket = swapTicket.add(value);
        emit Swap(msg.sender, msg.value, value);
    }

    function _burnFromticket(address from, uint256 value) internal {
        require(IERC20(ticket).burnFrom(from, value), "BURNFROM FAIL");
        swapTicketBurn = swapTicketBurn.add(value);
        uint256 rate = swapTicketBurn.div(uint256(420e22));
        if (rate == 1 && level == 1) _onOpenStage();
        if (rate == 2 && level == 2) _onOpenStage();
    }

    event Swap(address indexed sender, uint256 value, uint256 token);
}

contract Wave is Ownable, WSwap {
    using SafeMath for uint256;

    uint256 public funds;
    uint256 public fundsLoop;
    uint256 public fundsStake;
    uint256 public fundsClub;
    uint256 public fundsSpread;
    address public missTo;

    constructor(address _ticket, address _justswap) public {
        feeTo = msg.sender;
        missTo = msg.sender;
        ticket = _ticket;
        justswap = _justswap;
        spreadRewardStart = 1609430400;
    }

    function _onAllocateFundsSpread() internal {
        uint256 total = fundsSpread.div(100).mul(30);
        uint256 avg = total.div(100);
        uint256 size = spreadRewardList.length;
        if (size > 10) size = 10;
        uint256[10] memory rates = [uint256(35), 20, 15, 10, 7, 5, 3, 2, 2, 1];
        uint256 already;
        for (uint256 i = 0; i < size; i++) {
            uint256 value = avg.mul(rates[i]);
            _transferFundsTRX(spreadRewardList[i], value);
            already = already.add(value);
        }
        require(already <= total, "ALLOCATE OVERFLOW");
        fundsSpread = fundsSpread.sub(already);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function setMissTo(address _missTo) external onlyOwner {
        missTo = _missTo;
    }

    function staticReward() external {
        uint256 reward = _stakes.updateStake();
        uint256 already = reward;
        address prev = msg.sender;
        uint256 mvalue;
        uint256 avg = reward.div(100);
        for (uint256 i = 1; i <= 20; i++) {
            prev = players[prev].parent;
            uint256 value = avg;
            if (i <= 1) value = avg.mul(20);
            else if (i <= 4) value = avg.mul(10);
            else if (i <= 10) value = avg.mul(5);
            else if (i <= 15) value = avg.mul(8);
            else value = avg.mul(4);
            if (prev == address(0) || players[prev].spread < i) {
                already = already.add(value);
                mvalue = mvalue.add(value);
                continue;
            }

            value = _stakes.updateDynamic(prev, value, false);
            already = already.add(value);
        }
        if (mvalue > 0) {
            _transferTRX(missTo, mvalue);
        }
        fundsStake = fundsStake.sub(already.add(reward));
        _transferTRX(msg.sender, reward);
        _stakes.rece[msg.sender].statics = _stakes.rece[msg.sender].statics.add(
            reward
        );
        _updateStakeReward(msg.sender, reward);

        emit Statics(msg.sender, reward);
    }

    function dynamicReward() external {
        uint256 reward = _stakes.dict[msg.sender].dynamic;
        _stakes.dict[msg.sender].dynamic = 0;
        fundsStake = fundsStake.sub(reward);
        _transferTRX(msg.sender, reward);
        _stakes.rece[msg.sender].dynamic = _stakes.rece[msg.sender].dynamic.add(
            reward
        );
        _updateStakeReward(msg.sender, reward);
        if (_playerClub(msg.sender) != uint256(-1)) {
            _updateClubsDynamic(msg.sender, reward);
            _updateClubsDynamicLast(msg.sender);
        }
        emit Dynamic(msg.sender, reward);
    }

    function infoOf(address from)
        external
        view
        returns (uint256[] memory reward)
    {
        if (_playerClub(from) == uint256(-1)) {
            reward = new uint256[](8);
        } else {
            reward = new uint256[](9);
            reward[8] = _stakes.rece[from].clubSpread;
        }
        reward[0] = players[from].spread;
        reward[1] = _stakes.dict[from].value;
        reward[2] = _stakes.rece[from].dynamic;
        reward[3] = _stakes.rece[from].statics;
        reward[4] = _stakes.rece[from].funds;
        reward[5] = _stakes.rece[from].clubs;
        reward[6] = _stakes.rece[from].spread;
        reward[7] = _stakes.rece[from].total;
    }

    function rewardOf(address from)
        external
        view
        returns (uint256[2] memory reward)
    {
        reward[0] = _stakes.rewardsOf(from);
        reward[1] = _stakes.dict[from].dynamic;
    }

    function rateOf(address from) external view returns (uint256) {
        return _stakes.rateOf(from);
    }

    function stakeOf(address from) external view returns (uint256, uint256) {
        (uint256 min, uint256 value) = _stakes.stakeOf(from);
        return (min, trxLimit.sub(value));
    }

    function stakesOf(address from) external view returns (uint256[] memory) {
        return _stakes.stakesOf(from);
    }

    function tryStake(uint256 value) public view returns (uint256) {
        require(justswap != address(0), "JUST SWAP IS EMPTY");
        uint256 usdt = IJustSwap(justswap).getTrxToTokenInputPrice(value);
        return usdt.mul(1e18).div(10).div(ticketPrice());
    }

    function stakeTRX() external payable reviseSpread {
        require(level > 0, "LEVEL LESS THAN ZERO");
        _burnFromticket(msg.sender, tryStake(msg.value));
        _updateLastStake();

        uint256 avg = msg.value.div(1000);
        _allocateFunds(avg.mul(125));
        uint256 surplus = _allocateSpread(avg.mul(50));
        _allocateClubs(avg.mul(90));
        fundsStake = fundsStake.add(avg.mul(710)).add(surplus);
        fundsSpread = fundsSpread.add(avg.mul(25));
        emit StakeTRX(msg.sender, msg.value);
    }

    function _allocateSpread(uint256 value) internal returns (uint256) {
        address to = players[msg.sender].parent;
        uint256 surplus = value;
        if (to != address(0)) {
            value = _stakes.updateDynamic(to, value, true);
        } else {
            to = missTo;
        }
        _transferTRX(to, value);
        _stakes.rece[to].spread = _stakes.rece[to].spread.add(value);
        _updateStakeReward(to, value);
        emit AllocateSpread(msg.sender, to, value);
        return surplus.sub(value);
    }

    function _allocateFunds(uint256 value) internal {
        funds = funds.add(value);
        if (funds < uint256(125e10)) return;
        uint256 rate = 60;
        if (fundsLoop >= 4) rate = 90;
        uint256 reward = _allocateLastStake(uint256(125e10).mul(rate).div(100));

        funds = funds.sub(reward);
        emit AllocateFunds(msg.sender, fundsLoop);
        fundsLoop = fundsLoop >= 4 ? 0 : fundsLoop.add(1);
    }

    function _transferFundsTRX(address to, uint256 value) internal {
        _stakes.rece[to].funds = _stakes.rece[to].funds.add(value);
        _transferTRX(to, value);
        emit Funds(to, value);
        _updateStakeReward(to, value);
    }

    function _allocateClubs(uint256 value) internal {
        uint256 avg = value.div(100);
        _updateClubsReward(avg.mul(80));
        fundsClub = fundsClub.add(avg.mul(20));
    }

    function _allocateLastStake(uint256 value) internal returns (uint256) {
        uint256 avg = value.div(100);
        uint256 reward = 0;
        uint256[3] memory values =
            [avg.mul(45), avg.mul(20).div(10), avg.mul(35).div(20)];

        uint256 size = _lastStakes.length;
        for (uint256 i = 0; i < size; i++) {
            uint256 j = i == 0 ? 0 : i < 11 ? 1 : 2;
            address account = _lastStakes[i];
            _transferFundsTRX(account, values[j]);
            reward = reward.add(values[j]);
        }
        return reward;
    }

    modifier reviseSpread() {
        if (block.timestamp.sub(spreadRewardStart) > 1 days) {
            spreadRewardStart += 1 days;
            _onAllocateFundsSpread();
            delete spreadRewardList;
        }

        _;
    }

    // EVENT
    event StakeTRX(address indexed sender, uint256 indexed value);
    event Statics(address indexed to, uint256 indexed value);
    event Dynamic(address indexed to, uint256 indexed value);
    event Funds(address indexed to, uint256 indexed value);
    event AllocateFunds(address indexed sender, uint256 indexed loop);
    event AllocateSpread(
        address indexed sender,
        address indexed to,
        uint256 indexed value
    );
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function burnFrom(address from, uint256 value) external returns (bool);
}