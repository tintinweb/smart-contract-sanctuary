pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}


/**
 * @title MultiBeneficiariesTokenTimelock
 * @dev MultiBeneficiariesTokenTimelock is a token holder contract that will allow a
 * beneficiaries to extract the tokens after a given release time
 */
contract MultiBeneficiariesTokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address[] public beneficiaries;

    // token amounts of beneficiaries to be released
    uint256[] public tokenValues;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    constructor(
        ERC20Basic _token,
        address[] _beneficiaries,
        uint256[] _tokenValues,
        uint256 _releaseTime
    )
    public
    {
        require(_releaseTime > block.timestamp);
        releaseTime = _releaseTime;
        require(_beneficiaries.length == _tokenValues.length);
        beneficiaries = _beneficiaries;
        tokenValues = _tokenValues;
        token = _token;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiaries.
     */
    function release() public {
        require(block.timestamp >= releaseTime);

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            uint256 amount = tokenValues[i];
            require(amount > 0);
            token.safeTransfer(beneficiary, amount);
        }
    }
}