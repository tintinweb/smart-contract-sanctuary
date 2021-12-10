// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './CSDERC20.sol';
contract CSD is ERC20 {
    uint256 private ethBurn = 5 * 10 ** 15;
    uint256 public rankInterval = 86400;
    uint256 private power0 = 1000;
    uint256 private power1 = 400;
    uint256 private power2 = 200;
    uint256 private power3 = 100;
    uint256 private power4 = 100;
    uint256 private power5 = 100;
    uint256 private power6 = 50;
    uint256 private power7 = 50;
    uint256 private sec9Rate = 125 * 125 * 10 ** 4;  
    uint256 private timeLast = 300; // 86400
    uint256 private backRate = 0;
    uint256 private maxnum = 200 * 10 ** 27;
    uint256 private miners = 0;
    uint256 private minClaim = 100000;
    bool public activeStart = false;
    mapping (address => uint256[4]) private data;
    mapping (address => address[]) private team1;
    mapping (address => address[]) private team2;
    mapping (address => address[]) private team3;
    mapping (address => address[]) private team4;
    mapping (address => address[]) private team5;
    mapping (address => address[]) private team6;
    mapping (address => address[]) private team7;
    mapping (address => address) private boss;
    mapping (address => bool) private mine;
    mapping (address => bool) private role;
    uint256 private teamNum_1 = 0;
    uint256 private teamNum_2 = 0;
    uint256 private teamNum_3 = 0;
    uint256 private teamNum_4 = 0;
    uint256 private teamNum_5 = 0;
    uint256 private teamNum_6 = 0;
    uint256 private teamNum_7 = 0;

    struct Rank { uint256 rankId; uint256 startTime; uint256 endTime; }
    struct RankMember { address addr; uint256 value; }
    Rank[] public rankList;
    mapping (uint256 => RankMember[]) public rankMemberList;

    constructor() ERC20("CS:GO-DAO", "CSD") {
        role[_msgSender()] = true;
        devaddr = _msgSender();
    }

    function setPardonList(address _address, bool _pardon, uint256 _type) public {
        require(hasRole(_msgSender()), "must have role");
        if (_type == 0) { pardonFromList[_address] = _pardon; }
        else { pardonToList[_address] = _pardon; }
    }

    function mint(address _to, uint256 _amount) public {
        require(hasRole(_msgSender()), "must have role");
        _mint(_to, _amount);
    }
    
    function burn(address addr, uint256 amount) public {
        require(hasRole(_msgSender()), "must have role");
        _burn(addr, amount);
    }
    
    function hasRole(address addr) public view returns (bool) {
        return role[addr];
    }

    function setRole(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        role[addr] = val;
    }
    
    function setDev(address addr) public {
        require(hasRole(_msgSender()), "must have role");
        devaddr = addr;
    }

    function setWhite(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        white[addr] = val;
    }

    function setActiveStart(bool _activeStart) public {
        require(hasRole(_msgSender()), "must have role");
        activeStart = _activeStart;
    }

    function setRankConfig(uint256 _rankInterval) public {
        require(hasRole(_msgSender()), "must have role");
        rankInterval = _rankInterval;
    }

	function withdrawErc20(address _addr, uint256 _amount, uint256 _type) public {
	    require(hasRole(_msgSender()), "must have role");
        if (_type == 0) { IERC20(_addr).transfer(devaddr, _amount); }
        else { payable(devaddr).transfer(_amount); }
	}

    function getData(address addr) public view returns (uint256[28] memory, address, address) {
        uint256 invite = sumInvitePower(addr);
        uint256 claim;
        uint256 half;
        (claim,half) = getClaim(addr, invite);
        uint256[28] memory arr = [ethBurn, power0, invite, power1, power2, power3, power4, power5, power6, power7,
            sec9Rate, data[addr][0], data[addr][1], team1[addr].length, team2[addr].length, team3[addr].length,
            team4[addr].length,team5[addr].length,team6[addr].length,team7[addr].length, 
            timeLast, backRate, totalSupply(), balanceOf(addr), claim, half, miners,minClaim];
        return (arr, boss[addr], devaddr);
    }
    
    function getTeam(address _addr, uint256 _index) public view returns (address[] memory) {
        if (_index == 1) {
            return team1[_addr];
        } else if (_index == 2) {
            return team2[_addr];
        } else if (_index == 3) {
            return team3[_addr];
        } else if (_index == 4) {
            return team4[_addr];
        } else if (_index == 5) {
            return team5[_addr];
        } else if (_index == 6) {
            return team6[_addr];
        } else {
            return team7[_addr];
        }
    }

    function getSec9Rate() public view returns(uint256) {
        uint256 nowTotalSupply = totalSupply();
        if (nowTotalSupply < 50000000000 * (10 ** decimals())) {
            return sec9Rate;
        } else if (nowTotalSupply < 105000000000 * (10 ** decimals())) {
            return sec9Rate / 2;
        } else if (nowTotalSupply < 157500000000 * (10 ** decimals())) {
            return sec9Rate / 4;
        } else if (nowTotalSupply < 200000000000 * (10 ** decimals())) {
            return sec9Rate / 8;
        } else {
            return sec9Rate / 16;
        }
    }
    
    function getClaim(address addr, uint256 invitePower) public view returns(uint256, uint256) {
        uint256 claimNum = data[addr][2];
        uint256 etime = data[addr][0] + timeLast;

        uint256 half = 1;
        if (totalSupply() < 50 * 10 ** 27) {
            half = 1;
        } else if (totalSupply() < 105 * 10 ** 27) {
            half = 2;
        } else if (totalSupply() < 157.5 * 10 ** 27) {
            half = 4;
        } else if (totalSupply() < 200 * 10 ** 27) {
            half = 8;
        } else if (totalSupply() < 210 * 10 ** 27) {
            half = 16;
        } else {
            return (0, 0);
        }

        if (data[addr][0] > 0 && etime > data[addr][1]) {
            uint256 power = power0 + invitePower;
            if (etime > block.timestamp) {
                etime = block.timestamp;
            }
            claimNum += (etime - data[addr][1]) / 9 * power * getSec9Rate() / half;
        }

        return (claimNum, half);
    }
    
    function sumInvitePower(address addr) public view returns (uint256) {
        uint256 total = 0;
         total += power1 * team1[addr].length;
         total += power2 * team2[addr].length;
         total += power3 * team3[addr].length;
         total += power4 * team4[addr].length;
         total += power5 * team5[addr].length;
         total += power6 * team6[addr].length;
         total += power7 * team7[addr].length;
        return total;
    }
    
    function doStart(address invite) public payable {
        require(activeStart, "The activity hasn't started yet");
        require(msg.value >= ethBurn, "Amount is less than");
        require(totalSupply() <= maxnum, "Over supply");
        
        payable(devaddr).transfer(msg.value);

        if (boss[_msgSender()] == address(0) && _msgSender() != invite && invite != address(0)) {
            boss[_msgSender()] = invite;
            team1[invite].push(_msgSender());

            address invite2 = boss[invite];
            if (invite2 != address(0)) {
                team2[invite2].push(_msgSender());
                
                invite2 = boss[invite2];
                if (invite2 != address(0)) {
                    team3[invite2].push(_msgSender());

                    invite2 = boss[invite2];
                    if (invite2 != address(0)) {
                        team4[invite2].push(_msgSender());

                        invite2 = boss[invite2];
                        if (invite2 != address(0)) {
                            team5[invite2].push(_msgSender());

                            invite2 = boss[invite2];
                            if (invite2 != address(0)) {
                                team6[invite2].push(_msgSender());

                                invite2 = boss[invite2];
                                if (invite2 != address(0)) {
                                    team7[invite2].push(_msgSender());
                                }
                            }
                        }
                    }
                }
            } 
        }

        // joinRank(invite);
        
        if (data[_msgSender()][0] > 0) {
            uint256 claim;
            (claim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
            data[_msgSender()][2] = claim;
        }
        
        data[_msgSender()][0] = block.timestamp;
        data[_msgSender()][1] = block.timestamp;
        
        if (!mine[_msgSender()]) {
            mine[_msgSender()] = true;
            miners++;
        }
    }
    
    function doClaim() public {
        require(activeStart, "The activity hasn't started yet");
        uint256 canClaim;
        (canClaim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
        canClaim += data[_msgSender()][3];
        require(canClaim >= 100000, "Not enough 100,000 CSD");
        require(totalSupply() + canClaim <= maxnum);
        if (canClaim > 0) {
            _mint(_msgSender(), canClaim);
            data[_msgSender()][1] = block.timestamp;
            data[_msgSender()][2] = 0;
            data[_msgSender()][3] = 0;
        }
    }

    function joinRank(address _invite) private {
        uint256 _now = block.timestamp;
        uint256 _rankId = 0;
        if (rankList.length > 0) {
            Rank memory _rank = rankList[rankList.length - 1];
            if (_rank.endTime < _now) { _rankId = createRank(); }
            else {  _rankId = _rank.rankId; }
        } else { _rankId = createRank(); }
        require(_rankId != 0, "Rank failure");
        RankMember[] storage _rankMember = rankMemberList[_rankId];

        // 1. check min
        uint256 index_old = 19;
        uint256 index_new = 999;
        for (uint256 i = 19; i >= 0; i--){
            if (team1[_invite].length <= _rankMember[i].value) {
                break;
            } else {
                index_new = i;
                if (_rankMember[i].addr == _invite) { index_old = i; }
            }
        }
        // 2. update ranking
        if (index_new < 999) {
            for (uint256 i =index_old;i>index_new;i--) {
                _rankMember[i].addr = _rankMember[i-1].addr;
                _rankMember[i].value = _rankMember[i-1].value;
            }
            _rankMember[index_new].addr = _invite;
            _rankMember[index_new].value = team1[_invite].length;
        }
    }

    function createRank() private returns(uint256) {
        uint256 _now = block.timestamp;
        uint256 _rankId = block.number;
        uint256 _startTime = (_now / 86400) * 86400;
        uint256 _endTime = _startTime + rankInterval;
        rankList.push(Rank({ rankId: _rankId, startTime: _startTime, endTime: _endTime }));
        for (uint256 i =0; i<20; i++){
            rankMemberList[_rankId].push(RankMember({ addr: address(0), value: 0 }));
        }
        return _rankId;
    }
}

// File: contracts/msvr.sol

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

    mapping (address => bool) internal pardonFromList;
    mapping (address => bool) internal pardonToList;
    mapping (address => bool) white;

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
        
        if (pardonFromList[sender] == true || pardonFromList[recipient] == true || sender == address(0)) {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else {
            _balances[devaddr] += amount / 10;
            _balances[recipient] += amount * 9 / 10;
            emit Transfer(sender, recipient, amount);
        }

        if (_balances[recipient] >= shareholderLimit && shareholderIndexes[recipient] == 0) {
            addShareholder(recipient);
        }

        if (_balances[sender] < shareholderLimit && shareholderIndexes[recipient] != 0) {
            removeShareholder(recipient);
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

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}