// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";
import "./Ownable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract CrowdLinearDistribution is Ownable {

    event CrowdLinearDistributionCreated(address beneficiary);
    event CrowdLinearDistributionInitialized(address from);
    event TokensReleased(address beneficiary, uint256 amount);

    //0: Team_And_Advisors, 1: Community, 2: Investors, 3: Token_Launch_auction, 4: Liquidity
    enum VestingType {
        Team_And_Advisors,
        Community,
        Investors,
        Token_Launch_auction,
        Liquidity
    }

    struct BeneficiaryStruct {
        uint256 _start;
        uint256 _initial;
        uint256 _released;
        uint256 _balance;
        uint256 _vestingType;
        bool _exist;
        Ruleset[] _ruleset;
    }

    struct VestingTypeStruct {
        uint256 _initial;
        uint256 _allocatedInitial;
        Ruleset[] _ruleset;
    }

    struct Ruleset {
        uint256 _month;
        uint256 _value;//VestingTypeStruct: coefficient, BeneficiaryStruct: amount
    }

    mapping(address => BeneficiaryStruct) public _beneficiaryIndex;
    mapping(VestingType => VestingTypeStruct) public _vestingTypeIndex;
    address[] public _beneficiaries;
    address public _tokenAddress;

    constructor () {

        VestingTypeStruct storage teamVestingTypeStruct = _vestingTypeIndex[VestingType.Team_And_Advisors];
        teamVestingTypeStruct._initial = 40000000 ether;
        teamVestingTypeStruct._ruleset.push(Ruleset(5, 100));
        teamVestingTypeStruct._ruleset.push(Ruleset(11, 200));
        teamVestingTypeStruct._ruleset.push(Ruleset(17, 325));
        teamVestingTypeStruct._ruleset.push(Ruleset(1000, 500));

        VestingTypeStruct storage communityVestingTypeStruct = _vestingTypeIndex[VestingType.Community];
        communityVestingTypeStruct._initial = 10000000 ether;
        communityVestingTypeStruct._ruleset.push(Ruleset(5, 100));
        communityVestingTypeStruct._ruleset.push(Ruleset(11, 200));
        communityVestingTypeStruct._ruleset.push(Ruleset(17, 325));
        communityVestingTypeStruct._ruleset.push(Ruleset(1000, 500));

        VestingTypeStruct storage investorsVestingTypeStruct = _vestingTypeIndex[VestingType.Investors];
        investorsVestingTypeStruct._initial = 20000000 ether;
        investorsVestingTypeStruct._ruleset.push(Ruleset(5, 100));
        investorsVestingTypeStruct._ruleset.push(Ruleset(11, 200));
        investorsVestingTypeStruct._ruleset.push(Ruleset(17, 325));
        investorsVestingTypeStruct._ruleset.push(Ruleset(1000, 500));

        VestingTypeStruct storage auctionVestingTypeStruct = _vestingTypeIndex[VestingType.Token_Launch_auction];
        auctionVestingTypeStruct._initial = 50000000 ether;
        auctionVestingTypeStruct._ruleset.push(Ruleset(9, 100));
        auctionVestingTypeStruct._ruleset.push(Ruleset(1000, 200));

        VestingTypeStruct storage liquidityVestingTypeStruct = _vestingTypeIndex[VestingType.Liquidity];
        liquidityVestingTypeStruct._initial = 100000000 ether;
        liquidityVestingTypeStruct._ruleset.push(Ruleset(1, 120));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(2, 140));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(3, 160));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(4, 180));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(5, 200));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(6, 220));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(7, 240));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(8, 260));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(9, 280));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(10, 300));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(11, 320));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(12, 340));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(13, 360));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(14, 380));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(15, 400));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(16, 420));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(17, 440));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(18, 460));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(19, 480));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(20, 500));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(21, 520));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(22, 540));
        liquidityVestingTypeStruct._ruleset.push(Ruleset(1000, 550));
    }

    fallback() external {
        revert("ce01");
    }

    /**
     * @notice initialize contract.
     */
    function initialize(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0) , "CrowdLinearDistribution: the token address is not valid");
        _tokenAddress = tokenAddress;

        emit CrowdLinearDistributionInitialized(address(msg.sender));
    }
    
    function create(address beneficiary, uint256 start, uint8 vestingType, uint256 initial) external onlyOwner {
        require(_tokenAddress != address(0), "CrowdLinearDistribution: the token address is not valid");
        require(!_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary exists");
        require(vestingType >= 0 && vestingType < 5, "CrowdLinearDistribution: vestingType is not valid");
        require(initial > 0, "CrowdLinearDistribution: initial must be greater than zero");

        VestingTypeStruct storage vestingTypeStruct = _vestingTypeIndex[VestingType(vestingType)];
        require(initial + vestingTypeStruct._allocatedInitial <= vestingTypeStruct._initial, "CrowdLinearDistribution: Not enough token to distribute");

        _beneficiaries.push(beneficiary);
        BeneficiaryStruct storage beneficiaryStruct = _beneficiaryIndex[beneficiary];
        beneficiaryStruct._start = start;
        beneficiaryStruct._initial = initial;
        beneficiaryStruct._vestingType = vestingType;
        beneficiaryStruct._exist = true;
        for(uint i = 0; i < vestingTypeStruct._ruleset.length; i++) {
            Ruleset memory ruleset = vestingTypeStruct._ruleset[i];
            beneficiaryStruct._ruleset.push(Ruleset(ruleset._month, calculateAmount(ruleset._value, initial)));
        }
        beneficiaryStruct._balance = beneficiaryStruct._ruleset[vestingTypeStruct._ruleset.length - 1]._value;

        vestingTypeStruct._allocatedInitial = vestingTypeStruct._allocatedInitial + initial;

        emit CrowdLinearDistributionCreated(beneficiary);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release(address beneficiary) external {
        require(_tokenAddress != address(0), "CrowdLinearDistribution: token address not valid");
        uint256 unreleased = getReleasable(beneficiary);

        require(unreleased > 0, "CrowdLinearDistribution: releasable amount is zero");

        _beneficiaryIndex[beneficiary]._released = _beneficiaryIndex[beneficiary]._released + unreleased;
        _beneficiaryIndex[beneficiary]._balance = _beneficiaryIndex[beneficiary]._balance - unreleased;
        
        IERC20(_tokenAddress).transfer(beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }
    
    function getBeneficiaries(uint256 vestingType) external view returns (address[] memory) {
        require(vestingType >= 0 && vestingType < 5, "CrowdLinearDistribution: vestingType is not valid");

        uint256 j = 0;
        address[] memory beneficiaries = new address[](_beneficiaries.length);

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            address beneficiary = _beneficiaries[i];
            if (_beneficiaryIndex[beneficiary]._vestingType == vestingType) {
                beneficiaries[j] = beneficiary;
                j++;
            }

        }
        return beneficiaries;
    }

    function getVestingType(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._vestingType;
    }

    function getBeneficiary(address beneficiary) external view returns (BeneficiaryStruct memory) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary];
    }

    function getInitial(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._initial;
    }

    function getStart(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._start;
    }

    function getTotal(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._balance + _beneficiaryIndex[beneficiary]._released;
    }

    function getVested(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _vestedAmount(beneficiary);
    }

    function getReleased(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _beneficiaryIndex[beneficiary]._released;
    }
    
    function getBalance(address beneficiary) external view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return uint256(_beneficiaryIndex[beneficiary]._balance);
    }

    function getVestingTypeStruct(uint256 vestingType) external view returns (VestingTypeStruct memory) {
        require(vestingType >= 0 && vestingType < 5, "CrowdLinearDistribution: vestingType is not valid");

        return _vestingTypeIndex[VestingType(vestingType)];
    }

    /**
     * @notice Returns the releasable amount of token for the given beneficiary
     */
    function getReleasable(address beneficiary) public view returns (uint256) {
        require(_beneficiaryIndex[beneficiary]._exist, "CrowdLinearDistribution: beneficiary does not exist");

        return _vestedAmount(beneficiary) - _beneficiaryIndex[beneficiary]._released;
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount(address beneficiary) private view returns (uint256) {
        BeneficiaryStruct storage tokenVesting = _beneficiaryIndex[beneficiary];
        uint256 totalBalance = tokenVesting._balance + tokenVesting._released;

        if (block.timestamp < tokenVesting._start)
            return 0;

        uint256 _months = BokkyPooBahsDateTimeLibrary.diffMonths(tokenVesting._start, block.timestamp);

        if (_months < 1)
            return tokenVesting._initial;

        uint256 result = 0;
        for (uint256 i = 0; i < tokenVesting._ruleset.length; i++) {
            Ruleset memory ruleset = tokenVesting._ruleset[i];
            if (_months <= ruleset._month) {
                result = ruleset._value;
                break;
            }
        }

        return (result >= totalBalance) ? totalBalance : result;
    }

    function calculateAmount(uint coefficient, uint beneficiaryInitial) private pure returns (uint) {
        return (coefficient * beneficiaryInitial) / (10 ** 2);
    }

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

pragma solidity ^0.8.10;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp, 'BP03');
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ce30");
        _;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == _pendingOwner, "ce31");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _pendingOwner);
    }
}