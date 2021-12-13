/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract UtilitiesContract {
  address internal _ownerAddress;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }

  modifier onlyOwner() {
    require(_ownerAddress == _msgSender(), "Ownable: caller is not the _ownerAddress");
    _;
  }

  function transferOwnership(address newOwnerAddress) public onlyOwner {
    require(newOwnerAddress != address(0), "Ownable: new _ownerAddress is the zero address");
    emit OwnershipTransferred(_ownerAddress, newOwnerAddress);
    _ownerAddress = newOwnerAddress;
  }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract TaxFunctionsContract is UtilitiesContract { 
  using SafeMath for uint256;
  uint256 internal _liquidityTax; // Default : 2
  uint256 internal _developmentTax; // Default : 4
  uint256 internal _prizeTax; //Default : 4
  uint256 internal _burnTax; //Default : 2

  address internal _liquidityAddress;
  address internal constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
  address internal constant _prizeAddress = 0x7770000000000000000000000000000000000777;

  //////////////////////////////////////////////////////////
  //////////////////////Liquidity functions/////////////////
  function getLiquidityTax() external view returns (uint256) { 
    return _liquidityTax;
  }

  function setLiquidityTax(uint256 value) external onlyOwner {
    require(value.add(_burnTax).add(_developmentTax).add(_prizeTax) <= 12, "Liquidity tax is too high");
    _liquidityTax = value;
  }

  function getLiquidityAddress() external view returns (address){
    return _liquidityAddress;
  }

  function setLiquidityAddress(address _address) external onlyOwner () { 
    _liquidityAddress = _address;
  }
  //////////////////////Liquidity functions/////////////////
  //////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////
  //////////////////////Development functions///////////////
  function getDevelopmentTax() external view returns (uint256) { 
    return _developmentTax;
  }

  function setDevelopmentTax(uint256 value) external onlyOwner {
    require(value.add(_liquidityTax).add(_burnTax).add(_prizeTax) <= 12, "Development tax is too high");
    _developmentTax = value;
  }
  //////////////////////Development functions///////////////
  //////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////
  //////////////////////Burn functions//////////////////////
  function setBurnTax(uint256 value) external onlyOwner {
    require(value.add(_liquidityTax).add(_developmentTax).add(_prizeTax) <= 12, "Burn tax is too high");
    _burnTax = value;
  }

  function getBurnTax() external view returns (uint256) { 
    return _burnTax;
  }

  function getBurnAddress() external pure returns (address){
    return _burnAddress;
  }
  //////////////////////Burn functions//////////////////////
  //////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////
  //////////////////////Prize functions//////////////////////
  function setPrizeTax(uint256 value) external onlyOwner {
    require(value.add(_liquidityTax).add(_burnTax).add(_developmentTax) <= 12, "Prize tax is too high");
    _prizeTax = value;
  }

  function getPrizeTax() external view returns (uint256) { 
    return _prizeTax;
  }

  function getPrizeAddress() external pure returns (address){
    return _prizeAddress;
  }
  //////////////////////Prize functions//////////////////////
  //////////////////////////////////////////////////////////
}

abstract contract StandarBEP20TokenContract is IBEP20, TaxFunctionsContract {
  using SafeMath for uint256;
  mapping (address => uint256) internal _balances;
  mapping (address => mapping (address => uint256)) internal _allowances;
  uint256 internal constant _totalSupply = 100000000 * 10 ** 8;
  uint8 private constant _decimals = 8;
  string private constant _symbol = "TestV7";
  string private constant _name = "TestV7";

  //////////////////////////////////////////////////////////
  //////////////////////Utility functions///////////////////
  function decimals() override external pure returns (uint8) {
    return _decimals;
  }

  function symbol() override external pure returns (string memory) {
    return _symbol;
  }

  function name() override external pure returns (string memory) {
    return _name;
  }

  function totalSupply() override external pure returns (uint256) {
    return _totalSupply;
  }

  function getAvailableSupply() external view returns (uint256) {
    return _totalSupply.sub(_balances[_burnAddress]);
  }

  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  /* function transfer(address recipient, uint256 amount) external returns (bool); */

  function allowance(address _owner, address spender) override external view returns (uint256) {
    return _allowances[_owner][spender];
  }

  function approve(address spender, uint256 amount) override external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /* function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool); */

  function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
    _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].add(_addedValue));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].sub(subtractedValue));
    return true;
  }

  function _approve(address addressValue, address _spender, uint256 amount) internal {
    require(addressValue != address(0), "BEP20: approve from the zero address");
    require(_spender != address(0), "BEP20: approve to the zero address");

    _allowances[addressValue][_spender] = amount;
    emit Approval(addressValue, _spender, amount);
  }

  function getOwner() override external view returns (address) {
    return _ownerAddress;
  }
  //////////////////////Utility functions///////////////////
  //////////////////////////////////////////////////////////
}

