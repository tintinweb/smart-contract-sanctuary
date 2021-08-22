// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { ReentrancyGuard } from "./external/openzeppelin/ReentrancyGuard.sol";

import { StableMath } from "./libraries/StableMath.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";

/**
 * @title   SynapseVesting
 * @notice  Synapse Network Vesting contract
 * @dev     Vesting is constantly releasing tokens every block every second
 */
contract SynapseVesting is Ownable, ReentrancyGuard {
    using StableMath for uint256;

    /// @notice address of Synapse Network token
    address public immutable snpToken;
    /// @notice total tokens vested in contract
    /// @dev tokens from not initialized sale contracts are not included
    uint256 public totalVested;
    /// @notice total tokens already claimed form vesting
    uint256 public totalClaimed;
    /// @notice staking contract address
    /// @dev set buy Owner, for claimAndStake
    address public stakingAddress;

    struct Vest {
        uint256 dateStart; // start of claiming, can claim startTokens
        uint256 dateEnd; // after it all tokens can be claimed
        uint256 totalTokens; // total tokens to claim
        uint256 startTokens; // tokens to claim on start
        uint256 claimedTokens; // tokens already claimed
    }
    /// @notice storage of vestings
    Vest[] internal vestings;
    /// @notice map of vestings for user
    mapping(address => uint256[]) internal user2vesting;

    struct SaleContract {
        address[] contractAddresses; // list of cross sale contracts from sale round
        uint256 tokensPerCent; // amount of tokens per cent for sale round
        uint256 maxAmount; // max amount in USD cents for sale round
        uint256 percentOnStart; // percent of tokens to claim on start
        uint256 startDate; // start of claiming, can claim start tokens
        uint256 endDate; // after it all tokens can be claimed
    }
    /// @notice list of sale contract that will be checked
    SaleContract[] internal saleContracts;

    /// @notice map of users that initialized vestings from sale contracts
    mapping(address => bool) public vestingAdded;
    /// @notice map of users that were refunded after sales
    mapping(address => bool) public refunded;

    /// @dev events
    event Claimed(address indexed user, uint256 amount);
    event Vested(address indexed user, uint256 totalAmount, uint256 endDate);

    /**
     * @dev Contract constructor, deployer is owner
     * @param _token address of SNP token
     */
    constructor(address _token) {
        require(_token != address(0), "token address cannot be 0");
        snpToken = _token;
    }

    /**
     * @dev Add multiple vesting to contract by arrays of data
     * @param _users[] addresses of holders
     * @param _startTokens[] tokens that can be withdrawn at startDate
     * @param _totalTokens[] total tokens in vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function massAddHolders(
        address[] calldata _users,
        uint256[] calldata _startTokens,
        uint256[] calldata _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner {
        uint256 len = _users.length; //cheaper to use one variable
        require((len == _startTokens.length) && (len == _totalTokens.length), "data size mismatch");
        require(_startDate < _endDate, "startDate cannot exceed endDate");
        uint256 i;
        for (i; i < len; i++) {
            _addHolder(_users[i], _startTokens[i], _totalTokens[i], _startDate, _endDate);
        }
    }

    /**
     * @dev Add new vesting to contract
     * @param _user address of a holder
     * @param _startTokens how many tokens are claimable at start date
     * @param _totalTokens total number of tokens in added vesting
     * @param _startDate date from when tokens can be claimed
     * @param _endDate date after which all tokens can be claimed
     */
    function _addHolder(
        address _user,
        uint256 _startTokens,
        uint256 _totalTokens,
        uint256 _startDate,
        uint256 _endDate
    ) internal {
        require(_user != address(0), "user address cannot be 0");
        Vest memory v;
        v.startTokens = _startTokens;
        v.totalTokens = _totalTokens;
        v.dateStart = _startDate;
        v.dateEnd = _endDate;

        totalVested += _totalTokens;
        vestings.push(v);
        user2vesting[_user].push(vestings.length); // we are skipping index "0" for reasons
        emit Vested(_user, _totalTokens, _endDate);
    }

    /**
     * @dev Claim tokens from msg.sender vestings
     */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
     * @dev Claim tokens from msg.sender vestings to external address
     * @param _target transfer address for claimed tokens
     */
    function claimTo(address _target) external {
        _claim(msg.sender, _target);
    }

    /**
     * @dev Claim and stake claimed tokens directly in staking contract
     *      Ask staking contract if user is not in withdrawing state
     */
    function claimAndStake() external {
        require(stakingAddress != address(0), "Staking contract not configured");
        require(IStaking(stakingAddress).canStakeTokens(msg.sender), "Unable to stake");
        uint256 amt = _claim(msg.sender, stakingAddress);
        IStaking(stakingAddress).onClaimAndStake(msg.sender, amt);
    }

    /**
     * @dev internal claim function
     * @param _user address of holder
     * @param _target where tokens should be send
     * @return amt number of tokens claimed
     */
    function _claim(address _user, address _target) internal nonReentrant returns (uint256 amt) {
        if (!vestingAdded[_user]) {
            _addVesting(_user);
        }
        require(_target != address(0), "Claim, then burn");
        uint256 len = user2vesting[_user].length;
        require(len > 0, "No vestings for user");
        uint256 cl;
        uint256 i;
        for (i; i < len; i++) {
            Vest storage v = vestings[user2vesting[_user][i] - 1];
            cl = _claimable(v);
            v.claimedTokens += cl;
            amt += cl;
        }
        if (amt > 0) {
            totalClaimed += amt;
            _transfer(_target, amt);
            emit Claimed(_user, amt);
        } else revert("Nothing to claim");
    }

    /**
     * @dev Internal function to send out claimed tokens
     * @param _user address that we send tokens
     * @param _amt amount of tokens
     */
    function _transfer(address _user, uint256 _amt) internal {
        require(IERC20(snpToken).transfer(_user, _amt), "Token transfer failed");
    }

    /**
     * @dev Count how many tokens can be claimed from vesting to date
     * @param _vesting Vesting object
     * @return canWithdraw number of tokens
     */
    function _claimable(Vest memory _vesting) internal view returns (uint256 canWithdraw) {
        uint256 currentTime = block.timestamp;
        if (_vesting.dateStart > currentTime) return 0;
        // we are somewhere in the middle
        if (currentTime < _vesting.dateEnd) {
            // how much time passed (as fraction * 10^18)
            // timeRatio = (time passed * 1e18) / duration
            uint256 timeRatio = (currentTime - _vesting.dateStart).divPrecisely(_vesting.dateEnd - _vesting.dateStart);
            // how much tokens we can get in total to date
            canWithdraw = (_vesting.totalTokens - _vesting.startTokens).mulTruncate(timeRatio) + _vesting.startTokens;
        }
        // time has passed, we can take all tokens
        else {
            canWithdraw = _vesting.totalTokens;
        }
        // but maybe we take something earlier?
        canWithdraw -= _vesting.claimedTokens;
    }

    /**
     * @dev Read number of claimable tokens by user and vesting no
     * @param _user address of holder
     * @param _id his vesting number (starts from 0)
     * @return amount number of tokens
     */
    function getClaimable(address _user, uint256 _id) external view returns (uint256 amount) {
        amount = _claimable(vestings[user2vesting[_user][_id] - 1]);
    }

    /**
     * @dev Read total amount of tokens that user can claim to date from all vestings
     *      Function also includes tokens to claim from sale contracts that were not
     *      yet initiated for user.
     * @param _user address of holder
     * @return amount number of tokens
     */
    function getAllClaimable(address _user) public view returns (uint256 amount) {
        uint256 len = user2vesting[_user].length;
        uint256 i;
        for (i; i < len; i++) {
            amount += _claimable(vestings[user2vesting[_user][i] - 1]);
        }

        if (!vestingAdded[_user]) {
            amount += _claimableFromSaleContracts(_user);
        }
    }

    /**
     * @dev Extract all the vestings for the user
     *      Also extract not initialized vestings from
     *      sale contracts.
     * @param _user address of holder
     * @return v array of Vest objects
     */
    function getVestings(address _user) external view returns (Vest[] memory v) {
        // array of pending vestings
        Vest[] memory pV;

        if (!vestingAdded[_user]) {
            pV = _vestingsFromSaleContracts(_user);
        }

        uint256 len = user2vesting[_user].length;
        uint256 pLen = pV.length;
        v = new Vest[](len + pLen);

        // copy normal vestings
        uint256 i;
        for (i; i < len; i++) {
            v[i] = vestings[user2vesting[_user][i] - 1];
        }

        // copy not initialized vestings
        if (!vestingAdded[_user]) {
            uint256 j;
            for (j; j < pLen; j++) {
                v[i] = pV[j];
                i++;
            }
        }
    }

    /**
     * @dev Read total number of vestings registered
     * @return number of registered vestings on contract
     */
    function getVestingsCount() external view returns (uint256) {
        return vestings.length;
    }

    /**
     * @dev Read single registered vesting entry
     * @param _id index of vesting in storage
     * @return Vest object
     */
    function getVestingByIndex(uint256 _id) external view returns (Vest memory) {
        return vestings[_id];
    }

    /**
     * @dev Read registered vesting list by range from-to
     * @param _start first index
     * @param _end last index
     * @return array of Vest objects
     */
    function getVestingsByRange(uint256 _start, uint256 _end) external view returns (Vest[] memory) {
        uint256 cnt = _end - _start + 1;
        uint256 len = vestings.length;
        require(_end < len, "range error");
        Vest[] memory v = new Vest[](cnt);
        uint256 i;
        for (i; i < cnt; i++) {
            v[i] = vestings[_start + i];
        }
        return v;
    }

    /**
     * @dev Extract all sale contracts
     * @return array of SaleContract objects
     */
    function getSaleContracts() external view returns (SaleContract[] memory) {
        return saleContracts;
    }

    /**
     * @dev Read total number of sale contracts
     * @return number of SaleContracts
     */
    function getSaleContractsCount() external view returns (uint256) {
        return saleContracts.length;
    }

    /**
     * @dev Read single sale contract entry
     * @param _id index of sale contract in storage
     * @return SaleContract object
     */
    function getSaleContractByIndex(uint256 _id) external view returns (SaleContract memory) {
        return saleContracts[_id];
    }

    /**
     * @dev Register sale contract
     * @param _contractAddresses  addresses of sale contracts
     * @param _tokensPerCent      sale price
     * @param _maxAmount          the maximum amount in USD cents for which user could buy
     * @param _percentOnStart     percentage of vested coins that can be claimed on start date
     * @param _startDate          date when initial vesting can be released
     * @param _endDate            final date of vesting, where all tokens can be claimed
     */
    function addSaleContract(
        address[] memory _contractAddresses,
        uint256 _tokensPerCent,
        uint256 _maxAmount,
        uint256 _percentOnStart,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner {
        require(_contractAddresses.length > 0, "data is missing");
        require(_startDate < _endDate, "startDate cannot exceed endDate");
        SaleContract memory s;
        s.contractAddresses = _contractAddresses;
        s.tokensPerCent = _tokensPerCent;
        s.maxAmount = _maxAmount;
        s.startDate = _startDate;
        s.percentOnStart = _percentOnStart;
        s.endDate = _endDate;
        saleContracts.push(s);
    }

    /**
     * @dev Initialize vestings from sale contracts for msg.sender
     */
    function addMyVesting() external {
        _addVesting(msg.sender);
    }

    /**
     * @dev Initialize vestings from sale contracts for target user
     * @param _user address of user that will be initialized
     */
    function addVesting(address _user) external {
        require(_user != address(0), "User address cannot be 0");
        _addVesting(_user);
    }

    /**
     * @dev Function iterate sale contracts and initialize corresponding
     *      vesting for user.
     * @param _user address that will be initialized
     */
    function _addVesting(address _user) internal {
        require(!refunded[_user], "User refunded");
        require(!vestingAdded[_user], "Already done");
        uint256 len = saleContracts.length;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
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
                user2vesting[_user].push(vestings.length);
                emit Vested(_user, v.totalTokens, v.dateEnd);
            }
        }
        vestingAdded[_user] = true;
    }

    /**
     * @dev Function iterate sale contracts and count claimable amounts for given user.
     *      Used to calculate claimable amounts from not initialized vestings.
     * @param _user address of user to count claimable
     * @return claimable amount of tokens
     */
    function _claimableFromSaleContracts(address _user) internal view returns (uint256 claimable) {
        if (refunded[_user]) return 0;
        uint256 len = saleContracts.length;
        if (len == 0) return 0;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
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

    /**
     * @dev Function iterate sale contracts and extract not initialized user vestings.
     *      Used to return all stored and not initialized vestings.
     * @param _user address of user to extract vestings
     * @return v vesting array
     */
    function _vestingsFromSaleContracts(address _user) internal view returns (Vest[] memory v) {
        if (refunded[_user]) return v;
        uint256 len = saleContracts.length;
        if (len == 0) return v;
        v = new Vest[](_numberOfVestingsFromSaleContracts(_user));
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
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

    /**
     * @dev Function iterate sale contracts and return number of not initialized vestings for user.
     * @param _user address of user to extract vestings
     * @return number of not not initialized user vestings
     */
    function _numberOfVestingsFromSaleContracts(address _user) internal view returns (uint256 number) {
        uint256 len = saleContracts.length;
        uint256 i;
        for (i; i < len; i++) {
            SaleContract memory s = saleContracts[i];
            uint256 sLen = s.contractAddresses.length;
            uint256 j;
            uint256 amt;
            for (j; j < sLen; j++) {
                amt += ISaleContract(s.contractAddresses[j]).balanceOf(_user);
            }
            // amt is in cents, so $100 = 10000
            if (amt > 0) {
                number++;
            }
        }
    }

    /**
     * @dev Return vesting created from given sale and usd cent amount.
     * @param _sale address of user to extract vestings
     * @param _amount address of user to extract vestings
     * @return v vesting from given parameters
     */
    function _vestFromSaleContractAndAmount(SaleContract memory _sale, uint256 _amount) internal pure returns (Vest memory v) {
        v.dateStart = _sale.startDate;
        v.dateEnd = _sale.endDate;
        uint256 total = _amount * _sale.tokensPerCent;
        v.totalTokens = total;
        v.startTokens = (total * _sale.percentOnStart) / 100;
    }

    /**
     * @dev Set staking contract address for Claim and Stake.
     *      Only contract owner can set.
     * @param _staking address
     */
    function setStakingAddress(address _staking) external onlyOwner {
        stakingAddress = _staking;
    }

    /**
     * @dev Mark user as refunded
     * @param _user address of user
     * @param _refunded true=refunded
     */
    function setRefunded(address _user, bool _refunded) external onlyOwner {
        require(_user != address(0), "user address cannot be 0");
        refunded[_user] = _refunded;
    }

    /**
     * @dev Mark multiple refunded users
     * @param _users[] addresses of refunded users
     */
    function massSetRefunded(address[] calldata _users) external onlyOwner {
        uint256 i;
        for (i; i < _users.length; i++) {
            require(_users[i] != address(0), "user address cannot be 0");
            refunded[_users[i]] = true;
        }
    }

    /**
     * @dev Recover ETH from contract to owner address.
     */
    function recoverETH() external {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Recover given ERC20 token from contract to owner address.
     *      Can't recover SNP tokens.
     * @param _token address of ERC20 token to recover
     */
    function recoverErc20(address _token) external {
        require(_token != snpToken, "Not permitted");
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "Nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

/**
 * @title IStaking
 * @dev Interface for claim and stake
 */
interface IStaking {
    function canStakeTokens(address _account) external view returns (bool);

    function onClaimAndStake(address _from, uint256 _amount) external;
}

/**
 * @title ISaleContract
 * @dev Interface for sale contract
 */
interface ISaleContract {
    function balanceOf(address _account) external view returns (uint256);
}

/**
 * @title IBadErc20
 * @dev Interface for emergency recover any ERC20-tokens,
 *      even non-erc20-compliant like USDT not returning boolean
 */
interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

// Based on StableMath from mStable
// https://github.com/mstable/mStable-contracts/blob/master/contracts/shared/StableMath.sol

library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e36 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
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