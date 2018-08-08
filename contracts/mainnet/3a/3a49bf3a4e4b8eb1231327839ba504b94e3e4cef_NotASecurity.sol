pragma solidity ^0.4.23;

contract NotASecurity {
  uint public totalSupply;

  uint public decimals = 18;
  string public symbol = "NOT";
  string public name = "NotASecurity";

  mapping (address => uint) public balanceOf;
  mapping (address => mapping (address => uint)) internal allowed;

  address[11] public benefactors;
  uint public benefactorsBalance;

  // Caching things for performance reasons
  mapping (address => uint8) private benefactorMap;
  address private lowestBenefactor;

  event Approval(address indexed _owner, address indexed _spender, uint _value);
  event Transfer(address indexed _from, address indexed _to, uint _value);

  constructor (uint _fee) public {
    benefactors[1] = msg.sender;
    lowestBenefactor = address(0);
    benefactorMap[msg.sender] = 1;
    balanceOf[msg.sender] = _fee;
    totalSupply = _fee;
    benefactorsBalance = _fee;
  }

  function buy() payable public returns (uint) {
    uint _wei = msg.value;
    address _investor = msg.sender;

    require(_wei > 0);
    require(distribute(_wei));

    balanceOf[_investor] += _wei;
    totalSupply += _wei;

    require(reorganize(_wei, _investor));

    return _wei;
  }

  function () payable public {
    buy();
  }

  event Distribution(address _addr, uint _amount);

  function distribute(uint _amount) public returns (bool) {
    for (uint _i = 1; _i < benefactors.length; _i++) {
      address _benefactor = benefactors[_i];
      uint _benefactorBalance = balanceOf[_benefactor];

      uint _amountToTransfer = (_benefactorBalance * _amount) / benefactorsBalance;
      emit Distribution(_benefactor, _amountToTransfer);

      if (_amountToTransfer > 0 && _benefactor != address(0)) {
        _benefactor.transfer(_amountToTransfer);
      }
    }

    return true;
  }

  function findLowestBenefactor() public returns (address) {
    address _lowestBenefactor = benefactors[1];
    address _benefactor;
    for (
      uint _j = 2;
      _j < benefactors.length;
      _j++
    ) {
      _benefactor = benefactors[_j];
      if (_benefactor == address(0)) {
        return _benefactor;

      } else if (balanceOf[_benefactor] < balanceOf[_lowestBenefactor]) {
        _lowestBenefactor = _benefactor;
      }
    }
    return _lowestBenefactor;
  }

  function findEmptyBenefactorIndex() public returns (uint8) {
    for (uint8 _i = 1; _i < benefactors.length; _i++) {
      if (benefactors[_i] == address(0)) {
        return _i;
      }
    }

    return 0;
  }

  function reorganize(uint _amount, address _investor) public returns (bool) {
    // if investor is already a benefactor
    if (benefactorMap[_investor] > 0) {
      benefactorsBalance += _amount;

    // if investor is now a top token holder
    } else if (balanceOf[_investor] > balanceOf[lowestBenefactor]) {
      bool _lowestBenefactorEmpty = lowestBenefactor == address(0);
      uint _oldBalance = balanceOf[lowestBenefactor];
      uint8 _indexToSwap = _lowestBenefactorEmpty
        ? findEmptyBenefactorIndex()
        : benefactorMap[lowestBenefactor];

      // Swap out benefactors
      if (!_lowestBenefactorEmpty) {
        benefactorMap[lowestBenefactor] = 0;
      }
      benefactors[_indexToSwap] = _investor;
      benefactorMap[_investor] = _indexToSwap;
      lowestBenefactor = findLowestBenefactor();

      // Adjust benefactors balance
      benefactorsBalance += (balanceOf[_investor] - _oldBalance);

    }

    return true;
  }

  function _transfer(
    address _from,
    address _to,
    uint _amount
  ) internal returns (bool success) {
    require(_to != address(0));
    require(_to != address(this));
    require(_amount > 0);
    require(balanceOf[_from] >= _amount);
    require(balanceOf[_to] + _amount > balanceOf[_to]);

    balanceOf[_from] -= _amount;
    balanceOf[_to] += _amount;

    // reorganize for both addresses

    emit Transfer(msg.sender, _to, _amount);

    return true;
  }

  function transfer(address _to, uint _amount) public returns (bool success) {
    return _transfer(msg.sender, _to, _amount);
  }

  function transferFrom(address _from, address _to, uint _amount) external returns (bool success) {
    require(allowed[_from][msg.sender] >= _amount);

    bool _tranferSuccess = _transfer(_from, _to, _amount);
    if (_tranferSuccess) {
      allowed[_from][msg.sender] -= _amount;
      return true;
    } else {
      return false;
    }
  }

  function approve(address _spender, uint _value) external returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) external constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}