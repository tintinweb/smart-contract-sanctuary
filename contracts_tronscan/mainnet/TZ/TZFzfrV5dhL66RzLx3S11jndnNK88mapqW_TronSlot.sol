//SourceUnit: tronslot.sol

/*
  TRONSLOT
  Economic system

  Dapp: https://tronslot.com
  support@tronslot.com

  TronSlot (c) 2020, Tron Network 
*/

pragma solidity ^0.5.10;

/**
 * @notice Library of mathematical calculations for uit256
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @notice Access control and maintenance
 */
contract SysCtrl {
  address public sysman;
  address public sysWallet;
  constructor() public {
    sysman = msg.sender;
    sysWallet = address(0x0);
  }
  modifier onlySysman() {
    require(msg.sender == sysman, "Only for System Maintenance");
    _;
  }
  function setSysman(address _newSysman) public onlySysman {
    sysman = _newSysman;
  }
}

/**
 * @title TRC20Basic
 * @dev Simple version of ERC20/TRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract TRC20Basic is SysCtrl {
  //function balanceOf(address who) public view returns (uint256);
  //function transfer(address to, uint256 value) public returns (bool);
  event Transfer(
      address indexed from, 
      address indexed to, 
      uint256 value
  );
}

/**
 * @notice Standard Token ERC20/TRC20
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md for more details
 * Token to be used for future expansion, will soon be negotiated
 */
contract BasicToken is TRC20Basic {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public {
        uint256 initialSupply = 1000000000000000;
        string memory tokenName = "TronSlot";
        uint8 decimalUnits = 6;
        string memory tokenSymbol = "TSX";
        totalSupply = initialSupply;                 // Update total supply
        name = tokenName;                            // Set the name for display purposes
        symbol = tokenSymbol;                        // Set the symbol for display purposes
        decimals = decimalUnits;                     // Amount of decimals for display purposes
    }
}

/**
 * 
 * https://  for more details
 * 
 */
