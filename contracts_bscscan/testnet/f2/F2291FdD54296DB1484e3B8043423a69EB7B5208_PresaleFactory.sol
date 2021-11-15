// Hi. If you have any questions or comments in this smart contract please let me know at:
// Whatsapp +923014440289, Telegram @thinkmuneeb, discord: timon#1213, I'm Muneeb Zubair Khan
//
//
// Smart Contract belong to this DAPP: https://shield-launchpad.netlify.app/ Made in Pakistan by Muneeb Zubair Khan
// The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash.
// Project done in collaboration with TrippyBlue and ShieldNet Team.
//
//
// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.7;
import "./Presale.sol";

contract PresaleFactory is Ownable {
    ////////////////////////////////////////////////////////////////
    //                      VARIABLES                             //
    ////////////////////////////////////////////////////////////////

    // Users need to hold some amount of tokens of parent company to buy tokens from the different presales
    IERC20 tokenToHold;
    uint256 amountTokenToHold;

    // list of presales created from this factory
    mapping(uint256 => Presale) public presales;

    // last presale created from this factory
    uint256 public lastPresaleIndex;

    // busd address
    IERC20 public busd;

    /// @notice people can see if a presale created from this factory or not
    mapping(address => bool) public belongsToThisFactory;

    // this function is called when contract is created
    constructor(
        address _parentCompany,
        IERC20 _busd,
        IERC20 _tokenToHold,
        uint256 _amountTokenToHold
    ) {
        busd = _busd;
        tokenToHold = _tokenToHold;
        amountTokenToHold = _amountTokenToHold;
        transferOwnership(_parentCompany);
    }

    // this is used to pass arguments to the function. createERC20Presale
    struct Box {
        IERC20 tokenX;
        IERC20 lpTokenX;
        //
        uint256 rate;
        uint256 softcap;
        uint256 hardcap;
        uint256 presaleOpenAt;
        uint256 presaleCloseAt;
        uint256 unlockTokensAt;
        //
        uint256 tokenXToLock;
        uint256 lpTokenXToLock;
        //
        bool onlyWhitelistedAllowed;
        address[] whitelistAddresses;
        string presaleMediaLinks;
    }

    ////////////////////////////////////////////////////////////////
    //                  WRITE CONTRACT                            //
    ////////////////////////////////////////////////////////////////

    /// @notice users can create an ICO for erc20 from this function
    /// @dev we used struct Box because solidity gives error of deep stack if we not use it
    function createERC20Presale(Box memory __) external {
        Presale presale = new Presale(
            Presale.Box(
                __.tokenX,
                __.lpTokenX,
                //
                tokenToHold,
                busd,
                msg.sender, // the person who is creating this presale is the owner of this presale
                //
                __.rate,
                __.softcap,
                __.hardcap,
                //
                amountTokenToHold,
                //
                __.presaleOpenAt,
                __.presaleCloseAt,
                //
                __.unlockTokensAt,
                __.onlyWhitelistedAllowed,
                __.whitelistAddresses,
                __.presaleMediaLinks
            )
        );

        // set that this presale belongs to this factory
        belongsToThisFactory[address(presale)] = true;

        // add presale to the presales list
        presales[lastPresaleIndex++] = presale;

        __.tokenX.transferFrom(msg.sender, address(presale), __.hardcap);
        __.tokenX.transferFrom(
            msg.sender,
            address(presale.tokenXLocker()),
            __.tokenXToLock
        );
        __.lpTokenX.transferFrom(
            msg.sender,
            address(presale.lpTokenXLocker()),
            __.lpTokenXToLock
        );
    }

    function onlyOwner_editTokenToHold(IERC20 _tokenToHold) external onlyOwner {
        tokenToHold = _tokenToHold;
    }

    function onlyOwner_editAmountTokenToHold(uint256 _amountTokenToHold)
        external
        onlyOwner
    {
        amountTokenToHold = _amountTokenToHold;
    }

    ////////////////////////////////////////////////////////////////
    //                  READ CONTRACT                             //
    ////////////////////////////////////////////////////////////////

    // These following functions are for getting data via multicall.
    function getPresales(uint256 _index, uint256 _amountToFetch)
        external
        view
        returns (Presale[] memory, IERC20[] memory)
    {
        uint256 selectedCount = 0;
        uint256 currIndex = _index;
        Presale[] memory tempPresales = new Presale[](_amountToFetch);
        for (uint256 i = 0; i < _amountToFetch; i++) {
            if (address(presales[currIndex]) != address(0)) {
                tempPresales[i] = presales[currIndex++];
                selectedCount++;
            } else {
                tempPresales[i] = Presale(address(0));
            }
        }

        return getSelectedItems(tempPresales, selectedCount);
    }

    function getPresaleDetails(address _presale)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        return Presale(_presale).getPresaleDetails();
    }

    function getTokenName(address _token)
        external
        view
        returns (string memory name)
    {
        return IName(_token).name();
    }

    function getTokenSymbol(address _token)
        external
        view
        returns (string memory symbol)
    {
        return ISymbol(_token).symbol();
    }

    function getPresaleMediaLinks(Presale _presale)
        external
        view
        returns (string memory symbol)
    {
        return _presale.presaleMediaLinks();
    }

    function AAA_developers() external pure returns (string memory) {
        return
            "Smart Contract belong to this DAPP: https://shield-launchpad.netlify.app/ Smart contract made in Pakistan by Muneeb Zubair Khan, Whatsapp +923014440289, Telegram @thinkmuneeb, The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash. Discord timon#1213. Project done with TrippyBlue and ShieldNet Team.";
    }

    ////////////////////////////////////////////////////////////////
    //                  HELPER FUNCTIONS                          //
    ////////////////////////////////////////////////////////////////

    // gets a list of addresses which have some 0x0 addresses and some other addresses.
    // it filters addresses, and returns only those addresses which are not 0x0.
    // returns presales address and their corresponding token addresses
    // token addresses needed to get token name in multicall
    function getSelectedItems(
        Presale[] memory tempPresales, // search results temp presales list
        uint256 selectedCount
    ) private view returns (Presale[] memory, IERC20[] memory) {
        uint256 someI = 0;
        Presale[] memory selectedPresales = new Presale[](selectedCount);
        IERC20[] memory selectedPresalesTokens = new IERC20[](selectedCount);

        // traverse in tempPresales addresses to get only addresses that are not 0x0
        for (uint256 i = 0; i < tempPresales.length; i++) {
            if (address(tempPresales[i]) != address(0)) {
                selectedPresales[someI] = tempPresales[i];
                selectedPresalesTokens[someI++] = tempPresales[i].tokenX();
            }
        }

        return (selectedPresales, selectedPresalesTokens);
    }
}

