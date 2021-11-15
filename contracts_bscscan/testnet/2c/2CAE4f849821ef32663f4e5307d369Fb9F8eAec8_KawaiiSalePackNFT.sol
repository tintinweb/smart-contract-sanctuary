pragma solidity 0.6.12;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disab le-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public BUY_PACK_HASH;
    mapping(address => uint) public nonces;


    constructor() internal {
        NAME = "KawaiiSalePackNFT";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );

        BUY_PACK_HASH = keccak256("Data(address sender,uint256 pack,uint256 amount,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

interface IKawaiiRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber) external returns (uint256);
}

interface IERC1155 {
    function mint(address to, uint256 tokenId, uint256 value) external;
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        Unpause();
    }
}

contract KawaiiSalePackNFT is Pausable, SignData {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    struct PackData {
        uint256 tree;
        uint256 animal;
        uint256 field;
        uint256 price;
        uint256 incrementPrice;
        uint256 limit;
        uint256 purchasedPackNumber;
        uint96 startTime;
        uint96 duration;
        uint96 endTime;
    }

    PackData[] public packs;
    IERC20 public tokenPayment;
    IKawaiiRandomness public kawaiiRandomness;
    uint256[] public animals;
    uint256[] public trees;
    uint256 public fieldId;
    uint256 public limitPerAccount;
    //address => startTime => amount
    mapping(address => mapping(uint256 => uint256)) public amountPerAccount;
    uint256 public limitInSale;
    mapping(address => uint256) public purchasedInAccount;

    mapping(uint256 => uint256[]) public animalToTree;

    event BuyPack(address buyer, uint256 packNumber, uint256[] animals, uint256[] plants, uint256 numberField, uint256 purchasedIndex, uint256 amount);
    event UpdateStartTime(uint96 oldStartTime, uint96 newStartTime);

    constructor(IERC20 _tokenPayment, IKawaiiRandomness _kawaiiRandomness, uint256 _limitPerAccount) public {
        kawaiiRandomness = _kawaiiRandomness;
        tokenPayment = _tokenPayment;
        limitPerAccount = _limitPerAccount;
        limitInSale = 2;
    }

    function setLimitPerAccount(uint256 _limitPerAccount) external onlyOwner {
        limitPerAccount = _limitPerAccount;
    }

    function setLimitInSale(uint256 _limitInSale) external onlyOwner {
        limitInSale = _limitInSale;
    }

    function setField(uint256 _fieldId) external onlyOwner {
        fieldId = _fieldId;
    }

    function setAnimalToTree(uint256 animalId, uint256[] memory treeIds) external onlyOwner {
        animalToTree[animalId] = treeIds;
    }

    function setTree(uint256[] calldata _trees) external onlyOwner {
        trees = _trees;
    }

    function setAnimals(uint256[] calldata _animals) external onlyOwner {
        animals = _animals;
    }

    function setTokenPayment(IERC20 token) external onlyOwner {
        tokenPayment = token;
    }

    function setKawaiiRandomness(IKawaiiRandomness _kawaiiRandomness) external onlyOwner {
        kawaiiRandomness = _kawaiiRandomness;
    }

    function createPack(uint256 _numberTree, uint256 _numberAnimal, uint256 _numberField, uint256 _price, uint256 _incrementPrice, uint256 _limit, uint96 _startTime, uint96 _duration, uint96 _endTime) external onlyOwner {
        require(_numberAnimal < _numberTree, "Animal must < tree");
        packs.push(PackData(_numberTree, _numberAnimal, _numberField, _price, _incrementPrice, _limit, 0, _startTime, _duration, _endTime));

    }

    function updatePack(uint256 _pack, uint256 _numberTree, uint256 _numberAnimal, uint256 _numberField, uint256 _price, uint256 _incrementPrice, uint256 _limit, uint256 _purchasedNumber, uint96 _startTime, uint96 _duration, uint96 _endTime) external onlyOwner {
        require(_numberAnimal < _numberTree, "Animal must < tree");
        packs[_pack] = PackData(_numberTree, _numberAnimal, _numberField, _price, _incrementPrice, _limit, _purchasedNumber, _startTime, _duration, _endTime);
    }

    function getLenPack() external view returns (uint256){
        return packs.length;
    }

    function getPrice(uint256 amount, uint256 pack) external view returns (uint256){
        PackData memory packData = packs[pack];
        uint256 purchasedPackNumber = packData.purchasedPackNumber;
        if ((uint96(block.timestamp) - packData.startTime) / packData.duration >= 1) {
            purchasedPackNumber = 0;
        }
        return getPrice(packData.price, packData.incrementPrice, amount, purchasedPackNumber);
    }

    function getPrice(uint256 price, uint256 incrementPrice, uint256 amount, uint256 purchasedPackNumber) internal pure returns (uint256){
        uint256 currentPrice = purchasedPackNumber.mul(incrementPrice).add(price);
        uint256 incrementPriceWithAmount = amount.mul(amount.sub(1)).div(2).mul(incrementPrice);
        return currentPrice.mul(amount).add(incrementPriceWithAmount);
    }

    function buyPack(IERC1155 nftRegister, address sender, uint256 pack, uint256 amount, uint256 price, uint8 v, bytes32 r, bytes32 s) external whenNotPaused {
        verify(keccak256(abi.encode(BUY_PACK_HASH, sender, pack, amount, nonces[sender]++)), sender, v, r, s);
        require(purchasedInAccount[sender].add(amount) <= limitInSale, "Exceed limit one account in this sale");
        purchasedInAccount[sender] = purchasedInAccount[sender].add(amount);
        PackData memory packData = packs[pack];
        {
            require(uint96(block.timestamp) >= packData.startTime && uint96(block.timestamp) <= packData.endTime, "Expired");
            uint96 multiple = ((uint96(block.timestamp) - packData.startTime) / packData.duration);
            uint256 amountPay;
            if (multiple >= 1) {
                packs[pack].startTime += multiple * packData.duration;
                emit UpdateStartTime(packData.startTime, packs[pack].startTime);
                require(amount <= packData.limit, "Exceed limit in this sale");
                packs[pack].purchasedPackNumber = amount;
                amountPay = getPrice(packData.price, packData.incrementPrice, amount, 0);
                require(amount <= limitPerAccount, "Exceed limit in the account");
                amountPerAccount[sender][packData.startTime] = amount;
            }
            else {
                require(packData.purchasedPackNumber.add(amount) <= packData.limit, "Exceed limit in this sale");
                packs[pack].purchasedPackNumber = packData.purchasedPackNumber.add(amount);
                amountPay = getPrice(packData.price, packData.incrementPrice, amount, packData.purchasedPackNumber);
                require(amountPerAccount[sender][packData.startTime].add(amount) <= limitPerAccount, "Exceed limit in the account");
                amountPerAccount[sender][packData.startTime] = amountPerAccount[sender][packData.startTime].add(amount);
            }
            require(amountPay <= price, "Exceed price");
            IERC20(tokenPayment).safeTransferFrom(sender, address(this), amountPay);
        }
        uint256[] memory animalsInPack;
        uint256[] memory treesInPack;

        for (uint256 i = 0; i < amount; i++) {
            (animalsInPack, treesInPack) = randomItem(packData.animal, packData.tree);
            _mintItem(nftRegister, sender, packData.field, animalsInPack, treesInPack);
        }
        emit BuyPack(sender, pack, animalsInPack, treesInPack, packData.field, packData.purchasedPackNumber, amount);
    }

    function _mintItem(IERC1155 nftRegister, address sender, uint256 numberField, uint256[] memory animalsInPack, uint256[] memory treesInPack) internal {
        for (uint256 i = 0; i < animalsInPack.length; i++) {
            nftRegister.mint(sender, animalsInPack[i], 1);
        }
        for (uint256 i = 0; i < treesInPack.length; i++) {
            nftRegister.mint(sender, treesInPack[i], 1);
        }
        nftRegister.mint(sender, fieldId, numberField);
    }

    function randomItem(uint256 numberAnimal, uint256 numberTree) internal returns (uint256[] memory, uint256[] memory){
        require(numberTree >= numberAnimal, "Animal must < tree");
        uint256[] memory animalIds = new  uint256[](numberAnimal);
        uint256[] memory treeIds = new  uint256[](numberTree);

        for (uint256 i = 0; i < numberAnimal; i++) {
            animalIds[i] = chooseAnimal(animals.length, gasleft());
            treeIds[i] = chooseTree(animalIds[i], gasleft());
        }
        for (uint256 i = numberAnimal; i < numberTree; i++) {
            treeIds[i] = chooseTreeWithoutRules(trees.length, gasleft());
        }
        return (animalIds, treeIds);
    }

    function chooseAnimal(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return animals[index];

    }


    function chooseTreeWithoutRules(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return trees[index];

    }

    function chooseTree(uint256 animalId, uint256 randomNumber) private returns (uint256) {
        uint256 range = animalToTree[animalId].length;
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return animalToTree[animalId][index];

    }

    function claim(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }
}

