/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.5.0;



contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract CommunityVesting is Ownable {
    using SafeMath for uint256;

    mapping (address => Holding) public holdings;

    uint256 constant public MinimumHoldingPeriod = 90 days;
    uint256 constant public Interval = 90 days;
    uint256 constant public MaximumHoldingPeriod = 360 days;

    uint256 constant public CommunityCap = 14300000 ether; // 14.3 million tokens

    uint256 public totalCommunityTokensCommitted;

    struct Holding {
        uint256 tokensCommitted;
        uint256 tokensRemaining;
        uint256 startTime;
    }

    event CommunityVestingInitialized(address _to, uint256 _tokens, uint256 _startTime);
    event CommunityVestingUpdated(address _to, uint256 _totalTokens, uint256 _startTime);

    function claimTokens(address beneficiary)
        external
        onlyOwner
        returns (uint256 tokensToClaim)
    {
        uint256 tokensRemaining = holdings[beneficiary].tokensRemaining;
        uint256 startTime = holdings[beneficiary].startTime;
        require(tokensRemaining > 0, "All tokens claimed");

        require(now.sub(startTime) > MinimumHoldingPeriod, "Claiming period not started yet");

        if (now.sub(startTime) >= MaximumHoldingPeriod) {

            tokensToClaim = tokensRemaining;
            delete holdings[beneficiary];

        } else {

            uint256 percentage = calculatePercentageToRelease(startTime);

            uint256 tokensNotToClaim = (holdings[beneficiary].tokensCommitted.mul(100 - percentage)).div(100);
            tokensToClaim = tokensRemaining.sub(tokensNotToClaim);
            tokensRemaining = tokensNotToClaim;
            holdings[beneficiary].tokensRemaining = tokensRemaining;

        }
    }

    function calculatePercentageToRelease(uint256 _startTime) internal view returns (uint256 percentage) {
        // how many 90 day periods have passed
        uint periodsPassed = ((now.sub(_startTime)).div(Interval));
        percentage = periodsPassed.mul(25); // 25% to be released every 90 days
    }

    function initializeVesting(
        address _beneficiary,
        uint256 _tokens,
        uint256 _startTime
    )
        external
        onlyOwner
    {
        totalCommunityTokensCommitted = totalCommunityTokensCommitted.add(_tokens);
        require(totalCommunityTokensCommitted <= CommunityCap);

        if (holdings[_beneficiary].tokensCommitted != 0) {
            holdings[_beneficiary].tokensCommitted = holdings[_beneficiary].tokensCommitted.add(_tokens);
            holdings[_beneficiary].tokensRemaining = holdings[_beneficiary].tokensRemaining.add(_tokens);

            emit CommunityVestingUpdated(
                _beneficiary,
                holdings[_beneficiary].tokensRemaining,
                holdings[_beneficiary].startTime
            );

        } else {
            holdings[_beneficiary] = Holding(
                _tokens,
                _tokens,
                _startTime
            );

            emit CommunityVestingInitialized(_beneficiary, _tokens, _startTime);
        }
    }
}