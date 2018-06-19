pragma solidity ^0.4.23;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Autonomy is Ownable {
    address public congress;
    bool init = false;

    modifier onlyCongress() {
        require(msg.sender == congress);
        _;
    }

    /**
     * @dev initialize a Congress contract address for this token 
     *
     * @param _congress address the congress contract address
     */
    function initialCongress(address _congress) onlyOwner public {
        require(!init);
        require(_congress != address(0));
        congress = _congress;
        init = true;
    }

    /**
     * @dev set a Congress contract address for this token
     * must change this address by the last congress contract 
     *
     * @param _congress address the congress contract address
     */
    function changeCongress(address _congress) onlyCongress public {
        require(_congress != address(0));
        congress = _congress;
    }
}

contract Destructible is Ownable {

  function Destructible() public payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract DRCWalletMgrParams is Claimable, Autonomy, Destructible {
    uint256 public singleWithdrawMin; // min value of single withdraw
    uint256 public singleWithdrawMax; // Max value of single withdraw
    uint256 public dayWithdraw; // Max value of one day of withdraw
    uint256 public monthWithdraw; // Max value of one month of withdraw
    uint256 public dayWithdrawCount; // Max number of withdraw counting

    uint256 public chargeFee; // the charge fee for withdraw
    address public chargeFeePool; // the address that will get the returned charge fees.


    function initialSingleWithdrawMax(uint256 _value) onlyOwner public {
        require(!init);

        singleWithdrawMax = _value;
    }

    function initialSingleWithdrawMin(uint256 _value) onlyOwner public {
        require(!init);

        singleWithdrawMin = _value;
    }

    function initialDayWithdraw(uint256 _value) onlyOwner public {
        require(!init);

        dayWithdraw = _value;
    }

    function initialDayWithdrawCount(uint256 _count) onlyOwner public {
        require(!init);

        dayWithdrawCount = _count;
    }

    function initialMonthWithdraw(uint256 _value) onlyOwner public {
        require(!init);

        monthWithdraw = _value;
    }

    function initialChargeFee(uint256 _value) onlyOwner public {
        require(!init);

        chargeFee = _value;
    }

    function initialChargeFeePool(address _pool) onlyOwner public {
        require(!init);

        chargeFeePool = _pool;
    }    

    function setSingleWithdrawMax(uint256 _value) onlyCongress public {
        singleWithdrawMax = _value;
    }   

    function setSingleWithdrawMin(uint256 _value) onlyCongress public {
        singleWithdrawMin = _value;
    }

    function setDayWithdraw(uint256 _value) onlyCongress public {
        dayWithdraw = _value;
    }

    function setDayWithdrawCount(uint256 _count) onlyCongress public {
        dayWithdrawCount = _count;
    }

    function setMonthWithdraw(uint256 _value) onlyCongress public {
        monthWithdraw = _value;
    }

    function setChargeFee(uint256 _value) onlyCongress public {
        chargeFee = _value;
    }

    function setChargeFeePool(address _pool) onlyCongress public {
        chargeFeePool = _pool;
    }
}