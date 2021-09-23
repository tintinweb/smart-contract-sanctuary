/**
 *Submitted for verification at BscScan.com on 2021-09-23
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
    function startDistribution() external;
    function setDistributionParameters(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external;
    function setShares(address shareholder, uint256 amount) external;
    function process() external;
    function deposit(uint256 _amount) external;
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
    address public owner;
    mapping(address => bool) mainContract;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 public TOKEN;

    address[] public shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalRewarded;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 15 minutes;
    uint256 public decimals = 9;
    uint256 public minDistribution = 1000 * (10 ** decimals);
    uint256 public gas = 100000;
    
    uint256 currentIndex;
    Distributor previous;
    bool airdropping = true;

    bool public initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
        airdropping = false;
    }

    modifier onlyMain() {
        require(mainContract[msg.sender]); _;
    }

    constructor (address _mainContract, address _token) {
        mainContract[_mainContract] = true;
        owner = msg.sender;
        mainContract[owner] = true;
        TOKEN = IERC20(_token);
    }
    
    function finishAirdrop(bool _finished) external onlyMain {
        airdropping = _finished;
    }
    
    function transferOwnership(address newOwner) external onlyMain {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        mainContract[newOwner] = true;
        mainContract[owner] = false;
        owner = newOwner;
    }
    
    function importData(address[] calldata importList) external onlyMain {
        for (uint256 i=0;i < importList.length;i++) {
            addShareholder(importList[i]);
        }
    }
    
    function readData(address _dist, uint runs, uint start) external onlyMain {
        Distributor temp = Distributor(_dist);

        for (uint256 i=start;i < shareholders.length && i < runs;i++) {
            (
			uint256 amount,
            uint256 totalExcluded,
            uint256 totalRealised
		    ) = temp.shares(shareholders[i]);

            totalShares = totalShares + amount;
            shares[shareholders[i]].amount = amount;
            shares[shareholders[i]].totalExcluded = totalExcluded;
            shares[shareholders[i]].totalRealised = totalRealised;
        }
    }
    
    function readTotals(address _dist) external onlyMain {
        Distributor temp = Distributor(_dist);
        totalRewards = temp.totalRewards();
        totalRewarded = temp.totalRewarded();
        rewardsPerShare = temp.rewardsPerShare();
    }
    
    function startDistribution() external override initialization onlyMain {
        rewardsPerShare = (rewardsPerShareAccuracyFactor * address(this).balance) / totalShares;
    }
    
    function migrate(address _distributor) external override onlyMain {
        TOKEN.transfer(_distributor, TOKEN.balanceOf(address(this)));
    }

    function setDistributionParameters(uint256 _minPeriod, uint256 _minDistribution, uint256 _gas) external override onlyMain {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        gas = _gas;
    }

    function setShares(address shareholder, uint256 amount) external override onlyMain {
        if (airdropping) amount = amount * (10 ** decimals);
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        
        totalShares = (totalShares - shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        
        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function deposit(uint256 _amount) external override {
        totalRewards = totalRewards + _amount;
        if(initialized)
            rewardsPerShare = rewardsPerShare + (rewardsPerShareAccuracyFactor * _amount) / totalShares;
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
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidRewards(shareholder) > minDistribution;
    }
    
    function getClaimTime(address shareholder) external view override returns (uint256) {
        if (shareholderClaims[shareholder] + minPeriod <= block.timestamp)
            return 0;
        else
            return (shareholderClaims[shareholder] + minPeriod) - block.timestamp;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        
        uint256 unpaidEarnings = getUnpaidRewards(shareholder);
        if(unpaidEarnings > 0){
            totalRewarded = totalRewarded + unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            TOKEN.transfer(shareholder, unpaidEarnings);
        }
    }

    function claim(address shareholder) external override onlyMain {
        distributeDividend(shareholder);
    }

    function getUnpaidRewards(address shareholder) public view override returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
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
}