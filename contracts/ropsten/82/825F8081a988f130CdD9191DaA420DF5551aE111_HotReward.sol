pragma solidity 0.4.24;
/** @dev Math operations with safety checks that revert on error */
library SafeMath {

    /** @dev Multiplies two numbers, reverts on overflow. */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    /** @dev Integer division of two numbers truncating the quotient, reverts on division by zero. */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        uint256 c = a / b;
        return c;
    }

    /** @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend). */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        uint256 c = a - b;
        return c;
    }

    /** @dev Adds two numbers, reverts on overflow. */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    /** @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero. */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MOD_ERROR");
        return a % b;
    }
}

contract Erc20Token {

    /** @return total amount of tokens */
    function totalSupply() public pure returns (uint) {}

    /** @param _owner The address from which the balance will be retrieved
      * @return The balance
      */
    function balanceOf(address _owner) public view returns (uint);

    /** @notice send `_value` token to `_to` from `msg.sender`
      * @param _to The address of the recipient
      * @param _value The amount of token to be transferred
      * @return Whether the transfer was successful or not
      */
    function transfer(address _to, uint _value) public returns (bool success);

    /** @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
      * @param _from The address of the sender
      * @param _to The address of the recipient
      * @param _value The amount of token to be transferred
      * @return Whether the transfer was successful or not
      */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    /** @notice `msg.sender` approves `_addr` to spend `_value` tokens
      * @param _spender The address of the account able to transfer the tokens
      * @param _value The amount of wei to be approved for transfer
      * @return Whether the approval was successful or not
      */
    function approve(address _spender, uint _value) public returns (bool success);

    /** @param _owner The address of the account owning tokens
      * @param _spender The address of the account able to transfer the tokens
      * @return Amount of remaining tokens allowed to spent
      */
    function allowance(address _owner, address _spender) public view returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract LibOwnable {
    address private _owner;

    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
    * @return the address of the owner.
    */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns(bool) {
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
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract LibWhitelist is LibOwnable {
    mapping (address => bool) public whitelist;
    address[] public allAddresses;

    event AddressAdded(
        address indexed adr
    );

    event AddressRemoved(
        address indexed adr
    );

    /** @dev Only address in whitelist can invoke functions with this modifier. */
    modifier onlyAddressInWhitelist {
        require(whitelist[msg.sender], "SENDER_NOT_IN_WHITELIST");
        _;
    }

    /** @dev add Address into whitelist
      * @param adr Address to add
      */
    function addAddress(address adr) external onlyOwner {
        emit AddressAdded(adr);
        whitelist[adr] = true;
        allAddresses.push(adr);
    }

    /** @dev remove Address from whitelist
      * @param adr Address to remove
      */
    function removeAddress(address adr) external onlyOwner {
        emit AddressRemoved(adr);
        delete whitelist[adr];
        for(uint i = 0; i < allAddresses.length; i++){
            if(allAddresses[i] == adr) {
                allAddresses[i] = allAddresses[allAddresses.length - 1];
                allAddresses.length -= 1;
                break;
            }
        }
    }

    /** @dev Get all addresses in whitelist  */
    function getAllAddresses() external view returns (address[] memory) {
        return allAddresses;
    }
}

contract HotReward is LibWhitelist {
    using SafeMath for uint256;

    uint256 public hotPrice = 1;
    address public constant HotTokenAddress = 0x958113Ee9Def5ACa1698E1f5C4d7E9eB50Ff6f4F;

    function updateHotPrice(uint256 price) public onlyOwner {
        hotPrice = price;
    }

    function reward(address to, uint256 gasCost) external onlyAddressInWhitelist {
        // Erc20Token(HotTokenAddress).transfer(to, amount);
        address hotTokenAddress = HotTokenAddress;
        uint256 amount = gasCost;
        address selfAddress = address(this);

        assembly {
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(32)

            /* call ERC20 Token contract balanceOf function */
            mstore(0, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(4, selfAddress)

            let result := call(gas, hotTokenAddress, 0, 0, 36, 0, 32)
            result := mload(0)

            if lt(result, amount) {
                mstore(0, tmp1)
                mstore(4, tmp2)
                mstore(32, tmp3)
                return(0, 0)
            }

            /* Identifier of transfer function
             * keccak256(&#39;transfer(address,uint256)&#39;) & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
             */
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to)
            mstore(36, amount)
            /* call ERC20 Token contract transferFrom function */
            result := call(gas, hotTokenAddress, 0, 0, 68, 0, 32)

            if and(eq(result, 1), eq(mload(0), 1)) {
                mstore(0, tmp1)
                mstore(4, tmp2)
                mstore(32, tmp3)
                return(0, 0)
            }
        }

        revert("REWARD_ERROR");
    }
}