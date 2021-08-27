/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

import './Initializable.sol';
import './SafeMath.sol';

import './IERC20.sol';

// Copied and modified from https://github.com/aragon/govern/blob/develop/packages/govern-token/contracts/GovernToken.sol
// Token to be used on subDAOs for the AN DAO.
// Changes:
//   - Rename onlyMinter to onlyController for clarity
//   - Remove transfer method, so only the controller can transfer ownership (Main DAO, aka community)
//   - Allows controller to also burn tokens
//   - Removes transferWithAuthorization

contract CustomGovernToken is IERC20, Initializable {
    using SafeMath for uint256;

    // bytes32 private constant EIP712DOMAIN_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // bytes32 private constant VERSION_HASH = keccak256("1")
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    // bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
    //     keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)");
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH = 0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    string public name;
    string public symbol;
    uint8 public decimals;

    address public controller;
    uint256 override public totalSupply;
    mapping (address => uint256) override public balanceOf;
    mapping (address => mapping (address => uint256)) override public allowance;

    // ERC-2612, ERC-3009 state
    mapping (address => uint256) public nonces;
    mapping (address => mapping (bytes32 => bool)) public authorizationState;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
    event ChangeController(address indexed controller);

    modifier onlyController {
        require(msg.sender == controller, "token: not controller");
        _;
    }

    constructor(address _initialController, string memory _name, string memory _symbol, uint8 _decimals) public {
        initialize(_initialController, _name, _symbol, _decimals);
    }

    function initialize(address _initialController, string memory _name, string memory _symbol, uint8 _decimals) public onlyInit("token") {
        _changeController(_initialController);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function _validateSignedData(address signer, bytes32 encodeData, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                encodeData
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "token: bad sig");
    }

    function _changeController(address newController) internal {
        controller = newController;
        emit ChangeController(newController);
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
        require(to != address(this) && to != address(0), "token: bad to");

        // Balance is implicitly checked with SafeMath's underflow protection
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function getChainId() public pure returns (uint256 chainId) {
        assembly { chainId := chainid() }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_HASH,
                keccak256(abi.encodePacked(name)),
                VERSION_HASH,
                getChainId(),
                address(this)
            )
        );
    }

    function mint(address to, uint256 value) external onlyController returns (bool) {
        _mint(to, value);
        return true;
    }

    function changeController(address newController) external onlyController {
        _changeController(newController);
    }

    function burn(address target, uint256 value) external onlyController returns (bool) {
        _burn(target, value);
        return true;
    }

    function approve(address spender, uint256 value) override external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) override external onlyController returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) override external onlyController returns (bool) {
        uint256 fromAllowance = allowance[from][msg.sender];
        if (fromAllowance != uint256(-1)) {
            // Allowance is implicitly checked with SafeMath's underflow protection
            allowance[from][msg.sender] = fromAllowance.sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "token: auth expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

}