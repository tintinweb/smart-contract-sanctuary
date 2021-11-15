pragma solidity ^0.6.12;

import "./interface/IBettingFactory.sol";
import "./Owned.sol";
import "./interface/IPriceContract.sol";
import "./interface/IBettingContract.sol";
import "./interface/IERC20.sol";

contract BettingPool is Owned {
    IBettingFactory public factory;
    IPriceContract public priceContract;

    address[] public pool;
    mapping(address => address) public creater;
    uint256 public lastPoolIndex;
    mapping(address => bool) existed;

    event NewBetting(uint256 indexed _index, address indexed _address);

    constructor(address _bettingFactory, address _priceContract) public {
        factory = IBettingFactory(_bettingFactory);
        priceContract = IPriceContract(_priceContract);
    }

    modifier onlyExistedPool(address _pool) {
        require(existed[_pool], "BETTING_POOL: Pool not found");
        _;
    }

    modifier onlyBettingOwner(address _pool) {
        require(creater[_pool] == msg.sender, "BETTING_POOL: Only Creater");
        _;
    }

    function setPriceContract(address _priceContract) public onlyOwner {
        priceContract = IPriceContract(_priceContract);
    }

    function setFactoryContract(address _bettingFactory) public onlyOwner {
        factory = IBettingFactory(_bettingFactory);
    }

    function createNewBetting(
        string memory _name,
        string memory _description,
        address _tokenBet,
        uint256 _rewardAmount,
        uint256 _tickerPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _expiration
    ) public payable returns (address) {
        uint256 fee = priceContract.gasPrice() * priceContract.gasLimit();
        require(msg.value >= fee, "BETTING: Please send fee");
        address betting = factory.createNewPool(
            address(uint160(address(this))),
            msg.sender
        );
        pool.push(betting);
        existed[betting] = true;
        creater[betting] = msg.sender;
        lastPoolIndex = pool.length - 1;
        emit NewBetting(lastPoolIndex, betting);
        setupBettingContract(
            betting,
            _name,
            _description,
            _tokenBet,
            _tickerPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _expiration
        );
        IERC20(_tokenBet).transferFrom(msg.sender, betting, _rewardAmount);
        _start(betting);
        return betting;
    }

    function setupBettingContract(
        address _pool,
        string memory _name,
        string memory _description,
        address _token_address,
        uint256 _tickerPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _expiration
    ) public onlyBettingOwner(_pool) onlyExistedPool(_pool) returns (bool) {
        IBettingContract(_pool).setName(_name);
        IBettingContract(_pool).setDescription(_description);
        IBettingContract(_pool).setPool(_token_address);
        IBettingContract(_pool).setTicketPrice(_tickerPrice);
        IBettingContract(_pool).setBracketsPriceDecimals(_bracketsDecimals);
        IBettingContract(_pool).setBracketsPrice(_bracketsPrice);
        IBettingContract(_pool).setExpirationContract(_expiration);
        return true;
    }

    function _start(address _pool) internal {
        IBettingContract(_pool).start{value: msg.value}(address(priceContract));
    }

    function close(address _pool)
        public
        onlyBettingOwner(_pool)
        onlyExistedPool(_pool)
    {
        IBettingContract(_pool).close();
    }

    function withdrawETH(address payable _receiver, uint256 _value)
        public
        onlyOwner
    {
        _receiver.transfer(_value);
    }

    function withdrawAllETH(address payable _receiver) public onlyOwner {
        _receiver.transfer(address(this).balance);
    }

    function withdrawToken(
        address _token_address,
        address _receiver,
        uint256 _value
    ) public onlyOwner {
        IERC20(_token_address).transfer(_receiver, _value);
    }

    function withdrawAllToken(address _token_address, address _receiver)
        public
        onlyOwner
    {
        uint256 total = IERC20(_token_address).balanceOf(address(this));
        IERC20(_token_address).transfer(_receiver, total);
    }
}

pragma solidity ^0.6.12;

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only available for owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

pragma solidity ^0.6.12;

interface IBettingContract {
  function setName(string calldata _name) external;
  function setDescription(string calldata _description) external;
  function setPool(address _tokenAddress) external;
  function setTicketPrice(uint256 price) external;
  function setBracketsPriceDecimals(uint256 decimals) external;
  function setBracketsPrice(uint256[] calldata _bracketsPrice) external;
  function setExpirationContract(uint256 unixtime) external;
  function start(address _priceContract) payable external;
  function close() external;
  function buyTicket(uint256 guess_value) external payable;
  function getTicket() external view returns(uint256[] memory);
  function getToltalToken() external view returns(uint256);
  
}

pragma solidity ^0.6.12;

interface IBettingFactory {
  function createNewPool(address payable _owner, address payable _creater) external returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    
    
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.12;

interface IPriceContract {
  function updatePrice(uint256 _time, address _tokens) payable external returns(bytes32);
  function getPrice(bytes32 _id) external view returns(string memory);
  function gasPrice() external view returns(uint256);
  function gasLimit() external view returns(uint256);
}

