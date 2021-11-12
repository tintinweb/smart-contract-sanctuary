// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./IHousesNFT.sol";
import "./ReentrancyGuard.sol";

// standard interface of IERC20 token
// using this in this contract to receive Bino token by "transferFrom" method
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// must be a Minter Role of BinoHouse NFT contract
contract BinoBox is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public busd;
    IHousesNFT public binoHouse;

    uint256 public constant CAP = 2949;
    uint256 public constant EARLY_BIRD_PRICE = 200 * 1e18;  // 200 BUSD
    uint256 public constant WHITELIST_PRICE = 250 * 1e18;  // 250 BUSD
    uint256 public constant PUBLIC_SALE_PRICE = 300 * 1e18;  // 300 BUSD
    uint256 public maxPerTime = 1;

    bool public saleIsActive;
    // 1: testnet 2: earlybird 3: whitelist 4: public sale
    uint256 public currentRound;
    uint256 private _totalSold = 0;
    mapping(uint256 => uint256) private _roundToPrice;
    // address => roundNum => purchased or not 
    mapping(address => mapping(uint256 => bool)) private _isRoundPurchased;
    // address => level => availAmounts
    mapping(address => mapping(uint256 => uint256)) private _partnerAmounts;

    uint256 private _nonce;
    address private _validator;

    event BuyBox(address indexed to, uint256 indexed level, uint256 indexed roundNum);


    constructor (address busdAddress, address houseAddress) public {
        busd = IERC20(busdAddress);
        binoHouse = IHousesNFT(houseAddress);
        _validator = msg.sender;

        saleIsActive = false;
        currentRound = 1;
        _roundToPrice[2] = EARLY_BIRD_PRICE;
        _roundToPrice[3] = WHITELIST_PRICE;
        _roundToPrice[4] = PUBLIC_SALE_PRICE;
    }

    function setValidator(address newValidator) public onlyOwner {
        _validator = newValidator;
    }

    function setMaxPerTime(uint256 newMax) public onlyOwner {
        maxPerTime = newMax;
    }

    function setPartnerAvailableAmounts(address partner, uint256 level, uint256 amounts) public onlyOwner {
        _partnerAmounts[partner][level] = amounts;
    }

    // Set round first, then active sale
    // 1: testnet 2: earlybird 3: whitelist 4: public sale
    function setCurrentRound(uint256 roundNum) public onlyOwner {
        require(roundNum == 1 || roundNum == 2 || roundNum == 3 || roundNum == 4, "roundNum must be 1, 2, 3 or 4");
        currentRound = roundNum;
    }

    function setSaleIsActive(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function checkRemaining() public view returns (uint256) {
        return CAP.sub(_totalSold);
    }

    function isRoundPurchased(address account, uint256 roundNum) public view returns (bool) {
        return _isRoundPurchased[account][roundNum];
    }

    function checkPartnerAvailableAmounts(address partner, uint256 level) public view returns (uint256) {
        return _partnerAmounts[partner][level];
    }

    // busd: approve first
    function buyPreSaleBox(uint256 roundNum, uint256 level, bytes calldata signature) public nonReentrant {
        require(_msgSender() == tx.origin, "contract can not buy");
        require(saleIsActive, "sale does not start yet");
        require(currentRound == roundNum, "currentRound != roundNum: presale");
        require(!_isRoundPurchased[_msgSender()][roundNum], "you can only purchase ONE box in this round");

        // check signature
        address signer = tryRecover(whitelistHash(_msgSender(), roundNum, level), signature);
        require(signer == _validator, "check signature error: you are not on the whitelist");

        _isRoundPurchased[_msgSender()][roundNum] = true;
        if (roundNum != 1) {
            busd.safeTransferFrom(_msgSender(), address(this), _roundToPrice[roundNum]);
        }
        _nonce = _nonce.add(1);
        binoHouse.safeMint(_msgSender(), level);

        emit BuyBox(_msgSender(), level, roundNum);
    }

    // busd: approve first
    function buyPublicSaleBox(uint256 amounts) public nonReentrant {
        require(_msgSender() == tx.origin, "contract can not buy");
        require(saleIsActive, "sale does not start yet");
        require(currentRound == 4, "currentRound must be in Round #4: public sale");
        require(amounts <= maxPerTime, "can not excced maxPerTime limit");
        require(_totalSold.add(amounts) <= CAP, "can not exceed max cap in this round");
        require(amounts.mul(PUBLIC_SALE_PRICE) <= busd.balanceOf(_msgSender()), "BUSD balance is not enough");

        _totalSold = _totalSold.add(amounts);
        busd.safeTransferFrom(_msgSender(), address(this), amounts.mul(PUBLIC_SALE_PRICE));

        for(uint256 i = 0; i < amounts; ++i) {
            _nonce = _nonce.add(1);
            // 1,2,or 3
            uint256 randLevel = _getRandomInteger(_nonce);
            binoHouse.safeMint(_msgSender(), randLevel);

            emit BuyBox(_msgSender(), randLevel, currentRound);
        }
    }

    function partnerMint(uint256 level, uint256 amounts) public nonReentrant {
        require(saleIsActive, "sale does not start yet");
        require(amounts > 0, "can not input amounts == 0");
        require(_partnerAmounts[_msgSender()][level] >= amounts, "not enough balance left");

        _partnerAmounts[_msgSender()][level] = _partnerAmounts[_msgSender()][level].sub(amounts);

        for(uint256 i = 0; i < amounts; ++i) {
            binoHouse.safeMint(_msgSender(), level);
        }
    }

    function withdrawBUSD(address to) public onlyOwner {
        uint256 balance = busd.balanceOf(address(this));
        busd.safeTransfer(to, balance);
    }

    function whitelistHash(address account, uint256 roundNum, uint256 level) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, roundNum, level));
    }

    function tryRecover(bytes32 hashCode, bytes memory signature) public pure returns (address) {
        return ECDSA.recover(hashCode, signature);
    }

    // generate a random integer between [1, 3]
    function _getRandomInteger(uint256 nonce) private view returns (uint256) {

        uint256 randomInt = uint256(
            keccak256(
                abi.encodePacked(
                    uint256(blockhash(block.number.sub(1))),
                    uint256(block.coinbase),
                    block.difficulty,
                    block.timestamp,
                    _totalSold,
                    nonce
                )
            )
        ).mod(10000);
        
        if (randomInt <= 4) return 3;
        else if (randomInt <= 849) return 2;
        else return 1;
    }

}