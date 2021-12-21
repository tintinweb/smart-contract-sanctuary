/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint a, uint b) internal pure returns (uint ) {
        return a / b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract BridgeFrom is Ownable {
    using SafeMath for uint256;

    address public dev_adr;
    uint256 public cut;

    event Deposit(address indexed token,address indexed from, uint256 _amount);
    event Withdrawal(address indexed token, address indexed to, uint256 _amount);

    constructor(address _adr, uint256 _cut) public {
        dev_adr = _adr;
        cut = _cut;
    }

    //will trigger mint on other chain
    function deposit(address token, uint256 _amount) public {
        uint256 dev_cut = _amount.mul(cut).div(10000);
        IERC20(token).transferFrom(msg.sender, dev_adr, dev_cut);
        IERC20(token).transferFrom(msg.sender, address(this), _amount.sub(dev_cut));
        emit Deposit(token, msg.sender, _amount.sub(dev_cut));
    }

    function depositPermit(address token, uint256 _amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        IERC20Permit(token).permit(msg.sender, address(this), _amount, deadline, v, r, s);
        uint256 dev_cut = _amount.mul(cut).div(10000);
        IERC20(token).transferFrom(msg.sender, dev_adr, dev_cut);
        IERC20(token).transferFrom(msg.sender, address(this), _amount.sub(dev_cut));
        emit Deposit(token, msg.sender, _amount.sub(dev_cut));
    }

    //trigger by burn on other chain
    function withdrawal(address token, uint256 _amount, address to) public onlyOwner {
        uint256 dev_cut = _amount.mul(cut).div(10000);
        IERC20(token).transfer(dev_adr, dev_cut );
        IERC20(token).transfer(to, _amount.sub(dev_cut) );
        emit Withdrawal(token, to, _amount.sub(dev_cut));
    }

    function setCut(uint256 amount) public onlyOwner {
        cut = amount;
    }

    function setDev(address newDev) public {
        require(msg.sender == dev_adr, "dev: wut?");
        dev_adr = newDev;
    }

}