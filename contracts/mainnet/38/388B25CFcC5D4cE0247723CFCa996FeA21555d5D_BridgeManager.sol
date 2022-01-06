/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.6;

interface Bridge {
    function withdraw(uint toChainId, address toToken, address recipient, uint256 value, bytes memory hash) external;

    function withdrawNative(uint toChainId, address payable recipient, bool isMain, uint256 value, bytes memory hash) external;
}

contract BridgeManager {

    address public owner;

    address public bridgeAddress;

    // 确认事件，前端可用于捕获自己的跨链进度
    event Confirmation(uint fromChainId, bytes txHash, address toToken, address recipient, uint256 amount, bytes32 transactionId, address sender);

    address[] public Managers;
    mapping(address => bool) public isManager;
    mapping(bytes32 => mapping(address => bool)) public confirmations;
    mapping(bytes32 => Transaction) public transactions;


    // 需要多签数量
    uint public signLimit;

    //跨链交易
    struct Transaction {
        uint fromChainId;//目标链
        bytes txHash;//跨链hash
        address toToken; //代币
        address recipient;//接收
        uint amount;//数量
        bool isNative;// 是否主网币
        bool isMain;// 是否主链
        bool executed;//是否执行
    }

    // multiSigns[networkID][txHash] = managers[]
    mapping(uint => mapping(bytes => address[])) public multiSigns;

    constructor(uint _signLimit, address _bridgeAddress, address _owner) {
        owner = _owner;
        signLimit = _signLimit;
        bridgeAddress = _bridgeAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Bridge Manager: only use owner to call");
        _;
    }

    modifier onlyManager {
        require(isManager[msg.sender], "Bridge Manager: only manager can call this function");
        _;
    }

    function setOwner(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function setBridgeAddress(address _bridgeAddress) public onlyOwner {
        bridgeAddress = _bridgeAddress;
    }

    // 设置多签数量
    function setSignLimit(uint num) public onlyOwner {
        signLimit = num;
    }

    // 添加管理员
    function managerAdd(address _address) public onlyOwner {
        bool push = true;
        uint256 i = 0;
        while (push && i < Managers.length) {
            if (Managers[i] == _address) push = false;
            i++;
        }
        if (push) Managers.push(_address);
        isManager[_address] = true;
    }

    // 删除管理员
    function managerDel(address _address) public onlyOwner {
        address[] memory newManagers;
        uint256 j = 0;
        for (uint256 i = 0; i < Managers.length; i++) {
            if (Managers[i] != _address) {
                newManagers[j] = Managers[i];
                j++;
            }
        }
        Managers = newManagers;
        isManager[_address] = false;
    }


    function allManagersLength() public view returns (uint){
        return Managers.length;
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(bytes32 transactionId)
    public view
    returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < Managers.length; i++) {
            if (confirmations[transactionId][Managers[i]])
                count += 1;
            if (count == signLimit)
                return true;
        }
        return false;
    }

    //查询id
    function getTransactionId(uint fromChainId, bytes memory txHash, address toToken, address recipient, uint256 amount) pure public returns (bytes32){
        // 根据来源跨链交易生成唯一hash id，作为这笔跨链的id
        bytes32 transactionId = keccak256(abi.encodePacked(fromChainId, txHash, toToken, recipient, amount));

        return transactionId;
    }


    // 查询一笔交易是否跨链成功
    function isExecuted(uint fromChainId, bytes memory txHash, address toToken, address recipient, uint256 amount) view public returns (bool){
        // 根据来源跨链交易生成唯一hash id，作为这笔跨链的id
        bytes32 transactionId = keccak256(abi.encodePacked(fromChainId, txHash, toToken, recipient, amount));

        if (transactions[transactionId].executed)
            return true;
        else
            return false;
    }

    /// @dev 提交一个跨链请求
    /// @param fromChainId 来源链id
    /// @param txHash      来源链交易hash
    /// @param toToken     目标token
    /// @param recipient   接收地址
    /// @param amount      数量
    function submitTransaction(uint fromChainId, bytes memory txHash, address toToken, address recipient, uint256 amount, bool isNative, bool isMain) public onlyManager returns (bool) {
        // 根据来源跨链交易生成唯一hash id，作为这笔跨链的id
        bytes32 transactionId = keccak256(abi.encodePacked(fromChainId, txHash, toToken, recipient, amount));
        if (confirmations[transactionId][msg.sender])
            return true;

        //如果已经成功跨链，直接返回成功
        if (transactions[transactionId].executed)
            return true;

        transactions[transactionId] = Transaction({
        fromChainId : fromChainId,
        txHash : txHash,
        toToken : toToken,
        recipient : recipient,
        amount : amount,
        isNative : isNative,
        isMain : isMain,
        executed : false
        });

        confirmations[transactionId][msg.sender] = true;

        // 弹出事件，用于其它程序捕获，例如前端可以捕获自己跨链
        emit Confirmation(fromChainId, txHash, toToken, recipient, amount, transactionId, msg.sender);

        if (isConfirmed(transactionId))
        {
            executeTransaction(transactionId);
        }
        return true;
    }


    // 执行跨链操作，任意账号均可
    function executeTransaction(bytes32 transactionId) public {
        Transaction storage txn = transactions[transactionId];
        bool _confirmed = isConfirmed(transactionId);
        if (_confirmed && txn.executed == false) {
            txn.executed = true;
            if (txn.isNative) {
                withdrawNative(txn.fromChainId, txn.isMain, payable(txn.recipient), txn.amount, txn.txHash);
            } else {
                withdraw(txn.fromChainId, txn.toToken, txn.recipient, txn.amount, txn.txHash);
            }
        }
    }

    function withdraw(uint fromChainId, address toToken, address recipient, uint256 amount, bytes memory depositHash) private {
        Bridge bridge = Bridge(bridgeAddress);
        bridge.withdraw(fromChainId, toToken, recipient, amount, depositHash);

    }

    function withdrawNative(uint fromChainId, bool isMain, address payable recipient, uint256 amount, bytes memory depositHash) private {
        Bridge bridge = Bridge(bridgeAddress);
        bridge.withdrawNative(fromChainId, recipient, isMain, amount, depositHash);
    }

}