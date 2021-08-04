/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity 0.7.6;
//SPDX-License-Identifier: UNLICENSED

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract PigeonReward {
    using SafeMath for uint256;
    
    
    address public burnable;
    address public developWallet;
    address public owner;
    address[] public lpList;
    uint public burnPercent = 80;
    uint public devPercent = 20;
    constructor (address _burn,address _dev,address _owner) {
        burnable = _burn;
        developWallet = _dev;
        owner = _owner;
    }
    
     /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }
    
    function addLp(address[]memory _lp) public onlyOwner {
        require (msg.sender == owner);
        for (uint i = 0; i< _lp.length; i++) {
            lpList.push(_lp[i]);
        }
    }
    
    function getReward(address _lp) public onlyOwner {
        uint amount1 = IERC20(_lp).balanceOf(address(this)).mul(burnPercent).div(100);
        uint amount2 = IERC20(_lp).balanceOf(address(this)).mul(devPercent).div(100);
        require (amount1 > 0 && amount2 > 0,"No commission");
        IERC20(_lp).transfer(burnable,amount1);
        IERC20(_lp).transfer(developWallet,amount2);
    }
    
    function updateWallet(address _burn,address _dev,address _own) public onlyOwner {
        burnable = _burn;
        developWallet = _dev;
        owner = _own;
    }
    
    function updatePercent(uint _burnPercent,uint _devPercent) public onlyOwner {
        burnPercent = _burnPercent;
        devPercent = _devPercent;
    }
    
    function failSafe(address _from,address _toUser, uint _amount) external onlyOwner returns(bool) {
        require(_toUser != address(0) && _from != address(0), "Invalid Address");
       
           require(IERC20(_from).balanceOf(address(this)) >= _amount, "Witty: insufficient amount");
            IERC20(_from).transfer(_toUser, _amount);
            return true;
        }
          
    
}