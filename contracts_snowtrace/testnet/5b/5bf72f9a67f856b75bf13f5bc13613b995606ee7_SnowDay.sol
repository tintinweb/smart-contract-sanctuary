/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-10
*/

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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// amount of tokens in presale contract
// amount of tokens and amount of avax going to liquidity pool
// amount of tokens and amount of avax for marketing whatever expenses
contract SnowDay is Ownable {
// 20% of seed is released on launch, which is 5x than whitelist allocation

    address public MIM;
    uint public endBlock;
    uint public maxWlContribution;
    uint public maxPublicContribution;
    bool public presalePublic;
    uint public seedContribution;
    uint public whitelistsQ;
 
    event Whitelisted(address[] whitelisted);
    event SeedAdded(address[] seedAdded);
    event PublicSaleStarted();
    event PresaleEnded();

    mapping(address => bool) public whitelisted;
    mapping(address => uint) public deposits;
    mapping(address => bool) public seed;
    mapping(address => uint) public seedDeposits;

    modifier onlyWhitelisted(){
        require(whitelisted[msg.sender]==true);
        _;
    }

    modifier onlySeed(){
        require(seed[msg.sender]==true);
        _;
    }

    constructor(){
        endBlock = block.number+43400;// 24 hours presale, just in case can be adjusted by a function below
        maxWlContribution = 1000e18;
        maxPublicContribution = 500e18;
        MIM = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;//testnet wavax for now
        seedContribution = 5000e18;
    }

    function depositWhitelist(uint amount) external onlyWhitelisted {
        require(block.number<endBlock,"presale has ended");
        require(amount+deposits[msg.sender]<=maxWlContribution,"exceeds max contribution");
        require(IERC20(MIM).balanceOf(msg.sender)>=amount,"not enough tokens");
        require(whitelisted[msg.sender]==true,"not whitelisted");
        require(seedDeposits[msg.sender]==0,"already seed");
        IERC20(MIM).transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender]+=amount;
    }


    function depositPublic(uint amount) public {
        require(presalePublic==true&&block.number<=endBlock,"presale has ended");
        require(amount+deposits[msg.sender]<=maxPublicContribution,"exceeds max contribution");
        require(seedDeposits[msg.sender]==0,"already seed");
        require(IERC20(MIM).balanceOf(msg.sender)>=amount,"not enough tokens");
        IERC20(MIM).transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender]+=amount;
    }

    function addToWhitelist(address[] memory addresses) external onlyOwner returns(uint quantityOfAddedAddresses){
        uint quantity = 0;
        for(uint i=0;i<addresses.length;i++){
            if(!whitelisted[addresses[i]]) {
                whitelisted[addresses[i]]=true;
                quantity++;
            }
        }
        emit Whitelisted(addresses);
        whitelistsQ+=quantity;
        return quantity;
    }

    function withdrawForLiquidity() external onlyOwner {
        require(block.number>endBlock);
        if(IERC20(MIM).balanceOf(address(this))>0){
            IERC20(MIM).transfer(msg.sender, IERC20(MIM).balanceOf(address(this)));    
        }
        if(address(this).balance>0){
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function setEndBlock(uint endBlock_) external onlyOwner {
        endBlock = endBlock_;
    }

    function startPublicSale() external onlyOwner {// not necessary, just an option
        presalePublic = true;
        emit PublicSaleStarted();
    }

    function depositSeed() external onlySeed {// so there is a fixed amount of SNOW in seed presale
        require(block.number<endBlock,"presale has ended");
        require(seedDeposits[msg.sender]==0,"already contributed");
        require(deposits[msg.sender]==0,"already contributed");
        require(IERC20(MIM).balanceOf(msg.sender)>=seedContribution,"not enough tokens");
        IERC20(MIM).transferFrom(msg.sender, address(this), seedContribution);
        seedDeposits[msg.sender]=seedContribution;
    }

    function addToSeed(address[] memory addresses) external onlyOwner {
        for(uint i=0;i<addresses.length;i++){
            seed[addresses[i]]=true;
        }
        emit SeedAdded(addresses);
    }
}