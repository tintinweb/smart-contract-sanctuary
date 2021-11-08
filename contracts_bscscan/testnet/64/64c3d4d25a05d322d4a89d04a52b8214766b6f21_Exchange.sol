pragma solidity ^0.5.0;

import "./IExchange.sol";
import "./IStableCoin.sol";
import "./utils/stringUtils.sol";
import "./token/ERC20/IERC1400RawERC20.sol";
import "./whitelist/ITokenismWhitelist.sol";
import "./MarginLoan/IMarginLoan.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";


contract Exchange is IExchange, ReentrancyGuard {
    using SafeMath for uint256;

    IStableCoin public stableCoin; // Stable coin TKUSD used on Tokenism
    IERC1400RawERC20 public token; // ERC1400ERC20 Which they want to sell
    ITokenismWhitelist _whitelist;
    IMarginLoan _IMarginLoan;
    bool public sellPlaced = false; // Check if sell is placed
    address payable public admin; // Who Deployed Contract
    address public seller; // Seller Address
    uint256 public expDate; // Expiry date of token

    uint256 public price; // Price of each token they want to sale
    uint256 public totalQty; // Amount of Security token for sale
    uint256 public holdToken; // Amount of Security token Hold
    uint256 public remainingQty; // Amount of Security token for sale
    uint256 remainingAmount;
    uint256 transferTokens;
    struct CounterOffers {
        bool valid;
        string role; // buyer | seller
        address wallet;
        // uint256 price;
        uint256 buyPrice;
        uint256 sellPrice;
        uint256 counter;
        uint256 quantity;
        uint256 expiryTime;
    }
    mapping(address => CounterOffers) public counterOffers;

    address[] public counterAddresses;

    constructor(
        address _token,
        address _stableCoin,
        uint256 _expDate,
        address _seller,
        ITokenismWhitelist _whitelisting,
        IMarginLoan _iMarginLoan
    ) public {
        // Check of admin is whitelisted
        admin = msg.sender;
        seller = _seller;
        expDate = _expDate;
        token = IERC1400RawERC20(_token);
        stableCoin = IStableCoin(_stableCoin);
        // _whitelist = new ITokenismWhitelist();
        _whitelist = _whitelisting;
        _IMarginLoan = _iMarginLoan;
    }

    // Events Generated in Exchange

    event TokensSold(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price
    );
    event TokensPurchased(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price
    );
    event Counter(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price
    );
    event CancelContract(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price
    );
    event CancelCounter(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price
    );
    event AcceptCounter(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price,
        string message
    );
    event RejectCounter(
        address indexed wallet,
        address indexed token,
        uint256 quantity,
        uint256 price,
        string message
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "Sender must be admin");
        _;
    }
    modifier onlyTokenismAdmin() {
        require(_whitelist.isAdmin(msg.sender), "Only admin is allowed is transfer tokens");
        _;
    }

    modifier isSell() {
        require(sellPlaced, "Please execute sell order");
        _;
    }

    function isStatus() public view returns (string memory) {
        if (remainingQty == totalQty) return "Open";
        if ((remainingQty.add(holdToken)) == 0) return "Completed";
        return "Partial";
    }

    function sellTokens(uint256 _price, uint256 _quantity) nonReentrant public onlyAdmin {
        require(!sellPlaced, "Sell cannot be placed twice");
        // token.addFromExchange(seller , totalQty);
        // User can't sell more tokens than they have*
        require(
            token.balanceOf(seller) >= totalQty,
            "User Must Have Balance Greater or Equal to Sell Amount"
        );
        require(
            _price > 0 && _quantity > 0,
            "Price and Quantity must be greater than zero"
        );
        price = _price;
        totalQty = _quantity;
        remainingQty = _quantity;
        sellPlaced = true;

        // Transfer ERC1400 from Seller to Contract
        token.transferFrom(seller, address(this), totalQty);
        token.addFromExchange(seller, totalQty);
        emit TokensSold(seller, address(token), _quantity, _price);
    }

    // function getSellerLoan(address _seller , uint256 _id) public view returns(uint256 , address){
    //     if(_IMarginLoan.getLoanStatus(seller , _id) == 2){
    //           (address _user,address _bank,uint256 _loanAmount , uint256 _interestRate, ,address _tokenAddress) = _IMarginLoan.getMarginLoan(seller);
    //           uint256 interestAmount =  calculateMarginLoan(_loanAmount, _interestRate);
    //           uint256 loanPay= interestAmount.add(_loanAmount);
    //         //   buyerPay -= loanPay;
    //           return (loanPay , _bank);

    //         //   stableCoin.transferFrom(_wallet, _bank, loanPay);
    //      }
    //      return (0 , address(0));

    // }
    /** Buyer Direct Buy Token on that price */
    function buyTokens(uint256 _quantity, address _wallet) nonReentrant public {
        // return _IMarginLoan.getLoanStatus(seller);
        if ((token.balanceOf(_wallet)).add(_quantity) > token.basicCap()) {
            require(
                _whitelist.userType(_wallet),
                "You have need to Upgrade Premium Account"
            );
        }
        
        require(seller != _wallet, "Seller cannot buy token");
        require(_quantity > 0, "Quantity must be greater than zero");
        require(_quantity <= remainingQty, "Tokens are not available");
        // Calculate the number of TKSD to buy
        uint256 totalAmount = _quantity.mul(price);

        uint256 buyerPay = totalAmount;

        // Require Buyer has enough TKUSD balance
        require(
            stableCoin.balanceOf(_wallet) >= buyerPay,
            "Buyer have not enough balance"
        );

        // Require that Contract has enough Security Tokens
        require(
            token.balanceOf(address(this)) >= _quantity,
            "Contract don't have enough Security Tokens"
        );

        // Transfer Fee to Tokenism address fee collection address
        require(
            stableCoin.allowance(_wallet, address(this)) >= buyerPay,
            "Buyer should allow contract to spend"
        );
        //here Seller should pay loan
        // uint256 userAmount = payLoan(
        //     address(token),
        //     seller,
        //     _quantity,
        //     buyerPay
        // );
        
        remainingQty = remainingQty.sub(_quantity);

        // Transfer TKUSD to Seller Deduct fee as well
        stableCoin.transferFrom(_wallet, seller, buyerPay);

        // Transfer tokens to the user
        token.transfer(_wallet, _quantity);
        token.updateFromExchange(seller ,_quantity);

        // Cancel all counterOffers having greater quantity than remaining tokens
        _nullOffer();

        // Emit an event
        emit TokensPurchased(_wallet, address(token), _quantity, price);
    }

    /***
    Buyer Send First Offer 
    */
    function buyerOffer(
        uint256 _quantity,
        uint256 _price,
        address _wallet
    ) public {
        // Check User Type to add Caps on User
        if ((token.balanceOf(_wallet)).add(_quantity) > token.basicCap()) {
            //  string memory userType = _whitelist.userType(_wallet);
            require(
                _whitelist.userType(_wallet),
                "You have need to Upgrade Premium Account"
            );
        }


        // Price Must be less than original Price
        require(
            _price < price,
            "Price set by Buyer must be less than seller price"
        );

        // Remaining Token must be greater than Buyer offer
        require(
            remainingQty >= _quantity,
            "Remaing Quantity is must be greater or equal to offering quantity"
        );
        uint256 totalAmount = (_quantity.mul(_price));

        // Buyer have need enough stableCoin to buy tokens
        require(
            stableCoin.balanceOf(_wallet) >= totalAmount,
            "Buyer has not enough balance"
        );

        // This Buyer have must not active order on this token
        require(
            counterOffers[_wallet].counter == 0,
            "Buyer already Counter on this token"
        );

        // Adding Buyer Request to Struct mapping and Array
        counterOffers[_wallet].valid = true;
        counterOffers[_wallet].role = "buyer";

        counterOffers[_wallet].counter = counterOffers[_wallet].counter.add(1);
        counterOffers[_wallet].buyPrice = _price;
        counterOffers[_wallet].wallet = _wallet;
        counterOffers[_wallet].quantity = _quantity;
        counterOffers[_wallet].expiryTime = now + 2 days;

        // Adding address to array
        counterAddresses.push(_wallet);

        // Transfer Stable Coin (Ammount + fee) to contract
        stableCoin.transferFrom(_wallet, address(this), totalAmount);

        // Emit an event
        emit Counter(_wallet, address(token), _quantity, _price);
    }

    /* Counter Seller on Buyer Offer/Counter */
    function counterSeller(uint256 _price, address _buyerWallet) public {
        CounterOffers storage buyOffer = counterOffers[_buyerWallet];
        require(msg.sender == seller, "Only Seller Owner can Counter");
        require(_price > buyOffer.buyPrice, "Price be greater than zero");
        require(buyOffer.valid, "No Offer submitted");
        if (buyOffer.sellPrice == 0) // need to understand if required then change
            require(_price < price, "Price must be less than Price set before");
        else
            require(
                _price < buyOffer.sellPrice,
                "Price must be less than Price set before"
            );

        require(
            StringUtils.equal(buyOffer.role, "buyer"),
            "No buyOffer submitted"
        );
        require(buyOffer.counter < 4, "counter exceeded");

        // uint256 quantityLeft = remainingQty - buyOffer.quantity;  // Check before token hold its remainigQty is enough
        // require(quantityLeft >= 0," Require You have not enough token remainig" );

        address _wallet = buyOffer.wallet;
        uint256 _quantity = buyOffer.quantity;

        buyOffer.role = "seller";
        buyOffer.sellPrice = _price;
        buyOffer.counter = buyOffer.counter.add(1);
        buyOffer.expiryTime = now + 2 days;
        // holdToken security token _quantity
        if (buyOffer.counter <= 2) {
            holdToken = holdToken.add(_quantity);
            remainingQty = remainingQty.sub(_quantity);
            // Cancel all counterOffers having greater quantity than remaining tokens
            _nullOffer();
        }

        // Event emit
        emit Counter(_wallet, address(token), _quantity, _price);
    }

    /* Counter Buyer on Seller Counter */
    function counterBuyer(uint256 _price, address _wallet) public {
        CounterOffers storage sellOffer = counterOffers[_wallet];
        require(_price > 0, "Price be greater than zero");
        require(sellOffer.counter > 0, "No sellOffer submitted"); // changes to specific step of 1 or 3 counter number
        // require(_wallet == seller, "Only seller can counter Buyer");
        require(
            StringUtils.equal(sellOffer.role, "seller"),
            "No sellOffer submitted"
        );
        // Price Must be greater than previous offer
        require(
            sellOffer.buyPrice < _price,
            "New price must be higher than previous Offer"
        );
        // Price Must be less than original Price
        require(
            _price < sellOffer.sellPrice,
            "Price set by Buyer must be less than seller counter price"
        );
        // Maximum two times counter to each other
        require(sellOffer.counter < 4, "counter exceeded");

        uint256 _quantity = sellOffer.quantity;

        // Check User Type to add Caps on User
        if ((token.balanceOf(_wallet)).add(_quantity) > token.basicCap()) {
            //  string memory userType = _whitelist.userType(_wallet);
            require(
                _whitelist.userType(_wallet),
                "You have need to Upgrade Premium Account"
            );
        }
    // TKUSD need to be transfer according to buyer new counter.
        uint256 priceDiff = _price.sub(sellOffer.buyPrice);
        uint256 totalAmount = (sellOffer.quantity.mul(priceDiff));

        // Buyer have need enough stableCoin to buy tokens
        require(
            stableCoin.balanceOf(_wallet) >= totalAmount,
            "Buyer has not enough balance"
        );
        // Transfer Fee to Tokenism address fee collection address
        require(
            stableCoin.allowance(_wallet, address(this)) >= totalAmount,
            "Buyer should allow contract to spend"
        );

        // Counter By one User can only Two times
        require(sellOffer.counter <= 2, "You should only 2 times counter");

        // Adding Buyer Request to Struct mapping and Array
        sellOffer.role = "buyer";
        sellOffer.counter = sellOffer.counter.add(1);
        sellOffer.buyPrice = _price;
        sellOffer.expiryTime = now + 2 days;

        // Revert holdToken quantity
        // holdToken -= sellOffer.quantity;
        // remainingQty += sellOffer.quantity;

        // Transfer Stable Coin (Ammount + fee) to contract
        stableCoin.transferFrom(sellOffer.wallet, address(this), totalAmount);

        // Event emit
        emit Counter(
            _wallet,
            address(token),
            sellOffer.quantity,
            sellOffer.buyPrice
        );
    }

    /* Cancel Contract by Seller*/
    function cancelContract() public returns (bool) {
        // Only Seller Can cancell Contract
        require(msg.sender == seller, "Only Seller Can Cancell Order");

        // Status of Order must not be completed
        require(
            !StringUtils.equal(isStatus(), "Completed"),
            "This Order is Completed"
        );

        uint256 _price;
        address _wallet;
        uint256 _quantity;

        // Transfer Stable Coins to Buyer Counters Addresses
        for (uint256 i = 0; i < counterAddresses.length; i++) {
            if (counterOffers[counterAddresses[i]].valid) {
                _price = counterOffers[counterAddresses[i]].buyPrice;
                _wallet = counterOffers[counterAddresses[i]].wallet;
                _quantity = counterOffers[counterAddresses[i]].quantity;

                uint256 totalAmount = (_quantity.mul(_price));

                // Transfer Fee to Tokenism address fee collection address
                counterOffers[counterAddresses[i]].valid = false;
                counterOffers[counterAddresses[i]].counter = 0;
                stableCoin.transfer(_wallet, totalAmount);
                delete counterAddresses[i];
            }
        }
        // Transfer Token to Seller Address
        remainingQty = remainingQty.add(holdToken);
        uint256 transferholdToken = remainingQty;

        remainingQty = 0;
        holdToken = 0;


        token.transfer(seller, transferholdToken);
        token.updateFromExchange(seller ,transferholdToken);

     

        // Event emit
        emit CancelContract(seller, address(token), _quantity, price);
    }

    // Cancel Buyer itself Offer/Counter
    function cancelBuyer() public {
        // Buyer must active
        require(
            counterOffers[msg.sender].valid &&
                StringUtils.equal(counterOffers[msg.sender].role, "buyer"),
            "Buyer haven't any active Counter"
        );

        if (counterOffers[msg.sender].counter > 1) {
            holdToken = holdToken.sub(counterOffers[msg.sender].quantity);
            remainingQty = remainingQty.add(counterOffers[msg.sender].quantity);
        }
        // Remove status and role from mapping struct
        counterOffers[msg.sender].valid = false;
        counterOffers[msg.sender].role = "";
        counterOffers[msg.sender].counter = 0;

        // Calculate Amount to send Buyer

        uint256 _price = counterOffers[msg.sender].buyPrice;
        address _wallet = counterOffers[msg.sender].wallet;
        uint256 _quantity = counterOffers[msg.sender].quantity;

        uint256 totalAmount = (_quantity.mul(_price));

        // Transfer Stable Coin to Buyer
        stableCoin.transfer(_wallet, totalAmount);

        // Event emit
        emit CancelCounter(_wallet, address(token), _quantity, _price);
    }

    /* Cancel Seller itself Offer/Counter*/
    function cancelSeller(address _wallet) public {
        CounterOffers storage sellOffer = counterOffers[_wallet];
        require(msg.sender == seller, "Only Seller Owner can Cancel Offer");
        require(sellOffer.valid, "No sellOffer submitted");
        require(
            StringUtils.equal(sellOffer.role, "seller"),
            "No sellOffer submitted"
        );

        // Revert holdToken quantity
        holdToken = holdToken.sub(sellOffer.quantity);
        remainingQty = remainingQty.add(sellOffer.quantity);

        // Transfer Back Stable coin counter by buyer to him

        uint256 _price = counterOffers[_wallet].buyPrice;
        uint256 _quantity = counterOffers[_wallet].quantity;

        // Calculate Amount to send Buyer
        uint256 totalAmount = (_quantity.mul(_price));

        counterOffers[_wallet].role = "";
        counterOffers[_wallet].sellPrice = 0;
        counterOffers[_wallet].buyPrice = 0;
        counterOffers[_wallet].valid = false;
        counterOffers[_wallet].counter = 0;

        // Transfer Stable Coin to Buyer
        stableCoin.transfer(_wallet, totalAmount);

        
        // Event emit
        emit CancelCounter(
            _wallet,
            address(token),
            _quantity,
            counterOffers[_wallet].sellPrice
        );
    }

    /* Accept Counter By Buyer or Seller */
    function acceptCounter(address _buyerWallet) nonReentrant public {
        if (msg.sender == seller) {
            CounterOffers storage buyOffer = counterOffers[_buyerWallet];
            require(
                buyOffer.valid && StringUtils.equal(buyOffer.role, "buyer"),
                "No Buy Offer submitted"
            );

            uint256 _quantity = buyOffer.quantity;
            // Check User type to add Caps
            if (
                (token.balanceOf(msg.sender)).add(_quantity) > token.basicCap()
            ) {
                //  string memory userType = _whitelist.userType(msg.sender);
                require(
                    _whitelist.userType(msg.sender),
                    "You have need to Upgrade Premium Account"
                );
            }
            address _wallet = buyOffer.wallet;
            uint256 _price = buyOffer.buyPrice;
            
            uint256 totalAmount = (_quantity.mul(_price));

            //here Seller should pay loan
            // uint256 userAmount = payLoan(
            //     address(token),
            //     seller,
            //     _quantity,
            //     totalAmount
            // );
            
            if (buyOffer.counter <= 1){
                remainingQty = remainingQty.sub(_quantity);
            }
            else {
                holdToken = holdToken.sub(_quantity);
            }

            buyOffer.role = "";
            buyOffer.counter = 0;
            buyOffer.valid = false;
            buyOffer.sellPrice = 0;
            buyOffer.buyPrice = 0;
            // Transfer Fee to Tokenism address fee collection address
            stableCoin.transfer(seller, totalAmount);

            // Give security token to buyer
            token.transfer(_wallet, _quantity);
            token.updateFromExchange(seller , _quantity);
            // Cancel all counterOffers having greater quantity than remaining tokens
            _nullOffer();

            // Event emit
            emit AcceptCounter(
                _buyerWallet,
                address(token),
                _quantity,
                _price,
                "Seller accept counter"
            );
        } else {
            CounterOffers storage sellOffer = counterOffers[msg.sender];
            require(
                sellOffer.valid && StringUtils.equal(sellOffer.role, "seller"),
                "No Sell Offer submitted"
            );

            uint256 priceDiff = sellOffer.sellPrice.sub(sellOffer.buyPrice);
            uint256 extraAmount = (sellOffer.quantity.mul(priceDiff));

            // Buyer have need enough stableCoin to buy tokens
            require(
                stableCoin.balanceOf(msg.sender) >= extraAmount,
                "Buyer has not enough balance"
            );
            // Transfer Fee to Tokenism address fee collection address
            require(
                stableCoin.allowance(msg.sender, address(this)) >= extraAmount,
                "Buyer should allow contract to spend"
            );

            // Check User Type to add Caps on User
            uint256 _quantity = sellOffer.quantity;
            if (
                (token.balanceOf(msg.sender)).add(_quantity) > token.basicCap()
            ) {
                // string memory userType = _whitelist.userType(msg.sender);
                require(
                    _whitelist.userType(msg.sender),
                    "You have need to Upgrade Premium Account"
                );
            }

            // Adding Buyer Request to Struct mapping and Array
            sellOffer.role = "buyer";
            sellOffer.counter = sellOffer.counter.add(1);
            sellOffer.buyPrice = sellOffer.sellPrice;

            // Revert holdToken quantity
            holdToken = holdToken.sub(sellOffer.quantity);
            sellOffer.role = "";
            sellOffer.counter = 0;
            sellOffer.valid = false;

           
            address _wallet = sellOffer.wallet;
            uint256 _price = sellOffer.buyPrice;
            // uint256 _quantity = sellOffer.quantity;
            uint256 totalAmount = (_quantity.mul(_price));

            // uint256 userAmount = payLoan(
            //     address(token),
            //     seller,
            //     _quantity,
            //     totalAmount
            // );
             // Transfer Stable Coin (Ammount + fee) to contract
            sellOffer.buyPrice = 0;
            sellOffer.sellPrice = 0;
            stableCoin.transferFrom(
                sellOffer.wallet,
                address(this),
                extraAmount
            );

            // Transfer Fee to Tokenism address fee collection address
            stableCoin.transfer(seller, totalAmount);

           
            // Give security token to buyer
            token.transfer(_wallet, _quantity);
            token.updateFromExchange(seller , _quantity);

            // Event emit
            emit AcceptCounter(
                _buyerWallet,
                address(token),
                _quantity,
                _price,
                "Buyer accept counter"
            );
        }
    }

    /* Reject Counter By Seller or Buyer  */
    function rejectCounter(address _buyerWallet) nonReentrant public {
        if (msg.sender == seller) {
            CounterOffers storage buyOffer = counterOffers[_buyerWallet];
            require(
                buyOffer.valid && StringUtils.equal(buyOffer.role, "buyer"),
                "No Buy Offer submitted "
            );

            address _wallet = buyOffer.wallet;
            uint256 _price = buyOffer.buyPrice;
            uint256 _quantity = buyOffer.quantity;
            uint256 totalAmount = (_quantity.mul(_price));

            if (buyOffer.counter > 1) {
                // Revert holdToken quantity
                holdToken = holdToken.sub(buyOffer.quantity);
                remainingQty = remainingQty.add(buyOffer.quantity);
            }
            buyOffer.role = "";
            buyOffer.counter = 0;
            buyOffer.valid = false;
            // Transfer Fee to Tokenism address fee collection address
            stableCoin.transfer(_wallet, totalAmount);
            
            // Event emit
            emit RejectCounter(
                _buyerWallet,
                address(token),
                _quantity,
                _price,
                "Seller reject counter"
            );
        } else {
            CounterOffers storage sellOffer = counterOffers[msg.sender];
            require(
                sellOffer.valid && StringUtils.equal(sellOffer.role, "seller"),
                "No Sell Offer submitted"
            );

            address _wallet = sellOffer.wallet;
            uint256 _price = sellOffer.buyPrice;
            uint256 _quantity = sellOffer.quantity;

            uint256 totalAmount = (_quantity.mul(_price));

            
            sellOffer.role = "";
            sellOffer.counter = 0;
            sellOffer.valid = false;

            // Revert holdToken quantity
            holdToken = holdToken.sub(sellOffer.quantity);
            remainingQty = remainingQty.add(sellOffer.quantity);
            // Transfer Fee to Tokenism address fee collection address
            stableCoin.transfer(_wallet, totalAmount);

            // Event emit
            emit RejectCounter(
                _wallet,
                address(token),
                _quantity,
                sellOffer.sellPrice,
                "Buyer reject counter"
            );
        }
    }

    /* Remove or nullyfy all Offers */
    function _nullOffer() internal returns (bool) {
        for (uint256 i = 0; i < counterAddresses.length; i++) {
            if (
                counterOffers[counterAddresses[i]].valid &&
                counterOffers[counterAddresses[i]].quantity > remainingQty &&
                counterOffers[counterAddresses[i]].counter == 1 && //+ holdToken) // Add Hold
                StringUtils.equal(
                    counterOffers[counterAddresses[i]].role,
                    "buyer"
                )
            ) {
                uint256 _price = counterOffers[counterAddresses[i]].buyPrice;
                address _wallet = counterOffers[counterAddresses[i]].wallet;
                uint256 _quantity = counterOffers[counterAddresses[i]].quantity;

                uint256 totalAmount = (_quantity.mul(_price));

               
                counterOffers[counterAddresses[i]].role = "";
                counterOffers[counterAddresses[i]].counter = 0;
                counterOffers[counterAddresses[i]].valid = false;
                 // Transfer Fee to Tokenism address fee collection address
                stableCoin.transfer(_wallet, totalAmount);
                delete counterAddresses[i]; // Test if empty value create issue
            }
        }
    }

    /* Function to Check Expiry  */
    function expireOffer(address _wallet) public {
        require(
            _whitelist.isWhitelistedUser(msg.sender) <= 112,
            "Only Admin can Call"
        );
        CounterOffers storage sellOffer = counterOffers[_wallet];
        require(sellOffer.valid, "No offer exist");
        // require(sellOffer.expiryTime < now, "Offer is not expired yet");

        if (StringUtils.equal(sellOffer.role, "seller")) {
            // Revert holdToken quantity
            holdToken = holdToken.sub(sellOffer.quantity);
            remainingQty = remainingQty.add(sellOffer.quantity);

            // Transfer Back Stable coin counter by buyer to him

            uint256 _price = counterOffers[_wallet].buyPrice;
            uint256 _quantity = counterOffers[_wallet].quantity;

            // Calculate Amount to send Buyer
            uint256 totalAmount = (_quantity.mul(_price));

            
            counterOffers[_wallet].role = "";
            counterOffers[_wallet].sellPrice = 0;
            counterOffers[_wallet].buyPrice = 0;
            counterOffers[_wallet].counter = 0;
            counterOffers[_wallet].valid = false;
            // Transfer Stable Coin to Buyer
            stableCoin.transfer(_wallet, totalAmount);

            // Event emit
            emit CancelCounter(
                _wallet,
                address(token),
                _quantity,
                counterOffers[_wallet].sellPrice
            );
        } else {

             if (sellOffer.counter >= 2) {
                holdToken = holdToken.sub(sellOffer.quantity);
                remainingQty = remainingQty.add(sellOffer.quantity);
            }

            // Remove status and role from mapping struct
            counterOffers[_wallet].valid = false;
            counterOffers[_wallet].role = "";
            counterOffers[_wallet].counter = 0;


            // Calculate Amount to send Buyer

            uint256 _price = counterOffers[_wallet].buyPrice;
            address _wallet = counterOffers[_wallet].wallet;
            uint256 _quantity = counterOffers[_wallet].quantity;


            uint256 totalAmount = (_quantity.mul(_price));
 
            counterOffers[_wallet].sellPrice = 0;
            counterOffers[_wallet].buyPrice = 0;
            // Transfer Stable Coin to Buyer
            stableCoin.transfer(_wallet, totalAmount);

            // Event emit
            emit CancelCounter(_wallet, address(token), _quantity, _price);
        }
    }

    // Change Whitelisting
    function changeWhitelist(ITokenismWhitelist _whitelisted)
        public
        onlyTokenismAdmin
        returns (bool)
    {
        _whitelist = _whitelisted;
        return true;
    }

    function tokenFallback(
        address, /*_from*/
        uint256, /*_value*/
        bytes memory /*_data*/
    ) public pure returns (bool success) {
        return true;
    }

    // function calculateMarginLoan(uint256 _loanAmount, uint256 _interestRate)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return (_loanAmount * (_interestRate / 100)) / _loanAmount;
    //     //   _loanAmount.mul((_interestRate.div(100))) /1000; // 1000*(2/100) == 0.02*1000= 20
    // }

    // function payLoan(
    //     address token,
    //     address seller,
    //     uint256 quantity,
    //     uint256 totalAmount
    // ) internal returns (uint256) {
    //     (
    //         address[] memory banks,
    //         uint256[] memory loanAmounts,
    //         uint256[] memory interestRates,
    //         uint256[] memory createdAts
    //     ) = _IMarginLoan.getTotalLoanOfToken(seller, token);

    //     (uint256[] memory noOfTokens, uint256[] memory ids) = _IMarginLoan
    //         .getTotalNoOfTokens(seller, token);

    //     if (banks.length > 0) {
    //         uint256 i;
    //         for (i = 0; i < banks.length-1; i++) {
    //             if (noOfTokens[i] <= quantity && quantity != 0) {
    //                 // loan = 3 , sell = 5  seller balance = 3 + 5 <  10
    //                 // totalAmount - LoanAmounts[i] as transfer it to Bank[i]
    //                 // update quantity
    //                 // quantity = quantity.sub(noOfTokens[i]);

    //                 // return quantity;

    //                 totalAmount = totalAmount.sub(loanAmounts[i]);
    //                 remainingAmount = totalAmount;
    //                 quantity = quantity.sub(noOfTokens[i]);
    //                 stableCoin.transferFrom(seller, banks[i], totalAmount);
    //                 // _IMarginLoan.updateLoan(seller, ids[i], 0, 0, 1);
    //                 // return quantity;
    //             } else if (noOfTokens[i] > quantity && quantity != 0) {
    //                 //  loan = 4 , sell = 2
    //                 // 2000 , 1000;
    //                 // totalAmount -loanAmouns[i] and transfer it to bank[i]
    //                 //update Quantity
    //                 // quantity = noOfTokens[i].sub(quantity);

    //                 // return quantity;
    //                 // total amount = 3000 , 5 , 3
    //                 transferTokens = totalAmount.sub(
    //                     loanAmounts[i].mul(quantity).div(noOfTokens[i])
    //                 );
    //                 // totalAmount = totalAmount.sub(loanAmounts[i]);
    //                 stableCoin.transferFrom(seller, banks[i], totalAmount);
    //                 if (totalAmount >= transferTokens) {
    //                     remainingAmount = totalAmount.sub(transferTokens);
    //                 } else {
    //                     remainingAmount = transferTokens.sub(totalAmount);
    //                 }
    //                 // _IMarginLoan.updateLoan(
    //                 //     seller,
    //                 //     ids[i],
    //                 //     transferTokens,
    //                 //     noOfTokens[i].sub(quantity),
    //                 //     2
    //                 // );
    //                 return transferTokens;

    //                 quantity = 0; // ;
    //             }
    //         }
    //         return remainingAmount;
    //     } else {
    //         return totalAmount;
    //     }
    // }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.5.0;

