/**
 *Submitted for verification at Etherscan.io on 2021-02-22
*/

pragma solidity ^0.8.1;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
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
        return msg.sender == _owner || tx.origin == _owner;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

interface TokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool);
}

contract NexenVesting is Ownable {
    using SafeMath for uint256;

    TokenInterface public token;
    
    address[] public holders;
    
    mapping (address => Holding[]) public holdings;

    struct Holding {
        uint256 totalTokens;
        uint256 unlockDate;
        bool claimed;
    }
    
    // Events
    event VestingCreated(address _to, uint256 _totalTokens, uint256 _unlockDate);
    event TokensReleased(address _to, uint256 _tokensReleased);
    
    function getVestingByBeneficiary(address _beneficiary, uint256 _index) external view returns (uint256 totalTokens, uint256 unlockDate, bool claimed) {
        require(holdings[_beneficiary].length > _index, "The holding doesn't exist");
        Holding memory holding = holdings[_beneficiary][_index];
        totalTokens = holding.totalTokens;
        unlockDate = holding.unlockDate;
        claimed = holding.claimed;
    }
    
    function getTotalVestingsByBeneficiary(address _beneficiary) external view returns (uint256) {
        return holdings[_beneficiary].length;
    }

    function getTotalToClaimNowByBeneficiary(address _beneficiary) public view returns(uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < holdings[_beneficiary].length; i++) {
            Holding memory holding = holdings[_beneficiary][i];
            if (!holding.claimed && block.timestamp > holding.unlockDate) {
                total = total.add(holding.totalTokens);
            }
        }

        return total;
    }
    
    function getTotalVested() public view returns(uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < holders.length; i++) {
            for (uint256 j = 0; j < holdings[holders[i]].length; j++) {
                Holding memory holding = holdings[holders[i]][j];
                total = total.add(holding.totalTokens);
            }
        }

        return total;
    }
    
    function getTotalClaimed() public view returns(uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < holders.length; i++) {
            for (uint256 j = 0; j < holdings[holders[i]].length; j++) {
                Holding memory holding = holdings[holders[i]][j];
                if (holding.claimed) {
                    total = total.add(holding.totalTokens);
                }
            }
        }

        return total;
    }

    function claimTokens() external
    {
        uint256 tokensToClaim = getTotalToClaimNowByBeneficiary(msg.sender);
        require(tokensToClaim > 0, "Nothing to claim");
        
        for (uint256 i = 0; i < holdings[msg.sender].length; i++) {
            Holding storage holding = holdings[msg.sender][i];
            if (!holding.claimed && block.timestamp > holding.unlockDate) {
                holding.claimed = true;
            }
        }

        require(token.transfer(msg.sender, tokensToClaim), "Insufficient balance in vesting contract");
        emit TokensReleased(msg.sender, tokensToClaim);
    }
    
    function _addHolderToList(address _beneficiary) internal {
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == _beneficiary) {
                return;
            }
        }
        holders.push(_beneficiary);
    }

    function createVesting(address _beneficiary, uint256 _totalTokens, uint256 _unlockDate) public onlyOwner {
        token.transferFrom(msg.sender, address(this), _totalTokens);

        _addHolderToList(_beneficiary);
        Holding memory holding = Holding(_totalTokens, _unlockDate, false);
        holdings[_beneficiary].push(holding);
        emit VestingCreated(_beneficiary, _totalTokens, _unlockDate);
    }
    
    constructor(address _token) {
        token = TokenInterface(_token);
    }
}