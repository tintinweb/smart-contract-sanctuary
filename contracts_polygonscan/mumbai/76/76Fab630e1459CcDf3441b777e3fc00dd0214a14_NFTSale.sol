// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./AggregatorV3Interface.sol";

interface IERC721ChubbyAPE {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function mintTo(uint256 nums, address recipient) external;
}

interface IERC20Burn {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// library SignerCheck {
//     function recoverSigner(
//         bytes32 _ethSignedMessageHash,
//         bytes memory _signature
//     ) internal pure returns (address) {
//         (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
//         return ecrecover(_ethSignedMessageHash, v, r, s);
//     }

//     function splitSignature(bytes memory sig)
//         internal
//         pure
//         returns (
//             bytes32 r,
//             bytes32 s,
//             uint8 v
//         )
//     {
//         require(sig.length == 65);
//         assembly {
//             // first 32 bytes, after the length prefix
//             r := mload(add(sig, 32))
//             // second 32 bytes
//             s := mload(add(sig, 64))
//             // final byte (first byte of the next 32 bytes)
//             v := byte(0, mload(add(sig, 96)))
//         }
//     }

//     function getMessageHash(
//         address _to,
//         uint8 _amount,
//         uint256 _requestID
//     ) public pure returns (bytes32) {
//         return keccak256(abi.encodePacked(_to, _amount, _requestID));
//     }

//     function getEthSignedMessageHash(bytes32 _messageHash)
//         public
//         pure
//         returns (bytes32)
//     {
//         /*Signature is produced by signing a keccak256 hash with the following format:
//         "\x19Ethereum Signed Message\n" + len(msg) + msg*/
//         return
//             keccak256(
//                 abi.encodePacked(
//                     "\x19Ethereum Signed Message:\n32",
//                     _messageHash
//                 )
//             );
//     }
// }

contract NFTSale is Ownable {
    using SafeMath for uint256;

    //收錢地址
    address public EthCollector;
    //BOMT Token Owner
    address public BOMTOwner;

    //總銷售量
    uint16 public TotalSupply = 10000;

    IERC721ChubbyAPE public ChubbyAPE;

    IERC20Burn public BOMTToken;
    IERC20Burn public WETH;
    IERC20Burn public USDT;

    ////////////////Signer相關 Start////////////////
    //RequestID
    mapping(uint256 => bool) requestIDs;
    //Signer
    address public SignerAddress;
    ////////////////Signer相關  End////////////////////

    ////////////////白名單 Start////////////////
    struct WhitelistSaleSetting {
        uint256 Price;
        uint256 TotalSupply;
        uint256 Minted;
        uint256 Start;
        uint256 End;
        uint256 BonusToken;
        mapping(address => bool) whitelists;
    }
    WhitelistSaleSetting _WhitelistSaleSetting;

    function GetWhitelistSaleSetting()
        public
        view
        returns (
            uint256 _Price,
            uint256 _TotalSupply,
            uint256 _Minted,
            uint256 _Start,
            uint256 _End,
            uint256 _BonusToken
        )
    {
        return (
            _WhitelistSaleSetting.Price,
            _WhitelistSaleSetting.TotalSupply,
            _WhitelistSaleSetting.Minted,
            _WhitelistSaleSetting.Start,
            _WhitelistSaleSetting.End,
            _WhitelistSaleSetting.BonusToken
        );
    }

    ////////////////白名單 End////////////////

    ////////////////正式銷售-促銷階段 Start////////////////
    struct PreSaleSetting {
        uint256 TotalSupply;
        uint256 Minted;
        uint256 Start;
        uint256 End;
        uint256 BonusToken;
        mapping(uint256 => uint256) PreSalePrices;
    }
    PreSaleSetting _PreSaleSetting;

    uint16 public SalePerLimit = 50;

    //設定每個人的正式銷售購買上限
    function SetSalePerLimit(uint16 _count) public onlyOwner {
        SalePerLimit = _count;
    }

    function GetPreSaleSetting()
        public
        view
        returns (
            uint256 _TotalSupply,
            uint256 _Minted,
            uint256 _Start,
            uint256 _End,
            uint256 _BonusToken
        )
    {
        return (
            _PreSaleSetting.TotalSupply,
            _PreSaleSetting.Minted,
            _PreSaleSetting.Start,
            _PreSaleSetting.End,
            _PreSaleSetting.BonusToken
        );
    }

    function GetPreSalePrice(uint256 amount)
        public
        view
        returns (uint256 _price)
    {
        return _PreSaleSetting.PreSalePrices[amount];
    }

    ////////////////正式銷售-促銷階段 End////////////////

    ////////////////正式銷售 Start////////////////
    struct SaleSetting {
        uint256 TotalSupply;
        uint256 Minted;
        uint256 Start;
        uint256 End;
        uint256 BonusToken;
        mapping(uint256 => uint256) SalePrices;
    }
    SaleSetting _SaleSetting;

    function GetSaleSetting()
        public
        view
        returns (
            uint256 _TotalSupply,
            uint256 _Minted,
            uint256 _Start,
            uint256 _End,
            uint256 _BonusToken
        )
    {
        return (
            _SaleSetting.TotalSupply,
            _SaleSetting.Minted,
            _SaleSetting.Start,
            _SaleSetting.End,
            _SaleSetting.BonusToken
        );
    }

    function GetSalePrice(uint256 amount) public view returns (uint256 _price) {
        return _SaleSetting.SalePrices[amount];
    }

    ////////////////正式銷售 End////////////////

    constructor() {
        //PreDefine WhitelistSale
        // _WhitelistSaleSetting.Start = 1640443233;
        // _WhitelistSaleSetting.End = 2640443233;
        _WhitelistSaleSetting.Price = 20000000000000000;
        _WhitelistSaleSetting.Minted = 0;
        _WhitelistSaleSetting.TotalSupply = 1000;
        _WhitelistSaleSetting.BonusToken = 4000000000000000000;

        //PreDefine PreSalePrices
        _PreSaleSetting.Minted = 0;
        _PreSaleSetting.BonusToken = 4000000000000000000;
        _PreSaleSetting.PreSalePrices[1] = 30000000000000000;
        _PreSaleSetting.PreSalePrices[3] = 85500000000000000;
        _PreSaleSetting.PreSalePrices[5] = 135000000000000000;
        _PreSaleSetting.PreSalePrices[10] = 255000000000000000;
        _PreSaleSetting.PreSalePrices[15] = 360000000000000000;
        _PreSaleSetting.PreSalePrices[20] = 450000000000000000;

        //PreDefine SalePrices
        _SaleSetting.Minted = 0;
        _SaleSetting.BonusToken = 4000000000000000000;
        _SaleSetting.SalePrices[1] = 40000000000000000;
        _SaleSetting.SalePrices[3] = 114000000000000000;
        _SaleSetting.SalePrices[5] = 180000000000000000;
        _SaleSetting.SalePrices[10] = 340000000000000000;
        _SaleSetting.SalePrices[15] = 480000000000000000;
        _SaleSetting.SalePrices[20] = 600000000000000000;
    }

    //設定加簽地址
    function setSinger(address _signerAddress) public onlyOwner {
        SignerAddress = _signerAddress;
    }

    function verifySignData(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == SignerAddress;
    }

    //各階段售價設定
    function SetPrice(uint8 _type, uint256 _price) public onlyOwner {
        if (_type == 1) {
            _WhitelistSaleSetting.Price = _price;
        }
    }

    //正式銷售售價設定
    function SetBundlePrice(
        uint8 _type,
        uint8[] memory _amount,
        uint256[] memory _price
    ) public onlyOwner {
        if (_type == 2) {
            for (uint16 i = 0; i < _amount.length; i++) {
                _PreSaleSetting.PreSalePrices[_amount[i]] = _price[i];
            }
        }
        if (_type == 3) {
            for (uint16 i = 0; i < _amount.length; i++) {
                _SaleSetting.SalePrices[_amount[i]] = _price[i];
            }
        }
    }

    //各階段銷售量設定
    function SetTotalSupply(uint8 _type, uint16 _supply) public onlyOwner {
        //Type 1 is Whitelist
        if (_type == 1) {
            _WhitelistSaleSetting.TotalSupply = _supply;
        }
        //Type 2 is PreSale
        if (_type == 2) {
            _PreSaleSetting.TotalSupply = _supply;
        }
        //Type 3 is Sale
        if (_type == 3) {
            _SaleSetting.TotalSupply = _supply;
        }
    }

    //各階段銷售量設定
    function SetPeriod(
        uint8 _type,
        uint256 _start,
        uint256 _end
    ) public onlyOwner {
        //Type 1 is Whitelist
        if (_type == 1) {
            _WhitelistSaleSetting.Start = _start;
            _WhitelistSaleSetting.End = _end;
        }
        //Type 2 is PreSale
        if (_type == 2) {
            _PreSaleSetting.Start = _start;
            _PreSaleSetting.End = _end;
        }
        //Type 3 is Sale
        if (_type == 3) {
            _SaleSetting.Start = _start;
            _SaleSetting.End = _end;
        }
    }

    //各階段贈送Token數量設定
    function SetBonusToken(uint8 _type, uint256 _amount) public onlyOwner {
        //Type 1 is Whitelist
        if (_type == 1) {
            _WhitelistSaleSetting.BonusToken = _amount;
        }
        //Type 2 is PreSale
        if (_type == 2) {
            _PreSaleSetting.BonusToken = _amount;
        }
        //Type 3 is Sale
        if (_type == 3) {
            _SaleSetting.BonusToken = _amount;
        }
    }

    //SaleActive Check
    function isSaleActive(uint8 _tier) public view returns (bool) {
        if (
            _tier == 1 &&
            (block.timestamp > _WhitelistSaleSetting.Start &&
                _WhitelistSaleSetting.End > block.timestamp)
        ) {
            return true;
        }
        if (
            _tier == 2 &&
            (block.timestamp > _PreSaleSetting.Start &&
                _PreSaleSetting.End > block.timestamp)
        ) {
            return true;
        }
        if (
            _tier == 3 &&
            (block.timestamp > _SaleSetting.Start &&
                _SaleSetting.End > block.timestamp)
        ) {
            return true;
        }
        return false;
    }

    function SetERC20(uint8 _type, address _address) public onlyOwner {
        if (_type == 1) {
            WETH = IERC20Burn(_address);
        }
        if (_type == 2) {
            USDT = IERC20Burn(_address);
        }
        if (_type == 3) {
            BOMTToken = IERC20Burn(_address);
        }
    }

    function SetChubbyAPE(address _address) public onlyOwner {
        ChubbyAPE = IERC721ChubbyAPE(_address);
    }

    function SetCollector(uint8 _type, address _address) public onlyOwner {
        if (_type == 1) {
            EthCollector = _address;
        }
        if (_type == 2) {
            BOMTOwner = _address;
        }
    }

    //保留Mint
    function ReserveMint(address _recipient, uint16 _count) public onlyOwner {
        _BatchMint(_count, _recipient);
    }

    // function getMessageHash(
    //     address _to,
    //     uint8 _amount,
    //     uint256 _requestID
    // ) public pure returns (bytes32) {
    //     return SignerCheck.getMessageHash(_to, _amount, _requestID);
    // }

    function GetUSDTPrice() public view returns (uint256) {
        //Mainnet 0xF9680D99D6C9589e2a93a78A04A279e509205945
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x0715A7794a1dc8e42615F059dD6e406A6594651A
        );
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // uint256 price = 406872200923;
        //uint256 price = uint256(answeredInRound);
        return uint256(uint256(price) / uint256(10**8));
    }

