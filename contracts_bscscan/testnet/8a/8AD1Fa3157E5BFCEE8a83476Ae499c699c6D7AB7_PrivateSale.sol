// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/BEP20/IBEP20.sol";
import "./utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./chainlink/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Vestable.sol";

contract PrivateSale is ReentrancyGuard, Ownable, Vestable {
    using SafeMath for uint256;

    AggregatorV3Interface private priceFeed;
    IQuillToken private quill;
    IBEP20 private busd;
    uint256 private purchaseLimit;
    uint256 private priceImpact;
    uint256 activeSale;
    // uint256 totalPurchased;

    struct SaleConfig {
        string title;
        uint rate;
        uint minimumPurchase;
        uint32 endDate;
        uint32 startDate;
        //bool isActive;
        uint totalSupply;
        uint totalPurchasedPerSale; 
    }

    SaleConfig[] public sales;


    mapping(address => uint256) private tokenPurchased;

    event TokensPurchased(address indexed purchaser, uint256 amount);

    constructor(
        IBEP20 _busd, 
        uint256 _rate,
        uint256 _purchaseLimit,
        uint32 _startDate,
        uint32 _endDate,
        address _priceFeed,
        uint256 _priceImpact,
        uint256 _minimumPurchase,
        IQuillToken _quill,
        IBEP20 _nekoin,
        string memory _title
    ) Vestable(_quill, _nekoin) {
        require(_rate > 0, "Rate is 0");
        require(address(_quill) != address(0), "quill is the zero address");
        require(address(_busd) != address(0), "busd is the zero address");

        quill = _quill;
        busd = _busd;
        purchaseLimit = _purchaseLimit;
        priceFeed = AggregatorV3Interface(_priceFeed);
        priceImpact = _priceImpact;
        quill = _quill;
        nekoin = _nekoin;

        //config initial sale
        addSale(_title, _rate, _minimumPurchase, _endDate, _startDate);
        setTotalSupply(0, 200000000000000000000000, false);

        activeSale = 0;
    }
    // TODO
    // isActive 
    // add totalsupply to addSale()
    // function getTotalSupply() {
        // balance - totalPurchase
    // }

    function setTotalSupply(uint _saleIndex, uint _amount, bool _visible) public {
        SaleConfig storage sale = sales[_saleIndex];
        if(_visible) {
            // real time
            sale.totalSupply = _amount - sale.totalPurchasedPerSale;
        } else {
            // manual
            sale.totalSupply = _amount;
        }
    }

    function getSales() external view returns (uint[] memory) {
        uint[] memory result = new uint[](sales.length);
        for (uint i = 0; i < sales.length; i++) {
                result[i] = i;
        }
        return result;
    }

    function addSale(string memory _title, uint _rate, uint _minimumPurchase, uint32 _endDate, uint32 _startDate) public onlyOwner {
        require(_rate > 0, 'Rate cannot be less than zero');
        SaleConfig memory newSale;
        newSale.title = _title;
        newSale.rate = _rate;
        newSale.minimumPurchase = _minimumPurchase;
        newSale.endDate = _endDate;
        newSale.startDate = _startDate;
        sales.push(newSale);
    }

    function updateSale(uint256 _index, string memory _title, uint _rate, uint _minimumPurchase, uint32 _endDate, uint32 _startDate) external onlyOwner {
        SaleConfig storage sale = sales[_index];
        sale.title = _title;
        sale.rate = _rate;
        sale.minimumPurchase = _minimumPurchase;
        sale.endDate = _endDate;
        sale.startDate = _startDate;
    }

    function setActiveSale(uint256 _index) external onlyOwner {
        activeSale = _index;
    }

    function getSaleConfig(uint _index) public view returns (
        string memory title,
        uint rate,
        uint minimumPurchase,
        uint32 endDate,
        uint32 startDate
    ) {
        SaleConfig storage sale = sales[_index];
        return (
            sale.title,
            sale.rate,
            sale.minimumPurchase,
            sale.endDate,
            sale.startDate
        );
    }

    function getActiveSale() public view returns (uint256) {
        return activeSale;
    }

    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price * 10 ** 10;
    }

    function getTokenPurchased(address purchasher) public view returns (uint256) {
        return tokenPurchased[purchasher];
    }

    function getRate(uint _index) public view returns (uint256) {
        SaleConfig storage sale = sales[_index];
        return sale.rate;
    }

    function getPriceImpact() public view returns (uint256) {
        return priceImpact;
    }

    function getPurchaseLimit() public view returns (uint256) {
        return purchaseLimit;
    }

    function getEndDatePerSale(uint _index) external view returns (uint32) {
        SaleConfig storage sale = sales[_index];
        return sale.endDate;
    }
    function getMinimumPurchasePerSale(uint _index) external view returns (uint256) {
        SaleConfig storage sale = sales[_index];
        return sale.minimumPurchase;
    }

    // function setRate(uint256 _rate) external onlyOwner {
    //     rate = _rate;
    // }

    function setPriceImpact(uint256 _priceImpact) external onlyOwner {
        priceImpact = _priceImpact;
    }

    function setPurchaseLimit(uint256 _purchaseLimit) external onlyOwner {
        purchaseLimit = _purchaseLimit;
    }

    function getBusd() public view returns (IBEP20) {
        return busd;
    }

    function setBusd(IBEP20 _busd) external onlyOwner {
        busd = _busd;
    }

    function getQuill() public view returns (IQuillToken) {
        return quill;
    }

    function setQuill(IQuillToken _quill) external onlyOwner {
        quill = _quill;
    }
    
    function purchaseFromBnb(uint256 _saleIndex, uint256 _lastPrice, bytes memory signature) 
        public 
        whenActive 
        nonReentrant 
        payable
        onlyValid(signature)
    {
        SaleConfig storage sale = sales[_saleIndex];
        require(msg.sender != address(0), "wallet is the zero address");
        require(msg.value != 0, "Amount is 0");
        require(msg.value >= sale.minimumPurchase, "Must be grater than minimum purchase");

        int256 lp = getLatestPrice();
        uint256 bnbInUsd = msg.value * SafeCast.toUint256(lp);
        uint256 token = bnbInUsd * sale.rate / 1000000000000000000;
        uint256 diff = SafeCast.toUint256(lp) - _lastPrice;
        uint256 _priceImpact = diff * 1000000000000000000 / _lastPrice;

        require(_priceImpact <= priceImpact, "Price impact too high");
        require(tokenPurchased[msg.sender].add(token) <= purchaseLimit, "Individual cap exceeded");
        addVest(_saleIndex, token);
        sale.totalPurchasedPerSale += msg.value;
        tokenPurchased[msg.sender] = tokenPurchased[msg.sender].add(token);
        payable(owner()).transfer(msg.value);
        emit TokensPurchased(msg.sender, token);
    }

    function purchaseFromBusd(uint256 _saleIndex, uint256 _busdAmount, bytes memory signature) 
        external 
        whenActive
        onlyValid(signature)
    {
        // only if active
        SaleConfig storage sale = sales[_saleIndex];
        require(msg.sender != address(0), "wallet is the zero address");
        require(_busdAmount > 0, 'BUSD amount is zero');
        require(_busdAmount >= sale.minimumPurchase, "Must be grater than minimum purchase");

        uint256 token = _busdAmount * sale.rate;

        require(tokenPurchased[msg.sender].add(token) <= purchaseLimit, "Individual cap exceeded");

        busd.transferFrom(msg.sender, owner(), _busdAmount);
        addVest(activeSale, token);
        sale.totalPurchasedPerSale += _busdAmount;
        tokenPurchased[msg.sender] = tokenPurchased[msg.sender].add(token);
        emit TokensPurchased(msg.sender, token);
    }

    function purchaseFromQuill(uint256 _saleIndex, uint256 _quillAmount, bytes memory signature) 
        external 
        whenActive 
        onlyValid(signature) 
    {
        // only if active
        SaleConfig storage sale = sales[_saleIndex];
        require(msg.sender != address(0), "wallet is the zero address");
        require(_quillAmount > 0, 'QUT amount is zero');
        require(_quillAmount >= sale.minimumPurchase, "Must be grater than minimum purchase");
        uint256 token = _quillAmount;
        require(tokenPurchased[msg.sender].add(token) <= purchaseLimit, "Individual cap exceeded");
        quill.transferFrom(msg.sender, owner(), _quillAmount);
        addVest(_saleIndex, token);
        sale.totalPurchasedPerSale += _quillAmount;
        tokenPurchased[msg.sender] = tokenPurchased[msg.sender].add(token);
        emit TokensPurchased(msg.sender, token);
    }

    // function activate() external onlyOwner {
    //     isActive = true;
    // }

    // function deactivate() external onlyOwner {
    //     isActive = false;
    // }

    function withdraw() external onlyOwner whenInactive {
        uint256 nekoinBalance = nekoin.balanceOf(address(this));
        require(nekoinBalance >= 0, 'Nekoin is 0 balance');
        nekoin.transfer(owner(), nekoinBalance);
    }

    modifier whenActive {
        SaleConfig storage sale = sales[activeSale];
        // require(sales[_index].isActive);
        require(block.timestamp < sale.endDate, 'Token Sale is not active');
        _;
    }

    modifier whenInactive {
        SaleConfig storage sale = sales[activeSale];
        require(block.timestamp >= sale.endDate, 'Token Sale is active');
        _;
    }

    function getMessageHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(this, msg.sender));
    }

    function getEthSignedMessageHash(bytes32 messageHash) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
            );
    }

    function verify(bytes memory signature) public view returns (bool) {
        bytes32 messageHash = getMessageHash();
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return ECDSA.recover( ethSignedMessageHash, signature) == owner();
    }

    modifier onlyValid(bytes memory signature){
        require(signature.length == 65, "Signature not valid.");
        require( verify(signature), 'Address not whitelisted.' );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/BEP20/IQuillToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract Vestable is Ownable {

    IQuillToken quillToken;
    IBEP20 nekoin;
    uint32 CLIFF_IN_MINUTES = 2 minutes; // 30 days
    uint32 MINUTES_PER_PERIOD = 2;
    uint32 TOTAL_PERIOD = 10;

    enum Status {
        CLaimable,
        Claimed,
        Pending
    }

    struct Vest {
        uint256 amount;
        uint8 progress;
        uint256 claimedAmount;
        uint32 dateStarted;
    }

    struct Schedule {
        uint32 releaseDate;
        uint8 percentage;
        uint256 amount;
        Status status;
    }

    event VestCreated(uint index, uint256 amount, address owner);
    event VestClaimed(uint index, uint256 amount, address owner);

    Vest[] vests;

    mapping (uint256 => mapping(uint256 => address)) public vestToOwner;
    mapping (uint256 => mapping(address => uint)) public ownerVestCount;
    mapping (address => uint) public totalVest;
    
    Schedule[] schedule;
    mapping (uint => uint) public scheduleToVest;
    mapping (uint => uint) public scheduleCount;
    mapping (uint => mapping(uint32 => bool)) public isClaimed;
    mapping (uint => mapping(uint32 => uint256)) public claimedDate;


    constructor(IQuillToken _quillToken, IBEP20 _nekoin) {
        quillToken = _quillToken;
        nekoin = _nekoin;
    }

    // Getters 

    /**
     * @dev gets all the vest of a wallet;
     *
     * Returns an array of indices for each vest
     */
    function vestsByOwner(address _owner, uint256 _saleIndex) external view returns (uint[] memory) {
        uint[] memory result = new uint[](ownerVestCount[_saleIndex][_owner]);
        uint counter = 0;
        for (uint i = 0; i < vests.length; i++) {
            if (vestToOwner[_saleIndex][i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function scheduleByVest(uint256 _index) external view returns (uint[] memory) {
        Vest storage vest = vests[_index];
        uint[] memory result = new uint[](10);
        uint prevClaimDate = _gmtMidnight(vest.dateStarted) + CLIFF_IN_MINUTES;
        for (uint i = 0; i < 10; i++) {
            result[i] = prevClaimDate + CLIFF_IN_MINUTES;
            prevClaimDate = result[i];
        }
        return result;
    }

    function getSchedule(uint32 _date, uint256 _index) public view returns (
        uint releaseDate,
        uint8 percentage,
        uint amount,
        uint dateClaimed,
        Status status
    ) {
        Vest storage vest = vests[_index];
        if (_date > block.timestamp) {
            percentage = 10;
            amount = _tenPercentOf(vest.amount);
            status = Status.Pending;
        } else {
            percentage = 10;
            amount = _tenPercentOf(vest.amount);
            if (isClaimed[_index][_date]) { status = Status.Claimed; dateClaimed = claimedDate[_index][_date]; } 
            else { status = Status.CLaimable; }
        }
        return (
            _date,
            percentage,
            amount,
            dateClaimed,
            status
        );
    }

    /**
     * @dev return each vest of a wallet by index;
     *
     * Returns vest[_index]
     */
    function vestByIndex(uint _index) public view returns (
        uint256 index,
        uint256 amount, 
        uint8 progress,
        uint256 claimedAmount,
        uint32 dateCreated
    ) 
    {
        Vest storage vest = vests[_index];
        return (
            _index,
            vest.amount, 
            vest.progress,
            vest.claimedAmount,
            vest.dateStarted
        );
    }

    function addVest(uint256 _index, uint256 _amount) internal {
        require(_amount != 0, 'Amount cannot be zero');

        Vest memory newVest;
        newVest.amount = _amount;
        newVest.claimedAmount = 0;
        newVest.dateStarted = uint32(block.timestamp);
        newVest.progress = 0;
        vests.push(newVest);
        uint index = vests.length - 1;

        vestToOwner[_index][index] = msg.sender;
        ownerVestCount[_index][msg.sender]++;
        totalVest[msg.sender] += _amount;

        emit VestCreated(index, _amount, msg.sender);
    }

    function claimVest(uint256 _saleIndex, uint256 _index, uint32 _releaseDate) external {
        require(vestToOwner[_saleIndex][_index] == msg.sender, 'Caller is not the vestor');
        Vest storage vest = vests[_index];
        require(vest.amount != vest.claimedAmount, 'Already claimed');
        require(block.timestamp >= _releaseDate, 'Function cannot call now');
        (
            ,
            uint8 percentage,
            uint amount,,
            Status status
        ) = getSchedule(_releaseDate, _index);

        require(status == Status.CLaimable, 'Function cannot call now');
        nekoin.transfer(msg.sender, amount);

        vest.progress += percentage;
        vest.claimedAmount += amount;

        isClaimed[_index][_releaseDate] = true;
        claimedDate[_index][_releaseDate] = block.timestamp;

        emit VestClaimed(_index, amount, msg.sender);   
    }

    function _tenPercentOf(uint256 _amount) private pure returns (uint256 tenPercent) {
        tenPercent = (_amount / 100) * 10;
    }

    function _gmtMidnight(uint32 _timestamp) private view returns (uint32 gmtMidnight) {
        gmtMidnight = _timestamp;
        if (CLIFF_IN_MINUTES > 1440) {
            gmtMidnight = _timestamp - _timestamp % 86400;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity ^0.8.0;

import "./IBEP20.sol";

interface IQuillToken is IBEP20 {
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
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
    constructor () {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param hash      Hash of the data to be signed
   * @param signature Signature byte array associated with _data
   */
  function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract sigantures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        if (Address.isContract(signer)) {
            try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
                return magicValue == IERC1271(signer).isValidSignature.selector;
            } catch {
                return false;
            }
        } else {
            return ECDSA.recover(hash, signature) == signer;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}