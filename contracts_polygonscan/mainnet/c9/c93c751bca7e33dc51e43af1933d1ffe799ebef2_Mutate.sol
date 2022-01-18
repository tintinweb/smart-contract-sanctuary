/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/mutant_prod.sol


pragma solidity >=0.7.0 <0.9.0;


library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

interface IPolygonPenguin {
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Mutate {
    
    using SafeMath for uint256;

    address private constant penguinAddr = 0xeaD5D1eC4F7a647De61a7A0225eeC7387A25BE01;
    mapping(uint256 => bool) public isMutant;
    mapping(address => uint256) public currentBonds;
    uint256[] private mutant;
    address[] private bondedAddresses;
    uint256 public mutateFee = 10000000000000000 wei;
    uint256 public bonds;
    uint256 public bondsRemaining;
    uint256 public maxBondsperUser;
    address payable internal mutantFarmAddr;
    address payable internal deployer;
    address payable internal developer;


    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }


    constructor(address payable _deployer, address payable _developer, address payable _mutantFarmAddr) {
        mutantFarmAddr = _mutantFarmAddr;
        deployer = _deployer;
        developer = _developer;
    }

    function deposit() public payable {}

    function getMutant() public view returns (uint256[] memory) {
        return mutant;
    }

    function changeFee(uint256 _fee) public onlyDeployer {
        mutateFee = _fee;
    }

    function withdrawERC20(
        IERC20 token,
        address payable destination,
        uint256 amount
    ) public onlyDeployer {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "Insufficient funds");
        token.transfer(destination, amount);
        //emit Transfered(msg.sender, destination, amount);
    }


    function setBonds(uint protocol_amount, uint user_amount, uint set_fee) public onlyDeployer {
        bonds = protocol_amount;
        maxBondsperUser = user_amount;
        bondsRemaining = bonds;
        mutateFee = set_fee;
    }

    function setBondFee(uint fee) public onlyDeployer {
        mutateFee = fee;
    }

    function clearBonds() public onlyDeployer{
        for (uint256 i = 0; i < bondedAddresses.length; i++) {
            currentBonds[bondedAddresses[i]] = 0;
        }
    }

    function mutate(uint256 penguinId) external payable {
        uint mutantFarmBalance;
        uint developerBalance;
        
        require(bondsRemaining > 0, "no bonds left");
        require(currentBonds[msg.sender] < maxBondsperUser, "max bonds hit");
        //require(IPolygonPenguin(penguinAddr).ownerOf(penguinId) == msg.sender, "you don't own this penguin ser");
        require(msg.value == mutateFee, "fee sent not correct");
        require(!isMutant[penguinId], "already mutated penguin");
    
        bondedAddresses.push(msg.sender);
        mutantFarmBalance = ((mutateFee * 90) / 100); 
        developerBalance = ((mutateFee * 10) / 100);
        mutantFarmAddr.transfer(mutantFarmBalance);
        developer.transfer(developerBalance);
        isMutant[penguinId] = true;
        currentBonds[msg.sender] += 1;
        bondsRemaining -= 1;
        mutant.push(penguinId);
    }
}