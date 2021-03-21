/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// Developed by [email protected]
// +923207417544

pragma solidity ^0.5.0;


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


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}

contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
        // Solidity only automatically asserts when dividing by 0
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
contract ICO is Pausable{
    using SafeMath for uint;
    IERC20 erctoken;
    
    address payable public admin;
    uint public privateSaleDuration;
    uint public preSaleDuration = 30 days; // 15 days will be skip for private sale
    uint public crowdSaleDuration = 60 days; // 15 + 15 = 30 days will be skip for private and pre sale
    uint public crowdSalePhasesTime;
    uint public tokenPrice; // 1000000000000000 // 0.001
    uint public ethPrice;
    uint256 tokenSaleAmount = 10000000000; // 10 billion token for private sale, pre sale and crowd sale
    
    uint public availableTokensForPrivateSale;
    uint public availableTokensForPreSale;
    uint public availableTokensForCrowdSale;
    uint public availableTokensForCrowdSaleFirstYear;
    uint public availableTokensForCrowdSaleSecondYear;
    uint public availableTokensForCrowdSaleThreeYear;
    uint public availableTokensForCrowdSaleFourYear;
    
    uint public minPurchase;

    constructor(
        uint _tokenPrice
    ) 
    public {
        admin = msg.sender;
        tokenPrice = _tokenPrice;
        minPurchase = 1; // 1 $
        crowdSalePhasesTime = block.timestamp + 1825 days;
        
        // Total available token for ico is 10 billion
        availableTokensForPrivateSale = tokenSaleAmount.mul(20).div(100);
        availableTokensForPreSale = tokenSaleAmount.mul(10).div(100);
        
        availableTokensForCrowdSale = tokenSaleAmount.mul(70).div(100); // for 4 Years of crowdsale
        availableTokensForCrowdSaleFirstYear = tokenSaleAmount.mul(25).div(100); // for 1st Year of crowdsale 
        availableTokensForCrowdSaleSecondYear = tokenSaleAmount.mul(15).div(100); // for 2nd Year of crowdsale
        availableTokensForCrowdSaleThreeYear = tokenSaleAmount.mul(15).div(100); // for 3rd Year of crowdsale
        availableTokensForCrowdSaleFourYear = tokenSaleAmount.mul(15).div(100); // for 4th Year of crowdsale
    }
    
    function setTokenAddressandSendTokenAmount(address tokenAddress) public onlyAdmin{
        erctoken = IERC20(tokenAddress);
        // erctoken.transferFrom(msg.sender, address(this), bal);
        erctoken.transferFrom(msg.sender, address(this), erctoken.balanceOf(msg.sender));
    }
    
    function start()
        external
        onlyAdmin()
        whenNotPaused
        icoNotActive() {
        privateSaleDuration = block.timestamp + 15 days;
    }
    
    function buyPrivateSale()
        external 
        payable
        whenNotPaused
        privateSaleActive() 
    {
        uint256 totalPrice = (msg.value/1e18) * ethPrice;
        
        require(
          totalPrice >= minPurchase, 
          'have to buy between minPurchase and maxPurchase'
        );
        uint tokenAmount = totalPrice.div(tokenPrice);
        require(
          tokenAmount <= availableTokensForPrivateSale, 
          'Not enough tokens left for sale'
        );
        availableTokensForPrivateSale.sub(tokenAmount);
        erctoken.transfer(msg.sender, tokenAmount);
        admin.transfer(msg.value);
    }
    
    function buyPreSale()
        external
        payable
        whenNotPaused
        privateSaleEnded()
        preSaleActive() {
        uint256 totalPrice = (msg.value/1e18) * ethPrice;
            
        require(
          totalPrice >= minPurchase, 
          'have to buy between minPurchase and maxPurchase'
        );
        uint tokenAmount = totalPrice.div(tokenPrice);
        require(
          tokenAmount <= availableTokensForPreSale, 
          'Not enough tokens left for sale'
        );
        availableTokensForPreSale.sub(tokenAmount);
        erctoken.transfer(msg.sender, tokenAmount);
        admin.transfer(msg.value);
    }
    
    function buyCrowdSale()
        external
        payable
        preSaleEnded()
        whenNotPaused
        crowdSaleActive() {
        uint256 totalPrice = (msg.value/1e18) * ethPrice;
        require(
          totalPrice >= minPurchase, 
          'have to buy between minPurchase and maxPurchase'
        );
        uint tokenAmount = totalPrice.div(tokenPrice);
        if (crowdSalePhasesTime <= block.timestamp + 365 days) {
            require(
              tokenAmount <= availableTokensForCrowdSaleFirstYear, 
              'Not enough tokens left for sale'
            );
            availableTokensForCrowdSaleFirstYear.sub(tokenAmount);
        } else if (crowdSalePhasesTime <= block.timestamp + 730 days) {
            require(
              tokenAmount <= availableTokensForCrowdSaleSecondYear, 
              'Not enough tokens left for sale'
            );
            availableTokensForCrowdSaleSecondYear.sub(tokenAmount);
        } else if (crowdSalePhasesTime <= block.timestamp + 1095 days) {
            require(
              tokenAmount <= availableTokensForCrowdSaleThreeYear, 
              'Not enough tokens left for sale'
            );
            availableTokensForCrowdSaleThreeYear.sub(tokenAmount);
        } else if (crowdSalePhasesTime <= block.timestamp + 1460 days) {
            require(
              tokenAmount <= availableTokensForCrowdSaleFourYear, 
              'Not enough tokens left for sale'
            );
            availableTokensForCrowdSaleFourYear.sub(tokenAmount);
        } else {
            return;
        }
        availableTokensForCrowdSale.sub(tokenAmount);
        erctoken.transfer(msg.sender, tokenAmount);
        admin.transfer(msg.value);
    }
    
    function setETHPrice(uint256 price) external onlyAdmin {
        require(price > 0, "Invalid Price");
        ethPrice = price;
    }
    
    modifier privateSaleActive() {
        require(
          privateSaleDuration > 0 && block.timestamp < privateSaleDuration && availableTokensForPrivateSale > 0, 
          'ICO must be active'
        );
        _;
    }
    
    modifier privateSaleEnded() {
        require(
          privateSaleDuration > 0 && (block.timestamp >= privateSaleDuration || availableTokensForPrivateSale == 0), 
          'ICO must have ended'
        );
        _;
    }
    
    modifier preSaleActive() {
        require(
          preSaleDuration > 0 && block.timestamp < preSaleDuration && availableTokensForPreSale > 0, 
          'ICO must be active'
        );
        _;
    }
    
    modifier preSaleEnded() {
        require(
          preSaleDuration > 0 && (block.timestamp >= preSaleDuration || availableTokensForPreSale == 0), 
          'ICO must have ended'
        );
        _;
    }
    
    modifier crowdSaleActive() {
        require(
          crowdSaleDuration > 0 && block.timestamp < crowdSaleDuration && availableTokensForCrowdSale > 0, 
          'ICO must be active'
        );
        _;
    }
    
    modifier crowdSaleEnded() {
        require(
          crowdSaleDuration > 0 && (block.timestamp >= crowdSaleDuration || availableTokensForCrowdSale == 0), 
          'ICO must have ended'
        );
        _;
    }
    
    modifier icoNotActive() {
        require(privateSaleDuration == 0, 'ICO should not be active');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
    function pauseIco() public onlyAdmin {
        _pause();
    }
    
    
    function unpauseIco() public onlyAdmin {
        _unpause();
    }
}