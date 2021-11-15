pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 tokenId) external view returns (bool);
}

/**
 * @title Presale
 * @dev Presale contract allowing investors to purchase the cell token.
 * This contract implements such functionality in its most fundamental form and can be extended 
 * to provide additional functionality and/or custom behavior.
 */
contract Presale is Context {
    // The token being sold
    IERC721 private _cellToken;

    // Address where fund are collected
    address payable private _wallet;

    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of token to be pay for one ERC721 token
    uint256 private _weiPerToken;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param tokenId uint256 ID of the token to be purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 tokenId);

    /**
     * @param wallet_ Address where collected tokens will be forwarded to
     * @param cellToken_ Address of the Cell token being sold
     * @param weiPerToken_ tokens amount paid for purchase a Cell token
     */
    constructor (address payable wallet_, IERC721 cellToken_, uint256 weiPerToken_)
        public
    {
        require(wallet_ != address(0), "Presale: wallet is the zero address");
        require(address(cellToken_) != address(0), "Presale: cell token is the zero address");
        require(weiPerToken_ > 0, "Presale: token price must be greater than zero");
        _wallet = wallet_;
        _cellToken = cellToken_;
        _weiPerToken = weiPerToken_;
    }

    /**
     * @dev Fallback function revert your fund.
     * Only buy Cell token with the buyToken function.
     */
    fallback() external payable {
        revert("Presale: cannot accept any amount directly");
    }

    /**
     * @return The token being sold.
     */
    function cellToken() public view returns (IERC721) {
        return _cellToken;
    }

    /**
     * @return Amount of wei to be pay for a Cell token
     */
    function weiPerToken() public view returns (uint256) {
        return _weiPerToken;
    }

    /**
     * @return The address where tokens amounts are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @dev Returns x and y where represent the position of the cell.
     */
    function cellById(uint256 tokenId) public pure returns (uint256 x, uint256 y){
        x = tokenId / 90;
        y = tokenId - (x * 90);
    }

    /**
     * @dev token purchase with pay Land tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenId uint256 ID of the token to be purchase
     */
    function buyToken(address beneficiary, uint256 tokenId) public payable{
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        require(weiPerToken() == msg.value, "Presale: Not enough Eth");
        require(!_cellToken.exists(tokenId), "Presale: token already minted");
        require(tokenId < 11520, "Presale: tokenId must be less than max token count");
        (uint256 x, uint256 y) = cellById(tokenId);
        require(x < 38 || x > 53 || y < 28 || y > 43, "Presale: tokenId should not be in the unsold range");
        _wallet.transfer(msg.value);
        _cellToken.mint(beneficiary, tokenId);
        emit TokensPurchased(msg.sender, beneficiary, tokenId);
    }
    
    /**
     * @dev batch token purchase with pay our ERC20 tokens
     * @param beneficiary Recipient of the token purchase
     * @param tokenIds uint256 IDs of the token to be purchase
     */
    function buyBatchTokens(address beneficiary, uint256[] memory tokenIds) public payable{
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        uint256 weiAmount = weiPerToken() * tokenIds.length;
        require(weiAmount == msg.value, "Presale: Not enough Eth");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(!_cellToken.exists(tokenIds[i]), "Presale: token already minted");
            require(tokenIds[i] < 11520, "Presale: tokenId must be less than max token count");
            (uint256 x, uint256 y) = cellById(tokenIds[i]);
            require(x < 38 || x > 53 || y < 28 || y > 43, "Presale: tokenId should not be in the unsold range");
        }
        _wallet.transfer(msg.value);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _cellToken.mint(beneficiary, tokenIds[i]);
            emit TokensPurchased(msg.sender, beneficiary, tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

