pragma solidity ^0.4.24;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : dave@akomba.com
// released under Apache 2.0 licence
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

interface BankInterfaceForForwarder {
    function deposit(address _addr) external payable returns (bool);
    function migrationReceiver_setup() external returns (bool);
}

contract BankForwarder is Ownable {
    string public name = "BankForwarder";
    BankInterfaceForForwarder private currentCorpBank_;
    address private newCorpBank_;
    bool needsBank_ = true;

    constructor()
    public
    {
        //constructor does nothing.
    }

    function()
    public
    payable
    {
        // done so that if any one tries to dump eth into this contract, we can
        // just forward it to corp bank.
        currentCorpBank_.deposit.value(address(this).balance)(address(currentCorpBank_));
    }

    function deposit()
    public
    payable
    returns(bool)
    {
        require(msg.value > 0, "Forwarder Deposit failed - zero deposits not allowed");
        require(needsBank_ == false, "Forwarder Deposit failed - no registered bank");
        if (currentCorpBank_.deposit.value(msg.value)(msg.sender) == true)
            return(true);
        else
            return(false);
    }

    function status()
    public
    view
    returns(address, address, bool)
    {
        return(address(currentCorpBank_), address(newCorpBank_), needsBank_);
    }

    function startMigration(address _newCorpBank)
    external
    returns(bool)
    {
        // make sure this is coming from current corp bank
        require(msg.sender == address(currentCorpBank_), "Forwarder startMigration failed - msg.sender must be current corp bank");

        // communicate with the new corp bank and make sure it has the forwarder
        // registered
        if(BankInterfaceForForwarder(_newCorpBank).migrationReceiver_setup() == true)
        {
            // save our new corp bank address
            newCorpBank_ = _newCorpBank;
            return (true);
        } else
            return (false);
    }

    function cancelMigration()
    external
    returns(bool)
    {
        // make sure this is coming from the current corp bank (also lets us know
        // that current corp bank has not been killed)
        require(msg.sender == address(currentCorpBank_), "Forwarder cancelMigration failed - msg.sender must be current corp bank");

        // erase stored new corp bank address;
        newCorpBank_ = address(0x0);

        return (true);
    }

    function finishMigration()
    external
    returns(bool)
    {
        // make sure its coming from new corp bank
        require(msg.sender == newCorpBank_, "Forwarder finishMigration failed - msg.sender must be new corp bank");

        // update corp bank address
        currentCorpBank_ = (BankInterfaceForForwarder(newCorpBank_));

        // erase new corp bank address
        newCorpBank_ = address(0x0);

        return (true);
    }

    function setup(address _firstCorpBank) onlyOwner
    external
    {
        require(needsBank_ == true, "Forwarder setup failed - corp bank already registered");
        currentCorpBank_ = BankInterfaceForForwarder(_firstCorpBank);
        needsBank_ = false;
    }
}