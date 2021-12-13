// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IPresale.sol";

contract PresaleReader {
    function getCurrentTime(address _presale) external view returns (uint256){
        uint256 currentTime = IPresale(_presale).getCurrentTime();
        return currentTime;
    }

    function getTokenData(address _presale) external view returns (uint256[] memory) {
        uint256[] memory tokenData = IPresale(_presale).getTokenData();
        return tokenData;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Returns the number of decimals used to get its user representation.
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
pragma solidity =0.8.4;
import "./IERC20.sol";

interface IPresale {
    function startPresale(
        uint256[] memory tokenData,
        uint[] memory presaleData,
        string[] memory socialData,
        uint refund_type,
        address router)
    external;
    function getPresaleStatus() external returns (uint);
    function claimTokens() external;
    function withdraw() external;
    function checkContribution(address addr) external view returns(uint256);
    function setPresaleRate(uint256 newRate) external;
    function setListingRate(uint256 newRate) external;
    function setAvailableTokens(uint256 amount) external;
    function setHardCap(uint256 amount) external;
    function setSoftCap(uint256 amount) external;
    function getCurrentTime() external view returns (uint256);
    function weiRaised() external view returns (uint256);
    function getLogoImg() external view returns (string memory);
    function getWebsite() external view returns (string memory);
    function getFacebook() external view returns (string memory);
    function getTwitter() external view returns (string memory);
    function getGithub() external view returns (string memory);
    function getTelegram() external view returns (string memory);
    function getInstagram() external view returns (string memory);
    function getDiscord() external view returns (string memory);
    function getReddit() external view returns (string memory);
    function getDiscription() external view returns (string memory);
    function getSocialData() external view returns (string[] memory);
    function getTokenData() external view returns (uint256[] memory);
    function getPresaleData() external view returns (uint[] memory);
    function setMaxPurchase(uint256 value) external;
    function setMinPurchase(uint256 value) external;
    function takeTokens(IERC20 tokenAddress) external;
    function refundMe() external;

}