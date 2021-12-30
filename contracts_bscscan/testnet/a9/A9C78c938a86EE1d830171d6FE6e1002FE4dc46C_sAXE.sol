// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./types/ERC20.sol";
import "./types/AccessControlled.sol";
import "./interfaces/IERC20.sol";

contract sAXE is ERC20, AccessControlled {

  event LogSupply(uint256 indexed epoch, uint256 totalSupply);
  event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);
  event LogStakingContractUpdated(address stakingContract);

  struct Rebase {
      uint256 epoch;
      uint256 rebase;
      uint256 totalStakedBefore;
      uint256 totalStakedAfter;
      uint256 amountRebased;
      uint256 index;
      uint256 blockNumberOccured;
  }

  uint256 internal INDEX;
  Rebase[] public rebases;

  uint256 private constant MAX_UINT256 = type(uint256).max;
  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5_000_000 * 10**9;
  uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
  uint256 private constant MAX_SUPPLY = ~uint128(0);
  uint256 private _gonsPerFragment;
  mapping(address => uint256) private _gonBalances;
  mapping(address => mapping(address => uint256)) private _allowedValue;
  uint256 private _totalSupply;

  constructor(address _authority)
  ERC20("Staked Axe", "sAXE")
  AccessControlled(IAuthority(_authority)) {
    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _gonsPerFragment = TOTAL_GONS / _totalSupply;
  }

  function decimals() public pure override returns (uint8) {
      return 9;
  }

  function setIndex(uint256 _index) external onlyGovernor {
      require(INDEX == 0, "Cannot set INDEX again");
      INDEX = gonsForBalance(_index);
  }

  function initialize() external onlyGovernor {
      _gonBalances[authority.get('staking')] = TOTAL_GONS;
      emit Transfer(address(0x0), authority.get('staking'), _totalSupply);
      emit LogStakingContractUpdated(authority.get('staking'));
  }

  function rebase(uint256 profit_, uint256 epoch_) public onlyStaking returns (uint256) {
      uint256 rebaseAmount;
      uint256 circulatingSupply_ = circulatingSupply();
      if (profit_ == 0) {
          emit LogSupply(epoch_, _totalSupply);
          emit LogRebase(epoch_, 0, index());
          return _totalSupply;
      } else if (circulatingSupply_ > 0) {
          rebaseAmount = profit_ * _totalSupply / circulatingSupply_;
      } else {
          rebaseAmount = profit_;
      }
      _totalSupply = _totalSupply + rebaseAmount;
      if (_totalSupply > MAX_SUPPLY) {
          _totalSupply = MAX_SUPPLY;
      }
      _gonsPerFragment = TOTAL_GONS / _totalSupply;
      _storeRebase(circulatingSupply_, profit_, epoch_);
      return _totalSupply;
  }

  function _storeRebase(
      uint256 previousCirculating_,
      uint256 profit_,
      uint256 epoch_
  ) internal {
      uint256 rebasePercent = profit_ * 1e18 / previousCirculating_;
      rebases.push(
          Rebase({
              epoch: epoch_,
              rebase: rebasePercent, // 18 decimals
              totalStakedBefore: previousCirculating_,
              totalStakedAfter: circulatingSupply(),
              amountRebased: profit_,
              index: index(),
              blockNumberOccured: block.number
          })
      );

      emit LogSupply(epoch_, _totalSupply);
      emit LogRebase(epoch_, rebasePercent, index());
  }

  function transfer(address to, uint256 value) public override returns (bool) {
      uint256 gonValue = value * _gonsPerFragment;

      _gonBalances[msg.sender] = _gonBalances[msg.sender] - gonValue;
      _gonBalances[to] = _gonBalances[to] + gonValue;

      emit Transfer(msg.sender, to, value);
      return true;
  }

  function transferFrom(
      address from,
      address to,
      uint256 value
  ) public override returns (bool) {
      _allowedValue[from][msg.sender] = _allowedValue[from][msg.sender] - value;
      emit Approval(from, msg.sender, _allowedValue[from][msg.sender]);

      uint256 gonValue = gonsForBalance(value);
      _gonBalances[from] = _gonBalances[from] - gonValue;
      _gonBalances[to] = _gonBalances[to] + gonValue;

      emit Transfer(from, to, value);
      return true;
  }

  function balanceOf(address who) public view override returns (uint256) {
      return _gonBalances[who] / _gonsPerFragment;
  }

  function gonsForBalance(uint256 amount) public view returns (uint256) {
      return amount * _gonsPerFragment;
  }

  function balanceForGons(uint256 gons) public view returns (uint256) {
      return gons / _gonsPerFragment;
  }

  function circulatingSupply() public view returns (uint256) {
      return _totalSupply - balanceOf(authority.get('staking'));
  }

  function index() public view returns (uint256) {
      return balanceForGons(INDEX);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import "../interfaces/IAuthority.sol";

abstract contract AccessControlled {
    event AuthorityUpdated(IAuthority indexed authority);
    string UNAUTHORIZED = "UNAUTHORIZED";
    IAuthority public authority;
    constructor(IAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    modifier onlyGovernor() {
        require(msg.sender == authority.get('governor'), UNAUTHORIZED);
        _;
    }
    modifier onlyTreasury() {
        require(msg.sender == authority.get('treasury'), UNAUTHORIZED);
        _;
    }
    modifier onlyStaking() {
        require(msg.sender == authority.get('staking'), UNAUTHORIZED);
        _;
    }
    function setAuthority(IAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
interface IAuthority {
    function get(string memory _role) external view returns (address);
}