/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: node_modules\@openzeppelin\contracts\utils\Context.sol



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts\Privilege.sol


pragma solidity ^0.8.0;


contract Privilege is Ownable {
    uint16 public feeRate = 0;
    uint256 public feeFixed = 0;
    uint256 public currentDay = 0;

    mapping(address => PrivilegeAccountStruct) public privilegeAccountMap;

    struct PrivilegeAccountStruct {
        bool isState;
        uint256 dayMoney;
        uint256 dayMoneyLimit;
        uint256 totalMoney;
    }

    constructor() {
        privilegeAccountMap[owner()] = PrivilegeAccountStruct({
            isState: true,
            dayMoney: 1000000000000000000000,
            dayMoneyLimit: 1000000000000000000000,
            totalMoney: 10000000000000000000000
        });
    }

    modifier onlyPrivilegeAccount() {
        require(
            privilegeAccountMap[msg.sender].isState == true,
            "You have no privilege"
        );
        _;
    }
    function limitMoneyPrivilegeAccount(uint256 tradeMoney) internal{
        PrivilegeAccountStruct memory privilegeAccountStruct = privilegeAccountMap[msg.sender];
        if(block.timestamp/86400 > currentDay){
            currentDay = block.timestamp/86400;
            privilegeAccountStruct.dayMoney = privilegeAccountStruct.dayMoneyLimit;
        }
        require(
            privilegeAccountStruct.dayMoney >= tradeMoney,
            "The quota is exceeded on the day"
        );
        require(
            privilegeAccountStruct.totalMoney >= tradeMoney,
            "The total quota exceeds the limit"
        );
        privilegeAccountStruct.dayMoney -= tradeMoney;
        privilegeAccountStruct.totalMoney -= tradeMoney;
        privilegeAccountMap[msg.sender] = privilegeAccountStruct;
    }

    function setPrivilegeAccount(address addr,uint256 dayMoneyLimit,uint256 totalMoney) external onlyOwner(){
        require(addr != address(0), "The addr cannot be empty");
        privilegeAccountMap[addr].isState = true;
        privilegeAccountMap[addr].dayMoney = dayMoneyLimit;
        privilegeAccountMap[addr].dayMoneyLimit = dayMoneyLimit;
        privilegeAccountMap[addr].totalMoney = totalMoney;
    }

    function removePrivilegeAccount(address addr) external onlyOwner(){
        require(addr != address(0), "The addr cannot be empty");
        privilegeAccountMap[addr].isState = false;
    }

    function setFeeRate(uint16 _feeRate) external onlyOwner() returns (bool) {
        require(_feeRate <= 10000, "Maximum setting 10000");
        feeRate = _feeRate;
        return true;
    }

    function setFeeFixed(uint256 _feeFixed)
        external
        onlyOwner()
        returns (bool)
    {
        feeFixed = _feeFixed;
        return true;
    }
}

// File: contracts\BridgeGateway.sol


pragma solidity ^0.8.0;