/**
 * @title Exchange Interface
 * @dev Exchange logic
 */
interface IExchange {
    event TokensPurchased(
        // Event Generated on token Purchased
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );

    event TokensSold(
        // Event Generated on token Sell
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );
    event Counter(
        // Event Generated on Counter by Buyer or Seller
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );
    event CancelContract(
        // Event Generated on cancell contract by seller
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );
    event CancelCounter(
        // Event Generated on Counter cancel by seller or  buyer
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );
    event AcceptCounter(
        // Event Generated on Accept counter by seller or buyer
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );
    event RejectCounter(
        // Event Generated on reject counter by seller or buyer
        address wallet,
        address token,
        uint256 quantity,
        uint256 price,
        string message
    );
}

pragma solidity ^0.5.0;

interface IStableCoin{
    function transferWithData(address _account,uint256 _amount, bytes calldata _data ) external returns (bool success) ;
    function transfer(address _account, uint256 _amount) external returns (bool success);
    function burn(uint256 _amount) external;
    function burnFrom(address _account, uint256 _amount) external;
    function mint(address _account, uint256 _amount) external returns (bool);
    function transferOwnership(address payable _newOwner) external returns (bool);
    
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);


}

pragma solidity ^0.5.0;

interface IMarginLoan {
    /**
     * LoanStatus : it will have only follwoing three values.
     */
    enum LoanStatus {NOTFOUND, PENDING, ACTIVE, COMPLETE, REJECT, CANCEL}
    /**
     * MarginLoan: This struct will Provide the required field of Loan record
     */
    struct MarginLoan {
        address user;
        address bank;
        uint256 loanAmount;
        uint256 interestRate;
        LoanStatus status;
        address tokenAddress;
        uint256 createdAt;
        uint256 installmentAmount;
        uint256 noOfTokens;
    }

