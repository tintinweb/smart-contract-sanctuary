pragma solidity 0.4.25;

import "./multiOwnable.sol";
import "./IERC20.sol";

contract ethBridge is Multiownable {
    IERC20 private token;

    mapping(address => uint256) public tokensSent;
    mapping(address => uint256) public tokensRecieved;
    mapping(address => uint256) public tokensRecievedButNotSent;
    address[] public feeOwners;
    mapping(address => uint) public feeOwnersIndices;
    uint256 public fee;

    event FeeOwnersUpdated(address[] previousCallers, address[] newCallers);

    constructor (address _token) public {
        token = IERC20(_token);
        feeOwners.push(msg.sender);
        feeOwnersIndices[msg.sender] = 1;
        fee = 150000 * 10**9;
    }

    uint256 amountToSent;
    bool transferStatus;

    bool avoidReentrancy = false;

    function updateBaseFee(uint256 _feeGwei) public onlyAllOwners {
        fee = _feeGwei * 10**9;
    }

    function setOwnersForFee(address[] _feeOwners) public onlyAllOwners {
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

    function sendTokens(uint256 amount) public {
        require(msg.sender != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(token.balanceOf(msg.sender) >= amount,"Not enough balance");

        transferStatus = token.transferFrom(msg.sender, address(this), amount);
        if (transferStatus == true) {
            tokensRecieved[msg.sender] += amount;
        }
    }

    function writeTransaction(address user, uint256 amount) public onlySomeOwners(feeOwners.length) {
        require(user != address(0), "Zero account");
        require(amount > 0,"Amount of tokens should be more then 0");
        require(!avoidReentrancy);

        avoidReentrancy = true;
        tokensRecievedButNotSent[user] += amount;
        avoidReentrancy = false;
    }

    function recieveTokens(uint256[] memory commissions) public payable {
        if (tokensRecievedButNotSent[msg.sender] != 0) {
            require(commissions.length == feeOwners.length, "The number of commissions and owners does not match");
            uint256 sum;
            for(uint i = 0; i < commissions.length; i++) {
                sum += commissions[i];
            }
            require(msg.value >= sum, "Not enough ETH (The amount of ETH is less than the amount of commissions.)");
            require(msg.value >= feeOwners.length * fee, "Not enough ETH (The amount of ETH is less than the internal commission.)");

            for (i = 0; i < feeOwners.length; i++) {
                uint256 commission = commissions[i];
                feeOwners[i].transfer(commission);
            }

            amountToSent = tokensRecievedButNotSent[msg.sender] - tokensSent[msg.sender];
            token.transfer(msg.sender, amountToSent);
            tokensSent[msg.sender] += amountToSent;
        }
    }

    function withdrawTokens(uint256 amount, address reciever) public onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(reciever != address(0), "Zero account");
        require(token.balanceOf(address(this)) >= amount,"Not enough balance");

        token.transfer(reciever, amount);
    }

    function withdrawETHer(uint256 amount, address reciever) public onlyAllOwners {
        require(amount > 0,"Amount of tokens should be more then 0");
        require(reciever != address(0), "Zero account");
        require(address(this).balance >= amount,"Not enough balance");

        reciever.transfer(amount);
    }
}