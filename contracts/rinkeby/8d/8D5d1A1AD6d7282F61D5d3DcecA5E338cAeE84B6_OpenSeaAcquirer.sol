/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20
{
    function balanceOf(address _account) external view returns (uint256 _balance);
    function transfer(address recipient, uint256 _amount) external returns (bool _success);
    function approve(address _spender, uint256 _amount) external returns (bool _success);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool _success);
}

contract OpenSeaAcquirer
{
	struct Params {
		address[14] a;
		uint256[18] u;
		uint8[8] b;
		bytes db;
		bytes ds;
		bytes pb;
		bytes ps;
		bytes sb;
		bytes ss;
		uint8[2] v;
		bytes32[5] rsm;
	}

    // mainnet: 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
    // rinkeby: 0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9 / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
	address immutable public exchange;
	address immutable public feeRecipient;

    constructor (address _exchange, address _feeRecipient) public
    {
        exchange = _exchange;
        feeRecipient = _feeRecipient;
    }

    function encodeDetails(uint256 _makerRelayerFee, uint256 _basePrice, uint256 _extra, uint256 _listingTime, uint256 _expirationTime, uint256 _salt, uint8 _saleKind) external pure returns (bytes memory _details)
    {
        return abi.encode(_makerRelayerFee, _basePrice, _extra, _listingTime, _expirationTime, _salt, _saleKind);
    }

    function encodeSignature(uint8 _v, bytes32 _r, bytes32 _s) external pure returns (bytes memory _details)
    {
        return abi.encode(_v, _r, _s);
    }

    function acquire(address _seller,
        address _collection, uint256 _tokenId, uint256 _price, address _paymentToken,
        bytes calldata _details, bytes calldata _signature) external payable
    {
        address _buyer = address(this);
        
        Params memory _p;
        _p.a[0] = exchange;         // exchange
		_p.a[1] = _buyer;           // maker
		_p.a[2] = _seller;          // taker
		//_p.a[3] = address(0);     // feeRecipient
		_p.a[4] = _collection;      // target
		//_p.a[5] = address(0);     // staticTarget
    	_p.a[6] = _paymentToken;    // paymentToken

        _p.a[7] = exchange;         // exchange
		_p.a[8] = _seller;          // maker
    	//_p.a[9] = address(0);     // taker
		_p.a[10] = feeRecipient;    // feeRecipient
		_p.a[11] = _collection;     // target
		//_p.a[12] = address(0);    // staticTarget
		_p.a[13] = _paymentToken;   // paymentToken

        {
            (uint256 _makerRelayerFee, uint256 _basePrice, uint256 _extra, uint256 _listingTime, uint256 _expirationTime, uint256 _salt, uint8 _saleKind) = abi.decode(_details, (uint256, uint256, uint256, uint256, uint256, uint256, uint8));
    		_p.u[0] = _makerRelayerFee; // makerRelayerFee
    		//_p.u[1] = 0;              // takerRelayerFee
    		//_p.u[2] = 0;              // makerProtocolFee
    		//_p.u[3] = 0;              // takerProtocolFee
    		_p.u[4] = _price;           // price
    		//_p.u[5] = 0;              // extra
    		_p.u[6] = now - 1;          // listimtime
    		//_p.u[7] = 0;              // expirationTime
    		//_p.u[8] = 0;              // salt
    
    		_p.u[9] = _makerRelayerFee; // makerRelayerFee
    		_p.u[10] = 0;               // takerRelayerFee
    		_p.u[11] = 0;               // makerProtocolFee
    		_p.u[12] = 0;               // takerProtocolFee
        	_p.u[13] = _basePrice;      // basePrice
    		_p.u[14] = _extra;          // extra
        	_p.u[15] = _listingTime;    // listimtime
    		_p.u[16] = _expirationTime; // expirationTime
    		_p.u[17] = _salt;           // salt

            _p.b[0] = 1;                // feeMethod
            //_p.b[1] = 0;              // side
            //_p.b[2] = 0;              // saleKind
            //_p.b[3] = 0;              // howToCall
            
            _p.b[4] = 1;                // feeMethod
            _p.b[5] = 1;                // side
            _p.b[6] = _saleKind;        // saleKind
            //_p.b[7] = 0;              // howToCall
        }

        _p.db = abi.encodeWithSelector(0x23b872dd, address(0), _buyer, _tokenId);
        _p.ds = abi.encodeWithSelector(0x23b872dd, _seller, address(0), _tokenId);
        _p.pb = abi.encodeWithSelector(0x00000000, address(-1), address(0), 0);
        _p.ps = abi.encodeWithSelector(0x00000000, address(0), address(-1), 0);
        //_p.sb = new bytes(0);
        //_p.ss = new bytes(0);

        {
            (uint8 _v, bytes32 _r, bytes32 _s) = abi.decode(_signature, (uint8, bytes32, bytes32));
            //_p.v[0] = 0;
            //_p.rsm[0] = bytes32(0);
            //_p.rsm[1] = bytes32(0);

            _p.v[1] = _v;
            _p.rsm[2] = _r;
            _p.rsm[3] = _s;
        }

        //_p.rsm[4] = bytes32(0);   // metadata

        if (_paymentToken == address(0)) {
            _atomicMatch(_price, _p);
            msg.sender.transfer(address(this).balance);
        } else {
            require(IERC20(_paymentToken).transferFrom(msg.sender, address(this), _price));
            require(IERC20(_paymentToken).approve(exchange, _price));
            _atomicMatch(0, _p);
            require(IERC20(_paymentToken).approve(exchange, 0));
            require(IERC20(_paymentToken).transfer(msg.sender, IERC20(_paymentToken).balanceOf(address(this))));
        }
    }

	function _atomicMatch(uint256 _value, Params memory _p) internal
	{
	    emit DebugU(_value);
	    
	    emit DebugA(_p.a[0]);
	    emit DebugA(_p.a[1]);
	    emit DebugA(_p.a[2]);
	    emit DebugA(_p.a[3]);
	    emit DebugA(_p.a[4]);
	    emit DebugA(_p.a[5]);
	    emit DebugA(_p.a[6]);
	    emit DebugA(_p.a[7]);
	    emit DebugA(_p.a[8]);
	    emit DebugA(_p.a[9]);
	    emit DebugA(_p.a[10]);
	    emit DebugA(_p.a[11]);
	    emit DebugA(_p.a[12]);
	    emit DebugA(_p.a[13]);

	    emit DebugU(_p.u[0]);
	    emit DebugU(_p.u[1]);
	    emit DebugU(_p.u[2]);
	    emit DebugU(_p.u[3]);
	    emit DebugU(_p.u[4]);
	    emit DebugU(_p.u[5]);
	    emit DebugU(_p.u[6]);
	    emit DebugU(_p.u[7]);
	    emit DebugU(_p.u[8]);
	    emit DebugU(_p.u[9]);
	    emit DebugU(_p.u[10]);
	    emit DebugU(_p.u[11]);
	    emit DebugU(_p.u[12]);
	    emit DebugU(_p.u[13]);
	    emit DebugU(_p.u[14]);
	    emit DebugU(_p.u[15]);
	    emit DebugU(_p.u[16]);
	    emit DebugU(_p.u[17]);

	    emit DebugB(_p.b[0]);
	    emit DebugB(_p.b[1]);
	    emit DebugB(_p.b[2]);
	    emit DebugB(_p.b[3]);
	    emit DebugB(_p.b[4]);
	    emit DebugB(_p.b[5]);
	    emit DebugB(_p.b[6]);
	    emit DebugB(_p.b[7]);

	    emit DebugBS(_p.db, _p.db.length);
	    emit DebugBS(_p.ds, _p.ds.length);
	    emit DebugBS(_p.pb, _p.pb.length);
	    emit DebugBS(_p.ps, _p.ps.length);
	    emit DebugBS(_p.sb, _p.sb.length);
	    emit DebugBS(_p.ss, _p.ss.length);

	    emit DebugB(_p.v[0]);
	    emit DebugB(_p.v[1]);

        emit DebugB32(_p.rsm[0]);
        emit DebugB32(_p.rsm[1]);
        emit DebugB32(_p.rsm[2]);
        emit DebugB32(_p.rsm[3]);
        emit DebugB32(_p.rsm[4]);

		//bytes memory _data = abi.encodeWithSelector(0xab834bab, _p.a, _p.u, _p.b, _p.db, _p.ds, _p.pb, _p.ps, _p.sb, _p.ss, _p.v, _p.rsm);
		//(bool _success, bytes memory _returndata) = exchange.call{value: _value}(_data);
		//require(_success && _returndata.length == 0, "call failure");
	}
	
	event DebugA(address _a);
	event DebugU(uint256 _u);
	event DebugB(uint8 _b);
	event DebugBS(bytes _bs, uint256 _l);
	event DebugB32(bytes32 _b32);
}