contract BridgeGateway is Privilege {
    mapping(bytes32 => SendStruct) public sendMap;

    struct SendStruct {
        address fromAddr;
        address toAddr;
        address token20Addr;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 feeRate;
        uint256 feeFixed;
    }

    event ReceiveEvent(address fromAddr, uint256 amount);
    event ExtractEvent(address ownerAddr, address token20Addr, uint256 amount);
    event SendEvent(
        bytes32 txId,
        address fromAddr,
        address toAddr,
        address token20Addr,
        uint256 fromAmount,
        uint256 toAmount,
        uint16 feeRate,
        uint256 feeFixed
    );
    event SendListEvent(
        bytes32[] txId,
        address[] fromAddr,
        address[] toAddr,
        address token20Addr,
        uint256[] fromAmount,
        uint256[] toAmount,
        uint16[] feeRate,
        uint256[] feeFixed
    );

    receive() external payable {
        emit ReceiveEvent(msg.sender, msg.value);
    }

    function extractToken(uint256 amount) public onlyOwner() {
        payable(super.owner()).transfer(amount);
        emit ExtractEvent(owner(), address(0), amount);
    }

    function extractToken20(address token20Addr, uint256 amount)
        public
        onlyOwner()
    {
        require(token20Addr != address(0), "token20Addr cannot be empty");
        require(
            IERC20(token20Addr).transfer(owner(), amount),
            "extract failed"
        );
        emit ExtractEvent(owner(), token20Addr, amount);
    }

    function getToAmount(uint256 tradeMoney) private view returns (uint256) {
        return
            ((tradeMoney * (10000 - feeRate)) / 10000) - feeFixed;
    }

    function sendToken(
        bytes32 txId,
        address fromAddr,
        address payable toAddr,
        uint256 fromAmount
    ) external onlyPrivilegeAccount() {
        require(
            sendMap[txId].fromAddr == address(0),
            "The transaction has been transferred"
        );
        require(toAddr != address(0), "The toAddr cannot be empty");
        uint256 toAmount = getToAmount(fromAmount);
        require(
            address(this).balance >= toAmount,
            "Insufficient Contract Balance"
        );

        limitMoneyPrivilegeAccount(fromAmount);

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount,
            toAmount: toAmount,
            feeRate: feeRate,
            feeFixed: feeFixed
        });

        toAddr.transfer(toAmount);
        emit SendEvent(
            txId,
            fromAddr,
            toAddr,
            address(0),
            fromAmount,
            toAmount,
            feeRate,
            feeFixed
        );
    }

    function sendTokenList(
        bytes32[] memory txIdList,
        address[] memory fromAddrList,
        address[] memory toAddrList,
        uint256[] memory fromAmountList
    ) external onlyPrivilegeAccount() {
        require(
            txIdList.length == fromAddrList.length &&
                txIdList.length == toAddrList.length &&
                txIdList.length == fromAmountList.length,
            "Parameter lengths are not equal"
        );
        uint256[] memory toAmountList =new uint256[](txIdList.length);
        uint16[] memory feeRateList =new uint16[](txIdList.length);
        uint256[] memory feeFixedList = new uint256[](txIdList.length);

        for (uint16 index = 0; index < txIdList.length; index++) {
            if(sendMap[txIdList[index]].fromAddr != address(0)){
                continue;
            }
            require(
                toAddrList[index] != address(0),
                "The toAddr cannot be empty"
            );
            uint256 toAmount = getToAmount(fromAmountList[index]);
            require(
                address(this).balance >= toAmount,
                "Insufficient Contract Balance"
            );

            toAmountList[index] = toAmount;
            feeRateList[index] = feeRate;
            feeFixedList[index] = feeFixed;

            limitMoneyPrivilegeAccount(fromAmountList[index]);

            sendMap[txIdList[index]] = SendStruct({
                fromAddr: fromAddrList[index],
                toAddr: toAddrList[index],
                token20Addr: address(0),
                fromAmount: fromAmountList[index],
                toAmount: toAmount,
                feeRate: feeRate,
                feeFixed: feeFixed
            });

           payable(toAddrList[index]).transfer(toAmount);
        }
        emit SendListEvent(
            txIdList,
            fromAddrList,
            toAddrList,
            address(0),
            fromAmountList,
            toAmountList,
            feeRateList,
            feeFixedList
        );
    }

    function sendToken20(
        bytes32 txId,
        address fromAddr,
        address toAddr,
        address token20Addr,
        uint256 fromAmount
    ) external onlyPrivilegeAccount() {
        require(sendMap[txId].fromAddr == address(0), "txId is exis");
        require(toAddr != address(0), "The toAddr cannot be empty");
        require(token20Addr != address(0), "The token20Addr cannot be empty");

        uint256 toAmount = getToAmount(fromAmount);
        require(
            IERC20(token20Addr).balanceOf(address(this)) >= toAmount,
            "Insufficient Contract Balance"
        );

        sendMap[txId] = SendStruct({
            fromAddr: fromAddr,
            toAddr: toAddr,
            token20Addr: address(0),
            fromAmount: fromAmount,
            toAmount: toAmount,
            feeRate: feeRate,
            feeFixed: feeFixed
        });

        limitMoneyPrivilegeAccount(fromAmount);

        require(
            IERC20(token20Addr).transfer(toAddr, toAmount),
            "Token20 transfer failed"
        );

        emit SendEvent(
            txId,
            fromAddr,
            toAddr,
            token20Addr,
            fromAmount,
            toAmount,
            feeRate,
            feeFixed
        );
    }

    function sendToken20List(
        bytes32[] memory txIdList,
        address[] memory fromAddrList,
        address[] memory toAddrList,
        address token20Addr,
        uint256[] memory fromAmountList
    ) external onlyPrivilegeAccount() {
        require(
            txIdList.length == fromAddrList.length &&
                txIdList.length == toAddrList.length &&
                txIdList.length == fromAmountList.length,
            "Parameter lengths are not equal"
        );
        uint256[] memory toAmountList =new uint256[](txIdList.length);
        uint16[] memory feeRateList =new uint16[](txIdList.length);
        uint256[] memory feeFixedList = new uint256[](txIdList.length);

        for (uint16 index = 0; index < txIdList.length; index++) {
            if(sendMap[txIdList[index]].fromAddr != address(0)){
                continue;
            }
            require(
                toAddrList[index] != address(0),
                "The toAddr cannot be empty"
            );
            uint256 toAmount = getToAmount(fromAmountList[index]);
            
            require(
                IERC20(token20Addr).balanceOf(address(this)) >= toAmount,
                "Insufficient Contract Balance"
            );

            toAmountList[index] = toAmount;
            feeRateList[index] = feeRate;
            feeFixedList[index] = feeFixed;

            limitMoneyPrivilegeAccount(fromAmountList[index]);

            sendMap[txIdList[index]] = SendStruct({
                fromAddr: fromAddrList[index],
                toAddr: toAddrList[index],
                token20Addr: token20Addr,
                fromAmount: fromAmountList[index],
                toAmount: toAmount,
                feeRate: feeRate,
                feeFixed: feeFixed
            });

            require(
                IERC20(token20Addr).transfer(toAddrList[index], toAmount),
                "Token20 transfer failed");
        }
        emit SendListEvent(
            txIdList,
            fromAddrList,
            toAddrList,
            token20Addr,
            fromAmountList,
            toAmountList,
            feeRateList,
            feeFixedList
        );
    }
}