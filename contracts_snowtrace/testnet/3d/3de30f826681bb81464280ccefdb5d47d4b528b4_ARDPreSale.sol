// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";

contract ARDPreSale is Ownable, ReentrancyGuard {

    struct RoundSale {  
        uint256 price;
        uint256 minSpend;
        uint256 maxSpend;
        uint256 startingTimeStamp;
    }
    // ARD token
    IERC20 public ARD;
    // BuyingToken token
    IERC20 public BuyingToken;

    uint256 public constant ARD_ALLOCATION = 50000000000000000000000;       // hardcap 50k ARD
    // Set round active 1 pre, 2 public
    uint256 public roundActive = 1;
    // Store detail earch round
    mapping(uint256 => RoundSale) public rounds;
    // Whitelisting list
    mapping(address => bool) public whiteListed;
    // Total ARD user buy
    mapping(address => uint256) public tokenBoughtTotal;
    // Total BuyingToken spend for limits earch user
    mapping(uint256 => mapping(address => uint256)) public totalBuyingTokenSpend;
    // Total ARD sold
    uint256 public totalTokenSold = 0;
    // Claim token
    uint256[] public claimableTimestamp;
    mapping(uint256 => uint256) public claimablePercents;
    mapping(address => uint256) public claimCounts;

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(
        address _ARD,
        address _BuyingToken
    ) {
        ARD = IERC20(_ARD);
        BuyingToken = IERC20(_BuyingToken);
    }

    /* User methods */
    function buy(uint256 _amount) public nonReentrant {
        require(roundActive == 1 || roundActive == 2, "No open sale rounds found");
        RoundSale storage roundCurrent = rounds[roundActive];
        require(
            block.timestamp >= roundCurrent.startingTimeStamp,
            "Presale has not started"
        );
        require(
            roundActive != 1 || whiteListed[_msgSender()] == true,
            'Not whitelisted'
        );
        require(
            totalBuyingTokenSpend[roundActive][_msgSender()] + _amount >= roundCurrent.minSpend,
            "Below minimum amount"
        );
        require(
            totalBuyingTokenSpend[roundActive][_msgSender()] + _amount <= roundCurrent.maxSpend,
            "You have reached maximum spend amount per user"
        );

        uint256 tokens = _amount / roundCurrent.price * 1000;

        require(
            totalTokenSold + tokens <= ARD_ALLOCATION,
            "Token presale hardcap reached"
        );

        BuyingToken.transferFrom(_msgSender(), address(this), _amount);

 		tokenBoughtTotal[_msgSender()] += tokens;
        totalBuyingTokenSpend[roundActive][_msgSender()] += _amount;

        totalTokenSold += tokens;
        emit TokenBuy(_msgSender(), tokens);
    }

    
    function claim() external nonReentrant {
        uint256 userBought = tokenBoughtTotal[_msgSender()];
        require(userBought > 0, "Nothing to claim");
        require(claimableTimestamp.length > 0, "Can not claim at this time");
        require(_now() >= claimableTimestamp[0], "Can not claim at this time");

        uint256 startIndex = claimCounts[_msgSender()];
        require(startIndex < claimableTimestamp.length, "You have claimed all token");

        uint256 tokenQuantity = 0;
        for(uint256 index = startIndex; index < claimableTimestamp.length; index++){
            uint256 timestamp = claimableTimestamp[index];
            if(_now() >= timestamp){
                tokenQuantity += userBought * claimablePercents[timestamp] / 100;
                claimCounts[_msgSender()]++;
            }else{
                break;
            }
        }

        require(tokenQuantity > 0, "Token quantity is not enough to claim");
        require(ARD.transfer(_msgSender(), tokenQuantity), "Can not transfer ARD");

        emit TokenClaim(_msgSender(), tokenQuantity);
    }

    function getTokenBought(address _buyer) public view returns(uint256){
        require(_buyer != address(0), "Zero address");
        return tokenBoughtTotal[_buyer];
    }

    function getRoundActive() public view returns(uint256){
        return roundActive;
    }

    /* Admin methods */

    function setActiveRound(uint256 _roundId) external onlyOwner{
        require(_roundId == 1 || _roundId == 2, "Round ID invalid");
        roundActive = _roundId;
    }

    function setRoundSale(
        uint256 _roundId,
        uint256 _price,
        uint256 _minSpend,
        uint256 _maxSpend,
        uint256 _startingTimeStamp) external onlyOwner{
        require(_roundId == 1 || _roundId == 2, "Round ID invalid");
        require(_minSpend < _maxSpend, "Spend invalid");

        rounds[_roundId] = RoundSale({
            price: _price,
            minSpend: _minSpend,
            maxSpend: _maxSpend,
            startingTimeStamp: _startingTimeStamp
        });
    }

    function setClaimableBlocks(uint256[] memory _timestamp) external onlyOwner{
        require(_timestamp.length > 0, "Empty input");
        claimableTimestamp = _timestamp;
    }

    function setClaimablePercents(uint256[] memory _timestamps, uint256[] memory _percents) external onlyOwner{
        require(_timestamps.length > 0, "Empty input");
        require(_timestamps.length == _percents.length, "Empty input");
        for(uint256 index = 0; index < _timestamps.length; index++){
            claimablePercents[_timestamps[index]] = _percents[index];
        }
    }

    function setUsdcToken(address _newAddress) external onlyOwner{
        require(_newAddress != address(0), "Zero address");
        BuyingToken = IERC20(_newAddress);
    }

    function setArdToken(address _newAddress) external onlyOwner{
        require(_newAddress != address(0), "Zero address");
        ARD = IERC20(_newAddress);
    }

    function addToWhiteList(address[] memory _accounts) external onlyOwner {
        require(_accounts.length > 0, "Invalid input");
        for (uint256 i; i < _accounts.length; i++) {
            whiteListed[_accounts[i]] = true;
        }
    }

    function removeFromWhiteList(address[] memory _accounts) external onlyOwner{
        require(_accounts.length > 0, "Invalid input");
        for(uint256 index = 0; index < _accounts.length; index++){
            whiteListed[_accounts[index]] = false;
        }
    }

    function withdrawFunds() external onlyOwner {
        BuyingToken.transfer(_msgSender(), BuyingToken.balanceOf(address(this)));
    }

    function withdrawUnsold() external onlyOwner {
        uint256 amount = ARD.balanceOf(address(this)) - totalTokenSold;
        ARD.transfer(_msgSender(), amount);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Context.sol';

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    _owner = _msgSender();
    emit OwnershipTransferred(address(0), _msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
  
  function _now() internal view returns (uint256) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return block.timestamp;
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}