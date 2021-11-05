/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.4.23;

interface IERC20
{
    function balanceOf(address _account) external view returns (uint256 _balance);
    function transfer(address recipient, uint256 _amount) external returns (bool _success);
    function approve(address _spender, uint256 _amount) external returns (bool _success);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool _success);
}

contract Exchange
{
    function atomicMatch_(
        address[14] addrs,
        uint[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell,
        uint8[2] vs,
        bytes32[5] rssMetadata)
        public
        payable
    {
        emit Debug(calldataBuy);
        emit Debug(calldataSell);
        emit Debug(replacementPatternBuy);
        emit Debug(replacementPatternSell);
        emit Debug(staticExtradataBuy);
        emit Debug(staticExtradataSell);

        emit Debug(abi.encodeWithSelector(0x23b872dd, address(0), addrs[1], 10));
        emit Debug(abi.encodeWithSelector(0x23b872dd, addrs[2], address(0), 10));
        emit Debug(abi.encodeWithSelector(0x00000000, address(-1), address(0), 0));
        emit Debug(abi.encodeWithSelector(0x00000000, address(0), address(-1), 0));
        emit Debug(new bytes(0));
        emit Debug(new bytes(0));
    }

    event Debug(bytes _data);
}

interface IExchange
{
    function atomicMatch_(
        address[14] addrs,
        uint[26] uints,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell,
        uint256[7] rssMetadata) external payable;
}

contract OpenSeaAcquirer
{
	struct Params {
		address[14] a;
		uint256[26] u;
		bytes db;
		bytes ds;
		bytes pb;
		bytes ps;
		bytes sb;
		bytes ss;
		uint256[7] rsm;
	}

    // mainnet: 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
    // rinkeby: 0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9 / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
	address public exchange;
	address public feeRecipient;

    constructor (address _exchange, address _feeRecipient) public
    {
        exchange = _exchange;
        feeRecipient = _feeRecipient;
    }

    function acquire(address _seller,
        address _collection, uint256 _tokenId, uint256 _price, address _paymentToken,
        uint256 _makerRelayerFee, uint256 _basePrice, uint256 _extra, uint256 _listingTime, uint256 _expirationTime, uint256 _salt, //uint8 _saleKind,
        uint8 _v, bytes32 _r, bytes32 _s) external payable
    {
        Params memory _p;
        
        _p.a[0] = exchange;         // exchange
    	_p.a[1] = address(this);    // maker
		_p.a[2] = _seller;          // taker
		_p.a[3] = address(0);       // feeRecipient
		_p.a[4] = _collection;      // target
		_p.a[5] = address(0);       // staticTarget
    	_p.a[6] = _paymentToken;    // paymentToken

        _p.a[7] = exchange;         // exchange
		_p.a[8] = _seller;          // maker
    	_p.a[9] = address(0);       // taker
		_p.a[10] = feeRecipient;    // feeRecipient
		_p.a[11] = _collection;     // target
		_p.a[12] = address(0);      // staticTarget
		_p.a[13] = _paymentToken;   // paymentToken

		_p.u[0] = _makerRelayerFee; // makerRelayerFee
		_p.u[1] = 0;                // takerRelayerFee
		_p.u[2] = 0;                // makerProtocolFee
		_p.u[3] = 0;                // takerProtocolFee
		_p.u[4] = _price;           // price
		_p.u[5] = 0;                // extra
		_p.u[6] = now - 1;          // listimtime
		_p.u[7] = 0;                // expirationTime
		_p.u[8] = 0;                // salt

		_p.u[9] = _makerRelayerFee; // makerRelayerFee
		_p.u[10] = 0;               // takerRelayerFee
		_p.u[11] = 0;               // makerProtocolFee
		_p.u[12] = 0;               // takerProtocolFee
    	_p.u[13] = _basePrice;      // basePrice
		_p.u[14] = _extra;          // extra
    	_p.u[15] = _listingTime;    // listimtime
		_p.u[16] = _expirationTime; // expirationTime
		_p.u[17] = _salt;           // salt

        _p.u[18] = 1;               // feeMethod
        _p.u[19] = 0;               // side
        _p.u[20] = 0;               // saleKind
        _p.u[21] = 0;               // howToCall
            
        _p.u[22] = 1;               // feeMethod
        _p.u[23] = 1;               // side
        //_p.u[24] = _saleKind;     // saleKind
        _p.u[25] = 0;               // howToCall

        _p.db = abi.encodeWithSelector(0x23b872dd, address(0), address(this), _tokenId);
        _p.ds = abi.encodeWithSelector(0x23b872dd, _seller, address(0), _tokenId);
        _p.pb = abi.encodeWithSelector(0x00000000, address(-1), address(0), 0);
        _p.ps = abi.encodeWithSelector(0x00000000, address(0), address(-1), 0);
        _p.sb = new bytes(0);
        _p.ss = new bytes(0);

        _p.rsm[0] = uint256(0);
        _p.rsm[2] = uint256(0);
        _p.rsm[3] = uint256(0);

        _p.rsm[1] = uint256(_v);
        _p.rsm[4] = uint256(_r);
        _p.rsm[5] = uint256(_s);

        _p.rsm[6] = uint256(0);     // metadata

        if (_paymentToken == address(0)) {
            require(msg.value == _price);
            IExchange(exchange).atomicMatch_.value(_price)(_p.a, _p.u, _p.db, _p.ds, _p.pb, _p.ps, _p.sb, _p.ss, _p.rsm);
            msg.sender.transfer(address(this).balance);
        } else {
            require(msg.value == 0);
            require(IERC20(_paymentToken).transferFrom(msg.sender, address(this), _price));
            require(IERC20(_paymentToken).approve(exchange, _price));
            IExchange(exchange).atomicMatch_(_p.a, _p.u, _p.db, _p.ds, _p.pb, _p.ps, _p.sb, _p.ss, _p.rsm);
            require(IERC20(_paymentToken).approve(exchange, 0));
            require(IERC20(_paymentToken).transfer(msg.sender, IERC20(_paymentToken).balanceOf(address(this))));
        }
    }
}