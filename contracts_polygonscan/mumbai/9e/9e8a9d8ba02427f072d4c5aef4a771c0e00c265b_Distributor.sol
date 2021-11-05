/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

/*

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * C U ON THE MOON
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
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
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

interface IDistributor {
    function finishDistribution() external;
    function startDistribution() external;
    function setDistributionParameters(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external;
    function setShares(address shareholder, uint256 amount) external;
    function process() external;
    function deposit() external payable;
    function claim(address shareholder) external;
    function getUnpaidRewards(address shareholder) external view returns (uint256);
    function getPaidRewards(address shareholder) external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function getTotalRewards() external view returns (uint256);
    function getTotalRewarded() external view returns (uint256);
    function migrate(address distributor) external;
}

contract Distributor is IDistributor {
    mapping(address => bool) mainContract;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] public shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalRewarded;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 7 days;
    uint256 public minDistribution = 1 * (10 ** 15);
    uint256 public gas = 150000;
    
    uint256 currentIndex;

    bool public initialized;
    uint256 newBalance = 0;
    
    uint256 updateIndex;
    
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyMain() {
        require(mainContract[msg.sender]); _;
    }

    constructor (address _mainContract) {
        mainContract[_mainContract] = true;
    }
    
    function finishDistribution() external override onlyMain {
        initialized = false;
        newBalance = 0;
    }
    
    function startDistribution() external override initialization onlyMain {
        totalRewards += newBalance;
        rewardsPerShare += ((rewardsPerShareAccuracyFactor * newBalance) / totalShares);
    }
    
    function migrate(address _distributor) external override onlyMain {
        Distributor dist = Distributor(payable(_distributor));
        require(!dist.initialized());
        dist.deposit{value: address(this).balance}();
    }

    function setDistributionParameters(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external override onlyMain {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        gas = _gas;
    }

    function setShares(address shareholder, uint256 amount) external override onlyMain {
        uint256 currentAmount = shares[shareholder].amount;
        if(amount > 0 && currentAmount == 0){
            addShareholder(shareholder);
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
            shareholderClaims[shareholder] = block.timestamp;
        }else if(amount == 0 && currentAmount > 0){
            removeShareholder(shareholder);
        }
        
        bool dist = shouldDistribute(shareholder);
        
        if (dist){
            distributeDividend(shareholder);
        } else if (currentAmount > amount) {
            uint256 toExclude = getCumulativeDividends(currentAmount - amount);
            uint256 unclaimed = getUnpaidRewards(shareholder);
            if (toExclude >= unclaimed) toExclude = unclaimed;
            rewardsPerShare += (toExclude * rewardsPerShareAccuracyFactor) / totalShares;
        }
        
        totalShares = (totalShares - currentAmount) + amount;
        shares[shareholder].amount = amount;
        
	if(currentAmount > 0 && currentAmount <= amount) {
            shares[shareholder].totalExcluded += getCumulativeDividends(amount - currentAmount);
        }
	
	if (shares[shareholder].totalExcluded > getCumulativeDividends(amount))
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function deposit() external payable override {
        if(!initialized) {

            newBalance += msg.value;
            return;
        }

        uint256 amount = msg.value;

        totalRewards += amount;
        rewardsPerShare += ((rewardsPerShareAccuracyFactor * amount) / totalShares);
    }
    
    function process() public override onlyMain {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
            
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        uint256 claimTime = 0;
        return shareholderClaims[shareholder] + claimTime + minPeriod < block.timestamp
                && getUnpaidRewards(shareholder) > minDistribution;
    }
    
    function getClaimTime(address shareholder) external view override returns (uint256) {
        uint256 claimTime = 0;
        if (shareholderClaims[shareholder] + claimTime + minPeriod <= block.timestamp)
            return 0;
        else
            return (shareholderClaims[shareholder] + claimTime + minPeriod) - block.timestamp;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        
        uint256 unpaidEarnings = getUnpaidRewards(shareholder);
        if(unpaidEarnings > 0){
            totalRewarded = totalRewarded + unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            payable(shareholder).transfer(unpaidEarnings);
        }
    }

    function claim(address shareholder) external override onlyMain {
        distributeDividend(shareholder);
    }

    function getUnpaidRewards(address shareholder) public view override returns (uint256) {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;

        amount = shares[shareholder].amount;
        totalExcluded = shares[shareholder].totalExcluded;
        
        if(amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(amount);

        if(shareholderTotalDividends <= totalExcluded){ return 0; }

        return shareholderTotalDividends - totalExcluded;
    }
    
    function getPaidRewards(address shareholder) external view override returns (uint256) {
        return shares[shareholder].totalRealised;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        if(share == 0){ return 0; }
        return (share * rewardsPerShare) / rewardsPerShareAccuracyFactor;
    }
    
    function countShareholders() external view override returns (uint256) {
        return shareholders.length;
    }
    
    function getTotalRewards() external view override returns (uint256) {
        return totalRewards;
    }
    function getTotalRewarded() external view override returns (uint256) {
        return totalRewarded;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    receive() external payable { }
}