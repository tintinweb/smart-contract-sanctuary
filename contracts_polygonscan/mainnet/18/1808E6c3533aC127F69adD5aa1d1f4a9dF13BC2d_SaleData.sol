//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./interfaces/IBaseSale.sol";
import "./interfaces/ISaleFactory.sol";
import "./libraries/CommonStructures.sol";

contract SaleData {
    ISaleFactory iSaleFactory;

    constructor(address _saleFactory) {
        iSaleFactory = ISaleFactory(_saleFactory);
    }

    function getActiveSalesCount() public view returns (uint256 count) {
        address[] memory allSales = iSaleFactory.getAllSales();

        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (!refSale.isSaleOver() && refSale.saleStarted()) {
                count++;
            }
        }
    }

    function getUpcomingSalesCount() public view returns (uint256 count) {
        address[] memory allSales = iSaleFactory.getAllSales();

        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (!refSale.isSaleOver() && !refSale.saleStarted()) {
                count++;
            }
        }
    }

    function getParticipatedSalesCount(address user) public view returns (uint256 count) {
        address[] memory allSales = iSaleFactory.getAllSales();

        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (refSale.userData(user).contributedAmount > 0) {
                count++;
            }
        }
    }

    function getClaimableSalesCount(address user) public view returns (uint256 count) {
        address[] memory allSales = iSaleFactory.getAllSales();

        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            CommonStructures.UserData memory data = refSale.userData(user);
            if (data.contributedAmount > 0 && !data.tokensClaimed && refSale.isSaleOver()) {
                count++;
            }
        }
    }

    function getRefundableSalesCount() public view returns (uint256 count) {
        address[] memory allSales = iSaleFactory.getAllSales();

        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (refSale.shouldRefundWithBal()) {
                count++;
            }
        }
    }

    function getRefundableSales() public view returns (address[] memory salesRefundable) {
        salesRefundable = new address[](getRefundableSalesCount());
        uint256 count = 0;
        for (uint256 i = 0; i < salesRefundable.length; i++) {
            IBaseSale refSale = IBaseSale(payable(salesRefundable[i]));
            if (refSale.shouldRefundWithBal()) {
                salesRefundable[count] = address(refSale);
                count++;
            }
        }
    }

    function getParticipatedSalesRefundable(address user) public view returns (uint256 count) {
        address[] memory allSales = iSaleFactory.getAllSales();

        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (refSale.userEligibleToClaimRefund(user)) {
                count++;
            }
        }
    }

    function getSalesActive() public view returns (address[] memory activeSales) {
        address[] memory allSales = iSaleFactory.getAllSales();
        uint256 count = 0;
        activeSales = new address[](getActiveSalesCount());
        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (!refSale.isSaleOver() && refSale.saleStarted()) {
                activeSales[count] = allSales[i];
                count++;
            }
        }
    }

    function getSalesUpcoming() public view returns (address[] memory activeSales) {
        address[] memory allSales = iSaleFactory.getAllSales();
        uint256 count = 0;
        activeSales = new address[](getUpcomingSalesCount());
        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (!refSale.isSaleOver() && !refSale.saleStarted()) {
                activeSales[count] = allSales[i];
                count++;
            }
        }
    }

    function getSalesUserIsIn(address user) public view returns (address[] memory salesParticipated) {
        address[] memory allSales = iSaleFactory.getAllSales();
        uint256 count = 0;
        salesParticipated = new address[](getParticipatedSalesCount(user));
        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (refSale.userData(user).contributedAmount > 0) {
                salesParticipated[count] = allSales[i];
                count++;
            }
        }
    }

    function getSalesRefundableForUser(address user) public view returns (address[] memory salesRefundable) {
        address[] memory allSales = iSaleFactory.getAllSales();
        uint256 count = 0;
        salesRefundable = new address[](getParticipatedSalesRefundable(user));
        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            if (refSale.userEligibleToClaimRefund(user)) {
                salesRefundable[count] = allSales[i];
                count++;
            }
        }
    }

    function getSalesClaimableForUser(address user) public view returns (address[] memory salesClaimable) {
        address[] memory allSales = iSaleFactory.getAllSales();
        uint256 count = 0;
        salesClaimable = new address[](getClaimableSalesCount(user));
        for (uint256 i = 0; i < allSales.length; i++) {
            IBaseSale refSale = IBaseSale(payable(allSales[i]));
            CommonStructures.UserData memory data = refSale.userData(user);
            if (data.contributedAmount > 0 && !data.tokensClaimed && refSale.isSaleOver()) {
                salesClaimable[count] = allSales[i];
                count++;
            }
        }
    }

    /*
    TODO fix this
    function getInfoArrayFromSales(address[] memory sales) internal view returns (CommonStructures.SaleDataCombined[] memory infos) {
        infos = new CommonStructures.SaleDataCombined[](sales.length);
        for (uint256 i = 0; i < sales.length; i++) {
            infos[i] = CommonStructures.SaleDataCombined({config: IBaseSale(sales[i]).saleConfig(), info: IBaseSale(sales[i]).saleInfo()});
        }
    }
    function getAllSalesWithInfo() public view returns (CommonStructures.SaleDataCombined[] memory) {
        return getInfoArrayFromSales(iSaleFactory.getAllSales());
    }

    function getUpcomingSalesWithInfo() public view returns (CommonStructures.SaleDataCombined[] memory) {
        return getInfoArrayFromSales(getSalesUpcoming());
    }

    function getActiveSalesWithInfo() public view returns (CommonStructures.SaleDataCombined[] memory) {
        return getInfoArrayFromSales(getSalesActive());
    }

    function getSalesClaimableForUserWithInfo(address user) public view returns (CommonStructures.SaleDataCombined[] memory) {
        return getInfoArrayFromSales(getSalesClaimableForUser(user));
    }

    function getSalesRefundableForUserWithInfo(address user) public view returns (CommonStructures.SaleDataCombined[] memory) {
        return getInfoArrayFromSales(getSalesRefundableForUser(user));
    }

    function getSalesUserIsInWithInfo(address user) public view returns (CommonStructures.SaleDataCombined[] memory) {
        return getInfoArrayFromSales(getSalesUserIsIn(user));
    }
    */
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "../libraries/CommonStructures.sol";

