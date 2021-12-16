// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './CSDERC20.sol';
import './CSDRank.sol';
import './CSDUtils.sol';
contract CSD is ERC20, CSDRank, CSDUtils {
    uint256 private maxnum = 200 * 10 ** 27;
    uint256 private miners = 0;
    uint256 private minClaim = 100000;
    bool private activeStart = false;

    mapping (address => bool) private role;
    constructor() ERC20("CS:GO-DAO", "CSD") {
        role[_msgSender()] = true;
        devaddr = _msgSender();
    }
    function mint(address _to, uint256 _amount) public {
        require(hasRole(_msgSender()), "role");
        _mint(_to, _amount);
    }
    function hasRole(address addr) public view returns (bool) {
        return role[addr];
    }
    function setRole(address addr, bool val) public {
        require(hasRole(_msgSender()), "role");
        role[addr] = val;
    }
    function setDev(address addr) public {
        require(hasRole(_msgSender()), "role");
        devaddr = addr;
    }
    function setWhite(address addr, bool val) public {
        require(hasRole(_msgSender()), "role");
        white[addr] = val;
    }
    function setActiveStart(bool _activeStart) public {
        require(hasRole(_msgSender()), "role");
        activeStart = _activeStart;
    }
	function withdrawErc20(address _addr, uint256 _amount, uint256 _type) public {
	    require(hasRole(_msgSender()), "role");
        if (_type == 0) { IERC20(_addr).transfer(devaddr, _amount); }
        else { payable(devaddr).transfer(_amount); }
	}

    function getData(address addr) public view returns (uint256[19] memory, address) {
        uint256 invite = sumInvitePower(addr);
        uint256 claim;
        uint256 half;
        (claim,half) = getClaim(addr);
        uint256[19] memory arr = [ethBurn, powerSelfStart, invite, 
            sec9Rate, data[addr][0], data[addr][1], teamList[0][addr].length, teamList[1][addr].length,
            teamList[2][addr].length, teamList[3][addr].length, teamList[4][addr].length, teamList[5][addr].length,
            teamList[6][addr].length, timeLast, totalSupply(), balanceOf(addr), claim, half, miners];
        return (arr, boss[addr]);
    }


    function getClaim(address _addr) public view returns(uint256, uint256) {
        uint256 claimNum = data[_addr][2];
        uint256 etime = data[_addr][0] + timeLast;
        uint256 half = 1;
        if (totalSupply() < 50 * 10 ** 27) { half = 1; }
        else if (totalSupply() < 105 * 10 ** 27) { half = 2; }
        else if (totalSupply() < 1575 * 10 ** 26) { half = 4; }
        else if (totalSupply() < 200 * 10 ** 27) { half = 8; }
        else if (totalSupply() < 210 * 10 ** 27) { half = 16; }
        else { return (0, 0); }
        // plus mining claim
        if (data[_addr][0] > 0 && etime > data[_addr][1]) {
            uint256 power = powerSelfStart + sumInvitePower(_addr);
            if (etime > block.timestamp) {
                etime = block.timestamp;
            }
            claimNum += (etime - data[_addr][1]) / 9 * power / 1000 * sec9Rate / half;
        }
        return (claimNum, half);
    }
    function doStart(address invite) public payable {
        require(activeStart, "The activity hasn't started yet");
        require(msg.sender != invite, "Uninvited address");
        require(msg.value >= ethBurn, "Amount is less than");

        payable(devaddr).transfer(msg.value);

        bindInvite(invite);
        joinRank(invite);

        if (data[msg.sender][0] > 0) {
            uint256 claim;
            (claim,) = getClaim(msg.sender);
            data[msg.sender][2] = claim;
        }

        data[msg.sender][0] = block.timestamp;
        data[msg.sender][1] = block.timestamp;
        
        if (!mine[msg.sender]) {
            mine[msg.sender] = true;
            miners++;
        }
    }

    function doClaim() public {
        require(activeStart, "No started");
        uint256 canClaim;
        (canClaim,) = getClaim(_msgSender());
        require(totalSupply() + canClaim <= maxnum);
        require(canClaim >= 100000 * 10 ** 18, "Not 100,000 CSD");
        if (canClaim > 0) {
            // _mint(backAddr, canClaim * backRate / 100);
            _mint(_msgSender(), canClaim);
            
            data[_msgSender()][1] = block.timestamp;
            data[_msgSender()][2] = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address internal devaddr;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 public maxSupply = 210000000000 * (10 ** decimals());
    uint256 public shareholderLimit = 100000000 * (10 ** decimals());
    address[] public shareholders;
    mapping(address => uint256) public shareholderIndexes;
    mapping (address => bool) public white;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        if (white[sender] == true || white[recipient] == true || sender == address(0)) {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else {
            _balances[devaddr] += amount / 10;
            _balances[recipient] += amount * 9 / 10;
            emit Transfer(sender, recipient, amount);
        }

        if (_balances[recipient] >= 100000000 * (10 ** decimals()) && shareholderIndexes[recipient] == 0) {
            shareholderIndexes[recipient] = shareholders.length;
            shareholders.push(recipient);
        }

        if (_balances[sender] < 100000000 * (10 ** decimals()) && shareholderIndexes[recipient] != 0) {
            shareholders[shareholderIndexes[recipient]] = shareholders[shareholders.length - 1];
            shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[recipient];
            shareholders.pop();
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract CSDRank {
    uint256 private rankInterval = 86400;
    struct Rank { uint256 rankId; uint256 startTime; uint256 endTime; }
    struct RankMember { address addr; uint256 value; }
    Rank[] public rankList;
    mapping (uint256 => RankMember[]) public rankMemberList;
    function joinRank(address _invite) internal virtual {
        uint256 _now = block.timestamp;
        uint256 _rankId = 0;
        if (rankList.length > 0) {
            uint256 _nowRankEndTime = rankList[rankList.length - 1].endTime;
            uint256 _nowRankId = rankList[rankList.length - 1].rankId;
            if (_nowRankEndTime < _now) { _rankId = createRank(); }
            else {  _rankId = _nowRankId; }
        } else {
            _rankId = createRank();
        }
        RankMember[] storage rankMember = rankMemberList[_rankId];
        uint256 _inviteIndex = 21;
        uint256 _inviteValue = 1;
        for (uint256 _index = 0; _index < 20; _index++ ) {
            if (rankMember[_index].addr == _invite) {
                _inviteIndex = _index;
                _inviteValue = rankMember[_index].value + 1;
                break;
            }
        }
        if (_inviteIndex == 21) {
            for (uint256 _index = 0; _index < 20; _index++ ) {
                if (rankMember[_index].value == 0) {
                    rankMember[_index].addr = _invite;
                    rankMember[_index].value = _inviteValue;
                    break;
                }
            }
        } else {
            if (_inviteIndex == 0) { rankMember[_inviteIndex].value = _inviteValue; }
            else {
                if (rankMember[_inviteIndex - 1].value < _inviteValue) {
                    rankMember[_inviteIndex].addr = rankMember[_inviteIndex - 1].addr;
                    rankMember[_inviteIndex].value = rankMember[_inviteIndex - 1].value;
                    rankMember[_inviteIndex - 1].value = _inviteValue;
                    rankMember[_inviteIndex - 1].addr = _invite;
                }
            }
        }
    }
    function createRank() private returns(uint256) {
        uint256 _now = block.timestamp;
        uint256 _rankId = block.number;
        uint256 _startTime = (_now / 86400) * 86400;
        uint256 _endTime = _startTime + rankInterval;
        rankList.push(Rank({ rankId: _rankId, startTime: _startTime, endTime: _endTime }));
        rankMemberList[_rankId].push(RankMember({ addr: address(0), value: 0 }));
        for ( uint256 i = 0; i < 20; i++ ) { rankMemberList[_rankId].push(RankMember({ addr: address(0), value: 0 })); }
        return _rankId;
    }
    function getTodayRank() public view returns(RankMember[] memory) {
        uint256 _rankId = rankList[rankList.length - 1].rankId;
        return rankMemberList[_rankId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract CSDUtils {
    uint256 public sec9Rate = 1042 * 10 ** 16;  
    uint256 public ethBurn = 5000000000000000;
    uint256 powerSelfStart = 1000;
    uint256[7] public powerList = [400, 200, 100, 100, 100, 50, 50];
    mapping (address => bool) public mine;
    uint256 public timeLast = 86400;

    mapping (address => uint256[3]) public data;
    mapping (address => address) public boss;

    mapping (uint256 => mapping (address => address[])) public teamList;

    function sumInvitePower(address addr) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 _teamIndex = 0; _teamIndex < 7; _teamIndex++) {
             for (uint256 i=0; i < teamList[_teamIndex][addr].length; i++) {
                address team = teamList[_teamIndex][addr][i];
                if (data[team][0] + timeLast > block.timestamp) {
                    total += powerList[_teamIndex];
                }
            }
        }
        return total;
    }

    function getInvitePower(address addr) public view returns (uint256[7] memory) {
        uint256[7] memory _invitePowerList;
        for (uint256 _teamIndex = 0; _teamIndex < 7; _teamIndex++) {
             for (uint256 i=0; i < teamList[_teamIndex][addr].length; i++) {
                address team = teamList[_teamIndex][addr][i];
                if (data[team][0] + timeLast > block.timestamp) {
                    _invitePowerList[_teamIndex] += powerList[_teamIndex];
                }
            }
        }
        return _invitePowerList;
    }

    function bindInvite(address _invite) internal virtual {
        if (boss[msg.sender] == address(0)) {
            boss[msg.sender] = _invite;
            teamList[0][_invite].push(msg.sender);

            address _bossInvite = boss[_invite];

            for (uint256 _teamIndex = 1; _teamIndex < 7; _teamIndex++) {
                if (_bossInvite != address(0)) {
                    teamList[_teamIndex][_bossInvite].push(msg.sender);
                    _bossInvite = boss[_bossInvite];
                } else {
                    break;
                }
            }
        }
    }
}