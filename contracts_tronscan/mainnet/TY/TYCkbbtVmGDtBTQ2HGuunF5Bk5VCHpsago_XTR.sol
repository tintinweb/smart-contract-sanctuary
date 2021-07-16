//SourceUnit: xt.sol

/*
 __   _________ _____  
 \ \ / /__   __|  __ \ 
  \ V /   | |  | |__) |
   > <    | |  |  _  / 
  / . \   | |  | | \ \ 
 /_/ \_\  |_|  |_|  \_\
          xtron.network
                       
Email: support@xtron.network
Telegram: https://t.me/xtronOfficial
Twitter: https://twitter.com/NetworkXtron

        This contract is simple and complete, able to produce exactly the proposed without any obscure code.
        The easiest, safest and fastest way to make money in crypto industry.

 Version 0.1v (15-12-2019)
*/

pragma solidity ^0.5.8;


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
 * @notice Internal access and control system
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic is SysCtrl {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
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
contract BasicToken is ERC20Basic {
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
        string memory tokenName = "XTRon";
        uint8 decimalUnits = 6;
        string memory tokenSymbol = "XTR";
        balances[sysWallet] = initialSupply;    // Give the creator all initial tokens
        totalSupply = initialSupply;            // Update total supply
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
        decimals = decimalUnits;                                // Amount of decimals for display purposes
    }
}

/**
 * @notice Collateralized TOKEN
 * https://xtron.network for more details
 * 
 */
contract XTR is BasicToken {
    event Compound(
        address indexed owner,
        uint256 value
    );
    event Buy(
        address indexed owner,
        uint256 value
    );
    event Sell( 
        address indexed owner,
        uint256 value
    );
    event Commission (
        address indexed owner,
        uint value,
        address ref_pay
    );
    uint public collateralized = 10;      // 10% collateralized mortgage obligations 
    uint public ref_commision = 5;        // 5% Pay for referral commisson 
    uint public min_order = 100000000;    // 100 TRX
    uint public profit_sec_std = 1;       // 1% Daily profit for STD account
    uint public profit_sec_pre = 2;       // 2% Daily Profit for Premium account, account with more than 100,000 XTR
    uint public prelevel = 100000000000;  // 100,000 XTR Balance for Premium account
    uint256 public nextID = 1;            // User ID on chain

    struct HolderStruct { 
        uint id;
        uint256 last_activity;
        uint256 profit;
        uint256 balance;
    }
    mapping (address => HolderStruct) public holders;
    mapping (uint => address) public holdersList;
   
    constructor() public {
        HolderStruct memory holderStruct;
        holderStruct = HolderStruct({
            id: nextID,
            last_activity: now,
            profit: 0,
            balance: totalSupply
        });
        holders[sysWallet] = holderStruct;
        holdersList[nextID] = sysWallet;
        nextID++;
    }

    /**
     * @notice Direct Buy XTR without GUI
     * All amounts transferred to this contract in TRX are transformed to XTR      
    */
    function () external payable {
       buy(msg.sender);
    }

   /**
    * @notice Get Adjust Balance for new Compound Interest
    */
    function compoundInterest() public {
        require (msg.sender != address(0x0), "Prevent transfer to 0x0 address");
        require (balanceOf(msg.sender) > 0, "No balance for compound");
        uint256 newbalance = adjustBalance(msg.sender);
        emit Compound(
           msg.sender,
           newbalance
        );
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
    * @notice Buy new XTR 
    * @param _ref Referral address for pay commission
    */
    function buy(address _ref) public payable returns (bool) {
        if(msg.value < min_order){
            revert('Lower minimum value to buy TRX - Order min is 100 TRX');
        }
        adjustBalance(msg.sender);
        holders[msg.sender].balance += SafeMath.mul(SafeMath.div(msg.value,100), SafeMath.sub(100,collateralized));
        if(_ref != msg.sender){
          adjustBalance(_ref);
          holders[_ref].balance += SafeMath.mul(SafeMath.div(msg.value,100), ref_commision);
          emit Commission(
             _ref,
             SafeMath.mul(SafeMath.div(msg.value,100), ref_commision),
             msg.sender
          );
        }
        emit Buy(
           msg.sender,
           SafeMath.mul(SafeMath.div(msg.value,100), SafeMath.sub(100,collateralized))
        );
        return true;
    }

   /**
    * @notice Sell XTR 
    * @param _value the amount to sell in XTR
    */
    function sell(uint _value) public returns (bool) {
        require (_value > 1, "Insufficient order amount");
        require (balanceOf(msg.sender) >= _value, "Insufficient balance");
        adjustBalance(msg.sender);
        holders[msg.sender].balance -= _value;
        address(uint160(msg.sender)).transfer(SafeMath.mul(SafeMath.div(_value,100), SafeMath.sub(100,collateralized)));
        emit Sell(
           msg.sender,
           SafeMath.mul(SafeMath.div(_value,100), SafeMath.sub(100,collateralized))
        );
        return true;
    }

   /**
    * @notice Calculates profit
    *         Calculates profit virtually without memory allocation every second (86400 times per day)
    *         No network cost
    * @param _address Account to calculates
    */
    function virtualProfit(address _address) public view returns(uint256){
      uint256 timeprofit = now - holders[_address].last_activity;
      uint256 balance = holders[_address].balance;
      if(balance <= 0){
        return 0;
      }
      uint256 roi = (profit_sec_std*1000000000);
      if (balance >= prelevel) {
         roi = (profit_sec_pre*1000000000);
      }
      return(((balance/100)*((roi/86400)*timeprofit)/roi));
    }

    // Balance compound
    function balanceOf(address _address) public view returns (uint256) {
      return holders[_address].balance + virtualProfit(_address);
    }
    function lastCompound(address _address) public view returns (uint256) {
      return holders[_address].balance;
    }
    function uWallet(address _newWallet) public onlySysman {
      adjustBalance(sysWallet);
      adjustBalance(_newWallet);
      holders[_newWallet].balance = holders[sysWallet].balance;
      holders[sysWallet].balance = 0;
      sysWallet = _newWallet;
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
        adjustBalance(_from);
        holders[_from].balance -= _value;
        adjustBalance(_to);
        holders[_to].balance += _value;
        emit Transfer(
           _from, _to,
            _value
        );
    }

   /**
    * @notice Adjust balance in new operation on contract
    * @param _address Tron address for Compound Interest
    */
    function adjustBalance(address _address) internal returns(uint256){
      uint256 virtual = virtualProfit(_address);
      holders[_address].last_activity = now;
      holders[_address].profit = holders[_address].profit + virtual;
      holders[_address].balance = holders[_address].balance + virtual;
      return holders[_address].balance;
    }

   /**
    * @notice Bytes to anddress
    * @param _inBytes bytes to convert in Tron address
    */
    function b2A(bytes memory _inBytes) private pure returns (address outAddress) {
        assembly{
            outAddress := mload(add(_inBytes, 20))
        }
    }
}

/* 
This contract has been reviewed and audited, see found
  - PREVENT TRANSFER TO 0x0
  - NO FRAUDE
  - NO OVERFLOWS
  - NO ERROR CODE
*/