    function GetMATICPrice() public view returns (uint256) {
        //Mainnet 0xF9680D99D6C9589e2a93a78A04A279e509205945
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x12162c3E810393dEC01362aBf156D7ecf6159528
        );
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        //uint256 price = 619700000000000;
        return uint256(1 * 10**24) / uint256(price);
    }

    ///#region MATIC
    //白名單Mint By MATIC
    function WhitelistMintByMATIC(
        uint8 _amount,
        uint256 _requestID,
        bytes memory _signature
    ) public payable {
        require(isSaleActive(1), "sale is not ready"); //白名單開賣檢查
        require(
            msg.value * (GetMATICPrice() / (10**6)) >=
                _WhitelistSaleSetting.Price *
                    _amount *
                    (GetMATICPrice() / (10**6)),
            "Money is not enough"
        ); //傳入金額(MATIC)檢查

        require(
            _WhitelistSaleSetting.Minted <= _WhitelistSaleSetting.TotalSupply,
            "TotalSupply is excced"
        ); //白名單總銷量檢查
        require(
            !_WhitelistSaleSetting.whitelists[msg.sender],
            "Whitelist check failed"
        ); //白名單購買上限檢查
        require(!requestIDs[_requestID], "RequestID check failed"); //重複Request ID檢查

        //驗證傳入資料
        require(
            verifySignData(
                keccak256(abi.encodePacked(msg.sender, _amount, _requestID)),
                _signature
            )
        );
        //轉出收到的錢(MATIC)
        payable(EthCollector).call{value: msg.value}("");

        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _WhitelistSaleSetting.BonusToken * _amount
        );

        //Mint Token
        _WhitelistSaleSetting.whitelists[msg.sender] = true;
        requestIDs[_requestID] = true;
        _WhitelistSaleSetting.Minted = _WhitelistSaleSetting.Minted + 1;

        _BatchMint(_amount, msg.sender);
    }

    //促銷Mint By MATIC
    function PreSaleMintByMATIC(uint256 _amount) public payable {
        require(isSaleActive(2)); //促銷開賣檢查
        require(
            msg.value * (GetMATICPrice() / (10**6)) >=
                _PreSaleSetting.PreSalePrices[_amount] *
                    (GetMATICPrice() / (10**6)) &&
                _PreSaleSetting.PreSalePrices[_amount] > 0
        ); //傳入金額(MATIC)檢查
        require(
            (_amount + _PreSaleSetting.Minted) <= _PreSaleSetting.TotalSupply
        ); //促銷銷量檢查
        require(ChubbyAPE.balanceOf(msg.sender) < SalePerLimit); //個人購買上限檢查

        //轉出收到的錢(MATIC)
        (bool sent, bytes memory data) = EthCollector.call{value: msg.value}(
            ""
        );

        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _SaleSetting.BonusToken * _amount
        );
        //Mint Token
        _PreSaleSetting.Minted = _PreSaleSetting.Minted + 1;
        _BatchMint(_amount, msg.sender);
    }

    //正式銷售Mint By MATIC
    function SaleMintByMATIC(uint256 _amount) public payable {
        require(isSaleActive(3)); //正式銷售開賣檢查
        require(
            msg.value * (GetMATICPrice() / (10**6)) >=
                _SaleSetting.SalePrices[_amount] *
                    (GetMATICPrice() / (10**6)) &&
                _SaleSetting.SalePrices[_amount] > 0
        ); //傳入金額檢查
        require((_amount + _SaleSetting.Minted) <= _SaleSetting.TotalSupply); //正式銷售銷量檢查
        require(ChubbyAPE.balanceOf(msg.sender) < SalePerLimit); //個人購買上限檢查

        //轉出收到的錢(MATIC)
        (bool sent, bytes memory data) = EthCollector.call{value: msg.value}(
            ""
        );

        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _SaleSetting.BonusToken * _amount
        );
        //Mint Token
        _SaleSetting.Minted = _SaleSetting.Minted + 1;
        _BatchMint(_amount, msg.sender);
    }

    ///#endregion MATIC

    ///#region USDT
    //白名單Mint By USDT
    function WhitelistMintByUSDT(
        uint8 _amount,
        uint256 _value,
        uint256 _requestID,
        bytes memory _signature
    ) public {
        require(isSaleActive(1)); //白名單開賣檢查
        require(
            _value >= (_WhitelistSaleSetting.Price * GetUSDTPrice() * _amount)
        ); //傳入金額(USDT)檢查
        require(
            _WhitelistSaleSetting.Minted <= _WhitelistSaleSetting.TotalSupply
        ); //白名單總銷量檢查
        require(!_WhitelistSaleSetting.whitelists[msg.sender]); //白名單購買上限檢查
        require(!requestIDs[_requestID]); //重複Request ID檢查

        //驗證傳入資料
        require(
            verifySignData(
                keccak256(abi.encodePacked(msg.sender, _amount, _requestID)),
                _signature
            )
        );
        //轉出收到的錢(USDT)
        USDT.transferFrom(msg.sender, EthCollector, _value);
        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _WhitelistSaleSetting.BonusToken * _amount
        );

        //Mint Token
        _WhitelistSaleSetting.whitelists[msg.sender] = true;
        requestIDs[_requestID] = true;
        _WhitelistSaleSetting.Minted = _WhitelistSaleSetting.Minted + 1;

        _BatchMint(_amount, msg.sender);
    }

    //促銷Mint By USDT
    function PreSaleMintByUSDT(uint256 _amount, uint256 _value) public {
        require(isSaleActive(2)); //促銷開賣檢查
        require(
            _value >= _PreSaleSetting.PreSalePrices[_amount] * GetUSDTPrice() &&
                _PreSaleSetting.PreSalePrices[_amount] > 0
        ); //傳入金額(WETH)檢查
        require(
            (_amount + _PreSaleSetting.Minted) <= _PreSaleSetting.TotalSupply
        ); //促銷銷量檢查
        require(ChubbyAPE.balanceOf(msg.sender) < SalePerLimit); //個人購買上限檢查

        //轉出收到的錢(USDT)
        USDT.transferFrom(msg.sender, EthCollector, _value);
        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _SaleSetting.BonusToken * _amount
        );
        //Mint Token
        _PreSaleSetting.Minted = _PreSaleSetting.Minted + 1;
        _BatchMint(_amount, msg.sender);
    }

    //正式銷售Mint By USDT
    function SaleMintByUSDT(uint256 _amount, uint256 _value) public {
        require(isSaleActive(3)); //正式銷售開賣檢查
        require(
            _value >= _SaleSetting.SalePrices[_amount] * GetUSDTPrice() &&
                _SaleSetting.SalePrices[_amount] > 0
        ); //傳入金額檢查
        require((_amount + _SaleSetting.Minted) <= _SaleSetting.TotalSupply); //正式銷售銷量檢查
        require(ChubbyAPE.balanceOf(msg.sender) < SalePerLimit); //個人購買上限檢查

        //轉出收到的錢(USDT)
        USDT.transferFrom(msg.sender, EthCollector, _value);
        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _SaleSetting.BonusToken * _amount
        );
        //Mint Token
        _SaleSetting.Minted = _SaleSetting.Minted + 1;
        _BatchMint(_amount, msg.sender);
    }

    ///#endregion USDT

    ///#region WETH
    //白名單Mint By WETH
    function WhitelistMintByWETH(
        uint8 _amount,
        uint256 _value,
        uint256 _requestID,
        bytes memory _signature
    ) public {
        require(isSaleActive(1)); //白名單開賣檢查
        require(_value >= (_WhitelistSaleSetting.Price * _amount)); //傳入金額(WETH)檢查
        require(
            _WhitelistSaleSetting.Minted <= _WhitelistSaleSetting.TotalSupply
        ); //白名單總銷量檢查
        require(!_WhitelistSaleSetting.whitelists[msg.sender]); //白名單購買上限檢查
        require(!requestIDs[_requestID]); //重複Request ID檢查

        //驗證傳入資料
        require(
            verifySignData(
                keccak256(abi.encodePacked(msg.sender, _amount, _requestID)),
                _signature
            )
        );
        //轉出收到的錢(WETH)
        WETH.transferFrom(msg.sender, EthCollector, _value);
        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _WhitelistSaleSetting.BonusToken * _amount
        );

        //Mint Token
        _WhitelistSaleSetting.whitelists[msg.sender] = true;
        requestIDs[_requestID] = true;
        _WhitelistSaleSetting.Minted = _WhitelistSaleSetting.Minted + 1;

        _BatchMint(_amount, msg.sender);
    }

    //促銷Mint By WETH
    function PreSaleMintByWETH(uint256 _amount, uint256 _value) public {
        require(isSaleActive(2)); //促銷開賣檢查
        require(
            _value >= _PreSaleSetting.PreSalePrices[_amount] &&
                _PreSaleSetting.PreSalePrices[_amount] > 0,
            "Money is not enough"
        ); //傳入金額(WETH)檢查
        require(
            (_amount + _PreSaleSetting.Minted) <= _PreSaleSetting.TotalSupply,
            "sale limit is exceed"
        ); //促銷銷量檢查
        require(
            ChubbyAPE.balanceOf(msg.sender) < SalePerLimit,
            "PrePerson limit is exceed"
        ); //個人購買上限檢查

        //轉出收到的錢(WETH)
        WETH.transferFrom(msg.sender, EthCollector, _value);
        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _SaleSetting.BonusToken * _amount
        );
        //Mint Token
        _PreSaleSetting.Minted = _PreSaleSetting.Minted + 1;
        _BatchMint(_amount, msg.sender);
    }

    //正式銷售Mint By WETH
    function SaleMintByWETH(uint256 _amount, uint256 _value) public {
        require(isSaleActive(3)); //正式銷售開賣檢查
        require(
            _value >= _SaleSetting.SalePrices[_amount] &&
                _SaleSetting.SalePrices[_amount] > 0,
            "Money is not enough"
        ); //傳入金額檢查
        require(
            (_amount + _SaleSetting.Minted) <= _SaleSetting.TotalSupply,
            "limit is exceed"
        ); //正式銷售銷量檢查
        require(
            ChubbyAPE.balanceOf(msg.sender) < SalePerLimit,
            "You cannot buy more"
        ); //個人購買上限檢查

        //轉出收到的錢(WETH)
        WETH.transferFrom(msg.sender, EthCollector, _value);
        //贈送Token
        BOMTToken.transferFrom(
            BOMTOwner,
            msg.sender,
            _SaleSetting.BonusToken * _amount
        );
        //Mint Token
        _SaleSetting.Minted = _SaleSetting.Minted + 1;
        _BatchMint(_amount, msg.sender);
    }

    ///#endregion WETH

    function _BatchMint(uint256 numTokens, address recipient) internal {
        IERC721ChubbyAPE(ChubbyAPE).mintTo(numTokens, recipient);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getMessageHash(
        address _to,
        uint8 _amount,
        uint256 _requestID
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _requestID));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg*/
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
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
library SafeMath {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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
}