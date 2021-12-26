/**
 *Submitted for verification at FtmScan.com on 2021-12-26
*/

//(C) Sam, coin1337 0-9999
//file://tvlGuru.sol
//ftm.guru : On-chain Total Value Locked Finder
//Version: 5
//Author: Sam4x, 543#3017, Guru Network
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;
//All tvlGuru Compliant contracts must implement the ITVL interface
interface ITVL{
	function tvl() external view returns(uint256);
}
interface LPT
{
	function getReserves() external view returns (uint112, uint112, uint32);
	function balanceOf(address) external view returns (uint256);
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function token0() external view returns (address);
	function token1() external view returns (address);
	function transfer(address, uint) external;
}
contract tvlGuru
{
	/*
	 -	Personal Functions must begin with an "_".
			example: "_bankOf_e_usd"
			exception: EXPORTs
	 -	Term after the last "_" represents units.
			example: "_tvl_e_usd"
	 -	Universal functions must not begin with an "_".
			example: "p_t_coin_usd"
	 -	"_bankOf..." refers to personal datastores.
	 		example: "... _bankOf_t_coin_usd"
	 -	Structures of banks are public.
	 		example: "struct t_coin_usd ..."
	 -	Elementary bank structures must have "asset", "pool" and "dec" keys.
	 		example: "{address asset; address pool; uint8 dec; ...}"
	 - 	Follows modularity and consistency of algorithm & nomenclature.
	 		example: "... _bankOf_t_coin_usd" v/s
	 -	Convention for Universal TVL Finder
			example: "function tvlOf_..."
	 -	Convention for Self.TVL Finder
			example: "function _tvlOf_..."
	 -	Convention for Self.TVL.total
			example: "function _tvl_..."
	*/
	constructor() {DAO=msg.sender;}
	address payable public DAO;
	modifier dao{require(msg.sender==DAO);_;}




	//Bank
	address[] public _bankOf_e_usd;
	//Edit: Push & Pull
	function _pushBankOf_e_usd(address asset) public dao
	{_bankOf_e_usd.push(asset);}
	function _pullBankOf_e_usd(uint n) public dao
	{
		_bankOf_e_usd[n]=_bankOf_e_usd[_bankOf_e_usd.length-1];
		_bankOf_e_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_e_usd(address q) public view returns(uint256)
	{
		uint256 tvl =  ITVL(q).tvl();
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_e_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_e_usd(_bankOf_e_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_e_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_e_usd.length;i++)
		{ tvl+= tvlOf_e_usd(_bankOf_e_usd[i]); }
		return tvl;
	}




	address public usd = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
	address public wcoin = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address public wcoinusd = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;
	uint8 public usd_d = 6;

	function setUW(address u, address w, address l) public dao{
		usd=u;
		wcoin=w;
		wcoinusd=l;
	}

	//Find USD worth of coin ; 1e18 === $1
	function coinusd() public view returns(uint256)
	{
		LPT lpt=LPT(wcoinusd);
		(uint256 a, uint256 b,) = lpt.getReserves();
		uint256 p = wcoin==lpt.token0()?
			(1e18* (b* 10**(18-usd_d)) ) /a :
			(1e18* (a* 10**(18-usd_d)) ) /b ;
		return(p);
	}

	//Calculator for Native coin locked
	address[] public  _bankOf_coin;
	function _pushBankOf_coin(address asset) public dao {_bankOf_coin.push(asset);}
	function _pullBankOf_coin(uint n) public dao
	{
		_bankOf_coin[n]=_bankOf_coin[_bankOf_coin.length-1];
		_bankOf_coin.pop();
	}
	//Universal TVL Finder
	function tvlOf_coin_usd(address q) public view returns(uint256)
	{
		return ((address(q).balance)*coinusd())/1e18;
	}
	//Self.TVL Finder
	function _tvlOf_coin_usd(uint256 n) public view returns(uint256)
	{
		return(tvlOf_coin_usd(_bankOf_coin[n]));
	}
	//Self.TVL.total
	function _tvl_coin_usd() public view returns(uint256)
	{
		uint256 tvl = 0;
		for(uint i;i<_bankOf_coin.length;i++)
		{ tvl+= tvlOf_coin_usd(_bankOf_coin[i]); }
		return(tvl);
	}


	//Simple pairs
	//Find USD worth of a simple token via USD pair
	function p_t_usd(address u, address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		//pf: price of token in coin; 1e18 === 1coin
		address _t = lpt.token1();
		uint256 p;
		if(u==_t)
		{
			uint8 u_d = LPT(_t).decimals();
			uint8 t_d = LPT(lpt.token0()).decimals();
			p = (1e18* (b* 10**(18-u_d)) ) / (a* 10**(18-t_d)) ;
		}
		else
		{
			uint8 u_d = LPT(lpt.token0()).decimals();
			uint8 t_d = LPT(_t).decimals();
			p = (1e18* (a* 10**(18-u_d)) ) / (b* 10**(18-t_d)) ;
		}
		return p;
	}
	//Blob
	struct t_usd {address asset; address pool; uint8 dec; address u; address lp;}
	//Bank
	t_usd[] public _bankOf_t_usd;
	//Edit: Push & Pull
	function _pushBankOf_t_usd(address asset, address pool, uint8 dec, address u, address lp) public dao
	{_bankOf_t_usd.push(t_usd({asset: asset, pool: pool, dec: dec, u:u, lp: lp}));}
	function _pullBankOf_t_usd(uint n) public dao
	{
		_bankOf_t_usd[n]=_bankOf_t_usd[_bankOf_t_usd.length-1];
		_bankOf_t_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_t_usd(t_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_usd(q.u, q.lp)
			) / 1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_t_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_t_usd(_bankOf_t_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_t_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_t_usd.length;i++)
		{ tvl+= tvlOf_t_usd(_bankOf_t_usd[i]); }
		return tvl;
	}



	//Find USD worth of a simple token via coin pair via coinusd()
	function p_t_coin_usd(address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		//pf: price of token in coin; 1e18 === 1coin
		uint256 pf;
		uint8 t_d;
		address _t = lpt.token1();
		if(wcoin==_t)
		{
			t_d = LPT(lpt.token0()).decimals();
			pf = (1e18*b) / (a * 10**(18-t_d)) ;
		}
		else
		{
			t_d = LPT(_t).decimals();
			pf = (1e18*a) / (b * 10**(18-t_d)) ;
		}
		uint256 p = (pf * coinusd()) /1e18;
		return p;
	}
	//Blob
	struct t_coin_usd {address asset; address pool; uint8 dec; address lp;}
	//Bank
	t_coin_usd[] public _bankOf_t_coin_usd;
	//Edit: Push & Pull
	function _pushBankOf_t_coin_usd(address asset, address pool, uint8 dec, address lp) public dao
	{_bankOf_t_coin_usd.push(t_coin_usd({asset: asset, pool: pool, dec: dec, lp: lp}));}
	function _pullBankOf_t_coin_usd(uint n) public dao
	{
		_bankOf_t_coin_usd[n]=_bankOf_t_coin_usd[_bankOf_t_coin_usd.length-1];
		_bankOf_t_coin_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_t_coin_usd(t_coin_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_coin_usd(q.lp)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_t_coin_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_t_coin_usd(_bankOf_t_coin_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_t_coin_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_t_coin_usd.length;i++)
		{ tvl+= tvlOf_t_coin_usd(_bankOf_t_coin_usd[i]); }
		return tvl;
	}



	//Token-Token pairs
	//Find USD worth of a simple token in Token-Token pairs via USD pair
	//bt: base token, qt: queried token
	//Assumes: Token qt does not have a direct USD or coin pair. Uses bt to calculate.
	function p_t_tt_usd(address qt, address lp_tt, address lp_bt_u, address u) public view returns(uint256)
	{
		LPT lpt=LPT(lp_tt);
		uint256 a;
		uint256 b;//base reserve
		uint8 qd;
		uint8 bd;
		address _t = lpt.token0();
		address bt;
		if(qt == _t)
		{
			bt = lpt.token1();
			(a,b,) = lpt.getReserves();
		}
		else
		{
			bt = _t;
			(b,a,) = lpt.getReserves();
		}
		qd = LPT(qt).decimals();
		bd = LPT(bt).decimals();
		uint256 p_bt = p_t_usd(u, lp_bt_u);
		uint256 p = (p_bt * (b*10**(18-bd))) /(a*10**(18-qd));
		return p;
	}
	//Blob
	struct t_tt_usd {address asset; address pool; uint8 dec; address lp_tt; address lp_bt_u; address u;}
	//Bank
	t_tt_usd[] public _bankOf_t_tt_usd;
	//Edit: Push & Pull
	function _pushBankOf_t_tt_usd(address asset, address pool, uint8 dec, address lp_tt, address lp_bt_u, address u) public dao
	{_bankOf_t_tt_usd.push(t_tt_usd({asset: asset, pool: pool, dec: dec, lp_tt: lp_tt, lp_bt_u:lp_bt_u, u:u}));}
	function _pullBankOf_t_tt_usd(uint n) public dao
	{
		_bankOf_t_tt_usd[n]=_bankOf_t_tt_usd[_bankOf_t_tt_usd.length-1];
		_bankOf_t_tt_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_t_tt_usd(t_tt_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_tt_usd(q.asset, q.lp_tt, q.lp_bt_u, q.u)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_t_tt_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_t_tt_usd(_bankOf_t_tt_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_t_tt_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_t_tt_usd.length;i++)
		{ tvl+= tvlOf_t_tt_usd(_bankOf_t_tt_usd[i]); }
		return tvl;
	}



	//Find USD worth of a simple token in Token-Token pairs via coin pair via coinusd()
	//Assumes: Token qt does not have a direct USD or coin pair. Uses bt to calculate.
	function p_t_tt_coin_usd(address qt, address lp_tt, address lp_bt_f) public view returns(uint256)
	{
		LPT lpt=LPT(lp_tt);
		uint256 a;
		uint256 b;//base reserve
		uint8 ad;
		uint8 bd;
		address _t = lpt.token0();
		address bt;
		if(qt == _t)
		{
			bt = lpt.token1();
			(a,b,) = lpt.getReserves();
		}
		else
		{
			bt = _t;
			(b,a,) = lpt.getReserves();
		}
		ad = LPT(qt).decimals();
		bd = LPT(bt).decimals();
		uint256 p_bt = p_t_coin_usd(lp_bt_f);
		uint256 p = ( ((p_bt * (b*10**(18-bd))) /(a*10**(18-bd))) * coinusd()) /1e18;
		return p;
	}
	//Blob
	struct t_tt_coin_usd {address asset; address pool; uint8 dec; address lp_tt; address lp_bt_f;}
	//Bank
	t_tt_coin_usd[] public _bankOf_t_tt_coin_usd;
	//Edit: Push & Pull
	function _pushBankOf_t_tt_coin_usd(address asset, address pool, uint8 dec, address lp_tt, address lp_bt_f) public dao
	{_bankOf_t_tt_coin_usd.push(t_tt_coin_usd({asset: asset, pool: pool, dec: dec, lp_tt: lp_tt, lp_bt_f:lp_bt_f}));}
	function _pullBankOf_t_tt_coin_usd(uint n) public dao
	{
		_bankOf_t_tt_coin_usd[n]=_bankOf_t_tt_coin_usd[_bankOf_t_tt_coin_usd.length-1];
		_bankOf_t_tt_coin_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_t_tt_coin_usd(t_tt_coin_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_tt_coin_usd(q.asset, q.lp_tt, q.lp_bt_f)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_t_tt_coin_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_t_tt_coin_usd(_bankOf_t_tt_coin_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_t_tt_coin_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_t_tt_coin_usd.length;i++)
		{ tvl+= tvlOf_t_tt_coin_usd(_bankOf_t_tt_coin_usd[i]); }
		return tvl;
	}




	//Find USD worth of a Liquidity token via USD pair
	function p_lpt_usd(address u, address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		uint256 ts = lpt.totalSupply();
		uint8 u_d = LPT(u).decimals();
		//p: price of token in USD; 1e18 === $1
		uint256 p = u==lpt.token0()?
			(2e18*(a* 10**(18-u_d) ))/ts :
			(2e18*(b* 10**(18-u_d) ))/ts ;
		return p;
	}
	//Blob
	struct lpt_usd {address asset; address pool; uint8 dec; address u; address lp;}
	//Bank
	lpt_usd[] public _bankOf_lpt_usd;
	//Edit: Push & Pull
	function _pushBankOf_lpt_usd(address asset, address pool, uint8 dec, address u, address lp) public dao
	{_bankOf_lpt_usd.push(lpt_usd({asset: asset, pool: pool, dec: dec, u: u, lp:lp}));}
	function _pullBankOf_lpt_usd(uint n) public dao
	{
		_bankOf_lpt_usd[n]=_bankOf_lpt_usd[_bankOf_lpt_usd.length-1];
		_bankOf_lpt_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_lpt_usd(lpt_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_usd(q.lp, q.lp)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_lpt_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_lpt_usd(_bankOf_lpt_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_lpt_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_lpt_usd.length;i++)
		{ tvl+= tvlOf_lpt_usd(_bankOf_lpt_usd[i]); }
		return tvl;
	}




	//Find USD worth of a Liquidity token via coin pair via coinusd()
	function p_lpt_coin_usd(address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		uint256 ts = lpt.totalSupply();
		//pf: price of token in coin; 1e18 === 1coin
		uint256 pf = wcoin==lpt.token0()?
			(2e18*a)/ts :
			(2e18*b)/ts ;
		uint256 p = (pf * coinusd()) /1e18;
		return p;
	}
	//Blob
	struct lpt_coin_usd {address asset; address pool; uint8 dec; address lp;}
	//Bank
	lpt_coin_usd[] public _bankOf_lpt_coin_usd;
	//Edit: Push & Pull
	function _pushBankOf_lpt_coin_usd(address asset, address pool, uint8 dec, address lp) public dao
	{_bankOf_lpt_coin_usd.push(lpt_coin_usd({asset: asset, pool: pool, dec: dec, lp:lp}));}
	function _pullBankOf_lpt_coin_usd(uint n) public dao
	{
		_bankOf_lpt_coin_usd[n]=_bankOf_lpt_coin_usd[_bankOf_lpt_coin_usd.length-1];
		_bankOf_lpt_coin_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_lpt_coin_usd(lpt_coin_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_coin_usd(q.lp)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_lpt_coin_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_lpt_coin_usd(_bankOf_lpt_coin_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_lpt_coin_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_lpt_coin_usd.length;i++)
		{ tvl+= tvlOf_lpt_coin_usd(_bankOf_lpt_coin_usd[i]); }
		return tvl;
	}




	//Token-Token pairs
	//Find USD worth of a Liquidity token of a token-token pool via USD pair
	//bt: token with known USD-pair lp_bt_u
	function p_lpt_tt_usd(address bt, address lp_tt, address lp_bt_u, address u) public view returns(uint256)
	{
		LPT lpt=LPT(lp_tt);
		address _t = lpt.token0();
		uint256 b;
		uint8 bd = LPT(bt).decimals();
		if(bt == _t){(b,,) = lpt.getReserves();}
		else{(,b,) = lpt.getReserves();}
		uint256 ts = lpt.totalSupply();
		//pu: price of token in USD; 1e18 === $1
		uint256 pu = p_t_usd(u,lp_bt_u);
		uint256 p = (2*pu * (b*10**(18-bd))) / ts;
		return p;
	}
	//Blob
	struct lpt_tt_usd {address asset; address pool; uint8 dec; address lp_tt; address lp_bt_u; address u;}
	//Bank
	lpt_tt_usd[] public _bankOf_lpt_tt_usd;
	//Edit: Push & Pull
	function _pushBankOf_lpt_tt_usd(address asset, address pool, uint8 dec, address lp_tt, address lp_bt_u, address u) public dao
	{_bankOf_lpt_tt_usd.push(lpt_tt_usd({asset: asset, pool: pool, dec: dec, lp_tt: lp_tt, lp_bt_u: lp_bt_u, u:u}));}
	function _pullBankOf_lpt_tt_usd(uint n) public dao
	{
		_bankOf_lpt_tt_usd[n]=_bankOf_lpt_tt_usd[_bankOf_lpt_tt_usd.length-1];
		_bankOf_lpt_tt_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_lpt_tt_usd(lpt_tt_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_tt_usd(q.asset, q.lp_tt, q.lp_bt_u, q.u)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_lpt_tt_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_lpt_tt_usd(_bankOf_lpt_tt_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_lpt_tt_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_lpt_tt_usd.length;i++)
		{ tvl+= tvlOf_lpt_tt_usd(_bankOf_lpt_tt_usd[i]); }
		return tvl;
	}




	//Find USD worth of a Liquidity token of a token-token pool via USD pair via coinusd()
	function p_lpt_tt_coin_usd(address bt, address lp_tt, address lp_bt_f) public view returns(uint256)
	{
		LPT lpt=LPT(lp_tt);
		address _t = lpt.token0();
		uint256 b;
		uint8 bd = LPT(bt).decimals();
		if(bt == _t){(b,,) = lpt.getReserves();}
		else{(,b,) = lpt.getReserves();}
		uint256 ts = lpt.totalSupply();
		//pf: price of token in coin; 1e18 === 1coin
		uint256 pfu = p_t_coin_usd(lp_bt_f);
		uint256 p = (2*pfu * (b*10**(18-bd))) / ts;
		return p;
	}
	//Blob
	struct lpt_tt_coin_usd {address asset; address pool; uint8 dec; address lp_tt; address lp_bt_f;}
	//Bank
	lpt_tt_coin_usd[] public _bankOf_lpt_tt_coin_usd;
	//Edit: Push & Pull
	function _pushBankOf_lpt_tt_coin_usd(address asset, address pool, uint8 dec, address lp_tt, address lp_bt_f) public dao
	{_bankOf_lpt_tt_coin_usd.push(lpt_tt_coin_usd({asset: asset, pool: pool, dec: dec, lp_tt: lp_tt, lp_bt_f: lp_bt_f}));}
	function _pullBankOf_lpt_tt_coin_usd(uint n) public dao
	{
		_bankOf_lpt_tt_coin_usd[n]=_bankOf_lpt_tt_coin_usd[_bankOf_lpt_tt_coin_usd.length-1];
		_bankOf_lpt_tt_coin_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_lpt_tt_coin_usd(lpt_tt_coin_usd memory q) public view returns(uint256)
	{
		uint256 tvl = (
			LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_tt_coin_usd(q.asset, q.lp_tt, q.lp_bt_f)
			) /1e18;
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_lpt_tt_coin_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_lpt_tt_coin_usd(_bankOf_lpt_tt_coin_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_lpt_tt_coin_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_lpt_tt_coin_usd.length;i++)
		{ tvl+= tvlOf_lpt_tt_coin_usd(_bankOf_lpt_tt_coin_usd[i]); }
		return tvl;
	}


	//WRAPPERS - Sub-TVL categories

	//POOL2
	//Blob
	//struct _bankOf_pool2_usd_ {
		//Cannot use nested arrays in solidity! Use plain variables.
		uint256[] _bankOf_pool2_usd_e_usd;
        uint256[] _bankOf_pool2_usd_coin_usd;
        uint256[] _bankOf_pool2_usd_t_usd;
        uint256[] _bankOf_pool2_usd_t_coin_usd;
        uint256[] _bankOf_pool2_usd_t_tt_usd;
        uint256[] _bankOf_pool2_usd_t_tt_coin_usd;
        uint256[] _bankOf_pool2_usd_lpt_usd;
        uint256[] _bankOf_pool2_usd_lpt_coin_usd;
		uint256[] _bankOf_pool2_usd_lpt_tt_usd;
		uint256[] _bankOf_pool2_usd_lpt_tt_coin_usd;
	//}
	//Bank
		//pool2_usd public _bankOf_pool2_usd;
	//Edit: Post Update
	function _puBankOf_pool2_usd(
		uint256[] memory _e_usd,
        uint256[] memory _coin_usd,
        uint256[] memory _t_usd,
        uint256[] memory _t_coin_usd,
        uint256[] memory _t_tt_usd,
        uint256[] memory _t_tt_coin_usd,
        uint256[] memory _lpt_usd,
        uint256[] memory _lpt_coin_usd,
		uint256[] memory _lpt_tt_usd,
		uint256[] memory _lpt_tt_coin_usd
	) public dao
	{
		_bankOf_pool2_usd_e_usd = _e_usd;
        _bankOf_pool2_usd_coin_usd = _coin_usd;
        _bankOf_pool2_usd_t_usd = _t_usd;
        _bankOf_pool2_usd_t_coin_usd = _t_coin_usd;
        _bankOf_pool2_usd_t_tt_usd = _t_tt_usd;
        _bankOf_pool2_usd_t_tt_coin_usd = _t_tt_coin_usd;
        _bankOf_pool2_usd_lpt_usd = _lpt_usd;
        _bankOf_pool2_usd_lpt_coin_usd = _lpt_coin_usd;
		_bankOf_pool2_usd_lpt_tt_usd = _lpt_tt_usd;
		_bankOf_pool2_usd_lpt_tt_coin_usd = _lpt_tt_coin_usd;
	}
	//Universal TVL Finder
		//Use Elementary "function public view tvlOf_...(...) returns(uint256){...}"
	//Self.TVL Finder
	function _tvlOf_pool2_usd() public view returns(uint256){return _tvl_pool2_usd();}
	//Self.TVL.total
	function _tvl_pool2_usd() public view returns(uint256)
	{
		uint256 tvl;


		for(uint i;i<_bankOf_pool2_usd_e_usd.length;i++)
		{ tvl+= _tvlOf_e_usd(_bankOf_pool2_usd_e_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_coin_usd.length;i++)
		{ tvl+= _tvlOf_coin_usd(_bankOf_pool2_usd_coin_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_t_usd.length;i++)
		{ tvl+= _tvlOf_t_usd(_bankOf_pool2_usd_t_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_t_coin_usd.length;i++)
		{ tvl+= _tvlOf_t_coin_usd(_bankOf_pool2_usd_t_coin_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_t_tt_usd.length;i++)
		{ tvl+= _tvlOf_t_tt_usd(_bankOf_pool2_usd_t_tt_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_t_tt_coin_usd.length;i++)
		{ tvl+= _tvlOf_t_tt_coin_usd(_bankOf_pool2_usd_t_tt_coin_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_lpt_usd.length;i++)
		{ tvl+= _tvlOf_lpt_usd(_bankOf_pool2_usd_lpt_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_lpt_coin_usd.length;i++)
		{ tvl+= _tvlOf_lpt_coin_usd(_bankOf_pool2_usd_lpt_coin_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_lpt_tt_usd.length;i++)
		{ tvl+= _tvlOf_lpt_tt_usd(_bankOf_pool2_usd_lpt_tt_usd[i]); }

		for(uint i;i<_bankOf_pool2_usd_lpt_tt_coin_usd.length;i++)
		{ tvl+= _tvlOf_lpt_tt_coin_usd(_bankOf_pool2_usd_lpt_tt_coin_usd[i]); }


		return tvl;
	}



	//STAKING
	//Blob
	//struct _bankOf_staking_usd_ {
		//Cannot use nested arrays in solidity! Use plain variables.
		uint256[] _bankOf_staking_usd_e_usd;
        uint256[] _bankOf_staking_usd_coin_usd;
        uint256[] _bankOf_staking_usd_t_usd;
        uint256[] _bankOf_staking_usd_t_coin_usd;
        uint256[] _bankOf_staking_usd_t_tt_usd;
        uint256[] _bankOf_staking_usd_t_tt_coin_usd;
        uint256[] _bankOf_staking_usd_lpt_usd;
        uint256[] _bankOf_staking_usd_lpt_coin_usd;
		uint256[] _bankOf_staking_usd_lpt_tt_usd;
		uint256[] _bankOf_staking_usd_lpt_tt_coin_usd;
	//}
	//Bank
		//staking_usd public _bankOf_staking_usd;
	//Edit: Post Update
	function _puBankOf_staking_usd(
		uint256[] memory _e_usd,
        uint256[] memory _coin_usd,
        uint256[] memory _t_usd,
        uint256[] memory _t_coin_usd,
        uint256[] memory _t_tt_usd,
        uint256[] memory _t_tt_coin_usd,
        uint256[] memory _lpt_usd,
        uint256[] memory _lpt_coin_usd,
		uint256[] memory _lpt_tt_usd,
		uint256[] memory _lpt_tt_coin_usd
	) public dao
	{
		_bankOf_staking_usd_e_usd = _e_usd;
        _bankOf_staking_usd_coin_usd = _coin_usd;
        _bankOf_staking_usd_t_usd = _t_usd;
        _bankOf_staking_usd_t_coin_usd = _t_coin_usd;
        _bankOf_staking_usd_t_tt_usd = _t_tt_usd;
        _bankOf_staking_usd_t_tt_coin_usd = _t_tt_coin_usd;
        _bankOf_staking_usd_lpt_usd = _lpt_usd;
        _bankOf_staking_usd_lpt_coin_usd = _lpt_coin_usd;
		_bankOf_staking_usd_lpt_tt_usd = _lpt_tt_usd;
		_bankOf_staking_usd_lpt_tt_coin_usd = _lpt_tt_coin_usd;
	}
	//Universal TVL Finder
		//Use Elementary "function public view tvlOf_...(...) returns(uint256){...}"
	//Self.TVL Finder
	function _tvlOf_staking_usd() public view returns(uint256){return _tvl_staking_usd();}
	//Self.TVL.total
	function _tvl_staking_usd() public view returns(uint256)
	{
		uint256 tvl;


		for(uint i;i<_bankOf_staking_usd_e_usd.length;i++)
		{ tvl+= _tvlOf_e_usd(_bankOf_staking_usd_e_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_coin_usd.length;i++)
		{ tvl+= _tvlOf_coin_usd(_bankOf_staking_usd_coin_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_t_usd.length;i++)
		{ tvl+= _tvlOf_t_usd(_bankOf_staking_usd_t_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_t_coin_usd.length;i++)
		{ tvl+= _tvlOf_t_coin_usd(_bankOf_staking_usd_t_coin_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_t_tt_usd.length;i++)
		{ tvl+= _tvlOf_t_tt_usd(_bankOf_staking_usd_t_tt_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_t_tt_coin_usd.length;i++)
		{ tvl+= _tvlOf_t_tt_coin_usd(_bankOf_staking_usd_t_tt_coin_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_lpt_usd.length;i++)
		{ tvl+= _tvlOf_lpt_usd(_bankOf_staking_usd_lpt_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_lpt_coin_usd.length;i++)
		{ tvl+= _tvlOf_lpt_coin_usd(_bankOf_staking_usd_lpt_coin_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_lpt_tt_usd.length;i++)
		{ tvl+= _tvlOf_lpt_tt_usd(_bankOf_staking_usd_lpt_tt_usd[i]); }

		for(uint i;i<_bankOf_staking_usd_lpt_tt_coin_usd.length;i++)
		{ tvl+= _tvlOf_lpt_tt_coin_usd(_bankOf_staking_usd_lpt_tt_coin_usd[i]); }


		return tvl;
	}

	//EXPORTS
	//Self.TVL.pool2
	function pool2() public view returns(uint256){return _tvl_pool2_usd();}
	//Self.TVL.staking
	function staking() public view returns(uint256){return _tvl_staking_usd();}
	//Self.TVL.global
	function tvl() public view returns(uint256)
	{
		return(0
            + _tvl_e_usd()
            + _tvl_coin_usd()
            + _tvl_t_usd()
            + _tvl_t_coin_usd()
            + _tvl_t_tt_usd()
            + _tvl_t_tt_coin_usd()
            + _tvl_lpt_usd()
            + _tvl_lpt_coin_usd()
			+ _tvl_lpt_tt_usd()
			+ _tvl_lpt_tt_coin_usd()
        );
	}

    //For Donations
	/*
     * We would be immensely pleased if you use this code to calculate on-chain TVL
        in your Decentralized Finance and Smart Contract Blockchain projects.
        If you have any suggestions or feedback, do create a pull request or write
        to us directly at any of our public Community channels.

        Cheers,
        Sam [x4mas | sam4x]
        Architect, Guru Network

	 * Community Mediums:
		https://discord.com/invite/QpyfMarNrV
		https://twitter.com/kucino
		https://t.me/kccguru

	 * Other Products:
		KUCINO CASINO - The First and Most used Casino of KCC
		ELITE - ftm.guru is an indie growth-hacker for Fantom, providing numerous tools for
		Opera users, institutions & developers alike.

     * Please keep this notice intact if you fork, reuse or derive codes from this contract.

	 */
	function rescue(address tokenAddress, uint256 tokens) public dao
	{
		if(tokenAddress==address(0)) {DAO.call{value:tokens}("");}
		else if(tokenAddress!=address(0)) { LPT(tokenAddress).transfer(DAO, tokens);}
	}
	function reset() public dao{selfdestruct(DAO);}
}