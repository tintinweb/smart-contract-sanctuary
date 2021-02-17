/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity 0.5.10;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address addr) public view returns (uint256) {
        return _balances[addr];
    }

    function allowance(address addr, address spender) public view returns (uint256) {
        return _allowed[addr][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}

contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Caller is not the owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract SmartPool250 is ERC20, Ownable {

    string private _name = "Smartsel";
    string private _symbol = "SATL";
    uint8 private _decimals = 18;

    struct StartUp {
        address account;
        uint256 goal;
        uint256 time;
        uint256[] accumulated;
    }

    StartUp startup;

    struct User {
        bool active;
        uint256 time;
        uint256 checkpoint;
        uint256 reserved;
    }

    mapping (address => User) holders;
    mapping (uint256 => uint256) activated;

    uint256 public amountOfStakes;

    uint256 public stakingRequirement = 10e18;
    uint256 public limitOfStakes = 250;
    uint256 public holderReward = 10e18;

    uint256 tokenPriceIncremental = 0.00001 ether;
    uint256 magnitude = 1e18;

    uint256 date;
    uint256 public period = 30 days;

    address payable public wallet;
    address payable public dev;

    IERC20 public BITL;
    uint256 public priceBITL = 1e18;
    bool public ownerMode;
    bool public deprecated;

    event Purchased(address indexed sender, address indexed recipient, uint256 amountSATL);
    event Sold(address indexed sender, address indexed recipient, uint256 amountSATL, uint256 amountETH);
    event StakeActivated(address indexed account, uint256 time);
    event StakeDeactivated(address indexed account, uint256 time);
    event DividendsPayed(address indexed account, address indexed recipient, uint256 amount);
    event ExchangedSATLtoBITL(address indexed from, address indexed recipient,  uint256 amountSATL, uint256 amountBITL);
    event ExchangedBITLtoETH(address indexed from, address indexed recipient, uint256 amountBITL, uint256 amountETH);
    event InitStartUp(address wallet, uint256 goal);
    event EndStartUp(address wallet, uint256 goal);
    event Donate(address indexed sender, uint256 amount);

    constructor(address BITLAddr, address payable walletAddr, address payable devAddr) public {
        require(BITLAddr != address(0) && walletAddr != address(0) && devAddr != address(0));

        date = block.timestamp;
        BITL = IERC20(BITLAddr);
        wallet = walletAddr;
        dev = devAddr;

        ownerMode = true;

        purchase(msg.sender);
    }

    function() external payable {
        if (msg.value > 0) {
            purchase(msg.sender);
        } else {
            withdrawDividends(msg.sender);
        }
    }

    modifier createStake(address account, uint256 value) {
        _;
        if (
            _balances[account] >= stakingRequirement &&
            _balances[account].sub(value) < stakingRequirement &&
            amountOfStakes < limitOfStakes
            ) {

            if (startup.account != address(0))  {
                accumulate();
            }

            holders[account].active = true;
            holders[account].time = block.timestamp;
            holders[account].checkpoint = block.timestamp;

            amountOfStakes++;

            uint256 idx = (block.timestamp.sub(date)).div(period);
            activated[idx]++;

            emit StakeActivated(account, block.timestamp);

        }
    }

    modifier removeStake(address account, uint256 value) {
        _;
        if (
            _balances[account] < stakingRequirement &&
            _balances[account].add(value) >= stakingRequirement
            ) {

            if (startup.account != address(0))  {
                accumulate();
            }

            uint256 divs = getDividends(account);
            if (divs > 0) {
                holders[account].reserved = divs;
            }
            holders[account].active = false;

            amountOfStakes--;

            uint256 idx = (block.timestamp.sub(date)).div(period);
            if (idx == (holders[account].time.sub(date)).div(period)) {
                activated[idx]--;
            }

            emit StakeDeactivated(account, block.timestamp);
        }
    }

    function accumulate() internal {
        uint256 idx = (block.timestamp - ((startup.time - date) / period * period + date)) / period;

        if (idx > 0 && startup.accumulated.length < idx) {
            uint256 len = startup.accumulated.length;
            for (uint256 i = 0; i < idx - len; i++) {
                startup.accumulated.push(amountOfStakes * holderReward);
            }
        }

    }

    function _transfer(address from, address to, uint256 value) internal removeStake(from, value) createStake(to, value) {
        require(from != to);

        super._transfer(from, to, value);

    }

    function _mint(address account, uint256 value) internal createStake(account, value) {

        super._mint(account, value);

    }

    function _burn(address account, uint256 amount) internal removeStake(account, amount) {

        super._burn(account, amount);

    }

    function purchase(address recipient) public payable {

        uint256 value;
        uint256 amount;
        uint256 allowed = BITL.allowance(recipient, address(this));

        if (msg.value > 0) {
            value = msg.value;
        } else if (allowed > 0) {
            value = allowed.mul(priceBITL).mul(getCurrentPrice()).div(magnitude).div(magnitude);
            BITL.transferFrom(recipient, address(this), allowed);
        }

        if (amountOfStakes > 0) {
            amount = value.div(getCurrentPrice()).mul(magnitude);
        } else {
            amount = 10e18;
        }

        _purchase(recipient, amount);

    }

    function _purchase(address recipient, uint256 value) internal {

        _mint(recipient, value);

        emit Purchased(msg.sender, recipient, value);
    }

    function sell(address payable recipient, uint256 value) public {

        uint256 amountETH = value.mul(getCurrentPrice()).div(magnitude);

        _burn(msg.sender, value);

        recipient.transfer(amountETH);

        emit Sold(msg.sender, recipient, value, amountETH);
    }

    function withdrawDividends(address recipient) public {
        require(holders[msg.sender].active);

        uint256 reward = getDividends(msg.sender);

        holders[msg.sender].checkpoint = block.timestamp;
        holders[msg.sender].reserved = 0;

        _mint(recipient, reward);

        emit DividendsPayed(msg.sender, recipient, reward);
    }

    function receiveApproval(address account, uint256 value, address token, bytes memory extraData) public {
        require(token == address(BITL));
        uint256 uintData;
        assembly { uintData := mload(add(extraData, add(0x20, 0))) }
        if (uintData == 0) {
            purchase(account);
        } else {
            exchangeBITLtoETH(account, account, value);
        }
    }

    function exchangeBITLtoETH(address from, address recipient, uint256 value) public {
        if (ownerMode) {
            require(isOwner(tx.origin));
        }

        uint256 amountETH = value.mul(priceBITL).mul(getCurrentPrice()).div(magnitude).div(magnitude);

        BITL.transferFrom(from, address(this), value);
        address(uint160(recipient)).transfer(amountETH);

        emit ExchangedBITLtoETH(from, recipient, value, amountETH);
    }

    function exchangeSATLtoBITL(address recipient, uint256 value) public {

        uint256 amountBITL = value.mul(priceBITL).div(magnitude);

        _burn(msg.sender, value);
        BITL.transfer(recipient, amountBITL);

        emit ExchangedSATLtoBITL(msg.sender, recipient, value, amountBITL);
    }

    function initiateStartUp(address account, uint256 goal) public onlyOwner {
        require(account != address(0));

        startup.account = account;
        startup.goal = goal;
        startup.time = block.timestamp;
        startup.accumulated.push(payouts().mul(holderReward).mul(nextDate().sub(block.timestamp)).div(period));

        emit InitStartUp(account, goal);
    }

    function setStartUpWallet(address payable account) public onlyOwner {
        require(account != address(0));

        startup.account = account;
    }

    function setStartUpGoal(uint256 goal) public onlyOwner {
        require(goal != 0);

        startup.goal = goal;
    }

    function payToStartUp() public onlyOwner {

        uint256 amount = getAccumulated();

        _mint(startup.account, amount.mul(85).div(100));
        _mint(dev, amount.mul(10).div(100));
        _mint(wallet, amount.mul(5).div(100));

        emit EndStartUp(startup.account, amount);

        delete startup;
    }

    function setPriceBITL(uint256 value) public onlyOwner {
        require(value != 0);
        priceBITL = value;
    }

    function switchOwnerMode() public onlyOwner {
        if (!ownerMode) {
            ownerMode = true;
        } else {
            ownerMode = false;
        }
    }

    function switchDeprecated() public onlyOwner {
        if (!deprecated) {
            deprecated = true;
        } else {
            deprecated = false;
        }
    }

    function setWallet(address payable account) public onlyOwner {
        require(account != address(0));

        wallet = account;
    }

    function withdraw(address payable recipient, uint256 value) public onlyOwner {

        recipient.transfer(value);

    }

    function donate() public payable {

        uint256 allowed = BITL.allowance(msg.sender, address(this));

        if (allowed > 0) {
            BITL.transferFrom(msg.sender, address(this), allowed);
        }

        emit Donate(msg.sender, msg.value);

    }

    function getDividends(address account) public view returns(uint256) {
        if (deprecated) {
            return 0;
        }

        uint256 reward = holders[account].reserved;

        if (holders[account].active) {
            if (holders[account].time == holders[account].checkpoint) {

                if (block.timestamp < (holders[account].time - date) / period * period + period + date) {

                    reward = 0;

                } else {
                    uint256 next = ((holders[account].time - date) / period * period + period + date);

                    uint256 multiplier = (block.timestamp - next) / period;

                    reward = holderReward * (next - holders[account].time) / period + holderReward * multiplier;

                    return reward;
                }

            } else {

                if (block.timestamp < (holders[account].checkpoint - date) / period * period + period + date) {

                    reward = 0;

                } else {
                    uint256 multiplier = (block.timestamp - ((holders[account].checkpoint - date) / period * period + date)) / period;

                    reward = holderReward * multiplier;
                }

            }
        }

        return reward;

    }

    function getAccumulated() public view returns(uint256) {
        if (startup.account == address(0)) {
            return 0;
        }

        uint256 payout;

        uint256 idx = (block.timestamp - ((startup.time - date) / period * period + date)) / period;
        if (idx == 0) {
            return 0;
        }

        for (uint256 i = 0; i < startup.accumulated.length; i++) {

            payout += startup.accumulated[i];

        }

        if (idx > startup.accumulated.length) {
            for (uint256 i = 0; i < idx - startup.accumulated.length; i++) {

                payout += amountOfStakes * holderReward;

            }
        }

        if (payout < startup.goal) {
            return payout;
        } else {
            return startup.goal;
        }

    }

    function activatedStakes() public view returns(uint256) {
        return activated[(block.timestamp - date) / period];
    }

    function payouts() public view returns(uint256) {
        return amountOfStakes - activatedStakes();
    }

    function getCurrentPrice() public view returns(uint256) {
        uint256 price = ((5e16 + activatedStakes() * tokenPriceIncremental) - (5e16 - payouts() * tokenPriceIncremental)) * magnitude / (5e16 + activatedStakes() * tokenPriceIncremental);
        uint256 inaccuracy = price % tokenPriceIncremental;
        if (inaccuracy > 0) {
            price = price - inaccuracy + tokenPriceIncremental;
        }
        return price;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getAmountOfFreeStakes() public view returns(uint256) {
        return limitOfStakes - amountOfStakes;
    }

    function nextDate() public view returns(uint256) {
        return(date + period + (block.timestamp - date) / period * period);
    }

    function getStartUpInfo() public view returns(address, uint256) {
        return(startup.account, startup.goal);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

}