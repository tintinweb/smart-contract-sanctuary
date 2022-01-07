pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import "../NFT/IERC2981.sol";
import "../NFT/IRoyaltyDistribution.sol";
import '../NFT/I_NFT.sol';

import './EIP712Upgradeable.sol';

interface UnknownToken {
    function supportsInterface(bytes4 interfaceId) external returns (bool);
}

contract DecryptMarketplace is Initializable, OwnableUpgradeable, UUPSUpgradeable, EIP712Upgradeable {

    event Sale(
        address buyer,
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 quantity
    );

    event BundleSale(
        address buyer,
        address seller,
        address tokenAddress,
        uint256[] tokenId,
        uint256 amount
    );

    event RoyaltyPaid(
        address tokenAddress,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    event DistributedRoyaltyPaid(
        address tokenAddress,
        address royaltyReceiver,
        RoyaltyShare[] collaborators,
        uint256 royaltyAmount
    );

    event CancelledOrder(
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 listingType
    );

    event NewRoyaltyLimit(
        uint256 newRoyaltyLimit
    );

    event NewMarketplaceFee(
        uint256 newMarketplaceFee
    );

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    struct Order {
        address user;               //Address of the user, who's making and signing the order
        address tokenAddress;       //Token contract address.
        uint256 tokenId;            //Token contract ID. May be left 0 for bundle order
        uint256 quantity;           //Token quantity. For ERC721 - 1
        uint256 listingType;        //0 - Buy Now, 1 - Auction/Simple offer, 3 - Bundle Buy now, 4 - Bundle auction
        address paymentToken;       //Payment ERC20 token address if order will be paid in ERC20. address(0) for ETH
        uint256 value;              //Amount to be paid. ERC721 and bundle order - full amount to pay. ERC1155 - amount to pay for 1 token
        uint256 deadline;           //Deadline of the order validity. If auction - buyer will be able to claim NFT after auction has ended
        uint256[] bundleTokens;     //List of token IDs for bundle order. For non-bundle - keep empty
        uint256[] bundleTokensQuantity;    //List of quantities for according IDs for bundle order. For non-bundle - keep empty
        uint256 salt;               //Random number for different order hash
    }

    struct PaymentInfo {
        address owner;
        address buyer;
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        address paymentToken;
    }


    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address user,address tokenAddress,uint256 tokenId,uint256 quantity,uint256 listingType,address paymentToken,uint256 value,uint256 deadline,bytes32 bundleTokens,uint256 salt)"
    );

    uint256 public marketplaceFee; //in basis points (250 = 2.5%)
    uint256 public royaltyLimit;   //in basis points (9000 = 90%)

    mapping(address => mapping(bytes32 => bool)) orderIsCancelledOrCompleted;
    //seller => orderHash => Amount of ERC1155 tokens left to sell
    mapping(address => mapping(bytes32 => uint256)) amountOf1155TokensLeftToSell;


    /*
     * Constructor
     * Params
     * string calldata name - Marketplace name
     * string calldata version - Marketplace version
     * uint256 _marketplaceFee - Marketplace fee in basis points
     * uint256 _royaltyLimit - Maximum amount of royalties in basis points
     * (9000 = 90% of token price can be royalty)
     */
    function initialize(
        string calldata name,
        string calldata version,
        uint256 _marketplaceFee,
        uint256 _royaltyLimit
    ) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __EIP712_init(name, version);
        marketplaceFee = _marketplaceFee;
        royaltyLimit = _royaltyLimit;
    }


    /*
     * This function is called before proxy upgrade and makes sure it is authorized.
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}


    /*
     * Returns implementation address
     */
    function implementationAddress() external view returns (address){
        return _getImplementation();
    }


    /*
     * Params
     * uint256 _royaltyLimit - royalty limit in basis points
     *
     * Sets new royalty limit for marketplace.
     * If token asks for higher royalty than royalty limit allows,
     * marketplace will send only allowed amount and distributes it according to shares
     * (if royalty distribution is enabled)
     */
    function setRoyaltyLimit(uint256 _royaltyLimit) external onlyOwner{
        require(_royaltyLimit <= 9500,'Over 95%');
        royaltyLimit = _royaltyLimit;
        emit NewRoyaltyLimit(_royaltyLimit);
    }


    /*
     * Params
     * uint256 _marketplaceFee - Marketplace fee in basis points
     *
     * Sets new marketplace fee.
     * Marketplace fee takes specified share of every payment that goes through marketplace and stores on the contract
     */
    function setMarketplaceFee(uint256 _marketplaceFee) external onlyOwner{
        require(_marketplaceFee <= 9500,'Over 95%');
        marketplaceFee = _marketplaceFee;
        emit NewMarketplaceFee(_marketplaceFee);
    }


    /*
     * Params
     * uint256 amount - Amount to withdraw
     * address payable receiver - Wallet of the receiver
     *
     * Withdraws collected ETH from marketplace contract to specific wallet address.
     */
    function withdrawETH(uint256 amount, address payable receiver) external onlyOwner{
        require(receiver != address(0));
        require(amount != 0);
        receiver.transfer(amount);
    }


    /*
     * Params
     * uint256 amount - Amount to withdraw
     * address payable receiver - Wallet of the receiver
     * address tokenAddress - ERC20 token address
     *
     * Withdraws collected ERC20 from marketplace contract to specific wallet address.
     */
    function withdrawERC20(
        uint256 amount,
        address payable receiver,
        address tokenAddress
    ) external onlyOwner{
        require(receiver != address(0));
        require(amount != 0);
        IERC20(tokenAddress).transfer(receiver, amount);
    }

    /*********************    ORDERS PROCESSING   *********************/

    /*
     * Params
     * Order calldata _sellerOrder - Order info on seller side
     * Sig calldata _sellerSig - Seller signature
     * Order calldata _buyerOrder - Order info on buyer side
     * Sig calldata _buyerSig - Buyer signature
     *
     * Function checks and completes buyout order
     * Order and Signature must be of according format (array with correct element order)
     * Please check Order and Sig struct description for more
     * Function is used for buy now, auction, bundle buy now and bundle auction orders
     * It DOES NOT complete Pre Sale orders. Pre Sale orders are processed in {prePurchase} function
     */
    function completeOrder(
        Order calldata _sellerOrder,
        Sig calldata _sellerSig,
        Order calldata _buyerOrder,
        Sig calldata _buyerSig
    ) public payable {
        //if this is auction/accept offer
        bool isAuction = _sellerOrder.listingType == 1 || _sellerOrder.listingType == 4;
        if(isAuction){
            require(_sellerOrder.user == msg.sender || _buyerOrder.user == msg.sender, 'User address doesnt match');
            if(msg.sender == _buyerOrder.user)
                require(block.timestamp > _sellerOrder.deadline, 'Auction has not ended');
        }else{
            require(_buyerOrder.user == msg.sender, 'Buyer address doesnt match');
        }
        if(isAuction) require(_buyerOrder.paymentToken != address(0), 'Only ERC20 for auction');

        bool isERC721 = checkERCType(_buyerOrder.tokenAddress);
        bool isNotBundleOrder = _sellerOrder.listingType != 3 && _sellerOrder.listingType != 4;
        bool isSimpleERC1155sale = !isERC721 && isNotBundleOrder;


        bytes32 sellerHash = buildHash(_sellerOrder);
        //If this is not Simple Offer accepting - check seller signature.
        if(msg.sender == _buyerOrder.user)
            checkSignature(sellerHash, _sellerOrder.user, _sellerSig);

        //If auction - check buyer signature
        if(isAuction){
            bytes32 buyerHash = buildHash(_buyerOrder);
            checkSignature(buyerHash, _buyerOrder.user, _buyerSig);
        }

        //Initialize ERC1155 counter of tokens left to sell
        if(
            isSimpleERC1155sale
            && orderIsCancelledOrCompleted[_sellerOrder.user][sellerHash] == false
            && amountOf1155TokensLeftToSell[_sellerOrder.user][sellerHash] == 0
        ){
            amountOf1155TokensLeftToSell[_sellerOrder.user][sellerHash] = _sellerOrder.quantity;
        }

        checkOrdersValidity(_sellerOrder, _buyerOrder, isERC721, isNotBundleOrder, isAuction);
        checkOrdersCompatibility(_sellerOrder, _buyerOrder, isERC721, isNotBundleOrder, sellerHash);

        //Transfer tokens (non-bundle order)
        if(isNotBundleOrder)
            transferTokens(
                _sellerOrder.tokenAddress,
                _sellerOrder.tokenId,
                _sellerOrder.user,
                _buyerOrder.user,
                _buyerOrder.quantity,
                isERC721
            );
        //Counting ERC1155 sold
        if(isSimpleERC1155sale)
        {
            amountOf1155TokensLeftToSell[_sellerOrder.user][sellerHash] -=  _buyerOrder.quantity;
        }

        //Transfer bundle
        if(!isNotBundleOrder) transferBundle(_sellerOrder, _buyerOrder, isERC721);

        PaymentInfo memory payment = PaymentInfo(
            _sellerOrder.user,
            _buyerOrder.user,
            _sellerOrder.tokenAddress,
            _sellerOrder.tokenId,
            _buyerOrder.value,
            _sellerOrder.paymentToken
        );

        transferCoins(
            payment,
            isNotBundleOrder
        );

        //fix order completion
        if(isSimpleERC1155sale){  //if all ERC1155 tokens are sold
            if(amountOf1155TokensLeftToSell[_sellerOrder.user][sellerHash] == 0) {
                orderIsCancelledOrCompleted[_sellerOrder.user][sellerHash] = true;
            }
        }else{
            orderIsCancelledOrCompleted[_sellerOrder.user][sellerHash] = true;
        }

        if(isNotBundleOrder){
            emit Sale(
                _buyerOrder.user,
                _sellerOrder.user,
                _sellerOrder.tokenAddress,
                _buyerOrder.tokenId,
                _buyerOrder.value,
                _buyerOrder.quantity
            );
        } else {
            emit BundleSale(
                _buyerOrder.user,
                _sellerOrder.user,
                _sellerOrder.tokenAddress,
                _sellerOrder.bundleTokens,
                _buyerOrder.value
            );
        }

    }


    /*
     * Params
     * Order calldata _usersOrder - Users's order info
     * Sig calldata _usersSig - Users's signature info
     *
     * Function cancels specific order, making it impossible to complete
     * Any listing or bid can be cancelled
     * Before cancelling function checks user right to cancel this order
     */
    function cancelOrder(
        Order calldata _usersOrder,
        Sig calldata _usersSig
    ) external {
        require(_usersOrder.user == msg.sender, 'Wrong order');
        bytes32 usersHash = buildHash(_usersOrder);
        checkSignature(usersHash, _usersOrder.user, _usersSig);
        orderIsCancelledOrCompleted[msg.sender][usersHash] = true;

        emit CancelledOrder(_usersOrder.user, _usersOrder.tokenAddress, _usersOrder.tokenId, _usersOrder.listingType);
    }


    /*
     * Params
     * address ownerAddress - Address of the token owner
     * address tokenAddress - Address of token contract
     * uint256 tokenId - ID index of token user want to purchase
     * uint256 eventId - ID index of Pre Purchase event user want to participate
     * uint256 quantity - Quantity of tokens of specific ID user wants to purchase
     *
     * Function allows to buy tokens during Pre Sale events.
     * Function runs through some validity checks, but uses external token contract function {getTokenInfo}
     * to determine if user is allowed to purchase at this moment.
     * Contract should check event start, end time, whitelist, and other limitations.
     * After transfer of coins and tokens, function runs countTokensBought function on token contract
     * which allows it to keep track of tokens bought for further limitation calculations
     * If token does not allow transfer, "Not allowed" exception will be thrown
     * This should be avoided buy calling {getTokenInfo} from on Front End
     */
    function prePurchase(
        address ownerAddress,
        address tokenAddress,
        uint256 tokenId,
        uint256 eventId,
        uint256 quantity
    ) external payable {
        require
        (
            UnknownToken(tokenAddress).supportsInterface(type(IPreSale1155).interfaceId) ||
            UnknownToken(tokenAddress).supportsInterface(type(IPreSale721).interfaceId),
            "Pre Sale not supported"
        );
        require(ownerAddress != msg.sender,'Cant buy your token');

        bool isERC721 = checkERCType(tokenAddress);
        bool supportsLazyMint = supportsLazyMint(tokenAddress, isERC721);
        bool shouldLazyMint = supportsLazyMint && ((isERC721  && needsLazyMint721(tokenAddress, ownerAddress, tokenId))
        || (!isERC721 && needsLazyMint1155(tokenAddress, ownerAddress, tokenId, quantity)));

        require(
            IERC721(tokenAddress).isApprovedForAll(ownerAddress,address(this)),
            'Not approved'
        );

        uint256 price;

        if(isERC721){
            require(quantity == 1, 'ERC721 is unique');
            require(
                shouldLazyMint
                || IERC721(tokenAddress).ownerOf(tokenId) == ownerAddress,
                'Not an owner'
            );

            (uint256 tokenPrice, address paymentToken, bool availableForBuyer) = IPreSale721(tokenAddress)
                .getTokenInfo(msg.sender, tokenId, eventId);
            require(availableForBuyer, 'Not allowed');
            price = tokenPrice;

            transferTokens(tokenAddress, tokenId, ownerAddress, msg.sender, quantity, true);

            PaymentInfo memory payment = PaymentInfo(
                ownerAddress,
                msg.sender,
                tokenAddress,
                tokenId,
                tokenPrice,
                paymentToken
            );

            transferCoins(payment, true);

            IPreSale721(tokenAddress).countTokensBought(eventId, msg.sender);

        }else{
            require(quantity >= 1, 'Cant buy 0 quantity');
            require(
                shouldLazyMint
                || IERC1155(tokenAddress)
                .balanceOf(ownerAddress, tokenId)  >= quantity,
                'Not enough tokens'
            );

            (uint256 tokenPrice, address paymentToken, bool availableForBuyer) = IPreSale1155(tokenAddress)
            .getTokenInfo(msg.sender, tokenId, quantity, eventId);
            require(availableForBuyer, 'Not allowed');
            price = tokenPrice;

            transferTokens(tokenAddress, tokenId, ownerAddress, msg.sender, quantity, false);

            PaymentInfo memory payment = PaymentInfo(
                ownerAddress,
                msg.sender,
                tokenAddress,
                tokenId,
                quantity * tokenPrice,
                paymentToken
            );

            transferCoins(payment, true);

            IPreSale1155(tokenAddress).countTokensBought(msg.sender, tokenId, quantity, eventId);
        }

        emit Sale(
            msg.sender,
            ownerAddress,
            tokenAddress,
            tokenId,
            price,
            quantity
        );
    }


    /*
     * Params
     * address tokenAddress - Token contract address
     * uint256 tokenId - Token ID index
     * address from - Sender (owner) address
     * address to - Receiver (buyer) address
     * uint256 quantity - Tokens quantity
     * bool isERC721 - Is transferred token ERC721?
     *
     * Function transfers tokens from seller to buyer
     */
    function transferTokens(
        address tokenAddress,
        uint256 tokenId,
        address from,
        address to,
        uint256 quantity,
        bool isERC721
    ) private {
        bool supportsLazyMint = supportsLazyMint(tokenAddress, isERC721);

        if(isERC721){
            bool shouldLazyMint = supportsLazyMint &&
            needsLazyMint721(
                tokenAddress,
                from,
                tokenId
            );

            if(shouldLazyMint){
                ILazyMint721(tokenAddress).lazyMint(to, tokenId);
            }else{
                IERC721(tokenAddress).safeTransferFrom(from, to, tokenId);
            }
        }else{
            bool shouldLazyMint = supportsLazyMint &&
            needsLazyMint1155(
                tokenAddress,
                from,
                tokenId,
                quantity
            );

            if(shouldLazyMint){
                ILazyMint1155(tokenAddress)
                .lazyMint(to, tokenId, quantity);
            }else{
                IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, quantity, '');
            }
        }
    }


    /*
     * Params
     * Order calldata _sellerOrder - Sellers order information
     * Order calldata _buyerOrder - Sellers order information
     * bool isERC721 - Is transferred token ERC721?
     *
     * Function transfers token bundle from seller to buyer
     */
    function transferBundle(
        Order calldata _sellerOrder,
        Order calldata _buyerOrder,
        bool isERC721
    ) private {
        address tokenAddress = _buyerOrder.tokenAddress;
        bool supportsLazyMint = supportsLazyMint(_sellerOrder.tokenAddress, isERC721);

        for(uint i=0; i<_sellerOrder.bundleTokens.length; i++){
            require(_sellerOrder.bundleTokens[i] == _buyerOrder.bundleTokens[i], 'Wrong tokenId');
            require(_sellerOrder.bundleTokensQuantity[i] == _buyerOrder.bundleTokensQuantity[i], 'Wrong quantity');
            uint256 bundleTokenId = _sellerOrder.bundleTokens[i];
            uint256 bundleTokenQuantity = _sellerOrder.bundleTokensQuantity[i];

            if(isERC721){
                require(bundleTokenQuantity == 1,'ERC721 is unique');
                if(
                    supportsLazyMint &&
                    needsLazyMint721(
                    _sellerOrder.tokenAddress,
                    _sellerOrder.user,
                    bundleTokenId
                    )
                ){
                    ILazyMint721(_sellerOrder.tokenAddress)
                        .lazyMint(_buyerOrder.user, bundleTokenId);
                }else{
                    IERC721(tokenAddress)
                    .safeTransferFrom(
                        _sellerOrder.user,
                        _buyerOrder.user,
                        bundleTokenId
                    );
                }

            }else{
                if(supportsLazyMint &&
                needsLazyMint1155(
                    _sellerOrder.tokenAddress,
                    _sellerOrder.user,
                    bundleTokenId,
                    bundleTokenQuantity
                )){
                    ILazyMint1155(_sellerOrder.tokenAddress)
                        .lazyMint(_buyerOrder.user, bundleTokenId, bundleTokenQuantity);
                }else{
                    IERC1155(tokenAddress)
                    .safeTransferFrom(
                        _sellerOrder.user,
                        _buyerOrder.user,
                        bundleTokenId,
                        bundleTokenQuantity,
                        ''
                    );
                }
            }
        }
    }


    /*
     * Params
     * PaymentInfo memory payment - Payment information
     * bool isNotBundleOrder - Is this a bundle order?
     *
     * Function transfers ETH or ERC20 from buyer to according wallets/contracts
     */
    function transferCoins(
        PaymentInfo memory payment,
        bool isNotBundleOrder
    ) private {
        bool ERC20Payment = payment.paymentToken != address(0);
        uint256 transactionAmount = payment.amount;

        /******** Checking for ETH/ERC20 enough balance *******/
        if(ERC20Payment){
            require(IERC20(payment.paymentToken)
                .balanceOf(payment.buyer) >= payment.amount, 'Not enough balance');
            require(IERC20(payment.paymentToken)
                .allowance(payment.buyer, address(this)) >= payment.amount, 'Not enough allowance');
        }else{
            require(msg.value >= payment.amount,'Not enough {value}');
        }

        /**************** TRANSFER ***************/
        /******** Supporting royalty distribution *******/
        if(UnknownToken(payment.tokenAddress).supportsInterface(type(IRoyaltyDistribution).interfaceId)){
            IRoyaltyDistribution tokenContract = IRoyaltyDistribution(payment.tokenAddress);

            if(
                tokenContract.royaltyDistributionEnabled()
                && tokenContract.getDefaultRoyaltyDistribution().length > 0
            ){

                /******** Individual token royalty distribution *******/
                /******** Bundle order doesnt support royalty distribution *******/
                if(
                    isNotBundleOrder
                    && tokenContract.getTokenRoyaltyDistribution(payment.tokenId).length > 0
                ){
                    RoyaltyShare[] memory royaltyShares = tokenContract.getTokenRoyaltyDistribution(payment.tokenId);
                    (address royaltyReceiver, uint256 royaltyAmount) = IRoyaltyDistribution(payment.tokenAddress)
                                                                    .royaltyInfo(payment.tokenId, payment.amount);
                    payDistributedRoyalty
                    (
                        payment,
                        royaltyReceiver,
                        royaltyAmount,
                        royaltyShares
                    );
                /******** Default royalty distribution *******/
                }else{
                    RoyaltyShare[] memory royaltyShares = tokenContract.getDefaultRoyaltyDistribution();
                    (address royaltyReceiver, uint256 royaltyAmount) = IRoyaltyDistribution(payment.tokenAddress)
                                                                    .royaltyInfo(payment.tokenId, payment.amount);
                    payDistributedRoyalty
                    (
                        payment,
                        royaltyReceiver,
                        royaltyAmount,
                        royaltyShares
                    );
                }
            /******** IERC2981 royalty *******/
            }else{
                (address royaltyReceiver, uint256 royaltyAmount) = IRoyaltyDistribution(payment.tokenAddress)
                                                                .royaltyInfo(payment.tokenId, payment.amount);
                payRoyaltyIERC2981
                (
                    payment.buyer,
                    payment.owner,
                    payment.paymentToken,
                    payment.amount,
                    royaltyReceiver,
                    royaltyAmount,
                    payment.tokenAddress
                );
            }

        /******** Supporting IERC2981 *******/
        }else if(UnknownToken(payment.tokenAddress).supportsInterface(type(IERC2981).interfaceId)){
            (address royaltyReceiver, uint256 royaltyAmount) = IRoyaltyDistribution(payment.tokenAddress)
                                                            .royaltyInfo(payment.tokenId, payment.amount);
            payRoyaltyIERC2981
            (
                payment.buyer,
                payment.owner,
                payment.paymentToken,
                payment.amount,
                royaltyReceiver,
                royaltyAmount,
                payment.tokenAddress
            );

        /******** No royalty *******/
        }else{
            uint256 marketplaceFee = transactionAmount * marketplaceFee / 10000;
            uint256 amountforSeller = transactionAmount - marketplaceFee;

            if(ERC20Payment){
                IERC20(payment.paymentToken)
                    .transferFrom(payment.buyer, address(this), marketplaceFee);
                IERC20(payment.paymentToken)
                    .transferFrom(payment.buyer, payment.owner, amountforSeller);
            }else{
                payable(payment.owner).transfer(amountforSeller);
            }

        }

        /******** Returning ETH leftovers *******/
        if(payment.paymentToken == address(0)){
            uint256 amountToReturn = msg.value - transactionAmount;
            payable(payment.buyer).transfer(amountToReturn);
        }
    }


    /*
     * Params
     * address from - Buyer address
     * address to - Seller address
     * address paymentToken - Payment token address (if ETH, then address(0))
     * uint256 totalAmount - Total value of sale
     * address royaltyReceiver - Royalty receiver address
     * uint256 royaltyAmountToReceive - Royalty receiver address
     * address tokenAddress - NFT token contract address
     *
     * Function Send specific amount of ERC20/ETH to seller, marketplace and royalty receiver
     * Supporting IERC2981 standard
     */
    function payRoyaltyIERC2981(
        address from,
        address to,
        address paymentToken,
        uint256 totalAmount,
        address royaltyReceiver,
        uint256 royaltyAmountToReceive,
        address tokenAddress
    ) private {
        if(totalAmount > 0)
        {
            bool ERC20Payment = paymentToken != address(0);
            uint256 marketplaceFee = totalAmount * marketplaceFee / 10000;
            uint256 royaltyAmount = royaltyAmountToReceive;
            //If royalty receiver asks too much
            uint256 maxRoyaltyAmount = totalAmount * royaltyLimit / 10000;
            if(royaltyAmount > maxRoyaltyAmount)
                royaltyAmount = maxRoyaltyAmount;

            uint256 amountToSeller = totalAmount - marketplaceFee - royaltyAmount;

            if(ERC20Payment){
                if(marketplaceFee > 0)
                    IERC20(paymentToken).transferFrom(from, address(this), marketplaceFee);
                if(royaltyAmount > 0)
                    IERC20(paymentToken).transferFrom(from, royaltyReceiver, royaltyAmount);
                if(amountToSeller > 0)
                    IERC20(paymentToken).transferFrom(from, to, amountToSeller);
            }else{
                if(royaltyAmount > 0)
                    payable(royaltyReceiver).transfer(royaltyAmount);
                if(amountToSeller > 0)
                    payable(to).transfer(amountToSeller);
            }

            if(royaltyAmount > 0)
                emit RoyaltyPaid(tokenAddress, royaltyReceiver, royaltyAmount);
        }
    }


    /*
     * Params
     * Order calldata _sellerOrder - Seller order info
     * Order calldata _buyerOrder - Buyer order info
     * address royaltyReceiver - Royalty receiver address
     * uint256 royaltyAmountToReceive - Royalty amount
     * RoyaltyShare[] memory royaltyShares - Array of royalty shares
     *
     * Function transfers ERC20/ETH to marketplace, seller and royalty receivers
     * Function distributes royalty to collaborators and sends what left to royaltyReceiver
     */
    function payDistributedRoyalty(
        PaymentInfo memory payment,
        address royaltyReceiver,
        uint256 royaltyAmountToReceive,
        RoyaltyShare[] memory royaltyShares
    ) private {
        uint256 totalAmount = payment.amount;
        if(totalAmount > 0)
        {
            bool ERC20Payment = payment.paymentToken != address(0);
            uint256 marketplaceFee = totalAmount * marketplaceFee / 10000;
            uint256 royaltyAmount = royaltyAmountToReceive;
            //If royalty receiver asks too much
            uint256 maxRoyaltyAmount = totalAmount * royaltyLimit / 10000;
            if(royaltyAmount > maxRoyaltyAmount)
                royaltyAmount = maxRoyaltyAmount;

            uint256 amountToSeller = totalAmount - marketplaceFee - royaltyAmount;

            //paying to marketplace and seller
            if(ERC20Payment){
                if(marketplaceFee > 0)
                    IERC20(payment.paymentToken)
                    .transferFrom(payment.buyer, address(this), marketplaceFee);
                if(amountToSeller > 0)
                    IERC20(payment.paymentToken)
                    .transferFrom(payment.buyer, payment.owner, amountToSeller);
            }else{
                if(amountToSeller > 0)
                    payable(payment.owner).transfer(amountToSeller);
            }

            //paying to royalty receivers
            if(royaltyAmount > 0){
                uint256 royaltiesLeftToPay = royaltyAmount;
                for(uint i=0; i<royaltyShares.length; i++){
                    address royaltyShareReceiver = royaltyShares[i].collaborator;
                    uint256 royaltyShare = royaltyAmount * royaltyShares[i].share / 10000;
                    if(royaltyShare > 0 && royaltiesLeftToPay >= royaltyShare){
                        if(ERC20Payment){
                            IERC20(payment.paymentToken)
                            .transferFrom(payment.buyer, royaltyShareReceiver, royaltyShare);
                        }else{
                            payable(royaltyShareReceiver).transfer(royaltyShare);
                        }
                        royaltiesLeftToPay -= royaltyShare;
                    }
                }
                //If there is royalty left after distribution
                if(royaltiesLeftToPay > 0){
                    if(ERC20Payment){
                        IERC20(payment.paymentToken)
                        .transferFrom(payment.buyer, royaltyReceiver, royaltiesLeftToPay);
                    }else{
                        payable(royaltyReceiver).transfer(royaltiesLeftToPay);
                    }
                }
            }

            if(royaltyAmount > 0)
                emit DistributedRoyaltyPaid(payment.tokenAddress, royaltyReceiver, royaltyShares, royaltyAmount);
        }
    }


    /*********************    CHECKS   *********************/

    /*
     * Params
     * Order calldata _sellerOrder - Seller order info
     * Order calldata _buyerOrder - Buyer order info
     * bool isERC721 - Is NFT token of standard ERC721?
     * bool isNotBundleOrder - Is this a bundle order?
     * bool isAuction - Is this auction order?
     *
     * Function checks if orders are valid
     * Important security check
     */
    function checkOrdersValidity(
        Order calldata _sellerOrder,
        Order calldata _buyerOrder,
        bool isERC721,
        bool isNotBundleOrder,
        bool isAuction
    ) private {
        bool supportsLazyMint = supportsLazyMint(_sellerOrder.tokenAddress, isERC721);
        require(
            _sellerOrder.listingType == 0
            || _sellerOrder.listingType == 1
            || _sellerOrder.listingType == 3
            || _sellerOrder.listingType == 4
            ,'Unknown listing type'
        );

        //Quantity and ownership check
        if(isNotBundleOrder){
            require(_sellerOrder.bundleTokens.length == 0, 'Wrong listingType');
            if(isERC721){
                require(_buyerOrder.quantity == 1 && _sellerOrder.quantity == 1, 'Non-1 quantity');
                require(
                    (supportsLazyMint &&
                    needsLazyMint721(
                        _sellerOrder.tokenAddress,
                        _sellerOrder.user,
                        _sellerOrder.tokenId
                    ))
                    ||
                    IERC721(_sellerOrder.tokenAddress).ownerOf(_sellerOrder.tokenId) == _sellerOrder.user,
                    'Not an owner'
                );
            }else{
                require(_buyerOrder.quantity > 0 && _sellerOrder.quantity > 0, '0 quantity');
                require(
                    (supportsLazyMint &&
                    needsLazyMint1155(
                        _sellerOrder.tokenAddress,
                        _sellerOrder.user,
                        _sellerOrder.tokenId,
                        _buyerOrder.quantity
                    ))
                    ||
                    IERC1155(_sellerOrder.tokenAddress)
                    .balanceOf(_sellerOrder.user, _sellerOrder.tokenId)  >= _buyerOrder.quantity,
                    'Not enough tokens'
                );
            }
        }

        require(
            IERC721(_sellerOrder.tokenAddress).isApprovedForAll(_sellerOrder.user,address(this)),
            'Not approved'
        );

        if(!isAuction){
            require(_sellerOrder.deadline >= block.timestamp && _buyerOrder.deadline >= block.timestamp, 'Overdue order');
        } else {
            require(_buyerOrder.deadline >= block.timestamp, 'Overdue offer');
        }
    }


    /*
     * Params
     * Order calldata _sellerOrder - Seller order info
     * Order calldata _buyerOrder - Buyer order info
     * bool isERC721 - Is NFT token of standard ERC721?
     * bool isNotBundleOrder - Is this a bundle order
     * bytes32 sellerHash - Hash info of the seller order
     *
     * Function checks if buyer order and seller order are compatible
     * Hash info of the seller order is used to check amount of ERC1155 tokens that were already sold
     * Important security check
     */
    function checkOrdersCompatibility(
        Order calldata _sellerOrder,
        Order calldata _buyerOrder,
        bool isERC721,
        bool isNotBundleOrder,
        bytes32 sellerHash
    ) private view {
        require(_buyerOrder.user != _sellerOrder.user, 'Buyer == Seller');
        require(_buyerOrder.tokenAddress == _sellerOrder.tokenAddress, 'Different tokens');
        require(_sellerOrder.tokenId == _buyerOrder.tokenId || !isNotBundleOrder, 'TokenIDs dont match');
        if(!isERC721 && isNotBundleOrder){
            require(
                amountOf1155TokensLeftToSell[_sellerOrder.user][sellerHash] >= _buyerOrder.quantity,
                'Cant buy that many'
            );
        }
        require(_sellerOrder.listingType == _buyerOrder.listingType, 'Listing type doesnt match');
        require(_sellerOrder.paymentToken == _buyerOrder.paymentToken, 'Payment token dont match');
        require(
            (isNotBundleOrder &&
            ((_sellerOrder.value <= _buyerOrder.value && isERC721) ||
            ((_sellerOrder.value * _buyerOrder.quantity) <= _buyerOrder.value && !isERC721)))
            ||
            (!isNotBundleOrder &&
            (_sellerOrder.value <= _buyerOrder.value)),
            'Value is too small'
        );
        require(
            hashBundleTokens(_sellerOrder.bundleTokens, _sellerOrder.bundleTokensQuantity) ==
            hashBundleTokens(_buyerOrder.bundleTokens, _buyerOrder.bundleTokensQuantity),
            'Token lists dont match'
        );
    }


    /*
     * Params
     * bytes32 orderHash - Hashed order info
     * address userAddress - User address that will be compared to signer address
     * Sig calldata _sellerSig - Signature data, that wsa generated by signing hash data
     *
     * Function checks if user with userAddress is the one, who signed hash data
     * Important security check
     */
    function checkSignature(
        bytes32 orderHash,
        address userAddress,
        Sig calldata _sellerSig
    ) private view {
        require (!orderIsCancelledOrCompleted[userAddress][orderHash],'Cancelled or complete');
        address recoveredAddress = recoverAddress(orderHash, _sellerSig);
        require(userAddress == recoveredAddress, 'Bad signature');
    }


    /*
     * Params
     * address tokenAddress - NFT token contract address
     *
     * Function checks if contract is valid NFT of ERC721 or ERC1155 standard
     */
    function checkERCType(address tokenAddress) private returns(bool isERC721){
        bool isERC721 = UnknownToken(tokenAddress).supportsInterface(type(IERC721).interfaceId);

        require(
        isERC721 ||
        UnknownToken(tokenAddress).supportsInterface(type(IERC1155).interfaceId),
        'Unknown Token');

        return isERC721;
    }


    /*
     * Params
     * address tokenAddress - NFT token contract address
     * address ownerAddress - NFT token contract's owner address
     * uint256 tokenId - ID index of token that should be sold
     *
     * Function checks if ERC721 token with specific ID needs to be minted
     * Lazy mint works only for Pre Sale OR with owners order to sell this token
     */
    function needsLazyMint721(
        address tokenAddress,
        address ownerAddress,
        uint256 tokenId
    ) private returns(bool){
        return !ILazyMint721(tokenAddress).exists(tokenId)
        && OwnableUpgradeable(tokenAddress).owner() == ownerAddress;
    }


    /*
     * Params
     * address tokenAddress - NFT token contract address
     * address ownerAddress - NFT token contract's owner address
     * uint256 tokenId - ID index of token that should be sold
     * uint256 quantity - Quantity of tokens to be sold
     *
     * Function checks if ERC1155 tokens with specific ID needs to be minted
     * Lazy mint works only for Pre Sale OR with owners order to sell this token
     */
    function needsLazyMint1155(
        address tokenAddress,
        address ownerAddress,
        uint256 tokenId,
        uint256 quantity
    ) private returns(bool){
        return IERC1155(tokenAddress)
        .balanceOf(ownerAddress, tokenId) < quantity
        && OwnableUpgradeable(tokenAddress).owner() == ownerAddress;
    }


    /*
     * Params
     * address tokenAddress - NFT token contract address
     * bool isERC721 - Is this token ERC721?
     *
     * Function checks if token supports Lazy Minting
     * Returns true if it does
     */
    function supportsLazyMint(
        address tokenAddress,
        bool isERC721
    ) private returns(bool){
        return (isERC721 && UnknownToken(tokenAddress).supportsInterface(type(ILazyMint721).interfaceId))
        || (!isERC721 && UnknownToken(tokenAddress).supportsInterface(type(ILazyMint1155).interfaceId));
    }

    /*********************    HASHING   *********************/

    /*
     * Params
     * Order calldata _order - Order info
     *
     * Function builds hash according to hashing typed data standard V4 (EIP712)
     * May be used on off-chain to build order hash
     */
    function buildHash(Order calldata _order) public returns (bytes32){
        return _hashTypedDataV4(keccak256(abi.encode(
                ORDER_TYPEHASH,
                _order.user,
                _order.tokenAddress,
                _order.tokenId,
                _order.quantity,
                _order.listingType,
                _order.paymentToken,
                _order.value,
                _order.deadline,
                hashBundleTokens(_order.bundleTokens, _order.bundleTokensQuantity),
                _order.salt
            )));
    }


    /*
     * Params
     * uint256[] calldata _indexArray - array of token IDs
     * uint256[] calldata _quantityArray - array of token quantities
     *
     * Function calculates hash for token IDS + quantities
     * This is security operation bundle tokens check
     * May be used on off-chain to generate bundle order hash
     */
    function hashBundleTokens(
        uint256[] calldata _indexArray,
        uint256[] calldata _quantityArray
    ) public view returns(bytes32){
        if(_indexArray.length == 0) return bytes32(0);
        bytes32 indexHash = (keccak256(abi.encodePacked(_indexArray)));
        bytes32 arrayHash = (keccak256(abi.encodePacked(_quantityArray)));
        return (keccak256(abi.encodePacked(indexHash, arrayHash)));
    }


    /*
     * Params
     * bytes32 hash - Hashed order info
     * Sig calldata _sig - Signature, created from signing this hash
     * signature should have structure [v,r,s]
     *
     * Function recovers signer address (public key)
     * This is security operation that is needed to make sure we are working with trustworthy data
     * May be used on off-chain to verify signature
     */
    function recoverAddress(
        bytes32 hash,
        Sig calldata _sig
    ) public view returns(address) {
        (address recoveredAddress, ) = ECDSAUpgradeable.tryRecover(hash, _sig.v, _sig.r, _sig.s);
        return recoveredAddress;
    }
}

