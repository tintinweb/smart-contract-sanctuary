/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

pragma solidity 0.8.6;

// "SPDX-License-Identifier: MIT"

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

abstract contract ERC721Interface {
  function approve(address to, uint256 tokenId) external virtual;
  function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
}

abstract contract ERC20Interface {
    function approve(address spender, uint tokens) external virtual;
    function transfer(address to, uint tokens) external virtual;
    function transferFrom(address from, address to, uint tokens) external virtual;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract IDRsaleERC20 is IERC721Receiver, Owned {
    using SafeMath for uint; 
    
    uint256 public sellId;
    uint256 public fee1;
    uint256 public fee2;
    uint256 public feeDenominator;
    address public feeAddr1;
    address public feeAddr2;
    address public contract20Address;
    
    constructor() {
        fee1 = 5; // 0.5%
        fee2 = 5; // 0.5%
        feeDenominator = 1000;
        feeAddr1 = 0x960c82cF524a168aC93EC1Ae61F40635ACAcF6E2;
        feeAddr2 = owner;
        contract20Address = 0xf00dE6690cF9c8697622Df49C3AD993e7bED4492;
    }
    
    mapping (uint256 => Sales) sale;
    
    struct Sales {
        address seller;
        address buyer;
        address contr;
        uint256 tokenId;
        uint256 price;
        bool    active;
    }
    
    event Sell(uint256 sellId, address contractAddress, uint256 tokenId, uint256 price);
    event Cancel(uint256 sellId);
    event Buy(uint256 sellId, uint256 price, address buyer);
    event Verify(address sender, string code);
    
    function sellInfo(uint256 Id) public view returns (address seller, address buyer, address contractAddress, uint256 tokenId, uint256 price, bool active) {
        return (sale[Id].seller, sale[Id].buyer, sale[Id].contr, sale[Id].tokenId, sale[Id].price, sale[Id].active);
    }
    
    function sell(address contractAddress, uint256 tokenId, address from, uint256 amount) public returns (uint256 Id) { 
        ERC721Interface(contractAddress).safeTransferFrom(from, address(this), tokenId);
        require(amount != 0, 'PRICE IS ZERO');
        require(amount >= 1 * 10**18, 'PRICE >= 1 token');
        sale[sellId].seller = msg.sender;
        sale[sellId].buyer = address(0);
        sale[sellId].contr = contractAddress;
        sale[sellId].tokenId = tokenId;
        sale[sellId].price = amount;
        sale[sellId].active = true;
        emit Sell(sellId, contractAddress, tokenId, amount);
        sellId = sellId.add(1);
        return sellId.sub(1);
    }
    
    function cancel(uint256 Id) public {
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(sale[Id].active == true, "SELL IS NOT ACTIVE");
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Cancel(Id);
    }
    
    function buy(uint256 Id) public {
        require(sale[Id].active, "SELL IS NOT ACTIVE");
        ERC20Interface(contract20Address).transferFrom(msg.sender, address(this), sale[Id].price);
        ERC20Interface(contract20Address).transfer(sale[Id].seller, sale[Id].price.div(feeDenominator).mul(uint256(feeDenominator).sub(fee1.add(fee2))));
        ERC20Interface(contract20Address).transfer(feeAddr1, sale[Id].price.div(feeDenominator).mul(fee1));
        ERC20Interface(contract20Address).transfer(feeAddr2, sale[Id].price.div(feeDenominator).mul(fee2));
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].buyer = msg.sender;
        sale[Id].active = false;
        emit Buy(Id, sale[Id].price, msg.sender);
    }
    
    function changeFee1(uint _fee1) public onlyOwner {
        require(_fee1 <= 10); // 1%
        fee1 = _fee1;
    }
    
    function changeFee2(uint _fee2) public onlyOwner {
        require(_fee2 <= 10); // 1%
        fee2 = _fee2;
    }
    
    function changeFeeAddr1(address _feeAddr1) public onlyOwner {
        feeAddr1 = _feeAddr1;
    }

    function changeFeeAddr2(address _feeAddr2) public onlyOwner {
        feeAddr2 = _feeAddr2;
    }
    
    function change20Addr(address _contract20Address) public onlyOwner {
        contract20Address = _contract20Address;
    }
    
    function transferAny20Token(address tokenAddress, uint tokens) public onlyOwner {
        require(tokenAddress != contract20Address);
        ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function verification(string memory code) public {
        emit Verify(msg.sender, code);
    }
        
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}