// File: contracts/interfaces/ApproveAndCallReceiver.sol

pragma solidity ^0.5.17;


interface ApproveAndCallReceiver {
    /**
    * @dev This allows users to use their tokens to interact with contracts in one function call instead of two
    * @param _from Address of the account transferring the tokens
    * @param _amount The amount of tokens approved for in the transfer
    * @param _token Address of the token contract calling this function
    * @param _data Optional data that can be used to add signalling information in more complex staking applications
    */
    function receiveApproval(address _from, uint256 _amount, address _token, bytes calldata _data) external;
}

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.5.17;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.5.17;


// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "MATH:ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "MATH:SUB_UNDERFLOW");
    }
}

// File: contracts/ANTv2.sol

pragma solidity 0.5.17;




// Lightweight token modelled after UNI-LP: https://github.com/Uniswap/uniswap-v2-core/blob/v1.0.1/contracts/UniswapV2ERC20.sol
// Adds:
//   - An exposed `mint()` with minting role
//   - An exposed `burn()`
//   - ERC-3009 (`transferWithAuthorization()`)
contract ANTv2 is IERC20 {
    using SafeMath for uint256;

    string public constant name = "Aragon Network Token";
    string public constant symbol = "ANT";
    uint8 public constant decimals = 18;

    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    //     keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    address public minter;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // ERC-712, ERC-2612, ERC-3009 state
    bytes32 public DOMAIN_SEPARATOR;
    mapping (address => uint256) public nonces;
    mapping (address => mapping (bytes32 => bool)) public authorizationState;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event ChangeMinter(address indexed minter);

    modifier onlyMinter {
        require(msg.sender == minter, "ANTV2:NOT_MINTER");
        _;
    }

    constructor(uint256 chainId, address initialMinter) public {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );

        _changeMinter(initialMinter);
    }

    function _validateSignedData(address signer, bytes32 encodedData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                encodedData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "ANTV2:INVALID_SIGNATURE");
    }

    function _changeMinter(address newMinter) internal {
        minter = newMinter;
        emit ChangeMinter(newMinter);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        require(to != address(this), "ANTV2:RECEIVER_IS_TOKEN");

        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function mint(address to, uint256 value) external onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }

    function changeMinter(address newMinter) external onlyMinter {
        _changeMinter(newMinter);
    }

    function burn(uint256 value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 fromAllowance = allowance[from][msg.sender];
        if (fromAllowance != uint256(-1)) {
            // Allowance is implicitly checked with SafeMath's underflow protection
            allowance[from][msg.sender] = fromAllowance.sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "ANTV2:AUTH_EXPIRED");

        bytes32 encodedData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodedData, v, r, s);

        _approve(owner, spender, value);
    }

    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(block.timestamp > validAfter, "ANTV2:AUTH_NOT_YET_VALID");
        require(block.timestamp < validBefore, "ANTV2:AUTH_EXPIRED");
        require(!authorizationState[from][nonce],  "ANTV2:AUTH_ALREADY_USED");

        bytes32 encodedData = keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        _validateSignedData(from, encodedData, v, r, s);

        authorizationState[from][nonce] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }
}

// File: contracts/ANTv2Migrator.sol

pragma solidity 0.5.17;





contract ANTv2Migrator is ApproveAndCallReceiver {
    string private constant ERROR_NOT_INITATOR = "ANTV2_MIG:NOT_INITIATOR";
    string private constant ERROR_WRONG_TOKEN = "ANTV2_MIG:WRONG_TOKEN";
    string private constant ERROR_ZERO_AMOUNT = "ANTV2_MIG:ZERO_AMOUNT";
    string private constant ERROR_TRANSFER_FAILED = "ANTV2_MIG:TRANSFER_FAIL";

    address private constant BURNED_ADDR = 0x000000000000000000000000000000000000dEaD;

    address public owner;
    IERC20 public antv1;
    ANTv2 public antv2;

    constructor(address _owner, IERC20 _antv1, ANTv2 _antv2) public {
        owner = _owner;
        antv1 = _antv1;
        antv2 = _antv2;
    }

    function initiate() external {
        require(msg.sender == owner, ERROR_NOT_INITATOR);

        // Mint an equal supply of ANTv2 as ANTv1 to this migration contract
        uint256 antv1Supply = antv1.totalSupply();
        antv2.mint(address(this), antv1Supply);

        // Transfer ANTv2 minting role to owner
        antv2.changeMinter(owner);
    }

    function migrate(uint256 _amount) external {
        _migrate(msg.sender, _amount);
    }

    function migrateAll() external {
        uint256 amount = antv1.balanceOf(msg.sender);
        _migrate(msg.sender, amount);
    }

    function receiveApproval(address _from, uint256 _amount, address _token, bytes calldata /*_data*/) external {
        require(_token == msg.sender && _token == address(antv1), ERROR_WRONG_TOKEN);

        uint256 fromBalance = antv1.balanceOf(_from);
        uint256 migrationAmount = _amount > fromBalance ? fromBalance : _amount;

        _migrate(_from, migrationAmount);
    }

    function _migrate(address _from, uint256 _amount) private {
        require(_amount > 0, ERROR_ZERO_AMOUNT);

        // Burn ANTv1
        require(antv1.transferFrom(_from, BURNED_ADDR, _amount), ERROR_TRANSFER_FAILED);
        // Return ANTv2
        require(antv2.transfer(_from, _amount), ERROR_TRANSFER_FAILED);
    }
}