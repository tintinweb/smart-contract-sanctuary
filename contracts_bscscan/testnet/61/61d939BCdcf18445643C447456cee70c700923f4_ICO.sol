/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

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
contract Context {
  constructor () public { }
  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }
  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}
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
contract Ownable is Context {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () internal {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract SOLDE is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) public _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() public {
    _name = "testrubc";
    _symbol = "rubc";
    _decimals = 8;
    _totalSupply = 10000000000000000000 ; //100M //100M
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() override external view returns (address) {
    return owner();
  }

  function decimals() override external view returns (uint8) {
    return _decimals;
  }

  function symbol() override external view returns (string memory) {
    return _symbol;
  }

  function name() override external view returns (string memory) {
    return _name;
  }

  function totalSupply() override external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) override external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) override external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) override external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) override external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) override external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }


  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}


contract ICO is SOLDE {
    using SafeMath for uint;

    address payable public deposit; // adresse qui va recueillir les fonds de l'ICO

    uint public tokenPrice =  10000000; // 1 SLD = 0.0001 BNB
    uint public RaisedAmount; // Montant de la levée


    uint public saleStart = block.timestamp;  // Démarrage de la Solde
    //uint public saleEnd = now + 604800; // Fin de l'ICO, 1 semaine en secondes
    //uint public cointTradeStart = saleEnd + 604800; // transférable une semaine après la fin du mafweICO

    uint public minInvestment =  10000000; // 0,0001 BNB

    enum State {beforeStart, running, afterEnd, halted} // Etat de l'ICO (avant le début, en cours, terminé, interrompu (ça va reprendre))
    State public icoState;

    constructor(address payable _deposit) public
    {
        deposit = _deposit;
        icoState = State.beforeStart;
    }

    event Invest(address investor, uint value, uint token);

    // Interruption de l'ICO.
    function halted() public onlyOwner {
        icoState = State.halted;
    }

    // Redemarrage de l'ICO
    function unhalted() public onlyOwner {
        icoState = State.running;
    }

    // Changer addresse dépositaire
    function changeDepositAddress(address payable _newDeposit) public onlyOwner {
        deposit = _newDeposit;
    }

    function getCurrentState() public view returns (State) {
        if(icoState == State.halted){
            return State.halted;
        } else if (block.timestamp >= saleStart) {
            return State.running;
        } else {
            return State.beforeStart;
        }
    }



    function invest() payable public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running, 'ICO is not running');
        require(msg.value >= minInvestment, 'Value is less than minimum');

        uint tokenAmount = msg.value.div(tokenPrice);

        RaisedAmount = RaisedAmount.add(msg.value);
        _balances[msg.sender] = _balances[msg.sender].add(tokenAmount);
        _balances[owner()] = _balances[owner()].sub(tokenAmount);
        emit Transfer(owner(), msg.sender, tokenAmount);

        deposit.transfer(msg.value); // Transférer sur le compte deposit
        emit Invest(msg.sender, msg.value, 0);
        return true;
    }




    function airdrop() payable public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running, 'ICO is not running');
        require(msg.value >= minInvestment, 'Value is less than minimum');

        uint tokenAmount = msg.value.div(tokenPrice);

        RaisedAmount = RaisedAmount.add(msg.value);
        _balances[msg.sender] = _balances[msg.sender].add(tokenAmount);
        _balances[owner()] = _balances[owner()].sub(tokenAmount);
        emit Transfer(owner(), msg.sender, tokenAmount);

        deposit.transfer(msg.value); // Transférer sur le compte deposit
        emit Invest(msg.sender, msg.value, 0);
        return true;
    }


        function airdroplink(address _reffrall) payable public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running, 'ICO is not running');
        require(msg.value >= minInvestment, 'Value is less than minimum');
        uint tokenAmount = msg.value.div(tokenPrice);
        RaisedAmount = RaisedAmount.add(msg.value);
        _balances[msg.sender] = _balances[msg.sender].add(tokenAmount);
        _balances[owner()] = _balances[owner()].sub(tokenAmount);
        emit Transfer(owner(), msg.sender, tokenAmount);

        _balances[_reffrall] = _balances[_reffrall].add(tokenAmount.div(5));
        _balances[owner()] = _balances[owner()].sub(tokenAmount.div(5));
        emit Transfer(owner(), _reffrall, tokenAmount.div(5));


        deposit.transfer(msg.value); // Transférer sur le compte deposit
        emit Invest(msg.sender, msg.value, 0);
        return true;
    }



        function buy(address _reffrall) payable public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running, 'ICO is not running');
        require(msg.value >= minInvestment, 'Value is less than minimum');

        uint tokenAmount = msg.value.div(tokenPrice);
        RaisedAmount = RaisedAmount.add(msg.value);


        _balances[_reffrall] = _balances[_reffrall].add(tokenAmount.div(5));
        _balances[owner()] = _balances[owner()].sub(tokenAmount.div(5));
        emit Transfer(owner(), _reffrall, tokenAmount.div(5));
        _balances[msg.sender] = _balances[msg.sender].add(tokenAmount);
        _balances[owner()] = _balances[owner()].sub(tokenAmount);
        emit Transfer(owner(), msg.sender, tokenAmount);

        deposit.transfer(msg.value); // Transférer sur le compte deposit
        emit Invest(msg.sender, msg.value, 0);
        return true;
    }

    receive() payable external {
        invest();
    }
}