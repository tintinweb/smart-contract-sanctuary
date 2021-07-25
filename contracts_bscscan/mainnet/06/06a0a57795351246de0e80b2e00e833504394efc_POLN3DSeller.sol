/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {

    function mint(address to, uint32 _assetType, uint256 _value, uint32 _customDetails) external returns (bool success);
    function assetsByType(uint256 _typeId) external view returns (uint64 _maxAmount, uint64 _mintedAmount, uint64 _coinIndex, string memory copyright);
    function tradeCoins(uint256 coinIndex) external view returns (address _tokenAddress, string memory _symbol, string memory _name);

}
contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }


    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract POLN3DSeller is Ownable {
    
    address public nftAddress;
    address payable public sellingWallet;
    
    struct assetDescription {
        uint256 price;
        uint32 details;
        
    }
    mapping(uint => uint) public assets;
    
    constructor() {
        sellingWallet = payable(0xAD334543437EF71642Ee59285bAf2F4DAcBA613F);
        nftAddress = 0xbE279cE5CD7511a88c1aBc6c5EA53F6effcAB455;
        assets[24] = 17150000000000000000000;
        assets[25] = 194872000000000000000000;
        assets[31] = 1950000000000000000000;
        assets[32] = 3509000000000000000000;
        assets[34] = 888000000000000000000;
        assets[35] = 1771000000000000000000;
        assets[36] = 1610000000000000000000;
        assets[37] = 6050000000000000000000;
        assets[38] = 6050000000000000000000;
        assets[39] = 30250000000000000000000;
        assets[40] = 1210000000000000000000;
        assets[42] = 9680000000000000000000;

    }
    
    function decode(bytes memory _bytes) private pure returns (uint256 _assetType, uint256 _assetDetails) {
            uint256 parsed1;
            uint256 parsed2;
            assembly {
        	    parsed1 := mload(add(_bytes, 32))
        	    parsed2 := mload(add(_bytes, 64))
            }
            return (parsed1, parsed2);
    }
    

    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public returns (bool success) {
        IERC721 nft = IERC721(nftAddress);
        (uint256 bassetType, uint256 bassetDetails) = decode(_extraData);
       (, , uint64 _coinIndex, ) = nft.assetsByType(bassetType);
        require(_coinIndex != 0 && _coinIndex != 1, "Invalid coin");
        (address _tokenAddress, , ) = nft.tradeCoins((uint256(_coinIndex)));
        require((_token == _tokenAddress), "Invalid token");
        require((assets[bassetType] <= _value), "Balance is less than asset price");
        IERC20Token token = IERC20Token(_tokenAddress);
        require(token.transferFrom(_from, sellingWallet, assets[bassetType]), "ERC20 Transfer error");
        require(nft.mint(_from, uint32(bassetType), assets[bassetType], uint32(bassetDetails)), "Not possible to mint this type of asset");
        return true;
    }
    
    function buyWithEth(uint256 assetType, uint256 assetDetails) public payable returns (bool success) {
        IERC721 nft = IERC721(nftAddress);
        (, , uint64 _coinIndex, ) = nft.assetsByType(assetType);
        require(_coinIndex == 1 , "Invalid coin");
        require(msg.value == (assets[assetType]), 'Invalid amount');
        require(sellingWallet.send(msg.value));
        require(nft.mint(msg.sender, uint32(assetType), assets[assetType], uint32(assetDetails)), "Not possible to mint this type of asset");
        return true;
    }
    
    function setPrice(uint256 _assetId, uint256 _newPrice) public onlyOwner {
        assets[_assetId] = _newPrice;
    }
    
    function incrementPrice(uint256 _increment, uint256 _start, uint256 _end) public onlyOwner {
        for (uint i = _start;i <= _end; i++) {
            assets[i] += ((assets[i]*_increment)/100);
        }
    }
    

    
    
}