/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT
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

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        address payable msgSender = payable(msg.sender);
        return msgSender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract Buds is Context, IERC20, Ownable {
    
    using Address for address;

    string _name = "fBUDS";
    string _symbol = "fbuds";
    uint8 _decimals = 9;
    uint256 supply  = 420690 * 10**6 * 10**_decimals;
    
    uint maxTx = (supply/100);
    uint minWhaleTx = (supply/200);
    
    uint balanceFromLiquidityFee;
    uint balanceFromRewardsFee;
    
    address ownerContract;
    address goodBudsWallet;
    address smokeOutWallet;
    address manualLiquidityWallet;
    address budsBank;
    address lottery;
    address zombie;
    
    mapping (address => uint) balances;
    uint sumOfBalances;

    uint reservedDividendsForHOLDRs;
    uint currentClaimableDividends;
    mapping (address => uint) lastDividendClaimTime;
    uint lastDividendReleaseTime;
    
    mapping (uint => mapping(address => bool)) isRewardedAtRewardCycle;
    mapping (address => uint) lastRewardsClaimTime;
    uint rewardsCycleLength;
    uint currentRewardsCycle;
    uint endOfLastRewardsCycle;
    
    mapping (address => bool) isTeamBuds; 
    address[] teamBuds;
    mapping (address => bool) isExcludedFromFee;
    mapping (address => mapping (address => uint256)) private _allowances;

    event AddedTeamMember(address member, uint time);
    event RemovedTeamMember(address member, uint time);
    event RewardsCycleLengthChanged(uint numberOfSecondsOfNewCycle, uint time);
    event CommunityRewardsAdded(uint amount, uint time);
    event DividendDistributionEnabled(uint amount, uint time);
    event BalanceFromLiquidityFeeDistributed(uint funds, address destination, uint time);
 
    constructor() {
        
        ownerContract = msg.sender;

        
        rewardsCycleLength = 1 weeks;
        currentRewardsCycle = 1;
        
        reservedDividendsForHOLDRs = 176689800000000000000;
        balances[ownerContract] = supply - reservedDividendsForHOLDRs;
        
        ownerContract = msg.sender;
        isExcludedFromFee[ownerContract] = true;
        isTeamBuds[owner()] = true; 
        teamBuds.push(owner());
        
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() external view override returns (uint) {
        return supply;
    }
    
    //standard allowances and approval logic begins
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
       _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
       return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    
    //Allowances and approval logic ends

    function viewAddresses() public view returns(
        address _goodBudsWallet, 
        address _smokeOutWallet, 
        address _manualLiquidityWallet,
        address _budsBank, 
        address _lottery,
        address _zombie) {
        return(goodBudsWallet, smokeOutWallet, manualLiquidityWallet, budsBank, lottery, zombie);
    }

    //Buds team member logic begins

    function isCurrentTeamMember(address person) public view returns(bool) {
        if(isTeamBuds[person]){ return true;} return false;
    }

    function teamMembersAndExMembers() public view returns (address[] memory) {
        return teamBuds;
    }

    function addTeamMember(address teamMember) public onlyOwner {
        require(!isTeamBuds[teamMember], "That person is already a team member");
        isTeamBuds[teamMember] = true;
        teamBuds.push(teamMember);
        emit AddedTeamMember(teamMember, block.timestamp);
    }

    function removeTeamMember(address teamMember) public onlyOwner {
        require(isTeamBuds[teamMember], "That person isn't a team member to begin with");
        isTeamBuds[teamMember] = false;
        emit RemovedTeamMember(teamMember, block.timestamp);
    }

    //Buds Team Member Logic Ends

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;  
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        
        require(sender != address(0), "Invalid sender");
        require(recipient != address(0) && recipient != address(this), "Invalid recipient");
        require(balances[sender] >= amount, "Insufficient balance for transfer");
        //Custom $BUDs tx fee logic starts below
        if (recipient != budsBank) {
            require (amount <= maxTx, "The Transaction is too large");
        }
        if (!isExcludedFromFee[sender]) {
            
            uint sendable;
            if(isTeamBuds[sender] == false && amount <= minWhaleTx) {
                
                uint onePercentFee = amount/100; //2 fees within
                uint pointFivePercentFee = amount/200; //2 fees within
                
                uint difference = 2*onePercentFee + 2*pointFivePercentFee;
    
                sendable = amount - difference; 
    
                //regular tx transfer
                balances[sender] -= amount;
                balances[recipient] += sendable;
                
                //transfer to wallets
                balances[goodBudsWallet] += onePercentFee;
                balances[smokeOutWallet] += pointFivePercentFee;
                
                balanceFromRewardsFee += onePercentFee;
                balanceFromLiquidityFee += pointFivePercentFee;
                sumOfBalances -= amount - sendable;
            } 
            
            else if(isTeamBuds[sender] == true && amount <= minWhaleTx) {
                
                uint twoPercentFee = amount/50; //3 fees within
                uint pointNinePercentFee = (amount/1000)*9;
                
                uint difference = 3*twoPercentFee + pointNinePercentFee;
                sendable = amount - difference;
    
                //regular TEAM tx transfer
                balances[sender] -= amount;
                balances[recipient] += sendable;
    
                //transfer to wallets
                balances[goodBudsWallet] += twoPercentFee;
                balances[smokeOutWallet] += twoPercentFee;
                
                //token owners logic here
                balanceFromRewardsFee += twoPercentFee;
                balanceFromLiquidityFee += pointNinePercentFee;
                sumOfBalances -= amount - sendable;
            } 
            
            else if(amount > minWhaleTx && isTeamBuds[sender] == false) {
                
                uint twoPercentFee = amount/50; //2 fees within
                uint onePointFourPercentFee = (amount/1000)*4 + amount/100;
                uint onePointFivePercentFee = (amount/1000)*5 + amount/100;
    
                uint difference = 2*twoPercentFee + onePointFourPercentFee + onePointFivePercentFee;
                sendable = amount - difference;
    
                //regular WHALE tx transfer
                balances[sender] -= amount;
                balances[recipient] += sendable;

                //transfer to wallets
                balances[goodBudsWallet] += twoPercentFee;
                balances[smokeOutWallet] += onePointFivePercentFee;
                
                //token owners logic here
                balanceFromRewardsFee += twoPercentFee;
                balanceFromLiquidityFee += onePointFourPercentFee;
                sumOfBalances -= amount - sendable;
            } 
            
            else {
    
                uint fourPercentFee = (amount/100)*4; //2 fees within
                uint threePointFivePercentFee = (amount/100)*3 + amount/200;
                uint twoPointThreePercentFee = amount/50 + (amount/1000)*3;
        
                uint difference = 2*fourPercentFee + threePointFivePercentFee + twoPointThreePercentFee;
                sendable = amount - difference;
                
                // regular TEAM WHALE tx transfer
                balances[sender] -= amount;
                balances[recipient] += sendable;
    
                //transfer to wallets
                balances[goodBudsWallet] += fourPercentFee;
                balances[smokeOutWallet] += threePointFivePercentFee;
    
                //token owners logic here
                balanceFromRewardsFee += fourPercentFee;
                balanceFromLiquidityFee += twoPointThreePercentFee;
                sumOfBalances -= amount - sendable;
            }
            
            emit Transfer(sender, recipient, sendable); 
            if (block.timestamp - endOfLastRewardsCycle >= rewardsCycleLength) {
                currentRewardsCycle++;
                endOfLastRewardsCycle = block.timestamp;
            }
        } 
        
        else {
            if(!isExcludedFromFee[recipient]) {
                balances[sender] -= amount;
                balances[recipient] += amount;
                sumOfBalances += amount;
                emit Transfer(sender, recipient, amount);
            } else {
                balances[sender] -= amount;
                balances[recipient] += amount;
                emit Transfer(sender, recipient, amount);
            }
        }
    }
    
    function claimDividends() public {
        if(lastDividendReleaseTime != 0){
            require(lastDividendClaimTime[msg.sender] < lastDividendReleaseTime, "You've already claimed dividends this cycle");
        } else {
            require(lastDividendClaimTime[msg.sender] == 0, "You've already claimed dividends this cycle");
        }
        uint dividendReward = currentClaimableDividends * balances[msg.sender]/sumOfBalances;
        currentClaimableDividends -= dividendReward;
        balances[msg.sender] += dividendReward;
        lastDividendClaimTime[msg.sender] = block.timestamp;
    }
    
    function claimRewards() public {
        require(block.timestamp - lastRewardsClaimTime[msg.sender] >= rewardsCycleLength/3, "You can only claim rewards as often as rewardsCycleLength/3");
        require(!isRewardedAtRewardCycle[currentRewardsCycle][msg.sender], "You've already claimed rewards this cycle");
        require(!isExcludedFromFee[msg.sender], "You are not eligible for rewards");
        uint reward = balanceFromRewardsFee*balances[msg.sender]/sumOfBalances;
        balanceFromRewardsFee -= reward;
        balances[msg.sender] += reward;
        isRewardedAtRewardCycle[currentRewardsCycle][msg.sender] = true;
        lastRewardsClaimTime[msg.sender] = block.timestamp;
        sumOfBalances += reward;
    }
    
    
    function claimRewardsFromAPreviousRewardsCycle(uint rewardsCycle) public {
        require(block.timestamp - lastRewardsClaimTime[msg.sender] >= rewardsCycleLength/3, "You can only claim rewards as often as rewardsCycleLength/3");
        require(rewardsCycle < currentRewardsCycle, "That rewards cycle hasn't passed");
        require(!isRewardedAtRewardCycle[rewardsCycle][msg.sender], "You've claimed rewards for that cycle");
        require(!isExcludedFromFee[msg.sender], "You are not elegible for rewards");
        uint reward = balanceFromRewardsFee*balances[msg.sender]/sumOfBalances;
        balanceFromRewardsFee -= reward;
        balances[msg.sender] += reward;
        isRewardedAtRewardCycle[rewardsCycle][msg.sender] = true;
        lastRewardsClaimTime[msg.sender] = block.timestamp;
        sumOfBalances += reward;
    }
    
    function viewRewardsAndLiquidityInfo() public view returns(
        uint budsAccumulationFromRewardsFee, 
        uint sumOfAllHOLDRBalances, 
        uint theCurrentRewardsCycle, 
        uint lengthOfRewardsCycle, 
        uint budsAccumulationFromLiquidityFee,
        uint lastTimeDividendsWereReleased,
        uint dividendsClaimableNow,
        uint dividendsLeftFromReservedSupplyForHOLDRs) 
        {
        return(
            balanceFromRewardsFee, 
            sumOfBalances, 
            currentRewardsCycle, 
            rewardsCycleLength, 
            balanceFromLiquidityFee, 
            lastDividendReleaseTime,
            currentClaimableDividends,
            reservedDividendsForHOLDRs
        );
    }
    
    function changeRewardsCycleLength(uint numberOfSeconds) public onlyOwner {
        rewardsCycleLength = numberOfSeconds;
        emit RewardsCycleLengthChanged(numberOfSeconds, block.timestamp);
    }
    
    function allowDistributionOfDividends(uint amount) public onlyOwner {
        require(amount <= reservedDividendsForHOLDRs, "Amount entered is more than reserved supply");
        reservedDividendsForHOLDRs -= amount;
        currentClaimableDividends += amount;
        lastDividendReleaseTime = block.timestamp;
        emit DividendDistributionEnabled(amount, block.timestamp);
    }
    
    function addMoreRewards(uint amount) public onlyOwner {
        require(balances[ownerContract] >= amount, "Insufficient funds in BudsSupplyOwner");
        balances[ownerContract] -= amount;
        balanceFromRewardsFee += amount;
        emit CommunityRewardsAdded(amount, block.timestamp);
    }
    
    function moveBalanceFromLiquidityFee(uint amount, address destination) public onlyOwner {
        require(amount >= balanceFromLiquidityFee, "balanceFromLiquidityFee funds are less than amount");
        require(
                destination == manualLiquidityWallet
                || destination == zombie 
                || destination == lottery, 
                "Invalid destination"
                );
        balanceFromLiquidityFee -= amount;
        balances[destination] += amount;
        emit BalanceFromLiquidityFeeDistributed (amount, destination, block.timestamp);
    }
    
   function setAddresses(address _goodBudsWallet, address _smokeOutWallet, address _manualLiquidityWallet, address _budsBank, address _lottery, address _zombie) public onlyOwner {
       require(_goodBudsWallet != address(0) && goodBudsWallet == address(0), "Requirement failed");
       goodBudsWallet = _goodBudsWallet;
       smokeOutWallet = _smokeOutWallet;
       manualLiquidityWallet = _manualLiquidityWallet;
       budsBank = _budsBank;
       lottery = _lottery;
       zombie = _zombie;
       isExcludedFromFee[goodBudsWallet] = true;
       isExcludedFromFee[smokeOutWallet] = true;
       isExcludedFromFee[manualLiquidityWallet] = true;
       isExcludedFromFee[lottery] = true;
       isExcludedFromFee[budsBank] = true;
   }

}

