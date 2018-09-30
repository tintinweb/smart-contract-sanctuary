pragma solidity ^0.4.24;
interface IExchangeFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) external view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) external view returns (uint256);
}

interface ITradeableAsset {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function decimals() external view returns (uint256);
    function transfer(address _to, uint256 _value) external;
    function balanceOf(address _address) external view returns (uint256);
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract Administered {
    address public creator;

    mapping (address => bool) public admins;

    constructor() public {
        creator = msg.sender;
        admins[creator] = true;
    }

    modifier onlyOwner {
        require(creator == msg.sender);
        _;
    }

    modifier onlyAdmin {
        require(admins[msg.sender] || creator == msg.sender);
        _;
    }

    function grantAdmin(address newAdmin) onlyOwner  public {
        _grantAdmin(newAdmin);
    }

    function _grantAdmin(address newAdmin) internal
    {
        admins[newAdmin] = true;
    }

    function changeOwner(address newOwner) onlyOwner public {
        creator = newOwner;
    }

    function revokeAdminStatus(address user) onlyOwner public {
        admins[user] = false;
    }
}

contract ExchangerV4 is Administered, tokenRecipient {
    bool public enabled = false;

    ITradeableAsset public tokenContract;
    IExchangeFormula public formulaContract;
    uint32 public weight;
    uint32 public fee=5000; //0.5%
    uint256 public uncirculatedSupplyCount=0;
    uint256 public collectedFees=0;
    uint256 public virtualReserveBalance=0;

    uint public thresholdSendToSafeWallet = 100000000000000000; 
    uint public sendToSafeWalletPercentage = 10; 

    constructor(address _token,
                uint32 _weight,
                address _formulaContract) {
        require (_weight > 0 && weight <= 1000000);

        weight = _weight;
        tokenContract = ITradeableAsset(_token);
        formulaContract = IExchangeFormula(_formulaContract);
    }

    event Buy(address indexed purchaser, uint256 amountInWei, uint256 amountInToken);
    event Sell(address indexed seller, uint256 amountInToken, uint256 amountInWei);

    function depositTokens(uint amount) onlyOwner public {
        tokenContract.transferFrom(msg.sender, this, amount);
    }

    function depositEther() onlyOwner public payable {
    //return getQuotePrice();
    }

    function withdrawTokens(uint amount) onlyOwner public {
        tokenContract.transfer(msg.sender, amount);
    }

    function withdrawEther(uint amountInWei) onlyOwner public {
        msg.sender.transfer(amountInWei); //Transfers in wei
    }

    function extractFees(uint amountInWei) onlyAdmin public {
        require (amountInWei <= collectedFees);
        msg.sender.transfer(amountInWei);
    }

    function enable() onlyAdmin public {
        enabled = true;
    }

    function disable() onlyAdmin public {
        enabled = false;
    }

    function setReserveWeight(uint ppm) onlyAdmin public {
        require (ppm>0 && ppm<=1000000);
        weight = uint32(ppm);
    }

    function setFee(uint ppm) onlyAdmin public {
        require (ppm >= 0 && ppm <= 1000000);
        fee = uint32(ppm);
    }

    function setUncirculatedSupplyCount(uint newValue) onlyAdmin public {
        require (newValue > 0);
        uncirculatedSupplyCount = uint256(newValue);
    }

    function setVirtualReserveBalance(uint256 amountInWei) onlyAdmin public {
        virtualReserveBalance = amountInWei;
    }

    function getReserveBalances() public view returns (uint256, uint256) {
        return (tokenContract.balanceOf(this), address(this).balance+virtualReserveBalance);
    }

    function getPurchasePrice(uint256 amountInWei) public view returns(uint) {
        uint256 purchaseReturn = formulaContract.calculatePurchaseReturn(
            (tokenContract.totalSupply() - uncirculatedSupplyCount) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            amountInWei
        );

        purchaseReturn = (purchaseReturn - ((purchaseReturn * fee) / 1000000));

        if (purchaseReturn > tokenContract.balanceOf(this)){
            return tokenContract.balanceOf(this);
        }
        return purchaseReturn;
    }

    function getSalePrice(uint256 tokensToSell) public view returns(uint) {
        uint256 saleReturn = formulaContract.calculateSaleReturn(
            (tokenContract.totalSupply() - uncirculatedSupplyCount) - tokenContract.balanceOf(this),
            address(this).balance + virtualReserveBalance,
            weight,
            tokensToSell
        );
        saleReturn = (saleReturn - ((saleReturn * fee) / 1000000));
        if (saleReturn > address(this).balance) {
            return address(this).balance;
        }
        return saleReturn;
    }

    function buy(uint minPurchaseReturn) public payable {
        uint amount = formulaContract.calculatePurchaseReturn(
            (tokenContract.totalSupply() - uncirculatedSupplyCount) - tokenContract.balanceOf(this),
            (address(this).balance + virtualReserveBalance) - msg.value,
            weight,
            msg.value);
        amount = (amount - ((amount * fee) / 1000000));

        require (enabled);
        require (amount >= minPurchaseReturn);
        require (tokenContract.balanceOf(this) >= amount);

        if(msg.value > thresholdSendToSafeWallet){
            uint transferToSafeWallet = msg.value * sendToSafeWalletPercentage / 100;
            creator.transfer(transferToSafeWallet);
            virtualReserveBalance += transferToSafeWallet;
        }

        collectedFees += (msg.value * fee) / 1000000;

        emit Buy(msg.sender, msg.value, amount);
        tokenContract.transfer(msg.sender, amount);
    }

    function sell(uint quantity, uint minSaleReturn) public {
        uint amountInWei = formulaContract.calculateSaleReturn(
            (tokenContract.totalSupply()- uncirculatedSupplyCount) - tokenContract.balanceOf(this),
             address(this).balance + virtualReserveBalance,
             weight,
             quantity
        );
        amountInWei = (amountInWei - ((amountInWei * fee) / 1000000));

        require (enabled);
        require (amountInWei >= minSaleReturn);
        require (amountInWei <= address(this).balance);
        require (tokenContract.transferFrom(msg.sender, this, quantity));

        collectedFees += (amountInWei * fee) / 1000000;

        emit Sell(msg.sender, quantity, amountInWei);
        msg.sender.transfer(amountInWei);
    }

    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external {
        sellOneStep(_value, 0, _from);
    }

    function sellOneStep(uint quantity, uint minSaleReturn, address seller) public {
        uint amountInWei = formulaContract.calculateSaleReturn(
            (tokenContract.totalSupply() - uncirculatedSupplyCount) - tokenContract.balanceOf(this),
             address(this).balance + virtualReserveBalance,
             weight,
             quantity
        );
        amountInWei = (amountInWei - ((amountInWei * fee) / 1000000));

        require (enabled);
        require (amountInWei >= minSaleReturn);
        require (amountInWei <= address(this).balance);
        require (tokenContract.transferFrom(seller, this, quantity));

        collectedFees += (amountInWei * fee) / 1000000;

        emit Sell(seller, quantity, amountInWei);
        seller.transfer(amountInWei);
    }

    function setSendToSafeWalletPercentage(uint newValue) onlyOwner public {
        require (newValue > 0);
        sendToSafeWalletPercentage = uint(newValue);
    }

    function setThresholdSendToSafeWallet(uint256 amountInWei) onlyOwner public {
        thresholdSendToSafeWallet = amountInWei;
    }

}