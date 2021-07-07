/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**

 * `````````.```````...`````....````....`````..........`````....````....`````....`````.....````````.
 * ```````...``````...```````..````...````.....-:/+/:-....````...````....`````....````......````````
 * ``````...``````....``````..````...````..-+syyyysyyyso/...````..````...`````....`````.....````````
 * `````....``````...``````...```...```...+yyyyys:.+syyyys:...``...````...`````...`````......```````
 * `````....``````...``````..````..```..`+yyyys/``.`.oyyyys-..```...```...`````....````......```````
 * `````....``````...`````...````..```...yyyy+.`:-.--`:syyy/...``...```....````....``````....```````
 * `````....``````...`````...````..```..`sys:`-:.```-:../sy:...``...```...`````....``````....```````
 * ```````..``````...`````...````...```..:ss+o+///////so+s+...```...```...`````....`````.....```````
 * ```````..``````....`````...````..```...-oyyyyyyyyyyyys/...```...```....`````...``````.....```````
 * ```````..``````....`````...````...````...:+ossyyyso+:....```...``.-:-.`````....``````....````````
 * ````````..``````....`````...``````..````.....-----.....````...`+so//oo:://///-``````.....```````.
 * ````````..```````....`````....`````...```````.....``````....```:-...`.--....-:`````.....````````.
 * :////:-:++-......`.....````....``````.....``````````......````../..`````....``````..../h-``````..
 * mmNNmmmmmmmmmmmmmddhysosyysyysyhddddyo+/-.............`````-/+sydhs/-.--:/+++///:::::+yhyyyhddddm
 * NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmmmdhhhhhysoooo+oshmNNNNNNNNNNmmmNNNNNNmmmmmmmmNNNNNNNNNNN
 * NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
 *
 *                        .---.  _        _              .--.             
 *                        : .; ::_;      :_;            : .--'            
 *                        :   .'.-. .--. .-.,-.,-. .--. `. `. .-..-.,-.,-.
 *                        : :.`.: :`._-.': :: ,. :' .; : _`, :: :; :: ,. :
 *                        :_;:_;:_;`.__.':_;:_;:_;`._. ;`.__.'`.__.':_;:_;
 *                                                 .-. :                  
 *                                                 `._.'                  
 * 
 *  https://risingsun.finance/
 *  https://t.me/risingsun_token
 */