    /**
     * LoanRequest: This event will triggered when ever their is request for loan
     */
    event LoanRequest(
        address user,
        address bank,
        uint256 loanAmount,
        uint256 interestRate,
        LoanStatus status,
        address tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 id
    );
    event UpdateLoan(address user, uint256 id, LoanStatus status);

    /**
     * called when user request loan from bank
     *
     */
    function requestLoan(
        address _bank,
        uint256 _loanAmount,
        uint256 _interestRate,
        address _tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 noOfTokens
    ) external;

    /**
     * only user with a rule of bank can approve loan
     */
    function approveLoan(address _user, uint256 _id) external returns (bool);

    /**
     * only user with a rule of bank can reject loan
     */
    function rejectLoan(address _user, uint256 _id) external returns (bool);

    /**
     * this function would return user margin with erc1400 address
     */
    function getLoan(address _user, address tokenAddress)
        external
        view
        returns (uint256);

    /**
     * only user with a rule of bank can approve loan
     */
    function completeLoan(address _user, uint256 _id) external returns (bool);

    /**
     *getLoanStatus: thsi function return loan status of address provided
     */
    function getLoanStatus(address _user, uint256 _id)
        external
        view
        returns (uint256);

    /**
     * only user with a rule of bank can reject loan
     */
    function cancelLoan(uint256 _id) external returns (bool);

