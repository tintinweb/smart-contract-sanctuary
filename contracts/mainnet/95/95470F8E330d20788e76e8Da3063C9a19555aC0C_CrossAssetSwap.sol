/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
}


contract MarketRegistry is Ownable {
    
    enum MarketType {Buy, Sell, Both}
    enum CurrencySupported {Eth, Erc20}
    
    struct BuyDetails {
        uint256 marketId;
        bytes buyData;
    }

    struct SellDetails {
        uint256 marketId;
        bytes sellData;
    }

    struct Market {
        MarketType marketType;
        CurrencySupported currencySupported;
        address proxy;
        bool isActive;
    }

    Market[] public markets;

    constructor(
        MarketType[] memory marketTypes,
        CurrencySupported[] memory currenciesSupported, 
        address[] memory proxies
    ) {
        for (uint256 i = 0; i < marketTypes.length; i++) {
            markets.push(Market(marketTypes[i], currenciesSupported[i], proxies[i], true));    
        }
    }

    function addMarket(
        MarketType marketType, 
        CurrencySupported currencySupported, 
        address proxy
    ) external onlyOwner {
        markets.push(Market(marketType, currencySupported, proxy, true));
    }

    function setMarketStatus(uint256 marketId, bool newStatus) external onlyOwner {
        Market storage market = markets[marketId];
        market.isActive = newStatus;
    }

    function setMarketProxy(uint256 marketId, address newProxy) external onlyOwner {
        Market storage market = markets[marketId];
        market.proxy = newProxy;
    }
}

contract ExchangeRegistry is Ownable {
    
    struct SwapDetails {
        uint256 exchangeId;
        bytes swapData; 
    }

    struct Exchange {
        address proxy;
        bool isActive;
    }

    Exchange[] public exchanges;

    constructor(address[] memory proxies) {
        for (uint256 i = 0; i < proxies.length; i++) {
            exchanges.push(Exchange(proxies[i], true));
        }
    }

    function addExchange(
        address proxy
    ) external onlyOwner {
        exchanges.push(Exchange(proxy, true));
    }

    function setExchangeStatus(uint256 exchangeId, bool newStatus) external onlyOwner {
        Exchange storage exchange = exchanges[exchangeId];
        exchange.isActive = newStatus;
    }

    function setExchangeProxy(uint256 exchangeId, address newProxy) external onlyOwner {
        Exchange storage exchange = exchanges[exchangeId];
        exchange.proxy = newProxy;
    }

}

interface IERC20 {
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
}

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;
    
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface ISellMarket {
    function sellERC721ForERC20Equivalent(
        bytes memory data
    ) external returns (address _erc20Address, uint256 _erc20Amount);

    function sellERC1155ForERC20Equivalent(
        bytes memory data
    ) external returns (address erc20, uint256 amount);

    function sellERC1155BatchForERC20Equivalent(
        bytes memory data
    ) external returns (address erc20, uint256 amount);
}

interface IBuyMarket {
    function buyAssetsForEth(bytes memory data, address recipient) external;
    function buyAssetsForErc20(bytes memory data, address recipient) external;
    function estimateBatchAssetPriceInEth(bytes memory data) external view returns(uint256 totalCost);
    function estimateBatchAssetPriceInErc20(bytes memory data) external view returns(address[] memory erc20Addrs, uint256[] memory amounts);
}

interface IExchange {
    function swapExactERC20ForERC20(
        address _from,
        address _to,
        address _recipient,
        uint256 _amountIn
    ) external returns (uint256[] memory amounts);

    function swapERC20ForExactERC20(
        address _from,
        address _to,
        address _recipient,
        uint256 _amountOut
    ) external returns (uint256[] memory amounts);

    function swapERC20ForExactETH(
        address _from,
        address _recipient,
        uint256 _amountOut
    ) external returns (uint256[] memory amounts);

    function swapExactERC20ForETH(
        address _from,
        address _recipient,
        uint256 _amountIn
    ) external returns (uint256[] memory amounts);

