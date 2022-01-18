/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract PeachStorage {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private locked;
    mapping(address => uint256) private claimed;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => mapping(uint256 => uint256)) expenditures;

    /**
      Liquidity pools go here
    */
    address manager = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address owner = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address rewardsPool = 0x197b53e2ea9500ecFC0D6E34F061174eB1D9a9bc;

    string _name = "DW Teach Storage";
    string _symbol = "TSTR";
    uint8 _decimals = 18;
    uint256 _totalSupply = 5000000 * 10**_decimals;
    uint256 TGE;

    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor() {
        balances[owner] = _totalSupply / 100;
        TGE = block.timestamp;
    }

    // Token information functions
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function upgradePeach(address _newPeach) external onlyOwner {
        manager = _newPeach;
    }

    function getPeach() external view returns (address) {
        return manager;
    }

    function balanceOf(address _wallet) external view returns (uint256) {
        return balances[_wallet];
    }

    // ERC20 proxied functions and events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address _owner, address _spender, uint256 _value);

    function transfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) external onlyManager {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        _transfer(_from, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount.sub(_comission));
        emit Transfer(_from, rewardsPool, _comission);
    }

    function transferFrom(
        address _from,
        address _spender,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) external onlyManager {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            allowances[_from][_spender] >= _amount,
            "Allowance is lower tan requested funds"
        );
        allowances[_from][_spender] = allowances[_from][_spender].sub(_amount);
        _transfer(_from, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount.sub(_comission));
        emit Transfer(_from, rewardsPool, _comission);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) internal {
        require(balances[_from] >= _amount, "Not enough funds");
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount.sub(_comission));
        balances[rewardsPool] = balances[rewardsPool].add(_comission);
        expenditures[_from][(block.timestamp - TGE) / (1 hours)] = expenditures[
            _from
        ][(block.timestamp - TGE) / (1 hours)].add(_amount);
    }

    function getExpenditure(address _target, uint256 _hours)
        external
        view
        returns (uint256)
    {
        uint256 result = 0;
        for (
            uint256 i = (block.timestamp - TGE) / (1 hours);
            i > TGE && _hours > 0;
            i--
        ) {
            result = result.add(expenditures[_target][i]);
            _hours--;
        }
        return result;
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    function approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) external onlyManager returns (bool) {
        _approve(_owner, _spender, _amount);
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[_owner][_spender] = _amount;
    }
}

contract PeachMathematician {
    using SafeMath for uint256;

    /**
    @dev
    - This contract holds the logic for mathematical calculations not built into Solidity
    - **Random number calculations shall not be done here**.
    */

    function getBigComission(uint256 x) internal pure returns (uint256) {
        // Returns a percentage * 10 ** 18
        return 60 * 10**18 - (550000 * 10**18) / (x + 10000 * 10**18);
    }
}

contract ProxiedStorage is PeachMathematician {
    // Token parameters
    string _name = "DW Teach";
    string _symbol = "TEACH";
    uint8 _decimals = 18;

    address internal owner = 0x2DEbCd8eCD0aecd3234c92eaA8B4Eb7421b7aBe6;
    address internal game = address(0);
    address internal peachStorageAddress =
        0x1Faf80b0812e01692308Fc416E408e2460ED9AdE;
    address internal rewardsPoolv2 = 0x197b53e2ea9500ecFC0D6E34F061174eB1D9a9bc;
    address internal proxy;
    address internal support;
    address internal oracle;
    uint256 internal currentPrice; // 3 decimals
    uint256 internal maxCashout = 100 * 10**_decimals;
    uint256 internal liquidityExtractionLimit; // 21 decimals
    uint256 internal fixedComission = 5;
    mapping(address => bool) internal authorizedTransactors;
    mapping(address => bool) internal swaps;
    mapping(address => bool) internal banList;
    PeachStorage peachStorage = PeachStorage(peachStorage);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    // Get the balance of any wallet
    function balanceOf(address _target) external view returns (uint256) {
        return peachStorage.balanceOf(_target);
    }

    function _balanceOf(address _target) internal view returns (uint256) {
        return peachStorage.balanceOf(_target);
    }

    // Get the allowance of a wallet
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return peachStorage.allowance(_owner, _spender);
    }

    // Approve the allowance for a wallet
    function approve(address _spender, uint256 _amount)
        external
        returns (bool)
    {
        return peachStorage.approve(msg.sender, _spender, _amount);
    }

    // Transfer from a wallet A to a wallet B
    function _safeTransferFrom(
        address _from,
        address _spender,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _comission = _getComission(_from, _to, _amount);
        peachStorage.transferFrom(_from, _spender, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount - _comission);
        if (_comission != 0) emit Transfer(_from, rewardsPoolv2, _comission);
    }

    function _getTransactionLimit(address _target)
        internal
        view
        returns (uint256)
    {
        uint256 _balance = _balanceOf(_target);
        // This is a percentage
        uint256 limit = (3000 * 10**_decimals) /
            (_balance * currentPrice + 120 * 10**_decimals);
        return (limit * _balance) / 100;
    }

    function getTransactionLimit() external view returns (uint256) {
        return _getTransactionLimit(msg.sender);
    }

    function _getComission(
        address _from,
        address _to,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _comission = fixedComission * 10**18;
        if (swaps[_from] || _from == game) {
            // User is purchasing tokens
            _comission = 0;
        } else if (swaps[_to]) {
            uint256 _expenditure = peachStorage.getExpenditure(_from, 24);
            uint256 _value = _expenditure + _amount * currentPrice;
            require(
                _value <= liquidityExtractionLimit,
                "24h window liquidity extraction limit reached."
            );
            // User is selling tokens
            if (_value > maxCashout) {
                _comission = getBigComission(_value);
            }
        }
        return ((_comission * _amount) / 100) * 10**_decimals;
    }
}

