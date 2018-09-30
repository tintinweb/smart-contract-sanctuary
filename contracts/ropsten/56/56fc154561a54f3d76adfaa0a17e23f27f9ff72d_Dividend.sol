pragma solidity ^0.4.24;


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

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an address access to this role
     */
    function add(Role storage _role, address _addr)
        internal
    {
        _role.bearer[_addr] = true;
    }

    /**
     * @dev remove an address&#39; access to this role
     */
    function remove(Role storage _role, address _addr)
        internal
    {
        _role.bearer[_addr] = false;
    }

    /**
     * @dev check if an address has this role
     * // reverts
     */
    function check(Role storage _role, address _addr)
        internal
        view
    {
        require(has(_role, _addr));
    }

    /**
     * @dev check if an address has this role
     * @return bool
     */
    function has(Role storage _role, address _addr)
        internal
        view
        returns (bool)
    {
        return _role.bearer[_addr];
    }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
    using Roles for Roles.Role;

    mapping (string => Roles.Role) private roles;

    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);

    /**
     * @dev reverts if addr does not have role
     * @param _operator address
     * @param _role the name of the role
     * // reverts
     */
    function checkRole(address _operator, string _role)
        public
        view
    {
        roles[_role].check(_operator);
    }

    /**
     * @dev determine if addr has role
     * @param _operator address
     * @param _role the name of the role
     * @return bool
     */
    function hasRole(address _operator, string _role)
        public
        view
        returns (bool)
    {
        return roles[_role].has(_operator);
    }

    /**
     * @dev add a role to an address
     * @param _operator address
     * @param _role the name of the role
     */
    function addRole(address _operator, string _role)
        internal
    {
        roles[_role].add(_operator);
        emit RoleAdded(_operator, _role);
    }

    /**
     * @dev remove a role from an address
     * @param _operator address
     * @param _role the name of the role
     */
    function removeRole(address _operator, string _role)
        internal
    {
        roles[_role].remove(_operator);
        emit RoleRemoved(_operator, _role);
    }

    /**
     * @dev modifier to scope access to a single role (uses msg.sender as addr)
     * @param _role the name of the role
     * // reverts
     */
    modifier onlyRole(string _role)
    {
        checkRole(msg.sender, _role);
        _;
    }

    /**
     * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
     * @param _roles the names of the roles to scope access to
     * // reverts
     *
     * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
     *  see: https://github.com/ethereum/solidity/issues/2467
     */
    // modifier onlyRoles(string[] _roles) {
    //     bool hasAnyRole = false;
    //     for (uint8 i = 0; i < _roles.length; i++) {
    //         if (hasRole(msg.sender, _roles[i])) {
    //             hasAnyRole = true;
    //             break;
    //         }
    //     }

    //     require(hasAnyRole);

    //     _;
    // }
}


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";

    /**
     * @dev Throws if operator is not whitelisted.
     * @param _operator address
     */
    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address _operator)
        public
        onlyOwner
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev getter to determine if address is in whitelist
     */
    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param _operator address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn&#39;t in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyOwner
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren&#39;t in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
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


interface BBTxInterface {
    function snapshot() external returns(uint256);
    function circulationAt(uint256 _snapshotId) external view returns(uint256);
    function balanceOfAt(address _account, uint256 _snapshotId) external view returns (uint256);
}

