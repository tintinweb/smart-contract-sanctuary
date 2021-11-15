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
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Token is IERC20 {
    function mint(address to, uint256 amount) external;
}

contract ICO is Ownable {
    // The token being in crowdsale and airdrop
    Token public token;

    // Address where funds are collected
    address payable public wallet;

    // Amount of tokens airdropped
    uint256 public airdroppedAmount;

    // Amount of tokens sold
    uint256 public soldAmount;

    // Amount of eth received
    uint256 public receivedEth;

    // Amount of token rewarded to refer
    uint256 public rewardedAmount;

    // Amount of eth rewarded to refer
    uint256 public rewardedEth;

    // Active Token airdrop
    bool public activeAirdrop;

    // Active Token crowdsale
    bool public activeCrowdsale;

    // Amount of tokens unit to airdrop
    uint256 public airdropTokens;

    // Amount of wei paid to get airdrop
    uint256 public airdropPrice;

    // How many token unit a referrer gets on airdrop
    // example: for 40%, it must be 40
    uint256 public airdropReferralProfitTokenPercent;

    // How many wei a referrer gets on airdrop
    // example: for 20%, it must be 20
    uint256 public airdropReferralProfitWeiPercent;

    // Addresses that processed airdrop once
    mapping(address => bool) public processedAirdrops;

    // How many token units a buyer gets per wei.
    // wei / saleRate = TKNbits
    uint256 public saleRate;

    // How many token unit a referrer gets on buy
    // example: for 40%, it must be 40
    uint256 public saleReferralProfitTokenPercent;

    // How many wei a referrer gets on buy
    // example: for 20%, it must be 20
    uint256 public saleReferralProfitWeiPercent;

    /**
     * Event for token airdrop logging
     * @param recipient who got the airdrop
     * @param referrer who was referrer
     * @param amount amount of tokens airdropped
     * @param date date of airdrop
     */
    event AirdropProcessed(
        address indexed recipient,
        address indexed referrer,
        uint256 amount,
        uint256 date
    );

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param referrer who was referrer
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed referrer,
        uint256 value,
        uint256 amount
    );

    /**
     * @param _token Address of the token being in crowdsale and airdrop
     * @param _wallet Address where collected funds will be forwarded to
     * @param _activeAirdrop Active Token airdrop
     * @param _airdropTokens Amount of tokens unit to airdrop
     * @param _airdropPrice Amount of wei paid to get airdrop
     * @param _airdropReferralProfitTokenPercent percentage of token referrer gets on airdrop
     * @param _airdropReferralProfitWeiPercent percentage of wei referrer gets on airdrop
     * @param _activeCrowdsale Active Token crowdsale
     * @param _saleRate How many token units a buyer gets per wei. wei / saleRate = TKNbits
     * @param _saleReferralProfitTokenPercent percentage of token referrer gets on buy
     * @param _saleReferralProfitWeiPercent percentage of wei referrer gets on buy
     */
    constructor(
        address _token,
        address _wallet,
        bool _activeAirdrop,
        uint256 _airdropTokens,
        uint256 _airdropPrice,
        uint256 _airdropReferralProfitTokenPercent,
        uint256 _airdropReferralProfitWeiPercent,
        bool _activeCrowdsale,
        uint256 _saleRate,
        uint256 _saleReferralProfitTokenPercent,
        uint256 _saleReferralProfitWeiPercent
    ) {
        require(_wallet != address(0), "Crowdsale: wallet is the zero address");

        token = Token(_token);
        wallet = payable(_wallet);
        airdropTokens = _airdropTokens;
        airdropPrice = _airdropPrice;
        saleRate = _saleRate;
        activeAirdrop = _activeAirdrop;
        activeCrowdsale = _activeCrowdsale;
        airdropReferralProfitTokenPercent = _airdropReferralProfitTokenPercent;
        airdropReferralProfitWeiPercent = _airdropReferralProfitWeiPercent;
        saleReferralProfitTokenPercent = _saleReferralProfitTokenPercent;
        saleReferralProfitWeiPercent = _saleReferralProfitWeiPercent;
    }

    function update(
        address _wallet,
        bool _activeAirdrop,
        uint256 _airdropTokens,
        uint256 _airdropPrice,
        uint256 _airdropReferralProfitTokenPercent,
        uint256 _airdropReferralProfitWeiPercent,
        bool _activeCrowdsale,
        uint256 _saleRate,
        uint256 _saleReferralProfitTokenPercent,
        uint256 _saleReferralProfitWeiPercent
    ) public onlyOwner() {
        wallet = payable(_wallet);
        airdropTokens = _airdropTokens;
        airdropPrice = _airdropPrice;
        saleRate = _saleRate;
        activeAirdrop = _activeAirdrop;
        activeCrowdsale = _activeCrowdsale;
        airdropReferralProfitTokenPercent = _airdropReferralProfitTokenPercent;
        airdropReferralProfitWeiPercent = _airdropReferralProfitWeiPercent;
        saleReferralProfitTokenPercent = _saleReferralProfitTokenPercent;
        saleReferralProfitWeiPercent = _saleReferralProfitWeiPercent;
    }

    function buy(address _referrer) public payable {
        require(activeCrowdsale, "No active crowdsale");
        require(msg.value != 0, "Paid amount is 0");
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount / saleRate;

        token.mint(msg.sender, tokens);
        soldAmount += tokens;
        emit TokensPurchased(msg.sender, _referrer, weiAmount, tokens);

        // send profit to referrer
        if (msg.sender != _referrer && _referrer != address(0)) {
            // only referrers who hold the token
            if (token.balanceOf(_referrer) > 0) {
                uint256 ref_tokens = (msg.value *
                    saleReferralProfitTokenPercent) / 100;
                if (ref_tokens > 0) {
                    token.mint(_referrer, ref_tokens);
                    rewardedAmount += ref_tokens;
                }

                uint256 ref_wei = (msg.value * saleReferralProfitWeiPercent) /
                    100;
                if (ref_wei > 0) {
                    payable(_referrer).transfer(ref_wei);
                    weiAmount -= ref_wei;
                    rewardedEth += ref_wei;
                }
            }
        }

        // forward remaining founds to wallet
        wallet.transfer(weiAmount);
        receivedEth += weiAmount;
    }

    function airdrop(address _referrer) public payable {
        require(activeAirdrop, "No active airdrop");
        require(msg.value >= airdropPrice, "Insufficient amount paid");
        require(
            processedAirdrops[msg.sender] == false,
            "airdrop already processed"
        );
        uint256 weiAmount = msg.value;

        token.mint(msg.sender, airdropTokens);
        airdroppedAmount += airdropTokens;
        emit AirdropProcessed(
            msg.sender,
            _referrer,
            airdropTokens,
            block.timestamp
        );

        // send profit to referrer
        if (msg.sender != _referrer && _referrer != address(0)) {
            // only referrers who hold the token
            if (token.balanceOf(_referrer) > 0) {
                uint256 ref_tokens = (msg.value *
                    airdropReferralProfitTokenPercent) / 100;
                if (ref_tokens > 0) {
                    token.mint(_referrer, ref_tokens);
                    rewardedAmount += ref_tokens;
                }

                uint256 ref_wei = (msg.value *
                    airdropReferralProfitWeiPercent) / 100;
                if (ref_wei > 0) {
                    payable(_referrer).transfer(ref_wei);
                    weiAmount -= ref_wei;
                    rewardedEth += ref_wei;
                }
            }
        }

        // forward remaining founds to wallet
        wallet.transfer(weiAmount);
        receivedEth += weiAmount;
    }
}

