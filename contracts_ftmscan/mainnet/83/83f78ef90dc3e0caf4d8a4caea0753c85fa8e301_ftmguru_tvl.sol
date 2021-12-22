/**
 *Submitted for verification at FtmScan.com on 2021-12-22
*/

//(C) Sam, ftm1337 0-9999
//ftm.guru : Total Value Locked
//Author: Sam4x, 543#3017, Guru Network
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;
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
contract ftmguru_tvl
{

	constructor() {DAO=msg.sender;}
	address public DAO;
	modifier dao{require(msg.sender==DAO);_;}

	address public usd = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
	address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address public wftmusd = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;
	uint8 public usd_d = 6;

	//Find USD worth of FTM ; 1e18 === $1
	function ftmusd() public view returns(uint256)
	{
		LPT lpt=LPT(wftmusd);
		(uint256 a, uint256 b,) = lpt.getReserves();
		uint256 p = wftm==lpt.token0()?
			(1e18* (b* 10**(18-usd_d)) ) /a :
			(1e18* (a* 10**(18-usd_d)) ) /b ;
		return(p);
	}

	//Calculator for Native FTM locked
	address[] public  _bankOf_ftm;
	function _pushBankOf_ftm(address asset) public dao {_bankOf_ftm.push(asset);}
	function _pullBankOf_ftm(uint n) public dao
	{
		_bankOf_ftm[n]=_bankOf_ftm[_bankOf_ftm.length-1];
		_bankOf_ftm.pop();
	}
	//Universal TVL Finder
	function tvlOf_ftm(address q) public view returns(uint256)
	{
		return((address(q).balance)*ftmusd());
	}
	//Self.TVL Finder
	function _tvlOf_ftm(uint256 n) public view returns(uint256)
	{
		return(tvlOf_ftm(_bankOf_ftm[n]));
	}
	//Self.TVL.total
	function _tvl_ftm() public view returns(uint256)
	{
		uint256 tvl = 0;
		for(uint i;i<_bankOf_ftm.length;i++)
		{ tvl+= tvlOf_ftm(_bankOf_ftm[i]); }
		return(tvl);
	}


	//Simple pairs
	//Find USD worth of a simple token via USD pair
	function p_t_usd(address u, address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		//pf: price of token in FTM; 1e18 === 1FTM
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
	//Edit: Push
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
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_usd(q.u, q.lp);
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



	//Find USD worth of a simple token via FTM pair via ftmusd()
	function p_t_ftm_usd(address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		//pf: price of token in FTM; 1e18 === 1FTM
		uint256 pf;
		uint8 t_d;
		address _t = lpt.token1();
		if(wftm==_t)
		{
			t_d = LPT(lpt.token0()).decimals();
			pf = (1e18*b) / (a * 10**(18-t_d)) ;
		}
		else
		{
			t_d = LPT(_t).decimals();
			pf = (1e18*a) / (b * 10**(18-t_d)) ;
		}
		uint256 p = (pf * ftmusd()) /1e18;
		return p;
	}
	//Blob
	struct t_ftm_usd {address asset; address pool; uint8 dec; address lp;}
	//Bank
	t_ftm_usd[] public _bankOf_t_ftm_usd;
	//Edit: Push
	function _pushBankOf_t_ftm_usd(address asset, address pool, uint8 dec, address lp) public dao
	{_bankOf_t_ftm_usd.push(t_ftm_usd({asset: asset, pool: pool, dec: dec, lp: lp}));}
	function _pullBankOf_t_ftm_usd(uint n) public dao
	{
		_bankOf_t_ftm_usd[n]=_bankOf_t_ftm_usd[_bankOf_t_ftm_usd.length-1];
		_bankOf_t_ftm_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_t_ftm_usd(t_ftm_usd memory q) public view returns(uint256)
	{
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_ftm_usd(q.lp);
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_t_ftm_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_t_ftm_usd(_bankOf_t_ftm_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_t_ftm_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_t_ftm_usd.length;i++)
		{ tvl+= tvlOf_t_ftm_usd(_bankOf_t_ftm_usd[i]); }
		return tvl;
	}



	//Token-Token pairs
	//Find USD worth of a simple token in Token-Token pairs via USD pair
	//bt: base token, qt: queried token
	//Assumes: Token qt does not have a direct USD or FTM pair. Uses bt to calculate.
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
	//Edit: Push
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
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_tt_usd(q.asset, q.lp_tt, q.lp_bt_u, q.u);
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



	//Find USD worth of a simple token in Token-Token pairs via FTM pair via ftmusd()
	//Assumes: Token qt does not have a direct USD or FTM pair. Uses bt to calculate.
	function p_t_tt_ftm_usd(address qt, address lp_tt, address lp_bt_f) public view returns(uint256)
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
		uint256 p_bt = p_t_ftm_usd(lp_bt_f);
		uint256 p = ( ((p_bt * (b*10**(18-bd))) /(a*10**(18-bd))) * ftmusd()) /1e18;
		return p;
	}
	//Blob
	struct t_tt_ftm_usd {address asset; address pool; uint8 dec; address lp_tt; address lp_bt_f;}
	//Bank
	t_tt_ftm_usd[] public _bankOf_t_tt_ftm_usd;
	//Edit: Push
	function _pushBankOf_t_tt_ftm_usd(address asset, address pool, uint8 dec, address lp_tt, address lp_bt_f) public dao
	{_bankOf_t_tt_ftm_usd.push(t_tt_ftm_usd({asset: asset, pool: pool, dec: dec, lp_tt: lp_tt, lp_bt_f:lp_bt_f}));}
	function _pullBankOf_t_tt_ftm_usd(uint n) public dao
	{
		_bankOf_t_tt_ftm_usd[n]=_bankOf_t_tt_ftm_usd[_bankOf_t_tt_ftm_usd.length-1];
		_bankOf_t_tt_ftm_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_t_tt_ftm_usd(t_tt_ftm_usd memory q) public view returns(uint256)
	{
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_t_tt_ftm_usd(q.asset, q.lp_tt, q.lp_bt_f);
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_t_tt_ftm_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_t_tt_ftm_usd(_bankOf_t_tt_ftm_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_t_tt_ftm_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_t_tt_ftm_usd.length;i++)
		{ tvl+= tvlOf_t_tt_ftm_usd(_bankOf_t_tt_ftm_usd[i]); }
		return tvl;
	}




	//Find USD worth of a Liquidity token via USD pair
	function p_lpt_usd(address u, address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		uint256 ts = lpt.totalSupply();
		uint8 u_d = LPT(u).decimals();
		//pf: price of token in FTM; 1e18 === 1FTM
		uint256 p = u==lpt.token0()?
			(2e18*(a* 10**(18-u_d) ))/ts :
			(2e18*(b* 10**(18-u_d) ))/ts ;
		return p;
	}
	//Blob
	struct lpt_usd {address asset; address pool; uint8 dec; address u; address lp;}
	//Bank
	lpt_usd[] public _bankOf_lpt_usd;
	//Edit: Push
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
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_usd(q.lp, q.lp);
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




	//Find USD worth of a Liquidity token via FTM pair via ftmusd()
	function p_lpt_ftm_usd(address lp) public view returns(uint256)
	{
		LPT lpt=LPT(lp);
		(uint256 a, uint256 b,) = lpt.getReserves();
		uint256 ts = lpt.totalSupply();
		//pf: price of token in FTM; 1e18 === 1FTM
		uint256 pf = wftm==lpt.token0()?
			(2e18*a)/ts :
			(2e18*b)/ts ;
		uint256 p = (pf * ftmusd()) /1e18;
		return p;
	}
	//Blob
	struct lpt_ftm_usd {address asset; address pool; uint8 dec; address lp;}
	//Bank
	lpt_ftm_usd[] public _bankOf_lpt_ftm_usd;
	//Edit: Push
	function _pushBankOf_lpt_ftm_usd(address asset, address pool, uint8 dec, address lp) public dao
	{_bankOf_lpt_ftm_usd.push(lpt_ftm_usd({asset: asset, pool: pool, dec: dec, lp:lp}));}
	function _pullBankOf_lpt_ftm_usd(uint n) public dao
	{
		_bankOf_lpt_ftm_usd[n]=_bankOf_lpt_ftm_usd[_bankOf_lpt_ftm_usd.length-1];
		_bankOf_lpt_ftm_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_lpt_ftm_usd(lpt_ftm_usd memory q) public view returns(uint256)
	{
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_ftm_usd(q.lp);
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_lpt_ftm_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_lpt_ftm_usd(_bankOf_lpt_ftm_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_lpt_ftm_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_lpt_ftm_usd.length;i++)
		{ tvl+= tvlOf_lpt_ftm_usd(_bankOf_lpt_ftm_usd[i]); }
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
	//Edit: Push
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
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_tt_usd(q.asset, q.lp_tt, q.lp_bt_u, q.u);
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




	//Find USD worth of a Liquidity token of a token-token pool via USD pair via ftmusd()
	function p_lpt_tt_ftm_usd(address bt, address lp_tt, address lp_bt_f) public view returns(uint256)
	{
		LPT lpt=LPT(lp_tt);
		address _t = lpt.token0();
		uint256 b;
		uint8 bd = LPT(bt).decimals();
		if(bt == _t){(b,,) = lpt.getReserves();}
		else{(,b,) = lpt.getReserves();}
		uint256 ts = lpt.totalSupply();
		//pf: price of token in FTM; 1e18 === 1FTM
		uint256 pfu = p_t_ftm_usd(lp_bt_f);
		uint256 p = (2*pfu * (b*10**(18-bd))) / ts;
		return p;
	}
	//Blob
	struct lpt_tt_ftm_usd {address asset; address pool; uint8 dec; address lp_tt; address lp_bt_f;}
	//Bank
	lpt_tt_ftm_usd[] public _bankOf_lpt_tt_ftm_usd;
	//Edit: Push
	function _pushBankOf_lpt_tt_ftm_usd(address asset, address pool, uint8 dec, address lp_tt, address lp_bt_f) public dao
	{_bankOf_lpt_tt_ftm_usd.push(lpt_tt_ftm_usd({asset: asset, pool: pool, dec: dec, lp_tt: lp_tt, lp_bt_f: lp_bt_f}));}
	function _pullBankOf_lpt_tt_ftm_usd(uint n) public dao
	{
		_bankOf_lpt_tt_ftm_usd[n]=_bankOf_lpt_tt_ftm_usd[_bankOf_lpt_tt_ftm_usd.length-1];
		_bankOf_lpt_tt_ftm_usd.pop();
	}
	//Universal TVL Finder
	function tvlOf_lpt_tt_ftm_usd(lpt_tt_ftm_usd memory q) public view returns(uint256)
	{
		uint256 tvl = LPT(q.asset).balanceOf(q.pool) * 10**(18-q.dec)
			* p_lpt_tt_ftm_usd(q.asset, q.lp_tt, q.lp_bt_f);
		return tvl;
	}
	//Self.TVL Finder
	function _tvlOf_lpt_tt_ftm_usd(uint256 n) public view returns(uint256)
	{
		uint256 tvl = tvlOf_lpt_tt_ftm_usd(_bankOf_lpt_tt_ftm_usd[n]);
		return tvl;
	}
	//Self.TVL.total
	function _tvl_lpt_tt_ftm_usd() public view returns(uint256)
	{
		uint256 tvl;
		for(uint i;i<_bankOf_lpt_tt_ftm_usd.length;i++)
		{ tvl+= tvlOf_lpt_tt_ftm_usd(_bankOf_lpt_tt_ftm_usd[i]); }
		return tvl;
	}




	//Self.TVL.global
	function TVL() public view returns(uint256)
	{
		return(0
            + _tvl_ftm()
            + _tvl_t_usd()
            + _tvl_t_ftm_usd()
            + _tvl_t_tt_usd()
            + _tvl_t_tt_ftm_usd()
            + _tvl_lpt_usd()
            + _tvl_lpt_ftm_usd()
			+ _tvl_lpt_tt_usd()
			+ _tvl_lpt_tt_ftm_usd()
        );
	}


	//For Donations
	function rescue(address tokenAddress, uint256 tokens) public dao
	{
		if(tokenAddress==address(0)) { (bool x,) = DAO.call{value:tokens}("");require(x);}
		else if(tokenAddress!=address(0)) { LPT(tokenAddress).transfer(DAO, tokens);}
	}
	/*
	 * Community Mediums:
		https://discord.com/invite/QpyfMarNrV
		https://twitter.com/ftm1337
		https://t.me/ftm1337

	 * Other Products:
		KUCINO CASINO - The First and Most used Casino of KCC
		ELITE - ftm.guru is an indie growth-hacker for Fantom, providing numerous tools for
		users & developers alike.
	 */
}