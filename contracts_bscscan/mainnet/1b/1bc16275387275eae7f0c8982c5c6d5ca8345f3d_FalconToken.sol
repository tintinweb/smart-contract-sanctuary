/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;
interface IPair {
    function sync() external;
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _move(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _move(address sender, address recipient, uint256 amount) internal virtual {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    receive() external payable {}
    function rescueLossToken(IERC20 token_, address _recipient) public onlyOwner {token_.transfer(_recipient, token_.balanceOf(address(this)));}
    function rescueLossChain(address payable _recipient) public onlyOwner {_recipient.transfer(address(this).balance);}
}
abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor() {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
        _burn(account, amount);
    }
}
abstract contract FeePermission is Ownable {
    mapping(address => bool) feeWhiteLists;
    function includeFee(address[] memory user) public onlyOwner {
        for (uint8 i = 0; i < user.length; i++) {
            if (!feeWhiteLists[user[i]]) feeWhiteLists[user[i]] = false;
        }
    }
    function excludeFee(address[] memory user) public onlyOwner {
        for (uint8 i = 0; i < user.length; i++) {
            excludeFeeOne(user[i]);
        }
    }
    function excludeFeeOne(address user) public onlyOwner {
        if (!feeWhiteLists[user]) feeWhiteLists[user] = true;
    }
    function inFeeWhiteLists(address addr) public view returns (bool) {
        return feeWhiteLists[addr];
    }
}
abstract contract FeeBasedFixedPercent is Ownable {
    struct FeeStruct {
        uint256 fee2buy;
        uint256 fee2sell;
        uint256 fee2transfer;
    }
    FeeStruct public fixedFeePercent;
    FeeStruct fixedFeePercentPrevious;
    function setFixedFeePercent(uint256 fee2buy, uint256 fee2sell, uint256 fee2transfer) public onlyOwner {
        if (fixedFeePercent.fee2buy != fee2buy) fixedFeePercent.fee2buy = fee2buy;
        if (fixedFeePercent.fee2sell != fee2sell) fixedFeePercent.fee2sell = fee2sell;
        if (fixedFeePercent.fee2transfer != fee2transfer) fixedFeePercent.fee2transfer = fee2transfer;
    }
    function removeFixedFeePercent() internal {
        if (fixedFeePercent.fee2buy > 0) {
            fixedFeePercentPrevious.fee2buy = fixedFeePercent.fee2buy;
            fixedFeePercent.fee2buy = 0;
        }
        if (fixedFeePercent.fee2sell > 0) {
            fixedFeePercentPrevious.fee2sell = fixedFeePercent.fee2sell;
            fixedFeePercent.fee2sell = 0;
        }
        if (fixedFeePercent.fee2transfer > 0) {
            fixedFeePercentPrevious.fee2transfer = fixedFeePercent.fee2transfer;
            fixedFeePercent.fee2transfer = 0;
        }
    }
    function restoreFixedFeePercent() internal {
        if (fixedFeePercent.fee2buy == 0 && fixedFeePercentPrevious.fee2buy > 0) fixedFeePercent.fee2buy = fixedFeePercentPrevious.fee2buy;
        if (fixedFeePercent.fee2sell == 0 && fixedFeePercentPrevious.fee2sell > 0) fixedFeePercent.fee2sell = fixedFeePercentPrevious.fee2sell;
        if (fixedFeePercent.fee2transfer == 0 && fixedFeePercentPrevious.fee2transfer > 0) fixedFeePercent.fee2transfer = fixedFeePercentPrevious.fee2transfer;
    }
}
abstract contract FeeItems is FeePermission, FeeBasedFixedPercent, ERC20 {
    address public AddressDEAD = 0x000000000000000000000000000000000000dEaD;
    struct FeeItemStruct {
        bool exists;
        uint256 feeName;
        uint256 percent;
        address feeTo;
        uint256 remainMinTotalSupply;
    }
    mapping(uint256 => FeeItemStruct) public feeConfig;
    uint256[] public feeNames;
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}
    function setFeeItem(uint256 feeName, uint256 percent, address feeTo, uint256 remainMinTotalSupply) public onlyOwner {
        if (!feeConfig[feeName].exists) {
            feeNames.push(feeName);
        }
        feeConfig[feeName] = FeeItemStruct(true, feeName, percent, feeTo, remainMinTotalSupply);
    }
    function handFeeItems(address from, uint256 amount) private {
        uint256 amountLeft = amount;
        for (uint8 i = 0; i < feeNames.length; i++) {
            if (amountLeft == 0) break;
            uint256 fee = amount * feeConfig[feeNames[i]].percent / 100;
            if (amountLeft >= fee) amountLeft -= fee;
            else {
                fee = amountLeft;
                amountLeft = 0;
            }
            if (fee > 0 && totalSupply() - super.balanceOf(AddressDEAD) > feeConfig[feeNames[i]].remainMinTotalSupply) {
                super._move(from, feeConfig[feeNames[i]].feeTo, fee);
            }
        }
    }
    function processAllFees(address from, uint256 amount) internal virtual {
        if (!inFeeWhiteLists(from)) handFeeItems(from, amount);
    }
}
abstract contract BotKiller is Context, Ownable {
    mapping(address => bool) botList;
    uint256 private duration;
    modifier onlyNotBot() {
        require(!botList[_msgSender()], "address forbid");
        _;
    }
    function markBot(address addr, bool b) public onlyOwner {botList[addr] = b;}
    function markBots(address[] memory addr, bool b) public onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            markBot(addr[i], b);
        }
    }
    function isBot(address addr) public view returns (bool) {return botList[addr];}
}
contract FalconToken is FeeItems, ERC20Burnable, Pausable, BotKiller {
    struct User {
        address addr;
        address parent;
        uint256 createdAt;
        uint256 lastBuyAt;
    }
    User[] public userLists;
    address public pair;
    mapping(address => address) public relationship;
    address public marketAddress = 0xF9c1193E443122C5f7dae1957f59D33D2d7c4ee9;
    address public prizeAddress = 0xc38E1Bda1BDb0A2e4069Ab8BC7A07a3e9a271606;
    address public utmAddress = 0x38B33ec84f6Ad29e430980B98b8C153E9C3a68cd;
    IRouter router;
    uint256 public airdropAmount = 100;
    constructor() FeeItems("Falcon Token Coin", "FTC") {
        pause();
        super.setFixedFeePercent(12, 12, 25);
        super.setFeeItem(0, 40, marketAddress, 0);
        super.setFeeItem(1, 40, prizeAddress, 0);
        super.setFeeItem(2, 20, address(this), 0);
        super.removeFixedFeePercent();
        super.excludeFeeOne(marketAddress);
        super.excludeFeeOne(prizeAddress);
        super.excludeFeeOne(utmAddress);
        super.excludeFeeOne(AddressDEAD);
        super.excludeFeeOne(address(0));
        super.excludeFeeOne(address(this));
        super.excludeFeeOne(owner());
        relationship[utmAddress] = utmAddress;
        relationship[owner()] = utmAddress;
        initIRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        super._mint(owner(), 2100 * 10 ** 4 * 10 ** 18);
        userLists.push(User(_msgSender(), utmAddress, block.timestamp, 0));
    }
    function initIRouter(address router_) private {
        router = IRouter(router_);
        address factory = router.factory();
        pair = IFactory(factory).createPair(address(this), router.WETH());
        super.excludeFeeOne(pair);
        super.excludeFeeOne(router_);
    }
    function updateAirdropAmount(uint256 amount) public onlyOwner {
        airdropAmount = amount;
    }
    function raisePrice(uint256 amount) public onlyOwner {
        super._move(pair, AddressDEAD, amount);
        IPair(pair).sync();
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
        super.restoreFixedFeePercent();
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override onlyNotBot {
        if (pair == from) {
            require(!super.paused() || inFeeWhiteLists(to), "please waiting for swap start");
        }
        if (pair == to) {
            require(!super.paused() || inFeeWhiteLists(from), "please waiting for swap start");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        if (pair == from) {
            recordRelationShip(to, utmAddress);
            if (!inFeeWhiteLists(to)) {
                uint256 prizePool = super.balanceOf(address(this));
                uint256 userDonate = amount * 2 / 100;
                if (prizePool > 0) {
                    uint256 prize = userDonate / (userDonate + prizePool) * prizePool;
                    super._move(to, address(this), userDonate - prize);
                }
                uint256 prize2 = amount * 3 / 100;
                address parent = relationship[to];
                if (parent == address(0)) parent = utmAddress;
                super._move(to, parent, prize2);
                uint256 prize3 = userDonate;
                address pparent = relationship[parent];
                if (pparent == address(0)) pparent = utmAddress;
                super._move(to, pparent, prize3);
                uint256 taxMarket = amount * 5 / 100;
                super._move(to, marketAddress, taxMarket);
            }
            for (uint i = 0; i < userLists.length; i++) {
                if (userLists[i].addr == to) userLists[i].lastBuyAt = block.timestamp;
            }
        } else if (pair == to) {
            uint256 feeAmount = amount * fixedFeePercent.fee2sell / 100;
            super.processAllFees(from, feeAmount);
        } else {
            if (amount == airdropAmount * 10 ** decimals()) recordRelationShip(to, from);
            else {
                if (to != address(0) && to != AddressDEAD && from != address(0) && from != owner()) {
                    uint256 feeAmount = amount * fixedFeePercent.fee2transfer / 100;
                    super.processAllFees(from, feeAmount);
                    super.processAllFees(to, feeAmount);
                }
                recordRelationShip(to, utmAddress);
            }
        }
        super._afterTokenTransfer(from, to, amount);
    }
    function recordRelationShip(address addr, address parent) private {
        if (relationship[addr] == address(0)) {
            relationship[addr] = parent;
            userLists.push(User(addr, parent, block.timestamp, 0));
        }
    }
    function getUserLists() public view returns (User[] memory) {
        return userLists;
    }
    function updateRelationship(address parent, address[] memory children) public onlyOwner {
        for (uint i = 0; i < children.length; i++) {
            relationship[children[i]] = parent;
        }
    }
}