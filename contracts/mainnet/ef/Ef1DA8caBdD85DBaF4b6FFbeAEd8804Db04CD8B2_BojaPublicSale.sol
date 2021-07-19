// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

interface oracleInterface {
    function latestAnswer() external view returns (int256);
}

interface Token {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract BojaPublicSale is Ownable {
    using SafeMath for uint256;

    uint256 decimalFactor;

    address public tokenContractAddress =
        0x9D0BbFF00a3961455CcB87E43596c7E846e57e7a;

    address public adminAddress = 0xa8Ca8862E2Ef8713dFedff3b5Da69CD5ACd6e638;
    address public USDTContractAddress =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDCContractAddress =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public ETHOracleAddress =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public USDTOracleAddress =
        0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    address public USDCOracleAddress =
        0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address public transferLeftOverAddress =
        0xE0Df9d5367CAA8Eb9E250d7587d806aA01a9eD6D;
    uint256 public PreSaleStartDate = 1626652800;
    uint256 public PreSaleEndDate = 1630022399;

    uint256 public ICOStartDate = 1630022400;
    uint256 public ICOEndDate = 1634601599;


    uint256 PreSaleTokens = 157800181;

    uint256 public preSalePrice = 38; // in 10**2..
    uint256 public icoPrice = 360; // in 10**2..
    uint256 public tokenSold;

    event BuyTokenEvent(
        address indexed userAdress,
        uint256 tokenAmount,
        uint256 inputAmount,
        uint8 indexed currencyType,
        uint256 timestamp
    );

    constructor() {
        PreSaleStartDate = block.timestamp;
        decimalFactor = 10**Token(tokenContractAddress).decimals();
    }

    function buyTokens(uint8 currencyType, uint256 amount) external payable {
        //currencyType--> 1=ETH, currencyType-->2=USDT, currencyType-->3=USDC
        require(
            block.timestamp >= PreSaleStartDate,
            "Presale has not started yet."
        );
        require(block.timestamp < ICOEndDate, "ICO Ended.");
        require(
            (Token(tokenContractAddress).balanceOf(address(this))) > 0,
            "ICO Ended."
        );
        uint256 noOfTOkens;
        uint256 inputAmount;
        if (currencyType == 1) {
            inputAmount = msg.value;
        } else if (currencyType == 2) {
            Token tokenObj = Token(USDTContractAddress);
            require(
                tokenObj.balanceOf(msg.sender) >= amount,
                "You do not have enough USDT balance"
            );
            require(
                tokenObj.allowance(msg.sender, address(this)) >= amount,
                "Please allow smart contract to spend on your behalf"
            );
            inputAmount = amount;
        } else {
            Token tokenObj = Token(USDCContractAddress);
            require(
                tokenObj.balanceOf(msg.sender) >= amount,
                "You do not have enough USDT balance"
            );
            require(
                tokenObj.allowance(msg.sender, address(this)) >= amount,
                "Please allow smart contract to spend on your behalf"
            );
            inputAmount = amount;
        }
        (noOfTOkens) = calculateToken(currencyType, inputAmount);
        require(
            (noOfTOkens <=
                Token(tokenContractAddress).balanceOf(address(this))),
            "Not enough tokens available to buy."
        );
        if (currencyType == 1) {
            TransferHelper.safeTransferETH(adminAddress, msg.value);
        } else if (currencyType == 2) {
            TransferHelper.safeTransferFrom(
                USDTContractAddress,
                msg.sender,
                adminAddress,
                amount
            );
        } else {
            TransferHelper.safeTransferFrom(
                USDCContractAddress,
                msg.sender,
                adminAddress,
                amount
            );
        }
        TransferHelper.safeTransfer(
            tokenContractAddress,
            msg.sender,
            noOfTOkens
        );
        tokenSold = tokenSold.add(noOfTOkens);
        emit BuyTokenEvent(
            msg.sender,
            noOfTOkens,
            inputAmount,
            currencyType,
            block.timestamp
        );
    }

