/**
 *Submitted for verification at snowtrace.io on 2021-12-22
*/

pragma solidity ^0.5.10;

/**
 * @title Guardian node Nodeon storage
 */
contract Nodeon_NodeSave {
    IBMapping mappingContract;                      
    IBNodeon NodeonContract;                             
    
    /**
    * @dev Initialization method
    * @param map Mapping contract address
    */
    constructor (address map) public {
        mappingContract = IBMapping(address(map));              
        NodeonContract = IBNodeon(address(mappingContract.checkAddress("Nodeon")));            
    }
    
    /**
    * @dev Change mapping contract
    * @param map Mapping contract address
    */
    function changeMapping(address map) public onlyOwner {
        mappingContract = IBMapping(address(map));              
        NodeonContract = IBNodeon(address(mappingContract.checkAddress("Nodeon")));            
    }
    
    /**
    * @dev Transfer out Nodeon
    * @param amount Transfer out quantity
    * @param to Transfer out target
    * @return Actual transfer out quantity
    */
    function turnOut(uint256 amount, address to) public onlyMiningCalculation returns(uint256) {
        uint256 leftNum = NodeonContract.balanceOf(address(this));
        if (leftNum >= amount) {
            NodeonContract.transfer(to, amount);
            return amount;
        } else {
            return 0;
        }
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }

    modifier onlyMiningCalculation(){
        require(address(mappingContract.checkAddress("nodeAssignment")) == msg.sender);
        _;
    }
    
}

/**
 * @title Guardian node receives data
 */
contract Nodeon_NodeAssignmentData {
    using SafeMath for uint256;
    IBMapping mappingContract;              
    uint256 nodeAllAmount = 0;                                 
    mapping(address => uint256) nodeLatestAmount;               
    
    /**
    * @dev Initialization method
    * @param map Mapping contract address
    */
    constructor (address map) public {
        mappingContract = IBMapping(map); 
    }
    
    /**
    * @dev Change mapping contract
    * @param map Mapping contract address
    */
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map); 
    }
    
    //  Add Nodeon
    function addNodeon(uint256 amount) public onlyNodeAssignment {
        nodeAllAmount = nodeAllAmount.add(amount);
    }
    
    //  View cumulative total
    function checkNodeAllAmount() public view returns (uint256) {
        return nodeAllAmount;
    }
    
    //  Record last received quantity
    function addNodeLatestAmount(address add ,uint256 amount) public onlyNodeAssignment {
        nodeLatestAmount[add] = amount;
    }
    
    //  View last received quantity
    function checkNodeLatestAmount(address add) public view returns (uint256) {
        return nodeLatestAmount[address(add)];
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
    
    modifier onlyNodeAssignment(){
        require(address(msg.sender) == address(mappingContract.checkAddress("nodeAssignment")));
        _;
    }
}

/**
 * @title Guardian node assignment
 */
