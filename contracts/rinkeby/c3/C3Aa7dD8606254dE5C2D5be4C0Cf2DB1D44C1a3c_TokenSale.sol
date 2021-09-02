//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20Token {
    function balanceOf(address owner) external returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) external returns (bool);

    function approve(address delegate, uint256 numberOfTokens)
        external
        returns (bool);
}

interface IStockPrice {
    function update(string memory _symbol) external payable;

    function price() external returns (uint256);
}

contract TokenSale {
    IERC20Token public tokenContract; // the token being sold
    uint256 public price; // the price, in wei, per token
    address owner;
    bool buysTokens;
    uint256 public contractTokens;
    bool sellsTokens;
    uint256 public tokensSold;
    IStockPrice public stockPrice;

    event Sold(address buyer, uint256 amount);
    event MakerDepositedEther(uint256 amount);
    event TokensSoldToContract(address seller, uint256 amount);
    event ActivatedEvent(bool buys, bool sells);
    event PriceUpdatedbyOracle(IERC20Token tokenContract, uint256 newPrice);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );

    constructor(
        IERC20Token _tokenContract,
        uint256 _price,
        bool _buysTokens,
        bool _sellsTokens,
        IStockPrice _stockPrice
    ) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
        buysTokens = _buysTokens;
        sellsTokens = _sellsTokens;
        stockPrice = _stockPrice;
        emit ActivatedEvent(buysTokens, sellsTokens);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    /*function grantContractPermission(uint256 amountOfTokens) internal returns (bool){
        tokenContract.approve(address(this), amountOfTokens);
        //emit Approval(msg.sender, address(this), amountOfTokens);
        return true;
    }*/

    function activate(bool _buysTokens, bool _sellsTokens) public onlyOwner {
        buysTokens = _buysTokens;
        sellsTokens = _sellsTokens;
        emit ActivatedEvent(buysTokens, sellsTokens);
    }

    function buyTokens(uint256 numberOfTokens) public payable {
        if (sellsTokens || msg.sender == owner) {
            require(msg.value == safeMultiply(numberOfTokens, price));
            require(tokenContract.balanceOf(address(this)) >= numberOfTokens);
            emit Sold(msg.sender, numberOfTokens);
            tokensSold += numberOfTokens;
            require(tokenContract.transfer(msg.sender, numberOfTokens));
        } else {
            payable(msg.sender).transfer(msg.value);
        }
    }

    function sellTokens(uint256 amountOfTokensToSell) public {
        if (buysTokens || msg.sender == owner) {
            require(tokenContract.approve(address(this), amountOfTokensToSell));
            // Note that buyPrice has already been validated as > 0
            uint256 can_buy = address(this).balance / price;
            // Adjust order for funds available
            require(amountOfTokensToSell <= can_buy);

            // Extract user tokens
            require(
                tokenContract.transferFrom(
                    msg.sender,
                    address(this),
                    amountOfTokensToSell
                )
            );
            // Pay user
            uint256 ethOwed = safeMultiply(amountOfTokensToSell, price);
            payable(msg.sender).transfer(ethOwed);

            emit TokensSoldToContract(msg.sender, amountOfTokensToSell);
        }
    }

    function endSale() public {
        require(msg.sender == owner);

        // Send unsold tokens to the owner.
        require(
            tokenContract.transfer(
                owner,
                tokenContract.balanceOf(address(this))
            )
        );

        payable(msg.sender).transfer(address(this).balance);
    }

    function ownerDepositEther() public payable onlyOwner {
        emit MakerDepositedEther(msg.value);
    }

    function oracleUpdateStockPrice(string memory _symbol) public onlyOwner {
        stockPrice.update(_symbol);
        price = stockPrice.price();
        //price = uint256(priceGetter.stockResult);
        emit PriceUpdatedbyOracle(tokenContract, price);
    }

    function contractWeiBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function updateContractsTokenBalance() external returns (uint256) {
        return contractTokens = tokenContract.balanceOf(address(this));
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}