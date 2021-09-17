// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.6;

import "./INEFTiMTFeeCalcExt.sol";
import "./IERC20.sol";
// import "./libOZ-4.1.0/utils/math/SafeMath.sol";
import "./SafeMath.sol";
// import "./libOZ-4.1.0/access/Ownable.sol";
import "./Ownable.sol";

contract NEFTiMTFeeCalcExtension is INEFTiMTFeeCalcExt, Ownable {
    using SafeMath for uint256;

    IERC20 NFT_Token = IERC20(0xFaAb744dB9def8e13194600Ed02bC5D5BEd3B85C);
    uint256 internal NFT_Decimals = 16;
    IERC20 B20_Token = IERC20(0x55d398326f99059fF775485246999027B3197955);
    uint256 internal B20_Decimals = 18;

    enum PaymentType {
        MODE_BNB_NFT,
        MODE_BNB,
        MODE_B20_NFT,
        MODE_B20,
        MODE_NFT
    }
    // uint8 internal MODE_BNB_NFT = 0; uint8 internal MODE_BNB = 1;
    // uint8 internal MODE_B20_NFT = 2; uint8 internal MODE_B20 = 3;
    // uint8 internal MODE_NFT = 4;

    event OnSetBaseFee( uint256 bnbMin, uint256 bnbMax, uint256 b20Min, uint256 b20Max, uint256 nftMin, uint256 nftMax );
    event OnSetDivider( uint256 newDivider );
    event OnSetDefaultPaymentType( uint8 defaultType, string defaultTypeAsString );

    uint256 internal bnbMin = 0.00084 ether;  uint256 internal bnbMax = 0.0014 ether;
    uint256 internal b20Min = 0.45 ether;  uint256 internal b20Max = 0.7 ether;
    uint256 internal nftMin = 40 * (10**NFT_Decimals);  uint256 internal nftMax = 100 * (10**NFT_Decimals);

    uint256 internal defaultDivider = 10;
    PaymentType internal defaultPaymentType = PaymentType.MODE_BNB; 

    constructor (
        address _b20Token,
        uint256 _b20Decimals,
        address _nftToken,
        uint256 _nftDecimals,
        uint256 _bnbMin, uint _bnbMax,
        uint256 _b20Min, uint _b20Max,
        uint256 _nftMin, uint _nftMax,
        uint256 _defaultDivider
    ) {
        NFT_Token = IERC20(_nftToken);
        NFT_Decimals = _nftDecimals;
        B20_Token = IERC20(_b20Token);
        B20_Decimals = _b20Decimals;
        bnbMin = _bnbMin;  bnbMax = _bnbMax;
        b20Min = _b20Min;  b20Max = _b20Max;
        nftMin = _nftMin;  nftMax = _nftMax;
        defaultDivider = _defaultDivider;
    }
    
    /**
    * @notice Calculates mint fees based on input params
    * @param holder address of NFT_Token holder
    * @param fPayMode 0 - MODE_BNB_NFT, 1 - MODE_BNB,
    *                 2 - MODE_B20_NFT, 3 - MODE_B20,
    *                 4 - MODE_NFT
    */
    function _calcFeeNFT_Token(address holder, uint8 fPayMode)
        internal view
        returns( uint256 bnbFee, uint256 B20_TokenFee, uint256 NFT_TokenFee )
    {
        require (fPayMode <= 4, "INVALID PAYMENT METHOD");
        uint B20_TokenUserBalance = B20_Token.balanceOf(holder);
        uint NFT_TokenUserBalance = NFT_Token.balanceOf(holder);
        
        if ((fPayMode == uint8(PaymentType.MODE_BNB_NFT)) && (fPayMode == 0)) {
            require(
                (holder == address(0) || holder == address(0x0)) ||
                holder.balance >= bnbMin,
                "BNB balance is too low"
            );
            require(
                (holder == address(0) || holder == address(0x0)) ||
                NFT_TokenUserBalance >= nftMin,
                "NFT_Token balance is too low"
            );
            return ( /* bnbFee  */ bnbMin, /* B20_TokenFee  */ 0, /* NFT_TokenFee  */ nftMin );
        }
        else if ((fPayMode == uint8(PaymentType.MODE_BNB)) && (fPayMode == 1)) {
            require(
                (holder == address(0) || holder == address(0x0)) ||
                holder.balance >= bnbMax,
                "BNB balance is too low"
            );
            return ( /* bnbFee  */ bnbMax, /* B20_TokenFee  */ 0, /* NFT_TokenFee  */ 0      );
        }
        else if ((fPayMode == uint8(PaymentType.MODE_B20_NFT)) && (fPayMode == 2)) {
            require(
                (holder == address(0) || holder == address(0x0)) ||
                B20_TokenUserBalance >= b20Min,
                "B20_Token balance is too low"
            );
            require(
                (holder == address(0) || holder == address(0x0)) ||
                NFT_TokenUserBalance >= nftMin,
                "NFT_Token balance is too low"
            );
            return ( /* bnbFee  */ 0, /* B20_TokenFee  */ b20Min, /* NFT_TokenFee  */ nftMin );
        }
        else if ((fPayMode == uint8(PaymentType.MODE_B20)) && (fPayMode == 3)) {
            require(
                (holder == address(0) || holder == address(0x0)) ||
                B20_TokenUserBalance >= b20Max,
                "B20_Token balance is too low"
            );
            return ( /* bnbFee  */ 0, /* B20_TokenFee  */ b20Min, /* NFT_TokenFee  */ 0 );
        }
        else {
            require(
                (holder == address(0) || holder == address(0x0)) ||
                NFT_TokenUserBalance >= nftMax,
                "NFT_Token balance is too low"
            );
            return ( /* bnbFee  */ 0, /* B20_TokenFee  */ 0, /* NFT_TokenFee  */ nftMax );
        }
    }

    function _calculateFee(address holder, uint256 tokenAmount, uint8 fPayMode)
        internal view
        returns( uint256 bnbFee, uint256 B20_TokenFee, uint256 NFT_TokenFee )
    {
        uint multiplier = ((tokenAmount <= defaultDivider)
            ?   1
            :   ( (tokenAmount.mod(defaultDivider) > 0)
                ? tokenAmount.div(defaultDivider).add(1)
                : tokenAmount.div(defaultDivider)
            )
        );
        ( uint256 _bnbFee, uint256 _b20TokenFee, uint256 _nftTokenFee ) = _calcFeeNFT_Token(holder, fPayMode);
        return (_bnbFee.mul(multiplier), _b20TokenFee.mul(multiplier), _nftTokenFee.mul(multiplier));
    }
    function calculateFee(address holder, uint256 tokenAmount, uint8 fPayMode)
        external override view
        returns( uint256 bnbFee, uint256 B20_TokenFee, uint256 NFT_TokenFee )
    { return _calculateFee(holder, tokenAmount, fPayMode); }

    function getBaseFee()
        external override view
        returns(
            uint256[2] memory bnbMinMax,
            uint256[2] memory b20MinMax,
            uint256[2] memory nftMinMax,
            uint256[3] memory nftFee,
            uint256[3] memory multitokenFee,
            uint256 multitokenOnEach,
            string memory feeAs
        )
    {
        ( uint256 _bnbFee_NFT, uint256 _b20Fee_NFT, uint256 _nftFee_NFT ) = _calculateFee(address(0), 1, uint8(defaultPaymentType));
        ( uint256 _bnbFee_SFT, uint256 _b20Fee_SFT, uint256 _nftFee_SFT ) = _calculateFee(address(0), defaultDivider, uint8(defaultPaymentType));
        
        return (
            [ bnbMin, bnbMax ],
            [ b20Min, b20Max ],
            [ nftMin, nftMax ],
            [ _bnbFee_NFT, _b20Fee_NFT, _nftFee_NFT ],
            [ _bnbFee_SFT, _b20Fee_SFT, _nftFee_SFT ],
            defaultDivider,
            ( defaultPaymentType == PaymentType.MODE_BNB_NFT
                ?    "BNB+NFT"
                :   ( defaultPaymentType == PaymentType.MODE_BNB
                    ?    "BNB"
                    :   ( defaultPaymentType == PaymentType.MODE_B20_NFT
                        ?    "B20+NFT"
                        :   ( defaultPaymentType == PaymentType.MODE_B20
                            ?    "B20"
                            :    "NFT"
                        )
                    )
                )
            )
        );
    }
    function setBaseFee(uint256 _bnbMin, uint256 _bnbMax, uint256 _b20Min, uint256 _b20Max, uint256 _nftMin, uint _nftMax)
        external onlyOwner
    {
        bnbMin = _bnbMin;  bnbMax = _bnbMax;
        b20Min = _b20Min;  b20Max = _b20Max;
        nftMin = _nftMin;  nftMax = _nftMax;
        OnSetBaseFee(bnbMin, bnbMax, b20Min, b20Max, nftMin, nftMax);
    }

    function getDivider()
        external override view
        returns(uint256 _defaultDivider)
    { return defaultDivider; }
    function setDivider(uint256 _defaultDivider)
        public onlyOwner
    {
        defaultDivider = _defaultDivider;
        emit OnSetDivider(defaultDivider);
    }

    function _getDefaultPaymentType()
        internal view
        returns(uint8 defaultType, string memory defaultTypeAsString)
    {
        return (
            uint8(defaultPaymentType),
            (
                defaultPaymentType == PaymentType.MODE_BNB_NFT
                ? "BNB+NFT"
                : (
                    defaultPaymentType == PaymentType.MODE_BNB
                    ? "BNB"
                    : (
                        defaultPaymentType == PaymentType.MODE_B20_NFT
                        ? "B20+NFT"
                        : (
                            defaultPaymentType == PaymentType.MODE_B20
                            ? "B20"
                            : "NFT"
                        )
                    )
                )
            )
        );
    }
    function getDefaultPaymentType()
        external override view
        returns(uint8 defaultType, string memory defaultTypeAsString)
    {
        return _getDefaultPaymentType();
    }
    function setDefaultPaymentType(uint8 _defaultType)
        public onlyOwner
    {
        defaultPaymentType = PaymentType(_defaultType);
        ( , string memory paymentTypeAsString ) = _getDefaultPaymentType();
        emit OnSetDefaultPaymentType(uint8(defaultPaymentType), paymentTypeAsString);
    }

    function getMintFee(uint256 _amount)
        external override view
        returns( uint256[3] memory mintFee, uint256 multitokenOnEach, string memory feeAs )
    {
        if (_amount == 0) {
            revert( "ENEFTi1155CFE__|_getMintFee__INVALID_ZERO_AMOUNT" );
        }

        string memory paymentType = 
            ( defaultPaymentType == PaymentType.MODE_BNB_NFT
                ?    "BNB+NFT"
                :   ( defaultPaymentType == PaymentType.MODE_BNB
                    ?    "BNB"
                    :   ( defaultPaymentType == PaymentType.MODE_B20_NFT
                        ?    "B20+NFT"
                        :   ( defaultPaymentType == PaymentType.MODE_B20
                            ?    "B20"
                            :    "NFT"
                        )
                    )
                )
            );

        ( uint bnbFee, uint b20Fee, uint nftFee ) = ( _amount == 1
            ? _calculateFee(address(0), _amount, uint8(defaultPaymentType))
            : _calculateFee(address(0), defaultDivider, uint8(defaultPaymentType))
        );

        return (
            [ bnbFee, b20Fee, nftFee ],
            defaultDivider,
            paymentType
        );
    }

    function getBatchMintFee(uint[] memory _amounts)
        external override view
        returns( uint256[3] memory mintFee, uint256 multitokenOnEach, string memory feeAs )
    {
        if (_amounts.length == 0) {
            revert( "ENEFTi1155CFE__|_getBatchMintFee__ZERO_LENGTH_ARRAY" );
        }

        string memory paymentType = 
            ( defaultPaymentType == PaymentType.MODE_BNB_NFT
                ?    "BNB+NFT"
                :   ( defaultPaymentType == PaymentType.MODE_BNB
                    ?    "BNB"
                    :   ( defaultPaymentType == PaymentType.MODE_B20_NFT
                        ?    "B20+NFT"
                        :   ( defaultPaymentType == PaymentType.MODE_B20
                            ?    "B20"
                            :    "NFT"
                        )
                    )
                )
            );

        uint bnbFee; uint b20Fee; uint nftFee;
        uint _bnbFee; uint _b20Fee; uint _nftFee;

        for (uint256 i=0; i < _amounts.length; i++) {
            if (_amounts[i] <= defaultDivider) {
                ( _bnbFee, _b20Fee, _nftFee ) = _calculateFee(address(0), _amounts[i], uint8(defaultPaymentType));
                bnbFee += _bnbFee;
                b20Fee += _b20Fee;
                nftFee += _nftFee;
            } else {
                ( _bnbFee, _b20Fee, _nftFee ) = _calculateFee(address(0), _amounts[i], uint8(defaultPaymentType));
                bnbFee += _bnbFee;
                b20Fee += _b20Fee;
                nftFee += _nftFee;
            }
        }

        return (
            [ bnbFee, b20Fee, nftFee ],
            defaultDivider,
            paymentType
        );
    }
}