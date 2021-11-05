/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

interface IERC20
{
    function balanceOf(address _account) external view returns (uint256 _balance);
    function transfer(address recipient, uint256 _amount) external returns (bool _success);
    function approve(address _spender, uint256 _amount) external returns (bool _success);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool _success);
}

contract OpenSeaAcquirer
{
    // mainnet: 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
    // rinkeby: 0x5206e78b21Ce315ce284FB24cf05e0585A93B1d9 / 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073
	address immutable public exchange;
	address immutable public feeRecipient;

    uint256[75] private p_;

    constructor (address _exchange, address _feeRecipient) public
    {
        exchange = _exchange;
        feeRecipient = _feeRecipient;
    }

    function acquire(address _seller,
        address _collection, uint256 _tokenId, uint256 _price, address _paymentToken,
        uint256 _basePrice, uint256 _extra, uint256 _makerRelayerFee, uint8 _saleKind,
        uint256 _listingTime, uint256 _expirationTime, uint256 _salt,
        uint8 _v, bytes32 _r, bytes32 _s) external payable
    {
        p_[0] = uint256(exchange);          // exchange
	    p_[1] = uint256(address(this));     // maker
		//p_[2] = 0;                        // taker
		//p_[3] = address(0);               // feeRecipient
		p_[4] = uint256(_collection);       // target
		//p_[5] = address(0);               // staticTarget
    	p_[6] = uint256(_paymentToken);     // paymentToken

        p_[7] = uint256(exchange);          // exchange
		p_[8] = uint256(_seller);           // maker
    	//p_[9] = address(0);               // taker
		p_[10] = uint256(feeRecipient);     // feeRecipient
		p_[11] = uint256(_collection);      // target
		//p_[12] = address(0);              // staticTarget
		p_[13] = uint256(_paymentToken);    // paymentToken

		p_[14] = _makerRelayerFee;          // makerRelayerFee
		//p_[15] = 0;                       // takerRelayerFee
		//p_[16] = 0;                       // makerProtocolFee
		//p_[17] = 0;                       // takerProtocolFee
		p_[18] = _price;                    // price
		//p_[19] = 0;                       // extra
    	p_[20] = now - 1;                   // listimtime
		//p_[21] = 0;                       // expirationTime
		//p_[22] = 0;                       // salt

		p_[23] = _makerRelayerFee;          // makerRelayerFee
		//p_[24] = 0;                       // takerRelayerFee
		//p_[25] = 0;                       // makerProtocolFee
		//p_[26] = 0;                       // takerProtocolFee
    	p_[27] = _basePrice;                // basePrice
		p_[28] = _extra;                    // extra
    	p_[29] = _listingTime;              // listimtime
		p_[30] = _expirationTime;           // expirationTime
		p_[31] = _salt;                     // salt

        p_[32] = 1;                         // feeMethod
        //p_[33] = 0;                       // side
        //p_[34] = 0;                       // saleKind
        //p_[35] = 0;                       // howToCall

        p_[36] = 1;                         // feeMethod
        p_[37] = 1;                         // side
        p_[38] = _saleKind;                 // saleKind
        //p_[39] = 0;                       // howToCall

        /*
        p_.db = abi.encodeWithSelector(0x23b872dd, address(0), address(this), _tokenId);
        p_.ds = abi.encodeWithSelector(0x23b872dd, _seller, address(0), _tokenId);
        p_.pb = abi.encodeWithSelector(0x00000000, address(-1), address(0), 0);
        p_.ps = abi.encodeWithSelector(0x00000000, address(0), address(-1), 0);
        p_.sb = new bytes(0);
        p_.ss = new bytes(0);
        */

        //p_[46] = 0;                       // v
        p_[47] = _v;                        // v

        //p_[48] = bytes32(0);              // r
        //p_[49] = bytes32(0);              // s

        p_[50] = uint256(_r);               // r
        p_[51] = uint256(_s);               // s

        //p_[52] = bytes32(0);              // metadata

        p_[53] = 100;                       // db.length
        p_[54] = (0x23b872dd << 224);
        p_[55] = (uint256(address(this)) >> 32);
        p_[56] = (uint256(address(this)) << 224) | (_tokenId >> 32);
        p_[57] = (_tokenId << 224);

        p_[58] = 100;                       // ds.length
        p_[59] = (0x23b872dd << 224) | (uint256(_seller) >> 32);
        p_[60] = (uint256(_seller) << 224);
        p_[61] = (_tokenId >> 32);
        p_[62] = (_tokenId << 224);

        p_[63] = 100;                       // pb.length
        p_[64] = (uint256(-1) >> 32);
        p_[65] = (uint256(-1) << 224);
        //p_[66] = 0;
        //p_[67] = 0;

        p_[68] = 100;                       // ps.length
        //p_[69] = 0;
        p_[70] = (uint256(-1) >> 32);
        p_[71] = (uint256(-1) << 224);
        //p_[72] = 0;

        //p_[73] = 0;                       // sb.length

        //p_[74] = 0;                       // ss.length

        if (_paymentToken == address(0)) {
            require(msg.value == _price);
            _atomicMatch(_price);
            msg.sender.transfer(address(this).balance);
        } else {
            require(msg.value == 0);
            require(IERC20(_paymentToken).transferFrom(msg.sender, address(this), _price));
            require(IERC20(_paymentToken).approve(exchange, _price));
            _atomicMatch(0);
            require(IERC20(_paymentToken).approve(exchange, 0));
            require(IERC20(_paymentToken).transfer(msg.sender, IERC20(_paymentToken).balanceOf(address(this))));
        }
    }
    
    function _atomicMatch(uint256 _value) internal
    {
        bytes memory _data = abi.encodeWithSelector(0xab834bab, p_);
        (bool _success, bytes memory _returndata) = exchange.call{value: _value}(_data);
        require(_success && _returndata.length == 0, "call failure");
    }
}