    function calculateToken(uint8 currencyType, uint256 amount)
        public
        view
        returns (uint256)
    {
        //currencyType--> 1=ETH, currencyType-->2=USDT, currencyType-->3=USDC
        require(amount > 0, "Please enter amount greater than 0.");
        uint256 amountInUSD;
        uint256 decimalValue;
        if (currencyType == 1) {
            amountInUSD = (uint256)(
                oracleInterface(ETHOracleAddress).latestAnswer()
            );
            decimalValue = 10**18;
        } else if (currencyType == 2) {
            amountInUSD = (uint256)(
                oracleInterface(USDTOracleAddress).latestAnswer()
            );
            decimalValue = 10**Token(USDTContractAddress).decimals();
        } else if (currencyType == 3) {
            amountInUSD = (uint256)(
                oracleInterface(USDCOracleAddress).latestAnswer()
            );
            decimalValue = 10**Token(USDCContractAddress).decimals();
        }
        uint256 tokenPrice;
        if (
            block.timestamp < PreSaleEndDate &&
            tokenSold < PreSaleTokens.mul(decimalFactor)
        ) {
            tokenPrice = preSalePrice;
        } else if (
            block.timestamp < PreSaleEndDate &&
            tokenSold > PreSaleTokens.mul(decimalFactor)
        ) {
            tokenPrice = icoPrice;
        } else {
            tokenPrice = icoPrice;
        }
        uint256 tokenAmount = (
            (amountInUSD.mul(10**2).mul(decimalFactor).mul(amount)).div(
                tokenPrice.mul(decimalValue).mul(10**8)
            )
        );
        if (tokenPrice != icoPrice) {
            if (tokenSold.add(tokenAmount) > PreSaleTokens.mul(decimalFactor)) {
                uint256 tokenLeftInPresale = (PreSaleTokens.mul(decimalFactor))
                .sub(tokenSold);
                uint256 amountLeft = amount.sub(
                    (
                        tokenLeftInPresale.mul(preSalePrice).mul(10**8).mul(
                            decimalValue
                        )
                    )
                    .div(decimalFactor.mul(10**2).mul(amountInUSD))
                );
                uint256 tokenFromICO = (
                    (amountInUSD.mul(10**2).mul(decimalFactor).mul(amountLeft))
                    .div(icoPrice.mul(decimalValue).mul(10**8))
                );
                tokenAmount = tokenLeftInPresale.add(tokenFromICO);
            }
        }
        return tokenAmount;
    }

    function transferAfterICOEnd() external {
        require((block.timestamp > ICOEndDate), "ICO is currently running.");
        if (block.timestamp > ICOEndDate) {
            TransferHelper.safeTransfer(
                tokenContractAddress,
                transferLeftOverAddress,
                Token(tokenContractAddress).balanceOf(address(this))
            );
        }
    }

    function updateTokenAddress(address _tokenContractAddress)
        external
        onlyOwner
    {
        tokenContractAddress = _tokenContractAddress;
        decimalFactor = 10**Token(tokenContractAddress).decimals();
    }

    function updateAdminAddress(address _adminAddress) external onlyOwner {
        adminAddress = _adminAddress;
    }

    function updateTransferLeftOverAddress(address _transferLeftOverAddress)
        external
        onlyOwner
    {
        transferLeftOverAddress = _transferLeftOverAddress;
    }

    function updateUSDTContractAddress(address _USDTContractAddress)
        external
        onlyOwner
    {
        USDTContractAddress = _USDTContractAddress;
    }

    function updateUSDCContractAddress(address _USDCContractAddress)
        external
        onlyOwner
    {
        USDCContractAddress = _USDCContractAddress;
    }

    function updateETHOracleAddress(address _ETHOracleAddress)
        external
        onlyOwner
    {
        ETHOracleAddress = _ETHOracleAddress;
    }

    function updateUSDTOracleAddress(address _USDTOracleAddress)
        external
        onlyOwner
    {
        USDTOracleAddress = _USDTOracleAddress;
    }

    function updateUSDCOracleAddress(address _USDCOracleAddress)
        external
        onlyOwner
    {
        USDCOracleAddress = _USDCOracleAddress;
    }
}