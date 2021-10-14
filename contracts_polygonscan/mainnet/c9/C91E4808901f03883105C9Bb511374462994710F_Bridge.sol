pragma solidity ^0.8.0;

import "./multiOwnable.sol";
import "./IERC20.sol";

interface IERC20Trusted is IERC20 {
    function transferTrusted(address recipient, uint256 amount) external returns (bool);
    function transferFromTrusted(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Bridge is Multiownable {

    IERC20Trusted private token;
    address[] public feeOwners;
    uint256 public fee;
    uint256 amountToSent;
    bool transferStatus;
    bool avoidReentrancy = false;
    bool public transferBool;
    mapping(address => uint256) public tokensSent;
    mapping(address => uint256) public tokensReceived;
    mapping(address => uint256) public tokensReceivedButNotSent;
    mapping(address => uint256) public usersTransactionAmount;
    mapping(address => uint) public feeOwnersIndices;

    modifier transferEnabled() {
        require(transferBool, "Transfer: disabled");
        _;
    }

    event FeeOwnersUpdated(address[] previousCallers, address[] newCallers);
    event SendTokens (address indexed _sender, uint256 indexed _amount, uint256 indexed _targedChainId, uint256 _number, uint256 _currentBlock);
    event WriteTransaction (address indexed _sender, uint256 indexed _amount, uint256 _currentBlock);
    event ReceiveTokens (address indexed _sender, uint256 _currentBlock);

    constructor (address _token) {
        token = IERC20Trusted(_token);
        feeOwners.push(msg.sender);
        feeOwnersIndices[msg.sender] = 1;
        fee = 150000 * 10**9;
        transferBool = false;
    }

    function receiveTokens(uint256[] memory commissions) public payable {
        if (tokensReceivedButNotSent[msg.sender] != 0) {
            require(commissions.length == feeOwners.length, "The number of commissions and owners does not match");
            uint256 sum;
            for(uint i = 0; i < commissions.length; i++) {
                sum += commissions[i];
            }
            uint256 feeMinimalSum = usersTransactionAmount[msg.sender] * fee;
            require(msg.value >= sum, "Not enough ETH (The amount of ETH is less than the amount of commissions.)");
            require(msg.value >= feeOwners.length * fee, "Not enough ETH (The amount of ETH is less than the internal commission.)");
            require(msg.value >= feeMinimalSum, "Not enough ETH (The amount of ETH is less than the minimal sum of commissions)");

            for (uint256 i = 0; i < feeOwners.length; i++) {
                uint256 commission = commissions[i];
                require(commission >= feeMinimalSum, "Not enough amount of commision (The amount of commision is less than the minimal sum of commission)");
                payable(feeOwners[i]).transfer(commission);
            }

            amountToSent = tokensReceivedButNotSent[msg.sender] - tokensSent[msg.sender];
            token.transferTrusted(msg.sender, amountToSent);
            tokensSent[msg.sender] += amountToSent;
            usersTransactionAmount[msg.sender] = 0;

            emit ReceiveTokens (msg.sender, block.number);
        }
    }

    function updateTransfer(bool status) external onlyAllOwners {
        transferBool = status;
    }

    function updateBaseFee(uint256 _feeWei) external onlyAllOwners {
        require(_feeWei > 0, "Incorrect fee");
        fee = _feeWei;
    }

    function setOwnersForFee(address[] calldata _feeOwners) external onlyAllOwners {
        for (uint j = 0; j < owners.length; j++) {
            delete feeOwnersIndices[owners[j]];
        }
        for (uint i = 0; i < _feeOwners.length; i++) {
            require(_feeOwners[i] != address(0), "FeeOwners: callers array contains zero");
            require(feeOwnersIndices[_feeOwners[i]] == 0, "FeeOwners: callers array contains duplicates");
            require(ownersIndices[_feeOwners[i]] > 0, "FeeOwners: owners not match to callers");
            feeOwnersIndices[_feeOwners[i]] = i + 1;
        }
        emit FeeOwnersUpdated(feeOwners, _feeOwners);
        feeOwners = _feeOwners;
    }

    function writeTransaction(address user, uint256 amount) external onlySomeOwners(feeOwners.length) {
        require(user != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(!avoidReentrancy);

        avoidReentrancy = true;
        tokensReceivedButNotSent[user] += amount;
        avoidReentrancy = false;
        usersTransactionAmount[user] += 1;

        emit WriteTransaction (user, amount, block.number);
    }

    function withdrawTokens(uint256 amount, address receiver) external onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(receiver != address(0), "Zero account");
        require(token.balanceOf(address(this)) >= amount,"Not enough balance");

        token.transferTrusted(receiver, amount);
    }

    function withdrawETHer(uint256 amount, address receiver) external onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(receiver != address(0), "Zero account");
        require(address(this).balance >= amount,"Not enough balance");

        payable(receiver).transfer(amount);
    }

    function sendTokens(uint256 amount, uint256 _targetChainId, uint256 _counter) public {
        require(msg.sender != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(token.balanceOf(msg.sender) >= amount,"Not enough balance");

        transferStatus = token.transferFromTrusted(msg.sender, address(this), amount);
        if (transferStatus == true) {
            tokensReceived[msg.sender] += amount;
        }
        emit SendTokens (msg.sender, amount, _targetChainId, _counter, block.number);
    }

    function transferGateway(address to, uint256 amount) public transferEnabled {
        require(
            token.transferFromTrusted(msg.sender, address(this), amount),
            "Transfer: unable to transfer from address"
        );
        require(token.transferTrusted(to, amount), "Transfer: unable to transfer");
    }

}