    /**
     * get Margin loan record of customer
     */
    function getMarginLoan(address _user, uint256 id)
        external
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            LoanStatus,
            address,
            uint256,
            uint256,
            uint256
        );

    /**
     * get t0tal of margin loan array of address
     */
    function getTotalLoans(address _user) external view returns (uint256);

    /**
     * get total number of  loan on a signle erc1400 token
     */
    //  function getTotalLoanOfToken(address _user , address _token) external view returns(MarginLoan[] memory);

    function getTotalLoanOfToken(address _user, address _token)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function getTotalNoOfTokens(address _user, address _token)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function updateLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 noOfTokens,
        uint256 caller
    ) external;
}

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */
// pragma solidity ^0.5.0;

// /**
//  * @title Exchange Interface
//  * @dev Exchange logic
//  */
// interface IERC1400RawERC20  {

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */

//   function name() external view returns (string memory); // 1/13
//   function symbol() external view returns (string memory); // 2/13
//   function totalSupply() external view returns (uint256); // 3/13
//   function balanceOf(address owner) external view returns (uint256); // 4/13
//   function granularity() external view returns (uint256); // 5/13

//   function controllers() external view returns (address[] memory); // 6/13
//   function authorizeOperator(address operator) external; // 7/13
//   function revokeOperator(address operator) external; // 8/13
//   function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