contract Decorated is ProxiedStorage {
    modifier validSender(address from) {
        require(from == msg.sender, "Not the right sender");
        _;
    }

    modifier isntBroken(uint256 quantity, uint256 balance) {
        require(quantity <= balance, "Not enough funds");
        _;
    }

    modifier onlyProxy() {
        require(msg.sender == proxy, "You are not the proxy");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlySupport() {
        require(msg.sender == support, "You are not the support");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "You are not the owner");
        _;
    }

    modifier isAllowedTransaction(uint256 amount, uint256 balance) {
        bool limitCondition = amount * currentPrice <=
            _getTransactionLimit(msg.sender);
        require(
            authorizedTransactors[msg.sender] ||
                swaps[msg.sender] ||
                limitCondition,
            "This transaction exceeds your limit. You need to authorize it first."
        );
        require(
            !banList[msg.sender],
            "You are banned. You may get in touch with the development team to address the issue."
        );
        _;
    }
}

contract Peach is PeachMathematician, Decorated {
    address liquidityPool;
    address bnbLiquidityPool;

    constructor() {}

    // Set the support address. Maintainance tasks only
    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    // Set the oracle address. Financial tasks only
    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    // Upgrade Peach balances. Try not to migrate balances, it could be expensive.
    function upgradeStorage(address _newStorage) external onlySupport {
        peachStorageAddress = _newStorage;
        peachStorage = PeachStorage(peachStorageAddress);
    }

    // Upgrade base comission
    function updateComission(uint256 _comission) external onlySupport {
        fixedComission = _comission;
    }

    // Ban a wallet
    function ban(address _target) external onlySupport {
        banList[_target] = true;
    }

    // Unban a wallet
    function unban(address _target) external onlySupport {
        banList[_target] = false;
    }

    // Token information functions for Metamask detection
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return peachStorage.totalSupply();
    }

    // Add a lp address to avoid comissions in outgoing transfers
    function addSwap(address _swap) external onlySupport {
        swaps[_swap] = true;
    }

    function setCurrentPrice(uint256 _newPrice) external onlyOracle {
        currentPrice = _newPrice;
    }

    function getCurrentPrice() external view returns (uint256) {
        return currentPrice;
    }

    function setLiquidityExtractionLimit(uint256 _newLimit)
        external
        onlyOracle
    {
        liquidityExtractionLimit = _newLimit;
    }

    //////////////////////////////////
    /////////// Actual ERC20 functions
    //////////////////////////////////
    // Custom transfer with liquidity protection
    function _safeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal validSender(_from) {
        uint256 _comission = _getComission(_from, _to, _amount);
        emit Transfer(_from, _to, _amount - _comission);
        if (_comission != 0) emit Transfer(_from, rewardsPoolv2, _comission);
    }

    // Transfer
    function transfer(address _to, uint256 _amount)
        public
        isAllowedTransaction(_amount, _balanceOf(msg.sender))
    {
        _safeTransfer(msg.sender, _to, _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public isAllowedTransaction(_amount, _balanceOf(_from)) {
        _safeTransferFrom(_from, msg.sender, _to, _amount);
    }

    // Approve big liquidity extraction
    function approveTransactor() public {
        authorizedTransactors[msg.sender] = true;
    }
}