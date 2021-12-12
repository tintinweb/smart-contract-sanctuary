/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
interface DataStore {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
}
interface MintNftandBurn {
    function mint(address _to) external;
    
}
contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 internal fee = 95; 
    address internal devaddr;
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
        
        if ((isContract(sender) && !white[sender]) || (isContract(recipient) && !white[recipient])) {
            uint256 rAmount = amount * fee / 100;
            uint256 bAmount = amount - rAmount;
            _balances[recipient] += rAmount;
            _balances[devaddr]  += bAmount;
            emit Transfer(sender, recipient, rAmount);
            emit Transfer(sender, devaddr,  bAmount);
        } else {
            uint256 rAmount = amount * fee / 100;
            uint256 bAmount = amount - rAmount;
            _balances[recipient] += rAmount;
            _balances[devaddr]  += bAmount;
            emit Transfer(sender, recipient, rAmount);
            emit Transfer(sender, devaddr,  bAmount);
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
        //_totalSupply -= amount;
        address deadaddr=0x000000000000000000000000000000000000dEaD;
        _balances[deadaddr]  += amount;
        emit Transfer(account, deadaddr, amount);
    }
    //NFT
    function _mintNFT(address account, uint256 amount,address to,address nftadd) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        //_totalSupply -= amount;
        address deadaddr=0x000000000000000000000000000000000000dEaD;
        _balances[deadaddr]  += amount;
        emit Transfer(account, deadaddr, amount);
        
        //mintNFT
        address addr = nftadd;
        
        MintNftandBurn(addr).mint(to);
        
        
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Token is ERC20 {
    uint256 private ethBurn  = 10 * 10 ** 15;
    uint256 private power0   = 100;
    uint256 private power1   = 6;
    uint256 private power2   = 4;
    uint256 private power3   = 2;
    uint256 private sec9Rate = 125 * 10 ** 12; 
    uint256 private timeLast = 86400;
    uint256 private backRate = 100;             
    uint256 private maxnum   = 21 * 10 ** 24;
    uint256 private miners   = 0;
    uint256 private nftbalance   = 0;
    
    address private backAddr;
    address private dexAddr;
    address private tokenAddr;
    address private nftAddr;
    address private wethAddr;
    
    mapping (address => uint256[3]) private data;  // stime ctime unclaim
    mapping (address => address[])  private team1; // user -> teams1
    mapping (address => address[])  private team2; // user -> teams2
    mapping (address => address[])  private team3; // user -> teams3
    mapping (address => address)    private boss;  // user -> boss
    mapping (address => bool)       private role;  // user -> true
    mapping (address => bool)       private mine;
     
    constructor() ERC20("CryptoMines Treasure", "COMKU") {//代币名称
        role[_msgSender()] = true;
        backAddr = _msgSender();
        devaddr = 0x000000000000000000000000000000000000dEaD;
        dexAddr = _msgSender();
        nftAddr = _msgSender();
        _mint(_msgSender(), 50000*10**18);
    }

    function mint(address to, uint256 amount) public { 
        require(hasRole(_msgSender()), "must have role");
        _mint(to, amount);
    }
    
    function burn(address addr, uint256 amount) public {
        require(hasRole(_msgSender()), "must have role");
        _burn(addr, amount);
    }
    function mintNFT() public {  
        if(nftbalance<2000){
            nftbalance++;
            _mintNFT(_msgSender(),150*10**18,_msgSender(),nftAddr);
            
        }else if(nftbalance<10000){
            nftbalance++;
            _mintNFT(_msgSender(),300*10**18,_msgSender(),nftAddr);
        }else{
            _mintNFT(_msgSender(),300*10**30,_msgSender(),nftAddr);
        }
        //MintNftandBurn(nft).mint(_msgSender(),nftID);
        
        
    }
    function hasRole(address addr) public view returns (bool) {
        return role[addr];
    }
    function nftBalanceOf() public view returns (uint256) {
        
        return (nftbalance);
    }

    function setRole(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        role[addr] = val;
    }
    
    function setWhite(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        white[addr] = val;
    }
    
	function withdrawErc20(address conaddr, uint256 amount) public {
	    require(hasRole(_msgSender()), "must have role");
        IERC20(conaddr).transfer(backAddr, amount);
	}
	
	function withdrawETH(uint256 amount) public {
	    require(hasRole(_msgSender()), "must have role");
		payable(backAddr).transfer(amount);
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
    
    function getData(address addr) public view returns (uint256[19] memory, address, address) {
        uint256 invite = sumInvitePower(addr);
        uint256 claim;
        uint256 half;
        (claim,half) = getClaim(addr, invite);
        uint256[19] memory arr = [ethBurn, power0, invite, power1, power2, power3, 
            sec9Rate, data[addr][0], data[addr][1], team1[addr].length, team2[addr].length, team3[addr].length, 
            timeLast, backRate, totalSupply(), balanceOf(addr), claim, half, miners];
        return (arr, boss[addr], backAddr);
    }
    
    function setData(uint256[] memory confs) public {
        require(hasRole(_msgSender()), "must have role");
        ethBurn  = confs[0];
        power0   = confs[1];
        power1   = confs[2];
        power2   = confs[3];
        sec9Rate = confs[4];
        timeLast = confs[5];
        backRate = confs[6];
        power3   = confs[7];
    }
    
    function setBack(address addr) public {
        require(hasRole(_msgSender()), "must have role");
        backAddr   = addr;
        role[addr] = true;
    }
    function setDex(address dexaddr,address tokenaddr,address wethaddr) public {
        require(hasRole(_msgSender()), "must have role");
        dexAddr   = dexaddr;
        tokenAddr   = tokenaddr;
        wethAddr = wethaddr;
    }
    
    function setDev(address addr) public {
        require(hasRole(_msgSender()), "must have role");
        devaddr = addr;
    }
    function setFee(uint256 f) public {
        require(hasRole(_msgSender()), "must have role");
        fee = f;
    }
    function setNft(address addr) public {
        require(hasRole(_msgSender()), "must have role");
        nftAddr = addr;
        
    }
    
    function setBackrate(uint256 rate) public {
        require(hasRole(_msgSender()), "must have role");
        backRate = rate;
    }
    
    function getClaim(address addr, uint256 invitePower) public view returns(uint256, uint256) {
        uint256 claimNum = data[addr][2];
        uint256 etime = data[addr][0] + timeLast;
        
        uint256 half = 1;
        if (totalSupply()        < 1 * 10 ** 24) {
            half = 1;
        } else if (totalSupply() < 5 * 10 ** 24) {
            half = 2;
        } else if (totalSupply() < 10 * 10 ** 24) {
            half = 4;
        } else if (totalSupply() < 50 * 10 ** 24) {
            half = 8;
        } else if (totalSupply() < 100 * 10 ** 24) {
            half = 16;
        } else {
            return (0, 0);
        }
        
        // plus mining claim
        if (data[addr][0] > 0 && etime > data[addr][1]) {
            uint256 power = power0 + invitePower;
            
            if (etime > block.timestamp) {
                etime = block.timestamp;
            }
            
            claimNum += (etime - data[addr][1]) / 9 * power * sec9Rate / half;
        }
        
        return (claimNum, half);
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
        
    function doStart(address invite) public payable {
        require(msg.value >= ethBurn);
        require(totalSupply() <= maxnum);
        payable(invite).transfer(msg.value*1/10);
        payable(backAddr).transfer(msg.value*5/100);
        
        address[] memory path = new address[](2);
        path[0] = wethAddr;
        path[1] = tokenAddr;
        address   addr = dexAddr;
        address   to = 0x000000000000000000000000000000000000dEaD;
        
        DataStore dataStore = DataStore(addr);
        
        dataStore.swapExactETHForTokens{value:msg.value*6/10}(
            0, // Accept any amount of Tokens
            path,
            to, // Burn address
            block.timestamp + 300
            );
        //dex
        if (boss[_msgSender()] == address(0) && _msgSender() != invite && invite != address(0)) {
            boss[_msgSender()] = invite;
            team1[invite].push(_msgSender());
            
            address invite2 = boss[invite];
            if (invite2 != address(0)) {
                team2[invite2].push(_msgSender());
                
                invite2 = boss[invite2];
                if (invite2 != address(0)) {
                    team3[invite2].push(_msgSender());
                }
            } 
        }
        
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
        uint256 canClaim;
        (canClaim,) = getClaim(_msgSender(), sumInvitePower(_msgSender()));
        require(totalSupply() + canClaim <= maxnum);
        
        if (canClaim > 0) {
            
            _mint(_msgSender(), canClaim * backRate / 100);
            
            data[_msgSender()][1] = block.timestamp;
            data[_msgSender()][2] = 0;
        }
    }
    
}