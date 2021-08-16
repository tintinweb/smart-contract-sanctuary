// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IFerryNFTMinter.sol";
import "./interfaces/IFerry.sol";

// Integrates with Aave for treasury management

contract Ferry is IFerry, Ownable {
    // TODO add events
    IFerryNFTMinter NFTMinter;
    address public minterAddress;
    ILendingPool AaveLendingPool;
    IERC20 DAI;
    address public daiAddress;

    uint256 public annualFee; // annual pro fee
    uint256 public maxMembershipPeriod; // max membership you can prepay for
    bool public nftsActive;
    uint256 public nftCount;
    uint256 public maxMintedNFTs;
    uint256 public nftThresholdPayment;
    uint256 public constant YEAR = 365 days;

    struct NftData {
        uint256 index;
        uint256 randomNum;
        uint256 tokenID;
    }

    // address => membership expiry timestamp
    mapping(address => uint256) private memberships;
    // For membership NFTs -> 1 per account
    mapping(address => NftData) private nftOwned;
    mapping(address => bool) private nftRequested;

    event SubscriptionPaid(
        address indexed account,
        uint256 amount,
        uint256 expiry
    );
    event NFTNumberGenerated(address indexed account, uint256 randomNumber);
    event NFTMinted(address indexed account, uint256 index, uint256 tokenID);

    constructor(
        uint256 _annualFee,
        uint256 _maxMintedNFTs,
        uint256 _nftThreshold,
        uint256 _maxMembershipPeriod,
        address _dai,
        address _lendingPool,
        address _nftMinter
    ) {
        annualFee = _annualFee;
        maxMembershipPeriod = _maxMembershipPeriod;
        nftThresholdPayment = _nftThreshold;
        maxMintedNFTs = _maxMintedNFTs;

        DAI = IERC20(_dai);
        daiAddress = _dai;
        AaveLendingPool = ILendingPool(_lendingPool);
        NFTMinter = IFerryNFTMinter(_nftMinter);
        minterAddress = _nftMinter;

        // Infinite approve Aave for DAI deposits
        DAI.approve(_lendingPool, type(uint256).max);
    }

    // _account = user receiving subscription
    // _amount  = amount of DAI paid
    function paySubscription(address _account, uint256 _amount) public {
        require(_account != address(0), "FERRY: ZERO ADDRESS CAN'T SUBSCRIBE");
        require(_amount > 0, "FERRY: PAY SOME DAI TO SUBSCRIBE");

        // Transfer payment
        require(
            DAI.transferFrom(msg.sender, address(this), _amount),
            "FERRY: PAYMENT FAILED"
        );

        uint256 proTimeAdded = (YEAR * _amount) / annualFee;

        if (memberships[_account] < block.timestamp) {
            // Membership expired - start new one from now
            // Only charge and allocate up to max membership period
            if (proTimeAdded > maxMembershipPeriod) {
                proTimeAdded = maxMembershipPeriod;
                _amount = (maxMembershipPeriod / YEAR) * annualFee;
            }
            memberships[_account] = block.timestamp + proTimeAdded;
        } else {
            // Membership only expires in the future
            // Only charge and allocate up to max membership period
            uint256 availPeriod = block.timestamp +
                maxMembershipPeriod -
                memberships[_account];
            if (proTimeAdded > availPeriod) {
                proTimeAdded = availPeriod;
                _amount = (availPeriod / YEAR) * annualFee;
            }
            memberships[_account] += proTimeAdded;
        }

        // Only mint NFT if:
        // - NFT minting is active
        // - sender paid at least mint threshold
        // - account hasn't been minted NFT before
        // - NFTs minted doesn't exceed limit
        if (
            nftsActive &&
            _amount >= nftThresholdPayment &&
            !nftRequested[_account] &&
            nftCount < maxMintedNFTs
        ) {
            nftRequested[_account] = true;
            NFTMinter.createNFT(_account);
        }

        emit SubscriptionPaid(_account, _amount, memberships[_account]);
    }

    // Called from NFTMinter when Chainlink responds with random num
    function nftCreatedCallback(address _account, uint256 _randomNum)
        external
        override
        onlyMinter
    {
        nftOwned[_account].randomNum = _randomNum;

        emit NFTNumberGenerated(_account, _randomNum);
    }

    function mintNFT(address _account) external {
        // must have random num but no NFT yet minted
        require(
            nftOwned[_account].randomNum != 0 && nftOwned[_account].index == 0,
            "FERRY: CANT MINT NFT"
        );

        nftCount++;
        nftOwned[_account].index = nftCount;
        NFTMinter.mintNFT(_account);
    }

    function updateNFTData(address _account, uint256 _tokenID)
        external
        override
        onlyMinter
    {
        nftOwned[_account].tokenID = _tokenID;

        emit NFTMinted(_account, nftCount, _tokenID);
    }

    modifier onlyMinter() {
        require(
            minterAddress == msg.sender,
            "FERRY: ONLY MINTER IS AUTHORIZED"
        );
        _;
    }

    //------------------------------//
    //      OWNER FUNCTIONS         //
    //------------------------------//

    // Deposits DAI into Aave to earn interest
    function depositInAave(uint256 _amount) external onlyOwner {
        require(_amount > 0, "FERRY: DEPOSIT MORE THAN ZERO");
        AaveLendingPool.deposit(daiAddress, _amount, address(this), 0);
    }

    // Withdraws DAI from Aave
    function withdrawFromAave(uint256 _amount) external onlyOwner {
        require(_amount > 0, "FERRY: WITHDRAW MORE THAN ZERO");
        AaveLendingPool.withdraw(daiAddress, _amount, address(this));
    }

    // Set annual fee to [_fee] DAI
    function setAnnualFee(uint256 _annualFee) external onlyOwner {
        annualFee = _annualFee;
    }

    // Set length of max membership period that can be prepaid for
    function setMaxMembershipPeriod(uint256 _maxPeriod) external onlyOwner {
        maxMembershipPeriod = _maxPeriod;
    }

    // Set NFT threshold payment to [_threshold] DAI
    function setNftThresholdPayment(uint256 _threshold) external onlyOwner {
        nftThresholdPayment = _threshold;
    }

    // Set max number of NFTs that can be minted
    function setMaxMintedNFTs(uint256 _max) external onlyOwner {
        maxMintedNFTs = _max;
    }

    function setLendingPool(address _lendingPool) external onlyOwner {
        require(_lendingPool != address(0), "FERRY: CAN'T USE ZERO ADDRESS");
        AaveLendingPool = ILendingPool(_lendingPool);
        // Infinite approve Aave for DAI deposits
        DAI.approve(_lendingPool, type(uint256).max);
    }

    function setNFTMinter(address _minter, bool _nftsActive)
        external
        onlyOwner
    {
        require(_minter != address(0), "FERRY: CAN'T USE ZERO ADDRESS");
        NFTMinter = IFerryNFTMinter(_minter);
        minterAddress = _minter;
        nftsActive = _nftsActive;
    }

    function withdrawDAI() external onlyOwner {
        require(
            DAI.transfer(msg.sender, DAI.balanceOf(address(this))),
            "FERRY: DAI WITHDRAW FAILED"
        );
    }

    //------------------------------//
    //      VIEW FUNCTIONS          //
    //------------------------------//

    // Returns the UNIX time that membership for user will expire
    function getMembershipExpiryTime(address _account)
        public
        view
        returns (uint256)
    {
        return memberships[_account];
    }

    // Returns the random num of an address's NFT
    function getAccountNFT(address _account)
        public
        view
        returns (
            uint256 randomNum,
            uint256 index,
            uint256 tokenID
        )
    {
        return (
            nftOwned[_account].randomNum,
            nftOwned[_account].index,
            nftOwned[_account].tokenID
        );
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

// SPDX-License-Identifier: agpl-3.0
// AAVE LENDING POOL
pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IFerryNFTMinter {
    function createNFT(address _account) external;

    function mintNFT(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IFerry {
    function nftCreatedCallback(address _account, uint256 _randomNum) external;

    function updateNFTData(address _account, uint256 _tokenID) external;
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