contract TronSlot is BasicToken {
    event Deposit(
        address indexed owner,
        uint256 value,
        uint256 oldBalance,
        bool firstDeposit
    );
    event Withdraw (
        address indexed owner,
        uint256 value,
        uint256 oldBalance
    );
    event Buy(
        address indexed owner,
        uint256 slot,
        uint256 amount,
        uint256 total  
    );
    event Commission (
        address indexed owner,
        uint value,
        address ref_pay
    );
    event Prize (
      uint indexed prizeID,
      uint prizeTime,
      uint prizeAmount,
      uint start
    );
    event PrizeWin (
      address indexed owner,
      uint value,
      uint indexed prizeID,
      uint prizeAmount
    );
    event PrizeBuy(
      address indexed owner,
      uint value,
      uint indexed prizeID
    );
    uint256 public ref_commission = 5;     // Pay for referral commisson 
    uint256 public maintenance_fee = 5;    // maintenance fee, One-time fee
    uint256 public nextID = 1;             // User ID on chain
    uint256 public totalDeposit = 0;
    uint256 public totalWithdraw = 0;
    uint256 public totalInvested = 0;

    // Prize control
    uint256 public prizeID; 
    uint256 public prizeTime;
    uint256 public prizeAmount;
    address public ownerWin;
    uint256 public amountWin;

    struct SlotStruct {
        uint price;
        uint payout_per_hour;
        uint life_days;
    }
    SlotStruct[] public slots;
    
    struct HolderStruct { 
        uint id;
        uint256 last_activity;
        uint256 profit;
        uint256 balance;
        uint[] slots;
        uint[] slots_amount;
        uint[] slots_time;
    }
    mapping (address => HolderStruct) public holders;
    mapping (uint => address) public holdersList;
   
    constructor() public {
        HolderStruct memory holderStruct;
        holderStruct = HolderStruct({
            id: nextID,
            last_activity: now,
            profit: 0,
            balance: totalSupply,
            slots: new uint[](0),
            slots_amount: new uint[](0),
            slots_time: new uint[](0)
        });
        holders[sysWallet] = holderStruct;  // Wallet token (0x0)
        holdersList[nextID] = sysWallet;
        nextID++;

        _newHolder(sysman);   // Create an account for System maintenance

        // Slot Plans available
        slots.push(SlotStruct({price: 0 trx,  payout_per_hour: 0 trx, life_days: 0}));
        slots.push(SlotStruct({price: 100 trx, payout_per_hour: 0.20 trx, life_days: 60}));
        slots.push(SlotStruct({price: 500 trx, payout_per_hour: 1.10 trx, life_days: 50}));
        slots.push(SlotStruct({price: 1000 trx, payout_per_hour: 2.25 trx, life_days: 40}));
        slots.push(SlotStruct({price: 5000 trx, payout_per_hour: 12 trx, life_days: 35}));
        slots.push(SlotStruct({price: 10000 trx, payout_per_hour: 25 trx, life_days: 30}));
        slots.push(SlotStruct({price: 50000 trx, payout_per_hour: 130 trx, life_days: 25}));
    }

    /**
    * @notice Deposit TRX in the contract
    * 
    */
    function deposit() public payable returns (bool) {
        bool firstDeposit = false;
        uint256 oldBalance = 0;
        if(holders[msg.sender].id <= 0) {          // First deposit of an address
            _newHolder(msg.sender);
            firstDeposit = true;
        } else {
            oldBalance = holders[msg.sender].balance;
            aBalance(msg.sender);
        }
        holders[msg.sender].balance += msg.value;
        holders[sysWallet].balance -= msg.value;
        totalDeposit += msg.value; 
        emit Deposit(
           msg.sender,
           msg.value,
           oldBalance,
           firstDeposit
        );
        return true;
    }

    /**
    * @notice Withdraw
    * @param _value the amount to withdraw in TRX
    */
    function withdraw(uint _value) public returns (bool) {
        require (_value > 0, "Insufficient order amount");
        require (balanceOf(msg.sender) >= _value, "Insufficient balance");
        uint256 oldBalance = holders[msg.sender].balance;
        aBalance(msg.sender);
        holders[msg.sender].balance -= _value;
        holders[sysWallet].balance += _value;
        totalWithdraw += _value;
        address(uint160(msg.sender)).transfer(_value);
        emit Withdraw(
           msg.sender,
           _value,
           oldBalance
        );
        return true;
    }

   /**
    * @notice Send `_value` tokens to `_to` from your account
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
    }

  /**
    * @notice Buy new slot in system
    * @param _slot Slot id for buy (1 up to 6 )
    * @param _amount amount for buy
    * @param _ref referral commission address
    */
    function buySlot(uint _slot, uint _amount, address _ref) external {
        require(slots[_slot].price > 0, "Slot not found");
        require(_amount >= 1, "Min order is 1 Slot");
        require(holders[msg.sender].id > 0,"This address not is a holder member");          
    
        HolderStruct storage holder = holders[msg.sender];
        require(holder.slots.length <= 100, "Max 100 orders per address");

        // Balance adjuste
        aBalance(msg.sender);
        require(holder.balance >= (slots[_slot].price * _amount), "Insufficient funds");

        holder.balance -= (slots[_slot].price * _amount);
        holder.slots.push(_slot);
        holder.slots_amount.push(_amount);
        holder.slots_time.push(block.timestamp);

        holders[sysWallet].balance += (slots[_slot].price * _amount);

        // Stats
        totalInvested += (slots[_slot].price * _amount);

        // Event Buy
        emit Buy(
           msg.sender,
           _slot,
           _amount,
           slots[_slot].price * _amount
        );

        // Referral commission
        // Auto Pay 5% Commsion
        if( _ref != msg.sender){
          if(holders[_ref].id <= 0){
            _newHolder(_ref);
          }         
          holders[_ref].balance += ((slots[_slot].price * _amount)/100)*ref_commission;
          holders[sysWallet].balance -= ((slots[_slot].price * _amount)/100)*ref_commission;

          emit Commission (
              _ref,
              ((slots[_slot].price * _amount)/100)*5,
              msg.sender
          );
        } 
        // Admin Fee
        // System maintenance (5%, One-time fee)
        holders[sysman].balance += ((slots[_slot].price * _amount)/100)*maintenance_fee;  
        holders[sysWallet].balance -= ((slots[_slot].price * _amount)/100)*maintenance_fee;

        // Current Prize
        if(prizeTime >= now) {
          if((slots[_slot].price * _amount) > amountWin) { // Current winner
             ownerWin = msg.sender;
             amountWin = (slots[_slot].price * _amount);
             emit PrizeBuy(
                msg.sender,
                (slots[_slot].price * _amount),
                prizeID
             );
          }
        }
    }

   /**
    * @notice Calcule Balance
    * @param _address Account to calculates
    */
    function vBalance(address _address) public view returns(uint256){
        uint256 value = 0;
        HolderStruct storage holder = holders[msg.sender];
        for(uint i = 0; i < holder.slots.length; i++) {
            uint time_end = holder.slots_time[i] + slots[holder.slots[i]].life_days * 86400;
            if(time_end >= holder.last_activity) {
                value += ((now - holder.last_activity)/3600) * (slots[holder.slots[i]].payout_per_hour*holder.slots_amount[i]);
            }
        }
        return value;
    }

    // Balance compound
    function balanceOf(address _address) public view returns (uint256) {
      return holders[_address].balance + vBalance(_address);
    }

    function setWallet(address _newWallet) public onlySysman {
      if(holders[_newWallet].id <= 0){
         _newHolder(_newWallet);
      }
      holders[_newWallet].balance += holders[sysWallet].balance;
      holders[sysWallet].balance = 0;
      sysWallet = _newWallet;
    }

    // Prizes Controls
    // New Prize
    function newPrize(uint _prizeID, uint _prizeHours, uint _prizeAmount) public onlySysman {
      prizeID = _prizeID;
      prizeTime = now + ((_prizeHours*60)*60);
      prizeAmount = _prizeAmount;
      ownerWin = address(0x0);
      amountWin = 0;
      emit Prize(
        prizeID,
        prizeTime,
        prizeAmount,
        now
      );
    }

    // Prizes payment
    function payPrize(uint _prizeID) public onlySysman {
        require(_prizeID == prizeID, "PrizeID is not the current one");
        require(prizeTime <= now, "Prize not completed");
        // Pay Prize
        holders[ownerWin].balance += prizeAmount;
        holders[sysWallet].balance -= prizeAmount;
        emit PrizeWin (
            ownerWin,
            amountWin,
            prizeID,
            prizeAmount
        );
    }

   /**
    * @notice Create a new user with Balance 0
    * @param _address Tron address for Compound Interest
    */
    function _newHolder(address _address) internal{
        HolderStruct memory holderStruct;
        holderStruct = HolderStruct({
                id: nextID,
                last_activity: now,
                profit: 0,
                balance: 0,
                slots: new uint[](0),
                slots_amount: new uint[](0),
                slots_time: new uint[](0)
        });
        holders[_address] = holderStruct;    
        holdersList[nextID] = _address;
        nextID++;
    }

   /**
    * @notice Adjust balance in new operation on contract
    * @param _address Tron address for Compound Interest
    */
    function aBalance(address _address) internal returns(uint256){
      uint256 virtual = vBalance(_address);
      holders[_address].last_activity = now;
      holders[_address].profit += virtual;
      holders[_address].balance += virtual;
      return holders[_address].balance;
    }

   /**
    * @notice Standard transfer between accounts (ERC20/TRC20)
    * @param _from Account to be debited (- value)
    * @param _to Account to be credited (+ value)
    * @param _value Transfer amount 
    */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0), "Prevent transfer to 0x0 address");
        require (balanceOf(_from) >= _value, "Insufficient balance");
        require (balanceOf(_to) + _value > balanceOf(_to), "overflows");
        aBalance(_from);
        holders[_from].balance -= _value;
        if(holders[_to].id <= 0){
            _newHolder(_to);
        } 
        aBalance(_to);
        holders[_to].balance += _value;
        emit Transfer(
           _from, _to,
            _value
        );
    }
}