// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

// import "@unification-com/xfund-router/contracts/lib/ConsumerBase.sol";
// import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_Ex {
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

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
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
library OOOSafeMath {
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
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function saveDiv(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IConsumerBase {
    function rawReceiveData(uint256 _price, bytes32 _requestId) external;
}

/**
 * @title RequestIdBase
 *
 * @dev A contract used by ConsumerBase and Router to generate requestIds
 *
 */
contract RequestIdBase {

    /**
    * @dev makeRequestId generates a requestId
    *
    * @param _dataConsumer address of consumer contract
    * @param _dataProvider address of provider
    * @param _router address of Router contract
    * @param _requestNonce uint256 request nonce
    * @param _data bytes32 hex encoded data endpoint
    *
    * @return bytes32 requestId
    */
    function makeRequestId(
        address _dataConsumer,
        address _dataProvider,
        address _router,
        uint256 _requestNonce,
        bytes32 _data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_dataConsumer, _dataProvider, _router, _requestNonce, _data));
    }
}

/**
 * @title ConsumerBase smart contract
 *
 * @dev This contract can be imported by any smart contract wishing to include
 * off-chain data or data from a different network within it.
 *
 * The consumer initiates a data request by forwarding the request to the Router
 * smart contract, from where the data provider(s) pick up and process the
 * data request, and forward it back to the specified callback function.
 *
 */