interface IBaseSale {
    function saleStarted() external view returns (bool);

    function isSaleOver() external view returns (bool);

    function shouldRefundWithBal() external view returns (bool);

    function userEligibleToClaimRefund(address) external view returns (bool);

    function saleConfig() external view returns (CommonStructures.SaleConfig memory);

    function saleInfo() external view returns (CommonStructures.SaleInfo memory);

    function userData(address) external view returns (CommonStructures.UserData memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface ISaleFactory {
    function owner() external view returns (address);

    function checkTxPrice(uint256 txGasPrice) external view returns (bool);

    function getETHFee() external view returns (uint256);

    function getAllSales() external view returns (address[] memory);

    function locker() external view returns (address);

    function retriveETH() external;

    function retriveToken(address token) external;

    function setBaseSale(address _newBaseSale) external;

    function setLocker(address _newLocker) external;

    function setNewFee(uint256 _newFee) external;

    function setGasPriceLimit(uint256 _newPrice) external;

    function toggleLimit() external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

library CommonStructures {
    // enum SaleTypes {
    //     PRESALE,
    //     DUTCH_AUCTION
    // }

    struct SaleConfig {
        //The token being sold
        address token;
        //The token / asset being accepted as contributions,for ETH its address(0)
        address fundingToken;
        //Max buy in wei
        uint256 maxBuy;
        uint256 softCap;
        uint256 hardCap;
        //Sale price in integers,example 1 or 2 tokens per eth
        uint256 salePrice;
        uint256 listingPrice;
        uint256 startTime;
        uint256 lpUnlockTime;
        //This contains the sale data from backend url
        string detailsJSON;
        //The router which we add liq to
        address router;
        //Maker of the sale
        address creator;
        //Share of eth / tokens that goes to the team
        uint256 teamShare;
    }

    struct SaleInfo {
        //Total amount of ETH or tokens raised
        uint256 totalRaised;
        //The amount of tokens to have to fullfill claims
        uint256 totalTokensToKeep;
        //Force started incase start time is wrong
        bool saleForceStarted;
        //Refunds started incase of a issue with sale contract
        bool refundEnabled;
        //Used to check if the baseSale is init
        bool initialized;
        //Returns if the sale was finalized and listed
        bool finalized;
        // Used as a way to display quality checked sales,shows up on the main page if so
        bool qualitychecked;
    }

    struct SaleDataCombined {
        SaleConfig config;
        SaleInfo info;
    }

    struct UserData {
        //total amount of funding amount contributed
        uint256 contributedAmount;
        uint256 tokensClaimable;
        bool tokensClaimed;
        bool refundTaken;
    }
}