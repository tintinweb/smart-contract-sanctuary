/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract PaymentManager is ReentrancyGuard {
    address public Owner;
    address public Operator;

    address public WETH;

    uint256 public Start;

    mapping(uint256 => uint8) public Indices;

    modifier onlyOwner() {
        require(msg.sender == Owner, "not owner");
        _;
    }

    modifier onlyOper() {
        require(msg.sender == Operator, "not operator");
        _;
    }

    event Payout(
        // bool flag,
        uint256 index,
        address token,
        address from,
        bytes32 maddr,
        uint256 amount,
        address to
    );

    constructor(
        address owner,
        address weth,
        uint256 start
    ) public {
        Owner = owner;
        WETH = weth;
        Operator = owner;
        Start = start;
    }

    function modifyOperator(address oper) public onlyOwner {
        Operator = oper;
    }

    function modifyWETH(address weth) public onlyOwner {
        WETH = weth;
    }

    function superTransferETH(
        uint256 index,
        bytes32 maddr,
        address to,
        uint256 amount
    ) public onlyOper {
        require(index > Start, "index to low");
        require(Indices[index] == 0, "index already exist");
        TransferHelper.safeTransferETH(to, amount);
        Indices[index] = 1;
        emit Payout( index, WETH, address(this), maddr, amount, to);
    }

    function superTransfer(
        uint256 index,
        bytes32 maddr,
        address token,
        address to,
        uint256 amount
    ) public onlyOper {
        require(index > Start, "index to low");
        require(Indices[index] == 0, "index already exist");
        if (token == WETH) {
            //IWETH( token ).transfer(to,amount ) ;
            IWETH(token).withdraw(amount);
            superTransferETH(index, maddr, to, amount);
        } else {
            superTransferToken(index, maddr, token, to, amount);
        }
    }

    function superTransferToken(
        uint256 index,
        bytes32 maddr,
        address token,
        address to,
        uint256 amount
    ) public onlyOper {
        require(index > Start, "index to low");
        require(Indices[index] == 0, "index already exist");
        TransferHelper.safeTransfer(token, to, amount);
        Indices[index] = 1;
        emit Payout( index, token, address(this), maddr, amount, to);
    }

    function isExistIndex(uint256 index) public view returns (bool) {
        return Indices[index] == 1;
    }

    receive() external payable {
        require(WETH == msg.sender, "Accept eth from weth only.");
        //    uint amount = msg.value ;
        //    require( amount > 0 , "ETH value must be more than 0 .");
    }
}