//   function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
//   function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

//   function redeem(uint256 value, bytes calldata data) external; // 12/13
//   function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
//    // Added Latter
//    function cap(uint256 propertyCap) external;
//   function basicCap() external view returns (uint256);
//   function getStoredAllData() external view returns (address[] memory, uint256[] memory);

//     // function distributeDividends(address _token, uint256 _dividends) external;
//   event TransferWithData(
//     address indexed operator,
//     address indexed from,
//     address indexed to,
//     uint256 value,
//     bytes data,
//     bytes operatorData
//   );
//   event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
//   event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
//   event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
//   event RevokedOperator(address indexed operator, address indexed tokenHolder);

//  function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
// function allowance(address owner, address spender) external view returns (uint256);
// function approve(address spender, uint256 value) external returns (bool);
// function transfer(address to, uint256 value) external  returns (bool);
// function transferFrom(address from, address to, uint256 value)external returns (bool);
// function migrate(address newContractAddress, bool definitive)external;
// function closeERC1400() external;
// function addFromExchange(address investor , uint256 balance) external returns(bool);
// function updateFromExchange(address investor , uint256 balance) external;
// function transferOwnership(address payable newOwner) external; 
// }
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.5.0;

/**
 * @title Exchange Interface
 * @dev Exchange logic
 */
