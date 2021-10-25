pragma solidity >=0.4.25 <0.7.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import './Tokenize.sol';

interface InitializeInterface {
    function initialize(address _owner) external;
}

contract SelfTokenizerStorage {
    using SafeMath for uint256;

    // State variables
    address payable public contractOwner; // Admin address
    uint256 public tokenId; // ID for token being created - use: mapping token to address
    uint8 public decimal;
    // address public verificationListAddress; //the uinque verificationList

    // Mappings
    mapping(uint256 => address) tokenOwner; // Token owner address mapped to token id
    mapping(uint256 => address) tokenAddress; // Token contract address mapped to token id
    mapping(uint256 => Token) tokenDetails; // Token details mapped to token id
    mapping(address => Token) tokenContract; // Token details mapped to token contract address
    mapping(address => string) ownerInfo; // A URI that takes to where all the info is stores(It would be like https://ipfs.io/ipfs/[ipfsHash])
    mapping(address => mapping(uint256 => address)) ownerTokens; // number of created tokens owned and ERC20 contract address, referenced by owner address
    mapping(address => address[]) tokenCount; // Number of token contracts owned

    // Structs
    struct Token {
        string name; // Name of token
        string symbol; // Symbol of token
        uint8 decimal;
        address payable owner; // web3 wallet address of token submitter
        uint256 supply; // Total token supply
        uint256 tokenId; // Token id number - increments on token creation
        // string tokenDesc; // Description of token project
        // string assetType; // Type of asset being tokenized
        // string assetId; // Asset ID if any (Registration number for example)
        bool holderLimit; // Is there a limit to the number of addresses allowed to hold the token
        uint256 maxHolders; // Maximum number of holders allowed (optional)
        // //      bool restrictedHolders; // Can anyone hold the tokens or is it restricted to verified investors
        // bool tokenizerVerificationList; // Should the token use Tokenizer's verification list or the owners'
        // bool ownerVerificationList; // Is the owner using their own verification list
        string tokenURI; //A URI that has the metadata of the token
    }
}

contract SelfTokenizer is SelfTokenizerStorage, Ownable {
    // initializes (works like a constructor)
    function initialize(address _owner) external {
        // contractOwner = address(0x16EDE61a09835D35e60D92AE0F11CF148cE262bF);
        tokenId = 0;
        decimal = 18;
    }

    // Events
    event TokenCreated(
        uint256 tokenId,
        string _name,
        uint256 decimal,
        string _symbol,
        uint256 _supply,
        address _owner,
        string _tokenURI
    );

    // Methods
    function tokenizeAsset(
        string memory _name,
        string memory _symbol,
        uint8 _decimal,
        address payable _tokenOwner,
        uint256 _supply,
        string memory _tokenURI,
        bool _holderLimit,
        uint256 _maxHolders
    ) public payable returns (bool) {
        //require(msg.value == creationFee);
        Token memory token = Token(
            _name,
            _symbol,
            _decimal,
            _tokenOwner,
            _supply,
            tokenId,
            _holderLimit,
            _maxHolders,
            _tokenURI
        );
        tokenDetails[token.tokenId] = token;
        //  contractOwner.transfer(msg.value);

        Tokenize tokenized = new Tokenize(
            token.name,
            token.symbol,
            token.decimal,
            token.owner,
            token.supply,
            _holderLimit,
            _maxHolders,
            token.tokenURI
        );

        tokenAddress[token.tokenId] = address(tokenized);
        tokenOwner[token.tokenId] = address(token.owner);
        tokenCount[token.owner].push(address(tokenized));
        tokenContract[address(tokenized)] = token;
        ownerTokens[token.owner][token.tokenId] = tokenAddress[token.tokenId];
        tokenId += 1;
        emit TokenCreated(
            token.tokenId,
            token.name,
            token.decimal,
            token.symbol,
            token.supply,
            token.owner,
            token.tokenURI
        );
        //return(tokenAddress[token.tokenId]);
        return (true);
    }

    // Return addresses of created token contracts by token owner address
    function getTokenAddresses(address _owner)
        public
        view
        returns (
            address[] memory // Should this also be restricted to contractOwner?
        )
    {
        return (tokenCount[_owner]);
    }

    function getTokenAddress(address _owner, uint256 _id) public view returns (address) {
        return (ownerTokens[_owner][_id]);
    }

    // Return stored Token Struct details for created token address
    function getTokenDetails(address _tokenAddress)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            address,
            string memory
        )
    {
        Token memory token = tokenContract[_tokenAddress];
        return (token.name, token.symbol, token.decimal, token.supply, token.owner, token.tokenURI);
    }

    // Update IPFS URI on stored Token Struct
    function updateIPFS(address _tokenAddress, string memory _updatedIpfsHash)
        public
        onlyOwner
        returns (string memory, string memory)
    {
        Token memory token = tokenContract[_tokenAddress];
        string memory existingURI = token.tokenURI;
        token.tokenURI = _updatedIpfsHash;
        tokenContract[_tokenAddress] = token;
        return (existingURI, token.tokenURI);
    }
}

pragma solidity >=0.4.25 <0.7.0;