interface IName {
    function name() external view returns (string memory);
}

interface ISymbol {
    function symbol() external view returns (string memory);
}

// Hi. If you have any questions or comments in this smart contract please let me know at:
// Whatsapp +923014440289, Telegram @thinkmuneeb, discord: timon#1213, I'm Muneeb Zubair Khan
//
//
// Smart Contract belong to this DAPP: https://shield-launchpad.netlify.app/ Made in Pakistan by Muneeb Zubair Khan
// The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash.
// Project done in collaboration with TrippyBlue and ShieldNet Team.
//
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Locker.sol";

contract Presale is Ownable {
    ////////////////////////////////////////////////////////////////
    //                      VARIABLES                             //
    ////////////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;

    IERC20 public busd; // People will give BUSD or buyingToken and get tokenX in return
    IERC20 public tokenX; // People will buy tokenX by giving their BUSD
    IERC20 public lpTokenX; // Owner of tokenX will lock lpTokenX to get their confidence
    IERC20 public tokenToHold; // People hold this token to buy token X
    Locker public tokenXLocker; //
    Locker public lpTokenXLocker;

    uint256 public softcap;
    uint256 public hardcap;

    uint256 public rate; // rate = 3 = 3 000 000 000 000 000 000, 0.3 = 3 00 000 000 000 000 000 // 0.3 busd = 1 TokenX
    uint256 public tokenXSold;
    uint256 public amountTokenToHold;

    uint256 public presaleOpenAt;
    uint256 public presaleCloseAt;

    uint256 public participantsCount = 0;

    mapping(address => bool) private isParticipant;

    mapping(address => bool) public isWhitelisted;

    // Bookkeeping like bank account
    mapping(address => uint256) public tokenXSoldBy;
    mapping(address => uint256) public tokenXBoughtBy;

    /// @notice The more trustworthy presale is the more presaleScore its has. presaleScore is assigned by the parent network only.
    uint8 public presaleScore = 1;

    address public factory;
    string public presaleMediaLinks; // tokenX owner will give his social media, photo, driving liscense images links.

    bool public presaleIsApproved;
    bool public presaleIsBlacklisted;
    bool public presaleIsCancelled;
    bool public onlyWhitelistedAllowed;

    event PresaleApproved(uint8 _presaleScore);
    event UnlockedUnsoldTokens(uint256 _tokens);
    event AmountTokenToHoldChanged(uint256 _amountTokenToHold);

    struct Box {
        IERC20 tokenX;
        IERC20 lpTokenX;
        IERC20 tokenToHold;
        IERC20 busd;
        //
        address presaleOwner;
        //
        uint256 rate;
        uint256 softcap;
        uint256 hardcap;
        uint256 amountTokenToHold;
        uint256 presaleOpenAt;
        uint256 presaleCloseAt;
        uint256 unlockTokensAt;
        //
        bool onlyWhitelistedAllowed;
        address[] whitelistAddresses;
        string presaleMediaLinks;
    }

    constructor(Box memory __) {
        require(
            __.presaleOpenAt + 90 days <= __.presaleCloseAt,
            "Presale close time should be more than or equal to 90 days after the start time"
        );
        require(__.softcap < __.hardcap, "Hardcap should be more than softcap");

        tokenX = __.tokenX;
        lpTokenX = __.lpTokenX;
        tokenToHold = __.tokenToHold;
        busd = __.busd;
        factory = msg.sender; // only trust those presales who address exist in factory contract // go to factory address and see presale address belong to that factory or not. use method: belongsToThisFactory

        softcap = __.softcap;
        hardcap = __.hardcap;
        rate = __.rate;
        presaleOpenAt = __.presaleOpenAt;
        presaleCloseAt = __.presaleCloseAt;
        amountTokenToHold = __.amountTokenToHold;

        onlyWhitelistedAllowed = __.onlyWhitelistedAllowed;

        presaleMediaLinks = __.presaleMediaLinks;

        if (__.onlyWhitelistedAllowed) {
            for (uint256 i = 0; i < __.whitelistAddresses.length; i++) {
                isWhitelisted[__.whitelistAddresses[i]] = true;
            }
        }

        tokenXLocker = new Locker(
            __.tokenX,
            __.presaleOwner,
            __.unlockTokensAt
        );

        lpTokenXLocker = new Locker(
            __.lpTokenX,
            __.presaleOwner,
            __.unlockTokensAt
        );

        transferOwnership(__.presaleOwner);
    }

    ////////////////////////////////////////////////////////////////
    //                  WRITE CONTRACT                            //
    ////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////
    //                FUNCTIONS FOR PUBLIC                        //
    ////////////////////////////////////////////////////////////////

    /// @notice user buys at rate of 0.3 then 33 BUSD will be deducted and 100 tokenX will be given
    function buyTokens(uint256 _tokens)
        external
        presaleOpen
        userIsAllowed
        presaleApproved
        presaleNotCancelled
        presaleNotBlacklisted
        userHasAmountTokenToHold
    {
        buyTokensBookkeeping(_tokens);

        uint256 price = (_tokens * rate) / 1e18;
        busd.transferFrom(msg.sender, address(this), price);
        tokenX.transfer(msg.sender, _tokens);
    }

    // user can only sell tokens from the wallet where they purchased.
    // we need to prevent token owner taking out funds by giving tokenX and getting BUSD
    function sellTokens(uint256 _tokens)
        external
        presaleCancelledOrPresaleEndedAndSoftcapNotReached
    {
        tokenXSoldBy[msg.sender] += _tokens;

        require(
            tokenXBoughtBy[msg.sender] >= tokenXSoldBy[msg.sender],
            "You have to sell tokens less or equal amount than you bought"
        );

        uint256 price = (_tokens * rate) / 1e18;
        busd.transfer(msg.sender, price);
        tokenX.transferFrom(msg.sender, address(this), _tokens);
    }

    ////////////////////////////////////////////////////////////////
    //                 ONLY OWNER FUNCTIONS                       //
    ////////////////////////////////////////////////////////////////

    function onlyOwner_withdrawBUSD()
        external
        onlyOwner
        presaleNotCancelled
        hardcapReachedOrPresaleEndedAndSoftcapReached
    {
        uint256 contractBalance = tokenX.balanceOf(address(this));
        tokenX.transfer(msg.sender, contractBalance);
    }

    function onlyOwner_unlockUnsoldTokens()
        external
        onlyOwner
        presaleCancelledOrPresaleEnded
    {
        uint256 contractBalance = tokenX.balanceOf(address(this));
        tokenX.transfer(msg.sender, contractBalance);
        emit UnlockedUnsoldTokens(contractBalance);
    }

    function onlyOwner_cancelPresale() external onlyOwner {
        require(!presaleIsCancelled, "Presale already cancelled");
        require(!hardcapReached(), "Hardcap reached, can not cancell now");
        presaleIsCancelled = true;
    }

    function onlyOwner_setAmountTokenToHold(uint256 _amountTokenToHold)
        external
        onlyOwner
    {
        amountTokenToHold = _amountTokenToHold;
        emit AmountTokenToHoldChanged(_amountTokenToHold);
    }

    function onlyOwner_editOnlyWhitelistedAllowed(bool _onlyWhitelistedAllowed)
        external
        onlyOwner
    {
        onlyWhitelistedAllowed = _onlyWhitelistedAllowed;
    }

    /// @dev pass true to add to whitelist, pass false to remove from whitelist
    function onlyOwner_editWhitelist(address[] memory _addresses, bool _approve)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = _approve;
        }
    }

    ////////////////////////////////////////////////////////////////
    //            ONLY PARENT COMPANY FUNCTIONS                   //
    ////////////////////////////////////////////////////////////////

    modifier onlyParent() {
        require(
            msg.sender == parentCompany(),
            "You must be parent company to edit value"
        );
        _;
    }

    /// @notice Parent network will approve presale and assign a score to presale based on their photo, social media, driving liscense
    function onlyParent_editPresaleIsApproved(
        bool _presaleIsApproved,
        uint8 _presaleScore
    ) external onlyParent {
        presaleIsApproved = _presaleIsApproved;
        presaleScore = _presaleScore;
        emit PresaleApproved(_presaleScore);
    }

    /// @notice Parent network will assign a score to presale based on their photo, social media, driving liscense
    function onlyParent_editPresaleScore(uint8 _presaleScore)
        external
        onlyParent
    {
        presaleScore = _presaleScore;
    }

    function onlyParent_editPresaleIsBlacklisted(bool _presaleIsBlacklisted)
        external
        onlyParent
    {
        presaleIsBlacklisted = _presaleIsBlacklisted;
    }

    ////////////////////////////////////////////////////////////////
    //                  READ CONTRACT                             //
    ////////////////////////////////////////////////////////////////

    function getPresaleDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        address[] memory addresses = new address[](4);
        addresses[0] = address(tokenX);
        addresses[1] = address(lpTokenX);
        addresses[2] = address(tokenXLocker);
        addresses[3] = address(lpTokenXLocker);

        uint256[] memory uints = new uint256[](13);
        uints[0] = tokenX.totalSupply();
        uints[1] = tokenX.balanceOf(address(this));
        uints[2] = tokenXLocker.balance();
        uints[3] = tokenXLocker.unlockTokensAtTime();
        uints[4] = lpTokenX.balanceOf(address(this));
        uints[5] = lpTokenXLocker.balance();
        uints[6] = lpTokenXLocker.unlockTokensAtTime();
        uints[7] = tokenXSold;
        uints[8] = rate;
        uints[9] = amountTokenToHold;
        uints[10] = presaleOpenAt;
        uints[11] = presaleCloseAt;
        uints[12] = presaleScore;

        bool[] memory bools = new bool[](6);
        bools[0] = presaleIsBlacklisted;
        bools[1] = presaleIsApproved;

        bools[2] = tokenXLocker.unlockTokensRequestMade();
        bools[3] = tokenXLocker.unlockTokensRequestAccepted();
        bools[4] = lpTokenXLocker.unlockTokensRequestMade();
        bools[5] = lpTokenXLocker.unlockTokensRequestAccepted();

        return (addresses, uints, bools);
    }

    function parentCompany() public view returns (address) {
        return Ownable(factory).owner();
    }

    function AAA_developers() external pure returns (string memory) {
        return
            "Smart Contract belong to this DAPP: https://shield-launchpad.netlify.app/ Smart contract made in Pakistan by Muneeb Zubair Khan, Whatsapp +923014440289, Telegram @thinkmuneeb, The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash. Discord timon#1213. Project done with TrippyBlue and ShieldNet Team.";
    }

    // helper functions

    function hardcapReached() public view returns (bool) {
        return tokenXSold >= hardcap;
    }

    function softcapReached() public view returns (bool) {
        return tokenXSold >= softcap;
    }

    function presaleEnded() public view returns (bool) {
        return block.timestamp > presaleCloseAt;
    }

    function presaleEndedAndSoftcapReached() public view returns (bool) {
        return presaleEnded() && softcapReached();
    }

    function presaleEndedAndSoftcapNotReached() public view returns (bool) {
        return presaleEnded() && !softcapReached();
    }

    // helper modifiers

    modifier presaleNotCancelled() {
        require(!presaleIsCancelled, "Presale should not be cancelled.");
        _;
    }

    modifier hardcapReachedOrPresaleEndedAndSoftcapReached() {
        require(
            hardcapReached() || presaleEndedAndSoftcapReached(),
            "Hardcap should reach or presale ends with softcap reach."
        );
        _;
    }

    modifier presaleOpen() {
        require(block.timestamp > presaleOpenAt, "Presale is not opened yet.");
        require(block.timestamp < presaleCloseAt, "Presale is closed.");
        _;
    }

    modifier presaleNotBlacklisted() {
        require(
            !presaleIsBlacklisted,
            "Presale is blacklisted by the parent network."
        );
        _;
    }

    modifier presaleApproved() {
        require(
            presaleIsApproved,
            "Presale is not approved by the parent network."
        );
        _;
    }

    modifier userHasAmountTokenToHold() {
        // need to code these require statements in UI, so users do not get exceptions on metamask wallet
        require(
            tokenToHold.balanceOf(msg.sender) >= amountTokenToHold,
            "You need to hold tokens to buy from presale."
        );
        _;
    }

    modifier userIsAllowed() {
        if (onlyWhitelistedAllowed) {
            require(
                isWhitelisted[msg.sender],
                "You should become whitelisted to continue."
            );
        }
        _;
    }

    modifier presaleCancelledOrPresaleEndedAndSoftcapNotReached() {
        require(
            presaleIsCancelled || presaleEndedAndSoftcapNotReached(),
            "Presale should be cancelled or Presale should be ended and softcap should not met"
        );
        _;
    }

    modifier presaleCancelledOrPresaleEnded() {
        require(
            presaleIsCancelled || presaleEnded(),
            "Presale should be cancelled or ended"
        );
        _;
    }

    // helper function private
    function buyTokensBookkeeping(uint256 _tokens) private {
        // count tokenXSold
        tokenXSold += _tokens;

        // count tokenXBoughtBy each address, so we can return BUSD if they want
        tokenXBoughtBy[msg.sender] += _tokens;

        // count participants
        if (!isParticipant[msg.sender]) {
            isParticipant[msg.sender] = true;
            participantsCount++;
        }
    }
}

