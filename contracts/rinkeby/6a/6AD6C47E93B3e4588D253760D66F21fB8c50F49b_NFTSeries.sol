// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTSeriesBase.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract NFTSeries is NFTSeriesBase, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using CoAuthors for CoAuthors.List;
    using LibCommunity for LibCommunity.Settings;
    
    LibCommunity.Settings internal communitySettings;

    event TokenAddedToSale(uint256 tokenId, uint256 amount, address consumeToken);
    event TokenRemovedFromSale(uint256 tokenId);
    event TokensAddedToSale(uint256 tokenIdFrom, uint256 tokenIdTo, uint256 amount, address consumeToken);
    
    modifier canRecord(string memory communityRole) {
        require(communitySettings._canRecord(communityRole) == true, "Sender has not in accessible List");
        _;
    }
    
    function initialize(
        string memory name,
        string memory symbol,
        LibCommunity.Settings memory communitySettings_
    ) 
        public 
        override 
        initializer 
    {
        communitySettings = communitySettings_;
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721Series_init(name, symbol);
    }
    
    function create(
        string memory URI,
        CommissionParams memory commissionParams,
        uint256 tokenAmount
    ) 
        public 
        virtual  
    {
        _create(URI, commissionParams, tokenAmount);

    }
    
    /**
     * creation NFT token and immediately put to list for sale
     * @param URI Token URI
     * @param commissionParams commission will be send to author when token's owner sell to someone it. See {INFT-CommissionParams}.
     * @param tokenAmount amount of created tokens
     * @param consumeAmount amount that need to be paid to owner when some1 buy token
     * @param consumeToken erc20 token. if set address(0) then expected coins to pay for NFT
     */
    function createAndSale(
        string memory URI,
        CommissionParams memory commissionParams,
        uint256 tokenAmount,
        uint256 consumeAmount,
        address consumeToken
    ) 
        public 
        virtual  
    {
        (, uint256 rangeId) = _create(URI, commissionParams, tokenAmount);
        
        _listForSale(rangeId, consumeAmount, consumeToken);
        
        emit TokensAddedToSale(ranges[rangeId].from, ranges[rangeId].to, consumeAmount, consumeToken);
        
    }
    
    /** 
     * returned commission that will be paid to token's author while transferring NFT
     * @param tokenId NFT tokenId
     */
    function getCommission(
        uint256 tokenId
    ) 
        public
        view
        returns(address t, uint256 r)
    {
        (, uint256 rangeId, ) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        
        (t, r) = _getCommission(tokenId);
    }
    
    /**
     * contract's owner can claim tokens mistekenly sent to this contract
     * @param erc20address ERC20 address contract
     */
    function claimLostToken(
        address erc20address
    ) 
        public 
        onlyOwner 
    {
        uint256 funds = IERC20Upgradeable(erc20address).balanceOf(address(this));
        require(funds > 0, "There are no lost tokens");
            
        bool success = IERC20Upgradeable(erc20address).transfer(_msgSender(), funds);
        //require(success, "Failed when 'transferFrom' funds");
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
        require(success);
    }
    
    /**
     * put NFT to list for sale. then anyone can buy it
     * @param tokenId NFT tokenId
     * @param amount amount that need to be paid to owner when some1 buy token
     * @param consumeToken erc20 token. if set address(0) then expected coins to pay for NFT
     */
    function listForSale(
        uint256 tokenId,
        uint256 amount,
        address consumeToken
    )
        public
    {
        uint256 rangeId = _preListForSale(tokenId);
        
        _postListForSale(rangeId, tokenId, amount, consumeToken);
        
    }
    
    function listForSale(
        uint256 tokenId,
        uint256 amount,
        address consumeToken,
        CoAuthors.Ratio[] memory proportions
    )
        public
    {
        
        uint256 rangeId = _preListForSale(tokenId);
        
        
        ranges[rangeId].onetimeConsumers.smartAdd(proportions, ranges[rangeId].author);
        
        _postListForSale(rangeId, tokenId, amount, consumeToken);
    }
    
    
    
    
    /**
     * remove NFT from list for sale.
     * @param tokenId NFT tokenId
     */
    function removeFromSale(
        uint256 tokenId
    )
        public 
    {
        (uint256 serieId, uint256 rangeId, ) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateTokenOwner(rangeId);
        
        (, uint256 newRangeId) = __splitSeries(serieId, rangeId, tokenId);
        
        ranges[newRangeId].saleData.isSale = false;    
        ranges[rangeId].onetimeConsumers.empty();
        
        emit TokenRemovedFromSale(tokenId);
    }
    
    /**
     * sale info
     * @param tokenId NFT tokenId
     * @return address consumeToken
     * @return uint256 amount
     */
    function saleInfo(
        uint256 tokenId
    )   
        public
        view
        returns(address, uint256)
    {
        (, uint256 rangeId, ) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateOnlySale(rangeId);
        
        return (ranges[rangeId].saleData.erc20Address, ranges[rangeId].saleData.amount);
    }
    
    /**
     * buying token. new owner need to pay for nft by coins. Also payment to author is expected
     * @param tokenId NFT tokenId
     */
    function buy(
        uint256 tokenId
    )
        public 
        payable
        nonReentrant
    {
        (, uint256 rangeId, bool isSingle) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateOnlySale(rangeId);
        _validateOnlySaleForCoins(rangeId);
        if (!isSingle) {
            (, rangeId) = splitSeries(tokenId);
        }

        bool success;
        uint256 funds = msg.value;
        require(funds >= ranges[rangeId].saleData.amount, "The coins sent are not enough");
        
        // Refund
        uint256 refund = (funds).sub(ranges[rangeId].saleData.amount);
        if (refund > 0) {
            (success, ) = (_msgSender()).call{value: refund}("");    
            require(success, "Failed when send back coins to caller");
        }
        
        address owner = ownerOf(tokenId);
        _transfer(owner, _msgSender(), tokenId);
        
        
        uint256 fundsLeft = ranges[rangeId].saleData.amount;
        funds = ranges[rangeId].saleData.amount;
        
        uint256 len = ranges[rangeId].onetimeConsumers.length();
    
        if (len > 0) {
            uint256 tmpFunds;     
            address tmpAddr;
            for (uint256 i = 0; i < len; i++) {
                (tmpAddr, tmpFunds) = ranges[rangeId].onetimeConsumers.at(i);
                tmpFunds = (funds).mul(tmpFunds).div(100);
                
                (success, ) = (tmpAddr).call{value: tmpFunds}("");    
                require(success, "Failed when send coins");
        
                fundsLeft = fundsLeft.sub(tmpFunds);
            }
        }
    
        if (fundsLeft>0) {
            (success, ) = (owner).call{value: fundsLeft}("");    
            require(success, "Failed when send coins to owner");
        }
        
        
        
        removeFromSale(tokenId);
        
    }
    
    /**
     * buying token. new owner need to pay for nft by tokens(See {INFT-SalesData-erc20Address}). Also payment to author is expected
     * @param tokenId NFT tokenId
     */
    function buyWithToken(
        uint256 tokenId
    )
        public 
        nonReentrant
    {
        (, uint256 rangeId, bool isSingle) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        
        _validateOnlySale(rangeId);
        _validateOnlySaleForTokens(rangeId);
        if (!isSingle) {
            (, rangeId) = splitSeries(tokenId);
        }

        uint256 needToObtain = ranges[rangeId].saleData.amount;
        
        IERC20Upgradeable saleToken = IERC20Upgradeable(ranges[rangeId].saleData.erc20Address);
        uint256 minAmount = saleToken.allowance(_msgSender(), address(this)).min(saleToken.balanceOf(_msgSender()));
        
        require (minAmount >= needToObtain, "The allowance tokens are not enough");
        
        bool success;
        
        success = saleToken.transferFrom(_msgSender(), address(this), needToObtain);
        // require(success, "Failed when 'transferFrom' funds");
        // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
        require(success);

        address owner = ownerOf(tokenId);
        _transfer(owner, _msgSender(), tokenId);
        
        
        uint256 needToObtainLeft = needToObtain;
           
        uint256 len = ranges[rangeId].onetimeConsumers.length();
        if (len > 0) {
            uint256 tmpCommission;     
            address tmpAddr;
            for (uint256 i = 0; i < len; i++) {
                (tmpAddr, tmpCommission) = ranges[rangeId].onetimeConsumers.at(i);
                tmpCommission = needToObtain.mul(tmpCommission).div(100);
                
                success = saleToken.transfer(tmpAddr, tmpCommission);
                // require(success, "Failed when 'transfer' funds to co-author");
                // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
                require(success);
                needToObtainLeft = needToObtainLeft.sub(tmpCommission);
            }
            
        }
        
        if (needToObtainLeft>0) {
            success = saleToken.transfer(owner, needToObtain);
            // require(success, "Failed when 'transfer' funds to owner");
            // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
            require(success);
        }
        removeFromSale(tokenId);
    }
    
    /**
     * anyone can offer to pay commission to any tokens transfer
     * @param tokenId NFT tokenId
     * @param amount amount of token(See {INFT-ComissionSettings-token}) 
     */
    function offerToPayCommission(
        uint256 tokenId, 
        uint256 amount 
    )
        public 
    {
        (uint256 serieId, uint256 rangeId,) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        
        (, uint256 newRangeId) = __splitSeries(serieId, rangeId, tokenId);
        
        if (amount == 0) {
            if (ranges[newRangeId].commission.offerAddresses.contains(_msgSender())) {
                ranges[newRangeId].commission.offerAddresses.remove(_msgSender());
                delete ranges[newRangeId].commission.offerPayAmount[_msgSender()];
            }
        } else {
            ranges[newRangeId].commission.offerPayAmount[_msgSender()] = amount;
            ranges[newRangeId].commission.offerAddresses.add(_msgSender());
        }
    }
    
    /**
     * reduce commission. author can to allow a token transfer for free to setup reduce commission to 10000(100%)
     * @param tokenId NFT tokenId
     * @param reduceCommissionPercent commission in percent. can be in interval [0;10000]
     */
    function reduceCommission(
        uint256 tokenId,
        uint256 reduceCommissionPercent
    ) 
        public
    {
        (uint256 serieId, uint256 rangeId, ) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateTokenAuthor(rangeId);
        _validateReduceCommission(reduceCommissionPercent);
        
        (, uint256 newRangeId) = __splitSeries(serieId, rangeId, tokenId);
        
        ranges[newRangeId].commission.reduceCommission = reduceCommissionPercent;
    }
    
    function _create(
        string memory URI,
        CommissionParams memory commissionParams,
        uint256 tokenAmount
    ) 
        internal 
        canRecord(communitySettings.roleMint) 
        returns(uint256 serieId, uint256 rangeId)
    {
               
        require(commissionParams.token != address(0), "wrong token");
        require(commissionParams.intervalSeconds > 0, "wrong intervalSeconds");
        _validateReduceCommission(commissionParams.reduceCommission);
        
        (serieId, rangeId) = _mint(msg.sender, URI, tokenAmount, commissionParams);  
    }
    
    
    function _preListForSale(
        uint256 tokenId
    )
        internal
        returns(uint256 newRangeId)
    {
         
        (uint256 serieId, uint256 rangeId, ) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateTokenOwner(rangeId);
        
        (, newRangeId) = __splitSeries(serieId, rangeId, tokenId);
    }
    
    function _postListForSale(
        uint256 rangeId,
        uint256 tokenId,
        uint256 amount,
        address consumeToken
    )
        internal
    {
       _listForSale(rangeId, amount, consumeToken);

        emit TokenAddedToSale(tokenId, amount, consumeToken);
    }
    
    function _listForSale(
        uint256 rangeId,
        uint256 amount,
        address consumeToken
    )
        internal
    {
         
        ranges[rangeId].saleData.amount = amount;
        ranges[rangeId].saleData.isSale = true;
        ranges[rangeId].saleData.erc20Address = consumeToken;
        
    }
    
    
     function _transfer(
        address from, 
        address to, 
        uint256 tokenId
    ) 
        internal 
        override 
    {
        (, uint256 newSeriesPartsId) = splitSeries(tokenId);
        _transferHook(tokenId, newSeriesPartsId);
        
        // then usual transfer as expected
        super._transfer(from, to, tokenId);
    }
    
    function _validateReduceCommission(uint256 _reduceCommission) internal pure {
        require(_reduceCommission >= 0 && _reduceCommission <= 10000, "wrong reduceCommission");
    }
    function _validateOnlySale(uint256 rangeId) internal view {
        require(ranges[rangeId].saleData.isSale == true, "Token does not in sale");
    }
    function _validateOnlySaleForCoins(uint256 rangeId) internal view {
        require(ranges[rangeId].saleData.erc20Address == address(0), "sale for coins only");
    }
    function _validateOnlySaleForTokens(uint256 rangeId) internal view {
        require(ranges[rangeId].saleData.erc20Address != address(0), "sale for tokens only");
    }
    
    /**
     * method realized collect commission logic
     * @param tokenId token ID
     */
    function _transferHook(
        uint256 tokenId,
        uint256 rangeId
    ) 
        private
    {
        address author = ranges[rangeId].author;
        address owner = ranges[rangeId].owner;
        
        address commissionToken;
        uint256 commissionAmount;
        (commissionToken, commissionAmount) = _getCommission(tokenId);
        
        if (author == address(0) || commissionAmount == 0) {
            
        } else {
            
            uint256 commissionAmountLeft = commissionAmount;
            if (ranges[rangeId].commission.offerAddresses.contains(owner)) {
                commissionAmountLeft = _transferPay(tokenId, rangeId, owner, commissionToken, commissionAmountLeft);
            }
            
            
            uint256 len = ranges[rangeId].commission.offerAddresses.length();
            uint256 tmpCommission;
            uint256 i;
            for (i = 0; i < len; i++) {
                tmpCommission = commissionAmountLeft;
                if (tmpCommission > 0) {
                    commissionAmountLeft = _transferPay(tokenId, rangeId, ranges[rangeId].commission.offerAddresses.at(i), commissionToken, tmpCommission);
                }
                if (commissionAmountLeft == 0) {
                    break;
                }
            }
            
            require(commissionAmountLeft == 0, "author's commission should be paid");
            
            // 'transfer' commission to the author
            // if Author have co-authors then pays goes proportionally to co-authors 
            // else all send to author
            // ------------------------
            bool success;
            address tmpAddr;
            len = ranges[rangeId].coauthors.length();
            commissionAmountLeft = commissionAmount;
            if (len == 0) {
            } else {

                for (i = 0; i < len; i++) {
                    (tmpAddr, tmpCommission) = ranges[rangeId].coauthors.at(i);
                    tmpCommission = commissionAmount.mul(tmpCommission).div(100);
                    
                    success = IERC20Upgradeable(commissionToken).transfer(tmpAddr, tmpCommission);
                    // require(success, "Failed when 'transfer' funds to co-author");
                    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
                    require(success);
                    commissionAmountLeft = commissionAmountLeft.sub(tmpCommission);
                }
            }    
            
            if (commissionAmountLeft > 0) {
                success = IERC20Upgradeable(commissionToken).transfer(author, commissionAmountLeft);
                // require(success, "Failed when 'transfer' funds to author");
                // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
                require(success);
            }
            
        }
    }
    
    
     /**
     * doing one interation to transfer commission from {addr} to this contract and returned {commissionAmountNeedToPay} that need to pay
     * @param tokenId token ID
     * @param addr payer's address 
     * @param commissionToken token's address
     * @param commissionAmountNeedToPay left commission that need to pay after transfer
     */
    function _transferPay(
        uint256 tokenId,
        uint256 rangeId,
        address addr,
        address commissionToken,
        uint256 commissionAmountNeedToPay
    ) 
        private
        returns(uint256 commissionAmountLeft)
    {
        uint256 minAmount = (ranges[rangeId].commission.offerPayAmount[addr]).min(IERC20Upgradeable(commissionToken).allowance(addr, address(this))).min(IERC20Upgradeable(commissionToken).balanceOf(addr));
        if (minAmount > 0) {
            if (minAmount > commissionAmountNeedToPay) {
                minAmount = commissionAmountNeedToPay;
                commissionAmountLeft = 0;
            } else {
                commissionAmountLeft = commissionAmountNeedToPay.sub(minAmount);
            }
            bool success = IERC20Upgradeable(commissionToken).transferFrom(addr, address(this), minAmount);
            // require(success, "Failed when 'transferFrom' funds");
            // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
            require(success);
            
            ranges[rangeId].commission.offerPayAmount[addr] = ranges[rangeId].commission.offerPayAmount[addr].sub(minAmount);
            if (ranges[rangeId].commission.offerPayAmount[addr] == 0) {
                delete ranges[rangeId].commission.offerPayAmount[addr];
                ranges[rangeId].commission.offerAddresses.remove(addr);
            }
            
        }
        
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/BokkyPooBahsRedBlackTreeLibrary.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./interfaces/INFTAuthorship.sol";
import "./interfaces/INFTSeries.sol";
import "./lib/CoAuthors.sol";

abstract contract NFTSeriesBase is Initializable, ContextUpgradeable, ERC165Upgradeable, INFTSeries, IERC721MetadataUpgradeable, INFTAuthorship {
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using BokkyPooBahsRedBlackTreeLibrary for BokkyPooBahsRedBlackTreeLibrary.Tree;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using CoAuthors for CoAuthors.List;

    
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to series ID
    //mapping (uint256 => uint256) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
    //event TokenCreated(address author, uint256 tokenId);
    event TokenSeriesCreated(address author, uint256 fromTokenId, uint256 toTokenId);
    
    CountersUpgradeable.Counter private _tokenIds;
    CountersUpgradeable.Counter private _seriesIds;
    
    mapping(uint256 => Serie) internal series;
    mapping(uint256 => Range) internal ranges;
    
    struct Serie {
        uint256 from;
        uint256 to;
        string uri;
        BokkyPooBahsRedBlackTreeLibrary.Tree rangesTree;
    }
    
    struct Range {
        uint256 from;
        uint256 to;
        address owner;
        address author;

        //CoAuthorsSettings coauthors;
        CoAuthors.List coauthors;
        
        CoAuthors.List onetimeConsumers;
        
        CommissionSettings commission;
        SalesData saleData;
        
    }
    
    
    function _validateTokenExists(uint256 rangeId) internal view {
        require(ranges[rangeId].owner != address(0), "Nonexistent token");
    }
    function _validateTokenOwner(uint256 rangeId) internal view {
        require(ranges[rangeId].owner == _msgSender(), "Sender is not owner of token");
    }
    function _validateTokenAuthor(uint256 rangeId) internal view {
        require(ranges[rangeId].author == _msgSender(), "sender is not author of token");
    }
    
    /**
     * can see all the tokens that an author has.
     * do not use onchain
     * @param author author's address
     */
    function tokensByAuthor(
        address author
    ) 
        public
        override
        view 
        returns(uint256[] memory) 
    {
        uint256 i;
        uint256 j;
        
        uint256 len;
        uint256 next;
        
        for(i=1; i<_seriesIds.current(); i++) {
            next = series[i].rangesTree.first();
            while (next != 0) {
                if (ranges[next].author == author) {
                  len += 1+ranges[next].to - ranges[next].from;
                }
                next = series[i].rangesTree.next(next);
            }    
        }

        uint256[] memory ret = new uint256[](len);
        uint256 counter;
        for(i=1; i<_seriesIds.current(); i++) {
            next = series[i].rangesTree.first();
                while (next != 0) {
                    if (ranges[next].author == author) {
                        for(j = ranges[next].from; j <= ranges[next].to; j++) {
                            ret[counter] = j;
                            counter = counter+1;
                        }
                    }
                    next = series[i].rangesTree.next(next);
                }    
        }
        return ret;
     
    }

    /**
     * adding co-authors ot NFT token
     * @param tokenId  token ID
     * proportions array of tuples like [co-author's addresses, co-author's proportions]
     * proportions (mul by 100). here 40% looks like "40". (40%|0.4|0.4*100=40)
     */
    function addAuthors(
        uint256 tokenId,
        CoAuthors.Ratio[] memory proportions
    ) 
        public
    {
        (, uint256 rangeId, bool isSingle) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateTokenAuthor(rangeId);
        
        if (!isSingle) {
            (, rangeId) = splitSeries(tokenId);
        }
        
        
        ranges[rangeId].coauthors.smartAdd(proportions, ranges[rangeId].author);
        
    }

    /**
     * @param to address
     * @param tokenId token ID
     */
    function transferAuthorship(
        address to, 
        uint256 tokenId
    ) 
        public 
        override
    {
        (, uint256 rangeId, bool isSingle) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        _validateTokenAuthor(rangeId);
        if (!isSingle) {
            (, rangeId) = splitSeries(tokenId);
        }
        
        address author = __getAuthor(rangeId);
        require(to != author, "transferAuthorship to current author");
        
        _changeAuthor(to, tokenId);
        
        emit TransferAuthorship(author, to, tokenId);
    }
    
    /**
     * @param tokenId token ID
     */
    function authorOf(
        uint256 tokenId
    )
        public
        override
        view
        returns (address) 
    {
        (, uint256 rangeId,) = _getSeriesIds(tokenId);
        _validateTokenExists(rangeId);
        return _getAuthor(tokenId);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(INFTSeries).interfaceId
            || interfaceId == type(IERC721Upgradeable).interfaceId
            || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        
        return owner;
    }
    
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        
        (uint256 serieId,/* uint256 rangeId*/,) = _getSeriesIds(tokenId);
        
        // string memory base = _baseURI();
        string memory _tokenURI = series[serieId].uri;
        
        // If there is no base URI, return the token URI.
        // if (bytes(base).length == 0) {
        //     return _tokenURI;
        // }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        // if (bytes(_tokenURI).length > 0) {
        //     return string(abi.encodePacked(base, _tokenURI));
        // }
        
        
        if (bytes(_tokenURI).length > 0) {
            uint256 count = (series[serieId].to).sub((series[serieId].from)).add(1);
            uint256 index = (tokenId).sub(series[serieId].from).add(1);
            
            // ?&t=726&s=4&i=4&c=10
            return string(abi.encodePacked(
            _tokenURI,
            's=', serieId.toString(),   //serieId
            '&i=', index.toString(),    //indexId
            '&t=', tokenId.toString(),  //tokenId
            '&c=', count.toString()     //count
            ));
        }

        return "";
    }
    
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = NFTSeriesBase.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    /**
     * commission amount that need to be paid while NFT token transferring
     * @param tokenId NFT tokenId
     */
    function _getCommission(
        uint256 tokenId
    ) 
        internal 
        virtual
        view
        returns(address t, uint256 r)
    {
        (, uint256 rangeId, ) = _getSeriesIds(tokenId);

        //initialCommission
        r = ranges[rangeId].commission.amount;
        t = ranges[rangeId].commission.token;
        if (r == 0) {
            
        } else {
            if (ranges[rangeId].commission.multiply == 10000) {
                // left initial commission
            } else {
                
                uint256 intervalsSinceCreate = (block.timestamp.sub(ranges[rangeId].commission.createdTs)).div(ranges[rangeId].commission.intervalSeconds);
                uint256 intervalsSinceLastTransfer = (block.timestamp.sub(ranges[rangeId].commission.lastTransferTs)).div(ranges[rangeId].commission.intervalSeconds);
                
                // (   
                //     initialValue * (multiply ^ intervals) + (intervalsSinceLastTransfer * accrue)
                // ) * (10000 - reduceCommission) / 10000
                
                for(uint256 i = 0; i < intervalsSinceCreate; i++) {
                    r = r.mul(ranges[rangeId].commission.multiply).div(10000);
                    
                }
                
                r = r.add(
                        intervalsSinceLastTransfer.mul(ranges[rangeId].commission.accrue)
                    );
                
            }
            
            r = r.mul(
                        uint256(10000).sub(ranges[rangeId].commission.reduceCommission)
                    ).div(uint256(10000));
                
        }
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721Series_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Series_init_unchained(name_, symbol_);
    }

    function __ERC721Series_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        
        _tokenIds.increment();
        _seriesIds.increment();
       // _seriesPartsIds.increment();
    }

    function _ownerOf(uint256 tokenId) internal view returns (address owner) {
        
        (, uint256 rangeId, ) = _getSeriesIds(tokenId);
        owner = ranges[rangeId].owner;
        
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    
    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = NFTSeriesBase.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    // function _safeMint(address to, string memory URI, uint256 tokenAmount) internal virtual {
    //     _safeMint(to, URI, tokenAmount, "");
    // }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    // function _safeMint(address to, string memory URI, uint256 tokenAmount, bytes memory _data) internal virtual {
    //     _mint(to, URI, tokenAmount);
    //     require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    // }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, string memory URI, uint256 tokenAmount, CommissionParams memory commissionParams) internal virtual returns(uint256 serieId, uint256 rangeId) {
       
        require(to != address(0), "ERC721: mint to the zero address");
        uint256 tokenId = _tokenIds.current();
        uint256 lastTokenId = tokenId+tokenAmount-1;
        
        serieId = _seriesIds.current();
        
        emit TokenSeriesCreated(_msgSender(), tokenId, lastTokenId); 
        
        _tokenIds._value += tokenAmount ;
        
        _balances[to] += tokenAmount;
        
        series[serieId].from = tokenId;
        series[serieId].to = lastTokenId;
        series[serieId].uri = URI;
        
        rangeId = tokenId;
        
        ranges[rangeId].from = tokenId;
        ranges[rangeId].to = lastTokenId;
        ranges[rangeId].owner = to;
        ranges[rangeId].author = to;
        
        ranges[rangeId].commission.token = commissionParams.token;
        ranges[rangeId].commission.amount = commissionParams.amount;
        ranges[rangeId].commission.multiply = (commissionParams.multiply == 0 ? 10000 : commissionParams.multiply);
        ranges[rangeId].commission.accrue = commissionParams.accrue;
        ranges[rangeId].commission.intervalSeconds = commissionParams.intervalSeconds;
        ranges[rangeId].commission.reduceCommission = commissionParams.reduceCommission;
        ranges[rangeId].commission.createdTs = block.timestamp;
        ranges[rangeId].commission.lastTransferTs = block.timestamp;
        //-----------------
        
        series[serieId].rangesTree.insert(rangeId);
        _seriesIds.increment();
        
        return(serieId, rangeId);
    }
    
    function _getSeriesIds(uint256 tokenId) internal view returns(uint256 serieId, uint256 rangeId, bool isSingleRange) {
        
        for(uint256 i=1; i<_seriesIds.current(); i++) {
            
            if (tokenId >= series[i].from && tokenId <= series[i].to) {
                
                uint256 j = series[i].rangesTree.root;
                while (j != 0) {
                    if (tokenId >= ranges[j].from && tokenId <= ranges[j].to) {
                        return (
                            i,
                            j,
                            (tokenId == ranges[j].from && tokenId == ranges[j].to) ? true : false
                        );
                    }
                    if (tokenId < ranges[j].from && tokenId < ranges[j].to) {
                        j = series[i].rangesTree.prev(j);
                    } else if (tokenId > ranges[j].from && tokenId > ranges[j].to) {
                        j = series[i].rangesTree.next(j);
                    }
                }
                
            }
            
           
        }
        return (0,0,false);
    }
    
    
    function _changeOwner(address newOwner, uint256 tokenId) internal {
        (uint256 serieId, uint256 newRangeId) = splitSeries(tokenId);

        if (newOwner == address(0)) {
            delete ranges[newRangeId];
            series[serieId].rangesTree.remove(newRangeId);
        } else {
            ranges[newRangeId].owner = newOwner;
        }
    }
    
    function _changeAuthor(address newAuthor, uint256 tokenId) internal {
        (, uint256 rangeId) = splitSeries(tokenId);

        ranges[rangeId].author = newAuthor;
        
        ranges[rangeId].coauthors.removeIfExists(newAuthor);
        
    }
    
    /**
     * method will find serie by tokenId, split it and make another series with single range [tokenId; tokenId] with newOwner
     * 
     */
     
    function splitSeries(uint256 tokenId) internal returns(uint256 infoId, uint256 newRangeId) {
        (uint256 serieId, uint256 rangeId, ) = _getSeriesIds(tokenId);
        return __splitSeries(serieId, rangeId, tokenId);
    }
    
    /**
     * @dev here we split series to 3 parts and copying all data into new single range [tokenId; tokenId].
     * this trick are passes with nested mapping because any manipulation with mappings happens after splitted.
     * so if want to save to mapping into whole range and than split to single range that can not be possible without loop over all mapping(by some indexes i guees)
     */
    function __splitSeries(uint256 serieId, uint256 rangeId, uint256 tokenId) internal returns(uint256, uint256) {
        uint256 newRangeId;
        if (serieId != 0 && rangeId != 0) {
            if (ranges[rangeId].from == tokenId && ranges[rangeId].to == tokenId) {
                // no need split it's last part
                newRangeId = rangeId;
            } else {
                uint256 tmpRangeId; 
                uint256 tmpRangeId2;
                // create ranges
                if (ranges[rangeId].from == tokenId) {
                    newRangeId = rangeId;
                    // when split (id=4)[4:8] by 4.  i.e. it would be (id=4)[4:4] (id=5)[5:8]
                    
                    //----
                    tmpRangeId = rangeId+1;
                    //---
                    // ranges[tmpRangeId].from = tokenId+1;
                    // ranges[tmpRangeId].to = ranges[rangeId].to;
                    //---
                    // ranges[tmpRangeId].owner = ranges[rangeId].owner;
                    // ranges[tmpRangeId].author = ranges[rangeId].author;
                    // ranges[tmpRangeId].commission.token             = ranges[rangeId].commission.token;
                    // ranges[tmpRangeId].commission.amount            = ranges[rangeId].commission.amount;
                    // ranges[tmpRangeId].commission.multiply          = ranges[rangeId].commission.multiply;
                    // ranges[tmpRangeId].commission.accrue            = ranges[rangeId].commission.accrue;
                    // ranges[tmpRangeId].commission.intervalSeconds   = ranges[rangeId].commission.intervalSeconds;
                    // ranges[tmpRangeId].commission.reduceCommission  = ranges[rangeId].commission.reduceCommission;
                    // ranges[tmpRangeId].commission.createdTs         = ranges[rangeId].commission.createdTs;
                    // ranges[tmpRangeId].commission.lastTransferTs    = ranges[rangeId].commission.lastTransferTs;
                    copyRangePart(tmpRangeId, rangeId, tokenId+1, ranges[rangeId].to);
                    //---------
                    
                    ranges[newRangeId].from = tokenId;
                    ranges[newRangeId].to = tokenId;
                    
                    series[serieId].rangesTree.insert(tmpRangeId);
                } else {
                    //  when split (id==N)[4:8].  where 4<N<=8
                    
                    newRangeId = tokenId;
                    //---
                    // ranges[newRangeId].from = tokenId;
                    // ranges[newRangeId].to = tokenId;
                    //---
                    // ranges[newRangeId].owner = ranges[rangeId].owner;
                    // ranges[newRangeId].author = ranges[rangeId].author;
                    // ranges[newRangeId].commission.token             = ranges[rangeId].commission.token;
                    // ranges[newRangeId].commission.amount            = ranges[rangeId].commission.amount;
                    // ranges[newRangeId].commission.multiply          = ranges[rangeId].commission.multiply;
                    // ranges[newRangeId].commission.accrue            = ranges[rangeId].commission.accrue;
                    // ranges[newRangeId].commission.intervalSeconds   = ranges[rangeId].commission.intervalSeconds;
                    // ranges[newRangeId].commission.reduceCommission  = ranges[rangeId].commission.reduceCommission;
                    // ranges[newRangeId].commission.createdTs         = ranges[rangeId].commission.createdTs;
                    // ranges[newRangeId].commission.lastTransferTs    = ranges[rangeId].commission.lastTransferTs;
                    copyRangePart(newRangeId, rangeId, tokenId, tokenId);
                    //---------
                    
                    series[serieId].rangesTree.insert(newRangeId);
                    
                    // if N!=8 then create right part
                    if (tokenId != ranges[rangeId].to) {
                        tmpRangeId2 = tokenId+1;
                        //---
                        // ranges[tmpRangeId2].from = tokenId+1;
                        // ranges[tmpRangeId2].to = ranges[rangeId].to;
                        //---
                        // ranges[tmpRangeId2].owner = ranges[rangeId].owner;
                        // ranges[tmpRangeId2].author = ranges[rangeId].author;
                        // ranges[tmpRangeId2].commission.token             = ranges[rangeId].commission.token;
                        // ranges[tmpRangeId2].commission.amount            = ranges[rangeId].commission.amount;
                        // ranges[tmpRangeId2].commission.multiply          = ranges[rangeId].commission.multiply;
                        // ranges[tmpRangeId2].commission.accrue            = ranges[rangeId].commission.accrue;
                        // ranges[tmpRangeId2].commission.intervalSeconds   = ranges[rangeId].commission.intervalSeconds;
                        // ranges[tmpRangeId2].commission.reduceCommission  = ranges[rangeId].commission.reduceCommission;
                        // ranges[tmpRangeId2].commission.createdTs         = ranges[rangeId].commission.createdTs;
                        // ranges[tmpRangeId2].commission.lastTransferTs    = ranges[rangeId].commission.lastTransferTs;
                        copyRangePart(tmpRangeId2, rangeId, tokenId+1, ranges[rangeId].to);
                        //---------
                        
                        series[serieId].rangesTree.insert(tmpRangeId2);
                    }
                    
                    // finally reduce initial range and make it like "left part"
                    ranges[rangeId].to = tokenId-1;
                }
            }
        } else {
            return (0, 0);    
        }
        
        return (serieId, newRangeId);
    }
    
    function copyRangePart(
        uint256 newId, 
        uint256 oldId, 
        uint256 from, 
        uint256 to
    ) 
        private
    {
        ranges[newId].from = from;
        ranges[newId].to = to;
        
        ranges[newId].owner = ranges[oldId].owner;
        ranges[newId].author = ranges[oldId].author;
        
        ranges[newId].commission.token             = ranges[oldId].commission.token;
        ranges[newId].commission.amount            = ranges[oldId].commission.amount;
        ranges[newId].commission.multiply          = ranges[oldId].commission.multiply;
        ranges[newId].commission.accrue            = ranges[oldId].commission.accrue;
        ranges[newId].commission.intervalSeconds   = ranges[oldId].commission.intervalSeconds;
        ranges[newId].commission.reduceCommission  = ranges[oldId].commission.reduceCommission;
        ranges[newId].commission.createdTs         = ranges[oldId].commission.createdTs;
        ranges[newId].commission.lastTransferTs    = ranges[oldId].commission.lastTransferTs;
    }
    
    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = NFTSeriesBase.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        //delete _owners[tokenId];
        _changeOwner(address(0), tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(NFTSeriesBase.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        
        
        _changeOwner(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(NFTSeriesBase.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    
        
    function _getAuthor(uint256 tokenId) private view returns(address) {
        (, uint256 rangeId, ) = _getSeriesIds(tokenId);
        return __getAuthor(rangeId);
    }
    function __getAuthor(uint256 rangeId) private view returns(address) {
        return ranges[rangeId].author;
    }

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ICommunity {
    function memberCount(string calldata role) external view returns(uint256);
    function getRoles(address member)external view returns(string[] memory);
    function getMember(string calldata role) external view returns(address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTAuthorship {
    
    event TransferAuthorship(address indexed from, address indexed to, uint256 indexed tokenId);
   
    /**
     * can see all the tokens that an author has.
     * @param author author's address
     */
    function tokensByAuthor(address author) external returns(uint256[] memory);
    

    /**
     * @param to address
     * @param tokenId token ID
     */
    function transferAuthorship(address to, uint256 tokenId) external;
    
    /**
     * @param tokenId token ID
     */
    function authorOf(uint256 tokenId) external returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../lib/LibCommunity.sol";

interface INFTSeries  is IERC721Upgradeable {
    
    struct CommissionParams {
        address token; 
        uint256 amount;
        uint256 multiply;
        uint256 accrue;
        uint256 intervalSeconds;
        uint256 reduceCommission;
    }
    struct CommissionSettings {
        address token; 
        uint256 amount;
        uint256 multiply;
        uint256 accrue;
        uint256 intervalSeconds;
        uint256 reduceCommission;
        uint256 createdTs;
        uint256 lastTransferTs;
        mapping (address => uint256) offerPayAmount;
        EnumerableSetUpgradeable.AddressSet offerAddresses;
    }

    struct SalesData {
        address erc20Address;
        uint256 amount;
        bool isSale;
    }
    
    
    function initialize(string memory, string memory, LibCommunity.Settings memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
library BokkyPooBahsRedBlackTreeLibrary {

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
        
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }

    uint private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(Tree storage self) internal view returns (uint _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(Tree storage self, uint target) internal view returns (uint cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(Tree storage self, uint key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(uint key) internal pure returns (bool) {
        return key == EMPTY;
    }
    function getEmpty() internal pure returns (uint) {
        return EMPTY;
    }
    function getNode(Tree storage self, uint key) internal view returns (uint _returnKey, uint _parent, uint _left, uint _right, bool _red) {
        require(exists(self, key));
        return(key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    function insert(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        uint cursor = EMPTY;
        uint probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }
    function remove(Tree storage self, uint key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        uint probe;
        uint cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function treeMaximum(Tree storage self, uint key) private view returns (uint) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].right;
        uint keyParent = self.nodes[key].parent;
        uint cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(Tree storage self, uint key) private {
        uint cursor = self.nodes[key].left;
        uint keyParent = self.nodes[key].parent;
        uint cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint a, uint b) private {
        uint bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(Tree storage self, uint key) private {
        uint cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library CoAuthors{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    
    using SafeMathUpgradeable for uint256;
    
    struct List {
        mapping(address => uint256) proportions;
        EnumerableSetUpgradeable.AddressSet addresses;
    }
    
    struct Ratio {
        address addr;
        uint256 proportion;
    }
    
    
    function addBulk(List storage list, address[] memory addresses, uint256[] memory proportions) external returns (bool) {
        
        _empty(list);
        
        uint256 i;
        for (i = 0; i < addresses.length; i++) {
            
            list.addresses.add(addresses[i]);
            list.proportions[addresses[i]] = proportions[i];
            
        }
        
        return true;
    }
    function empty(List storage list) external {
        
        // make a trick. 
        // remove all items and push new. checking on duplicate values in progress
        for (uint256 i =0; i<list.addresses._inner._values.length; i++) {
            delete list.addresses._inner._indexes[list.addresses._inner._values[i]];
        }
        delete list.addresses._inner._values;
    }
    
    function add(List storage list, address addr, uint256 proportion) external returns (bool) {
        
        list.addresses.add(addr);
        list.proportions[addr] = proportion;
            
        return true;
    }
    
    function smartAdd(List storage list, Ratio[] memory ratio, address author) external returns (bool) {
        uint256 tmpProportions;
        for (uint256 i = 0; i < ratio.length; i++) {
            
            require (ratio[i].addr != author, "author can not be in list");
            require (list.addresses.contains(ratio[i].addr) == false, "can not have a duplicate values");
            require (ratio[i].proportion != 0, "proportions can not be zero value");
            
            tmpProportions = tmpProportions.add(ratio[i].proportion);
            
            //add(list, ratio[i].addr, ratio[i].proportion);
            list.addresses.add(ratio[i].addr);
            list.proportions[ratio[i].addr] = ratio[i].proportion;
            //---
        
        }
        require (tmpProportions <= 100, "total proportions can not be more than 100%");
        
            
        return true;
    }
    
    function contains(List storage list, address newAuthor) external view returns(bool) {
        return list.addresses.contains(newAuthor);
    }
    
    function removeIfExists(List storage list, address newAuthor) external {
        if (list.addresses.contains(newAuthor) == true) {
            list.addresses.remove(newAuthor);
        }
    }
    
    function length(List storage list) external view returns(uint256) {
        return list.addresses.length();
    }
    
    function at(List storage list, uint256 i) external view returns(address, uint256) {
        address addr = list.addresses.at(i);
        return (addr, list.proportions[addr]);
    }
    
    function _empty(List storage list) private {
        
        // make a trick. 
        // remove all items and push new. checking on duplicate values in progress
        for (uint256 i =0; i<list.addresses._inner._values.length; i++) {
            delete list.addresses._inner._indexes[list.addresses._inner._values[i]];
        }
        delete list.addresses._inner._values;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICommunity.sol";

library LibCommunity{
    
    struct Settings {
        address addr;
        string roleMint;
    }
    
    
    /**
     * return true if {roleName} exist in Community contract for msg.sender
     * @param roleName role name
     */
    function _canRecord(
        Settings storage settings,
        string memory roleName
    ) 
        external 
        view 
        returns(bool s)
    {
        //s = false;
        if (settings.addr == address(0)) {
            // if the community address set to zero then we must skip the check
            s = true;
        } else {
            string[] memory roles = ICommunity(settings.addr).getRoles(msg.sender);
            for (uint256 i=0; i< roles.length; i++) {
                
                if (keccak256(abi.encodePacked(roleName)) == keccak256(abi.encodePacked(roles[i]))) {
                    s = true;
                }
            }
        }

    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