interface IERC1400RawERC20  {

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

  function name() external view returns (string memory); // 1/13
  function symbol() external view returns (string memory); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function controllers() external view returns (address[] memory); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

  function redeem(uint256 value, bytes calldata data) external; // 12/13
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   // Added Latter
   function cap(uint256 propertyCap) external;
  function basicCap() external view returns (uint256);
  function getStoredAllData() external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

 function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 value) external returns (bool);
function transfer(address to, uint256 value) external  returns (bool);
function transferFrom(address from, address to, uint256 value)external returns (bool);
function migrate(address newContractAddress, bool definitive)external;
function closeERC1400() external;
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
function updateFromExchange(address investor , uint256 balance) external returns (bool);
function transferOwnership(address payable newOwner) external; 
}

pragma solidity ^0.5.0;


library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b)
        internal
        pure
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }

    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle)
        internal
        pure
        returns (int256)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if (h.length < 1 || n.length < 1 || (n.length > h.length)) return -1;
        else if (h.length > (2**128 - 1))
            // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;
        else {
            uint256 subindex = 0;
            for (uint256 i = 0; i < h.length; i++) {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while (
                        subindex < n.length &&
                        (i + subindex) < h.length &&
                        h[i + subindex] == n[subindex] // search until the chars don't match or until we reach the end of a or b
                    ) {
                        subindex++;
                    }
                    if (subindex == n.length) return int256(i);
                }
            }
            return -1;
        }
    }

    // function toBytes(address a) 
    //    internal
    //     pure
    //     returns (bytes memory) {
    // return abi.encodePacked(a);
    // }
}

pragma solidity ^0.5.0;


interface ITokenismWhitelist {
    function addWhitelistedUser(address _wallet, bool _kycVerified, bool _accredationVerified, uint256 _accredationExpiry) external;
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    function suspendUser(address _wallet) external;

    function activeUser(address _wallet) external;

    function updateUserType(address _wallet, string calldata _userType) external;
    function isWhitelistedUser(address wallet) external view returns (uint);
    function removeWhitelistedUser(address _wallet) external;
    function isWhitelistedManager(address _wallet) external view returns (bool);

 function removeSymbols(string calldata _symbols) external returns(bool);
 function closeTokenismWhitelist() external;
 function addSymbols(string calldata _symbols)external returns(bool);

  function isAdmin(address _admin) external view returns(bool);
  function isOwner(address _owner) external view returns (bool);
  function isBank(address _bank) external view returns(bool);
  function isSuperAdmin(address _calle) external view returns(bool);
  function getFeeStatus() external returns(uint8);
  function getFeePercent() external view returns(uint8);
  function getFeeAddress()external returns(address);

    function isManager(address _calle)external returns(bool);
    function userType(address _caller) external view returns(bool);

}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}