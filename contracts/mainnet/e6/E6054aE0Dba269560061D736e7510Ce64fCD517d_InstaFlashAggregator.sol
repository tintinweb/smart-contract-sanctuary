//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Flashloan.
 * @dev Flashloan aggregator.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { Helper } from "./helpers.sol";

import { 
    TokenInterface,
    CTokenInterface,
    InstaFlashReceiverInterface
} from "./interfaces.sol";

contract Setups is Helper {
    using SafeERC20 for IERC20;

    /**
     * @dev Add to token to cToken mapping.
     * @notice Add to token to cToken mapping.
     * @param _cTokens list of cToken addresses to be added to the mapping.
    */
    function addTokenToCToken(address[] memory _cTokens) public {
        for (uint i = 0; i < _cTokens.length; i++) {
            (bool isMarket_,,) = troller.markets(_cTokens[i]);
            require(isMarket_, "unvalid-ctoken");
            address token_ = CTokenInterface(_cTokens[i]).underlying();
            require(tokenToCToken[token_] == address((0)), "already-added");
            tokenToCToken[token_] = _cTokens[i];
            IERC20(token_).safeApprove(_cTokens[i], type(uint256).max);
        }
    }
}

contract FlashAggregator is Setups {
    using SafeERC20 for IERC20;

    event LogFlashloan(
        address indexed account,
        uint256 indexed route,
        address[] tokens,
        uint256[] amounts
    );
    
    /**
     * @dev Callback function for aave flashloan.
     * @notice Callback function for aave flashloan.
     * @param _assets list of asset addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets for flashloan.
     * @param _premiums list of premiums/fees for the corresponding addresses for flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _data extra data passed.
    */
    function executeOperation(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _premiums,
        address _initiator,
        bytes memory _data
    ) external verifyDataHash(_data) returns (bool) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == aaveLendingAddr, "not-aave-sender");

        FlashloanVariables memory instaLoanVariables_;

        (address sender_, bytes memory data_) = abi.decode(
            _data,
            (address, bytes)
        );

        instaLoanVariables_._tokens = _assets;
        instaLoanVariables_._amounts = _amounts;
        instaLoanVariables_._instaFees = calculateFees(_amounts, calculateFeeBPS(1));
        instaLoanVariables_._iniBals = calculateBalances(_assets, address(this));

        safeApprove(instaLoanVariables_, _premiums, aaveLendingAddr);
        safeTransfer(instaLoanVariables_, sender_);

        if (checkIfDsa(msg.sender)) {
            Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
        } else {
            InstaFlashReceiverInterface(sender_).executeOperation(_assets, _amounts, instaLoanVariables_._instaFees, sender_, data_);
        }

        instaLoanVariables_._finBals = calculateBalances(_assets, address(this));
        validateFlashloan(instaLoanVariables_);

        return true;
    }
    
    /**
     * @dev Fallback function for makerdao flashloan.
     * @notice Fallback function for makerdao flashloan.
     * @param _initiator initiator address for flashloan.
     * @param _amount DAI amount for flashloan.
     * @param _fee fee for the flashloan.
     * @param _data extra data passed(includes route info aswell).
    */
    function onFlashLoan(
        address _initiator,
        address,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external verifyDataHash(_data) returns (bytes32) {
        require(_initiator == address(this), "not-same-sender");
        require(msg.sender == makerLendingAddr, "not-maker-sender");

        FlashloanVariables memory instaLoanVariables_;

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(tokens_, address(this));
        instaLoanVariables_._instaFees = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 2) {
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }
            
        } else if (route_ == 3 || route_ == 4) {
            require(_fee == 0, "flash-DAI-fee-not-0");
            if (route_ == 3) {
                compoundSupply(daiToken, _amount);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(daiToken, _amount);
                aaveBorrow(tokens_, amounts_);
            }
            
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (route_ == 3) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(daiToken, _amount);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(daiToken, _amount);
            }
        } else {
            require(false, "wrong-route");
        }

        instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
        validateFlashloan(instaLoanVariables_);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /**
     * @dev Fallback function for balancer flashloan.
     * @notice Fallback function for balancer flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _fees list of fees for the corresponding addresses for flashloan.
     * @param _data extra data passed(includes route info aswell).
    */
    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory _amounts,
        uint256[] memory _fees,
        bytes memory _data
    ) external verifyDataHash(_data) {
        require(msg.sender == balancerLendingAddr, "not-aave-sender");

        FlashloanVariables memory instaLoanVariables_;

        (uint route_, address[] memory tokens_, uint256[] memory amounts_, address sender_, bytes memory data_) = abi.decode(
            _data,
            (uint, address[], uint256[], address, bytes)
        );

        instaLoanVariables_._tokens = tokens_;
        instaLoanVariables_._amounts = amounts_;
        instaLoanVariables_._iniBals = calculateBalances(tokens_, address(this));
        instaLoanVariables_._instaFees = calculateFees(amounts_, calculateFeeBPS(route_));

        if (route_ == 5) {
            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
        } else if (route_ == 6 || route_ == 7) {
            require(_fees[0] == 0, "flash-ETH-fee-not-0");
            if (route_ == 6) {
                compoundSupply(wEthToken, _amounts[0]);
                compoundBorrow(tokens_, amounts_);
            } else {
                aaveSupply(wEthToken, _amounts[0]);
                aaveBorrow(tokens_, amounts_);
            }

            safeTransfer(instaLoanVariables_, sender_);

            if (checkIfDsa(msg.sender)) {
                Address.functionCall(sender_, data_, "DSA-flashloan-fallback-failed");
            } else {
                InstaFlashReceiverInterface(sender_).executeOperation(tokens_, amounts_, instaLoanVariables_._instaFees, sender_, data_);
            }

            if (route_ == 6) {
                compoundPayback(tokens_, amounts_);
                compoundWithdraw(wEthToken, _amounts[0]);
            } else {
                aavePayback(tokens_, amounts_);
                aaveWithdraw(wEthToken, _amounts[0]);
            }
            instaLoanVariables_._finBals = calculateBalances(tokens_, address(this));
            validateFlashloan(instaLoanVariables_);
            instaLoanVariables_._amounts = _amounts;
            instaLoanVariables_._tokens = new address[](1);
            instaLoanVariables_._tokens[0] = wEthToken;
            safeTransferWithFee(instaLoanVariables_, _fees, balancerLendingAddr);
        } else {
            require(false, "wrong-route");
        }
    }

    /**
     * @dev Middle function for route 1.
     * @notice Middle function for route 1.
     * @param _tokens list of token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets or amount of ether to borrow as collateral for flashloan.
     * @param _data extra data passed.
    */
    function routeAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(msg.sender, _data);
        uint length_ = _tokens.length;
        uint[] memory _modes = new uint[](length_);
        for (uint i = 0; i < length_; i++) {
            _modes[i]=0;
        }
        dataHash = bytes32(keccak256(data_));
        aaveLending.flashLoan(address(this), _tokens, _amounts, _modes, address(0), data_, 3228);
    }

    /**
     * @dev Middle function for route 2.
     * @notice Middle function for route 2.
     * @param _token token address for flashloan(DAI).
     * @param _amount DAI amount for flashloan.
     * @param _data extra data passed.
    */
    function routeMaker(address _token, uint256 _amount, bytes memory _data) internal {
        address[] memory tokens_ = new address[](1);
        uint256[] memory amounts_ = new uint256[](1);
        tokens_[0] = _token;
        amounts_[0] = _amount;
        bytes memory data_ = abi.encode(2, tokens_, amounts_, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), _token, _amount, data_);
    }

    /**
     * @dev Middle function for route 3.
     * @notice Middle function for route 3.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeMakerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(3, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }
    
    /**
     * @dev Middle function for route 4.
     * @notice Middle function for route 4.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeMakerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(4, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        makerLending.flashLoan(InstaFlashReceiverInterface(address(this)), daiToken, daiBorrowAmount, data_);
    }

    /**
     * @dev Middle function for route 5.
     * @notice Middle function for route 5.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeBalancer(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        uint256 length_ = _tokens.length;
        IERC20[] memory tokens_ = new IERC20[](length_);
        for(uint256 i = 0 ; i < length_ ; i++) {
            tokens_[i] = IERC20(_tokens[i]);
        }
        bytes memory data_ = abi.encode(5, _tokens, _amounts, msg.sender, _data);
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), tokens_, _amounts, data_);
    }

    /**
     * @dev Middle function for route 6.
     * @notice Middle function for route 6.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeBalancerCompound(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(6, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
    }
    
    /**
     * @dev Middle function for route 7.
     * @notice Middle function for route 7.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _data extra data passed.
    */
    function routeBalancerAave(address[] memory _tokens, uint256[] memory _amounts, bytes memory _data) internal {
        bytes memory data_ = abi.encode(7, _tokens, _amounts, msg.sender, _data);
        IERC20[] memory wethTokenList_ = new IERC20[](1);
        uint256[] memory wethAmountList_ = new uint256[](1);
        wethTokenList_[0] = IERC20(wEthToken);
        wethAmountList_[0] = getWEthBorrowAmount();
        dataHash = bytes32(keccak256(data_));
        balancerLending.flashLoan(InstaFlashReceiverInterface(address(this)), wethTokenList_, wethAmountList_, data_);
    }

    /**
     * @dev Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @notice Main function for flashloan for all routes. Calls the middle functions according to routes.
     * @param _tokens token addresses for flashloan.
     * @param _amounts list of amounts for the corresponding assets.
     * @param _route route for flashloan.
     * @param _data extra data passed.
    */
    function flashLoan(	
        address[] memory _tokens,	
        uint256[] memory _amounts,
        uint256 _route,
        bytes calldata _data,
        bytes calldata // added this as we might need some extra data to decide route in future cases. Not using it anywhere at the moment.
    ) external reentrancy {

        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);

        if (_route == 1) {
            routeAave(_tokens, _amounts, _data);	
        } else if (_route == 2) {
            routeMaker(_tokens[0], _amounts[0], _data);	
        } else if (_route == 3) {
            routeMakerCompound(_tokens, _amounts, _data);
        } else if (_route == 4) {
            routeMakerAave(_tokens, _amounts, _data);
        } else if (_route == 5) {
            routeBalancer(_tokens, _amounts, _data);
        } else if (_route == 6) {
            routeBalancerCompound(_tokens, _amounts, _data);
        } else if (_route == 7) {
            routeBalancerAave(_tokens, _amounts, _data);
        } else {
            require(false, "route-does-not-exist");
        }
        
        emit LogFlashloan(
            msg.sender,
            _route,
            _tokens,
            _amounts
        );
    }

    /**
     * @dev Function to get the list of available routes.
     * @notice Function to get the list of available routes.
    */
    function getRoutes() public pure returns (uint16[] memory routes_) {
        routes_ = new uint16[](7);
        routes_[0] = 1;
        routes_[1] = 2;
        routes_[2] = 3;
        routes_[3] = 4;
        routes_[4] = 5;
        routes_[5] = 6;
        routes_[6] = 7;
    }

    /**
     * @dev Function to transfer fee to the treasury.
     * @notice Function to transfer fee to the treasury. Will be called manually.
     * @param _tokens token addresses for transferring fee to treasury.
    */
    function transferFeeToTreasury(address[] memory _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            uint decimals_ = TokenInterface(_tokens[i]).decimals();
            uint amtToSub_ = decimals_ == 18 ? 1e10 : decimals_ > 12 ? 10000 : decimals_ > 7 ? 100 : 10;
            uint amtToTransfer_ = token_.balanceOf(address(this)) > amtToSub_ ? (token_.balanceOf(address(this)) - amtToSub_) : 0;
            if (amtToTransfer_ > 0) token_.safeTransfer(treasuryAddr, amtToTransfer_);
        }
    }
}

