/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity ^0.5.0;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
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

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
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
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 transferToAmount, uint256 transferToFeeDistributorAmount);

    //mint function
    function mintByGovernance(uint256 amount) external;
    
    //burn function
    function burn(uint256 amount) external;
}

//government contract interface
interface ris3Gov {
    function getCurrentLaws() external view returns (uint256 taxRates, uint256 prodRates, string memory taxPoolUses);
    function getCurrentTaxPoolUsesType() external view returns (uint256 _currentTaxPoolUsesType);
    function getRis3Address() external view returns (address _ris3Address);
}

contract Ris3TaxPool is Ownable {
    using SafeMath for uint256;
    
    address public governmentAddress = 0x6ff53cd24E7a1345cE1ff221BD2BcD11ed4D023B;
    ris3Gov public government = ris3Gov(governmentAddress);
    
    address public ris3Address = government.getRis3Address();
    IERC20 public ris3 = IERC20(ris3Address);
    
    uint256 sentToGovernment;
    
    event taxTransferred(address indexed user, uint256 amount);
    event Burned(uint256 amount);
    
    constructor () public {
        
    }
    
    //Send tax to government
    function governmentCollectTaxes() public {
        require(msg.sender == governmentAddress, "Only government can call collect tax");
        uint256 amountToSend;
        uint256 amount = ris3.balanceOf(address(this));
        
        //get currentTaxPoolUsesType
        uint256 currentTaxPoolUsesType= government.getCurrentTaxPoolUsesType();
        if (amount > 1000) {
            if (currentTaxPoolUsesType == 1){
                sentToGovernment = amount;
                ris3.transfer(msg.sender, amount);
                emit taxTransferred(msg.sender, amount);
            }
            else if (currentTaxPoolUsesType == 2) {
                amountToSend = amount.div(2);
                //burn half
                ris3.burn(amountToSend);
                emit Burned(amountToSend);
                
                //transfer to government
                sentToGovernment = amount - amountToSend;
                ris3.transfer(msg.sender, amount - amountToSend);
                emit taxTransferred(msg.sender, amount - amountToSend);
            } else {
                sentToGovernment = 0;
                //burn all
                ris3.burn(amount);
                emit Burned(amount);
            }
        } else {
            sentToGovernment = 0;
        }
        
    }
  
    function getTotalTaxCollected() view public returns (uint256 _totalTax)
    {
        return ris3.balanceOf(address(this));
    }
    
    function getTaxSentToGovernment() view public returns (uint256 _sentToGovernment)
    {
        return sentToGovernment;
    }
   
    //set government address
    function setGovernmentAddress(address _govAddress) public onlyOwner {
        governmentAddress = _govAddress;
        government = ris3Gov(governmentAddress);
        ris3Address = government.getRis3Address();
        ris3 = IERC20(ris3Address);
    }
    
}