/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

import './Initializable.sol';
import './SafeMath.sol';

// Copied and modified from https://github.com/aragon/govern/blob/develop/packages/govern-token/contracts/GovernToken.sol
// Token to be used on subDAOs for the AN DAO.
// Changes:
//   - Rename onlyMinter to onlyController for clarity
//   - Only the controller can transfer ownership (Main DAO, aka community)
//   - Allows controller to also burn tokens
//   - No longer required methods removed

contract CustomGovernToken is Initializable {
    using SafeMath for uint256;

    // bytes32 private constant EIP712DOMAIN_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // bytes32 private constant VERSION_HASH = keccak256("1")
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    string public name;
    string public symbol;
    uint8 public decimals;

    address public controller;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
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

    function transferFrom(address from, address to, uint256 value) external onlyController returns (bool) {
        _transfer(from, to, value);
        return true;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity 0.6.8;

contract Initializable {
    mapping (string => uint256) public initBlocks;

    event Initialized(string indexed key);

    modifier onlyInit(string memory key) {
        require(initBlocks[key] == 0, "initializable: already initialized");
        initBlocks[key] = block.number;
        _;
        emit Initialized(key);
    }
}

/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity ^0.6.8;

// A library for performing overflow-safe math, courtesy of DappHub: https://github.com/dapphub/ds-math/blob/d0ef6d6a5f/src/math.sol
// Modified to include only the essentials
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math: overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "math: underflow");
    }
}