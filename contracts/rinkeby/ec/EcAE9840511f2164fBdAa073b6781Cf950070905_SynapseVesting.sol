// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { ReentrancyGuard } from "./external/openzeppelin/ReentrancyGuard.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";

/**
 @title Synapse Network Vesting contract
 */
contract SynapseVesting is Ownable, ReentrancyGuard {
    // Address of Synapse Network token
    address public immutable snpToken;
    // Total tokens vested in contract
    uint256 public totalVested;
    // Total tokens already claimed form vesting
    uint256 public totalClaimed;
    /// staking contract address, set buy Owner
    address public stakingAddress;

    struct Vest {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }
    // storage of vestings
    Vest[] internal vestings;
    // map of vestings for user
    mapping(address => uint256[]) internal user2vesting;

    // events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount, uint256 endDate);

    /**
    @notice contract constructor, deployer is owner
    @param token address of SNP token
    */
    constructor(address token) {
        require(token != address(0), "token address cannot be 0");
        snpToken = token;
    }

    /**
    @notice add multiple vesting to contract by arrays of data
    @param user[] address of holder
    @param startTokens[] tokens that can be withdrawn at startDate
    @param totalTokens[] total tokens in vesting
    @param startDate date from tokens can be claimed
    @param endDate date after all tokens can be claimed
    */
    function massAddHolders(
        address[] calldata user,
        uint256[] calldata startTokens,
        uint256[] calldata totalTokens,
        uint256 startDate,
        uint256 endDate
    ) external onlyOwner {
        uint256 len = user.length; //cheaper to use one variable
        require((len == startTokens.length) && (len == totalTokens.length), "Data size mismatch");
        require(startDate < endDate, "startDate cannot exceed endDate");
        uint256 i;
        for (i; i < len; i++) {
            _addHolder(user[i], startTokens[i], totalTokens[i], startDate, endDate);
        }
    }

    /**
    @dev Add new vesting to contract
    @param user address of holder
    @param startTokens how many tokens are claimable at start date
    @param totalTokens total number of tokens in vesting
    @param startDate timestamp when you can take startTokens
    @param endDate date after you can take all tokens from vesting
    */
    function _addHolder(
        address user,
        uint256 startTokens,
        uint256 totalTokens,
        uint256 startDate,
        uint256 endDate
    ) internal {
        require(user != address(0), "user address cannot be 0");
        Vest memory v;
        v.startTokens = startTokens;
        v.totalTokens = totalTokens;
        v.dateStart = startDate;
        v.dateEnd = endDate;

        totalVested += totalTokens;
        vestings.push(v);
        user2vesting[user].push(vestings.length); // we are skipping index "0" for reasons
        emit Vested(user, totalTokens, endDate);
    }

    /**
    @notice Claim all tokens from all your vestings
    */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
    @notice Claim own tokens to another address
    @param target where send claimed tokens
    */
    function claimTo(address target) external {
        _claim(msg.sender, target);
    }

    /**
    Stake claimed tokens directly to stake contract
    */
    function claimAndStake() external {
        require(stakingAddress != address(0), "Staking contract not configured");
        require(IStaking(stakingAddress).canStakeTokens(msg.sender), "Unable to stake");
        uint256 amt = _claim(msg.sender, stakingAddress);
        IStaking(stakingAddress).onClaimAndStake(msg.sender, amt);
    }

    /**
    @dev internal claim function
    @param user address of holder
    @param target where tokens should be send
    @return amt number of tokens claimed
    */
    function _claim(address user, address target) internal nonReentrant returns (uint256 amt) {
        if (!vestingAdded[user]) {
            _addVesting(user);
        }
        require(target != address(0), "claim, then burn");
        uint256 len = user2vesting[user].length;
        require(len > 0, "No vestings for user");
        uint256 cl;
        uint256 i;
        for (i; i < len; i++) {
            Vest storage v = vestings[user2vesting[user][i] - 1];
            cl = _claimable(v);
            v.claimedTokens += cl;
            amt += cl;
        }
        if (amt > 0) {
            _transfer(target, amt);
            emit Claimed(user, amt);
        } else revert("nothing to claim");
    }

    /**
    @dev internal function to send out claimed tokens
    @param user address that we send tokens
    @param amt amount of tokens
    */
    function _transfer(address user, uint256 amt) internal {
        totalClaimed += amt;
        require(IERC20(snpToken).transfer(user, amt), "Token transfer failed");
    }

    /**
    @dev how much tokens can be claimed from vesting to date
    @param v Vesting object
    @return canWithdraw number of tokens
    */
    function _claimable(Vest memory v) internal view returns (uint256 canWithdraw) {
        uint256 currentTime = block.timestamp;
        if (v.dateStart > currentTime) return 0;
        // we are somewhere in the middle
        if (currentTime < v.dateEnd) {
            // how much time passed (as fraction * 10^18)
            uint256 timeRatio = ((currentTime - v.dateStart) * 1 ether) / (v.dateEnd - v.dateStart);
            // how much tokens we can get in total to date
            canWithdraw = (((v.totalTokens - v.startTokens) * timeRatio) / 1 ether) + v.startTokens;
        }
        // time has passed, we can take all tokens
        else {
            canWithdraw = v.totalTokens;
        }
        // but maybe we take something earlier?
        canWithdraw -= v.claimedTokens;
    }

    /**
    @notice read claimable tokens by user and vesting no
    @param user address of holder
    @param id his vesting number (starts from 0)
    */
    function getClaimable(address user, uint256 id) external view returns (uint256 amount) {
        amount = _claimable(vestings[user2vesting[user][id] - 1]);
    }

    /**
    @notice read total amount of tokens that user can claim to date
    @param user address of holder
    */
    function getAllClaimable(address user) public view returns (uint256 amount) {
        uint256 len = user2vesting[user].length;
        uint256 i;
        for (i; i < len; i++) {
            amount += _claimable(vestings[user2vesting[user][i] - 1]);
        }

        if (!vestingAdded[user]) {
            amount += _claimableFromSaleContracts(user);
        }
    }

    /**
    @notice dump all vestings from user
    @param user address of holder
    @return v array of Vest objects
    */
    function getVestings(address user) external view returns (Vest[] memory v) {
        Vest[] memory pV;
        if (!vestingAdded[user]) {
            pV = _vestingsFromSaleContracts(user);
        }

        uint256 len = user2vesting[user].length;
        uint256 pLen = pV.length;
        v = new Vest[](len + pLen);

        // copy normal vestings
        uint256 i;
        for (i; i < len; i++) {
            v[i] = vestings[user2vesting[user][i] - 1];
        }

        // copy not initialized vestings
        if (!vestingAdded[user]) {
            uint256 j;
            for (j; j < pLen; j++) {
                v[i] = pV[j];
                i++;
            }
        }

        return v;
    }

    /**
    @notice read total number of vestings registered
    @return number of vestings on contract
    */
    function getVestingsCount() external view returns (uint256) {
        return vestings.length;
    }

    /**
    @notice read single vesting entry
    @param id number of vesting in storage
    @return Vest object
    */
    function getVestingByIndex(uint256 id) external view returns (Vest memory) {
        return vestings[id];
    }

    /**
    @notice read vesting list by range from-to
    @param start first index
    @param end last index
    @return array of Vest objects
    */
    function getVestingsByRange(uint256 start, uint256 end) external view returns (Vest[] memory) {
        uint256 cnt = end - start + 1;
        uint256 len = vestings.length;
        require(end < len, "Range error");
        Vest[] memory v = new Vest[](cnt);
        uint256 i;
        for (i; i < cnt; i++) {
            v[i] = vestings[start + i];
        }
        return v;
    }

    //
    // add sale contract parameters
    //
    struct SaleContract {
        address[] contractAddresses;
        uint256 tokensPerCent;
        uint256 maxAmount;
        uint256 percentOnStart;
        uint256 startDate;
        uint256 endDate;
    }
    /// list of sale contract that will be checked
    SaleContract[] internal saleContracts;

    /**
    @notice dump all sale contracts
    @return array of SaleContract objects
    */
    function getSaleContracts() external view returns (SaleContract[] memory) {
        return saleContracts;
    }

    /**
    @notice read total number of sale contracts registered
    @return number of SaleContracts
    */
    function getSaleContractsCount() external view returns (uint256) {
        return saleContracts.length;
    }

    /**
    @notice read single sale contract entry
    @param id number of SaleContract in storage
    @return SaleContract object
    */
    function getSaleContractByIndex(uint256 id) external view returns (SaleContract memory) {
        return saleContracts[id];
    }

    /**
    Register sale contract to be read
    @param contractAddresses    addresses of sale contracts
    @param tokensPerCent        sale price
    @param maxAmount            the maximum amount in USD cents for which user could buy
    @param percentOnStart       percentage of vested coins that can be claimed on start date
    @param startDate            date when initial vesting can be released
    @param endDate              final date of vesting, where all tokens can be claimed
    */
    function addSaleContract(
        address[] memory contractAddresses,
        uint256 tokensPerCent,
        uint256 maxAmount,
        uint256 percentOnStart,
        uint256 startDate,
        uint256 endDate
    ) external onlyOwner {
        require(contractAddresses.length > 0, "Data is missing");
        require(startDate < endDate, "startDate cannot exceed endDate");
        SaleContract memory s;
        s.contractAddresses = contractAddresses;
        s.tokensPerCent = tokensPerCent;
        s.maxAmount = maxAmount;
        s.startDate = startDate;
        s.percentOnStart = percentOnStart;
        s.endDate = endDate;
        saleContracts.push(s);
    }

    //
    // add vesting from sale contract
    //
    /// has user used addVesting function
    mapping(address => bool) public vestingAdded;

    /**
    Import vestings from sale contracts
    */
    function addMyVesting() external {
        _addVesting(msg.sender);
    }

    /**
    Import vestings from sale contract for someone
    */
    function addVesting(address user) external {
        require(user != address(0), "user address cannot be 0");
        _addVesting(user);
    }

    // Function iterate sale contracts and add corresponding vesting for user
    function _addVesting(address user) internal {
        require(!vestingAdded[user], "Already done");
        uint256 len = saleContracts.length;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                if (amt > s.maxAmount) {
                    amt = s.maxAmount;
                }
                // create Vest object
                Vest memory v = _vestFromSaleContractAndAmount(s, amt);
                // update contract data
                totalVested += v.totalTokens;
                vestings.push(v);
                user2vesting[user].push(vestings.length);
                emit Vested(user, v.totalTokens, v.dateEnd);
            }
        }
        vestingAdded[user] = true;
    }

    // Function iterate sale contracts and count claimable amounts for given user
    function _claimableFromSaleContracts(address user) internal view returns (uint256 claimable) {
        uint256 len = saleContracts.length;
        if (len == 0) return 0;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                if (amt > s.maxAmount) {
                    amt = s.maxAmount;
                }
                claimable += _claimable(_vestFromSaleContractAndAmount(s, amt));
            }
        }
    }

    // Function iterate sale contracts and extract not initialized user vestings
    function _vestingsFromSaleContracts(address user) internal view returns (Vest[] memory v) {
        uint256 len = saleContracts.length;
        if (len == 0) return v;
        v = new Vest[](_numberOfVestingsFromSaleContracts(user));
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                if (amt > s.maxAmount) {
                    amt = s.maxAmount;
                }
                v[i] = _vestFromSaleContractAndAmount(s, amt);
            }
        }
    }

    // Function iterate sale contracts and return number of vestings for user
    function _numberOfVestingsFromSaleContracts(address user) internal view returns (uint256 number) {
        uint256 len = saleContracts.length;
        if (len == 0) return 0;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                number++;
            }
        }
    }

    function _vestFromSaleContractAndAmount(SaleContract memory s, uint256 amt) internal pure returns (Vest memory v) {
        v.dateStart = s.startDate;
        v.dateEnd = s.endDate;
        uint256 total = amt * s.tokensPerCent;
        v.totalTokens = total;
        v.startTokens = (total * s.percentOnStart) / 100;
    }

    function recoverETH() external {
        payable(owner).transfer(address(this).balance);
    }

    function recoverErc20(address token) external {
        require(token != snpToken, "Not permitted");
        uint256 amt = IERC20(token).balanceOf(address(this));
        require(amt > 0, "Nothing to recover");
        IBadErc20(token).transfer(owner, amt);
    }

    function setStakingAddress(address staking) external onlyOwner {
        stakingAddress = staking;
    }
}

interface IStaking {
    function canStakeTokens(address _account) external view returns (bool);

    function onClaimAndStake(address from, uint256 amount) external;
}

interface ISaleContract {
    function balanceOf(address user) external view returns (uint256);
}

// Interface for emergency recover any ERC20-tokens,
// even non-erc20-compliant like USDT not returning boolean
interface IBadErc20 {
    function transfer(address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
     */
    function transferOwnership(address _newOwner, bool _direct) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0), "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}