contract Nodeon_NodeAssignment {
    
    using SafeMath for uint256;
    IBMapping mappingContract;  
    IBNodeon NodeonContract;                                   
    SuperMan supermanContract;                              
    Nodeon_NodeSave nodeSave;
    Nodeon_NodeAssignmentData nodeAssignmentData;

    /**
    * @dev Initialization method
    * @param map Mapping contract address
    */
    constructor (address map) public {
        mappingContract = IBMapping(map); 
        NodeonContract = IBNodeon(address(mappingContract.checkAddress("Nodeon")));
        supermanContract = SuperMan(address(mappingContract.checkAddress("NodeonNode")));
        nodeSave = Nodeon_NodeSave(address(mappingContract.checkAddress("NodeonNodeSave")));
        nodeAssignmentData = Nodeon_NodeAssignmentData(address(mappingContract.checkAddress("nodeAssignmentData")));
    }
    
    /**
    * @dev Change mapping contract
    * @param map Mapping contract address
    */
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map); 
        NodeonContract = IBNodeon(address(mappingContract.checkAddress("Nodeon")));
        supermanContract = SuperMan(address(mappingContract.checkAddress("NodeonNode")));
        nodeSave = Nodeon_NodeSave(address(mappingContract.checkAddress("NodeonNodeSave")));
        nodeAssignmentData = Nodeon_NodeAssignmentData(address(mappingContract.checkAddress("nodeAssignmentData")));
    }
    
    /**
    * @dev Deposit in Nodeon
    * @param amount Quantity deposited in Nodeon
    */
    function bookKeeping(uint256 amount) public {
        require(amount > 0);
        require(NodeonContract.balanceOf(address(msg.sender)) >= amount);
        require(NodeonContract.allowance(address(msg.sender), address(this)) >= amount);
        require(NodeonContract.transferFrom(address(msg.sender), address(nodeSave), amount));
        nodeAssignmentData.addNodeon(amount);
    }
    
    /**
    * @dev Guardian node collection
    */
    function nodeGet() public {
        require(address(msg.sender) == address(tx.origin));
        require(supermanContract.balanceOf(address(msg.sender)) > 0);
        uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
        uint256 amount = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(msg.sender)));
        uint256 getAmount = amount.mul(supermanContract.balanceOf(address(msg.sender))).div(1500);
        require(NodeonContract.balanceOf(address(nodeSave)) >= getAmount);
        nodeSave.turnOut(getAmount,address(msg.sender));
        nodeAssignmentData.addNodeLatestAmount(address(msg.sender),allAmount);
    }
    
    /**
    * @dev Transfer settlement
    * @param fromAdd Transfer out address
    * @param toAdd Transfer in address
    */
    function nodeCount(address fromAdd, address toAdd) public {
        require(address(supermanContract) == address(msg.sender));
        require(supermanContract.balanceOf(address(fromAdd)) > 0);
        uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
        
        uint256 amountFrom = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(fromAdd)));
        uint256 getAmountFrom = amountFrom.mul(supermanContract.balanceOf(address(fromAdd))).div(1500);
        require(NodeonContract.balanceOf(address(nodeSave)) >= getAmountFrom);
        nodeSave.turnOut(getAmountFrom,address(fromAdd));
        nodeAssignmentData.addNodeLatestAmount(address(fromAdd),allAmount);
        
        uint256 amountTo = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(toAdd)));
        uint256 getAmountTo = amountTo.mul(supermanContract.balanceOf(address(toAdd))).div(1500);
        require(NodeonContract.balanceOf(address(nodeSave)) >= getAmountTo);
        nodeSave.turnOut(getAmountTo,address(toAdd));
        nodeAssignmentData.addNodeLatestAmount(address(toAdd),allAmount);
    }
    
    //  Amount available to the guardian node
    function checkNodeNum() public view returns (uint256) {
         uint256 allAmount = nodeAssignmentData.checkNodeAllAmount();
         uint256 amount = allAmount.sub(nodeAssignmentData.checkNodeLatestAmount(address(msg.sender)));
         uint256 getAmount = amount.mul(supermanContract.balanceOf(address(msg.sender))).div(1500);
         return getAmount;
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract SuperMan is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    IBMapping mappingContract;  //映射合约

    uint256 private _totalSupply = 1500;
    string public name = "NodeonNode";
    string public symbol = "NN";
    uint8 public decimals = 0;

    constructor (address map) public {
    	_balances[msg.sender] = _totalSupply;
    	mappingContract = IBMapping(map); 
    }
    
    function changeMapping(address map) public onlyOwner{
        mappingContract = IBMapping(map);
    }
    
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        
        Nodeon_NodeAssignment nodeAssignment = Nodeon_NodeAssignment(address(mappingContract.checkAddress("nodeAssignment")));
        nodeAssignment.nodeCount(from, to);
        
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        
        
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

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
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
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
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

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
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

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
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

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

contract IBMapping {
	function checkAddress(string memory name) public view returns (address contractAddress);
	function checkOwners(address man) public view returns (bool);
}

contract IBNodeon {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint256 value) external;
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
    
    function balancesStart() public view returns(uint256);
    function balancesGetBool(uint256 num) public view returns(bool);
    function balancesGetNext(uint256 num) public view returns(uint256);
    function balancesGetValue(uint256 num) public view returns(address, uint256);
}