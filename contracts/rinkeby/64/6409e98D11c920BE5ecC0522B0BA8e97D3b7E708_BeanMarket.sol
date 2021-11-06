pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../../Common/Upgradable.sol";
import "../../Common/SafeMath256.sol";
import "./BeanMarketSilo.sol";
import "../../Bean/Bean.sol";

// ----------------------------------------------------------------------------
// --- Contract BeanMarket 
// ----------------------------------------------------------------------------

contract BeanMarket is Upgradable {
    using SafeMath256 for uint256;

    BeanMarketSilo _silo_;
    Bean beanStalks;

    uint256 constant BEAN_DECIMALS = uint256(10) ** 18;


    function _calculateFullPrice(
        uint256 _price,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _price.mul(_amount).div(BEAN_DECIMALS);
    }

    function _transferBean(address _to, uint256 _value) internal {
        beanStalks.remoteTransfer(_to, _value);
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a <= _b ? _a : _b;
    }

    function _safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b > a ? 0 : a.sub(b);
    }

    function _checkPrice(uint256 _value) internal pure {
        require(_value > 0, "price must be greater than 0");
    }

    function _checkAmount(uint256 _value) internal pure {
        require(_value > 0, "amount must be greater than 0");
    }

    function _checkActualPrice(uint256 _expected, uint256 _actual) internal pure {
        require(_expected == _actual, "wrong actual price");
    }

    function createSellOrder(
        address _user,
        uint256 _price,
        uint256 _amount
    ) external onlyFarmer {
        _checkPrice(_price);
        _checkAmount(_amount);
        _transferBean(address(_silo_), _amount);
        _silo_.createSellOrder(_user, _price, _amount);
    }

    function cancelSellOrder(address _user) external onlyFarmer {
        ( , , , uint256 _amount) = _silo_.orderOfSeller(_user);
        _silo_.transferBean(_user, _amount);
        _silo_.cancelSellOrder(_user);
    }

    function fillSellOrder(
        address _buyer,
        uint256 _value,
        address _seller,
        uint256 _expectedPrice,
        uint256 _amount
    ) external onlyFarmer returns (uint256 price) {
        uint256 _available;
        ( , , price, _available) = _silo_.orderOfSeller(_seller);
        _checkAmount(_amount);
        require(_amount <= _available, "seller has no enough bean");
        _checkActualPrice(_expectedPrice, price);
        uint256 _fullPrice = _calculateFullPrice(price, _amount);
        require(_fullPrice > 0, "no free bean, sorry");
        require(_fullPrice <= _value, "not enough ether");

        _seller.transfer(_fullPrice);
        if (_value > _fullPrice) {
            _buyer.transfer(_value.sub(_fullPrice));
        }
        _silo_.transferBean(_buyer, _amount);

        _available = _available.sub(_amount);

        if (_available == 0) {
            _silo_.cancelSellOrder(_seller);
        } else {
            _silo_.updateSellOrder(_seller, price, _available);
        }
    }

    function () external payable onlyFarmer {}

    function createBuyOrder(
        address _user,
        uint256 _value,
        uint256 _price,
        uint256 _amount
    ) external onlyFarmer {
        _checkPrice(_price);
        _checkAmount(_amount);
        uint256 _fullPrice = _calculateFullPrice(_price, _amount);
        require(_fullPrice == _value, "wrong eth value");

        address(_silo_).transfer(_value);

        _silo_.createBuyOrder(_user, _price, _amount);
    }

    function cancelBuyOrder(address _user) external onlyFarmer {
        ( , address _buyer, uint256 _price, uint256 _amount) = _silo_.orderOfBuyer(_user);
        require(_buyer == _user, "user addresses are not equal");
        uint256 _fullPrice = _calculateFullPrice(_price, _amount);
        _silo_.transferEth(_user, _fullPrice);
        _silo_.cancelBuyOrder(_user);
    }

    function fillBuyOrder(
        address _seller,
        address _buyer,
        uint256 _expectedPrice,
        uint256 _amount
    ) external onlyFarmer returns (uint256 price) {
        uint256 _needed;
        ( , , price, _needed) = _silo_.orderOfBuyer(_buyer);

        _checkAmount(_amount);
        require(_amount <= _needed, "buyer do not need so much");
        _checkActualPrice(_expectedPrice, price);

        uint256 _fullPrice = _calculateFullPrice(price, _amount);

        _transferBean(_buyer, _amount);
        _silo_.transferEth(_seller, _fullPrice);

        _needed = _needed.sub(_amount);

        if (_needed == 0) {
            _silo_.cancelBuyOrder(_buyer);
        } else {
            _silo_.updateBuyOrder(_buyer, price, _needed);
        }
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        _silo_ = BeanMarketSilo(_newDependencies[0]);
        beanStalks = Bean(_newDependencies[1]);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Controllable.sol";

// ----------------------------------------------------------------------------
// --- Contract Upgradable 
// ----------------------------------------------------------------------------

contract Upgradable is Controllable {
    address[] internalDependencies;
    address[] externalDependencies;

    function getInternalDependencies() public view returns(address[]) {
        return internalDependencies;
    }

    function getExternalDependencies() public view returns(address[]) {
        return externalDependencies;
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        for (uint256 i = 0; i < _newDependencies.length; i++) {
            _validateAddress(_newDependencies[i]);
        }
        internalDependencies = _newDependencies;
    }

    function setExternalDependencies(address[] _newDependencies) public onlyOwner {
        _setFarmers(externalDependencies, false); 
        externalDependencies = _newDependencies;
        _setFarmers(_newDependencies, true);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath256 {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        if (b == 0) return 1;

        uint256 c = a ** b;
        assert(c / (a ** (b - 1)) == a);
        return c;
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "../../Common/Upgradable.sol";
import "../../Bean/Bean.sol";
import "../../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract BeanMarketSilo 
// ----------------------------------------------------------------------------

contract BeanMarketSilo is Upgradable {
    using SafeMath256 for uint256;

    Bean beanStalks;

    struct Order {
        address user;
        uint256 price;
        uint256 amount;
    }

    mapping (address => uint256) public userToSellOrderIndex;
    mapping (address => uint256) public userToBuyOrderIndex;

    Order[] public sellOrders;
    Order[] public buyOrders;

    constructor() public {
        sellOrders.length = 1;
        buyOrders.length = 1;
    }

    function _ordersShouldExist(uint256 _amount) internal pure {
        require(_amount > 1, "no orders"); 
    }

    function _orderShouldNotExist(uint256 _index) internal pure {
        require(_index == 0, "order already exists");
    }

    function _orderShouldExist(uint256 _index) internal pure {
        require(_index != 0, "order does not exist");
    }

    function _sellOrderShouldExist(address _user) internal view {
        _orderShouldExist(userToSellOrderIndex[_user]);
    }

    function _buyOrderShouldExist(address _user) internal view {
        _orderShouldExist(userToBuyOrderIndex[_user]);
    }

    function transferBean(address _to, uint256 _value) external onlyFarmer {
        beanStalks.transfer(_to, _value);
    }

    function transferEth(address _to, uint256 _value) external onlyFarmer {
        _to.transfer(_value);
    }

    function createSellOrder(
        address _user,
        uint256 _price,
        uint256 _amount
    ) external onlyFarmer {
        _orderShouldNotExist(userToSellOrderIndex[_user]);

        Order memory _order = Order(_user, _price, _amount);
        userToSellOrderIndex[_user] = sellOrders.length;
        sellOrders.push(_order);
    }

    function cancelSellOrder(
        address _user
    ) external onlyFarmer {
        _sellOrderShouldExist(_user);
        _ordersShouldExist(sellOrders.length);

        uint256 _orderIndex = userToSellOrderIndex[_user];

        uint256 _lastOrderIndex = sellOrders.length.sub(1);
        Order memory _lastOrder = sellOrders[_lastOrderIndex];

        userToSellOrderIndex[_lastOrder.user] = _orderIndex;
        sellOrders[_orderIndex] = _lastOrder;

        sellOrders.length--;
        delete userToSellOrderIndex[_user];
    }

    function updateSellOrder(
        address _user,
        uint256 _price,
        uint256 _amount
    ) external onlyFarmer {
        _sellOrderShouldExist(_user);
        uint256 _index = userToSellOrderIndex[_user];
        sellOrders[_index].price = _price;
        sellOrders[_index].amount = _amount;
    }

    function () external payable onlyFarmer {}

    function createBuyOrder(
        address _user,
        uint256 _price,
        uint256 _amount
    ) external onlyFarmer {
        _orderShouldNotExist(userToBuyOrderIndex[_user]);

        Order memory _order = Order(_user, _price, _amount);
        userToBuyOrderIndex[_user] = buyOrders.length;
        buyOrders.push(_order);
    }

    function cancelBuyOrder(address _user) external onlyFarmer {
        _buyOrderShouldExist(_user);
        _ordersShouldExist(buyOrders.length);

        uint256 _orderIndex = userToBuyOrderIndex[_user];

        uint256 _lastOrderIndex = buyOrders.length.sub(1);
        Order memory _lastOrder = buyOrders[_lastOrderIndex];

        userToBuyOrderIndex[_lastOrder.user] = _orderIndex;
        buyOrders[_orderIndex] = _lastOrder;

        buyOrders.length--;
        delete userToBuyOrderIndex[_user];
    }

    function updateBuyOrder(
        address _user,
        uint256 _price,
        uint256 _amount
    ) external onlyFarmer {
        _buyOrderShouldExist(_user);
        uint256 _index = userToBuyOrderIndex[_user];
        buyOrders[_index].price = _price;
        buyOrders[_index].amount = _amount;
    }

    function orderOfSeller(
        address _user
    ) external view returns (
        uint256 index,
        address user,
        uint256 price,
        uint256 amount
    ) {
        _sellOrderShouldExist(_user);
        index = userToSellOrderIndex[_user];
        Order memory order = sellOrders[index];
        return (
            index,
            order.user,
            order.price,
            order.amount
        );
    }

    function orderOfBuyer(
        address _user
    ) external view returns (
        uint256 index,
        address user,
        uint256 price,
        uint256 amount
    ) {
        _buyOrderShouldExist(_user);
        index = userToBuyOrderIndex[_user];
        Order memory order = buyOrders[index];
        return (
            index,
            order.user,
            order.price,
            order.amount
        );
    }

    function sellOrdersAmount() external view returns (uint256) {
        return sellOrders.length;
    }

    function buyOrdersAmount() external view returns (uint256) {
        return buyOrders.length;
    }

    function setInternalDependencies(address[] _newDependencies) public onlyOwner {
        super.setInternalDependencies(_newDependencies);

        beanStalks = Bean(_newDependencies[0]);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      :
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./ERC20.sol";
import "../Common/Upgradable.sol";

// ----------------------------------------------------------------------------
// --- Contract Bean
// ----------------------------------------------------------------------------

contract Bean is ERC20, Upgradable {
    uint256 constant DEVS_STAKE = 6;

    address[3] founders = [
        0xc14E8600Fa952A856035fA58090C410604b9Ff7C,
        0xc14E8600Fa952A856035fA58090C410604b9Ff7C,
        0xc14E8600Fa952A856035fA58090C410604b9Ff7C
    ];

    address foundation = 0xc14E8600Fa952A856035fA58090C410604b9Ff7C;
    address Blockhaus = 0xc14E8600Fa952A856035fA58090C410604b9Ff7C;

    string constant WP_IPFS_HASH = "QmfR75tK12q2LpkU5dzYqykUUpYswSiewpCbDuwYhRb6M5";


    constructor(address field) public {
        name = "Tomatoereum Bean";
        symbol = "BEAN";
        decimals = 18;

        uint256 _foundersBean = 6000000 * 10**18;
        uint256 _foundationBean = 6000000 * 10**18;
        uint256 _BlockhausBean = 3000000 * 10**18;
        uint256 _gameAccountBean = 45000000 * 10**18;

        uint256 _founderStake = _foundersBean.div(founders.length);
        for (uint256 i = 0; i < founders.length; i++) {
            _mint(founders[i], _founderStake);
        }

        _mint(foundation, _foundationBean);
        _mint(Blockhaus, _BlockhausBean);
        _mint(field, _gameAccountBean);

        require(_totalSupply == 60000000 * 10**18, "wrong total supply");
    }

    function remoteTransfer(address _to, uint256 _value) external onlyFarmer {
        _transfer(tx.origin, _to, _value);
    }

    function burn(uint256 _value) external onlyFarmer {
        _burn(msg.sender, _value);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./Ownable.sol";

// ----------------------------------------------------------------------------
// --- Contract Controllable 
// ----------------------------------------------------------------------------

contract Controllable is Ownable {
    mapping(address => bool) farmers;

    modifier onlyFarmer {
        require(_isFarmer(msg.sender), "no farmer rights");
        _;
    }

    function _isFarmer(address _farmer) internal view returns (bool) {
        return farmers[_farmer];
    }

    function _setFarmers(address[] _farmers, bool _active) internal {
        for (uint256 i = 0; i < _farmers.length; i++) {
            _validateAddress(_farmers[i]);
            farmers[_farmers[i]] = _active;
        }
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract Ownable 
// ----------------------------------------------------------------------------

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not a contract owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _validateAddress(newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

import "./IERC20.sol";
import "../Common/SafeMath256.sol";

// ----------------------------------------------------------------------------
// --- Contract ERC20 
// ----------------------------------------------------------------------------

contract ERC20 is IERC20 {
    using SafeMath256 for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(
        address owner,
        address spender
    )
      public
      view
      returns (uint256)
    {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "invalid address");
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _validateAddress(spender);

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
      public
      returns (bool)
    {
        require(value <= _allowed[from][msg.sender], "not enough allowed tokens");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
      public
      returns (bool)
    {
        _validateAddress(spender);

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
      public
      returns (bool)
    {
        _validateAddress(spender);

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from], "not enough tokens");
        _validateAddress(to);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        _validateAddress(account);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        _validateAddress(account);
        require(value <= _balances[account], "not enough tokens to burn");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender], "not enough allowed tokens to burn");

        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
}

pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// --- Name        : CropClash - [Crop SHARE]
// --- Symbol      : Format - {CRP}
// --- Total supply: Generated from minter accounts
// --- @Legal      : 
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- BlockHaus.Company - EJS32 - 2018-2021
// --- @dev pragma solidity version:0.8.0+commit.661d1103
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Contract IERC20 
// ----------------------------------------------------------------------------

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}