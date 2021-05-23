// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import "./SafeMath.sol";
import "./Token.sol";

/// @title  Контракт ICO

contract TokenCrowdSale {

  using SafeMath for uint256;
  
  address payable private owner; /// адрес владельца
  
  
  uint256 private _openingTime; /// время открытия ICO (Unix Timestamp)
  uint256 private _closingTime; /// время закрытия ICO (Unix Timestamp)
  
  /// @notice вклад в ICO
  mapping(address => uint256) private contributions;
  
  Token private token; /// сам токен 

  uint256 private _rate; /// Сколько единиц токена вкладчик получит за 1 wei
  
  uint256 private _softCap; /// нижний потолок для успешного ICO (в wei)
  uint256 private _hardCap; /// верхний потолок (в wei)

  uint256 private _weiRaised; /// число собранных средств (в wei)

  bool private _allowRefunds = false; /// переменная для возврата средств в случае неуспешного ICO


  modifier onlyWhileOpen {
    require(block.timestamp >= _openingTime && block.timestamp <= _closingTime);
    _;
  }
  
  /// @notice Получить информацию о том, закрыт ли ICO
  function hasClosed() public view returns (bool) {
    return block.timestamp > _closingTime;
  }
  
  /// @notice Получить информацию о том, открыт ли ICO
  function hasOpen() public view returns(bool) {
      return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

  constructor(Token _token, uint256 rate_, uint256 softCap_, uint256 hardCap_, uint256 openingTime_, uint256 closingTime_) public {
    _rate = rate_;
    token = _token;
    _softCap = softCap_;
    _hardCap = hardCap_;
    owner = msg.sender;
    _openingTime = openingTime_;
    _closingTime = closingTime_;
  }
  
  /// @notice Получить нижний границу для успешного ICO
  function softCap() public view returns(uint256) {
      return _softCap;
  }
  
  /// @notice Получить верхнюю границу сборов
  function hardCap() public view returns(uint256) {
      return _hardCap;
  }
  
  /// @notice Получить время открытия ICO
  function openingTime() public view returns(uint256) {
      return _openingTime;
  }
  
  /// @notice Получить время закрытия ICO
  function closingTime() public view returns(uint256) {
      return _closingTime;
  }
  
  /// @notice Получить вклад в ICO
  /// @param  _investor адрес инвестора
  function contribution(address _investor) public view returns(uint256) {
      return contributions[_investor];
  }
  
  /// @notice Получить сколько единиц токена вкладчик получит за 1 wei
  function rate() public view returns(uint256) {
      return _rate;
  }
  
  /// @notice Получить число собранных средств (в wei)
  function weiRased() public view returns(uint256) {
      return _weiRaised;
  }
  
  /// @notice Получить информацию о разрешении на вывод средств (случай неуспешного ICO)
  function allowRefunds() public view returns(bool) {
      return _allowRefunds;
  }
  
  /// @notice Функция для приема средств 
  function() external payable {
    buyTokens(msg.sender);
  }
  
  /// @notice Купить токен
  /// @param _beneficiary адрес бенифициара (кому купленные токены переведутся)
  function buyTokens(address _beneficiary) onlyWhileOpen public payable returns (bool success) {
    
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);
    
    require(_weiRaised.add(weiAmount) <= _hardCap, "The ceiling has already been reached");

    // update state
    _weiRaised = _weiRaised.add(weiAmount);
    contributions[msg.sender] = contributions[msg.sender].add(msg.value);
    _processPurchase(_beneficiary, tokens);
    return true;
  }

  /// @notice Валидация данных для покупки
  function _preValidatePurchase(address _beneficiary,uint256 _weiAmount) internal pure {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /// @notice Доставка токенов бенифициару
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.mint(_beneficiary, _tokenAmount);
  }

  /// @notice Внутренняя функция продолжения процесса покупки токена
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /// @notice Получить число токенов, соответствующих сумме (в wei)
  /// @param _weiAmount сумма в wei
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(_rate);
  }

  /// @notice Разрешить вывод средств (ICO неуспешен)
  function enableRefunds() private {
      require(msg.sender == owner);
      _allowRefunds = true;
  }
  
  /// @notice Вывод средств с ICO (пользователь сам вызывает функцию)
  function refund() public returns (bool success) {
      require(allowRefunds(), 'Refunds is not allowed, ICO is in progress');
      uint amount = contributions[msg.sender];
      if (amount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            contributions[msg.sender] = 0;
    
            if (!msg.sender.send(amount)) {
                // No need to call throw here, just reset the amount owing
                contributions[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
  
  /// @notice Закрытие ICO
  function finalization() public {
    require(msg.sender == owner, "Only owner can finalize ICO");
    require(hasClosed(), "Crowdsale is still open");
    if (goalReached()) {
      token.unpause_token();
      token.finishMint();
      owner.transfer(_weiRaised);
    } else {
      enableRefunds();
      token.finishMint();
    }
  }
    
  /// @notice Проверка достигнута ли цель
  function goalReached() public view returns (bool) {
    return _weiRaised >= _softCap;
  }
}