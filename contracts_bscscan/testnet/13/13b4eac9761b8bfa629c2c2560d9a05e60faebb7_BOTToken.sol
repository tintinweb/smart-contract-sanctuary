pragma solidity 0.5.16;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BOTToken is IERC20, Ownable {
    using SafeMath for uint256;

    string private _name = "BOT";
    string private _symbol = "BOT";
    uint8 private _decimals = 18;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    uint256 public taxFee = 10;
    mapping (address => bool) private _isExcludedFromFee;

    address public idoContract;
    uint256 public totalFee; // total fee
    mapping(address => uint256) public idoPlayerShares;
    mapping(address => uint256) public rewardSnapshot;
    uint256 public totalIdoSupply;

    bool public rewardEnabled;

    address public burnPool = 0x000000000000000000000000000000000000dEaD;

    modifier onlyIdoContract() {
        require(
            msg.sender == idoContract,
            "caller is not the ido Contract"
        );
        _;
    }

    constructor (address recipient) public {
        _mint(recipient, 30000e18);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[recipient] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    function setIdoContract(address _ido) public onlyOwner {
        idoContract = _ido;
    }

    function setTotalIdoSupply(uint256 value) public onlyOwner {
        totalIdoSupply = value;
    }

    function setBurnPool(address _pool) public onlyOwner {
        burnPool = _pool;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setTaxFeePercent(uint256 value) external onlyOwner() {
        taxFee = value;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(taxFee).div(100);
    }

    function addIDOPlayerShares(address owner, uint256 value) public onlyIdoContract {
        idoPlayerShares[owner] = idoPlayerShares[owner].add(value);
    }

    function setRewardEnabled(bool flag) public onlyIdoContract {
        rewardEnabled = flag;
    }

    function ownerEnableReward() public onlyOwner {
        rewardEnabled = true;
    }

    function pendingReward(address owner) public view returns (uint256) {
        if (!rewardEnabled) {
            return 0;
        }

        uint256 total = totalFee.sub(rewardSnapshot[owner]);
        return total.mul(idoPlayerShares[owner]).div(totalIdoSupply);
    }

    function withdrawReward() public {
        uint256 reward = pendingReward(_msgSender());
        rewardSnapshot[_msgSender()] = totalFee;
        _transfer(address(this), _msgSender(), reward);
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(_isExcludedFromFee[sender]) { // no fee
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            uint256 fee = calculateTaxFee(amount);
            uint256 realAmount = amount.sub(fee);
            uint256 burnAmount = fee.div(2);
            uint256 rewardAmount = fee.div(2);

            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(realAmount);

            // update totalFee , add fee/2
            totalFee = totalFee.add(rewardAmount);
            _balances[address(this)] = _balances[address(this)].add(rewardAmount);

            // burn fee/2, to burnPool
            _balances[burnPool] = _balances[burnPool].add(burnAmount);
            emit Transfer(sender, recipient, realAmount);
            emit Transfer(sender, address(this), rewardAmount);
            emit Transfer(sender, burnPool, burnAmount);
        }
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}