pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Bridge is Ownable {
    using SafeMath for uint256;

    event Unwrap(address indexed receiver, uint256 amount, uint256 chainId);
    event Swap(address indexed receiver, uint256 amount, bytes32 originTx);

    mapping(bytes32 => bool) public transactions; // bridge transactions
    mapping(uint256 => bool) public chainIds;

    bool public isBridgeActive;

    address public oracle;
    address public feeReceiver;

    uint256 public feeBP;
    uint256 public minAmount;
    uint256 public destinationAmount; // swap yapıldıkça artacak. Diğer chainde ne kadar token olduğunu tutan değişken.

    IERC20 public token;


    constructor(IERC20 _token, address _feeReceiver, uint256 _feeBP) {
        token = _token;
        feeReceiver = _feeReceiver;
        feeBP = _feeBP;
    }

    function swap(address _to, uint256 _amount, bytes32 _originTxId) public onlyOracle {
        // sends tokens on network which contract deployed.
        // fee kesilmiş miktar gönderilmeli
        require(transactions[_originTxId] == false, "transaction already sent");
        require(_to != address(0),"receiver zero");
        require(isBridgeActive == true, "bridge not active");

        uint256 balance = contractBalance();
        require(balance >= _amount, "contract balance low");

        transactions[_originTxId] = true;

        token.transfer(_to, _amount);

        destinationAmount = destinationAmount.add(_amount);

        emit Swap(_to, _amount, _originTxId);
    }

    function unwrap(uint256 _amount, uint256 _chainId) public {
        // send to other chain
        require(tx.origin == msg.sender, "contract call not allowed");
        require(chainIds[_chainId] == true ,"chain id not supported");
        require(_amount >= minAmount, "amount too low");
        require(isBridgeActive == true, "bridge not active");
        require(destinationAmount >= _amount , "dest amount low");

        uint256 netAmount = netTransfer(msg.sender, _amount);
        require(netAmount > 0, "net amount zero");
        uint256 fee = 0;
        if(feeBP > 0) {
            fee = netAmount.mul(feeBP).div(10000);
        }
        uint256 amountSent = netAmount.sub(fee); // swaplanan token miktarı

        token.transfer(feeReceiver, fee); // fee gönderildi

        destinationAmount = destinationAmount.sub(amountSent);

        emit Unwrap(msg.sender, amountSent, _chainId); // eventleri oracleda okuyarak işlem yapmak gerekiyor.
    }

    // view functions

    function transactionStatus(bytes32 _txId) public view returns(bool) {
        //returns is the transaction processed or not.

        return transactions[_txId];
    }

    function contractBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    // internal functions

    // transfer funds from user account and returns the net value.
    function netTransfer(address _user, uint256 _amount) internal returns(uint256) {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.transferFrom(_user, address(this), _amount);
        uint256 balanceAfter = token.balanceOf(address(this));

        return balanceAfter.sub(balanceBefore);
    }

    // admin functions

    function setFeeReceiver(address _receiver) public onlyOwner {
        require(_receiver != address(0), "recv zero");
        feeReceiver = _receiver;
    }

    function setFeeBP(uint256 _fee) public onlyOwner {
        require(_fee < 10000, "fee too high");
        feeBP = _fee;
    }

    function setChainId(uint256 _chainId, bool _value) public onlyOwner {
        chainIds[_chainId] = _value;
    }

    function setDestinationAmount(uint256 _amount) public onlyOwner {
        destinationAmount = _amount;
    }

    function setMinimumAmount(uint256 _amount) public onlyOwner {
        minAmount = _amount;
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function toggleBridgeStatus() public onlyOwner {
        isBridgeActive = !isBridgeActive;
    }

    modifier onlyOracle {
        require(msg.sender == oracle, "Only oracle can call");
        _;
    }
}