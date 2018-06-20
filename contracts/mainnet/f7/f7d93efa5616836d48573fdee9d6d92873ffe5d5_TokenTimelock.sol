pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
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
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary = 0x2F1C2Fb4cf9b46172D59d8878Fc795277b8a2c9a;

    // timestamp when token release is enabled
    uint256 public firstTime = 1529942400;         //2018-06-26
    uint256 public secondTime = 1532534400;        //2018-07-26
    uint256 public thirdTime = 1535212800;         //2018-08-26

    uint256 public firstPay = 900000000000000000000000000;    //900 million  FTI
    uint256 public secondPay = 900000000000000000000000000;    //900 million  FTI
    uint256 public thirdPay = 600000000000000000000000000;    //900 million  FTI

    constructor(
            ERC20Basic _token
            )
        public
        {
            token = _token;
        }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        uint256 tmpPay = 0;
        if(block.timestamp >= firstTime && firstPay > 0){
            tmpPay = firstPay;
            firstPay = 0;
        }else if(block.timestamp >= secondTime && secondPay > 0 ){
            tmpPay = secondPay;
            secondPay = 0;
        }else if (block.timestamp >= thirdTime && thirdPay > 0) {
            tmpPay = token.balanceOf(this);
            thirdPay = 0;
        }
        require(tmpPay > 0);
        uint256 amount = token.balanceOf(this);
        require(amount >= tmpPay);
        token.safeTransfer(beneficiary, tmpPay);
    }
}