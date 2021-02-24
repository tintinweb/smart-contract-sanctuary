/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

pragma solidity =0.8.0;

// ----------------------------------------------------------------------------
// NBU token main contract (2020)
//
// Symbol       : NBU
// Name         : Nimbus
// Total supply : 1.000.000.000 (burnable)
// Decimals     : 18
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

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


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: addition overflow");
    }
    
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract NBU is IERC20, Ownable, Pausable {
    using SafeMath for uint;

    mapping (address => mapping (address => uint)) private _allowances;
    
    mapping (address => uint) private _unfrozenBalances;

    mapping (address => uint) private _vestingNonces;
    mapping (address => mapping (uint => uint)) private _vestingAmounts;
    mapping (address => mapping (uint => uint)) private _unvestedAmounts;
    mapping (address => mapping (uint => uint)) private _vestingTypes; //0 - multivest, 1 - single vest, > 2 give by vester id
    mapping (address => mapping (uint => uint)) private _vestingReleaseStartDates;

    uint private _totalSupply = 1_000_000_000e18;
    string private constant _name = "Nimbus";
    string private constant _symbol = "NBU";
    uint8 private constant _decimals = 18;

    uint private vestingFirstPeriod = 60 days;
    uint private vestingSecondPeriod = 152 days;

    uint public giveAmount;
    mapping (address => bool) public vesters;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping (address => uint) public nonces;

    event Unvest(address user, uint amount);

    constructor () {
        _unfrozenBalances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply); 

        uint chainId = block.chainid;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(_name)),
                chainId,
                address(this)
            )
        );
        giveAmount = _totalSupply / 10;
    }

    function approve(address spender, uint amount) external override whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint amount) external override whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "NBU::transferFrom: transfer amount exceeds allowance"));
        return true;
    }

    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "NBU::permit: invalid signature");
        require(signatory == owner, "NBU::permit: unauthorized");
        require(block.timestamp <= deadline, "NBU::permit: signature expired");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "NBU::decreaseAllowance: decreased allowance below zero"));
        return true;
    }

    function unvest() external whenNotPaused returns (uint unvested) {
        require (_vestingNonces[msg.sender] > 0, "NBU::unvest:No vested amount");
        for (uint i = 1; i <= _vestingNonces[msg.sender]; i++) {
            if (_vestingAmounts[msg.sender][i] == _unvestedAmounts[msg.sender][i]) continue;
            if (_vestingReleaseStartDates[msg.sender][i] > block.timestamp) break;
            uint toUnvest = block.timestamp.sub(_vestingReleaseStartDates[msg.sender][i]).mul(_vestingAmounts[msg.sender][i]) / vestingSecondPeriod;
            if (toUnvest > _vestingAmounts[msg.sender][i]) {
                toUnvest = _vestingAmounts[msg.sender][i];
            } 
            uint totalUnvestedForNonce = toUnvest;
            toUnvest = toUnvest.sub(_unvestedAmounts[msg.sender][i]);
            unvested = unvested.add(toUnvest);
            _unvestedAmounts[msg.sender][i] = totalUnvestedForNonce;
        }
        _unfrozenBalances[msg.sender] = _unfrozenBalances[msg.sender].add(unvested);
        emit Unvest(msg.sender, unvested);
    }

    function give(address user, uint amount, uint vesterId) external {
        require (giveAmount > amount, "NBU::give: give finished");
        require (vesters[msg.sender], "NBU::give: not vester");
        giveAmount = giveAmount.sub(amount);
        _vest(user, amount, vesterId);
     }

    function vest(address user, uint amount) external {
        require (vesters[msg.sender], "NBU::vest: not vester");
        _vest(user, amount, 1);
    }

    function burnTokens(uint amount) external onlyOwner returns (bool success) {
        require(amount <= _unfrozenBalances[owner], "NBU::burnTokens: exceeds available amount");
        _unfrozenBalances[owner] = _unfrozenBalances[owner].sub(amount, "NBU::burnTokens: transfer amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount, "NBU::burnTokens: overflow");
        emit Transfer(owner, address(0), amount);
        return true;
    }



    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowances[owner][spender];
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        uint amount = _unfrozenBalances[account];
        if (_vestingNonces[account] == 0) return amount;
        for (uint i = 1; i <= _vestingNonces[account]; i++) {
            amount = amount.add(_vestingAmounts[account][i]).sub(_unvestedAmounts[account][i]);
        }
        return amount;
    }

    function availableForUnvesting(address user) external view returns (uint unvestAmount) {
        if (_vestingNonces[user] == 0) return 0;
        for (uint i = 1; i <= _vestingNonces[user]; i++) {
            if (_vestingAmounts[user][i] == _unvestedAmounts[user][i]) continue;
            if (_vestingReleaseStartDates[user][i] > block.timestamp) break;
            uint toUnvest = block.timestamp.sub(_vestingReleaseStartDates[user][i]).mul(_vestingAmounts[user][i]) / vestingSecondPeriod;
            if (toUnvest > _vestingAmounts[user][i]) {
                toUnvest = _vestingAmounts[user][i];
            } 
            toUnvest = toUnvest.sub(_unvestedAmounts[user][i]);
            unvestAmount = unvestAmount.add(toUnvest);
        }
    }

    function availableForTransfer(address account) external view returns (uint) {
        return _unfrozenBalances[account];
    }

    function vestingInfo(address user, uint nonce) external view returns (uint vestingAmount, uint unvestedAmount, uint vestingReleaseStartDate, uint vestType) {
        vestingAmount = _vestingAmounts[user][nonce];
        unvestedAmount = _unvestedAmounts[user][nonce];
        vestingReleaseStartDate = _vestingReleaseStartDates[user][nonce];
        vestType = _vestingTypes[user][nonce];
    }

    function vestingNonces(address user) external view returns (uint lastNonce) {
        return _vestingNonces[user];
    }



    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "NBU::_approve: approve from the zero address");
        require(spender != address(0), "NBU::_approve: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "NBU::_transfer: transfer from the zero address");
        require(recipient != address(0), "NBU::_transfer: transfer to the zero address");

        _unfrozenBalances[sender] = _unfrozenBalances[sender].sub(amount, "NBU::_transfer: transfer amount exceeds balance");
        _unfrozenBalances[recipient] = _unfrozenBalances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _vest(address user, uint amount, uint vestType) private {
        uint nonce = ++_vestingNonces[user];
        _vestingAmounts[user][nonce] = amount;
        _vestingReleaseStartDates[user][nonce] = block.timestamp + vestingFirstPeriod;
        _unfrozenBalances[owner] = _unfrozenBalances[owner].sub(amount);
        _vestingTypes[user][nonce] = vestType;
        emit Transfer(owner, user, amount);
    }




    function multisend(address[] memory to, uint[] memory values) external onlyOwner returns (uint) {
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        _unfrozenBalances[owner] = _unfrozenBalances[owner].sub(sum, "NBU::multisend: transfer amount exceeds balance");
        for (uint i; i < to.length; i++) {
            _unfrozenBalances[to[i]] = _unfrozenBalances[to[i]].add(values[i], "NBU::multisend: transfer amount exceeds balance");
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }

    function multivest(address[] memory to, uint[] memory values) external onlyOwner returns (uint) { 
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        _unfrozenBalances[owner] = _unfrozenBalances[owner].sub(sum, "NBU::multivest: transfer amount exceeds balance");
        for (uint i; i < to.length; i++) {
            uint nonce = ++_vestingNonces[to[i]];
            _vestingAmounts[to[i]][nonce] = values[i];
            _vestingReleaseStartDates[to[i]][nonce] = block.timestamp + vestingFirstPeriod;
            _vestingTypes[to[i]][nonce] = 0;
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }

    function updateVesters(address vester, bool isActive) external onlyOwner { 
        vesters[vester] = isActive;
    }

    function updateGiveAmount(uint amount) external onlyOwner { 
        require (_unfrozenBalances[owner] > amount, "NBU::updateGiveAmount: exceed owner balance");
        giveAmount = amount;
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(owner, tokens);
    }

    function acceptOwnership() public override {
        uint amount = _unfrozenBalances[owner];
        _unfrozenBalances[newOwner] = amount;
        _unfrozenBalances[owner] = 0;
        emit Transfer(owner, newOwner, amount);
        super.acceptOwnership();
    }
}