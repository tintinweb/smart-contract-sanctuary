pragma solidity ^0.6.12;

import './libraries/SafeMath.sol';
import './interface/IBettingContract.sol';
import './interface/IERC20.sol';

contract BettingContract is IBettingContract {
    
    uint256 private TIME_PRICE_CLOSE = 1 minutes;
    
    address payable public owner;
    address payable public creator;
    
    address public tokenAddress;
    
    string public name;
    string public description;
    uint256 public expiration;
    
    uint256 public ticketPrice;
    
    uint256 public bracketsPriceDecimals;
    uint256[] public bracketsPrice;
    
    bool public isOpen = false;
    
    address[] private listBuyer;
    mapping(address => uint256[]) private buyers;
    mapping(uint256 => address[]) private ticketSell;
    
    IPriceContract private priceContract;
    bytes32 public resultId;
    
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp, bytes32 _resultId);
    event Close(uint256 _timestamp, uint256 _price , address[] _winers, uint256 _reward);
    
    constructor(address payable _owner, address payable _creator) public {
        owner = _owner;
        creator = _creator;
    }
    
    using SafeMath for uint256;
    
    modifier onlyOwner() {
        require(owner == msg.sender, "BETTING: Only owner");
        _;
    }
    
    modifier decimalsLength(uint256 decimals) {
        require(decimals <= 18, "BETTING: Required decimals <= 18");
        _;
    }
    
    modifier onlyOpen() {
        require(isOpen, "BETTING: Required Open");
        _;
    }
    
    modifier onlyClose() {
        require(isOpen == false, "BETTING: Required NOT start");
        _;
    }
    
    modifier onlyNotExpired() {
        require(block.timestamp <= expiration, "BETTING: EXPRIED");
        _;
    }
    
    modifier onlyExpired() {
        require(block.timestamp > expiration, "BETTING: NOT EXPRIED");
        _;
    }
    
    modifier onlyPriceClose() {
        require(block.timestamp > expiration + TIME_PRICE_CLOSE, "BETTING: Please waiting for price close");
        _;
    }
    
    
    function setName(string calldata _name) external override onlyOwner {
        name = _name;
    }
    
    function setDescription(string calldata _description) external override onlyOwner {
        description = _description;
    }
    
    // Setup asset
    function setPool(address _tokenAddress) external override onlyOwner onlyClose {
        tokenAddress = _tokenAddress;
    }
    
    //Unit: wei
    function setTicketPrice(uint256 price) external onlyOwner override onlyClose {
        ticketPrice = price;
    }
    
    function setBracketsPriceDecimals(uint256 decimals) external override onlyOwner decimalsLength(decimals) onlyClose {
        bracketsPriceDecimals = decimals;
    }
    
    //Example: [1, 2, 3, 4] ==>  1 <= bracket1 < 2, 2 <= bracket2 < 3, 3 <= bracket3 < 4
    function setBracketsPrice(uint256[] calldata _bracketsPrice) external override onlyOwner onlyClose {
        for (uint256 i = 1; i < _bracketsPrice.length; i++) {
            require(_bracketsPrice[i] >= _bracketsPrice[i - 1], "BETTING: bracketsPrice is wrong");
        }
        bracketsPrice = _bracketsPrice;
    }
    
    //Setup expiration
    function setExpirationContract(uint256 unixtime) public override onlyOwner onlyClose {
        require(block.timestamp < unixtime, "BETTING: Required expiration > now");
        expiration = unixtime;
    }
    
    function start(IPriceContract _priceContract) external payable override onlyOwner onlyClose {
        uint256 fee = priceContract.gasPrice() * priceContract.gasLimit();
        require(msg.value >= fee, "BETTING: Please send fee");
        require(expiration > block.timestamp, "BETTING: Required expiration > now");
        require(bracketsPrice.length > 0, "BETTING: Required set brackets price");
        require(tokenAddress != address(0x0), "BETTING: Required set token address");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "BETTING: Required deposit token");
        priceContract = _priceContract;
        resultId =  IPriceContract(_priceContract).updatePrice{value: msg.value}(expiration - block.timestamp + TIME_PRICE_CLOSE, tokenAddress, msg.sender);
        isOpen = true;
        emit Ready(block.timestamp, resultId);
    }
    
    function close() external override onlyExpired onlyPriceClose onlyOpen {
        (uint256 price, uint256 result, bool success ) = getResult();
        if (!success) {
            _closeForce();
            return;
        }
        address[] memory winers = ticketSell[result];
        uint256 reward = 0;
        if (winers.length > 0) {
            reward = getToltalToken().div(winers.length);
            for (uint256 i = winers.length - 1; i > 0; i--) {
                if (winers[i] != address(0x0)) {
                    IERC20(tokenAddress).transfer(winers[i], reward);
                    delete winers[i];   
                }
            }
            if (winers[0] != address(0x0)) {
                IERC20(tokenAddress).transfer(winers[0], getToltalToken() );   
                delete winers[0];
            }
        } else {
            IERC20(tokenAddress).transfer(creator, getToltalToken());
        }
        creator.transfer(address(this).balance.div(100).mul(95));
        emit Close(block.timestamp, price, ticketSell[result], reward);
        selfdestruct(owner);
    }
    
    function _closeForce() private {
        if (listBuyer.length > 0) {
            uint256 reward = getToltalToken().div(listBuyer.length);
            for (uint256 i = listBuyer.length - 1; i > 0; i--) {
                if (listBuyer[i] != address(0x0)) {
                    IERC20(tokenAddress).transfer(listBuyer[i], reward);
                    address(uint160(listBuyer[i])).transfer(ticketPrice);
                    delete listBuyer[i];
                }
            }
            if (listBuyer[0] != address(0x0)) {
                IERC20(tokenAddress).transfer(listBuyer[0], getToltalToken() );
                address(uint160(listBuyer[0])).transfer(ticketPrice);
                delete listBuyer[0];
            }
        } else {
            IERC20(tokenAddress).transfer(owner, getToltalToken());
        }
        
        selfdestruct(owner);
    }
    
    // guess_value = real_value * 10**bracketsPriceDecimals
    function buyTicket(uint256 _bracketIndex) public override payable onlyOpen onlyNotExpired {
        require(msg.value >= ticketPrice, "BETTING: Required ETH >= ticketPrice");
        if (_bracketIndex > bracketsPrice.length - 1) {
            _bracketIndex = bracketsPrice.length;
        }
        buyers[msg.sender].push(_bracketIndex);
        ticketSell[_bracketIndex].push(msg.sender);
        listBuyer.push(msg.sender);
        emit Ticket(msg.sender, _bracketIndex);
    }
    
    function getTicket() public override view returns(uint256[] memory) {
        return buyers[msg.sender];
    }
    
    function getToltalToken() public override view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function getResult() private view returns(uint256 price, uint256 index, bool success) {
        price = getTokenPrice();
        if (price == 0) {
            return (price, 0, false);
        }
        
        if (price < bracketsPrice[0]) {
            return (price, 0, true);
        }
        if (price >= bracketsPrice[bracketsPrice.length - 1]) {
            return (price, bracketsPrice.length, true);
        }
        for (uint256 i = 0; i < bracketsPrice.length - 1; i++) {
            if (bracketsPrice[i] <= price && price < bracketsPrice[i + 1]) {
                return (price, i + 1, true);
            }
        }
        
        return (price, 0, false);
    }
    
    // calculate price based on pair reserves
    function getTokenPrice() private view returns(uint) {
        string memory price = IPriceContract(priceContract).getPrice(resultId);
        return stringToUint(price, bracketsPriceDecimals);
    }
    
    function stringToUint(string memory s, uint _decimals) private pure returns (uint) {
        bytes memory b = bytes(s);
        uint i;
        uint result = 0;
        uint dec = 0;
        bool startDot = false;
        for (i = 0; i < b.length && dec < _decimals; i++) {
            if (startDot) {
                dec++;
            }
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            } else {
               startDot = true;
            }
        }
        result = result * 10 ** (_decimals - dec);
        return result;
    }
}

pragma solidity ^0.6.12;

import './BettingContract.sol';
import './interface/IBettingFactory.sol';

contract BettingFactory is IBettingFactory {
    function createNewPool(address payable _owner, address payable _creater) public override returns(address) {
        BettingContract betting = new BettingContract(_owner, _creater);
        return address(betting);
    }
}

pragma solidity ^0.6.12;
import './IPriceContract.sol';

interface IBettingContract {
  function setName(string calldata _name) external;
  function setDescription(string calldata _description) external;
  function setPool(address _tokenAddress) external;
  function setTicketPrice(uint256 price) external;
  function setBracketsPriceDecimals(uint256 decimals) external;
  function setBracketsPrice(uint256[] calldata _bracketsPrice) external;
  function setExpirationContract(uint256 unixtime) external;
  function start(IPriceContract _priceContract) payable external;
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
  function updatePrice(uint256 _time, address _tokens, address payable _refund) payable external returns(bytes32);
  function getPrice(bytes32 _id) external view returns(string memory);

  function gasPrice() external view returns(uint256);
  function gasLimit() external view returns(uint256);
}

pragma solidity ^0.6.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
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

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}