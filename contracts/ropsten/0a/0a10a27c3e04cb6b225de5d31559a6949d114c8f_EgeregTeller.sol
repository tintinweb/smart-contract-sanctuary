pragma solidity ^0.4.23;

contract Token {
    function transfer(address _to, uint _amount) external;
    function transferFrom(address _from, address _to, uint _amount) external;
}

contract EgeregTeller {
    Token egereg;
    address public owner;
    bool public isPaused;
    uint buyPrice;
    uint sellPrice;
    string public encryptKey;

    constructor() public {
        owner = msg.sender;
        isPaused = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyNotPaused() {
        require(isPaused == false);
        _;
    }

    function() external payable onlyNotPaused {
        egereg.transfer(msg.sender, msg.value/buyPrice);
    }

    function tokenFallback(address _from, uint _amount, bytes _data) external onlyNotPaused returns(bool) {
        require(msg.sender == address(egereg));

        if (_data.length != 0) {
            emit ToMNT(_amount, string(_data));
        } else {
            _from.transfer(_amount * sellPrice);
        }

        return true;
    }

    function eth2MNT(string _encryptedBankInfo) external payable onlyNotPaused {
        emit ToMNT(msg.value / buyPrice, _encryptedBankInfo);
    }

    function setPrices(uint _newBuyPrice, uint _newSellPrice) external onlyOwner {
        sellPrice = 10000000000000000/_newSellPrice;
        buyPrice = 10000000000000000/_newBuyPrice;
        emit PriceChange(_newBuyPrice, _newSellPrice);
    }

    function getBuyPrice() external view returns(uint) {
        return 10000000000000000/buyPrice;
    }

    function getSellPrice() external view returns(uint) {
        return 10000000000000000/sellPrice;
    }

    function setEgeregAddress(address _newEgeregAddress) external onlyOwner {
        egereg = Token(_newEgeregAddress);
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setEncryptKey(string _newKey) external onlyOwner {
        encryptKey = _newKey;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function resume() external onlyOwner {
        isPaused = false;
    }

    function depositEgereg(uint _amount) external {
        egereg.transferFrom(msg.sender, this, _amount);
    }

    function depositEther() external payable {}

    function withdrawEgereg(uint _amount) external onlyOwner {
        egereg.transfer(owner, _amount);
    }

    function withdrawEther(uint _amount) external onlyOwner {
        owner.transfer(_amount);
    }

    event ToMNT(uint _amount, string _encryptedBankInfo);
    event PriceChange(uint _newBuyPrice, uint _newSellPrice);
}