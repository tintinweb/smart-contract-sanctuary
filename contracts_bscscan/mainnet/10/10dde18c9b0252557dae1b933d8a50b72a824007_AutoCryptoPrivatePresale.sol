/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

/**
 * Website: autocrypto.ai
 * International Telegram: t.me/AutoCryptoInternational
 * Spanish Telegram: t.me/AutoCryptoSpain
 * Starred Calls Telegram: t.me/AutoCryptoStarredCalls
 * Discord: discord.gg/autocrypto
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @notice Interface for an ERC20 standar Token that will be used to
 * transfer AU tokens to the contributors of the private presale.
 */
interface IERC20{
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
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
    function transfer(address recipient, uint amount) external returns (bool);
}

/**
 * @title AutoCrypto Private Presale
 * @author AutoCrypto
 * @notice This contracts allows whitelisted users to buy AutoCrypto token
 * before its release on 15th of October at 15:00 UTC.
 *
 * The admin account is the one that deploys the contract. This cannot be changed
 * 
 * The contract will keep 50% of each contribution which will be used to provide
 * liquidity with the public presale contract to the AU token. A 50% of the
 * contributions will be transferred to the marketing wallet which will only be
 * used to promote the project in different sites.
 *
 * With the token release, the 50% of contributions remaining in the contract
 * will be distributed. A 10% of the 100% will be transferred to the project wallet
 * which will be used to maintain the servers and services provided in the AutoCrypto
 * community (eg. website, telegram bots, discord bots), and the last 40% of the total
 * will be transferred to the token contract, which will be used to provide liquidity
 * instantly.
 */