contract Dividend is Whitelist, Pausable {
    using SafeMath for *;

    struct RoundInfo {
        uint256 bbtSnapshotId;
        uint256 dividend;
    }

    struct CurrentRoundInfo {
        uint256 roundId;
        uint256 dividend;
        bool isEnded;   // default is false
    }

    BBTxInterface private BBT;   // BBT contract
    CurrentRoundInfo public currentRound_;  // current round information
    mapping (address => uint256) public playersWithdrew_;    // (plyAddr => withdrewEth)
    mapping (uint256 => RoundInfo) public roundsInfo_;  // roundId => RoundInfo
    uint256[] public roundIds_;
    uint256 public cumulativeDividend;  // cumulative total dividend;

    event Deposited(address indexed _from, uint256 indexed _round, uint256 _value);
    event Distributed(uint256 indexed _roundId, uint256 bbtSnapshotId, uint256 dividend);
    event Withdrew(address indexed _from, uint256 _value);

    constructor(address _bbtAddress) public {
        BBT = BBTxInterface(_bbtAddress);
    }

    /**
     * @dev prevents contracts from interacting with fomo3d
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev get count of game rounds
     */
    function getRoundsCount() public view returns(uint256) {
        return roundIds_.length;
    }

    /**
     * @dev deposit dividend eth in.
     * @param _round which round the dividend for.
     * @return deposit success.
     */
    function deposit(uint256 _round)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
        payable
        returns(bool)
    {
        require(msg.value > 0, "deposit amount should not be empty.");
        require(_round > 0 && _round >= currentRound_.roundId, "can not deposit dividend for past round.");

        if (_round == currentRound_.roundId) {
            require(currentRound_.isEnded == false, "this round has ended. can not deposit.");
            currentRound_.dividend = (currentRound_.dividend).add(msg.value);
        } else {    // new round
            if (currentRound_.roundId > 0)  //when first deposit come in, don&#39;t check isEnded.
                require(currentRound_.isEnded == true, "last round not end. can not deposit new round.");
            currentRound_.roundId = _round;
            currentRound_.isEnded = false;
            currentRound_.dividend = msg.value;
        }

        cumulativeDividend = cumulativeDividend.add(msg.value);

        emit Deposited(msg.sender, _round, msg.value);
        return true;
    }

    /**
     * @dev distribute dividend to BBT holder.
     * @param _round which round the distribution for.
     * @return distributed success.
     */
    function distribute(uint256 _round)
        onlyIfWhitelisted(msg.sender)
        whenNotPaused
        public
        returns(bool)
    {
        require(_round > 0 && _round >= currentRound_.roundId, "can not distribute dividend for past round.");

        if (_round == currentRound_.roundId) {
            require(currentRound_.isEnded == false, "this round has ended. can not distribute again.");
        } else {    //when this round has no deposit
            currentRound_.roundId = _round;
            currentRound_.dividend = 0;
        }

        RoundInfo memory roundInfo;
        roundInfo.bbtSnapshotId = BBT.snapshot();
        roundInfo.dividend = currentRound_.dividend;
        roundsInfo_[currentRound_.roundId] = roundInfo;
        roundIds_.push(currentRound_.roundId);

        currentRound_.isEnded = true;   //mark this round is ended

        emit Distributed(currentRound_.roundId, roundInfo.bbtSnapshotId, roundInfo.dividend);
        return true;
    }

    /**
     * @dev player withdraw dividend out.
     */
    function withdraw()
        whenNotPaused
        isHuman
        public
    {
        uint256 plyLeftDividend = getPlayerLeftDividend(msg.sender);
        if (plyLeftDividend > 0) {
            msg.sender.transfer(plyLeftDividend);
            playersWithdrew_[msg.sender] = (playersWithdrew_[msg.sender]).add(plyLeftDividend);
        }
        emit Withdrew(msg.sender, plyLeftDividend);
    }

    /**
     * @dev get player dividend by round id.
     */
    function getPlayerRoundDividend(address _plyAddr, uint256 _roundId)
        public
        view
        returns(uint256)
    {
        require(_roundId > 0 && _roundId <= roundIds_.length, &#39;invalid round id.&#39;);

        RoundInfo storage roundInfo = roundsInfo_[_roundId];
        // cause circulation divide token decimal, so the balance should divide too.
        uint256 plyRoundBBT = (BBT.balanceOfAt(_plyAddr, roundInfo.bbtSnapshotId)).div(1e18);
        return plyRoundBBT.mul(getRoundDividendPerBBTHelper(_roundId));
    }

    function getPlayerTotalDividend(address _plyAddr)
        public
        view
        returns(uint256)
    {
        uint256 plyTotalDividend;
        for (uint256 i = 0; i < roundIds_.length; i++) {
            uint256 roundId = roundIds_[i];
            plyTotalDividend = plyTotalDividend.add(getPlayerRoundDividend(_plyAddr, roundId));
        }
        return plyTotalDividend;
    }

    function getPlayerLeftDividend(address _plyAddr)
        public
        view
        returns(uint256)
    {
        return (getPlayerTotalDividend(_plyAddr)).sub(playersWithdrew_[_plyAddr]);
    }

    /**
     * @dev calculate dividend per BBT by round id.
     */
    function getRoundDividendPerBBTHelper(uint256 _roundId)
        internal
        view
        returns(uint256)
    {
        RoundInfo storage roundInfo = roundsInfo_[_roundId];

        if (roundInfo.dividend == 0)
            return 0;

        // must divide token decimal, or circulation is greater than dividend,
        // the result will be 0, not 0.xxx(cause solidity not support float.)
        // and the func which rely on this helper will get the result 0 too.
        uint256 circulationAtSnapshot = (BBT.circulationAt(roundInfo.bbtSnapshotId)).div(1e18);
        if (circulationAtSnapshot == 0)
            return 0;
        return (roundInfo.dividend).div(circulationAtSnapshot);
    }
}