// Hi. If you have any questions or comments in this smart contract please let me know at:
// Whatsapp +923014440289, Telegram @thinkmuneeb, discord: timon#1213, I'm Muneeb Zubair Khan
//
//
// Smart Contract belong to this DAPP: https://shield-launchpad.netlify.app/ Made in Pakistan by Muneeb Zubair Khan
// The UI is made by Abraham Peter, Whatsapp +923004702553, Telegram @Abrahampeterhash.
// Project done in collaboration with TrippyBlue and ShieldNet Team.
//
//
// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// functions: lockTokens, unlockTokens...
contract Locker is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public tokenX;
    address public walletOwner;
    address public factory;

    uint256 public unlockTokensAtTime;
    bool public unlockTokensRequestMade = false;
    bool public unlockTokensRequestAccepted = false;

    event UnlockTokensRequestMade(IERC20 _token, uint256 _amount);
    event UnlockedTokens(IERC20 _token, uint256 _amount);

    constructor(
        IERC20 _tokenX,
        address _walletOwner,
            uint256 _unlockTokensAtTime
    ) {
        tokenX = _tokenX;
        walletOwner = _walletOwner;
        unlockTokensAtTime = _unlockTokensAtTime;
        transferOwnership(_walletOwner);
    }

    function lockTokens(uint256 _amount) external onlyOwner {
        tokenX.transferFrom(owner(), address(this), _amount);
    }

    function makeUnlockTokensRequest() external onlyOwner {
        unlockTokensRequestMade = true;
        emit UnlockTokensRequestMade(tokenX, tokenX.balanceOf(address(this)));
    }

    function approveUnlockTokensRequest() external onlyOwner {
        require(
            unlockTokensRequestMade,
            "Locker Owner has to make request to unlock tokens."
        );
        require(
            msg.sender == Ownable(factory).owner(),
            "You must be owner of presale factory to approve unlock tokens."
        );
        require(
            block.timestamp > unlockTokensAtTime,
            "Tokens will be unlocked soon."
        );

        unlockTokensRequestAccepted = true;

        tokenX.transfer(owner(), tokenX.balanceOf(address(this)));
        emit UnlockedTokens(tokenX, tokenX.balanceOf(address(this)));
    }

    function balance() public view returns (uint256) {
        return tokenX.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

