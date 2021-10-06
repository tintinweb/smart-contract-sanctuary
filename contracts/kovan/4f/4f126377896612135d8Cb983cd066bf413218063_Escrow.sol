/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity =0.8.9;

contract Escrow {
    
    uint256 productPrice;
    uint256 _arbitrationFeePercentage;
    uint256 arbitrationFee;
    address payable _buyerAddress;
    address payable _sellerAddress;
    address payable _escrowAgentAddress;
    bool _productShipped;
    mapping(address => uint) public _userBalance;
    
    modifier onlyBuyer
    {
        require(msg.sender == _buyerAddress);
        _;
    }
 
    modifier onlySeller
    {
        require(msg.sender == _sellerAddress);
        _;
    }
    
    modifier onlyEscrowAgent
    {
        require(msg.sender == _escrowAgentAddress);
        _;
    }
    
    
    constructor(address payable buyerAddress, address payable sellerAddress, address payable escrowAgentAddress, uint256 arbitrationFeePercentage) 
    {
        _buyerAddress = buyerAddress;
        _sellerAddress = sellerAddress;
        _escrowAgentAddress = escrowAgentAddress;
        _arbitrationFeePercentage = arbitrationFeePercentage; //arbitbration fee percentage input of 1000 is equal to 1% which is required for integer math
    }
    
    function updateBuyerAddress(address payable buyerAddress) public onlyEscrowAgent
    {
        _buyerAddress = buyerAddress;
    }
    
    function updateSellerAddress(address payable sellerAddress) public onlyEscrowAgent
    {
        _sellerAddress = sellerAddress;
    }
    
    function updateEscrowAgentAddress(address payable escrowAgentAddress) public onlyEscrowAgent
    {
        _escrowAgentAddress = escrowAgentAddress;
    }
    
    function updateArbitrationFeePercentage(uint256 arbitrationFeePercentage) public onlyEscrowAgent
    {
        _arbitrationFeePercentage = arbitrationFeePercentage;
    }
    
    function checkUserBalance(address userBalance) public view returns(uint256)
    {
        return _userBalance[userBalance];
    }
    
    function checkBuyerAddress() public view returns(address)
    {
        return _buyerAddress;
    }
    
    function checkSellerAddress() public view returns(address)
    {
        return _sellerAddress;
    }
    
    function checkEscrowAgentAddress() public view returns(address)
    {
        return _escrowAgentAddress;
    }
    
    function checkArbitrationFee() public view returns(uint256)
    {
        return arbitrationFee;
    }
    
    function checkProductPrice() public view returns(uint256)
    {
        return productPrice;
    }
    
    function checkProductPricePlusArbitrationFee() public view returns(uint256)
    {
        return productPrice + arbitrationFee;
    }
    
    
    //allows escrow agent to set the agreed price of the sellers product
    function setProductPrice(uint256 amount) public onlyEscrowAgent
    {
        productPrice = amount;
        arbitrationFee = productPrice*_arbitrationFeePercentage/100000; 
    }
    
    //allows parties to check if buyer and seller deposited funds and if funds are sufficient
    //allows seller to check if buyer has deposited enough funds for the product
    function checkFunds() public view returns(bool)
    {
        require(_userBalance[_buyerAddress] > 0, "BUYER HAS NOT DEPOSITED ANY FUNDS");
        if (_userBalance[_buyerAddress] == productPrice + arbitrationFee && _userBalance[_sellerAddress] == arbitrationFee)
        {
            return true;
        }
        
        return false;
    }
    
    //allows escrow agent to confirm product shipment once seller provides proof of shipment 
    function confirmShipment(bool productShipped) public onlyEscrowAgent returns(bool)
    {
        _productShipped = productShipped;
        return _productShipped;
    }
    
    //allows parties to check if product shipment has been confirmed by the escrow agent
    function shipmentStatus() public view returns(bool)
    {
        return _productShipped;
    }
    
    //if product shipment is confirmed this allows escrow agent to transfer buyers funds to the seller 
    function transferFundsToSeller() external payable onlyEscrowAgent
    {
        require(_productShipped == true, "SHIPMENT STATUS UNCONFIRMED BY ESCROW AGENT");
        _sellerAddress.transfer(productPrice); //seller gets funds for their product that has been shipped to the buyer
        _escrowAgentAddress.transfer(arbitrationFee*2); //escrow agent gets arbitration fee from buyer and seller
        _userBalance[_buyerAddress] -= productPrice + arbitrationFee;
        _userBalance[_sellerAddress] -= arbitrationFee;
        _productShipped = false; //reset variables for next product
        arbitrationFee = 0;
        productPrice = 0;
        
    }
    
    //if product shipment is uncomfirmed this allows escrow agent to return the funds to the buyer
    function returnFundsToBuyer() external payable onlyEscrowAgent
    {
        require(_productShipped == false, "SHIPMENT STATUS CONFIRMED");
        require(_userBalance[_buyerAddress] > 0, "BUYER HAS NOT DEPOSITED ANY FUNDS");
        _buyerAddress.transfer(productPrice + arbitrationFee); //buyer gets refunded product price plus arbitration fee
        _escrowAgentAddress.transfer(arbitrationFee); //escrow agent gets arbitration fee from seller
        _userBalance[_buyerAddress] -= productPrice + arbitrationFee;
        _userBalance[_sellerAddress] -= arbitrationFee;
        arbitrationFee = 0; //reset variables for next product
        productPrice = 0;
    }
    
    function newEscrowProduct() public onlyEscrowAgent
    {
        _productShipped = false; //reset variables for next product
        arbitrationFee = 0;
        productPrice = 0;
        _userBalance[_buyerAddress] = 0;
        _userBalance[_sellerAddress] = 0;       
    }
    
    //allows smart contract to receive funds from seller and buyer and increments their balances within the contract accordingly
    receive() external payable  
    {
        
        if (msg.sender == _buyerAddress)
        {
            require(msg.value == productPrice + arbitrationFee, "INSUFFICIENT DEPOSIT AMOUNT");
            _userBalance[msg.sender] += msg.value;
        }
        
        else if (msg.sender == _sellerAddress)
        {
            require(msg.value == arbitrationFee, "INSUFFICIENT DEPOSIT AMOUNT");
            _userBalance[msg.sender] += msg.value;
        }
    }
    
}