contract InstaFlashAggregator is FlashAggregator {
    using SafeERC20 for IERC20;

    function initialize(address[] memory _ctokens) public {
        require(status == 0, "cannot-call-again");
        IERC20(daiToken).safeApprove(makerLendingAddr, type(uint256).max);
        addTokenToCToken(_ctokens);
        status = 1;
    }

    receive() external payable {}

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Variables} from "./variables.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
    TokenInterface,
    CTokenInterface,
    CEthInterface
} from "./interfaces.sol";

contract Helper is Variables {
    using SafeERC20 for IERC20;

    /**
     * @dev Approves the tokens to the receiver address with allowance (amount + fee).
     * @notice Approves the tokens to the receiver address with allowance (amount + fee).
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _fees list of premiums/fees for the corresponding addresses for flashloan.
     * @param _receiver address to which tokens have to be approved.
    */
    function safeApprove(
        FlashloanVariables memory _instaLoanVariables,
        uint256[] memory _fees,
        address _receiver
    ) internal {
        require(_instaLoanVariables._tokens.length == _instaLoanVariables._amounts.length, "Lengths of parameters not same");
        require(_instaLoanVariables._tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length_ = _instaLoanVariables._tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeApprove(_receiver, _instaLoanVariables._amounts[i] + _fees[i]);
        }
    }

    /**
     * @dev Transfers the tokens to the receiver address.
     * @notice Transfers the tokens to the receiver address.
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _receiver address to which tokens have to be transferred.
    */
    function safeTransfer(
        FlashloanVariables memory _instaLoanVariables,
        address _receiver
    ) internal {
        require(_instaLoanVariables._tokens.length == _instaLoanVariables._amounts.length, "Lengths of parameters not same");
        uint256 length_ = _instaLoanVariables._tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(_receiver, _instaLoanVariables._amounts[i]);
        }
    }

    /**
     * @dev Transfers the tokens to the receiver address (amount + fee).
     * @notice Transfers the tokens to the receiver address (amount + fee).
     * @param _instaLoanVariables struct which includes list of token addresses and amounts.
     * @param _fees list of fees for the respective tokens.
     * @param _receiver address to which tokens have to be transferred.
    */
    function safeTransferWithFee(
        FlashloanVariables memory _instaLoanVariables,
        uint256[] memory _fees,
        address _receiver
    ) internal {
        require(_instaLoanVariables._tokens.length == _instaLoanVariables._amounts.length, "Lengths of parameters not same");
        require(_instaLoanVariables._tokens.length == _fees.length, "Lengths of parameters not same");
        uint256 length_ = _instaLoanVariables._tokens.length;
        for (uint i = 0; i < length_; i++) {
            IERC20 token = IERC20(_instaLoanVariables._tokens[i]);
            token.safeTransfer(_receiver, _instaLoanVariables._amounts[i] + _fees[i]);
        }
    }

    /**
     * @dev Calculates the balances..
     * @notice Calculates the balances of the account passed for the tokens.
     * @param _tokens list of token addresses to calculate balance for.
     * @param _account account to calculate balance for.
    */
    function calculateBalances(
        address[] memory _tokens,
        address _account
    ) internal view returns (uint256[] memory) {
        uint256 _length = _tokens.length;
        uint256[] memory balances_ = new uint256[](_length);
        for (uint i = 0; i < _length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            balances_[i] = token.balanceOf(_account);
        }
        return balances_;
    }

    /**
     * @dev Validates if the receiver sent the correct amounts of funds.
     * @notice Validates if the receiver sent the correct amounts of funds.
     * @param _instaLoanVariables struct which includes list of initial balances, final balances and fees for the respective tokens.
    */
    function validateFlashloan(
        FlashloanVariables memory _instaLoanVariables
    ) internal pure {
        for (uint i = 0; i < _instaLoanVariables._iniBals.length; i++) {
            require(_instaLoanVariables._iniBals[i] + _instaLoanVariables._instaFees[i] <= _instaLoanVariables._finBals[i], "amount-paid-less");
        }
    }

    /**
     * @dev Validates if token addresses are unique. Just need to check adjacent tokens as the array was sorted first
     * @notice Validates if token addresses are unique.
     * @param _tokens list of token addresses.
    */
    function validateTokens(address[] memory _tokens) internal pure {
        for (uint i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i+1], "non-unique-tokens");
        }
    }

    /**
     * @dev Supply token for the amount to compound.
     * @notice Supply token for the amount to compound.
     * @param _token token addresses.
     * @param _amount amount of token.
    */
    function compoundSupply(address _token, uint256 _amount) internal {
        address[] memory cTokens_ = new address[](1);
        if (_token == wEthToken) {
            wEth.withdraw(_amount);
            CEthInterface cEth_ = CEthInterface(cEthToken);
            cEth_.mint{value: _amount}();
            cTokens_[0] = cEthToken;
        } else {
            CTokenInterface cToken_ = CTokenInterface(tokenToCToken[_token]);
            // Approved already in addTokenToctoken function
            require(cToken_.mint(_amount) == 0, "mint failed");
            cTokens_[0] = tokenToCToken[_token];
        }
        uint[] memory errors_ = troller.enterMarkets(cTokens_);
        for(uint i=0; i < errors_.length; i++){
            require(errors_[i] == 0, "Comptroller.enterMarkets failed.");
        }
    }

    /**
     * @dev Borrow tokens for the amounts to compound.
     * @notice Borrow tokens for the amounts to compound.
     * @param _tokens list of token addresses.
     * @param _amounts amounts of respective tokens.
    */
    function compoundBorrow(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            if (_tokens[i] == wEthToken) {
                CEthInterface cEth = CEthInterface(cEthToken);
                require(cEth.borrow(_amounts[i]) == 0, "borrow failed");
                wEth.deposit{value: _amounts[i]}();
            } else {
                CTokenInterface cToken = CTokenInterface(tokenToCToken[_tokens[i]]);
                require(cToken.borrow(_amounts[i]) == 0, "borrow failed");
            }
        }
    }

    /**
     * @dev Payback tokens for the amounts to compound.
     * @notice Payback tokens for the amounts to compound.
     * @param _tokens list of token addresses.
     * @param _amounts amounts of respective tokens.
    */
    function compoundPayback(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            if ( _tokens[i] == wEthToken ) {
                wEth.withdraw(_amounts[i]);
                CEthInterface cToken = CEthInterface(cEthToken);
                cToken.repayBorrow{value : _amounts[i]}();
            } else {
                CTokenInterface cToken = CTokenInterface(tokenToCToken[_tokens[i]]);
                // Approved already in addTokenToctoken function
                require(cToken.repayBorrow(_amounts[i]) == 0, "repay failed");
            }
        }
    }

    /**
     * @dev Withdraw token from compound.
     * @notice Withdraw token from compound.
     * @param _token token address.
     * @param _amount amount of token.
    */
    function compoundWithdraw(address _token, uint256 _amount) internal {
        if (_token == wEthToken) {
            CEthInterface cEth_ = CEthInterface(cEthToken);
            require(cEth_.redeemUnderlying(_amount) == 0, "redeem failed");
            wEth.deposit{value: _amount}();
        } else {
            CTokenInterface cToken_ = CTokenInterface(tokenToCToken[_token]);    
            require(cToken_.redeemUnderlying(_amount) == 0, "redeem failed");
        }
    }

    /**
     * @dev Supply token to aave.
     * @notice Supply token to aave.
     * @param _token token address.
     * @param _amount amount of token.
    */
    function aaveSupply(address _token, uint256 _amount) internal {
        IERC20 token_ = IERC20(_token);
        token_.safeApprove(aaveLendingAddr, _amount);
        aaveLending.deposit(_token, _amount, address(this), 3228);
        aaveLending.setUserUseReserveAsCollateral(_token, true);
    }

    /**
     * @dev Borrow tokens from aave.
     * @notice Borrow tokens from aave.
     * @param _tokens list of token addresses.
     * @param _amounts list of amounts for respective tokens.
    */
    function aaveBorrow(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length_ = _tokens.length;
        for(uint i=0; i < length_; i++) {
            aaveLending.borrow(_tokens[i], _amounts[i], 2, 3228, address(this));
        }
    }

    /**
     * @dev Payback tokens to aave.
     * @notice Payback tokens to aave.
     * @param _tokens list of token addresses.
     * @param _amounts list of amounts for respective tokens.
    */
    function aavePayback(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        uint256 length = _tokens.length;
        for(uint i=0; i < length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            token_.safeApprove(aaveLendingAddr, _amounts[i]);
            aaveLending.repay(_tokens[i], _amounts[i], 2, address(this));
        }
    }

    /**
     * @dev Withdraw token from aave.
     * @notice Wiothdraw token from aave.
     * @param _token token address.
     * @param _amount amount of token.
    */
    function aaveWithdraw(address _token, uint256 _amount) internal {
        aaveLending.withdraw(_token, _amount, address(this));
    }

    /**
     * @dev Returns fee for the passed route in BPS.
     * @notice Returns fee for the passed route in BPS. 1 BPS == 0.01%.
     * @param _route route number for flashloan.
    */
    function calculateFeeBPS(uint256 _route) public view returns (uint256 BPS_) {
        if (_route == 1) {
            BPS_ = aaveLending.FLASHLOAN_PREMIUM_TOTAL();
        } else if (_route == 2 || _route == 3 || _route == 4) {
            BPS_ = (makerLending.toll()) / (10 ** 14);
        } else if (_route == 5 || _route == 6 || _route == 7) {
            BPS_ = (balancerLending.getProtocolFeesCollector().getFlashLoanFeePercentage()) * 100;
        } else {
            require(false, "Invalid source");
        }
        
        if (BPS_ < InstaFeeBPS) {
            BPS_ = InstaFeeBPS;
        }
    }

    /**
     * @dev Calculate fees for the respective amounts and fee in BPS passed.
     * @notice Calculate fees for the respective amounts and fee in BPS passed. 1 BPS == 0.01%.
     * @param _amounts list of amounts.
     * @param _BPS fee in BPS.
    */
    function calculateFees(uint256[] memory _amounts, uint256 _BPS) internal pure returns (uint256[] memory) {
        uint256 length_ = _amounts.length;
        uint256[] memory InstaFees = new uint256[](length_);
        for (uint i = 0; i < length_; i++) {
            InstaFees[i] = (_amounts[i] * _BPS) / (10 ** 4);
        }
        return InstaFees;
    }

    /**
     * @dev Sort the tokens and amounts arrays according to token addresses.
     * @notice Sort the tokens and amounts arrays according to token addresses.
     * @param _tokens list of token addresses.
     * @param _amounts list of respective amounts.
    */
    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts) internal pure returns (address[] memory, uint256[] memory) {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for( uint256 j = 0; j < _tokens.length - i - 1 ; j++) {
                if(_tokens[j] > _tokens[j+1]) {
                   (_tokens[j], _tokens[j+1], _amounts[j], _amounts[j+1]) = (_tokens[j+1], _tokens[j], _amounts[j+1], _amounts[j]);
                }
            }
        }
        return (_tokens, _amounts);
    }

    /**
     * @dev Returns to wEth amount to be borrowed.
     * @notice Returns to wEth amount to be borrowed.
    */
    function getWEthBorrowAmount() internal view returns (uint256) {
        uint256 amount_ = wEth.balanceOf(balancerLendingAddr);
        return (amount_ * wethBorrowAmountPercentage) / 100;
    }
    
    /**
     * @dev Returns to true if the passed address is a DSA else returns false.
     * @notice Returns to true if the passed address is a DSA else returns false.
     * @param _account account to check for, if DSA.
    */
    function checkIfDsa(address _account) internal view returns (bool) {
        return instaList.accountID(_account) > 0;
    }

    /**
     * @dev  better checking by double encoding the data.
     * @notice better checking by double encoding the data.
     * @param data_ data passed.
    */
    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == dataHash && dataHash_ != bytes32(0), "invalid-data-hash");
        require(status == 2, "already-entered");
        dataHash = bytes32(0);
        _;
        status = 1;
    }

    /**
     * @dev reentrancy gaurd.
     * @notice reentrancy gaurd.
    */
    modifier reentrancy {
        require(status == 1, "already-entered");
        status = 2;
        _;
        require(status == 1, "already-entered");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface InstaFlashReceiverInterface {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata _data
    ) external returns (bool);
}

