// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Rounds
/// @author Jonah Burian, Anna Lulushi, Chunda McCain, Sophie Fujiwara
/// @notice This contract is not ready to be deployed on mainnet
/// @dev All function calls are currently in testing
contract Rounds is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //----------State Variables-----------

    // owner state variable is inherited from Ownable interface

    // The id of the next created offering. incremented each time a offering is created.
    uint private openOfferingId;

    /// @notice The whitelist map for each investor
    /// @dev maps investor => (offeringid => canInvest)
    mapping(address =>  mapping(uint => bool)) public whitelist;

    /// @notice The map to store pending withdraws for each investor
    /// @dev maps investor => (ERC20 => amount : Rejected investments by offerings)
    mapping(address =>  mapping(IERC20 =>  uint)) public pendingWithdrawsMap;

    /// @notice The map of each offering id to OfferingInfo struct
    mapping(uint =>  OfferingInfo) public offeringMap;

    /// @notice OfferingInfo struct for each offering
    /// @param stage current stage of the offering
    /// @param company address of the compainy raising funds
    /// @param ERC20Token ERC20 token used for funding
    /// @param pendingInvestmentMap funds recieved by company but not accepted or rejected
    /// @param canAcceptAll indicates whether the company is able to accept all funds
    struct OfferingInfo {
        Stages stage;
        address company;
        IERC20 ERC20Token;
        mapping(address => PendingInvestment) pendingInvestmentMap;
        bool canAcceptAll;
    }

    /// @notice PendingInvestment struct for each investment
    /// @param canAccept indicates whether the company can accept the investment
    /// @param amount the amount to be invested. When true, withdraw is enabled.
    struct PendingInvestment {
        bool canAccept;
        uint amount;
    }

    /// @notice Stages enum for offerings
    /// @param DoesNotExist only availible function is intializing offering -> OfferingOpen
    /// @param Active 1) Investors can invest, 2) Companies can accept and reject investments, 3) Investors can withdraw rejected funds but NOT pending funds
    /// @param Inactive 1) Investors CANNOT invest, 2) Companies can accept and reject investments, 3) Investors can withdraw rejected funds but NOT pending funds
    /// @param Archived 1) Investors CANNOT invest, 2) Companies CANNOT accept or reject investments, 3) Investors can withdraw rejected funds and pending funds
    enum Stages {
        DoesNotExist,
        Active,
        Inactive,
        Archived
    }

    //----------Events--------------

    event NewOffering(uint id, address company, address ERC20Token);

    event Whitelist(address investor, uint offeringId);

    event NextStage(uint offeringId, Stages stage);

    event SingleInvestmentUnlocked(uint offeringId, address investor);

    event AllInvestmentsUnlocked(uint offeringId);

    event Investment(uint offeringId, address investor, uint amount);

    event InvestmentRejected(uint offeringId, address investor, uint amount);

    event InvestmentAccepted(uint offeringId, address investor, uint amount);

    event InvestorWithdrawFromPendingWithdraws(address investor, address ERC20Token, uint amount);

    event InvestorWithdrawFromFinishedOffering(uint _offeringId, address _investor, uint _amount);

    //----------Modifiers-----------

    //onlyOwner modifier is inherited

    /// @notice Revert if sender is not the owner or company
    /// @param _offeringId The offering of the company
    modifier onlyCompanyOrOwner(uint _offeringId) {
        address sender = msg.sender;
        require(sender == owner() || sender == offeringMap[_offeringId].company, "Caller is not the owner or company");
        _;
    }

    /// @notice Revert if sender is not the company
    /// @param _offeringId The offering of the company
    modifier onlyCompany(uint _offeringId) {
        address sender = msg.sender;
        require(sender == offeringMap[_offeringId].company, "Caller is not the company");
        _;
    }

    /// @notice Revert if an address is the zero address
    /// @param _address The address being tested
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot be zero address");
        _;
    }

    /// @notice Checks that two addreses are not the same
    /// @param _address1 The first address
    /// @param _address2 The second address
    modifier addressesNotEqual(address _address1, address _address2) {
        require(_address1 != _address2, "Addresses cannot be the same");
        _;
    }

    /// @notice Checks that the offering is at a valid stage
    /// @param _offeringId The id of the offering
    /// @param _stage The valid stage
    modifier atStage(uint _offeringId, Stages _stage) {
        require(offeringMap[_offeringId].stage == _stage, "Action not allowed in current stage");
        _;
    }

    /// @notice Checks that the offering is not at an invalid stage
    /// @param _offeringId The id of the offering
    /// @param _stage The invalid stage
    modifier notAtStage(uint _offeringId, Stages _stage) {
        require(offeringMap[_offeringId].stage != _stage, "Action not allowed in current stage");
        _;
    }


    /// @notice Checks that an investor is whitelisted for a particular offering
    /// @param _offeringId The id of the offering
    modifier investorWhitelisted(uint _offeringId) {
        require(whitelist[msg.sender][_offeringId], "Investor is not whitelisted");
        _;
    }

    /// @notice Checks that an investor is not whitelisted for a particular offering
    /// @param _investor The address of the investor
    /// @param _offeringId The id of the offering
    modifier investorNotWhitelisted(address _investor, uint _offeringId) {
        require(!whitelist[_investor][_offeringId], "Investor is already whitelisted");
        _;
    }

    /// @notice Checks that pending investment is not zero
    /// @param _investor The address of the investor
    /// @param _offeringId The id of the offering
    modifier pendingInvestmentNotZero(uint _offeringId, address _investor) {
        require(_getPendingInvestment(_offeringId, _investor) > 0, "There is no pending investment");
        _;
    }

    /// @notice Checks that there is a balance in pending withdraws
    /// @param _token Token to check
    modifier pendingWithdrawsNotZero(address _investor, IERC20 _token) {
        require(pendingWithdrawsMap[_investor][_token] > 0, "There is no balance to withdraw");
        _;
    }

    /// @notice Checks if the investor is able to withdraw
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    modifier companyCanAcceptInvestment(uint _offeringId, address _investor) {
        require(_canCompanyAcceptInvestment(_offeringId, _investor), "Company not permitted to accept");
        _;
    }

    modifier companyCantAlreadyHavePermission(uint _offeringId, address _investor) {
        require(!_canCompanyAcceptInvestment(_offeringId, _investor), "Company already permitted to Accept");
        _;
    }
    /// @notice Checks whether the investment amount is greater than zero
    /// @param _amount The amount of the investment
    modifier amountGreaterThanZero(uint _amount) {
        require(_amount > 0, "Investment must be greater than zero");
        _;
    }

    //----------Accessors-----------

    /// @notice Get pending investment amount for a given offering and investor
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    /// @return amount The amount in pending investment the investor has for given offering
    function getPendingInvestment(uint _offeringId, address _investor) external view returns (uint amount) {
       return _getPendingInvestment(_offeringId, _investor);
    }

    /// @notice Get withdrawable amount for a given IERC20
    /// @dev Function is called by an investor
    /// @param token The desired IERC20
    /// @return amount The withdrawable amount the investor has for given IERC20
    function getWithdrawableAmount(IERC20 token) external view returns (uint amount) {
        return _getWithdrawableAmount(msg.sender, token);
    }

    /// @notice Check whether canAccept field for an investor is set
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    /// @return canAccept True if the company can accept the investor's investment, false otherwise
    function getCanAccept(uint _offeringId, address _investor) external view returns (bool canAccept) {
        return offeringMap[_offeringId].pendingInvestmentMap[_investor].canAccept;
    }

    //----------External Functions-----------

    /// @notice Does not allow owner to renounce ownership or else funds would get stuck
    /// @dev WE NEED TO RESEARCH WHETHER THIS IS STANDARD
    function renounceOwnership() public virtual onlyOwner override {
        require(false, "Ownership is not transferrable");
    }

    /// @notice Creates a new offering info struct and adds it to the map.
    /// @dev We do not test that the _ERC20Token follows the standared ERC20 interface. We may want to add more modifiers and a return
    /// @param _company Address of the company
    /// @param _ERC20Token Address of the ERC20
    function createOffering(address _company, address _ERC20Token)
        external
        onlyOwner
        addressesNotEqual(_company, _ERC20Token)
        notZeroAddress(_company)
        notZeroAddress(_ERC20Token) {
            uint id = openOfferingId;
            _createOffering(_company, _ERC20Token);
            emit NewOffering(id, _company, _ERC20Token);
    }

    /// @notice Add investor to whitelist
    /// @dev We need to check that we don't want any more modifiers
    /// @param _investor Address of the investor
    /// @param _offeringId The id of the offering
    function addWhitelist(address _investor, uint _offeringId)
        external
        onlyOwner
        notZeroAddress(_investor)
        atStage(_offeringId, Stages(1))
        addressesNotEqual(_investor, offeringMap[_offeringId].company)
        investorNotWhitelisted(_investor, _offeringId) {
            _addWhitelist(_investor, _offeringId);
            emit Whitelist(_investor, _offeringId);
    }

    /// @notice Move a offering to the next stage
    /// @dev We only allow this action in offering 1 or 2. In offering 0, the offering is not created and in offering 3 the offering is closed
    /// @param _offeringId The id of the offering
    function nextStage(uint _offeringId)
        external
        onlyCompanyOrOwner(_offeringId)
        notAtStage(_offeringId, Stages(0))
        notAtStage(_offeringId, Stages(3)) {
            _nextStage(_offeringId);
            //event below
    }

    /// @notice Enable an offering to accept a single investment
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    function enableCanAcceptSingleInvestment(uint _offeringId, address _investor)
        external
        onlyOwner
        notAtStage(_offeringId, Stages(0))
        notAtStage(_offeringId, Stages(3))
        companyCantAlreadyHavePermission(_offeringId, _investor)
        pendingInvestmentNotZero(_offeringId, _investor) {
            _enableCanAcceptSingleInvestment(_offeringId, _investor);
             emit SingleInvestmentUnlocked(_offeringId, _investor);
    }

    /// @notice Allow a company to accept all investments (should only be called if they have offline cross singned all docs)
    /// @dev Only allowed in stage 2 because there are no new investors
    /// @param _offeringId The id of the offering
    function enableCanAcceptAll(uint _offeringId)
        external
        onlyOwner
        atStage(_offeringId, Stages(2)) {
            _enableCanAcceptAll(_offeringId);
            emit AllInvestmentsUnlocked(_offeringId);
    }

    /// @notice Allow an investor to invest in an offering
    /// @dev Function is called by an investor
    /// @param _offeringId The id of the offering
    /// @param _amount The amount to be invested
    function invest(uint _offeringId, uint _amount)
        external
        investorWhitelisted(_offeringId)
        atStage(_offeringId, Stages(1))
        amountGreaterThanZero(_amount) {
            address investor = msg.sender;
            _invest(investor, _offeringId, _amount);
            emit Investment(_offeringId, investor, _amount);
    }

    /// @notice Rejects an investor's investment for given offering
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    function rejectInvestment(uint _offeringId, address _investor)
        external
        onlyCompanyOrOwner(_offeringId)
        notAtStage(_offeringId, Stages(0))
        notAtStage(_offeringId, Stages(3))
        pendingInvestmentNotZero(_offeringId, _investor) {
            _rejectInvestment(_offeringId, _investor);
            //event below
    }

    /// @notice Accept an investment for an offering
    /// @param _offeringId The id of the offering
    /// @param _investor The address of theinvestor
    function acceptInvestment(uint _offeringId, address _investor)
        external
        onlyCompany(_offeringId)
        companyCanAcceptInvestment(_offeringId, _investor)
        pendingInvestmentNotZero(_offeringId, _investor) {
            whitelist[_investor][_offeringId] = false;
            uint amount = _getPendingInvestment(_offeringId, _investor);
            _sendPendingInvestment(_offeringId, _investor, msg.sender);
            emit InvestmentAccepted(_offeringId, _investor, amount);
    }

    /// @notice Withdraw all funds from archived offerings for a given token
    /// @dev Function is called by an investor
    /// @param _token IERC20 token to withdraw funds in
    function withdrawFromPendingWithdraws(IERC20 _token)
        external
        pendingWithdrawsNotZero(msg.sender, _token) {
            address investor = msg.sender;
            uint amount = _getWithdrawableAmount(investor, _token);
            _withdrawFromPendingWithdraws(investor, _token);
            emit InvestorWithdrawFromPendingWithdraws(investor, address(_token), amount);
    }

    /// @notice Withdraw pending funds from an archived offering
    /// @dev Function is called by an investor
    /// @param _offeringId The id of the offering
    function withdrawFromFinishedOffering(uint _offeringId)
        external
        atStage(_offeringId, Stages(3))
        pendingInvestmentNotZero(_offeringId, msg.sender) {
            address investor = msg.sender;
            uint amount = _getPendingInvestment(_offeringId, investor);
            _sendPendingInvestment(_offeringId, investor, investor);
             emit InvestorWithdrawFromFinishedOffering(_offeringId, investor, amount);
    }

    //----------Internal Functions-----------

    // @notice Check whether a company can accept an investment from given investor
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    /// @return locked True if the company can accept the investment, false otherwise
    function canCompanyAcceptInvestment(uint _offeringId, address _investor) external view returns (bool locked) {
        return _canCompanyAcceptInvestment(_offeringId, _investor);
    }


    /// @notice Internal helper function to get pending investment amount for a given offering and investor
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    /// @return amount The amount in pending investment the investor has for given offering
    function _getPendingInvestment(uint _offeringId, address _investor) internal view returns (uint amount) {
        return offeringMap[_offeringId].pendingInvestmentMap[_investor].amount;
    }

    /// @notice Internal helper function to get withdrawable amount for a given IERC20
    /// @param investor The address of the investor
    /// @param token The desired IERC20
    /// @return amount The withdrawable amount the investor has for given IERC20
    function _getWithdrawableAmount(address investor, IERC20 token) internal view returns (uint amount) {
        return pendingWithdrawsMap[investor][token];
    }

    /// @notice Internal helper function to check whether a company can accept an investment from given investor
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    /// @return locked True if the company can accept the investment, false otherwise
    function _canCompanyAcceptInvestment(uint _offeringId, address _investor) internal view returns (bool locked) {
        OfferingInfo storage offering = offeringMap[_offeringId];
        bool canAll = offering.canAcceptAll;
        bool canParticular = offering.pendingInvestmentMap[_investor].canAccept;
        Stages stage = offering.stage;
        return (canParticular && (stage == Stages(1))) || ((canParticular || canAll) && (stage == Stages(2)));
    }

    /// @notice Internal helper function to create an offering
    /// @dev Need to figure out what happens if openOfferingId breaks
    /// @param _company Address of the company
    /// @param _ERC20Token Address of the ERC20
    function _createOffering(address _company, address _ERC20Token) internal {
        OfferingInfo storage offering = offeringMap[openOfferingId];
        assert(offering.stage == Stages(0));
        offering.stage = Stages(1);
        offering.company = _company;
        offering.ERC20Token = IERC20(_ERC20Token);
        openOfferingId = openOfferingId.add(1); // next offering will have id 1
    }

    /// @notice Add investor to whitelist helper
    /// @dev Need to figure out what happens if openOfferingId breaks
    /// @param _investor Address of the investor
    /// @param _offeringId The id of the offering
    function _addWhitelist(address _investor, uint _offeringId) internal {
        whitelist[_investor][_offeringId] = true;
    }

    /// @notice Internal helper function to move a offering to the next stage
    /// @dev If the offering is moved to stage 3 the company cannot accept investments
    /// @param _offeringId The id of the offering
    function _nextStage(uint _offeringId) internal {
        Stages currStage = offeringMap[_offeringId].stage;
        Stages newStage = Stages(uint(currStage).add(1));

        //in offering 3 the company cannot accept investments
        if (newStage == Stages(3)) {
            offeringMap[_offeringId].canAcceptAll = false;
        }

        offeringMap[_offeringId].stage = newStage;
        emit NextStage(_offeringId, newStage);
    }

    /// @notice Internal helper function to allow a company to accept all investments
    /// @dev Require canAcceptAll to be false - this can be switched
    /// @param _offeringId The id of the offering
    function _enableCanAcceptAll(uint _offeringId) internal {
        OfferingInfo storage offering = offeringMap[_offeringId];
        require(!offering.canAcceptAll, "canAcceptAll is already true");
        offering.canAcceptAll = true;
    }

    /// @notice Internal helper function to allow an investor to invest in an offering
    /// @param _investor Address of investor
    /// @param _offeringId Id of the offering
    /// @param _amount Amount to be invested
    function _invest(address _investor, uint _offeringId, uint _amount) internal {
        OfferingInfo storage offering = offeringMap[_offeringId];
        assert(_investor != offering.company); //company cannot be investor
        IERC20 token = offering.ERC20Token;

        offering.pendingInvestmentMap[_investor].canAccept = false; //investment is now locked
        whitelist[_investor][_offeringId] = false; //investor cannot invest twice
        uint currAmount = _getPendingInvestment(_offeringId, _investor);

        token.safeTransferFrom(_investor, address(this), _amount); //transfer

        offering.pendingInvestmentMap[_investor].amount = currAmount.add(_amount); //after to prevent reentry attacks
    }

    /// @notice Internal helper function to reject an investment for given offering
    /// @dev Sets fields in pendingInvestmentMap and pendingWithdrawsMap appropriately
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    function _rejectInvestment(uint _offeringId, address _investor) internal {
        OfferingInfo storage offering = offeringMap[_offeringId];
        IERC20 token = offering.ERC20Token;

        uint currPendingAmount = _getPendingInvestment(_offeringId, _investor);
        uint currWithdrawAmount = pendingWithdrawsMap[_investor][token];

        offering.pendingInvestmentMap[_investor].canAccept = false; //investment is now locked
        offering.pendingInvestmentMap[_investor].amount = 0;
        pendingWithdrawsMap[_investor][token] = currWithdrawAmount.add(currPendingAmount);
        emit InvestmentRejected(_offeringId, _investor, currPendingAmount);
    }

    /// @notice Internal helper function to accept an offering to accept a single investment
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    function _enableCanAcceptSingleInvestment(uint _offeringId, address _investor) internal {
        OfferingInfo storage offering = offeringMap[_offeringId];
        offering.pendingInvestmentMap[_investor].canAccept = true;
    }

    /// @notice Internal function to send funds for an offering from pendingInvestmentMap to destination
    /// @param _offeringId The id of the offering
    /// @param _investor The address of the investor
    /// @param _to The address where funds are sent
    function _sendPendingInvestment(uint _offeringId, address _investor, address _to) internal {
        OfferingInfo storage offering = offeringMap[_offeringId];
        IERC20 token = offering.ERC20Token;
        uint currPendingAmount = _getPendingInvestment(_offeringId, _investor);
        PendingInvestment storage pending = offering.pendingInvestmentMap[_investor];

        pending.amount = 0;
        pending.canAccept = false;
        token.safeTransfer(_to, currPendingAmount);
    }

    /// @notice Internal function to withdraw all funds from archived offerings for a given token
    /// @dev Function is called by an investor
    /// @param _token IERC20 token to withdraw funds in
    function _withdrawFromPendingWithdraws(address _investor, IERC20 _token) internal {
        uint currPendingAmount = pendingWithdrawsMap[_investor][_token];
        pendingWithdrawsMap[_investor][_token] = 0;
        _token.safeTransfer(_investor, currPendingAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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