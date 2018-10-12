pragma solidity 0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}


/**
 * @title Photochain token vesting period contract
 *
 * @dev PhotochainVesting is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 * @dev Based on https://github.com/OpenZeppelin/zeppelin-solidity
 */
contract PhotochainVesting {
    // ERC20 token contract being held
    ERC20 public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    constructor(ERC20 _token, address _beneficiary, uint256 _releaseTime) public {
        // solium-disable-next-line security/no-block-members
        require(_releaseTime > block.timestamp, "Release time must be in future");

        // solium-disable-next-line security/no-block-members
        require(_releaseTime < block.timestamp + 3 * 365 days, "Release time must not exceed 3 years");

        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= releaseTime, "Release time must pass");

        uint256 amount = token.balanceOf(address(this));
        require(amount > 0, "Contract must hold any tokens");

        require(token.transfer(beneficiary, amount), "Transfer must succeed");
    }
}