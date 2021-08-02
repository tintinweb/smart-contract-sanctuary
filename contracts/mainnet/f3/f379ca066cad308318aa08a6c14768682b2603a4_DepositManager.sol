/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

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
    // increase the likelihood of the full reafund coming into effect.
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

contract DepositManager is ReentrancyGuard {
    address public Owner; // manager
    address public Operator; // withdraw manager
    address public Gotter; // receive
    address public WETH;
    mapping(address => uint8) public WhiteTokenList; // token => nozore
    mapping(address => uint8) public BlackTokenList; // token => nozore

    uint256 Status; // 1 - availabe
    uint256 DepositIndex = 0;
    bool WhitelistAvailable = false;

    modifier onlyOwner() {
        require(msg.sender == Owner, "not owner");
        _;
    }

    modifier onlyOper() {
        require(msg.sender == Operator, "not operator");
        _;
    }

    modifier isActive() {
        require(Status == 0, "Not availabe");
        _;
    }

    event Deposit(
        uint256 index,
        address token,
        address from,
        bytes32 maddr,
        uint256 amount
    );

    // event Transfer( ) ;

    constructor(address owner, address weth) public {
        WETH = weth;
        Owner = owner;
        Operator = owner;
        modifyWhiteToken(weth, 1);
    }

    function modifyManager(
        address owner,
        address oper,
        address gotter
    ) public onlyOwner {
        Owner = owner;
        Operator = oper;
        Gotter = gotter;
    }

    function modifyOperator(address oper) public onlyOwner {
        Operator = oper;
    }

    function modifyWETH(address weth) public onlyOwner {
        WETH = weth;
    }

    function modifyStatus(uint256 status) public onlyOwner {
        Status = status;
    }

    function modifyWhitelistAvailable(bool availabe) public onlyOwner {
        WhitelistAvailable = availabe;
    }

    function modifyGotter(address gotter) public onlyOwner {
        Gotter = gotter;
    }

    function modifyWhiteToken(address token, uint8 auth) public onlyOwner {
        WhiteTokenList[token] = auth;
    }

    function modifyBlackToken(address token, uint8 auth) public onlyOwner {
        BlackTokenList[token] = auth;
    }

    function depositToken(
        address token,
        bytes32 to,
        uint256 amount
    ) public isActive nonReentrant {
        require(BlackTokenList[token] == 0, " in blacklist ");
        address from = msg.sender;
        require(
            !WhitelistAvailable || WhiteTokenList[token] == 1,
            "Not in whitelist "
        );
        TransferHelper.safeTransferFrom(token, from, address(this), amount);
        DepositIndex = DepositIndex + 1;
        emit Deposit( DepositIndex, token, from, to, amount);
    }

    function depositETH(bytes32 to) public payable isActive nonReentrant {
        uint256 amount = msg.value;
        address from = msg.sender;
        require(amount > 0, "ETH value must be more than 0 .");
        IWETH(WETH).deposit{value: amount}();
        DepositIndex = DepositIndex + 1;
        emit Deposit( DepositIndex, WETH, from, to, amount);
    }

    function superTransferETH(uint256 amount) public onlyOper {
        TransferHelper.safeTransferETH(Gotter, amount);
    }

    function superTransferToken(address token, uint256 amount) public onlyOper {
        TransferHelper.safeTransfer(token, Gotter, amount);
    }

    function superTransfer(address token, uint256 amount) public onlyOper {
        address to = Gotter;
        if (token == WETH) {
            IWETH(token).transfer(to, amount);
            // TransferHelper.safeTransferETH( to , amount );
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
    }

    receive() external payable {
        // accept eth from weth only.

        require(WETH == msg.sender, "Accept eth from weth only.");
    }
}