abstract contract ConsumerBase is RequestIdBase {
    using OOOSafeMath for uint256;

    /*
     * STATE VARIABLES
     */

    // nonces for generating requestIds. Must be in sync with the
    // nonces defined in Router.sol.
    mapping(address => uint256) private nonces;

    IERC20_Ex internal immutable xFUND;
    IRouter internal router;

    /*
     * WRITE FUNCTIONS
     */

    /**
     * @dev Contract constructor. Accepts the address for the router smart contract,
     * and a token allowance for the Router to spend on the consumer's behalf (to pay fees).
     *
     * The Consumer contract should have enough tokens allocated to it to pay fees
     * and the Router should be able to use the Tokens to forward fees.
     *
     * @param _router address of the deployed Router smart contract
     * @param _xfund address of the deployed xFUND smart contract
     */
    constructor(address _router, address _xfund) {
        require(_router != address(0), "router cannot be the zero address");
        require(_xfund != address(0), "xfund cannot be the zero address");
        router = IRouter(_router);
        xFUND = IERC20_Ex(_xfund);
    }

    /**
     * @notice _setRouter is a helper function to allow changing the router contract address
     * Allows updating the router address. Future proofing for potential Router upgrades
     * NOTE: it is advisable to wrap this around a function that uses, for example, OpenZeppelin's
     * onlyOwner modifier
     *
     * @param _router address of the deployed Router smart contract
     */
    function _setRouter(address _router) internal returns (bool) {
        require(_router != address(0), "router cannot be the zero address");
        router = IRouter(_router);
        return true;
    }

    /**
     * @notice _increaseRouterAllowance is a helper function to increase token allowance for
     * the xFUND Router
     * Allows this contract to increase the xFUND allowance for the Router contract
     * enabling it to pay request fees on behalf of this contract.
     * NOTE: it is advisable to wrap this around a function that uses, for example, OpenZeppelin's
     * onlyOwner modifier
     *
     * @param _amount uint256 amount to increase allowance by
     */
    function _increaseRouterAllowance(uint256 _amount) internal returns (bool) {
        // The context of msg.sender is this contract's address
        require(xFUND.increaseAllowance(address(router), _amount), "failed to increase allowance");
        return true;
    }

    /**
     * @dev _requestData - initialises a data request. forwards the request to the deployed
     * Router smart contract.
     *
     * @param _dataProvider payable address of the data provider
     * @param _fee uint256 fee to be paid
     * @param _data bytes32 value of data being requested, e.g. PRICE.BTC.USD.AVG requests
     * average price for BTC/USD pair
     * @return requestId bytes32 request ID which can be used to track or cancel the request
     */
    function _requestData(address _dataProvider, uint256 _fee, bytes32 _data)
    internal returns (bytes32) {
        bytes32 requestId = makeRequestId(address(this), _dataProvider, address(router), nonces[_dataProvider], _data);
        // call the underlying ConsumerLib.sol lib's submitDataRequest function
        require(router.initialiseRequest(_dataProvider, _fee, _data));
        nonces[_dataProvider] = nonces[_dataProvider].safeAdd(1);
        return requestId;
    }

    /**
     * @dev rawReceiveData - Called by the Router's fulfillRequest function
     * in order to fulfil a data request. Data providers call the Router's fulfillRequest function
     * The request is validated to ensure it has indeed been sent via the Router.
     *
     * The Router will only call rawReceiveData once it has validated the origin of the data fulfillment.
     * rawReceiveData then calls the user defined receiveData function to finalise the fulfilment.
     * Contract developers will need to override the abstract receiveData function defined below.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     * has sent the data
     */
    function rawReceiveData(
        uint256 _price,
        bytes32 _requestId) external
    {
        // validate it came from the router
        require(msg.sender == address(router), "only Router can call");

        // call override function in end-user's contract
        receiveData(_price, _requestId);
    }

    /**
    * @dev receiveData - should be overridden by contract developers to process the
    * data fulfilment in their own contract.
    *
    * @param _price uint256 result being sent
    * @param _requestId bytes32 request ID of the request being fulfilled
    */
    function receiveData(
        uint256 _price,
        bytes32 _requestId
    ) internal virtual;

    /*
     * READ FUNCTIONS
     */

    /**
     * @dev getRouterAddress returns the address of the Router smart contract being used
     *
     * @return address
     */
    function getRouterAddress() external view returns (address) {
        return address(router);
    }

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


interface IRouter {
    function initialiseRequest(address, uint256, bytes32) external returns (bool);
}

contract MyDataConsumerForShib is ConsumerBase, Ownable {
    uint256 public price;
    address NFTAddress;

    event GotSomeData(bytes32 requestId, uint256 price);

     // RinkeBy 
    // address private ROUTER_ADDRESS = address(0x05AB63BeC9CfC3897a20dE62f5f812de10301FDf);

    // RinkeBy
    // address private XFUND_ADDRESS = address(0x245330351344F9301690D5D8De2A07f5F32e1149);

    // Mainnet 
    // address private constant ROUTER_ADDRESS = address(0x9ac9AE20a17779c17b069b48A8788e3455fC6121);

    // // Mainnet
    // address private constant XFUND_ADDRESS = address(0x892A6f9dF0147e5f079b0993F486F9acA3c87881);

    modifier onlyNFTOrOwner() {
        require(msg.sender == NFTAddress || msg.sender == owner(), "Price Can only be fetched by NFT contract or the Owner");
        _;
    }

    constructor(address router, address xfund) ConsumerBase(router, xfund) {
        price = 0;
    }

    // Optionally protect with a modifier to limit who can call
    function getData(address PROVIDER_ADDRESS, uint256 _fee, bytes32 _data) external onlyNFTOrOwner returns (bytes32) {

        // bytes32 _data = 0x555344542e534849422e50522e41564300000000000000000000000000000000;  //USDT.SHIB.PR.AVC
    
        // uint256 _fee = 100000000;

        // Rinkeby 
        // address PROVIDER_ADDRESS = address(0x611661f4B5D82079E924AcE2A6D113fAbd214b14);

        // Mainnet 
        // address PROVIDER_ADDRESS = address(0xFDEc0386011d085A6b4F0e37Fab5d7f2601aCB33);

        // _provider = PROVIDER_ADDRESS
        return _requestData(PROVIDER_ADDRESS, _fee, _data);
    }

    // Todo - protect with a modifier to limit who can call!
    function increaseRouterAllowance(uint256 _amount) external onlyOwner {
        require(_increaseRouterAllowance(_amount));       // 115792089237316195423570985008687907853269984665640564039457584007913129639935
    }

    // ConsumerBase ensures only the Router can call this
    function receiveData(uint256 _price, bytes32 _requestId) internal override {
        price = _price;
        // optionally emit an event to the logs
        emit GotSomeData(_requestId, _price);
    }

    function setNFTContract(address _nftAddress) external onlyOwner {
        NFTAddress = _nftAddress;        
    }
}