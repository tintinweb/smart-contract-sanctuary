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
interface IERC20 {
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
 * @title AutoCrypto Public Presale
 * @author AutoCrypto
 * @notice This contracts allows any user to buy AutoCrypto token
 * from October 4th 16:00 UTC until October 14th 22:00 UTC.
 * Tokens will be claimable from October 15th 15:00 UTC, at the same time of the release.
 *
 * The admin account is the one that deploys the contract. This cannot be changed.
 *
 * This presale has a softcap of 500 BNB and a hardcap of 1000 BNB, with a minimum
 * contribution of 0.1 BNB and a maximum of 2 BNB. In the event of the softcap not being
 * reached, contributors will be able to ask for a refund from October 15th 15:00 UTC.
 * 
 * With the release of the token, a 80% of the total contribution will be instantly added
 * to the liquidity through the token contract. A 20% will be transferred to the project
 * wallet, which will be used to maintain the servers and services provided in the AutoCrypto
 * community (eg. website, telegram bots, discord bots, AI).
 */
contract AutoCryptoPublicPresaleTest {

    event TokenSet(address tokenAddress);
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

    address private _admin;

    mapping(address => Contributor) contributor;

    address[] private contributors;
    uint[] private contributions;
    uint public totalContribution;
    uint public presaleRate;

    address public token;
    uint public minContribution;
    uint public maxContribution;

    uint public liquidityDistribution;
    uint public projectDistribution;
    address payable public projectWallet;

    bool presaleCancelled;

    constructor() {
        _admin = msg.sender;

        minContribution = 1 ether / 10;
        maxContribution = 2 ether;
        presaleRate = 44_000;

        liquidityDistribution = 80;
        projectDistribution = 20;

        projectWallet = payable(0x4c8c20BB413AD29d3C59d92be393a0c0B32A127f);
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, "AutoCrypto: Access denied");
        _;
    }

    /**
     * @return The contribution of a given address.
     */
    function getContribution(address _contributor) public view returns (uint) {
        return contributor[_contributor].contribution;
    }

    /**
     * @return Two arrays with the wallets of the contributors and their contribution in wei.
     */
    function getContributors() public view returns (address[] memory, uint[] memory) {
        return (contributors, contributions);
    }

    /**
     * @dev Check all the requirements (eg. the presale has started, the contribution is
     * between the limits) and then stores the user's contribution.
     *
     * The only interaction with an external contract is here. `antibot` is a contract
     * deployed by AutoCrypto which serves the only purpose of stopping bots from buying
     * in this presale.
     *
     * Emits a {Contribute} event.
     */
    function contribute() public payable {
        require(contributor[msg.sender].contribution + msg.value >= minContribution, "AutoCrypto: Contribution is below minimum");
        require(contributor[msg.sender].contribution + msg.value <= maxContribution, "AutoCrypto: Contribution is above maximum");

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
        emit Contribute(msg.sender, msg.value);
    }

    /**
     * @dev Sets the AU token address.
     * For safety reasons, the token can only be set once and this must be done before
     * the release of the token on October 15th at 15:00 UTC.
     *
     * This is done in order to require the token balance to equal to the hardcap
     * multiplied by the rate (44,000) and thus guaranteeing that any contributor can
     * claim their tokens after the release.
     *
     * Emits a {RemoveWhitelisted} event
     */
    function setTokenAddress(address tokenAddress) public onlyAdmin {
        token = tokenAddress;
        emit TokenSet(tokenAddress);
    }

    /**
     * @dev Refunds 100% of the contributed amount in case the function {setTokenAddress}
     * has not been called, meaning that the token has not been released.
     * This function requires the current timestamp to be over the release time (Oct 15th 15:00 UTC).
     * only if the presale has not been cancelled manually.
     *
     * This is a safety measure that guarantees all of the invested amount to the contributor.
     * This function can also be called if presale is cancelled manually through the function {cancelPresale}.
     *
     * Emits a {Refund} event.
     */
    function refund() public {
        require(presaleCancelled);
        uint contribution = contributor[msg.sender].contribution;
        require(contribution > 0, "AutoCrypto: You haven't contributed");
        contributor[msg.sender].contribution = 0;
        payable(msg.sender).transfer(contribution);

        emit Refund(msg.sender, contribution);
    }

    /**
     * @dev Transfer 80% of the total contribution to the token contract, which will be added 
     * to the liquidity instantly, and the remaining 20% will be sent to the project wallet.
     *
     * This function can only be called by the token contract.
     */
    function releaseToken() public {
        require(msg.sender == address(token), "AutoCrypto: Access denied");
        
        projectWallet.transfer(totalContribution * projectDistribution / 100);
        payable(msg.sender).transfer(totalContribution * liquidityDistribution / 100);
    }

    /**
     * @dev Cancel the current presale created by this contract. This function allows any
     * contributor to ask for a refund through the function {refund}.
     */
    function cancelPresale() public onlyAdmin() {
        presaleCancelled = true;
    }
}