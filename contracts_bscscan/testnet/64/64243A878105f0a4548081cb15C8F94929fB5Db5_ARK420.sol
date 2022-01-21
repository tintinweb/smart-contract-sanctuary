pragma solidity =0.8.0;

// ----------------------------------------------------------------------------
// ARK420 token main contract (2022)
//
// Symbol       : ARK420
// Name         : Ark420
// Total supply : 4.200.000.000 (burnable)
// Decimals     : 18
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getOwner() external view returns (address);

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

    function transferOwnership(address transferOwner) external onlyOwner {
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

contract ARK420 is IBEP20, Ownable, Pausable {
    mapping (address => mapping (address => uint)) private _allowances;
    
    mapping (address => uint) private _unfrozenBalances;

    mapping (address => uint) private _vestingNonces;
    mapping (address => mapping (uint => uint)) private _vestingAmounts;
    mapping (address => mapping (uint => uint)) private _unvestedAmounts;
    mapping (address => mapping (uint => uint)) private _vestingTypes; //0 - multivest, 1 - single vest, > 2 give by vester id
    mapping (address => mapping (uint => uint)) private _vestingReleaseStartDates;
    mapping (address => mapping (uint => uint)) private _vestingSecondPeriods;

    uint private _totalSupply = 4_200_000_000e18;
    string private constant _name = "ARK420";
    string private constant _symbol = "ARK420";
    uint8 private constant _decimals = 18;

    uint public constant vestingSaleReleaseStart = 1642724700; // 00:00:00 20 April 2022 GMT+00:00 1650412800
    uint public constant vestingSaleSecondPeriod = 1 hours; // 1/365 each day

    uint public constant vestingTeamReleaseStart = 1642724700 + 10 minutes; // 00:00:00 20 October 2022 GMT+00:00 1666213200
    uint public constant vestingTeamSecondPeriod = 1 hours; // 1/365 each day

    uint public constant vestingFoundationReleaseStart = 1642724700 + 60 minutes; // 00:00:00 20 April + 2 Months 2022 GMT+00:00 1650412800
    uint public constant vestingFoundationSecondPeriod = 1 seconds; // immediately release

    address public stakingContract; // can be set once
    uint public constant stakingContractRelease = 1642724700; // 00:00:00 20 April 2022 GMT+00:00 1650412800
    uint public stakingAmount;

    address public liquidityContract; // can be set once
    uint public constant liquidityContractRelease = 1642724700; // 00:00:00 20 April 2022 GMT+00:00 1650412800
    uint public liquidityAmount;

    address public exchangeListingContract; // can be set once
    uint public constant exchangeListingContractRelease = 1642724700; // 00:00:00 20 April 2022 GMT+00:00 1650412800
    uint public exchangeListingAmount;

    uint public giveAmount;
    mapping (address => bool) public vesters;

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping (address => uint) public nonces;

    event Unvest(address indexed user, uint amount);

    constructor (address[] memory advisors, address[] memory team, address[] memory foundation, address support) {
        require(support != address(0), "ARK420: Zero address");
        require(support != msg.sender, "ARK420: Owner can't be support address");
        _unfrozenBalances[owner] = _totalSupply;

        uint256 toAdvisors = _totalSupply * 5 / 100; // 5% to advisors
        for (uint i = 0; i < advisors.length; i++) {
            _vest(advisors[i], toAdvisors / advisors.length, 1, vestingTeamReleaseStart, vestingTeamReleaseStart + vestingTeamSecondPeriod);
        }

        uint256 toTeam = _totalSupply * 11 / 100; // 11% to team
        for (uint i = 0; i < team.length; i++) {
            _vest(team[i], toTeam / team.length, 1, vestingTeamReleaseStart, vestingTeamReleaseStart + vestingTeamSecondPeriod);
        }

        uint256 toFoundation = _totalSupply * 25 / 100; // 25% to foundation
        for (uint i = 0; i < foundation.length; i++) {
            _vest(foundation[i], toFoundation / foundation.length, 1, vestingFoundationReleaseStart, vestingFoundationReleaseStart + vestingFoundationSecondPeriod);
        }

        uint256 toExchangeListing = _totalSupply * 8 / 100; // 8% to exchange listing
        exchangeListingAmount += toExchangeListing;
        _unfrozenBalances[owner] -= exchangeListingAmount;

        uint256 toStaking = _totalSupply * 25 / 100; // 25% to staking
        stakingAmount += toStaking;
        _unfrozenBalances[owner] -= stakingAmount;

        uint256 toLiquidity = _totalSupply * 1 / 100; // 1% to liquidity
        liquidityAmount += toLiquidity;
        _unfrozenBalances[owner] -= liquidityAmount;
        
        uint256 tosupport = _unfrozenBalances[owner] * 4 / 100; // 4% of public sale to vested for support wallet
        _vest(support, tosupport, 1, vestingSaleReleaseStart, vestingSaleReleaseStart + vestingSaleSecondPeriod);

        // rest to p2p
        emit Transfer(address(0), owner, _unfrozenBalances[owner]);

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

    receive() payable external {
        revert();
    }

    function getOwner() public override view returns (address) {
        return owner;
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
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ARK420::transferFrom: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "ARK420::permit: invalid signature");
        require(signatory == owner, "ARK420::permit: unauthorized");
        require(block.timestamp <= deadline, "ARK420::permit: signature expired");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ARK420::decreaseAllowance: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    function unvest() external whenNotPaused returns (uint unvested) {
        require (_vestingNonces[msg.sender] > 0, "ARK420::unvest:No vested amount");
        for (uint i = 1; i <= _vestingNonces[msg.sender]; i++) {
            if (_vestingAmounts[msg.sender][i] == _unvestedAmounts[msg.sender][i]) continue;
            if (_vestingReleaseStartDates[msg.sender][i] > block.timestamp) break;
            uint toUnvest = (block.timestamp - _vestingReleaseStartDates[msg.sender][i]) * _vestingAmounts[msg.sender][i] / (_vestingSecondPeriods[msg.sender][i] - _vestingReleaseStartDates[msg.sender][i]);
            if (toUnvest > _vestingAmounts[msg.sender][i]) {
                toUnvest = _vestingAmounts[msg.sender][i];
            } 
            uint totalUnvestedForNonce = toUnvest;
            toUnvest -= _unvestedAmounts[msg.sender][i];
            unvested += toUnvest;
            _unvestedAmounts[msg.sender][i] = totalUnvestedForNonce;
        }
        _unfrozenBalances[msg.sender] += unvested;
        emit Unvest(msg.sender, unvested);
    }

    function give(address user, uint amount, uint vesterId) external {
        require (giveAmount > amount, "ARK420::give: give finished");
        require (vesters[msg.sender], "ARK420::give: not vester");
        giveAmount -= amount;
        _vest(user, amount, vesterId, vestingSaleReleaseStart, vestingSaleReleaseStart + vestingSaleSecondPeriod);
    }

    function vest(address user, uint amount) external {
        require (vesters[msg.sender], "ARK420::vest: not vester");
        _vest(user, amount, 1, vestingSaleReleaseStart, vestingSaleReleaseStart + vestingSaleSecondPeriod);
    }

    function setExchangeListing(address exchangeListing) external onlyOwner { 
        require (exchangeListing != address(0), "ARK420::setExchangeListing: exchange listing address should be non zero");
        require (exchangeListingContract == address(0), "ARK420::setExchangeListing: exchange listing address already set");
        exchangeListingContract = exchangeListing;
    }

    function releaseToExchangeListing() external onlyOwner {
        require (exchangeListingContract != address(0), "ARK420::releaseToExchangeListing: Exchange Listing address should be set");
        require (exchangeListingAmount > 0, "ARK420::releaseToExchangeListing: Exchange Listing amount should be more then 0");
        require(block.timestamp > exchangeListingContractRelease, "ARK420::releaseToExchangeListing: too early to release ExchangeListing amount");
        _unfrozenBalances[exchangeListingContract] += exchangeListingAmount;
        exchangeListingAmount = 0;
        emit Transfer(address(0), exchangeListingContract, _unfrozenBalances[exchangeListingContract]);
    }

    function setLiquidity(address liquidity) external onlyOwner { 
        require (liquidity != address(0), "ARK420::setLiquidity: liquidity address should be non zero");
        require (liquidityContract == address(0), "ARK420::setLiquidity: liquidity address already set");
        liquidityContract = liquidity;
    }

    function releaseToLiquidity() external onlyOwner {
        require (liquidityContract != address(0), "ARK420::releaseToLiquidity: liquidity address should be set");
        require (liquidityAmount > 0, "ARK420::releaseToLiquidity: liquidity amount should be more then 0");
        require(block.timestamp > liquidityContractRelease, "ARK420::releaseToLiquidity: too early to release liquidity amount");
        _unfrozenBalances[liquidityContract] += liquidityAmount;
        liquidityAmount = 0;
        emit Transfer(address(0), liquidityContract, _unfrozenBalances[liquidityContract]);
    }

    function setStaking(address staking) external onlyOwner { 
        require (staking != address(0), "ARK420::setStaking: staking address should be non zero");
        require (stakingContract == address(0), "ARK420::setStaking: staking address already set");
        stakingContract = staking;
    }

    function releaseToStaking() external onlyOwner {
        require (stakingContract != address(0), "ARK420::releaseToStaking: staking address should be set");
        require (stakingAmount > 0, "ARK420::releaseToStaking: staking amount should be more then 0");
        require(block.timestamp > stakingContractRelease, "ARK420::releaseToStaking: too early to release staking amount");
        _unfrozenBalances[stakingContract] += stakingAmount;
        stakingAmount = 0;
        emit Transfer(address(0), stakingContract, _unfrozenBalances[stakingContract]);
    }

    function vestPurchase(address user, uint amount) external {
        require (vesters[msg.sender], "ARK420::vestPurchase: not vester");
        _transfer(msg.sender, owner, amount);
        _vest(user, amount, 1, vestingSaleReleaseStart, vestingSaleReleaseStart + vestingSaleSecondPeriod);
    }

    function burnTokens(uint amount) external onlyOwner returns (bool success) {
        require(amount <= _unfrozenBalances[owner], "ARK420::burnTokens: exceeds available amount");

        uint256 ownerBalance = _unfrozenBalances[owner];
        require(ownerBalance >= amount, "ARK420::burnTokens: burn amount exceeds owner balance");

        _unfrozenBalances[owner] = ownerBalance - amount;
        _totalSupply -= amount;
        emit Transfer(owner, address(0), amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowances[owner][spender];
    }

    function decimals() external override pure returns (uint8) {
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
            amount = amount + _vestingAmounts[account][i] - _unvestedAmounts[account][i];
        }
        return amount;
    }

    function availableForUnvesting(address user) external view returns (uint unvestAmount) {
        if (_vestingNonces[user] == 0) return 0;
        for (uint i = 1; i <= _vestingNonces[user]; i++) {
            if (_vestingAmounts[user][i] == _unvestedAmounts[user][i]) continue;
            if (_vestingReleaseStartDates[user][i] > block.timestamp) break;
            uint toUnvest = (block.timestamp - _vestingReleaseStartDates[user][i]) * _vestingAmounts[user][i] / (_vestingSecondPeriods[user][i] - _vestingReleaseStartDates[user][i]);
            if (toUnvest > _vestingAmounts[user][i]) {
                toUnvest = _vestingAmounts[user][i];
            } 
            toUnvest -= _unvestedAmounts[user][i];
            unvestAmount += toUnvest;
        }
    }

    function availableForTransfer(address account) external view returns (uint) {
        return _unfrozenBalances[account];
    }

    function vestingInfo(address user, uint nonce) external view returns (uint vestingAmount, uint unvestedAmount, uint vestingReleaseStartDate, uint vestingSecondPeriod, uint vestType) {
        vestingAmount = _vestingAmounts[user][nonce];
        unvestedAmount = _unvestedAmounts[user][nonce];
        vestingReleaseStartDate = _vestingReleaseStartDates[user][nonce];
        vestingSecondPeriod = _vestingSecondPeriods[user][nonce];
        vestType = _vestingTypes[user][nonce];
    }

    function vestingNonces(address user) external view returns (uint lastNonce) {
        return _vestingNonces[user];
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ARK420::_approve: approve from the zero address");
        require(spender != address(0), "ARK420::_approve: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "ARK420::_transfer: transfer from the zero address");
        require(recipient != address(0), "ARK420::_transfer: transfer to the zero address");

        uint256 senderAvailableBalance = _unfrozenBalances[sender];
        require(senderAvailableBalance >= amount, "ARK420::_transfer: amount exceeds available for transfer balance");
        _unfrozenBalances[sender] = senderAvailableBalance - amount;
        _unfrozenBalances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _vest(address user, uint amount, uint vestType, uint vestingReleaseStart, uint vestingReleaseSecondPeriod) private {
        require(user != address(0), "ARK420::_vest: vest to the zero address");
        require(vestingReleaseStart >= 0, "ARK420::_vest: vesting release start date should be more then 0");
        require(vestingReleaseSecondPeriod >= vestingReleaseStart, "ARK420::_vest: vesting release end date should be more then start date");
        uint nonce = ++_vestingNonces[user];
        _vestingAmounts[user][nonce] = amount;
        _vestingReleaseStartDates[user][nonce] = vestingReleaseStart;
        _vestingSecondPeriods[user][nonce] = vestingReleaseSecondPeriod;
        _unfrozenBalances[owner] -= amount;
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
        _unfrozenBalances[owner] -= sum;
        for (uint i; i < to.length; i++) {
            _unfrozenBalances[to[i]] += values[i];
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }

    function multivest(address[] memory to, uint[] memory values, uint[] memory vestingReleaseStarts, uint[] memory vestingSecondPeriods) external onlyOwner returns (uint) { 
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        _unfrozenBalances[owner] -= sum;
        for (uint i; i < to.length; i++) {
            uint nonce = ++_vestingNonces[to[i]];
            _vestingAmounts[to[i]][nonce] = values[i];
            _vestingReleaseStartDates[to[i]][nonce] = vestingReleaseStarts[i];
            _vestingSecondPeriods[to[i]][nonce] = vestingSecondPeriods[i];
            _vestingTypes[to[i]][nonce] = 0;
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }

    function updateVesters(address vester, bool isActive) external onlyOwner { 
        vesters[vester] = isActive;
    }

    function updateGiveAmount(uint amount) external onlyOwner { 
        require (_unfrozenBalances[owner] > amount, "ARK420::updateGiveAmount: exceed owner balance");
        giveAmount = amount;
    }
    
    function transferAnyBEP20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(owner, tokens);
    }

    function acceptOwnership() public override {
        uint amount = _unfrozenBalances[owner];
        _unfrozenBalances[newOwner] = amount;
        _unfrozenBalances[owner] = 0;
        emit Transfer(owner, newOwner, amount);
        super.acceptOwnership();
    }
}