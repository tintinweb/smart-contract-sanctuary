/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.8.2;


interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Boss is Context {

    address public boss;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyBoss() {
        require(boss == _msgSender(), "Ownable: caller is not the boss");
        _;
    }

}


contract withdrawUSDT is Boss {
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor (address bossaddress) {
        boss = bossaddress;
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function currentbalanceOf() public view returns (uint256) {
        uint256 amount = IERC20(USDT).balanceOf(address(this));
        return amount;
    }

    function withdraw(address to) public onlyBoss returns (bool) {
        safeTransfer(USDT,to,currentbalanceOf());
    }

}