// import "hardhat/console.sol";

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
    function sendValue(address payable recipient, uint amount) internal {
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
        uint value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

enum Permission {
    ChangeFees,
    Buyback,
    AdjustContractVariables,
    Authorize,
    Unauthorize,
    PauseUnpauseContract,
    BypassPause,
    LockPermissions,
    ExcludeInclude
}

/**
 * Allows for contract ownership along with multi-address authorization for different permissions
 */
abstract contract RSunAuth {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint => bool)) private authorizations; // uint is permission index
    
    uint constant NUM_PERMISSIONS = 9; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint) permissionNameToIndex;
    mapping(uint => string) permissionIndexToName;

    mapping(uint => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        permissionNameToIndex["ChangeFees"] = uint(Permission.ChangeFees);
        permissionNameToIndex["Buyback"] = uint(Permission.Buyback);
        permissionNameToIndex["AdjustContractVariables"] = uint(Permission.AdjustContractVariables);
        permissionNameToIndex["Authorize"] = uint(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint(Permission.Unauthorize);
        permissionNameToIndex["PauseUnpauseContract"] = uint(Permission.PauseUnpauseContract);
        permissionNameToIndex["BypassPause"] = uint(Permission.BypassPause);
        permissionNameToIndex["LockPermissions"] = uint(Permission.LockPermissions);
        permissionNameToIndex["ExcludeInclude"] = uint(Permission.ExcludeInclude);

        permissionIndexToName[uint(Permission.ChangeFees)] = "ChangeFees";
        permissionIndexToName[uint(Permission.Buyback)] = "Buyback";
        permissionIndexToName[uint(Permission.AdjustContractVariables)] = "AdjustContractVariables";
        permissionIndexToName[uint(Permission.Authorize)] = "Authorize";
        permissionIndexToName[uint(Permission.Unauthorize)] = "Unauthorize";
        permissionIndexToName[uint(Permission.PauseUnpauseContract)] = "PauseUnpauseContract";
        permissionIndexToName[uint(Permission.BypassPause)] = "BypassPause";
        permissionIndexToName[uint(Permission.LockPermissions)] = "LockPermissions";
        permissionIndexToName[uint(Permission.ExcludeInclude)] = "ExcludeInclude";
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownership required."); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorizedFor(Permission permission) {
        require(!lockedPermissions[uint(permission)].isLocked, "Permission is locked.");
        require(isAuthorizedFor(msg.sender, permission), string(abi.encodePacked("Not authorized. You need the permission ", permissionIndexToName[uint(permission)]))); _;
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Authorize) {
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Authorize) {
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public authorizedFor(Permission.Unauthorize) {
        require(adr != owner, "Can't unauthorize owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint) {
        return permissionNameToIndex[permissionName];
    }
    
    /**
     * Get the time the timelock expires
     */
    function getUnlockTime(string memory permissionName) public view returns (uint) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    /**
     * Check if the permission is locked
     */
    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    /*
     *Locks the permission from being used for the amount of time provided
     */
    function lockPermissions(string memory permissionName, uint64 time) public virtual authorizedFor(Permission.LockPermissions) {
        uint permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }
    
    /*
     * Unlocks the permission if the lock has expired 
     */
    function unlockPermissions(string memory permissionName) public virtual {
        require(block.timestamp > getUnlockTime(permissionName) , "Permission is locked until the expiry time.");
        uint permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint permissionIndex);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract DividendDistributor {
    using Address for address;

    address constant WBNB_ADR = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address constant BUSD_ADR = 0xbcca17a1e79Cb6Fcf2A5B7433e6fBCb7408Ca535;
    IBEP20 busd = IBEP20(BUSD_ADR);
    IDEXRouter router;

    struct Share {
        // uint72 is enough if we cut some decimals off and this will result in massive gas savings cause these are assigned together a lot of times
        uint72 amount;
        uint72 totalExcluded;
        uint72 totalRealised;
        uint40 lastClaim;
    }

    uint constant removedDecimals = 10 ** 6;

    address[] shareholders;
    mapping (address => uint) shareholderIndexes;

    mapping (address => Share) public shares;

    uint public totalShares;
    uint public totalDividends;
    uint public totalDistributed;
    uint public dividendsPerShare;
    uint public dividendsPerShareAccuracyFactor = 10 ** 20;

    uint public minPeriod = 2 hours;
    uint public minDistribution = 2 * (10 ** 18); // 2 busd min reflect

    uint public currentIndex;

    constructor () {
        router = IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    }

    function setDistributionCriteria(uint _minPeriod, uint _minDistribution) internal {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint amount) internal {
        uint shareholderAmount = shares[shareholder].amount * removedDecimals; // gas savings
        // console.log("setShare: shareholder =", shareholder);
        // console.log("setShare: amount =", amount);
        // console.log("setShare: shareholderAmount =", shareholderAmount);

        if (shareholderAmount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shareholderAmount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shareholderAmount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shareholderAmount + amount;
        shares[shareholder].amount = uint72(amount / removedDecimals); // cutting off 6 decimals, shouldn't cause inaccuracy problems
        shares[shareholder].totalExcluded = uint72(getCumulativeDividends(shares[shareholder].amount * removedDecimals) / removedDecimals);

        // console.log("setShare: totalShares =", totalShares);
        // console.log("setShare: shares[shareholder].amount =", shares[shareholder].amount);
        // console.log("setShare: shares[shareholder].totalExcluded =", shares[shareholder].totalExcluded);
    }

    function deposit(uint bnbAmount) internal returns (bool) {
        uint256 balanceBefore = busd.balanceOf(address(this));

        // console.log("deposit: bnbAmount =", bnbAmount);
        // console.log("deposit: balanceBefore =", balanceBefore);

        address[] memory path = new address[](2);
        path[0] = WBNB_ADR;
        path[1] = BUSD_ADR;

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: bnbAmount }(
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint256 amount = busd.balanceOf(address(this)) - balanceBefore;

            totalDividends += amount;
            dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);

            // console.log("deposit: amount =", amount);
            // console.log("deposit: totalDividends =", totalDividends);
            // console.log("deposit: dividendsPerShare =", dividendsPerShare);
            return true;
        } catch {
            // console.log("deposit: swapExactETHForTokensSupportingFeeOnTransferTokens failed");
            return false;
        }
    }

    function process(uint gas) internal {
        uint shareholderCount = shareholders.length;

        // console.log("process: gas =", gas);
        // console.log("process: shareholderCount =", shareholderCount);

        if (shareholderCount == 0) { return; }

        uint gasUsed = 0;
        uint gasLeft = gasleft();

        // console.log("process: gasLeft =", gasLeft);

        uint iterations = 0;
        uint currIndex = currentIndex; // gas savings

        while (gasUsed < gas && iterations < shareholderCount) {
            // console.log("process: in loop: iterations =", iterations);
            // console.log("process: in loop: currIndex =", currIndex);
            // console.log("process: in loop: gasUsed =", gasUsed);
            // console.log("process: in loop: gasLeft =", gasLeft);

            if (currIndex >= shareholderCount) {
                currIndex = 0;
            }

            address currentShareholder = shareholders[currIndex];
            // console.log("process: in loop: currentShareholder =", currentShareholder);
            // console.log("process: in loop: shouldDistribute(currentShareholder) =", shouldDistribute(currentShareholder));

            if (shouldDistribute(currentShareholder)) {
                distributeDividend(currentShareholder);
            }

            gasUsed = gasUsed + gasLeft - gasleft();
            gasLeft = gasleft();
            currIndex++;
            iterations++;
        }

        currentIndex = currIndex;
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shares[shareholder].lastClaim + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal returns (bool success) {
        uint shareholderAmount = shares[shareholder].amount * removedDecimals;

        // console.log("distributeDividend: shareholder =", shareholder);
        // console.log("distributeDividend: shareholderAmount =", shareholderAmount);
        if (shareholderAmount == 0) { return true; }

        uint amount = getUnpaidEarnings(shareholder);

        // console.log("distributeDividend: amount =", amount);
        // console.log("distributeDividend: busd.balanceOf(address(this)) =", busd.balanceOf(address(this)));
        
        if (amount > 0 && busd.balanceOf(address(this)) >= amount) {
            try busd.transfer(shareholder, amount) {
                totalDistributed += amount;
                shares[shareholder].lastClaim = uint40(block.timestamp);
                shares[shareholder].totalRealised += uint72(amount / removedDecimals);
                shares[shareholder].totalExcluded = uint72(getCumulativeDividends(shareholderAmount) / removedDecimals);

                // console.log("distributeDividend: shares[shareholder].lastClaim =", shares[shareholder].lastClaim);
                // console.log("distributeDividend: shares[shareholder].totalRealised =", shares[shareholder].totalRealised);
                // console.log("distributeDividend: shares[shareholder].totalExcluded =", shares[shareholder].totalExcluded);

                return true;
            } catch {
                // console.log("distributeDividend: busd.transfer failed");

                return false;
            }
        }

        return true;
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint) {
        uint shareholderAmount = shares[shareholder].amount * removedDecimals;
        if (shareholderAmount == 0) { return 0; }

        uint shareholderTotalDividends = (shareholderAmount);
        uint shareholderTotalExcluded = shares[shareholder].totalExcluded * removedDecimals;

        if (shareholderTotalDividends <= shareholderTotalExcluded) { return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint share) internal view returns (uint) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        address lastShareholder = shareholders[shareholders.length - 1];
        uint indexShareholder = shareholderIndexes[shareholder];

        shareholders[indexShareholder] = lastShareholder;
        shareholderIndexes[lastShareholder] = indexShareholder;
        shareholders.pop();
    }
}

contract RisingSun is IBEP20, RSunAuth, DividendDistributor {
    using Address for address;
    // SafeMath is not necessary since solidity >=0.8.0 checks for overflows/underflows automatically

    address constant DEAD_ADR = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO_ADR = 0x0000000000000000000000000000000000000000;
    uint UINT_MAX = ~uint(0);

    string constant _name = "RisingSun";
    string constant _symbol = "RSUN";
    uint8 constant _decimals = 9;

    uint _totalSupply = 1 * 10 ** 10 * (10 ** _decimals); // 10 billion supply
    uint public _maxTxAmount = _totalSupply / 1000; // 0.1%

    mapping (address => uint) _balances;
    mapping (address => mapping (address => uint)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;

    uint liquidityPortion = 40;
    uint buybackPortion = 60;
    uint reflectionPortion = 40;
    uint marketingPortion = 20;
    uint feePortionDenominator = 160;

    uint totalBuyFee = 800;
    uint totalSellFee = 1600;
    uint feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint targetLiquidity = 20;
    uint targetLiquidityDenominator = 100;

    address public pancakeV2BnbPair;
    address[] public pairs;

    uint public launchedAt;

    uint buybackMultiplierNumerator = 200;
    uint buybackMultiplierDenominator = 100;
    uint buybackMultiplierTriggeredAt;
    uint buybackMultiplierLength = 30 minutes;

    DividendDistributor distributor;
    uint distributorGas = 800000;

    bool public swapEnabled = false;
    uint public swapThreshold = _totalSupply / 5000; // 0.02%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    bool public feesOnNormalTransfers = false;

    constructor (
        // address _presaler,
        // address _presaleContract
    ) RSunAuth(msg.sender) DividendDistributor() {
        pancakeV2BnbPair = IDEXFactory(router.factory()).createPair(WBNB_ADR, address(this));
        _allowances[address(this)][address(router)] = UINT_MAX;

        pairs.push(pancakeV2BnbPair);

        address _presaler = msg.sender;

        isFeeExempt[_presaler] = true;
        isTxLimitExempt[_presaler] = true;
        // isFeeExempt[_presaleContract] = true;
        // isTxLimitExempt[_presaleContract] = true;
        // isDividendExempt[_presaleContract] = true;
        isDividendExempt[pancakeV2BnbPair] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD_ADR] = true;

        autoLiquidityReceiver = _presaler;
        marketingFeeReceiver = _presaler;

        _balances[_presaler] = _totalSupply;
        emit Transfer(address(0), _presaler, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint) { return _allowances[holder][spender]; }

    function approve(address spender, uint amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, UINT_MAX);
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {

        uint senderAllowance = _allowances[sender][msg.sender];
        // console.log("transferFrom: senderAllowance =", senderAllowance);
        require(senderAllowance >= amount, "Insufficient allowance");
        
        if (senderAllowance != UINT_MAX) {
            _allowances[sender][msg.sender] = senderAllowance - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint amount) internal returns (bool) {
        // console.log("_transferFrom: sender =", sender);
        // console.log("_transferFrom: recipient =", recipient);
        // console.log("_transferFrom: amount =", amount);

        uint senderBalance = _balances[sender];
        uint recipientBalance = _balances[recipient];
        require(senderBalance >= amount, "Insufficient Balance");

        // console.log("_transferFrom: senderBalance =", senderBalance);
        // console.log("_transferFrom: recipientBalance =", recipientBalance);
        // console.log("_transferFrom: inSwap =", inSwap);

        if (inSwap) { return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);

        // console.log("_transferFrom: shouldSwapBack() =", shouldSwapBack());

        if (shouldSwapBack()) { swapBack(); }

        // console.log("_transferFrom: launched() =", launched());

        if (!launched() && recipient == pancakeV2BnbPair) { require(senderBalance > 0); launch(); }

        // console.log("_transferFrom: launchedAt =", launchedAt);

        _balances[sender] = senderBalance - amount;

        // console.log("_transferFrom: _balances[sender] =", senderBalance - amount);

        // console.log("_transferFrom: shouldTakeFee(sender, recipient) =", shouldTakeFee(sender, recipient));
        // console.log("_transferFrom: takeFee(sender, recipient, amount) =", takeFee(sender, recipient, amount));

        uint amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = recipientBalance + amountReceived;

        // console.log("_transferFrom: _balances[recipient] =", recipientBalance + amountReceived);
        // console.log("_transferFrom: isDividendExempt[sender] =", isDividendExempt[sender]);
        // console.log("_transferFrom: isDividendExempt[recipient] =", isDividendExempt[recipient]);

        if (!isDividendExempt[sender]) { setShare(sender, _balances[sender]); }
        if (!isDividendExempt[recipient]) { setShare(recipient, _balances[recipient]); }

        // console.log("_transferFrom: setShares passed");

        process(distributorGas);

        // console.log("_transferFrom: process passed");

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint amount) internal returns (bool) {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient] || !launched()) return false;

        address[] memory liqPairs = pairs;

        for (uint i = 0; i < liqPairs.length; i++) {
            if (sender == liqPairs[i] || recipient == liqPairs[i]) return true;
        }

        return false;
    }

    function takeFee(address sender, address recipient, uint amount) internal returns (uint) {
        uint feeAmount = amount * getTotalFee(isSell(recipient)) / feeDenominator;

        // console.log("takeFee: feeAmount =", amount * getTotalFee(isSell(recipient)) / feeDenominator);

        _balances[address(this)] += feeAmount;
        
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }
    
    function isSell(address recipient) internal view returns (bool) {
        address[] memory liqPairs = pairs;
        for (uint i = 0; i < liqPairs.length; i++) {
            if (recipient == liqPairs[i]) return true;
        }
        return false;
    }

    function getFeeFromPortion(uint portion, bool selling) public view returns (uint) {
        return portion * (selling ? totalSellFee : totalBuyFee) / feePortionDenominator;
    }

    function getTotalFee(bool selling) public view returns (uint) {
        if (launchedAt + 1 >= block.number) { return feeDenominator - 1; }
        if (selling) {
            uint bbMultiplierTriggeredAt = buybackMultiplierTriggeredAt; // gas savings
            uint bbMultiplierLength = buybackMultiplierLength;
            
            if (bbMultiplierTriggeredAt + bbMultiplierTriggeredAt > block.timestamp) { return getMultipliedFee(bbMultiplierTriggeredAt, bbMultiplierLength); }
        }
        return selling ? totalSellFee : totalBuyFee;
    }

    function getMultipliedFee(uint bbMultiplierTriggeredAt, uint bbMultiplierLength) public view returns (uint) {
        uint totalFee = totalSellFee;
        uint remainingTime = bbMultiplierTriggeredAt + bbMultiplierLength - block.timestamp;
        uint feeIncrease = (totalFee * buybackMultiplierNumerator / buybackMultiplierDenominator) - totalFee;
        return totalFee + (feeIncrease * remainingTime / bbMultiplierLength);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pancakeV2BnbPair
            && !inSwap
            && swapEnabled
            && _balances[address(this)] >= swapThreshold
            && launched();
    }

    function swapBack() internal swapping {
        uint dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : getFeeFromPortion(liquidityPortion, false);
        uint tokenAmountToLiq = swapThreshold * dynamicLiquidityFee / getTotalFee(false) / 2;
        uint amountToSwap = swapThreshold - tokenAmountToLiq;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB_ADR;

        uint balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {
            uint amountBNB = address(this).balance - balanceBefore;

            uint totalBNBFee = totalBuyFee - dynamicLiquidityFee / 2;

            uint amountBNBLiquidity = amountBNB * dynamicLiquidityFee / totalBNBFee / 2;
            uint amountBNBReflection = amountBNB * getFeeFromPortion(reflectionPortion, false) / totalBNBFee;
            uint amountBNBMarketing = amountBNB * getFeeFromPortion(marketingPortion, false) / totalBNBFee;

            deposit(amountBNBReflection);
            payable(marketingFeeReceiver).call{ value: amountBNBMarketing }("");

            if (tokenAmountToLiq > 0) {
                try router.addLiquidityETH{ value: amountBNBLiquidity }(
                    address(this),
                    tokenAmountToLiq,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                ) {
                    emit AutoLiquify(tokenAmountToLiq, amountBNBLiquidity);
                } catch {
                    emit AutoLiquify(0, 0);
                }
            }

            emit SwapBackSuccess(amountToSwap);
        } catch Error(string memory e) {
            emit SwapBackFailed(string(abi.encodePacked("SwapBack failed with error ", e)));
        } catch {
            emit SwapBackFailed("SwapBack failed without an error message from pancakeSwap");
        }
        
    }

    function triggerBuyback(uint amount, bool triggerBuybackMultiplier) external authorizedFor(Permission.Buyback) {
        buyTokens(amount, DEAD_ADR);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }
    
    function clearBuybackMultiplier() external authorizedFor(Permission.AdjustContractVariables) {
        buybackMultiplierTriggeredAt = 0;
    }

    function buyTokens(uint amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB_ADR;
        path[1] = address(this);

        try router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
            0,
            path,
            to,
            block.timestamp
        ) {
            emit BoughtBack(amount, to);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("Buyback failed with error ", reason)));
        } catch {
            revert("Buyback failed without an error message from pancakeSwap");
        }
    }

    function setBuybackMultiplierSettings(uint numerator, uint denominator, uint length) external authorizedFor(Permission.AdjustContractVariables) {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        emit Launched(block.number, block.timestamp);
    }

    function setTxLimit(uint amount) external authorizedFor(Permission.AdjustContractVariables) {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        require(holder != address(this) && holder != pancakeV2BnbPair);
        isDividendExempt[holder] = exempt;
        
        if (exempt) {
            setShare(holder, 0);
        } else {
            setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorizedFor(Permission.ExcludeInclude) {
        isTxLimitExempt[holder] = exempt;
    }

    function setPortions(uint _liquidityPortion, uint _buybackPortion, uint _reflectionPortion, uint _marketingPortion, uint _feePortionDenominator) external authorizedFor(Permission.ChangeFees) {
        liquidityPortion = _liquidityPortion;
        buybackPortion = _buybackPortion;
        reflectionPortion = _reflectionPortion;
        marketingPortion = _marketingPortion;

        feePortionDenominator = _feePortionDenominator;
    }

    function setFees(uint _buyFee, uint _sellFee) external authorizedFor(Permission.ChangeFees) {
        require(_buyFee < feeDenominator / 10, "Buy fee can at most be 10%");
        require(_sellFee < feeDenominator / 5, "Unmultiplied sell fee can at most be 20%");

        totalBuyFee = _buyFee;
        totalSellFee = _sellFee;
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorizedFor(Permission.AdjustContractVariables) {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint _amount) external authorizedFor(Permission.AdjustContractVariables) {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setFeesOnNormalTransfers(bool _enabled) external authorizedFor(Permission.AdjustContractVariables) {
        feesOnNormalTransfers = _enabled;
    }

    function setTargetLiquidity(uint _target, uint _denominator) external authorizedFor(Permission.AdjustContractVariables) {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributorSettings(uint gas) external authorizedFor(Permission.AdjustContractVariables) {
        require(gas <= 1500000);
        distributorGas = gas;
    }

    function addPair(address pair) external authorizedFor(Permission.AdjustContractVariables) {
        pairs.push(pair);
    }
    
    function removeLastPair() external authorizedFor(Permission.AdjustContractVariables) {
        pairs.pop();
    }

    function getCirculatingSupply() public view returns (uint) {
        return _totalSupply - balanceOf(DEAD_ADR) - balanceOf(ZERO_ADR);
    }

    function getLiquidityBacking(uint accuracy) public view returns (uint) {
        return accuracy * balanceOf(pancakeV2BnbPair) * 2 / getCirculatingSupply();
    }

    function isOverLiquified(uint target, uint accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint tokenAmount, uint bnbAmount);
    event BuybackMultiplierActive(uint duration);
    event BoughtBack(uint amount, address to);
    event Launched(uint blockNumber, uint timestamp);
    event SwapBackSuccess(uint amount);
    event SwapBackFailed(string message);
}