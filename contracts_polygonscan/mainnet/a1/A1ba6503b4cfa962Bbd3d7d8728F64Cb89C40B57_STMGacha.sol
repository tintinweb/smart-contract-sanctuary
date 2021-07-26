/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

/*
    StakeMars Protocol ("STM")

    This is the gacha contract on Polygon.

    TELEGRAM: https://t.me/StakeMars
    WEBSITE: https://www.StakeMars.com/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IGacha {
    function distribute(uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function getRandomNumber() external returns (bytes32);
    function setRandAddress(bytes32 requestId, address sender, uint256 num, uint256 prob) external;
}

interface INFT {
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;
}

contract STMGacha is Ownable {

    IERC20 private token;
    IERC20 private tokenSTM;
    IERC20 private tokenUnit;
    IGacha public stakingAddress;
    IGacha private depositTokenAddress;
    IGacha private chainlinkAddress;
    INFT private nftAddress;
    IERC1155 private nftToken;
    address private chainlink;
    address private staking;

    uint256 public nav;
    uint256 public totalStakedUnit;
    uint256 public totalStaked;
    uint256 public totalPlayed;

    uint256 public jackpotPool;
    uint256 public jackpotShareBPS;
    uint256 public mktPool;
    uint256 public mktShareBPS;
    address public mktAddress;
    uint256 public stmShareBPS;
    uint256 public discountBPS;
    uint256 public discountSTMHold;
    uint256 public withdrawFeeBPS;
    uint256 public customFee;

    mapping(address => bool) public isPlayingGacha;
    mapping(address => bool) public canGetGachaReward;
    uint256 private clOnProcess;
    bool private stopPlay;

    // Referral
    mapping(address => address) public inviter;
    mapping(address => uint256) public referralReward;
    uint256 public totalRefReward;
    uint256 public refRewardBPS;

    // decimal
    uint256 private USDCdecimal = 6;

    // STMGacha
    mapping(address => uint256) public playedTimes;
    mapping(address => uint256) public playSize; // 2 * 10 ** 18 , 10 , 50
    mapping(address => uint256) private ticket;
    mapping(address => uint256) private pendingFund;
    mapping(address => uint256[5]) public currentGachaReward; // 0 = Jackpot
    uint256[5] payoutReward = [0,1000,200,50,0];
    uint256[3] priceTicket = [2 * 10 ** USDCdecimal, 10 * 10 ** USDCdecimal, 50 * 10 ** USDCdecimal];
    mapping(address => bool) public rewardCustomStatus;
    mapping(address => uint256) public playProb;
    mapping(address => bool) public getLastDiscount;

    event OnStake(address sender, uint256 amount);
    event OnUnstake(address sender, uint256 amount);
    event OnClaimRefReward(address sender, uint256 amount);
    event OnClaimGacha(address sender, uint256 amount);
    event UpdateGachaStatus(uint256 nav);
    event UpdateChainlink(address chainlink);

    constructor(address _unitToken, address _nftToken) {
        // BSC Testnet (BUSD) : 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
        // Mainnet (STM) : 0x74f4ccdaEdb13b73754cf7Bb8CbABE74E2DD4B70
        // Mumbai (smUSD) : 0x58591327aF246bf26e909657B636680763AFF54b
        // Mumbai (mUSDC 6 decimals) : 0xd4f1eb62FDd23e55B93036f37EB20127CC18aE8F
        token = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); // USDC
        tokenSTM = IERC20(0xd4A9a52040D154928F6d219a5c24D1aEdd8453fE); // mSTM
        staking = 0x42834Ab5B8765f3baa5fD5921dE372F75498f08F;
        stakingAddress = IGacha(staking);
        depositTokenAddress = IGacha(_unitToken);
        tokenUnit = IERC20(_unitToken);
        nftAddress = INFT(_nftToken);
        nftToken = IERC1155(_nftToken);
        mktAddress = owner();
        nav = 1 *  10 ** 18; //Start NAV
        refRewardBPS = 50; //Set Referal reward at 0.50%
        jackpotShareBPS = 45; //Set Jackpot pool sharing at 0.45%
        mktShareBPS = 10; //Set mkt sharing at 0.10%
        stmShareBPS = 75; //Set STM pool sharing at 0.75%
        discountBPS = 100; //Set STM pool sharing at 1%
        discountSTMHold = 20000 * 10 ** 18; //Set 20,000 STM holding for discount
        withdrawFeeBPS = 25; // Withdrawal fee 0.25%
        customFee = 2; // Custom Game Fee 0.002 USDC
    }

    function getDiscount(address sender) view public returns (bool) {
        return tokenSTM.balanceOf(sender) >= discountSTMHold;
    }

    // prob is percentage min = 1 = 1% = 100x
    function customPlay(uint256 amount, uint256 prob, address _inviter) external {
        require(prob >= 1 && prob <= 98);
        buyAndRandom(amount, 0, _inviter, prob);
    }

    function buyAndRandom (uint256 amount, uint256 size, address _inviter, uint256 prob) internal {
        require(canPlay());
        require(!isPlayingGacha[msg.sender]);
        if (_inviter == msg.sender) _inviter = address(0);
        if(playedTimes[msg.sender] == 0 && _inviter != address(0)) inviter[msg.sender] = _inviter;
        uint256 checkingAmount;
        uint256 received;
        uint256 receivedAfterDis;
        uint256 addJackpot;
        uint256 addMkt;
        uint256 addStaking;
        uint256 price;
        uint256 num;
        if ( prob != 0 ) {
            uint256 onePercentPayout;
            uint256 payoutAmount = amount * 100 / prob;
            onePercentPayout = payoutAmount / 100;
            if (getDiscount(msg.sender)) {
                getLastDiscount[msg.sender] = true;
            } else {
                payoutAmount = payoutAmount - onePercentPayout;
                getLastDiscount[msg.sender] = false;
            }
            checkingAmount = payoutAmount - onePercentPayout; //payoff should be not over 1% of total prize pool.
            received = amount;
            addMkt = customFee * 10 ** (USDCdecimal - 3);
            receivedAfterDis = received + addMkt;
            addStaking = received * stmShareBPS / ( 10000 * 2 );
            price = amount;
            num = 0;
            playedTimes[msg.sender] += 1;
            playProb[msg.sender] = prob;
        } else {
            ( received, checkingAmount, price ) = ( amount * priceTicket[size-1], amount * priceTicket[size-1], priceTicket[size-1]);
            receivedAfterDis = received;
            if (getDiscount(msg.sender)) receivedAfterDis = received * ( 10000 - discountBPS ) / 10000;
            addJackpot = received * jackpotShareBPS / 10000;
            addMkt = received * mktShareBPS / 10000;
            addStaking = received * stmShareBPS / 10000;
            num = amount;
            playedTimes[msg.sender] += amount;
            playProb[msg.sender] = 0;
        }
        require(checkingAmount <= totalStaked / 100);
        require(token.balanceOf(msg.sender) >= receivedAfterDis);
        require(token.transferFrom(msg.sender, address(this), receivedAfterDis));
        jackpotPool += addJackpot;
        mktPool += addMkt;
        token.approve(address(staking), addStaking);
        stakingAddress.distribute(addStaking);
        uint256 commToInviter;
        if(inviter[msg.sender] != address(0)){
            commToInviter = received * refRewardBPS / 10000;
            if ( prob != 0 ) commToInviter = commToInviter / 2;
            referralReward[inviter[msg.sender]] += commToInviter;
            totalRefReward += commToInviter;
        }
        (ticket[msg.sender], playSize[msg.sender], isPlayingGacha[msg.sender]) = (num, price, true);
        pendingFund[msg.sender] = receivedAfterDis - addJackpot - addMkt - addStaking - commToInviter;
        totalPlayed += received;
        clOnProcess += 1;
        currentGachaReward[msg.sender] = [0,0,0,0,0];
        bytes32 randId = chainlinkAddress.getRandomNumber();
        chainlinkAddress.setRandAddress(randId, msg.sender, num, prob);
    }

    function buyAndPlace(uint256 amount, uint256 size, address _inviter) external {
        require(size == 1 || size == 2 || size == 3);
        require(amount <= 100);
        buyAndRandom(amount, size, _inviter, 0);
    }

    function setGachaRewardStatus (address sender, bool status, uint256[5] memory reward) external {
        require(msg.sender==chainlink, "Do not have permission");
        currentGachaReward[sender] = reward;
        setGachaStatus(sender, status);
    }

    function setGachaCustomStatus (address sender, bool status, bool _rewardCustom) external {
        require(msg.sender==chainlink, "Do not have permission");
        rewardCustomStatus[sender] = _rewardCustom;
        setGachaStatus(sender, status);
    }

    function setGachaStatus (address sender, bool status) internal {
        canGetGachaReward[sender] = status;
        updateNAV(sender);
        clOnProcess -= 1;
    }

    function updateNAV (address sender) internal {
        uint256 payout = getPendingPayout(sender);
        uint256 received = pendingFund[sender];
        if (received >= payout){
            totalStaked += received - payout;
        } else {
            totalStaked -= payout - received;
        }
        nav = totalStaked * 10 ** (18 + 18 - USDCdecimal) / totalStakedUnit;
        emit UpdateGachaStatus(nav);
    }

    // Without Jackpot
    function getPendingPayout (address sender) view internal returns (uint256) {
        uint256 payout;
        if(!rewardCustomStatus[sender]){
            for (uint256 i=1; i<5; i++){
                payout += currentGachaReward[sender][i] * playSize[sender] * payoutReward[i] / 100;
            }
        }else{
            uint256 payoutBefore = playSize[sender] * 100 / playProb[sender];
            uint256 onePercent = payoutBefore / 100;
            if (!getLastDiscount[sender]) payoutBefore = payoutBefore - onePercent;
            payout = payoutBefore - onePercent;
        }
        return payout;
    }

    function claimGachaReward() external {
        require(canGetGachaReward[msg.sender], "Please wait to process");
        uint256 payoutWOjackpot = getPendingPayout(msg.sender);
        uint256 payoutJackpot;
        uint256 payout;
        if (currentGachaReward[msg.sender][0] != 0) {
            for (uint256 i=0; i < currentGachaReward[msg.sender][0]; i++){
                uint256 jackpotReward = jackpotPool * 8 * playSize[msg.sender] / ( 10 * priceTicket[2] * 10 ** USDCdecimal );
                payoutJackpot += jackpotReward;
                jackpotPool -= jackpotReward;
            }
        }
        payout = payoutWOjackpot + payoutJackpot;
        if (payout != 0) {
            token.approve(address(this), payout);
            require(
                token.transferFrom(address(this), msg.sender, payout),
                "Failed due to failed transfer."
            );
        }
        recordRewards(currentGachaReward[msg.sender],playSize[msg.sender]);
        isPlayingGacha[msg.sender] = false;
        canGetGachaReward[msg.sender] = false;
        rewardCustomStatus[msg.sender] = false;
        emit OnClaimGacha(msg.sender, payout);
    }

    function recordRewards(uint256[5] memory amount, uint256 size) internal {
        uint256[] memory ids = new uint[](5);
        uint256[] memory amounts = new uint[](5);
        uint256 idPlus;
        if(size == priceTicket[0]){
            idPlus = 1;
        }else if(size == priceTicket[1]){
            idPlus = 6;
        }else{
            idPlus = 11;
        }
        for (uint256 i = 0; i<5; i++) {
            ids[i] = i+idPlus;
            amounts[i] = amount[i];
        }
        nftAddress.mintBatch(msg.sender, ids, amounts);
    }

    function enterStaking(uint256 amount) external {
        require(
            token.balanceOf(msg.sender) >= amount,
            "Cannot stake more than you hold."
        );

        _addStake(amount);

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );

        emit OnStake(msg.sender, amount);
    }

    function _addStake(uint256 _amount) internal {
        totalStaked += _amount;
        uint256 unitNum = _amount * 10 ** (18 + 18 - USDCdecimal) / nav;
        depositTokenAddress.mint(msg.sender, unitNum);
        totalStakedUnit += unitNum;
    }

    function leaveStaking(uint256 _unit) external {
        require(
            tokenUnit.balanceOf(msg.sender) >= _unit,
            "Cannot unstake more than you have staked."
        );
        require(
            canWithdraw(),
            "Cannot waitdraw in unavailable period"
        );
        uint256 amount = nav * _unit / 10 ** (18 + 18 - USDCdecimal);
        depositTokenAddress.burn(msg.sender, _unit);
        totalStaked -= amount;
        totalStakedUnit -= _unit;
        uint256 fee = withdrawFeeBPS * amount / 10000;
        token.approve(address(this), amount - fee);
        if (withdrawFeeBPS != 0){
            token.approve(address(staking), fee);
            stakingAddress.distribute(fee);
        }
        require(token.transferFrom(address(this), msg.sender, amount - fee),"Unstake failed due to failed transfer.");

        emit OnUnstake(msg.sender, amount);
    }

    function canPlay () view public returns (bool) {
        return (!(getHour(block.timestamp) % 4 == 0 && getMinute(block.timestamp) >= 45) && !stopPlay);
    }

    function canWithdraw () view public returns (bool) {
        return (!canPlay () && clOnProcess == 0);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256) {
        return uint256((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256) {
        return uint256((timestamp / 60) % 60);
    }

    function claimRefReward() external {
        require(
            referralReward[msg.sender] > 0,
            "You do not have any reward."
        );

        token.approve(address(this), referralReward[msg.sender]);

        require(
            token.transferFrom(address(this), msg.sender, referralReward[msg.sender]),
            "Claim failed due to failed transfer."
        );

        referralReward[msg.sender] = 0;

        emit OnClaimRefReward(msg.sender, referralReward[msg.sender]);
    }

    function claimMktShare() external {
        require(address(msg.sender) == mktAddress,"You do not have the permission.");
        require(mktPool > 0,"You do not have any reward.");

        token.approve(address(this), mktPool);

        require(
            token.transferFrom(address(this), mktAddress, mktPool),
            "Claim failed due to failed transfer."
        );

        mktPool = 0;

        emit OnClaimMktShare(mktAddress, mktPool);
    }

    event OnClaimMktShare(address receiver, uint256 amount);
    event UpdateRefReward(uint256 amount);
    event UpdateJackpotShare(uint256 amount);
    event UpdateMktShare(uint256 amount);
    event UpdateMktAddress(address mktAddress);
    event UpdateSTMShare(uint256 amount);
    event UpdateDiscountRate(uint256 amount);
    event UpdateDiscountSTMHold(uint256 amount);
    event UpdateStopPlay(bool stop);

    function setRefReward(uint256 amount) external onlyOwner {
        require(amount <= 100, "Referal Reward cannot be higher than 1 percentage");
        refRewardBPS = amount;
        emit UpdateRefReward(amount);
    }

    function setJackpotShare(uint256 amount) external onlyOwner {
        require(amount <= 100, "Jackpot share cannot be higher than 1 percentage");
        jackpotShareBPS = amount;
        emit UpdateJackpotShare(amount);
    }

    function setMktShare(uint256 amount) external onlyOwner {
        require(amount <= 20, "Mkt share cannot be higher than 0.20 percentage");
        mktShareBPS = amount;
        emit UpdateMktShare(amount);
    }

    function setMktAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Mkt address cannot be the zero address");
        mktAddress = address(newAddress);
        emit UpdateMktAddress(newAddress);
    }

    function setSTMShare(uint256 amount) external onlyOwner {
        require(amount <= 100, "STM share cannot be higher than 1 percentage");
        stmShareBPS = amount;
        emit UpdateSTMShare(amount);
    }

    function setDiscountRate(uint256 amount) external onlyOwner {
        require(amount <= 100, "Discount cannot be higher than 1 percentage");
        discountBPS = amount;
        emit UpdateDiscountRate(amount);
    }

    function setDiscountSTMHold(uint256 amount) external onlyOwner {
        discountSTMHold = amount;
        emit UpdateDiscountSTMHold(amount);
    }

    function setChainlink(address _chainlink) external onlyOwner {
        require(address(chainlink) == address(0),"Chainlink already set");
        chainlinkAddress = IGacha(_chainlink);
        chainlink = address(_chainlink);
        emit UpdateChainlink(_chainlink);
    }

    function setStopPlay(bool _stop) external onlyOwner {
        stopPlay = _stop;
        emit UpdateStopPlay(_stop);
    }

    function setWithdrawFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Cannot be over 1%");
        withdrawFeeBPS = _fee;
        emit UpdateWithdrawFeeBPS(_fee);
    }

    event UpdateWithdrawFeeBPS(uint256 withdrawFeeBPS);

    function setCustomFee(uint256 _fee) external onlyOwner {
        require(_fee <= 20, "Cannot be over 0.02 USDC"); // 1 = 0.001 USDC
        customFee = _fee;
        emit UpdateCustomFee(_fee);
    }

    event UpdateCustomFee(uint256 customFee);
}