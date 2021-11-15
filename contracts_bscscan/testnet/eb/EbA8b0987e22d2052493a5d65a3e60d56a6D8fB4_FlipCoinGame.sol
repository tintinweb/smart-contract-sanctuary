pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@pancakeswap2/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap2/pancake-swap-core/contracts/interfaces/IPancakePair.sol";
import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter01.sol";
import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";

/**
 * @title ERC20Token
 * @author AmberSoft (visit https://ambersoft.llc)
 *
 * @dev Mintable ERC20 token with burning and optional functions implemented.
 * Any address with minter role can mint new tokens.
 * For full specification of ERC-20 standard see:
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20Token is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address public immutable WETH;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    struct WeekEntries{
        uint256 entriesCount;
    }

    uint256 public _currentStartIndex = 0;
    uint256 public _currentParticipantCount = 0;

    address public _currentWinner;
    uint256 public _currentReward = 0;
    uint256 public _lastGiveawayTime = 0;
    uint256 public _timeForDecision = 24 hours;
    bool public _winnerWillTakeReward = false;
    bool public _winnerMakeDecision = false;
    bool public _takeFeesOnTransfer = false;

    mapping (address => WeekEntries[]) public _participantsEntries;
    address[] public _participantIndexes;
    address[] public _allParticipants;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public _giveawayFee = 9;
    uint256 private _rewardSize = 5;
    uint256 public _liquidityFee = 2;

    uint256 public _totalLiquidity = 0;
    uint256 public _currentLiquidity = 0;

    uint256 public _currentGiveAwayBNB = 0;
    uint256 public _totalGiveAwayBNB = 0;
    uint256 public _currentPromo = 0;
    uint256 public _totalPromoBnb = 0;

    uint256 public _minHoldAmount = 0;

    address public _flipCoinContractAddress = address(0);

    uint256 public _lastRaffle = 0;
    uint256 public _startHourToRaffle = 8;
    uint256 public _endHourToRaffle = 9;
    uint256 public _dayOfWeekToRaffle = 5;
    int256 public _timeZoneTimeChange = 0 - 1*60*60;
    uint256 public _nextStartTimestampToRaffle = 1630173000;
    uint256 public _nextEndTimestampToRaffle = 1630173600;
    uint256 public _oneWeekTimestamp = 7*24*60*60;


    IPancakeRouter02 public immutable pancakeswapV2Router;
    address public immutable pancakeswapV2Pair;

    address payable public _promoPoolAddress;

    uint256 public _oneEntryPrice = (1 * 10**17); // 0.1BNB

    /* @dev
    * Bool to lock recursive calls to avoid interfering calls.
    */
    bool inSwapAndLiquify;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event ItsTooLate();

    event NoWinnerThisWeek(
        string reason
    );

    /**
     * @dev Constructor.
     * @param name name of the token
     * @param symbol symbol of the token, 3-4 chars is recommended
     * @param decimals number of decimal places of one token unit, 18 is widely used
     * @param initialSupply initial supply of tokens in lowest units (depending on decimals)
     * @param feeReceiver promo pool address
     * @param tokenOwnerAddress address that gets 100% of token supply
     * @param routerAddress address for pancakeswap
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 initialSupply,
        address payable feeReceiver,
        address tokenOwnerAddress,
        address routerAddress // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 - test, 0x10ED43C718714eb63d5aA57B78B54704E256024E - main
    ) public payable {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _promoPoolAddress = feeReceiver;

        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(routerAddress);
        WETH = _pancakeswapV2Router.WETH();

        // Create a Pancake pair for this new token
        pancakeswapV2Pair = IPancakeFactory(_pancakeswapV2Router.factory())
        .createPair(address(this), _pancakeswapV2Router.WETH());

        // set the rest of the contract variables
        pancakeswapV2Router = _pancakeswapV2Router;

        // set tokenOwnerAddress as owner of initial supply, more tokens can be minted later
        _mint(tokenOwnerAddress, initialSupply);
        emit Transfer(address(0), tokenOwnerAddress, initialSupply);

        // pay the service fee for contract deployment
        _promoPoolAddress.transfer(msg.value);
    }

    function setPromoPoolAddress(address payable promoPoolAddress) external onlyOwner() {
        _promoPoolAddress = promoPoolAddress;
    }

    function setGiveawayFee(uint256 giveawayFee) external onlyOwner() {
        _giveawayFee = giveawayFee;
    }

    function setLiquidityFee(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setOneEntryPrice(uint256 oneEntryPrice) external onlyOwner() {
        _oneEntryPrice = oneEntryPrice;
    }

    function setMinHoldAmount(uint256 minHoldAmount) external onlyOwner() {
        _minHoldAmount = minHoldAmount;
    }

    function setFlipCoinContractAddress(address flipCoinContractAddress) external onlyOwner() {
        _flipCoinContractAddress = flipCoinContractAddress;
    }

    function setFlipCoinContractAddressByFlipCoin(address flipCoinContractAddress) external {
        require(_msgSender() == _flipCoinContractAddress, "Only FlipCoin contract can change self");
        _flipCoinContractAddress = flipCoinContractAddress;
    }

    function mintForWinner(address recipient, uint256 amount) external {
        require(_msgSender() == _flipCoinContractAddress, "Only FlipCoin contract can mint");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_totalSupply+amount < uint256(-1), "Limit reached");

        _balances[recipient] = _balances[recipient].add(amount);
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), recipient, amount);
    }

    function sendForWinner(address recipient, uint256 amount) external {
        require(_msgSender() == _flipCoinContractAddress, "Only FlipCoin contract can initialize sending to winner");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_totalSupply+amount < uint256(-1), "Limit reached");

        _balances[_flipCoinContractAddress] = _balances[_flipCoinContractAddress].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(_flipCoinContractAddress, recipient, amount);
    }

    function burnFromGamer(address gamer, uint256 amount) external {
        require(_msgSender() == _flipCoinContractAddress, "Only FlipCoin contract can burn");
        require(gamer != address(0), "ERC20: burn from the zero address");

        _burn(gamer, amount);
    }

    function getFromGamer(address gamer, uint256 amount) external {
        require(_msgSender() == _flipCoinContractAddress, "Only FlipCoin contract can initialize sending from gamer");
        require(gamer != address(0), "ERC20: send from the zero address");

        _balances[_flipCoinContractAddress] = _balances[_flipCoinContractAddress].add(amount);
        _balances[gamer] = _balances[gamer].sub(amount);

        emit Transfer(gamer, _flipCoinContractAddress, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        uint256 totalSendAmount = amount;

        if(_takeFeesOnTransfer && sender != owner() && recipient != owner() && sender != address(this) && recipient != address(this))
        {
            uint256 giveawayFeeAmount = amount.mul(_giveawayFee).div(100);
            uint256 liquidityFeeAmount = amount.mul(_liquidityFee).div(100);
            totalSendAmount = totalSendAmount.sub(giveawayFeeAmount).sub(liquidityFeeAmount);

            _balances[address(this)] = _balances[address(this)].add(giveawayFeeAmount);
            _balances[address(this)] = _balances[address(this)].add(liquidityFeeAmount);

            // Add Giveaway Counters
            _currentPromo = _currentPromo.add(giveawayFeeAmount);

            // Add Liquidity Counters
            _currentLiquidity = _currentLiquidity.add(liquidityFeeAmount);
            _totalLiquidity = _totalLiquidity.add(liquidityFeeAmount);

            // If winner didn't made the decision
            if(_currentWinner != address(0) && _winnerMakeDecision == false && (_lastGiveawayTime + _timeForDecision) <= block.timestamp)
            {
                sacrificeReward();
            }

            // Only in Swap
            if(sender == pancakeswapV2Pair || recipient == pancakeswapV2Pair)
            {
                address participant = address(0);
                if(sender == pancakeswapV2Pair)
                {
                    participant = recipient;
                }
                else
                {
                    participant = sender;
                }
                // Calculate entries
                uint bnbCount = getBnbPriceOfToken(pancakeswapV2Pair, amount);

                if(bnbCount > _oneEntryPrice)
                {
                    uint entryCount = bnbCount.div(_oneEntryPrice);
                    generateParticipantEntries(participant);

                    if(!isParticipant(participant))
                    {
                        _allParticipants.push(participant);
                    }

                    for (uint i = 0; i < entryCount; i++)
                    {
                        _participantIndexes.push(participant);
                        _currentParticipantCount = _currentParticipantCount.add(1);
                    }

                    _participantsEntries[participant][_currentStartIndex].entriesCount = _participantsEntries[participant][_currentStartIndex].entriesCount.add(entryCount);
                    _participantsEntries[participant][_currentStartIndex + 1].entriesCount = _participantsEntries[participant][_currentStartIndex + 1].entriesCount.add(entryCount);
                    _participantsEntries[participant][_currentStartIndex + 2].entriesCount = _participantsEntries[participant][_currentStartIndex + 2].entriesCount.add(entryCount);
                    _participantsEntries[participant][_currentStartIndex + 3].entriesCount = _participantsEntries[participant][_currentStartIndex + 3].entriesCount.add(entryCount);
                }
            }
        }

        _balances[recipient] = _balances[recipient].add(totalSendAmount);
        emit Transfer(sender, recipient, totalSendAmount);
    }

    function burn(uint256 amount) external onlyOwner() {
        _burn(_msgSender(), amount);
    }

    function getRewardSize() public view returns (uint256) {
        return _rewardSize;
    }

    function setRewardSize(uint256 rewardSize) external onlyOwner() {
        _rewardSize = rewardSize;
    }

    function setTakeFeesOnTransfer(bool takeFeesOnTransfer) external onlyOwner() {
        _takeFeesOnTransfer = takeFeesOnTransfer;
    }

    function makeRaffle() external {
        require(
            block.timestamp >= _nextStartTimestampToRaffle,
            "Not time yet"
        );

        _nextStartTimestampToRaffle = _nextStartTimestampToRaffle.add(_oneWeekTimestamp);
        _nextEndTimestampToRaffle = _nextEndTimestampToRaffle.add(_oneWeekTimestamp);

        if(block.timestamp >= _nextEndTimestampToRaffle)
        {
            emit ItsTooLate();
        }
        else
        {
            changePromoTokensToBnb();

            _lastGiveawayTime = block.timestamp;
            _currentReward = _currentGiveAwayBNB;

            uint256 winnerIndex = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))% _currentParticipantCount);
            _currentWinner = _participantIndexes[winnerIndex];
            bool isWinnerFounded = _balances[_currentWinner] >= _minHoldAmount;
            uint256 startIndex = winnerIndex;
            //Finding Winner with balance > minimal
            while(!isWinnerFounded)
            {
                winnerIndex = winnerIndex.add(1);
                if(winnerIndex >= _participantIndexes.length)
                {
                    winnerIndex = 0;
                }
                if(winnerIndex == startIndex)
                {
                    break;
                }
                _currentWinner = _participantIndexes[winnerIndex];
                //check balance > minimal
                if(_balances[_currentWinner] >= _minHoldAmount)
                {
                    isWinnerFounded = true;
                    break;
                }
            }
            if(!isWinnerFounded)
            {
                emit NoWinnerThisWeek('Winner not founded');
            }
            else
            {
                _winnerWillTakeReward = false;
                _winnerMakeDecision = false;

                // After Giveaway - cleaning Up
                _currentGiveAwayBNB = 0;
                _currentParticipantCount = 0;
                delete _participantIndexes;
                for (uint i = 0; i < _allParticipants.length; i++)
                {
                    delete _participantsEntries[_allParticipants[i]][_currentStartIndex];

                    for (uint j = 0; j < _participantsEntries[_allParticipants[i]][_currentStartIndex + 1].entriesCount; j++)
                    {
                        _participantIndexes.push(_allParticipants[i]);
                        _currentParticipantCount = _currentParticipantCount.add(1);
                    }
                }

                _currentStartIndex = _currentStartIndex.add(1);
            }
        }

    }

    function makeDecision(bool takeReward) external {
        require(_currentWinner == _msgSender(), "Only Winner can Make Decision");
        require(_winnerMakeDecision == false, "Winner can make decision once");
        require((_lastGiveawayTime + _timeForDecision) > block.timestamp, "It's too late");
        generateParticipantEntries(_currentWinner);

        // If Sacrifice - then give him 26 rewards
        if(takeReward == false)
        {
            for (uint i = 0; i < 26; i++)
            {
                _participantsEntries[_msgSender()][_currentStartIndex + i].entriesCount = _participantsEntries[_msgSender()][_currentStartIndex + i].entriesCount.add(1);
            }

            _participantIndexes.push(_msgSender());
            _currentParticipantCount = _currentParticipantCount.add(1);
        }

        _winnerMakeDecision = true;
        _winnerWillTakeReward = takeReward;
        _currentWinner = address(0);
        _currentReward = 0;
    }

    function sacrificeReward() private {

        generateParticipantEntries(_currentWinner);

        for (uint i = 0; i < 26; i++)
        {
            _participantsEntries[_currentWinner][_currentStartIndex + i].entriesCount = _participantsEntries[_currentWinner][_currentStartIndex + i].entriesCount.add(1);
        }

        _participantIndexes.push(_currentWinner);
        _currentParticipantCount = _currentParticipantCount.add(1);
        _winnerMakeDecision = true;
        _winnerWillTakeReward = false;
        _currentWinner = address(0);
        _currentReward = 0;
    }

    function getParticipantCount() public view returns (uint256) {
        return _currentParticipantCount;
    }

    function generateParticipantEntries(address participant) private {
        for (uint i = 0; i < 26; i++) {
            _participantsEntries[participant].push(WeekEntries(0));
        }
    }

    function isParticipant(address participant) private view returns (bool){
        return _participantsEntries[participant].length > 0 && _participantsEntries[participant][_currentStartIndex].entriesCount > 0;
    }

    // to recieve ETH from pancakeswapV2Router when swaping
    receive() external payable {}

    function changePromoTokensToBnb() public {

        // Add Giveaway Counters
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(_currentPromo);
        uint256 promoInBNB = address(this).balance.sub(initialBalance);
        uint256 giveawayBnb = promoInBNB.mul(_rewardSize).div(_giveawayFee);

        _promoPoolAddress.transfer(promoInBNB);
        _currentPromo = 0;
        _totalPromoBnb = _totalPromoBnb.add(promoInBNB);
        _currentGiveAwayBNB = _currentGiveAwayBNB.add(giveawayBnb);
        _totalGiveAwayBNB = _totalGiveAwayBNB.add(giveawayBnb);
    }

    //Get current price info of LP Pair
    // Input: Bnb amount
    // Output: token amount
    function getBnbPriceOfToken(address pairAddress, uint amount) private view returns(uint)
    {
        if(isContract(pairAddress)){
            IPancakePair pair = IPancakePair(pairAddress);
            (uint Res0, uint Res1,) = pair.getReserves();
            return (amount * Res1) / Res0;
        } else {
            return 1;
        }
    }

    //Get current price info of LP Pair
    // Input: token amount
    // Output: Bnb amount
    function getTokenPriceInBnb(address pairAddress, uint amount) private view returns(uint)
    {
        if(isContract(pairAddress)){
            IPancakePair pair = IPancakePair(pairAddress);
            (uint Res0, uint Res1,) = pair.getReserves();
            return (amount * Res0) / Res1;
        } else {
            return 1;
        }
    }

    /**
    * Evaluates whether address is a contract and exists.
    */
    function isContract(address addr) view private returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function sendLiquidityTokenToSwap() external {
        // Add Liquidity Counters
        swapAndLiquify(_currentLiquidity);
        _currentLiquidity = 0;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2); //ETH
        uint256 otherHalf = contractTokenBalance.sub(half); //BNB

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to Pancake
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the Pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ERC20Token.sol";

