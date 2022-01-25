/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-24
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// File: contracts/blotter.sol



pragma solidity ^0.8.7;



// contract to map addresses to twitter links for promotion
contract blotter is ReentrancyGuard{
    address[] users;
    address activator;
    IERC20 token;
    address owner;
    uint256 index;
    uint public cost;
    struct tweet{
        bool live;
        string link;
        uint timestamp;
    }
    mapping(address => tweet) public tweets;
    event TweetPromoted(address user, string link, uint timestamp);
    event TweetDemoted(address user, string link, uint timestamp);
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }
    modifier isAlive {
        require(tweets[msg.sender].live, "Promotion is not live");
        _;
    }
    constructor(uint _cost, IERC20 _token){ // in wei, cost to promote a users twitter link
        token = _token;
        owner = msg.sender;
        activator = msg.sender;
        cost = _cost;
        index = 0;
    }
    function promoteTweet(string memory _link) external returns(tweet memory){ // must be approved by owner to transfer RXG
        require(token.transferFrom(msg.sender, activator, cost), "RXG failed to transfer");
        address _addr = msg.sender;
        tweets[_addr].link = _link;
        tweets[_addr].timestamp = block.timestamp;
        tweets[_addr].live = true;
        users.push(_addr);
        tweet memory _tweet = tweets[_addr];
        emit TweetPromoted(_addr, _tweet.link, _tweet.timestamp);
        return _tweet;
    }
    function demoteTweet() external onlyOwner isAlive returns(tweet memory){
        address _addr = msg.sender;
        tweets[_addr].link = "";
        tweets[_addr].timestamp = block.timestamp;
        tweets[_addr].live = false;
        tweet memory _tweet = tweets[_addr];
        emit TweetDemoted(_addr, _tweet.link, _tweet.timestamp);
        return _tweet;
    }
    function getTwitterLinks(address _addr) public view returns (tweet memory) {
        return tweets[_addr];
    }
    function getUsers() public view returns (address[] memory) {
        return users;
    }
    function getAllTweets() public view returns (tweet[] memory) {
        tweet[] memory _tweets;
        for(uint i = 0; i < users.length; i++){
            if (tweets[users[i]].live){
                _tweets[i] = tweets[users[i]];
            }
            else{
                continue;
            }
        }
        return _tweets;
    }
    function getCost() public view returns (uint){
        return cost;
    }
    function killPromotion(address _addr) external onlyOwner isAlive {
        tweets[_addr].live = false;
    }
}