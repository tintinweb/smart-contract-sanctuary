//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.4;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // The account hash of 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned for non-contract addresses,
        // so-called Externally Owned Account (EOA)
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract PrivateSale is Ownable {
  using SafeMath for uint256;
  using Address for address;

  struct PrivateSaleWhiteListStruct {
      address addresses;
      bool inserted;
      uint256 tokenBuyed;
      uint256 bnbBuyed;
      bool deleted;

  }
  mapping (address => PrivateSaleWhiteListStruct) private _PrivateSaleWhiteList;
  address[] private _PrivateSaleWhiteListAccounts;

  uint256 public rate; // rate
  uint256 public minTrade; // 0.5 bnb
  uint256 public maxTrade; // 1 bnb

  // address del wallet
  address payable public wallet;
  uint public startDate;
  uint public endDate;
  bool public finalized;
  uint256 public bnbRemaining;

  event TokensPurchased(address buyer, uint256 BNBSold, uint256 tokenAmount, uint256 rate);
  event WithdrawAll(address wallet, uint256 total);

  constructor ()  {
  }

  //////////////////////////// funzioni del contratto di base /////////////////////////////////////

  ///////////////////////////////// funzioni per la private Sale //////////////////////////////////
  function buyTokens () public payable returns (bool) {
      uint256 tokenDecimals = 9;
      // Calculate the number of tokens to buy
      uint256 tokenAmount = (((msg.value).mul(rate)).div(10**18)).mul(
          10**tokenDecimals
      );
      require(isPrivateSaleActive(), "The Private Sale isn't active");
      require(
          msg.value == minTrade || msg.value == maxTrade,
          "The BNB amount should be minTrade or maxTrade"
      );
      require(get_InsertedPrivateSaleWhiteList(msg.sender), "The address it isn't in whitelist");
      // Emit an event
      emit TokensPurchased(msg.sender, msg.value, tokenAmount, rate);
      bnbRemaining = bnbRemaining.sub(msg.value);
      set_ValuesPrivateSaleWhiteList(msg.sender,tokenAmount,msg.value);
      return true;
  }

  function withdraw() public onlyOwner {
      uint256 totalToTransfer = address(this).balance; //esprime il balance in BNB
      require(totalToTransfer > 0, "The balance should be >0");
      wallet.transfer(totalToTransfer);
      emit WithdrawAll(wallet, totalToTransfer);
  }

  function isPrivateSaleActive() public view returns (bool isActive) {
      uint nowDate = block.timestamp;
      isActive =
          nowDate >= startDate &&
          nowDate <= endDate &&
          !finalized &&
          bnbRemaining > 0;
  }

  function currentTime () public view returns (uint) {
      return block.timestamp;
  }

  function setFinalize (bool _finalized) public onlyOwner {
      finalized = _finalized;
  }

  function getFinalize () public view returns (bool) {
      return finalized;
  }

  // Set wallet address whre will place the amount of sale
  function setWallet (address _wallet) public onlyOwner {
      wallet = payable(_wallet);
  }

  function getWallet () public view returns (address) {
      return wallet;
  }

  function setRate (uint256 _rate) public onlyOwner {
      rate = _rate;
  }

  function getRate () public view returns (uint256) {
      return rate;
  }

  function setStartDate (uint _start) public onlyOwner {
      startDate = _start;
  }

  function getStartDate () public view returns (uint) {
      return startDate;
  }

  function setEndDate (uint _end) public onlyOwner {
      endDate = _end;
  }

  function getEndDate () public view returns (uint) {
      return endDate ;
  }

  function setMinTrade (uint256 _min) public onlyOwner {
      minTrade = _min;
  }

  function getMinTrade () public view returns (uint256) {
      return minTrade;
  }

  function setMaxTrade (uint256 _max) public onlyOwner {
      maxTrade = _max;
  }

  function getMaxTrade () public view returns (uint256) {
      return maxTrade;
  }

  function setbnbRemaining (uint256 _bnbremaining) public onlyOwner {
      bnbRemaining = _bnbremaining;
  }

  // funzione che restituisce i BNB ancora rimanenti da comprare
  function getbnbRemaining () public view returns (uint256) {
      return bnbRemaining;
  }

  // fuunzione che calcola quanto manca alla partenza
  function getStarIntDate () public view returns (uint) {
      uint starIntDate;
      if (block.timestamp >= startDate) starIntDate = 0;
      else starIntDate =  startDate.sub(block.timestamp);
      return starIntDate;
  }

  // fuunzione che calcola quanto manca alla partenza
  function getEndIntDate () public view returns (uint) {
      uint endIntDate;
      if (block.timestamp >= endDate) endIntDate = 0;
      else endIntDate =  endDate.sub(block.timestamp);
      return endIntDate;
  }

  function setStartParameters(
    uint256 _rate,
    uint256 _minTrade,
    uint256 _maxTrade,
    address _wallet,
    uint _startDate,
    uint _endDate,
    bool _finalized,
    uint256 _bnbRemaining
  ) public onlyOwner {

    setRate (_rate); // 18000000000
    setMinTrade (_minTrade); // 500000000000000000 = 0.5 bnb
    setMaxTrade (_maxTrade); // 1000000000000000000 = 1 bnb
    setWallet (_wallet);
    setStartDate (_startDate); // UnixTime
    setEndDate (_endDate); // UnixTime
    setFinalize (_finalized); // false
    setbnbRemaining (_bnbRemaining); // 60000000000000000000 = 50 BNB
  }

  function popolateWhitelistAddresses (address[] memory startWhiteListAddrs) public onlyOwner {
    uint256 size = startWhiteListAddrs.length;
    address keyAddress;
    if (size>0) {
      for (uint256 i = 0; i < size ; i++) {
          keyAddress = startWhiteListAddrs[i];
          set_ValuesPrivateSaleWhiteList(keyAddress,0,0);
      }
    }
  }

  /////////////////////////////////////////////////////////////////////////////////////////
  ////////////////////// funzioni del mapping PrivateSaleWhiteList ////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////

  function set_BnbBuyedPrivateSaleWhiteList (address addr, uint256 value) public onlyOwner {
     _PrivateSaleWhiteList[addr].bnbBuyed = value;
  }

  function get_BnbBuyedPrivateSaleWhiteList (address addr) public view returns (uint256) {
     return _PrivateSaleWhiteList[addr].bnbBuyed;
  }

  function set_TokenBuyedPrivateSaleWhiteList (address addr, uint256 value) public onlyOwner {
     _PrivateSaleWhiteList[addr].tokenBuyed = value;
  }

  function get_TokenBuyedPrivateSaleWhiteList (address addr) public view returns (uint256) {
     return _PrivateSaleWhiteList[addr].tokenBuyed;
  }

  function set_DeletedPrivateSaleWhiteList (address addr, bool value) public onlyOwner {
     _PrivateSaleWhiteList[addr].deleted = value;
  }

  function get_DeletedPrivateSaleWhiteList (address addr) private view returns (bool) {
     return _PrivateSaleWhiteList[addr].deleted;
  }

  function get_InsertedPrivateSaleWhiteList (address addr) private view returns (bool) {
     return _PrivateSaleWhiteList[addr].inserted;
  }

  function get_SizePrivateSaleWhiteList () public onlyOwner view returns (uint) {
     return _PrivateSaleWhiteListAccounts.length;
  }

  function get_AllPrivateSaleWhiteList () public onlyOwner view returns (address[] memory) {
     return _PrivateSaleWhiteListAccounts;
  }

  function set_ValuesPrivateSaleWhiteList(
     address addr,
     uint256 tokenbuyed,
     uint256 bnbbuyed
     ) private {

     if (_PrivateSaleWhiteList[addr].inserted) {
         _PrivateSaleWhiteList[addr].tokenBuyed = tokenbuyed;
         _PrivateSaleWhiteList[addr].bnbBuyed = bnbbuyed;
         _PrivateSaleWhiteList[addr].deleted = false;
     } else {
         _PrivateSaleWhiteList[addr].inserted = true;
         _PrivateSaleWhiteList[addr].tokenBuyed = tokenbuyed;
         _PrivateSaleWhiteList[addr].bnbBuyed = bnbbuyed;
         _PrivateSaleWhiteList[addr].deleted = false;
         _PrivateSaleWhiteListAccounts.push(addr);
     }
  }

}