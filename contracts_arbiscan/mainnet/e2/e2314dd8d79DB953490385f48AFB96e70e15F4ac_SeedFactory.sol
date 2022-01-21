/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0-or-later
// PrimeDAO Seed Factory contract. Enable PrimeDAO governance to create new Seed contracts.
// Copyright (C) 2021 PrimeDao

// solium-disable linebreak-style
/* solhint-disable space-after-comma */

pragma solidity 0.8.9;

import "openzeppelin-contracts-sol8/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-sol8/access/Ownable.sol";
import "./Seed.sol";
import "../utils/CloneFactory.sol";

/**
 * @title PrimeDAO Seed Factory
 * @dev   Enable PrimeDAO governance to create new Seed contracts.
 */
contract SeedFactory is CloneFactory, Ownable {
    Seed public masterCopy;

    event SeedCreated(address indexed newSeed, address indexed admin);

    /**
     * @dev               Set Seed contract which works as a base for clones.
     * @param _masterCopy The address of the new Seed basis.
     */
    function setMasterCopy(Seed _masterCopy) external onlyOwner {
        require(
            address(_masterCopy) != address(0),
            "SeedFactory: new mastercopy cannot be zero address"
        );
        masterCopy = _masterCopy;
    }

    /**
      * @dev                                Deploys Seed contract.
      * @param _beneficiary                 The address that recieves fees.
      * @param _admin                       The address of the admin of this contract. Funds contract
                                            and has permissions to whitelist users, pause and close contract.
      * @param _tokens                      Array containing two params:
                                                - The address of the seed token being distributed.
      *                                         - The address of the funding token being exchanged for seed token.
      * @param _softHardThresholds          Array containing two params:
                                                - the minimum funding token collection threshold in wei denomination.
                                                - the highest possible funding token amount to be raised in wei denomination.
      * @param _price                       price of a SeedToken, expressed in fundingTokens, with precision of 10**18
      * @param _startTime                   Distribution start time in unix timecode.
      * @param _endTime                     Distribution end time in unix timecode.
      * @param _vestingDurationAndCliff       Array containing two params:
                                                - Vesting period duration in days.
                                                - Cliff duration in days.
      * @param _permissionedSeed      Set to true if only whitelisted adresses are allowed to participate.
      * @param _fee                   Success fee expressed as a % (e.g. 10**18 = 100% fee, 10**16 = 1%)
      * @param _metadata              Seed contract metadata, that is IPFS URI
    */
    function deploySeed(
        address _beneficiary,
        address _admin,
        address[] memory _tokens,
        uint256[] memory _softHardThresholds,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint32[] memory _vestingDurationAndCliff,
        bool _permissionedSeed,
        uint256 _fee,
        bytes memory _metadata
    ) external onlyOwner returns (address) {
        {
            require(
                address(masterCopy) != address(0),
                "SeedFactory: mastercopy cannot be zero address"
            );
            require(
                _vestingDurationAndCliff.length == 2,
                "SeedFactory: Hasn't provided both vesting duration and cliff"
            );
        }

        // deploy clone
        address _newSeed = createClone(address(masterCopy));

        Seed(_newSeed).updateMetadata(_metadata);

        // initialize
        Seed(_newSeed).initialize(
            _beneficiary,
            _admin,
            _tokens,
            _softHardThresholds,
            _price,
            _startTime,
            _endTime,
            _vestingDurationAndCliff[0],
            _vestingDurationAndCliff[1],
            _permissionedSeed,
            _fee
        );

        emit SeedCreated(address(_newSeed), _admin);

        return _newSeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0-or-later
// PrimeDAO Seed contract. Smart contract for seed phases of liquid launch.
// Copyright (C) 2021 PrimeDao

// solium-disable operator-whitespace
/* solhint-disable space-after-comma */
/* solhint-disable max-states-count */
// solium-disable linebreak-style
pragma solidity 0.8.9;

import "openzeppelin-contracts-sol8/token/ERC20/IERC20.sol";

/**
 * @title PrimeDAO Seed contract
 * @dev   Smart contract for seed phases of liquid launch.
 */
contract Seed {
    // Locked parameters
    address public beneficiary;
    address public admin;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public seedAmountRequired; // Amount of seed required for distribution
    uint256 public feeAmountRequired; // Amount of seed required for fee
    uint256 public price; // price of a SeedToken, expressed in fundingTokens, with precision of 10**18
    uint256 public startTime;
    uint256 public endTime; // set by project admin, this is the last resort endTime to be applied when
    //     maximumReached has not been reached by then
    bool public permissionedSeed;
    uint32 public vestingDuration;
    uint32 public vestingCliff;
    IERC20 public seedToken;
    IERC20 public fundingToken;
    uint256 public fee; // Success fee expressed as a % (e.g. 10**18 = 100% fee, 10**16 = 1%)

    bytes public metadata; // IPFS Hash

    uint256 internal constant PRECISION = 10**18; // used for precision e.g. 1 ETH = 10**18 wei; toWei("1") = 10**18

    // Contract logic
    bool public closed; // is the distribution closed
    bool public paused; // is the distribution paused
    bool public isFunded; // distribution can only start when required seed tokens have been funded
    bool public initialized; // is this contract initialized [not necessary that it is funded]
    bool public minimumReached; // if the softCap[minimum limit of funding token] is reached
    bool public maximumReached; // if the hardCap[maximum limit of funding token] is reached
    bool public isWhitelistBatchInvoked; // if the whitelistBatch method have been invoked
    uint256 public vestingStartTime; // timestamp for when vesting starts, by default == endTime,
    //     otherwise when maximumReached is reached
    uint256 public totalFunderCount; // Total funders that have contributed.
    uint256 public seedRemainder; // Amount of seed tokens remaining to be distributed
    uint256 public seedClaimed; // Amount of seed token claimed by the user.
    uint256 public feeRemainder; // Amount of seed tokens remaining for the fee
    uint256 public fundingCollected; // Amount of funding tokens collected by the seed contract.
    uint256 public fundingWithdrawn; // Amount of funding token withdrawn from the seed contract.

    mapping(address => bool) public whitelisted; // funders that are whitelisted and allowed to contribute
    mapping(address => FunderPortfolio) public funders; // funder address to funder portfolio

    event SeedsPurchased(address indexed recipient, uint256 amountPurchased);
    event TokensClaimed(
        address indexed recipient,
        uint256 amount,
        address indexed beneficiary,
        uint256 feeAmount
    );
    event FundingReclaimed(address indexed recipient, uint256 amountReclaimed);
    event MetadataUpdated(bytes indexed metadata);

    struct FunderPortfolio {
        uint256 totalClaimed; // Total amount of seed tokens claimed
        uint256 fundingAmount; // Total amount of funding tokens contributed
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Seed: caller should be admin");
        _;
    }

    modifier isActive() {
        require(!closed, "Seed: should not be closed");
        require(!paused, "Seed: should not be paused");
        _;
    }

    /**
      * @dev                          Initialize Seed.
      * @param _beneficiary           The address that recieves fees.
      * @param _admin                 The address of the admin of this contract. Funds contract
                                      and has permissions to whitelist users, pause and close contract.
      * @param _tokens                Array containing two params:
                                        - The address of the seed token being distributed.
      *                                 - The address of the funding token being exchanged for seed token.
      * @param _softHardThresholds    Array containing two params:
                                        - the minimum funding token collection threshold in wei denomination.
                                        - the highest possible funding token amount to be raised in wei denomination.
      * @param _price                 price of a SeedToken, expressed in fundingTokens, with precision of 10**18
      * @param _startTime             Distribution start time in unix timecode.
      * @param _endTime               Distribution end time in unix timecode.
      * @param _vestingDuration       Vesting period duration in seconds.
      * @param _vestingCliff          Cliff duration in seconds.
      * @param _permissionedSeed      Set to true if only whitelisted adresses are allowed to participate.
      * @param _fee                   Success fee expressed as a % (e.g. 10**18 = 100% fee, toWei('1') = 100%)
    */
    function initialize(
        address _beneficiary,
        address _admin,
        address[] memory _tokens,
        uint256[] memory _softHardThresholds,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint32 _vestingDuration,
        uint32 _vestingCliff,
        bool _permissionedSeed,
        uint256 _fee
    ) external {
        require(!initialized, "Seed: contract already initialized");
        initialized = true;

        // parameter check
        require(
            _tokens[0] != _tokens[1],
            "SeedFactory: seedToken cannot be fundingToken"
        );
        require(
            _softHardThresholds[1] >= _softHardThresholds[0],
            "SeedFactory: hardCap cannot be less than softCap"
        );
        require(
            _vestingDuration >= _vestingCliff,
            "SeedFactory: vestingDuration cannot be less than vestingCliff"
        );
        require(
            _endTime > _startTime,
            "SeedFactory: endTime cannot be less than equal to startTime"
        );

        beneficiary = _beneficiary;
        admin = _admin;
        softCap = _softHardThresholds[0];
        hardCap = _softHardThresholds[1];
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        vestingStartTime = endTime;
        vestingDuration = _vestingDuration;
        vestingCliff = _vestingCliff;
        permissionedSeed = _permissionedSeed;
        seedToken = IERC20(_tokens[0]);
        fundingToken = IERC20(_tokens[1]);
        fee = _fee;

        seedAmountRequired = (hardCap * PRECISION) / _price;
        // (seedAmountRequired*fee) / (100*FEE_PRECISION) = (seedAmountRequired*fee) / PRECISION
        //  where FEE_PRECISION = 10**16
        feeAmountRequired = (seedAmountRequired * fee) / PRECISION;
        seedRemainder = seedAmountRequired;
        feeRemainder = feeAmountRequired;
    }

    /**
     * @dev                     Buy seed tokens.
     * @param _fundingAmount    The amount of funding tokens to contribute.
     */
    function buy(uint256 _fundingAmount)
        external
        isActive
        returns (uint256, uint256)
    {
        require(!maximumReached, "Seed: maximum funding reached");
        require(
            !permissionedSeed || whitelisted[msg.sender],
            "Seed: sender has no rights"
        );
        require(
            endTime >= block.timestamp && startTime <= block.timestamp,
            "Seed: only allowed during distribution period"
        );
        if (!isFunded) {
            require(
                seedToken.balanceOf(address(this)) >=
                    seedAmountRequired + feeAmountRequired,
                "Seed: sufficient seeds not provided"
            );
            isFunded = true;
        }
        // fundingAmount is an amount of fundingTokens required to buy _seedAmount of SeedTokens
        uint256 seedAmount = (_fundingAmount * PRECISION) / price;

        // feeAmount is an amount of fee we are going to get in seedTokens
        uint256 feeAmount = (seedAmount * fee) / PRECISION;

        // seed amount vested per second > zero, i.e. amountVestedPerSecond = seedAmount/vestingDuration
        require(
            seedAmount >= vestingDuration,
            "Seed: amountVestedPerSecond > 0"
        );

        // total fundingAmount should not be greater than the hardCap
        require(
            fundingCollected + _fundingAmount <= hardCap,
            "Seed: amount exceeds contract sale hardCap"
        );

        fundingCollected += _fundingAmount;

        // the amount of seed tokens still to be distributed
        seedRemainder -= seedAmount;
        feeRemainder -= feeAmount;

        if (fundingCollected >= softCap) {
            minimumReached = true;
        }
        if (fundingCollected >= hardCap) {
            maximumReached = true;
            vestingStartTime = block.timestamp;
        }

        //functionality of addFunder
        if (funders[msg.sender].fundingAmount == 0) {
            totalFunderCount++;
        }
        funders[msg.sender].fundingAmount += _fundingAmount;

        // Here we are sending amount of tokens to pay for seed tokens to purchase
        require(
            fundingToken.transferFrom(
                msg.sender,
                address(this),
                _fundingAmount
            ),
            "Seed: funding token transferFrom failed"
        );

        emit SeedsPurchased(msg.sender, seedAmount);

        return (seedAmount, feeAmount);
    }

    /**
     * @dev                     Claim vested seed tokens.
     * @param _funder           Address of funder to calculate seconds and amount claimable
     * @param _claimAmount      The amount of seed token a users wants to claim.
     */
    function claim(address _funder, uint256 _claimAmount)
        external
        returns (uint256)
    {
        require(minimumReached, "Seed: minimum funding amount not met");
        require(
            endTime < block.timestamp || maximumReached,
            "Seed: the distribution has not yet finished"
        );
        uint256 amountClaimable;

        amountClaimable = calculateClaim(_funder);
        require(amountClaimable > 0, "Seed: amount claimable is 0");
        require(
            amountClaimable >= _claimAmount,
            "Seed: request is greater than claimable amount"
        );
        uint256 feeAmountOnClaim = (_claimAmount * fee) / PRECISION;

        funders[_funder].totalClaimed += _claimAmount;

        seedClaimed += _claimAmount;
        require(
            seedToken.transfer(beneficiary, feeAmountOnClaim) &&
                seedToken.transfer(_funder, _claimAmount),
            "Seed: seed token transfer failed"
        );

        emit TokensClaimed(
            _funder,
            _claimAmount,
            beneficiary,
            feeAmountOnClaim
        );

        return feeAmountOnClaim;
    }

    /**
     * @dev         Returns funding tokens to user.
     */
    function retrieveFundingTokens() external returns (uint256) {
        require(
            startTime <= block.timestamp,
            "Seed: distribution haven't started"
        );
        require(!minimumReached, "Seed: minimum funding amount met");
        FunderPortfolio storage tokenFunder = funders[msg.sender];
        uint256 fundingAmount = tokenFunder.fundingAmount;
        require(fundingAmount > 0, "Seed: zero funding amount");
        seedRemainder += seedAmountForFunder(msg.sender);
        feeRemainder += feeForFunder(msg.sender);
        totalFunderCount--;
        tokenFunder.fundingAmount = 0;
        fundingCollected -= fundingAmount;
        require(
            fundingToken.transfer(msg.sender, fundingAmount),
            "Seed: cannot return funding tokens to msg.sender"
        );
        emit FundingReclaimed(msg.sender, fundingAmount);

        return fundingAmount;
    }

    // ADMIN ACTIONS

    /**
     * @dev                     Pause distribution.
     */
    function pause() external onlyAdmin isActive {
        paused = true;
    }

    /**
     * @dev                     Unpause distribution.
     */
    function unpause() external onlyAdmin {
        require(closed != true, "Seed: should not be closed");
        require(paused == true, "Seed: should be paused");

        paused = false;
    }

    /**
      * @dev                Shut down contributions (buying).
                            Supersedes the normal logic that eventually shuts down buying anyway.
                            Also shuts down the admin's ability to alter the whitelist.
    */
    function close() external onlyAdmin {
        // close seed token distribution
        require(!closed, "Seed: should not be closed");
        closed = true;
        paused = false;
    }

    /**
     * @dev                     retrieve remaining seed tokens back to project.
     * @param _refundReceiver   refund receiver address
     */
    function retrieveSeedTokens(address _refundReceiver) external onlyAdmin {
        // transfer seed tokens back to admin
        /*
            Can't withdraw seed tokens until buying has ended and
            therefore the number of distributable seed tokens can no longer change.
        */
        require(
            closed || maximumReached || block.timestamp >= endTime,
            "Seed: The ability to buy seed tokens must have ended before remaining seed tokens can be withdrawn"
        );
        if (!minimumReached) {
            require(
                seedToken.transfer(
                    _refundReceiver,
                    seedToken.balanceOf(address(this))
                ),
                "Seed: should transfer seed tokens to refund receiver"
            );
        } else {
            // seed tokens to transfer = balance of seed tokens - totalSeedDistributed
            uint256 totalSeedDistributed = (seedAmountRequired +
                feeAmountRequired) - (seedRemainder + feeRemainder);
            uint256 amountToTransfer = seedToken.balanceOf(address(this)) -
                totalSeedDistributed;
            require(
                seedToken.transfer(_refundReceiver, amountToTransfer),
                "Seed: should transfer seed tokens to refund receiver"
            );
        }
    }

    /**
     * @dev                     Add address to whitelist.
     * @param _buyer            Address which needs to be whitelisted
     */
    function whitelist(address _buyer) external onlyAdmin {
        require(!closed, "Seed: should not be closed");
        require(permissionedSeed == true, "Seed: seed is not whitelisted");

        whitelisted[_buyer] = true;
    }

    /**
     * @dev                     Add multiple addresses to whitelist.
     * @param _buyers           Array of addresses to whitelist addresses in batch
     */
    function whitelistBatch(address[] memory _buyers) external onlyAdmin {
        require(!closed, "Seed: should not be closed");
        require(permissionedSeed == true, "Seed: seed is not whitelisted");
        isWhitelistBatchInvoked = true;
        for (uint256 i = 0; i < _buyers.length; i++) {
            whitelisted[_buyers[i]] = true;
        }
    }

    /**
     * @dev                     Remove address from whitelist.
     * @param buyer             Address which needs to be unwhitelisted
     */
    function unwhitelist(address buyer) external onlyAdmin {
        require(!closed, "Seed: should not be closed");
        require(permissionedSeed == true, "Seed: seed is not whitelisted");

        whitelisted[buyer] = false;
    }

    /**
     * @dev                     Withdraw funds from the contract
     */
    function withdraw() external onlyAdmin {
        /*
            Admin can't withdraw funding tokens until buying has ended and
            therefore contributors can no longer withdraw their funding tokens.
        */
        require(
            maximumReached || (minimumReached && block.timestamp >= endTime),
            "Seed: cannot withdraw while funding tokens can still be withdrawn by contributors"
        );
        uint256 pendingFundingBalance = fundingCollected - fundingWithdrawn;
        fundingWithdrawn = fundingCollected;
        fundingToken.transfer(msg.sender, pendingFundingBalance);
    }

    /**
     * @dev                     Updates metadata.
     * @param _metadata         Seed contract metadata, that is IPFS Hash
     */
    function updateMetadata(bytes memory _metadata) external {
        require(
            initialized != true || msg.sender == admin,
            "Seed: contract should not be initialized or caller should be admin"
        );
        metadata = _metadata;
        emit MetadataUpdated(_metadata);
    }

    // GETTER FUNCTIONS
    /**
     * @dev                     Calculates the maximum claim
     * @param _funder           Address of funder to find the maximum claim
     */
    function calculateClaim(address _funder) public view returns (uint256) {
        FunderPortfolio storage tokenFunder = funders[_funder];

        if (block.timestamp < vestingStartTime) {
            return 0;
        }

        // Check cliff was reached
        uint256 elapsedSeconds = block.timestamp - vestingStartTime;

        if (elapsedSeconds < vestingCliff) {
            return 0;
        }

        // If over vesting duration, all tokens vested
        if (elapsedSeconds >= vestingDuration) {
            return seedAmountForFunder(_funder) - tokenFunder.totalClaimed;
        } else {
            uint256 amountVested = (elapsedSeconds *
                seedAmountForFunder(_funder)) / vestingDuration;
            return amountVested - tokenFunder.totalClaimed;
        }
    }

    /**
     * @dev                     Amount of seed tokens claimed as fee
     */
    function feeClaimed() public view returns (uint256) {
        return (seedClaimed * fee) / PRECISION;
    }

    /**
     * @dev                     get fee claimed for funder
     * @param _funder           address of funder to check fee claimed
     */
    function feeClaimedForFunder(address _funder)
        public
        view
        returns (uint256)
    {
        return (funders[_funder].totalClaimed * fee) / PRECISION;
    }

    /**
     * @dev                     get fee for funder
     * @param _funder           address of funder to check fee
     */
    function feeForFunder(address _funder) public view returns (uint256) {
        return (seedAmountForFunder(_funder) * fee) / PRECISION;
    }

    /**
     * @dev                     get seed amount for funder
     * @param _funder           address of funder to seed amount
     */
    function seedAmountForFunder(address _funder)
        public
        view
        returns (uint256)
    {
        return (funders[_funder].fundingAmount * PRECISION) / price;
    }
}

/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

* ===========
*
* CloneFactory.sol was originally published under MIT license.
* Republished by PrimeDAO under GNU General Public License v3.0.
*
*/

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// solium-disable linebreak-style
// solhint-disable max-line-length
// solhint-disable no-inline-assembly

pragma solidity 0.8.9;

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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