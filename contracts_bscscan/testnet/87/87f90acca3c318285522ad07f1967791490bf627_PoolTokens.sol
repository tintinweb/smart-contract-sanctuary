/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IPoolTokens {
    struct HopsRoute {
        address[] path;
        bool enable;
    }

    function getAcceptedTokens() external view returns (address[] memory);

    function getAllowedTokens() external view returns (address[] memory);

    function countAcceptedTokens() external view returns (uint256);

    function countAllowedTokens() external view returns (uint256);

    function hasAcceptedToken(address token) external view returns (bool);

    function hasAllowedToken(address token) external view returns (bool);

    function getRouteHop(address src, address dest)
        external
        view
        returns (HopsRoute[] memory);
}

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
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

contract PoolTokens is IPoolTokens, Ownable {
    using Address for address;

    mapping(address => mapping(address => HopsRoute[])) tokenHops;

    struct TokenSetting {
        bool added;
        bool isAccepted; // for accepted/deposit
        bool isAllowed; // for holding
    }

    mapping(address => TokenSetting) tokens;
    address[] tokensAddress;

    uint256 _countAcceptedTokens;
    uint256 _countAllowedTokens;

    function getAcceptedTokens()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory _tokens = new address[](_countAcceptedTokens);
        uint256 j = 0;
        for (uint256 i = 0; i < tokensAddress.length; i++) {
            if (_hasAcceptedToken(tokensAddress[i])) {
                _tokens[j] = tokensAddress[i];
                j++;
            }
        }
        return _tokens;
    }

    function getAllowedTokens()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory _tokens = new address[](_countAllowedTokens);
        uint256 j = 0;
        for (uint256 i = 0; i < tokensAddress.length; i++) {
            if (_hasAllowedToken(tokensAddress[i])) {
                _tokens[j] = tokensAddress[i];
                j++;
            }
        }
        return _tokens;
    }

    function countAcceptedTokens() external view override returns (uint256) {
        return _countAcceptedTokens;
    }

    function countAllowedTokens() external view override returns (uint256) {
        return _countAllowedTokens;
    }

    function hasAcceptedToken(address token)
        external
        view
        override
        returns (bool)
    {
        return _hasAcceptedToken(token);
    }

    function hasAllowedToken(address token)
        external
        view
        override
        returns (bool)
    {
        return _hasAllowedToken(token);
    }

    function addToken(
        address token,
        bool isAccepted,
        bool isAllowed
    ) public onlyOwner {
        require(tokens[token].added == false, "PoolTokens: exist token");

        tokens[token].added = true;
        tokens[token].isAccepted = isAccepted;
        tokens[token].isAllowed = isAllowed;
        (true, isAccepted, isAllowed);
        if (isAccepted == true) {
            _countAcceptedTokens += 1;
        }
        if (isAllowed == true) {
            _countAllowedTokens += 1;
        }
        tokensAddress.push(token);
    }

    function updateToken(
        address token,
        bool isAccepted,
        bool isAllowed
    ) public onlyOwner {
        require(tokens[token].added == true, "PoolTokens: token not exist");
        if (tokens[token].isAccepted != isAccepted) {
            _countAcceptedTokens = isAccepted == true
                ? _countAcceptedTokens + 1
                : _countAcceptedTokens - 1;
            tokens[token].isAccepted = isAccepted;
        }

        if (tokens[token].isAllowed != isAllowed) {
            _countAllowedTokens = isAllowed == true
                ? _countAllowedTokens + 1
                : _countAllowedTokens - 1;
            tokens[token].isAllowed = isAllowed;
        }
    }

    function addRouteHop(
        address src,
        address dest,
        address[] memory hops
    ) public onlyOwner {
        HopsRoute memory hopRoute;
        hopRoute.path = hops;
        hopRoute.enable = true;

        tokenHops[src][dest].push(hopRoute);
    }

    function getRouteHop(address src, address dest)
        external
        view
        override
        returns (HopsRoute[] memory)
    {
        HopsRoute[] memory hopsRoutes = new HopsRoute[](
            tokenHops[src][dest].length + 1
        );

        for (uint256 i = 0; i < tokenHops[src][dest].length; i++) {
            if (tokenHops[src][dest][i].enable == true) {
                hopsRoutes[i] = tokenHops[src][dest][i];
            }
        }

        address[] memory mainPair = new address[](2);
        mainPair[0] = src;
        mainPair[1] = dest;
        HopsRoute memory mainHops;
        mainHops.path = mainPair;
        mainHops.enable = true;
        hopsRoutes[hopsRoutes.length - 1] = mainHops;
        return hopsRoutes;
    }

    function getAllRouteHop(address src, address dest)
        external
        view
        returns (HopsRoute[] memory)
    {
        HopsRoute[] memory hopsRoutes = new HopsRoute[](
            tokenHops[src][dest].length + 1
        );
        address[] memory mainPair = new address[](2);
        mainPair[0] = src;
        mainPair[1] = dest;
        HopsRoute memory mainHops;
        mainHops.path = mainPair;
        mainHops.enable = true;
        hopsRoutes[hopsRoutes.length - 1] = mainHops;
        return hopsRoutes;
    }

    function switchHopsRoute(
        address src,
        address dest,
        uint256 index,
        bool state
    ) public onlyOwner {
        require(
            tokenHops[src][dest][index].path.length == 0 &&
                tokenHops[src][dest][index].enable != state,
            "PoolTokens: invalid index"
        );
        tokenHops[src][dest][index].enable = state;
    }

    // internal
    function _hasAcceptedToken(address token) internal view returns (bool) {
        return tokens[token].isAccepted == true;
    }

    function _hasAllowedToken(address token) internal view returns (bool) {
        return tokens[token].isAllowed == true;
    }
}