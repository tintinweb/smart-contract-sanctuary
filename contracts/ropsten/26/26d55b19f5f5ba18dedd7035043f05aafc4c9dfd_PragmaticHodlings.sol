pragma solidity 0.4.24;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/MembersBookLib.sol

/**
 * @title MembersBook library
 * @dev Allows to store and manage addresses of members in contract
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Dominik Kroliczek (https://github.com/kruligh)
 */
library MembersBookLib {

    /**
     * @dev Represents member with its address and
     * @dev joining to organization timestamp
     */
    struct Member {
        address account;
        uint64 joinDate;
    }

    /**
     * @dev Represents set of members
     */
    struct MembersBook {
        Member[] entries;
    }

    /**
     * @dev Adds new member to book
     * @param account address Member&#39;s address
     * @param joinDate uint64 Member&#39;s joining timestamp
     */
    function add(
        MembersBook storage self,
        address account,
        uint64 joinDate
    )
        internal
        returns (bool)
    {
        if (account == address(0) || contains(self, account)) {
            return false;
        }

        self.entries.push(
            Member({
                account: account,
                joinDate: joinDate
            }));

        return true;
    }

    /**
     * @dev Removes existing member from book
     * @param account address Member&#39;s address whose should be removed
     */
    function remove(
        MembersBook storage self,
        address account
    )
        internal
        returns (bool)
    {
        if (!contains(self, account)) {
            return false;
        } else {
            uint256 entryIndex = index(self, account);
            if (entryIndex < self.entries.length - 1) {
                self.entries[entryIndex] = self.entries[self.entries.length - 1];
            }

            self.entries.length--;
        }

        return true;
    }

    /**
     * @dev Checks if member address exists in book
     * @param account address Address to check
     * @return bool Address existence indicator
     */
    function contains(
        MembersBook storage self,
        address account
    )
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.entries.length; i++) {
            if (self.entries[i].account == account) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Returns member index in book or reverts if doesn&#39;t exists
     * @param account address Address to check
     * @return uint256 Address index
     */
    function index(
        MembersBook storage self,
        address account
    )
        private
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < self.entries.length; i++) {
            if (self.entries[i].account == account) {
                return i;
            }
        }
        assert(false);
    }
}

// File: contracts/PragmaticHodlings.sol

/**
 * @title Token interface compatible with Pragmatic Hodlings
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Dominik Kroliczek (https://github.com/kruligh)
 */
contract TransferableToken {
    function transfer(address to, uint256 amount) public;
    function balanceOf(address who) public view returns (uint256);
}


/**
 * @title Proportionally distribute contract&#39;s tokens to each registered hodler
 * @dev Proportion is calculated based on join date timestamp
 * @dev Group of hodlers and settlements are managed by contract owner
 * @author Wojciech Harzowski (https://github.com/harzo)
 * @author Dominik Kroliczek (https://github.com/kruligh)
 */
contract PragmaticHodlings is Ownable {

    using SafeMath for uint256;
    using MembersBookLib for MembersBookLib.MembersBook;

    MembersBookLib.MembersBook private hodlers;

    /**
     * @dev Stores addresses added to book
     */
    modifier onlyValidAddress(address account) {
        require(account != address(0));
        _;
    }

    modifier onlyHodlersExist {
        require(hodlers.entries.length != 0);
        _;
    }

    modifier onlyExisting(address account) {
        require(hodlers.contains(account));
        _;
    }

    modifier onlyNotExisting(address account) {
        require(!hodlers.contains(account));
        _;
    }

    modifier onlySufficientAmount(TransferableToken token) {
        require(token.balanceOf(this) > 0);
        _;
    }

    modifier onlyPast(uint64 timestamp) {
        // solhint-disable not-rely-on-time
        // solium-disable-next-line security/no-block-members
        require(now > timestamp);
        _;
    }

    /**
    * @dev New hodler has been added to book
    * @param account address Hodler&#39;s address
    * @param joinDate uint64 Hodler&#39;s joining timestamp
    */
    event HodlerAdded(address account, uint64 joinDate);

    /**
     * @dev Existing hodler has been removed
     * @param account address Removed hodler address
     */
    event HodlerRemoved(address account);

    /**
     * @dev Token is settled on hodlers addresses
     * @param token address The token address
     * @param amount uint256 Settled amount
     */
    event TokenSettled(address token, uint256 amount);

    /**
     * @dev Adds new hodler to book
     * @param account address Hodler&#39;s address
     * @param joinDate uint64 Hodler&#39;s joining timestamp
     */
    function addHodler(address account, uint64 joinDate)
        public
        onlyOwner
        onlyValidAddress(account)
        onlyNotExisting(account)
        onlyPast(joinDate)
    {
        hodlers.add(account, joinDate);
        emit HodlerAdded(account, joinDate);
    }

    /**
     * @dev Removes existing hodler from book
     * @param account address Hodler&#39;s address whose should be removed
     */
    function removeHodler(address account)
        public
        onlyOwner
        onlyValidAddress(account)
        onlyExisting(account)
    {
        hodlers.remove(account);
        emit HodlerRemoved(account);
    }

    /**
     * @dev Settles given token on hodlers addresses
     * @param token BasicToken The token to settle
     */
    function settleToken(TransferableToken token)
        public
        onlyOwner
        onlyHodlersExist
        onlySufficientAmount(token)
    {
        uint256 tokenAmount = token.balanceOf(this);

        uint256[] memory tokenShares = calculateShares(tokenAmount);

        for (uint i = 0; i < hodlers.entries.length; i++) {
            token.transfer(hodlers.entries[i].account, tokenShares[i]);
        }

        emit TokenSettled(token, tokenAmount);
    }

    /**
     * @dev Calculates proportional share in given amount
     * @param amount uint256 Amount to share between hodlers
     * @return tokenShares uint256[] Calculated shares
     */
    function calculateShares(uint256 amount)
        public
        view
        returns (uint256[])
    {
        uint256[] memory temp = new uint256[](hodlers.entries.length);

        uint256 sum = 0;
        for (uint256 i = 0; i < temp.length; i++) {
            // solium-disable-next-line security/no-block-members
            temp[i] = now.sub(hodlers.entries[i].joinDate);
            sum = sum.add(temp[i]);
        }

        uint256 sharesSum = 0;
        for (i = 0; i < temp.length; i++) {
            temp[i] = amount.mul(temp[i]).div(sum);
            sharesSum += temp[i];
        }

        if (amount > sharesSum) { // undivided rest of token
            temp[0] = temp[0].add(amount.sub(sharesSum));
        }

        return temp;
    }

    /**
     * @dev Returns hodlers addresses with joining timestamps
     * @return address[] Addresses of hodlers
     * @return uint64[] joining timestamps. Related by index with addresses
     */
    function getHodlers()
        public
        view
        returns (address[], uint64[])
    {
        address[] memory hodlersAddresses = new address[](hodlers.entries.length);
        uint64[] memory hodlersTimestamps = new uint64[](hodlers.entries.length);

        for (uint256 i = 0; i < hodlers.entries.length; i++) {
            hodlersAddresses[i] = hodlers.entries[i].account;
            hodlersTimestamps[i] = hodlers.entries[i].joinDate;
        }

        return (hodlersAddresses, hodlersTimestamps);
    }

    /**
     * @param account address Hodler address
     * @return bool whether account is registered as holder
     */
    function isHodler(address account)
        public
        view
        returns (bool)
    {
        return hodlers.contains(account);
    }
}