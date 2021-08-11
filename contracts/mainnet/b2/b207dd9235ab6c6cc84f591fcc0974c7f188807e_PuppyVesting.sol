pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";

interface PuppyToken {
    function transfer(address _to, uint _amount) external returns(bool);
    function transferFrom(address _from, address _to, uint _amount) external returns(bool);
    function balanceOf(address _user) external returns(uint);
}

contract PuppyVesting is AccessControlEnumerable {
    
    struct Member {
        address memberAddress;
        uint lastClaimed;
        uint totalClaimed;
        uint vested;
    }
    
    uint public totalVested;
    Member[] public team;
    Member[] public treasury;
    Member[] public marketing;
    uint public end;
    uint public start;
    uint public vestingPeriod;
    uint public teamTotalVested;
    uint public treasuryTotalVested;
    uint public marketingTotalVested;
    uint public teamStart;
    uint public teamEnd;
    PuppyToken public token;
    
    event TeamVestingClaimed(address to, uint amount);
    event TreasuryVestingClaimed(address to, uint amount);
    event MarketingVestingClaimed(address to, uint amount);
    event Rescue(address to, uint amount);
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    bytes32 public constant MARKETING_ROLE = keccak256("MARKETING_ROLE");
    
    constructor(address _token, address _admin) {
        require(_token != address(0) && _admin != address(0), "0 address not allowed");
        _setupRole(ADMIN_ROLE, _admin);
        end = block.timestamp + 730 days; //2 years
        start = block.timestamp;
        teamStart = block.timestamp + 30 days; //1 month lockup
        teamEnd = block.timestamp + 30 days + 730 days; //2 years + 1 month for lockup
        vestingPeriod = end - start;
        token = PuppyToken(_token);
    }
    
    function addTeam(address[] memory _team) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Not allowed");
        for (uint i; i < _team.length; i++) {
            team.push(Member(_team[i], teamStart , 0, teamTotalVested/_team.length));
            _setupRole(TEAM_ROLE, _team[i]);
        }
    }
    
    function addTreasury(address[] memory _treasury) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Not allowed");
        for (uint i; i < _treasury.length; i++) {
            treasury.push(Member(_treasury[i], start, 0, treasuryTotalVested/_treasury.length));
            _setupRole(TREASURY_ROLE, _treasury[i]);
        }
    }
    
    function addMarketing(address[] memory _marketing) external {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Not allowed");
        for (uint i; i < _marketing.length; i++) {
            marketing.push(Member(_marketing[i], start, 0, marketingTotalVested/_marketing.length));
            _setupRole(MARKETING_ROLE, _marketing[i]);
        }
    }
    
    function claimTeamVesting() external {
        require(hasRole(TEAM_ROLE, _msgSender()), "Not allowed");
        require(block.timestamp >= teamStart, "Can't claim yet");
        Member[] storage _team = team;
        for (uint i; i <= _team.length; i++) {
            if (_team[i].memberAddress == _msgSender() && _team[i].vested - _team[i].totalClaimed > 0) {
                uint _reward;
                if (block.timestamp < teamEnd) {
                    _reward = _team[i].vested * (block.timestamp - _team[i].lastClaimed)  / vestingPeriod;
                } else {
                    _reward = _team[i].vested * (teamEnd - _team[i].lastClaimed) / vestingPeriod;
                }
                if (_reward > _team[i].vested - _team[i].totalClaimed) {
                    _reward = _team[i].vested - _team[i].totalClaimed;
                }
                token.transfer(_team[i].memberAddress, _reward);
                _team[i].totalClaimed += _reward;
                _team[i].lastClaimed = block.timestamp;
                emit TeamVestingClaimed(_team[i].memberAddress, _reward);
                return;
            }
        }
    }
    
    function claimTreasuryVesting() external {
        require(hasRole(TREASURY_ROLE, _msgSender()), "Not allowed");
        Member[] storage _treasury = treasury;
        for (uint i; i <= _treasury.length; i++) {
            if (_treasury[i].memberAddress == _msgSender() && _treasury[i].vested - _treasury[i].totalClaimed > 0) {
                uint _reward;
                if (block.timestamp < end) {
                    _reward = _treasury[i].vested * (block.timestamp - _treasury[i].lastClaimed)  / vestingPeriod;
                } else {
                    _reward = _treasury[i].vested * (end - _treasury[i].lastClaimed) / vestingPeriod;
                }
                if (_reward > _treasury[i].vested - _treasury[i].totalClaimed) {
                    _reward = _treasury[i].vested - _treasury[i].totalClaimed;
                }
                token.transfer(_treasury[i].memberAddress, _reward);
                _treasury[i].totalClaimed += _reward;
                _treasury[i].lastClaimed = block.timestamp;
                emit TreasuryVestingClaimed(_treasury[i].memberAddress, _reward);
                return;
            }
        }
    }
    
    function claimMarketingVesting() external {
        require(hasRole(MARKETING_ROLE, _msgSender()), "Not allowed");
        Member[] storage _marketing = marketing;
        for (uint i; i <= _marketing.length; i++) {
            if (_marketing[i].memberAddress == _msgSender() && _marketing[i].vested - _marketing[i].totalClaimed > 0) {
                uint _reward;
                if (block.timestamp < end) {
                    _reward = _marketing[i].vested * (block.timestamp - _marketing[i].lastClaimed)  / vestingPeriod;
                } else {
                    _reward = _marketing[i].vested * (end - _marketing[i].lastClaimed) / vestingPeriod;
                }
                if (_reward > _marketing[i].vested - _marketing[i].totalClaimed) {
                    _reward = _marketing[i].vested - _marketing[i].totalClaimed;
                }
                token.transfer(_marketing[i].memberAddress, _reward);
                _marketing[i].totalClaimed += _reward;
                _marketing[i].lastClaimed = block.timestamp;
                emit MarketingVestingClaimed(_marketing[i].memberAddress, _reward);
                return;
            }
        }
    }
    
    function initVesting(uint _amount) external {
        require(hasRole(ADMIN_ROLE, _msgSender()));
        token.transferFrom(_msgSender(), address(this), _amount);
        totalVested = _amount;
        teamTotalVested = _amount * 4 / 10; //40%
        treasuryTotalVested = _amount * 3 / 10; // 30%
        marketingTotalVested = _amount * 3 / 10; // 30%
    }

    function rescue(address _to) external {
        require(hasRole(ADMIN_ROLE, _msgSender()));
        uint _balance = token.balanceOf(address(this));
        token.transfer(_to, _balance);
        emit Rescue(_to, _balance);
    }
    
}