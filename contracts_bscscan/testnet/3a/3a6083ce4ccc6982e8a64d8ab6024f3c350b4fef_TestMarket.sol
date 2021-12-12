// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";


contract TestMarket is ERC721Holder, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;


    struct Offer {
        bool status;
        address seller;
        uint256 tokenId;
        uint256 category;
        uint256 amount;
        uint256 tokenIndex;
    }

    mapping(uint256 => Offer) private _offers;

    mapping(address => uint256[]) private tokensIdsOnSell;

    uint256 private _lastOfferID = 0;

    IERC20 private ERC20Contract;

    IERC721 private nftContract;

    address private _feeWallet;

    uint256 private _exchangeRate;

    uint256 private _fee;


    event NewOffer(address indexed wallet, uint256 _id, uint256 tokenId, uint256 category, uint256 amount);

    event OfferCancelled(uint256 _id, uint256 tokenId);

    event OfferChanged(uint256 _id, uint256 tokenId, uint256 amount);

    event OfferClosed(address indexed buyer, uint256 _id, uint256 tokenId);

    mapping(uint256 => bool) private usedNonces;


    constructor (address cOwner) Ownable(cOwner) {
        _feeWallet = owner();
        _fee = 10;
    }

    function setERC20Contract(address _account) public onlyOwner {
        ERC20Contract = IERC20(_account);
    }

    function setNFTContract(address _account) public onlyOwner {
        nftContract = IERC721(_account);
    }


    function setExchangeRate(uint256 _newrate) public onlyOwner {
        _exchangeRate = _newrate;
    }


    function setFee(uint256 _newfee) public onlyOwner {
        _fee = _newfee;
    }


    function placeBid(uint256 _tokenId, uint256 _price) public {
        require(nftContract._isApprovedOrOwner(address(this), _tokenId), "Token is not approved for marketplace");
        require(_price > 0, "Zero price prohibited");
        uint256 categoryToken = nftContract.getTokenCategory(_tokenId);
        uint256 amount = _price * _exchangeRate;
        nftContract.transferFrom(_msgSender(), address(this), _tokenId);
        uint256 tokenIndex = addTokenIndex(_msgSender(), _tokenId);
        _lastOfferID += 1;
        Offer memory offer = Offer({
                                    status: true,
                                    seller: _msgSender(),
                                    tokenId: _tokenId,
                                    category: categoryToken,
                                    amount: amount,
                                    tokenIndex: tokenIndex
                                });
        _offers[_lastOfferID] = offer;

        emit NewOffer(_msgSender(), _lastOfferID, _tokenId, categoryToken, amount);
    }

    function addTokenIndex(address _seller, uint256 _tokenId) private returns(uint256) {
        tokensIdsOnSell[_seller].push(_tokenId);
        uint256 tokenIndex = tokensIdsOnSell[_seller].length - 1;
        return tokenIndex;
    }

    function removeTokenIndex(address _seller, uint256 index) private {
        for (uint256 i = index; i < tokensIdsOnSell[_seller].length - 1; i++) {
            tokensIdsOnSell[_seller][i] = tokensIdsOnSell[_seller][i+1];
        }
        tokensIdsOnSell[_seller].pop();
    }

    function cancelOffer(uint256 _offerId) public {
        require(_offers[_offerId].status, "This offer is not active");
        require(_offers[_offerId].seller == _msgSender(), "You cannot close offer's that are not yours");
        nftContract.safeTransferFrom(address(this), _msgSender(), _offers[_offerId].tokenId);
        emit OfferCancelled(_offerId, _offers[_offerId].tokenId);
        removeTokenIndex(_offers[_offerId].seller, _offers[_offerId].tokenId);
        delete _offers[_offerId];
    }

    function getSellTokensIds(address _seller) external view returns(uint256[] memory) {
        return tokensIdsOnSell[_seller];       
    }

    function getCostOffer(uint256 _offerId) external view returns(uint256) {
        require(_offers[_offerId].status, "This offer is not active");
        return _offers[_offerId].amount;
    }

    function buyToken(uint256 _offerId) public  {
        require(_offers[_offerId].status, "This offer is not active");
        uint256 amount = _offers[_offerId].amount * (100 + _fee) / 100;
        require(ERC20Contract.balanceOf(_msgSender()) >= amount,"Insufficient ERC20 tokens amount to buy");
        require(ERC20Contract.allowance(_msgSender(), address(this)) >= amount, "Amount is not allowed by ERC20 holder");
        nftContract.safeTransferToken(_msgSender(), _offers[_offerId].seller, _offers[_offerId].tokenId, _offers[_offerId].category);
        ERC20Contract.safeTransferFrom(_msgSender(), _offers[_offerId].seller, _offers[_offerId].amount);
        ERC20Contract.safeTransferFrom(_msgSender(), _feeWallet, amount - _offers[_offerId].amount);
        emit OfferClosed(_msgSender(), _offerId, _offers[_offerId].tokenId);
        removeTokenIndex(_offers[_offerId].seller, _offers[_offerId].tokenId);
        delete _offers[_offerId];
    }


}