/**
 * @title FlipCoinGame
 * @author AmberSoft (visit https://ambersoft.llc)
 */
contract FlipCoinGame is Context, Ownable {
    using SafeMath for uint256;

    // Token info
    address payable public immutable _token;
    ERC20Token public _tokenContract;

    // Token slippage in percent, 1100 = 11%
    uint256 public _tokenSlippage = 1100;

    // Max bid for one play, 3000 = 30% of current bank
    uint256 public _maxBid = 3000;
    uint256 public _minimumHold = 1000 * 10**9;

    // Win Rate in percent, 20000 = 200%
    uint256 public _winRate = 20000;
    // Chance to win 4800 = 48%
    uint256 public _chanceToWin = 4800;

    bool public _isManualMintStatus = false;
    bool public _isManualBurnStatus = false;
    bool public _isMintActive = true;
    bool public _isBurnActive = false;

    uint256 public _minimalBalanceBar = 50000000000000000;  //50000000 +000000000
    uint256 public _maximalBalanceBar = 100000000000000000; //100000000 +000000000

    event Win(
        address who,
        uint256 bid,
        uint256 timestamp,
        bool isTail
    );

    event Lose(
        address who,
        uint256 bid,
        uint256 timestamp,
        bool isTail
    );

    /**
     * @dev Constructor.
     * @param owner who is an owner
     * @param token which token acceptable
     */
    constructor(
        address owner,
        address payable token
    ) public {
        _token = token;
        _tokenContract = ERC20Token(token);

        // transfer ownership to owner address
        transferOwnership(owner);
    }

    // Owner methods

    function setTokenSlippage(uint256 tokenSlippage) external onlyOwner() {
        _tokenSlippage = tokenSlippage;
    }

    function setMaxBid(uint256 maxBid) external onlyOwner() {
        _maxBid = maxBid;
    }

    function setMinimumHold(uint256 minimumHold) external onlyOwner() {
        _minimumHold = minimumHold;
    }

    function setWinRate(uint256 winRate) external onlyOwner() {
        _winRate = winRate;
    }

    function setChanceToWin(uint256 chanceToWin) external onlyOwner() {
        _chanceToWin = chanceToWin;
    }

    function changeMainFlipCoinGameContract(address newFlipCoinContractAddress) external onlyOwner() {
        _tokenContract.setFlipCoinContractAddressByFlipCoin(newFlipCoinContractAddress);
    }

    function setMintStatus(bool mintStatus) external onlyOwner() {
        _isMintActive = mintStatus;
        _isManualMintStatus = true;
    }

    function setBurnStatus(bool burnStatus) external onlyOwner() {
        _isBurnActive = burnStatus;
        _isManualBurnStatus = true;
    }

    function recoverAutomaticMintStatus() external onlyOwner() {
        _isManualMintStatus = false;
        _checkStatuses();
    }

    function recoverAutomaticBurnStatus() external onlyOwner() {
        _isManualBurnStatus = false;
        _checkStatuses();
    }

    function withdrawBalance(uint256 amount) external onlyOwner() {
        _tokenContract.transfer(this.owner(), amount);
    }

    // External methods to play

    function play(bool isTail, uint256 bid, uint256 timestamp) external {
        require(_canPlay(bid, _msgSender()), "You can't play");

        _checkStatuses();

        if(_isBurnActive)
        {
            _tokenContract.burnFromGamer(_msgSender(), bid);
        }
        else
        {
            _tokenContract.getFromGamer(_msgSender(), bid);
        }

        uint256 realBid = bid - bid.mul(_tokenSlippage).div(10000);

        if (_doesWin()) {
            _onWin(_msgSender(), bid, realBid, timestamp, isTail);
        } else {
            _onLose(_msgSender(), bid, realBid, timestamp, isTail);
        }

    }

    // Checks if the value of the behavior flags should be changed
    function _checkStatuses() internal {

        if(!_isManualMintStatus)
        {
            if(_tokenContract.balanceOf(address(this)) > _maximalBalanceBar)
            {
                _isMintActive = false;
            }
            else
            {
                _isMintActive = true;
            }
        }

        if(!_isManualBurnStatus)
        {
            if(_tokenContract.balanceOf(address(this)) < _minimalBalanceBar)
            {
                _isBurnActive = false;
            }
            else
            {
                _isBurnActive = true;
            }
        }
    }

    // Internal methods

    // true - tail, false - head
    function _doesWin() internal view returns (bool) {
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _tokenContract._totalLiquidity))) % 10000) <= _chanceToWin;
    }

    function _onWin(address player, uint256 rawBid, uint256 realBid, uint256 timestamp, bool isTail) internal {
        uint256 award = realBid.mul(_winRate).div(10000);

        if(_isMintActive)
        {
            _tokenContract.mintForWinner(_msgSender(), award);
        }
        else
        {
            _tokenContract.sendForWinner(_msgSender(), award);
        }

        emit Win(player, rawBid, timestamp, isTail);
    }

    function _onLose(address player, uint256 rawBid, uint256 realBid, uint256 timestamp, bool isTail) internal {
        emit Lose(player, rawBid, timestamp, isTail == false);
    }

    function _canPlay(uint256 bid, address player) internal view returns (bool) {
        require(_tokenContract.balanceOf(player) >= bid, "You have insufficient funds");

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