contract SepgodToken is TaxFunctionsContract, StandarBEP20TokenContract {
  using SafeMath for uint256;
  address[] private _jackpotWinners = new address[](0);
  uint256 private _lastJackpotTimestamp = 0;
  uint256 private _nextjackpotTimestamp = 0;

  address[] private _tickets = new address[](0);

  uint256[] private _lastBuyTokensAmount = new uint256[](25);
  uint256 private _lastBuyTokensAmountIndex = 0;

  uint256[] private _lastBuyTicketPrice = new uint256[](10);
  uint256 private _lastBuyTicketPriceIndex = 0;
  
  event BuyTicketEvent(address indexed buyer, uint256 quantityOfTickets);

  constructor () {
    address msgSender = _msgSender();

    _liquidityTax = 2;
    _burnTax = 2;
    _developmentTax = 4;
    _prizeTax = 4;

    setNextJackpotTimestamp();

    _ownerAddress = msgSender;
    emit OwnershipTransferred(address(0), msgSender);

    _balances[msgSender] = _totalSupply;
    emit Transfer(address(0), msgSender, _totalSupply);
  }

  function getPrizeAddressBalance() external view returns (uint256){
    return _balances[_prizeAddress];
  }

  function getBurnAddressBalance() external view returns (uint256){
    return _balances[_burnAddress];
  }

  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
    return true;
  }
  
  //Standar Transfer
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount);
    bool applyTaxes = !(sender == _ownerAddress || recipient == _ownerAddress);

    if(sender == _liquidityAddress && recipient != _ownerAddress) { 
      _lastBuyTokensAmount[_lastBuyTokensAmountIndex] = amount;
      _lastBuyTokensAmountIndex = _lastBuyTokensAmountIndex + 1 >= _lastBuyTokensAmount.length ? 0 : _lastBuyTokensAmountIndex + 1;
    }

    uint256 onePorcentAmount = amount.div(100);

    if(_prizeTax > 0 && applyTaxes) {
      uint256 prizeTaxAmount = onePorcentAmount.mul(_prizeTax);
      _balances[_prizeAddress] = _balances[_prizeAddress].add(prizeTaxAmount);
      amount -= prizeTaxAmount;
      emit Transfer(sender, _prizeAddress, prizeTaxAmount);

      uint256 ticketPrice = getTicketPrice();
      if(prizeTaxAmount >= ticketPrice) { 
        uint256 ticketsQuantity = 0;

        _lastBuyTicketPrice[_lastBuyTicketPriceIndex] = ticketPrice;
        _lastBuyTicketPriceIndex = _lastBuyTicketPriceIndex + 1 >= _lastBuyTicketPrice.length ? 0 : _lastBuyTicketPriceIndex + 1;

        for(uint256 i = 0; i < 5; i++){
          if(prizeTaxAmount >= ticketPrice) {
            ticketsQuantity++;
            _tickets.push(sender);
            prizeTaxAmount = prizeTaxAmount - ticketPrice;
          } else {
            break;
          }
        }

        emit BuyTicketEvent(sender, ticketsQuantity);
      }
    }

    if(_burnTax > 0 && applyTaxes) {
      uint256 burnTaxAmount = onePorcentAmount.mul(_burnTax);
      _balances[_burnAddress] = _balances[_burnAddress].add(burnTaxAmount);
      amount -= burnTaxAmount;

      emit Transfer(sender, _burnAddress, burnTaxAmount);
    }
    
    if(_liquidityTax > 0 && _liquidityAddress != address(0) && applyTaxes) {
      uint256 liquidityTaxAmount = onePorcentAmount.mul(_liquidityTax);
      _balances[_liquidityAddress] = _balances[_liquidityAddress].add(liquidityTaxAmount);
      amount -= liquidityTaxAmount;

      emit Transfer(sender, _liquidityAddress, liquidityTaxAmount);
    }
    
    if(_developmentTax > 0 && _ownerAddress != address(0) && applyTaxes) {
      uint256 developmentTaxAmount = onePorcentAmount.mul(_developmentTax);
      _balances[_ownerAddress] = _balances[_ownerAddress].add(developmentTaxAmount);
      amount -= developmentTaxAmount;

      emit Transfer(sender, _ownerAddress, developmentTaxAmount);
    }

    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);

    if(isJackpotAvailable() == true) {
      initJackpot();
    }
  }

  function buyTicket(uint ticketsQuantity) external { 
    require(ticketsQuantity > 0, "Tickets Quantity Must be > 0");
    require(ticketsQuantity <= 10, "You can't purchase more than 10 Tickets in the same transaction");

    address sender = _msgSender();
    uint256 ticketPrice = getTicketPrice();
    uint256 totalAmount = ticketPrice.mul(ticketsQuantity);

    if(_balances[sender] >= totalAmount) { 
      _lastBuyTicketPrice[_lastBuyTicketPriceIndex] = ticketPrice;
      _lastBuyTicketPriceIndex = _lastBuyTicketPriceIndex + 1 >= _lastBuyTicketPrice.length ? 0 : _lastBuyTicketPriceIndex + 1;

      uint256 totalAmountTenPorcent = totalAmount.div(10);
      uint256 totalAmountNintyPorcent = totalAmountTenPorcent.mul(9);

      _balances[sender] = _balances[sender].sub(totalAmount);
      _balances[_burnAddress] = _balances[_burnAddress].add(totalAmountTenPorcent);
      _balances[_prizeAddress] = _balances[_prizeAddress].add(totalAmountNintyPorcent);

      emit Transfer(sender, _burnAddress, totalAmountTenPorcent);
      emit Transfer(sender, _prizeAddress, totalAmountNintyPorcent);
      emit BuyTicketEvent(sender, ticketsQuantity);

      for(uint i = 0; i < ticketsQuantity; i++) { 
        _tickets.push(sender);
      }
    }else {
      revert("Balance < totalTicketsPriceAmount");
    }
  }

  function getTicketsQuantity() external view returns (uint256)  { 
    return _tickets.length;
  }

  function isJackpotAvailable() internal view returns(bool) {
    if(getRemainingTimestampToNextJackpot() > 0) { 
      return false;
    } else {
      return true;
    }
  }

  function initJackpot() public { 
    require(isJackpotAvailable() == true, "Remaining Time to Next jackpot > 0");
    if(_tickets.length == 0) { 
      setNextJackpotTimestamp();
      return;
    }

    address winnerAddress = _tickets[randomTicketIndex()];
    uint256 jackpotAmount = _balances[_prizeAddress];

    _balances[winnerAddress] = _balances[winnerAddress].add(jackpotAmount);
    _balances[_prizeAddress] = 0;
    _jackpotWinners.push(winnerAddress);
    _tickets = new address[](0);
    setNextJackpotTimestamp();

    emit Transfer(_prizeAddress, winnerAddress, jackpotAmount);
  }

  function getLastJackpotWinner() external view returns(address) { 
    if(_jackpotWinners.length > 0) { 
      return _jackpotWinners[_jackpotWinners.length - 1];
    }else { 
      return address(0);
    }
  }
  
  function getLastJackpotTimestamp() external view returns (uint256) {
    return _lastJackpotTimestamp;
  }

  function getNextJackpotTimestamp() external view returns (uint256) {
    return _nextjackpotTimestamp;
  }

  function getRemainingTimestampToNextJackpot() public view returns (uint256) {
    uint blockTimestamp = block.timestamp;
    uint nextJackpotTitemsap = _nextjackpotTimestamp;
    if(blockTimestamp <= nextJackpotTitemsap) {
      return nextJackpotTitemsap - blockTimestamp;
    }else{
      return 0;
    }
  }

  function randomTicketIndex() internal view returns (uint256) {
    require(_tickets.length > 0, "Tickets length == 0");
    return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, uint256(_tickets.length)))) % _tickets.length;
  }

  function getAverageLast25TransactionsAmount() internal view returns (uint256){ 
    uint256 amount = 0;
    uint256 validTransactions = 0;

    for(uint256 i = 0; i < _lastBuyTokensAmount.length; i++) { 
      if(_lastBuyTokensAmount[i] > 0) {
        amount += _lastBuyTokensAmount[i];
        validTransactions++;
      }
    }

    if(validTransactions == 0 || amount == 0) { 
      return uint256(10000 * 10 ** 8);
    } else {
      return amount.div(validTransactions);
    }
  }

  function getAverageLast10TicketPrice() internal view returns (uint256){ 
    uint256 amount = 0;
    uint256 validTickets = 0;
    for(uint256 i = 0; i < _lastBuyTicketPrice.length; i++) { 
      if(_lastBuyTicketPrice[i] > 0) {
        amount += _lastBuyTicketPrice[i];
        validTickets++;
      }
    }

    if(validTickets == 0 || amount == 0) { 
      return uint256(10000 * 10 ** 8);
    } else {
      return amount.div(validTickets);
    }
  }

  function getTicketPrice() public view returns (uint256) { 
    uint256 averageTransactionAmount = getAverageLast25TransactionsAmount().div(100);
    uint256 averageTicketPrice = getAverageLast10TicketPrice();

    uint256 CeilPrice = averageTicketPrice.div(10).mul(12);
    uint256 FloorPrice = averageTicketPrice.div(10).mul(8);

    if(averageTransactionAmount >= CeilPrice) { 
      return CeilPrice;
    }

    if(averageTransactionAmount <= FloorPrice) {
      return FloorPrice; 
    }

    return averageTransactionAmount;
  }

  function setNextJackpotTimestamp() internal {
    _lastJackpotTimestamp = block.timestamp;
    _nextjackpotTimestamp = block.timestamp + 4 minutes;
  }
}