pragma solidity ^0.4.23;

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/sale/Product.sol

/**
 * @title Product
 * @dev Simpler version of Product interface
 */
contract Product is ExtendsOwnable {
    using SafeMath for uint256;

    string public name;
    uint256 public maxcap;
    uint256 public weiRaised;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;
    uint256 public lockup;

    constructor (
        string _name,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        uint256 _lockup
    ) public {
        require(_maxcap > _minimum);

        name = _name;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;
        lockup = _lockup;
    }

    function addWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised <= _weiRaised);

        weiRaised = _weiRaised;
    }

    function subWeiRaised(uint256 _weiRaised) public onlyOwner {
        require(weiRaised >= _weiRaised);

        weiRaised = weiRaised.sub(_weiRaised);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts/sale/TokenDistributor.sol

contract TokenDistributor is ExtendsOwnable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        bytes32 id;
        address buyer;
        address product;
        uint256 amount;
        uint256 criterionTime;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] purchasedList;
    mapping (bytes32 => uint256) indexId;
    uint256 private nonce;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    event Receipt(
        bytes32 id,
        address buyer,
        address product,
        uint256 amount,
        uint256 criterionTime,
        bool release,
        bool refund
    );

    event BuyerAddressTransfer(bytes32 _id, address _from, address _to);

    event WithdrawToken(address to, uint256 amount);

    constructor(address _token) public {
        token = ERC20(_token);
        nonce = 0;

        //for error check
        purchasedList.push(Purchased(0, 0, 0, 0, 0, true, true));
    }

    function setPurchased(address _buyer, address _product, uint256 _amount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(bytes32)
    {
        nonce = nonce.add(1);
        bytes32 id = keccak256(_buyer, block.timestamp, nonce);
        purchasedList.push(Purchased(id, _buyer, _product, _amount, 0, false, false));
        indexId[id] = purchasedList.length;
        return id;

        emit Receipt(id, _buyer, _product, _amount, 0, false, false);
    }

    function addPurchased(bytes32 _id, uint256 _amount) external onlyOwner {
        require(_id != 0);

        uint index = indexId[_id];
        if (isLive(index)) {
            purchasedList[index].amount = purchasedList[index].amount.add(_amount);

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                _amount,
                0,
                false,
                false);
        }
    }

    function getAmount(bytes32 _id) external view returns(uint256) {
        if (_id == 0) {
            return 0;
        }

        uint index = indexId[_id];
        if (purchasedList[index].release || purchasedList[index].refund) {
            return 0;
        } else {
            return purchasedList[index].amount;
        }
    }

    function getAmountFromBuyer(address _buyer, address _product) external view returns (uint256) {
        for(uint index=1; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product
                && purchasedList[index].buyer == _buyer) {
                return purchasedList[index].amount;
            }
        }
        return 0;
    }

    function setCriterionTime(address _product, uint256 _criterionTime)
        external
        onlyOwner
        validAddress(_product)
    {
        for(uint index=1; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product) {
                purchasedList[index].criterionTime = _criterionTime;
            }
        }
    }

    function releaseProduct(address _product)
        external
        onlyOwner
        validAddress(_product)
    {
        for(uint index=1; index < purchasedList.length; index++) {
            if (purchasedList[index].product == _product
                && !purchasedList[index].release
                && !purchasedList[index].refund)
            {
                Product product = Product(purchasedList[index].product);
                require(purchasedList[index].criterionTime != 0);
                require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
                purchasedList[index].release = true;

                require(token.balanceOf(address(this)) >= purchasedList[index].amount);
                token.safeTransfer(purchasedList[index].buyer, purchasedList[index].amount);

                emit Receipt(
                    purchasedList[index].id,
                    purchasedList[index].buyer,
                    purchasedList[index].product,
                    purchasedList[index].amount,
                    purchasedList[index].criterionTime,
                    purchasedList[index].release,
                    purchasedList[index].refund);
            }
        }
    }

    function release(bytes32 _id) external onlyOwner {
        uint index = indexId[_id];

        if (isLive(index)) {
            Product product = Product(purchasedList[index].product);
            require(purchasedList[index].criterionTime != 0);
            require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
            purchasedList[index].release = true;

            require(token.balanceOf(address(this)) >= purchasedList[index].amount);
            token.safeTransfer(purchasedList[index].buyer, purchasedList[index].amount);

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);
        }
    }

    function refund(bytes32 _id) external onlyOwner returns (bool, uint256) {
        uint index = indexId[_id];

        if (isLive(index)) {
            Product product = Product(purchasedList[index].product);
            require(block.timestamp >= purchasedList[index].criterionTime.add(product.lockup()));
            purchasedList[index].refund = true;

            emit Receipt(
                purchasedList[index].id,
                purchasedList[index].buyer,
                purchasedList[index].product,
                purchasedList[index].amount,
                purchasedList[index].criterionTime,
                purchasedList[index].release,
                purchasedList[index].refund);

            return (true, purchasedList[index].amount);
        } else {
            return (false, 0);
        }
    }

    function buyerAddressTransfer(bytes32 _id, address _from, address _to)
        external
        onlyOwner
        returns (bool)
    {
        uint index = indexId[_id];
        if (purchasedList[index].buyer == _from) {
            purchasedList[index].buyer = _to;
            emit BuyerAddressTransfer(_id, _from, _to);
            return true;
        } else {
            return false;
        }
    }

    function withdrawToken(address _Owner) external onlyOwner {
        token.safeTransfer(_Owner, token.balanceOf(address(this)));
        emit WithdrawToken(_Owner, token.balanceOf(address(this)));
    }

    function isLive(uint256 _index) private view returns(bool){
        if (!purchasedList[_index].release && !purchasedList[_index].refund) {
            return true;
        } else {
            return false;
        }
    }
}