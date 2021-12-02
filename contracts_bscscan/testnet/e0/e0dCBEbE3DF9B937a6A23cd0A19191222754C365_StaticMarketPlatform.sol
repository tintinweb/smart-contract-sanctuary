/*

  << Static Market contract >>

*/

import "./lib/ArrayUtils.sol";
import "./registry/AuthenticatedProxy.sol";
import "./StaticMarketBase.sol";

pragma solidity 0.7.5;

contract StaticMarketPlatform is StaticMarketBase {

    function ERC721ForETH(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721ForETH: call must be a direct call");

        (address[1] memory tokenGive, uint256[2] memory tokenIdAndPrice) = abi.decode(extra, (address[1], uint256[2]));

        require(tokenIdAndPrice[1] > 0,"ERC721ForETH: ERC721 price must be larger than zero");
        require(addresses[2] == tokenGive[0], "ERC721ForETH: call target must equal address of token to give");

        require(uints[0] == tokenIdAndPrice[1], "ERC721ForETH: Price must be same");

        checkERC721Side(data,addresses[1],addresses[4],tokenIdAndPrice[0]);

        checkETHSideWithOffset(addresses[1], uints[0], tokenIdAndPrice[1], counterdata);

        return 1;
    }

    function ETHForERC721(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC721: call must be a delegate call");

        (address[1] memory tokenGet, uint256[2] memory tokenIdAndPrice) = abi.decode(extra, (address[1], uint256[2]));

        require(tokenIdAndPrice[1] > 0,"ETHForERC721: ERC721 price must be larger than zero");
        require(addresses[5] == tokenGet[0], "ETHForERC721: call target must equal address of token to give");

        checkERC721Side(counterdata,addresses[4],addresses[1],tokenIdAndPrice[0]);

        checkETHSideWithOffset(addresses[4], uints[0], tokenIdAndPrice[1], data);

        return 1;
    }

    function ERC721ForETHWithOneFee(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721ForETHWithOneFee: call must be a direct call");

        (address[2] memory tokenGiveAndFeeRecipient, uint256[3] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[2], uint256[3]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721ForETHWithOneFee: ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveAndFeeRecipient[0], "ERC721ForETHWithOneFee: call target must equal address of token to give");

        require(uints[0] == (tokenIdAndPriceAndFee[1] + tokenIdAndPriceAndFee[2]), "ERC721ForETHWithOneFee: Price must be same");

        checkERC721Side(data, addresses[1], addresses[4], tokenIdAndPriceAndFee[0]);

        checkETHSideOneFeeWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], counterdata);

        return 1;
    }

    function ETHForERC721WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC721WithOneFee: call must be a delegate call");

        (address[2] memory tokenGetAndFeeRecipient, uint256[3] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[2], uint256[3]));

        require(tokenIdAndPriceAndFee[1] > 0,"ETHForERC721WithOneFee: ERC721 price must be larger than zero");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "ETHForERC721WithOneFee: countercall target must equal address of token to get");

        checkERC721Side(counterdata, addresses[4], addresses[1], tokenIdAndPriceAndFee[0]);

        checkETHSideOneFeeWithOffset(addresses[4], tokenGetAndFeeRecipient[1], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], data);

        return 1;
    }

    function ERC721ForETHWithTwoFees(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC721ForETHWithTwoFees: call must be a direct call");

        (address[3] memory tokenGiveAndFeeRecipient, uint256[4] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[3], uint256[4]));

        require(tokenIdAndPriceAndFee[1] > 0,"ERC721ForETHWithTwoFees: ERC721 price must be larger than zero");
        require(addresses[2] == tokenGiveAndFeeRecipient[0], "ERC721ForETHWithTwoFees: call target must equal address of token to give");

        require(uints[0] == (tokenIdAndPriceAndFee[1] + tokenIdAndPriceAndFee[2] + tokenIdAndPriceAndFee[3]), "ERC721ForETHWithTwoFees: Price must be same");

        checkERC721Side(data, addresses[1], addresses[4], tokenIdAndPriceAndFee[0]);

        checkETHSideTwoFeesWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], tokenGiveAndFeeRecipient[2], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], tokenIdAndPriceAndFee[3], counterdata);

        return 1;
    }

    function ETHForERC721WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC721WithTwoFees: call must be a delegate call");

        (address[3] memory tokenGetAndFeeRecipient, uint256[4] memory tokenIdAndPriceAndFee) = abi.decode(extra, (address[3], uint256[4]));

        require(tokenIdAndPriceAndFee[1] > 0,"ETHForERC721WithTwoFees: ERC721 price must be larger than zero");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "ETHForERC721WithTwoFees: countercall target must equal address of token to get");

        checkERC721Side(counterdata, addresses[4], addresses[1], tokenIdAndPriceAndFee[0]);

        checkETHSideTwoFeesWithOffset(addresses[4], tokenGetAndFeeRecipient[1], tokenGetAndFeeRecipient[2], uints[0], tokenIdAndPriceAndFee[1], tokenIdAndPriceAndFee[2], tokenIdAndPriceAndFee[3], data);

        return 1;
    }

    function ETHForAnyERC721(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForAnyERC721: call must be a delegate call");

        (address[1] memory tokenGet, uint256[1] memory price) = abi.decode(extra, (address[1], uint256[1]));

        require(price[0] > 0,"ETHForAnyERC721: ERC721 price must be larger than zero");
        require(addresses[5] == tokenGet[0], "ETHForAnyERC721: call target must equal address of token to give");

        checkERC721SideForCollection(counterdata,addresses[4],addresses[1]);

        checkETHSideWithOffset(addresses[4], uints[0], price[0], data);

        return 1;
    }

    function ETHForAnyERC721WithOneFee(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC721WithOneFee: call must be a delegate call");

        (address[2] memory tokenGetAndFeeRecipient, uint256[2] memory priceAndFee) = abi.decode(extra, (address[2], uint256[2]));

        require(priceAndFee[0] > 0,"ETHForERC721WithOneFee: ERC721 price must be larger than zero");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "ETHForERC721WithOneFee: countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);

        checkETHSideOneFeeWithOffset(addresses[4], tokenGetAndFeeRecipient[1], uints[0], priceAndFee[0], priceAndFee[1], data);

        return 1;
    }

    function ETHForAnyERC721WithTwoFees(bytes memory extra,
        address[7] memory addresses, AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata)
        public
        pure
        returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC721WithTwoFees: call must be a delegate call");

        (address[3] memory tokenGetAndFeeRecipient, uint256[3] memory priceAndFee) = abi.decode(extra, (address[3], uint256[3]));

        require(priceAndFee[0] > 0,"ETHForERC721WithTwoFees: ERC721 price must be larger than zero");
        require(addresses[5] == tokenGetAndFeeRecipient[0], "ETHForERC721WithTwoFees: countercall target must equal address of token to get");

        checkERC721SideForCollection(counterdata, addresses[4], addresses[1]);

        checkETHSideTwoFeesWithOffset(addresses[4], tokenGetAndFeeRecipient[1], tokenGetAndFeeRecipient[2], uints[0], priceAndFee[0], priceAndFee[1], priceAndFee[2], data);

        return 1;
    }

    function ERC1155ForETH(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC1155ForETH: call must be a direct call");

        (address[1] memory tokenGive, uint256[3] memory tokenIdAndNumeratorDenominator) = abi.decode(extra, (address[1], uint256[3]));

        require(tokenIdAndNumeratorDenominator[1] > 0, "ERC1155ForETH: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominator[2] > 0, "ERC1155ForETH: denominator must be larger than zero");

        require(addresses[2] == tokenGive[0], "ERC1155ForETH: call target must equal address of token to give");

        require(uints[0] == tokenIdAndNumeratorDenominator[2], "ERC1155ForETH: Price must be same");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(data);
        uint256 new_fill = SafeMath.add(uints[5], erc1155Amount);
        require(new_fill <= uints[1],"ERC1155ForETH: new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominator[1], uints[0]) == SafeMath.mul(tokenIdAndNumeratorDenominator[2], erc1155Amount), "ERC1155ForETH: wrong ratio");

        checkERC1155Side(data, addresses[1], addresses[4], tokenIdAndNumeratorDenominator[0], erc1155Amount);

        checkETHSideWithOffset(addresses[1], uints[0], tokenIdAndNumeratorDenominator[2], counterdata);

        return 1;
    }

    function ETHForERC1155(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC1155: call must be a delegate call");

        (address[1] memory tokenGet, uint256[3] memory tokenIdAndNumeratorDenominator) = abi.decode(extra, (address[1], uint256[3]));

        require(tokenIdAndNumeratorDenominator[1] > 0,"ETHForERC1155: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominator[2] > 0,"ETHForERC1155: denominator must be larger than zero");

        require(addresses[5] == tokenGet[0], "ETHForERC1155: call target must equal address of token to give");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(counterdata);
        uint256 new_fill = SafeMath.add(uints[5], uints[0]);
        require(new_fill <= uints[1],"ETHForERC1155: new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominator[1], erc1155Amount) == SafeMath.mul(tokenIdAndNumeratorDenominator[2], uints[0]), "ETHForERC1155: wrong ratio");

        checkERC1155Side(counterdata, addresses[4], addresses[1], tokenIdAndNumeratorDenominator[0], erc1155Amount);

        checkETHSideWithOffset(addresses[4], uints[0], tokenIdAndNumeratorDenominator[1], data);

        return 1;
    }

    function ERC1155ForETHWithOneFee(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC1155ForETHWithOneFee: call must be a direct call");

        (address[2] memory tokenGiveAndFeeRecipient, uint256[4] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[2], uint256[4]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "ERC1155ForETHWithOneFee: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "ERC1155ForETHWithOneFee: denominator must be larger than zero");

        // addresses[2] and addresses[5] are the address of WyvernAtomicizer. How to check it?
        // require(addresses[2] == tokenGiveAndFeeRecipient[0], "ERC1155ForETHWithOneFee: call target must equal address of token to give");

        require(uints[0] == (tokenIdAndNumeratorDenominatorAndFee[2] + tokenIdAndNumeratorDenominatorAndFee[3]), "ERC1155ForETHWithOneFee: Price must be same");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(data);
        uint256 new_fill = SafeMath.add(uints[5], erc1155Amount);
        require(new_fill <= uints[1],"ERC1155ForETHWithOneFee: new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1], uints[0]) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2] + tokenIdAndNumeratorDenominatorAndFee[3], erc1155Amount), "ERC1155ForETHWithOneFee: wrong ratio");

        checkERC1155Side(data, addresses[1], addresses[4], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideOneFeeWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], uints[0], tokenIdAndNumeratorDenominatorAndFee[2], tokenIdAndNumeratorDenominatorAndFee[3], counterdata);

        return 1;
    }

    function ETHForERC1155WithOneFee(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC1155WithOneFee: call must be a delegate call");

        (address[2] memory tokenGetAndFeeRecipient, uint256[4] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[2], uint256[4]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "ETHForERC1155WithOneFee: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "ETHForERC1155WithOneFee: denominator must be larger than zero");

        // addresses[2] is the address of WyvernAtomicizer. How to check it?
        // require(addresses[5] == tokenGetAndFeeRecipient[0], "ETHForERC1155WithOneFee: call target must equal address of token to give");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(counterdata);
        uint256 new_fill = SafeMath.add(uints[5], uints[0]);
        require(new_fill <= uints[1],"ETHForERC1155WithOneFee: new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1] + tokenIdAndNumeratorDenominatorAndFee[3], erc1155Amount) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2], uints[0]), "ETHForERC1155WithOneFee: wrong ratio");

        checkERC1155Side(counterdata, addresses[4], addresses[1], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideOneFeeWithOffset(addresses[4], tokenGetAndFeeRecipient[1], uints[0], tokenIdAndNumeratorDenominatorAndFee[1], tokenIdAndNumeratorDenominatorAndFee[3], data);

        return 1;
    }

    function ERC1155ForETHWithTwoFees(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.Call, "ERC1155ForETHWithTwoFees: call must be a direct call");

        (address[3] memory tokenGiveAndFeeRecipient, uint256[5] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[3], uint256[5]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "ERC1155ForETHWithTwoFees: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "ERC1155ForETHWithTwoFees: denominator must be larger than zero");

        // addresses[2] and addresses[5] are the address of WyvernAtomicizer. How to check it?
        // require(addresses[2] == tokenGiveAndFeeRecipient[0], "ERC1155ForETHWithOneFee: call target must equal address of token to give");

        uint256 totalAmount = tokenIdAndNumeratorDenominatorAndFee[2] + tokenIdAndNumeratorDenominatorAndFee[3] + tokenIdAndNumeratorDenominatorAndFee[4];
        require(uints[0] == totalAmount, "ERC1155ForETHWithTwoFees: Price must be same");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(data);
        uint256 new_fill = SafeMath.add(uints[5], erc1155Amount);
        require(new_fill <= uints[1],"ERC1155ForETHWithTwoFees: new fill exceeds maximum fill");
        require(SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[1], uints[0]) == SafeMath.mul(totalAmount, erc1155Amount), "ERC1155ForETHWithTwoFees: wrong ratio");

        checkERC1155Side(data, addresses[1], addresses[4], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideTwoFeesWithOffset(addresses[1], tokenGiveAndFeeRecipient[1], tokenGiveAndFeeRecipient[2], uints[0], tokenIdAndNumeratorDenominatorAndFee[2], tokenIdAndNumeratorDenominatorAndFee[3], tokenIdAndNumeratorDenominatorAndFee[4], counterdata);

        return 1;
    }

    function ETHForERC1155WithTwoFees(bytes memory extra, address[7] memory addresses,
        AuthenticatedProxy.HowToCall[2] memory howToCalls, uint[6] memory uints,
        bytes memory data, bytes memory counterdata) public pure returns (uint)
    {
        require(howToCalls[0] == AuthenticatedProxy.HowToCall.DelegateCall, "ETHForERC1155WithTwoFees: call must be a delegate call");

        (address[3] memory tokenGetAndFeeRecipient, uint256[5] memory tokenIdAndNumeratorDenominatorAndFee) = abi.decode(extra, (address[3], uint256[5]));

        require(tokenIdAndNumeratorDenominatorAndFee[1] > 0, "ETHForERC1155WithTwoFees: numerator must be larger than zero");
        require(tokenIdAndNumeratorDenominatorAndFee[2] > 0, "ETHForERC1155WithTwoFees: denominator must be larger than zero");

        // addresses[2] is the address of WyvernAtomicizer. How to check it?
        // require(addresses[5] == tokenGetAndFeeRecipient[0], "ETHForERC1155WithTwoFees: call target must equal address of token to give");

        uint256 erc1155Amount = getERC1155AmountFromCalldata(counterdata);
        uint256 new_fill = SafeMath.add(uints[5], uints[0]);
        require(new_fill <= uints[1],"ETHForERC1155WithTwoFees: new fill exceeds maximum fill");
        uint totalAmount = tokenIdAndNumeratorDenominatorAndFee[1] + tokenIdAndNumeratorDenominatorAndFee[3] + tokenIdAndNumeratorDenominatorAndFee[4];
        require(SafeMath.mul(totalAmount, erc1155Amount) == SafeMath.mul(tokenIdAndNumeratorDenominatorAndFee[2], uints[0]), "ETHForERC1155WithTwoFees: wrong ratio");

        checkERC1155Side(counterdata, addresses[4], addresses[1], tokenIdAndNumeratorDenominatorAndFee[0], erc1155Amount);

        checkETHSideTwoFeesWithOffset(addresses[4], tokenGetAndFeeRecipient[1], tokenGetAndFeeRecipient[2], uints[0], tokenIdAndNumeratorDenominatorAndFee[1], tokenIdAndNumeratorDenominatorAndFee[3], tokenIdAndNumeratorDenominatorAndFee[4], data);

        return 1;
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

pragma solidity 0.7.5;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() virtual public view returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() virtual public pure returns (uint256 proxyTypeId);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback () external payable {
        address _impl = implementation();
        require(_impl != address(0), "Proxy implementation required");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

pragma solidity 0.7.5;

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract OwnedUpgradeabilityStorage {

    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

pragma solidity 0.7.5;

import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() override public view returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId Proxy type, 2 for forwarding proxy
     */
    function proxyType() override public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementation) internal {
        require(_implementation != implementation, "Proxy already uses this implementation");
        _implementation = implementation;
        emit Upgraded(implementation);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Only the proxy owner can call this method");
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(implementation);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Call failed after proxy upgrade");
    }
}

/*

  Token recipient. Modified very slightly from the example on http://ethereum.org/dao (just to index log parameters).

*/

pragma solidity 0.7.5;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/**
 * @title TokenRecipient
 * @author Wyvern Protocol Developers
 */
contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes memory extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, address(this), value), "ERC20 token transfer failed");
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback () payable external {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

/*

  Proxy registry interface.

*/

pragma solidity 0.7.5;

import "./OwnableDelegateProxy.sol";

/**
 * @title ProxyRegistryInterface
 * @author Wyvern Protocol Developers
 */
interface ProxyRegistryInterface {

    function delegateProxyImplementation() external returns (address);

    function proxies(address owner) external returns (OwnableDelegateProxy);

}

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.

  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/

pragma solidity 0.7.5;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";
import "./ProxyRegistryInterface.sol";

/**
 * @title ProxyRegistry
 * @author Wyvern Protocol Developers
 */
contract ProxyRegistry is Ownable, ProxyRegistryInterface {

    /* DelegateProxy implementation contract. Must be initialized. */
    address public override delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public override proxies;

    /* Contracts pending access. */
    mapping(address => uint) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the Wyvern DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the Wyvern and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint public DELAY_PERIOD = 2 weeks;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0, "Contract is already allowed in registry, or pending");
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to enable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
        public
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < block.timestamp), "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */
    function revokeAuthentication (address addr)
        public
        onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy()
        public
        returns (OwnableDelegateProxy proxy)
    {
        return registerProxyFor(msg.sender);
    }

    /**
     * Register a proxy contract with this registry, overriding any existing proxy
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyOverride()
        public
        returns (OwnableDelegateProxy proxy)
    {
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Can be called by any user
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyFor(address user)
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[user] == OwnableDelegateProxy(0), "User already has a proxy");
        proxy = new OwnableDelegateProxy(user, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", user, address(this)));
        proxies[user] = proxy;
        return proxy;
    }

    /**
     * Register multiple proxies contract with this registry
     *
     * @dev Can be called by any user
     * @return userProxies New AuthenticatedProxy contracts
     */
    function registerProxyForMultiple(address[] calldata users)
        external
        returns (OwnableDelegateProxy[] memory)
    {
        OwnableDelegateProxy[] memory userProxies = new OwnableDelegateProxy[](users.length);
        for (uint i = 0; i < users.length; i++) {
            require(proxies[users[i]] == OwnableDelegateProxy(0), "User already has a proxy");
            OwnableDelegateProxy proxy = new OwnableDelegateProxy(users[i], delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", users[i], address(this)));
            proxies[users[i]] = proxy;
            userProxies[i] = proxy;
        }
        return userProxies;
    }

    /**
     * Transfer access
     */
    function transferAccessTo(address from, address to)
        public
    {
        OwnableDelegateProxy proxy = proxies[from];

        /* CHECKS */
        require(OwnableDelegateProxy(msg.sender) == proxy, "Proxy transfer can only be called by the proxy");
        require(proxies[to] == OwnableDelegateProxy(0), "Proxy transfer has existing proxy as destination");

        /* EFFECTS */
        delete proxies[from];
        proxies[to] = proxy;
    }

}

/*

  OwnableDelegateProxy

*/

pragma solidity 0.7.5;

import "./proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author Wyvern Protocol Developers
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data)
        public
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }

}

/*

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

pragma solidity 0.7.5;

import "./ProxyRegistry.sol";
import "./TokenRecipient.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";

/**
 * @title AuthenticatedProxy
 * @author Wyvern Protocol Developers
 */
contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize (address addrUser, ProxyRegistry addrRegistry)
        public
    {
        require(!initialized, "Authenticated proxy already initialized");
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
        public
    {
        require(msg.sender == user, "Authenticated proxy can only be revoked by its user");
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes memory data)
        public payable
        returns (bool result)
    {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)), "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access");
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param data Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes memory data)
        public
    {
        require(proxy(dest, howToCall, data), "Proxy assertion failed");
    }

}

/*

  << ArrayUtils >>

  Various functions for manipulating arrays in Solidity.
  This library is completely inlined and does not need to be deployed or linked.

*/

pragma solidity 0.7.5;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title ArrayUtils
 * @author Wyvern Protocol Developers
 */
library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     * Modifies the provided byte array parameter in place
     * 
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        internal
        pure
    {
        require(array.length == desired.length, "Arrays have different lengths");
        require(array.length == mask.length, "Array and mask have different lengths");

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     * 
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Drop the beginning of an array
     *
     * @param _bytes array
     * @param _start start index
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayDrop(bytes memory _bytes, uint _start)
        internal
        pure
        returns (bytes memory)
    {

        uint _length = SafeMath.sub(_bytes.length, _start);
        return arraySlice(_bytes, _start, _length);
    }

    /**
     * Take from the beginning of an array
     *
     * @param _bytes array
     * @param _length elements to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayTake(bytes memory _bytes, uint _length)
        internal
        pure
        returns (bytes memory)
    {

        return arraySlice(_bytes, 0, _length);
    }

    /**
     * Slice an array
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @param _bytes array
     * @param _start start index
     * @param _length length to take
     * @return Whether or not all bytes in the arrays are equal
     */
    function arraySlice(bytes memory _bytes, uint _start, uint _length)
        internal
        pure
        returns (bytes memory)
    {

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal
        pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint(source) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

}

/*

  << Static Market contract >>

*/

import "./lib/ArrayUtils.sol";

pragma solidity 0.7.5;

contract StaticMarketBase {
    function checkERC20Side(bytes memory data, address from, address to, uint256 amount)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)));
    }

    function checkERC20SideWithOneFee(bytes memory data, address from, address to, address feeRecipient, uint256 amount, uint256 fee)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 356, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)));
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 516, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, feeRecipient, fee)));
    }

    function checkERC20SideWithTwoFees(bytes memory data, address from, address to, address feeRecipient, address royaltyFeeRecipient, uint256 amount, uint256 fee, uint256 royaltyFee)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 452, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)));
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 612, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, feeRecipient, fee)));
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 772, 100), abi.encodeWithSignature("transferFrom(address,address,uint256)", from, royaltyFeeRecipient, royaltyFee)));
    }

    function checkERC721Side(bytes memory data, address from, address to, uint256 tokenId)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId)));
    }

    function checkERC721SideForCollection(bytes memory data, address from, address to)
        internal
        pure
    {
        (uint256 tokenId) = abi.decode(ArrayUtils.arraySlice(data, 68, 32), (uint256));
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId)));
    }

    function getERC1155AmountFromCalldata(bytes memory data)
        internal
        pure
        returns (uint256)
    {
        (uint256 amount) = abi.decode(ArrayUtils.arraySlice(data, 100, 32), (uint256));
        return amount;
    }

    function checkERC1155Side(bytes memory data, address from, address to, uint256 tokenId, uint256 amount)
        internal
        pure
    {
        require(ArrayUtils.arrayEq(data, abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", from, to, tokenId, amount, "")));
    }

    function extractInfoFromData(bytes memory data) internal pure returns (address[] memory, bytes[] memory) {
        (address[] memory addrs, uint256[] memory values, uint256[] memory calldataLengths, bytes memory calldatas) = abi.decode(ArrayUtils.arrayDrop(data, 4), (address[], uint256[], uint256[], bytes));

        require(addrs.length == values.length && addrs.length == calldataLengths.length, "extractInfoFromData: Addresses, calldata lengths, and values must match in quantity");

        bytes[] memory allBytes = new bytes[](addrs.length);

        uint start = 0;
        for (uint i = 0; i < addrs.length; i++) {
            if (i == 1) {
                start = calldataLengths[i - 1];
            } else if (i > 1) {
                start += calldataLengths[i];
            }

            allBytes[i] = ArrayUtils.arraySlice(calldatas, start, calldataLengths[i]);
        }
        return (addrs, allBytes);
    }

    function checkETHSideWithOffset(address to, uint256 value, uint price, bytes memory data) internal pure {
        require(value >= price, "checkETHSideWithOffset: msg.value must not less than price");
        address[] memory addrs = new address[](1);
        addrs[0] = to;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = price;
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 132, 196), abi.encodeWithSignature("transferETH(address[],uint256[])", addrs, amounts)));
    }

    function checkETHSideOneFeeWithOffset(address to, address feeRecipient, uint256 value, uint price, uint fee, bytes memory data) internal pure {
        require(value >= price + fee, "checkETHSideOneFeeWithOffset: msg.value must not less than price");
        address[] memory addrs = new address[](2);
        addrs[0] = to;
        addrs[1] = feeRecipient;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = price;
        amounts[1] = fee;
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 132, 260), abi.encodeWithSignature("transferETH(address[],uint256[])", addrs, amounts)));
    }

    function checkETHSideTwoFeesWithOffset(address to, address feeRecipient, address royaltyFeeRecipient, uint256 value, uint price, uint fee, uint royaltyFee, bytes memory data) internal pure {
        require(value >= price + fee + royaltyFee, "checkETHSideTwoFeesWithOffset: msg.value must not less than price");
        address[] memory addrs = new address[](3);
        addrs[0] = to;
        addrs[1] = feeRecipient;
        addrs[2] = royaltyFeeRecipient;
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = price;
        amounts[1] = fee;
        amounts[2] = royaltyFee;
        require(ArrayUtils.arrayEq(ArrayUtils.arraySlice(data, 132, 324), abi.encodeWithSignature("transferETH(address[],uint256[])", addrs, amounts)));
    }
}