// import './VerificationList.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Tokenize is ERC20, Ownable, Pausable {
    // IPFS hash of linked documents
    string public _ipfsURI;
    uint256 _totalSupply;
    uint256 public whiteListCount;
    uint256 public blackListCount;
    // Event emitted when the token IPFS URI has been updated
    event IpfsURIUpdated(address tokenAddress, string oldIpfsURI, string newIpfsURI);

    // Mapping of token addresses to vesting deadline
    mapping(address => uint256) public _lockedInvestorsList;
    // release time of transferring token - set by token owner
    uint256 public _ownerReleaseTime;
    bool public holderLimit;
    uint256 public maxHolders;
    uint256 public tokenHolders;
    bool isDelivered;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owner,
        uint256 _supply,
        bool _holderLimit,
        uint256 _maxHolders,
        string memory _ipfs
    ) public ERC20(_name, _symbol) {
        // _totalSupply = _supply.mul(10**_decimals);
        holderLimit = _holderLimit;
        maxHolders = _maxHolders;
        _setupDecimals(_decimals);
        isDelivered = false;
        // address[] ownerArray;
        // ownerArray[0] = _owner;
        // addWhiteList(ownerArray);
        _mint(_owner, _supply);
        transferOwnership(_owner);
        isDelivered = true;
        _ipfsURI = _ipfs;
    }

    /**
    @dev Transfers tokens to an allowed address with a lock in period before which tokens can then be subsequently transfered - To be used at initial allocation of tokens to investors. Subsequent transfers should use the transfer method
    @param recipient The wallet address of the investor receiving the tokens
    @param amount The amount of tokens being alloted
    @param lockPeriodInSeconds The length of time in SECONDS before which tokens cannot be transfered
   */
    function lockAndTransfer(
        address recipient,
        uint256 amount,
        uint256 lockPeriodInSeconds
    ) public onlyOwner() returns (bool) {
        require(lockPeriodInSeconds > 0, 'Lock in period is too short');
        //require(!existsInLockedList(recipient),'Address already exist');
        _lockedInvestorsList[recipient] = block.timestamp.add(lockPeriodInSeconds);
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
    @dev add list of locked address with lock in period
    @param addressesToLock list of wallet addresses that need to lock them
    @param lockPeriodInSeconds The length of time in SECONDS before which tokens cannot be transfered
    */
    function lockAddresses(address[] memory addressesToLock, uint256 lockPeriodInSeconds) public onlyOwner() {
        require(lockPeriodInSeconds > 0, 'Lock in period is too short');
        for (uint256 i = 0; i < addressesToLock.length; i++) {
            //if (!existsInLockedList(addressesToLock[i]) ) {
            _lockedInvestorsList[addressesToLock[i]] = block.timestamp.add(lockPeriodInSeconds);
            //}
        }
    }

    /**
    @dev unlock locked addresses
    @param unlocklist list of wallet addresses that need to unlock them
    */
    function unlockAddresses(address[] memory unlocklist) public onlyOwner() {
        for (uint256 i = 0; i < unlocklist.length; i++) {
            //if (!existsInLockedList(locklist[i]) ) {
            _lockedInvestorsList[unlocklist[i]] = 0;
            //}
        }
    }

    /**
    @dev add lockin period to lock transferring token for all investors by owner   
    @param lockPeriodInSeconds The length of time in SECONDS before which tokens cannot be transfered
    */
    function lockAllAddresses(uint256 lockPeriodInSeconds) public onlyOwner() {
        _ownerReleaseTime = block.timestamp.add(lockPeriodInSeconds);
    }

    /**
    @dev check the address whether he locked or not before transfer his tokens
    */
    function checkTransferAvailability() internal view {
        require(block.timestamp > _ownerReleaseTime, 'TokenTimelock: Token transfer is locked by owner');
        uint256 _releaseTime = _lockedInvestorsList[_msgSender()];

        if (_releaseTime > 0) {
            require(block.timestamp > _releaseTime, 'TokenTimelock: current time is before release time');
        }
    }

    /**
    @dev check the investor exists in the Locked list in order to avoid add it twice 
    */
    // function existsInLockedList(address element) internal view returns (bool) {
    //      uint256  _releaseTime=_lockedInvestorsList[element];
    //    if (_releaseTime>0){

    //     if (block.timestamp < _releaseTime)
    //     return true ;
    //     else{
    //      return false;
    //     }
    //    }
    //     else
    //     return false;
    // }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * @param recipient The wallet address of the investor receiving the tokens
     * @param amount The amount of tokens being sent
     */
    // function transfer(address recipient, uint256 amount) public virtual override whenNotPaused() returns (bool) {
    //     _beforeTokenTransfer(msg.sender, recipient, amount);

    //     checkTransferAvailability();
    //     _transfer(_msgSender(), recipient, amount);
    //     return true;
    // }

    /**
    * @dev See {IERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20};
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for ``sender``'s tokens of at least
    * `amount`.
  //   */
    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) public virtual override returns (bool) {
    //     _beforeTokenTransfer(msg.sender, recipient, amount);
    //     _transfer(sender, recipient, amount);
    //     _approve(
    //         sender,
    //         _msgSender(),
    //         _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    //     );
    //     return true;
    // }

    /**
     * @dev Updates the token IPFS URI
     * @param newIpfsURI The new token IPFS URI to be set
     */
    function updateIPFS(string memory newIpfsURI) public onlyOwner() {
        string memory oldIpfsURI = _ipfsURI;
        _ipfsURI = newIpfsURI;
        emit IpfsURIUpdated(address(this), oldIpfsURI, newIpfsURI);
    }

    /**
     * @dev Retrives the current IPFS URI of the token
     * @return The IPFS URI
     */
    function getIPFS() public view returns (string memory) {
        return _ipfsURI;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused and must be called by the owner.
     */
    function pause() public onlyOwner() {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused and must be called by the owner.
     */
    function unpause() public onlyOwner() {
        _unpause();
    }

    /**
     * @dev Burns a given number of tokens
     * @param amount The number of tokens to burn
     */
    function burn(uint256 amount) public onlyOwner() {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Mints a given number of tokens
     * @param amount The number of tokens to burn
     */
    function mint(uint256 amount) public onlyOwner() {
        _mint(_msgSender(), amount);
    }

    /**
    @dev List of checks before token transfers are allowed
    @param from The wallet address sending the tokens
    @param to The wallet address recieving the tokens
    @param amount The amount of tokens being transfered
   */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, 'Amount must not be 0');
        if (isDelivered) require(isWhiteListed[to], 'Recipient not allowed');
        if (_msgSender() != owner()) {
            require(!paused(), 'ERC20Pausable: token transfer while paused');
            checkTransferAvailability();
        }

        if (!(balanceOf(to) > 0)) {
            //tokenHolders.push(to);
            tokenHolders++;
        }
        if (balanceOf(from) == amount) {
            //tokenHolders.pop();
            tokenHolders--;
        }
        if (holderLimit) {
            require(tokenHolders <= maxHolders, 'MaxHolderLimit: max holder exceed');
        }
    }

    ///mapping of the addresses if it is blacklisted or not
    mapping(address => bool) public isBlackListed;

    ///mapping of the addresses if it is whitelisted or not
    mapping(address => bool) public isWhiteListed;

    /***
     * @notice Check of an address is blacklisted
     * @param _address Address to be checked if blacklisted
     * @return Whether the address passed is blacklisted or not
     */
    function getBlackListStatus(address _address) public view onlyOwner returns (bool) {
        return isBlackListed[_address];
    }

    /***
     * @notice Check of an address is whitelisted
     * @param _address Address to be checked if whitelisted
     * @return Whether the address passed is whitelisted or not
     */
    function getWhiteListStatus(address _address) public view onlyOwner returns (bool) {
        return isWhiteListed[_address];
    }

    /***
     * @notice Add an address to the blacklist
     * @param _address The address to be added to the blacklist
     */
    function addBlackList(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            require(_address[i] != address(0), 'The address is address 0');
            require(_address[i] != owner(), 'The address is the owner');
            if (!isBlackListed[_address[i]]) {
                isBlackListed[_address[i]] = true;
                blackListCount++;
                //emit AddedBlackList(_address[i]);
            }
            if (isWhiteListed[_address[i]]) {
                isWhiteListed[_address[i]] = false;
                //emit RemovedWhiteList(_address[i]);
            }
        }
    }

    /***
     * @notice Remove an address from the blacklist
     * @param _address The address to be removed from the blacklist
     */
    function removeBlackList(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            if (isBlackListed[_address[i]]) {
                isBlackListed[_address[i]] = false;
                blackListCount--;
                //emit RemovedBlackList(_address[i]);
            }
        }
    }

    /***
     * @notice Add an address to the whitelist
     * @param _address The address to be added to the whitelist
     */
    function addWhiteList(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            if (!isBlackListed[_address[i]]) {
                isWhiteListed[_address[i]] = true;
                whiteListCount++;
                //emit AddedWhiteList(_address[i]);
            }
        }
    }

    /***
     * @notice Remove an address from the whitelist
     * @param _address The address to be removed from the whitelist
     */
    function removeWhiteList(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            if (isWhiteListed[_address[i]]) {
                isWhiteListed[_address[i]] = false;
                whiteListCount--;
                emit RemovedWhiteList(_address[i]);
            }
        }
    }

    /**
     * @dev allow admin to increase the max holder count
     * @param _maxHolders the new max holder number
     */
    function changeMaxHolders(uint256 _maxHolders) public onlyOwner() {
        // require(_maxHolders > maxHolders, 'MaxHolderLimit: maxholder is not valid');
        maxHolders = _maxHolders;
    }

    /**
     * @dev allow admin to change holder limit
     * @param _holderLimit a limit to the number of addresses allowed to hold the token
     */
    function changeHolderLimit(bool _holderLimit) public onlyOwner() {
        holderLimit = _holderLimit;
    }

    // event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

    event AddedBlackList(address _address);

    event RemovedBlackList(address _address);

    event AddedWhiteList(address _address);

    event RemovedWhiteList(address _address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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