contract Derived is Buds() {}

contract BudsSupplyOwner {
    
    address[] managers;
    mapping (address => bool) isManager;
    modifier managersOnly() {
        if(managers.length != 0) {require(isManager[msg.sender], "Only managers can do this"); _;} 
        else {require(msg.sender == genesisManager, "Only the genesisManager can do this"); _;}
    }
    
    address genesisManager = msg.sender;
    
    uint lastApril20thRewardsTime;
    
    Derived budsContract = new Derived();
    
    function addManagers(address account) public managersOnly {
        require(!isManager[account], "That account is already a manager");
        isManager[account] = true;
        managers.push(account);
        if(!budsContract.isCurrentTeamMember(account)) {
           budsContract.addTeamMember(account); 
        }
    }
    
    function setContractAddresses(
        address _goodBudsWallet, 
        address _smokeOutWallet, 
        address _manualLiquidityWallet, 
        address _budsBank,
        address _lottery,
        address _zombie
    ) public managersOnly {
        budsContract.setAddresses(_goodBudsWallet, _smokeOutWallet, _manualLiquidityWallet, _budsBank, _lottery, _zombie);
    }
    
    function removeMananger(address account) public managersOnly {
        require(isManager[account], "That account is already not a manager");
        isManager[account] = false;
        budsContract.removeTeamMember(account);
    }
    
    function viewAuthorization(address account) public view returns(bool) {
        return(isManager[account]);
    } 
    
    function viewManagersAndExManagers() public view returns(address[] memory) {
        return managers;
    }
    
    function addATeamMember(address account) public managersOnly {
        budsContract.addTeamMember(account);
    }
    
    function removeATeamMember(address account) public managersOnly {
        budsContract.removeTeamMember(account);
    }
    
    function transfer(address recipient, uint amount) public managersOnly {
        budsContract.transfer(recipient, amount);
    }
    
    function addMoreRewards(uint amount) public managersOnly {
        budsContract.addMoreRewards(amount);
    }
    
    function moveFundsInLiquidityFee(uint amount, address destination) public managersOnly {
        budsContract.moveBalanceFromLiquidityFee(amount, destination);
    }
    
    function april20thCommunityRewards() public managersOnly {
        if(lastApril20thRewardsTime != 0) {require(block.timestamp - lastApril20thRewardsTime > 31536000 seconds);}
        else {require(msg.sender == genesisManager, "Only the genesisManager can send the first 420 rewards");}
        
        (uint budsContractRewardsFeeBalance, , , , , , , ) = budsContract.viewRewardsAndLiquidityInfo();
        uint fourPointTwoPercent = 4*budsContractRewardsFeeBalance/100 + budsContractRewardsFeeBalance/500;
        budsContract.addMoreRewards(fourPointTwoPercent);
        lastApril20thRewardsTime = block.timestamp;
    }
    
    function rewardsCycleLengthChange(uint howManySecondsLong) public managersOnly {
        budsContract.changeRewardsCycleLength(howManySecondsLong);
    }
    
    function allowDividendDistribution(uint amount) public managersOnly {
        budsContract.allowDistributionOfDividends(amount);
    }
}