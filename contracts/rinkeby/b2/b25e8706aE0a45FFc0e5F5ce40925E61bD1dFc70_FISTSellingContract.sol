/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IFIST {
    function safeTransferFrom(address from, address to, uint256 tokenid) external;
} 

// FTC --> Furnishing Token Contract, FSC --> FIST Selling Contract
contract FISTSellingContract is IERC721Receiver {
    address public _ftcAddress;
    address public _fscOwnerAddress;
    address public _ftcOwnerAddress;
    uint256 public _pricePerFIST;
    
    // bytes4 constant ERC721Received = 0xf0b9e5ba;
    uint256[] public _tokensOwned;
    uint public _tokensSoldSoFar;
    uint public _myProfitPercent = 10; // 10 percent
    
    
    
    event FISTReceived(address, address, uint256);
    event FISTSold(address, uint256);
    event WithDrawn(address, uint);
    
    constructor(address ftcAddress_, address ftcOwnerAddress_){
        _fscOwnerAddress = msg.sender;
        _ftcAddress = ftcAddress_;
        _ftcOwnerAddress = ftcOwnerAddress_;
    }
    
    function setPrice(uint256 price_) public onlyfcOwner {
        require(price_ > 0);
        _pricePerFIST = price_;
    }
    
    function getPrice() public view returns (uint256) {
        return _pricePerFIST;
    }
    
    function getStock() public view returns (uint256){
        return _tokensOwned.length;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getTotalTokensOwned() public view returns (uint256) {
        return _tokensOwned.length;
    }
    
    
    function buyFIST() public payable {
        require(msg.value == _pricePerFIST, "Amount must be equal to the token price");
        require(_tokensOwned.length > 0);
        ++_tokensSoldSoFar;
        uint256 tokenId = _tokensOwned[_tokensOwned.length - 1];
        // finally remove the tokenId and decrease array length by 1
        _tokensOwned.pop();
        IFIST(_ftcAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        
        emit FISTSold(msg.sender, tokenId);
    }
    
    function withDraw() public onlyfcOwnerORfscOwner {
        uint amnt = address(this).balance;
        if(msg.sender == _ftcOwnerAddress){
            require(_tokensSoldSoFar > 0);
            _tokensSoldSoFar = 0;
            amnt = amnt - amnt/_myProfitPercent;
        }
        require(amnt > 0, "Insufficient balance.");
        payable(msg.sender).transfer(amnt);
        emit WithDrawn(msg.sender, amnt);
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        // save incomming tokenId in array
        _tokensOwned.push(tokenId);
        emit FISTReceived(operator, from, tokenId); 
        return this.onERC721Received.selector;
    }
    
    modifier onlyfcOwner {
        require(msg.sender == _ftcOwnerAddress);
        _;
    }
    
    modifier onlyfscOwner {
        require(msg.sender == _fscOwnerAddress);
        _;
    }
    
    modifier onlyfcOwnerORfscOwner {
        require(msg.sender == _ftcOwnerAddress || 
                    msg.sender == _fscOwnerAddress);
        _;
    }
}