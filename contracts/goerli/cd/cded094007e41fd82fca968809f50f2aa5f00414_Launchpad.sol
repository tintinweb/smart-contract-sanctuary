/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// import ierc20 & safemath & non-standard
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract Launchpad  is Ownable {
    using SafeMath for uint256;

    event ClaimableAmount(address _user, uint256 _claimableAmount);

    // address public owner;

    uint256 public rate;
    
    uint256 public allowedUserBalance;
    
    bool public presaleOver;
    IERC20 public usdc;
    mapping(address => uint256) public claimable;

    uint256 public hardcap;

    constructor(uint256 _rate, address _usdc, uint256 _hardcap, uint256 _allowedUserBalance) public {
        rate = _rate;
        usdc = IERC20(_usdc);
        presaleOver = false;
        // owner = msg.sender;
        hardcap = _hardcap; 
        allowedUserBalance = _allowedUserBalance;
    }

    modifier isPresaleOver() {
        require(presaleOver == true, "The presale is not over");
        _;
    }
    
    function changeHardCap(uint256 _hardcap) onlyOwner public {
        hardcap = _hardcap;
    }
    
    function changeAllowedUserBalance(uint256 _allowedUserBalance) onlyOwner public {
        allowedUserBalance = _allowedUserBalance;
    }

    function endPresale() external onlyOwner returns (bool) {
        presaleOver = true;
        return presaleOver;
    }

    function startPresale() external onlyOwner returns (bool) {
        presaleOver = false;
        return presaleOver;
    }

    function buyTokenWithUSDC(uint256 _amount) external {
        // user enter amount of ether which is then transfered into the smart contract and tokens to be given is saved in the mapping
        require(presaleOver == false, "presale is over you cannot buy now");
        // require()
        
        
        uint256 tokensPurchased = _amount.mul(rate).div(1e6);
        
        uint256 ownerUpdatedBalance = claimable[msg.sender].add(tokensPurchased);

        require( ownerUpdatedBalance.add(usdc.balanceOf(address(this))) <= hardcap, "Hardcap for the tokens reached");

        require(ownerUpdatedBalance <= allowedUserBalance, "Exceeded allowed user balance");
        
        usdc.transferFrom(msg.sender, address(this), _amount);

        claimable[msg.sender] = ownerUpdatedBalance;
        
        emit ClaimableAmount(msg.sender, tokensPurchased);
    }
    
    // function claim() external isPresaleOver {
    //     // it checks for user msg.sender claimable amount and transfer them to msg.sender
    //     require(claimable[msg.sender] > 0, "NO tokens left to be claim");
    //     usdc.transfer(msg.sender, claimable[msg.sender]);
    //     claimable[msg.sender] = 0;
    // }
    
    function fundsWithdrawal(uint256 _value) external onlyOwner isPresaleOver {
        // claimable[owner] = claimable[owner].sub(_value);
        usdc.transfer(_msgSender(), _value);
    }

}