/**
 * ▒█▀▀█ ░▀░ █▀▀█ █▀▀▄ █▀▄▀█ █▀▀█ █▀▀▄ 
 * ▒█▀▀▄ ▀█▀ █▄▄▀ █░░█ █░▀░█ █▄▄█ █░░█ 
 * ▒█▄▄█ ▀▀▀ ▀░▀▀ ▀▀▀░ ▀░░░▀ ▀░░▀ ▀░░▀ 
 *
 * Birdman helps grow the Microverse community,
 * which is considered the premature version of Mutual Constructor.
 */

pragma solidity ^0.4.23;

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
 * @title AdminUtils
 * @dev customized admin control panel
 * @dev just want to keep everything safe
 */
contract AdminUtils is Ownable {

    mapping (address => uint256) adminContracts;

    address internal root;

    /* modifiers */
    modifier OnlyContract() {
        require(isSuperContract(msg.sender));
        _;
    }

    modifier OwnerOrContract() {
        require(msg.sender == owner || isSuperContract(msg.sender));
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

    /* constructor */
    constructor() public {
        // This is a safe key stored offline
        root = 0xe07faf5B0e91007183b76F37AC54d38f90111D40;
    }

    /**
     * @dev this is the kickass idea from @dan
     * and well we will see how it works
     */
    function claimOwnership()
        external
        onlyRoot
        returns (bool) {
        owner = root;
        return true;
    }

    /**
     * @dev function to address a super contract address
     * some functions are meant to be called from another contract
     * but not from any contracts
     * @param _address A contract address
     */
    function addContractAddress(address _address)
        public
        onlyOwner
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        adminContracts[_address] = 1;
        return true;
    }

    /**
     * @dev remove the contract address as a super user role
     * have it here just in case
     * @param _address A contract address
     */
    function removeContractAddress(address _address)
        public
        onlyOwner
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        adminContracts[_address] = 0;
        return true;
    }

    /**
     * @dev check contract eligibility
     * @param _address A contract address
     */
    function isSuperContract(address _address)
        public
        view
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        if (adminContracts[_address] == 1) {
            return true;
        } else {
            return false;
        }
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Contract that will work with ERC223 tokens.
 */
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

/**
 * @title EvilMortyTokenInterface
 */
contract EvilMortyTokenInterface {

    /**
     * @dev Check balance of a given address
     * @param sender address
     */
    function balanceOf(address sender) public view returns (uint256);
}

/**
 * @title Birdman
 */
