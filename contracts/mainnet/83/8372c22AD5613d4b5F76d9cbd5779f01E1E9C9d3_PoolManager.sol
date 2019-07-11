/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity 0.5.0;

library UniformRandomNumber {
  /// @author Brendan Asselstine
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

contract ICErc20 {
    address public underlying;
    function mint(uint mintAmount) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getCash() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
}


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
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
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
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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







/**
 *  @reviewers: [@clesaege, @unknownunknown1, @ferittuncer]
 *  @auditors: []
 *  @bounties: [<14 days 10 ETH max payout>]
 *  @deployments: []
 */



/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d1b4a1b8a0a4b4a3b0a2a291b6bcb0b8bdffb2bebc">[email&#160;protected]</a>>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
library SortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K The number of children each node in the tree should have.
     */
    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack.length = 0;
        tree.nodes.length = 0;
        tree.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // No existing node.
            if (_value != 0) { // Non zero value.
                // Append.
                // Add node.
                if (tree.stack.length == 0) { // No vacant spots.
                    // Get the index and append the value.
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    // Potentially append a new node and make the parent a sum node.
                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { // Some vacant spot.
                    // Pop the stack and append the value.
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.length--;
                    tree.nodes[treeIndex] = _value;
                }

                // Add label.
                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { // Existing node.
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    /* Public Views */

    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return The index at which leaves start, the values of the returned leaves, and whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) public view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    /** @dev Gets a specified ID&#39;s associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return The associated value.
     */
    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}





/**
 * @title FixidityLib
 * @author Gadi Guy, Alberto Cuesta Canada
 * @notice This library provides fixed point arithmetic with protection against
 * overflow. 
 * All operations are done with int256 and the operands must have been created 
 * with any of the newFrom* functions, which shift the comma digits() to the 
 * right and check for limits.
 * When using this library be sure of using maxNewFixed() as the upper limit for
 * creation of fixed point numbers. Use maxFixedMul(), maxFixedDiv() and
 * maxFixedAdd() if you want to be certain that those operations don&#39;t 
 * overflow.
 */
library FixidityLib {

    /**
     * @notice Number of positions that the comma is shifted to the right.
     */
    function digits() public pure returns(uint8) {
        return 24;
    }
    
    /**
     * @notice This is 1 in the fixed point units used in this library.
     * @dev Test fixed1() equals 10^digits()
     * Hardcoded to 24 digits.
     */
    function fixed1() public pure returns(int256) {
        return 1000000000000000000000000;
    }

    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() public pure returns(int256) {
        return 1000000000000;
    }

    /**
     * @notice Maximum value that can be represented in an int256
     * @dev Test maxInt256() equals 2^255 -1
     */
    function maxInt256() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

    /**
     * @notice Minimum value that can be represented in an int256
     * @dev Test minInt256 equals (2^255) * (-1)
     */
    function minInt256() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * @dev deployment. 
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * deployment. 
     * @dev Test minNewFixed() equals -(maxInt256()) / fixed1()
     * Hardcoded to 24 digits.
     */
    function minNewFixed() public pure returns(int256) {
        return -57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as an addition operator.
     * @dev Test maxFixedAdd() equals maxInt256()-1 / 2
     * Test add(maxFixedAdd(),maxFixedAdd()) equals maxFixedAdd() + maxFixedAdd()
     * Test add(maxFixedAdd()+1,maxFixedAdd()) throws 
     * Test add(-maxFixedAdd(),-maxFixedAdd()) equals -maxFixedAdd() - maxFixedAdd()
     * Test add(-maxFixedAdd(),-maxFixedAdd()-1) throws 
     */
    function maxFixedAdd() public pure returns(int256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

    /**
     * @notice Maximum negative value that can be safely in a subtraction.
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() public pure returns(int256) {
        return -28948022309329048855892746252171976963317496166410141009864396001978282409984;
    }

    /**
     * @notice Maximum value that can be safely used as a multiplication operator.
     * @dev Calculated as sqrt(maxInt256()*fixed1()). 
     * Be careful with your sqrt() implementation. I couldn&#39;t find a calculator
     * that would give the exact square root of maxInt256*fixed1 so this number
     * is below the real number by no more than 3*10**28. It is safe to use as
     * a limit for your multiplications, although powers of two of numbers over
     * this value might still work.
     * Test multiply(maxFixedMul(),maxFixedMul()) equals maxFixedMul() * maxFixedMul()
     * Test multiply(maxFixedMul(),maxFixedMul()+1) throws 
     * Test multiply(-maxFixedMul(),maxFixedMul()) equals -maxFixedMul() * maxFixedMul()
     * Test multiply(-maxFixedMul(),maxFixedMul()+1) throws 
     * Hardcoded to 24 digits.
     */
    function maxFixedMul() public pure returns(int256) {
        return 240615969168004498257251713877715648331380787511296;
    }

    /**
     * @notice Maximum value that can be safely used as a dividend.
     * @dev divide(maxFixedDiv,newFixedFraction(1,fixed1())) = maxInt256().
     * Test maxFixedDiv() equals maxInt256()/fixed1()
     * Test divide(maxFixedDiv(),multiply(mulPrecision(),mulPrecision())) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,multiply(mulPrecision(),mulPrecision())) throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDiv() public pure returns(int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as a divisor.
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() public pure returns(int256) {
        return 1000000000000000000000000000000000000000000000000;
    }

    /**
     * @notice Converts an int256 to fixed point units, equivalent to multiplying
     * by 10^digits().
     * @dev Test newFixed(0) returns 0
     * Test newFixed(1) returns fixed1()
     * Test newFixed(maxNewFixed()) returns maxNewFixed() * fixed1()
     * Test newFixed(maxNewFixed()+1) fails
     */
    function newFixed(int256 x)
        public
        pure
        returns (int256)
    {
        assert(x <= maxNewFixed());
        assert(x >= minNewFixed());
        return x * fixed1();
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this 
     * library to a non decimal. All decimal digits will be truncated.
     */
    function fromFixed(int256 x)
        public
        pure
        returns (int256)
    {
        return x / fixed1();
    }

    /**
     * @notice Converts an int256 which is already in some fixed point 
     * representation to a different fixed precision representation.
     * Both the origin and destination precisions must be 38 or less digits.
     * Origin values with a precision higher than the destination precision
     * will be truncated accordingly.
     * @dev 
     * Test convertFixed(1,0,0) returns 1;
     * Test convertFixed(1,1,1) returns 1;
     * Test convertFixed(1,1,0) returns 0;
     * Test convertFixed(1,0,1) returns 10;
     * Test convertFixed(10,1,0) returns 1;
     * Test convertFixed(10,0,1) returns 100;
     * Test convertFixed(100,1,0) returns 10;
     * Test convertFixed(100,0,1) returns 1000;
     * Test convertFixed(1000,2,0) returns 10;
     * Test convertFixed(1000,0,2) returns 100000;
     * Test convertFixed(1000,2,1) returns 100;
     * Test convertFixed(1000,1,2) returns 10000;
     * Test convertFixed(maxInt256,1,0) returns maxInt256/10;
     * Test convertFixed(maxInt256,0,1) throws
     * Test convertFixed(maxInt256,38,0) returns maxInt256/(10**38);
     * Test convertFixed(1,0,38) returns 10**38;
     * Test convertFixed(maxInt256,39,0) throws
     * Test convertFixed(1,0,39) throws
     */
    function convertFixed(int256 x, uint8 _originDigits, uint8 _destinationDigits)
        public
        pure
        returns (int256)
    {
        assert(_originDigits <= 38 && _destinationDigits <= 38);
        
        uint8 decimalDifference;
        if ( _originDigits > _destinationDigits ){
            decimalDifference = _originDigits - _destinationDigits;
            return x/(uint128(10)**uint128(decimalDifference));
        }
        else if ( _originDigits < _destinationDigits ){
            decimalDifference = _destinationDigits - _originDigits;
            // Cast uint8 -> uint128 is safe
            // Exponentiation is safe:
            //     _originDigits and _destinationDigits limited to 38 or less
            //     decimalDifference = abs(_destinationDigits - _originDigits)
            //     decimalDifference < 38
            //     10**38 < 2**128-1
            assert(x <= maxInt256()/uint128(10)**uint128(decimalDifference));
            assert(x >= minInt256()/uint128(10)**uint128(decimalDifference));
            return x*(uint128(10)**uint128(decimalDifference));
        }
        // _originDigits == digits()) 
        return x;
    }

    /**
     * @notice Converts an int256 which is already in some fixed point 
     * representation to that of this library. The _originDigits parameter is the
     * precision of x. Values with a precision higher than FixidityLib.digits()
     * will be truncated accordingly.
     */
    function newFixed(int256 x, uint8 _originDigits)
        public
        pure
        returns (int256)
    {
        return convertFixed(x, _originDigits, digits());
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this 
     * library to a different representation. The _destinationDigits parameter is the
     * precision of the output x. Values with a precision below than 
     * FixidityLib.digits() will be truncated accordingly.
     */
    function fromFixed(int256 x, uint8 _destinationDigits)
        public
        pure
        returns (int256)
    {
        return convertFixed(x, digits(), _destinationDigits);
    }

    /**
     * @notice Converts two int256 representing a fraction to fixed point units,
     * equivalent to multiplying dividend and divisor by 10^digits().
     * @dev 
     * Test newFixedFraction(maxFixedDiv()+1,1) fails
     * Test newFixedFraction(1,maxFixedDiv()+1) fails
     * Test newFixedFraction(1,0) fails     
     * Test newFixedFraction(0,1) returns 0
     * Test newFixedFraction(1,1) returns fixed1()
     * Test newFixedFraction(maxFixedDiv(),1) returns maxFixedDiv()*fixed1()
     * Test newFixedFraction(1,fixed1()) returns 1
     * Test newFixedFraction(1,fixed1()-1) returns 0
     */
    function newFixedFraction(
        int256 numerator, 
        int256 denominator
        )
        public
        pure
        returns (int256)
    {
        assert(numerator <= maxNewFixed());
        assert(denominator <= maxNewFixed());
        assert(denominator != 0);
        int256 convertedNumerator = newFixed(numerator);
        int256 convertedDenominator = newFixed(denominator);
        return divide(convertedNumerator, convertedDenominator);
    }

    /**
     * @notice Returns the integer part of a fixed point number.
     * @dev 
     * Test integer(0) returns 0
     * Test integer(fixed1()) returns fixed1()
     * Test integer(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test integer(-fixed1()) returns -fixed1()
     * Test integer(newFixed(-maxNewFixed())) returns -maxNewFixed()*fixed1()
     */
    function integer(int256 x) public pure returns (int256) {
        return (x / fixed1()) * fixed1(); // Can&#39;t overflow
    }

    /**
     * @notice Returns the fractional part of a fixed point number. 
     * In the case of a negative number the fractional is also negative.
     * @dev 
     * Test fractional(0) returns 0
     * Test fractional(fixed1()) returns 0
     * Test fractional(fixed1()-1) returns 10^24-1
     * Test fractional(-fixed1()) returns 0
     * Test fractional(-fixed1()+1) returns -10^24-1
     */
    function fractional(int256 x) public pure returns (int256) {
        return x - (x / fixed1()) * fixed1(); // Can&#39;t overflow
    }

    /**
     * @notice Converts to positive if negative.
     * Due to int256 having one more negative number than positive numbers 
     * abs(minInt256) reverts.
     * @dev 
     * Test abs(0) returns 0
     * Test abs(fixed1()) returns -fixed1()
     * Test abs(-fixed1()) returns fixed1()
     * Test abs(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test abs(newFixed(minNewFixed())) returns -minNewFixed()*fixed1()
     */
    function abs(int256 x) public pure returns (int256) {
        if (x >= 0) {
            return x;
        } else {
            int256 result = -x;
            assert (result > 0);
            return result;
        }
    }

    /**
     * @notice x+y. If any operator is higher than maxFixedAdd() it 
     * might overflow.
     * In solidity maxInt256 + 1 = minInt256 and viceversa.
     * @dev 
     * Test add(maxFixedAdd(),maxFixedAdd()) returns maxInt256()-1
     * Test add(maxFixedAdd()+1,maxFixedAdd()+1) fails
     * Test add(-maxFixedSub(),-maxFixedSub()) returns minInt256()
     * Test add(-maxFixedSub()-1,-maxFixedSub()-1) fails
     * Test add(maxInt256(),maxInt256()) fails
     * Test add(minInt256(),minInt256()) fails
     */
    function add(int256 x, int256 y) public pure returns (int256) {
        int256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead. 
     * @dev Tests covered by add(x,y)
     */
    function subtract(int256 x, int256 y) public pure returns (int256) {
        return add(x,-y);
    }

    /**
     * @notice x*y. If any of the operators is higher than maxFixedMul() it 
     * might overflow.
     * @dev 
     * Test multiply(0,0) returns 0
     * Test multiply(maxFixedMul(),0) returns 0
     * Test multiply(0,maxFixedMul()) returns 0
     * Test multiply(maxFixedMul(),fixed1()) returns maxFixedMul()
     * Test multiply(fixed1(),maxFixedMul()) returns maxFixedMul()
     * Test all combinations of (2,-2), (2, 2.5), (2, -2.5) and (0.5, -0.5)
     * Test multiply(fixed1()/mulPrecision(),fixed1()*mulPrecision())
     * Test multiply(maxFixedMul()-1,maxFixedMul()) equals multiply(maxFixedMul(),maxFixedMul()-1)
     * Test multiply(maxFixedMul(),maxFixedMul()) returns maxInt256() // Probably not to the last digits
     * Test multiply(maxFixedMul()+1,maxFixedMul()) fails
     * Test multiply(maxFixedMul(),maxFixedMul()+1) fails
     */
    function multiply(int256 x, int256 y) public pure returns (int256) {
        if (x == 0 || y == 0) return 0;
        if (y == fixed1()) return x;
        if (x == fixed1()) return y;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        int256 x1 = integer(x) / fixed1();
        int256 x2 = fractional(x);
        int256 y1 = integer(y) / fixed1();
        int256 y2 = fractional(y);
        
        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        int256 x1y1 = x1 * y1;
        if (x1 != 0) assert(x1y1 / x1 == y1); // Overflow x1y1
        
        // x1y1 needs to be multiplied back by fixed1
        // solium-disable-next-line mixedcase
        int256 fixed_x1y1 = x1y1 * fixed1();
        if (x1y1 != 0) assert(fixed_x1y1 / x1y1 == fixed1()); // Overflow x1y1 * fixed1
        x1y1 = fixed_x1y1;

        int256 x2y1 = x2 * y1;
        if (x2 != 0) assert(x2y1 / x2 == y1); // Overflow x2y1

        int256 x1y2 = x1 * y2;
        if (x1 != 0) assert(x1y2 / x1 == y2); // Overflow x1y2

        x2 = x2 / mulPrecision();
        y2 = y2 / mulPrecision();
        int256 x2y2 = x2 * y2;
        if (x2 != 0) assert(x2y2 / x2 == y2); // Overflow x2y2

        // result = fixed1() * x1 * y1 + x1 * y2 + x2 * y1 + x2 * y2 / fixed1();
        int256 result = x1y1;
        result = add(result, x2y1); // Add checks for overflow
        result = add(result, x1y2); // Add checks for overflow
        result = add(result, x2y2); // Add checks for overflow
        return result;
    }
    
    /**
     * @notice 1/x
     * @dev 
     * Test reciprocal(0) fails
     * Test reciprocal(fixed1()) returns fixed1()
     * Test reciprocal(fixed1()*fixed1()) returns 1 // Testing how the fractional is truncated
     * Test reciprocal(2*fixed1()*fixed1()) returns 0 // Testing how the fractional is truncated
     */
    function reciprocal(int256 x) public pure returns (int256) {
        assert(x != 0);
        return (fixed1()*fixed1()) / x; // Can&#39;t overflow
    }

    /**
     * @notice x/y. If the dividend is higher than maxFixedDiv() it 
     * might overflow. You can use multiply(x,reciprocal(y)) instead.
     * There is a loss of precision on division for the lower mulPrecision() decimals.
     * @dev 
     * Test divide(fixed1(),0) fails
     * Test divide(maxFixedDiv(),1) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,1) throws
     * Test divide(maxFixedDiv(),maxFixedDiv()) returns fixed1()
     */
    function divide(int256 x, int256 y) public pure returns (int256) {
        if (y == fixed1()) return x;
        assert(y != 0);
        assert(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}


/**
 * @title The Pool contract for PoolTogether
 * @author Brendan Asselstine
 * @notice This contract implements a "lossless pool".  The pool exists in three states: open, locked, and complete.
 * The pool begins in the open state during which users can buy any number of tickets.  The more tickets they purchase, the greater their chances of winning.
 * After the lockStartBlock the owner may lock the pool.  The pool transfers the pool of ticket money into the Compound Finance money market and no more tickets are sold.
 * After the lockEndBlock the owner may unlock the pool.  The pool will withdraw the ticket money from the money market, plus earned interest, back into the contract.  The fee will be sent to
 * the owner, and users will be able to withdraw their ticket money and winnings, if any.
 * @dev All monetary values are stored internally as fixed point 24.
 */
contract Pool is Ownable {
  using SafeMath for uint256;

  /**
   * Emitted when "tickets" have been purchased.
   * @param sender The purchaser of the tickets
   * @param count The number of tickets purchased
   * @param totalPrice The total cost of the tickets
   */
  event BoughtTickets(address indexed sender, int256 count, uint256 totalPrice);

  /**
   * Emitted when a user withdraws from the pool.
   * @param sender The user that is withdrawing from the pool
   * @param amount The amount that the user withdrew
   */
  event Withdrawn(address indexed sender, int256 amount);

  /**
   * Emitted when the pool is locked.
   */
  event PoolLocked();

  /**
   * Emitted when the pool is unlocked.
   */
  event PoolUnlocked();

  /**
   * Emitted when the pool is complete
   */
  event PoolComplete(address indexed winner);

  enum State {
    OPEN,
    LOCKED,
    UNLOCKED,
    COMPLETE
  }

  struct Entry {
    address addr;
    int256 amount;
    uint256 ticketCount;
    int256 withdrawnNonFixed;
  }

  bytes32 public constant SUM_TREE_KEY = "PoolPool";

  int256 private totalAmount; // fixed point 24
  uint256 private lockStartBlock;
  uint256 private lockEndBlock;
  bytes32 private secretHash;
  bytes32 private secret;
  State public state;
  int256 private finalAmount; //fixed point 24
  mapping (address => Entry) private entries;
  uint256 public entryCount;
  ICErc20 public moneyMarket;
  IERC20 public token;
  int256 private ticketPrice; //fixed point 24
  int256 private feeFraction; //fixed point 24
  bool private ownerHasWithdrawn;
  bool public allowLockAnytime;
  address private winningAddress;

  using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
  SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

  /**
   * @notice Creates a new Pool.
   * @param _moneyMarket The Compound money market to supply tokens to.
   * @param _token The ERC20 token to be used.
   * @param _lockStartBlock The block number on or after which the deposit can be made to Compound
   * @param _lockEndBlock The block number on or after which the Compound supply can be withdrawn
   * @param _ticketPrice The price of each ticket (fixed point 18)
   * @param _feeFractionFixedPoint18 The fraction of the winnings going to the owner (fixed point 18)
   */
  constructor (
    ICErc20 _moneyMarket,
    IERC20 _token,
    uint256 _lockStartBlock,
    uint256 _lockEndBlock,
    int256 _ticketPrice,
    int256 _feeFractionFixedPoint18,
    bool _allowLockAnytime
  ) public {
    require(_lockEndBlock > _lockStartBlock, "lock end block is not after start block");
    require(address(_moneyMarket) != address(0), "money market address cannot be zero");
    require(address(_token) != address(0), "token address cannot be zero");
    require(_ticketPrice > 0, "ticket price must be greater than zero");
    require(_feeFractionFixedPoint18 >= 0, "fee must be zero or greater");
    require(_feeFractionFixedPoint18 <= 1000000000000000000, "fee fraction must be less than 1");
    feeFraction = FixidityLib.newFixed(_feeFractionFixedPoint18, uint8(18));
    ticketPrice = FixidityLib.newFixed(_ticketPrice);
    sortitionSumTrees.createTree(SUM_TREE_KEY, 4);

    state = State.OPEN;
    moneyMarket = _moneyMarket;
    token = _token;
    lockStartBlock = _lockStartBlock;
    lockEndBlock = _lockEndBlock;
    allowLockAnytime = _allowLockAnytime;
  }

  /**
   * @notice Buys a pool ticket.  Only possible while the Pool is in the "open" state.  The
   * user can buy any number of tickets.  Each ticket is a chance at winning.
   * @param _countNonFixed The number of tickets the user wishes to buy.
   */
  function buyTickets (int256 _countNonFixed) public requireOpen {
    require(_countNonFixed > 0, "number of tickets is less than or equal to zero");
    int256 count = FixidityLib.newFixed(_countNonFixed);
    int256 totalDeposit = FixidityLib.multiply(ticketPrice, count);
    uint256 totalDepositNonFixed = uint256(FixidityLib.fromFixed(totalDeposit));
    require(token.transferFrom(msg.sender, address(this), totalDepositNonFixed), "token transfer failed");

    if (_hasEntry(msg.sender)) {
      entries[msg.sender].amount = FixidityLib.add(entries[msg.sender].amount, totalDeposit);
      entries[msg.sender].ticketCount = entries[msg.sender].ticketCount.add(uint256(_countNonFixed));
    } else {
      entries[msg.sender] = Entry(
        msg.sender,
        totalDeposit,
        uint256(_countNonFixed),
        0
      );
      entryCount = entryCount.add(1);
    }

    int256 amountNonFixed = FixidityLib.fromFixed(entries[msg.sender].amount);
    sortitionSumTrees.set(SUM_TREE_KEY, uint256(amountNonFixed), bytes32(uint256(msg.sender)));

    totalAmount = FixidityLib.add(totalAmount, totalDeposit);

    // the total amount cannot exceed the max pool size
    require(totalAmount <= maxPoolSizeFixedPoint24(FixidityLib.maxFixedDiv()), "pool size exceeds maximum");

    emit BoughtTickets(msg.sender, _countNonFixed, totalDepositNonFixed);
  }

  /**
   * @notice Pools the deposits and supplies them to Compound.
   * Can only be called by the owner when the pool is open.
   * Fires the PoolLocked event.
   */
  function lock(bytes32 _secretHash) external requireOpen onlyOwner {
    if (allowLockAnytime) {
      lockStartBlock = block.number;
    } else {
      require(block.number >= lockStartBlock, "pool can only be locked on or after lock start block");
    }
    require(_secretHash != 0, "secret hash must be defined");
    secretHash = _secretHash;
    state = State.LOCKED;

    if (totalAmount > 0) {
      uint256 totalAmountNonFixed = uint256(FixidityLib.fromFixed(totalAmount));
      require(token.approve(address(moneyMarket), totalAmountNonFixed), "could not approve money market spend");
      require(moneyMarket.mint(totalAmountNonFixed) == 0, "could not supply money market");
    }

    emit PoolLocked();
  }

  function unlock() public requireLocked {
    if (allowLockAnytime && msg.sender == owner()) {
      lockEndBlock = block.number;
    } else {
      require(lockEndBlock < block.number, "pool cannot be unlocked yet");
    }

    uint256 balance = moneyMarket.balanceOfUnderlying(address(this));

    if (balance > 0) {
      require(moneyMarket.redeemUnderlying(balance) == 0, "could not redeem from compound");
      finalAmount = FixidityLib.newFixed(int256(balance));
    }

    state = State.UNLOCKED;

    emit PoolUnlocked();
  }

  /**
   * @notice Withdraws the deposit from Compound and selects a winner.
   * Can only be called by the owner after the lock end block.
   * Fires the PoolUnlocked event.
   */
  function complete(bytes32 _secret) public onlyOwner {
    if (state == State.LOCKED) {
      unlock();
    }
    require(state == State.UNLOCKED, "state must be unlocked");
    require(keccak256(abi.encodePacked(_secret)) == secretHash, "secret does not match");
    secret = _secret;
    state = State.COMPLETE;
    winningAddress = calculateWinner();

    uint256 fee = feeAmount();
    if (fee > 0) {
      require(token.transfer(owner(), fee), "could not transfer winnings");
    }

    emit PoolComplete(winningAddress);
  }

  /**
   * @notice Transfers a users deposit, and potential winnings, back to them.
   * The Pool must be unlocked.
   * The user must have deposited funds.  Fires the Withdrawn event.
   */
  function withdraw() public {
    require(_hasEntry(msg.sender), "entrant exists");
    require(state == State.UNLOCKED || state == State.COMPLETE, "pool has not been unlocked");
    Entry storage entry = entries[msg.sender];
    int256 remainingBalanceNonFixed = balanceOf(msg.sender);
    require(remainingBalanceNonFixed > 0, "entrant has already withdrawn");
    entry.withdrawnNonFixed = entry.withdrawnNonFixed + remainingBalanceNonFixed;

    emit Withdrawn(msg.sender, remainingBalanceNonFixed);

    require(token.transfer(msg.sender, uint256(remainingBalanceNonFixed)), "could not transfer winnings");
  }

  /**
   * @notice Calculates a user&#39;s winnings.  This is their deposit plus their winnings, if any.
   * @param _addr The address of the user
   */
  function winnings(address _addr) public view returns (int256) {
    Entry storage entry = entries[_addr];
    if (entry.addr == address(0)) { //if does not have an entry
      return 0;
    }
    int256 winningTotal = entry.amount;
    if (state == State.COMPLETE && _addr == winningAddress) {
      winningTotal = FixidityLib.add(winningTotal, netWinningsFixedPoint24());
    }
    return FixidityLib.fromFixed(winningTotal);
  }

  /**
   * @notice Calculates a user&#39;s remaining balance.  This is their winnings less how much they&#39;ve withdrawn.
   * @return The users&#39;s current balance.
   */
  function balanceOf(address _addr) public view returns (int256) {
    Entry storage entry = entries[_addr];
    int256 winningTotalNonFixed = winnings(_addr);
    return winningTotalNonFixed - entry.withdrawnNonFixed;
  }

  function calculateWinner() private view returns (address) {
    if (totalAmount > 0) {
      return address(uint256(sortitionSumTrees.draw(SUM_TREE_KEY, randomToken())));
    } else {
      return address(0);
    }
  }

  /**
   * @notice Selects and returns the winner&#39;s address
   * @return The winner&#39;s address
   */
  function winnerAddress() public view returns (address) {
    return winningAddress;
  }

  /**
   * @notice Returns the total interest on the pool less the fee as a whole number
   * @return The total interest on the pool less the fee as a whole number
   */
  function netWinnings() public view returns (int256) {
    return FixidityLib.fromFixed(netWinningsFixedPoint24());
  }

  /**
   * @notice Computes the total interest earned on the pool less the fee as a fixed point 24.
   * @return The total interest earned on the pool less the fee as a fixed point 24.
   */
  function netWinningsFixedPoint24() internal view returns (int256) {
    return grossWinningsFixedPoint24() - feeAmountFixedPoint24();
  }

  /**
   * @notice Computes the total interest earned on the pool as a fixed point 24.
   * This is what the winner will earn once the pool is unlocked.
   * @return The total interest earned on the pool as a fixed point 24.
   */
  function grossWinningsFixedPoint24() internal view returns (int256) {
    return FixidityLib.subtract(finalAmount, totalAmount);
  }

  /**
   * @notice Calculates the size of the fee based on the gross winnings
   * @return The fee for the pool to be transferred to the owner
   */
  function feeAmount() public view returns (uint256) {
    return uint256(FixidityLib.fromFixed(feeAmountFixedPoint24()));
  }

  /**
   * @notice Calculates the fee for the pool by multiplying the gross winnings by the fee fraction.
   * @return The fee for the pool as a fixed point 24
   */
  function feeAmountFixedPoint24() internal view returns (int256) {
    return FixidityLib.multiply(grossWinningsFixedPoint24(), feeFraction);
  }

  /**
   * @notice Selects a random number in the range from [0, total tokens deposited)
   * @return If the current block is before the end it returns 0, otherwise it returns the random number.
   */
  function randomToken() public view returns (uint256) {
    if (block.number <= lockEndBlock) {
      return 0;
    } else {
      return _selectRandom(uint256(FixidityLib.fromFixed(totalAmount)));
    }
  }

  /**
   * @notice Selects a random number in the range [0, total)
   * @param total The upper bound for the random number
   * @return The random number
   */
  function _selectRandom(uint256 total) internal view returns (uint256) {
    return UniformRandomNumber.uniform(_entropy(), total);
  }

  /**
   * @notice Computes the entropy used to generate the random number.
   * The blockhash of the lock end block is XOR&#39;d with the secret revealed by the owner.
   * @return The computed entropy value
   */
  function _entropy() internal view returns (uint256) {
    return uint256(blockhash(block.number - 1) ^ secret);
  }

  /**
   * @notice Retrieves information about the pool.
   * @return A tuple containing:
   *    entryTotal (the total of all deposits)
   *    startBlock (the block after which the pool can be locked)
   *    endBlock (the block after which the pool can be unlocked)
   *    poolState (either OPEN, LOCKED, COMPLETE)
   *    winner (the address of the winner)
   *    supplyBalanceTotal (the total deposits plus any interest from Compound)
   *    ticketCost (the cost of each ticket in DAI)
   *    participantCount (the number of unique purchasers of tickets)
   *    maxPoolSize (the maximum theoretical size of the pool to prevent overflow)
   *    estimatedInterestFixedPoint18 (the estimated total interest percent for this pool)
   *    hashOfSecret (the hash of the secret the owner submitted upon locking)
   */
  function getInfo() public view returns (
    int256 entryTotal,
    uint256 startBlock,
    uint256 endBlock,
    State poolState,
    address winner,
    int256 supplyBalanceTotal,
    int256 ticketCost,
    uint256 participantCount,
    int256 maxPoolSize,
    int256 estimatedInterestFixedPoint18,
    bytes32 hashOfSecret
  ) {
    return (
      FixidityLib.fromFixed(totalAmount),
      lockStartBlock,
      lockEndBlock,
      state,
      winningAddress,
      FixidityLib.fromFixed(finalAmount),
      FixidityLib.fromFixed(ticketPrice),
      entryCount,
      FixidityLib.fromFixed(maxPoolSizeFixedPoint24(FixidityLib.maxFixedDiv())),
      FixidityLib.fromFixed(currentInterestFractionFixedPoint24(), uint8(18)),
      secretHash
    );
  }

  /**
   * @notice Retrieves information about a user&#39;s entry in the Pool.
   * @return Returns a tuple containing:
   *    addr (the address of the user)
   *    amount (the amount they deposited)
   *    ticketCount (the number of tickets they have bought)
   *    withdrawn (the amount they have withdrawn)
   */
  function getEntry(address _addr) public view returns (
    address addr,
    int256 amount,
    uint256 ticketCount,
    int256 withdrawn
  ) {
    Entry storage entry = entries[_addr];
    return (
      entry.addr,
      FixidityLib.fromFixed(entry.amount),
      entry.ticketCount,
      entry.withdrawnNonFixed
    );
  }

  /**
   * @notice Calculates the maximum pool size so that it doesn&#39;t overflow after earning interest
   * @dev poolSize = totalDeposits + totalDeposits * interest => totalDeposits = poolSize / (1 + interest)
   * @return The maximum size of the pool to be deposited into the money market
   */
  function maxPoolSizeFixedPoint24(int256 _maxValueFixedPoint24) public view returns (int256) {
    /// Double the interest rate in case it increases over the lock period.  Somewhat arbitrarily.
    int256 interestFraction = FixidityLib.multiply(currentInterestFractionFixedPoint24(), FixidityLib.newFixed(2));
    return FixidityLib.divide(_maxValueFixedPoint24, FixidityLib.add(interestFraction, FixidityLib.newFixed(1)));
  }

  /**
   * @notice Estimates the current effective interest rate using the money market&#39;s current supplyRateMantissa and the lock duration in blocks.
   * @return The current estimated effective interest rate
   */
  function currentInterestFractionFixedPoint24() public view returns (int256) {
    int256 blockDuration = int256(lockEndBlock - lockStartBlock);
    int256 supplyRateMantissaFixedPoint24 = FixidityLib.newFixed(int256(supplyRateMantissa()), uint8(18));
    return FixidityLib.multiply(supplyRateMantissaFixedPoint24, FixidityLib.newFixed(blockDuration));
  }

  /**
   * @notice Extracts the supplyRateMantissa value from the money market contract
   * @return The money market supply rate per block
   */
  function supplyRateMantissa() public view returns (uint256) {
    return moneyMarket.supplyRatePerBlock();
  }

  /**
   * @notice Determines whether a given address has bought tickets
   * @param _addr The given address
   * @return Returns true if the given address bought tickets, false otherwise.
   */
  function _hasEntry(address _addr) internal view returns (bool) {
    return entries[_addr].addr == _addr;
  }

  modifier requireOpen() {
    require(state == State.OPEN, "state is not open");
    _;
  }

  modifier requireLocked() {
    require(state == State.LOCKED, "state is not locked");
    _;
  }

  modifier requireComplete() {
    require(state == State.COMPLETE, "pool is not complete");
    require(block.number > lockEndBlock, "block is before lock end period");
    _;
  }
}



/**
 * @title The Pool Manager contract for PoolTogether.
 * @author Brendan Asselstine
 * @notice Creates Pools and ensures that there is only one active Pool at a time.
 */
contract PoolManager is Ownable {
  using SafeMath for uint256;

  /**
   * Emitted when a new Pool is created.
   * @param pool The address of the new Pool contract
   * @param number The index of the pool
   */
  event PoolCreated(address indexed pool, uint256 indexed number);

  /**
   * Emitted when the open duration is changed.
   * @param durationInBlocks The new duration in blocks
   */
  event OpenDurationChanged(uint256 durationInBlocks);

  /**
   * Emitted when the lock duration is changed.
   * @param durationInBlocks The new duration in blocks
   */
  event LockDurationChanged(uint256 durationInBlocks);

  /**
   * Emitted when the ticket price is changed
   * @param ticketPrice The ticket price
   */
  event TicketPriceChanged(int256 ticketPrice);

  /**
   * Emitted when the fee fraction is changed
   * @param feeFractionFixedPoint18 The new fee fraction encoded as a fixed point 18 decimal
   */
  event FeeFractionChanged(int256 feeFractionFixedPoint18);

  /**
   * Emitted when the allow lock anytime is changed
   * @param allowLockAnytime The value of allow lock anytime
   */
  event AllowLockAnytimeChanged(bool allowLockAnytime);

  /**
   * The Compound cToken to supply and withdraw from
   */
  ICErc20 public moneyMarket;

  /**
   * The token to use for the moneyMarket
   */
  IERC20 public token;

  /**
   * The currently active Pool
   */
  Pool public currentPool;

  /**
   * The open duration in blocks to use for the next Pool
   */
  uint256 public openDurationInBlocks;

  /**
   * The lock duration in blocks to use for the next Pool
   */
  uint256 public lockDurationInBlocks;

  /**
   * The ticket price in tokens to use for the next Pool
   */
  int256 public ticketPrice;

  /**
   * The owner fee fraction to use for the next Pool
   */
  int256 private feeFractionFixedPoint18;

  /**
   * The number of Pools that have been created
   */
  uint256 public poolCount;

  /**
   * Whether to allow the owner of the next Pool to lock and unlock at anytime.
   */
  bool public allowLockAnytime;

  /**
   * @notice Initializes a new PoolManager contract.  Generally called through ZeppelinOS
   * @param _owner The owner of the PoolManager.  They are able to change settings and are set as the owner of new lotteries.
   * @param _moneyMarket The Compound Finance MoneyMarket contract to supply and withdraw tokens.
   * @param _token The token to use for the Pools
   * @param _openDurationInBlocks The duration between a Pool&#39;s creation and when it can be locked.
   * @param _lockDurationInBlocks The duration that a Pool must be locked for.
   * @param _ticketPrice The price that tickets should sell for
   * @param _feeFractionFixedPoint18 The fraction of the gross winnings that should be transferred to the owner as the fee.  Is a fixed point 18 number.
   * @param _allowLockAnytime Whether the owner can lock and unlock the pools at any time.
   */
  function init (
    address _owner,
    address _moneyMarket,
    address _token,
    uint256 _openDurationInBlocks,
    uint256 _lockDurationInBlocks,
    int256 _ticketPrice,
    int256 _feeFractionFixedPoint18,
    bool _allowLockAnytime
  ) public initializer {
    require(_owner != address(0), "owner cannot be the null address");
    require(_moneyMarket != address(0), "money market address is zero");
    require(_token != address(0), "token address is zero");
    Ownable.initialize(_owner);
    token = IERC20(_token);
    moneyMarket = ICErc20(_moneyMarket);

    require(_token == moneyMarket.underlying(), "token does not match the underlying money market token");

    _setFeeFraction(_feeFractionFixedPoint18);
    _setLockDuration(_lockDurationInBlocks);
    _setOpenDuration(_openDurationInBlocks);
    _setTicketPrice(_ticketPrice);
    _setAllowLockAnytime(_allowLockAnytime);
  }

  /**
   * @notice Returns information about the PoolManager
   * @return A tuple containing:
   *    _currentPool (the address of the current pool),
   *    _openDurationInBlocks (the open duration in blocks to use for the next pool),
   *    _lockDurationInBlocks (the lock duration in blocks to use for the next pool),
   *    _ticketPrice (the ticket price in DAI for the next pool),
   *    _feeFractionFixedPoint18 (the fee fraction for the next pool),
   *    _poolCount (the number of pools that have been created)
   */
  function getInfo() public view returns (
    address _currentPool,
    uint256 _openDurationInBlocks,
    uint256 _lockDurationInBlocks,
    int256 _ticketPrice,
    int256 _feeFractionFixedPoint18,
    uint256 _poolCount
  ) {
    return (
      address(currentPool),
      openDurationInBlocks,
      lockDurationInBlocks,
      ticketPrice,
      feeFractionFixedPoint18,
      poolCount
    );
  }

  /**
   * @notice Creates a new Pool.  There can be no current pool, or the current pool must be complete.
   * Can only be called by the owner.
   * Fires the PoolCreated event.
   * @return The address of the new pool
   */
  function createPool() external onlyOwner returns (address) {
    bool canCreatePool = address(currentPool) == address(0) || currentPool.state() == Pool.State.COMPLETE;
    require(canCreatePool, "the last pool has not completed");
    currentPool = new Pool(
      moneyMarket,
      token,
      block.number + openDurationInBlocks,
      block.number + openDurationInBlocks + lockDurationInBlocks,
      ticketPrice,
      feeFractionFixedPoint18,
      allowLockAnytime
    );
    currentPool.initialize(owner());
    poolCount = poolCount.add(1);

    emit PoolCreated(address(currentPool), poolCount);

    return address(currentPool);
  }

  /**
   * @notice Sets the open duration in blocks for new Pools.
   * Fires the OpenDurationChanged event.
   * Can only be set by the owner.  Fires the OpenDurationChanged event.
   * @param _openDurationInBlocks The duration, in blocks, that a pool must be open for after it is created.
   */
  function setOpenDuration(uint256 _openDurationInBlocks) public onlyOwner {
    _setOpenDuration(_openDurationInBlocks);
  }

  function _setOpenDuration(uint256 _openDurationInBlocks) internal {
    require(_openDurationInBlocks > 0, "open duration must be greater than zero");
    openDurationInBlocks = _openDurationInBlocks;

    emit OpenDurationChanged(_openDurationInBlocks);
  }

  /**
   * @notice Sets the lock duration in blocks for new Pools.
   * Fires the LockDurationChanged event.
   * Can only be set by the owner.  Only applies to subsequent Pools.
   * @param _lockDurationInBlocks The duration, in blocks, that new pools must be locked for.
   */
  function setLockDuration(uint256 _lockDurationInBlocks) public onlyOwner {
    _setLockDuration(_lockDurationInBlocks);
  }

  function _setLockDuration(uint256 _lockDurationInBlocks) internal {
    require(_lockDurationInBlocks > 0, "bond duration must be greater than zero");
    lockDurationInBlocks = _lockDurationInBlocks;

    emit LockDurationChanged(_lockDurationInBlocks);
  }

  /**
   * @notice Sets the ticket price in DAI.
   * Fires the TicketPriceChanged event.
   * Can only be called by the owner.  Only applies to subsequent Pools.
   * @param _ticketPrice The new price for tickets.
   */
  function setTicketPrice(int256 _ticketPrice) public onlyOwner {
    _setTicketPrice(_ticketPrice);
  }

  function _setTicketPrice(int256 _ticketPrice) internal {
    require(_ticketPrice > 0, "ticket price must be greater than zero");
    ticketPrice = _ticketPrice;

    emit TicketPriceChanged(_ticketPrice);
  }

  /**
   * @notice Sets the fee fraction paid out to the Pool owner.
   * Fires the FeeFractionChanged event.
   * Can only be called by the owner. Only applies to subsequent Pools.
   * @param _feeFractionFixedPoint18 The fraction to pay out.
   * Must be between 0 and 1 and formatted as a fixed point number with 18 decimals (as in Ether).
   */
  function setFeeFraction(int256 _feeFractionFixedPoint18) public onlyOwner {
    _setFeeFraction(_feeFractionFixedPoint18);
  }

  function _setFeeFraction(int256 _feeFractionFixedPoint18) internal {
    require(_feeFractionFixedPoint18 >= 0, "fee must be zero or greater");
    require(_feeFractionFixedPoint18 <= 1000000000000000000, "fee fraction must be 1 or less");
    feeFractionFixedPoint18 = _feeFractionFixedPoint18;

    emit FeeFractionChanged(_feeFractionFixedPoint18);
  }

  /**
   * @notice Allows the owner to set whether a Pool can be locked and unlocked at any time.
   * Fires the AllowLockAnytimeChanged event.
   * Can only be set by the owner.  Only applies to subsequent Pools.
   * @param _allowLockAnytime True if the Pool can be locked and unlocked anytime, false otherwise.
   */
  function setAllowLockAnytime(bool _allowLockAnytime) public onlyOwner {
    _setAllowLockAnytime(_allowLockAnytime);
  }

  function _setAllowLockAnytime(bool _allowLockAnytime) internal {
    allowLockAnytime = _allowLockAnytime;

    emit AllowLockAnytimeChanged(_allowLockAnytime);
  }
}