pragma solidity >=0.6.0 <0.8.0;

import "./IBEP20.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract NFTMarketplace is ERC1155, ERC2981PerTokenRoyalties, Ownable {

    uint256 BNB_TOKEN_ID = uint256(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
    uint256 SPC_TOKEN_ID = uint256(0x002013fe8529077c6c6177b80ace8746f8f8a1eb4f);
    uint8 TOKEN_BNB = 1;
    uint8 TOKEN_SPC = 2;

    address payable myOwner;

    IBEP20 stakedToken;

    mapping (uint256 => address) private _addressFromID;
    mapping (address => bool) private _isCreater;
    mapping (address => uint256) private _balanceFromAddress;

    modifier onlyCreater {
        require((_isCreater[msg.sender]), "Not NFT creater...");
        _;
    }

    constructor(string memory _uri) ERC1155(_uri) public {
        myOwner = msg.sender;
        mintingFee = 1;
        sellingFee = 10;
    }

    function setOwner(address payable newOwner)
    external
    onlyOwner {
        myOwner = newOwner;
    }

    function setCreater(address addr, bool isCreater) 
    external
    onlyOwner {
        _isCreater[addr] = isCreater;
    }

    function setStakedToken(IBEP20 _stakedToken)
    external {
        stakedToken = _stakedToken;
    }

    function setRoyalty(uint256 tokenId, address recipient, uint24 ratio)
    external
    onlyOwner {
        if (ratio > 0) {
            _setTokenRoyalty(tokenId, recipient, ratio);
        }
    }

    function setMintingFee(uint256 tokenId, address recipient, uint256 amount)
    external
    onlyOwner {
        if (amount > 0) {
            _setMintingFee(tokenId, recipient, amount);
        }
    }

    function setSellingFee(uint256 tokenId, address recipient, uint24 ratio)
    external
    onlyOwner {
        if (ratio > 0) {
            _setSellingFee(tokenId, recipient, ratio);
        }
    }

    function transferInETH(address payable to, uint256 amountETH)
    internal {
        to.transfer(amountETH);
    }

    function transferInBNB(address payable to, uint256 amountBNB)
    internal {
        to.transfer(amountBNB);
    }

    function transferInSPC(address payable to, uint256 amountSPC)
    internal {
        stakedToken.transfer(to, amountSPC);
    }

    function transferOnBSC(address payable to, uint256 amount, uint8 tokenType)
    internal {
        if (tokenType == TOKEN_BNB) {
            require(balanceOf(address(this), BNB_TOKEN_ID) >= amount, "Not enough balance...");
            transferInBNB(to, amount);
        } else if ( tokenType == TOKEN_SPC) {
            require(balanceOf(address(this), SPC_TOKEN_ID) >= amount, "Not enough balance...");
            transferInSPC(to, amount);
        } else {
            transferInETH(to, amount);
        }
    }

    function chargeBalance(address to, uint256 amount)
    internal
    onlyOwner {
        uint256 temp = _balanceFromAddress[to];
        _balanceFromAddress[to] = temp + amount;
    }

    function dischargeBalance(address to, uint256 amount)
    internal
    onlyOwner {
        uint256 temp = _balanceFromAddress[to];
        require(temp >= amount, "Not available...");
        _balanceFromAddress[to] = temp - amount;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amountNFT,
        address royaltyRecipient,
        uint24 royaltyValue,
        uint8 tokenType)
    external
    onlyCreater {
        require((_isCreater[msg.sender] || (myOwner == msg.sender)), "Not allowed creater...");
        _addressFromID[tokenId] = msg.sender;
        
        transferOnBSC(myOwner, mintingInfo(tokenId), tokenType);
        _mint(to, tokenId, amountNFT, '');

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amountNFTs,
        address[] calldata royaltyRecipients,
        uint24[]  calldata royaltyValues,
        uint256[] calldata mintingValues,
        uint8 tokenType)
    external
    onlyCreater {
        require(
            tokenIds.length == royaltyRecipients.length &&
            tokenIds.length == royaltyValues.length &&
            tokenIds.length == mintingValues.length,
            'ERC1155: Arrays length mismatch'
        );

        require((_isCreater[msg.sender]), "Not allowed creater...");
        for (uint256 i; i < tokenIds.length; i++) {
            _addressFromID[tokenIds[i]] = msg.sender;
        }
        
        uint256 feeBatchAmount = mintingInfo(tokenIds[0]) * tokenIds.length;

        transferOnBSC(myOwner, feeBatchAmount, tokenType);
        _mintBatch(to, tokenIds, amountNFTs, '');

        for (uint256 i; i < tokenIds.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    tokenIds[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
        }
    }

    function transferNFT(address to, uint256 id, uint256 amount, uint8 tokenType)
    external {
        require(balanceOf(to, id) > amount, "Insufficient purchase balance...");

        (address receiver, uint256 royaltyAmount) = royaltyInfo(id);
        uint256 salePrice = amount - amount * sellingInfo(id) - amount * royaltyAmount;

        address seller = _addressFromID[id];
        _addressFromID[id] = to;

        chargeBalance(seller, salePrice);
        chargeBalance(receiver, amount * royaltyAmount);

        safeTransferFrom(seller, to, id, 1, '0');
    }

    function withDraw(address payable to, uint256 id, uint8 tokenType)
    internal
    onlyOwner {
        require(_balanceFromAddress[to] > 0, "Insufficient purchase balance...");

        transferOnBSC(to, _balanceFromAddress[_addressFromID[id]], tokenType);
        _balanceFromAddress[_addressFromID[id]] = 0;
    }
    
    function supportsInterface(bytes4 interfaceId)
    public view
    virtual override(ERC165, ERC2981Base)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}