contract Birdman is AdminUtils, ERC223ReceivingContract {

    using SafeMath for uint256;

    event MCApplied(address sender);
    event MCAdded(address sender);
    event MCRemoved(address sender);
    event ShareSent(address indexed receiver, uint256 value);
    event SystemChangeValidMCAmount(uint256 oldValue, uint256 newValue);
    event SystemChangeMaxNumMC(uint256 oldValue, uint256 newValue);
    event SystemChangeShareTimeGap(uint256 oldValue, uint256 newValue);
    event SystemChangeVettingTime(uint256 oldValue, uint256 newValue);

    EvilMortyTokenInterface internal EvilMortyInstance;

    uint256 public validMCAmount = 5000000e18;
    uint256 public maxNumMC = 20;
    uint256 public vettingTime = 86400; // in block height, roughly 15 days
    uint256 public shareTimeGap = 86400; // in block height, roughly 15 days
    uint256 public numMC;
    uint256 public numMCApplied;
    uint256 public nextShareTime = 6213990; // around UTC 01:00, 8/26/2018
    uint256 public weiAmountShare;

    mapping (uint256 => MC) constructors;
    mapping (address => uint256) addressToIndex;

    struct MC {
      address playerAddress;
      uint256 timeSince;
      uint256 nextSharedSentTime;
      bool passed;
    }
    
    uint256[] emptyIndexes;

    modifier isValidMC() {
        require (EvilMortyInstance.balanceOf(msg.sender) >= validMCAmount);
        _;
    }

    modifier canAddMC() {
      require (numMCApplied < maxNumMC);
      // make sure no one cheats
      require (addressToIndex[msg.sender] == 0);
      
      _; 
    }

    modifier isEvilMortyToken() {
        require(msg.sender == address(EvilMortyInstance));
        _;
    }

    /* constructor */
    constructor(address EvilMortyAddress)
        public {
        EvilMortyInstance = EvilMortyTokenInterface(EvilMortyAddress);
    }

    /**
     * @dev Allow funds to be sent to this contract
     * if the sender is the owner or a super contract
     * then it will do nothing
     */
    function ()
        public
        payable {
        if (msg.sender == owner || isSuperContract(msg.sender)) {
            return;
        }
        applyMC();
    }

    /**
     * @dev Allow morty token to be sent to this contract
     * if the sender is the owner it will do nothing
     */
    function tokenFallback(address _from, uint256 _value, bytes)
        public
        isEvilMortyToken {
        if (_from == owner) {
            return;
        }
        claimShare(addressToIndex[_from]);
    }

    /**
     * @dev Apply for becoming a MC
     */
    function applyMC()
        public
        payable
        canAddMC {

        require (EvilMortyInstance.balanceOf(msg.sender) >= validMCAmount);

        numMCApplied = numMCApplied.add(1);
        uint256 newIndex = numMCApplied;

        if (emptyIndexes.length > 0) {
            newIndex = emptyIndexes[emptyIndexes.length-1];
            delete emptyIndexes[emptyIndexes.length-1];
            emptyIndexes.length--;
        }

        constructors[newIndex] = MC({
            playerAddress: msg.sender,
            timeSince: block.number.add(vettingTime),
            nextSharedSentTime: nextShareTime,
            passed: false
        });

        addressToIndex[msg.sender] = newIndex;

        emit MCApplied(msg.sender);
    }

    /**
     * @dev Get a MC&#39;s info given index
     * @param _index the MC&#39;s index
     */
    function getMC(uint256 _index)
        public
        view
        returns (address, uint256, uint256, bool) {
        MC storage mc = constructors[_index];
        return (
            mc.playerAddress,
            mc.timeSince,
            mc.nextSharedSentTime,
            mc.passed
        );
    }

    /**
     * @dev Get number of empty indexes
     */
    function numEmptyIndexes()
        public
        view
        returns (uint256) {
        return emptyIndexes.length;
    }

    /**
     * @dev Get the MC index given address
     * @param _address MC&#39;s address
     */
    function getIndex(address _address)
        public
        view
        returns (uint256) {
        return addressToIndex[_address];
    }

    /**
     * @dev Update all MC&#39;s status
     */
    function updateMCs()
        public {

        if (numMCApplied == 0) {
            return;
        }

        for (uint256 i = 0; i < maxNumMC; i ++) {
            updateMC(i);
        }
    }

    /**
     * @dev Update a MC&#39;s status, if
     * - the MC&#39;s balance is below min requirement, it will be deleted;
     * - the MC&#39;s vetting time is passed, it will be added
     * @param _index the MC&#39;s index
     */
    function updateMC(uint256 _index)
        public {
        MC storage mc = constructors[_index];

        // skip empty index
        if (mc.playerAddress == 0) {
            return;
        }

        if (EvilMortyInstance.balanceOf(mc.playerAddress) < validMCAmount) {
            // remove MC
            numMCApplied = numMCApplied.sub(1);
            if (mc.passed == true) {
                numMC = numMC.sub(1);
            }
            emptyIndexes.push(_index);
            emit MCRemoved(mc.playerAddress);
            delete addressToIndex[mc.playerAddress];
            delete constructors[_index];
            return;
        }

        if (mc.passed == false && mc.timeSince < block.number) {
             mc.passed = true;
             numMC = numMC.add(1);
             emit MCAdded(mc.playerAddress);
             return;
        }
    }

    /**
     * @dev Update funds to be sent in this shares period
     */
    function updateWeiAmountShare()
        public {
        if (numMC == 0) {
            return;
        }
        if (nextShareTime < block.number) {
            weiAmountShare = address(this).balance.div(numMC);

            // make height accurate
            uint256 timeGap = block.number.sub(nextShareTime);
            uint256 gap = timeGap.div(shareTimeGap).add(1);
            nextShareTime = nextShareTime.add(shareTimeGap.mul(gap));
        }
    }

    /**
     * @dev Ask for funds for a MC
     * @param _index the Mc&#39;s index
     */
    function claimShare(uint256 _index)
        public {

        // need update all MCs first
        updateMCs();

        MC storage mc = constructors[_index];

        // skip empty index
        if (mc.playerAddress == 0) {
            return;
        }

        if (mc.passed == false) {
            return;
        }

        if (mc.nextSharedSentTime < block.number) {
            // update next share time
            updateWeiAmountShare();
            mc.nextSharedSentTime = nextShareTime;
            // every mc gets equal share
            mc.playerAddress.transfer(weiAmountShare);
            emit ShareSent(mc.playerAddress, weiAmountShare);
        }
    }

    /**
     * @dev Upgrade evil morty
     * in case of upgrade needed
     */
    function upgradeEvilMorty(address _address)
        external
        onlyOwner {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return;
        }

        EvilMortyInstance = EvilMortyTokenInterface(_address);
    }

    /**
     * @dev Update min requirement for being a MC
     * a system event is emitted to capture the change
     * @param _amount new amount
     */
    function updateValidMCAmount(uint256 _amount)
        external
        onlyOwner {
        emit SystemChangeValidMCAmount(validMCAmount, _amount);
        validMCAmount = _amount;
    }

    /**
     * @dev Update max number of MCs
     * a system event is emitted to capture the change
     */
    function updateMaxNumMC(uint256 _num)
        external
        onlyOwner {
        emit SystemChangeMaxNumMC(maxNumMC, _num);
        maxNumMC = _num;
    }

    /**
     * @dev Update the length of a share period
     * a system event is emitted to capture the change
     * @param _height bloch heights
     */
    function updateShareTimeGap(uint256 _height)
        external
        onlyOwner {
        emit SystemChangeShareTimeGap(shareTimeGap, _height);
        shareTimeGap = _height;
    }

    /**
     * @dev Update the length of vetting time
     * a system event is emitted to capture the change
     * @param _height bloch heights
     */
    function updateVettingTime(uint256 _height)
        external
        onlyOwner {
        emit SystemChangeVettingTime(vettingTime, _height);
        vettingTime = _height;
    }
}