// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IERC20.sol";

contract BeinBuildERC20Bridge is Context {

    // transfer erc20 (original) to another chain
    event Lock(address sourceERC20, address destERC20, address receiverAddress, uint256 value);

    // transfer erc20 (not original) to another chain
    event Burn(address sourceERC20, address destERC20, address receiverAddress, uint256 value);

    event Unlock(address destERC20, address receiverAddress, uint256 value);
    event Mint(address destERC20, address receiverAddress, uint256 value);

    address public admin;   

    // bridgeDirection is "BSC TO BIC" OR "BIC TO BSC"
    // it depends on which chain this smart contract is lying on
    string public bridgeDirection;

    // Mapping from erc20 contract address on source chain to erc20 contract address on dest chain
    mapping (address => address) public addressMap;

    mapping (address => bool) public isOriginal;

    constructor(string memory _bridgeDirection) {
        admin = _msgSender();
        bridgeDirection = _bridgeDirection;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin, "restrict to admin");
        _;
    }

    function grantAdminRole(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function buildOneWayBridge(
        address _sourceERC20, 
        address _destERC20, 
        bool _toOriginal
    ) public onlyAdmin {
        require(addressMap[_sourceERC20] == address(0), "bridge existed");
        isOriginal[_sourceERC20] = !_toOriginal;
        addressMap[_sourceERC20] = _destERC20;
    }

    // transfer erc20 from one chain to another chain by:
    // locking token () when erc20 is original on current chain
    // or burning token when erc20 is original on another chain
    function transferToOtherChain(
        address _sourceERC20, 
        address _receiverAddress, 
        uint256 _value
    ) public { 
        require(addressMap[_sourceERC20] != address(0), "bridge is not existed");
        require(_receiverAddress != address(0), "can not transfer to address 0");

        if (isOriginal[_sourceERC20]) {
            IERC20(_sourceERC20).transfer(admin, _value);
            emit Lock(_sourceERC20, addressMap[_sourceERC20], _receiverAddress, _value);
        } else {
            IERC20(_sourceERC20).burn(_sourceERC20, _value);
            emit Burn(_sourceERC20, addressMap[_sourceERC20], _receiverAddress, _value);
        }
    }

    // bridger handles the 
    // function handleOnDestChain(
    //     address _destERC20, 
    //     address _receiverAddress, 
    //     uint256 _value
    // ) public onlyAdmin {
    //     if (isOriginal[_destERC20]) {
    //         (bool success, bytes memory data) = _destERC20.call(
    //             abi.encodeWithSignature("transfer(address,uint256)", _receiverAddress, _value)
    //         );
    //         emit Response(success, data);
    //         require(success, "fail when bridger handles tx on dest chain");
    //         emit Unlock(_destERC20, _receiverAddress, _value);
    //     } else {
    //         (bool success, bytes memory data) = _destERC20.call(
    //             abi.encodeWithSignature("mint(address,uint256)", _receiverAddress, _value)
    //         );
    //         emit Response(success, data);
    //         require(success, "fail when bridger handles tx on dest chain");
    //         emit Mint(_destERC20, _receiverAddress, _value);
    //     }
    // } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