    function swapETHForExactERC20(
        address _to,
        address _recipient,
        uint256 _amountOut
    ) external returns (uint256[] memory amounts);

    function swapExactETHForERC20(
        address _to,
        address _recipient,
        uint256 _amountOutMin
    ) external returns (uint256[] memory amounts);
}

contract CrossAssetSwap is Ownable {

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint256[] ids;
        MarketRegistry.SellDetails[] sellDetails;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
        MarketRegistry.SellDetails[] sellDetails;
    }

    MarketRegistry public marketRegistry;
    ExchangeRegistry public exchangeRegistry;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant MAINTAINER = 0x073Ab1C0CAd3677cDe9BDb0cDEEDC2085c029579;
    uint256 public FEES = 300;

    constructor(address _marketRegistry, address _exchangeRegistry) {
        marketRegistry = MarketRegistry(_marketRegistry);
        exchangeRegistry = ExchangeRegistry(_exchangeRegistry);
    }

    function updateFees(uint256 newFees) external {
        require(msg.sender == MAINTAINER, "updateFees: invalid caller.");
        FEES = newFees;
    }

    function _transferHelper(
        ERC20Details memory _inputERC20s,
        ERC721Details[] memory inputERC721s,
        ERC1155Details[] memory inputERC1155s
    ) internal returns (address[] memory _erc20AddrsIn, uint256[] memory _erc20AmountsIn) {
        address[] memory _addrsIn1;
        address[] memory _addrsIn2; 
        uint256[] memory _amountsIn1;
        uint256[] memory _amountsIn2;

        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < _inputERC20s.tokenAddrs.length; i++) {
            require(
                IERC20(_inputERC20s.tokenAddrs[i]).transferFrom(
                    msg.sender,
                    address(this),
                    _inputERC20s.amounts[i]
                ),
                "_transferHelper: transfer failed"
            );
        }
        // transfer ERC721 tokens from the sender to this contract
        for (uint256 i = 0; i < inputERC721s.length; i++) {
            for (uint256 j = 0; j < inputERC721s[i].ids.length; j++) {
                IERC721(inputERC721s[i].tokenAddr).transferFrom(
                    msg.sender,
                    address(this),
                    inputERC721s[i].ids[j]
                );
            }
            (_addrsIn1, _amountsIn1) = _sellNFT(inputERC721s[i].sellDetails);
        }
        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < inputERC1155s.length; i++) {
            IERC1155(inputERC1155s[i].tokenAddr).safeBatchTransferFrom(
                msg.sender,
                address(this),
                inputERC1155s[i].ids,
                inputERC1155s[i].amounts,
                ""
            );
            (_addrsIn2, _amountsIn2) = _sellNFT(inputERC1155s[i].sellDetails);
        }
        // return _erc20AddrsIn, _erc20AmountsIn
        {
            uint256 totalLen = msg.value > 0 
            ? _inputERC20s.tokenAddrs.length+_addrsIn1.length+_addrsIn2.length+1
            : _inputERC20s.tokenAddrs.length+_addrsIn1.length+_addrsIn2.length;
            _erc20AddrsIn = new address[](totalLen);
            _erc20AmountsIn = new uint256[](totalLen);
            if (msg.value > 0) {
                _erc20AddrsIn[totalLen-1] = ETH; 
                _erc20AmountsIn[totalLen-1] = msg.value;
            }
            // populate the arrays
            for (uint256 i = 0; i < _inputERC20s.tokenAddrs.length; i++) {
                _erc20AddrsIn[i] = _inputERC20s.tokenAddrs[i];
                _erc20AmountsIn[i] = _inputERC20s.amounts[i];
            }

            totalLen = _inputERC20s.tokenAddrs.length-1;
            for (uint256 i = 0; i < _addrsIn1.length; i++) {
                _erc20AddrsIn[_inputERC20s.tokenAddrs.length+i] = _addrsIn1[i];
                _erc20AmountsIn[_inputERC20s.tokenAddrs.length+i] = _amountsIn1[i];
            }

            totalLen = _inputERC20s.tokenAddrs.length+_addrsIn1.length-1;
            for (uint256 i = 0; i < _addrsIn2.length; i++) {
                _erc20AddrsIn[totalLen+i] = _addrsIn2[i];
                _erc20AmountsIn[totalLen+i] = _amountsIn2[i];
            }
        }
    }

    // swaps any combination of ERC-20/721/1155
    // User needs to approve assets before invoking swap
    function multiAssetSwap(
        ERC20Details memory inputERC20s,
        ERC721Details[] memory inputERC721s,
        ERC1155Details[] memory inputERC1155s,
        MarketRegistry.BuyDetails[] memory buyDetails,
        ExchangeRegistry.SwapDetails[] memory swapDetails,
        address[] memory addrs // [changeIn, exchange, recipient]
    ) payable external {
        address[] memory _erc20AddrsIn;
        uint256[] memory _erc20AmountsIn;
        
        // transfer all tokens
        (_erc20AddrsIn, _erc20AmountsIn) = _transferHelper(
            inputERC20s,
            inputERC721s,
            inputERC1155s
        );

        // execute all swaps
        _swap(
            swapDetails,
            buyDetails,
            _erc20AmountsIn,
            _erc20AddrsIn,
            addrs[0],
            addrs[1],
            addrs[2]
        );
    }
    event Data(ERC721Details[]);
    function buyNftForERC20(
        MarketRegistry.BuyDetails[] memory buyDetails,
        ExchangeRegistry.SwapDetails[] memory swapDetails,
        ERC20Details memory inputErc20Details,
        address[] memory addrs // [changeIn, exchange, recipient]
    ) external {
        // transfer the fees
        require(
            IERC20(inputErc20Details.tokenAddrs[0]).transferFrom(msg.sender, MAINTAINER, FEES*inputErc20Details.amounts[0]/10000),
            "buyNftForERC20: fees transfer failed"
        );
        // transfer the inputErc20 to the contract
        require(
            IERC20(inputErc20Details.tokenAddrs[0]).transferFrom(msg.sender, address(this), (10000-FEES)*inputErc20Details.amounts[0]/10000),
            "buyNftForERC20: transfer failed"
        );
        // swap to desired assets if needed
        for (uint256 i=0; i < swapDetails.length; i++) {
            (address proxy, ) = exchangeRegistry.exchanges(swapDetails[i].exchangeId);
            (bool success, ) = proxy.delegatecall(swapDetails[i].swapData);
            require(success, "buyNftForERC20: swap failed.");
        }

        // buy NFTs
        _buyNFT(buyDetails);

        // Note: We know it as a fact that only input ERC20 can be the dust asset
        // return remaining input ERC20
        if(addrs[0] == inputErc20Details.tokenAddrs[0]) {
            IERC20(inputErc20Details.tokenAddrs[0]).transfer(msg.sender, IERC20(inputErc20Details.tokenAddrs[0]).balanceOf(address(this)));
        }
        // return remaining ETH
        else if(addrs[0] == ETH) {
            (bool success, ) = addrs[1].delegatecall(abi.encodeWithSignature("swapExactERC20ForETH(address,address,uint256)", inputErc20Details.tokenAddrs[0], addrs[2], IERC20(inputErc20Details.tokenAddrs[0]).balanceOf(address(this))));
            require(success, "buyNftForERC20: return failed.");
        }
        // return remaining ERC20
        else {
            (bool success, ) = addrs[1].delegatecall(abi.encodeWithSignature("swapExactERC20ForERC20(address,address,address,uint256)", inputErc20Details.tokenAddrs[0], addrs[0], addrs[2], IERC20(inputErc20Details.tokenAddrs[0]).balanceOf(address(this))));
            require(success, "buyNftForERC20: return failed.");
        }
    }

    function buyNftForEth(
        MarketRegistry.BuyDetails[] memory buyDetails,
        ExchangeRegistry.SwapDetails[] memory swapDetails,
        address[] memory addrs // [changeIn, exchange, recipient]
    ) external payable {
        bool success;
        (success, ) = MAINTAINER.call{value:FEES*address(this).balance/10000}('');
        require(success, "buyNftForEth: fees failed.");

        // swap to desired assets if needed
        for (uint256 i=0; i < swapDetails.length; i++) {
            (address proxy, ) = exchangeRegistry.exchanges(swapDetails[i].exchangeId);
            (success, ) = proxy.delegatecall(swapDetails[i].swapData);
            require(success, "buyNftForEth: swap failed.");
        }

        // buy NFT
        _buyNFT(buyDetails);

        // Note: We know it as a fact that only Eth can be the dust asset
        // return remaining ETH
        if(addrs[0] == ETH) {
            (success, ) = msg.sender.call{value:address(this).balance}('');
            require(success, "buyNftForEth: return failed.");
        }
        // return remaining ERC20
        else {
            (success, ) = addrs[1].delegatecall(abi.encodeWithSignature("swapExactETHForERC20(address,address,uint256)", addrs[0], addrs[2], 0));
            require(success, "buyNftForEth: return failed.");
        }
    }

    function _sellNFT(
        MarketRegistry.SellDetails[] memory _sellDetails
    ) internal returns(address[] memory erc20Addrs, uint256[] memory erc20Amounts) {
        erc20Addrs = new address[](_sellDetails.length);
        erc20Amounts = new uint256[](_sellDetails.length);

        // sell ERC1155 assets to respective markets
        for (uint256 i = 0; i < _sellDetails.length; i++) {
            // fetch the market details
            (, , address _proxy, bool _isActive) = marketRegistry.markets(_sellDetails[i].marketId);
            // the market should be active 
            require(_isActive, "_sellNFT: InActive Market");
            // sell the specified asset
            (bool success, bytes memory data) = _proxy.delegatecall(_sellDetails[i].sellData);
            // check if the delegatecall passed successfully
            require(success, "_sellNFT: sell failed.");
            // populate return values            
            (erc20Addrs[i], erc20Amounts[i]) = abi.decode(
                data,
                (address, uint256)
            );
        }
    }

    function _buyNFT(
        MarketRegistry.BuyDetails[] memory _buyDetails
    ) internal {
        for (uint256 i = 0; i < _buyDetails.length; i++) {
            // get market details
            (, , address _proxy, bool _isActive) = marketRegistry.markets(_buyDetails[i].marketId);
            // market should be active
            require(_isActive, "function: InActive Market");
            // buy NFT with ETH or ERC20
            (bool success, ) = _proxy.delegatecall(_buyDetails[i].buyData);
            // check if the delegatecall passed successfully
            require(success, "_buyNFT: buy failed.");
        }
    }

    function _returnChange(
        address _changeIn,
        address _erc20AddrIn,
        address _recipient,
        address _proxy,
        uint256 _erc20AmountIn
    ) internal {
        bool success;
        // in case desired changeIn is NOT the equivalent ERC20
        if (_changeIn != _erc20AddrIn) {
            // get market address
            // (address proxy, ) = exchangeRegistry.exchanges(_exchangeId);
            // in case input asset is ETH
            if(_erc20AddrIn == ETH) {
                (success, ) = _proxy.delegatecall(abi.encodeWithSignature("swapExactETHForERC20(address,address,uint256)", _changeIn, _recipient, 0));
                require(success, "_returnChange: return failed.");
            }
            // in case changeIn is ETH
            else if(_changeIn == ETH) {
                // Convert all the _erc20Amount to _changeIn ERC20
                (success, ) = _proxy.delegatecall(abi.encodeWithSignature("swapExactERC20ForETH(address,address,uint256)", _erc20AddrIn, _recipient, _erc20AmountIn));
                require(success, "_returnChange: return failed.");
            }
            // in case changeIn is some other ERC20
            else {
                // execute exchange
                (success, ) = _proxy.delegatecall(abi.encodeWithSignature("swapExactERC20ForERC20(address,address,address,uint256)", _erc20AddrIn, _changeIn, _recipient, _erc20AmountIn));
                require(success, "_returnChange: return failed.");
            }
        }
        // in case desired changeIn is the equivalent ERC20
        else {
            IERC20(_changeIn).transfer(_recipient, _erc20AmountIn);
        }
    }

    function _swap(
        ExchangeRegistry.SwapDetails[] memory _swapDetails,
        MarketRegistry.BuyDetails[] memory _buyDetails,
        uint256[] memory _erc20AmountsIn,
        address[] memory _erc20AddrsIn,
        address _changeIn,
        address _exchange,
        address _recipient
    ) internal {
        bool success;
        // in case user does NOT want to buy any NFTs 
        if(_buyDetails.length == 0) {
            for(uint256 i = 0; i < _erc20AddrsIn.length; i++) {
                _returnChange(
                    _changeIn,
                    _erc20AddrsIn[i],
                    _recipient,
                    _exchange,
                    _erc20AmountsIn[i]
                );
            }
        }
        // in case user wants to buy NFTs
        else {
            for (uint256 i = 0; i < _swapDetails.length; i++) {
                // get market address
                (address proxy, ) = exchangeRegistry.exchanges(_swapDetails[i].exchangeId);
                // execute swap 
                (success, ) = proxy.delegatecall(_swapDetails[i].swapData);
                require(success, "_swap: swap failed.");
            }

            // buy the NFTs
            _buyNFT(_buyDetails);

            // return remaining amount to the user
            for (uint256 i = 0; i < _erc20AddrsIn.length; i++) {
                _returnChange(
                    _changeIn,
                    _erc20AddrsIn[i],
                    _recipient,
                    _exchange,
                    _erc20AddrsIn[i] == ETH 
                        ? address(this).balance
                        : IERC20(_erc20AddrsIn[i]).balanceOf(address(this))
                );
            }
        }
    }

    function _executeSingleTrxSwap(
        bytes memory _data,
        address _from
    ) internal {
        // decode the trade details
        MarketRegistry.SellDetails[] memory _sellDetails;
        ExchangeRegistry.SwapDetails[] memory _swapDetails;
        MarketRegistry.BuyDetails[] memory _buyDetails;
        address[] memory addrs; // [changeIn, exchange, recipient]

        (_sellDetails, _swapDetails, _buyDetails, addrs) = abi.decode(
            _data,
            (MarketRegistry.SellDetails[], ExchangeRegistry.SwapDetails[], MarketRegistry.BuyDetails[], address[])
        );

        // _sellDetails should not be empty
        require(_sellDetails.length > 0, "_executeSingleTrxSwap: no sell details");

        // if recipient is zero address, then set _from as recipient
        if(addrs[2] == address(0)) {
            addrs[2] = _from;
        }

        // sell input assets
        (address[] memory _erc20AddrsIn, uint256[] memory _erc20AmountsIn) = _sellNFT(_sellDetails);
        
        // swap ERC20 equivalents to desired intermediate assets
        _swap(_swapDetails, _buyDetails, _erc20AmountsIn, _erc20AddrsIn, addrs[0], addrs[1], addrs[2]);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata _data
    ) public virtual returns (bytes4) {
        // return with function selector if data is empty
        if(keccak256(abi.encodePacked((_data))) == keccak256(abi.encodePacked(("")))) {
            return this.onERC1155BatchReceived.selector;
        }
        
        // execute single transaction swap
        _executeSingleTrxSwap(_data, _from);

        // return the function selector
        return this.onERC1155BatchReceived.selector;
    }


    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual returns (bytes4) {
        // return with function selector if data is empty        
        if(keccak256(abi.encodePacked((_data))) == keccak256(abi.encodePacked(("")))) {
            return this.onERC721Received.selector;
        }

        // execute single transaction swap
        _executeSingleTrxSwap(_data, _from);

        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external returns(uint256 amountRescued) {
        amountRescued = IERC20(asset).balanceOf(address(this)); 
        IERC20(asset).transfer(recipient, amountRescued);
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}