contract AutoCryptoPrivatePresale {

    event TokenSet(address tokenAddress);
    event AddWhitelisted(address contributor);
    event RemoveWhitelisted(address contributor);
    event Claim(address contributor, uint amount);
    event Refund(address contributor, uint amount);
    event Contribute(address contributor, uint amount);

    /**
     * @notice This struc will store the contribution of each user who participates.
     * The index is used to keep track of the user in the arrays `contributors`
     * and `contributions`.
     */
    struct Contributor {
        uint index;
        uint contribution;
        bool claimed;
    }

    address _admin;

    mapping(address => Contributor) contributor;
    mapping(address => bool) whitelisted;

    address[] private contributors;
    uint[] private contributions;
    uint public totalContribution;
    uint public presaleRate;
    uint public refundable;

    IERC20 public token;
    uint public minContribution;
    uint public maxContribution;
    uint public startTime;
    uint public endTime;
    uint public releaseTime;

    uint liquidityDistribution;
    uint marketingDistribution;
    uint projectDistribution;
    address payable marketingWallet;
    address payable projectWallet;

    constructor() {
        _admin = msg.sender;

        minContribution = 1 ether / 10;
        maxContribution = 3 ether;
        presaleRate = 48_000;
        startTime = 1_632_088_800; // September 20, 00:00 UTC
        endTime = 1_633_219_200; // October 3th, 00:00 UTC
        releaseTime = 1_634_310_000; // October 15th, 15:00 UTC

        liquidityDistribution = 50;
        marketingDistribution = 40;
        projectDistribution = 10;

        marketingWallet = payable(0x63A6486E8Acf2c700De94668Ffc22976AeF447D6);
        projectWallet = payable(0x41B297Af3e52F12C25442d8B542463bEb80B22BF);
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, "AutoCrypto: Access denied");
        _;
    }

    /**
     * @return Two arrays with the wallets of the contributors and their contribution in wei.
     */
    function getContributors() public view returns (address[] memory, uint[] memory) {
        return (contributors, contributions);
    }

    /**
     * @return The contribution of a given address.
     */
    function getContribution(address _contributor) public view returns (uint) {
        return contributor[_contributor].contribution;
    }

    /**
     * @dev Delegates to {contribute}
     */
    receive() external payable {
        contribute();
    }

    /**
     * @dev Check all the requirements (eg. the presale has started, the contribution is
     * between the limits, user is whitelisted) and then stores the user's contribution.
     * A 50% is sent to the marketing wallet as explained in the contract notice.
     *
     * Emits a {Contribute} event.
     */
    function contribute() public payable {
        require(block.timestamp >= startTime, "AutoCrypto: Presale has not started");
        require(endTime >= block.timestamp, "AutoCrypto: Presale has ended");

        require(whitelisted[msg.sender], "AutoCrypto: Not whitelisted");

        require(msg.value >= minContribution || contributor[msg.sender].contribution > minContribution, "AutoCrypto: Contribution is below minimum");
        require(msg.value <= maxContribution, "AutoCrypto: Contribution is above maximum");
        
        require(contributor[msg.sender].contribution + msg.value <= maxContribution, "AutoCrypto: Maximum contribution achieved");

        if (contributor[msg.sender].contribution == 0) {
            contributor[msg.sender].contribution = msg.value;
            contributor[msg.sender].index = contributors.length;
            contributors.push(msg.sender);
            contributions.push(msg.value);
        } else {
            contributor[msg.sender].contribution += msg.value;
            contributions[contributor[msg.sender].index] = contributor[msg.sender].contribution;
        }
        totalContribution += msg.value;
        refundable += msg.value * (liquidityDistribution + projectDistribution) / 100;
        marketingWallet.transfer(msg.value * marketingDistribution / 100);
        emit Contribute(msg.sender, msg.value);
    }

    /**
     * @dev Adds an array of wallets to the whitelist.
     * This function is protected with the {onlyAdmin} modifier.
     *
     * Emits a {AddWhitelisted} event
    */
    function addWhitelist(address[] calldata accounts) public onlyAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            whitelisted[accounts[i]] = true;
            emit AddWhitelisted(accounts[i]);
        }
    }

    /**
     * @dev Removes an array of wallets to the whitelist.
     * This function is protected with the {onlyAdmin} modifier.
    */
    function removeWhitelist(address[] calldata accounts) public onlyAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            whitelisted[accounts[i]] = false;
            emit RemoveWhitelisted(accounts[i]);
        }
    }

    /**
     * @dev Sets the AU token address.
     * For safety reasons, the token can only be set once and this must be done before
     * the release of the token on October 15th at 15:00 UTC, and after the private presale
     * has finished on October 3rd at 00:00 UTC
     *
     * This is done in order to require the token balance to equal to the total contribution
     * multiplied by the rate.
     *
     * Emits a {RemoveWhitelisted} event
     */
    function setTokenAddress(address tokenAddress) public onlyAdmin {
        require(address(token) == address(0), "AutoCrypto: Token already set");
        require(block.timestamp < releaseTime, "AutoCrypto: Refunds are active");
        require(block.timestamp > endTime, "AutoCrypto: Presale has not ended");
        token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) == totalContribution * presaleRate, "AutoCrypto: Insuficient tokens");
        require(bytes(token.name()).length == bytes("AutoCrypto").length && bytes(token.symbol()).length == bytes("AU").length, "AutoCrypto: This is not AutoCrypto");
        emit TokenSet(tokenAddress);
    }

    /**
     * @dev Refunds a 50% of the contributed amount in case the token has not been released
     * and the current timestamp is over the release time.
     * This is a safety measure that guarantees a 50% of the invested amount to the contributor.
     *
     * Emits a {Refund} event.
     */
    function refund() public {
        uint contribution = contributor[msg.sender].contribution;
        require(block.timestamp > releaseTime, "AutoCrypto: Token has not been released");
        require(address(token) == address(0), "AutoCrypto: Presale not refundable");
        require(contribution > 0, "AutoCrypto: You haven't contributed");
        contributor[msg.sender].contribution = 0;
        uint contributionPercent = contribution * 100 / totalContribution;
        uint amount = refundable * contributionPercent / 100;
        payable(msg.sender).transfer(amount);

        emit Refund(msg.sender, amount);
    }

    /**
     * @dev Any contributor can claim their AU tokens once the token is released on October 15th at 15:00 UTC.
     * Each claim will receive an amount of tokens following the rate of 1 BNB = 48.000 AU
     *
     * Emits a {Claim} event.
     */
    function claim() public {
        require(!contributor[msg.sender].claimed, "AutoCrypto: Already claimed");
        uint contribution = contributor[msg.sender].contribution;
        require(block.timestamp > releaseTime, "AutoCrypto: Token has not been released");
        require(address(token) != address(0), "AutoCrypto: Presale not refundable");
        require(contribution > 0, "AutoCrypto: You haven't contributed");
        contributor[msg.sender].claimed = true;
        uint amount = contribution * presaleRate * 10 ** token.decimals() / 1 ether;
        token.transfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    /**
     * @dev Transfer the remaining 10% of the total contribution to the project wallet, and the remaining 40%
     * to the token contract, which will be added to the liquidity instantly.
     */
    function releaseToken() public {
        require(msg.sender == address(token), "AutoCrypto: Access denied");
        require(block.timestamp > releaseTime, "AutoCrypto: Token cannot be released yet");
        
        projectWallet.transfer(totalContribution * projectDistribution / 100);
        payable(msg.sender).transfer(totalContribution * liquidityDistribution / 100);
    }
}