pragma solidity ^0.4.25;

/*
VERSION DATE: 30/10/2018

CREATED BY: CRYPTO SPORTZ
ENJOY YOUR TEAM AND SPORTS AND EMAIL US IF YOU HAVE ANY QUESTIONS
*/

contract Owned 
{
    address private candidate;
	address public owner;

	mapping(address => bool) public admins;
	
    constructor() public 
	{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public 
	{
		require(msg.sender == owner);
        candidate = newOwner;
    }
	
	function confirmOwner() public 
	{
        require(candidate == msg.sender);
		owner = candidate;
    }
	
    function addAdmin(address addr) public
	{
		require(msg.sender == owner);
        admins[addr] = true;
    }

    function removeAdmin(address addr) public
	{
		require(msg.sender == owner);
        admins[addr] = false;
    }
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Functional
{
	function uint2str(uint i) internal pure returns (string)
	{
		if (i == 0) return "0";
		uint j = i;
		uint len;
		while (j != 0){
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len - 1;
		while (i != 0){
			bstr[k--] = byte(48 + i % 10);
			i /= 10;
		}
		return string(bstr);
	}
	
	function strConcat(string _a, string _b, string _c) internal pure returns (string)
	{
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		string memory abc;
		uint k = 0;
		uint i;
		bytes memory babc;
		if (_ba.length==0)
		{
			abc = new string(_bc.length);
			babc = bytes(abc);
		}
		else
		{
			abc = new string(_ba.length + _bb.length+ _bc.length);
			babc = bytes(abc);
			for (i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
			for (i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
		}
        for (i = 0; i < _bc.length; i++) babc[k++] = _bc[i];
		return string(babc);
	}
	
	function timenow() public view returns(uint32) { return uint32(block.timestamp); }
}

contract CryptoSportZ is Owned, Functional
{
	enum Winner
	{
		STAKING,
		MAKER,
		BETTER,
		CANCEL
	}
	
	struct Params
	{
		address maker;
		uint32 date;
		uint16 rate;					// the probability of winning the maker = (1-99%)
	}
	
	struct Game
	{
		uint limitMaker;
		uint params;
        mapping(address => int) stake;	// real bets: maker`s>0, bettor`s<0
		uint sumBettorBets;
		uint32 winner;
    }
	
	struct Market
	{
        bytes32 marketHash;
        uint64 gameId;
        uint32 dateStop;
		uint16 rate;
        address maddr;
		uint amount;
    }
	
	struct Decision
	{
		bytes32 decisionHash;
		uint64 gameId;
		uint32 winner;
		address aaddr;
	}
	
	uint256 private constant FEECONTRACT = 2;
	uint256 public feeValue;
	
	mapping(address => uint256) private balances;
	mapping(uint => Game) private games;

	uint[] private markets;
	
	function getMakerBalance(address addr) public view returns(uint balance)
	{
        balance = balances[addr];
    }
	
	event LogChangeBalance(address indexed account, uint oldAmount, uint newAmount);
	event LogMaker(uint gameId, uint date, uint rate, address indexed addr, uint amount, bytes32 marketHash);
	event LogBetter(uint gameId, address indexed better, uint amount, address indexed signer);	
	event LogFinalizeGame(uint gameId, uint32 winner);
	event LogPauOut(address indexed sender, uint gameId, uint amount);
	event LogAffiliate(address indexed sender,uint amount);
	
	constructor() public 
	{
	}

    function deposit() public payable
	{
        require(msg.value > 0);
		uint oldAmount = balances[msg.sender];
		balances[msg.sender] = balances[msg.sender] + msg.value;
		emit LogChangeBalance(msg.sender, oldAmount, balances[msg.sender]);
    }

    function withdraw(uint amount) public
	{
		require(balances[msg.sender] >= amount);
		uint oldAmount = balances[msg.sender];
		balances[msg.sender] = balances[msg.sender] - amount;
		emit LogChangeBalance(msg.sender, oldAmount, balances[msg.sender]);
		msg.sender.transfer(amount);
	}
	
	function getGameInfo(uint gameId) public view returns(
		address maker, 
		uint limitMaker,
		uint32 date, 
		uint32 rate, 
		uint makerStake, 
		uint sumBettorBets, 
		bool finalized, 
		uint32 winner
	){
        Game storage g = games[gameId];
		Params memory params = unPackParams(g.params);
		maker = params.maker;
		date = params.date;
		rate = params.rate;
		limitMaker = g.limitMaker;
		makerStake = uint(g.stake[maker]);
		sumBettorBets = g.sumBettorBets;
		finalized = g.winner==uint32(Winner.STAKING)?false:true;
		winner = g.winner;
    }

    function getGameStake(uint gameId, address addr) public view returns(uint stake, uint prize, bool maker)
	{
		Game storage g = games[gameId];
		int value = g.stake[addr];
		stake = value>0 ? uint(value) : uint(-value);
		maker = value>0;
		prize = 0;
		Params memory params = unPackParams(g.params);
		if (g.winner!=uint32(Winner.STAKING))
		{
			if (addr == params.maker && g.winner == uint32(Winner.MAKER))  prize =  uint( g.stake[addr]) * 100 / params.rate;
			if (addr != params.maker && g.winner == uint32(Winner.BETTER)) prize =  uint(-g.stake[addr]) * 100 / (100-params.rate);
			if (addr == params.maker && g.winner == uint32(Winner.CANCEL)) prize =  uint( g.stake[addr]);
			if (addr != params.maker && g.winner == uint32(Winner.CANCEL)) prize =  uint(-g.stake[addr]);
		}
    }
	
	function getListMarkets(address addr, uint count) public view returns(string res)
	{
		res="";
		uint i;
		uint32 findCount=0;
		Game storage g = games[0];
		
		if (addr!=0x0)
		for (i = markets.length-1; i>=0; i--)
		{
			if(i>markets.length) break;
			g = games[ markets[i] ];
			if (g.stake[addr] != 0) res = strConcat( res, ",", uint2str(markets[i]) );
			findCount++;
			if (count!=0 && findCount>=count) break;
		}
	
		if (addr==0x0)
		for (i = markets.length-1; i>=0; i--)
		{
			if(i>markets.length) break;
			g = games[ markets[i] ];
			if (g.sumBettorBets != 0) res = strConcat( res, ",", uint2str(markets[i]) );
			findCount++;
			if (count!=0 && findCount>=count) break;
		}
	}
	
	function packParams(address addr, uint16 rate, uint32 date) private pure returns(uint pack)
	{
		pack = ( uint256(date) << 22*8 ) + ( uint256(rate) << 20*8 ) + uint256(addr);
	}

	function unPackParams(uint pack) private pure returns(Params memory params)
	{
		params.date = uint32((pack >> (8*22)) & 0xffffffff);
		params.rate = uint16((pack >> (8*20)) & 0xffff);
        params.maker = address(pack & 0x00ffffffffffffffffffffffffffffffffffffffff);
	}
	
	function unPackMarket(uint[2] memory market) private pure returns(Market memory m)
	{
        m.marketHash = keccak256( abi.encodePacked(market) );

		uint packed = market[0];
        m.amount = market[1];
	
		m.gameId   = uint64((packed >> (8*26)) & 0xffffffffffff);
		m.dateStop = uint32((packed >> (8*22)) & 0xffffffff);
		m.rate     = uint16((packed >> (8*20)) & 0xffff);
        m.maddr    = address(packed & 0x00ffffffffffffffffffffffffffffffffffffffff);
    }
	
	// market[0] : 
	// [  id  ][ date ][ rate  ][ masddr]
	// [6 байт][4 байт][2 байта][20 байт]  = 32 байт
	// market[1] : 
	// [ amount ] = 32 байт
	function deal(uint[2] market, bytes32 r, bytes32 s, uint8 v) public payable
	{
		Market memory m = unPackMarket(market);

		require(msg.value>0);
		require(m.gameId>0 && m.gameId<2**48);
		require(m.dateStop>block.timestamp);
		require(m.rate>0 && m.rate<100);
		require(m.maddr != 0x0);
		require(msg.sender != m.maddr);
		require(m.amount > 0 && m.amount < 2**128);
		
		Game storage g = games[m.gameId];
        require(g.winner==uint32(Winner.STAKING));

		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		address signer = ecrecover(keccak256( abi.encodePacked(prefix,m.marketHash) ), v, r, s);
		require(signer==m.maddr);
	
		if (g.sumBettorBets==0)
		{
			emit LogMaker(m.gameId, m.dateStop, m.rate, m.maddr, m.amount, m.marketHash );	
			g.params = packParams(m.maddr,m.rate,m.dateStop);			
			g.limitMaker = m.amount;
			markets.push(m.gameId);
		}

		Params memory params = unPackParams(g.params);
		
		require(params.date == m.dateStop);
		require(params.maker == m.maddr);
		require(params.rate == m.rate);
		
		emit LogBetter(m.gameId, msg.sender, msg.value, signer);	
	
		require( balances[m.maddr] >= msg.value * params.rate / (100-params.rate) );
	
		require( (g.limitMaker-uint(g.stake[params.maker])) >= msg.value * params.rate / (100-params.rate) );

		g.stake[msg.sender] -= int(msg.value);
		g.stake[m.maddr] += int(msg.value * params.rate / (100-params.rate) );

		balances[m.maddr] -= msg.value * params.rate / (100-params.rate);
		
		g.sumBettorBets += msg.value;
	}
	
	event LogStartTrade(uint wager1, uint wager, bytes32 r, bytes32 s, uint8 v, address sender, uint value);
	event LogError(string param, uint value);
	event LogError2(string param, address value);
	function dealLog(uint[2] market, bytes32 r, bytes32 s, uint8 v) public payable
	{
		Market memory m = unPackMarket(market);

		emit LogStartTrade(market[0], market[1], r,s,v, msg.sender, msg.value);
		
		if (msg.value==0) { emit LogError("value", 0); return; }
		if (m.gameId==0 || m.gameId>2**48) { emit LogError("gameId", m.gameId); return; }
		if (m.dateStop<=block.timestamp) { emit LogError("date", m.dateStop); return; }
		if (m.rate==0 || m.rate>=100) { emit LogError("rate", m.rate); return; }
		if (m.maddr == 0x0) { emit LogError("maddr", 0); return; }
		if (msg.sender == m.maddr) { emit LogError("sender=maddr", 0); return; }
		if (m.amount == 0 || m.amount >= 2**128) { emit LogError("amount", m.amount); return; }
		
		Game storage g = games[m.gameId];
		if (g.winner!=uint32(Winner.STAKING)){ emit LogError("winner", g.winner); return; }

		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		address signer = ecrecover(keccak256( abi.encodePacked(prefix,m.marketHash) ), v, r, s);
		if (signer!=m.maddr) { emit LogError2("signer!=maddr", signer); return; }
	
		if (g.sumBettorBets==0)
		{
			emit LogMaker(m.gameId, m.dateStop, m.rate, m.maddr, m.amount, m.marketHash );	
			g.params = packParams(m.maddr,m.rate,m.dateStop);			
			g.limitMaker = m.amount;
			markets.push(m.gameId);
		}

		Params memory params = unPackParams(g.params);
		
		if (params.date != m.dateStop){ emit LogError("params.date", params.date ); return; }
		if (params.maker != m.maddr){ emit LogError2("params.maker", params.maker); return; }
		if (params.rate != m.rate){ emit LogError("params.rate", params.rate); return; }
		
		emit LogBetter(m.gameId, msg.sender, msg.value, signer);	
	
		if ( balances[m.maddr] < msg.value * params.rate / (100-params.rate) ) { emit LogError("NoMoneyInDeposit", balances[m.maddr]); return; }
	
		if ( (g.limitMaker-uint(g.stake[params.maker])) < msg.value * params.rate / (100-params.rate) ) { emit LogError("Limit", (g.limitMaker-uint(g.stake[params.maker]))); return; }

		g.stake[msg.sender] -= int(msg.value);
		g.stake[m.maddr] += int(msg.value * params.rate / (100-params.rate) );

		balances[m.maddr] -= msg.value * params.rate / (100-params.rate);
		
		g.sumBettorBets += msg.value;
	}
	
	function unPackDecision(uint packed) private pure returns(Decision memory d)
	{
        d.decisionHash = keccak256( abi.encodePacked(packed) );
	
		d.gameId   = uint64((packed >> (8*24)) & 0xffffffffffff);
		d.winner   = uint32((packed >> (8*20)) & 0xffffffff);
        d.aaddr    = address(packed & 0x00ffffffffffffffffffffffffffffffffffffffff);
    }
	
	// decision : 
	// [  0 ][  id  ][winner][ masddr]
	// [0000][6 байт][4 байт][20 байт]  = 32 байт
    function payout(uint256 decision, bytes32 r, bytes32 s, uint8 v) public
	{
		Decision memory d = unPackDecision(decision);
		
        Game storage g = games[d.gameId];

        if (g.winner==uint32(Winner.STAKING)) 
		{
			require(d.winner==uint32(Winner.MAKER) || d.winner==uint32(Winner.BETTER) || d.winner==uint32(Winner.CANCEL));

			bytes memory prefix = "\x19Ethereum Signed Message:\n32";
			address signer = ecrecover(keccak256( abi.encodePacked(prefix,d.decisionHash) ), v, r, s);
            require(admins[signer]);

            g.winner = d.winner;
            emit LogFinalizeGame(d.gameId, d.winner);
        }

		require(g.winner!=uint32(Winner.STAKING));

        uint sendValue = 0;
		Params memory params = unPackParams(g.params);

		if (msg.sender == params.maker && g.winner == uint32(Winner.MAKER))  sendValue = uint( g.stake[msg.sender]) * 100 / params.rate;
		if (msg.sender != params.maker && g.winner == uint32(Winner.BETTER)) sendValue = uint(-g.stake[msg.sender]) * 100 / (100-params.rate);

		if (msg.sender == params.maker && g.winner == uint32(Winner.CANCEL)) sendValue = uint( g.stake[msg.sender]);
		if (msg.sender != params.maker && g.winner == uint32(Winner.CANCEL)) sendValue = uint(-g.stake[msg.sender]);

        require(sendValue > 0);
        g.stake[msg.sender] = 0;

		// fee
		uint256 curFee = sendValue * FEECONTRACT / 100;
		sendValue = sendValue - curFee;
		
		// affiliate
		if (d.aaddr != 0x0 && d.aaddr != msg.sender)
		{
			uint aValue = curFee/2;
			curFee = curFee - aValue;
			d.aaddr.transfer(aValue);
			emit LogAffiliate(d.aaddr, aValue);
		}
		
		feeValue = feeValue + curFee;
		
		if (msg.sender == params.maker) 
		{
			uint oldAmount = balances[msg.sender];
			balances[msg.sender] = balances[msg.sender] + sendValue;
			emit LogChangeBalance(msg.sender, oldAmount, balances[msg.sender]);
		}

		if (msg.sender != params.maker)
		{
			msg.sender.transfer(sendValue);
			emit LogPauOut(msg.sender, d.gameId, sendValue);
		}
    }
	
	function cancel(uint64 gameId) public 
	{
		Game storage g = games[gameId];
        require(g.winner==uint32(Winner.STAKING) || g.winner==uint32(Winner.CANCEL));
		
		require( g.stake[msg.sender] != 0 );
		
		Params memory params = unPackParams(g.params);
		require( timenow() > params.date + 60 days );
		
		if ( g.winner==uint32(Winner.STAKING) )
		{
			g.winner = uint32(Winner.CANCEL);
			emit LogFinalizeGame(gameId, g.winner);
		}
		
		require(g.winner==uint32(Winner.CANCEL));

        uint sendValue = 0;

		if (msg.sender == params.maker) sendValue = uint( g.stake[msg.sender]);
		if (msg.sender != params.maker) sendValue = uint(-g.stake[msg.sender]);

        require(sendValue > 0);
        g.stake[msg.sender] = 0;

		// fee
		uint256 curFee = sendValue * FEECONTRACT / 100;
		sendValue = sendValue - curFee;
		feeValue = feeValue + curFee;
		
		if (msg.sender == params.maker) 
		{
			uint oldAmount = balances[msg.sender];
			balances[msg.sender] = balances[msg.sender] + sendValue;
			emit LogChangeBalance(msg.sender, oldAmount, balances[msg.sender]);
		}

		if (msg.sender != params.maker)
		{
			msg.sender.transfer(sendValue);
			emit LogPauOut(msg.sender, gameId, sendValue);
		}
	}
	
	function () onlyOwner payable public {}
	
	function withdrawFee() onlyOwner public
	{
		require( feeValue > 0 );

		uint256 tmpFeeValue = feeValue;
		feeValue = 0;
		
		owner.transfer(tmpFeeValue);
	}
	
}