// SPDX-License-Identifier: MIT

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

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

//interface IERC165 {
//    /// @notice Query if a contract implements an interface
//    /// @param interfaceID The interface identifier, as specified in ERC-165
//    /// @dev Interface identification is specified in ERC-165. This function
//    ///  uses less than 30,000 gas.
//    /// @return `true` if the contract implements `interfaceID` and
//    ///  `interfaceID` is not 0xffffffff, `false` otherwise
//    function supportsInterface(bytes4 interfaceID) external view returns (bool);
//}

pragma solidity ^0.8.0;

interface IRoyaltyDistribution {
    function globalRoyaltyEnabled() external returns(bool);
    function royaltyDistributionEnabled() external returns(bool);
    function defaultCollaboratorsRoyaltyShare() external returns(RoyaltyShare[] memory);


    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );

    function getDefaultRoyaltyDistribution() external view returns(RoyaltyShare[] memory);

    function getTokenRoyaltyDistribution(uint256 tokenId) external view returns(RoyaltyShare[] memory);

}

struct RoyaltyShare {
    address collaborator;
    uint256 share;
}

pragma solidity ^0.8.0;

interface ICreator {
    function deployedTokenContract(address) external view returns(bool);
}

interface ILazyMint721 {
    function exists(uint256 tokenId) external view returns (bool);
    function owner() external view returns (address);
    function lazyMint(address to, uint256 tokenId) external;
}

interface ILazyMint1155 {
    function owner() external view returns (address);
    function lazyMint(address to, uint256 tokenId, uint256 amount) external;
}

interface IPreSale721 {
    function getTokenInfo (address buyer, uint256 tokenId, uint256 eventId)
        external view returns (uint256 tokenPrice, address paymentToken, bool availableForBuyer);
    function countTokensBought(uint256 eventId, address buyer) external;
}

interface IPreSale1155 {
    function getTokenInfo(address buyer, uint256 tokenId, uint256 quantity, uint256 eventId)
        external view returns (uint256 tokenPrice, address paymentToken, bool availableForBuyer);
    function countTokensBought(address buyer, uint256 tokenId, uint256 amount, uint256 eventId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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
        return msg.data;
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
interface IERC165 {
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

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}