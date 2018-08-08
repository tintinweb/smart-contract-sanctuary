pragma solidity ^0.4.15;

/**
 *
 * @author  David Rosen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="432822222d272c2a37032e202c2d6d2c3124">[email&#160;protected]</a>>
 *
 * Version A
 *
 * Overview:
 * This divides all incoming funds among various `activity` accounts. The division cannot be changed
 * after the contract is locked.
 */


// --------------------------
//  R Split Contract
// --------------------------
contract OrganizeFunds {

  struct ActivityAccount {
    uint credited;   // total funds credited to this account
    uint balance;    // current balance = credited - amount withdrawn
    uint pctx10;     // percent allocation times ten
    address addr;    // payout addr of this acct
  }

  uint constant TENHUNDWEI = 1000;                     // need gt. 1000 wei to distribute
  uint constant MAX_ACCOUNTS = 10;                     // max accounts this contract can handle

  event MessageEvent(string message);
  event MessageEventI(string message, uint val);


  bool public isLocked;
  address public owner;                                // deployer executor
  mapping (uint => ActivityAccount) activityAccounts;  // accounts by index
  uint public activityCount;                           // how many activity accounts
  uint public totalFundsReceived;                      // amount received since begin of time
  uint public totalFundsDistributed;                   // amount distributed since begin of time
  uint public totalFundsWithdrawn;                     // amount withdrawn since begin of time
  uint public withdrawGas = 100000;                    // gas for withdrawals


  modifier ownerOnly {
    require(msg.sender == owner);
    _;
  }

  modifier unlockedOnly {
    require(!isLocked);
    _;
  }



  //
  // constructor
  //
  function OrganizeFunds() {
    owner = msg.sender;
  }

  function lock() public ownerOnly {
    isLocked = true;
  }


  //
  // reset
  // reset all accounts
  // in case we have any funds that have not been withdrawn, they become  newly received and undistributed.
  //
  function reset() public ownerOnly unlockedOnly {
    totalFundsReceived = this.balance;
    totalFundsDistributed = 0;
    totalFundsWithdrawn = 0;
    activityCount = 0;
    MessageEvent("ok: all accts reset");
  }


  //
  // set withdrawal gas
  // nonstandard gas is necessary to support push-withdrawals to other contract
  //
  function setWitdrawGas(uint256 _withdrawGas) public ownerOnly unlockedOnly {
    withdrawGas = _withdrawGas;
    MessageEventI("ok: withdraw gas set", withdrawGas);
  }


  //
  // add a new account
  //
  function addAccount(address _addr, uint256 _pctx10) public ownerOnly unlockedOnly {
    if (activityCount >= MAX_ACCOUNTS) {
      MessageEvent("err: max accounts");
      return;
    }
    activityAccounts[activityCount].addr = _addr;
    activityAccounts[activityCount].pctx10 = _pctx10;
    activityAccounts[activityCount].credited = 0;
    activityAccounts[activityCount].balance = 0;
    ++activityCount;
    MessageEvent("ok: acct added");
  }


  // ----------------------------
  // get acct info
  // ----------------------------
  function getAccountInfo(address _addr) public constant returns(uint _idx, uint _pctx10, uint _credited, uint _balance) {
    for (uint i = 0; i < activityCount; i++ ) {
      address addr = activityAccounts[i].addr;
      if (addr == _addr) {
        _idx = i;
        _pctx10 = activityAccounts[i].pctx10;
        _credited = activityAccounts[i].credited;
        _balance = activityAccounts[i].balance;
        return;
      }
    }
  }


  //
  // get total percentages x10
  //
  function getTotalPctx10() public constant returns(uint _totalPctx10) {
    _totalPctx10 = 0;
    for (uint i = 0; i < activityCount; i++ ) {
      _totalPctx10 += activityAccounts[i].pctx10;
    }
  }


  //
  // default payable function.
  // call us with plenty of gas, or catastrophe will ensue
  //
  function () payable {
    totalFundsReceived += msg.value;
    MessageEventI("ok: received", msg.value);
  }


  //
  // distribute funds to all activities
  //
  function distribute() public {
    //only payout if we have more than 1000 wei
    if (this.balance < TENHUNDWEI) {
      return;
    }
    //each account gets their prescribed percentage of this holdover.
    uint i;
    uint pctx10;
    uint acctDist;
    for (i = 0; i < activityCount; i++ ) {
      pctx10 = activityAccounts[i].pctx10;
      acctDist = totalFundsReceived * pctx10 / TENHUNDWEI;
      //we also double check to ensure that the amount credited cannot exceed the total amount due to this acct
      if (activityAccounts[i].credited >= acctDist) {
        acctDist = 0;
      } else {
        acctDist = acctDist - activityAccounts[i].credited;
      }
      activityAccounts[i].credited += acctDist;
      activityAccounts[i].balance += acctDist;
      totalFundsDistributed += acctDist;
    }
    MessageEvent("ok: distributed funds");
  }


  //
  // withdraw actvity balance
  // can be called by owner to push funds to another contract
  //
  function withdraw() public {
    for (uint i = 0; i < activityCount; i++ ) {
      address addr = activityAccounts[i].addr;
      if (addr == msg.sender || msg.sender == owner) {
        uint amount = activityAccounts[i].balance;
        if (amount > 0) {
          activityAccounts[i].balance = 0;
          totalFundsWithdrawn += amount;
          if (!addr.call.gas(withdrawGas).value(amount)()) {
            //put back funds in case of err
            activityAccounts[i].balance = amount;
            totalFundsWithdrawn -= amount;
            MessageEvent("err: error sending funds");
            return;
          }
        }
      }
    }
  }


  //
  // suicide
  //
  function hariKari() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }

}