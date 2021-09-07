// SPDX-License-Identifier: UNLICENSE
// Rzucam worki w tłum w tłum .. kto łapie ten jara ... XD

/**
Apes Together Strong!

About BigShortBets DeFi project:

We are creating a social&trading p2p platform that guarantees encrypted interaction between investors.
Logging in is possible via a cryptocurrency wallet (e.g. Metamask).
The security level is one comparable to the Tor network.

https://bigsb.io/ - Our Tool
https://bigshortbets.com - Project&Team info

Video explainer:
https://youtu.be/wbhUo5IvKdk

Zaorski, You Son of a bitch I’m in …
*/

pragma solidity 0.8.7;
import "./interfaces.sol";
import "./owned.sol";

/**
BigShortBets.com BigSB token claiming contract
Contract need tokens on its address to send them to owners

*/
contract ClaimBigSB is Owned {
    // presale contracts
    address public immutable presale1;
    address public immutable presale2;
    address public immutable sale;

    // BigSB token contract
    address public immutable token;

    // 1-year claiming window after which Owner can sweep remaining tokens
    uint256 public immutable claimDateLimit;

    // claiming process need to be enabled
    bool public claimStarted;

    // Presale2 is bugged in handling multiple ETH deposits
    // we need handle that
    mapping(address => uint256) internal buggedTokens;

    // mark users that already claim tokens
    mapping(address => bool) public isClaimed;

    // handle ETH/tokens send from exchanges
    mapping(address => address) internal _morty;

    // AML-ed users address->tokens
    mapping(address => uint256) internal _aml;

    // events
    event TokensClaimed(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    // useful constant
    address internal constant ZERO = address(0x0);

    uint256 internal immutable startRate;

    /**
    @dev contract constructor
    @param _presale1 address of presale1 contract
    @param _presale2 address of presale2 contract
    @param _sale address of final sale contract
    @param _token address of BigSB token contract
     */
    constructor(
        address _presale1,
        address _presale2,
        address _sale,
        address _token
    ) {
        presale1 = _presale1;
        presale2 = _presale2;
        sale = _sale;
        token = _token;
        claimDateLimit = block.timestamp + 365 days; //max 1 year to take tokens
        startRate = IReflect(_token).getRate();
    }

    // count tokens from all pre/sale contracts
    function _allTokens(address user) internal view returns (uint256) {
        // presale2 need manual handle because of "multiple ETH send" error
        // "tokensBoughtOf" is also flawed, so we do all math there
        uint256 amt = buggedTokens[user];
        if (amt == 0) {
            // calculate tokens at sale price $2630/ETH, $0.95/token
            // function is returning ETH value in wei
            amt = (IPresale2(presale2).ethDepositOf(user) * 2630 * 100) / 95;
            // calculate tokens for USD at $0.95/token
            // contract is returning USD with 0 decimals
            amt += (IPresale2(presale2).usdDepositOf(user) * 100 ether) / 95;
        }

        // presale1 reader is returning ETH amount in wei, $0.65 / token, $1530/ETH
        // yes, there is a typo in function name
        amt += (IPresale1(presale1).blanceOf(user) * 1530 * 100) / 65;

        // sale returning tokens, $1/token, ETH price from oracle at buy time
        amt += ISale(sale).tokensBoughtOf(user);

        return amt;
    }

    /**
    Reader that can check how many tokens can be claimed by given address
    @param user address to check
    @return number of tokens (18 decimals)
    */
    function canClaim(address user) external view returns (uint256) {
        return _recalculate(_allTokens(user));
    }

    // recalculate amount of tokens via start rate
    function _recalculate(uint256 tokens) internal view returns (uint256) {
        uint256 rate = IReflect(token).getRate();
        return (tokens * rate) / startRate;
    }

    /**
    @dev claim BigSB tokens bought on any pre/sale
     */
    function claim() external {
        require(_morty[msg.sender] == ZERO, "Use claimFrom");
        _claim(msg.sender, msg.sender);
    }

    /// Claim tokens from AMLed list
    function claimAML() external {
        uint256 amt = _aml[msg.sender];
        require(amt > 0, "Not on AML list");
        _aml[msg.sender] = 0;
        amt = _recalculate(amt);
        IERC20(token).transfer(msg.sender, amt);
        emit TokensClaimed(msg.sender, msg.sender, amt);
    }

    /**
    @dev Claim BigSB tokens bought on any pre/sale to different address
    @param to address to which tokens will be claimed
     */
    function claimTo(address to) external {
        require(_morty[msg.sender] == ZERO, "Use claimFromTo");
        _claim(msg.sender, to);
    }

    /**
    @dev Claim BigSB tokens bought on any pre/sale from exchange
    @param from sender address that ETH was send to pre/sale contract
     */
    function claimFrom(address from) external {
        address to = _morty[from];
        require(msg.sender == to, "Wrong Morty");
        _claim(from, to);
    }

    /**
    @dev Claim BigSB tokens by ETH send from exchange to another address
    @param from sender address that ETH was send
    @param to address to which send claimed tokens
     */
    function claimFromTo(address from, address to) external {
        require(msg.sender == _morty[from], "Wrong Morty");
        _claim(from, to);
    }

    // internal claim function, validate claim and send tokens to given address
    function _claim(address from, address to)
        internal
        claimStart
        notZeroAddress(to)
    {
        require(!isClaimed[from], "Already claimed!");
        isClaimed[from] = true;
        uint256 amt = _recalculate(_allTokens(from));
        require(IERC20(token).transfer(to, amt), "Token transfer failed");
        emit TokensClaimed(from, to, amt);
    }

    //
    // viewers
    //
    function isReplacedBy(address user) external view returns (address) {
        return _morty[user];
    }

    //
    // useful modifiers
    //
    modifier notZeroAddress(address user) {
        require(user != ZERO, "Can not use address 0x0");
        _;
    }
    modifier claimStart() {
        require(claimStarted, "Claiming process not started!");
        _;
    }
    modifier claimNotStarted() {
        require(!claimStarted, "Claiming process already started!");
        _;
    }

    //
    // Rick mode
    //

    /**
    @dev add single address that need to be changed in claim process
    @param bad address to replace
    @param good new address that can claim tokens bought by "bad" address
     */
    function addMorty(address bad, address good)
        external
        onlyOwner
        claimNotStarted
    {
        _addMorty(bad, good);
    }

    /// internal add replacement address function used in singe and multi add function
    function _addMorty(address bad, address good)
        internal
        notZeroAddress(good)
    {
        require(_morty[bad] == ZERO, "Morty already on list");
        _morty[bad] = good;
    }

    /**
    @dev add addresses that need to be replaced in claiming precess, ie send ETH from exchange
    @param bad list of wrong send addresses
    @param good list of address replacements
     */
    function addMortys(address[] calldata bad, address[] calldata good)
        external
        onlyOwner
        claimNotStarted
    {
        uint256 dl = bad.length;
        require(dl == good.length, "Data size mismatch");
        uint256 i;
        for (i; i < dl; i++) {
            _addMorty(bad[i], good[i]);
        }
    }

    /**
    @dev add single "bugged" user
    @param user affected user address
    @param tokens counted tokens for user from presale2
     */
    function addBugged(address user, uint256 tokens)
        external
        onlyOwner
        claimNotStarted
    {
        buggedTokens[user] = tokens;
    }

    /**
    @dev add list of users affected by "many ETH send" bug via list
    @param user list of users
    @param amt list of corresponding tokens amount
     */
    function addBuggedList(address[] calldata user, uint256[] calldata amt)
        external
        onlyOwner
        claimNotStarted
    {
        uint256 dl = user.length;
        require(dl == amt.length, "Data size mismatch");
        uint256 i;
        for (i; i < dl; i++) {
            buggedTokens[user[i]] = amt[i];
        }
    }

    // add data to ALMed user list
    function addAML(address[] calldata user, uint256[] calldata tokens)
        external
        onlyOwner
        claimNotStarted
    {
        uint256 dl = user.length;
        require(dl == tokens.length, "Data size mismatch");
        uint256 i;
        for (i; i < dl; i++) {
            _aml[user[i]] = tokens[i];
        }
    }

    /// Enable claiming process
    function enableClaim() external onlyOwner claimNotStarted {
        claimStarted = true;
    }

    /**
    @dev Function to recover accidentally send ERC20 tokens
    @param erc20 ERC20 token address
    */
    function rescueERC20(address erc20) external onlyOwner {
        if (erc20 == token) {
            require(block.timestamp > claimDateLimit, "Too soon");
        }
        uint256 amt = IERC20(erc20).balanceOf(address(this));
        require(amt > 0, "Nothing to rescue");
        IUsdt(erc20).transfer(owner, amt);
    }

    /**
    @dev Function to recover any ETH send to contract
    */
    function rescueETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}

//This is fine!