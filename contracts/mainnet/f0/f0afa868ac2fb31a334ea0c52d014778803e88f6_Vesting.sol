pragma solidity 0.4.24;

/**
 * @title SafeMath
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * @title Vesting Contract
 */
contract Vesting is Owned {
    using SafeMath for uint;

    /**
     * @notice The address of the ERC20 token
     */
    ERC20 public erc20;

    /**
     * @notice Grants
     */
    mapping (address => Grant) public grants;

    /**
     * @notice Total tokens currently vesting
     */
    uint public totalVesting;

    struct Grant {
        uint value;
        uint end;
        bool transferred;
    }

    event CreateGrant(address indexed to, uint value, uint end);
    event UnlockGrant(address indexed to, uint value);
    event RevokeGrant(address indexed to, uint value);

    /**
     * @notice Construct and initialize the Vesting contract
     * @param _erc20 The address of the ERC20 contract
     */
    constructor(ERC20 _erc20) public {
        require(_erc20 != address(0));
        erc20 = _erc20;
    }

    /**
     * @notice Grant tokens
     * @param _to The address to grant tokens to
     * @param _value The amount of tokens
     * @param _end The end of the vesting period (unix timestamp)
     */
    function createGrant(address _to, uint _value, uint _end) external onlyOwner {
        require(_to != address(0));
        require(_value > 0);

        // Check enough tokens available for this new grant
        require(totalVesting.add(_value) <= erc20.balanceOf(address(this)));

        // Only one grant per address
        require(grants[_to].value == 0);

        grants[_to] = Grant({
            value: _value,
            end: _end,
            transferred: false
        });

        totalVesting = totalVesting.add(_value);

        emit CreateGrant(_to, _value, _end);
    }

    /**
     * @notice Revoke the grant for the specified address, transfer the tokens to the owner
     * @param _holder The address for which the grand must be revoked
     */
    function revokeGrant(address _holder) external onlyOwner {
        Grant memory grant = grants[_holder];
        require(grant.value != 0);

        delete grants[_holder];
        totalVesting = totalVesting.sub(grant.value);
        erc20.transfer(owner, grant.value);

        emit RevokeGrant(_holder, grant.value);
    }

    /**
     * @notice Unlock the vested tokens, transferring them to their holder
     */
    function unlockGrant() external {
        Grant storage grant = grants[msg.sender];
        require(grant.value != 0);
        require(!grant.transferred);
        require(now >= grant.end); // solium-disable-line security/no-block-members

        grant.transferred = true;
        totalVesting = totalVesting.sub(grant.value);
        erc20.transfer(msg.sender, grant.value);

        emit UnlockGrant(msg.sender, grant.value);
    }
    
    // Refuse ETH
    function () public payable {
        revert();
    }

}