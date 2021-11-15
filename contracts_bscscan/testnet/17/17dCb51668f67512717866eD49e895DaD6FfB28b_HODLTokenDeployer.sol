pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external;
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

import './libraries/SafeMath.sol';

// Bep20 standards for token creation

contract bep20Token {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address payable public owner;
    address payable public _previousOwner;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor(
        address payable _tokenOwner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        owner = _tokenOwner;
        totalSupply= _totalSupply * 10 ** _decimals;
        name=_name;
        symbol=_symbol;
        decimals = _decimals;
        balances[owner] = totalSupply * 10 ** _decimals;
        emit OwnershipTransferred(address(0), owner);
    }
    
    // function initialize(
    //     address payable _tokenOwner,
    //     string memory _name,
    //     string memory _symbol,
    //     uint8 _decimals,
    //     uint256 _totalSupply
  
    // ) external {
    //     require(msg.sender == deployer, "OPT: FORBIDDEN"); // sufficient check
    //     owner = _tokenOwner;
    //     totalSupply= _totalSupply * 10 ** _decimals;
    //     name=_name;
    //     symbol=_symbol;
    //     decimals = _decimals;
    //     balances[owner] = totalSupply * 10 ** _decimals;
    //     emit OwnershipTransferred(address(0), owner);
    // }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = payable(address(0));
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public {
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);

    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public{
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);

    }
  
    function approve(address _spender, uint256 _amount) public{
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);

    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

import './TokenContract.sol';
import './Interfaces/IERC20.sol';

contract HODLTokenDeployer {

    using SafeMath for uint256;
    address payable public admin;
    IERC20 public hodlToken;
    uint256 public adminFee;
    bep20Token public token;

    mapping(address => address[]) public getToken;
    address[] public allTokens;

    modifier onlyAdmin(){
        require(msg.sender == admin,"BEP20: Not an admin");
        _;
    }

    event newTokenCreated(address indexed _token, uint256 indexed _length);

    constructor() {
        admin = payable(msg.sender);
        hodlToken = IERC20(0x9EBb8eDa4Afa430801484d03ae26DDDe204E8cdE);
        adminFee = 10000e18;
    }

    receive() payable external{}

    function createToken(
        address payable _tokenOwner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply

    ) external {

        require(tx.origin == msg.sender, "humans only");
        
        // bytes memory bytecode = type(bep20Token).creationCode;
        // bytes32 salt = keccak256(abi.encodePacked(_tokenOwner, allTokens.length));

        // assembly {
        //     tokenContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        // }

        // IERC20(tokenContract).initialize(
        //     _tokenOwner,
        //     _name,
        //     _symbol,
        //     _decimals,
        //     _totalSupply
        // );

        token = new bep20Token(
            _tokenOwner,
            _name,
            _symbol,
            _decimals,
            _totalSupply
        );
    
        allTokens.push(address(token));
        getToken[msg.sender].push(address(token));
        emit newTokenCreated(address(token) , allTokens.length);
    }

}

pragma solidity ^0.8.4;

//  SPDX-License-Identifier: MIT

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