interface IndexInterface {
    function master() external view returns (address);

    function list() external view returns (address);
}

interface ListInterface {
    function accountID(address) external view returns (uint64);
}

interface TokenInterface is IERC20 {
    function decimals() external view returns (uint256);
}

interface CTokenInterface {
    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function underlying() external view returns (address);
}

interface CEthInterface {
    function mint() external payable;

    function redeemUnderlying(uint) external returns (uint);

    function borrow(uint) external returns (uint);

    function repayBorrow() external payable;
}

interface IWeth is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface Comptroller {
    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);
    function markets(address) external view returns (bool, uint, bool);
    function getAllMarkets() external view returns (CTokenInterface[] memory);
}

interface IAaveLending {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external;

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;
}

interface IERC3156FlashLender {
    function maxFlashLoan(address token) external view returns (uint256);

    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);

    function flashLoan(
        InstaFlashReceiverInterface receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function toll() external view returns (uint256);
}

interface ProtocolFeesCollector {
    function getFlashLoanFeePercentage() external view returns (uint256);
}

interface IBalancerLending {
    function flashLoan(
        InstaFlashReceiverInterface recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
    function getProtocolFeesCollector() external view returns (ProtocolFeesCollector);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    IndexInterface,
    ListInterface,
    TokenInterface,
    IAaveLending,
    IERC3156FlashLender, 
    Comptroller,
    IBalancerLending,
    IWeth
} from "./interfaces.sol";

contract ConstantVariables {

    address public constant wEthToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWeth public constant wEth = IWeth(wEthToken);

    address public constant aaveLendingAddr = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    IAaveLending public constant aaveLending = IAaveLending(aaveLendingAddr);

    address public constant makerLendingAddr = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;
    IERC3156FlashLender public constant makerLending = IERC3156FlashLender(makerLendingAddr);

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    IBalancerLending public constant balancerLending = IBalancerLending(balancerLendingAddr);

    address public constant daiToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant cDaiToken = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    uint256 public constant daiBorrowAmount = 500000000000000000000000000;

    address public constant cEthToken = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    uint256 public constant wethBorrowAmountPercentage = 80;

    address public constant comptrollerAddr = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    Comptroller public constant troller = Comptroller(comptrollerAddr);

    address public constant treasuryAddr = 0x28849D2b63fA8D361e5fc15cB8aBB13019884d09;
    address private constant instaListAddr = 0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb;
    ListInterface public constant instaList = ListInterface(instaListAddr);

    uint256 public constant InstaFeeBPS = 5; // in BPS; 1 BPS = 0.01%

}

contract Variables is ConstantVariables{

    bytes32 internal dataHash;
    // if 1 then can enter flashlaon, if 2 then callback
    uint internal status;

    struct FlashloanVariables {
        address[] _tokens;
        uint256[] _amounts;
        uint256[] _iniBals;
        uint256[] _finBals;
        uint256[] _instaFees;
    }

    mapping(address => address) public tokenToCToken;

}